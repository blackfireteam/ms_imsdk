//
//  MSIMManager+Message.m
//  BlackFireIM
//
//  Created by benny wang on 2021/2/26.
//

#import "MSIMManager+Message.h"
#import "MSIMTools.h"
#import "MSIMErrorCode.h"
#import "MSDBFileRecordStore.h"
#import "NSString+Ext.h"
#import "NSFileManager+filePath.h"
#import "MSIMManager+Parse.h"
#import "ChatProtobuf.pbobjc.h"
#import "MSConversationProvider.h"
#import "MSIMManager+Internal.h"
#import "MSIMMessage+Internal.h"

@implementation MSIMManager (Message)

/** 创建文本消息*/
- (MSIMMessage *)createTextMessage:(NSString *)text
{
    MSIMMessage *message = [[MSIMMessage alloc]init];
    MSIMTextElem *elem = [[MSIMTextElem alloc]init];
    elem.text = text;
    message.type = MSIM_MSG_TYPE_TEXT;
    message.elem = elem;
    [self initDefault:message];
    return message;
}

/** 创建图片消息*/
- (MSIMMessage *)createImageMessage:(NSString *)imagePath identifierID:(nullable NSString *)identifierID
{
    MSIMMessage *message = [[MSIMMessage alloc]init];
    MSIMImageElem *elem = [[MSIMImageElem alloc]init];
    elem.path = imagePath;
    if ([[NSFileManager defaultManager]fileExistsAtPath:imagePath]) {
        UIImage *image = [UIImage imageWithContentsOfFile:imagePath];
        elem.width = image.size.width;
        elem.height = image.size.height;
    }
    elem.uuid = identifierID;
    message.elem = elem;
    message.type = MSIM_MSG_TYPE_IMAGE;
    [self initDefault:message];
    return message;
}

/** 创建音频消息*/
- (MSIMMessage *)createVoiceMessage:(NSString *)audioFilePath duration:(NSInteger)duration
{
    MSIMMessage *message = [[MSIMMessage alloc]init];
    MSIMVoiceElem *elem = [[MSIMVoiceElem alloc]init];
    elem.path = audioFilePath;
    elem.duration = duration;
    message.elem = elem;
    message.type = MSIM_MSG_TYPE_VOICE;
    [self initDefault:message];
    return message;
}

/** 创建视频消息*/
- (MSIMMessage *)createVideoMessage:(NSString *)videoFilePath
                               type:(NSString *)type
                           duration:(NSInteger)duration
                       snapshotPath:(NSString *)snapshotPath
                       identifierID:(nullable NSString *)identifierID
{
    MSIMMessage *message = [[MSIMMessage alloc]init];
    MSIMVideoElem *elem = [[MSIMVideoElem alloc]init];
    elem.videoPath = videoFilePath;
    elem.coverPath = snapshotPath;
    if ([[NSFileManager defaultManager]fileExistsAtPath:snapshotPath]) {
        UIImage *coverImage = [UIImage imageWithContentsOfFile:snapshotPath];
        elem.width = coverImage.size.width;
        elem.height = coverImage.size.height;
        elem.coverImage = coverImage;
    }
    elem.uuid = identifierID;
    elem.duration = duration;
    message.elem = elem;
    message.type = MSIM_MSG_TYPE_VIDEO;
    [self initDefault:message];
    return message;
}

/** 创建位置消息
 */
- (MSIMMessage *)createLocationMessage:(MSIMLocationElem *)elem
{
    MSIMMessage *message = [[MSIMMessage alloc]init];
    message.type = MSIM_MSG_TYPE_LOCATION;
    message.elem = elem;
    [self initDefault:message];
    return message;
}

/** 创建自定义表情消息
 */
- (MSIMMessage *)createEmotionMessage:(MSIMEmotionElem *)elem
{
    MSIMMessage *message = [[MSIMMessage alloc]init];
    message.type = MSIM_MSG_TYPE_EMOTION;
    message.elem = elem;
    [self initDefault:message];
    return message;
}

/** 创建自定义消息 */
- (MSIMMessage *)createCustomMessage:(NSString *)jsonStr option:(MSIMCustomOption)option pushExt:(nullable MSIMPushInfo *)pushExt
{
    MSIMMessage *message = [[MSIMMessage alloc]init];
    MSIMCustomElem *elem = [[MSIMCustomElem alloc]init];
    elem.jsonStr = jsonStr;
    elem.option = option;
    elem.pushExt = pushExt;
    message.type = option;
    message.elem = elem;
    [self initDefault:message];
    return message;
}

/** 创建走voip通道的消息 */
- (MSIMMessage *)createVoipMessage:(NSString *)jsonStr
                            option:(MSIMCustomOption)option
                           pushExt:(nullable MSIMPushInfo *)pushExt
{
    MSIMMessage *message = [[MSIMMessage alloc]init];
    MSIMCustomElem *elem = [[MSIMCustomElem alloc]init];
    elem.jsonStr = jsonStr;
    elem.option = option;
    elem.pushExt = pushExt;
    message.type = option + 8;
    message.elem = elem;
    [self initDefault:message];
    return message;
}

- (void)initDefault:(MSIMMessage *)message
{
    message.fromUid = [MSIMTools sharedInstance].user_id;
    message.sendStatus = MSIM_MSG_STATUS_SENDING;
    message.readStatus = MSIM_MSG_STATUS_UNREAD;
    message.msgSign = [MSIMTools sharedInstance].adjustLocalTimeInterval;
}

