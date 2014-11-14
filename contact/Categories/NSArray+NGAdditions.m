//
//  NSArray+NGAdditions.m
//  newgame
//
//  Created by shichangone on 16/4/14.
//  Copyright (c) 2014 ngds. All rights reserved.
//

#import "NSArray+NGAdditions.h"
#import "NSJSONSerialization+NGAdditions.h"

@implementation NSArray (NGAdditions)


- (NSString*)jsonString {
    return [NSJSONSerialization stringWithJSONObject:self];
}

- (NSString*)prettyJSONString {
    return [NSJSONSerialization stringWithJSONObject:self options:NSJSONWritingPrettyPrinted error:nil];
}

- (NSArray*) deepCopy {
    unsigned int count = [self count];
    id cArray[count];
    
    for (unsigned int i = 0; i < count; ++i) {
        id obj = [self objectAtIndex:i];
        if ([obj respondsToSelector:@selector(deepCopy)])
            cArray[i] = [obj deepCopy];
        else
            cArray[i] = [obj copy];
    }
    
    return [NSArray arrayWithObjects:cArray count:count];
}
- (NSMutableArray*) mutableDeepCopy {
    unsigned int count = [self count];
    id cArray[count];
    
    for (unsigned int i = 0; i < count; ++i) {
        id obj = [self objectAtIndex:i];
        
        // Try to do a deep mutable copy, if this object supports it
        if ([obj respondsToSelector:@selector(mutableDeepCopy)])
            cArray[i] = [obj mutableDeepCopy];
        
        // Then try a shallow mutable copy, if the object supports that
        else if ([obj respondsToSelector:@selector(mutableCopyWithZone:)])
            cArray[i] = [obj mutableCopy];
        
        // Next try to do a deep copy
        else if ([obj respondsToSelector:@selector(deepCopy)])
            cArray[i] = [obj deepCopy];
        
        // If all else fails, fall back to an ordinary copy
        else
            cArray[i] = [obj copy];
    }
    
    return [NSMutableArray arrayWithObjects:cArray count:count];
}

@end
