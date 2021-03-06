// Generated by the protocol buffer compiler.  DO NOT EDIT!
// source: chatProtobuf.proto

// This CPP symbol can be defined to use imports that match up to the framework
// imports needed when using CocoaPods.
#if !defined(GPB_USE_PROTOBUF_FRAMEWORK_IMPORTS)
 #define GPB_USE_PROTOBUF_FRAMEWORK_IMPORTS 0
#endif

#if GPB_USE_PROTOBUF_FRAMEWORK_IMPORTS
 #import <Protobuf/GPBProtocolBuffers.h>
#else
 #import "GPBProtocolBuffers.h"
#endif

#if GOOGLE_PROTOBUF_OBJC_VERSION < 30004
#error This file was generated by a newer version of protoc which is incompatible with your Protocol Buffer library sources.
#endif
#if 30004 < GOOGLE_PROTOBUF_OBJC_MIN_SUPPORTED_VERSION
#error This file was generated by an older version of protoc which is incompatible with your Protocol Buffer library sources.
#endif

// @@protoc_insertion_point(imports)

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

CF_EXTERN_C_BEGIN

@class ChatItem;
@class ChatR;
@class GetProfile;
@class GroupChatR;
@class GroupMember;
@class GroupTipEvent;
@class Profile;

NS_ASSUME_NONNULL_BEGIN

#pragma mark - ChatProtobufRoot

/**
 * Exposes the extension registry for this file.
 *
 * The base class provides:
 * @code
 *   + (GPBExtensionRegistry *)extensionRegistry;
 * @endcode
 * which is a @c GPBExtensionRegistry that includes all the extensions defined by
 * this file and all files that it depends on.
 **/
GPB_FINAL @interface ChatProtobufRoot : GPBRootObject
@end

#pragma mark - Ping

typedef GPB_ENUM(Ping_FieldNumber) {
  Ping_FieldNumber_Type = 1,
};

/**
 * 0
 **/
GPB_FINAL @interface Ping : GPBMessage

@property(nonatomic, readwrite) int64_t type;

@end

#pragma mark - ImLogin

typedef GPB_ENUM(ImLogin_FieldNumber) {
  ImLogin_FieldNumber_Sign = 1,
  ImLogin_FieldNumber_Token = 2,
  ImLogin_FieldNumber_Ct = 3,
  ImLogin_FieldNumber_SubApp = 4,
  ImLogin_FieldNumber_PushChannel = 5,
  ImLogin_FieldNumber_PushToken = 6,
  ImLogin_FieldNumber_LastToken = 7,
};

/**
 * 1
 **/
GPB_FINAL @interface ImLogin : GPBMessage

@property(nonatomic, readwrite) int64_t sign;

/** 从应用方获取的imtoken */
@property(nonatomic, readwrite, copy, null_resettable) NSString *token;

/** 客户端类型 0:Android   1:ios    2:web */
@property(nonatomic, readwrite) int64_t ct;

/** 子应用id */
@property(nonatomic, readwrite) int64_t subApp;

/** 子应用的推送渠道 1 apns  2 fcm */
@property(nonatomic, readwrite) int64_t pushChannel;

/** push token */
@property(nonatomic, readwrite, copy, null_resettable) NSString *pushToken;

/** 本机上一次登录成功的token，用于处理未正常退出登录的情况。如果本次token和上次token一致，或者本机确定上次退出登录成功，就不传。 */
@property(nonatomic, readwrite, copy, null_resettable) NSString *lastToken;

@end

#pragma mark - ImLogout

typedef GPB_ENUM(ImLogout_FieldNumber) {
  ImLogout_FieldNumber_Sign = 1,
};

/**
 * 2
 **/
GPB_FINAL @interface ImLogout : GPBMessage

@property(nonatomic, readwrite) int64_t sign;

@end

#pragma mark - Result

typedef GPB_ENUM(Result_FieldNumber) {
  Result_FieldNumber_Sign = 1,
  Result_FieldNumber_Code = 2,
  Result_FieldNumber_Msg = 3,
  Result_FieldNumber_NowTime = 4,
  Result_FieldNumber_Uid = 5,
};

/**
 * 3
 **/
GPB_FINAL @interface Result : GPBMessage

/** 信息标示，原路返回 */
@property(nonatomic, readwrite) int64_t sign;

@property(nonatomic, readwrite) int64_t code;

@property(nonatomic, readwrite, copy, null_resettable) NSString *msg;

/** 当前服务器时间戳(精确到秒) */
@property(nonatomic, readwrite) int64_t nowTime;

/** 鉴权时返回的uid */
@property(nonatomic, readwrite) int64_t uid;

@end

#pragma mark - ChatS

typedef GPB_ENUM(ChatS_FieldNumber) {
  ChatS_FieldNumber_Sign = 1,
  ChatS_FieldNumber_Type = 2,
  ChatS_FieldNumber_ToUid = 3,
  ChatS_FieldNumber_Title = 4,
  ChatS_FieldNumber_Body = 5,
  ChatS_FieldNumber_Thumb = 6,
  ChatS_FieldNumber_Width = 7,
  ChatS_FieldNumber_Height = 8,
  ChatS_FieldNumber_Duration = 9,
  ChatS_FieldNumber_Lat = 10,
  ChatS_FieldNumber_Lng = 11,
  ChatS_FieldNumber_Zoom = 12,
  ChatS_FieldNumber_PushTitle = 13,
  ChatS_FieldNumber_PushBody = 14,
  ChatS_FieldNumber_PushSound = 15,
  ChatS_FieldNumber_Flash = 16,
};

/**
 * 4
 **/
GPB_FINAL @interface ChatS : GPBMessage

/** 客户端自定义标识，服务器会原样返回 */
@property(nonatomic, readwrite) int64_t sign;

/** 消息类型 */
@property(nonatomic, readwrite) int64_t type;

/** 发送给谁 */
@property(nonatomic, readwrite) int64_t toUid;

/** 消息内容 */
@property(nonatomic, readwrite, copy, null_resettable) NSString *title;

/** 消息内容 */
@property(nonatomic, readwrite, copy, null_resettable) NSString *body;

/** 封面图 */
@property(nonatomic, readwrite, copy, null_resettable) NSString *thumb;

/** 封面图的宽度 */
@property(nonatomic, readwrite) int64_t width;

/** 封面图的高度 */
@property(nonatomic, readwrite) int64_t height;

/** 时长 */
@property(nonatomic, readwrite) int64_t duration;

/** 纬度 */
@property(nonatomic, readwrite) double lat;

/** 经度 */
@property(nonatomic, readwrite) double lng;

