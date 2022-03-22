//
//  MSIMManager+Parse.m
//  BlackFireIM
//
//  Created by benny wang on 2021/3/16.
//

#import "MSIMManager+Parse.h"
#import "ChatProtobuf.pbobjc.h"
#import "MSProfileProvider.h"
#import "MSIMErrorCode.h"
#import "MSIMConversation.h"
#import "MSIMManager+Message.h"
#import "MSIMTools.h"
#import "MSConversationProvider.h"
#import "MSIMMessageReceipt.h"
#import "MSIMManager+Conversation.h"
#import "MSIMManager+Internal.h"
#import "MSChatRoomManager.h"
#import "MSChatRoomManager+Internal.h"
#import "MSIMMessage+Internal.h"


@implementation MSIMManager (Parse)


- (void)profilesResultHandler:(NSArray<Profile *> *)list
{
    NSMutableArray *arr = [NSMutableArray array];
    for (Profile *p in list) {
        MSProfileInfo *info = [MSProfileInfo createWithProto:p];
        [arr addObject:info];
    }
    [[MSProfileProvider provider] updateProfiles:arr];
    [self.profileListener onProfileUpdates:arr];
}

///服务器返回的会话列表数据处理
- (void)chatListResultHandler:(ChatList *)list
{
    NSArray *items = list.chatItemsArray;
    for (ChatItem *item in items) {
        NSString *partnerID = [NSString stringWithFormat:@"%lld",item.uid];
        MSIMConversation *conv = [[MSConversationProvider provider]providerConversation:partnerID];
        if (conv == nil) {
            conv = [[MSIMConversation alloc]init];
            conv.chat_type = MSIM_CHAT_TYPE_C2C;
            conv.partner_id = partnerID;
            MSCustomExt *ext = [[MSCustomExt alloc]init];
            conv.ext = ext;
        }
        conv.msg_end = item.msgEnd;
        conv.msg_last_read = item.msgLastRead;
        conv.time = item.showMsgTime;
        conv.unread_count = item.unread;
        conv.deleted = item.deleted;
        conv.ext.i_block_u = item.iBlockU;
        [self.convCaches addObject:conv];
        MSProfileInfo *info = [[MSProfileProvider provider] providerProfileFromLocal:partnerID];
        if (info == nil) {
            info = [[MSProfileInfo alloc]init];
            info.update_time = 0;
            info.user_id = partnerID;
        }
        [self.profileCaches addObject:info];
    }
    NSInteger update_time = list.updateTime;
    if (update_time) {//批量下发的会话结束,写入数据库
        //顺便同步下自己的Profile
        MSProfileInfo *me = [[MSProfileProvider provider]providerProfileFromLocal:[MSIMTools sharedInstance].user_id];
        if (!me) {
            me = [[MSProfileInfo alloc]init];
            me.user_id = [MSIMTools sharedInstance].user_id;
        }
        [self.profileCaches addObject:me];
        
        //更新Profile信息
        [[MSProfileProvider provider] synchronizeProfiles:self.profileCaches];
        //更新会话缓存
        [[MSConversationProvider provider]updateConversations:self.convCaches];
        //判断是否是首次同步会话完成
        NSString *isNotFirstConvFinishKey = [NSString stringWithFormat:@"isNotFirstConvFinish_%@",MSIMTools.sharedInstance.user_id];
        BOOL isNotFirstConvFinish = [[NSUserDefaults standardUserDefaults]boolForKey:isNotFirstConvFinishKey];
        if (isNotFirstConvFinish) {
            [self updateConvLastMessage:self.convCaches];
            //通知会话有更新
            if ([self.convListener respondsToSelector:@selector(onUpdateConversations:)]) {
                [self.convListener onUpdateConversations:self.convCaches];
            }
        }else {
//            同步最后一页聊天数据,如果是首次同步会话，有可能会很多，只同步最多50条
            NSArray *firstPageConvs = (self.convCaches.count > self.socket.config.chatListPageCount ? [self.convCaches subarrayWithRange:NSMakeRange(0, self.socket.config.chatListPageCount)] : self.convCaches);
            [self updateConvLastMessage:firstPageConvs];
            //通知会话有更新
            if ([self.convListener respondsToSelector:@selector(onUpdateConversations:)]) {
                [self.convListener onUpdateConversations:firstPageConvs];
            }
            [[NSUserDefaults standardUserDefaults]setBool:YES forKey:isNotFirstConvFinishKey];
        }
        self.isChatListResult = YES;
        [self updateChatListUpdateTime:MAX(self.chatUpdateTime, update_time)];
        
        if ([self.convListener respondsToSelector:@selector(onSyncServerFinish)]) {
            [self.convListener onSyncServerFinish];
        }
        [self.convCaches removeAllObjects];
        [self.profileCaches removeAllObjects];
    }
}

