//
//  MSIMTools.h
//  BlackFireIM
//
//  Created by benny wang on 2021/2/26.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN


@interface MSIMTools : NSObject

+ (MSIMTools *)sharedInstance;

@property(nonatomic,copy) NSString * _Nullable user_id;

@property(nonatomic,copy) NSString * _Nullable user_sign;

@property(nonatomic,assign) NSInteger sub_app_id;

@property(nonatomic,assign) NSInteger chatRoomID;

@property(nonatomic,assign,readonly) NSInteger currentLocalTimeInterval;

@property(nonatomic,assign,readonly) NSInteger adjustLocalTimeInterval;

- (void)updateServerTime:(NSInteger)s_time;

///维护会话列表更新时间
- (void)updateConversationTime:(NSInteger)update_time;

///获取会话列表更新时间
- (NSInteger)convUpdateTime;

///清空会话列表更新时间
- (void)cleanConvUpdateTime;

@end

NS_ASSUME_NONNULL_END
