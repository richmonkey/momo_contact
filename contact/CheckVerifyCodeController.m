//
//  CheckVerifyCodeController.m
//  Message
//
//  Created by 杨朋亮 on 14/9/14.
//  Copyright (c) 2014年 daozhu. All rights reserved.
//

#import "CheckVerifyCodeController.h"
#import "APIRequest.h"
#import "MBProgressHUD.h"
#import "TAHttpOperation.h"
#import "Config.h"
#import "AppDelegate.h"
#import "MainViewController.h"
#import "Token.h"

@interface CheckVerifyCodeController ()

@property (weak, nonatomic) IBOutlet   UITextField *verifyCodeTextField;
@property  (nonatomic)                 UIBarButtonItem *nextButton;
@property (strong, nonatomic)          NSArray *reciver;

@end

@implementation CheckVerifyCodeController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setTitle:@"输入验证码"];
    
    self.nextButton = [[UIBarButtonItem alloc]
                       initWithTitle:@"验证"
                       style:UIBarButtonItemStylePlain
                       target:self
                       action:@selector(nextAction)];
    [self.navigationItem setRightBarButtonItem:self.nextButton];
    [self.nextButton setEnabled:NO];
    
    [self.navigationItem setHidesBackButton:YES];
    
    [self.verifyCodeTextField becomeFirstResponder];
    [self.verifyCodeTextField addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
}

-(void)viewDidAppear:(BOOL)animated{
    [self.verifyCodeTextField becomeFirstResponder];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void) textFieldDidChange:(id) sender {
    UITextField *_field = (UITextField *)sender;
    if ([_field text].length == 6) {
        [self.nextButton setEnabled:YES];
    }else{
        [self.nextButton setEnabled:NO];
    }
}

-(void) nextAction {
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];

    [APIRequest requestAuthToken:self.verifyCodeTextField.text zone:@"86"
                          number:self.phoneNumberStr deviceToken:@""
                         success:^(int64_t uid, NSString* accessToken, NSString *refreshToken, int expireTimestamp, NSString *state){
                             NSLog(@"auth token success");
                             Token *token = [Token instance];
                             token.accessToken = accessToken;
                             token.refreshToken = refreshToken;
                             token.expireTimestamp = expireTimestamp;
                             token.uid = uid;
                             token.phoneNumber = self.phoneNumberStr;
                             [token save];

                             [hud hide:NO];
                             
                             [self verifySuccess];
                         }
                            fail:^{
                                NSLog(@"auth token fail");
                                [hud hide:NO];
                            }];
}


-(void) verifySuccess{
    MainViewController *tabController = [[MainViewController alloc] init];
    UINavigationController *navCtl = [[UINavigationController alloc] initWithRootViewController:tabController];
    navCtl.navigationBarHidden = YES;
    AppDelegate *delegate = [[UIApplication sharedApplication] delegate];
    delegate.window.rootViewController = navCtl;
    
}


#pragma mark - UITextFieldDelegate
- (void)textFieldDidBeginEditing:(UITextField *)textField{
    
}

- (void)textFieldDidEndEditing:(UITextField *)textField{
    
    
}


@end
