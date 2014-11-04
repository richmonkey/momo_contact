//
//  MMHttpDownloadMgr.m
//  momo
//
//  Created by jackie on 11-5-5.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "MMHttpDownloadMgr.h"
#import "DefineEnum.h"
#import "MMGlobalData.h"
#import "MMUapRequest.h"

@implementation MMDownloadInfo
@synthesize url, delegateSet, request;

- (id)init {
	if (self = [super init]) {
		self.delegateSet = [NSMutableSet set];
	}
	return self;
}

- (void)dealloc {
	[url release];
	[request release];
	[delegateSet release];
	[super dealloc];
}

@end

static MMHttpDownloadMgr* instance = nil;
@implementation MMHttpDownloadMgr
@synthesize downloadQueue, urlAndDownloadInfo, cachePath, downloadCache;

+ (MMHttpDownloadMgr*)shareInstance {
	if (!instance) {
		instance = [[MMHttpDownloadMgr alloc] init];
	}
	return instance;
}

- (id)init {
	if (self = [super init]) {
		self.downloadQueue = [ASINetworkQueue queue];
		[downloadQueue setShouldCancelAllRequestsOnFailure:NO];
		[downloadQueue go];
		
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onAppLaunched) name:UIApplicationDidFinishLaunchingNotification object:nil];
        
		self.cachePath = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0] 
					 stringByAppendingPathComponent:@"MomoCache"];
		downloadCache = [[ASIDownloadCache alloc] init];
		[downloadCache setStoragePath:cachePath];
		
		self.urlAndDownloadInfo = [NSMutableDictionary dictionary];
	}
	return self;
}

- (void)clearCacheThread {
    NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
    
    NSFileManager* fileManager = [NSFileManager defaultManager];
    NSDirectoryEnumerator* dirEnum = [fileManager enumeratorAtPath:cachePath];
    NSString *file;
    
    NSDate* currentData = [NSDate date];
    NSTimeInterval timeIntervalToDel = 30 * 24 * 3600; //删除30天前下载的缓存
    NSMutableArray* filesToDel = [NSMutableArray array];
    
    while (file = [dirEnum nextObject]) {
        NSDictionary* fileAttribute = [dirEnum fileAttributes];
        if (fileAttribute && [[fileAttribute objectForKey:NSFileType] isEqualToString:NSFileTypeRegular]) {
            NSDate* lastModifyData = [fileAttribute objectForKey:NSFileModificationDate];
            
            if ([currentData timeIntervalSinceDate:lastModifyData] > timeIntervalToDel) {
                [filesToDel addObject:file];
            }
        }
    }
    
    for (NSString* file in filesToDel) {
        NSString* filePath = [cachePath stringByAppendingPathComponent:file];
        [fileManager removeItemAtPath:filePath error:nil];
    }
    
    [pool release];
}

//程序启动后进行缓存清理
- (void)onAppLaunched {
    //程序启动一段时间后清理缓存
    [NSTimer scheduledTimerWithTimeInterval:3.0f target:self selector:@selector(clearCacheThread) userInfo:nil repeats:NO];
}

- (void)downloadIfServerUpdated:(NSString*)url delegate:(id<MMHttpDownloadDelegate>)delegate {
	[self downloadWithCachePolicy:url 
						 delegate:delegate 
					  cachePolicy:ASIAskServerIfModifiedCachePolicy
			   cacheStoragePolicy:ASICachePermanentlyCacheStoragePolicy];
}

- (void)downloadFirstUsingCache:(NSString*)url delegate:(id<MMHttpDownloadDelegate>)delegate {
	[self downloadWithCachePolicy:url 
						 delegate:delegate 
					  cachePolicy:ASIOnlyLoadIfNotCachedCachePolicy
			   cacheStoragePolicy:ASICachePermanentlyCacheStoragePolicy];
}

- (void)downloadWithCachePolicy:(NSString*)url 
					   delegate:(id<MMHttpDownloadDelegate>)delegate 
					cachePolicy:(ASICachePolicy)cachePolicy 
			 cacheStoragePolicy:(ASICacheStoragePolicy)cacheStoragePolicy {
    if (url.length == 0) {
        return;
    }
    
	@synchronized(self) {
		MMDownloadInfo* downloadInfo = [urlAndDownloadInfo objectForKey:url];
		if (downloadInfo) {
			[downloadInfo.delegateSet addObject:delegate];
			return;
		}
	}
	
	ASIHTTPRequest* request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:url]];
	request.timeOutSeconds = HTTP_REQUEST_TIME_OUT_SECONDS;
	request.delegate = self;
	request.downloadCache = downloadCache;
	request.cachePolicy = cachePolicy;
	request.cacheStoragePolicy = cacheStoragePolicy;
    request.temporaryUncompressedDataDownloadPath = [NSHomeDirectory() stringByAppendingString:@"/tmp/tmp_download"];
    request.allowResumeForFileDownloads = YES;
	[request setDownloadDestinationPath:[downloadCache pathToStoreCachedResponseDataForRequest:request]];
	
	MMDownloadInfo* downloadInfo = [[[MMDownloadInfo alloc] init] autorelease];
	downloadInfo.url = url;
	if (delegate) {
		[downloadInfo.delegateSet addObject:delegate];
	}
	
	downloadInfo.request = request;
	[urlAndDownloadInfo setObject:downloadInfo forKey:url];
	
	[self.downloadQueue addOperation:request];
}

