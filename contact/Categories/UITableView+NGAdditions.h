//
//  UITableView+NGAdditions.h
//  newgame
//
//  Created by Coffee on 14-5-15.
//  Copyright (c) 2014年 ngds. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UITableView (NGAdditions)

@end

@interface UITableView (NGCreate)

+ (UITableView *)tableviewWithFrame:(CGRect)frame delegateAndDatasource:(id)sender;
@end
