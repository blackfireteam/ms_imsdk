//
//  BFProfileInfo.m
//  BlackFireIM
//
//  Created by benny wang on 2021/3/15.
//

#import "MSProfileInfo.h"
#import "ChatProtobuf.pbobjc.h"


@implementation MSProfileInfo

+ (MSProfileInfo *)createWithProto:(Profile *)profile
{
    MSProfileInfo *info = [[MSProfileInfo alloc]init];
    info.user_id = [NSString stringWithFormat:@"%lld",profile.uid];
    info.nick_name = profile.nickName;
    info.avatar = profile.avatar;
    info.update_time = profile.updateTime;
    info.gold = YES;
    info.verified = YES;
    info.gender = profile.gender;
    info.custom = profile.custom;
    return info;
}


@end
