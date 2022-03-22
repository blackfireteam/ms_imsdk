//
//  MSIMElem.m
//  BlackFireIM
//
//  Created by benny wang on 2021/2/26.
//

#import "MSIMElem.h"
#import "MSIMTools.h"
#import "NSDictionary+Ext.h"
#import "MSProfileProvider.h"


@implementation MSIMElem

- (NSData *)extData
{
    return nil;
}

- (id)copyWithZone:(NSZone *)zone
{
    MSIMElem *elem = [[[self class] allocWithZone:zone]init];
    elem.block_id = self.block_id;
    return elem;
}

@end

@implementation MSIMTextElem

- (id)copyWithZone:(NSZone *)zone
{
    MSIMTextElem *elem = [[[self class] allocWithZone:zone]init];
    elem.text = self.text;
    return elem;
}

- (NSData *)extData
{
    NSDictionary *dic = @{@"text": XMNoNilString(self.text)};
    return [dic el_convertData];
}

@end

@implementation MSIMImageElem

- (NSData *)extData
{
    NSDictionary *dic = @{@"url": XMNoNilString(self.url),@"width": @(self.width),@"height": @(self.height),@"path": XMNoNilString(self.path),@"size": @(self.size),@"uuid": XMNoNilString(self.uuid)};
    return [dic el_convertData];
}

- (id)copyWithZone:(NSZone *)zone
{
    MSIMImageElem *elem = [[[self class] allocWithZone:zone]init];
    elem.url = self.url;
    elem.image = self.image;
    elem.path = self.path;
    elem.width = self.width;
    elem.height = self.height;
    elem.size = self.size;
    elem.uuid = self.uuid;
    return elem;
}


@end

@implementation MSIMVoiceElem

- (NSData *)extData
{
    NSDictionary *dic = @{@"voiceUrl": XMNoNilString(self.url),@"voicePath": XMNoNilString(self.path),@"duration": @(self.duration),@"size":@(self.dataSize)};
    return [dic el_convertData];
}

- (id)copyWithZone:(NSZone *)zone
{
    MSIMVoiceElem *elem = [[[self class] allocWithZone:zone]init];
    elem.path = self.path;
    elem.url = self.url;
    elem.dataSize = self.dataSize;
    elem.duration = self.duration;
    return elem;
}

@end

@implementation MSIMVideoElem

- (NSData *)extData
{
    NSDictionary *dic = @{@"videoUrl": XMNoNilString(self.videoUrl),@"width": @(self.width),@"height": @(self.height),@"videoPath": XMNoNilString(self.videoPath),@"duration": @(self.duration),@"size": @(self.size),@"coverPath":XMNoNilString(self.coverPath),@"coverUrl":XMNoNilString(self.coverUrl),@"uuid": XMNoNilString(self.uuid)};
    return [dic el_convertData];
}

- (id)copyWithZone:(NSZone *)zone
{
    MSIMVideoElem *elem = [[[self class] allocWithZone:zone]init];
    elem.videoUrl = self.videoUrl;
    elem.videoPath = self.videoPath;
    elem.coverUrl = self.coverUrl;
    elem.coverPath = self.coverPath;
    elem.size = self.size;
    elem.width = self.width;
    elem.height = self.height;
    elem.duration = self.duration;
    elem.uuid = self.uuid;
    return elem;
}


@end

@implementation MSIMEmotionElem

- (NSData *)extData
{
    NSDictionary *dic = @{@"emotionID": XMNoNilString(self.emotionID),@"emotionUrl": XMNoNilString(self.emotionUrl),@"emotionName": XMNoNilString(self.emotionName)};
    return [dic el_convertData];
}

- (id)copyWithZone:(NSZone *)zone
{
    MSIMEmotionElem *elem = [[[self class] allocWithZone:zone]init];
    elem.emotionID = self.emotionID;
    elem.emotionUrl = self.emotionUrl;
    elem.emotionName = self.emotionName;
    return elem;
}

@end

@implementation MSIMLocationElem

- (NSData *)extData
{
    NSDictionary *dic = @{@"title": XMNoNilString(self.title),@"detail": XMNoNilString(self.detail),@"longitude": @(self.longitude),@"latitude": @(self.latitude),@"zoom": @(self.zoom)};
    return [dic el_convertData];
}

- (id)copyWithZone:(NSZone *)zone
{
    MSIMLocationElem *elem = [[[self class] allocWithZone:zone]init];
    elem.title = self.title;
    elem.detail = self.detail;
    elem.longitude = self.longitude;
    elem.latitude = self.latitude;
    elem.zoom = self.zoom;
    return elem;
}

@end

@implementation MSIMCustomElem

- (id)copyWithZone:(NSZone *)zone
{
    MSIMCustomElem *elem = [[[self class] allocWithZone:zone]init];
    elem.jsonStr = self.jsonStr;
    elem.option = self.option;
    elem.pushExt = self.pushExt;
    return elem;
}

- (NSData *)extData
{
    NSDictionary *dic = @{@"jsonStr": XMNoNilString(self.jsonStr),@"title": XMNoNilString(self.pushExt.title),@"body": XMNoNilString(self.pushExt.body),@"isMute": @(self.pushExt.isMute),@"sound": self.pushExt.sound};
    return  [dic el_convertData];
}

- (BOOL)canCount
{
    return (self.option == IMCUSTOM_UNREADCOUNT_NO_RECALL || self.option == IMCUSTOM_UNREADCOUNT_RECALL);
}

- (BOOL)canRecall
{
    return (self.option == IMCUSTOM_UNREADCOUNT_RECALL);
}

@end

@implementation MSIMPushInfo

- (instancetype)init
{
    if (self = [super init]) {
        _sound = @"default";
        _isMute = NO;
    }
    return self;
}

@end
