//
//  MSIMManager+Conversation.h
//  BlackFireIM
//
//  Created by benny wang on 2021/3/8.
//

#import <MSIMSDK/MSIMManager.h>
#import <MSIMSDK/MSIMConversation.h>



NS_ASSUME_NONNULL_BEGIN


@interface MSIMManager (Conversation)


///每次建立长链接时，会自动触发跟服务器同步最新的会话列表信息
///该请求不会直接获取到会话列表，而是告知服务器：我需要从什么时间开始的会话列表。
///服务器会异步将该时间后的会话列表发送给客户端sdk，如果会话列表很长，服务器会分批次的发送
- (void)synchronizeConversationList;


/// 分页拉取会话列表
/// @param nextSeq 分页拉取游标，第一次默认取传 0，后续分页拉传上一次分页拉取回调里的 nextSeq
/// @param succ 拉取成功
/// @param fail 拉取失败
- (void)getConversationList:(NSInteger)nextSeq
                       succ:(nullable MSIMConversationListSucc)succ
                       fail:(nullable MSIMFail)fail;

///删除某一条会话
///删除会话只会删除会话记录，不会删除会话对应的聊天内容
- (void)deleteConversation:(MSIMConversation *)conv
                      succ:(MSIMSucc)succed
                    failed:(MSIMFail)failed;

///标记消息已读
- (void)markC2CMessageAsRead:(NSString *)user_id
                        succ:(MSIMSucc)succed
                      failed:(MSIMFail)failed;


///设置会话草稿
///只在本地保存，不会存储 Server，不能多端同步，程序卸载重装会失效。
- (void)setConversationDraft:(NSString *)user_id
                   draftText:(NSString *)text
                        succ:(nullable MSIMSucc)succed
                      failed:(nullable MSIMFail)failed;

@end

NS_ASSUME_NONNULL_END
