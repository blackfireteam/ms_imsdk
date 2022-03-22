//
//  MSDBMessageStore.m
//  BlackFireIM
//
//  Created by benny wang on 2021/3/2.
//

#import "MSDBMessageStore.h"
#import "FMDB.h"
#import "NSString+Ext.h"
#import "ChatProtobuf.pbobjc.h"
#import "MSIMTools.h"
#import "MSIMManager.h"
#import "MSIMErrorCode.h"
#import "NSDictionary+Ext.h"
#import "MSDBConversationStore.h"
#import "MSIMConversation.h"
#import "MSConversationProvider.h"
#import "MSIMManager+Parse.h"
#import "MSDBManager.h"
#import "MSIMManager+Internal.h"
#import "MSIMMessage+Internal.h"


static NSString *msg_id = @"msg_id";
static NSString *msg_sign = @"msg_sign";
static NSString *f_id = @"f_id";
static NSString *t_id = @"t_id";
static NSString *msg_type = @"msg_type";
static NSString *send_status = @"send_status";
static NSString *read_status = @"read_status";
static NSString *block_id = @"block_id";
static NSString *code = @"code";
static NSString *reason = @"reason";
static NSString *ext_data = @"ext_data";

@interface MSDBMessageStore()

@end
@implementation MSDBMessageStore

- (BOOL)createTableWithName:(NSString *)name
{
    BOOL isExist = [self tableExists:name];
    if (isExist) {
        //阅后即焚功能需要在消息表中新增一列，snap。为了兼容之谫版本，需要在创建表时判断该字段是否存在。
        BOOL addColumnSucccess = [self inertColumnInTable:name columnName:@"snap" columnType:@"INTEGER"];
        if (addColumnSucccess) {
            return YES;
        }
    }

    NSString *createSQL = [NSString stringWithFormat:@"create table if not exists %@(msg_id INTEGER UNIQUE,msg_sign INTEGER NOT NULL,f_id TEXT,t_id TEXT,msg_type INTEGER,send_status INTEGER,read_status INTEGER,code INTEGER,reason TEXT,block_id INTEGER NOT NULL,snap INTEGER,ext_data blob,PRIMARY KEY(msg_sign))",name];
    BOOL isOK = [self createTable:name withSQL:createSQL];
    if (isOK == NO) {
        NSLog(@"创建表失败****%@",name);
        return NO;
    }
    [[MSDBManager sharedInstance].tableCache setObject:@(YES) forKey:name];
    return YES;
}

- (NSInteger)createBlock_idWithElem:(MSIMMessage *)message tableName:(NSString *)tableName database:(FMDatabase *)db
{
    NSInteger block_id = 1;
    NSString *searchNextSQL = [NSString stringWithFormat:@"select * from %@ where msg_id = '%zd'",tableName,message.msgID + 1];
    FMResultSet *searchNextSet = [db executeQuery:searchNextSQL];
    MSIMMessage *nextElem;
    while ([searchNextSet next]) {
        nextElem = [self bf_componentElem:searchNextSet];
        NSString *searchPreSQL = [NSString stringWithFormat:@"select * from %@ where msg_id = '%zd'",tableName,message.msgID - 1];
        FMResultSet *searchPreSet = [db executeQuery:searchPreSQL];
        MSIMMessage *preElem;
        while ([searchPreSet next]) {
            preElem = [self bf_componentElem:searchPreSet];
            block_id = MIN(nextElem.elem.block_id, preElem.elem.block_id);
            NSString *updateBlockSQL = [NSString stringWithFormat:@"update %@ set block_id = '%zd' where block_id = '%zd'",tableName,block_id,MAX(preElem.elem.block_id, nextElem.elem.block_id)];
            [db executeUpdate:updateBlockSQL];
        }
        if (preElem == nil) {
            block_id = nextElem.elem.block_id;
        }
    }
    if (nextElem == nil) {
        NSString *searchPreSQL = [NSString stringWithFormat:@"select * from %@ where msg_id = '%zd'",tableName,message.msgID - 1];
        FMResultSet *searchPreSet = [db executeQuery:searchPreSQL];
        MSIMMessage *preElem;
        while ([searchPreSet next]) {
            preElem = [self bf_componentElem:searchPreSet];
            block_id = preElem.elem.block_id;
        }
        if (preElem == nil) {
            NSString *maxBlockIDSQL = [NSString stringWithFormat:@"select block_id from %@ order by block_id desc limit 1",tableName];
            FMResultSet *maxBlockSet = [db executeQuery:maxBlockIDSQL];
            while ([maxBlockSet next]) {
                block_id = [maxBlockSet intForColumn:@"block_id"] + 1;
            }
        }
    }
    return block_id;
}

