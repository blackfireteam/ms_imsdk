//
//  MSIMConst.h
//  BlackFireIM
//
//  Created by benny wang on 2021/2/25.
//

#ifndef MSIMConst_h
#define MSIMConst_h

#define WS(weakSelf)  __weak __typeof(&*self)weakSelf = self;
#define STRONG_SELF(strongSelf) if (!weakSelf) return; \
__strong typeof(weakSelf) strongSelf = weakSelf;


#define XMNoNilString(str)  (str.length > 0 ? str : @"")

#define customLogEnable   [[[NSUserDefaults standardUserDefaults] valueForKey:@"kLogEnable"] boolValue]

#define MSLog(format, ...) if(customLogEnable) {\
NSLog(format, ## __VA_ARGS__);\
} else {}


/// 成功通用回调
typedef void (^MSIMSucc)(void);
/// 失败通用回调
typedef void (^MSIMFail)(NSInteger code, NSString * desc);


//**proto编码对应表**
typedef NS_ENUM(NSInteger, XMChatProtoType) {
    XMChatProtoTypeHeadBeat = 0,//向服务器发送心跳
    XMChatProtoTypeLogin = 1,//im登录
    XMChatProtoTypeLogout = 2,//im登出
    XMChatProtoTypeResult = 3,//返回结果
    XMChatProtoTypeSend = 4,//发送消息
    XMChatProtoTypeResponse = 5,//消息回执
    XMChatProtoTypeRecieve = 6,//接收消息
    XMChatProtoTypeMassRecieve = 7,//接收批量消息
    XMChatProtoTypeGetHistoryMsg = 8,//请求历史消息
    XMChatProtoTypeRecall = 9,//消息撤回
    XMChatProtoTypeMsgread = 10,//发送消息已读
    XMChatProtoTypeDeleteChat = 11,//删除某一会话
    XMChatProtoTypeGetChatList = 12,//拉会话记录
    XMChatProtoTypeChatListChanged = 14,//会话某些属性发生变更
    XMChatProtoTypeGetChatListResponse = 15,//会话记录结果
    XMChatProtoTypeGetProfile = 16,//请求用户信息
    XMChatProtoTypeGetProfiles = 17,//批量请求用户信息
    XMChatProtoTypeGetProfileResult = 18,//请求单个用户信息返回
    XMChatProtoTypeGetProfilesResult = 19,//请求批量用户信息返回
    
    XMChatProtoTypeRefreshPushToken = 21,//客户端更新push token
    XMChatProtoTypeGetCosToken = 22,//请求cos的临时证书
    XMChatProtoTypeCosTokenResponse = 23,//cos的临时证书结果
    XMChatProtoTypeGetAgoraToken = 24,//请求声网的临时token
    XMChatProtoTypeAgoraTokenResponse = 25,//声网的临时token结果
    
    XMChatProtoTypeJoinGroupRequest = 26,//申请加入群
    XMChatProtoTypeQuitGroupRequest = 27,//申请退出群
    XMChatProtoTypeGroupMemberInfo = 28,//群成员属性
    XMChatProtoTypeJoinGroupResult = 29,//申请加入群结果
    XMChatProtoTypeJoinGroupEvent = 30,//群事件
    
    XMChatProtoTypeSendGroupMsgRequest = 31,//发送群消息请求
    XMChatProtoTypeSendGroupMsgResponse = 32,//发送群消息回复
    XMChatProtoTypeRecieveGroupMsg = 33,//收到群消息
    XMChatProtoTypeRecieveGroupMsgBatch = 34,//收到群批量消息
    XMChatProtoTypeRecieveGroupProfilesRequest = 35,//获取群中用户的profile
    XMChatProtoTypeRecieveGroupManagerAction = 36,//群的管理操作
    XMChatProtoTypeGroupMessageRevoke = 37,//群消息撤回
    XMChatProtoTypeGroupTipEvent = 38,//群类显示的提示性事件小字，如果GroupEvent中，附带reason，在提示小字后面需加上reason
    XMChatProtoTypeChatActionRequest = 39,//发送指令消息

    
    XMChatProtoTypeProfileOnline = 50,//通知客户端用户上线事件
    XMChatProtoTypeProfileOffline = 52,//通知客户端用户下线事件
    XMChatProtoTypeSignup = 53,//注册新用户  for demo
    XMChatProtoTypeGetSpark = 54,//获取spark  for demo
    XMChatProtoTypeGetSparkResponse = 56,//获取spark结果  for demo
    CMChatProtoTypeGetImToken = 57,//获取用户token  for demo:
};