/** 发送单聊消息*/
- (void)sendC2CMessage:(MSIMMessage *)message
            toReciever:(NSString *)reciever
             successed:(void(^)(NSInteger msg_id))success
                failed:(MSIMFail)failed
{
    if (message == nil) {
        failed(ERR_USER_SEND_EMPTY,@"message is nill");
        return;
    }
    if (reciever == nil || message.msgSign == 0) {
        failed(ERR_USER_PARAMS_ERROR,@"params error");
        return;
    }
    message.toUid = reciever;
    if (message.type == MSIM_MSG_TYPE_TEXT) {
        [self sendTextMessage:message isResend:NO successed:success failed:failed];
    }else if (message.type == MSIM_MSG_TYPE_IMAGE) {
        [self sendImageMessage:message isResend:NO successed:success failed:failed];
    }else if (message.type == MSIM_MSG_TYPE_VIDEO) {
        [self sendVideoMessage:message isResend:NO successed:success failed:failed];
    }else if (message.type == MSIM_MSG_TYPE_VOICE) {
        [self sendVoiceMessage:message isResend:NO successed:success failed:failed];
    }else if (message.type == MSIM_MSG_TYPE_LOCATION) {
        [self sendLocationMessage:message isResend:NO successed:success failed:failed];
    }else if (message.type == MSIM_MSG_TYPE_EMOTION) {
        [self sendEmotionMessage:message isResend:NO successed:success failed:failed];
    }else if (message.type == MSIM_MSG_TYPE_CUSTOM_SIGNAL) {
        [self sendSignalMessage:message successed:success failed:failed];
    }else if (message.type == MSIM_MSG_TYPE_CUSTOM_SIGNAL + 8) {
        message.type -= 8;
        [self sendVoipSignalMessage:message successed:success failed:failed];
    }else if (message.type == MSIM_MSG_TYPE_CUSTOM_IGNORE_UNREADCOUNT_RECALL
              || message.type == MSIM_MSG_TYPE_CUSTOM_UNREADCOUNT_NO_RECALL
              || message.type == MSIM_MSG_TYPE_CUSTOM_UNREADCOUNT_RECAL) {
        [self sendNormalCustomMessage:message isResend:NO  successed:success failed:failed];
    }else if (message.type == MSIM_MSG_TYPE_CUSTOM_IGNORE_UNREADCOUNT_RECALL + 8
              || message.type == MSIM_MSG_TYPE_CUSTOM_UNREADCOUNT_NO_RECALL + 8
              || message.type == MSIM_MSG_TYPE_CUSTOM_UNREADCOUNT_RECAL + 8) {
        message.type -= 8;
        [self sendVoipCustomMessage:message isResend:NO  successed:success failed:failed];
    }else {
        failed(ERR_USER_PARAMS_ERROR,@"sendC2CMessage params error");
    }
}

/// 发送单聊普通文本消息
- (void)sendTextMessage:(MSIMMessage *)message
               isResend:(BOOL)isResend
              successed:(void(^)(NSInteger msg_id))success
                 failed:(void(^)(NSInteger code,NSString *errorString))failed
{
    if (message.textElem.text.length == 0) {
        failed(ERR_USER_PARAMS_ERROR,@"text is empty");
        return;
    }
    if ([message.textElem.text dataUsingEncoding:NSUTF8StringEncoding].length > 8 * 1024) {
        failed(ERR_IM_TEXT_MAX_ERROR,@"text exceed max limit");
        return;
    }
    if (isResend == NO) {
        [self.messageStore addMessage:message];
        [self.msgListener onNewMessages:@[message]];
        [self elemNeedToUpdateConversations:@[message] increaseUnreadCount:@[@(NO)] isConvLastMessage:NO];
    }
    ChatS *chats = [[ChatS alloc]init];
    chats.sign = message.msgSign;
    chats.type = message.type;
    chats.body = message.textElem.text;
    chats.toUid = message.toUid.integerValue;
    chats.flash = message.isSnapChat;
    WS(weakSelf)
    MSLog(@"[发送文本消息]ChatS:\n%@",chats);
    [self.socket send:[chats data] protoType:XMChatProtoTypeSend needToEncry:NO sign:chats.sign callback:^(NSInteger code, id  _Nullable response, NSString * _Nullable error) {
        STRONG_SELF(strongSelf)
        dispatch_async(dispatch_get_main_queue(), ^{
            if (code == ERR_SUCC) {
                ChatSR *result = response;
                if (success) success(result.msgId);
                [strongSelf sendMessageSuccessHandler:message response:result];
            }else {
                if (failed) failed(code,error);
                [strongSelf sendMessageFailedHandler:message code:code error:error];
            }
        });
    }];
}

/// 发送单聊普通图片消息
- (void)sendImageMessage:(MSIMMessage *)message
                isResend:(BOOL)isResend
               successed:(void(^)(NSInteger msg_id))success
                  failed:(void(^)(NSInteger code,NSString *errorString))failed
{
    if ([[NSFileManager defaultManager]fileExistsAtPath:message.imageElem.path]) {
        message.imageElem.size = (NSInteger)[[[NSFileManager defaultManager] attributesOfItemAtPath:message.imageElem.path error:nil] fileSize];
    }
    if (message.imageElem.size > 28 * 1024 * 1024 ) {
        failed(ERR_IM_IMAGE_MAX_ERROR,@"image data exceed max limit");
        return;
    }
    if (isResend == NO) {
        [self.msgListener onNewMessages:@[message]];
        [self.messageStore addMessage:message];
        [self elemNeedToUpdateConversations:@[message] increaseUnreadCount:@[@(NO)] isConvLastMessage:NO];
    }
    if (message.imageElem.url.length == 0 || ![message.imageElem.url hasPrefix:@"http"]) {
        if (message.imageElem.uuid.length > 0) {
            MSDBFileRecordStore *store = [[MSDBFileRecordStore alloc]init];
            MSFileInfo *cacheElem = [store searchRecord:message.imageElem.uuid];
            if ([cacheElem.url hasPrefix:@"http"]) {
                message.imageElem.url = cacheElem.url;
                [self sendImageMessageByTCP:message successed:success failed:failed];
            }else {
                [self uploadImage:message successed:success failed:failed];
            }
        }else {
            [self uploadImage:message successed:success failed:failed];
        }
        return;
    }
    [self sendImageMessageByTCP:message successed:success failed:failed];
}

