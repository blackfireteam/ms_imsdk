//
//  MSDBBaseStore.m
//  BlackFireIM
//
//  Created by benny wang on 2021/3/16.
//

#import "MSDBBaseStore.h"
#import "FMDB.h"
#import "MSDBManager.h"


@implementation MSDBBaseStore

- (FMDatabaseQueue *)dbQueue
{
    return [MSDBManager sharedInstance].messageQueue;
}

- (BOOL)createTable:(NSString *)tableName withSQL:(NSString *)sqlString
{
    __block BOOL ok = YES;
    [self.dbQueue inDeferredTransaction:^(FMDatabase * _Nonnull db, BOOL * _Nonnull rollback) {
        if(![db tableExists:tableName]){
            ok = [db executeUpdate:sqlString];
        }
    }];
    return ok;
}

- (BOOL)tableExists:(NSString *)tableName
{
    if (tableName.length == 0) return NO;
    NSNumber *isExistNum = [[MSDBManager sharedInstance].tableCache objectForKey:tableName];
    if (isExistNum.boolValue) return YES;
    __block BOOL isExist = NO;
    if (self.dbQueue) {
        [self.dbQueue inDeferredTransaction:^(FMDatabase * _Nonnull db, BOOL * _Nonnull rollback) {
            if ([db tableExists:tableName]) {
                [[MSDBManager sharedInstance].tableCache setObject:@(YES) forKey:tableName];
                isExist = YES;
            }
        }];
    }
    return isExist;
}

/**
*  判断表中是否存在该字段，如果不存在则添加
*/
- (BOOL)inertColumnInTable:(NSString *)tableName columnName:(NSString *)columnName columnType:(NSString *)type
{
    __block BOOL ok = NO;
    if(self.dbQueue) {
        [self.dbQueue inDeferredTransaction:^(FMDatabase * _Nonnull db, BOOL * _Nonnull rollback) {
            if(![db columnExists:columnName inTableWithName:tableName]) {
                NSString *sql = [NSString stringWithFormat:@"ALTER TABLE %@ ADD %@ %@",tableName,columnName,type];
                ok = [db executeUpdate:sql];
            }else {
                ok = YES;
            }
        }];
    }
    return ok;
}

- (BOOL)excuteSQL:(NSString *)sqlString withArrParameter:(NSArray *)arrParameter
{
    __block BOOL ok = NO;
    if (self.dbQueue) {
        [self.dbQueue inDeferredTransaction:^(FMDatabase * _Nonnull db, BOOL * _Nonnull rollback) {
            ok = [db executeUpdate:sqlString withArgumentsInArray:arrParameter];
        }];
    }
    return ok;
}

- (BOOL)excuteSQL:(NSString *)sqlString withDicParameter:(NSDictionary *)dicParameter
{
    __block BOOL ok = NO;
    if (self.dbQueue) {
        [self.dbQueue inDeferredTransaction:^(FMDatabase * _Nonnull db, BOOL * _Nonnull rollback) {
            ok = [db executeUpdate:sqlString withParameterDictionary:dicParameter];
        }];
    }
    return ok;
}

- (BOOL)excuteSQL:(NSString *)sqlString,...
{
    __block BOOL ok = NO;
    if (self.dbQueue) {
        va_list args;
        va_list *p_args;
        p_args = &args;
        va_start(args, sqlString);
        [self.dbQueue inDeferredTransaction:^(FMDatabase * _Nonnull db, BOOL * _Nonnull rollback) {
            ok = [db executeUpdate:sqlString withVAList:*p_args];
        }];
        va_end(args);
    }
    return ok;
}

- (void)excuteQuerySQL:(NSString*)sqlStr resultBlock:(void(^)(FMResultSet * rsSet))resultBlock
{
    if (self.dbQueue) {
        [self.dbQueue inDeferredTransaction:^(FMDatabase * _Nonnull db, BOOL * _Nonnull rollback) {
            FMResultSet * retSet = [db executeQuery:sqlStr];
            if (resultBlock) {
                resultBlock(retSet);
            }
        }];
    }
}

@end
