//
//  MMMomoUserMgr.h
//  momo
//
//  Created by jackie on 11-8-4.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MMMomoUser.h"
#import <pthread.h>

#define kMMUserInfoChanged		@"UserInfoChanged"	//用户头像或名字变更了

@protocol MMMomoUserDelegate <NSObject>

- (void)userAvatarDidChange:(NSString*)avatarURL;

@end

@interface MMMomoUserMgr : NSObject {
	NSMutableDictionary* momoUserDict;
    
    NSMutableDictionary* userAvatarObservers;
}

+ (MMMomoUserMgr*)shareInstance;

- (void)setUserInfo:(MMMomoUserInfo*)userInfo;

//添加MOMO用户信息
- (void)setUserId:(NSUInteger)uid 
		 realName:(NSString*)realName 
   avatarImageUrl:(NSString*)avatarImageUrl;


//获取接口必须在主线程调用
- (MMMomoUserInfo*)userInfoByUserId:(NSUInteger)uid;

- (NSString*)realNameByUserId:(NSUInteger)uid;

- (NSString*)avatarImageUrlByUserId:(NSUInteger)uid;

//头像变更 刷新
- (void)notifyAvatarChange:(NSInteger)uid newAvatarUrl:(NSString*)newAvatarUrl;

- (void)addAvatarChangeObserverForUid:(NSInteger)uid observer:(id<MMMomoUserDelegate>)observer;
- (void)removeAvatarObserver:(id<MMMomoUserDelegate>)observer;

@end
