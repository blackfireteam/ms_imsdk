//
//  MSDBConversationStore.m
//  BlackFireIM
//
//  Created by benny wang on 2021/3/3.
//

#import "MSDBConversationStore.h"
#import "MSIMConversation.h"
#import "FMDB.h"

static NSString *CONV_TABLE_NAME = @"conversation";

@implementation MSDBConversationStore

- (BOOL)createTable
{
    if ([self tableExists:CONV_TABLE_NAME]) return YES;
    NSString *createSQL = [NSString stringWithFormat:@"create table if not exists %@(conv_id TEXT,chat_type INTEGER,f_id TEXT,msg_end INTEGER,show_msg_sign INTEGER,msg_last_read INTEGER,unread_count INTEGER,status INTEGER,draft TEXT,is_top INTEGER,show_time INTEGER,ext TEXT,PRIMARY KEY(conv_id))",CONV_TABLE_NAME];
    BOOL isOK = [self createTable:CONV_TABLE_NAME withSQL:createSQL];
    if (isOK == NO) {
        NSLog(@"创建表失败****%@",CONV_TABLE_NAME);
    }
    return isOK;
}

///批量添加会话记录
- (void)addConversations:(NSArray<MSIMConversation *> *)convs
{
    [self createTable];
    [self.dbQueue inDeferredTransaction:^(FMDatabase * _Nonnull db, BOOL * _Nonnull rollback) {
        NSString *addSQL = @"REPLACE into %@ (conv_id,chat_type,f_id,msg_end,show_msg_sign,msg_last_read,unread_count,status,draft,is_top,show_time,ext) VALUES (?,?,?,?,?,?,?,?,?,?,?,?)";
        NSString *sqlStr = [NSString stringWithFormat:addSQL,CONV_TABLE_NAME];
        for (MSIMConversation *conv in convs) {
            NSArray *addParams = @[conv.conversation_id,
                                   @(conv.chat_type),
                                   conv.partner_id,
                                   @(conv.msg_end),
                                   @(conv.show_msg_sign),
                                   @(conv.msg_last_read),
                                   @(conv.unread_count),
                                   @(conv.deleted),
                                   XMNoNilString(conv.draftText),
                                   @(conv.is_top),
                                   @(conv.time),
                                   conv.extString];
            [db executeUpdate:sqlStr withArgumentsInArray:addParams];
        }
    }];
}

///更新会话记录未读数
- (BOOL)updateConvesation:(NSString *)conv_id unread_count:(NSInteger)count
{
    if (![self tableExists:CONV_TABLE_NAME]) return NO;
    NSString *sqlStr = [NSString stringWithFormat:@"update %@ set unread_count = '%zd' where conv_id = '%@'",CONV_TABLE_NAME,count,conv_id];
    BOOL isOK = [self excuteSQL:sqlStr];
    return isOK;
}


///查询所有的会话记录
- (NSArray<MSIMConversation *> *)allConvesations
{
    if (![self tableExists:CONV_TABLE_NAME]) return @[];
    __block NSMutableArray *convs = [[NSMutableArray alloc] init];
    NSString *sqlString = [NSString stringWithFormat: @"SELECT * FROM %@ where status = 0 ORDER BY show_time DESC", CONV_TABLE_NAME];
    WS(weakSelf)
    [self excuteQuerySQL:sqlString resultBlock:^(FMResultSet * _Nonnull rsSet) {
        while ([rsSet next]) {
            MSIMConversation *conv = [weakSelf bf_component_conv:rsSet];
            [convs addObject:conv];
        }
        [rsSet close];
    }];
    return convs;
}