- (void)uploadImage:(MSIMMessage *)message
          successed:(void(^)(NSInteger msg_id))success
             failed:(void(^)(NSInteger code,NSString *errorString))failed
{
    WS(weakSelf)
    [self.uploadMediator ms_uploadWithObject:message.imageElem.image ? message.imageElem.image : message.imageElem.path
                                    fileType:MSUploadFileTypeImage
                                    progress:^(CGFloat progress) {
        message.imageElem.progress = progress;
        [weakSelf.msgListener onMessageUpdate:message];
    }
                                        succ:^(NSString * _Nonnull url) {
        message.imageElem.progress = 1;
        message.imageElem.url = url;
        if (message.imageElem.uuid.length) {
            MSDBFileRecordStore *store = [[MSDBFileRecordStore alloc]init];
            MSFileInfo *info = [[MSFileInfo alloc]init];
            info.uuid = message.imageElem.uuid;
            info.url = message.imageElem.url;
            info.modTime = [MSIMTools sharedInstance].adjustLocalTimeInterval;
            [store addRecord:info];
        }
        //上传成功，清除沙盒中的缓存
        [[NSFileManager defaultManager]removeItemAtPath:message.imageElem.path error:nil];
        
        [weakSelf.messageStore addMessage:message];
        [weakSelf.msgListener onMessageUpdate:message];
        [weakSelf elemNeedToUpdateConversations:@[message] increaseUnreadCount:@[@(NO)] isConvLastMessage:NO];
        [weakSelf sendImageMessageByTCP:message successed:success failed:failed];
    }
                                        fail:^(NSInteger code, NSString * _Nonnull desc) {
        message.imageElem.progress = 0;
        [weakSelf sendMessageFailedHandler:message code:code error:desc];
        if (failed) failed(code,desc);
    }];
}

- (void)sendImageMessageByTCP:(MSIMMessage *)message
                    successed:(void(^)(NSInteger msg_id))success
                       failed:(void(^)(NSInteger code,NSString *errorString))failed
{
    ChatS *chats = [[ChatS alloc]init];
    chats.sign = message.msgSign;
    chats.type = message.type;
    chats.body = message.imageElem.url;
    chats.toUid = message.toUid.integerValue;
    chats.width = message.imageElem.width;
    chats.height = message.imageElem.height;
    chats.flash = message.isSnapChat;
    WS(weakSelf)
    MSLog(@"[发送图片消息]ChatS:\n%@",chats);
    [self.socket send:[chats data] protoType:XMChatProtoTypeSend needToEncry:NO sign:chats.sign callback:^(NSInteger code, id  _Nullable response, NSString * _Nullable error) {
        STRONG_SELF(strongSelf)
        dispatch_async(dispatch_get_main_queue(), ^{
            if (code == ERR_SUCC) {
                ChatSR *result = response;
                [strongSelf sendMessageSuccessHandler:message response:result];
                if (success) success(result.msgId);
            }else {
                if (failed) failed(code,error);
                [strongSelf sendMessageFailedHandler:message code:code error:error];
            }
        });
    }];
}

/// 发送单聊普通视频消息
- (void)sendVideoMessage:(MSIMMessage *)message
                isResend:(BOOL)isResend
               successed:(void(^)(NSInteger msg_id))success
                  failed:(void(^)(NSInteger code,NSString *errorString))failed
{
    if ([[NSFileManager defaultManager]fileExistsAtPath:message.videoElem.videoPath]) {
        message.videoElem.size = (NSInteger)[[[NSFileManager defaultManager] attributesOfItemAtPath:message.videoElem.videoPath error:nil] fileSize];
    }
    if (message.videoElem.size > 100 * 1024 * 1024) {
        failed(ERR_IM_VIDEO_MAX_ERROR,@"video data exceed max limit");
        return;
    }
    if (isResend == NO) {
        [self.msgListener onNewMessages:@[message]];
        [self.messageStore addMessage:message];
        [self elemNeedToUpdateConversations:@[message] increaseUnreadCount:@[@(NO)] isConvLastMessage:NO];
    }
    if (!([message.videoElem.videoUrl hasPrefix:@"http"] && [message.videoElem.coverUrl hasPrefix:@"http"])) {
        if (message.videoElem.uuid.length > 0) {
            MSDBFileRecordStore *store = [[MSDBFileRecordStore alloc]init];
            MSFileInfo *cacheElem = [store searchRecord:message.videoElem.uuid];
            if ([cacheElem.url hasPrefix:@"http"] && [cacheElem.coverUrl hasPrefix:@"http"]) {
                message.videoElem.videoUrl = cacheElem.url;
                message.videoElem.coverUrl = cacheElem.coverUrl;
                [self sendVideoMessageByTCP:message successed:success failed:failed];
            }else {
                [self uploadVideo:message successed:success failed:failed];
            }
        }else {
            [self uploadVideo:message successed:success failed:failed];
        }
        return;
    }
    [self sendVideoMessageByTCP:message successed:success failed:failed];
}