- (void)elemNeedToUpdateConversations:(NSArray<MSIMMessage *> *)messages increaseUnreadCount:(NSArray<NSNumber *> *)increases isConvLastMessage:(BOOL)isConvLastMessage
{
    NSMutableArray *needConvs = [NSMutableArray array];
    for (NSInteger i = 0; i < messages.count; i++) {
        MSIMMessage *message = messages[i];
        NSInteger increaseCount = [increases[i] integerValue];
        BOOL needUpdate = NO;
        MSIMConversation *conv = [[MSConversationProvider provider]providerConversation:message.partnerID];
        if (conv == nil) {
            conv = [[MSIMConversation alloc]init];
            conv.chat_type = MSIM_CHAT_TYPE_C2C;
            conv.partner_id = message.partnerID;
            conv.show_msg = message;
            conv.show_msg_sign = message.msgSign;
            conv.time = message.msgSign;
            conv.msg_end = message.msgID;
        }
        if(message.code > conv.show_msg_sign || message.msgSign > conv.show_msg_sign) {
            conv.show_msg_sign = message.msgSign;
            conv.time = message.msgSign;
            conv.show_msg = message;
            if (message.msgID > conv.msg_end) {
                conv.msg_end = message.msgID;
            }
            needUpdate = YES;
        }
        if (increaseCount) {
            conv.unread_count += increaseCount;
            needUpdate = YES;
        }
        if (isConvLastMessage == NO) {
            conv.deleted = 0;
            needUpdate = YES;
        }
        if (needUpdate) {
            [needConvs addObject:conv];
        }
    }
    if (needConvs.count) {
        [[MSConversationProvider provider]updateConversations:needConvs];
        [self.convListener onUpdateConversations:needConvs];
    }
}

- (void)updateConvLastMessage:(NSArray *)convs
{
    //拉取最后一页聊天记录
    WS(weakSelf)
    NSMutableArray *tempConvs = [NSMutableArray array];
    NSMutableArray *tempIncreases = [NSMutableArray array];
    NSMutableArray *needProfiles = [NSMutableArray array];
    NSInteger convsCount = convs.count;
    __block NSInteger total = 0;
    for (MSIMConversation *conv in convs) {
        MSIMMessage *lastMessage = [self.messageStore lastMessageID:conv.partner_id];
        //如果本地最大的Msgid>服务器msgend时，强制拉最后一页。在服务器清数据时，接收离线消息时会出现
        NSInteger requestID = 0;
        if (lastMessage.msgID == conv.msg_end) {
            continue;
        }
        if (lastMessage.msgID < conv.msg_end) {
            requestID = lastMessage.msgID;
        }
        [self.messageStore requestHistoryMessageFromEnd:0 toStart:requestID partner_Id:conv.partner_id result:^(NSArray<MSIMMessage *> * _Nonnull messages) {
            //重新取出数据表中最后一条消息
            MSIMMessage *lastMsg = [weakSelf.messageStore lastShowMessage:conv.partner_id];
            if (lastMsg) {
                [tempConvs addObject:lastMsg];
                [tempIncreases addObject:@(0)];
            }else {
                MSLog(@"拉取最后一页聊天记录失败");
            }
            MSProfileInfo *profile = [[MSProfileProvider provider]providerProfileFromLocal:conv.partner_id];
            if (profile == nil || profile.update_time == 0) {
                MSProfileInfo *info = [[MSProfileInfo alloc]init];
                info.user_id = conv.partner_id;
                [needProfiles addObject:info];
            }
            total += 1;
            if (total >= convsCount) {
                [weakSelf elemNeedToUpdateConversations:tempConvs increaseUnreadCount:tempIncreases isConvLastMessage: YES];
                [[MSProfileProvider provider]synchronizeProfiles:needProfiles];
                [needProfiles removeAllObjects];
                [tempConvs removeAllObjects];
                [tempIncreases removeAllObjects];
            }
            //与服务器同步下来的聊天记录，通知聊天详情页刷新。很有可能会有消息重复，详情页需要做去重
            if ([self.msgListener respondsToSelector:@selector(onNewMessages:)]) {
                [self.msgListener onNewMessages:messages];
            }
        }];
    }
}

///收到服务器下发的消息处理
- (void)receiveMessageHandler:(NSArray<ChatR *> *)responses
{
    if (responses.count == 0) return;
    NSArray *messages = [self transferChatItem:responses isHistory:NO];
    NSMutableArray *normalElems = [NSMutableArray array];
    NSMutableArray *signalElems = [NSMutableArray array];
    NSMutableArray *tempElems = [NSMutableArray array];
    NSMutableArray *tempUnreads = [NSMutableArray array];
    NSMutableArray *needProfiles = [NSMutableArray array];
    for (NSInteger i = 0; i < messages.count; i++) {
        MSIMMessage *elem = messages[i];
        BOOL isNull = elem.type == MSIM_MSG_TYPE_NULL;
        if (isNull) {
            MSIMMessage *showElem = [self.messageStore lastShowMessage:elem.partnerID];
            showElem.msgID = elem.msgID;
            // 暂时将撤回或删除指令的msgsign用code记录，用于下一步的更新会话
            showElem.code = elem.msgSign;
            elem = showElem;
        }else {
            if (elem.type == MSIM_MSG_TYPE_CUSTOM_SIGNAL) {
                [signalElems addObject:elem];
            }else {
                [normalElems addObject:elem];
            }
        }
        if (elem == nil) continue;
        BOOL isExsit = NO;
        for (NSInteger j = 0; j < tempElems.count; j++) {
            MSIMMessage *tempE = tempElems[j];
            if ([tempE.partnerID isEqualToString:elem.partnerID]) {
                isExsit = YES;
                [tempElems removeObjectAtIndex:j];
                [tempElems insertObject:elem atIndex:j];
                NSInteger tempUnread = [tempUnreads[j] integerValue];
                [tempUnreads removeObjectAtIndex:j];
                [tempUnreads insertObject:((isNull || elem.isSelf || elem.type == MSIM_MSG_TYPE_CUSTOM_IGNORE_UNREADCOUNT_RECALL) ? @(tempUnread) : @(tempUnread+1)) atIndex:j];
                break;
            }
        }
        if (isExsit == NO) {
            if (elem.type != MSIM_MSG_TYPE_CUSTOM_SIGNAL) {
                [tempElems addObject:elem];
                [tempUnreads addObject:((isNull || elem.isSelf || elem.type == MSIM_MSG_TYPE_CUSTOM_IGNORE_UNREADCOUNT_RECALL) ? @(0) : @(1))];
            }
            MSProfileInfo *fromProfile = [[MSProfileProvider provider]providerProfileFromLocal:elem.partnerID];
            if (fromProfile == nil) {
                fromProfile = [[MSProfileInfo alloc]init];
                fromProfile.user_id = elem.partnerID;
            }
            if (fromProfile.update_time < responses[i].sput) {
                [needProfiles addObject:fromProfile];
            }
        }
    }
    [self elemNeedToUpdateConversations:tempElems increaseUnreadCount:tempUnreads isConvLastMessage:NO];
    if (normalElems.count && [self.msgListener respondsToSelector:@selector(onNewMessages:)]) {
        [self.msgListener onNewMessages:normalElems];
    }
    if (signalElems.count && [self.msgListener respondsToSelector:@selector(onRecieveSignalMessages:)]) {
        [self.msgListener onRecieveSignalMessages:signalElems];
    }
    //更新profile
    [[MSProfileProvider provider]synchronizeProfiles:needProfiles];
}

