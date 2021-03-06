//
//  MSIMManager.m
//  BlackFireIM
//
//  Created by benny wang on 2021/2/25.
//

#import "MSIMManager.h"
#import "MSIMConst.h"
#import "MSIMTools.h"
#import "MSIMErrorCode.h"
#import "MSDBManager.h"
#import "MSIMManager+Conversation.h"
#import "MSProfileProvider.h"
#import "MSIMManager+Parse.h"
#import "ChatProtobuf.pbobjc.h"
#import "MSIMManager+Internal.h"
#import "MSChatRoomManager.h"
#import "MSChatRoomManager+Internal.h"


@interface MSIMManager()<MSTCPSocketDelegate>

@property(nonatomic,copy) MSIMSucc loginSuccBlock;
@property(nonatomic,copy) MSIMFail loginFailBlock;

@property(nonatomic,strong) dispatch_queue_t commonQueue;

@property(nonatomic,assign) NSInteger lastRecieveMsgTime;

@end
@implementation MSIMManager

static MSIMManager *_manager;
+ (instancetype)sharedInstance
{
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        _manager = [[MSIMManager alloc]init];
    });
    return _manager;
}

- (instancetype)init
{
    if (self = [super init]) {
    }
    return self;
}

- (MSTCPSocket *)socket
{
    if (!_socket) {
        _socket = [[MSTCPSocket alloc]init];
        _socket.delegate = self;
    }
    return _socket;
}

- (MSDBMessageStore *)messageStore
{
    if (!_messageStore) {
        _messageStore = [[MSDBMessageStore alloc]init];
    }
    return _messageStore;
}

- (MSDBConversationStore *)convStore
{
    if (!_convStore) {
        _convStore = [[MSDBConversationStore alloc]init];
    }
    return _convStore;
}

- (NSMutableArray *)convCaches
{
    if (!_convCaches) {
        _convCaches = [NSMutableArray array];
    }
    return _convCaches;
}

- (NSMutableArray *)profileCaches
{
    if (!_profileCaches) {
        _profileCaches = [NSMutableArray array];
    }
    return _profileCaches;
}

- (NSMutableArray *)messageCaches
{
    if (!_messageCaches) {
        _messageCaches = [NSMutableArray array];
    }
    return _messageCaches;
}

- (NSMutableArray *)offlineCache
{
    if (!_offlineCache) {
        _offlineCache = [NSMutableArray array];
    }
    return _offlineCache;
}

- (NSMutableDictionary *)cacheMsgSigns
{
    if (!_cacheMsgSigns) {
        _cacheMsgSigns = [NSMutableDictionary dictionary];
    }
    return _cacheMsgSigns;
}

- (MSIMNetStatus)connStatus
{
    return self.socket.connStatus;
}

- (dispatch_queue_t)commonQueue
{
    if (!_commonQueue) {
        _commonQueue = dispatch_queue_create("mQueue", NULL);
    }
    return _commonQueue;
}

- (void)initSDK:(IMSDKConfig *)config listener:(id<MSIMSDKListener>)listener
{
    self.socket.config = config;
    _connListener = listener;
}

#pragma mark - MSTCPSocketDelegate
- (void)connectSucc
{
    if ([self.connListener respondsToSelector:@selector(connectSucc)]) {
        [self.connListener connectSucc];
    }
}

- (void)connectFailed:(NSInteger)code err:(NSString *)errString
{
    if ([self.connListener respondsToSelector:@selector(connectFailed:err:)]) {
        [self.connListener connectFailed:code err:errString];
    }
}

- (void)onConnecting
{
    if ([self.connListener respondsToSelector:@selector(onConnecting)]) {
        [self.connListener onConnecting];
    }
}

- (void)onForceOffline
{
    if ([self.connListener respondsToSelector:@selector(onForceOffline)]) {
        [self.connListener onForceOffline];
    }
}

