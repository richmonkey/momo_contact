//
//  MMGlobalData.m
//  momo
//
//  Created by mfm on 6/12/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "MMGlobalData.h"
#import "MMGlobalPara.h"
#import "DbStruct.h"

@interface MMGlobalData()
@property(nonatomic, retain)    NSMutableDictionary *preference_;
+ (MMGlobalData*)getInstance;
@end

@implementation MMGlobalData
@synthesize preference_;

+(MMGlobalData *)getInstance
{
    static MMGlobalData* instance = nil;
	if(!instance) {
		@synchronized(self) {
			if(!instance) {
				instance = [[[MMGlobalData alloc] init] autorelease];
			}
		}
	}
	return instance;
}

+ (void)setPreference:(id)anObject forKey:(id)aKey {
    @synchronized(self) {
        [[MMGlobalData getInstance].preference_ setValue:anObject forKey:aKey];
    }
}

+ (id)getPreferenceforKey:(id)aKey {
    @synchronized(self) {
        id value = [[MMGlobalData getInstance].preference_ objectForKey:aKey];
        [[value retain] autorelease];
        return value;
    }
}

+ (void)removePreferenceforKey:(id)aKey {
    @synchronized(self) {
        [[MMGlobalData getInstance].preference_ removeObjectForKey:aKey];
    }
}

+ (void)savePreference {
    @synchronized(self) {
        MMGlobalData *instance = [MMGlobalData getInstance];
        NSString *documentsDirectory = [MMGlobalPara documentDirectory];
        NSString *prefPath = [documentsDirectory stringByAppendingPathComponent:@"/momo_preference.plist"];
        [instance.preference_ writeToFile:prefPath atomically:YES];
    }
}

+ (void)removeAllPreference {
    @synchronized(self) {
        MMGlobalData *instance = [MMGlobalData getInstance];
        NSString *documentsDirectory = [MMGlobalPara documentDirectory];
        NSString *prefPath = [documentsDirectory stringByAppendingPathComponent:@"/momo_preference.plist"];
        [instance.preference_ removeAllObjects];
        [instance.preference_ writeToFile:prefPath atomically:YES];
    }
}

+(void)upgrade {
    @synchronized(self) {
        MMGlobalData *instance = [MMGlobalData getInstance];
        // 初始化存盘配置
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSError* error;
        
        NSString *documentsDirectory = [MMGlobalPara documentDirectory];
        if (![fileManager fileExistsAtPath:documentsDirectory]) {
            [fileManager createDirectoryAtPath:documentsDirectory withIntermediateDirectories:YES attributes:nil error:nil];
        }
        
        NSString *prefPath = [documentsDirectory stringByAppendingPathComponent:@"/momo_preference.plist"];
        [fileManager removeItemAtPath:prefPath error:nil];
        
        if(![fileManager fileExistsAtPath:prefPath]) {
            NSString *defaultDBPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"momo_preference.plist"];
            [fileManager copyItemAtPath:defaultDBPath toPath:prefPath error:&error];
            
        }
        
        NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithContentsOfFile:prefPath];
        instance.preference_ = [[[NSMutableDictionary alloc] initWithDictionary:dict] autorelease];
    }
}

-(id)init {
    self = [super init];
    if (self) {
        // 初始化存盘配置
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSError* error;

        NSString *documentsDirectory = [MMGlobalPara documentDirectory];
        if (![fileManager fileExistsAtPath:documentsDirectory]) {
            [fileManager createDirectoryAtPath:documentsDirectory withIntermediateDirectories:YES attributes:nil error:nil];
        }
        
        NSString *prefPath = [documentsDirectory stringByAppendingPathComponent:@"/momo_preference.plist"];
        if(![fileManager fileExistsAtPath:prefPath]) {
            NSString *defaultDBPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"momo_preference.plist"];
            [fileManager copyItemAtPath:defaultDBPath toPath:prefPath error:&error];
            
        }
        
        NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithContentsOfFile:prefPath];
        preference_ = [[NSMutableDictionary alloc] initWithDictionary:dict];
	}
    return self;
	
}

-(void)dealloc {		
    [MMGlobalData savePreference];
    [preference_ release];
	[super dealloc];
}
@end









