//
//  MMContactSync.m
//  momo
//
//  Created by houxh on 11-7-5.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "MMContactSync.h"
#import "MMUapRequest.h"
#import "DbStruct.h"
#import <AddressBook/AddressBook.h>
#import "MMAddressBook.h"
#import "SBJSON.h"
#import "MMServerContactManager.h"
#import "MMLogger.h"
#import "MMContact.h"
#import "MMGlobalDefine.h"

@implementation MMSyncResult

@synthesize 	downloadAddCount, downloadDelCount, downloadUpdateCount, uploadAddCount, 
				uploadDelCount, uploadUpdateCount,  momoDownloadAddCount, momoDownloadDelCount, momoDownloadUpdateCount;
@synthesize		momoCardDownloadCount;

@end

@implementation MMContactSync

@synthesize syncResult = syncResult_;
@synthesize syncProgress = syncProgress_;

-(id)init {
	self = [super init];
	if (self) {
		syncResult_	= [[MMSyncResult alloc] init];
	}
	return self;
}
-(void)dealloc {
	[syncResult_ release];
	[categoryCache_ release];
    self.syncProgress = nil;
	[super dealloc];
}

-(BOOL) isCancelled {
	MMThread *thread = [MMThread currentThread];
	MMHttpRequestThread *requestThread = nil;
	
	if ([thread isKindOfClass:[MMHttpRequestThread class]]) {
		requestThread = (MMHttpRequestThread*)thread;
	}

	return requestThread.isCancelled;
}



-(BOOL) clearSyncDb {
	if (![[self db]  executeUpdate:@"delete from category_member_sync"]) {
		MLOG(@"delete from about fail");            
		return NO;
	} 
	
	if (![[self db]  executeUpdate:@"delete from category_sync"]) {
		MLOG(@"delete from about fail"); 
		return NO;
	} 
	
	if (![[self db]  executeUpdate:@"delete from contact_sync"]) {
		MLOG(@"delete from feed fail"); 
		return NO;
	} 

	return YES;
}
@end

@implementation MMSyncProgressInfo
@synthesize stageTitle = stageTitle_;
@synthesize stageCount = stageCount_;
@synthesize currentStageIndex = currentStageIndex_;
@synthesize stageOperationCount = stageOperationCount_;
@synthesize stageOperationIndex = stageOperationIndex_;
@synthesize currentProgress = currentProgress_;

- (id)init {
    self = [super init];
    if (self) {
        stageCount_ = 1;
        currentStageIndex_ = 0;
    }
    return self;
}

- (void)dealloc {
    self.stageTitle = nil;
    [super dealloc];
}

- (void)notifyProgressIfNeed {
    if (infoChanged_) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kMMSyncProgress object:self];
    }
}

- (void)setStageTitle:(NSString *)stageTitle {
    infoChanged_ = YES;
    
    MM_RELEASE_SAFELY(stageTitle_);
    stageTitle_ = [stageTitle copy];
}

- (void)setCurrentStageIndex:(NSInteger)currentStageIndex {
    currentStageIndex_ = currentStageIndex;
    
    stageOperationCount_ = 1;
    stageOperationIndex_ = 0;
}

- (void)setStageOperationIndex:(NSInteger)stageOperationIndex {
    stageOperationIndex_ = stageOperationIndex;
    
    if (stageOperationCount_ == 0) {
        currentProgress_ = 0;
        return;
    }
    
    float tmpProgress = (float)stageOperationIndex_ / (float)stageOperationCount_;
    if (tmpProgress - currentProgress_ > 0.01f) {
        infoChanged_ = YES;
        currentProgress_ = tmpProgress;
    }
    
    if (currentProgress_ > 1) {
        currentProgress_ = 1;
    }
    
    [self notifyProgressIfNeed];
}

- (void)setStageOperationCount:(NSInteger)stageOperationCount {
    stageOperationCount_ = stageOperationCount;
    stageOperationIndex_ = 0;
    
    currentProgress_ = 0;
    infoChanged_ = YES;
    [self notifyProgressIfNeed];
}

@end
