//
//  MSCustomStore.h
//  MSIMSDK
//
//  Created by benny wang on 2021/9/29.
//

#import <MSIMSDK/MSIMSDK.h>

NS_ASSUME_NONNULL_BEGIN

@interface MSCustomStore : MSDBBaseStore

/// 向某张表中批量数据
- (BOOL)cacheValues:(NSArray<NSString *> *)values forKeys:(NSArray<NSString *> *)keys inTable:(NSString *)tableName;

/// 从某一张表中批量取出数据
- (nullable NSArray<NSString *> *)valuesForKey:(NSArray<NSString *> *)keys fromTable:(NSString *)tableName;

/// 从某一张表中取出一条数据
- (nullable NSString *)valueForKey:(NSString *)key fromTable:(NSString *)tableName;

/// 从某一张表中批量删除数据
- (void)deleteRowForKeys:(NSArray<NSString *> *)keys fromTable:(NSString *)tableName;

/// 删除一张表
- (BOOL)deleteTable:(NSString *)tableName;

@end

NS_ASSUME_NONNULL_END
