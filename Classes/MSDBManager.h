//
//  MSDBManager.h
//  BlackFireIM
//
//  Created by benny wang on 2021/3/2.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class FMDatabaseQueue;
@interface MSDBManager : NSObject

+ (instancetype)sharedInstance;

@property(nonatomic,strong) NSMutableDictionary *tableCache;

/**
 *  与IM相关的DB队列
 */
@property (nonatomic, strong) FMDatabaseQueue *messageQueue;

/**
 *  通用的DB队列
 */
@property (nonatomic, strong) FMDatabaseQueue *commonQueue;

/**
 *  用户自定义的DB队列
 */
@property (nonatomic, strong) FMDatabaseQueue *customQueue;


/**
 针对用户切换帐号的情况
 */
- (void)accountChanged;

///app启动或切换帐号时，扫描消息数据库中所有消息表，将消息发送中状态的消息改成发送失败
- (void)scanAllTables;

@end

NS_ASSUME_NONNULL_END