///向数据库中添加批量记录
- (void)addMessages:(NSArray<MSIMMessage *> *)messages
{
    for (MSIMMessage *message in messages) {
        NSString *tableName = [NSString stringWithFormat:@"message_user_%@",message.partnerID];
        BOOL isTableExist = [self createTableWithName:tableName];
        if (isTableExist == NO){
            MSLog(@"创建消息表失败");
            return;
        }
    }
    WS(weakSelf)
    [self.dbQueue inDeferredTransaction:^(FMDatabase * _Nonnull db, BOOL * _Nonnull rollback) {
        for (MSIMMessage *message in messages) {
            NSString *tableName = [NSString stringWithFormat:@"message_user_%@",message.partnerID];
            NSString *lastMessageIDSQL = [NSString stringWithFormat:@"select * from %@ where msg_id > 0 order by msg_id desc limit 1",tableName];
            FMResultSet *lastMessageIDSet = [db executeQuery:lastMessageIDSQL];
            MSIMMessage *lastContainMsgIDElem;
            while ([lastMessageIDSet next]) {
                lastContainMsgIDElem = [weakSelf bf_componentElem:lastMessageIDSet];
                if (message.msgID != 0) {
                    
                    NSString *searchCurrentSQL = [NSString stringWithFormat:@"select * from %@ where msg_id = '%zd'",tableName,message.msgID];
                    FMResultSet *searchCurrentSet = [db executeQuery:searchCurrentSQL];
                    MSIMMessage *currentElem;
                    while ([searchCurrentSet next]) {
                        currentElem = [weakSelf bf_componentElem:searchCurrentSet];
                        continue;
                    }
                    //如果Msg_id重复，将旧的一条删除。在服务器清除数据时会出现
                    if (currentElem) {
                        NSString *updateSQL = [NSString stringWithFormat:@"delete from %@ where msg_id = '%zd'",tableName,message.msgID];
                        [db executeUpdate:updateSQL];
                    }
                    NSInteger blockId = [weakSelf createBlock_idWithElem:message tableName:tableName database:db];
                    [weakSelf addMessageToDB:message block_id:blockId tableName:tableName database:db];

                }else {
                    NSString *maxBlockIDSQL = [NSString stringWithFormat:@"select block_id from %@ order by block_id desc limit 1",tableName];
                    FMResultSet *maxBlockSet = [db executeQuery:maxBlockIDSQL];
                    while ([maxBlockSet next]) {
                        NSInteger block_id = [maxBlockSet intForColumn:@"block_id"];
                        [weakSelf addMessageToDB:message block_id:block_id tableName:tableName database:db];
                    }
                }
            }
            if (lastContainMsgIDElem == nil) {
                [weakSelf addMessageToDB:message block_id:1 tableName:tableName database:db];
            }
        }
    }];
}

///向数据库中添加一条记录
- (void)addMessage:(MSIMMessage *)message
{
    [self addMessages:@[message]];
}

- (void)addMessageToDB:(MSIMMessage *)message block_id:(NSInteger)block_id tableName:(NSString *)tableName database:(FMDatabase *)db
{
    NSString *addSQL = @"replace into %@ (msg_id,msg_sign,f_id,t_id,msg_type,send_status,read_status,code,reason,block_id,snap,ext_data) VALUES (?,?,?,?,?,?,?,?,?,?,?,?)";
    NSString *sqlStr = [NSString stringWithFormat:addSQL,tableName];
    NSArray *addParams = @[(message.msgID ? @(message.msgID) : [NSNull null]),
                           @(message.msgSign),
                           message.fromUid,
                           message.toUid,
                           @(message.type),
                           @(message.sendStatus),
                           @(message.readStatus),
                           @(message.code),
                           XMNoNilString(message.reason),
                           @(block_id),
                           @(message.isSnapChat),
                           message.elem.extData ?:[NSNull  null]];
    [db executeUpdate:sqlStr withArgumentsInArray:addParams];
}

///标记某一条消息为撤回消息
- (BOOL)updateMessageRevoke:(NSInteger)msg_id partnerID:(NSString *)partnerID
{
    NSString *tableName = [NSString stringWithFormat:@"message_user_%@",partnerID];
    if (![self tableExists:tableName]) return NO;
    
    NSString *sqlStr = [NSString stringWithFormat:@"update %@ set msg_type = '%zd' where msg_id = '%zd'",tableName,MSIM_MSG_TYPE_REVOKE,msg_id];
    BOOL isOK = [self excuteSQL:sqlStr];
    return isOK;
}