- (void)onUserSigExpired
{
    if ([self.connListener respondsToSelector:@selector(onUserSigExpired)]) {
        [self.connListener onUserSigExpired];
    }
}

- (void)onIMLoginSucc
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.loginSuccBlock) self.loginSuccBlock();
        self.loginSuccBlock = nil;
    });
    //??????????????????
    [self.convCaches removeAllObjects];
    [self synchronizeConversationList];
    // ???????????????????????????????????????????????????????????????????????????
    NSInteger chatRoomID = [MSIMTools sharedInstance].chatRoomID;
    if (chatRoomID) {
        [self joinInChatRoom:chatRoomID succ:^(MSGroupInfo * _Nonnull info) {
            
        } failed:^(NSInteger code, NSString *desc) {
            
        }];
    }
}

- (void)onIMLoginFail:(NSInteger)code msg:(NSString *)err
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.loginFailBlock) self.loginFailBlock(code, err);
        self.loginFailBlock = nil;
    });
}

- (void)globTimerCallback
{
    dispatch_async(self.commonQueue, ^{
        @synchronized (self) {
            [self receiveMessageHandler:self.messageCaches.copy];
            [self.messageCaches removeAllObjects];
            [self userOnLineChangeHandler:self.offlineCache.copy];
            [self.offlineCache removeAllObjects];
        }
    });
}

