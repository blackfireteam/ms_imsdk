//
//  MSTCPSocket.m
//  BlackFireIM
//
//  Created by benny wang on 2021/5/14.
//

#import "MSTCPSocket.h"
#import "GCDAsyncSocket.h"
#import "Reachability.h"
#import "ChatProtobuf.pbobjc.h"
#import "MSIMTools.h"
#import "NSString+AES.h"
#import "NSData+zlib.h"
#import "MSIMErrorCode.h"



#define kMsgMaxOutTime 60
@interface MSTCPSocket()<GCDAsyncSocketDelegate>

@property(nonatomic,copy) NSString *imHost;

@property(nonatomic,assign) NSInteger imPort;

@property(nonatomic, strong) Reachability *reachability;

@property(nonatomic,assign) NetworkStatus netStatus;//当前的网络状态

@property(nonatomic,strong) NSMutableData *buffer;// 接收缓冲区
@property(nonatomic,assign) NSInteger bodyLength;//包体总长度
@property(nonatomic,strong) NSTimer *heartTimer; // 心跳 timer

@property(nonatomic,strong) NSTimer *retryTimer;//断线重连timer

@property(nonatomic,strong) GCDAsyncSocket *socket;
@property(nonatomic,strong)dispatch_queue_t socketQueue;// 数据的串行队列

@property(nonatomic,assign) BOOL needReconnect;//是否需要自动重连
@property(nonatomic,assign) NSInteger retryCount;//重连次数
@property(nonatomic,strong) NSArray *retryDurations;//自动重连间隔

@property(nonatomic,assign) MSIMNetStatus connStatus;//tcp连接状态

/** 发送消息队列池*/
@property(nonatomic,strong) NSMutableArray<MSMsgCacheItem *> *sendCache;

@property(nonatomic,strong) NSTimer *sendTimer;

@property(nonatomic,strong) NSLock *cacheLock;

@property(nonatomic,strong) NSMutableDictionary *taskIDs;

@property(nonatomic,assign) MSIMUserStatus userStatus;//用户登录状态

@property(nonatomic,assign) NSInteger sendCount;

@property(nonatomic,assign) BOOL isSuspect;

@end
@implementation MSTCPSocket

static MSTCPSocket *_manager;
+ (instancetype)sharedInstance
{
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        _manager = [[MSTCPSocket alloc]init];
    });
    return _manager;
}

- (instancetype)init
{
    if (self = [super init]) {
        _needReconnect = YES;
        [self refreshImUrl];
        _buffer = [NSMutableData data];
        [_buffer setLength: 0];
        _sendCache = [NSMutableArray array];
        _cacheLock = [[NSLock alloc]init];
        _retryDurations = @[@(0),@(0.25),@(0.5),@(1),@(2),@(4),@(8),@(16),@(32),@(64)];
        _socket = [[GCDAsyncSocket alloc]initWithDelegate:self delegateQueue:self.socketQueue];
        _sendTimer = [NSTimer scheduledTimerWithTimeInterval:0.02 target:self selector:@selector(sendTimerHandler:) userInfo:nil repeats:true];
        [[NSRunLoop mainRunLoop]addTimer:_sendTimer forMode:NSRunLoopCommonModes];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChanged:) name:kReachabilityChangedNotification object:nil];
        self.reachability = [Reachability reachabilityWithHostName:@"www.apple.com"];
        [self.reachability startNotifier];
        
        //app启动或者app从后台进入前台都会调用这个方法
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appBecomeActive) name:UIApplicationDidBecomeActiveNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidEnterBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];
    }
    return self;
}

- (dispatch_queue_t)socketQueue
{
    if(!_socketQueue) {
        _socketQueue = dispatch_queue_create("socketQueue", NULL);
        MSLog(@"*****%@",_socketQueue);
    }
    return _socketQueue;
}

