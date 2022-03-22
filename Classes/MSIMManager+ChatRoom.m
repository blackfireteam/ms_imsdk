//
//  MSIMManager+ChatRoom.m
//  MSIMSDK
//
//  Created by benny wang on 2021/10/28.
//

#import "MSIMManager+ChatRoom.h"
#import "ChatProtobuf.pbobjc.h"
#import "MSIMTools.h"
#import "MSIMConst.h"
#import "MSIMManager+Parse.h"
#import "MSIMErrorCode.h"
#import "MSIMManager+Internal.h"
#import "MSGroupInfo.h"
#import "MSChatRoomManager.h"
#import "MSChatRoomManager+Internal.h"

@implementation MSIMManager (ChatRoom)

/// 申请加入聊天室
- (void)joinInChatRoom:(NSInteger)room_id
                  succ:(void (^)(MSGroupInfo *info))succed
                failed:(MSIMFail)failed
{
    if (room_id == 0) {
        failed(ERR_USER_PARAMS_ERROR,@"params error");
        return;
    }
    if ([MSIMTools sharedInstance].chatRoomID && [MSIMTools sharedInstance].chatRoomID != room_id) {
        failed(ERR_USER_PARAMS_ERROR,@"you are already in the other chat room！");
        return;
    }
    JoinGroup *request = [[JoinGroup alloc]init];
    request.id_p = room_id;
    request.gtype = 0;
    request.lastMsgId = MSChatRoomManager.sharedInstance.chatRoomLastMsgID;
    request.sign = [MSIMTools sharedInstance].adjustLocalTimeInterval;
    MSLog(@"[发送消息]申请加入聊天室：%@",request);
    WS(weakSelf)
    [self.socket send:[request data] protoType:XMChatProtoTypeJoinGroupRequest needToEncry:NO sign:request.sign callback:^(NSInteger code, id  _Nullable response, NSString * _Nullable error) {

        dispatch_async(dispatch_get_main_queue(), ^{
            if (code == ERR_SUCC){
                GroupInfo *infoC = response;
                
                NSMutableArray *arr = [NSMutableArray array];
                NSMutableArray *needUpdateProfiles = [NSMutableArray array];
                for (NSInteger i = 0; i < infoC.membersArray.count; i++) {
                    GroupMember *member = infoC.membersArray[i];
                    MSGroupMemberItem *item = [[MSGroupMemberItem alloc]init];
                    item.uid = [NSString stringWithFormat:@"%lld",member.uid];
                    item.role = member.role;
                    item.is_mute = member.isMute;
                    [arr addObject:item];
                    if (item.profile == nil) {
                        MSProfileInfo *info = [[MSProfileInfo alloc]init];
                        info.user_id = [NSString stringWithFormat:@"%lld",member.uid];
                        [needUpdateProfiles addObject:info];
                    }
                }
                if (needUpdateProfiles.count > 0) {
                    [[MSProfileProvider provider]synchronizeProfiles:needUpdateProfiles];
                }
                if (MSChatRoomManager.sharedInstance.chatroomInfo == nil) {
                    MSChatRoomManager.sharedInstance.chatroomInfo = [[MSGroupInfo alloc]init];
                }
                MSChatRoomManager.sharedInstance.chatroomInfo.gtype = infoC.gtype;
                MSChatRoomManager.sharedInstance.chatroomInfo.room_id = [NSString stringWithFormat:@"%lld",infoC.id_p];
                MSChatRoomManager.sharedInstance.chatroomInfo.room_name = infoC.name;
                MSChatRoomManager.sharedInstance.chatroomInfo.max_count = infoC.maxCount;
                MSChatRoomManager.sharedInstance.chatroomInfo.is_mute = infoC.isMute;
                MSChatRoomManager.sharedInstance.chatroomInfo.members = arr;
                MSChatRoomManager.sharedInstance.chatroomInfo.action_tod = infoC.actionTod;
                MSChatRoomManager.sharedInstance.chatroomInfo.action_mute = infoC.actionMute;
                MSChatRoomManager.sharedInstance.chatroomInfo.action_assign = infoC.actionAssign;
                MSChatRoomManager.sharedInstance.chatroomInfo.action_del_msg = infoC.actionDelMsg;
                MSChatRoomManager.sharedInstance.chatroomInfo.action_mute_all = infoC.actionMuteAll;
                succed(MSChatRoomManager.sharedInstance.chatroomInfo);
                [weakSelf sendChatRoomConvUpdate];
                [weakSelf sendEnterChatRoom];
            }else {
                failed(code,error);
            }
        });
    }];
}

- (void)sendChatRoomConvUpdate
{
    if ([self.chatRoomMsgListener respondsToSelector:@selector(onChatRoomConvUpdate)]) {
        [self.chatRoomMsgListener onChatRoomConvUpdate];
    }
}

