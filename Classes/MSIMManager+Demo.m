//
//  MSIMManager+Demo.m
//  BlackFireIM
//
//  Created by benny wang on 2021/4/9.
//

#import "MSIMManager+Demo.h"
#import "MSIMTools.h"
#import "MSIMErrorCode.h"
#import "MSProfileProvider.h"
#import "ChatProtobuf.pbobjc.h"
#import "MSIMManager+Internal.h"


@implementation MSIMManager (Demo)

///获取首页Spark相关数据
- (void)getSparks:(void(^)(NSArray<MSProfileInfo *> *sparks))succ
             fail:(MSIMFail)fail
{
    FetchSpark *request = [[FetchSpark alloc]init];
    request.sign = [MSIMTools sharedInstance].adjustLocalTimeInterval;
    MSLog(@"[发送消息]获取首页Sparks：%@",request);
    [self.socket send:[request data] protoType:XMChatProtoTypeGetSpark needToEncry:NO sign:request.sign callback:^(NSInteger code, id  _Nullable response, NSString * _Nullable error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (code == ERR_SUCC) {
                Sparks *datas = response;
                NSMutableArray *arr = [[NSMutableArray alloc]init];
                for (Profile *s in datas.sparksArray) {
                    MSProfileInfo *info = [MSProfileInfo createWithProto:s];
                    [arr addObject:info];
                }
                [[MSProfileProvider provider]updateSparkProfiles:arr];
                if (succ) succ(arr);
            }else {
                if (fail) fail(code,error);
            }
        });
    }];
}

///模拟获取用户的token  for demo
- (void)getIMToken:(NSString *)phone
              succ:(void(^)(NSString *userToken))succ
            failed:(MSIMFail)fail
{
    GetImToken *token = [[GetImToken alloc]init];
    token.sign = [MSIMTools sharedInstance].adjustLocalTimeInterval;
    token.phone = [phone integerValue];
    MSLog(@"[发送消息]获取im-token：%@",token);
    [self.socket send:[token data] protoType:CMChatProtoTypeGetImToken needToEncry:NO sign:token.sign callback:^(NSInteger code, id  _Nullable response, NSString * _Nullable error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            Result *result = response;
            if (code == ERR_SUCC) {
                if (succ) succ(result.msg);
            }else {
                if (fail) fail(result.code,result.msg);
            }
        });
    }];
}

- (void)getCOSToken:(void(^)(MSCOSInfo *cosInfo))succ
             failed:(MSIMFail)fail
{
    GetCosKey *request = [[GetCosKey alloc]init];
    request.sign = [MSIMTools sharedInstance].adjustLocalTimeInterval;
    MSLog(@"[发送消息]请求cos的临时证书：%@",request);
    [self.socket send:[request data] protoType:XMChatProtoTypeGetCosToken needToEncry:NO sign:request.sign callback:^(NSInteger code, id  _Nullable response, NSString * _Nullable error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            CosKey *result = response;
            if (code == ERR_SUCC) {
                MSCOSInfo *info = [[MSCOSInfo alloc]init];
                info.secretID = result.id_p;
                info.secretKey = result.key;
                info.token = result.token;
                info.im_path = result.path;
                info.other_path = result.pathDemo;
                info.start_time = result.startTime;
                info.exp_time = result.expTime;
                info.region = result.region;
                info.bucket = result.bucket;
                if (succ) succ(info);
            }else {
                if (fail) fail(code,error);
            }
        });
    }];
}

///申请cos上传的临时密钥
- (void)getAgoraToken:(NSString *)channel
                 succ:(void(^)(NSString *app_id,NSString * token))succ
               failed:(MSIMFail)fail
{
    GetAgoraToken *request = [[GetAgoraToken alloc]init];
    request.sign = [MSIMTools sharedInstance].adjustLocalTimeInterval;
    request.channel = channel;
    MSLog(@"[发送消息]请求声网密钥：%@",request);
    [self.socket send:[request data] protoType:XMChatProtoTypeGetAgoraToken needToEncry:NO sign:request.sign callback:^(NSInteger code, id  _Nullable response, NSString * _Nullable error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            AgoraToken *result = response;
            if (code == ERR_SUCC) {
                if (succ) succ(result.appId,result.token);
            }else {
                if (fail) fail(code,error);
            }
        });
    }];
}

@end

@implementation MSCOSInfo


@end