/** 消息发送状态*/
typedef NS_ENUM(NSInteger ,MSIMMessageStatus){
    
    MSIM_MSG_STATUS_SENDING = 0, //消息发送中
    
    MSIM_MSG_STATUS_SEND_SUCC = 1,//消息发送成功
    
    MSIM_MSG_STATUS_SEND_FAIL = 2,//消息发送失败
    
    MSIM_MSG_STATUS_HAS_DELETED = 3,//消息被删除
};

/** 聊天类型*/
typedef NS_ENUM(NSInteger ,MSIMAChatType){
    
    MSIM_CHAT_TYPE_C2C = 0, //单聊
    
    MSIM_CHAT_TYPE_CHATROOM = 1,//聊天室
};

/** 消息状态*/
typedef NS_ENUM(NSInteger ,MSIMMessageReadStatus){
    
    MSIM_MSG_STATUS_UNREAD = 0, //消息未读
    
    MSIM_MSG_STATUS_READ = 1,//消息已读
};

/** 消息类型*/
typedef NS_ENUM(NSInteger ,MSIMMessageType){
    
    MSIM_MSG_TYPE_UNKNOWN = -1, //未知消息
    
    MSIM_MSG_TYPE_TEXT = 0, //文本消息
    
    MSIM_MSG_TYPE_IMAGE = 1,//图片消息
    
    MSIM_MSG_TYPE_VOICE = 2,//音频消息
    
    MSIM_MSG_TYPE_VIDEO = 3,//视频消息
    
    MSIM_MSG_TYPE_LOCATION = 4,//位置消息
    
    MSIM_MSG_TYPE_USER_CARD = 5,//用户名片消息
    
    MSIM_MSG_TYPE_EMOTION = 6,//自定义表情
    
    MSIM_MSG_TYPE_REVOKE = 31,//撤回消息
    
    MSIM_MSG_TYPE_RECALL_ACTION = 64,//消息撤回指令
    
    MSIM_MSG_TYPE_DELETE = 67,//被删除消息（可能是阅后即焚已读后产生）
    
    MSIM_MSG_TYPE_SNAP_ACTION = 70,//阅后即焚指令
    
    MSIM_MSG_TYPE_CUSTOM_SIGNAL = 240,//自定义消息（不生成消息，仅作为信号传递）
    
    MSIM_MSG_TYPE_CUSTOM_IGNORE_UNREADCOUNT_RECALL  = 241,//自定义消息（不算计数 不可撤回 （可带push字段））
    
    MSIM_MSG_TYPE_CUSTOM_UNREADCOUNT_NO_RECALL = 243,//自定义消息（算计数 不可撤回 （可带push字段）））
    
    MSIM_MSG_TYPE_CUSTOM_UNREADCOUNT_RECAL = 247,//自定义消息（算计数 可撤回 （可带push字段））
    
    MSIM_MSG_TYPE_NULL = 999,//空消息，用于占位
};

/** 网络连接状态*/
typedef NS_ENUM(NSUInteger, MSIMNetStatus) {
    IMNET_STATUS_SUCC = 1,    //连接成功
    IMNET_STATUS_CONNECTING,  //正在连接
    IMNET_STATUS_CONNFAILED,  //连接失败
    IMNET_STATUS_DISCONNECT,  //断开连接
};

/** 用户在线状态*/
typedef NS_ENUM(NSUInteger, MSIMUserStatus) {
    IMUSER_STATUS_UNLOGIN = 0,   //用户未登录
    IMUSER_STATUS_LOGIN,         //用户已登录
    IMUSER_STATUS_FORCEOFFLINE,  //用户被强制下线
    IMUSER_STATUS_SIGEXPIRED,    //用户身份（usersig）过期
};

/** 自定义消息配置*/
typedef NS_ENUM(NSUInteger, MSIMCustomOption) {
    IMCUSTOM_SIGNAL = 240,                     //指令类型，不会产生消息,在线时才会收到。如：xxx正在输入。。。
    IMCUSTOM_IGNORE_UNREADCOUNT_RECALL = 241,  //不计入未读数，不可撤回。
    IMCUSTOM_UNREADCOUNT_NO_RECALL = 243,      //计入未读数，不可撤回。
    IMCUSTOM_UNREADCOUNT_RECALL = 247,         //计入未读数，也可撤回。
};

#define kApnsTokenKey @"ms_device_token"
#define kVoipTokenKey @"ms_voip_token"

#endif /* MSIMConst_h */