/** 地图缩放层级 */
@property(nonatomic, readwrite) int64_t zoom;

/** 当type为240、241、243、247 时，可以自定义推送的内容 */
@property(nonatomic, readwrite, copy, null_resettable) NSString *pushTitle;

/** 当type为240、241、243、247 时，可以自定义推送的内容 */
@property(nonatomic, readwrite, copy, null_resettable) NSString *pushBody;

/** 当type为240、241、243、247 时，可以自定义推送的内容 */
@property(nonatomic, readwrite, copy, null_resettable) NSString *pushSound;

/** 是否是阅后即焚，默认为false */
@property(nonatomic, readwrite) BOOL flash;

@end

#pragma mark - ChatSR

typedef GPB_ENUM(ChatSR_FieldNumber) {
  ChatSR_FieldNumber_Sign = 1,
  ChatSR_FieldNumber_MsgId = 2,
  ChatSR_FieldNumber_MsgTime = 3,
};

/**
 * 5
 **/
GPB_FINAL @interface ChatSR : GPBMessage

/** 信息标示，原路返回 */
@property(nonatomic, readwrite) int64_t sign;

/** 消息id */
@property(nonatomic, readwrite) int64_t msgId;

@property(nonatomic, readwrite) int64_t msgTime;

@end

#pragma mark - ChatR

typedef GPB_ENUM(ChatR_FieldNumber) {
  ChatR_FieldNumber_Sign = 1,
  ChatR_FieldNumber_FromUid = 2,
  ChatR_FieldNumber_ToUid = 3,
  ChatR_FieldNumber_MsgId = 4,
  ChatR_FieldNumber_MsgTime = 5,
  ChatR_FieldNumber_Sput = 6,
  ChatR_FieldNumber_Type = 8,
  ChatR_FieldNumber_Title = 9,
  ChatR_FieldNumber_Body = 10,
  ChatR_FieldNumber_Thumb = 11,
  ChatR_FieldNumber_Width = 12,
  ChatR_FieldNumber_Height = 13,
  ChatR_FieldNumber_Duration = 14,
  ChatR_FieldNumber_Lat = 15,
  ChatR_FieldNumber_Lng = 16,
  ChatR_FieldNumber_Zoom = 17,
  ChatR_FieldNumber_PushTitle = 18,
  ChatR_FieldNumber_PushBody = 19,
  ChatR_FieldNumber_PushSound = 20,
  ChatR_FieldNumber_Flash = 21,
};

/**
 * 6
 **/
GPB_FINAL @interface ChatR : GPBMessage

@property(nonatomic, readwrite) int64_t sign;

/** 谁发的 */
@property(nonatomic, readwrite) int64_t fromUid;

/** 发给谁 */
@property(nonatomic, readwrite) int64_t toUid;

/** 消息id */
@property(nonatomic, readwrite) int64_t msgId;

/** 消息时间（以服务器为准 精确到百万分之一秒的时间戳） */
@property(nonatomic, readwrite) int64_t msgTime;

/** sender_profile_update_time 发送人的profile更新时间（精确到秒的时间戳） */
@property(nonatomic, readwrite) int64_t sput;

/** 消息类型 */
@property(nonatomic, readwrite) int64_t type;

/** 消息内容 */
@property(nonatomic, readwrite, copy, null_resettable) NSString *title;

/** 消息内容 */
@property(nonatomic, readwrite, copy, null_resettable) NSString *body;

/** 封面图 */
@property(nonatomic, readwrite, copy, null_resettable) NSString *thumb;

/** 封面图的宽度 */
@property(nonatomic, readwrite) int64_t width;

/** 封面图的高度 */
@property(nonatomic, readwrite) int64_t height;

/** 时长 */
@property(nonatomic, readwrite) int64_t duration;

/** 纬度 */
@property(nonatomic, readwrite) double lat;

/** 经度 */
@property(nonatomic, readwrite) double lng;

/** 地图缩放层级 */
@property(nonatomic, readwrite) int64_t zoom;

/** 当type为240、241、243、247 时，可以自定义推送的内容 */
@property(nonatomic, readwrite, copy, null_resettable) NSString *pushTitle;

/** 当type为240、241、243、247 时，可以自定义推送的内容 */
@property(nonatomic, readwrite, copy, null_resettable) NSString *pushBody;

/** 当type为240、241、243、247 时，可以自定义推送的内容 */
@property(nonatomic, readwrite, copy, null_resettable) NSString *pushSound;

/** 是否是阅后即焚，默认为false */
@property(nonatomic, readwrite) BOOL flash;

@end

#pragma mark - ChatRBatch

typedef GPB_ENUM(ChatRBatch_FieldNumber) {
  ChatRBatch_FieldNumber_Sign = 1,
  ChatRBatch_FieldNumber_MsgsArray = 2,
};

/**
 * 7
 **/
GPB_FINAL @interface ChatRBatch : GPBMessage

/** 信息标示，原路返回 */
@property(nonatomic, readwrite) int64_t sign;

@property(nonatomic, readwrite, strong, null_resettable) NSMutableArray<ChatR*> *msgsArray;
/** The number of items in @c msgsArray without causing the array to be created. */
@property(nonatomic, readonly) NSUInteger msgsArray_Count;

@end

#pragma mark - GetHistory

typedef GPB_ENUM(GetHistory_FieldNumber) {
  GetHistory_FieldNumber_Sign = 1,
  GetHistory_FieldNumber_ToUid = 2,
  GetHistory_FieldNumber_MsgEnd = 3,
  GetHistory_FieldNumber_MsgStart = 4,
  GetHistory_FieldNumber_Offset = 5,
};

/**
 * 8 拉取历史消息，只能按时间倒序拉取，服务器会返回offset条，或者到msg_start为止
 * msg_end  msg_start 是客户端两个连续的block中间缺失的部分
 **/
GPB_FINAL @interface GetHistory : GPBMessage

/** 客户端自定义标识，服务器会原样返回 */
@property(nonatomic, readwrite) int64_t sign;

/** 和谁的聊天记录 */
@property(nonatomic, readwrite) int64_t toUid;

/** 从这条消息往前拉（不包括此条） */
@property(nonatomic, readwrite) int64_t msgEnd;

/** 最多拉到这条（不包括此条） */
@property(nonatomic, readwrite) int64_t msgStart;

/** 拉多少条，默认20，最多100 */
@property(nonatomic, readwrite) int64_t offset;

@end

#pragma mark - Revoke

typedef GPB_ENUM(Revoke_FieldNumber) {
  Revoke_FieldNumber_Sign = 1,
  Revoke_FieldNumber_ToUid = 2,
  Revoke_FieldNumber_MsgId = 3,
};

