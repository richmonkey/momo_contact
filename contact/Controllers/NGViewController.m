//
//  NGViewController.m
//  newgame
//
//  Created by shichangone on 6/5/14.
//  Copyright (c) 2014 ngds. All rights reserved.
//

#import "NGViewController.h"

@interface NGViewController ()

@end

@implementation NGViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    _leftButton = [UIButton buttonWithImageName:@"nav_back"];
    [_leftButton addTarget:self action:@selector(actionLeft) forControlEvents:UIControlEventTouchUpInside];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:_leftButton];

    if ([self respondsToSelector:@selector(setEdgesForExtendedLayout:)]) {
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }

    //设置导航栏的颜色,不透明,且无底部的2个像素
    UINavigationBar *navigationBar = self.navigationController.navigationBar;
    [navigationBar setTranslucent:NO];
    [navigationBar setBackgroundImage:[UIImage new] forBarPosition:UIBarPositionAny barMetrics:UIBarMetricsDefault];
    [navigationBar setShadowImage:[UIImage new]];
    [self.navigationController.navigationBar setTranslucent:NO];
    [self.view setBackgroundColor:VIEWCONTROLLER_BACK_COLOR];
}

//- (void)viewDidAppear:(BOOL)animated
//{
//    [super viewDidAppear:animated];
//
//    // Disable iOS 7 back gesture
//    __weak typeof(self) weakSelf = self;
//    if ([self.navigationController respondsToSelector:@selector(interactivePopGestureRecognizer)]) {
//        self.navigationController.interactivePopGestureRecognizer.enabled = NO;
//    }
//}
//-(NSUInteger)supportedInterfaceOrientations
//{
//    return UIInterfaceOrientationMaskPortrait;
//}
- (BOOL)shouldAutorotate {
    return NO;
}
//
//-(NSUInteger)supportedInterfaceOrientations
//{
//    return UIInterfaceOrientationMaskLandscapeLeft;
//}
//
//- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
//{
//    NSLog(@"preferredInterfaceOrientationForPresentation");
//    return UIInterfaceOrientationPortrait;
//}

//- (void)setSwipeBack:(BOOL)swipeBack {
//    _swipeBack = swipeBack;
//
//    __weak typeof(self) weakSelf = self;
//    if (swipeBack) {
//        if (!_swipeBackGesture) {
//            _swipeBackGesture = [[UISwipeGestureRecognizer alloc] bk_initWithHandler:^(UIGestureRecognizer *sender, UIGestureRecognizerState state, CGPoint location) {
//                [weakSelf actionLeft];
//            }];
//            _swipeBackGesture.direction = UISwipeGestureRecognizerDirectionRight;
//            [self.view addGestureRecognizer:_swipeBackGesture];
//        }
//    } else {
//        [self.view removeGestureRecognizer:_swipeBackGesture];
//    }
//}

#pragma mark - Public

-(void)actionLeft {
    [SVProgressHUD dismiss];
	[self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - Private

@end