///服务器返回的历史数据处理
- (NSArray<MSIMMessage *> *)chatHistoryHandler:(NSArray<ChatR *> *)responses
{
    NSArray *arr = [self transferChatItem:responses isHistory: YES];
    MSIMMessage *firstMessage = arr.firstObject;
    if (firstMessage.type == MSIM_MSG_TYPE_NULL) {
        MSIMMessage *showMsg = [self.messageStore lastShowMessage:firstMessage.partnerID];
        showMsg.msgID = firstMessage.msgID;
        firstMessage = showMsg;
    }
    if (firstMessage && firstMessage.type != MSIM_MSG_TYPE_CUSTOM_SIGNAL) {
        [self elemNeedToUpdateConversations:@[firstMessage] increaseUnreadCount:@[@(0)] isConvLastMessage:YES];
    }
    return arr;
}

- (NSArray<MSIMMessage *> *)transferChatItem:(NSArray<ChatR *> *)responses isHistory:(BOOL)isHistory
{
    NSMutableArray *recieves = [NSMutableArray array];
    NSMutableArray *stores = [NSMutableArray array];
    for (NSInteger i = 0; i < responses.count; i++) {
        ChatR *response = responses[i];
        NSInteger chatType = response.type;
        MSIMMessage *message = [[MSIMMessage alloc]init];
        MSIMElem *elem = nil;
        //自定义消息
        if (chatType == MSIM_MSG_TYPE_CUSTOM_SIGNAL + 8 || chatType == MSIM_MSG_TYPE_CUSTOM_IGNORE_UNREADCOUNT_RECALL + 8 || chatType == MSIM_MSG_TYPE_CUSTOM_UNREADCOUNT_NO_RECALL + 8 || chatType == MSIM_MSG_TYPE_CUSTOM_UNREADCOUNT_RECAL + 8) {
            chatType -= 8;
        }
        BOOL isCustomMsg = (chatType == MSIM_MSG_TYPE_CUSTOM_SIGNAL || chatType == MSIM_MSG_TYPE_CUSTOM_IGNORE_UNREADCOUNT_RECALL || chatType == MSIM_MSG_TYPE_CUSTOM_UNREADCOUNT_NO_RECALL || chatType == MSIM_MSG_TYPE_CUSTOM_UNREADCOUNT_RECAL);
        BOOL canStore = YES;
        
        if (chatType == MSIM_MSG_TYPE_RECALL_ACTION) {//收到消息撤回指令
            message.type = MSIM_MSG_TYPE_NULL;
            message.fromUid = [NSString stringWithFormat:@"%lld",response.fromUid];
            message.toUid = [NSString stringWithFormat:@"%lld",response.toUid];
            elem = [[MSIMElem alloc]init];
            //将之前的消息标记为撤回消息
            message.elem = elem;
            [self.messageStore updateMessageRevoke:response.body.integerValue partnerID:message.partnerID];
            
            ////再取出数据库更新过的这条消息
            MSIMMessage *revokeMsg = [self.messageStore searchMessage:message.partnerID msg_id:response.body.integerValue];
            //发送消息撤回通知
            if (revokeMsg && [self.msgListener respondsToSelector:@selector(onMessageUpdate:)]) {
                [self.msgListener onMessageUpdate:revokeMsg];
            }
        }else if (chatType == MSIM_MSG_TYPE_SNAP_ACTION) {//收到阅后即焚指令
            message.type = MSIM_MSG_TYPE_NULL;
            message.fromUid = [NSString stringWithFormat:@"%lld",response.fromUid];
            message.toUid = [NSString stringWithFormat:@"%lld",response.toUid];
            elem = [[MSIMElem alloc]init];
            //将之前的消息标记为删除消息
            message.elem = elem;
            [self.messageStore updateMessageSnapchat:response.body.integerValue partnerID:message.partnerID];
            //通知UI删除消息
            if (message.isSelf == NO && [self.msgListener respondsToSelector:@selector(onDeleteMessages:)]) {
                [self.msgListener onDeleteMessages:@[@(response.body.integerValue)]];
            }
            
        }else if (chatType == MSIM_MSG_TYPE_TEXT) {
            message.type = MSIM_MSG_TYPE_TEXT;
            MSIMTextElem *textElem = [[MSIMTextElem alloc]init];
            textElem.text = response.body;
            elem = textElem;
            message.elem = elem;
            
        }else if (chatType == MSIM_MSG_TYPE_IMAGE) {
            message.type = MSIM_MSG_TYPE_IMAGE;
            MSIMImageElem *imageElem = [[MSIMImageElem alloc]init];
            imageElem.width = response.width;
            imageElem.height = response.height;
            imageElem.url = response.body;
            elem = imageElem;
            message.elem = elem;
        }else if (chatType == MSIM_MSG_TYPE_VIDEO) {
            message.type = MSIM_MSG_TYPE_VIDEO;
            MSIMVideoElem *videoElem = [[MSIMVideoElem alloc]init];
            videoElem.width = response.width;
            videoElem.height = response.height;
            videoElem.videoUrl = response.body;
            videoElem.coverUrl = response.thumb;
            videoElem.duration = response.duration;
            elem = videoElem;
            message.elem = elem;
        }else if (chatType == MSIM_MSG_TYPE_VOICE) {
            message.type = MSIM_MSG_TYPE_VOICE;
            MSIMVoiceElem *voiceElem = [[MSIMVoiceElem alloc]init];
            voiceElem.url = response.body;
            voiceElem.duration = response.duration;
            elem = voiceElem;
            message.elem = elem;
        }else if (chatType == MSIM_MSG_TYPE_LOCATION) {
            message.type = MSIM_MSG_TYPE_LOCATION;
            MSIMLocationElem *locationElem = [[MSIMLocationElem alloc]init];
            locationElem.title = response.title;
            locationElem.detail = response.body;
            locationElem.latitude = response.lat;
            locationElem.longitude = response.lng;
            locationElem.zoom = response.zoom;
            elem = locationElem;
            message.elem = elem;
        }else if (chatType == MSIM_MSG_TYPE_EMOTION) {
            message.type = MSIM_MSG_TYPE_EMOTION;
            MSIMEmotionElem *emotionElem = [[MSIMEmotionElem alloc]init];
            emotionElem.emotionID = response.body;
            emotionElem.emotionName = response.title;
            emotionElem.emotionUrl = response.thumb;
            elem = emotionElem;
            message.elem = elem;
        }else if (chatType == MSIM_MSG_TYPE_REVOKE) {
            message.type = MSIM_MSG_TYPE_REVOKE;
            elem = [[MSIMElem alloc]init];
            message.elem = elem;
        }else if (chatType == MSIM_MSG_TYPE_DELETE) {
            message.type = MSIM_MSG_TYPE_NULL;
            elem = [[MSIMElem alloc]init];
            message.elem = elem;
        }else if (isCustomMsg == YES) {
            message.type = chatType;
            MSIMCustomElem *customElem = [[MSIMCustomElem alloc]init];
            customElem.jsonStr = response.body;
            customElem.option = chatType;
            MSIMPushInfo *push = [[MSIMPushInfo alloc]init];
            push.title = response.title;
            push.body = response.pushBody;
            push.sound = response.pushSound;
            customElem.pushExt = push;
            elem = customElem;
            message.elem = elem;
            canStore = (chatType != MSIM_MSG_TYPE_CUSTOM_SIGNAL);
            
        }else {//未知消息
            message.type = MSIM_MSG_TYPE_UNKNOWN;
            MSIMElem *unknowElem = [[MSIMElem alloc]init];
            elem = unknowElem;
            message.elem = elem;
        }
        message.fromUid = [NSString stringWithFormat:@"%lld",response.fromUid];
        message.toUid = [NSString stringWithFormat:@"%lld",response.toUid];
        message.msgID = response.msgId;
        message.isSnapChat = response.flash;
        NSInteger tempSign = 0;
        if (response.sign > 0) {
            tempSign = response.sign;
        }else {
            //防止msgtime重复，保证msg_sign唯一性
            tempSign = response.msgId < 100000 ? response.msgTime + response.msgId : response.msgTime;
        }
        message.msgSign = [self uniqueMsgSign:tempSign];
        message.sendStatus = MSIM_MSG_STATUS_SEND_SUCC;
        MSIMConversation *conv = [[MSConversationProvider provider]providerConversation:message.partnerID];
        if (message.isSelf && message.msgID > conv.msg_last_read) {
            message.readStatus = MSIM_MSG_STATUS_UNREAD;
        }else {
            message.readStatus = MSIM_MSG_STATUS_READ;
        }
        [recieves addObject:message];
        if (canStore) {
            [stores addObject:message];
        }
        //更新会话更新时间
        if (isHistory == NO && message.msgID > 0) {
            [self updateChatListUpdateTime:response.msgTime];
        }
    }
    [self.messageStore addMessages:stores];
    return recieves;
}

