//
//  MSIMConversation.m
//  BlackFireIM
//
//  Created by benny wang on 2021/3/3.
//

#import "MSIMConversation.h"
#import "MSProfileProvider.h"


@implementation MSIMConversation

- (NSString *)conversation_id {
    if (self.partner_id.length == 0) {
        return @"";
    }
    if (self.chat_type == MSIM_CHAT_TYPE_C2C) {
        return [NSString stringWithFormat:@"c2c_%@",self.partner_id];
    }else {
        return [NSString stringWithFormat:@"group_%@",self.partner_id];
    }
}

- (NSString *)extString
{
    if (self.ext == nil) {
        return @"";
    }else {
        NSDictionary *dic = [self.ext convertToDictionary];
        NSData *data = [NSJSONSerialization dataWithJSONObject:dic options:NSJSONWritingPrettyPrinted error:nil];
        if (data == nil) {
            return @"";
        }else {
            return [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
        }
    }
}

- (MSProfileInfo *)userInfo
{
    return [[MSProfileProvider provider] providerProfileFromLocal:self.partner_id];
}

@end


@implementation MSCustomExt

- (MSCustomExt *)initWithDictionary:(NSDictionary *)dic
{
    if (dic == nil) {
        return nil;
    }
    MSCustomExt *ext = [[MSCustomExt alloc]init];
    ext.matched = [dic[@"matched"] integerValue];
    ext.new_msg = [dic[@"new_msg"] integerValue];
    ext.my_move = [dic[@"my_move"] integerValue];
    ext.ice_break = [dic[@"ice_break"] integerValue];
    ext.tip_free = [dic[@"tip_free"] integerValue];
    ext.top_album = [dic[@"top_album"] integerValue];
    ext.i_block_u = [dic[@"i_block_u"] integerValue];
    return  ext;
}

- (NSDictionary *)convertToDictionary
{
    NSMutableDictionary *dic = [NSMutableDictionary dictionary];
    [dic setValue:@(self.matched) forKey:@"matched"];
    [dic setValue:@(self.new_msg) forKey:@"new_msg"];
    [dic setValue:@(self.my_move) forKey:@"my_move"];
    [dic setValue:@(self.ice_break) forKey:@"ice_break"];
    [dic setValue:@(self.tip_free) forKey:@"tip_free"];
    [dic setValue:@(self.top_album) forKey:@"top_album"];
    [dic setValue:@(self.i_block_u) forKey:@"i_block_u"];
    return dic;
}

@end
