//
//  NSString+NGAdditions.h
//  newgame
//
//  Created by shichangone on 16/4/14.
//  Copyright (c) 2014 ngds. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (NGAdditions)

- (NSString*)md5Hash;
- (NSString*)sha1Hash;

+ (NSString*)stringWithData:(NSData*)data encoding:(NSStringEncoding)encoding;

- (id)jsonValue;

@end

@interface  NSString (Email)

- (BOOL)isEmailValid;

@end

@interface NSString (Check)

- (BOOL)isEmpty;
@end