///服务器返回的用户上线下线通知处理
- (void)userOnLineChangeHandler:(NSArray *)onlines
{
    if (onlines.count ==0) return;
    NSMutableArray *onlineArr = [NSMutableArray array];
    NSMutableArray *offlineArr = [NSMutableArray array];
    for (id one in onlines) {
        if ([one isKindOfClass:[ProfileOnline class]]) {
            [onlineArr addObject:one];
        }else if ([one isKindOfClass:[UsrOffline class]]) {
            UsrOffline *offline = one;
            [offlineArr addObject:@(offline.uid)];
        }
    }
    if (onlineArr.count) {
        [self userOnLineHandler: onlineArr];
    }
    if (offlineArr.count) {
        [self userOfflineHandler:offlineArr];
    }
}

///服务器返回的用户上线通知处理
- (void)userOnLineHandler:(NSArray<ProfileOnline *> *)onlines
{
    NSMutableArray *arr = [NSMutableArray array];
    NSMutableArray *uids = [NSMutableArray array];
    for (ProfileOnline *online in onlines) {
        MSProfileInfo *info = [[MSProfileInfo alloc]init];
        info.user_id = [NSString stringWithFormat:@"%lld",online.uid];
        info.nick_name = online.nickName;
        info.avatar = online.avatar;
        info.gold = YES;
        info.update_time = online.updateTime;
        info.verified = YES;
        [arr addObject:info];
        [uids addObject:@(online.uid)];
    }
    [[MSProfileProvider provider] updateProfiles:arr];
    [[NSNotificationCenter defaultCenter]postNotificationName:@"MSUIKitNotification_Profile_online" object:uids];
}