- (void)sendEnterChatRoom
{
    if ([self.chatRoomMsgListener respondsToSelector:@selector(onEnterChatRoomSuccess)]) {
        [self.chatRoomMsgListener onEnterChatRoomSuccess];
    }
}

/// 退出聊天室
- (void)quitChatRoom:(NSInteger)room_id
                succ:(MSIMSucc)succed
              failed:(MSIMFail)failed
{
    if (room_id == 0) {
        failed(ERR_USER_PARAMS_ERROR,@"params error");
        return;
    }
    // 清空记录的聊天室最后一条消息msg_id
    MSChatRoomManager.sharedInstance.chatRoomLastMsgID = 0;
    [MSIMTools sharedInstance].chatRoomID = 0;
    MSChatRoomManager.sharedInstance.chatroomInfo = nil;
    [self sendChatRoomConvUpdate];
    
    LeaveGroup *request = [[LeaveGroup alloc]init];
    request.id_p = room_id;
    request.gtype = 0;
    request.sign = [MSIMTools sharedInstance].adjustLocalTimeInterval;
    MSLog(@"[发送消息]退出聊天室：%@",request);
    [self.socket send:[request data] protoType:XMChatProtoTypeQuitGroupRequest needToEncry:NO sign:request.sign callback:^(NSInteger code, id  _Nullable response, NSString * _Nullable error) {

        dispatch_async(dispatch_get_main_queue(), ^{
            if (code == ERR_SUCC){
                succed();
            }else {
                failed(code,error);
            }
        });
    }];
}

/// 发送聊天室消息
- (void)sendChatRoomMessage:(MSIMMessage *)message
                   toRoomID:(NSString *)room_id
                  successed:(void(^)(NSInteger msg_id))success
                     failed:(MSIMFail)failed
{
    if (message == nil) {
        failed(ERR_USER_SEND_EMPTY,@"message is nill");
        return;
    }
    if (room_id == nil || message.msgSign == 0) {
        failed(ERR_USER_PARAMS_ERROR,@"params error");
        return;
    }
    message.toUid = room_id;
    message.groupID = room_id;
    message.chatType = MSIM_CHAT_TYPE_CHATROOM;
    if (message.type == MSIM_MSG_TYPE_TEXT) {
        [self sendChatRoomTextMessage:message isResend:NO successed:success failed:failed];
    }else if (message.type == MSIM_MSG_TYPE_IMAGE) {
        [self sendChatRoomImageMessage:message isResend:NO successed:success failed:failed];
    }else if (message.type == MSIM_MSG_TYPE_VIDEO) {
        [self sendChatRoomVideoMessage:message isResend:NO successed:success failed:failed];
    }else if (message.type == MSIM_MSG_TYPE_VOICE) {
        [self sendChatRoomVoiceMessage:message isResend:NO successed:success failed:failed];
    }else if (message.type == MSIM_MSG_TYPE_LOCATION) {
        [self sendChatRoomLocationMessage:message isResend:NO successed:success failed:failed];
    }else if (message.type == MSIM_MSG_TYPE_EMOTION) {
        [self sendChatRoomEmotionMessage:message isResend:NO successed:success failed:failed];
    }else if (message.type == MSIM_MSG_TYPE_CUSTOM_SIGNAL) {
        [self sendChatRoomSignalMessage:message successed:success failed:failed];
    }else if (message.type == MSIM_MSG_TYPE_CUSTOM_IGNORE_UNREADCOUNT_RECALL || message.type == MSIM_MSG_TYPE_CUSTOM_UNREADCOUNT_NO_RECALL || message.type == MSIM_MSG_TYPE_CUSTOM_UNREADCOUNT_RECAL) {
        [self sendChatRoomNormalCustomMessage:message isResend:NO  successed:success failed:failed];
    }else {
        failed(ERR_USER_PARAMS_ERROR,@"params error");
    }
}

/// 发送单聊普通文本消息（最大支持 8KB)
- (void)sendChatRoomTextMessage:(MSIMMessage *)message
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
        [self.chatRoomMsgListener onNewChatRoomMessages:@[message]];
        [MSChatRoomManager.sharedInstance recieveMessages:@[message]];
    }
    GroupChatS *chats = [[GroupChatS alloc]init];
    chats.gtype = 0;
    chats.sign = message.msgSign;
    chats.type = message.type;
    chats.body = message.textElem.text;
    chats.id_p = message.toUid.integerValue;
    WS(weakSelf)
    MSLog(@"[发送聊天室文本消息]ChatS:\n%@",chats);
    [self.socket send:[chats data] protoType:XMChatProtoTypeSendGroupMsgRequest needToEncry:NO sign:chats.sign callback:^(NSInteger code, id  _Nullable response, NSString * _Nullable error) {
        STRONG_SELF(strongSelf)
        dispatch_async(dispatch_get_main_queue(), ^{
            if (code == ERR_SUCC) {
                GroupChatSR *result = response;
                if (success) success(result.msgId);
                [strongSelf sendChatRoomMessageSuccessHandler:message response:result];
            }else {
                if (failed) failed(code,error);
                [strongSelf sendChatRoomMessageFailedHandler:message code:code error:error];
            }
        });
    }];
}