/**
 * 9
 **/
GPB_FINAL @interface Revoke : GPBMessage

/** 客户端自定义标识，服务器会原样返回 */
@property(nonatomic, readwrite) int64_t sign;

/** 会话列表的对方id */
@property(nonatomic, readwrite) int64_t toUid;

/** 撤回的消息id */
@property(nonatomic, readwrite) int64_t msgId;

@end

#pragma mark - MsgRead

typedef GPB_ENUM(MsgRead_FieldNumber) {
  MsgRead_FieldNumber_Sign = 1,
  MsgRead_FieldNumber_ToUid = 2,
  MsgRead_FieldNumber_MsgId = 3,
};

/**
 * 10
 **/
GPB_FINAL @interface MsgRead : GPBMessage

/** 客户端自定义标识，服务器会原样返回 */
@property(nonatomic, readwrite) int64_t sign;

/** 谁发的消息已读 */
@property(nonatomic, readwrite) int64_t toUid;

/** 已读消息id */
@property(nonatomic, readwrite) int64_t msgId;

@end

#pragma mark - DelChat

typedef GPB_ENUM(DelChat_FieldNumber) {
  DelChat_FieldNumber_Sign = 1,
  DelChat_FieldNumber_ToUid = 2,
};

/**
 * 11 删除会话
 **/
GPB_FINAL @interface DelChat : GPBMessage

/** 客户端自定义标识，服务器会原样返回 */
@property(nonatomic, readwrite) int64_t sign;

/** 删除谁的 */
@property(nonatomic, readwrite) int64_t toUid;

@end

#pragma mark - GetChatList

typedef GPB_ENUM(GetChatList_FieldNumber) {
  GetChatList_FieldNumber_Sign = 1,
  GetChatList_FieldNumber_UpdateTime = 2,
  GetChatList_FieldNumber_Uid = 3,
};

/**
 * 12
 **/
GPB_FINAL @interface GetChatList : GPBMessage

/** 客户端自定义标识，服务器会原样返回 */
@property(nonatomic, readwrite) int64_t sign;

/** 客户端本地保存的会话列表的最新一个会话的变动时间（精确到百万分之一秒的时间戳） */
@property(nonatomic, readwrite) int64_t updateTime;

/** websocket 端传此值, 作为分页指针 */
@property(nonatomic, readwrite) int64_t uid;

@end

#pragma mark - ChatItem

typedef GPB_ENUM(ChatItem_FieldNumber) {
  ChatItem_FieldNumber_Sign = 1,
  ChatItem_FieldNumber_Uid = 2,
  ChatItem_FieldNumber_MsgEnd = 3,
  ChatItem_FieldNumber_MsgLastRead = 4,
  ChatItem_FieldNumber_ShowMsgId = 5,
  ChatItem_FieldNumber_ShowMsgType = 6,
  ChatItem_FieldNumber_ShowMsg = 7,
  ChatItem_FieldNumber_ShowMsgTime = 8,
  ChatItem_FieldNumber_Unread = 9,
  ChatItem_FieldNumber_IBlockU = 16,
  ChatItem_FieldNumber_Deleted = 18,
};

/**
 * 13
 **/
GPB_FINAL @interface ChatItem : GPBMessage

@property(nonatomic, readwrite) int64_t sign;

@property(nonatomic, readwrite) int64_t uid;

@property(nonatomic, readwrite) int64_t msgEnd;

@property(nonatomic, readwrite) int64_t msgLastRead;

@property(nonatomic, readwrite) int64_t showMsgId;

/** 仅websocket端 返回 */
@property(nonatomic, readwrite) int64_t showMsgType;

/** 仅websocket端 返回 */
@property(nonatomic, readwrite, copy, null_resettable) NSString *showMsg;

@property(nonatomic, readwrite) int64_t showMsgTime;

@property(nonatomic, readwrite) int64_t unread;

@property(nonatomic, readwrite) BOOL iBlockU;

/** 该会话已删除 */
@property(nonatomic, readwrite) BOOL deleted;

@end

#pragma mark - ChatItemUpdate

typedef GPB_ENUM(ChatItemUpdate_FieldNumber) {
  ChatItemUpdate_FieldNumber_Sign = 1,
  ChatItemUpdate_FieldNumber_Uid = 2,
  ChatItemUpdate_FieldNumber_Event = 3,
  ChatItemUpdate_FieldNumber_UpdateTime = 4,
  ChatItemUpdate_FieldNumber_MsgLastRead = 5,
  ChatItemUpdate_FieldNumber_Unread = 6,
  ChatItemUpdate_FieldNumber_IBlockU = 7,
  ChatItemUpdate_FieldNumber_Deleted = 8,
};

/**
 * 14
 **/
GPB_FINAL @interface ChatItemUpdate : GPBMessage

@property(nonatomic, readwrite) int64_t sign;

/** 变动的哪个uid */
@property(nonatomic, readwrite) int64_t uid;

/** 0 msg_last_read 变动    1 unread 数变动    2 i_block_u 变动   3 deleted 变动 */
@property(nonatomic, readwrite) int64_t event;

@property(nonatomic, readwrite) int64_t updateTime;

@property(nonatomic, readwrite) int64_t msgLastRead;

@property(nonatomic, readwrite) int64_t unread;

@property(nonatomic, readwrite) BOOL iBlockU;

@property(nonatomic, readwrite) BOOL deleted;

@end

#pragma mark - ChatList

typedef GPB_ENUM(ChatList_FieldNumber) {
  ChatList_FieldNumber_Sign = 1,
  ChatList_FieldNumber_ChatItemsArray = 2,
  ChatList_FieldNumber_UpdateTime = 3,
};

/**
 * 15
 **/
GPB_FINAL @interface ChatList : GPBMessage

/** websocket 会返回该值 */
@property(nonatomic, readwrite) int64_t sign;

@property(nonatomic, readwrite, strong, null_resettable) NSMutableArray<ChatItem*> *chatItemsArray;
/** The number of items in @c chatItemsArray without causing the array to be created. */
@property(nonatomic, readonly) NSUInteger chatItemsArray_Count;

/** app会返回，有该值说明 会话列表发送完毕，且会话列表中的最新更新时间会是这个值（精确到百万分之一秒的时间戳） */
@property(nonatomic, readwrite) int64_t updateTime;

@end

#pragma mark - GetProfile

typedef GPB_ENUM(GetProfile_FieldNumber) {
  GetProfile_FieldNumber_Sign = 1,
  GetProfile_FieldNumber_Uid = 2,
  GetProfile_FieldNumber_UpdateTime = 3,
};

/**
 * 16
 **/
GPB_FINAL @interface GetProfile : GPBMessage

