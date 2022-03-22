//
//  BFProfileProvider.m
//  BlackFireIM
//
//  Created by benny wang on 2021/3/15.
//

#import "MSProfileProvider.h"
#import "MSDBProfileStore.h"
#import "ChatProtobuf.pbobjc.h"
#import "MSIMManager.h"
#import "MSIMTools.h"
#import "MSIMErrorCode.h"
#import "MSIMManager+Internal.h"


@interface MSProfileProvider()

@property(nonatomic,strong) NSCache *mainCache;
@property(nonatomic,strong) MSDBProfileStore *store;

///针对相同的查询个人profile请求，去重。
@property(nonatomic,strong) NSMutableDictionary *requestCache;

@end
@implementation MSProfileProvider

///单例
static MSProfileProvider *instance;
+ (instancetype)provider
{
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        instance = [[MSProfileProvider alloc]init];
    });
    return instance;
}

- (NSCache *)mainCache
{
    if (!_mainCache) {
        _mainCache = [[NSCache alloc] init];
        _mainCache.countLimit = 1000; // 限制个数，默认是0，无限空间
        _mainCache.totalCostLimit = 0; // 设置大小设置，默认是0，无限空间
        _mainCache.name = @"profile_cache";
    }
    return _mainCache;
}

- (NSMutableDictionary *)requestCache
{
    if (!_requestCache) {
        _requestCache = [NSMutableDictionary dictionary];
    }
    return _requestCache;
}

- (MSDBProfileStore *)store
{
    if (!_store) {
        _store = [[MSDBProfileStore alloc]init];
    }
    return _store;
}

/// 查询某个用户的个人信息
/// @param uid 用户uid
/// @param completed 异步返回查询结果。
- (void)providerProfile:(NSString *)uid
               complete:(profileBlock)completed
{
    if (uid.length == 0) return;
    MSProfileInfo *p = [self.mainCache objectForKey:uid];
    if (p) {
        completed(p);
    }else {
        //从数据库取
        MSProfileInfo *p1 = [self.store searchProfile:uid];
        if (p1) {
            completed(p1);
            [self.mainCache setObject:p1 forKey:uid];
        }else {
            //服务器请求
            NSMutableArray *blocks = [self.requestCache valueForKey:uid];
            if (blocks) {
                [blocks addObject:completed];
                return;
            }
            blocks = [NSMutableArray array];
            [blocks addObject:completed];
            [self.requestCache setValue:blocks forKey:uid];
            
            GetProfile *getP = [[GetProfile alloc]init];
            getP.uid = [uid integerValue];
            getP.updateTime = 0;
            getP.sign = [MSIMTools sharedInstance].adjustLocalTimeInterval;
            MSLog(@"[发送消息]GetProfile: %@",getP);
            [[MSIMManager sharedInstance].socket send:[getP data] protoType:XMChatProtoTypeGetProfile needToEncry:NO sign:getP.sign callback:^(NSInteger code, id  _Nullable response, NSString * _Nullable error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    MSProfileInfo *info;
                    if (code == ERR_SUCC) {
                        Profile *profile = response;
                        info = [MSProfileInfo createWithProto:profile];
                    }
                    NSArray *tempBlocks = [self.requestCache valueForKey:uid];
                    for (profileBlock block in tempBlocks) {
                        if (block) block(info);
                    }
                    [self.requestCache removeObjectForKey:uid];
                });
            }];
        }
    }
}

///只从本地查询用户的个人信息
- (nullable MSProfileInfo *)providerProfileFromLocal:(NSString *)uid
{
    if (uid.length == 0) return nil;
    MSProfileInfo *p = [self.mainCache objectForKey:uid];
    if (p) {
        return p;
    }else {
        MSProfileInfo *p1 = [self.store searchProfile:uid];
        if (p1) {
            [self.mainCache setObject:p1 forKey:uid];
        }
        return p1;
    }
}

///批量更新用户信息
- (void)updateProfiles:(NSArray<MSProfileInfo *> *)infos
{
    for (MSProfileInfo *info in infos) {
        if (info.user_id.length == 0) {
            continue;
        }
        [self.mainCache setObject:info forKey:info.user_id];
    }
    [self.store addProfiles:infos];
}

- (void)updateSparkProfiles:(NSArray<MSProfileInfo *> *)infos
{
    for (MSProfileInfo *info in infos) {
        MSProfileInfo *cacheInfo = [self providerProfileFromLocal:info.user_id];
        if (cacheInfo == nil) {
            [self.mainCache setObject:info forKey:info.user_id];
            [self.store addProfiles:@[info]];
        }
    }
}

///返回本地数据库中所有的用户信息
- (NSArray<MSProfileInfo *> *)allProfiles
{
    return [self.store allProfiles];
}

///比对update_time与服务器同步更新用户信息
///批量请求，100个一组
- (void)synchronizeProfiles:(NSMutableArray<MSProfileInfo *> *)profiles
{
    [self componentRequestWithProfiles:profiles];
}

- (void)componentRequestWithProfiles:(NSMutableArray *)arr
{
    if (arr.count <= 0) {
        return;
    }
    NSMutableArray *pArr = [NSMutableArray array];
    GetProfiles *request = [[GetProfiles alloc]init];
    for (NSInteger i = 0; i < arr.count; i++) {
        if (i >= 100) {
            break;
        }
        MSProfileInfo *info = arr[i];
        GetProfile *pR = [[GetProfile alloc]init];
        pR.updateTime = info.update_time;
        pR.uid = [info.user_id integerValue];
        [pArr addObject:pR];
    }
    [arr removeObjectsInRange:NSMakeRange(0, pArr.count)];
    request.getProfilesArray = pArr;
    request.sign = [MSIMTools sharedInstance].adjustLocalTimeInterval;
    MSLog(@"[发送消息]GetProfiles:\n%@",request);
    [[MSIMManager sharedInstance].socket send:[request data] protoType:XMChatProtoTypeGetProfiles needToEncry:NO sign:request.sign callback:^(NSInteger code, id  _Nullable response, NSString * _Nullable error) {
        if (code == ERR_SUCC) {
            
        }
    }];
    if (arr.count > 0) {
        [self componentRequestWithProfiles:arr];
    }else {
        MSLog(@"批量同步profile完成");
    }
}

- (void)clean
{
    [self.mainCache removeAllObjects];
}

@end
