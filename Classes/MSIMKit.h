//
//  MSIMKit.h
//  BlackFireIM
//
//  Created by benny wang on 2021/3/19.
//

#import <Foundation/Foundation.h>


NS_ASSUME_NONNULL_BEGIN

@class IMSDKConfig;
@interface MSIMKit : NSObject

/**
 *  共享实例
 */
+ (instancetype)sharedInstance;


- (void)initWithConfig:(IMSDKConfig *)config;


@end

NS_ASSUME_NONNULL_END
