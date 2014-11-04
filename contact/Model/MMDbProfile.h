//
//  MMDbProfile.h
//  momo
//
//  Created by m fm on 11-3-16.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DbStruct.h"
#import "MMModel.h"

@interface MMDbProfile : MMModel {
	
}

+ (id)instance;

- (NSArray*) getAllLabelInProfileWithError:(MMErrorType*)error ;
- (MMErrorType)insertLabel:(NSString*)label;
- (MMErrorType)deleteLabel:(NSString*)label;

- (void)setObject:(NSString*)anObject forKey:(NSString*)aKey;
- (NSString*)objectForKey:(NSString*)aKey;
- (void)removeObjectForKey:(NSString*)aKey;

- (void)clearLastCharTime;

@end
