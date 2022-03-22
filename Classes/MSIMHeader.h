//
//  MSIMHeader.h
//  BlackFireIM
//
//  Created by benny wang on 2021/3/19.
//

#ifndef MSIMHeader_h
#define MSIMHeader_h

//IM网络连接状态通知
#define MSUIKitNotification_ConnListener @"MSUIKitNotification_ConnListener"
//用户登录状态通知
#define MSUIKitNotification_UserStatusListener @"MSUIKitNotification_UserStatusListener"

//会话列表有变更通知
#define MSUIKitNotification_ConversationUpdate @"MSUIKitNotification_ConversationUpdate"

//会话列表同步开始通知
#define MSUIKitNotification_ConversationSyncStart @"MSUIKitNotification_ConversationSyncStart"
//会话列表同步完成通知
#define MSUIKitNotification_ConversationSyncFinish @"MSUIKitNotification_ConversationSyncFinish"

//会话被删除时的通知
#define MSUIKitNotification_ConversationDelete @"MSUIKitNotification_ConversationDelete"

//有新消息通知
#define MSUIKitNotification_MessageListener @"MSUIKitNotification_MessageListener"

//有指令消息通知
#define MSUIKitNotification_SignalMessageListener @"MSUIKitNotification_SignalMessageListener"

//消息有变更通知
#define MSUIKitNotification_MessageUpdate @"MSUIKitNotification_MessageUpdate"

//收到对方消息已读的通知
#define MSUIKitNotification_MessageReceipt @"MSUIKitNotification_MessageReceipt"

//收到一条消息被删除的通知
#define MSUIKitNotification_MessageRecieveDelete @"MSUIKitNotification_MessageRecieveDelete"

//用户信息更新通知
#define MSUIKitNotification_ProfileUpdate @"MSUIKitNotification_ProfileUpdate"

//加入聊天室成功通知
#define MSUIKitNotification_EnterChatroom_success @"MSUIKitNotification_EnterChatroom_success"

//聊天室信息发生变化通知
#define MSUIKitNotification_ChatRoomConv_update @"MSUIKitNotification_ChatRoomConv_update"

//聊天室有新聊天室消息通知
#define MSUIKitNotification_ChatRoom_MessageListener @"MSUIKitNotification_ChatRoom_MessageListener"

//聊天室消息有变更通知
#define MSUIKitNotification_ChatRoom_MessageUpdate @"MSUIKitNotification_ChatRoom_MessageUpdate"

//收到聊天室公告的通知
#define MSUIKitNotification_ChatroomMessageRecieveTipsOfDay @"MSUIKitNotification_ChatroomMessageRecieveTipsOfDay"

//收到聊天室消息被删除的通知
#define MSUIKitNotification_ChatRoomMessageRecieveDelete @"MSUIKitNotification_ChatRoomMessageRecieveDelete"

//聊天室事件通知
#define MSUIKitNotification_ChatRoom_Event @"MSUIKitNotification_ChatRoom_Event"

//聊天室有人进入通知
#define MSUIKitNotification_ChatRoom_People_enter @"MSUIKitNotification_ChatRoom_People_enter"

//聊天室有人离开通知
#define MSUIKitNotification_ChatRoom_People_leave @"MSUIKitNotification_ChatRoom_People_leave"

#endif /* MSIMHeader_h */
