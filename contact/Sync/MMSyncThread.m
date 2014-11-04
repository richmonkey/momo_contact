//
//  MMSyncThread.m
//  momo
//
//  Created by houxh on 11-7-11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "MMSyncThread.h"
#import "MMContactSync.h"
#import "MMGlobalData.h"
#import "MMServerContactManager.h"
#import "DbStruct.h"
#import "MMContact.h"
#import "MMLogger.h"

@interface MMSyncThread()
-(BOOL)sync;
-(void)wakeUpRunLoop:(CFRunLoopRef)runLoop;

-(BOOL)remoteSync;
@end

@implementation MMSyncThread
@synthesize isSyncing = isSyncing_;

-(BOOL)beginSync {
    if (isSyncing_) {
        return NO;
    }
    
    pthread_mutex_lock(&mutex_);
    if (nil == runLoop_) {
        pthread_mutex_unlock(&mutex_);
        return NO;
    }
    CFRunLoopPerformBlock(runLoop_, kCFRunLoopDefaultMode, ^(void){
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:kMMBeginSync object:nil];
        });
        self.isSyncing = YES;
        
        lastSyncResult_ = [self sync];
        if (!lastSyncResult_) {
            MLOG(@"同步失败");
        }
        
        self.isSyncing = NO;
        dispatch_async(dispatch_get_main_queue(), ^{
            NSDictionary* userInfo = [NSDictionary dictionaryWithObject:BOOL_NUMBER(lastSyncResult_) forKey:@"result"];
            [[NSNotificationCenter defaultCenter] postNotificationName:kMMEndSync object:userInfo];
        });
    } );
    [self wakeUpRunLoop:runLoop_];
    pthread_mutex_unlock(&mutex_);
	return YES;
}



void timerCallback(CFRunLoopTimerRef timer, void *info) {
}

-(void)wakeUpRunLoop:(CFRunLoopRef)runLoop {
	//wakeup sync thread!!!!!!!!
	CFRunLoopTimerContext context1 = {0, (void*)NULL, NULL, NULL, NULL};
	CFRunLoopTimerRef timer = CFRunLoopTimerCreate(NULL, 0, 0, 0, 0, (CFRunLoopTimerCallBack)timerCallback, (CFRunLoopTimerContext*)&context1);
	CFRunLoopAddTimer(runLoop, timer, kCFRunLoopDefaultMode);
	CFRelease(timer);
	CFRunLoopWakeUp(runLoop);
}

-(void)cancel {
	[super cancel];
    pthread_mutex_lock(&mutex_);
    while (nil == runLoop_) {
        pthread_cond_wait(&condition_, &mutex_);
    }
    assert(runLoop_);
    CFRunLoopPerformBlock(runLoop_, kCFRunLoopDefaultMode, ^(void){
        //在CFRunloop过程中此函数才有效
        CFRunLoopStop(CFRunLoopGetCurrent());
    } );
    [self wakeUpRunLoop:runLoop_];
    pthread_mutex_unlock(&mutex_);
}

-(void) onUserLogout:(NSNotification*)notification {
    [self cancel];
    [self wait];
    
    //注销后清空联系人数据
    MMContactSync *syncer = [[[MMContactSync alloc] init] autorelease];
    [syncer clearSyncDb];
    [[MMContactManager instance] clearContactDB];
}


+ (MMSyncThread*)shareInstance {
	static MMSyncThread* instance = nil;
	if(!instance) {
		@synchronized(self) {
			if(!instance) {
				instance = [[[MMSyncThread alloc] init] autorelease];
			}
		}
	}
	return instance;
}

-(id)init {
	self = [super initWithTarget:nil selector:nil object:nil];
	if (self) {
        int result = pthread_mutex_init(&mutex_, 0);
        assert(0 == result);
        result = pthread_cond_init(&condition_, 0);
        assert(0 == result);
	}
	return self;
}

-(void)dealloc {
    pthread_mutex_destroy(&mutex_);
    pthread_cond_destroy(&condition_);
	[super dealloc];
}

-(void)onContactChangedInSyncThread:(NSNotification*)notification {
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:kMMBeginSync object:[NSNumber numberWithBool:NO]]; //MQ下发变更不显示同步进度
    });
    
    if (!lastSyncResult_) {
        lastSyncResult_ = [self sync];
    }
    
    NSDictionary* userInfo = [NSDictionary dictionaryWithObjectsAndKeys:BOOL_NUMBER(lastSyncResult_),@"result", 
                              BOOL_NUMBER(NO), @"hide_hud", nil];
    
    if (!lastSyncResult_) {
        MLOG(@"ignore server change");
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:kMMEndSync object:userInfo];
        });
        return;
    }
    
	MMContactSync *syncer = [[[MMContactSync alloc] init] autorelease];
	NSArray *array = (NSArray*)(notification.object);
	NSMutableArray *simpleList = [NSMutableArray array];
	for (NSDictionary *dic in array) {
		NSString *type = [dic objectForKey:@"type"];
		if ([type isEqualToString:@"delete"]) {
			int contactId = [[dic objectForKey:@"id"] intValue];
			[[MMContactManager instance] deleteContact:contactId];
			[syncer deleteContactDown:contactId];
		} else {
			MMMomoContactSimple *c = [[[MMMomoContactSimple alloc] init] autorelease];
			c.contactId = [[dic objectForKey:@"id"] intValue];
			c.modifyDate = [[dic objectForKey:@"modified_at"] longLongValue];
			[simpleList addObject:c];
		}
	}
	if ([syncer downloadContactToMomo:simpleList]) {
		[syncer downloadContact:simpleList ];
	}
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:kMMEndSync object:userInfo];
    });
}

