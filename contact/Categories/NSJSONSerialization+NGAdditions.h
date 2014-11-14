//
//  NSJSONSerialization+NGAdditions.h
//  newgame
//
//  Created by shichangone on 16/4/14.
//  Copyright (c) 2014 ngds. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSJSONSerialization (NGAdditions)

+ (id)JSONObjectWithNString:(NSString *)string;

+ (id)JSONObjectWithNString:(NSString *)string options:(NSJSONReadingOptions)opt error:(NSError **)error;

+ (NSString*)stringWithJSONObject:(id)obj;

+ (NSString*)stringWithJSONObject:(id)obj options:(NSJSONWritingOptions)opt error:(NSError **)error;

@end
