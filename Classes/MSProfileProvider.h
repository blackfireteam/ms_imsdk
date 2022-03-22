//
//  MSProfileProvider.h
//  BlackFireIM
//
//  Created by benny wang on 2021/3/15.
//
///用户信息提供类。内部有缓存处理。网络->内存->数据库
#import <Foundation/Foundation.h>
#import <MSIMSDK/MSProfileInfo.h>


NS_ASSUME_NONNULL_BEGIN

typedef void (^profileBlock)(MSProfileInfo * __nullable profile);

@interface MSProfileProvider : NSObject

///单例
+ (instancetype)provider NS_SWIFT_NAME(shared());


/// 查询某个用户的个人信息
/// @param uid 用户uid
/// @param completed 异步返回查询结果。
- (void)providerProfile:(NSString *)uid
               complete:(profileBlock)completed;

///只从本地查询用户的个人信息
- (nullable MSProfileInfo *)providerProfileFromLocal:(NSString *)uid;

///批量更新用户信息
- (void)updateProfiles:(NSArray<MSProfileInfo *> *)infos;

///批量缓存spark返回的用户信息，因为spark返回的用户信息字段不全，故特殊处理
- (void)updateSparkProfiles:(NSArray<MSProfileInfo *> *)infos;

///比对update_time与服务器同步更新用户信息
- (void)synchronizeProfiles:(NSMutableArray<MSProfileInfo *> *)profiles;

///返回本地数据库中所有的用户信息
- (NSArray<MSProfileInfo *> *)allProfiles;

- (void)clean;

@end

NS_ASSUME_NONNULL_END
