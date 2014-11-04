//
//  MMCardManager.h
//  momo
//
//  Created by  on 12-5-25.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DbStruct.h"
#import "MMModel.h"

@interface MMCardManager : MMModel {
	NSMutableDictionary *numberUidCacheDic;
}

+(id)instance;

//for momo_card
- (BOOL)saveCard:(MMCard *)card;
- (BOOL)deleteCard:(NSInteger)uid;
- (MMCard *)getCardByUid:(NSInteger)uid;

//对外用
- (MMCard *)getCardByNumber:(NSString *)number;
- (BOOL)insertUserCard:(MMCard *)card withNumber:(NSString *)number;

- (void)deleteCardByUid:(NSInteger)uid;
- (void)deleteCardByNumber:(NSString *)number;


//for number_uid
- (BOOL)insertNumber:(NSString *)number withUid:(NSInteger)uid;

- (NSInteger)getUidByNumber:(NSString *)number;
- (NSString*)numberByUID:(NSInteger)uid;

//Http Related
+ (MMCard *)getUserCardByTel:(NSString *)mobile andName:(NSString *)name;
+ (MMCard *)getUserCard:(NSUInteger)uid; 
+ (BOOL)updateUserCard:(MMCard *)fullContact withErrorString:(NSString**)errorString;

+ (NSDictionary*)encodeCard:(MMCard *)card;
+ (MMCard *)decodeCard:(NSDictionary*)dic;

+ (BOOL)isInvalidNumber:(NSString*)number; //UID为-1则为非法号码
+ (BOOL)isRegisterNumber:(NSString*)number;

- (void)downloadCards:(NSArray*)numbers; 
- (void)refreshNeedDownloadCards:(NSArray*)numbers; //下载所有需要更新或下载名片

@end

