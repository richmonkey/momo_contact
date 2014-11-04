//
//  MMGlobalData.h
//  momo
//
//  Created by mfm on 6/12/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MMLogger.h"

@interface MMGlobalData : NSObject {
    NSMutableDictionary *preference_;   // 配置

}


+(void)upgrade;
+ (void)setPreference:(id)anObject forKey:(id)aKey;
+ (id)getPreferenceforKey:(id)aKey;
+ (void)removePreferenceforKey:(id)aKey;
+ (void)savePreference;

+ (void)removeAllPreference;

@end