/** 信息标示，原路返回 */
@property(nonatomic, readwrite) int64_t sign;

@property(nonatomic, readwrite) int64_t uid;

/** profile的更新时间 精确到秒的时间戳 */
@property(nonatomic, readwrite) int64_t updateTime;

@end

#pragma mark - GetProfiles

typedef GPB_ENUM(GetProfiles_FieldNumber) {
  GetProfiles_FieldNumber_Sign = 1,
  GetProfiles_FieldNumber_GetProfilesArray = 2,
};

/**
 * 17
 **/
GPB_FINAL @interface GetProfiles : GPBMessage

/** 信息标示，原路返回 */
@property(nonatomic, readwrite) int64_t sign;

@property(nonatomic, readwrite, strong, null_resettable) NSMutableArray<GetProfile*> *getProfilesArray;
/** The number of items in @c getProfilesArray without causing the array to be created. */
@property(nonatomic, readonly) NSUInteger getProfilesArray_Count;

@end

#pragma mark - Profile

typedef GPB_ENUM(Profile_FieldNumber) {
  Profile_FieldNumber_Sign = 1,
  Profile_FieldNumber_Uid = 2,
  Profile_FieldNumber_UpdateTime = 3,
  Profile_FieldNumber_NickName = 4,
  Profile_FieldNumber_Avatar = 5,
  Profile_FieldNumber_Gender = 6,
  Profile_FieldNumber_Custom = 7,
  Profile_FieldNumber_Hidden = 8,
};

/**
 * 18
 **/
GPB_FINAL @interface Profile : GPBMessage

/** 信息标示，原路返回 */
@property(nonatomic, readwrite) int64_t sign;

@property(nonatomic, readwrite) int64_t uid;

/** profile的更新时间 精确到秒的时间戳 */
@property(nonatomic, readwrite) int64_t updateTime;

@property(nonatomic, readwrite, copy, null_resettable) NSString *nickName;

@property(nonatomic, readwrite, copy, null_resettable) NSString *avatar;

@property(nonatomic, readwrite) int64_t gender;

/** 第三方自定义数据 */
@property(nonatomic, readwrite, copy, null_resettable) NSString *custom;

/** 是否应为某种原因 需要隐藏这个profile的会话记录，比如说删除 */
@property(nonatomic, readwrite) BOOL hidden;

@end

#pragma mark - ProfileList

typedef GPB_ENUM(ProfileList_FieldNumber) {
  ProfileList_FieldNumber_ProfilesArray = 1,
};

/**
 * 19
 **/
GPB_FINAL @interface ProfileList : GPBMessage

@property(nonatomic, readwrite, strong, null_resettable) NSMutableArray<Profile*> *profilesArray;
/** The number of items in @c profilesArray without causing the array to be created. */
@property(nonatomic, readonly) NSUInteger profilesArray_Count;

@end

#pragma mark - GetChat

typedef GPB_ENUM(GetChat_FieldNumber) {
  GetChat_FieldNumber_Sign = 1,
  GetChat_FieldNumber_Uid = 2,
};

/**
 * 20
 **/
GPB_FINAL @interface GetChat : GPBMessage

@property(nonatomic, readwrite) int64_t sign;

@property(nonatomic, readwrite) int64_t uid;

@end

#pragma mark - UpdatePushToken

typedef GPB_ENUM(UpdatePushToken_FieldNumber) {
  UpdatePushToken_FieldNumber_Sign = 1,
  UpdatePushToken_FieldNumber_PushChannel = 2,
  UpdatePushToken_FieldNumber_PushToken = 3,
};

/**
 * 21 客户端更新push token
 **/
GPB_FINAL @interface UpdatePushToken : GPBMessage

@property(nonatomic, readwrite) int64_t sign;

/** 子应用的推送渠道 1 apns  2 fcm */
@property(nonatomic, readwrite) int64_t pushChannel;

@property(nonatomic, readwrite, copy, null_resettable) NSString *pushToken;

@end

#pragma mark - GetCosKey

typedef GPB_ENUM(GetCosKey_FieldNumber) {
  GetCosKey_FieldNumber_Sign = 1,
};

/**
 * 22 请求cos的临时证书
 **/
GPB_FINAL @interface GetCosKey : GPBMessage

@property(nonatomic, readwrite) int64_t sign;

@end

#pragma mark - CosKey

typedef GPB_ENUM(CosKey_FieldNumber) {
  CosKey_FieldNumber_Sign = 1,
  CosKey_FieldNumber_Token = 2,
  CosKey_FieldNumber_Id_p = 3,
  CosKey_FieldNumber_Key = 4,
  CosKey_FieldNumber_Bucket = 5,
  CosKey_FieldNumber_Region = 6,
  CosKey_FieldNumber_StartTime = 7,
  CosKey_FieldNumber_ExpTime = 8,
  CosKey_FieldNumber_Path = 9,
  CosKey_FieldNumber_PathDemo = 10,
};

/**
 * 23 cos的临时证书
 **/
GPB_FINAL @interface CosKey : GPBMessage

@property(nonatomic, readwrite) int64_t sign;

@property(nonatomic, readwrite, copy, null_resettable) NSString *token;

@property(nonatomic, readwrite, copy, null_resettable) NSString *id_p;

@property(nonatomic, readwrite, copy, null_resettable) NSString *key;

@property(nonatomic, readwrite, copy, null_resettable) NSString *bucket;

@property(nonatomic, readwrite, copy, null_resettable) NSString *region;

@property(nonatomic, readwrite) int64_t startTime;

@property(nonatomic, readwrite) int64_t expTime;

/** 临时存储的目录 7天自动删除 */
@property(nonatomic, readwrite, copy, null_resettable) NSString *path;

/** demo app 所需的永久存储的目录 正式平台不会有这个值 */
@property(nonatomic, readwrite, copy, null_resettable) NSString *pathDemo;

@end

#pragma mark - GetAgoraToken

typedef GPB_ENUM(GetAgoraToken_FieldNumber) {
  GetAgoraToken_FieldNumber_Sign = 1,
  GetAgoraToken_FieldNumber_Uid = 2,
  GetAgoraToken_FieldNumber_Channel = 3,
  GetAgoraToken_FieldNumber_ExpType = 4,
};

/**
 * 24 请求声网的临时token
 **/
GPB_FINAL @interface GetAgoraToken : GPBMessage

@property(nonatomic, readwrite) int64_t sign;

@property(nonatomic, readwrite) int64_t uid;

@property(nonatomic, readwrite, copy, null_resettable) NSString *channel;

/** 哪种时长类型 默认 0， 根据需求以后加 */
@property(nonatomic, readwrite) int64_t expType;

