//
//  MSUploadMediator.h
//  BlackFireIM
//
//  Created by benny wang on 2021/5/15.
//

#import <UIKit/UIKit.h>
#import <MSIMSDK/MSIMConst.h>


NS_ASSUME_NONNULL_BEGIN

/** 附件类型*/
typedef NS_ENUM(NSInteger ,MSUploadFileType){
    
    MSUploadFileTypeImage = 0, //图片
    
    MSUploadFileTypeVideo = 1,//视频
    
    MSUploadFileTypeVoice = 2,//音频
    
    MSUploadFileTypeAvatar = 3,//头像
};

typedef void(^normalSucc)(NSString *url);
typedef void(^normalProgress)(CGFloat progress);
typedef void(^normalFail)(NSInteger code, NSString *desc);

@protocol MSUploadMediator <NSObject>

@optional

- (void)ms_uploadWithObject:(id)object
                   fileType:(MSUploadFileType)type
                   progress:(normalProgress)progress
                       succ:(normalSucc)succ
                       fail:(normalFail)fail;



- (void)ms_downloadFromUrl:(NSString *)url
                toSavePath:(NSString *)savePath
                  progress:(normalProgress)progress
                      succ:(normalSucc)succ
                      fail:(normalFail)fail;

@end

NS_ASSUME_NONNULL_END
