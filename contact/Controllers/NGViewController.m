//
//  NGViewController.m
//  newgame
//
//  Created by shichangone on 6/5/14.
//  Copyright (c) 2014 ngds. All rights reserved.
//

#import "NGViewController.h"
#import "UIButton+NGAdditions.h"

@interface NGViewController ()

@end

@implementation NGViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    _leftButton = [UIButton buttonWithImageName:@"nav_back"];
    [_leftButton addTarget:self action:@selector(actionLeft) forControlEvents:UIControlEventTouchUpInside];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:_leftButton];

    _rightButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_rightButton setTitleColor:[UIColor colorWithRed:0.529f green:0.808f blue:0.749f alpha:1.00f] forState:UIControlStateDisabled];
    [_rightButton setTitleColor:[UIColor whiteColor] forState:UIControlStateDisabled];
    _rightButton.titleLabel.font = [UIFont systemFontOfSize:13];
    [_rightButton setFrame:CGRectMake(0, 5, 50, 44)];
    [_rightButton addTarget:self action:@selector(actionRight) forControlEvents:UIControlEventTouchUpInside];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:_rightButton];

    if ([self respondsToSelector:@selector(setEdgesForExtendedLayout:)]) {
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }

    //设置导航栏的颜色,不透明,且无底部的2个像素
    UINavigationBar *navigationBar = self.navigationController.navigationBar;
    [navigationBar setTranslucent:NO];
    [navigationBar setBackgroundImage:[UIImage new] forBarPosition:UIBarPositionAny barMetrics:UIBarMetricsDefault];
    [navigationBar setShadowImage:[UIImage new]];
    [self.navigationController.navigationBar setTranslucent:NO];
    [self.view setBackgroundColor:[UIColor colorWithRed:0.894f green:0.910f blue:0.918f alpha:1.00f]];
}


- (BOOL)shouldAutorotate {
    return NO;
}

#pragma mark - Public

-(void)actionLeft {
	[self.navigationController popViewControllerAnimated:YES];
}

- (void)actionRight {

}
#pragma mark - Private

@end
