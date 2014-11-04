//
//  MMMomoUser.m
//  momo
//
//  Created by jackie on 11-8-4.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "MMMomoUser.h"


@implementation MMMomoUser

+ (id)instance {
	static id _instance = nil;
    @synchronized(self) {
        if(_instance == nil) 
            _instance = [[self class] new];
    }
    return _instance;
}

- (MMErrorType)saveUser:(MMMomoUserInfo*)userInfo {
	// 如果数据没打开
	if(![[self db]  goodConnection]) {
		return MM_DB_FAILED_OPEN;
	}
	
	NSString* sql = @"replace into momo_user ( uid, real_name, avatar_image_url) \
	values (:uid, :real_name, :avatar_image_url);";
	NSMutableDictionary* parameters = [NSMutableDictionary dictionary];
	[parameters setObject:[NSNumber numberWithInt:userInfo.uid] forKey:@"uid"];
	[parameters setObject:PARSE_NULL_STR(userInfo.realName) forKey:@"real_name"];
	[parameters setObject:PARSE_NULL_STR(userInfo.avatarImageUrl) forKey:@"avatar_image_url"];
	
	id<PLPreparedStatement> stmt = [[self db]  prepareStatement:sql];   
	// 绑定参数
	[stmt bindParameterDictionary:parameters];
	
	// 如果执行失败
	if(![stmt executeUpdate]) {
		
		return MM_DB_FAILED_INVALID_STATEMENT;
	}
	
	return MM_DB_OK;
}

- (MMMomoUserInfo*)getUserInfo:(NSUInteger)uid {
    // 如果数据没打开
	if(![[self db]  goodConnection]) {
		return nil;
	}
	
	NSError* outError = nil;
	NSString * sql = [NSString stringWithFormat:@"select * from momo_user where uid=%u;", uid];
	id<PLResultSet> results = [[self db]  executeQueryAndReturnError:&outError statement:sql];        
	if(SQLITE_OK != [outError code]) {
		return nil;
	}
	
	MMMomoUserInfo* userInfo = nil;
	PLResultSetStatus status = [results nextAndReturnError:nil];
	if (status == PLResultSetStatusRow) {
		userInfo = [self userInfoFromPLResultSet:results];
	}
	[results close];
	
	return userInfo;
}

- (NSMutableDictionary*)getAllUserInfo {
	// 如果数据没打开
	if(![[self db]  goodConnection]) {
		return nil;
	}
	
	NSError* outError = nil;
	NSString * sql = @"select * from momo_user;";
	id<PLResultSet> results = [[self db]  executeQueryAndReturnError:&outError statement:sql];        
	if(SQLITE_OK != [outError code]) {
		return nil;
	}
	
	NSMutableDictionary* userDict = [NSMutableDictionary dictionary];
	PLResultSetStatus status = [results nextAndReturnError:nil];
	while (status) {
		MMMomoUserInfo* userInfo = [self userInfoFromPLResultSet:results];
		[userDict setObject:userInfo forKey:[NSNumber numberWithInt:userInfo.uid]];
		
		status = [results nextAndReturnError:nil];
	}
	[results close];
	
	return userDict;
}

- (MMMomoUserInfo*)userInfoFromPLResultSet:(id<PLResultSet>)result {
	MMMomoUserInfo* userInfo = [[[MMMomoUserInfo alloc] init] autorelease];
	userInfo.uid = [result intForColumn:@"uid"];
    
    if (![result isNullForColumn:@"real_name"]) {
        userInfo.realName = [result stringForColumn:@"real_name"];
    }
    userInfo.realName = PARSE_NULL_STR(userInfo.realName);
    
    if (![result isNullForColumn:@"avatar_image_url"]) {
        userInfo.avatarImageUrl = [result stringForColumn:@"avatar_image_url"];
    }
	
	return userInfo;
}


@end