- (void)uploadVideo:(MSIMMessage *)message
          successed:(void(^)(NSInteger msg_id))success
             failed:(void(^)(NSInteger code,NSString *errorString))failed
{
    WS(weakSelf)
    if ([message.videoElem.videoUrl hasPrefix:@"http"]) {
        //只需要上传图片
        [self.uploadMediator ms_uploadWithObject:message.videoElem.coverImage ? message.videoElem.coverImage : message.videoElem.coverPath
                                        fileType:MSUploadFileTypeImage
                                        progress:^(CGFloat progress) {
            message.videoElem.progress = progress;
            [weakSelf.msgListener onMessageUpdate:message];
        }
                                            succ:^(NSString * _Nonnull url) {
            message.videoElem.progress = 1;
            message.videoElem.coverUrl = url;
            if (message.videoElem.uuid.length) {
                MSDBFileRecordStore *store = [[MSDBFileRecordStore alloc]init];
                MSFileInfo *info = [[MSFileInfo alloc]init];
                info.uuid = message.videoElem.uuid;
                info.url = message.videoElem.videoUrl;
                info.coverUrl = message.videoElem.coverUrl;
                info.modTime = [MSIMTools sharedInstance].adjustLocalTimeInterval;
                [store addRecord:info];
            }
            //上传成功，清除沙盒中的缓存
            [[NSFileManager defaultManager]removeItemAtPath:message.videoElem.coverPath error:nil];
            [[NSFileManager defaultManager]removeItemAtPath:message.videoElem.videoPath error:nil];
            
            [weakSelf.messageStore addMessage:message];
            [weakSelf.msgListener onMessageUpdate:message];
            [weakSelf elemNeedToUpdateConversations:@[message] increaseUnreadCount:@[@(NO)] isConvLastMessage:NO];
            [weakSelf sendVideoMessageByTCP:message successed:success failed:failed];
        }
                                            fail:^(NSInteger code, NSString * _Nonnull desc) {
            message.videoElem.progress = 0;
            [weakSelf sendMessageFailedHandler:message code:code error:desc];
            if (failed) failed(code,desc);
        }];
    }else {
        //先上传图片
        [self.uploadMediator ms_uploadWithObject:message.videoElem.coverImage ? message.videoElem.coverImage : message.videoElem.coverPath
                                        fileType:MSUploadFileTypeImage
                                        progress:^(CGFloat coverProgress) {
            message.videoElem.progress = coverProgress*0.2;
            [weakSelf.msgListener onMessageUpdate:message];
        }
                                            succ:^(NSString * _Nonnull coverUrl) {
            message.videoElem.progress = 0.2;
            message.videoElem.coverUrl = coverUrl;
            //再上传视频
            [self.uploadMediator ms_uploadWithObject:message.videoElem.videoPath fileType:MSUploadFileTypeVideo progress:^(CGFloat videoProgress) {
                message.videoElem.progress = 0.2 + videoProgress*0.8;
                [weakSelf.msgListener onMessageUpdate:message];
            } succ:^(NSString * _Nonnull videoUrl) {
                
                message.videoElem.videoUrl = videoUrl;
                if (message.videoElem.uuid.length) {
                    MSDBFileRecordStore *store = [[MSDBFileRecordStore alloc]init];
                    MSFileInfo *info = [[MSFileInfo alloc]init];
                    info.uuid = message.videoElem.uuid;
                    info.url = message.videoElem.videoUrl;
                    info.coverUrl = message.videoElem.coverUrl;
                    info.modTime = [MSIMTools sharedInstance].adjustLocalTimeInterval;
                    [store addRecord:info];
                }
                //上传成功，清除沙盒中的缓存
                if ([[NSFileManager defaultManager]fileExistsAtPath:message.videoElem.coverPath]) {
                    [[NSFileManager defaultManager]removeItemAtPath:message.videoElem.coverPath error:nil];
                }
                if ([[NSFileManager defaultManager]fileExistsAtPath:message.videoElem.videoPath]) {
                    [[NSFileManager defaultManager]removeItemAtPath:message.videoElem.videoPath error:nil];
                }
                [weakSelf.messageStore addMessage:message];
                [weakSelf.msgListener onMessageUpdate:message];
                [weakSelf elemNeedToUpdateConversations:@[message] increaseUnreadCount:@[@(NO)] isConvLastMessage:NO];
                [weakSelf sendVideoMessageByTCP:message successed:success failed:failed];
                
            } fail:^(NSInteger code, NSString * _Nonnull desc) {
                message.videoElem.progress = 0;
                [weakSelf sendMessageFailedHandler:message code:code error:desc];
                if (failed) failed(code,desc);
            }];
        }
                                            fail:^(NSInteger code, NSString * _Nonnull desc) {
            message.videoElem.progress = 0;
            [weakSelf sendMessageFailedHandler:message code:code error:desc];
            if (failed) failed(code,desc);
        }];
    }
}