///收到对阅后即焚消息已读的指令，将消息表中对应的消息标记为删除
- (BOOL)updateMessageSnapchat:(NSInteger)msg_id partnerID:(NSString *)partnerID
{
    NSString *tableName = [NSString stringWithFormat:@"message_user_%@",partnerID];
    if (![self tableExists:tableName]) return NO;
    
    NSString *sqlStr = [NSString stringWithFormat:@"update %@ set msg_type = '%zd' where msg_id = '%zd'",tableName,MSIM_MSG_TYPE_NULL,msg_id];
    BOOL isOK = [self excuteSQL:sqlStr];
    return isOK;
}

///将表中所有消息id <= last_msg_id标记为已读
- (BOOL)markMessageAsRead:(NSInteger)last_msg_id partnerID:(NSString *)partnerID
{
    NSString *tableName = [NSString stringWithFormat:@"message_user_%@",partnerID];
    if (![self tableExists:tableName]) return NO;
    
    NSString *sqlStr = [NSString stringWithFormat:@"update %@ set read_status = '%zd' where msg_id <= '%zd'",tableName,MSIM_MSG_STATUS_READ,last_msg_id];
    BOOL isOK = [self excuteSQL:sqlStr];
    return isOK;
}

///取最后一条msg_id
- (MSIMMessage *)lastMessageID:(NSString *)partner_id
{
    if (partner_id.length == 0) {
        return nil;
    }
    __block MSIMMessage *message = nil;
    NSString *tableName = [NSString stringWithFormat:@"message_user_%@",partner_id];
    if (![self tableExists:tableName]) return nil;
    
    NSString *sqlStr = [NSString stringWithFormat:@"select * from %@ where msg_id > 0 order by msg_id desc limit 1",tableName];
    WS(weakSelf)
    [self excuteQuerySQL:sqlStr resultBlock:^(FMResultSet * _Nonnull rsSet) {
        while ([rsSet next]) {
            message = [weakSelf bf_componentElem:rsSet];
        }
        [rsSet close];
    }];
    return message;
}

///取最后一条msg_sign
- (MSIMMessage *)lastMessage:(NSString *)partner_id
{
    if (partner_id.length == 0) {
        return nil;
    }
    __block MSIMMessage *message = nil;
    NSString *tableName = [NSString stringWithFormat:@"message_user_%@",partner_id];
    if (![self tableExists:tableName]) return nil;
    
    NSString *sqlStr = [NSString stringWithFormat:@"select * from %@ order by msg_sign desc limit 1",tableName];
    WS(weakSelf)
    [self excuteQuerySQL:sqlStr resultBlock:^(FMResultSet * _Nonnull rsSet) {
        STRONG_SELF(strongSelf)
        while ([rsSet next]) {
            message = [strongSelf bf_componentElem:rsSet];
        }
        [rsSet close];
    }];
    return message;
}

///取最后一条可显示的消息
- (MSIMMessage *)lastShowMessage:(NSString *)partner_id
{
    if (partner_id.length == 0) {
        return nil;
    }
    __block MSIMMessage *message = nil;
    NSString *tableName = [NSString stringWithFormat:@"message_user_%@",partner_id];
    if (![self tableExists:tableName]) return nil;
    
    NSString *sqlStr = [NSString stringWithFormat:@"select * from %@ where msg_type != '%zd' order by msg_sign desc limit 1",tableName,MSIM_MSG_TYPE_NULL];
    WS(weakSelf)
    [self excuteQuerySQL:sqlStr resultBlock:^(FMResultSet * _Nonnull rsSet) {
        STRONG_SELF(strongSelf)
        while ([rsSet next]) {
            message = [strongSelf bf_componentElem:rsSet];
        }
        [rsSet close];
    }];
    return message;
}

///取表中最大的block_id
- (NSInteger)maxBlockID:(NSString *)partner_id
{
    if (partner_id.length == 0) {
        return 1;
    }
    __block NSInteger block_id = 1;
    NSString *tableName = [NSString stringWithFormat:@"message_user_%@",partner_id];
    if (![self tableExists:tableName]) return 1;
    
    NSString *sqlStr = [NSString stringWithFormat:@"select block_id from %@ order by block_id desc limit 1",tableName];
    [self excuteQuerySQL:sqlStr resultBlock:^(FMResultSet * _Nonnull rsSet) {
        while ([rsSet next]) {
            block_id = [rsSet intForColumn:@"block_id"];
        }
        [rsSet close];
    }];
    return block_id;
}