///服务器返回的用户下线通知处理
- (void)userOfflineHandler:(NSArray<NSNumber *> *)offlines
{
    [[NSNotificationCenter defaultCenter]postNotificationName:@"MSUIKitNotification_Profile_offline" object:offlines];
}

///会话某些属性发生变更
- (void)chatListChanged:(ChatItemUpdate *)item
{
    if (item.event == 0) {//msg_last_read 变动
        
        [self chatMarkReadChanged:item];
        MSLog(@"[收到]msg_last_read 变动 : %@",item);
    }else if (item.event == 1) {//unread 数变动
        
        [self chatUnreadCountChanged:item];
        MSLog(@"[收到]unread 数变动 : %@",item);
    }else if (item.event == 2) {//i_block_u 变动
        
        [self chatListBlockChanged:item];
        MSLog(@"[收到]i_block_u 变动 : %@",item);
    }else if (item.event == 3) {//deleted 变动
        
        [self deleteChatHandler:item];
        MSLog(@"[收到]deleted 变动 : %@",item);
    }
}

///服务器返回的删除会话的处理
- (void)deleteChatHandler:(ChatItemUpdate *)result
{
    [self.socket sendMessageResponse:result.sign resultCode:ERR_SUCC resultMsg:@"" response:result];
    NSString *partner_id = [NSString stringWithFormat:@"%lld",result.uid];
    [[MSConversationProvider provider]deleteConversation: partner_id];
    if (self.convListener && [self.convListener respondsToSelector:@selector(conversationDidDelete:)]) {
        [self.convListener conversationDidDelete:partner_id];
    }
    //更新会话更新时间
    [self updateChatListUpdateTime:result.updateTime];
}

- (void)chatListBlockChanged:(ChatItemUpdate *)result
{
    MSIMConversation *conv = [[MSConversationProvider provider]providerConversation:[NSString stringWithFormat:@"%lld",result.uid]];
    conv.ext.i_block_u = result.iBlockU;
    [[MSConversationProvider provider]updateConversations:@[conv]];
    [self.convListener onUpdateConversations:@[conv]];
    [self updateChatListUpdateTime:result.updateTime];
}

//我主动发起的标记消息已读
- (void)chatUnreadCountChanged:(ChatItemUpdate *)result
{
//    NSString *fromUid = [NSString stringWithFormat:@"%lld",result.uid];
//    MSIMConversation *conv = [[MSConversationProvider provider]providerConversation:fromUid];
//    conv.unread_count = result.unread;
//    [[MSConversationProvider provider]updateConversations:@[conv]];
//    if (self.convListener && [self.convListener respondsToSelector:@selector(onUpdateConversations:)]) {
//        [self.convListener onUpdateConversations:@[conv]];
//    }
    //标记的时候就直接清空未读数，不等结果返回
    [self updateChatListUpdateTime:result.updateTime];
}

//对方发起的标记消息已读
- (void)chatMarkReadChanged:(ChatItemUpdate *)result
{
    NSString *fromUid = [NSString stringWithFormat:@"%lld",result.uid];
    MSIMConversation *conv = [[MSConversationProvider provider]providerConversation:fromUid];
    conv.msg_last_read = result.msgLastRead;
    [[MSConversationProvider provider]updateConversations:@[conv]];
    [self.messageStore markMessageAsRead:result.msgLastRead partnerID:fromUid];
    
    MSIMMessageReceipt *receipt = [[MSIMMessageReceipt alloc]init];
    receipt.msg_id = result.msgLastRead;
    receipt.user_id = fromUid;
    if (self.msgListener && [self.convListener respondsToSelector:@selector(onRecvC2CReadReceipt:)]) {
        [self.msgListener onRecvC2CReadReceipt:receipt];
    }
    [self updateChatListUpdateTime:result.updateTime];
}

