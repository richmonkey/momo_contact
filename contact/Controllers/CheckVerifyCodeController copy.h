//
//  CheckVerifyCodeController.h
//  Message
//
//  Created by 杨朋亮 on 14/9/14.
//  Copyright (c) 2014年 daozhu. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>
#import "NGViewController.h"
@interface CheckVerifyCodeController : NGViewController <UITextFieldDelegate>

@property (nonatomic) NSString *phoneNumberStr;

@end
