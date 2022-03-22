//
//  MSCacheProvider.h
//  MSIMSDK
//
//  Created by benny wang on 2021/9/29.
//
//
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MSCacheProvider : NSObject

///单例
+ (instancetype)provider NS_SWIFT_NAME(shared());

/// 向某张表中批量缓存数据
- (BOOL)updateCaches:(NSArray<NSString *> *)keys values:(NSArray<NSString *> *)values inTable:(NSString *)tableName;

/// 批量读取数据
- (nullable NSArray<NSString *> *)valuesForKeys:(NSArray<NSString *> *)keys inTable:(NSString *)tableName;

/// 取出某张表中对应key的value
- (nullable NSString *)valueForKey:(NSString *)key inTable:(NSString *)tableName;

/// 从某一张表中删除批量数据
- (void)deleteRowForKeys:(NSArray<NSString *> *)keys fromTable:(NSString *)tableName;

/// 删除一张表
- (BOOL)deleteTable:(NSString *)tableName;

@end

NS_ASSUME_NONNULL_END
