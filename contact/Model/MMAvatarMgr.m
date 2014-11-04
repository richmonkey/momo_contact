//
//  MMAvatarMgr.m
//  momo
//
//  Created by jackie on 11-7-18.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "MMAvatarMgr.h"
#import "DbStruct.h"
#import "oauth.h"
#import "MMGlobalData.h"
#import "UIImage+Resize.h"
#import "RegexKitLite.h"

static MMAvatarMgr* instance = nil;
@implementation MMAvatarMgr
@synthesize urlAndImageCache, urlAndDownloadInfo, cachePath, downloadCache, downloadQueue;;

+ (MMAvatarMgr*)shareInstance {
	if (!instance) {
		@synchronized(self) {
			if(!instance) {
				instance = [[MMAvatarMgr alloc] init];
			}
		}
	}
	return instance;
}

- (id)init {
	if (self = [super init]) {
		urlAndImageCache = [[NSMutableDictionary alloc] init];
		urlAndDownloadInfo = [[NSMutableDictionary alloc] init];
		
		self.downloadQueue = [ASINetworkQueue queue];
		[downloadQueue setShouldCancelAllRequestsOnFailure:NO];
		[downloadQueue go];
		
		self.cachePath = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0] 
						  stringByAppendingPathComponent:@"AvatarCache"];
		downloadCache = [[ASIDownloadCache alloc] init];
		[downloadCache setStoragePath:cachePath];
	}
	return self;
}

- (void)dealloc {
	[urlAndImageCache release];
	[urlAndDownloadInfo release];
	[cachePath release];
	[downloadCache release];
	[downloadQueue release];
	[super dealloc];
}

- (void)clearCache {
	@synchronized(self) {
		[urlAndImageCache removeAllObjects];
	}
}

- (void)reset {
	@synchronized(self) {
        [self.downloadQueue cancelAllOperations];
		[self.downloadQueue waitUntilAllOperationsAreFinished];
		[urlAndImageCache removeAllObjects];
		[urlAndDownloadInfo removeAllObjects];
	}
}

- (NSString*)filePathForURL:(NSString*)url {
	ASIHTTPRequest* request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:url]];
	request.cacheStoragePolicy = ASICachePermanentlyCacheStoragePolicy;
	return [downloadCache pathToStoreCachedResponseDataForRequest:request];
}

- (UIImage*)imageFromURL:(NSString*)avatarImageURL {
	if (!avatarImageURL || avatarImageURL.length == 0) {
		return nil;
	}
	
	UIImage* image = [urlAndImageCache objectForKey:avatarImageURL];
	if (!image) {
		NSData* data = [NSData dataWithContentsOfFile:[self filePathForURL:avatarImageURL]];
		if (data) {
			image = [UIImage imageWithData:data];
		}
		
		if (image) {
			@synchronized(self){
				[urlAndImageCache setObject:image forKey:avatarImageURL];
			}
		}
	}

	return image;
}

- (UIImage*)downImageByURLSync:(NSString*)avatarImageURL {
	ASIHTTPRequest* request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:avatarImageURL]];
	request.timeOutSeconds = HTTP_REQUEST_TIME_OUT_SECONDS;
	request.delegate = self;
	request.downloadCache = downloadCache;
	request.cachePolicy = ASIDoNotReadFromCacheCachePolicy;
	request.cacheStoragePolicy = ASICachePermanentlyCacheStoragePolicy;
	[request setDownloadDestinationPath:[downloadCache pathToStoreCachedResponseDataForRequest:request]];
	
	[request startSynchronous];
	
	UIImage* image = [UIImage imageWithData:[request responseData]];
	if (image) {
		@synchronized(self){
			[urlAndImageCache setObject:image forKey:avatarImageURL];
		}
	}
	
	return image;
}

- (void)downImageByURLAsync:(NSString *)avatarImageURL delegate:(id)delegate {
	MMDownloadInfo* downloadInfo = nil;
	@synchronized(self) {
		downloadInfo = [urlAndDownloadInfo objectForKey:avatarImageURL];
		
		//已经下载中, 直接加入delegate
		if (downloadInfo && delegate && downloadInfo.request && [downloadInfo.request isExecuting]) {
			[downloadInfo.delegateSet addObject:delegate];
			return;
		}
		
		if (!downloadInfo) {
			downloadInfo = [[[MMDownloadInfo alloc] init] autorelease];
			downloadInfo.url = avatarImageURL;
			[urlAndDownloadInfo setObject:downloadInfo forKey:avatarImageURL];
		}
		
		if (delegate) {
			[downloadInfo.delegateSet addObject:delegate];
		}
	}
	
	ASIHTTPRequest* request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:avatarImageURL]];
	request.timeOutSeconds = HTTP_REQUEST_TIME_OUT_SECONDS;
	request.delegate = self;
	request.downloadCache = downloadCache;
	request.cachePolicy = ASIDoNotReadFromCacheCachePolicy;
	request.cacheStoragePolicy = ASICachePermanentlyCacheStoragePolicy;
	[request setDownloadDestinationPath:[downloadCache pathToStoreCachedResponseDataForRequest:request]];
	
	downloadInfo.request = request;
	[self.downloadQueue addOperation:request];
}

