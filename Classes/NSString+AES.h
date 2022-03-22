//
//  NSString+AES.h
//  adeCode
//
//  Created by bennyw on 2017/3/2.
//  Copyright © 2017年 XMQ. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (AES)

/** 加密 */
+ (NSString *)encryptAES:(NSString *)content key:(NSString *)key;
/** 解密 */
+ (NSString *)decryptAES:(NSString *)content key:(NSString *)key;

@end
