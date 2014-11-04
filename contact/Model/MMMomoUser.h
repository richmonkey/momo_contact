//
//  MMMomoUser.h
//  momo
//
//  Created by jackie on 11-8-4.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MMModel.h"
#import "DbStruct.h"

@interface MMMomoUser : MMModel {

}

+ (id)instance;

- (MMErrorType)saveUser:(MMMomoUserInfo*)userInfo;

- (NSMutableDictionary*)getAllUserInfo;

- (MMMomoUserInfo*)getUserInfo:(NSUInteger)uid;

- (MMMomoUserInfo*)userInfoFromPLResultSet:(id<PLResultSet>)result;

@end
