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
	ABAddressBookRef addressBook_;
	int syncMode_;
    BOOL lastSyncResult_;
    pthread_cond_t condition_;
    pthread_mutex_t mutex_;
	CFRunLoopRef runLoop_;
    
    BOOL isSyncing_;
    
    BOOL responseToAddressBookChange_; //是否响应本机联系人变更通知,  往本地写入头像等情况时使用
}
@property (nonatomic) BOOL isSyncing;
@property (nonatomic) BOOL responseToAddressBookChange;

+ (MMSyncThread*)shareInstance;
-(BOOL)beginSync;
@end
