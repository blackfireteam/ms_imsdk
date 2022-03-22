//
//  NSDictionary+Ext.m
//  BlackFireIM
//
//  Created by benny wang on 2021/3/20.
//

#import "NSDictionary+Ext.h"

@implementation NSDictionary (Ext)

//字典转json格式字符串：
- (NSString *)el_convertJsonString
{
    if (self == nil) {
        return @"";
    }
    NSError *parseError = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:self options:NSJSONWritingPrettyPrinted error:&parseError];
    return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
}

- (NSData *)el_convertData
{
    if (self == nil) {
        return nil;
    }
    NSError *parseError = nil;
    NSData *data = [NSJSONSerialization dataWithJSONObject:self options:NSJSONWritingPrettyPrinted error:&parseError];
    return data;
}

+ (NSDictionary *)el_convertFromData:(NSData *)data
{
    if (data == nil) return nil;
    return [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
}

@end