/// 收到服务器下发的聊天室消息的处理
- (void)receiveChatRoomMessageHandler:(NSArray<GroupChatR *> *)responses
{
    if (responses.count == 0) return;
    NSMutableArray *recieves = [NSMutableArray array];
    NSMutableDictionary *needProfiles = [NSMutableDictionary dictionary];
    NSMutableArray  *noticeArr = [NSMutableArray array];
    NSInteger unreadCount = 0;
    for (NSInteger i = 0; i < responses.count; i++) {
        GroupChatR *response = responses[i];
        MSIMMessage *message = [[MSIMMessage alloc]init];
        MSIMElem *elem = nil;
        //自定义消息
        BOOL isCustomMsg = (response.type == MSIM_MSG_TYPE_CUSTOM_SIGNAL || response.type == MSIM_MSG_TYPE_CUSTOM_IGNORE_UNREADCOUNT_RECALL || response.type == MSIM_MSG_TYPE_CUSTOM_UNREADCOUNT_NO_RECALL || response.type == MSIM_MSG_TYPE_CUSTOM_UNREADCOUNT_RECAL);
        
        if (response.type == MSIM_MSG_TYPE_TEXT) {
            message.type = MSIM_MSG_TYPE_TEXT;
            MSIMTextElem *textElem = [[MSIMTextElem alloc]init];
            textElem.text = response.body;
            elem = textElem;
            message.elem = elem;
        }else if (response.type == MSIM_MSG_TYPE_IMAGE) {
            message.type = MSIM_MSG_TYPE_IMAGE;
            MSIMImageElem *imageElem = [[MSIMImageElem alloc]init];
            imageElem.width = response.width;
            imageElem.height = response.height;
            imageElem.url = response.body;
            elem = imageElem;
            message.elem = elem;
        }else if (response.type == MSIM_MSG_TYPE_VIDEO) {
            message.type = MSIM_MSG_TYPE_VIDEO;
            MSIMVideoElem *videoElem = [[MSIMVideoElem alloc]init];
            videoElem.width = response.width;
            videoElem.height = response.height;
            videoElem.videoUrl = response.body;
            videoElem.coverUrl = response.thumb;
            videoElem.duration = response.duration;
            elem = videoElem;
            message.elem = elem;
        }else if (response.type == MSIM_MSG_TYPE_VOICE) {
            message.type = MSIM_MSG_TYPE_VOICE;
            MSIMVoiceElem *voiceElem = [[MSIMVoiceElem alloc]init];
            voiceElem.url = response.body;
            voiceElem.duration = response.duration;
            elem = voiceElem;
            message.elem = elem;
        }else if (response.type == MSIM_MSG_TYPE_LOCATION) {
            message.type = MSIM_MSG_TYPE_LOCATION;
            MSIMLocationElem *locationElem = [[MSIMLocationElem alloc]init];
            locationElem.title = response.title;
            locationElem.detail = response.body;
            locationElem.latitude = response.lat;
            locationElem.longitude = response.lng;
            locationElem.zoom = response.zoom;
            elem = locationElem;
            message.elem = elem;
        }else if (response.type == MSIM_MSG_TYPE_EMOTION) {
            message.type = MSIM_MSG_TYPE_EMOTION;
            MSIMEmotionElem *emotionElem = [[MSIMEmotionElem alloc]init];
            emotionElem.emotionID = response.body;
            emotionElem.emotionName = response.title;
            emotionElem.emotionUrl = response.thumb;
            elem = emotionElem;
            message.elem = elem;
        }else if (response.type == MSIM_MSG_TYPE_REVOKE) {
            message.type = MSIM_MSG_TYPE_REVOKE;
            elem = [[MSIMElem alloc]init];
            message.elem = elem;
        }else if (response.type == 66) {  //删除某些消息
            //删除的消息有可能是批量的
            NSString *delStr = response.body;
            NSArray *arr = [delStr componentsSeparatedByString:@","];
            if ([self.chatRoomMsgListener respondsToSelector:@selector(onChatRoomDeleteMessages:)]) {
                [self.chatRoomMsgListener onChatRoomDeleteMessages:arr];
            }
            [MSChatRoomManager.sharedInstance onDeleteMessages:arr];
        }else if(response.type == 68) { // 群公告
            [noticeArr addObject:response];
            MSChatRoomManager.sharedInstance.chatroomInfo.intro = response.body;
            
        }else if (response.type == MSIM_MSG_TYPE_RECALL_ACTION) {//撤回消息
            message.type = MSIM_MSG_TYPE_NULL;
            MSIMMessage *revokeMsg = [[MSChatRoomManager sharedInstance]searchMessageWithMsgID:response.body.integerValue];
            revokeMsg.type = MSIM_MSG_TYPE_REVOKE;
            [[MSChatRoomManager sharedInstance]onChatRoomMessageUpdate:revokeMsg];
            if (revokeMsg && [self.chatRoomMsgListener respondsToSelector:@selector(onChatRoomMessageUpdate:)]) {
                [self.chatRoomMsgListener onChatRoomMessageUpdate:revokeMsg];
            }
        }else if (isCustomMsg == YES) {
            message.type = response.type;
            MSIMCustomElem *customElem = [[MSIMCustomElem alloc]init];
            customElem.jsonStr = response.body;
            customElem.option = response.type;
            MSIMPushInfo *push = [[MSIMPushInfo alloc]init];
            push.title = response.title;
            elem = customElem;
            message.elem = elem;
        }else {//未知消息
            message.type = MSIM_MSG_TYPE_UNKNOWN;
            MSIMElem *unknowElem = [[MSIMElem alloc]init];
            elem = unknowElem;
            message.elem = elem;
        }
        message.fromUid = [NSString stringWithFormat:@"%lld",response.fromUid];
        message.toUid = [NSString stringWithFormat:@"%lld",response.id_p];
        message.groupID = message.toUid;
        message.msgID = response.msgId;
        message.chatType = MSIM_CHAT_TYPE_CHATROOM;
        NSInteger tempSign = 0;
        if (response.sign > 0) {
            tempSign = response.sign;
        }else {
            tempSign = response.msgId < 100000 ? response.msgTime + response.msgId : response.msgTime;
        }
        message.msgSign = [self uniqueMsgSign:tempSign];
        message.sendStatus = MSIM_MSG_STATUS_SEND_SUCC;
        message.readStatus = MSIM_MSG_STATUS_READ;
        if (elem) {
            [recieves addObject:message];
        }
        
        NSString *fromUid = [NSString stringWithFormat:@"%lld",response.fromUid];
        MSProfileInfo *fromProfile = [[MSProfileProvider provider]providerProfileFromLocal:fromUid];
        if (fromProfile == nil) {
            fromProfile = [[MSProfileInfo alloc]init];
            fromProfile.user_id = message.fromUid;
            [needProfiles setValue:fromProfile forKey:fromUid];
        }
        // 更新聊天室记录的上次最后一条消息msg_id，用于重连后服务器推历史消息
        if (response.msgId > MSChatRoomManager.sharedInstance.chatRoomLastMsgID) {
            MSChatRoomManager.sharedInstance.chatRoomLastMsgID = response.msgId;
        }
        if (response.msgId > MSChatRoomManager.sharedInstance.lastReadMsgID && message.type != MSIM_MSG_TYPE_NULL) {
            unreadCount++;
        }
    }
    if (unreadCount) {
        NSInteger totalCount = MSChatRoomManager.sharedInstance.unreadCount + unreadCount;
        [MSChatRoomManager.sharedInstance updateUnreadCountTo:totalCount];
    }
    if (recieves.count && [self.chatRoomMsgListener respondsToSelector:@selector(onNewChatRoomMessages:)]) {
        [self.chatRoomMsgListener onNewChatRoomMessages:recieves];
        [[MSChatRoomManager sharedInstance]recieveMessages:recieves];
    }
    if (noticeArr.count)  {
        [self.chatRoomMsgListener onNewChatRoomTipsOfDay:MSChatRoomManager.sharedInstance.chatroomInfo.intro];
    }
    // 更新profile
    if (needProfiles.allKeys.count > 0) {
        [[MSProfileProvider provider] synchronizeProfiles:needProfiles.allValues.mutableCopy];
    }
}

