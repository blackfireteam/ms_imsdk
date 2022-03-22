//
//  MSIMManager+Message.h
//  BlackFireIM
//
//  Created by benny wang on 2021/2/26.
//
#import <MSIMSDK/MSIMManager.h>
#import <MSIMSDK/MSIMMessage.h>



NS_ASSUME_NONNULL_BEGIN

@class ChatR;

/// 获取历史消息成功回调
typedef void (^BFIMMessageListSucc)(NSArray<MSIMMessage *> * msgs,BOOL isFinished);

@interface MSIMManager (Message)

/////////////////////////////////////////////////////////////////////////////////
//
//                         创建和发送文本、图片等消息接口
//
/////////////////////////////////////////////////////////////////////////////////
/** 创建文本消息 文本最大支持 8k*/
- (MSIMMessage *)createTextMessage:(NSString *)text;

/** 创建图片消息（图片文件最大支持 28 MB）
    如果是系统相册拿的图片，需要先把图片导入 APP 的目录下
    identifierID  资源的唯一标识，用于重复图片附件上传去重。可以为空
 */
- (MSIMMessage *)createImageMessage:(NSString *)imagePath identifierID:(nullable NSString *)identifierID;

/** 创建语音消息（语音文件最大支持 28 MB）
 参数
 duration    音频时长，单位 s
 */
- (MSIMMessage *)createVoiceMessage:(NSString *)audioFilePath duration:(NSInteger)duration;


/** 创建视频消息（视频文件最大支持 100 MB）
 参数
 type    视频类型，如 mp4 mov 等
 duration    视频时长，单位 s
 snapshotPath    视频封面文件路径
 identifierID  资源的唯一标识，用于重复视频附件上传去重。可以为空
 */
- (MSIMMessage *)createVideoMessage:(NSString *)videoFilePath
                               type:(NSString *)type
                           duration:(NSInteger)duration
                       snapshotPath:(NSString *)snapshotPath
                       identifierID:(nullable NSString *)identifierID;

/** 创建位置消息
 */
- (MSIMMessage *)createLocationMessage:(MSIMLocationElem *)elem;


/** 创建自定义表情消息
 */
- (MSIMMessage *)createEmotionMessage:(MSIMEmotionElem *)elem;


/** 创建自定义消息,如果不走推送，pushExt字段可以传nil */
- (MSIMMessage *)createCustomMessage:(NSString *)jsonStr
                                 option:(MSIMCustomOption)option
                                pushExt:(nullable MSIMPushInfo *)pushExt;


/** 创建走voip通道的消息 */
- (MSIMMessage *)createVoipMessage:(NSString *)jsonStr
                            option:(MSIMCustomOption)option
                           pushExt:(nullable MSIMPushInfo *)pushExt;

/// 发送单聊消息
/// @param message 消息体
/// @param reciever 接收者Uid
/// @param success 发送成功，返回消息的唯一标识ID
/// @param failed 发送失败
- (void)sendC2CMessage:(MSIMMessage *)message
            toReciever:(NSString *)reciever
             successed:(void(^)(NSInteger msg_id))success
                failed:(MSIMFail)failed;



/// 请求撤回某一条消息
/// @param reciever 会话对方的uid
/// @param msg_id 消息的唯一ID
/// @param success 撤回成功
/// @param failed 撤回失败
- (void)revokeMessage:(NSInteger)msg_id
           toReciever:(NSString *)reciever
            successed:(MSIMSucc)success
               failed:(MSIMFail)failed;


/// 单聊消息重发
/// @param message 消息体
/// @param reciever 接收者Uid
/// @param success 发送成功，返回消息的唯一标识ID
/// @param failed 发送失败
- (void)resendC2CMessage:(MSIMMessage *)message
              toReciever:(NSString *)reciever
               successed:(void(^)(NSInteger msg_id))success
                  failed:(MSIMFail)failed;

/////////////////////////////////////////////////////////////////////////////////
//
//                         获取历史消息、撤回、删除、标记已读等接口
//
/////////////////////////////////////////////////////////////////////////////////
/**
 *  获取单聊历史消息
 *
 *  @param count 拉取消息的个数，不宜太多，会影响消息拉取的速度，这里建议一次拉取 20 个
 *  @param lastMsgID 获取消息的起始消息，如果传 0，起始消息为会话的最新消息
 */
- (void)getC2CHistoryMessageList:(NSString *)user_id
                           count:(int)count
                         lastMsg:(NSInteger)lastMsgID
                            succ:(BFIMMessageListSucc)succ
                            fail:(MSIMFail)fail;


///删除消息
///只做本地删除，卸载重装后从服务器仍能拉到此消息
- (BOOL)deleteMessageFromLocal:(MSIMMessage *)message;

/**
 *  收到阅后即焚消息已读
 *
 *  @param message  阅后即焚消息
 *  @param success 操作成功
 *  @param failed 操作失败
 */
- (void)readSnapchat:(MSIMMessage *)message
           successed:(nullable MSIMSucc)success
              failed:(nullable MSIMFail)failed;

@end

NS_ASSUME_NONNULL_END
