//
//  MMAvatarMgr.h
//  momo
//
//  Created by jackie on 11-7-18.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ASIHTTPRequest.h"
#import "ASINetworkQueue.h"
#import "ASIDownloadCache.h"
#import "MMHttpDownloadMgr.h"

@protocol MMAvatarMgrDelegate <NSObject>
@optional
- (void)downloadAvatarDidSuccess:(NSString*)url image:(UIImage*)image;

- (void)downloadAvatarDidFailed:(NSString*)url;

@end

@interface MMAvatarMgr : NSObject {
	NSMutableDictionary* urlAndImageCache;
	NSMutableDictionary* urlAndDownloadInfo;
	
	NSString*			cachePath;
	ASIDownloadCache*	downloadCache;
	ASINetworkQueue*	downloadQueue;
}
@property (nonatomic, retain) NSMutableDictionary* urlAndImageCache;
@property (nonatomic, retain) NSMutableDictionary* urlAndDownloadInfo;
@property (nonatomic, copy) NSString*	cachePath;
@property (nonatomic, retain) ASIDownloadCache*	downloadCache;
@property (nonatomic, retain) ASINetworkQueue*	downloadQueue;

+ (MMAvatarMgr*)shareInstance;

- (void)reset;
- (void)clearCache;

- (UIImage*)imageFromURL:(NSString*)avatarImageURL;	//获取URL对应头像

- (void)downImageByURLAsync:(NSString *)avatarImageURL delegate:(id)delegate;//异步下载头像, 需要调用removeDelegate移除delegate

- (void)setImage:(NSData*)avatarImageData forURL:(NSString*)avatarImageURL;

//
- (void)addDelegate:(id)target avatarImageURL:(NSString*)avatarImageURL;
- (void)removeDelegate:(id)target avatarImageURL:(NSString*)avatarImageURL;

//private
- (void)onImageDownSuccess:(NSString*)url;

@end
