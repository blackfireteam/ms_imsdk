//
//  MSProfileInfo.h
//  BlackFireIM
//
//  Created by benny wang on 2021/3/15.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class Profile;
@class Spark;
@interface MSProfileInfo : NSObject

@property(nonatomic,copy) NSString *user_id;

@property(nonatomic,assign) NSInteger update_time;

@property(nonatomic,copy) NSString *nick_name;

@property(nonatomic,copy) NSString *avatar;

@property(nonatomic,assign) BOOL gold;

@property(nonatomic,assign) BOOL verified;

@property(nonatomic,assign) NSInteger gold_exp;

@property(nonatomic,assign) NSInteger gender;

@property(nonatomic,copy) NSString *custom;

+ (MSProfileInfo *)createWithProto:(Profile *)profile;

@end

NS_ASSUME_NONNULL_END
