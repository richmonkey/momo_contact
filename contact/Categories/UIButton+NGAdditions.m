//
//  UIButton+NGAdditions.m
//  newgame
//
//  Created by shichangone on 16/4/14.
//  Copyright (c) 2014 ngds. All rights reserved.
//

#import "UIButton+NGAdditions.h"
#import "UIView+NGAdditions.h"
#import "UIImage+NGAdditions.h"

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag
#endif

@implementation UIButton (NGAdditions)

+ (UIButton*)buttonWithImage:(UIImage*)image {
    UIButton* button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button setImage:image forState:UIControlStateNormal];
    button.size = image.size;
    
    return button;
}

@end


@implementation UIButton (Icon)

+ (UIButton*)buttonWithImage:(UIImage*)image {
    UIButton* button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button setImage:image forState:UIControlStateNormal];
    button.size = image.size;

    return button;
}

+ (UIButton*)buttonWithImageName:(NSString*)imageName hlightName:(NSString*)hlightName {
    UIButton* button = [UIButton buttonWithType:UIButtonTypeCustom];
    UIImage* image = [UIImage imageNamed:imageName];
    [button setImage:image forState:UIControlStateNormal];
    [button setImage:[UIImage imageNamed:hlightName] forState:UIControlStateHighlighted];
    button.size = image.size;

    return button;
}

//自动添加_press后缀
+ (UIButton*)buttonWithImageName:(NSString*)imageName {
    UIButton* button = [UIButton buttonWithType:UIButtonTypeCustom];
    UIImage* image = [UIImage imageNamed:imageName];
    [button setImage:image forState:UIControlStateNormal];

    NSString* hlightName = [imageName stringByAppendingString:@"_press"];
    [button setImage:[UIImage imageNamed:hlightName] forState:UIControlStateHighlighted];
    button.size = image.size;

    return button;
}


//根据拉伸图像返回按钮
+ (UIButton*)buttonWithStrengImageName:(NSString*)imageName {
    UIButton* button = [UIButton buttonWithType:UIButtonTypeCustom];
	[button setBackgroundImage:[UIImage imageWithStretchName:imageName top:20 left:5] forState:UIControlStateNormal];
    NSString* hlightName = [imageName stringByAppendingString:@"_press"];
    [button setBackgroundImage:[UIImage imageWithStretchName:hlightName top:20 left:5] forState:UIControlStateHighlighted];

    return button;
}
@end