///更新block_id
- (BOOL)updateBlockID:(NSInteger)fromBlockID toBlockID:(NSInteger)toBlockID partnerID:(NSString *)partnerID
{
    NSString *tableName = [NSString stringWithFormat:@"message_user_%@",partnerID];
    if (![self tableExists:tableName]) return NO;
    
    NSString *sqlStr = [NSString stringWithFormat:@"update %@ set block_id = '%zd' where block_id = '%zd'",tableName,toBlockID,fromBlockID];
    BOOL isOK = [self excuteSQL:sqlStr];
    return isOK;
}

///根据msg_id查询消息
- (MSIMMessage *)searchMessage:(NSString *)partner_id msg_id:(NSInteger)msg_id
{
    if (partner_id.length == 0) {
        return nil;
    }
    __block MSIMMessage *message = nil;
    NSString *tableName = [NSString stringWithFormat:@"message_user_%@",partner_id];
    
    NSString *sqlStr = [NSString stringWithFormat:@"select * from %@ where msg_id = '%zd'",tableName,msg_id];
    WS(weakSelf)
    [self excuteQuerySQL:sqlStr resultBlock:^(FMResultSet * _Nonnull rsSet) {
        STRONG_SELF(strongSelf)
        while ([rsSet next]) {
            message = [strongSelf bf_componentElem:rsSet];
        }
        [rsSet close];
    }];
    return message;
}

///根据msg_sign查询消息
- (MSIMMessage *)searchMessage:(NSString *)partner_id msg_sign:(NSInteger)msg_sign
{
    if (partner_id.length == 0) {
        return nil;
    }
    __block MSIMMessage *message = nil;
    NSString *tableName = [NSString stringWithFormat:@"message_user_%@",partner_id];
    
    NSString *sqlStr = [NSString stringWithFormat:@"select * from %@ where msg_sign = '%zd'",tableName,msg_sign];
    WS(weakSelf)
    [self excuteQuerySQL:sqlStr resultBlock:^(FMResultSet * _Nonnull rsSet) {
        STRONG_SELF(strongSelf)
        while ([rsSet next]) {
            message = [strongSelf bf_componentElem:rsSet];
        }
        [rsSet close];
    }];
    return message;
}

- (NSArray<MSIMMessage *> *)localMessageGroupByBlockID:(NSInteger)blockID partnerID:(NSString *)partnerID maxCount:(NSInteger)count
{
    NSString *tableName = [NSString stringWithFormat:@"message_user_%@",partnerID];
    NSString *sqlStr = [NSString stringWithFormat:@"select * from %@ where block_id = '%zd' order by msg_sign desc limit '%zd'",tableName,blockID,count];
    __block NSMutableArray *data = [[NSMutableArray alloc] init];
    WS(weakSelf)
    [self excuteQuerySQL:sqlStr resultBlock:^(FMResultSet * _Nonnull rsSet) {
        while ([rsSet next]) {
            [data addObject:[weakSelf bf_componentElem:rsSet]];
        }
        [rsSet close];
    }];
    return data;
}

- (MSIMMessage *)latestMessageIDBeforeMsgSign:(NSInteger)msg_sign partnerID:(NSString *)partnerID notBlockID:(NSInteger)block_id
{
    NSString *tableName = [NSString stringWithFormat:@"message_user_%@",partnerID];
    NSString *sqlStr = [NSString stringWithFormat:@"select * from %@ where msg_sign < '%zd' and msg_id != 0 and block_id != '%zd' order by msg_sign desc limit 1",tableName,msg_sign,block_id];
    __block MSIMMessage *message = nil;
    WS(weakSelf)
    [self excuteQuerySQL:sqlStr resultBlock:^(FMResultSet * _Nonnull rsSet) {
        while ([rsSet next]) {
            message = [weakSelf bf_componentElem:rsSet];
        }
        [rsSet close];
    }];
    return message;
}

- (MSIMMessage *)greaterMessageIDBeforeMsgSign:(NSInteger)msg_sign partnerID:(NSString *)partnerID
{
    NSString *tableName = [NSString stringWithFormat:@"message_user_%@",partnerID];
    NSString *sqlStr = [NSString stringWithFormat:@"select * from %@ where msg_sign >= '%zd' and msg_id != 0 order by msg_sign asc limit 1",tableName,msg_sign];
    __block MSIMMessage *message = nil;
    WS(weakSelf)
    [self excuteQuerySQL:sqlStr resultBlock:^(FMResultSet * _Nonnull rsSet) {
        while ([rsSet next]) {
            message = [weakSelf bf_componentElem:rsSet];
        }
        [rsSet close];
    }];
    return message;
}