- (void)setImage:(NSData*)avatarImageData forURL:(NSString*)avatarImageURL {
	NSString* imagePath = [self filePathForURL:avatarImageURL];
	[avatarImageData writeToFile:imagePath atomically:YES];
	
	//更新cache
	UIImage* image = [urlAndImageCache objectForKey:avatarImageURL];
	if (image) {
		@synchronized(self) {
			[urlAndImageCache setObject:image forKey:avatarImageURL];
		}
		
		[self onImageDownSuccess:avatarImageURL];
	}
}

- (void)addDelegate:(id)target avatarImageURL:(NSString*)avatarImageURL {
	@synchronized(self) {
		MMDownloadInfo* downloadInfo = [urlAndDownloadInfo objectForKey:avatarImageURL];
		if (!downloadInfo) {
			downloadInfo = [[[MMDownloadInfo alloc] init] autorelease];
			downloadInfo.url = avatarImageURL;
			[urlAndDownloadInfo setObject:downloadInfo forKey:avatarImageURL];
		}
		
		if (target) {
			[downloadInfo.delegateSet addObject:target];
		}
	}
}

- (void)removeDelegate:(id)target avatarImageURL:(NSString*)avatarImageURL {
	@synchronized(self) {
		MMDownloadInfo* downloadInfo = [urlAndDownloadInfo objectForKey:avatarImageURL];
		if (!downloadInfo) {
			return;
		}
		
		NSEnumerator* enumerator = [downloadInfo.delegateSet objectEnumerator];
		id<MMHttpDownloadDelegate> delegateObject = nil;
		while (delegateObject = [enumerator nextObject]) {
			if ([delegateObject isEqual:target]) {
				[downloadInfo.delegateSet removeObject:delegateObject];
				break;
			}
		}
		
		if (downloadInfo.delegateSet.count == 0) {
			[urlAndDownloadInfo removeObjectForKey:avatarImageURL];
		}
	}
}

//////////////////////////////////////////////
- (void)onImageDownSuccess:(NSString*)url {
	@synchronized(self) {
		MMDownloadInfo* downloadInfo = [urlAndDownloadInfo objectForKey:url];
		if (!downloadInfo) {
			return;
		}
		
		NSData* imageData = [NSData dataWithContentsOfFile:[self filePathForURL:url]];
		UIImage* image = [UIImage imageWithData:imageData];
		if (!image) {
			return;
		}
        
        NSString* tmpString = [url stringByMatching:@"_\\d+?\\."]; //url中是否有图片大小 "_130.jpg"
        if (!tmpString) {
            //头像的大小最大限制为130, 大于130的请用MMWebImageView
            if (image.size.width > 131) {
                image = [image resizedImage:130];
                imageData = UIImagePNGRepresentation(image);
                NSString* imagePath = [self filePathForURL:url];
                [imageData writeToFile:imagePath atomically:YES];
            }
        }
		
		[urlAndImageCache setObject:image forKey:url];
		
		NSArray* delegates = [downloadInfo.delegateSet allObjects];
		for (id<MMAvatarMgrDelegate> delegate in delegates) {
			if (delegate && [delegate respondsToSelector:@selector(downloadAvatarDidSuccess:image:)]) {
				[delegate downloadAvatarDidSuccess:url image:image];
			}
		}
		[urlAndDownloadInfo removeObjectForKey:url];	//下载完删除
	}
}

- (void)onImageDownFailed:(NSString*)url {
	@synchronized(self) {
		MMDownloadInfo* downloadInfo = [urlAndDownloadInfo objectForKey:url];
		if (!downloadInfo) {
			return;
		}
		
		NSArray* delegates = [downloadInfo.delegateSet allObjects];
		for (id<MMAvatarMgrDelegate> delegate in delegates) {
			if (delegate && [delegate respondsToSelector:@selector(downloadAvatarDidFailed:)]) {
				[delegate downloadAvatarDidFailed:url];
			}
		}
		[urlAndDownloadInfo removeObjectForKey:url];
	}
}

#pragma mark ASIHTTPRequestDelegate
- (void)requestFinished:(ASIHTTPRequest *)request {
	NSString* url = [[request originalURL] absoluteString];
	[self performSelectorOnMainThread:@selector(onImageDownSuccess:) withObject:url waitUntilDone:YES];
}

- (void)requestFailed:(ASIHTTPRequest *)request {
	NSString* url = [[request originalURL] absoluteString];
	[self performSelectorOnMainThread:@selector(onImageDownFailed:) withObject:url waitUntilDone:YES];
}

@end
