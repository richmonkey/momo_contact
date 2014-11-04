//
//  MMSyncThread.h
//  momo
//
//  Created by houxh on 11-7-11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AddressBook/AddressBook.h>
#import "MMUapRequest.h"

#define kMMBeginSync @"BeginSync"
#define kMMEndSync   @"EndSync"

@interface MMSyncThread : MMHttpRequestThread {
    BOOL lastSyncResult_;
    pthread_cond_t condition_;
    pthread_mutex_t mutex_;
	CFRunLoopRef runLoop_;
    
    BOOL isSyncing_;
}
@property (nonatomic) BOOL isSyncing;

+ (MMSyncThread*)shareInstance;
-(BOOL)beginSync;
@end
