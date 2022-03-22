//
//  MSCustomStore.m
//  MSIMSDK
//
//  Created by benny wang on 2021/9/29.
//

#import "MSCustomStore.h"
#import "FMDB.h"
#import "MSDBManager.h"


@implementation MSCustomStore

- (FMDatabaseQueue *)dbQueue
{
    return [MSDBManager sharedInstance].customQueue;
}


- (BOOL)cacheValues:(NSArray<NSString *> *)values forKeys:(NSArray<NSString *> *)keys inTable:(NSString *)tableName
{
    if (tableName.length == 0) return NO;
    NSString *createSQL = [NSString stringWithFormat:@"create table if not exists %@(key TEXT,value TEXT,ext TEXT,PRIMARY KEY(key))",tableName];
    __block BOOL isOK = [self createTable:tableName withSQL:createSQL];
    if (isOK == NO) {
        NSLog(@"创建表失败****%@",tableName);
        return NO;
    }
    [self.dbQueue inDeferredTransaction:^(FMDatabase * _Nonnull db, BOOL * _Nonnull rollback) {
        NSString *addSQL = @"replace into %@ (key,value,ext) VALUES (?,?,?)";
        NSString *sqlStr = [NSString stringWithFormat:addSQL,tableName];
        for (NSInteger i = 0; i < keys.count; i++) {
            NSString *key = keys[i];
            NSString *value = values[i];
            NSArray *addParams = @[key,XMNoNilString(value),@""];
            BOOL ok = [db executeUpdate:sqlStr withArgumentsInArray:addParams];
            if (ok == NO) {
                isOK = NO;
                *rollback = YES;
                break;
            }
        }
    }];
    return isOK;
}

- (nullable NSArray<NSString *> *)valuesForKey:(NSArray<NSString *> *)keys fromTable:(NSString *)tableName
{
    __block NSMutableArray *values = [NSMutableArray array];
    [self.dbQueue inDeferredTransaction:^(FMDatabase * _Nonnull db, BOOL * _Nonnull rollback) {

        for (NSInteger i = 0; i < keys.count; i++) {
            NSString *key = keys[i];
            NSString *sqlStr = [NSString stringWithFormat:@"select * from %@ where key = '%@'",tableName,key];
            
            FMResultSet *rsSet = [db executeQuery:sqlStr];
            while ([rsSet next]) {
                NSString *value = [rsSet stringForColumn:@"value"];
                if (value) {
                    [values addObject:value];
                }
            }
        }
    }];
    if (values.count == 0) {
        return nil;
    }
    return values;
}

/// 从某一张表中取出一条数据
- (nullable NSString *)valueForKey:(NSString *)key fromTable:(NSString *)tableName
{
    __block NSString *value = nil;
    NSString *sqlStr = [NSString stringWithFormat:@"select * from %@ where key = '%@'",tableName,key];
    [self excuteQuerySQL:sqlStr resultBlock:^(FMResultSet * _Nonnull rsSet) {
        while ([rsSet next]) {
            value = [rsSet stringForColumn:@"value"];
        }
    }];
    return value;
}

/// 从某一张表中删除一条数据
- (void)deleteRowForKeys:(NSArray<NSString *> *)keys fromTable:(NSString *)tableName
{
    [self.dbQueue inDeferredTransaction:^(FMDatabase * _Nonnull db, BOOL * _Nonnull rollback) {
        
        for (NSInteger i = 0; i < keys.count; i++) {
            NSString *key = keys[i];
            NSString *sqlString = [NSString stringWithFormat:@"DELETE FROM %@ WHERE key = '%@'", tableName, key];
            [db executeUpdate:sqlString];
        }
    }];
}

/// 删除一张表
- (BOOL)deleteTable:(NSString *)tableName
{
    if (tableName.length == 0) {
        return NO;
    }
    NSString *sqlString = [NSString stringWithFormat:@"DROP TABLE '%@'", tableName];
    BOOL ok = [self excuteSQL:sqlString];
    return ok;
}

@end
