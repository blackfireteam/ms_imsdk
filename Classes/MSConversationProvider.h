//
//  MSConversationProvider.h
//  BlackFireIM
//
//  Created by benny wang on 2021/3/24.
//

#import <Foundation/Foundation.h>
#import <MSIMSDK/MSIMConversation.h>


NS_ASSUME_NONNULL_BEGIN

@interface MSConversationProvider : NSObject

///单例
+ (instancetype)provider NS_SWIFT_NAME(shared());

- (nullable MSIMConversation *)providerConversation:(NSString *)partner_id;

- (void)updateConversations:(NSArray<MSIMConversation *> *)convs;

- (void)deleteConversation:(NSString *)partner_id;

- (NSInteger)allUnreadCount;

- (void)clean;

@end

NS_ASSUME_NONNULL_END