///取出小于msg_id的消息的msg_id
- (NSInteger)latestMsgIDLessThan:(NSInteger)msg_id partner_id:(NSString *)partner_id block_id:(NSInteger)block_id
{
    NSString *tableName = [NSString stringWithFormat:@"message_user_%@",partner_id];
    NSString *sqlStr = [NSString stringWithFormat:@"select msg_id from %@ where msg_id < '%zd' and msg_id != 0 and block_id != '%zd' order by msg_sign desc limit 1",tableName,msg_id,block_id];
    __block NSInteger minMsgID = 0;
    [self excuteQuerySQL:sqlStr resultBlock:^(FMResultSet * _Nonnull rsSet) {
        while ([rsSet next]) {
            minMsgID = [rsSet longLongIntForColumn:@"msg_id"];
        }
        [rsSet close];
    }];
    return minMsgID;
}

/// 分页获取聊天记录
- (void)messageByPartnerID:(NSString *)partnerID
             last_msg_sign:(NSInteger)last_msg_sign
                     count:(NSInteger)count
                  complete:(void(^)(NSArray<MSIMMessage *> *data,BOOL hasMore))complete
{
    //先取出对应会话中记录的最后一条msg_id
    MSDBConversationStore *convStore = [[MSDBConversationStore alloc]init];
    MSIMConversation *conv = [convStore searchConversation:[NSString stringWithFormat:@"c2c_%@",partnerID]];
    NSInteger msg_end = conv.msg_end;
    if (last_msg_sign == 0) {//第一页
        MSIMMessage *lastElem = [self lastMessageID:partnerID];
        NSInteger lastMsgSign = 0;
        if (lastElem == nil) {
            lastMsgSign = [self lastMessage:partnerID].msgSign;
        }
        if (msg_end <= lastElem.msgID) {//直接本地取
            WS(weakSelf)
            [self messageFromLocalByPartnerID:partnerID last_msg_sign:last_msg_sign count:count block_id:MAX(lastElem.elem.block_id, 1) result:^(NSArray<MSIMMessage *> *arr, BOOL hasMore) {
                NSInteger minMsgID = [weakSelf minMsgIDInMessages:arr];
                if (hasMore) {
                    complete(arr,YES);
                }else {
                    if (minMsgID <= 1) {
                        complete(arr,NO);
                    }else {
                        if (arr.count >= count) {
                            complete(arr,YES);
                        }else {
                            NSInteger preMsgID = [weakSelf latestMsgIDLessThan:minMsgID partner_id:partnerID block_id: MAX(lastElem.elem.block_id, 1)];
                            [weakSelf requestHistoryMessageFromEnd:minMsgID toStart:preMsgID partner_Id:partnerID result:^(NSArray<MSIMMessage *> *msgs) {
                                NSMutableArray *tempArr = [NSMutableArray array];
                                [tempArr addObjectsFromArray:arr];
                                [tempArr addObjectsFromArray:msgs];
                                if ((preMsgID == 0 && msgs.count == 0) || (msgs.lastObject.msgID <= 1 && lastMsgSign == 0)) {
                                    //说明之前的消息在服务器都不存在了
                                    complete(tempArr,NO);
                                }else {
                                    complete(tempArr,YES);
                                }
                            }];
                        }
                    }
                }
            }];
        }else {
            WS(weakSelf)
            [self requestHistoryMessageFromEnd:0 toStart:lastElem.msgID partner_Id:partnerID result:^(NSArray<MSIMMessage *> *msgs) {
                NSInteger minMsgID = [weakSelf minMsgIDInMessages:msgs];
                if (msgs.count >= count) {
                    if (minMsgID <= 1 && lastMsgSign == 0) {
                        complete(msgs,NO);
                    }else {
                        complete(msgs,YES);
                    }
                }else {
                    [weakSelf messageFromLocalByPartnerID:partnerID last_msg_sign:msgs.lastObject.msgSign count:count-msgs.count block_id:MAX(lastElem.elem.block_id, 1) result:^(NSArray<MSIMMessage *> *localElems, BOOL hasMore) {
                        NSMutableArray *tempArr = [NSMutableArray array];
                        [tempArr addObjectsFromArray:msgs];
                        [tempArr addObjectsFromArray:localElems];
                        if (hasMore) {
                            complete(tempArr,YES);
                        }else {
                            if ([weakSelf minMsgIDInMessages:localElems] <= 1) {
                                complete(tempArr,NO);
                            }else {
                                complete(tempArr,YES);
                            }
                        }
                    }];
                }
            }];
        }
    }else {
        WS(weakSelf)
        MSIMMessage *preElem = [self searchMessage:partnerID msg_sign:last_msg_sign];
        [self messageFromLocalByPartnerID:partnerID last_msg_sign:last_msg_sign count:count block_id:preElem.elem.block_id result:^(NSArray<MSIMMessage *> *arr, BOOL hasMore) {
            if (hasMore) {
                complete(arr,YES);
            }else {
                if (arr.count == 0) {
                    MSIMMessage *greaterMsdID = [weakSelf greaterMessageIDBeforeMsgSign:last_msg_sign partnerID:partnerID];
                    NSInteger startID = 0;
                    [weakSelf requestHistoryMessageFromEnd:greaterMsdID.msgID toStart:startID partner_Id:partnerID result:^(NSArray<MSIMMessage *> *msgs) {
                        if ((startID == 0 && msgs.count == 0) || msgs.lastObject.msgID <= 1) {
                            complete(msgs, NO);
                        }else {
                            complete(msgs,YES);
                        }
                    }];
                }else {
                    NSInteger minMsgID = [weakSelf minMsgIDInMessages:arr];
                    if (minMsgID <= 1) {
                        complete(arr,NO);
                    }else {
                        MSIMMessage *lastMsdID = [weakSelf latestMessageIDBeforeMsgSign:arr.lastObject.msgSign partnerID:partnerID notBlockID: arr.lastObject.elem.block_id];
                        [weakSelf requestHistoryMessageFromEnd:minMsgID toStart:lastMsdID.msgID partner_Id:partnerID result:^(NSArray<MSIMMessage *> *msgs) {
                            NSMutableArray *tempArr = [NSMutableArray array];
                            [tempArr addObjectsFromArray:arr];
                            [tempArr addObjectsFromArray:msgs];
                            if ((lastMsdID.msgID == 0 && msgs.count == 0) || msgs.lastObject.msgID <= 1) {
                                complete(tempArr, NO);
                            }else {
                                complete(tempArr,YES);
                            }
                        }];
                    }
                }
            }
        }];
    }
}

