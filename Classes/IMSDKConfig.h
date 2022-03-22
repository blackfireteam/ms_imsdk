//
//  IMSDKConfig.h
//  BlackFireIM
//
//  Created by benny wang on 2021/2/25.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol MSUploadMediator;
@interface IMSDKConfig : NSObject

/** 心跳间隔 默认 ：30s, min: 5s max: 4分钟*/
@property(nonatomic,assign) NSInteger heartDuration;

/** 链接断开，自动重连次数,默认：6次，min: 1次*/
@property(nonatomic,assign) NSInteger retryCount;

/** 会话列表分页拉取数量,默认：50个*/
@property(nonatomic,assign) NSInteger chatListPageCount;

/** 音视频通话是否走voip推送，默认：不开启*/
@property(nonatomic,assign) BOOL voipEnable;

/** 指向IM测试服务器 or 正式服务器 .默认为 YES*/
@property(nonatomic,assign) BOOL isProduct;

/** IM附件服务器存储时长。默认最多存储7天，超过7天的文件会自动清除 默认： 7天。永久存储设置为：-1*/
@property(nonatomic,assign) NSInteger objectCleanDay;

/** 是否需要输出日志，默认：true*/
@property(nonatomic,assign) BOOL logEnable;

@property(nonatomic,weak) id<MSUploadMediator> uploadMediator;

+ (instancetype)defaultConfig;

@end

NS_ASSUME_NONNULL_END
