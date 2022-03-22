//
//  MSChatRoomManager+Internal.h
//  MSIMSDK
//
//  Created by benny wang on 2021/12/28.
//

#import "MSIMSDK.h"

NS_ASSUME_NONNULL_BEGIN

@interface MSChatRoomManager ()

/// 上次离开该聊天室之前收到的最后一条消息id
@property(nonatomic,assign) NSInteger chatRoomLastMsgID;

/// 记录上次已读的消息位置，用于计算未读数
@property(nonatomic,assign) NSInteger lastReadMsgID;

- (void)recieveMessages:(NSArray<MSIMMessage *> *)msgs;

- (void)onChatRoomMessageUpdate:(MSIMMessage *)message;

- (void)onDeleteMessages:(NSArray<NSNumber *> *)msg_ids;

- (void)cleanChatRoomCache;

- (void)updateUnreadCountTo:(NSInteger)count;

@end

NS_ASSUME_NONNULL_END