/// 收到聊天室事件处理
/// 0：聊天室被销毁（所有用户被迫离开聊天室）
/// 1：聊天室信息修改，（名称，容纳上限，是否全体禁言）
/// 2：用户状态变动 即 GroupMember 变动（包括用户上下线，禁言状态变动、角色变动）
/// 3：我的权限变动 （action属性全量重新刷新）
- (void)receiveChatRoomEventHandler:(GroupEvent *)event
{
    MSGroupEvent *eventModel = [[MSGroupEvent alloc]init];
    eventModel.room_id = [NSString stringWithFormat:@"%lld",event.id_p];
    eventModel.room_name = event.name;
    eventModel.max_count = event.maxCount;
    eventModel.is_mute = event.isMute;
    eventModel.reason = event.reason;
    eventModel.eventType = event.etype;
    eventModel.action_tod = event.actionTod;
    eventModel.action_mute = event.actionMute;
    eventModel.action_assign = event.actionAssign;
    eventModel.action_del_msg = event.actionDelMsg;
    eventModel.action_mute_all = event.actionMuteAll;
    eventModel.from_uid = [NSString stringWithFormat:@"%lld",event.fromUid];
    
    MSGroupTipEvent *tipEvent = [[MSGroupTipEvent alloc]init];
    tipEvent.event = event.tip.event;
    NSMutableArray *uids = [NSMutableArray array];
    for (NSInteger i = 0; i < event.tip.uidsArray.count; i++) {
        NSInteger uid = [event.tip.uidsArray valueAtIndex:i];
        [uids addObject: @(uid)];
    }
    tipEvent.uids = uids;
    eventModel.tips = tipEvent;
    NSMutableArray *arr = [NSMutableArray array];
    NSArray *members = event.membersArray;
    for (GroupMember *m in members) {
        MSGroupMemberItem *item = [[MSGroupMemberItem alloc]init];
        item.uid = [NSString stringWithFormat:@"%lld",m.uid];
        item.is_mute = m.isMute;
        item.role = m.role;
        [arr addObject:item];
    }
    eventModel.members = arr;
    //事件类型：
    //1：聊天室已被解散
    //2：聊天室属性已修改
    //3：管理员 %s 将本聊天室设为听众模式
    //4: 管理员 %s 恢复聊天室发言功能
    //5：管理员 %s 上线
    //6：管理员 %s 下线
    //7: 管理员 %s 将用户 %s 禁言
    //8: 管理员 %s 将用户 %s、%s 等人禁言
    //9: %s 成为本聊天室管理员
    //10: 管理员 %s 指派 %s 为临时管理员
    //11：管理员 %s 指派 %s、%s 等人为临时管理员
    switch (event.tip.event) {
        case 1://聊天室被销毁（所有用户被迫离开聊天室）
            break;
        case 2://聊天室信息修改，（名称，容纳上限）
        {
            if (event.name.length) {
                MSChatRoomManager.sharedInstance.chatroomInfo.room_name = event.name;
            }else if (event.maxCount) {
                MSChatRoomManager.sharedInstance.chatroomInfo.max_count = event.maxCount;
            }
        }
            break;
        case 3: //管理员 %s 将本聊天室设为听众模式
        {
            MSChatRoomManager.sharedInstance.chatroomInfo.is_mute = event.isMute;
        }
            break;
        case 4://管理员 %s 恢复聊天室发言功能
        {
            MSChatRoomManager.sharedInstance.chatroomInfo.is_mute = event.isMute;
        }
            break;
        case 5: // %s 上线
            break;
        case 6: // %s 下线
            break;
        case 7: //管理员 %s 将用户 %s 禁言
        case 8: //管理员 %s 将用户 %s、%s 等人禁言
        case 9: //%s 成为本聊天室管理员
        case 10://管理员 %s 指派 %s 为临时管理员
        case 11://管理员 %s 指派 %s、%s 等人为临时管理员
        {
            for (GroupMember *m in members) {
                MSGroupMemberItem *item = [self containMember:[NSString stringWithFormat:@"%lld",m.uid]];
                item.is_mute = m.isMute;
                item.role = m.role;
            }
        }
            break;
        default:
            break;
    }
    if (event.etype == 1) {//聊天室信息修改，（名称，容纳上限，是否全体禁言）
        if ([self.chatRoomMsgListener respondsToSelector:@selector(onChatRoomConvUpdate)]) {
            [self.chatRoomMsgListener onChatRoomConvUpdate];
        }
    }else if (event.etype == 2) {//用户状态变动
        for (GroupMember *m in members) {
            if (m.uid > 0) {//上线
                MSGroupMemberItem *item = [self containMember:[NSString stringWithFormat:@"%lld",m.uid]];
                if (item) {
                    item.role = m.role;
                    item.is_mute = m.isMute;
                }else {
                    MSGroupMemberItem *item = [[MSGroupMemberItem alloc]init];
                    item.uid = [NSString stringWithFormat:@"%lld",m.uid];
                    item.is_mute = m.isMute;
                    item.role = m.role;
                    [MSChatRoomManager.sharedInstance.chatroomInfo.members addObject:item];
                    if ([self.chatRoomMsgListener respondsToSelector:@selector(onPeopleJoinInChatRoom:)]) {
                        [self.chatRoomMsgListener onPeopleJoinInChatRoom:item];
                    }
                    //检查profile本地是否有缓存
                    MSProfileInfo *info = [[MSProfileProvider provider]providerProfileFromLocal:item.uid];
                    if (info == nil) {
                        info = [[MSProfileInfo alloc]init];
                        info.user_id = item.uid;
                        [[MSProfileProvider provider] synchronizeProfiles:@[info].mutableCopy];
                    }
                }
            }else {
                NSString *uid = [NSString stringWithFormat:@"%lld",-m.uid];
                [self someoneOffline:uid];
                if ([self.chatRoomMsgListener respondsToSelector:@selector(onPeopleQuitChatRoom:)]) {
                    [self.chatRoomMsgListener onPeopleQuitChatRoom:uid];
                }
            }
        }
    }else if (event.etype == 3) {//我的权限变动 （action属性全量重新刷新）
        MSChatRoomManager.sharedInstance.chatroomInfo.action_tod = event.actionTod;
        MSChatRoomManager.sharedInstance.chatroomInfo.action_mute = event.actionMute;
        MSChatRoomManager.sharedInstance.chatroomInfo.action_assign = event.actionAssign;
        MSChatRoomManager.sharedInstance.chatroomInfo.action_del_msg = event.actionDelMsg;
        MSChatRoomManager.sharedInstance.chatroomInfo.action_mute_all = event.actionMuteAll;
    }
    if ([self.chatRoomMsgListener respondsToSelector:@selector(onNewChatRoomEvent:)]) {
        [self.chatRoomMsgListener onNewChatRoomEvent: eventModel];
    }
}