@end

#pragma mark - AgoraToken

typedef GPB_ENUM(AgoraToken_FieldNumber) {
  AgoraToken_FieldNumber_Sign = 1,
  AgoraToken_FieldNumber_AppId = 2,
  AgoraToken_FieldNumber_Token = 3,
};

/**
 * 25 声网的临时token
 **/
GPB_FINAL @interface AgoraToken : GPBMessage

@property(nonatomic, readwrite) int64_t sign;

@property(nonatomic, readwrite, copy, null_resettable) NSString *appId;

@property(nonatomic, readwrite, copy, null_resettable) NSString *token;

@end

#pragma mark - JoinGroup

typedef GPB_ENUM(JoinGroup_FieldNumber) {
  JoinGroup_FieldNumber_Sign = 1,
  JoinGroup_FieldNumber_Gtype = 2,
  JoinGroup_FieldNumber_Id_p = 3,
  JoinGroup_FieldNumber_LastMsgId = 4,
};

/**
 * 26 加入群
 **/
GPB_FINAL @interface JoinGroup : GPBMessage

@property(nonatomic, readwrite) int64_t sign;

/** 群的类型，0：chatroom   1：固定群 */
@property(nonatomic, readwrite) int64_t gtype;

@property(nonatomic, readwrite) int64_t id_p;

/** 上次离开该聊天室之前收到的最后一条消息id，该值也决定了 tips of day 是否要下发 */
@property(nonatomic, readwrite) int64_t lastMsgId;

@end

#pragma mark - LeaveGroup

typedef GPB_ENUM(LeaveGroup_FieldNumber) {
  LeaveGroup_FieldNumber_Sign = 1,
  LeaveGroup_FieldNumber_Gtype = 2,
  LeaveGroup_FieldNumber_Id_p = 3,
};

/**
 * 27 退出群
 **/
GPB_FINAL @interface LeaveGroup : GPBMessage

@property(nonatomic, readwrite) int64_t sign;

@property(nonatomic, readwrite) int64_t gtype;

@property(nonatomic, readwrite) int64_t id_p;

@end

#pragma mark - GroupMember

typedef GPB_ENUM(GroupMember_FieldNumber) {
  GroupMember_FieldNumber_Uid = 1,
  GroupMember_FieldNumber_Role = 2,
  GroupMember_FieldNumber_IsMute = 3,
};

/**
 * 28 群一个用户的属性
 **/
GPB_FINAL @interface GroupMember : GPBMessage

@property(nonatomic, readwrite) int64_t uid;

/** 角色 0：普通用户  1、临时管理员  9：管理员 */
@property(nonatomic, readwrite) int64_t role;

/** 是否被禁言 */
@property(nonatomic, readwrite) BOOL isMute;

@end

#pragma mark - GroupInfo

typedef GPB_ENUM(GroupInfo_FieldNumber) {
  GroupInfo_FieldNumber_Sign = 1,
  GroupInfo_FieldNumber_Gtype = 2,
  GroupInfo_FieldNumber_Id_p = 3,
  GroupInfo_FieldNumber_Name = 4,
  GroupInfo_FieldNumber_MaxCount = 5,
  GroupInfo_FieldNumber_IsMute = 6,
  GroupInfo_FieldNumber_MembersArray = 7,
  GroupInfo_FieldNumber_ActionTod = 20,
  GroupInfo_FieldNumber_ActionMute = 21,
  GroupInfo_FieldNumber_ActionMuteAll = 22,
  GroupInfo_FieldNumber_ActionDelMsg = 23,
  GroupInfo_FieldNumber_ActionAssign = 24,
};

/**
 * 29 群信息
 **/
GPB_FINAL @interface GroupInfo : GPBMessage

@property(nonatomic, readwrite) int64_t sign;

@property(nonatomic, readwrite) int64_t gtype;

@property(nonatomic, readwrite) int64_t id_p;

@property(nonatomic, readwrite, copy, null_resettable) NSString *name;

/** 该聊天室人数上限 */
@property(nonatomic, readwrite) int64_t maxCount;

/** 是否全体禁言 */
@property(nonatomic, readwrite) BOOL isMute;

/** 在线的用户 */
@property(nonatomic, readwrite, strong, null_resettable) NSMutableArray<GroupMember*> *membersArray;
/** The number of items in @c membersArray without causing the array to be created. */
@property(nonatomic, readonly) NSUInteger membersArray_Count;

/** 我是否具备修改tips of day（公告）的权限 */
@property(nonatomic, readwrite) BOOL actionTod;

/** 我是否具备禁言单人的权限， */
@property(nonatomic, readwrite) BOOL actionMute;

/** 我是否有关闭聊天室发言的权限 */
@property(nonatomic, readwrite) BOOL actionMuteAll;

/** 我是否有权限删除消息 */
@property(nonatomic, readwrite) BOOL actionDelMsg;

/** 我是否具备指派临时管理员的权限（管理员才有） */
@property(nonatomic, readwrite) BOOL actionAssign;

@end

#pragma mark - GroupEvent

typedef GPB_ENUM(GroupEvent_FieldNumber) {
  GroupEvent_FieldNumber_Sign = 1,
  GroupEvent_FieldNumber_Gtype = 2,
  GroupEvent_FieldNumber_Id_p = 3,
  GroupEvent_FieldNumber_FromUid = 4,
  GroupEvent_FieldNumber_Etype = 5,
  GroupEvent_FieldNumber_Name = 6,
  GroupEvent_FieldNumber_MaxCount = 7,
  GroupEvent_FieldNumber_IsMute = 8,
  GroupEvent_FieldNumber_MembersArray = 9,
  GroupEvent_FieldNumber_Reason = 10,
  GroupEvent_FieldNumber_Tip = 11,
  GroupEvent_FieldNumber_ActionTod = 20,
  GroupEvent_FieldNumber_ActionMute = 21,
  GroupEvent_FieldNumber_ActionMuteAll = 22,
  GroupEvent_FieldNumber_ActionDelMsg = 23,
  GroupEvent_FieldNumber_ActionAssign = 24,
};

/**
 * 30 群事件
 **/
GPB_FINAL @interface GroupEvent : GPBMessage

@property(nonatomic, readwrite) int64_t sign;

@property(nonatomic, readwrite) int64_t gtype;

@property(nonatomic, readwrite) int64_t id_p;

/** 0 表示系统后台 */
@property(nonatomic, readwrite) int64_t fromUid;

/** 事件类型 具体见聊天室相关的接口文档 */
@property(nonatomic, readwrite) int64_t etype;

@property(nonatomic, readwrite, copy, null_resettable) NSString *name;

