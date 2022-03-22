//
//  MSDBConversationStore.h
//  BlackFireIM
//
//  Created by benny wang on 2021/3/3.
//

#import <MSIMSDK/MSDBBaseStore.h>
#import <MSIMSDK/MSIMConst.h>


NS_ASSUME_NONNULL_BEGIN

@class MSIMConversation;
@interface MSDBConversationStore : MSDBBaseStore

///批量添加会话记录
- (void)addConversations:(NSArray<MSIMConversation *> *)convs;

///更新会话记录未读数
- (BOOL)updateConvesation:(NSString *)conv_id unread_count:(NSInteger)count;

///查询所有的会话记录
- (NSArray<MSIMConversation *> *)allConvesations;

///查询某一条会话
- (nullable MSIMConversation *)searchConversation:(NSString *)conv_id;

/// 分页获取会话记录
- (void)conversationsWithLast_seq:(NSInteger)last_seq
                            count:(NSInteger)count
                         complete:(void(^)(NSArray<MSIMConversation *> *data,BOOL hasMore))complete;

///更新会话的状态。status: 0 显示  1 不显示
- (BOOL)updateConvesationStatus:(NSInteger)status conv_id:(NSString *)conv_id;

///更新草稿
- (BOOL)updateDraft:(NSString *)text conv_id:(NSString *)conv_id;

///所有未读数之和
- (NSInteger)allUnreadCount;

@end

NS_ASSUME_NONNULL_END
