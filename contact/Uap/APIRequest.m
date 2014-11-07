//
//  APIRequest.m
//  Message
//
//  Created by houxh on 14-7-26.
//  Copyright (c) 2014年 daozhu. All rights reserved.
//

#import "APIRequest.h"
#import "Config.h"

@implementation APIRequest
+(TAHttpOperation*)requestVerifyCode:(NSString*)zone number:(NSString*)number
                              success:(void (^)(NSString* code))success fail:(void (^)())fail{
    TAHttpOperation *request = [TAHttpOperation httpOperationWithTimeoutInterval:60];
    request.targetURL = [[Config instance].URL stringByAppendingFormat:@"/verify_code?zone=%@&number=%@", zone, number];
    request.method = @"POST";
    request.successCB = ^(TAHttpOperation*commObj, NSURLResponse *response, NSData *data) {
        NSInteger statusCode = [(NSHTTPURLResponse*)response statusCode];
        if (statusCode != 200) {
            fail();
            return;
        }
        NSDictionary *resp = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:nil];
        NSString *code = [resp objectForKey:@"code"];
        success(code);
    };
    request.failCB = ^(TAHttpOperation*commObj, TAHttpOperationError error) {
        fail();
    };
    [[NSOperationQueue mainQueue] addOperation:request];
    return request;
}


+(TAHttpOperation*)requestAuthToken:(NSString*)code zone:(NSString*)zone number:(NSString*)number deviceToken:(NSString*)deviceToken
                            success:(void (^)(int64_t uid, NSString* accessToken, NSString *refreshToken, int expireTimestamp, NSString *state))success
                               fail:(void (^)())fail {
    TAHttpOperation *request = [TAHttpOperation httpOperationWithTimeoutInterval:60];
    request.targetURL = [[Config instance].URL stringByAppendingString:@"/auth/token"];
    
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    [dict setObject:code forKey:@"code"];
    [dict setObject:zone forKey:@"zone"];
    [dict setObject:number forKey:@"number"];
    if (deviceToken) {
        [dict setObject:deviceToken forKey:@"apns_device_token"];
    }

    NSDictionary *headers = [NSDictionary dictionaryWithObject:@"application/json" forKey:@"Content-Type"];
    request.headers = headers;
    NSData *data = [NSJSONSerialization dataWithJSONObject:dict options:0 error:nil];
    request.postBody = data;
    request.method = @"POST";
    request.successCB = ^(TAHttpOperation*commObj, NSURLResponse *response, NSData *data) {
        NSInteger statusCode = [(NSHTTPURLResponse*)response statusCode];
        if (statusCode != 200) {
            fail();
            return;
        }
        NSDictionary *resp = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:nil];
     
        NSString *accessToken = [resp objectForKey:@"access_token"];
        NSString *refreshToken = [resp objectForKey:@"refresh_token"];
        int expireTimestamp = time(NULL) + [[resp objectForKey:@"expires_in"] intValue];
        int64_t uid = [[resp objectForKey:@"uid"] longLongValue];
        NSString *state = [resp objectForKey:@"state"];
        success(uid, accessToken, refreshToken, expireTimestamp, state);
    };
    request.failCB = ^(TAHttpOperation*commObj, TAHttpOperationError error) {
        fail();
    };
    [[NSOperationQueue mainQueue] addOperation:request];
    return request;
}

+(TAHttpOperation*)refreshAccessToken:(NSString*)refreshToken
                              success:(void (^)(NSString *accessToken, NSString *refreshToken, int expireTimestamp))success
                                 fail:(void (^)())fail{
    TAHttpOperation *request = [TAHttpOperation httpOperationWithTimeoutInterval:60];
    request.targetURL = [[Config instance].URL stringByAppendingString:@"/auth/refresh_token"];
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    [dict setObject:refreshToken forKey:@"refresh_token"];
    NSDictionary *headers = [NSDictionary dictionaryWithObject:@"application/json" forKey:@"Content-Type"];
    request.headers = headers;
    NSData *data = [NSJSONSerialization dataWithJSONObject:dict options:0 error:nil];
    request.postBody = data;
    request.method = @"POST";
    request.successCB = ^(TAHttpOperation*commObj, NSURLResponse *response, NSData *data) {
        int statusCode = [(NSHTTPURLResponse*)response statusCode];
        if (statusCode != 200) {
            NSDictionary *e = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:nil];
            NSLog(@"refresh token fail:%@", e);
            fail();
            return;
        }
        NSDictionary *resp = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:nil];
        NSString *accessToken = [resp objectForKey:@"access_token"];
        NSString *refreshToken = [resp objectForKey:@"refresh_token"];
        int expireTimestamp = time(NULL) + [[resp objectForKey:@"expires_in"] intValue];
        success(accessToken, refreshToken, expireTimestamp);
    };
    request.failCB = ^(TAHttpOperation*commObj, TAHttpOperationError error) {
        fail();
    };
    [[NSOperationQueue mainQueue] addOperation:request];
    return request;
}
@end