- (void)sendVideoMessageByTCP:(MSIMMessage *)message
                    successed:(void(^)(NSInteger msg_id))success
                       failed:(void(^)(NSInteger code,NSString *errorString))failed
{
    ChatS *chats = [[ChatS alloc]init];
    chats.sign = message.msgSign;
    chats.type = message.type;
    chats.body = message.videoElem.videoUrl;
    chats.thumb = message.videoElem.coverUrl;
    chats.toUid = message.toUid.integerValue;
    chats.width = message.videoElem.width;
    chats.height = message.videoElem.height;
    chats.duration = message.videoElem.duration;
    chats.flash = message.isSnapChat;
    WS(weakSelf)
    MSLog(@"[发送视频消息]ChatS:\n%@",chats);
    [self.socket send:[chats data] protoType:XMChatProtoTypeSend needToEncry:NO sign:chats.sign callback:^(NSInteger code, id  _Nullable response, NSString * _Nullable error) {
        STRONG_SELF(strongSelf)
        dispatch_async(dispatch_get_main_queue(), ^{
            if (code == 0) {
                ChatSR *result = response;
                [strongSelf sendMessageSuccessHandler:message response:result];
                if (success) success(result.msgId);
            }else {
                if (failed) failed(code,error);
                [strongSelf sendMessageFailedHandler:message code:code error:error];
            }
        });
    }];
}

/// 发送单聊普通语音消息
- (void)sendVoiceMessage:(MSIMMessage *)message
                isResend:(BOOL)isResend
               successed:(void(^)(NSInteger msg_id))success
                  failed:(void(^)(NSInteger code,NSString *errorString))failed
{
    if ([[NSFileManager defaultManager]fileExistsAtPath:message.voiceElem.path]) {
        message.voiceElem.dataSize = (NSInteger)[[[NSFileManager defaultManager] attributesOfItemAtPath:message.voiceElem.path error:nil] fileSize];
    }
    if (message.voiceElem.dataSize > 28 * 1024 * 1024) {
        failed(ERR_IM_VOICE_MAX_ERROR,@"voice data exceed max limit");
        return;
    }
    if (isResend == NO) {
        [self.msgListener onNewMessages:@[message]];
        [self.messageStore addMessage:message];
        [self elemNeedToUpdateConversations:@[message] increaseUnreadCount:@[@(NO)] isConvLastMessage:NO];
    }
    if (message.voiceElem.url.length == 0 || ![message.voiceElem.url hasPrefix:@"http"]) {
        [self uploadVoice:message successed:success failed:failed];
        return;
    }
    [self sendVoiceMessageByTCP:message successed:success failed:failed];
}

- (void)uploadVoice:(MSIMMessage *)message
          successed:(void(^)(NSInteger msg_id))success
             failed:(void(^)(NSInteger code,NSString *errorString))failed
{
    WS(weakSelf)
    [self.uploadMediator ms_uploadWithObject:message.voiceElem.path fileType:MSUploadFileTypeVoice progress:^(CGFloat progress) {
        
    } succ:^(NSString * _Nonnull url) {
        message.voiceElem.url = url;
        //上传成功，清除沙盒中的缓存
        [[NSFileManager defaultManager]removeItemAtPath:message.voiceElem.path error:nil];
        
        [weakSelf.messageStore addMessage:message];
        [weakSelf.msgListener onMessageUpdate:message];
        [weakSelf elemNeedToUpdateConversations:@[message] increaseUnreadCount:@[@(NO)] isConvLastMessage:NO];
        [weakSelf sendVoiceMessageByTCP:message successed:success failed:failed];
        
    } fail:^(NSInteger code, NSString * _Nonnull desc) {
        [weakSelf sendMessageFailedHandler:message code:code error:desc];
        if (failed) failed(code,desc);
    }];
}

- (void)sendVoiceMessageByTCP:(MSIMMessage *)message
                    successed:(void(^)(NSInteger msg_id))success
                       failed:(void(^)(NSInteger code,NSString *errorString))failed
{
    ChatS *chats = [[ChatS alloc]init];
    chats.sign = message.msgSign;
    chats.type = message.type;
    chats.body = message.voiceElem.url;
    chats.duration = message.voiceElem.duration;
    chats.toUid = message.toUid.integerValue;
    chats.flash = message.isSnapChat;
    WS(weakSelf)
    MSLog(@"[发送语音消息]ChatS:\n%@",chats);
    [self.socket send:[chats data] protoType:XMChatProtoTypeSend needToEncry:NO sign:chats.sign callback:^(NSInteger code, id  _Nullable response, NSString * _Nullable error) {
        STRONG_SELF(strongSelf)
        dispatch_async(dispatch_get_main_queue(), ^{
            if (code == 0) {
                ChatSR *result = response;
                [strongSelf sendMessageSuccessHandler:message response:result];
                if (success) success(result.msgId);
            }else {
                [strongSelf sendMessageFailedHandler:message code:code error:error];
                if (failed) failed(code,error);
            }
        });
    }];
}

/// 发送位置消息
- (void)sendLocationMessage:(MSIMMessage *)message
                   isResend:(BOOL)isResend
                  successed:(void(^)(NSInteger msg_id))success
                     failed:(void(^)(NSInteger code,NSString *errorString))failed
{
    if (message.locationElem.title.length == 0 || message.locationElem.latitude == 0 || message.locationElem.longitude == 0) {
        failed(ERR_USER_PARAMS_ERROR,@"sendLocationMessage params error");
        return;
    }
    if (isResend == NO) {
        [self.messageStore addMessage:message];
        [self.msgListener onNewMessages:@[message]];
        [self elemNeedToUpdateConversations:@[message] increaseUnreadCount:@[@(NO)] isConvLastMessage:NO];
    }
    ChatS *chats = [[ChatS alloc]init];
    chats.sign = message.msgSign;
    chats.type = message.type;
    chats.title = message.locationElem.title;
    chats.body = message.locationElem.detail;
    chats.lat = message.locationElem.latitude;
    chats.lng = message.locationElem.longitude;
    chats.zoom = message.locationElem.zoom;
    chats.toUid = message.toUid.integerValue;
    chats.flash = message.isSnapChat;
    WS(weakSelf)
    MSLog(@"[发送位置消息]ChatS:\n%@",chats);
    [self.socket send:[chats data] protoType:XMChatProtoTypeSend needToEncry:NO sign:chats.sign callback:^(NSInteger code, id  _Nullable response, NSString * _Nullable error) {
        STRONG_SELF(strongSelf)
        dispatch_async(dispatch_get_main_queue(), ^{
            if (code == ERR_SUCC) {
                ChatSR *result = response;
                if (success) success(result.msgId);
                [strongSelf sendMessageSuccessHandler:message response:result];
            }else {
                if (failed) failed(code,error);
                [strongSelf sendMessageFailedHandler:message code:code error:error];
            }
        });
    }];
}


