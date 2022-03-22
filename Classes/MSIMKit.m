//
//  MSIMKit.m
//  BlackFireIM
//
//  Created by benny wang on 2021/3/19.
//

#import "MSIMKit.h"
#import "MSIMSDK.h"


@interface MSIMKit()<MSIMMessageListener,MSIMProfileListener,MSIMConversationListener,MSIMSDKListener,MSIMChatRoomMessageListener>


@end
@implementation MSIMKit

+ (instancetype)sharedInstance
{
    static MSIMKit *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[MSIMKit alloc] init];
    });
    return instance;
}

- (void)initWithConfig:(IMSDKConfig *)config
{
    [[MSIMManager sharedInstance] initSDK:config listener:self];
    [MSIMManager sharedInstance].msgListener = self;
    [MSIMManager sharedInstance].connListener = self;
    [MSIMManager sharedInstance].convListener = self;
    [MSIMManager sharedInstance].profileListener = self;
    [MSIMManager sharedInstance].chatRoomMsgListener = self;
    [MSIMManager sharedInstance].uploadMediator = config.uploadMediator;
}


#pragma mark - MSIMSDKListener
/// 网络连接成功
- (void)connectSucc
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:MSUIKitNotification_ConnListener object:[NSNumber numberWithInt:IMNET_STATUS_SUCC]];
    });
}

/// 网络连接失败
- (void)connectFailed:(NSInteger)code err:(NSString *)errString
{
    dispatch_async(dispatch_get_main_queue(), ^{
        MSIMNetStatus status = (code == ERR_NET_NOT_CONNECT ? IMNET_STATUS_DISCONNECT : IMNET_STATUS_CONNFAILED);
        [[NSNotificationCenter defaultCenter] postNotificationName:MSUIKitNotification_ConnListener object:@(status) userInfo:@{@"code": @(code),@"desc": XMNoNilString(errString)}];
    });
}

/// 连接中
- (void)onConnecting
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:MSUIKitNotification_ConnListener object:[NSNumber numberWithInt:IMNET_STATUS_CONNECTING]];
    });
}

/**
 *  踢下线通知
 */
- (void)onForceOffline
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:MSUIKitNotification_UserStatusListener object:[NSNumber numberWithInt:IMUSER_STATUS_FORCEOFFLINE]];
    });
}

/**
 *  用户登录的userSig过期（用户需要重新获取userSig后登录）
 */
- (void)onUserSigExpired
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:MSUIKitNotification_UserStatusListener object:[NSNumber numberWithInt:IMUSER_STATUS_SIGEXPIRED]];
    });
}

#pragma mark - MSIMConversationListener

/**
 * 同步服务器会话开始，SDK 会在登录成功或者断网重连后自动同步服务器会话，您可以监听这个事件做一些 UI 进度展示操作。
 */
- (void)onSyncServerStart
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:MSUIKitNotification_ConversationSyncStart object:nil];
    });
}

/**
 * 同步服务器会话完成，如果会话有变更，会通过 onNewConversation | onConversationChanged 回调告知客户
 */
- (void)onSyncServerFinish
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:MSUIKitNotification_ConversationSyncFinish object:nil];
    });
}

/**
 * 同步服务器会话失败
 */
- (void)onSyncServerFailed
{
    ///
}

///新增会话或会话发生变化
- (void)onUpdateConversations:(NSArray<MSIMConversation*> *) conversationList
{
    //将被删除的会话过滤
    NSMutableArray *arr = [NSMutableArray array];
    for (MSIMConversation *conv in conversationList) {
        if (!conv.deleted) {
            [arr addObject:conv];
        }
    }
    if (arr.count > 0) {
        [[NSNotificationCenter defaultCenter] postNotificationName:MSUIKitNotification_ConversationUpdate object:arr];
    }
}

///会话被删除时
- (void)conversationDidDelete:(NSString *)partner_id
{
    [[NSNotificationCenter defaultCenter] postNotificationName:MSUIKitNotification_ConversationDelete object:partner_id];
}

