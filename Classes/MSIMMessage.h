//
//  MSIMMessage.h
//  MSIMSDK
//
//  Created by benny wang on 2022/2/11.
//

#import <Foundation/Foundation.h>
#import <MSIMSDK/MSIMConst.h>
#import <MSIMSDK/MSIMElem.h>
#import <MSIMSDK/MSProfileInfo.h>

NS_ASSUME_NONNULL_BEGIN

@interface MSIMMessage : NSObject<NSCopying>

/** 聊天类型*/
@property(nonatomic,assign) MSIMAChatType chatType;

/** 消息类型*/
@property(nonatomic,assign) MSIMMessageType type;

/** 消息发送方ID*/
@property(nonatomic,copy) NSString *fromUid;

/** 消息接收方ID*/
@property(nonatomic,copy) NSString *toUid;

/** 非单聊时有值。当为聊天室时，为room_id，群聊时为group_id*/
@property(nonatomic,copy,nullable) NSString *groupID;

/** 服务器返回的消息的id*/
@property(nonatomic,assign) NSInteger msgID;

/** 当消息生成时就已经固定，全局唯一，会贯穿整个发送以及接收过程。*/
@property(nonatomic,assign) NSInteger msgSign;

/** 消息状态*/
@property(nonatomic,assign) MSIMMessageStatus sendStatus;

/** 消息是否为阅后即焚*/
@property(nonatomic,assign) BOOL isSnapChat;

/** 消息发送失败错误码*/
@property(nonatomic,assign) NSInteger code;

/** 消息发送失败描述*/
@property(nonatomic,copy) NSString *reason;

/** 消息已读状态*/
@property(nonatomic,assign) MSIMMessageReadStatus readStatus;

/** 自己是否为消息的发送者*/
@property(nonatomic,assign,readonly) BOOL isSelf;

/** 指对方uid*/
@property(nonatomic,copy,readonly) NSString *partnerID;

/** 消息所有者信息,即消息的发送者 有可能为空*/
@property(nonatomic,strong,readonly,nullable) MSProfileInfo *owner;

/** 当message为文本消息时有值*/
@property(nonatomic,strong,readonly,nullable) MSIMTextElem *textElem;

/** 当message为图片消息时有值*/
@property(nonatomic,strong,readonly,nullable) MSIMImageElem *imageElem;

/** 当message为音频消息时有值*/
@property(nonatomic,strong,readonly,nullable) MSIMVoiceElem *voiceElem;

/** 当message为视频消息时有值*/
@property(nonatomic,strong,readonly,nullable) MSIMVideoElem *videoElem;

/** 当message为表情消息时有值*/
@property(nonatomic,strong,readonly,nullable) MSIMEmotionElem *emotionElem;

/** 当message为位置消息时有值*/
@property(nonatomic,strong,readonly,nullable) MSIMLocationElem *locationElem;

/** 当message为自定义消息时有值*/
@property(nonatomic,strong,readonly,nullable) MSIMCustomElem *customElem;

@end

NS_ASSUME_NONNULL_END
