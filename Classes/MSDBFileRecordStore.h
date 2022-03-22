//
//  MSDBImageFileStore.h
//  BlackFireIM
//
//  Created by benny wang on 2021/3/18.
//

#import <MSIMSDK/MSDBBaseStore.h>


NS_ASSUME_NONNULL_BEGIN

@class MSFileInfo;
@interface MSDBFileRecordStore : MSDBBaseStore

///向数据库中添加一条记录
- (BOOL)addRecord:(MSFileInfo *)info;

///查找某一条记录
- (MSFileInfo *)searchRecord:(NSString *)key;

///删除某一条记录
- (BOOL)deleteRecord:(NSString *)key;


@end

@interface MSFileInfo: NSObject

@property(nonatomic,copy) NSString *uuid;

@property(nonatomic,copy) NSString *url;

@property(nonatomic,copy) NSString *coverUrl;

@property(nonatomic,assign) NSInteger modTime;
@end

NS_ASSUME_NONNULL_END