///建立tcp新连接
- (void)connectTCPToServer
{
    [self refreshImUrl];
    if (self.imHost.length == 0 || self.imPort == 0) return;
    if (self.connStatus == IMNET_STATUS_SUCC) return;
    MSLog(@"请求建立TCP连接");
    self.needReconnect = YES;
    self.userStatus = IMUSER_STATUS_UNLOGIN;
    self.connStatus = IMNET_STATUS_CONNECTING;
    self.retryCount = 0;
    NSError *error = nil;
    [self.socket connectToHost:self.imHost onPort:self.imPort withTimeout:10 error:&error];
    if(error) {
        MSLog(@"socket连接错误：%@", error);
        if (self.delegate && [self.delegate respondsToSelector:@selector(connectFailed:err:)]) {
            [self.delegate connectFailed:error.code err:error.localizedDescription];
        }
        self.connStatus = IMNET_STATUS_CONNFAILED;
    }else {
        if (self.delegate && [self.delegate respondsToSelector:@selector(onConnecting)]) {
            [self.delegate onConnecting];
        }
    }
}

- (void)disConnectTCP
{
    MSLog(@"请求断开TCP连接");
    self.needReconnect = NO;
    self.imHost = nil;
    self.imPort = 0;
    [self.socket disconnect];
}

///tcp重连
- (void)reconnectTCP
{
    if (self.imHost.length == 0) return;
    if (self.connStatus == IMNET_STATUS_SUCC || self.connStatus == IMNET_STATUS_CONNECTING || self.netStatus == NotReachable) return;
    MSLog(@"断线重连");
    self.userStatus = IMUSER_STATUS_UNLOGIN;
    self.connStatus = IMNET_STATUS_CONNECTING;
    NSError *error = nil;
    [self.socket connectToHost:self.imHost onPort:self.imPort withTimeout:3 error:&error];
    if(error) {
        MSLog(@"socket连接错误：%@", error);
        if (self.delegate && [self.delegate respondsToSelector:@selector(connectFailed:err:)]) {
            [self.delegate connectFailed:error.code err:error.localizedDescription];
        }
        self.connStatus = IMNET_STATUS_CONNFAILED;
    }else {
        if (self.delegate && [self.delegate respondsToSelector:@selector(onConnecting)]) {
            [self.delegate onConnecting];
        }
    }
}

- (void)reachabilityChanged:(NSNotification *)note
{
    Reachability *curReach = note.object;
    NetworkStatus netStatus = [curReach currentReachabilityStatus];
    self.netStatus = netStatus;
    switch (netStatus) {
        case NotReachable:
            MSLog(@"当前网络不能用");
        {
            self.connStatus = IMNET_STATUS_DISCONNECT;
            if (self.delegate && [self.delegate respondsToSelector:@selector(connectFailed:err:)]) {
                [self.delegate connectFailed:ERR_NET_NOT_CONNECT err:@"network is not work"];
            }
        }
            break;
        case ReachableViaWWAN:
            MSLog(@"当前网络WAN");
            [self reconnectTCP];
            break;
        case ReachableViaWiFi:
            MSLog(@"当前网络WIFI");
            [self reconnectTCP];
            break;
        default:
            break;
    }
}

- (void)appBecomeActive
{
    self.isSuspect = NO;
    if (self.netStatus != NotReachable) {
        [self reconnectTCP];
    }
}

- (void)applicationDidEnterBackground
{
    self.isSuspect = YES;
    [self.socket disconnect];
}

- (void)refreshImUrl
{
    NSString *im_url = [[NSUserDefaults standardUserDefaults]stringForKey:@"im_url"];
    NSArray *arr = [im_url componentsSeparatedByString:@":"];
    if (arr.count == 2) {
        self.imHost = arr.firstObject;
        self.imPort = [arr.lastObject integerValue];
    }else {
        self.imHost = nil;
        self.imPort = 0;
    }
}

