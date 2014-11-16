//
//  LoginCheckVController.m
//  contact
//
//  Created by Coffee on 14/11/16.
//  Copyright (c) 2014年 momo. All rights reserved.
//

#import "LoginCheckVController.h"
#import "APIRequest.h"
#import "TAHttpOperation.h"
#import "AppDelegate.h"
#import "MainSynVController.h"
#import "Token.h"
#import "UIImage+NGAdditions.h"
#import "SVProgressHUD.h"

@interface LoginCheckVController () <UITextFieldDelegate>
@property (strong, nonatomic) UITextField *codeField;
@property (strong, nonatomic) UITextField *phoneField;
@property (strong, nonatomic) NSArray *reciver;
@property (strong, nonatomic) UIButton *registBtn;
@end

@implementation LoginCheckVController
- (void)viewDidLoad {
    [super viewDidLoad];

    [self setTitle:@"输入验证码"];

    //手机号码
	UIImageView* backImage = [[UIImageView alloc] initWithFrame:CGRectMake(0, 30, 320, 50)] ;
	backImage.userInteractionEnabled = YES;
    backImage.backgroundColor = [UIColor whiteColor];
	_codeField = [[UITextField alloc] initWithFrame: CGRectMake(20, 12, 280, 30)] ;
	_codeField.borderStyle = UITextBorderStyleNone;
	_codeField.textAlignment = NSTextAlignmentLeft;
    _codeField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@" 输入短信验证码" attributes:@{NSForegroundColorAttributeName: [UIColor colorWithRed:0.702f green:0.702f blue:0.702f alpha:1.00f], NSFontAttributeName: [UIFont systemFontOfSize:17]}];
    _codeField.font = [UIFont systemFontOfSize:17];
    _codeField.keyboardType = UIKeyboardTypePhonePad;
    _codeField.clearButtonMode = UITextFieldViewModeWhileEditing;
    _codeField.textColor = [UIColor blackColor];
    _codeField.returnKeyType = UIReturnKeyDone;
    [_codeField becomeFirstResponder];
    _codeField.delegate = self;
	[backImage addSubview:_codeField];
    [self.view addSubview:backImage];
    [_codeField addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];

    self.registBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    self.registBtn.frame = CGRectMake(15, 138, 290, 48);
	[self.registBtn setBackgroundImage: [UIImage imageWithStretchName:@"btn_green" top:20 left:5] forState:UIControlStateNormal];
    [self.registBtn setBackgroundImage: [UIImage imageWithStretchName:@"btn_grey@" top:20 left:5] forState:UIControlStateDisabled];
    [self.registBtn setBackgroundImage: [UIImage imageWithStretchName:@"btn_green_press" top:20 left:5] forState:UIControlStateHighlighted];
	[self.registBtn setTitle:@"注册" forState:UIControlStateNormal];
    [self.registBtn addTarget:self action:@selector(actionRegist) forControlEvents:UIControlEventTouchUpInside];
    [self.registBtn setEnabled:NO];
    [self.view addSubview: self.registBtn];
}

-(void)viewDidAppear:(BOOL)animated{
    [_codeField becomeFirstResponder];
}

- (void) textFieldDidChange:(id) sender {
    UITextField *_field = (UITextField *)sender;
    if ([_field text].length == 6) {
        [self.registBtn setEnabled:YES];
    }else {
        [self.registBtn setEnabled:NO];
    }
}

- (BOOL) textField:(UITextField *)aTextField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    // Check the replacementString
    if (_codeField.text.length >= 6) {
        return NO;
    }
    return YES;
}

- (BOOL)textFieldShouldClear:(UITextField *)textField {
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

-(void) actionRegist {
    __weak typeof(self) weakSelf = self;
    [SVProgressHUD showWithStatus:@"请求中" maskType:SVProgressHUDMaskTypeBlack];

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

                             [SVProgressHUD dismiss];

                             [weakSelf verifySuccess];
                         }fail:^{
                             NSLog(@"auth token fail");
                             [SVProgressHUD dismiss];
                         }];
}


-(void) verifySuccess{
    MainSynVController *tabController = [[MainSynVController alloc] init];
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
