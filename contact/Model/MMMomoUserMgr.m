//
//  MMUserMgr.m
//  momo
//
//  Created by jackie on 11-8-4.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "MMMomoUserMgr.h"
#import "MMGlobalData.h"
#import "MMGlobalDefine.h"
#import <pthread.h>

@implementation MMMomoUserMgr

static pthread_mutex_t mutex = PTHREAD_MUTEX_INITIALIZER;

+ (MMMomoUserMgr*)shareInstance {
	static id _instance = nil;
    @synchronized(self) {
        if(_instance == nil) 
            _instance = [[[self class] alloc] init];
    }
    return _instance;
}

- (id)init {
	if (self = [super init]) {
		momoUserDict = [[MMMomoUser instance] getAllUserInfo];
		[momoUserDict retain];
        
        userAvatarObservers = [[NSMutableDictionary alloc] init];
	}
	return self;
}

- (void)dealloc {
	if (momoUserDict) {
		[momoUserDict release];
	}
    MM_RELEASE_SAFELY(userAvatarObservers);
	[super dealloc];
}

- (void)setUserInfo:(MMMomoUserInfo *)userInfo {
    MMMomoUserInfo* oldUserInfo = [[MMMomoUser instance] getUserInfo:userInfo.uid];
    BOOL needUpdate = NO;
    if (!oldUserInfo) {
        needUpdate = YES;
        
        if (userInfo.avatarImageUrl.length > 0) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self notifyAvatarChange:userInfo.uid newAvatarUrl:userInfo.avatarImageUrl];
            });
        }
    } else {
        if (![oldUserInfo.realName isEqualToString:userInfo.realName]) {
            needUpdate = YES;
        } else if (userInfo.avatarImageUrl.length > 0 && 
                   ![oldUserInfo.avatarImageUrl isEqualToString:userInfo.avatarImageUrl]) {
            needUpdate = YES;
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self notifyAvatarChange:userInfo.uid newAvatarUrl:userInfo.avatarImageUrl];
            });
        }
		if ([userInfo.realName length] == 0) {
			needUpdate = NO;
		}
    }
    
    if (needUpdate) {
        //直接更新数据库
        [[MMMomoUser instance] saveUser:userInfo];
        
        pthread_mutex_lock(&mutex);
        [momoUserDict setObject:userInfo forKey:[NSNumber numberWithInt:userInfo.uid]];
        pthread_mutex_unlock(&mutex);      
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:kMMUserInfoChanged object:userInfo];
        });
    }
}

//添加MOMO用户信息
- (void)setUserId:(NSUInteger)uid 
		 realName:(NSString*)realName 
   avatarImageUrl:(NSString*)avatarImageUrl {
	MMMomoUserInfo* userInfo = [[[MMMomoUserInfo alloc] initWithUserId:uid 
													  realName:realName 
												avatarImageUrl:avatarImageUrl] autorelease];
	[self setUserInfo:userInfo];
}

- (MMMomoUserInfo*)userInfoByUserId:(NSUInteger)uid {
    return nil;
}

- (NSString*)realNameByUserId:(NSUInteger)uid {
    if (uid == FEED_BACK_ID) {
        return @"小秘";
    }
    
    return PARSE_NULL_STR([self userInfoByUserId:uid].realName);
}

- (NSString*)avatarImageUrlByUserId:(NSUInteger)uid {
    if (uid == 0) {
        return nil;
    }
    return [self userInfoByUserId:uid].avatarImageUrl;
}

#pragma mark Avatar Change
- (void)notifyAvatarChange:(NSInteger)uid  newAvatarUrl:(NSString*)newAvatarUrl {
    NSAssert([NSThread isMainThread], @"Not Main Thread");
    
    NSMutableSet* observerSet = [userAvatarObservers objectForKey:[NSNumber numberWithInt:uid]];
    NSArray* array = [observerSet allObjects];
    for (id<MMMomoUserDelegate> observer in array) {
        if ([observer respondsToSelector:@selector(userAvatarDidChange:)]) {
            [observer userAvatarDidChange:newAvatarUrl];
        }
    }
}

- (void)addAvatarChangeObserverForUid:(NSInteger)uid observer:(id<MMMomoUserDelegate>)observer {
    NSAssert([NSThread isMainThread], @"Not Main Thread");
    
    NSMutableSet* observerSet = [userAvatarObservers objectForKey:[NSNumber numberWithInt:uid]];
    if (!observerSet) {
        observerSet = [NSMutableSet set];
        [userAvatarObservers setObject:observerSet forKey:[NSNumber numberWithInt:uid]];
    }
    [observerSet addObject:observer];
}

- (void)removeAvatarObserver:(id<MMMomoUserDelegate>)observer {
    NSAssert([NSThread isMainThread], @"Not Main Thread");
    
    NSArray* allKey = [userAvatarObservers allKeys];
    for (NSNumber* key in allKey) {
        NSMutableSet* observerSet = [userAvatarObservers objectForKey:key];
        if ([observerSet containsObject:observer]) {
            [observerSet removeObject:observer];
            break;
        }
    }
}

@end
