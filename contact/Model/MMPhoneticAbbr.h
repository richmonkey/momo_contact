//
//  MMPhoneticAbbr.h
//  Momo
//
//  Created by zdh on 5/13/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#ifndef _MMPHONETICABBR_H_
#define _MMPHONETICABBR_H_

#import <Foundation/Foundation.h>

typedef enum {
    MMPhoneticAbbrTypeAll,
    MMPhoneticAbbrTypePinyin,
    MMPhoneticAbbrTypeAbbr,
} MMPhoneticAbbrType;

@interface MMPhoneticAbbr : NSObject {
	
}

// 获得某字符串的拼音
+ (NSString *)getPinyin:(NSString *)sourceStringInput;

// 获得某字符串的拼音首字母
+ (NSString *)getPinyinAbbr:(NSString *)sourceString;

// 获得拼音的数字
+ (NSString *)get_key_num:(NSString *)nsstrEn;

// inner
+ (NSString *)_getPinyin:(NSString *)sourceString type:(MMPhoneticAbbrType)type;

// 获取字符对应的所有拼音
+ (NSArray *)getWordPinyin:(unichar)word;

+ (BOOL)contactMatch:(NSString*)contactName 
             pattern:(NSString*)pattern 
             isFuzzy:(BOOL)isFuzzy 
           isDigital:(BOOL)isDigital;

@end

#endif
