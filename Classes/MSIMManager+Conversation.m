//
//  MSIMManager+Conversation.m
//  BlackFireIM
//
//  Created by benny wang on 2021/3/8.
//

#import "MSIMManager+Conversation.h"
#import "MSIMTools.h"
#import "MSIMConst.h"
#import "MSIMErrorCode.h"
#import "MSProfileProvider.h"
#import "MSConversationProvider.h"
#import "MSIMManager+Parse.h"
#import "ChatProtobuf.pbobjc.h"
#import "MSIMManager+Internal.h"


@implementation MSIMManager (Conversation)

- (void)synchronizeConversationList
{
    self.isChatListResult = NO;
    if (self.convListener && [self.convListener respondsToSelector:@selector(onSyncServerStart)]) {
        [self.convListener onSyncServerStart];
    }
    GetChatList *request = [[GetChatList alloc]init];
    request.sign = [MSIMTools sharedInstance].adjustLocalTimeInterval;
    request.updateTime = [MSIMTools sharedInstance].convUpdateTime;
    WS(weakSelf)
    MSLog(@"[发送消息]同步会话列表：%@",request);
    [self.socket send:[request data] protoType:XMChatProtoTypeGetChatList needToEncry:NO sign:request.sign callback:^(NSInteger code, id  _Nullable response, NSString * _Nullable error) {
        STRONG_SELF(strongSelf)
        if (code == ERR_CHAT_LIST_EMPTY) {//如果用户一条会话都没有时，服务器会通过result直接返回错误码
            strongSelf.isChatListResult = YES;
            if (strongSelf.convListener && [strongSelf.convListener respondsToSelector:@selector(onSyncServerFinish)]) {
                [strongSelf.convListener onSyncServerFinish];
            }
            //顺便同步下自己的Profile
            MSProfileInfo *me = [[MSProfileProvider provider]providerProfileFromLocal:[MSIMTools sharedInstance].user_id];
            if (!me) {
                me = [[MSProfileInfo alloc]init];
                me.user_id = [MSIMTools sharedInstance].user_id;
            }
            [[MSProfileProvider provider] synchronizeProfiles:@[me].mutableCopy];
        }else if (code == ERR_SUCC){
        }else {
            MSLog(@"建立链接与服务器同步会话列表失败.%@", error);
            if (strongSelf.convListener && [strongSelf.convListener respondsToSelector:@selector(onSyncServerFailed)]) {
                [strongSelf.convListener onSyncServerFailed];
            }
        }
    }];
}

/// 分页拉取会话列表
/// @param nextSeq 分页拉取游标，第一次默认取传 0，后续分页拉传上一次分页拉取回调里的 nextSeq
/// @param succ 拉取成功
/// @param fail 拉取失败
- (void)getConversationList:(NSInteger)nextSeq
                       succ:(nullable MSIMConversationListSucc)succ
                       fail:(nullable MSIMFail)fail
{
    NSInteger count = [MSIMManager sharedInstance].socket.config.chatListPageCount;
    if (nextSeq < 0 || count <= 0) {
        if (fail) fail(ERR_USER_PARAMS_ERROR,@"getConversationList params error");
        return;
    }
    NSString *isNotFirstConvFinishKey = [NSString stringWithFormat:@"isNotFirstConvFinish_%@",MSIMTools.sharedInstance.user_id];
    BOOL isNotFirstConvFinish = [[NSUserDefaults standardUserDefaults]boolForKey:isNotFirstConvFinishKey];
    if (isNotFirstConvFinish == NO && self.isChatListResult == NO) {
        return;
    }
    WS(weakSelf)
    [self.convStore conversationsWithLast_seq:nextSeq count:count complete:^(NSArray<MSIMConversation *> * _Nonnull data, BOOL hasMore) {
        //组装最后一条消息和头像昵称等信息
        NSMutableArray *tempConvs = [NSMutableArray array];
        NSMutableArray *tempProfiles = [NSMutableArray array];
        for (MSIMConversation *conv in data) {
            MSIMMessage *message = [weakSelf.messageStore searchMessage:conv.partner_id msg_sign:conv.show_msg_sign];
            conv.show_msg = message;
            if (message == nil) {
                [tempConvs addObject:conv];
            }
            MSProfileInfo *info = [[MSProfileProvider provider]providerProfileFromLocal:conv.partner_id];
            if (info == nil || info.update_time == 0) {
                info = [[MSProfileInfo alloc]init];
                info.user_id = conv.partner_id;
                [tempProfiles addObject:info];
            }
        }
        [[MSConversationProvider provider]updateConversations:data];
        [self updateConvLastMessage:tempConvs];
        [[MSProfileProvider provider]synchronizeProfiles:tempProfiles];
        MSIMConversation *lastConv = data.lastObject;
        NSInteger nextSign = lastConv.time;
        succ(data,nextSign,hasMore ? NO : YES);
    }];
}

