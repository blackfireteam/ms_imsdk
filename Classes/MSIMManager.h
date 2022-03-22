//
//  MSIMManager.h
//  BlackFireIM
//
//  Created by benny wang on 2021/2/25.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "MSIMManagerListener.h"
#import "MSDBMessageStore.h"
#import "MSDBConversationStore.h"
#import "MSTCPSocket.h"
#import "MSUploadMediator.h"


NS_ASSUME_NONNULL_BEGIN

/// 获取历史消息成功回调
typedef void (^MSIMConversationListSucc)(NSArray<MSIMConversation *> * convs,NSInteger nexSeq,BOOL isFinished);

@interface MSIMManager : NSObject

@property(nonatomic,assign,readonly) MSIMNetStatus connStatus;//tcp连接状态

///更新同步会话时间
- (void)updateChatListUpdateTime:(NSInteger)updateTime;

+ (instancetype)sharedInstance;

///IM连接状态监听器
@property(nonatomic,weak) id<MSIMSDKListener> connListener;

///收发c2c消息监听器
@property(nonatomic,weak) id<MSIMMessageListener> msgListener;

///收到聊天室消息监听器
@property(nonatomic,weak) id<MSIMChatRoomMessageListener> chatRoomMsgListener;

///会话列表监听器
@property(nonatomic,weak) id<MSIMConversationListener> convListener;

///profile信息变更监听器
@property(nonatomic,weak) id<MSIMProfileListener> profileListener;

///文件上传服务
@property(nonatomic,weak) id<MSUploadMediator> uploadMediator;

///初始化 SDK 并设置 MSIMSDKListener 的监听对象
///initSDK 后 SDK 会自动连接网络，网络连接状态可以在 MSIMSDKListener 回调里面监听
- (void)initSDK:(IMSDKConfig *)config listener:(id<MSIMSDKListener>)listener;

///反初始化 SDK
- (void) unInitSDK;

///登录需要用户签名 token
- (void)login:(NSString *)userSign
        imUrl:(NSString *)imUrl
     subAppID:(NSInteger)subID
         succ:(MSIMSucc)succ
       failed:(MSIMFail)fail;

///退出登录
- (void)logout:(MSIMSucc)succ
        failed:(MSIMFail)fail;

///更新推送的token. device_token为空时，表示推送权限关闭，不接受推送
///voip_token device_token为空时，表示不走voip推送通道
- (void)refreshPushToken:(nullable NSString *)device_token voipToken: (nullable NSString *)voip_token;


@end

NS_ASSUME_NONNULL_END
