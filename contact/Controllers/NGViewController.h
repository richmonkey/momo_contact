//
//  NGViewController.h
//  newgame
//
//  Created by shichangone on 6/5/14.
//  Copyright (c) 2014 ngds. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NGViewController : UIViewController

@property(nonatomic,retain)UIButton* leftButton;
@property(nonatomic,retain)UIButton* rightButton;
-(void)actionLeft;
-(void)actionRight;
@end