#pragma mark - GCDAsyncSocketDelegate
- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port
{
    MSLog(@"****建立连接成功****");
    if (self.delegate && [self.delegate respondsToSelector:@selector(connectSucc)]) {
        [self.delegate connectSucc];
    }
    self.connStatus = IMNET_STATUS_SUCC;
    [self.socket readDataWithTimeout:-1 tag:100];
    [self.retryTimer invalidate];
    self.retryTimer = nil;
    [self startHeartBeat];
    [self imLogin:[MSIMTools sharedInstance].user_sign subAppID:[MSIMTools sharedInstance].sub_app_id];
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err
{
    MSLog(@"****连接断开****%@",err);
    [self.socket disconnect];
    self.userStatus = IMUSER_STATUS_UNLOGIN;
    self.connStatus = IMNET_STATUS_CONNFAILED;
    [self closeTimer];
    [self.retryTimer invalidate];
    self.retryTimer = nil;
    if (self.netStatus != NotReachable && self.needReconnect == YES && self.isSuspect == NO) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSInteger duration = 0;
            if (self.retryCount > self.retryDurations.count-1) {
                duration = 64;
            }else {
                duration = [self.retryDurations[self.retryCount] integerValue];
            }
            if (duration > 0) {
                if (self.delegate && [self.delegate respondsToSelector:@selector(connectFailed:err:)]) {
                    [self.delegate connectFailed:ERR_SOCKET_CONNECT_FAIL err:@"tcp link failed"];
                }
            }
            self.retryTimer = [NSTimer scheduledTimerWithTimeInterval:duration target:self selector:@selector(reconnectTCP) userInfo:nil repeats:true];
            [[NSRunLoop mainRunLoop]addTimer:self.retryTimer forMode:NSRunLoopCommonModes];
            self.retryCount++;
        });
    }
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
    [_buffer appendData:data];
    while (_buffer.length >=4) {
        SInt32 length = 0;
        [_buffer getBytes:&length length:4];//1.先读取包头4字节的长度
        HTONL(length);//ios系统采用的是小端序，将网络的大端序转换成本机序
        if(length == 0) {
            //没有申明长度的包作为异常包丢弃
            NSData *tmp = [_buffer subdataWithRange:NSMakeRange(4, _buffer.length-4)];
            [_buffer setLength:0];//清零
            [_buffer appendData:tmp];
            MSLog(@"buffer length = 0");
        }else {
            _bodyLength = (length >> 12) - 4;
            BOOL isZip = length & 1;//对应是否压缩
            BOOL isSecrect = (length >> 1) & 1; //是否加密
            NSInteger type = (length & 4095) >> 2;//对应protobuf的模型
            
            if(_buffer.length >= (_bodyLength+4)) {//如果数据包没有超过缓冲区的大小
                @try {
                    NSData *data = [_buffer subdataWithRange:NSMakeRange(4, _bodyLength)];
                    if(data != nil && isSecrect) {//先解密
                        MSLog(@"buffer 解密");
                        NSString *encryStr = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
                        data = [[NSString decryptAES:encryStr key:nil]dataUsingEncoding:NSUTF8StringEncoding];
                    }
                    if(data != nil && isZip) {//先解压
                        MSLog(@"buffer 解压");
                        data = [NSData dataByDecompressingData:data];
                    }
                    [self handlePackage:data protoType:type];//收到的数据分发
                    // 截取剩下的作为下个数据包
                    NSData *tmp = [_buffer subdataWithRange:NSMakeRange(_bodyLength+4, _buffer.length-_bodyLength-4)];
                    [_buffer setLength:0];//清零
                    [_buffer appendData:tmp];
                }@catch (NSException *exception) {
                    MSLog(@"exception name is %@,reason is %@",exception.name,exception.reason);
                }
            }else {
                MSLog(@"******buffer break");
                break;
            }
        }
    }
    [self.socket readDataWithTimeout:-1 tag:100];
}

