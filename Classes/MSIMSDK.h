//
//  MSIMSDK.h
//  MSIMSDK
//
//  Created by benny wang on 2021/6/21.
//

#import <Foundation/Foundation.h>

//! Project version number for MSIMSDK.
FOUNDATION_EXPORT double MSIMSDKVersionNumber;

//! Project version string for MSIMSDK.
FOUNDATION_EXPORT const unsigned char MSIMSDKVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import "PublicHeader.h"

#import "MSProfileProvider.h"
#import "MSConversationProvider.h"
#import "MSCacheProvider.h"


#import "NSString+AES.h"
#import "NSString+Ext.h"
#import "NSDictionary+Ext.h"
#import "NSFileManager+filePath.h"

#import "MSIMManager.h"
#import "MSTCPSocket.h"
#import "MSIMManagerListener.h"
#import "MSIMManager+Message.h"
#import "MSIMManager+Conversation.h"
#import "MSIMManager+Parse.h"
#import "MSIMConversation.h"
#import "MSProfileInfo.h"
#import "MSIMMessageReceipt.h"
#import "MSIMManager+Demo.h"
#import "MSIMConst.h"
#import "IMSDKConfig.h"
#import "MSIMMessage.h"
#import "MSIMTools.h"
#import "MSIMErrorCode.h"
#import "MSUploadMediator.h"

#import "MSDBManager.h"
#import "MSDBBaseStore.h"
#import "MSDBMessageStore.h"
#import "MSDBConversationStore.h"
#import "MSDBFileRecordStore.h"
#import "MSDBProfileStore.h"

#import "MSIMManager+ChatRoom.h"
#import "MSChatRoomManager.h"

#import "MSIMHeader.h"
#import "MSIMKit.h"