@property(nonatomic, readwrite) int64_t maxCount;

/** 是否全体禁言 */
@property(nonatomic, readwrite) BOOL isMute;

/** 用户 */
@property(nonatomic, readwrite, strong, null_resettable) NSMutableArray<GroupMember*> *membersArray;
/** The number of items in @c membersArray without causing the array to be created. */
@property(nonatomic, readonly) NSUInteger membersArray_Count;

/** 操作原因（ 禁言 / 指派管理员等某些操作时可能附带该信息） */
@property(nonatomic, readwrite, copy, null_resettable) NSString *reason;

/** 提示性小字 */
@property(nonatomic, readwrite, strong, null_resettable) GroupTipEvent *tip;
/** Test to see if @c tip has been set. */
@property(nonatomic, readwrite) BOOL hasTip;

/** 我是否具备修改tips of day（公告）的权限 */
@property(nonatomic, readwrite) BOOL actionTod;

/** 我是否具备禁言单人的权限 */
@property(nonatomic, readwrite) BOOL actionMute;

/** 我是否有聊天室禁止发言的权限 */
@property(nonatomic, readwrite) BOOL actionMuteAll;

/** 我是否有权限删除消息 */
@property(nonatomic, readwrite) BOOL actionDelMsg;

/** 我是否具备指派临时管理员的权限（管理员才有） */
@property(nonatomic, readwrite) BOOL actionAssign;

@end

#pragma mark - GroupChatS

typedef GPB_ENUM(GroupChatS_FieldNumber) {
  GroupChatS_FieldNumber_Sign = 1,
  GroupChatS_FieldNumber_Gtype = 2,
  GroupChatS_FieldNumber_Id_p = 3,
  GroupChatS_FieldNumber_Type = 4,
  GroupChatS_FieldNumber_Title = 5,
  GroupChatS_FieldNumber_Body = 6,
  GroupChatS_FieldNumber_Thumb = 7,
  GroupChatS_FieldNumber_Width = 8,
  GroupChatS_FieldNumber_Height = 9,
  GroupChatS_FieldNumber_Duration = 10,
  GroupChatS_FieldNumber_Lat = 11,
  GroupChatS_FieldNumber_Lng = 12,
  GroupChatS_FieldNumber_Zoom = 13,
  GroupChatS_FieldNumber_Anonymous = 14,
};

/**
 * 31 群发消息
 **/
GPB_FINAL @interface GroupChatS : GPBMessage

/** 客户端自定义标识，服务器会原样返回 */
@property(nonatomic, readwrite) int64_t sign;

/** 群类型 */
@property(nonatomic, readwrite) int64_t gtype;

/** 发到哪个群id */
@property(nonatomic, readwrite) int64_t id_p;

/** 消息类型 */
@property(nonatomic, readwrite) int64_t type;

/** 消息内容 */
@property(nonatomic, readwrite, copy, null_resettable) NSString *title;

/** 消息内容 */
@property(nonatomic, readwrite, copy, null_resettable) NSString *body;

/** 封面图 */
@property(nonatomic, readwrite, copy, null_resettable) NSString *thumb;

/** 封面图的宽度 */
@property(nonatomic, readwrite) int64_t width;

/** 封面图的高度 */
@property(nonatomic, readwrite) int64_t height;

/** 时长 */
@property(nonatomic, readwrite) int64_t duration;

/** 纬度 */
@property(nonatomic, readwrite) double lat;

/** 经度 */
@property(nonatomic, readwrite) double lng;

/** 地图缩放层级 */
@property(nonatomic, readwrite) int64_t zoom;

/** 匿名id */
@property(nonatomic, readwrite) int64_t anonymous;

@end

#pragma mark - GroupChatSR

typedef GPB_ENUM(GroupChatSR_FieldNumber) {
  GroupChatSR_FieldNumber_Sign = 1,
  GroupChatSR_FieldNumber_Gtype = 2,
  GroupChatSR_FieldNumber_Id_p = 3,
  GroupChatSR_FieldNumber_MsgId = 4,
  GroupChatSR_FieldNumber_MsgTime = 5,
};

/**
 * 32
 **/
GPB_FINAL @interface GroupChatSR : GPBMessage

/** 信息标示，原路返回 */
@property(nonatomic, readwrite) int64_t sign;

/** 群类型 */
@property(nonatomic, readwrite) int64_t gtype;

/** 来自哪个群 */
@property(nonatomic, readwrite) int64_t id_p;

/** 消息id */
@property(nonatomic, readwrite) int64_t msgId;

@property(nonatomic, readwrite) int64_t msgTime;

@end

#pragma mark - GroupChatR

typedef GPB_ENUM(GroupChatR_FieldNumber) {
  GroupChatR_FieldNumber_Sign = 1,
  GroupChatR_FieldNumber_Gtype = 2,
  GroupChatR_FieldNumber_Id_p = 3,
  GroupChatR_FieldNumber_FromUid = 4,
  GroupChatR_FieldNumber_MsgId = 5,
  GroupChatR_FieldNumber_MsgTime = 6,
  GroupChatR_FieldNumber_Type = 7,
  GroupChatR_FieldNumber_Title = 8,
  GroupChatR_FieldNumber_Body = 9,
  GroupChatR_FieldNumber_Thumb = 10,
  GroupChatR_FieldNumber_Width = 11,
  GroupChatR_FieldNumber_Height = 12,
  GroupChatR_FieldNumber_Duration = 13,
  GroupChatR_FieldNumber_Lat = 14,
  GroupChatR_FieldNumber_Lng = 15,
  GroupChatR_FieldNumber_Zoom = 16,
  GroupChatR_FieldNumber_Anonymous = 17,
};

/**
 * 33
 **/
GPB_FINAL @interface GroupChatR : GPBMessage

@property(nonatomic, readwrite) int64_t sign;

/** 群类型 */
@property(nonatomic, readwrite) int64_t gtype;

/** 来自哪个群 */
@property(nonatomic, readwrite) int64_t id_p;

/** 谁发的 */
@property(nonatomic, readwrite) int64_t fromUid;

/** 消息id */
@property(nonatomic, readwrite) int64_t msgId;

/** 消息时间（以服务器为准 精确到百万分之一秒的时间戳） */
@property(nonatomic, readwrite) int64_t msgTime;

/** 消息类型 */
@property(nonatomic, readwrite) int64_t type;

/** 消息标题 */
@property(nonatomic, readwrite, copy, null_resettable) NSString *title;

/** 消息内容 */
@property(nonatomic, readwrite, copy, null_resettable) NSString *body;

/** 封面图 */
@property(nonatomic, readwrite, copy, null_resettable) NSString *thumb;