/// 发送单聊普通图片消息
- (void)sendChatRoomImageMessage:(MSIMMessage *)message
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
        [self.chatRoomMsgListener onNewChatRoomMessages:@[message]];
        [MSChatRoomManager.sharedInstance recieveMessages:@[message]];
    }
    if (message.imageElem.url.length == 0 || ![message.imageElem.url hasPrefix:@"http"]) {
        if (message.imageElem.uuid.length > 0) {
            MSDBFileRecordStore *store = [[MSDBFileRecordStore alloc]init];
            MSFileInfo *cacheElem = [store searchRecord:message.imageElem.uuid];
            if ([cacheElem.url hasPrefix:@"http"]) {
                message.imageElem.url = cacheElem.url;
                [self sendChatRoomImageMessageByTCP:message successed:success failed:failed];
            }else {
                [self uploadChatRoomImage:message successed:success failed:failed];
            }
        }else {
            [self uploadChatRoomImage:message successed:success failed:failed];
        }
        return;
    }
    [self sendChatRoomImageMessageByTCP:message successed:success failed:failed];
}

- (void)uploadChatRoomImage:(MSIMMessage *)message
                  successed:(void(^)(NSInteger msg_id))success
                     failed:(void(^)(NSInteger code,NSString *errorString))failed
{
    WS(weakSelf)
    [self.uploadMediator ms_uploadWithObject:message.imageElem.image ? message.imageElem.image : message.imageElem.path
                                    fileType:MSUploadFileTypeImage
                                    progress:^(CGFloat progress) {
        message.imageElem.progress = progress;
        [weakSelf.chatRoomMsgListener onChatRoomMessageUpdate:message];
        [MSChatRoomManager.sharedInstance onChatRoomMessageUpdate:message];
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
        
        [weakSelf.chatRoomMsgListener onChatRoomMessageUpdate:message];
        [MSChatRoomManager.sharedInstance onChatRoomMessageUpdate:message];
        [weakSelf sendChatRoomImageMessageByTCP:message successed:success failed:failed];
    }
                                        fail:^(NSInteger code, NSString * _Nonnull desc) {
        message.imageElem.progress = 0;
        [weakSelf sendChatRoomMessageFailedHandler:message code:code error:desc];
        if (failed) failed(code,desc);
    }];
}

- (void)sendChatRoomImageMessageByTCP:(MSIMMessage *)message
                            successed:(void(^)(NSInteger msg_id))success
                               failed:(void(^)(NSInteger code,NSString *errorString))failed
{
    GroupChatS *chats = [[GroupChatS alloc]init];
    chats.gtype = 0;
    chats.sign = message.msgSign;
    chats.type = message.type;
    chats.body = message.imageElem.url;
    chats.id_p = message.toUid.integerValue;
    chats.width = message.imageElem.width;
    chats.height = message.imageElem.height;
    WS(weakSelf)
    MSLog(@"[发送聊天室图片消息]ChatS:\n%@",chats);
    [self.socket send:[chats data] protoType:XMChatProtoTypeSendGroupMsgRequest needToEncry:NO sign:chats.sign callback:^(NSInteger code, id  _Nullable response, NSString * _Nullable error) {
        STRONG_SELF(strongSelf)
        dispatch_async(dispatch_get_main_queue(), ^{
            if (code == ERR_SUCC) {
                GroupChatSR *result = response;
                [strongSelf sendChatRoomMessageSuccessHandler:message response:result];
                if (success) success(result.msgId);
            }else {
                if (failed) failed(code,error);
                [strongSelf sendChatRoomMessageFailedHandler:message code:code error:error];
            }
        });
    }];
}

/// 发送单聊普通视频消息
- (void)sendChatRoomVideoMessage:(MSIMMessage *)message
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
        [self.chatRoomMsgListener onNewChatRoomMessages:@[message]];
        [MSChatRoomManager.sharedInstance recieveMessages:@[message]];
    }
    if (!([message.videoElem.videoUrl hasPrefix:@"http"] && [message.videoElem.coverUrl hasPrefix:@"http"])) {
        if (message.videoElem.uuid.length > 0) {
            MSDBFileRecordStore *store = [[MSDBFileRecordStore alloc]init];
            MSFileInfo *cacheElem = [store searchRecord:message.videoElem.uuid];
            if ([cacheElem.url hasPrefix:@"http"] && [cacheElem.coverUrl hasPrefix:@"http"]) {
                message.videoElem.videoUrl = cacheElem.url;
                message.videoElem.coverUrl = cacheElem.coverUrl;
                [self sendChatRoomVideoMessageByTCP:message successed:success failed:failed];
            }else {
                [self uploadChatRoomVideo:message successed:success failed:failed];
            }
        }else {
            [self uploadChatRoomVideo:message successed:success failed:failed];
        }
        return;
    }
    [self sendChatRoomVideoMessageByTCP:message successed:success failed:failed];
}

