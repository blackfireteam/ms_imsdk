//
//  MSCacheProvider.m
//  MSIMSDK
//
//  Created by benny wang on 2021/9/29.
//

#import "MSCacheProvider.h"
#import "MSCustomStore.h"


@interface MSCacheProvider()

@property(nonatomic,strong) MSCustomStore *store;

@end
@implementation MSCacheProvider

///单例
static MSCacheProvider *instance;
+ (instancetype)provider
{
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        instance = [[MSCacheProvider alloc]init];
    });
    return instance;
}

- (MSCustomStore *)store
{
    if (!_store) {
        _store = [[MSCustomStore alloc] init];
    }
    return _store;
}

/// 向某张表中批量缓存数据
- (BOOL)updateCaches:(NSArray<NSString *> *)keys values:(NSArray<NSString *> *)values inTable:(NSString *)tableName
{
    if (keys.count == 0 || values.count == 0) return NO;
    if (tableName.length == 0) return NO;
    if (keys.count != values.count) return NO;
    return [self.store cacheValues:values forKeys:keys inTable:tableName];
}

/// 取出某张表中对应key的value
- (nullable NSArray<NSString *> *)valuesForKeys:(NSArray<NSString *> *)keys inTable:(NSString *)tableName
{
    if (keys.count == 0 || tableName.length == 0) return nil;
    return [self.store valuesForKey:keys fromTable:tableName];
}

/// 取出某张表中对应key的value
- (nullable NSString *)valueForKey:(NSString *)key inTable:(NSString *)tableName
{
    if (key.length == 0 || tableName.length == 0) return nil;
    return [self.store valueForKey:key fromTable:tableName];
}

/// 从某一张表中删除一条数据
- (void)deleteRowForKeys:(NSArray<NSString *> *)keys fromTable:(NSString *)tableName
{
    if (keys.count == 0 || tableName.length == 0) return;
    [self.store deleteRowForKeys:keys fromTable:tableName];
}

- (BOOL)deleteTable:(NSString *)tableName
{
    return [self.store deleteTable:tableName];
}


@end

