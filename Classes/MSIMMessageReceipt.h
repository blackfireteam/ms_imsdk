//
//  MSIMMessageReceipt.h
//  BlackFireIM
//
//  Created by benny wang on 2021/4/7.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MSIMMessageReceipt : NSObject


@property(nonatomic,copy)NSString *user_id;

///已读消息id，这个id之前的消息都可以认为对方已读
@property(nonatomic,assign)NSInteger msg_id;


@end

NS_ASSUME_NONNULL_END
