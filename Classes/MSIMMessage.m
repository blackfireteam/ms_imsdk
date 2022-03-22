//
//  MSIMMessage.m
//  MSIMSDK
//
//  Created by benny wang on 2022/2/11.
//

#import "MSIMMessage.h"
#import "MSIMTools.h"
#import "NSDictionary+Ext.h"
#import "MSIMMessage+Internal.h"


@implementation MSIMMessage

- (BOOL)isSelf
{
    if ([self.fromUid isEqualToString:[MSIMTools sharedInstance].user_id]) {
        return YES;
    }
    return NO;
}

- (NSString *)partnerID
{
    return self.isSelf ? self.toUid : self.fromUid;
}

- (MSProfileInfo *)owner
{
    return [[MSProfileProvider provider]providerProfileFromLocal:self.fromUid];
}

- (MSIMTextElem *)textElem
{
    if (self.type == MSIM_MSG_TYPE_TEXT) {
        return (MSIMTextElem *)self.elem;
    }
    return nil;
}

- (MSIMImageElem *)imageElem
{
    if (self.type == MSIM_MSG_TYPE_IMAGE) {
        return (MSIMImageElem *)self.elem;
    }
    return nil;
}

- (MSIMVoiceElem *)voiceElem
{
    if (self.type == MSIM_MSG_TYPE_VOICE) {
        return (MSIMVoiceElem *)self.elem;
    }
    return nil;
}

- (MSIMVideoElem *)videoElem
{
    if (self.type == MSIM_MSG_TYPE_VIDEO) {
        return (MSIMVideoElem *)self.elem;
    }
    return nil;
}

- (MSIMEmotionElem *)emotionElem
{
    if (self.type == MSIM_MSG_TYPE_EMOTION) {
        return (MSIMEmotionElem *)self.elem;
    }
    return nil;
}

- (MSIMLocationElem *)locationElem
{
    if (self.type == MSIM_MSG_TYPE_LOCATION) {
        return (MSIMLocationElem *)self.elem;
    }
    return nil;
}

- (MSIMCustomElem *)customElem
{
    if (self.type == MSIM_MSG_TYPE_CUSTOM_SIGNAL
        || self.type == MSIM_MSG_TYPE_CUSTOM_SIGNAL + 8
        || self.type == MSIM_MSG_TYPE_CUSTOM_IGNORE_UNREADCOUNT_RECALL
        || self.type == MSIM_MSG_TYPE_CUSTOM_IGNORE_UNREADCOUNT_RECALL + 8
        || self.type == MSIM_MSG_TYPE_CUSTOM_UNREADCOUNT_NO_RECALL
        || self.type == MSIM_MSG_TYPE_CUSTOM_UNREADCOUNT_NO_RECALL + 8
        || self.type == MSIM_MSG_TYPE_CUSTOM_UNREADCOUNT_RECAL
        || self.type == MSIM_MSG_TYPE_CUSTOM_UNREADCOUNT_RECAL + 8) {
        return (MSIMCustomElem *)self.elem;
    }
    return nil;
}

- (id)copyWithZone:(NSZone *)zone
{
    MSIMMessage *msg = [[[self class] allocWithZone:zone]init];
    msg.chatType = self.chatType;
    msg.type = self.type;
    msg.fromUid = self.fromUid;
    msg.toUid = self.toUid;
    msg.groupID = self.groupID;
    msg.msgID = self.msgID;
    msg.msgSign = self.msgSign;
    msg.sendStatus = self.sendStatus;
    msg.readStatus = self.readStatus;
    msg.code = self.code;
    msg.reason = self.reason;
    msg.isSnapChat = self.isSnapChat;
    return msg;
}


@end