- (void)onRevieveData:(NSData *)package protoType:(XMChatProtoType)type
{
    if(package == nil || package.length == 0) {
        return;
    }
    switch (type) {
        case XMChatProtoTypeResponse://??????????????????
        {
            NSError *error;
            ChatSR *result = [[ChatSR alloc]initWithData:package error:&error];
            if (error == nil && result != nil) {
                [self.socket sendMessageResponse:result.sign resultCode:ERR_SUCC resultMsg:@"?????????????????????????????????" response:result];
                //????????????????????????
                [self updateChatListUpdateTime:result.msgTime];
            }else {
                MSLog(@"??????protobuf????????????-- %@",error);
            }
            MSLog(@"????????????????????????***%@",result);
            MSLog(@"??????????????????[sign:%lld],[time:%ld]",result.sign,[MSIMTools sharedInstance].adjustLocalTimeInterval);
        }
            break;
        case XMChatProtoTypeRecieve: // ???????????????
        {
            NSError *error;
            ChatR *recieve = [[ChatR alloc]initWithData:package error:&error];
            if (error == nil && recieve != nil) {
                NSInteger currentTime = [MSIMTools sharedInstance].adjustLocalTimeInterval;
                @synchronized (self) {
                    if (self.messageCaches.count == 0 && (currentTime - self.lastRecieveMsgTime > 0.05*1000*1000)) {
                        [self receiveMessageHandler:@[recieve]];
                    }else {
                        [self.messageCaches addObject:recieve];
                    }
                    self.lastRecieveMsgTime = currentTime;
                }
            }else {
                MSLog(@"??????protobuf????????????-- %@",error);
            }
            MSLog(@"[??????]?????????***%@",recieve);
        }
            break;
        case XMChatProtoTypeMassRecieve: //??????????????????
        {
            NSError *error;
            ChatRBatch *batch = [[ChatRBatch alloc]initWithData:package error:&error];
            if (error == nil && batch.msgsArray != nil) {
                [self.socket sendMessageResponse:batch.sign resultCode:ERR_SUCC resultMsg:@"??????????????????" response:batch];
            }else {
                MSLog(@"??????protobuf????????????-- %@",error);
            }
            MSLog(@"[??????]????????????:%@",batch);
        }
            break;
        case XMChatProtoTypeGetChatListResponse: //????????????????????????
        {
            NSError *error;
            ChatList *result = [[ChatList alloc]initWithData:package error:&error];
            if (error == nil) {
                [self chatListResultHandler:result];
            }
            MSLog(@"[??????]????????????***%@",result);
        }
            break;
        case XMChatProtoTypeGetProfileResult: //?????????????????????????????????
        {
            NSError *error;
            Profile *profile = [[Profile alloc]initWithData:package error:&error];
            if(error == nil && profile != nil) {
                [self profilesResultHandler:@[profile]];
                [self.socket sendMessageResponse:profile.sign resultCode:ERR_SUCC resultMsg:@"" response:profile];
            }else {
                MSLog(@"??????protobuf????????????-- %@",error);
            }
            MSLog(@"[??????]????????????***%@",profile);
        }
            break;
        case XMChatProtoTypeGetProfilesResult: //??????????????????????????????
        {
            NSError *error;
            ProfileList *profiles = [[ProfileList alloc]initWithData:package error:&error];
            if(error == nil && profiles != nil) {
                [self profilesResultHandler:profiles.profilesArray];
            }else {
                MSLog(@"??????protobuf????????????-- %@",error);
            }
            MSLog(@"[??????]??????????????????***%@",profiles);
        }
            break;
        case XMChatProtoTypeResult: //??????????????????????????????
        {
            NSError *error;
            Result *result = [[Result alloc]initWithData:package error:&error];
            if(error == nil && result != nil) {
                [self messageRsultHandler:result];
            }else {
                MSLog(@"??????protobuf????????????-- %@",error);
            }
            MSLog(@"??????????????????????????????***%@",result);
        }
            break;
        case XMChatProtoTypeProfileOnline: //??????????????????
        {
            NSError *error;
            ProfileOnline *online = [[ProfileOnline alloc]initWithData:package error:&error];
            if (error == nil && online != nil) {
                @synchronized (self) {
                    [self.offlineCache addObject:online];
                }
            }else {
                MSLog(@"??????protobuf????????????-- %@",error);
            }
            MSLog(@"[??????]??????????????????***%@",online);
        }
            break;
            
        case XMChatProtoTypeProfileOffline: //??????????????????
        {
            NSError *error;
            UsrOffline *offline = [[UsrOffline alloc]initWithData:package error:&error];
            if (error == nil && offline != nil) {
                @synchronized (self) {
                    [self.offlineCache addObject:offline];
                }
            }else {
                MSLog(@"??????protobuf????????????-- %@",error);
            }
            MSLog(@"[??????]??????????????????***%@",offline);
        }
            break;
        case XMChatProtoTypeChatListChanged: //??????????????????????????????
        {
            NSError *error;
            ChatItemUpdate *item = [[ChatItemUpdate alloc]initWithData:package error:&error];
            if (error == nil && item != nil) {
                [self chatListChanged:item];
            }else {
                MSLog(@"??????protobuf????????????-- %@",error);
            }
        }
            break;
        case XMChatProtoTypeGetSparkResponse: //????????????sparks??????   for demo
        {
            NSError *error;
            Sparks *datas = [[Sparks alloc]initWithData:package error:&error];
            if(error == nil && datas != nil) {
                [self.socket sendMessageResponse:datas.sign resultCode:ERR_SUCC resultMsg:@"" response:datas];
            }else {
                MSLog(@"??????protobuf????????????-- %@",error);
            }
            MSLog(@"[??????]??????Sparks??????***");
        }
            break;
        case XMChatProtoTypeCosTokenResponse:  //cos?????????????????????
        {
            NSError *error;
            CosKey *key = [[CosKey alloc]initWithData:package error:&error];
            if(error == nil && key != nil) {
                [self.socket sendMessageResponse:key.sign resultCode:ERR_SUCC resultMsg:@"" response:key];
            }else {
                MSLog(@"??????protobuf????????????-- %@",error);
            }
            MSLog(@"[??????]cos?????????????????????:%@***",key);
        }
            break;
        case XMChatProtoTypeAgoraTokenResponse: //???????????????token??????
        {
            NSError *error;
            AgoraToken *token = [[AgoraToken alloc]initWithData:package error:&error];
            if(error == nil && token != nil) {
                [self.socket sendMessageResponse:token.sign resultCode:ERR_SUCC resultMsg:@"" response:token];
            }else {
                MSLog(@"??????protobuf????????????-- %@",error);
            }
            MSLog(@"[??????]????????????token:%@***",token);
        }
            break;
        case XMChatProtoTypeJoinGroupResult: //?????????????????????????????????
        {
            NSError *error;
            GroupInfo *info = [[GroupInfo alloc]initWithData:package error:&error];
            if(error == nil && info != nil) {
                [self.socket sendMessageResponse:info.sign resultCode:ERR_SUCC resultMsg:@"" response:info];
            }else {
                MSLog(@"??????protobuf????????????-- %@",error);
            }
            MSLog(@"[??????]???????????????????????????:%@***",info);
        }
            break;
        case XMChatProtoTypeSendGroupMsgResponse: //???????????????????????????
        {
            NSError *error;
            GroupChatSR *result = [[GroupChatSR alloc]initWithData:package error:&error];
            if (error == nil && result != nil) {
                [self.socket sendMessageResponse:result.sign resultCode:ERR_SUCC resultMsg:@"????????????????????????????????????" response:result];
            }else {
                MSLog(@"??????protobuf????????????-- %@",error);
            }
            MSLog(@"????????????????????????***%@",result);
        }
            break;
        case XMChatProtoTypeRecieveGroupMsg: //?????????????????????
        {
            NSError *error;
            GroupChatR *recieve = [[GroupChatR alloc]initWithData:package error:&error];
            if (error == nil && recieve != nil) {
                [self receiveChatRoomMessageHandler:@[recieve]];
            }else {
                MSLog(@"??????protobuf????????????-- %@",error);
            }
            MSLog(@"[??????]???????????????***%@",recieve);
        }
            break;
        case XMChatProtoTypeRecieveGroupMsgBatch: //???????????????????????????
        {
            NSError *error;
            GroupChatRBatch *batch = [[GroupChatRBatch alloc]initWithData:package error:&error];
            if (error == nil && batch.msgsArray != nil) {
                [self receiveChatRoomMessageHandler:batch.msgsArray];
            }else {
                MSLog(@"??????protobuf????????????-- %@",error);
            }
            MSLog(@"[??????]?????????????????????:%@",batch);
        }
            break;
        case XMChatProtoTypeJoinGroupEvent: //?????????????????????
        {
            NSError *error;
            GroupEvent *event = [[GroupEvent alloc]initWithData:package error:&error];
            if (error == nil) {
                [self receiveChatRoomEventHandler: event];
            }else {
                MSLog(@"??????protobuf????????????-- %@",error);
            }
            MSLog(@"[??????]?????????????????????:%@",event);
        }
            break;
        default:
            break;
    }
}


