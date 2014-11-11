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

-(BOOL)remoteSync {
    MMSyncHistoryInfo *history = [[[MMSyncHistoryInfo alloc]init] autorelease];
	
	history.beginTime = [[NSDate date] timeIntervalSince1970];
	history.syncType  = 0;	
    
	MMContactSync *syncer = [[[MMContactSync alloc] init] autorelease];

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

    BEGIN_TICKET(downcontact);
    pool = [[NSAutoreleasePool alloc] init];
	if (![syncer downloadContact]) {
        [pool release];
		return NO;
	}
    [pool release];
    END_TICKET(downcontact);
	
    if (syncer.isCancelled) {
        return NO;
    }

    history.endTime = [[NSDate date] timeIntervalSince1970];
    history.errorcode = 0;
    
	MMSyncResult *result = [syncer syncResult];
    history.detailInfo = [NSString stringWithFormat: @"%ld,%ld,%ld,%ld,%ld,%ld,%ld,%ld",
                          result.downloadAddCount + result.downloadUpdateCount + result.downloadDelCount,
                          result.downloadAddCount, result.downloadDelCount, result.downloadUpdateCount,
                          result.uploadAddCount + result.uploadUpdateCount + result.uploadDelCount,
                          result.uploadAddCount,  result.uploadDelCount, result.uploadUpdateCount];
    
	MLOG(@"downadd:%ld, downup:%ld, downdel:%ld, uploadadd:%ld, "
         @"uploadup:%ld, uploaddel:%ld",
         (long)result.downloadAddCount, (long)result.downloadUpdateCount, (long)result.downloadDelCount,
         result.uploadAddCount, result.uploadUpdateCount, result.uploadDelCount);
         
	return YES;
}

-(BOOL)sync {
    return [self remoteSync];
}


- (void)main {
    pthread_mutex_lock(&mutex_);
	runLoop_ = CFRunLoopGetCurrent();
    pthread_cond_signal(&condition_);
    pthread_mutex_unlock(&mutex_);


	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

    
	CFRunLoopSourceContext context = {0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL};
	CFRunLoopSourceRef source = CFRunLoopSourceCreate(kCFAllocatorDefault, 0, &context);
	CFRunLoopAddSource(CFRunLoopGetCurrent(), source, kCFRunLoopDefaultMode);

    CFRunLoopRun();
    
	// Should never be called, but anyway
	CFRunLoopRemoveSource(CFRunLoopGetCurrent(), source, kCFRunLoopDefaultMode);
	CFRelease(source);
	
    
	[pool release];
    
	pthread_mutex_lock(&mutex_);
    runLoop_ = nil;
	pthread_mutex_unlock(&mutex_);
}

@end
