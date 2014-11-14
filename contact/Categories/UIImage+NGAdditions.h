//
//  UIImage+NGAdditions.h
//  newgame
//
//  Created by shichangone on 16/4/14.
//  Copyright (c) 2014 ngds. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (NGAdditions)

+ (UIImage*)imageWithColor:(UIColor*)color;

@end

@interface UIImage (Stretch)

+ (UIImage*)imageWithStretchName:(NSString*)imageName top:(float)top left:(float)left;

@end