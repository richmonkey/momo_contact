//
//  MMHttpDownloadMgr.h
//  momo
//
//  Created by jackie on 11-5-5.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ASIHTTPRequest.h"
#import "ASINetworkQueue.h"
#import "ASIDownloadCache.h"

@protocol MMHttpDownloadDelegate <NSObject>

- (void)downloadDidSuccess:(NSString*)url;

- (void)downloadDidFailed:(NSString*)url;

@end

@interface MMDownloadInfo : NSObject
{
	NSString*			url;
	NSMutableSet* delegateSet;
	ASIHTTPRequest*		request;
}
@property (nonatomic, retain) NSString* url;
@property (nonatomic, retain) NSMutableSet* delegateSet;
@property (nonatomic, retain) ASIHTTPRequest*		request;

@end


@interface MMHttpDownloadMgr : NSObject <ASIHTTPRequestDelegate>{
	ASINetworkQueue*	downloadQueue;
	NSMutableDictionary* urlAndDownloadInfo;
	
	NSString*			cachePath;
	ASIDownloadCache*	downloadCache;
}
@property (nonatomic, retain) ASINetworkQueue*	downloadQueue;
@property (nonatomic, retain) NSMutableDictionary* urlAndDownloadInfo;
@property (nonatomic, copy) NSString*			cachePath;
@property (nonatomic, retain) ASIDownloadCache*	downloadCache;

+ (MMHttpDownloadMgr*)shareInstance;

- (void)downloadIfServerUpdated:(NSString*)url delegate:(id<MMHttpDownloadDelegate>)delegate;

- (void)downloadFirstUsingCache:(NSString*)url delegate:(id<MMHttpDownloadDelegate>)delegate;

- (void)downloadWithCachePolicy:(NSString*)url 
					   delegate:(id<MMHttpDownloadDelegate>)delegate 
					cachePolicy:(ASICachePolicy)cachePolicy 
			 cacheStoragePolicy:(ASICacheStoragePolicy)cacheStoragePolicy;

- (NSString*)cachePathForUrl:(NSString*)url;
    
- (BOOL)fileExistInCache:(NSString*)url;

- (NSData*)dataFromCache:(NSString*)url;

- (void)removeAllCache;
- (void)removeCacheForUrl:(NSString*)url;

- (void)removeDelegateAndNotStopDownload:(id)delegate;

- (void)stopDownloadByUrl:(NSString*)url;

- (void)stopDownloadByDelegate:(id<MMHttpDownloadDelegate>)delegate;

@end