/// 发送自定义表情
- (void)sendEmotionMessage:(MSIMMessage *)message
                  isResend:(BOOL)isResend
                 successed:(void(^)(NSInteger msg_id))success
                    failed:(void(^)(NSInteger code,NSString *errorString))failed
{
    if (message.emotionElem.emotionName.length == 0) {
        failed(ERR_USER_PARAMS_ERROR,@"emotionName is nill");
        return;
    }
    if (isResend == NO) {
        [self.messageStore addMessage:message];
        [self.msgListener onNewMessages:@[message]];
        [self elemNeedToUpdateConversations:@[message] increaseUnreadCount:@[@(NO)] isConvLastMessage:NO];
    }
    ChatS *chats = [[ChatS alloc]init];
    chats.sign = message.msgSign;
    chats.type = message.type;
    chats.thumb = message.emotionElem.emotionUrl;
    chats.title = message.emotionElem.emotionName;
    chats.body = message.emotionElem.emotionID;
    chats.toUid = message.toUid.integerValue;
    chats.flash = message.isSnapChat;
    WS(weakSelf)
    MSLog(@"[发送动画表情义消息]ChatS:\n%@",chats);
    [self.socket send:[chats data] protoType:XMChatProtoTypeSend needToEncry:NO sign:chats.sign callback:^(NSInteger code, id  _Nullable response, NSString * _Nullable error) {
        STRONG_SELF(strongSelf)
        dispatch_async(dispatch_get_main_queue(), ^{
            if (code == ERR_SUCC) {
                ChatSR *result = response;
                if (success) success(result.msgId);
                [strongSelf sendMessageSuccessHandler:message response:result];
            }else {
                if (failed) failed(code,error);
                [strongSelf sendMessageFailedHandler:message code:code error:error];
            }
        });
    }];
}

/// 发送单聊自定义消息-指令消息  不计数，不入库
- (void)sendSignalMessage:(MSIMMessage *)message
                successed:(void(^)(NSInteger msg_id))success
                   failed:(void(^)(NSInteger code,NSString *errorString))failed
{
    if (message.customElem.jsonStr.length == 0) {
        failed(ERR_USER_PARAMS_ERROR,@"sendSignalMessage params error");
        return;
    }
    ChatS *chats = [[ChatS alloc]init];
    chats.sign = message.msgSign;
    chats.type = message.type;
    chats.body = message.customElem.jsonStr;
    chats.toUid = message.toUid.integerValue;
    if (message.customElem.pushExt != nil) {
        chats.pushTitle = message.customElem.pushExt.title;
        chats.pushBody = message.customElem.pushExt.body;
        if (message.customElem.pushExt.isMute) {
            chats.pushSound = @"";
        }else {
            chats.pushSound = message.customElem.pushExt.sound.length ? message.customElem.pushExt.sound : @"default";
        }
    }

    MSLog(@"[发送自定义消息-指令]ChatS:\n%@",chats);
    [self.socket send:[chats data] protoType:XMChatProtoTypeSend needToEncry:NO sign:chats.sign callback:^(NSInteger code, id  _Nullable response, NSString * _Nullable error) {
       
        dispatch_async(dispatch_get_main_queue(), ^{
            if (code == ERR_SUCC) {
                message.sendStatus = MSIM_MSG_STATUS_SEND_SUCC;
                if (success) success(0);
            }else {
                message.sendStatus = MSIM_MSG_STATUS_SEND_FAIL;
                if (failed) failed(code,error);
            }
        });
    }];
}

/// 发送单聊自定义消息-指令消息  不计数，不入库
- (void)sendVoipSignalMessage:(MSIMMessage *)message
                    successed:(void(^)(NSInteger msg_id))success
                       failed:(void(^)(NSInteger code,NSString *errorString))failed
{
    if (message.customElem.jsonStr.length == 0) {
        failed(ERR_USER_PARAMS_ERROR,@"sendSignalMessage params error");
        return;
    }
    ChatS *chats = [[ChatS alloc]init];
    chats.sign = message.msgSign;
    chats.type = message.type + 8;
    chats.body = message.customElem.jsonStr;
    chats.toUid = message.toUid.integerValue;
    if (message.customElem.pushExt != nil) {
        chats.pushTitle = message.customElem.pushExt.title;
        chats.pushBody = message.customElem.pushExt.body;
        if (message.customElem.pushExt.isMute) {
            chats.pushSound = @"";
        }else {
            chats.pushSound = message.customElem.pushExt.sound.length ? message.customElem.pushExt.sound : @"default";
        }
    }

    MSLog(@"[发送自定义消息-指令]ChatS:\n%@",chats);
    [self.socket send:[chats data] protoType:XMChatProtoTypeSend needToEncry:NO sign:chats.sign callback:^(NSInteger code, id  _Nullable response, NSString * _Nullable error) {
       
        dispatch_async(dispatch_get_main_queue(), ^{
            if (code == ERR_SUCC) {
                message.sendStatus = MSIM_MSG_STATUS_SEND_SUCC;
                if (success) success(0);
            }else {
                message.sendStatus = MSIM_MSG_STATUS_SEND_FAIL;
                if (failed) failed(code,error);
            }
        });
    }];
}

