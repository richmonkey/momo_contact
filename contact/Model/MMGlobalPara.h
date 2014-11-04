//
//  MMGlobalPara.h
//  momo
//
//  Created by mfm on 6/11/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MMGlobalPara : NSObject {

}

+(void)setTabBarController:(UITabBarController*)barController;
+(UITabBarController*)getTabBarController;

+ (NSString*)documentDirectory;

+(NSObject*)getAppDelegate;


@end
