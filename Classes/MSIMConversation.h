//
//  MSIMConversation.h
//  BlackFireIM
//
//  Created by benny wang on 2021/3/3.
//

#import <Foundation/Foundation.h>
#import <MSIMSDK/MSIMConst.h>
#import <MSIMSDK/MSIMMessage.h>
#import <MSIMSDK/MSProfileInfo.h>



NS_ASSUME_NONNULL_BEGIN

@class MSCustomExt;
@interface MSIMConversation : NSObject

///会话id
@property(nonatomic,copy,readonly) NSString *conversation_id;

///聊天类型，单聊或群聊
@property(nonatomic,assign) MSIMAChatType chat_type;

///如果是单聊：对方的uid,群聊： 指group_id
@property(nonatomic,copy) NSString *partner_id;

///服务器记录的最后一条消息id
@property(nonatomic,assign) NSInteger msg_end;

///要显示在会话列表的最后一条消息msg_sign
@property(nonatomic,assign) NSInteger show_msg_sign;

///最后一条标记为已读的消息id
@property(nonatomic,assign) NSInteger msg_last_read;

///未读数
@property(nonatomic,assign) NSInteger unread_count;

///草稿信息
@property(nonatomic,copy) NSString *draftText;

///是否置顶
@property(nonatomic,assign) NSInteger is_top;

///显示时间
@property(nonatomic,assign) NSInteger time;

///会话已删除
@property(nonatomic,assign) NSInteger deleted;

///用户信息
@property(nonatomic,strong,readonly) MSProfileInfo *userInfo;

///扩展字段
@property(nonatomic,strong) MSCustomExt *ext;

///需要展示的最后一条消息
@property(nonatomic,strong) MSIMMessage *show_msg;

- (NSString *)extString;

@end


@interface MSCustomExt: NSObject

///是否是matched
@property(nonatomic,assign) NSInteger matched;

///是否以newmessage显示
@property(nonatomic,assign) NSInteger new_msg;

///是否显示my move
@property(nonatomic,assign) NSInteger my_move;

///是否要显示破冰文案
@property(nonatomic,assign) NSInteger ice_break;

///是否要显示 xx can reply you for free/ you can reply xx for free
@property(nonatomic,assign) NSInteger tip_free;

///是否要显示顶部tool bar 相册
@property(nonatomic,assign) NSInteger top_album;

///我是否把你block了。
@property(nonatomic,assign) NSInteger i_block_u;

- (MSCustomExt *_Nullable)initWithDictionary:(NSDictionary *_Nullable)dic;

- (NSDictionary *_Nonnull)convertToDictionary;


@end


NS_ASSUME_NONNULL_END
