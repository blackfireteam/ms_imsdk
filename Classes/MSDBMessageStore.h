//
//  MSDBMessageStore.h
//  BlackFireIM
//
//  Created by benny wang on 2021/3/2.
//
/**
 消息存储实行分库分表制，每一个对话单独存一张表，表名规则：个人对话表名：message_user_123 群对话表名：message_group_123
 */
#import <MSIMSDK/MSDBBaseStore.h>
#import <MSIMSDK/MSIMMessage.h>


NS_ASSUME_NONNULL_BEGIN

@interface MSDBMessageStore : MSDBBaseStore

///向数据库中添加一条记录
- (void)addMessage:(MSIMMessage *)message;

///向数据库中添加批量记录
- (void)addMessages:(NSArray<MSIMMessage *> *)messages;

///将表中所有消息id <= last_msg_id标记为已读
- (BOOL)markMessageAsRead:(NSInteger)last_msg_id partnerID:(NSString *)partnerID;

///标记某一条消息为撤回消息
- (BOOL)updateMessageRevoke:(NSInteger)msg_id partnerID:(NSString *)partnerID;

///收到对阅后即焚消息已读的指令，将消息表中对应的消息标记为删除
- (BOOL)updateMessageSnapchat:(NSInteger)msg_id partnerID:(NSString *)partnerID;

///取最后一条msg_id
- (MSIMMessage *)lastMessageID:(NSString *)partner_id;

///取最后一条可显示的消息
- (MSIMMessage *)lastShowMessage:(NSString *)partner_id;

/// 分页获取聊天记录
/// @param partnerID 对方Uid
/// @param last_msg_sign 上一页的结束标记。
/// @param count 每页条数
/// @param complete 返回聊天记录数据
- (void)messageByPartnerID:(NSString *)partnerID
             last_msg_sign:(NSInteger)last_msg_sign
                     count:(NSInteger)count
                  complete:(void(^)(NSArray<MSIMMessage *> *data,BOOL hasMore))complete;


- (void)requestHistoryMessageFromEnd:(NSInteger)msgEnd toStart:(NSInteger)msgStart partner_Id:(NSString *)partner_id result:(void(^)(NSArray<MSIMMessage *> *messages))result;

///根据msg_id查询消息
- (MSIMMessage *)searchMessage:(NSString *)partner_id msg_id:(NSInteger)msg_id;

///根据msg_sign查询消息
- (MSIMMessage *)searchMessage:(NSString *)partner_id msg_sign:(NSInteger)msg_sign;

///本地删除消息
- (BOOL)deleteFromLocalWithMsg_sign:(NSInteger)msg_sign partner_id:(NSString *)partner_id;

@end

NS_ASSUME_NONNULL_END
