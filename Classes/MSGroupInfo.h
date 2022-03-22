//
//  MSChatRoomInfo.h
//  BlackFireIM
//
//  Created by benny wang on 2021/10/29.
//

#import <Foundation/Foundation.h>
#import <MSIMSDK/MSProfileInfo.h>


NS_ASSUME_NONNULL_BEGIN

@class MSGroupMemberItem;
@class MSGroupTipEvent;
@interface MSGroupInfo : NSObject

@property(nonatomic,assign) NSInteger gtype;

/** 聊天室id*/
@property(nonatomic,copy) NSString *room_id;

/** 聊天室名称 */
@property(nonatomic,copy) NSString *room_name;

/** 聊天室最大同时在线人数*/
@property(nonatomic,assign) NSInteger max_count;

/** 公告 只记录最近的一条*/
@property(nonatomic,copy,nullable) NSString *intro;

/** 是否全体禁言*/
@property(nonatomic,assign) BOOL is_mute;

/** 我是否具备修改tips of day（公告）的权限*/
@property(nonatomic,assign) BOOL action_tod;

/** 我是否具备禁言单人的权限*/
@property(nonatomic,assign) BOOL action_mute;

/** 我是否有关闭聊天室发言的权限*/
@property(nonatomic,assign) BOOL action_mute_all;

/** 我是否有权限删除消息*/
@property(nonatomic,assign) BOOL action_del_msg;

/** 我是否具备指派临时管理员的权限（管理员才有）*/
@property(nonatomic,assign) BOOL action_assign;

/** 在线的用户列表*/
@property(nonatomic,strong) NSMutableArray<MSGroupMemberItem *> *members;

/** 当前在线人数*/
@property(nonatomic,assign,readonly) NSInteger onlineCount;

@end

@interface MSGroupEvent: NSObject

/** 群类型  0 聊天室 1 群*/
@property(nonatomic,assign) NSInteger gtype;

/** 0 表示系统后台*/
@property(nonatomic,copy) NSString *from_uid;

/** 聊天室id*/
@property(nonatomic,copy) NSString *room_id;

/** 聊天室名称 */
@property(nonatomic,copy,nullable) NSString *room_name;

/** 聊天室最大同时在线人数*/
@property(nonatomic,assign) NSInteger max_count;

/** 是否全体禁言*/
@property(nonatomic,assign) BOOL is_mute;

/** 用户*/
@property(nonatomic,strong) NSArray<MSGroupMemberItem *> *members;

/** 操作原因（ 禁言 / 指派管理员等某些操作时可能附带该信息）*/
@property(nonatomic,copy,nullable) NSString *reason;

//0：聊天室被销毁（所有用户被迫离开聊天室）
//1：聊天室信息修改，（名称，容纳上限，是否全体禁言）
//2：用户状态变动 即 GroupMember 变动（包括用户上下线，禁言状态变动、角色变动）
//3：我的权限变动 （action属性全量重新刷新）
@property(nonatomic,assign) NSInteger eventType;

//提示性小字
@property(nonatomic,strong,nullable) MSGroupTipEvent *tips;

/** 我是否具备修改tips of day（公告）的权限*/
@property(nonatomic,assign) BOOL action_tod;

/** 我是否具备禁言单人的权限*/
@property(nonatomic,assign) BOOL action_mute;

/** 我是否有关闭聊天室发言的权限*/
@property(nonatomic,assign) BOOL action_mute_all;

/** 我是否有权限删除消息*/
@property(nonatomic,assign) BOOL action_del_msg;

/** 我是否具备指派临时管理员的权限（管理员才有）*/
@property(nonatomic,assign) BOOL action_assign;

@end

@interface MSGroupMemberItem: NSObject


@property(nonatomic,copy) NSString *uid;

/** 角色 0：普通用户  1、临时管理员  9：管理员   */
@property(nonatomic,assign) NSInteger role;

/** 是否被禁言*/
@property(nonatomic,assign) BOOL is_mute;

@property(nonatomic,strong,readonly,nullable) MSProfileInfo *profile;

@end

@interface MSGroupTipEvent: NSObject

//事件类型：
                    //1：聊天室已被解散
                    //2：聊天室属性已修改
                    //3：管理员 %s 将本聊天室设为听众模式
                    //4: 管理员 %s 恢复聊天室发言功能
                    //5：管理员 %s 上线
                    //6：管理员 %s 下线
                    //7: 管理员 %s 将用户 %s 禁言
                    //8: 管理员 %s 将用户 %s、%s 等人禁言
                    //9: %s 成为本聊天室管理员
                    //10: 管理员 %s 指派 %s 为临时管理员
                    //11：管理员 %s 指派 %s、%s 等人为临时管理员
@property(nonatomic,assign) NSInteger event;

//如果事件中有用户nick_name需要替换，此uid数组就是这些要替换的用户id（依次排序）
@property(nonatomic,strong) NSArray *uids;

@end


NS_ASSUME_NONNULL_END
