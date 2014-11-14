//
//  NSJSONSerialization+NGAdditions.m
//  newgame
//
//  Created by shichangone on 16/4/14.
//  Copyright (c) 2014 ngds. All rights reserved.
//

#import "NSJSONSerialization+NGAdditions.h"

@implementation NSJSONSerialization (NGAdditions)

+ (id)JSONObjectWithNString:(NSString *)string {
    return [self JSONObjectWithNString:string options:0 error:nil];
}

+ (id)JSONObjectWithNString:(NSString *)string options:(NSJSONReadingOptions)opt error:(NSError **)error {
    NSData* data = [string dataUsingEncoding:NSUTF8StringEncoding];
    return [self JSONObjectWithData:data options:opt error:error];
}

+ (NSString*)stringWithJSONObject:(id)obj {
    return [self stringWithJSONObject:obj options:0 error:nil];
}

+ (NSString*)stringWithJSONObject:(id)obj options:(NSJSONWritingOptions)opt error:(NSError **)error {
    NSData* data = [self dataWithJSONObject:obj options:opt error:error];
    return [[NSString alloc] initWithBytes:data.bytes length:data.length encoding:NSUTF8StringEncoding];
}

@end
