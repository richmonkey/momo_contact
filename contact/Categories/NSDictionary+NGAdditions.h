//
//  NSDictionary+NGAdditions.h
//  newgame
//
//  Created by shichangone on 16/4/14.
//  Copyright (c) 2014 ngds. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDictionary (NGAdditions)

- (NSString*)jsonString;
- (NSString*)prettyJSONString;

- (NSMutableDictionary*)mutableDeepCopy;

@end
