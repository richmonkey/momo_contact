//
//  SearchPinyin.h
//  Momo
//
//  Created by zdh on 5/13/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#ifndef _SEARCH_PINYIN_H_
#define _SEARCH_PINYIN_H_

#import <Foundation/Foundation.h>

int compare2(const wchar_t *p1, const wchar_t **p2);

@interface SearchPinyin : NSObject {
	
}

// 获得汉字拼间
+(NSString*)queryPinyin:(wchar_t*)wstrChn;

// 获得某个汉字的拼音
+(NSString*)get_pinyin:(wchar_t*)wstrChn;

// 获得某字符串的拼音
+(NSString*)getPinyin:(NSString*)nsstrChn;



// 获得拼音的首字母
+(NSString*) get_pinyin_abbr:(wchar_t*)wstrChn;
// 获得某字符串的拼音首字母
+(NSString*) getPinyinAbbr:(NSString*)nsstrChn;



// 获得拼音的数字
+(NSString*) get_key_num:(NSString*)nsstrEn;

@end

#endif
