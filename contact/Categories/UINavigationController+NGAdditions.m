//
//  UINavigationController+NGAdditions.m
//  newgame
//
//  Created by Coffee on 14-7-7.
//  Copyright (c) 2014年 ngds. All rights reserved.
//

#import "UINavigationController+NGAdditions.h"

@implementation UINavigationController (NGAdditions)

-(BOOL)shouldAutorotate {
    return [[self.viewControllers lastObject] shouldAutorotate];
}

-(NSUInteger)supportedInterfaceOrientations {
    return [[self.viewControllers lastObject] supportedInterfaceOrientations];
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    return [[self.viewControllers lastObject] preferredInterfaceOrientationForPresentation];
}
@end