- (void)send:(NSData *)sendData protoType:(XMChatProtoType)protoType needToEncry:(BOOL)encry sign:(int64_t)sign callback:(TCPBlock)block
{
    if (self.connStatus != IMNET_STATUS_SUCC) {
        [self reconnectTCP];
    }
    //等发送消息先加入消息队列
    [self.cacheLock lock];
    //重新生成一个taskID,映射到msg_seq
    NSString *taskID = [NSString stringWithFormat:@"%zd",[MSIMTools sharedInstance].adjustLocalTimeInterval];
    [self.taskIDs setObject:@(sign) forKey:taskID];
    
    MSMsgCacheItem *item = [[MSMsgCacheItem alloc]init];
    item.taskID = taskID;
    item.data = sendData;
    item.protoType = protoType;
    item.encry = encry;
    item.sign = sign;
    item.block = block;
    [self.sendCache addObject:item];

    [self.cacheLock unlock];
}

/** 鉴权*/
- (void)imLogin:(NSString *)user_sign subAppID:(NSInteger)subID
{
    WS(weakSelf)
    ImLogin *login = [[ImLogin alloc]init];
    login.token = user_sign;
    login.sign = [MSIMTools sharedInstance].adjustLocalTimeInterval;
    login.ct = 1;
    login.subApp = subID;
    login.pushChannel = 1;
    NSString *apnsToken = [[NSUserDefaults standardUserDefaults]stringForKey:kApnsTokenKey];
    NSString *voipToken = [[NSUserDefaults standardUserDefaults]stringForKey:kVoipTokenKey];
    if (apnsToken.length != 0 || voipToken.length != 0) {
        login.pushToken = [NSString stringWithFormat:@"%@,%@",XMNoNilString(apnsToken),XMNoNilString(voipToken)];
    }
    login.lastToken = [[NSUserDefaults standardUserDefaults]stringForKey:@"ms_last_token"];
    MSLog(@"[发送消息-login]:\n%@",login);
    [self send:[login data] protoType:XMChatProtoTypeLogin needToEncry:false sign:login.sign callback:^(NSInteger code, id  _Nullable response, NSString * _Nullable error) {
        STRONG_SELF(strongSelf)
        
        if (code == ERR_SUCC) {
            strongSelf.retryCount = 0;
            strongSelf.userStatus = IMUSER_STATUS_LOGIN;
            Result *result = response;
            [MSIMTools sharedInstance].user_id = [NSString stringWithFormat:@"%lld",result.uid];
            [[MSIMTools sharedInstance] updateServerTime:result.nowTime*1000*1000];
            if (strongSelf.delegate && [strongSelf.delegate respondsToSelector:@selector(onIMLoginSucc)]) {
                [strongSelf.delegate onIMLoginSucc];
            }
        }else {
            if (code == ERR_USER_SIG_EXPIRED || code == ERR_IM_TOKEN_NOT_FIND) {
                strongSelf.userStatus = IMUSER_STATUS_SIGEXPIRED;
            }else {
                strongSelf.userStatus = IMUSER_STATUS_UNLOGIN;
            }
            MSLog(@"token 鉴权失败*******code = %ld,response = %@,errorMsg = %@",code,response,error);
            if (strongSelf.delegate && [strongSelf.delegate respondsToSelector:@selector(onIMLoginFail:msg:)]) {
                [strongSelf.delegate onIMLoginFail:code msg:error];
            }
        }
    }];
}

- (void)handlePackage:(NSData *)package protoType:(XMChatProtoType)type
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(onRevieveData:protoType:)]) {
        [self.delegate onRevieveData:package protoType:type];
    }
}

- (void)sendTimerHandler:(NSTimer *)timer
{
    self.sendCount++;
    if (self.sendCount % 50 == 0) {
        [self outTimeClean];
        self.sendCount = 0;
    }
    if ([self.delegate respondsToSelector:@selector(globTimerCallback)]) {
        [self.delegate globTimerCallback];
    }
    if (self.sendCache.count == 0) return;
    
    if (self.connStatus != IMNET_STATUS_SUCC) return;
    
    MSMsgCacheItem *noNeedLoginItem = nil;
    for (NSInteger i = 0; i < self.sendCache.count; i++) {
        MSMsgCacheItem *item = self.sendCache[i];
        if (item.isSending == NO && (item.protoType == XMChatProtoTypeLogin || item.protoType == CMChatProtoTypeGetImToken)) {
            noNeedLoginItem = item;
            noNeedLoginItem.isSending = YES;
            break;
        }
    }
    if (noNeedLoginItem) {
        [self sendTcpMessage:noNeedLoginItem.data protoType:noNeedLoginItem.protoType needToEncry:noNeedLoginItem.encry];
    }else {
        if ( self.userStatus != IMUSER_STATUS_LOGIN) return;
        for (NSInteger i = 0; i < self.sendCache.count; i++) {
            MSMsgCacheItem *item = self.sendCache[i];
            if (item.isSending == NO) {
                item.isSending = YES;
                [self sendTcpMessage:item.data protoType:item.protoType needToEncry:item.encry];
                break;
            }
        }
    }
}