-(void)onContactChanged:(NSNotification*)notification {
    if (isSyncing_) {
        return;
    }
    
    pthread_mutex_lock(&mutex_);
    if (nil == runLoop_) {
        pthread_mutex_unlock(&mutex_);
        return;
    }
    CFRunLoopPerformBlock(runLoop_, kCFRunLoopDefaultMode, ^(void){
        //等待主线程将修改信息入库
        [self performSelector:@selector(onContactChangedInSyncThread:) withObject:notification afterDelay:2];
    } );
    [self wakeUpRunLoop:runLoop_];
    pthread_mutex_unlock(&mutex_);
}


-(BOOL)remoteSync {
    MMSyncHistoryInfo *history = [[[MMSyncHistoryInfo alloc]init] autorelease];
	
	history.beginTime = [[NSDate date] timeIntervalSince1970];
	history.syncType  = 0;	
    
	MMContactSync *syncer = [[[MMContactSync alloc] init] autorelease];
    syncer.syncProgress = [[[MMSyncProgressInfo alloc] init] autorelease];
    syncer.syncProgress.stageCount = 3;
    syncer.syncProgress.stageTitle = @"同步联系人中...";
    
    syncer.syncProgress.currentStageIndex = 1;
    BEGIN_TICKET(uploadcontact);
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    if (![syncer uploadContact]){
        [pool release];
        return NO;
    }
    [pool release];
    END_TICKET(uploadcontact);

	if (self.isCancelled) {
		return NO;
	}
    
    syncer.syncProgress.currentStageIndex = 2;
    BEGIN_TICKET(downcontacttomomo);
    pool = [[NSAutoreleasePool alloc] init];
	if (![syncer downloadContactToMomo]) {
        [pool release];
		return NO;
	}
    [pool release];
    END_TICKET(downcontacttomomo);
	
    if (syncer.isCancelled) {
        return NO;
    }
    
    syncer.syncProgress.currentStageIndex = 3;
    BEGIN_TICKET(downcontact);
    pool = [[NSAutoreleasePool alloc] init];
    if (![syncer downloadContact]) {
        [pool release];
        return NO;
    }
    [pool release];
    END_TICKET(downcontact);


    history.endTime = [[NSDate date] timeIntervalSince1970];
    history.errorcode = 0;
    
	MMSyncResult *result = [syncer syncResult];
    history.detailInfo = [NSString stringWithFormat: @"%d,%d,%d,%d,%d,%d,%d,%d", 
                          result.downloadAddCount + result.downloadUpdateCount + result.downloadDelCount,
                          result.downloadAddCount, result.downloadDelCount, result.downloadUpdateCount, 
                          result.uploadAddCount + result.uploadUpdateCount + result.uploadDelCount,
                          result.uploadAddCount,  result.uploadDelCount, result.uploadUpdateCount];
    
	MLOG(@"downadd:%d, downup:%d, downdel:%d, uploadadd:%d, "
         @"uploadup:%d, uploaddel:%d, mmadd:%d, mmup:%d, mmdel:%d",
         result.downloadAddCount, result.downloadUpdateCount, result.downloadDelCount,
         result.uploadAddCount, result.uploadUpdateCount, result.uploadDelCount,
         result.momoDownloadAddCount, result.momoDownloadUpdateCount, result.momoDownloadDelCount);
	return YES;
}

-(BOOL)sync {
    [[MMContactManager instance] clearAddressBookContact];
    return [self remoteSync];
}


- (void)main {
    pthread_mutex_lock(&mutex_);
	runLoop_ = CFRunLoopGetCurrent();
    pthread_cond_signal(&condition_);
    pthread_mutex_unlock(&mutex_);
    {

        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:kMMBeginSync object:nil];
        });
        self.isSyncing = YES;
        
        lastSyncResult_ = [self sync];
        if (!lastSyncResult_)
            MLOG(@"同步失败");
        
        self.isSyncing = NO;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            NSDictionary* userInfo = [NSDictionary dictionaryWithObject:BOOL_NUMBER(lastSyncResult_) forKey:@"result"];
            [[NSNotificationCenter defaultCenter] postNotificationName:kMMEndSync object:userInfo];
        });
        
        [pool release];

	}

	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

    NSNotificationCenter * center = [NSNotificationCenter defaultCenter];
	
    [center addObserver:self selector:@selector(onContactChanged:) name:kMMMQContactChangedMsg object:nil];
    
	CFRunLoopSourceContext context = {0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL};
	CFRunLoopSourceRef source = CFRunLoopSourceCreate(kCFAllocatorDefault, 0, &context);
	CFRunLoopAddSource(CFRunLoopGetCurrent(), source, kCFRunLoopDefaultMode);

    CFRunLoopRun();
    
	// Should never be called, but anyway
	CFRunLoopRemoveSource(CFRunLoopGetCurrent(), source, kCFRunLoopDefaultMode);
	CFRelease(source);
	
    [center removeObserver:self name:kMMMQContactChangedMsg object:nil];
    
	[pool release];
    
	pthread_mutex_lock(&mutex_);
    runLoop_ = nil;
	pthread_mutex_unlock(&mutex_);
}

@end
