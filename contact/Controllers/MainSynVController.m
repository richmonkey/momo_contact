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
#import "MMCommonAPI.h"
#import "MMGlobalData.h"

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag
#endif

@interface MainSynVController ()<UINavigationControllerDelegate, UIImagePickerControllerDelegate>
@property(nonatomic)dispatch_source_t refreshTimer;
@property(nonatomic)int refreshFailCount;
@property(nonatomic, assign)ABAddressBookRef addressBook;
@property(strong, nonatomic)UILabel *localNumLabel;
@property(strong, nonatomic)UILabel *serviceNumLabel;
@property(strong, nonatomic)UIImageView *topBackImageView;
@property(strong, nonatomic)UIButton *synBtn;
@property(nonatomic) BOOL bAnimating;
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
    self.rightButton.hidden = YES;

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
                dispatch_async(dispatch_get_main_queue(), ^{
                    ABAddressBookRegisterExternalChangeCallback(self.addressBook, ABChangeCallback, (__bridge void *)(self));
                    int count = [MMAddressBook getContactCount];
                    self.localNumLabel.text = [NSString stringWithFormat:@"%d", count];
                });
            }
        });
    } else if (status == kABAuthorizationStatusAuthorized){
        ABAddressBookRegisterExternalChangeCallback(self.addressBook, ABChangeCallback, (__bridge void *)(self));
        NSLog(@"addressbook authorized");
        int count = [MMAddressBook getContactCount];
        self.localNumLabel.text = [NSString stringWithFormat:@"%d", count];
    } else {
        NSLog(@"no addressbook authorization");
    }

    id value = [MMGlobalData getPreferenceforKey:@"server_contact_count"];
    if (value != nil) {
        int count = [value intValue];
        self.serviceNumLabel.text = [NSString stringWithFormat:@"%d", count];
    }

    Token *token = [Token instance];
    int now = (int)time(NULL);
    if (now >= token.expireTimestamp - 1) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(20 * NSEC_PER_SEC)),
                       dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            int count;
            BOOL r = [MMServerContactManager getContactCount:&count];
            if (r) {
                NSLog(@"server count:%d", count);
                dispatch_async(dispatch_get_main_queue(), ^{
                    [MMGlobalData setPreference:[NSNumber numberWithInt:count] forKey:@"server_contact_count"];
                    [MMGlobalData savePreference];
                    self.serviceNumLabel.text = [NSString stringWithFormat:@"%d", count];
                });
            }
        });
    } else {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            int count;
            BOOL r = [MMServerContactManager getContactCount:&count];
            if (r) {
                NSLog(@"server count:%d", count);
                dispatch_async(dispatch_get_main_queue(), ^{
                    [MMGlobalData setPreference:[NSNumber numberWithInt:count] forKey:@"server_contact_count"];
                    [MMGlobalData savePreference];
                    self.serviceNumLabel.text = [NSString stringWithFormat:@"%d", count];
                });
            }
        });
    }

    NSNotificationCenter * center = [NSNotificationCenter defaultCenter];
    [center addObserver:self selector:@selector(onBeginSync:) name:kMMBeginSync object:nil];
    [center addObserver:self selector:@selector(onEndSync:) name:kMMEndSync object:nil];
}

