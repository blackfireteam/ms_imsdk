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

// In this header, you should import all the public headers of your framework using statements like #import <MSIMSDK/PublicHeader.h>

#import <MSIMSDK/MSProfileProvider.h>
#import <MSIMSDK/MSConversationProvider.h>
#import <MSIMSDK/MSCacheProvider.h>


#import <MSIMSDK/NSString+AES.h>
#import <MSIMSDK/NSString+Ext.h>
#import <MSIMSDK/NSDictionary+Ext.h>
#import <MSIMSDK/NSFileManager+filePath.h>

#import <MSIMSDK/MSIMManager.h>
#import <MSIMSDK/MSTCPSocket.h>
#import <MSIMSDK/MSIMManagerListener.h>
#import <MSIMSDK/MSIMManager+Message.h>
#import <MSIMSDK/MSIMManager+Conversation.h>
#import <MSIMSDK/MSIMManager+Parse.h>
#import <MSIMSDK/MSIMConversation.h>
#import <MSIMSDK/MSProfileInfo.h>
#import <MSIMSDK/MSIMMessageReceipt.h>
#import <MSIMSDK/MSIMManager+Demo.h>
#import <MSIMSDK/MSIMConst.h>
#import <MSIMSDK/IMSDKConfig.h>
#import <MSIMSDK/MSIMMessage.h>
#import <MSIMSDK/MSIMTools.h>
#import <MSIMSDK/MSIMErrorCode.h>
#import <MSIMSDK/MSUploadMediator.h>

#import <MSIMSDK/MSDBManager.h>
#import <MSIMSDK/MSDBBaseStore.h>
#import <MSIMSDK/MSDBMessageStore.h>
#import <MSIMSDK/MSDBConversationStore.h>
#import <MSIMSDK/MSDBFileRecordStore.h>
#import <MSIMSDK/MSDBProfileStore.h>

#import <MSIMSDK/MSIMManager+ChatRoom.h>
#import <MSIMSDK/MSChatRoomManager.h>

#import <MSIMSDK/MSIMHeader.h>
#import <MSIMSDK/MSIMKit.h>









