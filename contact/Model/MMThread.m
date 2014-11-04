//
//  MMThread.m
//  momo
//
//  Created by houxh on 11-7-1.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "MMThread.h"
#import <pthread.h>
#import "MMLogger.h"
//#import "MMLoginService.h"

static pthread_key_t threadKey = 0;

static void*  thread_main(void* arg) {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	MMThread *thread = (MMThread*)arg;
	pthread_setspecific(threadKey, (void*)thread);
	[thread main];
	if (thread.detached) {
		dispatch_async(dispatch_get_main_queue(), ^{
			[thread wait];
		});
	}
	[thread release];
    [pool release];
	return 0;
}

@implementation MMThread
@synthesize pid=pid_;
@synthesize detached = detached_;
@synthesize autoCancel = autoCancel_;

-(void)setAutoCancel:(BOOL)autoCancel {
	if (autoCancel == autoCancel_) {
		return;
	}
	autoCancel_ = autoCancel;
	if (autoCancel_) {
		NSNotificationCenter * center = [NSNotificationCenter defaultCenter];
//		[center addObserver:self selector:@selector(onUserLogout:) name:kMMUserLogout object:nil];
	} else {
		NSNotificationCenter * center = [NSNotificationCenter defaultCenter];
//		[center removeObserver:self name:kMMUserLogout object:nil];
	}
}

+ (void)initialize {
	if (self == [MMThread class]) {
		pthread_key_create(&threadKey, 0);
	}
}
- (id)initWithTarget:(id)target selector:(SEL)selector object:(id)argument {
	self = [super init];
	if (self) {
		target_ = target;
		argument_ = argument;
		selector_ = selector;
		detached_ = NO;
	}
	return self;
}

-(void)dealloc {
	assert(0 == pid_);
	//remove ob
	self.autoCancel = NO;
	[super dealloc];
}

- (void)start {
	assert([NSThread isMultiThreaded]);
	assert(0 == pid_);
	[target_ retain];
	[argument_ retain];
	[self retain];
	int result = pthread_create(&pid_, 0, thread_main, self);
	assert(0 == result);
	if (result != 0) {
		[target_ release];
		[argument_ release];
		[self release];
	}
}

- (void)main {
	[target_ performSelector:selector_ withObject:argument_];
	[target_ release];
	[argument_ release];
}

-(void)wait {
	if (0 == pid_) {
		return;
	}
	void* exit_code = 0;
	pthread_join(pid_, &exit_code);
	pid_ = 0;
    
    if (![self isCancelled]) {
        return;
    }
    assert([NSThread isMainThread]);
    //清空残存在主消息队列里的消息    
    CFRunLoopPerformBlock(CFRunLoopGetCurrent(), kCFRunLoopDefaultMode, ^(void){
        CFRunLoopStop(CFRunLoopGetCurrent());
    });
    CFRunLoopRun();
}

- (void)forceCancel {
    if (pid_) 
        pthread_cancel(pid_);
}

-(void)cancel {
	cancelled_ = YES;
}

- (BOOL)isCancelled {
	return cancelled_;
}

-(void)onUserLogout:(NSNotification*)notification {
	[self cancel];
	[self wait];
}

+ (MMThread *)currentThread{
	return (MMThread*)pthread_getspecific(threadKey);
}

+ (void)detachNewThreadSelector:(SEL)selector toTarget:(id)target withObject:(id)argument cancelOnLogout:(BOOL)autoCancel {
	MMThread *thread = [[[[self class] alloc] initWithTarget:target selector:selector object:argument] autorelease];
	thread.detached = YES;
	thread.autoCancel = autoCancel;
	[thread start];
}

@end