- (void)initCustomView {

    self.topBackImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, self.view.width, self.view.height - 160 - 64)];
    self.topBackImageView.contentMode =UIViewContentModeScaleAspectFill ;
    self.topBackImageView.clipsToBounds = YES;
    self.topBackImageView.image = [UIImage imageNamed:@"xingji"];
    [self.view addSubview:self.topBackImageView];


    self.synBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    self.synBtn.frame = CGRectMake(0, 0, 112, 112);
    self.synBtn.center = CGPointMake(225, self.view.height - 160 - 64);
	[self.synBtn setImage: [UIImage imageNamed:@"syn"] forState:UIControlStateNormal];
    [self.synBtn addTarget:self action:@selector(actionSyn) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview: self.synBtn];

    UIImageView *localImage = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 36, 36)];
    localImage.centerX= 157/2;
    localImage.centerY = self.view.height - 140;
    localImage.image = [UIImage imageNamed:@"local"];
    [self.view addSubview:localImage];

    self.localNumLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 65, 30)];
    self.localNumLabel.center = CGPointMake(157/2, self.view.height - 100);
    self.localNumLabel.textAlignment = NSTextAlignmentCenter;
    self.localNumLabel.textColor = [UIColor colorWithRed:0.255f green:0.804f blue:0.412f alpha:1.00f];
    self.localNumLabel.font = [UIFont systemFontOfSize:20];
    [self.view addSubview:self.localNumLabel];


    UIImageView *serviceImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 36, 36)];
    serviceImageView.centerX=  240;
    serviceImageView.centerY = self.view.height - 140;
    serviceImageView.image = [UIImage imageNamed:@"service"];
    [self.view addSubview:serviceImageView];

    self.serviceNumLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 65, 30)];
    self.serviceNumLabel.center = CGPointMake(240, self.view.height - 100);
    self.serviceNumLabel.textAlignment = NSTextAlignmentCenter;
    self.serviceNumLabel .textColor = [UIColor colorWithRed:0.255f green:0.804f blue:0.412f alpha:1.00f];
    self.serviceNumLabel.font = [UIFont systemFontOfSize:20];
    


    [self.view addSubview:self.serviceNumLabel];
}

- (void)onAddressBookChanged {
    ABAddressBookRevert(self.addressBook);
    int count = [MMAddressBook getContactCount];
    self.localNumLabel.text = [NSString stringWithFormat:@"%d", count];
    NSLog(@"contact count:%d", count);
}

- (void)onBeginSync:(NSNotification*)notification {
    [self startSpin];
    NSLog(@"onBeginSync");
}

- (void)onEndSync:(NSNotification*)notification {
    BOOL r = [[notification.object objectForKey:@"result"] boolValue];
    if (!r) {
        [MMCommonAPI alert:@"同步失败"];
        [self stopSpin];
        return;
    }
    
    NSLog(@"onEndSync");
    int count = [MMAddressBook getContactCount];
    NSLog(@"contact count:%zd", count);
    self.localNumLabel.text = [NSString stringWithFormat:@"%d", count];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        int count = 0;
        BOOL sucuess = [MMServerContactManager getContactCount:&count];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self stopSpin];
            if (sucuess) {
                self.serviceNumLabel.text = [NSString stringWithFormat:@"%d", count];
                NSLog(@"server count:%d", count);
                [MMCommonAPI alert:@"同步完成"];
            } else {
                [MMCommonAPI alert:@"同步失败"];
            }
        });
    });
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

//旋转
- (void) spinWithOptions: (UIViewAnimationOptions) options {
    // this spin completes 360 degrees every 2 seconds
    [UIView animateWithDuration: 0.5f
                          delay: 0.0f
                        options: options
                     animations: ^{
                         self.synBtn.transform = CGAffineTransformRotate(self.synBtn.transform, M_PI / 2);
                     }
                     completion: ^(BOOL finished) {
                         if (finished) {
                             if (self.bAnimating) {
                                 // if flag still set, keep spinning with constant speed
                                 [self spinWithOptions: UIViewAnimationOptionCurveLinear];
                             } else if (options != UIViewAnimationOptionCurveEaseOut) {
                                 // one last spin, with deceleration
                                 [self spinWithOptions: UIViewAnimationOptionCurveEaseOut];
                             }
                         }
                     }];
}

- (void) startSpin {
    if (!self.bAnimating) {
        self.bAnimating = YES;
        [self spinWithOptions: UIViewAnimationOptionCurveEaseIn];
    }
}

- (void) stopSpin {
    self.bAnimating = NO;
}
@end

