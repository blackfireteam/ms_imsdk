//
//  MSIMManager+Demo.h
//  BlackFireIM
//
//  Created by benny wang on 2021/4/9.
//
//测试Demo相关的接口
#import <MSIMSDK/MSIMManager.h>

NS_ASSUME_NONNULL_BEGIN

@class MSProfileInfo;
@class MSCOSInfo;
@interface MSIMManager (Demo)

///获取首页Spark相关数据
- (void)getSparks:(void(^)(NSArray<MSProfileInfo *> *sparks))succ
             fail:(MSIMFail)fail;


///模拟获取用户的token  for demo
- (void)getIMToken:(NSString *)phone
              succ:(void(^)(NSString *userToken))succ
            failed:(MSIMFail)fail;


///申请cos上传的临时密钥
- (void)getCOSToken:(void(^)(MSCOSInfo *cosInfo))succ
             failed:(MSIMFail)fail;

///申请声网密钥
- (void)getAgoraToken:(NSString *)channel
                 succ:(void(^)(NSString *app_id,NSString * token))succ
               failed:(MSIMFail)fail;

@end

@interface MSCOSInfo: NSObject

@property(nonatomic,copy) NSString *region;

@property(nonatomic,copy) NSString *bucket;

@property(nonatomic,copy) NSString *secretID;

@property(nonatomic,copy) NSString *secretKey;

@property(nonatomic,copy) NSString *token;

@property(nonatomic,copy,nullable) NSString *other_path;

@property(nonatomic,copy,nullable) NSString *im_path;

@property(nonatomic,assign) NSInteger start_time;

@property(nonatomic,assign) NSInteger exp_time;

@end
NS_ASSUME_NONNULL_END