- (void)uploadChatRoomVideo:(MSIMMessage *)message
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
            [weakSelf.chatRoomMsgListener onChatRoomMessageUpdate:message];
            [MSChatRoomManager.sharedInstance onChatRoomMessageUpdate:message];
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
            
            [weakSelf.chatRoomMsgListener onChatRoomMessageUpdate:message];
            [MSChatRoomManager.sharedInstance onChatRoomMessageUpdate:message];
            [weakSelf sendChatRoomVideoMessageByTCP:message successed:success failed:failed];
        }
                                            fail:^(NSInteger code, NSString * _Nonnull desc) {
            message.videoElem.progress = 0;
            [weakSelf sendChatRoomMessageFailedHandler:message code:code error:desc];
            if (failed) failed(code,desc);
        }];
    }else {
        //先上传图片
        [self.uploadMediator ms_uploadWithObject:message.videoElem.coverImage ? message.videoElem.coverImage : message.videoElem.coverPath
                                        fileType:MSUploadFileTypeImage
                                        progress:^(CGFloat coverProgress) {
            message.videoElem.progress = coverProgress*0.2;
            [weakSelf.chatRoomMsgListener onChatRoomMessageUpdate:message];
            [MSChatRoomManager.sharedInstance onChatRoomMessageUpdate:message];
        }
                                            succ:^(NSString * _Nonnull coverUrl) {
            message.videoElem.progress = 0.2;
            message.videoElem.coverUrl = coverUrl;
            //再上传视频
            [self.uploadMediator ms_uploadWithObject:message.videoElem.videoPath fileType:MSUploadFileTypeVideo progress:^(CGFloat videoProgress) {
                message.videoElem.progress = 0.2 + videoProgress*0.8;
                [weakSelf.chatRoomMsgListener onChatRoomMessageUpdate:message];
                [MSChatRoomManager.sharedInstance onChatRoomMessageUpdate:message];
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
                [weakSelf.chatRoomMsgListener onChatRoomMessageUpdate:message];
                [MSChatRoomManager.sharedInstance onChatRoomMessageUpdate:message];
                [weakSelf sendChatRoomVideoMessageByTCP:message successed:success failed:failed];
                
            } fail:^(NSInteger code, NSString * _Nonnull desc) {
                message.videoElem.progress = 0;
                [weakSelf sendChatRoomMessageFailedHandler:message code:code error:desc];
                if (failed) failed(code,desc);
            }];
        }
                                            fail:^(NSInteger code, NSString * _Nonnull desc) {
            message.videoElem.progress = 0;
            [weakSelf sendChatRoomMessageFailedHandler:message code:code error:desc];
            if (failed) failed(code,desc);
        }];
    }
}

- (void)sendChatRoomVideoMessageByTCP:(MSIMMessage *)message
                            successed:(void(^)(NSInteger msg_id))success
                               failed:(void(^)(NSInteger code,NSString *errorString))failed
{
    GroupChatS *chats = [[GroupChatS alloc]init];
    chats.gtype = 0;
    chats.sign = message.msgSign;
    chats.type = message.type;
    chats.body = message.videoElem.videoUrl;
    chats.thumb = message.videoElem.coverUrl;
    chats.id_p = message.toUid.integerValue;
    chats.width = message.videoElem.width;
    chats.height = message.videoElem.height;
    chats.duration = message.videoElem.duration;
    WS(weakSelf)
    MSLog(@"[发送聊天室视频消息]ChatS:\n%@",chats);
    [self.socket send:[chats data] protoType:XMChatProtoTypeSendGroupMsgRequest needToEncry:NO sign:chats.sign callback:^(NSInteger code, id  _Nullable response, NSString * _Nullable error) {
        STRONG_SELF(strongSelf)
        dispatch_async(dispatch_get_main_queue(), ^{
            if (code == 0) {
                GroupChatSR *result = response;
                [strongSelf sendChatRoomMessageSuccessHandler:message response:result];
                if (success) success(result.msgId);
            }else {
                if (failed) failed(code,error);
                [strongSelf sendChatRoomMessageFailedHandler:message code:code error:error];
            }
        });
    }];
}

/// 发送单聊普通语音消息
- (void)sendChatRoomVoiceMessage:(MSIMMessage *)message
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
        [self.chatRoomMsgListener onNewChatRoomMessages:@[message]];
        [MSChatRoomManager.sharedInstance recieveMessages:@[message]];
    }
    if (message.voiceElem.url.length == 0 || ![message.voiceElem.url hasPrefix:@"http"]) {
        [self uploadChatRoomVoice:message successed:success failed:failed];
        return;
    }
    [self sendChatRoomVoiceMessageByTCP:message successed:success failed:failed];
}

