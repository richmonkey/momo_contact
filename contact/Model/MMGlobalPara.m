//
//  MMGlobalPara.m
//  momo
//
//  Created by mfm on 6/11/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "MMGlobalPara.h"

static UITabBarController *g_tabBarController;

@implementation MMGlobalPara


+(void)setTabBarController:(UITabBarController*)barController {
	g_tabBarController = barController;
}

+(UITabBarController*)getTabBarController {
	return g_tabBarController;
}

+ (NSString*)documentDirectory {
	return [NSString stringWithFormat:@"%@/Documents/MomoData/", NSHomeDirectory()];
}


+(NSObject*)getAppDelegate {
    return [UIApplication sharedApplication].delegate;
}

@end
