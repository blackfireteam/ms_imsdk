//
//  MSChatRoomInfo.m
//  BlackFireIM
//
//  Created by benny wang on 2021/10/29.
//

#import "MSGroupInfo.h"
#import "MSProfileProvider.h"


@implementation MSGroupInfo

- (NSInteger)onlineCount
{
    return self.members.count;
}

@end

@implementation MSGroupEvent


@end

@implementation MSGroupMemberItem

- (MSProfileInfo *)profile
{
    return [[MSProfileProvider provider]providerProfileFromLocal:self.uid];
}

@end


@implementation MSGroupTipEvent



@end