- (void)uploadChatRoomVoice:(MSIMMessage *)message
                  successed:(void(^)(NSInteger msg_id))success
                     failed:(void(^)(NSInteger code,NSString *errorString))failed
{
    WS(weakSelf)
    [self.uploadMediator ms_uploadWithObject:message.voiceElem.path fileType:MSUploadFileTypeVoice progress:^(CGFloat progress) {
        
    } succ:^(NSString * _Nonnull url) {
        message.voiceElem.url = url;
        //上传成功，清除沙盒中的缓存
        [[NSFileManager defaultManager]removeItemAtPath:message.voiceElem.path error:nil];
        
        [weakSelf.chatRoomMsgListener onChatRoomMessageUpdate:message];
        [MSChatRoomManager.sharedInstance onChatRoomMessageUpdate:message];
        [weakSelf sendChatRoomVoiceMessageByTCP:message successed:success failed:failed];
        
    } fail:^(NSInteger code, NSString * _Nonnull desc) {
        [weakSelf sendChatRoomMessageFailedHandler:message code:code error:desc];
        if (failed) failed(code,desc);
    }];
}

- (void)sendChatRoomVoiceMessageByTCP:(MSIMMessage *)message
                            successed:(void(^)(NSInteger msg_id))success
                               failed:(void(^)(NSInteger code,NSString *errorString))failed
{
    GroupChatS *chats = [[GroupChatS alloc]init];
    chats.gtype = 0;
    chats.sign = message.msgSign;
    chats.type = message.type;
    chats.body = message.voiceElem.url;
    chats.duration = message.voiceElem.duration;
    chats.id_p = message.toUid.integerValue;
    WS(weakSelf)
    MSLog(@"[发送聊天室语音消息]ChatS:\n%@",chats);
    [self.socket send:[chats data] protoType:XMChatProtoTypeSendGroupMsgRequest needToEncry:NO sign:chats.sign callback:^(NSInteger code, id  _Nullable response, NSString * _Nullable error) {
        STRONG_SELF(strongSelf)
        dispatch_async(dispatch_get_main_queue(), ^{
            if (code == 0) {
                GroupChatSR *result = response;
                [strongSelf sendChatRoomMessageSuccessHandler:message response:result];
                if (success) success(result.msgId);
            }else {
                [strongSelf sendChatRoomMessageFailedHandler:message code:code error:error];
                if (failed) failed(code,error);
            }
        });
    }];
}

- (void)sendChatRoomLocationMessage:(MSIMMessage *)message
                           isResend:(BOOL)isResend
                          successed:(void(^)(NSInteger msg_id))success
                             failed:(void(^)(NSInteger code,NSString *errorString))failed
{
    if (message.locationElem.title.length == 0 || message.locationElem.latitude == 0 || message.locationElem.longitude == 0) {
        failed(ERR_USER_PARAMS_ERROR,@"param error");
        return;
    }
    if (isResend == NO) {
        [self.chatRoomMsgListener onNewChatRoomMessages:@[message]];
        [MSChatRoomManager.sharedInstance recieveMessages:@[message]];
    }
    GroupChatS *chats = [[GroupChatS alloc]init];
    chats.gtype = 0;
    chats.sign = message.msgSign;
    chats.type = message.type;
    chats.body = message.locationElem.detail;
    chats.title = message.locationElem.title;
    chats.lng = message.locationElem.longitude;
    chats.lat = message.locationElem.latitude;
    chats.id_p = message.toUid.integerValue;
    WS(weakSelf)
    MSLog(@"[发送聊天室位置消息]ChatS:\n%@",chats);
    [self.socket send:[chats data] protoType:XMChatProtoTypeSendGroupMsgRequest needToEncry:NO sign:chats.sign callback:^(NSInteger code, id  _Nullable response, NSString * _Nullable error) {
        STRONG_SELF(strongSelf)
        dispatch_async(dispatch_get_main_queue(), ^{
            if (code == 0) {
                GroupChatSR *result = response;
                [strongSelf sendChatRoomMessageSuccessHandler:message response:result];
                if (success) success(result.msgId);
            }else {
                [strongSelf sendChatRoomMessageFailedHandler:message code:code error:error];
                if (failed) failed(code,error);
            }
        });
    }];
}