/// 发送单聊自定义消息
- (void)sendNormalCustomMessage:(MSIMMessage *)message
                       isResend:(BOOL)isResend
                      successed:(void(^)(NSInteger msg_id))success
                         failed:(void(^)(NSInteger code,NSString *errorString))failed
{
    if (message.customElem.jsonStr.length == 0) {
        failed(ERR_USER_PARAMS_ERROR,@"sendNormalCustomMessage params error");
        return;
    }
    if (isResend == NO) {
        [self.messageStore addMessage:message];
        [self.msgListener onNewMessages:@[message]];
        [self elemNeedToUpdateConversations:@[message] increaseUnreadCount:@[@(NO)] isConvLastMessage:NO];
    }
    ChatS *chats = [[ChatS alloc]init];
    chats.sign = message.msgSign;
    chats.type = message.type;
    chats.body = message.customElem.jsonStr;
    chats.toUid = message.toUid.integerValue;
    chats.flash = message.isSnapChat;
    if (message.customElem.pushExt != nil) {
        chats.pushTitle = message.customElem.pushExt.title;
        chats.pushBody = message.customElem.pushExt.body;
        if (message.customElem.pushExt.isMute) {
            chats.pushSound = nil;
        }else {
            chats.pushSound = message.customElem.pushExt.sound.length ? message.customElem.pushExt.sound : @"default";
        }
    }
    WS(weakSelf)
    MSLog(@"[发送自定义消息]ChatS:\n%@",chats);
    [self.socket send:[chats data] protoType:XMChatProtoTypeSend needToEncry:NO sign:chats.sign callback:^(NSInteger code, id  _Nullable response, NSString * _Nullable error) {
        STRONG_SELF(strongSelf)
        dispatch_async(dispatch_get_main_queue(), ^{
            if (code == ERR_SUCC) {
                ChatSR *result = (ChatSR *)response;
                [strongSelf sendMessageSuccessHandler:message response:result];
                if (success) success(result.msgId);
            }else {
                [strongSelf sendMessageFailedHandler:message code:code error:error];
                if (failed) failed(code,error);
            }
        });
    }];
}

/// 发送单聊自定义消息
- (void)sendVoipCustomMessage:(MSIMMessage *)message
                     isResend:(BOOL)isResend
                    successed:(void(^)(NSInteger msg_id))success
                       failed:(void(^)(NSInteger code,NSString *errorString))failed
{
    if (message.customElem.jsonStr.length == 0) {
        failed(ERR_USER_PARAMS_ERROR,@"sendNormalCustomMessage params error");
        return;
    }
    if (isResend == NO) {
        [self.messageStore addMessage:message];
        [self.msgListener onNewMessages:@[message]];
        [self elemNeedToUpdateConversations:@[message] increaseUnreadCount:@[@(NO)] isConvLastMessage:NO];
    }
    ChatS *chats = [[ChatS alloc]init];
    chats.sign = message.msgSign;
    chats.type = message.type + 8;
    chats.body = message.customElem.jsonStr;
    chats.toUid = message.toUid.integerValue;
    chats.flash = message.isSnapChat;
    if (message.customElem.pushExt != nil) {
        chats.pushTitle = message.customElem.pushExt.title;
        chats.pushBody = message.customElem.pushExt.body;
        if (message.customElem.pushExt.isMute) {
            chats.pushSound = nil;
        }else {
            chats.pushSound = message.customElem.pushExt.sound.length ? message.customElem.pushExt.sound : @"default";
        }
    }
    WS(weakSelf)
    MSLog(@"[发送自定义消息]ChatS:\n%@",chats);
    [self.socket send:[chats data] protoType:XMChatProtoTypeSend needToEncry:NO sign:chats.sign callback:^(NSInteger code, id  _Nullable response, NSString * _Nullable error) {
        STRONG_SELF(strongSelf)
        dispatch_async(dispatch_get_main_queue(), ^{
            if (code == ERR_SUCC) {
                ChatSR *result = (ChatSR *)response;
                [strongSelf sendMessageSuccessHandler:message response:result];
                if (success) success(result.msgId);
            }else {
                [strongSelf sendMessageFailedHandler:message code:code error:error];
                if (failed) failed(code,error);
            }
        });
    }];
}

- (void)sendMessageSuccessHandler:(MSIMMessage *)message response:(ChatSR *)response
{
    message.sendStatus = MSIM_MSG_STATUS_SEND_SUCC;
    message.msgID = response.msgId;
    [self.messageStore addMessage:message];
    [self.msgListener onMessageUpdate:message];
    [self elemNeedToUpdateConversations:@[message] increaseUnreadCount:@[@(NO)] isConvLastMessage:NO];
}

- (void)sendMessageFailedHandler:(MSIMMessage *)message code:(NSInteger)code error:(NSString *)error
{
    message.sendStatus = MSIM_MSG_STATUS_SEND_FAIL;
    message.code = code;
    message.reason = error;
    [self.messageStore addMessage:message];
    [self.msgListener onMessageUpdate:message];
    [self elemNeedToUpdateConversations:@[message] increaseUnreadCount:@[@(NO)] isConvLastMessage:NO];
}

