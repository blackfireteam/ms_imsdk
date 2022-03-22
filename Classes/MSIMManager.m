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
    //同步会话列表
    [self.convCaches removeAllObjects];
    [self synchronizeConversationList];
    // 如果断线重连前有进入聊天室，重连后自动调加入聊天室
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
        case XMChatProtoTypeResponse://单条消息回执
        {
            NSError *error;
            ChatSR *result = [[ChatSR alloc]initWithData:package error:&error];
            if (error == nil && result != nil) {
                [self.socket sendMessageResponse:result.sign resultCode:ERR_SUCC resultMsg:@"单条消息已发送到服务器" response:result];
                //更新会话更新时间
                [self updateChatListUpdateTime:result.msgTime];
            }else {
                MSLog(@"消息protobuf解析失败-- %@",error);
            }
            MSLog(@"收到单条消息回执***%@",result);
            MSLog(@"收到消息回执[sign:%lld],[time:%ld]",result.sign,[MSIMTools sharedInstance].adjustLocalTimeInterval);
        }
            break;
        case XMChatProtoTypeRecieve: // 收到新消息
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
                MSLog(@"消息protobuf解析失败-- %@",error);
            }
            MSLog(@"[收到]新消息***%@",recieve);
        }
            break;
        case XMChatProtoTypeMassRecieve: //收到批量消息
        {
            NSError *error;
            ChatRBatch *batch = [[ChatRBatch alloc]initWithData:package error:&error];
            if (error == nil && batch.msgsArray != nil) {
                [self.socket sendMessageResponse:batch.sign resultCode:ERR_SUCC resultMsg:@"收到历史消息" response:batch];
            }else {
                MSLog(@"消息protobuf解析失败-- %@",error);
            }
            MSLog(@"[收到]历史消息:%@",batch);
        }
            break;
        case XMChatProtoTypeGetChatListResponse: //拉取会话列表结果
        {
            NSError *error;
            ChatList *result = [[ChatList alloc]initWithData:package error:&error];
            if (error == nil) {
                [self chatListResultHandler:result];
            }
            MSLog(@"[收到]会话列表***%@",result);
        }
            break;
        case XMChatProtoTypeGetProfileResult: //返回的单个用户信息结果
        {
            NSError *error;
            Profile *profile = [[Profile alloc]initWithData:package error:&error];
            if(error == nil && profile != nil) {
                [self profilesResultHandler:@[profile]];
                [self.socket sendMessageResponse:profile.sign resultCode:ERR_SUCC resultMsg:@"" response:profile];
            }else {
                MSLog(@"消息protobuf解析失败-- %@",error);
            }
            MSLog(@"[收到]用户信息***%@",profile);
        }
            break;
        case XMChatProtoTypeGetProfilesResult: //返回批量用户信息结果
        {
            NSError *error;
            ProfileList *profiles = [[ProfileList alloc]initWithData:package error:&error];
            if(error == nil && profiles != nil) {
                [self profilesResultHandler:profiles.profilesArray];
            }else {
                MSLog(@"消息protobuf解析失败-- %@",error);
            }
            MSLog(@"[收到]批量用户信息***%@",profiles);
        }
            break;
        case XMChatProtoTypeResult: //主动发起操作处理结果
        {
            NSError *error;
            Result *result = [[Result alloc]initWithData:package error:&error];
            if(error == nil && result != nil) {
                [self messageRsultHandler:result];
            }else {
                MSLog(@"消息protobuf解析失败-- %@",error);
            }
            MSLog(@"主动发起操作处理结果***%@",result);
        }
            break;
        case XMChatProtoTypeProfileOnline: //有用户上线了
        {
            NSError *error;
            ProfileOnline *online = [[ProfileOnline alloc]initWithData:package error:&error];
            if (error == nil && online != nil) {
                @synchronized (self) {
                    [self.offlineCache addObject:online];
                }
            }else {
                MSLog(@"消息protobuf解析失败-- %@",error);
            }
            MSLog(@"[收到]有用户上线了***%@",online);
        }
            break;
            
        case XMChatProtoTypeProfileOffline: //有用户下线了
        {
            NSError *error;
            UsrOffline *offline = [[UsrOffline alloc]initWithData:package error:&error];
            if (error == nil && offline != nil) {
                @synchronized (self) {
                    [self.offlineCache addObject:offline];
                }
            }else {
                MSLog(@"消息protobuf解析失败-- %@",error);
            }
            MSLog(@"[收到]有用户下线了***%@",offline);
        }
            break;
        case XMChatProtoTypeChatListChanged: //会话某些属性发生变更
        {
            NSError *error;
            ChatItemUpdate *item = [[ChatItemUpdate alloc]initWithData:package error:&error];
            if (error == nil && item != nil) {
                [self chatListChanged:item];
            }else {
                MSLog(@"消息protobuf解析失败-- %@",error);
            }
        }
            break;
        case XMChatProtoTypeGetSparkResponse: //获取首页sparks返回   for demo
        {
            NSError *error;
            Sparks *datas = [[Sparks alloc]initWithData:package error:&error];
            if(error == nil && datas != nil) {
                [self.socket sendMessageResponse:datas.sign resultCode:ERR_SUCC resultMsg:@"" response:datas];
            }else {
                MSLog(@"消息protobuf解析失败-- %@",error);
            }
            MSLog(@"[收到]首页Sparks数据***");
        }
            break;
        case XMChatProtoTypeCosTokenResponse:  //cos的临时证书结果
        {
            NSError *error;
            CosKey *key = [[CosKey alloc]initWithData:package error:&error];
            if(error == nil && key != nil) {
                [self.socket sendMessageResponse:key.sign resultCode:ERR_SUCC resultMsg:@"" response:key];
            }else {
                MSLog(@"消息protobuf解析失败-- %@",error);
            }
            MSLog(@"[收到]cos的临时证书结果:%@***",key);
        }
            break;
        case XMChatProtoTypeAgoraTokenResponse: //声网的临时token结果
        {
            NSError *error;
            AgoraToken *token = [[AgoraToken alloc]initWithData:package error:&error];
            if(error == nil && token != nil) {
                [self.socket sendMessageResponse:token.sign resultCode:ERR_SUCC resultMsg:@"" response:token];
            }else {
                MSLog(@"消息protobuf解析失败-- %@",error);
            }
            MSLog(@"[收到]声网临时token:%@***",token);
        }
            break;
        case XMChatProtoTypeJoinGroupResult: //收到申请加入聊天室结果
        {
            NSError *error;
            GroupInfo *info = [[GroupInfo alloc]initWithData:package error:&error];
            if(error == nil && info != nil) {
                [self.socket sendMessageResponse:info.sign resultCode:ERR_SUCC resultMsg:@"" response:info];
            }else {
                MSLog(@"消息protobuf解析失败-- %@",error);
            }
            MSLog(@"[收到]申请加入聊天室结果:%@***",info);
        }
            break;
        case XMChatProtoTypeSendGroupMsgResponse: //发送聊天室消息回复
        {
            NSError *error;
            GroupChatSR *result = [[GroupChatSR alloc]initWithData:package error:&error];
            if (error == nil && result != nil) {
                [self.socket sendMessageResponse:result.sign resultCode:ERR_SUCC resultMsg:@"聊天室消息已发送到服务器" response:result];
            }else {
                MSLog(@"消息protobuf解析失败-- %@",error);
            }
            MSLog(@"收到单条消息回执***%@",result);
        }
            break;
        case XMChatProtoTypeRecieveGroupMsg: //收到聊天室消息
        {
            NSError *error;
            GroupChatR *recieve = [[GroupChatR alloc]initWithData:package error:&error];
            if (error == nil && recieve != nil) {
                [self receiveChatRoomMessageHandler:@[recieve]];
            }else {
                MSLog(@"消息protobuf解析失败-- %@",error);
            }
            MSLog(@"[收到]聊天室消息***%@",recieve);
        }
            break;
        case XMChatProtoTypeRecieveGroupMsgBatch: //收到聊天室批量消息
        {
            NSError *error;
            GroupChatRBatch *batch = [[GroupChatRBatch alloc]initWithData:package error:&error];
            if (error == nil && batch.msgsArray != nil) {
                [self receiveChatRoomMessageHandler:batch.msgsArray];
            }else {
                MSLog(@"消息protobuf解析失败-- %@",error);
            }
            MSLog(@"[收到]聊天室批量消息:%@",batch);
        }
            break;
        case XMChatProtoTypeJoinGroupEvent: //收到聊天室事件
        {
            NSError *error;
            GroupEvent *event = [[GroupEvent alloc]initWithData:package error:&error];
            if (error == nil) {
                [self receiveChatRoomEventHandler: event];
            }else {
                MSLog(@"消息protobuf解析失败-- %@",error);
            }
            MSLog(@"[收到]收到聊天室事件:%@",event);
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
        //清空本地的token
        [self cleanIMToken];
        
    }else if (result.code == ERR_LOGIN_KICKED_OFF_BY_OTHER) {
        if (self.connListener && [self.connListener respondsToSelector:@selector(onForceOffline)]) {
            [self.connListener onForceOffline];
        }
        //清空本地的token
        [self cleanIMToken];
    }
}

