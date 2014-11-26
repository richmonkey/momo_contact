//
//  LoginViewController.m
//  contact
//
//  Created by Coffee on 14/11/16.
//  Copyright (c) 2014年 momo. All rights reserved.
//

#import "LoginViewController.h"
#import "APIRequest.h"
#import "MBProgressHUD.h"
#import "TAHttpOperation.h"
#import "AppDelegate.h"
#import "Token.h"
#import "MMCommonAPI.h"
#import "SVProgressHUD.h"
#import "UIImage+NGAdditions.h"
#import "LoginCheckVController.h"
#import "MainSynVController.h"

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag
#endif

@interface LoginViewController () <UITextFieldDelegate>
@property (strong, nonatomic) UITextField *phoneField;
@property (strong, nonatomic) UIButton *nextBtn;
@end

@implementation LoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.navigationItem.title = @"获取验证码";
    self.leftButton.hidden = YES;

    //手机号码
	UIImageView* backImage = [[UIImageView alloc] initWithFrame:CGRectMake(0, 30, 320, 50)] ;
	backImage.userInteractionEnabled = YES;
    backImage.backgroundColor = [UIColor whiteColor];
	_phoneField = [[UITextField alloc] initWithFrame: CGRectMake(20, 12, 280, 30)] ;
	_phoneField.borderStyle = UITextBorderStyleNone;
	_phoneField.textAlignment = NSTextAlignmentLeft;
    _phoneField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@" 输入手机号码" attributes:@{NSForegroundColorAttributeName: [UIColor colorWithRed:0.702f green:0.702f blue:0.702f alpha:1.00f], NSFontAttributeName: [UIFont systemFontOfSize:17]}];
    _phoneField.font = [UIFont systemFontOfSize:17];
    _phoneField.keyboardType = UIKeyboardTypePhonePad;
    _phoneField.clearButtonMode = UITextFieldViewModeWhileEditing;
    _phoneField.textColor = [UIColor blackColor];
    _phoneField.returnKeyType = UIReturnKeyDone;
    [_phoneField becomeFirstResponder];
    _phoneField.delegate = self;
	[backImage addSubview:_phoneField];
    [self.view addSubview:backImage];
    [_phoneField addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];

	self.nextBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    self.nextBtn.frame = CGRectMake(15, 138, 290, 48);
	[self.nextBtn setBackgroundImage: [UIImage imageWithStretchName:@"btn_green" top:20 left:5] forState:UIControlStateNormal];
    [self.nextBtn setBackgroundImage: [UIImage imageWithStretchName:@"btn_grey@" top:20 left:5] forState:UIControlStateDisabled];
    [self.nextBtn setBackgroundImage: [UIImage imageWithStretchName:@"btn_green_press" top:20 left:5] forState:UIControlStateHighlighted];
	[self.nextBtn setTitle:@"下一步" forState:UIControlStateNormal];
    [self.nextBtn addTarget:self action:@selector(actionLogin) forControlEvents:UIControlEventTouchUpInside];
    [self.nextBtn setEnabled:NO];
    [self.view addSubview: self.nextBtn];
}


- (void) textFieldDidChange:(id) sender {
    if ([_phoneField text].length == 11) {
        [self.nextBtn setEnabled:YES];
    }else {
        [self.nextBtn setEnabled:NO];
    }
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
//    if ([textField isEqual:_phoneField] && range.length == 1 && string.length == 0) {
//        //将号码的分割成 3 4 4的带空格间隔格式 当删除到空格的时候 不出发字符变化通知
//        if (textField.text.length == 4) {
//            textField.text = [textField.text substringWithRange:NSMakeRange(0, textField.text.length - 1)];
//
//            return NO;
//        }
//        if (textField.text.length == 9) {
//            textField.text = [textField.text substringWithRange:NSMakeRange(0, textField.text.length - 1)];
//            return NO;
//        }
//    }

    //增加char
    if ([textField isEqual:_phoneField] && range.length == 0 && string.length == 1) {
        if (textField.text.length >= 11) {
            return NO;
        }
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

- (void)actionLogin {
    NSString* phone = _phoneField.text;
    phone = [phone stringByReplacingOccurrencesOfString:@" " withString:@""];
	if ((phone.length != 11) || (![self checkTel:phone])) {
		[MMCommonAPI alert:@"号码格式错误"];
		return;
	}

    __weak typeof(self) weakSelf = self;
    [SVProgressHUD showWithStatus:@"获取中" maskType:SVProgressHUDMaskTypeBlack];
    [APIRequest requestVerifyCode:@"86" number:phone success:^(NSString *code){
        NSLog(@"code:%@", code);
        [SVProgressHUD dismiss];
        LoginCheckVController * ctrl = [[LoginCheckVController alloc] init];
        ctrl.phoneNumberStr = phone;
        [weakSelf.navigationController pushViewController:ctrl animated: YES];
    } fail:^{
        NSLog(@"获取验证码失败");
        [SVProgressHUD dismiss];
    }];

}

- (BOOL)checkTel:(NSString *)str
{
    //1[0-9]{10}
    //^((13[0-9])|(15[^4,\\D])|(18[0,5-9]))\\d{8}$
    //    NSString *regex = @"[0-9]{11}";
    NSString *regex = @"^((13[0-9])|(147)|(15[^4,\\D])|(18[0,5-9]))\\d{8}$";
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", regex];
    BOOL isMatch = [pred evaluateWithObject:str];
    if (!isMatch) {
        return NO;
    }
    return YES;
}

@end
