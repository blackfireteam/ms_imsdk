//
//  NSFileManager+filePath.h
//  BlackFireIM
//
//  Created by benny wang on 2021/3/2.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSFileManager (filePath)

///聊天数据库
+ (NSString *)pathDBMessage;

///能用数据库
+ (NSString *)pathDBCommon;

///自定义数据库
+ (NSString *)pathDBCustom;


///聊天图片保存地址
+ (NSString *)pathForIMImage;

///聊天音频保存地址
+ (NSString *)pathForIMVoice;

///聊天视频保存地址
+ (NSString *)pathForIMVideo;

@end

NS_ASSUME_NONNULL_END