/// 分页获取会话记录
- (void)conversationsWithLast_seq:(NSInteger)last_seq
                            count:(NSInteger)count
                         complete:(void(^)(NSArray<MSIMConversation *> *data,BOOL hasMore))complete
{
    if (![self tableExists:CONV_TABLE_NAME]) {
        complete(@[],NO);
        return;
    }
    NSString *sqlStr;
    if (last_seq == 0) {
        sqlStr = [NSString stringWithFormat:@"select * from %@ where status = 0 order by show_time desc limit '%zd'",CONV_TABLE_NAME,count+1];
    }else {
        sqlStr = [NSString stringWithFormat:@"select * from %@ where status = 0 and show_time < '%zd' order by show_time desc limit '%zd'",CONV_TABLE_NAME,last_seq,count+1];
    }
    __block NSMutableArray *data = [[NSMutableArray alloc] init];
    WS(weakSelf)
    [self excuteQuerySQL:sqlStr resultBlock:^(FMResultSet * _Nonnull rsSet) {
        while ([rsSet next]) {
            [data addObject:[weakSelf bf_component_conv:rsSet]];
        }
        [rsSet close];
    }];
    BOOL hasMore = NO;
    if (data.count == count + 1) {
        hasMore = YES;
        [data removeLastObject];
    }
    complete(data,hasMore);
}

///查询某一条会话
- (nullable MSIMConversation *)searchConversation:(NSString *)conv_id
{
    if (![self tableExists:CONV_TABLE_NAME]) return nil;
    __block MSIMConversation *conv = nil;
    NSString *sqlString = [NSString stringWithFormat:@"SELECT * FROM %@ WHERE conv_id = '%@'", CONV_TABLE_NAME,conv_id];
    WS(weakSelf)
    [self excuteQuerySQL:sqlString resultBlock:^(FMResultSet * _Nonnull rsSet) {
        while ([rsSet next]) {
            conv = [weakSelf bf_component_conv:rsSet];
        }
        [rsSet close];
    }];
    return conv;
}

///所有未读数之和
- (NSInteger)allUnreadCount
{
    if (![self tableExists:CONV_TABLE_NAME]) return 0;
    __block NSInteger total = 0;
    NSString *sqlString = [NSString stringWithFormat:@"SELECT SUM(unread_count) AS 'total' from %@ WHERE status = 0", CONV_TABLE_NAME];
    [self excuteQuerySQL:sqlString resultBlock:^(FMResultSet * _Nonnull rsSet) {
        while ([rsSet next]) {
            total = [rsSet longLongIntForColumn:@"total"];
        }
        [rsSet close];
    }];
    return total;
}

- (MSIMConversation *)bf_component_conv:(FMResultSet *)rsSet
{
    MSIMConversation *conv = [[MSIMConversation alloc]init];
    conv.partner_id = [rsSet stringForColumn:@"f_id"];
    conv.chat_type = [rsSet intForColumn:@"chat_type"];
    conv.msg_end = [rsSet longLongIntForColumn:@"msg_end"];
    conv.show_msg_sign = [rsSet longLongIntForColumn:@"show_msg_sign"];
    conv.msg_last_read = [rsSet longLongIntForColumn:@"msg_last_read"];
    conv.unread_count = [rsSet intForColumn:@"unread_count"];
    conv.deleted = [rsSet intForColumn:@"status"];
    conv.draftText = [rsSet stringForColumn:@"draft"];
    conv.is_top = [rsSet intForColumn:@"is_top"];
    conv.time = [rsSet longLongIntForColumn:@"show_time"];
    NSString *extString = [rsSet stringForColumn:@"ext"];
    NSData *data = [extString dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
    conv.ext = [[MSCustomExt alloc]initWithDictionary:dic];
    return conv;
}

///更新会话的状态。status: 0 显示  1 不显示
- (BOOL)updateConvesationStatus:(NSInteger)status conv_id:(NSString *)conv_id
{
    if (![self tableExists:CONV_TABLE_NAME]) return NO;
    NSString *sqlString = [NSString stringWithFormat:@"UPDATE %@ set status = '%zd' WHERE conv_id = '%@'", CONV_TABLE_NAME,status, conv_id];
    BOOL ok = [self excuteSQL:sqlString];
    return ok;
}

///更新草稿
- (BOOL)updateDraft:(NSString *)text conv_id:(NSString *)conv_id
{
    if (![self tableExists:CONV_TABLE_NAME]) return NO;
    NSString *sqlString = [NSString stringWithFormat:@"UPDATE %@ set draft = '%@' WHERE conv_id = '%@'", CONV_TABLE_NAME,XMNoNilString(text), conv_id];
    BOOL ok = [self excuteSQL:sqlString];
    return ok;
}

@end
