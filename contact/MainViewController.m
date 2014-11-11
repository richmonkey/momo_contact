//
//  ViewController.m
//  contact
//
//  Created by houxh on 14-11-4.
//  Copyright (c) 2014年 momo. All rights reserved.
//

#import "MainViewController.h"
#import "MMSyncThread.h"
#import "Token.h"
#import "APIRequest.h"
#import "MMAddressBook.h"
#import "MMServerContactManager.h"

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag
#endif

@interface MainViewController ()
@property(nonatomic)dispatch_source_t refreshTimer;
@property(nonatomic)int refreshFailCount;
@property(nonatomic, assign)ABAddressBookRef addressBook;

- (void)onAddressBookChanged;
@end

static void ABChangeCallback(ABAddressBookRef addressBook, CFDictionaryRef info, void *context) {
    MainViewController *controller = (__bridge MainViewController *)(context);
    [controller onAddressBookChanged];
}

@implementation MainViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    [[MMSyncThread shareInstance] start];
    
    dispatch_queue_t queue = dispatch_get_main_queue();
    self.refreshTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0,queue);
    dispatch_source_set_event_handler(self.refreshTimer, ^{
        [self refreshAccessToken];
    });
    [self startRefreshTimer];
    
    CFErrorRef err = nil;
    self.addressBook = ABAddressBookCreateWithOptions(NULL, &err);
    if (err) {
        NSString *s = (__bridge NSString*)CFErrorCopyDescription(err);
        NSLog(@"address book error:%@", s);
        return;
    }

    ABAuthorizationStatus status = ABAddressBookGetAuthorizationStatus();
    if (status == kABAuthorizationStatusNotDetermined) {
        NSLog(@"not determined");
        ABAddressBookRequestAccessWithCompletion(self.addressBook, ^(bool granted, CFErrorRef error) {
            NSLog(@"grant:%d", granted);
            if (granted) {
               ABAddressBookRegisterExternalChangeCallback(self.addressBook, ABChangeCallback, (__bridge void *)(self));
            }
        });
    } else if (status == kABAuthorizationStatusAuthorized){
        ABAddressBookRegisterExternalChangeCallback(self.addressBook, ABChangeCallback, (__bridge void *)(self));
        NSLog(@"addressbook authorized");
    } else {
        NSLog(@"no addressbook authorization");
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSInteger count;
        [MMServerContactManager getContactCount:&count];
        NSLog(@"server count:%d", count);
    });
    
    NSNotificationCenter * center = [NSNotificationCenter defaultCenter];
    [center addObserver:self selector:@selector(onBeginSync:) name:kMMBeginSync object:nil];
    [center addObserver:self selector:@selector(onEndSync:) name:kMMEndSync object:nil];
}

- (void)onAddressBookChanged {
    ABAddressBookRevert(self.addressBook);
    int count = [MMAddressBook getContactCount];
    NSLog(@"contact count:%d", count);
}

- (void)onBeginSync:(NSNotification*)notification {
    NSLog(@"onBeginSync");
}

- (void)onEndSync:(NSNotification*)notification {
    NSLog(@"onEndSync");
    ABAddressBookRevert(self.addressBook);
    int count = [MMAddressBook getContactCount];
    NSLog(@"contact count:%d", count);
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSInteger count;
        [MMServerContactManager getContactCount:&count];
        NSLog(@"server count:%d", count);
    });
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)sync:(id)sender {
    [[MMSyncThread shareInstance] beginSync];
}

-(void)startRefreshTimer {
    [self prepareTimer];
    dispatch_resume(self.refreshTimer);
}

-(void)prepareTimer {
    Token *token = [Token instance];
    int now = time(NULL);
    if (now >= token.expireTimestamp - 1) {
        dispatch_time_t w = dispatch_walltime(NULL, 0);
        dispatch_source_set_timer(self.refreshTimer, w, DISPATCH_TIME_FOREVER, 0);
    } else {
        dispatch_time_t w = dispatch_walltime(NULL, (token.expireTimestamp - now - 1)*NSEC_PER_SEC);
        dispatch_source_set_timer(self.refreshTimer, w, DISPATCH_TIME_FOREVER, 0);
    }
}

-(void)refreshAccessToken {
    Token *token = [Token instance];
    [APIRequest refreshAccessToken:token.refreshToken
                           success:^(NSString *accessToken, NSString *refreshToken, int expireTimestamp) {
                               token.accessToken = accessToken;
                               token.refreshToken = refreshToken;
                               token.expireTimestamp = expireTimestamp;
                               [token save];
                               [self prepareTimer];
                               
                           }
                              fail:^{
                                  self.refreshFailCount = self.refreshFailCount + 1;
                                  int64_t timeout;
                                  if (self.refreshFailCount > 60) {
                                      timeout = 60*NSEC_PER_SEC;
                                  } else {
                                      timeout = (int64_t)self.refreshFailCount*NSEC_PER_SEC;
                                  }
                                  
                                  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, timeout), dispatch_get_main_queue(), ^{
                                      [self prepareTimer];
                                  });
                                  
                              }];
}


@end