/// 发送自定义表情
- (void)sendChatRoomEmotionMessage:(MSIMMessage *)message
                          isResend:(BOOL)isResend
                         successed:(void(^)(NSInteger msg_id))success
                            failed:(void(^)(NSInteger code,NSString *errorString))failed
{
    if (message.emotionElem.emotionName.length == 0) {
        failed(ERR_USER_PARAMS_ERROR,@"emotionName is nill");
        return;
    }
    if (isResend == NO) {
        [self.chatRoomMsgListener onNewChatRoomMessages:@[message]];
        [MSChatRoomManager.sharedInstance recieveMessages:@[message]];
    }
    GroupChatS *chats = [[GroupChatS alloc]init];
    chats.gtype = 0;
    chats.sign = message.msgSign;
    chats.type = message.type;
    chats.thumb = message.emotionElem.emotionUrl;
    chats.title = message.emotionElem.emotionName;
    chats.body = message.emotionElem.emotionID;
    chats.id_p = message.toUid.integerValue;
    WS(weakSelf)
    MSLog(@"[发送聊天室动画表情消息]ChatS:\n%@",chats);
    [self.socket send:[chats data] protoType:XMChatProtoTypeSendGroupMsgRequest needToEncry:NO sign:chats.sign callback:^(NSInteger code, id  _Nullable response, NSString * _Nullable error) {
        STRONG_SELF(strongSelf)
        dispatch_async(dispatch_get_main_queue(), ^{
            if (code == ERR_SUCC) {
                GroupChatSR *result = response;
                if (success) success(result.msgId);
                [strongSelf sendChatRoomMessageSuccessHandler:message response:result];
            }else {
                if (failed) failed(code,error);
                [strongSelf sendChatRoomMessageFailedHandler:message code:code error:error];
            }
        });
    }];
}

/// 发送单聊自定义消息-指令消息  不计数，不入库
- (void)sendChatRoomSignalMessage:(MSIMMessage *)message
                        successed:(void(^)(NSInteger msg_id))success
                           failed:(void(^)(NSInteger code,NSString *errorString))failed
{
    if (message.customElem.jsonStr.length == 0) {
        failed(ERR_USER_PARAMS_ERROR,@"params error");
        return;
    }
}

/// 发送单聊自定义消息
- (void)sendChatRoomNormalCustomMessage:(MSIMMessage *)message
                               isResend:(BOOL)isResend
                              successed:(void(^)(NSInteger msg_id))success
                                 failed:(void(^)(NSInteger code,NSString *errorString))failed
{
    if (message.customElem.jsonStr.length == 0) {
        failed(ERR_USER_PARAMS_ERROR,@"params error");
        return;
    }
}

- (void)sendChatRoomMessageSuccessHandler:(MSIMMessage *)message response:(GroupChatSR *)response
{
    // 更新聊天室记录的上次最后一条消息msg_id，用于重连后服务器推历史消息
    if (response.msgId > MSChatRoomManager.sharedInstance.chatRoomLastMsgID) {
        MSChatRoomManager.sharedInstance.chatRoomLastMsgID = response.msgId;
    }
    message.sendStatus = MSIM_MSG_STATUS_SEND_SUCC;
    message.msgID = response.msgId;
    [self.chatRoomMsgListener onChatRoomMessageUpdate:message];
    [MSChatRoomManager.sharedInstance onChatRoomMessageUpdate:message];
}

- (void)sendChatRoomMessageFailedHandler:(MSIMMessage *)message code:(NSInteger)code error:(NSString *)error
{
    message.sendStatus = MSIM_MSG_STATUS_SEND_FAIL;
    message.code = code;
    message.reason = error;
    [self.chatRoomMsgListener onChatRoomMessageUpdate:message];
    [MSChatRoomManager.sharedInstance onChatRoomMessageUpdate:message];
}

/// 聊天室消息重发
- (void)resendChatRoomMessage:(MSIMMessage *)message
                     toRoomID:(NSString *)room_id
                    successed:(void(^)(NSInteger msg_id))success
                       failed:(MSIMFail)failed
{
    message.sendStatus = MSIM_MSG_STATUS_SENDING;
    [self.chatRoomMsgListener onChatRoomMessageUpdate:message];
    if (message.type == MSIM_MSG_TYPE_TEXT) {
        [self sendChatRoomTextMessage:message isResend:YES successed:success failed:failed];
    }else if (message.type == MSIM_MSG_TYPE_IMAGE) {
        [self sendChatRoomImageMessage:message isResend:YES successed:success failed:failed];
    }else if (message.type == MSIM_MSG_TYPE_VIDEO) {
        [self sendChatRoomVideoMessage:message isResend:YES successed:success failed:failed];
    }else if (message.type == MSIM_MSG_TYPE_VOICE) {
        [self sendChatRoomVoiceMessage:message isResend:YES successed:success failed:failed];
    }else if (message.type == MSIM_MSG_TYPE_LOCATION) {
        [self sendChatRoomLocationMessage:message isResend:YES successed:success failed:failed];
    }else if (message.type == MSIM_MSG_TYPE_EMOTION) {
        [self sendChatRoomEmotionMessage:message isResend:YES successed:success failed:failed];
    }else if (message.type == MSIM_MSG_TYPE_CUSTOM_UNREADCOUNT_RECAL) {
        [self sendChatRoomNormalCustomMessage:message isResend:YES successed:success failed:failed];
    }else {
        failed(ERR_USER_PARAMS_ERROR,@"params error");
    }
}

