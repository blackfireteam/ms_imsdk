//
//  MSIMManager+Internal.h
//  MSIMSDK
//
//  Created by benny wang on 2021/9/29.
//

#import "MSIMSDK.h"
#import "MSDBMessageStore.h"
#import "MSDBConversationStore.h"
#import "MSTCPSocket.h"

NS_ASSUME_NONNULL_BEGIN

@interface MSIMManager ()

@property(nonatomic,strong) MSTCPSocket *socket;

@property(nonatomic,strong) MSDBMessageStore *messageStore;

@property(nonatomic,strong) MSDBConversationStore *convStore;

///暂时缓存服务器返回的会话列表，当接收到服务器返回的所有会话时，再写入数据库
@property(nonatomic,strong) NSMutableArray *convCaches;

///消息池，当短时间内收到大量消息时，批量消息处理以提高性能
@property(nonatomic,strong) NSMutableArray *messageCaches;

///用户下线消息池，当短时间内收到大量用户下线消息时，批量处理
@property(nonatomic,strong) NSMutableArray *offlineCache;

///当接收到服务器返回的所有会话时,批量同步profile信息，再写入数据库
@property(nonatomic,strong) NSMutableArray *profileCaches;

/// 保证sign生成机制唯一
@property(nonatomic,strong) NSMutableDictionary *cacheMsgSigns;

///记录上次同步会话的时间戳
@property(nonatomic,assign) NSInteger chatUpdateTime;

///同步会话列表是否完成
@property(nonatomic,assign) BOOL isChatListResult;

///更新同步会话时间
- (void)updateChatListUpdateTime:(NSInteger)updateTime;


@end

NS_ASSUME_NONNULL_END
