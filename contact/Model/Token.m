//
//  Token.m
//  Message
//
//  Created by houxh on 14-7-8.
//  Copyright (c) 2014年 daozhu. All rights reserved.
//

#import "Token.h"
#import "MMGlobalData.h"
#import "TAHttpOperation.h"
#import "APIRequest.h"

@interface Token()
@property(nonatomic)dispatch_source_t refreshTimer;
@property(nonatomic)int refreshFailCount;
@end

@implementation Token

+(Token*)instance {
    static Token *tok;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (!tok) {
            tok = [[Token alloc] init];
            [tok load];
        }
    });
    return tok;
}

-(id)init {
    self = [super init];
    if (self) {

    }
    return self;
}

-(void)load {
    self.accessToken = [MMGlobalData getPreferenceforKey:@"access_token"];
    self.refreshToken = [MMGlobalData getPreferenceforKey:@"refresh_token"];
    self.phoneNumber = [MMGlobalData getPreferenceforKey:@"phone_number"];
    self.expireTimestamp = [[MMGlobalData getPreferenceforKey:@"token_expire"] intValue];
    self.uid = [[MMGlobalData getPreferenceforKey:@"token_uid"] longLongValue];
}

-(void)save {
    [MMGlobalData setPreference:self.accessToken forKey:@"access_token"];
    [MMGlobalData setPreference:self.refreshToken forKey:@"refresh_token"];
    [MMGlobalData setPreference:self.phoneNumber forKey:@"phone_number"];
    [MMGlobalData setPreference:[NSNumber numberWithInt:self.expireTimestamp] forKey:@"token_expire"];
    [MMGlobalData setPreference:[NSNumber numberWithLongLong:self.uid] forKey:@"token_uid"];
    [MMGlobalData savePreference];
}

@end