/** 封面图的宽度 */
@property(nonatomic, readwrite) int64_t width;

/** 封面图的高度 */
@property(nonatomic, readwrite) int64_t height;

/** 时长 */
@property(nonatomic, readwrite) int64_t duration;

/** 纬度 */
@property(nonatomic, readwrite) double lat;

/** 经度 */
@property(nonatomic, readwrite) double lng;

/** 地图缩放层级 */
@property(nonatomic, readwrite) int64_t zoom;

/** 匿名id */
@property(nonatomic, readwrite) int64_t anonymous;

@end

#pragma mark - GroupChatRBatch

typedef GPB_ENUM(GroupChatRBatch_FieldNumber) {
  GroupChatRBatch_FieldNumber_Sign = 1,
  GroupChatRBatch_FieldNumber_MsgsArray = 2,
};

/**
 * 34
 **/
GPB_FINAL @interface GroupChatRBatch : GPBMessage

/** 信息标示，原路返回 */
@property(nonatomic, readwrite) int64_t sign;

@property(nonatomic, readwrite, strong, null_resettable) NSMutableArray<GroupChatR*> *msgsArray;
/** The number of items in @c msgsArray without causing the array to be created. */
@property(nonatomic, readonly) NSUInteger msgsArray_Count;

@end

#pragma mark - GetGroupProfiles

typedef GPB_ENUM(GetGroupProfiles_FieldNumber) {
  GetGroupProfiles_FieldNumber_Sign = 1,
  GetGroupProfiles_FieldNumber_Gtype = 2,
  GetGroupProfiles_FieldNumber_Id_p = 3,
  GetGroupProfiles_FieldNumber_GetProfilesArray = 4,
};

/**
 * 35 获取群中用户的profile
 **/
GPB_FINAL @interface GetGroupProfiles : GPBMessage

/** 信息标示，原路返回 */
@property(nonatomic, readwrite) int64_t sign;

/** 群类型 */
@property(nonatomic, readwrite) int64_t gtype;

@property(nonatomic, readwrite) int64_t id_p;

@property(nonatomic, readwrite, strong, null_resettable) NSMutableArray<GetProfile*> *getProfilesArray;
/** The number of items in @c getProfilesArray without causing the array to be created. */
@property(nonatomic, readonly) NSUInteger getProfilesArray_Count;

@end

#pragma mark - GroupAction

typedef GPB_ENUM(GroupAction_FieldNumber) {
  GroupAction_FieldNumber_Sign = 1,
  GroupAction_FieldNumber_Gtype = 2,
  GroupAction_FieldNumber_Id_p = 3,
  GroupAction_FieldNumber_Action = 4,
  GroupAction_FieldNumber_UidsArray = 5,
  GroupAction_FieldNumber_Duration = 6,
  GroupAction_FieldNumber_Tod = 7,
  GroupAction_FieldNumber_Reason = 8,
  GroupAction_FieldNumber_MsgsArray = 9,
};

/**
 * 36 群的管理操作
 **/
GPB_FINAL @interface GroupAction : GPBMessage

/** 信息标示，原路返回 */
@property(nonatomic, readwrite) int64_t sign;

/** 群类型 */
@property(nonatomic, readwrite) int64_t gtype;

/** 群id */
@property(nonatomic, readwrite) int64_t id_p;

/** 0：修改公告 1：禁言/恢复发言  2：全聊天室禁言 3：取消全聊天室禁言  4：删除消息  5：任命/解除临时管理员 */
@property(nonatomic, readwrite) int64_t action;

@property(nonatomic, readwrite, strong, null_resettable) GPBInt64Array *uidsArray;
/** The number of items in @c uidsArray without causing the array to be created. */
@property(nonatomic, readonly) NSUInteger uidsArray_Count;

/** 0：10分钟  1：30分钟  2：1小时  3：24小时  4：1周 */
@property(nonatomic, readwrite) int64_t duration;

/** tips of day  公告信息 */
@property(nonatomic, readwrite, copy, null_resettable) NSString *tod;

/** 操作原因（ 禁言 / 指派管理员等操作时可选择附加该信息） */
@property(nonatomic, readwrite, copy, null_resettable) NSString *reason;

/** 消息id */
@property(nonatomic, readwrite, strong, null_resettable) GPBInt64Array *msgsArray;
/** The number of items in @c msgsArray without causing the array to be created. */
@property(nonatomic, readonly) NSUInteger msgsArray_Count;

@end

#pragma mark - GroupRevoke

typedef GPB_ENUM(GroupRevoke_FieldNumber) {
  GroupRevoke_FieldNumber_Sign = 1,
  GroupRevoke_FieldNumber_Gtype = 2,
  GroupRevoke_FieldNumber_Id_p = 3,
  GroupRevoke_FieldNumber_MsgId = 4,
};

/**
 * 37 群消息撤回
 **/
GPB_FINAL @interface GroupRevoke : GPBMessage

/** 客户端自定义标识，服务器会原样返回 */
@property(nonatomic, readwrite) int64_t sign;

/** 群类型 */
@property(nonatomic, readwrite) int64_t gtype;

/** 从哪个群撤回消息 */
@property(nonatomic, readwrite) int64_t id_p;

/** 撤回的消息id */
@property(nonatomic, readwrite) int64_t msgId;

@end

#pragma mark - GroupTipEvent

typedef GPB_ENUM(GroupTipEvent_FieldNumber) {
  GroupTipEvent_FieldNumber_Event = 1,
  GroupTipEvent_FieldNumber_UidsArray = 2,
};

/**
 * 38 群类显示的提示性事件小字，如果GroupEvent中，附带reason，在提示小字后面需加上reason
 **/
GPB_FINAL @interface GroupTipEvent : GPBMessage

/** 事件类型： */
@property(nonatomic, readwrite) int64_t event;

/**
 * 1：聊天室已被解散
 * 2：聊天室属性已修改
 * 3：管理员 %s 将本聊天室设为听众模式
 * 4: 管理员 %s 恢复聊天室发言功能
 * 5：管理员 %s 上线
 * 6：管理员 %s 下线
 * 7: 管理员 %s 将用户 %s 禁言
 * 8: 管理员 %s 将用户 %s、%s 等人禁言
 * 9: %s 成为本聊天室管理员
 * 10: 管理员 %s 指派 %s 为临时管理员
 * 11：管理员 %s 指派 %s、%s 等人为临时管理员
 **/
@property(nonatomic, readwrite, strong, null_resettable) GPBInt64Array *uidsArray;
/** The number of items in @c uidsArray without causing the array to be created. */
@property(nonatomic, readonly) NSUInteger uidsArray_Count;