- (NSInteger)minMsgIDInMessages:(NSArray *)msgs
{
    NSInteger msgID = 0;
    for (NSInteger i = 0; i < msgs.count; i++) {
        MSIMMessage *message = msgs[i];
        if (message.msgID == 0) continue;
        if (msgID == 0 || message.msgID < msgID) {
            msgID = message.msgID;
        }
    }
    return msgID;
}


- (void)requestHistoryMessageFromEnd:(NSInteger)msgEnd toStart:(NSInteger)msgStart partner_Id:(NSString *)partner_id result:(void(^)(NSArray<MSIMMessage *> *messages))result
{
    GetHistory *history = [[GetHistory alloc]init];
    history.sign = [MSIMTools sharedInstance].adjustLocalTimeInterval;
    history.toUid = partner_id.integerValue;
    history.msgEnd = msgEnd;
    history.msgStart = msgStart;
    NSLog(@"[发送消息]GetHistory:\n%@",history);
    [[MSIMManager sharedInstance].socket send:[history data] protoType:XMChatProtoTypeGetHistoryMsg needToEncry:NO sign:history.sign callback:^(NSInteger code, id  _Nullable response, NSString * _Nullable error) {
        if (code == ERR_SUCC) {
            ChatRBatch *batch = response;
            NSArray<MSIMMessage *> *msgs = [[MSIMManager sharedInstance] chatHistoryHandler:batch.msgsArray];
            //将不显示的消息剔除
            NSMutableArray *tempArr = [NSMutableArray array];
            for (MSIMMessage *message in msgs) {
                if (message.type != MSIM_MSG_TYPE_NULL) {
                    [tempArr addObject:message];
                }
            }
            // 如果服务器将消息删除了，或者服务器数据丢失情况时，本地用占位消息补上缺失的来保证msg_id的连续性。
            [self addEmptyMessageIfNeededIn:msgs msgStart:msgStart msgEnd:msgEnd partner_Id:partner_id];
            result(tempArr);
        }else {
            result(nil);
        }
    }];
}

