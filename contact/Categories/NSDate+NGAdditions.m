//
//  NSDate+NGAdditions.m
//  newgame
//
//  Created by shichangone on 16/4/14.
//  Copyright (c) 2014 ngds. All rights reserved.
//

#import "NSDate+NGAdditions.h"

@implementation NSDate (NGAdditions)

- (NSDateComponents *)dateComponentsDate
{
    NSUInteger components = (NSDayCalendarUnit | NSMonthCalendarUnit | NSYearCalendarUnit);
    return [self dateComponents:components];
}

- (NSDateComponents *)dateComponents:(NSUInteger)components
{
    return [[NSCalendar currentCalendar] components:components fromDate:self];
}

- (NSInteger)year
{
    return [self dateComponentsDate].year;
}

- (NSInteger)month{
    return [self dateComponentsDate].month;
}

- (NSInteger)day {
    return [self dateComponentsDate].day;
}

@end
