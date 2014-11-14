//
//  UIImage+NGAdditions.m
//  newgame
//
//  Created by shichangone on 16/4/14.
//  Copyright (c) 2014 ngds. All rights reserved.
//

#import "UIImage+NGAdditions.h"

@implementation UIImage (NGAdditions)

+ (UIImage*)imageWithColor:(UIColor *)color {
    CGRect rect = CGRectMake(0, 0, 1, 1);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, rect);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

@end

@implementation UIImage (Stretch)

+ (UIImage*)imageWithStretchName:(NSString*)imageName top:(float)top left:(float)left{
    UIImage *image = [[UIImage imageNamed:imageName] resizableImageWithCapInsets:UIEdgeInsetsMake(top, left, top, left)];

    return image;
}

@end