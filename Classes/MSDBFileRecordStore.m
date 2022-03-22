//
//  MSDBImageFileStore.m
//  BlackFireIM
//
//  Created by benny wang on 2021/3/18.
//

#import "MSDBFileRecordStore.h"
#import "FMDB.h"
#import <MSIMSDK/MSIMSDK.h>
#import "MSIMManager+Internal.h"


static NSString *FILE_TABLE_NAME = @"file2";
@implementation MSDBFileRecordStore

- (FMDatabaseQueue *)dbQueue
{
    return [MSDBManager sharedInstance].commonQueue;
}

///向数据库中添加一条记录
- (BOOL)addRecord:(MSFileInfo *)info
{
    if (info == nil || info.uuid.length == 0 || info.url.length == 0) {
        return NO;
    }
    NSString *createSQL = [NSString stringWithFormat:@"create table if not exists %@(uuid TEXT,url TEXT,cover TEXT,mod_time INTEGER,PRIMARY KEY(uuid))",FILE_TABLE_NAME];
    BOOL isOK = [self createTable:FILE_TABLE_NAME withSQL:createSQL];
    if (isOK == NO) {
        NSLog(@"创建表失败****%@",FILE_TABLE_NAME);
        return NO;
    }
    NSString *addSQL = @"REPLACE into %@ (uuid,url,cover,mod_time) VALUES (?,?,?,?)";
    NSString *sqlStr = [NSString stringWithFormat:addSQL,FILE_TABLE_NAME];
    NSArray *addParams = @[info.uuid,XMNoNilString(info.url),XMNoNilString(info.coverUrl),@(info.modTime)];
    BOOL isAddOK = [self excuteSQL:sqlStr withArrParameter:addParams];
    return isAddOK;
}

///查找某一条记录
- (MSFileInfo *)searchRecord:(NSString *)key
{
    if (key.length == 0) {
        return nil;
    }
    NSString *sqlStr = [NSString stringWithFormat:@"select * from %@ where uuid = '%@'",FILE_TABLE_NAME,key];
    __block MSFileInfo *info = nil;
    [self excuteQuerySQL:sqlStr resultBlock:^(FMResultSet * _Nonnull rsSet) {
        while ([rsSet next]) {
            info = [[MSFileInfo alloc]init];
            info.uuid = [rsSet stringForColumn:@"uuid"];
            info.url = [rsSet stringForColumn:@"url"];
            info.coverUrl = [rsSet stringForColumn:@"cover"];
            info.modTime = [rsSet longLongIntForColumn:@"mod_time"];
        }
        [rsSet close];
    }];
    //判断这条记录有没有过期
    NSInteger overDay = [MSIMManager sharedInstance].socket.config.objectCleanDay;
    if (overDay == -1) {
        return info;
    }
    if (info && ([MSIMTools sharedInstance].adjustLocalTimeInterval-info.modTime)*1.0/1000.0/1000.0 >= overDay*24*60*60) {
        return nil;
    }
    return info;
}

///删除某一条记录
- (BOOL)deleteRecord:(NSString *)key
{
    if (key.length == 0) {
        return NO;
    }
    NSString *sqlString = [NSString stringWithFormat:@"DELETE FROM %@ WHERE uuid = '%@'", FILE_TABLE_NAME, key];
    BOOL ok = [self excuteSQL:sqlString];
    return ok;
}


@end

@implementation MSFileInfo



@end
