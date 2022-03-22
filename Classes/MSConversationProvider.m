//
//  MSConversationProvider.m
//  BlackFireIM
//
//  Created by benny wang on 2021/3/24.
//


#import "MSConversationProvider.h"
#import "MSDBConversationStore.h"


@interface MSConversationProvider()

@property(nonatomic,strong) NSMutableDictionary *mainCache;
@property(nonatomic,strong) MSDBConversationStore *store;

@end
@implementation MSConversationProvider

///单例
static MSConversationProvider *instance;
+ (instancetype)provider
{
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        instance = [[MSConversationProvider alloc]init];
    });
    return instance;
}

- (NSMutableDictionary *)mainCache
{
    if (!_mainCache) {
        _mainCache = [NSMutableDictionary dictionary];
    }
    return _mainCache;
}

- (MSDBConversationStore *)store
{
    if (!_store) {
        _store = [[MSDBConversationStore alloc]init];
    }
    return _store;
}

- (nullable MSIMConversation *)providerConversation:(NSString *)partner_id
{
    if (!partner_id) return nil;
    NSString *conv_id = [NSString stringWithFormat:@"c2c_%@",partner_id];
    MSIMConversation *conv = [self.mainCache objectForKey:conv_id];
    if (conv) {
        return conv;
    }
    MSIMConversation *con = [self.store searchConversation:conv_id];
    if (con) {
        [self.mainCache setObject:con forKey:conv_id];
        return con;
    }
    return nil;
}

- (void)updateConversations:(NSArray<MSIMConversation *> *)convs
{
    if (convs.count == 0) return;
    @synchronized (self) {
        for (MSIMConversation *conv in convs) {
            [self.mainCache setObject:conv forKey:conv.conversation_id];
        }
    }
    [self.store addConversations:convs];
}

///删除会话
- (void)deleteConversation:(NSString *)partner_id
{
    if (!partner_id) return;
    @synchronized (self) {
        NSString *conv_id = [NSString stringWithFormat:@"c2c_%@",partner_id];
        [self.mainCache removeObjectForKey:conv_id];
        [self.store updateConvesationStatus:1 conv_id:conv_id];
    }
}

- (NSInteger)allUnreadCount
{
    return [self.store allUnreadCount];
}

- (void)clean
{
    [self.mainCache removeAllObjects];
}

@end
