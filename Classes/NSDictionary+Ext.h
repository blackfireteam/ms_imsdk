//
//  NSDictionary+Ext.h
//  BlackFireIM
//
//  Created by benny wang on 2021/3/20.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSDictionary (Ext)

- (NSString *)el_convertJsonString;

- (NSData *)el_convertData;

+ (NSDictionary *)el_convertFromData:(NSData *)data;

@end

NS_ASSUME_NONNULL_END