- (void)addEmptyMessageIfNeededIn:(NSArray<MSIMMessage *> *)msgs msgStart:(NSInteger)start msgEnd:(NSInteger)end partner_Id:(NSString *)partner_id
{
    NSInteger from_msg_id = 0;
    NSInteger to_msg_id = 0;
    if (start && end) {
        from_msg_id = end - 1;
        to_msg_id = start + 1;
    }else if (end) {
        from_msg_id = end - 1;
        to_msg_id = msgs.lastObject.msgID;
    }else if (start) {
        from_msg_id = msgs.firstObject.msgID;
        to_msg_id = start + 1;
    }else {
        from_msg_id = msgs.firstObject.msgID;
        to_msg_id = msgs.lastObject.msgID;
    }
    NSMutableArray *arr = [NSMutableArray array];
    NSInteger msgSign = [MSIMTools sharedInstance].adjustLocalTimeInterval;
    for (NSInteger i = from_msg_id; i >= to_msg_id; i--) {
        BOOL isExsit = NO;
        for (MSIMMessage *message in msgs) {
            if (message.msgID == i) {
                isExsit = YES;
                break;
            }
        }
        if (isExsit == NO) {
            MSIMMessage *emptyMsg = [[MSIMMessage alloc]init];
            emptyMsg.type = MSIM_MSG_TYPE_NULL;
            emptyMsg.fromUid = [MSIMTools sharedInstance].user_id;
            emptyMsg.toUid = partner_id;
            emptyMsg.msgID = i;
            emptyMsg.msgSign = msgSign;
            [arr addObject:emptyMsg];
            msgSign += 1;
        }
    }
    [self addMessages:arr];
}

- (void)messageFromLocalByPartnerID:(NSString *)partnerID
                                       last_msg_sign:(NSInteger)last_msg_sign
                                               count:(NSInteger)count
                                            block_id:(NSInteger)block_id
                                              result:(void(^)(NSArray<MSIMMessage *> *messages,BOOL hasMore))result
{
    NSString *sqlStr;
    NSString *tableName = [NSString stringWithFormat:@"message_user_%@",partnerID];
    if (![self tableExists:tableName]) {
        result(@[],NO);
        return;
    }
    
    if (last_msg_sign == 0) {
        sqlStr = [NSString stringWithFormat:@"select * from %@ where msg_type != '%zd' and block_id = '%zd' order by msg_sign desc limit '%zd'",tableName,MSIM_MSG_TYPE_NULL,block_id,count+1];
    }else {
        sqlStr = [NSString stringWithFormat:@"select * from %@ where msg_sign < '%zd' and msg_type != '%zd' and block_id = '%zd' order by msg_sign desc limit '%zd'",tableName,last_msg_sign,MSIM_MSG_TYPE_NULL,block_id,count+1];
    }
    __block NSMutableArray *data = [[NSMutableArray alloc] init];
    WS(weakSelf)
    [self excuteQuerySQL:sqlStr resultBlock:^(FMResultSet * _Nonnull rsSet) {
        while ([rsSet next]) {
            [data addObject:[weakSelf bf_componentElem:rsSet]];
        }
        [rsSet close];
    }];
    if (data.count > count) {
        [data removeLastObject];
        result(data,YES);
    }else {
        result(data,NO);
    }
}

///本地删除消息
- (BOOL)deleteFromLocalWithMsg_sign:(NSInteger)msg_sign partner_id:(NSString *)partner_id
{
    NSString *tableName = [NSString stringWithFormat:@"message_user_%@",partner_id];
    if (![self tableExists:tableName]) return NO;
    
    NSString *sqlStr = [NSString stringWithFormat:@"update %@ set msg_type = '%zd' where msg_sign = '%zd'",tableName,MSIM_MSG_TYPE_NULL,msg_sign];
    BOOL isOK = [self excuteSQL:sqlStr];
    return isOK;
}

