//
//  MainSynVController.m
//  contact
//
//  Created by Coffee on 14/11/16.
//  Copyright (c) 2014年 momo. All rights reserved.
//

#import "MainSynVController.h"
#import "MMSyncThread.h"
#import "Token.h"
#import "APIRequest.h"
#import "MMAddressBook.h"
#import "MMServerContactManager.h"
#import "UIView+NGAdditions.h"
#import "UIImage+NGAdditions.h"
@interface MainSynVController ()
@property(nonatomic)dispatch_source_t refreshTimer;
@property(nonatomic)int refreshFailCount;
@property(nonatomic, assign)ABAddressBookRef addressBook;
@property(strong, nonatomic)UILabel *localNumLabel;
@property(strong, nonatomic)UILabel *serviceNumLabel;
@property(strong, nonatomic)UIImageView *synImageView;
@property(strong, nonatomic)UIImageView *topBackImageView;
@property(strong, nonatomic)UIButton *synBtn;
- (void)onAddressBookChanged;
@end


static void ABChangeCallback(ABAddressBookRef addressBook, CFDictionaryRef info, void *context) {
    MainSynVController *controller = (__bridge MainSynVController *)(context);
    [controller onAddressBookChanged];
}

@implementation MainSynVController
- (void)viewDidLoad
{
    [super viewDidLoad];

    self.navigationItem.title = @"MoMo同步助手";
    self.leftButton.hidden = YES;
    [self.rightButton setTitle:@"退出" forState:UIControlStateNormal];

    [self initCustomView];
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
        int count;
        [MMServerContactManager getContactCount:&count];
        NSLog(@"server count:%d", count);
    });

    NSNotificationCenter * center = [NSNotificationCenter defaultCenter];
    [center addObserver:self selector:@selector(onBeginSync:) name:kMMBeginSync object:nil];
    [center addObserver:self selector:@selector(onEndSync:) name:kMMEndSync object:nil];
}

- (void)initCustomView {
    self.synBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    self.synBtn.frame = CGRectMake(15, 138, 290, 48);
	[self.synBtn setBackgroundImage: [UIImage imageWithStretchName:@"btn_green" top:20 left:5] forState:UIControlStateNormal];
    [self.synBtn setBackgroundImage: [UIImage imageWithStretchName:@"btn_green_press" top:20 left:5] forState:UIControlStateHighlighted];
	[self.synBtn setTitle:@"同步" forState:UIControlStateNormal];
    [self.synBtn addTarget:self action:@selector(actionSyn) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview: self.synBtn];

    UIImageView *localImage = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 36, 36)];
    localImage.centerX= 157/2;
    localImage.centerY = self.view.height - 60;
    localImage.image = [UIImage imageNamed:@"local"];
    [self.view addSubview:localImage];

    UIImageView *serviceImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 36, 36)];
    serviceImageView.centerX=  240;
    serviceImageView.centerY = self.view.height - 60;
    serviceImageView.image = [UIImage imageNamed:@"service"];
    [self.view addSubview:serviceImageView];


    self.synImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 112, 112)];
    self.synImageView.center = CGPointMake(225, self.view.height*2/3);
    self.synImageView.image = [UIImage imageNamed:@"syn"];
    [self.view addSubview:self.synImageView];
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
    int count = [MMAddressBook getContactCount];
    NSLog(@"contact count:%zd", count);

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        int count;
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
    int now = (int)time(NULL);
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

- (void)actionRight {
    [self.navigationController popToRootViewControllerAnimated:YES];
}

- (void)actionSyn {
       [[MMSyncThread shareInstance] beginSync];
}
@end
