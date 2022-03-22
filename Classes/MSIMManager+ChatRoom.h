//
//  MSIMManager+ChatRoom.h
//  MSIMSDK
//
//  Created by benny wang on 2021/10/28.
//

#import <MSIMSDK/MSIMManager.h>
#import <MSIMSDK/MSGroupInfo.h>


NS_ASSUME_NONNULL_BEGIN


@interface MSIMManager (ChatRoom)

/// 申请加入聊天室
- (void)joinInChatRoom:(NSInteger)room_id
                  succ:(void (^)(MSGroupInfo *info))succed
                failed:(MSIMFail)failed;

/// 退出聊天室
- (void)quitChatRoom:(NSInteger)room_id
                succ:(MSIMSucc)succed
              failed:(MSIMFail)failed;


/// 发送聊天室消息
/// @param message 消息体
/// @param room_id 聊天室id
/// @param success 发送成功，返回消息的唯一标识ID
/// @param failed 发送失败
- (void)sendChatRoomMessage:(MSIMMessage *)message
                   toRoomID:(NSString *)room_id
                  successed:(void(^)(NSInteger msg_id))success
                     failed:(MSIMFail)failed;

/// 聊天室消息重发
/// @param message 消息体
/// @param room_id 聊天室id
/// @param success 发送成功，返回消息的唯一标识ID
/// @param failed 发送失败
- (void)resendChatRoomMessage:(MSIMMessage *)message
                     toRoomID:(NSString *)room_id
                    successed:(void(^)(NSInteger msg_id))success
                       failed:(MSIMFail)failed;

/// 聊天室中请求撤回某一条消息
/// @param room_id 聊天室id
/// @param msg_id 消息的唯一ID
/// @param success 撤回成功
/// @param failed 撤回失败
- (void)chatRoomRevokeMessage:(NSInteger)msg_id
                   fromRoomID:(NSString *)room_id
                    successed:(MSIMSucc)success
                       failed:(MSIMFail)failed;

///标记消息已读
///last_msg_id 标记这个消息id之前的消息都为已读
- (void)markChatRoomMessageAsRead:(NSInteger)last_msg_id
                             succ:(MSIMSucc)succed
                           failed:(MSIMFail)failed;

/// 聊天室所有的群成员
/// @param room_id 聊天室id
/// @param success 发送成功，返回群成员列表
/// @param failed 发送失败
- (void)chatRoomMembers:(NSInteger)room_id
              successed:(void(^)(NSArray<MSGroupMemberItem *> *))success
                 failed:(MSIMFail)failed;

/// 修改聊天室公告 （管理员权限）
/// tod 公告内容
/// room_id 房间id
/// 发送成功
/// 发送失败
- (void)editChatRoomTOD:(NSString *)tod
              toRoom_id:(NSString *)room_id
              successed:(MSIMSucc)success
                 failed:(MSIMFail)failed;

/// 全聊天室禁言 或 取消禁言（管理员权限）
/// is_mute 禁言 或 恢复发言
/// room_id 房间id
/// duration //0：10分钟  1：30分钟  2：1小时  3：24小时  4：1周
/// 发送成功
/// 发送失败
- (void)muteChatRoom:(BOOL)is_mute
           toRoom_id:(NSString *)room_id
            duration:(NSInteger)duration
           successed:(MSIMSucc)success
              failed:(MSIMFail)failed;


/// 只对一批在线用户禁言或恢复发言（管理员权限）
/// room_id 房间id
/// uids  待处理的用户uid
/// duration //0：10分钟  1：30分钟  2：1小时  3：24小时  4：1周
/// reason  操作原因 （可选）
/// 发送成功
/// 发送失败
- (void)muteMembers:(NSString *)room_id
               uids:(NSArray<NSNumber *> *)uids
           duration:(NSInteger)duration
             reason:(nullable NSString *)reason
          successed:(MSIMSucc)success
             failed:(MSIMFail)failed;


/// 任命/解除临时管理员（管理员权限）
/// room_id 房间id
/// uids  待处理的用户uid  一次性最多100条
/// duration //0：10分钟  1：30分钟  2：1小时  3：24小时  4：1周
/// reason  操作原因 （可选）
/// 发送成功
/// 发送失败
- (void)editChatroomManagerAccess:(NSString *)room_id
                             uids:(NSArray<NSNumber *> *)uids
                         duration:(NSInteger)duration
                           reason:(nullable NSString *)reason
                        successed:(MSIMSucc)success
                           failed:(MSIMFail)failed;


/// 批量删除消息（管理员权限）
/// room_id 房间id
/// msg_ids  待删除的消息id  一次性最多100条
/// 发送成功
/// 发送失败
- (void)deleteChatroomMsgs:(NSString *)room_id
                    msgIDs:(NSArray<NSNumber *> *)msgIDs
                 successed:(MSIMSucc)success
                    failed:(MSIMFail)failed;


@end

NS_ASSUME_NONNULL_END