/// 聊天室所有的群成员
- (void)chatRoomMembers:(NSInteger)room_id
              successed:(void(^)(NSArray<MSGroupMemberItem *> *))success
                 failed:(MSIMFail)failed
{
    if (room_id == 0) {
        failed(ERR_USER_PARAMS_ERROR,@"params error");
        return;
    }
    if (room_id != [MSIMTools sharedInstance].chatRoomID) {
        failed(ERR_USER_PARAMS_ERROR,@"params error");
        return;
    }
    if (MSChatRoomManager.sharedInstance.chatroomInfo.members.count == 0) {
        success(@[]);
        return;
    }
    NSMutableArray *filterArr = [NSMutableArray array];
    for (MSGroupMemberItem *item in MSChatRoomManager.sharedInstance.chatroomInfo.members) {
        MSProfileInfo *info = item.profile;
        if (info == nil) {
            [filterArr addObject:item.uid];
        }
    }
    [[MSProfileProvider provider]synchronizeProfiles:filterArr];
    success(MSChatRoomManager.sharedInstance.chatroomInfo.members);
}

/// 修改聊天室公告
- (void)editChatRoomTOD:(NSString *)tod
              toRoom_id:(NSString *)room_id
              successed:(MSIMSucc)success
                 failed:(MSIMFail)failed
{
    if (tod.length == 0) {
        failed(ERR_USER_PARAMS_ERROR,@"tod content is nill");
        return;
    }
    GroupAction *action = [[GroupAction alloc]init];
    action.gtype = 0;
    action.sign = [MSIMTools sharedInstance].adjustLocalTimeInterval;
    action.tod = tod;
    action.action = 0;
    action.id_p = room_id.integerValue;
    MSLog(@"[发送修改聊天室公告]ChatS:\n%@",action);
    [self.socket send:[action data] protoType:XMChatProtoTypeRecieveGroupManagerAction needToEncry:NO sign:action.sign callback:^(NSInteger code, id  _Nullable response, NSString * _Nullable error) {
     
        dispatch_async(dispatch_get_main_queue(), ^{
            if (code == ERR_SUCC) {
                if (success) success();
            }else {
                if (failed) failed(code,error);
            }
        });
    }];
}

/// 全聊天室禁言 或 取消禁言（管理员权限）
- (void)muteChatRoom:(BOOL)is_mute
           toRoom_id:(NSString *)room_id
            duration:(NSInteger)duration
           successed:(MSIMSucc)success
              failed:(MSIMFail)failed
{
    if (room_id.length == 0) {
        failed(ERR_USER_PARAMS_ERROR,@"room_id is nill");
        return;
    }
    GroupAction *action = [[GroupAction alloc]init];
    action.gtype = 0;
    action.sign = [MSIMTools sharedInstance].adjustLocalTimeInterval;
    action.action = is_mute ? 2 : 3;
    action.id_p = room_id.integerValue;
    action.duration = duration;
    MSLog(@"[发送设置聊天室全体禁言]ChatS:\n%@",action);
    [self.socket send:[action data] protoType:XMChatProtoTypeRecieveGroupManagerAction needToEncry:NO sign:action.sign callback:^(NSInteger code, id  _Nullable response, NSString * _Nullable error) {
     
        dispatch_async(dispatch_get_main_queue(), ^{
            if (code == ERR_SUCC) {
                if (success) success();
            }else {
                if (failed) failed(code,error);
            }
        });
    }];
}

/// 只对一批在线用户禁言或恢复发言（管理员权限）
- (void)muteMembers:(NSString *)room_id
               uids:(NSArray<NSNumber *> *)uids
           duration:(NSInteger)duration
             reason:(nullable NSString *)reason
          successed:(MSIMSucc)success
             failed:(MSIMFail)failed
{
    if (room_id.length == 0) {
        failed(ERR_USER_PARAMS_ERROR,@"room_id is nill");
        return;
    }
    GroupAction *action = [[GroupAction alloc]init];
    action.gtype = 0;
    action.sign = [MSIMTools sharedInstance].adjustLocalTimeInterval;
    action.action = 1;
    action.id_p = room_id.integerValue;
    action.reason = reason;
    action.duration = duration;
    GPBInt64Array *arr = [[GPBInt64Array alloc]init];
    for (NSNumber *uid in uids) {
        [arr addValue:uid.integerValue];
    }
    action.uidsArray = arr;
    MSLog(@"[发送设置聊天室成员禁言]ChatS:\n%@",action);
    [self.socket send:[action data] protoType:XMChatProtoTypeRecieveGroupManagerAction needToEncry:NO sign:action.sign callback:^(NSInteger code, id  _Nullable response, NSString * _Nullable error) {
     
        dispatch_async(dispatch_get_main_queue(), ^{
            if (code == ERR_SUCC) {
                if (success) success();
            }else {
                if (failed) failed(code,error);
            }
        });
    }];
}

