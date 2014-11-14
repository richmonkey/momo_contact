//
//  UIButton+NGAdditions.h
//  newgame
//
//  Created by shichangone on 16/4/14.
//  Copyright (c) 2014 ngds. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIButton (NGAdditions)

+ (UIButton*)buttonWithImage:(UIImage*)image;

@end

@interface UIButton (Icon)


+ (UIButton*)buttonWithImage:(UIImage*)image;
+ (UIButton*)buttonWithImageName:(NSString*)imageName hlightName:(NSString*)hlightName;
+ (UIButton*)buttonWithImageName:(NSString*)imageName;
+ (UIButton*)buttonWithStrengImageName:(NSString*)imageName;
@end

@interface UIButton (Tag)

+ (UIButton*)ng_buttonWithTag:(NSString*)tag;

@end