@end

#pragma mark - ChatAction

typedef GPB_ENUM(ChatAction_FieldNumber) {
  ChatAction_FieldNumber_Sign = 1,
  ChatAction_FieldNumber_Type = 2,
  ChatAction_FieldNumber_ToUid = 3,
  ChatAction_FieldNumber_MsgId = 4,
  ChatAction_FieldNumber_UidsArray = 5,
  ChatAction_FieldNumber_MsgsArray = 6,
  ChatAction_FieldNumber_Data_p = 7,
};

/**
 * 39 发送指令消息
 **/
GPB_FINAL @interface ChatAction : GPBMessage

/** 客户端自定义标识，服务器会原样返回 */
@property(nonatomic, readwrite) int64_t sign;

/** 指令消息，64 revoke  68 点开闪照 */
@property(nonatomic, readwrite) int64_t type;

/** 发送给谁 */
@property(nonatomic, readwrite) int64_t toUid;

/** 撤回的消息id */
@property(nonatomic, readwrite) int64_t msgId;

/** 预留 */
@property(nonatomic, readwrite, strong, null_resettable) GPBInt64Array *uidsArray;
/** The number of items in @c uidsArray without causing the array to be created. */
@property(nonatomic, readonly) NSUInteger uidsArray_Count;

/** 预留 */
@property(nonatomic, readwrite, strong, null_resettable) GPBInt64Array *msgsArray;
/** The number of items in @c msgsArray without causing the array to be created. */
@property(nonatomic, readonly) NSUInteger msgsArray_Count;

/** 预留 */
@property(nonatomic, readwrite, copy, null_resettable) NSString *data_p;

@end

#pragma mark - ProfileOnline

typedef GPB_ENUM(ProfileOnline_FieldNumber) {
  ProfileOnline_FieldNumber_Uid = 1,
  ProfileOnline_FieldNumber_UpdateTime = 2,
  ProfileOnline_FieldNumber_NickName = 3,
  ProfileOnline_FieldNumber_Avatar = 4,
  ProfileOnline_FieldNumber_Gender = 5,
};

/**
 * 50  for demo: 通知客户端用户上线事件
 **/
GPB_FINAL @interface ProfileOnline : GPBMessage

@property(nonatomic, readwrite) int64_t uid;

/** profile的更新时间 精确到秒的时间戳 */
@property(nonatomic, readwrite) int64_t updateTime;

@property(nonatomic, readwrite, copy, null_resettable) NSString *nickName;

@property(nonatomic, readwrite, copy, null_resettable) NSString *avatar;

@property(nonatomic, readwrite) int64_t gender;

@end

#pragma mark - UsrOnline

typedef GPB_ENUM(UsrOnline_FieldNumber) {
  UsrOnline_FieldNumber_Uid = 1,
};

/**
 * 51 for demo：通知客户端用户上线事件
 **/
GPB_FINAL @interface UsrOnline : GPBMessage

@property(nonatomic, readwrite) int64_t uid;

@end

#pragma mark - UsrOffline

typedef GPB_ENUM(UsrOffline_FieldNumber) {
  UsrOffline_FieldNumber_Uid = 1,
};

/**
 * 52 for demo：通知客户端用户下线事件
 **/
GPB_FINAL @interface UsrOffline : GPBMessage

@property(nonatomic, readwrite) int64_t uid;

@end

#pragma mark - Signup

typedef GPB_ENUM(Signup_FieldNumber) {
  Signup_FieldNumber_Sign = 1,
  Signup_FieldNumber_AppId = 2,
  Signup_FieldNumber_Phone = 3,
  Signup_FieldNumber_NickName = 4,
  Signup_FieldNumber_Avatar = 5,
  Signup_FieldNumber_Gender = 6,
  Signup_FieldNumber_Pic = 7,
};

/**
 * 53 for demo：注册新用户
 **/
GPB_FINAL @interface Signup : GPBMessage

@property(nonatomic, readwrite) int64_t sign;

@property(nonatomic, readwrite) int64_t appId;

@property(nonatomic, readwrite) int64_t phone;

@property(nonatomic, readwrite, copy, null_resettable) NSString *nickName;

@property(nonatomic, readwrite, copy, null_resettable) NSString *avatar;

@property(nonatomic, readwrite) int64_t gender;

/** 用户spark界面的封面图 */
@property(nonatomic, readwrite, copy, null_resettable) NSString *pic;

@end

#pragma mark - FetchSpark

typedef GPB_ENUM(FetchSpark_FieldNumber) {
  FetchSpark_FieldNumber_Sign = 1,
};

/**
 * 54 for demo: 获取spark
 **/
GPB_FINAL @interface FetchSpark : GPBMessage

@property(nonatomic, readwrite) int64_t sign;

@end

#pragma mark - Sparks

typedef GPB_ENUM(Sparks_FieldNumber) {
  Sparks_FieldNumber_Sign = 1,
  Sparks_FieldNumber_SparksArray = 2,
};

/**
 * 56 for demo: sparks
 **/
GPB_FINAL @interface Sparks : GPBMessage

@property(nonatomic, readwrite) int64_t sign;

@property(nonatomic, readwrite, strong, null_resettable) NSMutableArray<Profile*> *sparksArray;
/** The number of items in @c sparksArray without causing the array to be created. */
@property(nonatomic, readonly) NSUInteger sparksArray_Count;

@end

#pragma mark - GetImToken

typedef GPB_ENUM(GetImToken_FieldNumber) {
  GetImToken_FieldNumber_Sign = 1,
  GetImToken_FieldNumber_Phone = 2,
};

/**
 * 57 for demo: 获取用户token
 **/
GPB_FINAL @interface GetImToken : GPBMessage

@property(nonatomic, readwrite) int64_t sign;

@property(nonatomic, readwrite) int64_t phone;

@end

#pragma mark - RobotOn

typedef GPB_ENUM(RobotOn_FieldNumber) {
  RobotOn_FieldNumber_Sign = 1,
};

/**
 * for ws：统计功能：开启机器人
 * 58
 **/
GPB_FINAL @interface RobotOn : GPBMessage

@property(nonatomic, readwrite) int64_t sign;

@end

#pragma mark - RobotOff

typedef GPB_ENUM(RobotOff_FieldNumber) {
  RobotOff_FieldNumber_Sign = 1,
};

/**
 * 59
 **/
GPB_FINAL @interface RobotOff : GPBMessage

@property(nonatomic, readwrite) int64_t sign;

@end

NS_ASSUME_NONNULL_END

CF_EXTERN_C_END

#pragma clang diagnostic pop

// @@protoc_insertion_point(global_scope)
