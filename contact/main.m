//
//  main.m
//  contact
//
//  Created by houxh on 14-11-4.
//  Copyright (c) 2014年 momo. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <sqlite3.h>
#import "AppDelegate.h"
#import "MMSyncThread.h"
#import "MMGlobalData.h"

int main(int argc, char * argv[])
{
    @autoreleasepool {

        //保证多线程模式
        NSObject* tmpObject = [[NSObject alloc] init];
        [tmpObject performSelectorInBackground:@selector(release) withObject:nil];
        
        if (sqlite3_config(SQLITE_CONFIG_MULTITHREAD) != SQLITE_OK) {
            NSLog(@"sqlite3_config failed");
        }
        
        [MMSyncThread shareInstance];
        [MMUapRequest shareInstance];
        MLOG(@"app startup");
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([AppDelegate class]));
    }
}