- (void)messageRsultHandler:(Result *)result
{
    [self.socket sendMessageResponse:result.sign resultCode:result.code resultMsg:result.msg response:result];
    if (result.code == ERR_USER_SIG_EXPIRED || result.code == ERR_IM_TOKEN_NOT_FIND) {
        
        if (self.connListener && [self.connListener respondsToSelector:@selector(onUserSigExpired)]) {
            [self.connListener onUserSigExpired];
        }
        //???????????????token
        [self cleanIMToken];
        
    }else if (result.code == ERR_LOGIN_KICKED_OFF_BY_OTHER) {
        if (self.connListener && [self.connListener respondsToSelector:@selector(onForceOffline)]) {
            [self.connListener onForceOffline];
        }
        //???????????????token
        [self cleanIMToken];
    }
}

///???????????? SDK
- (void) unInitSDK
{
    
}

- (void)login:(NSString *)userSign
        imUrl:(NSString *)imUrl
     subAppID:(NSInteger)subID
         succ:(MSIMSucc)succ
       failed:(MSIMFail)fail
{
    if (userSign.length == 0) {
        if (fail) fail(ERR_USER_PARAMS_ERROR, @"token??????");
        return;
    }
    if (imUrl.length == 0) {
        if (fail) fail(ERR_USER_PARAMS_ERROR, @"imUrl??????");
        return;
    }
    if ([MSIMTools sharedInstance].user_id.length > 0) {
        if (fail) fail(ERR_IM_LOGIN_ALREADY, @"??????????????????");
        return;
    }
    [[NSUserDefaults standardUserDefaults]setValue:imUrl forKey:@"im_url"];
    [MSIMTools sharedInstance].user_sign = userSign;
    [MSIMTools sharedInstance].sub_app_id = subID;
    self.loginSuccBlock = succ;
    self.loginFailBlock = fail;
    if (self.socket.connStatus == IMNET_STATUS_SUCC) {
        [self.socket imLogin:userSign subAppID:subID];
    }else {
        [self.socket connectTCPToServer];
    }
}