- (MSGroupMemberItem *)containMember:(NSString *)uid
{
    if (uid.length == 0) return nil;
    for (MSGroupMemberItem *item in MSChatRoomManager.sharedInstance.chatroomInfo.members) {
        if ([item.uid isEqualToString:uid]) {
            return item;
        }
    }
    return nil;
}

- (void)someoneOffline:(NSString *)uid
{
    if (uid.length == 0) return;
    for (NSInteger i = 0; i < MSChatRoomManager.sharedInstance.chatroomInfo.members.count; i++) {
        MSGroupMemberItem *item = MSChatRoomManager.sharedInstance.chatroomInfo.members[i];
        if ([item.uid isEqualToString:uid]) {
            [MSChatRoomManager.sharedInstance.chatroomInfo.members removeObject:item];
            return;
        }
    }
}

- (NSInteger)uniqueMsgSign:(NSInteger)msgTime
{
    if (self.cacheMsgSigns.allKeys.count > 1000) {
        [self.cacheMsgSigns removeAllObjects];
        return msgTime;
    }
    if (!self.cacheMsgSigns[@(msgTime)]) {
        [self.cacheMsgSigns setObject:@(1) forKey:@(msgTime)];
        return msgTime;
    }
    return [self uniqueMsgSign: msgTime + 1];
}

@end
