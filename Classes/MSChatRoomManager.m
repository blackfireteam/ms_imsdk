//
//  MSChatRoomManager.m
//  MSIMSDK
//
//  Created by benny wang on 2021/12/28.
//

#import "MSChatRoomManager.h"
#import "MSIMMessage.h"
#import "MSGroupInfo.h"
#import "MSIMTools.h"
#import "MSIMManagerListener.h"
#import "MSIMManager.h"
#import "MSChatRoomManager+Internal.h"

@interface MSChatRoomManager()

@property(nonatomic,strong) NSMutableArray<MSIMMessage *> *messages;

@property(nonatomic,assign) NSInteger unreadCount;

@end
@implementation MSChatRoomManager
@synthesize lastReadMsgID = _lastReadMsgID;


static MSChatRoomManager *_manager;
+ (instancetype)sharedInstance
{
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        _manager = [[MSChatRoomManager alloc]init];
    });
    return _manager;
}

- (instancetype)init
{
    if (self = [super init]) {
        _messages = [NSMutableArray array];
    }
    return self;
}

- (void)loginChatRoom:(NSInteger)chatRoom
{
    [MSIMTools sharedInstance].chatRoomID = chatRoom;
}

- (void)recieveMessages:(NSArray<MSIMMessage *> *)msgs
{
    @synchronized (self) {
        [self.messages insertObjects:msgs atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, msgs.count)]];
    }
    if ([MSIMManager.sharedInstance.chatRoomMsgListener respondsToSelector:@selector(onChatRoomConvUpdate)]) {
        [MSIMManager.sharedInstance.chatRoomMsgListener onChatRoomConvUpdate];
    }
}

- (void)onChatRoomMessageUpdate:(MSIMMessage *)message
{
    if (message.chatType != MSIM_CHAT_TYPE_CHATROOM) return;
    if (![message.groupID isEqualToString:self.chatroomInfo.room_id]) return;
    @synchronized (self) {
        for (NSInteger i = 0; i < self.messages.count; i++) {
            MSIMMessage *el = self.messages[i];
            if (el.msgSign == message.msgSign) {
                el = message;
            }
        }
    }
    if ([MSIMManager.sharedInstance.chatRoomMsgListener respondsToSelector:@selector(onChatRoomConvUpdate)]) {
        [MSIMManager.sharedInstance.chatRoomMsgListener onChatRoomConvUpdate];
    }
}

- (void)onDeleteMessages:(NSArray<NSNumber *> *)msg_ids
{
    @synchronized (self) {
        for (NSInteger i = 0; i < self.messages.count; i++) {
            MSIMMessage *el = self.messages[i];
            for (NSNumber *msgID in msg_ids) {
                if (msgID.integerValue == el.msgID) {
                    [self.messages removeObject:el];
                }
            }
        }
    }
    if ([MSIMManager.sharedInstance.chatRoomMsgListener respondsToSelector:@selector(onChatRoomConvUpdate)]) {
        [MSIMManager.sharedInstance.chatRoomMsgListener onChatRoomConvUpdate];
    }
}

- (MSIMMessage *)last_show_msg
{
    @synchronized (self) {
        for (NSInteger i = 0; i < self.messages.count; i++) {
            MSIMMessage *el = self.messages[i];
            if (el.type != MSIM_MSG_TYPE_CUSTOM_SIGNAL && el.type != MSIM_MSG_TYPE_NULL) {
                return el;
            }
        }
        return nil;
    }
}

- (void)setLastReadMsgID:(NSInteger)lastReadMsgID
{
    _lastReadMsgID = lastReadMsgID;
    NSString *user_id = [MSIMTools sharedInstance].user_id;
    NSInteger room_id = [MSIMTools sharedInstance].chatRoomID;
    if (user_id == nil || room_id == 0) return;
    NSString *key = [NSString stringWithFormat:@"%@-%zd_lastReadMsgID",user_id,room_id];
    [[NSUserDefaults standardUserDefaults] setInteger:lastReadMsgID forKey:key];
}

- (NSInteger)lastReadMsgID
{
    if (!_lastReadMsgID) {
        NSString *user_id = [MSIMTools sharedInstance].user_id;
        NSInteger room_id = [MSIMTools sharedInstance].chatRoomID;
        if (user_id == nil || room_id == 0) return 0;
        
        NSString *key = [NSString stringWithFormat:@"%@-%zd_lastReadMsgID",user_id,room_id];
        _lastReadMsgID = [[NSUserDefaults standardUserDefaults]integerForKey:key];
    }
    return _lastReadMsgID;
}

- (void)updateUnreadCountTo:(NSInteger)count
{
    _unreadCount = count;
    NSString *user_id = [MSIMTools sharedInstance].user_id;
    NSInteger room_id = [MSIMTools sharedInstance].chatRoomID;
    if (user_id == nil || room_id == 0) return;
    NSString *key = [NSString stringWithFormat:@"%@-%zd_unreadcount",user_id,room_id];
    [[NSUserDefaults standardUserDefaults] setInteger:count forKey:key];
    if ([MSIMManager.sharedInstance.chatRoomMsgListener respondsToSelector:@selector(onChatRoomConvUpdate)]) {
        [MSIMManager.sharedInstance.chatRoomMsgListener onChatRoomConvUpdate];
    }
}


/// 根据msg_id查找缓存的这条消息
- (nullable MSIMMessage *)searchMessageWithMsgID:(NSInteger)msg_id
{
    @synchronized (self) {
        for (MSIMMessage *message in self.messages) {
            if (message.msgID == msg_id) {
                return message;
            }
        }
        return nil;
    }
}

/// 删除缓存的某条消息
- (void)removeMessage:(MSIMMessage *)message
{
    @synchronized (self) {
        for (NSInteger i = 0; i < self.messages.count; i++) {
            MSIMMessage *msg = self.messages[i];
            if (msg.msgSign == message.msgSign) {
                [self.messages removeObject:msg];
                break;
            }
        }
    }
}

- (NSInteger)unreadCount
{
    if (!_unreadCount) {
        NSString *user_id = [MSIMTools sharedInstance].user_id;
        NSInteger room_id = [MSIMTools sharedInstance].chatRoomID;
        if (user_id == nil || room_id == 0) return 0;
        NSString *key = [NSString stringWithFormat:@"%@-%zd_unreadcount",user_id,room_id];
        _unreadCount = [[NSUserDefaults standardUserDefaults]integerForKey:key];
    }
    return _unreadCount;
}

- (void)cleanChatRoomCache
{
    [MSIMTools sharedInstance].chatRoomID = 0;
    _lastReadMsgID = 0;
    self.chatRoomLastMsgID = 0;
    self.chatroomInfo = nil;
    @synchronized (self) {
        [self.messages removeAllObjects];
    }
}


@end