/// 任命/解除临时管理员（管理员权限）
- (void)editChatroomManagerAccess:(NSString *)room_id
                             uids:(NSArray<NSNumber *> *)uids
                         duration:(NSInteger)duration
                           reason:(nullable NSString *)reason
                        successed:(MSIMSucc)success
                           failed:(MSIMFail)failed
{
    if (room_id.length == 0) {
        failed(ERR_USER_PARAMS_ERROR,@"room_id is nill");
        return;
    }
    GroupAction *action = [[GroupAction alloc]init];
    action.gtype = 0;
    action.sign = [MSIMTools sharedInstance].adjustLocalTimeInterval;
    action.action = 5;
    action.id_p = room_id.integerValue;
    action.reason = reason;
    action.duration = duration;
    GPBInt64Array *arr = [[GPBInt64Array alloc]init];
    for (NSNumber *uid in uids) {
        [arr addValue:uid.integerValue];
    }
    action.uidsArray = arr;
    MSLog(@"[发送任命/解除临时管理员]ChatS:\n%@",action);
    [self.socket send:[action data] protoType:XMChatProtoTypeRecieveGroupManagerAction needToEncry:NO sign:action.sign callback:^(NSInteger code, id  _Nullable response, NSString * _Nullable error) {
     
        dispatch_async(dispatch_get_main_queue(), ^{
            if (code == ERR_SUCC) {
                if (success) success();
            }else {
                if (failed) failed(code,error);
            }
        });
    }];
}

/// 批量删除消息（管理员权限）
- (void)deleteChatroomMsgs:(NSString *)room_id
                    msgIDs:(NSArray<NSNumber *> *)msgIDs
                 successed:(MSIMSucc)success
                    failed:(MSIMFail)failed
{
    if (room_id.length == 0) {
        failed(ERR_USER_PARAMS_ERROR,@"room_id is nill");
        return;
    }
    GroupAction *action = [[GroupAction alloc]init];
    action.gtype = 0;
    action.sign = [MSIMTools sharedInstance].adjustLocalTimeInterval;
    action.action = 4;
    action.id_p = room_id.integerValue;
    GPBInt64Array *arr = [[GPBInt64Array alloc]init];
    for (NSNumber *msgID in msgIDs) {
        [arr addValue:msgID.integerValue];
    }
    action.msgsArray = arr;
    MSLog(@"[发送批量删除聊天室消息]ChatS:\n%@",action);
    [self.socket send:[action data] protoType:XMChatProtoTypeRecieveGroupManagerAction needToEncry:NO sign:action.sign callback:^(NSInteger code, id  _Nullable response, NSString * _Nullable error) {
     
        dispatch_async(dispatch_get_main_queue(), ^{
            if (code == ERR_SUCC) {
                if (success) success();
            }else {
                if (failed) failed(code,error);
            }
        });
    }];
}

/// 聊天室中请求撤回某一条消息
- (void)chatRoomRevokeMessage:(NSInteger)msg_id
                   fromRoomID:(NSString *)room_id
                    successed:(MSIMSucc)success
                       failed:(MSIMFail)failed
{
    if (!room_id || !msg_id) {
        failed(ERR_USER_PARAMS_ERROR,@"params error");
        return;
    }
    GroupRevoke *revoke = [[GroupRevoke alloc]init];
    revoke.sign = [MSIMTools sharedInstance].adjustLocalTimeInterval;
    revoke.id_p = room_id.integerValue;
    revoke.msgId = msg_id;
    revoke.gtype = 0;
    MSLog(@"[发送聊天室撤回消息]:\n%@",revoke);
    [self.socket send:[revoke data] protoType:XMChatProtoTypeGroupMessageRevoke needToEncry:NO sign:revoke.sign callback:^(NSInteger code, id  _Nullable response, NSString * _Nullable error) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (code == ERR_SUCC) {
                
                success();
            }else {
                failed(code,error);
            }
        });
    }];
}

///标记消息已读
///last_msg_id 标记这个消息id之前的消息都为已读
- (void)markChatRoomMessageAsRead:(NSInteger)last_msg_id
                             succ:(MSIMSucc)succed
                           failed:(MSIMFail)failed
{
    if (last_msg_id > 0) {
        MSChatRoomManager.sharedInstance.lastReadMsgID = last_msg_id;
    }
    [MSChatRoomManager.sharedInstance updateUnreadCountTo:0];
    if (succed) succed();
}

@end
