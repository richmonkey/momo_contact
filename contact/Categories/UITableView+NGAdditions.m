//
//  UITableView+NGAdditions.m
//  newgame
//
//  Created by Coffee on 14-5-15.
//  Copyright (c) 2014年 ngds. All rights reserved.
//

#import "UITableView+NGAdditions.h"

@implementation UITableView (NGAdditions)

@end


@implementation UITableView (NGCreate)
//通用列表风格
+ (UITableView *)tableviewWithFrame:(CGRect)frame delegateAndDatasource:(id)sender {
    UITableView *tableView = [[UITableView alloc] initWithFrame:frame style:UITableViewStylePlain];
    tableView.delegate = sender;
    tableView.dataSource = sender;
    tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
	tableView.backgroundColor = [UIColor clearColor];
	tableView.backgroundView  = nil;
	tableView.tableFooterView = [[UIView alloc] init] ;
	tableView.showsVerticalScrollIndicator = NO;

    return tableView;
}
@end