- (NSString*)cachePathForUrl:(NSString*)url {
    ASIHTTPRequest* request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:url]];
	request.cacheStoragePolicy = ASICachePermanentlyCacheStoragePolicy;
	return [downloadCache pathToStoreCachedResponseDataForRequest:request];
}

- (BOOL)fileExistInCache:(NSString*)url {
	ASIHTTPRequest* request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:url]];
	request.cacheStoragePolicy = ASICachePermanentlyCacheStoragePolicy;
	NSString* path = [downloadCache pathToStoreCachedResponseDataForRequest:request];
	return [[NSFileManager defaultManager] fileExistsAtPath:path];
}

- (NSData*)dataFromCache:(NSString*)url {
	ASIHTTPRequest* request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:url]];
	request.cacheStoragePolicy = ASICachePermanentlyCacheStoragePolicy;
	NSString* path = [downloadCache pathToStoreCachedResponseDataForRequest:request];
	NSData* data = [NSData dataWithContentsOfFile:path];
	if (data) {
		return data;
	}
	
	request.cacheStoragePolicy = ASICacheForSessionDurationCacheStoragePolicy;
	path = [downloadCache pathToStoreCachedResponseDataForRequest:request];
	return [NSData dataWithContentsOfFile:path];
}

- (void)removeDelegateAndNotStopDownload:(id)delegate {
	@synchronized(self) {
		NSArray* allKeys = [urlAndDownloadInfo allKeys];
		for (int i = allKeys.count - 1; i >= 0; i--) {
			NSString* key = [allKeys objectAtIndex:i];
			MMDownloadInfo* downloadInfo = [urlAndDownloadInfo valueForKey:key];
			if ([downloadInfo.delegateSet containsObject:delegate]) {
				[downloadInfo.delegateSet removeObject:delegate];
			}
		}
	}
}

- (void)stopDownloadByUrl:(NSString*)url {
	@synchronized(self) {
		MMDownloadInfo* downloadInfo = [urlAndDownloadInfo objectForKey:url];
		if (!downloadInfo || !downloadInfo.request) {
			return;
		}
		
		if (![downloadInfo.request isFinished]) {
			[downloadInfo.request clearDelegatesAndCancel];
		}
		
		[urlAndDownloadInfo removeObjectForKey:url];
	}
}

- (void)stopDownloadByDelegate:(id<MMHttpDownloadDelegate>)delegate {
	@synchronized(self) {
		NSArray* allKeys = [urlAndDownloadInfo allKeys];
		for (int i = allKeys.count - 1; i >= 0; i--) {
			NSString* key = [allKeys objectAtIndex:i];
			MMDownloadInfo* downloadInfo = [urlAndDownloadInfo valueForKey:key];
			if ([downloadInfo.delegateSet containsObject:delegate]) {
				[downloadInfo.delegateSet removeObject:delegate];
				
				if (downloadInfo.delegateSet.count == 0) {
					if (downloadInfo.request && ![downloadInfo.request isFinished]) {
						[downloadInfo.request clearDelegatesAndCancel];
					}
					[urlAndDownloadInfo removeObjectForKey:key];
				}
				break;
			}
		}
	}
}

- (void)removeAllCache {
	[[NSFileManager defaultManager] removeItemAtPath:cachePath error:nil];
}

- (void)removeCacheForUrl:(NSString*)url {
	ASIHTTPRequest* request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:url]];
	[downloadCache removeCachedDataForRequest:request];
}

- (void)dealloc {
	[downloadQueue release];
	[urlAndDownloadInfo release];
	[cachePath release];
	[downloadCache release];
	[super dealloc];
}

#pragma mark ASIHTTPRequestDelegate
- (void)requestFinished:(ASIHTTPRequest *)request {
	@synchronized(self) {
		NSString* url = [[request originalURL] absoluteString];
		MMDownloadInfo* downloadInfo = [urlAndDownloadInfo objectForKey:url];
		if (!downloadInfo) {
			return;
		}
		
		NSArray* delegates = [downloadInfo.delegateSet allObjects];
		for (id<MMHttpDownloadDelegate> delegate in delegates) {
			if (delegate && [delegate respondsToSelector:@selector(downloadDidSuccess:)]) {
				[delegate performSelector:@selector(downloadDidSuccess:) withObject:downloadInfo.url];
			}
		}
		
		[urlAndDownloadInfo removeObjectForKey:downloadInfo.url];
	}
}

- (void)requestFailed:(ASIHTTPRequest *)request {
	@synchronized(self) {
		MMDownloadInfo* downloadInfo = [urlAndDownloadInfo objectForKey:[request.url absoluteString]];
		if (!downloadInfo) {
			return;
		}
		
		NSArray* delegates = [downloadInfo.delegateSet allObjects];
		for (id<MMHttpDownloadDelegate> delegate in delegates) {
			if (delegate && [delegate respondsToSelector:@selector(downloadDidFailed:)]) {
				[delegate performSelector:@selector(downloadDidFailed:) withObject:downloadInfo.url];
			}
		}
		
		[urlAndDownloadInfo removeObjectForKey:downloadInfo.url];
	}
}

@end