///????????????
- (void)logout:(MSIMSucc)succ
        failed:(MSIMFail)fail
{
    //???????????????????????????uid??????last_uid?????????
    [[NSUserDefaults standardUserDefaults]setObject:[MSIMTools sharedInstance].user_sign forKey:@"ms_last_token"];
    ImLogout *logout = [[ImLogout alloc]init];
    logout.sign = [MSIMTools sharedInstance].adjustLocalTimeInterval;
    MSLog(@"[????????????-logout]:\n%@",logout);
    [self.socket send:[logout data] protoType:XMChatProtoTypeLogout needToEncry:NO sign:logout.sign callback:^(NSInteger code, id  _Nullable response, NSString * _Nullable error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (code == ERR_SUCC) {
            }else {
                MSLog(@"??????????????????*******code = %ld,response = %@,errorMsg = %@",code,response,error);
            }
        });
    }];
    [self cleanIMToken];
    if (succ) succ();
}

///???????????????token. device_token??????????????????????????????????????????????????????
///voip_token device_token????????????????????????voip????????????
- (void)refreshPushToken:(nullable NSString *)device_token voipToken: (nullable NSString *)voip_token
{
    UpdatePushToken *update = [[UpdatePushToken alloc]init];
    update.sign = [MSIMTools sharedInstance].adjustLocalTimeInterval;
    update.pushChannel = 1;
    if (device_token.length != 0 || voip_token.length != 0) {
        update.pushToken = [NSString stringWithFormat:@"%@,%@",XMNoNilString(device_token),XMNoNilString(voip_token)];
    }
    MSLog(@"[????????????-????????????token]:\n%@",update);
    [self.socket send:[update data] protoType:XMChatProtoTypeRefreshPushToken needToEncry:NO sign:update.sign callback:^(NSInteger code, id  _Nullable response, NSString * _Nullable error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (code == ERR_SUCC) {
            }else {
                MSLog(@"????????????token??????*******code = %ld,response = %@,errorMsg = %@",code,response,error);
            }
        });
    }];
}

///????????????????????????
- (void)updateChatListUpdateTime:(NSInteger)updateTime
{
    if (self.isChatListResult == NO) {
        self.chatUpdateTime = updateTime;
    }else {
        [[MSIMTools sharedInstance]updateConversationTime:updateTime];
        self.chatUpdateTime = 0;
    }
}

- (void)cleanIMToken
{
    [MSChatRoomManager.sharedInstance cleanChatRoomCache];
    
    self.chatUpdateTime = 0;
    [self.socket disConnectTCP];
    [self.socket cleanCache];
    [MSIMTools sharedInstance].user_id = nil;
    [MSIMTools sharedInstance].user_sign = nil;
    [[NSUserDefaults standardUserDefaults]removeObjectForKey:@"im_url"];
    [[MSIMTools sharedInstance]cleanConvUpdateTime];
    [[MSDBManager sharedInstance] accountChanged];
}

@end