///反初始化 SDK
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
        if (fail) fail(ERR_USER_PARAMS_ERROR, @"token为空");
        return;
    }
    if (imUrl.length == 0) {
        if (fail) fail(ERR_USER_PARAMS_ERROR, @"imUrl为空");
        return;
    }
    if ([MSIMTools sharedInstance].user_id.length > 0) {
        if (fail) fail(ERR_IM_LOGIN_ALREADY, @"用户已经登录");
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

///退出登录
- (void)logout:(MSIMSucc)succ
        failed:(MSIMFail)fail
{
    //退出登录时，将当前uid做为last_uid保存下
    [[NSUserDefaults standardUserDefaults]setObject:[MSIMTools sharedInstance].user_sign forKey:@"ms_last_token"];
    ImLogout *logout = [[ImLogout alloc]init];
    logout.sign = [MSIMTools sharedInstance].adjustLocalTimeInterval;
    MSLog(@"[发送消息-logout]:\n%@",logout);
    [self.socket send:[logout data] protoType:XMChatProtoTypeLogout needToEncry:NO sign:logout.sign callback:^(NSInteger code, id  _Nullable response, NSString * _Nullable error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (code == ERR_SUCC) {
            }else {
                MSLog(@"退出登录失败*******code = %ld,response = %@,errorMsg = %@",code,response,error);
            }
        });
    }];
    [self cleanIMToken];
    if (succ) succ();
}

///更新推送的token. device_token为空时，表示推送权限关闭，不接受推送
///voip_token device_token为空时，表示不走voip推送通道
- (void)refreshPushToken:(nullable NSString *)device_token voipToken: (nullable NSString *)voip_token
{
    UpdatePushToken *update = [[UpdatePushToken alloc]init];
    update.sign = [MSIMTools sharedInstance].adjustLocalTimeInterval;
    update.pushChannel = 1;
    if (device_token.length != 0 || voip_token.length != 0) {
        update.pushToken = [NSString stringWithFormat:@"%@,%@",XMNoNilString(device_token),XMNoNilString(voip_token)];
    }
    MSLog(@"[发送消息-更新推送token]:\n%@",update);
    [self.socket send:[update data] protoType:XMChatProtoTypeRefreshPushToken needToEncry:NO sign:update.sign callback:^(NSInteger code, id  _Nullable response, NSString * _Nullable error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (code == ERR_SUCC) {
            }else {
                MSLog(@"更新推送token失败*******code = %ld,response = %@,errorMsg = %@",code,response,error);
            }
        });
    }];
}

///更新同步会话时间
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
