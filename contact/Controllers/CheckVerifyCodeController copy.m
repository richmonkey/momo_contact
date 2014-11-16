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
#import "AppDelegate.h"
#import "MainViewController.h"
#import "Token.h"
#import "UIImage+NGAdditions.h"

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag
#endif

@interface CheckVerifyCodeController ()
@property (strong, nonatomic) UITextField *codeField;
@property  (nonatomic)                 UIBarButtonItem *nextButton;
@property (strong, nonatomic)          NSArray *reciver;
@property (strong, nonatomic) UIButton *registBtn;

@end

@implementation CheckVerifyCodeController


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setTitle:@"输入验证码"];
    
//    [self.rightButton setTitle:@"验证" forState:UIControlStateNormal];

    [self.navigationItem setHidesBackButton:YES];

    //验证码
	UIImageView* backImage = [[UIImageView alloc] initWithFrame:CGRectMake(0, 15, 320, 50)] ;
	backImage.userInteractionEnabled = YES;
    backImage.backgroundColor = [UIColor whiteColor];
	//backImage.image = [[UIImage imageNamed:@"inputbox"] stretchableImageWithLeftCapWidth:12 topCapHeight:25];;
	_codeField= [[UITextField alloc] initWithFrame: CGRectMake(20, 12, 280, 30)] ;
	_codeField = UITextBorderStyleNone;
	_codeField.textAlignment = NSTextAlignmentLeft;
    _codeField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@" 输入短信验证码" attributes:@{NSForegroundColorAttributeName: [UIColor colorWithRed:0.702f green:0.702f blue:0.702f alpha:1.00f], NSFontAttributeName: [UIFont systemFontOfSize:17]}];
    _codeField.font = [UIFont systemFontOfSize:17];
    _codeField.keyboardType = UIKeyboardTypePhonePad;
    _codeField.clearButtonMode = UITextFieldViewModeWhileEditing;
    _codeField.textColor = [UIColor blackColor];
    _codeField.returnKeyType = UIReturnKeyDone;
    _codeField.delegate = self;
	[backImage addSubview:_codeField];
    [self.view addSubview:backImage];
    [_codeField becomeFirstResponder];
    [_codeField addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];

    self.registBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    self.registBtn.frame = CGRectMake(15, 138, 290, 48);
	[self.registBtn setBackgroundImage: [UIImage imageWithStretchName:@"btn_green" top:20 left:5] forState:UIControlStateNormal];
    [self.registBtn setBackgroundImage: [UIImage imageWithStretchName:@"btn_grey@" top:20 left:5] forState:UIControlStateDisabled];
    [self.registBtn setBackgroundImage: [UIImage imageWithStretchName:@"btn_green_press" top:20 left:5] forState:UIControlStateHighlighted];
	[self.registBtn setTitle:@"注册" forState:UIControlStateNormal];
    [self.registBtn addTarget:self action:@selector(actionRegist) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview: self.registBtn];
}

-(void)viewDidAppear:(BOOL)animated{
    [_codeField becomeFirstResponder];
}

- (void) textFieldDidChange:(id) sender {
    UITextField *_field = (UITextField *)sender;
    if ([_field text].length == 6) {
        [self.nextButton setEnabled:YES];
    }else if([_field text].length > 11){
        [self.nextButton setEnabled:NO];
    }else{
        [self.nextButton setEnabled:NO];
    }
}

-(void) actionRegist {
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];

    [APIRequest requestAuthToken:self.codeField.text zone:@"86"
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
                         }fail:^{
                           NSLog(@"auth token fail");
                                [hud hide:NO];
                            }];
}


-(void) verifySuccess{
    MainViewController *tabController = [[MainViewController alloc] init];
    [self.navigationController pushViewController:tabController animated:YES];
//    UINavigationController *navCtl = [[UINavigationController alloc] initWithRootViewController:tabController];
//    navCtl.navigationBarHidden = YES;
//    AppDelegate *delegate = [[UIApplication sharedApplication] delegate];
//    delegate.window.rootViewController = navCtl;

}


#pragma mark - UITextFieldDelegate
- (void)textFieldDidBeginEditing:(UITextField *)textField{
    
}

- (void)textFieldDidEndEditing:(UITextField *)textField{
    
    
}


@end