- (MSIMMessage *)bf_componentElem:(FMResultSet *)rsSet
{
    MSIMMessage *message = [[MSIMMessage alloc]init];
    MSIMElem *elem = [[MSIMElem alloc]init];
    MSIMMessageType type = [rsSet intForColumn:msg_type];
    NSData *extData = [rsSet dataForColumn:@"ext_data"];
    NSDictionary *dic = [NSDictionary el_convertFromData:extData];
    if (type == MSIM_MSG_TYPE_TEXT) {
        MSIMTextElem *textElem = [[MSIMTextElem alloc]init];
        textElem.text = dic[@"text"];
        elem = textElem;
    }else if (type == MSIM_MSG_TYPE_IMAGE) {
        MSIMImageElem *imageElem = [[MSIMImageElem alloc]init];
        imageElem.width = [dic[@"width"]integerValue];
        imageElem.height = [dic[@"height"]integerValue];
        imageElem.size = [dic[@"size"]integerValue];
        imageElem.path = [self fixLocalImagePath:dic[@"path"]];
        imageElem.url = dic[@"url"];
        imageElem.uuid = dic[@"uuid"];
        elem = imageElem;
    }else if (type == MSIM_MSG_TYPE_VIDEO) {
        MSIMVideoElem *videoElem = [[MSIMVideoElem alloc]init];
        videoElem.width = [dic[@"width"]integerValue];
        videoElem.height = [dic[@"height"]integerValue];
        videoElem.videoUrl = dic[@"videoUrl"];
        videoElem.videoPath = [self fixLocalImagePath:dic[@"videoPath"]];
        videoElem.coverPath = [self fixLocalImagePath:dic[@"coverPath"]];
        videoElem.coverUrl = dic[@"coverUrl"];
        videoElem.duration = [dic[@"duration"] integerValue];
        videoElem.uuid = dic[@"uuid"];
        videoElem.size = [dic[@"size"]integerValue];
        elem = videoElem;
    }else if (type == MSIM_MSG_TYPE_VOICE) {
        MSIMVoiceElem *voiceElem = [[MSIMVoiceElem alloc]init];
        voiceElem.url = dic[@"voiceUrl"];
        voiceElem.path = [self fixLocalImagePath:dic[@"voicePath"]];
        voiceElem.duration = [dic[@"duration"] integerValue];
        voiceElem.dataSize = [dic[@"size"] integerValue];
        elem = voiceElem;
    }else if (type == MSIM_MSG_TYPE_LOCATION) {
        MSIMLocationElem *locationElem = [[MSIMLocationElem alloc]init];
        locationElem.title = dic[@"title"];
        locationElem.detail = dic[@"detail"];
        locationElem.latitude = [dic[@"latitude"] doubleValue];
        locationElem.longitude = [dic[@"longitude"] doubleValue];
        locationElem.zoom = [dic[@"zoom"] integerValue];
        elem = locationElem;
    }else if (type == MSIM_MSG_TYPE_EMOTION) {
        MSIMEmotionElem *emotionElem = [[MSIMEmotionElem alloc]init];
        emotionElem.emotionID = dic[@"emotionID"];
        emotionElem.emotionUrl = dic[@"emotionUrl"];
        emotionElem.emotionName = dic[@"emotionName"];
        elem = emotionElem;
    }else if (type == MSIM_MSG_TYPE_CUSTOM_IGNORE_UNREADCOUNT_RECALL || type == MSIM_MSG_TYPE_CUSTOM_UNREADCOUNT_NO_RECALL || type == MSIM_MSG_TYPE_CUSTOM_UNREADCOUNT_RECAL) {
        MSIMCustomElem *customElem = [[MSIMCustomElem alloc]init];
        customElem.option = type;
        customElem.jsonStr = dic[@"jsonStr"];
        MSIMPushInfo *push = [[MSIMPushInfo alloc]init];
        push.title = dic[@"title"];
        push.body = dic[@"body"];
        push.isMute = [dic[@"isMute"]boolValue];
        push.sound = dic[@"sound"];
        customElem.pushExt = push;
        elem = customElem;
    }
    message.elem = elem;
    message.msgID = [rsSet longLongIntForColumn:@"msg_id"];
    message.msgSign = [rsSet longLongIntForColumn:@"msg_sign"];
    message.type = type;
    message.fromUid = [rsSet stringForColumn:@"f_id"];
    message.toUid = [rsSet stringForColumn:@"t_id"];
    message.sendStatus = [rsSet intForColumn:@"send_status"];
    message.readStatus = [rsSet intForColumn:@"read_status"];
    message.elem.block_id = [rsSet intForColumn:@"block_id"];
    message.code = [rsSet intForColumn:@"code"];
    message.reason = [rsSet stringForColumn:@"reason"];
    message.isSnapChat = [rsSet intForColumn:@"snap"];
    return message;
}


- (NSString *)fixLocalImagePath:(NSString *)path
{
    if (path.length == 0) return @"";
    NSString *homePath = NSHomeDirectory();
    if ([path hasPrefix:homePath]) {
        return path;
    }
    if ([path containsString:@"/Documents/"]) {
        NSRange range = [path rangeOfString:@"/Documents/"];
        path = [path substringFromIndex:range.location];
        path = [homePath stringByAppendingPathComponent:path];
        return path;
    }
    if ([path containsString:@"/Library/"]) {
        NSRange range = [path rangeOfString:@"/Library/"];
        path = [path substringFromIndex:range.location];
        path = [homePath stringByAppendingPathComponent:path];
        return path;
    }
    if ([path containsString:@"/tmp/"]) {
        NSRange range = [path rangeOfString:@"/tmp/"];
        path = [path substringFromIndex:range.location];
        path = [homePath stringByAppendingPathComponent:path];
        return path;
    }
    return @"";
}

@end
