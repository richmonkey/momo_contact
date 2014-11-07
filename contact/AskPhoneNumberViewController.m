//
//  AskPhoneNumberViewController.m
//  Message
//
//  Created by 杨朋亮 on 14/9/14.
//  Copyright (c) 2014年 daozhu. All rights reserved.
//

#import "AskPhoneNumberViewController.h"
#import "APIRequest.h"
#import "MBProgressHUD.h"
#import "CheckVerifyCodeController.h"



@interface AskPhoneNumberViewController ()

@property (weak, nonatomic) IBOutlet UITextField *phoneTextField;
@property  (nonatomic)               UIBarButtonItem *nextButton;

@end

@implementation AskPhoneNumberViewController

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
    
    [self setTitle:@"您的电话号码"];
    self.nextButton = [[UIBarButtonItem alloc]
                                   initWithTitle:@"获取验证码"
                                   style:UIBarButtonItemStylePlain
                                   target:self
                                   action:@selector(nextAction)];
    [self.navigationItem setRightBarButtonItem:self.nextButton];
    [self.nextButton setEnabled:NO];
    
    [self.phoneTextField becomeFirstResponder];
    [self.phoneTextField addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
    // Do any additional setup after loading the view from its nib.
}

-(void)viewDidAppear:(BOOL)animated{
    [self.phoneTextField becomeFirstResponder];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


-(void) nextAction {
    NSString *number = self.phoneTextField.text;
    
    if (number.length != 11) return;
    
    if ([self checkTel:number]) {
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        [APIRequest requestVerifyCode:@"86" number:number success:^(NSString *code){
            NSLog(@"code:%@", code);
            [hud hide:YES];
            CheckVerifyCodeController * ctrl = [[CheckVerifyCodeController alloc] init];
            ctrl.phoneNumberStr = number;
            [self.navigationController pushViewController:ctrl animated: YES];
        } fail:^{
            NSLog(@"获取验证码失败");
            [hud hide:NO];
        }];
    }
    
}

- (void) textFieldDidChange:(id) sender {
    UITextField *_field = (UITextField *)sender;
    if ([_field text].length == 11) {
        [self.nextButton setEnabled:YES];
    }else if([_field text].length > 11){
        [self.nextButton setEnabled:NO];
    }else{
        [self.nextButton setEnabled:NO];
    }
}

#pragma mark - UITextFieldDelegate
- (void)textFieldDidBeginEditing:(UITextField *)textField{
    
}

- (void)textFieldDidEndEditing:(UITextField *)textField{

    
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