- (void)sendTcpMessage:(NSData *)sendData protoType:(XMChatProtoType)protoType needToEncry:(BOOL)encry
{
    // 包头是 4个字节 包括：前20位代表整个数据包的长度，后11位代表proto的编码 ，最后一位表示报文是否压缩
    NSInteger type = protoType;
    type = type << 2;
    NSInteger isZip = 0;
    if((sendData.length + 4)/1024 > 10) {//如果发送的文本大于10kb,进行zlib压缩
        isZip = 1;
        sendData = [NSData dataByCompressingData:sendData];
    }
    encry = encry << 1;
    NSInteger originalLength = ((NSInteger)sendData.length + 4) << 12;
    NSInteger allLength = originalLength + type + encry + isZip;
    
    HTONL(allLength);
    NSMutableData *data = [NSMutableData dataWithBytes:&allLength length:4];//生成包头
    [data appendData:sendData];

    [self.socket writeData:data withTimeout:-1 tag:100];
}

- (void)sendMessageResponse:(NSInteger)sign resultCode:(NSInteger)code resultMsg:(NSString *)msg response:(id)response
{
    for (NSInteger i = 0; i < self.sendCache.count; i++) {
        MSMsgCacheItem *item = self.sendCache[i];
        if (item.sign == sign) {
            if (item.block) {
                item.block(code, response, msg);
            }
            [self.sendCache removeObject:item];
        }
    }
}

- (void)outTimeClean
{
    for (NSInteger i = 0; i < self.sendCache.count; i++) {
        MSMsgCacheItem *item = self.sendCache[i];
        NSInteger sendTime = item.taskID.integerValue;
        if (([MSIMTools sharedInstance].adjustLocalTimeInterval - sendTime) > kMsgMaxOutTime*1000*1000) {//判断超时，回调失败
            if (item.block) {
                item.block(item.sign, nil, @"send message time out");
            }
            [self.sendCache removeObject:item];
        }
    }
}

- (void)cleanCache
{
    [self.sendCache removeAllObjects];
}

#pragma mark - 心跳
/** 开启心跳 */
- (void)startHeartBeat
{
    [self closeTimer];
    // timer 要在主线程中开启才有效
    dispatch_async(dispatch_get_main_queue(), ^{
        self.heartTimer = [NSTimer scheduledTimerWithTimeInterval:self.config.heartDuration target:self selector:@selector(sendHeart) userInfo:nil repeats:true];
        [[NSRunLoop mainRunLoop]addTimer:self.heartTimer forMode:NSRunLoopCommonModes];
    });
}

/** 关闭心跳*/
- (void)closeTimer
{
    if (self.heartTimer != nil) {
        [self.heartTimer invalidate];
        self.heartTimer = nil;
    }
}

/** 发送心跳*/
- (void)sendHeart
{
    Ping *ping = [[Ping alloc]init];
    ping.type = 0;
    MSLog(@"[发送消息-心跳包]:\n%@",ping);
    [self send:[ping data] protoType:XMChatProtoTypeHeadBeat needToEncry:NO sign:[MSIMTools sharedInstance].adjustLocalTimeInterval callback:^(NSInteger code, id  _Nullable response, NSString * _Nullable error) {
        
    }];
}

@end


@implementation MSMsgCacheItem


@end
