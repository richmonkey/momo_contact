//
//  NSDictionary+NGAdditions.m
//  newgame
//
//  Created by shichangone on 16/4/14.
//  Copyright (c) 2014 ngds. All rights reserved.
//

#import "NSDictionary+NGAdditions.h"
#import "NSJSONSerialization+NGAdditions.h"

@implementation NSDictionary (NGAdditions)

- (NSString*)jsonString {
    return [NSJSONSerialization stringWithJSONObject:self];
}

- (NSString*)prettyJSONString {
    return [NSJSONSerialization stringWithJSONObject:self options:NSJSONWritingPrettyPrinted error:nil];
}

- (NSDictionary*) deepCopy {
    unsigned int count = [self count];
    id cObjects[count];
    id cKeys[count];
    
    NSEnumerator *e = [self keyEnumerator];
    unsigned int i = 0;
    id thisKey;
    while ((thisKey = [e nextObject]) != nil) {
        id obj = [self objectForKey:thisKey];
        
        if ([obj respondsToSelector:@selector(deepCopy)])
            cObjects[i] = [obj deepCopy];
        else
            cObjects[i] = [obj copy];
        
        if ([thisKey respondsToSelector:@selector(deepCopy)])
            cKeys[i] = [thisKey deepCopy];
        else
            cKeys[i] = [thisKey copy];
        
        ++i;
    }
    
    return [NSDictionary dictionaryWithObjects:cObjects forKeys:cKeys count:count];
}

- (NSMutableDictionary*) mutableDeepCopy {
    unsigned int count = [self count];
    id cObjects[count];
    id cKeys[count];
    
    NSEnumerator *e = [self keyEnumerator];
    unsigned int i = 0;
    id thisKey;
    while ((thisKey = [e nextObject]) != nil) {
        id obj = [self objectForKey:thisKey];
        
        // Try to do a deep mutable copy, if this object supports it
        if ([obj respondsToSelector:@selector(mutableDeepCopy)])
            cObjects[i] = [obj mutableDeepCopy];
        
        // Then try a shallow mutable copy, if the object supports that
        else if ([obj respondsToSelector:@selector(mutableCopyWithZone:)])
            cObjects[i] = [obj mutableCopy];
        
        // Next try to do a deep copy
        else if ([obj respondsToSelector:@selector(deepCopy)])
            cObjects[i] = [obj deepCopy];
        
        // If all else fails, fall back to an ordinary copy
        else
            cObjects[i] = [obj copy];
        
        // I don't think mutable keys make much sense, so just do an ordinary copy
        if ([thisKey respondsToSelector:@selector(deepCopy)])
            cKeys[i] = [thisKey deepCopy];
        else
            cKeys[i] = [thisKey copy];
        
        ++i;
    }
    
    return[NSMutableDictionary dictionaryWithObjects:cObjects forKeys:cKeys count:count];
}

@end
