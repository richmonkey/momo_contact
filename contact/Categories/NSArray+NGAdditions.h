//
//  NSArray+NGAdditions.h
//  newgame
//
//  Created by shichangone on 16/4/14.
//  Copyright (c) 2014 ngds. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSArray (NGAdditions)


- (NSString*)jsonString;

- (NSString*)prettyJSONString;

- (NSMutableArray*)mutableDeepCopy;

@end
