//
//  MMThread.h
//  momo
//
//  Created by houxh on 11-7-1.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

//pthread joinable
@interface MMThread : NSObject {
	id target_;
	id argument_;
	SEL selector_;
	pthread_t pid_;
	BOOL cancelled_;
	BOOL detached_;
	BOOL autoCancel_;
}
@property (nonatomic) pthread_t pid;
@property (nonatomic) BOOL detached;
@property (nonatomic) BOOL autoCancel;

+ (void)detachNewThreadSelector:(SEL)selector toTarget:(id)target withObject:(id)argument cancelOnLogout:(BOOL)autoCancel;

- (id)initWithTarget:(id)target selector:(SEL)selector object:(id)argument;
- (void)start;
- (void)main;
- (void)forceCancel;
- (void)cancel;
- (BOOL)isCancelled;
//must wait
- (void)wait;
+ (MMThread *)currentThread;

@end