#pragma mark - MSIMMessageListener

/// 收到新消息(信令消息除外)
- (void)onNewMessages:(NSArray<MSIMMessage *> *)msgs
{
    [[NSNotificationCenter defaultCenter] postNotificationName:MSUIKitNotification_MessageListener object:msgs];
}

/// 收到信令消息
- (void)onRecieveSignalMessages:(NSArray<MSIMMessage *> *)msgs
{
    [[NSNotificationCenter defaultCenter] postNotificationName:MSUIKitNotification_SignalMessageListener object:msgs];
}

/// 收到删除的消息
- (void)onDeleteMessages:(NSArray<NSNumber *> *)msg_ids
{
    [[NSNotificationCenter defaultCenter] postNotificationName:MSUIKitNotification_MessageRecieveDelete object:msg_ids];
}

/**
 *  消息发生变化通知（包括发送状态，撤回等等）
 */
- (void)onMessageUpdate:(MSIMMessage *)message
{
    [[NSNotificationCenter defaultCenter] postNotificationName:MSUIKitNotification_MessageUpdate object:message];
}

///收到消息已读回执（仅单聊有效）
- (void)onRecvC2CReadReceipt:(MSIMMessageReceipt *)receipt
{
    [[NSNotificationCenter defaultCenter] postNotificationName:MSUIKitNotification_MessageReceipt object:receipt];
}

#pragma mark - MSIMProfileListener

/**
 *  用户头像昵称等修改通知
 */
- (void)onProfileUpdates:(NSArray<MSProfileInfo *> *)infos
{
    [[NSNotificationCenter defaultCenter] postNotificationName:MSUIKitNotification_ProfileUpdate object:infos];
}

#pragma mark - MSIMChatRoomMessageListener

/// 加入聊天室成功通知
- (void)onEnterChatRoomSuccess
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:MSUIKitNotification_EnterChatroom_success object:nil];
    });
}

///聊天室在会话中展示的信息发生变化通知
- (void)onChatRoomConvUpdate
{
    [[NSNotificationCenter defaultCenter] postNotificationName:MSUIKitNotification_ChatRoomConv_update object:nil];
}

/// 收到新消息(信令消息除外)
- (void)onNewChatRoomMessages:(NSArray<MSIMMessage *> *)msgs
{
    [[NSNotificationCenter defaultCenter] postNotificationName:MSUIKitNotification_ChatRoom_MessageListener object:msgs];
}

/// 收到删除的消息
- (void)onChatRoomDeleteMessages:(NSArray<NSNumber *> *)msg_ids
{
    [[NSNotificationCenter defaultCenter] postNotificationName:MSUIKitNotification_ChatRoomMessageRecieveDelete object:msg_ids];
}

/// 消息发送状态发生变化通知
- (void)onChatRoomMessageUpdate:(MSIMMessage *)message
{
    [[NSNotificationCenter defaultCenter] postNotificationName:MSUIKitNotification_ChatRoom_MessageUpdate object:message];
}

/// 聊天室事件通知
- (void)onNewChatRoomEvent:(MSGroupEvent *)event
{
    [[NSNotificationCenter defaultCenter] postNotificationName:MSUIKitNotification_ChatRoom_Event object:event];
}

/// 有人进入聊天室通知
- (void)onPeopleJoinInChatRoom:(MSGroupMemberItem *)member
{
    [[NSNotificationCenter defaultCenter] postNotificationName:MSUIKitNotification_ChatRoom_People_enter object:member];
}

/// 有人退出了聊天室通知
- (void)onPeopleQuitChatRoom:(NSString *)uid
{
    [[NSNotificationCenter defaultCenter] postNotificationName:MSUIKitNotification_ChatRoom_People_leave object:uid];
}

/// 收到新的聊天室公告
- (void)onNewChatRoomTipsOfDay:(NSString *)text
{
    [[NSNotificationCenter defaultCenter] postNotificationName:MSUIKitNotification_ChatroomMessageRecieveTipsOfDay object:text];
}

@end
