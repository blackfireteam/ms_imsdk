//
//  IMSDKConfig.m
//  BlackFireIM
//
//  Created by benny wang on 2021/2/25.
//

#import <MSIMSDK/IMSDKConfig.h>


@implementation IMSDKConfig

+ (instancetype)defaultConfig
{
    IMSDKConfig *config = [[IMSDKConfig alloc]init];
    config.heartDuration = 30;
    config.chatListPageCount = 50;
    config.objectCleanDay = 7;
    config.logEnable = YES;
    return config;
}

- (instancetype)init
{
    if (self = [super init]) {
        _isProduct = YES;
    }
    return self;
}

- (void)setLogEnable:(BOOL)logEnable
{
    _logEnable = logEnable;
    [[NSUserDefaults standardUserDefaults]setBool:logEnable forKey:@"kLogEnable"];
}

//写入保护
- (void)setHeartDuration:(NSInteger)heartDuration
{
    _heartDuration = MAX(heartDuration, 5);
    _heartDuration = MIN(_heartDuration, 4*60);
}

- (void)setRetryCount:(NSInteger)retryCount
{
    _retryCount = MAX(1, retryCount);
}

- (void)setObjectCleanDay:(NSInteger)objectCleanDay
{
    if (objectCleanDay <= 0) {
        _objectCleanDay = -1;
    }else {
        _objectCleanDay = objectCleanDay;
    }
}

- (void)setIsProduct:(BOOL)isProduct
{
    _isProduct = isProduct;
    [[NSUserDefaults standardUserDefaults]setBool:!isProduct forKey:@"ms_Test"];
}


@end