///删除某一条会话
///只更改会话的状态，不会真正的删除会话，也不会删除会话对应的聊天内容
- (void)deleteConversation:(MSIMConversation *)conv
                      succ:(MSIMSucc)succed
                    failed:(MSIMFail)failed
{
    if (conv == nil) {
        failed(ERR_USER_PARAMS_ERROR,@"deleteConversation params error");
        return;
    }
    DelChat *delRequest = [[DelChat alloc]init];
    delRequest.sign = [MSIMTools sharedInstance].adjustLocalTimeInterval;
    delRequest.toUid = conv.partner_id.integerValue;
    MSLog(@"[发送消息]删除会话：%@",delRequest);
    [self.socket send:[delRequest data] protoType:XMChatProtoTypeDeleteChat needToEncry:NO sign:delRequest.sign callback:^(NSInteger code, id  _Nullable response, NSString * _Nullable error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (code == ERR_SUCC) {
                succed();
            }else {
                failed(ERR_SDK_DB_DEL_CONVERSATION_FAIL,error);
            }
        });
    }];
}

///标记消息已读
- (void)markC2CMessageAsRead:(NSString *)user_id
                        succ:(MSIMSucc)succed
                      failed:(MSIMFail)failed
{
    if (user_id.length == 0) {
        failed(ERR_USER_PARAMS_ERROR,@"markC2CMessageAsRead params error");
        return;
    }
    MSIMConversation *conv = [[MSConversationProvider provider]providerConversation:user_id];
    if (conv && conv.unread_count) {
        conv.unread_count = 0;
        conv.show_msg.readStatus = MSIM_MSG_STATUS_READ;
        [[MSConversationProvider provider]updateConversations:@[conv]];
        if (self.convListener && [self.convListener respondsToSelector:@selector(onUpdateConversations:)]) {
            [self.convListener onUpdateConversations:@[conv]];
        }
        MsgRead *request = [[MsgRead alloc]init];
        request.sign = [MSIMTools sharedInstance].adjustLocalTimeInterval;
        request.toUid = user_id.integerValue;
        MSLog(@"[发送消息]标记消息已读：%@",request);
        [self.socket send:[request data] protoType:XMChatProtoTypeMsgread needToEncry:NO sign:request.sign callback:^(NSInteger code, id  _Nullable response, NSString * _Nullable error) {
            
        }];
    }
}

///设置会话草稿
///只在本地保存，不会存储 Server，不能多端同步，程序卸载重装会失效。
- (void)setConversationDraft:(NSString *)user_id
                   draftText:(NSString *)text
                        succ:(nullable MSIMSucc)succed
                      failed:(nullable MSIMFail)failed
{
    if (user_id.length == 0) {
        if (failed) failed(ERR_USER_PARAMS_ERROR,@"setConversationDraft params error");
        return;
    }
    MSIMConversation *conv = [[MSConversationProvider provider]providerConversation:user_id];
    if (conv == nil && text.length == 0) {
        return;
    }
    if (conv == nil) {
        conv = [[MSIMConversation alloc]init];
        conv.chat_type = MSIM_CHAT_TYPE_C2C;
        conv.partner_id = user_id;
    }
    conv.draftText = text;
    if (text.length == 0 && conv.show_msg_sign > 0) {
        conv.time = conv.show_msg_sign;
    }else {
        conv.time = [MSIMTools sharedInstance].adjustLocalTimeInterval;
    }
    [[MSConversationProvider provider]updateConversations:@[conv]];
    [self.convListener onUpdateConversations:@[conv]];
    if (succed) succed();
}

@end
