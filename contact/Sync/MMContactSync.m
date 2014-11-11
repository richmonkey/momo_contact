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
#import "MMGlobalDefine.h"

@implementation MMSyncResult

@synthesize 	downloadAddCount, downloadDelCount, downloadUpdateCount, uploadAddCount, 
				uploadDelCount, uploadUpdateCount;


@end

@implementation MMContactSync

@synthesize syncResult = syncResult_;

-(id)init {
	self = [super init];
	if (self) {
		syncResult_	= [[MMSyncResult alloc] init];
	}
	return self;
}
-(void)dealloc {
	[syncResult_ release];
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