/// 请求撤回某一条消息
- (void)revokeMessage:(NSInteger)msg_id
           toReciever:(NSString *)reciever
            successed:(MSIMSucc)success
               failed:(MSIMFail)failed
{
    if (!reciever || !msg_id) {
        failed(ERR_USER_PARAMS_ERROR,@"revokeMessage params error");
        return;
    }
    ChatAction *action = [[ChatAction alloc]init];
    action.type = MSIM_MSG_TYPE_RECALL_ACTION;
    action.sign = [MSIMTools sharedInstance].adjustLocalTimeInterval;
    action.toUid = reciever.integerValue;
    action.msgId = msg_id;
    MSLog(@"[发送请求消息撤回]ChatAction:\n%@",action);
    [self.socket send:[action data] protoType:XMChatProtoTypeChatActionRequest needToEncry:NO sign:action.sign callback:^(NSInteger code, id  _Nullable response, NSString * _Nullable error) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (code == ERR_SUCC) {
                
                success();
            }else {
                failed(code,error);
            }
        });
    }];
}

/** 单聊消息重发*/
- (void)resendC2CMessage:(MSIMMessage *)message
              toReciever:(NSString *)reciever
               successed:(void(^)(NSInteger msg_id))success
                  failed:(MSIMFail)failed
{
    message.sendStatus = MSIM_MSG_STATUS_SENDING;
    [self.messageStore addMessage:message];
    [self.msgListener onMessageUpdate:message];
    if (message.type == MSIM_MSG_TYPE_TEXT) {
        [self sendTextMessage:message isResend:YES successed:success failed:failed];
    }else if (message.type == MSIM_MSG_TYPE_IMAGE) {
        [self sendImageMessage:message isResend:YES successed:success failed:failed];
    }else if (message.type == MSIM_MSG_TYPE_VIDEO) {
        [self sendVideoMessage:message isResend:YES successed:success failed:failed];
    }else if (message.type == MSIM_MSG_TYPE_VOICE) {
        [self sendVoiceMessage:message isResend:YES successed:success failed:failed];
    }else if (message.type == MSIM_MSG_TYPE_LOCATION) {
        [self sendLocationMessage:message isResend:YES successed:success failed:failed];
    }else if (message.type == MSIM_MSG_TYPE_EMOTION) {
        [self sendEmotionMessage:message isResend:YES successed:success failed:failed];
    }else if (message.type == MSIM_MSG_TYPE_CUSTOM_UNREADCOUNT_RECAL) {
        [self sendNormalCustomMessage:message isResend:YES successed:success failed:failed];
    }else if (message.type == MSIM_MSG_TYPE_CUSTOM_UNREADCOUNT_RECAL + 8) {
        message.type -= 8;
        [self sendVoipCustomMessage:message isResend:YES successed:success failed:failed];
    }else {
        failed(ERR_USER_PARAMS_ERROR,@"resendC2CMessage params error");
    }
}

/** 获取单聊历史消息*/
- (void)getC2CHistoryMessageList:(NSString *)user_id
                           count:(int)count
                         lastMsg:(NSInteger)lastMsgID
                            succ:(BFIMMessageListSucc)succ
                            fail:(MSIMFail)fail
{
    if (user_id.length == 0 || count <= 0) {
        fail(ERR_USER_PARAMS_ERROR,@"getC2CHistoryMessageList params error");
        return;
    }
    NSInteger tempCount = MIN(100, count);
    [self.messageStore messageByPartnerID:user_id last_msg_sign:lastMsgID count:tempCount complete:^(NSArray<MSIMMessage *> * _Nonnull data, BOOL hasMore) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (succ) {
                succ(data,hasMore ? NO : YES);
            }
        });
    }];
}

- (BOOL)deleteMessageFromLocal:(MSIMMessage *)message
{
    NSString *partnerID = message.partnerID;
    if (message.msgSign == 0 || partnerID.length == 0) return NO;
    BOOL isOK = [self.messageStore deleteFromLocalWithMsg_sign:message.msgSign partner_id:partnerID];
    if (isOK) {
        MSIMMessage *message = [self.messageStore lastShowMessage:partnerID];
        MSIMConversation *conv = [[MSConversationProvider provider]providerConversation:partnerID];
        conv.show_msg = message;
        conv.show_msg_sign = message.msgSign;
        conv.time = message.msgSign;
        if (conv) {
            [[MSConversationProvider provider]updateConversations:@[conv]];
            [self.convListener onUpdateConversations:@[conv]];
        }
    }
    return isOK;
}

/** 收到阅后即焚消息已读*/
- (void)readSnapchat:(MSIMMessage *)message
           successed:(nullable MSIMSucc)success
              failed:(nullable MSIMFail)failed
{
    if (!message || !message.msgID || message.isSelf == YES) {
        if(failed) failed(ERR_USER_PARAMS_ERROR,@"readSnapchat params error");
        return;
    }
    ChatAction *action = [[ChatAction alloc]init];
    action.type = MSIM_MSG_TYPE_SNAP_ACTION;
    action.sign = [MSIMTools sharedInstance].adjustLocalTimeInterval;
    action.toUid = message.partnerID.integerValue;
    action.msgId = message.msgID;
    MSLog(@"[发送打开阅后即焚]ChatAction:\n%@",action);
    [self.socket send:[action data] protoType:XMChatProtoTypeChatActionRequest needToEncry:NO sign:action.sign callback:^(NSInteger code, id  _Nullable response, NSString * _Nullable error) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (code == ERR_SUCC) {
                
             if(success) success();
            }else {
              if(failed) failed(code,error);
            }
        });
    }];
}

@end
