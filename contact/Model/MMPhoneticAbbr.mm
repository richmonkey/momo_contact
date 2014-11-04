//
//  MMPhoneticAbbr.m
//  Momo
//
//  Created by zdh on 5/13/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "MMPhoneticAbbr.h"
#import "DefineDictionary.h"
#import "pinyin.h"
#include <string>
#import <wchar.h>
#include <CoreFoundation/CoreFoundation.h>
#include "contact_match.h"

@implementation MMPhoneticAbbr

// Get the key pad number related to the name phonetic
+(NSString*) get_key_num:(NSString*)nsstr; {
    NSString *key_num = @"";
    
    if (!nsstr)
        return key_num;
	
	int len = [nsstr length];
	
	for ( int j = 0; j < len && j < 32; j++) {
        unichar ch = [nsstr characterAtIndex:j];

		if(('a' == ch) || ('b' == ch) || ('c' == ch))
            ch = '2';
		if(('d' == ch) || ('e' == ch) || ('f' == ch))
            ch = '3';
		if(('g' == ch) || ('h' == ch) || ('i' == ch))
            ch = '4';
		if(('j' == ch) || ('k' == ch) || ('l' == ch))
            ch = '5';
		if(('m' == ch) || ('n' == ch) || ('o' == ch))
            ch = '6';
		if(('p' == ch) || ('q' == ch) || ('r' == ch) || ('s' == ch))
            ch = '7';
		if(('t' == ch) || ('u' == ch) || ('v' == ch))
            ch = '8';
		if(('w' == ch) || ('x' == ch) || ('y' == ch) || ('z' == ch))
            ch = '9';
	    
		key_num = [key_num stringByAppendingFormat:@"%c", ch];
	}
	
	return key_num;
}

+ (NSString *)getPinyin:(NSString *)sourceStringInput {	
	
	NSString *sourceString = [sourceStringInput stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
	
	if (0 == [sourceString length]) {
		return @"";
	}
	
	
    int unicodesSize = ([sourceString length] + 1) * sizeof(wchar_t);
    wchar_t *unicode = (wchar_t *)malloc(unicodesSize);
	memset(unicode, 0x0, unicodesSize);
    
    CFStringRef str = CFStringCreateWithCString(NULL, [sourceString UTF8String], kCFStringEncodingUTF8);
    CFIndex length = CFStringGetLength(str);
    CFRange rangeToProcess = CFRangeMake(0, length);
    
    CFStringGetBytes(str, rangeToProcess, kCFStringEncodingUTF32, 0, FALSE, (UInt8 *)unicode, unicodesSize, NULL);

    std::wstring s = unicode;
    std::string pinyin = get_pinyin(s);
    NSString *result = [NSString stringWithFormat:@"%s", pinyin.c_str()];
    
    free(unicode);
    CFRelease(str);
    return result;
}

+ (NSString *)getPinyinAbbr:(NSString *)sourceString {
    if (0 == [sourceString length]) {
        return @"";
    }
    int unicodesSize = ([sourceString length] + 1) * sizeof(wchar_t);
    wchar_t *unicode = (wchar_t *)malloc(unicodesSize);
    
    CFStringRef str = CFStringCreateWithCString(NULL, [sourceString UTF8String], kCFStringEncodingUTF8);
    CFIndex length = CFStringGetLength(str);
    CFRange rangeToProcess = CFRangeMake(0, length);
    
    CFStringGetBytes(str, rangeToProcess, kCFStringEncodingUTF32, 0, FALSE, (UInt8 *)unicode, unicodesSize, NULL);
    
    std::wstring s = unicode;
    std::string pinyin = get_pinyin_abbr(s);
    NSString *result = [NSString stringWithFormat:@"%s", pinyin.c_str()];
    free(unicode);
    CFRelease(str);
    return result;
}

+ (NSString *)_getPinyin:(NSString *)sourceString type:(MMPhoneticAbbrType)type {
	if (sourceString == nil || sourceString.length == 0) {
		return [NSString stringWithFormat:@""];
	}
	
	NSMutableString *result = [NSMutableString stringWithFormat:@""];
	for (NSUInteger i = 0; i < sourceString.length; ++i) {
		unichar word = [sourceString characterAtIndex:i];
		NSArray *pinyins = [self getWordPinyin:word];
		if (pinyins == nil || pinyins.count == 0) {
			[result appendFormat:@"%C", word];
			continue;
		} 
		else {
			NSString *pinyin = [pinyins objectAtIndex:0];
			switch (type) {
				case MMPhoneticAbbrTypePinyin:
					[result appendFormat:@"%@", pinyin];
					break;
				case MMPhoneticAbbrTypeAbbr:
					[result appendFormat:@"%C", [pinyin characterAtIndex:0]];
				default:
					break;
			}
		}
	}
	return result;
}

+ (NSArray *)getWordPinyin:(unichar)word {
	if (word < 0x4e00 || word > 0x9fa5) {		//一:0x4e00 龥:9fa5
		return nil;
	}
	
	const char* p = pinyins_unicode[word - 0x4e00];
	NSString *pinyins = [NSString stringWithUTF8String:p];
	return [pinyins componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
}

+ (BOOL)contactMatch:(NSString*)contactName 
             pattern:(NSString*)pattern 
             isFuzzy:(BOOL)isFuzzy 
           isDigital:(BOOL)isDigital {
    #define MAX_NAME_LEN 8
    wchar_t contact_name_wide[MAX_NAME_LEN] = {0};
    CFIndex length = CFStringGetLength((CFStringRef)contactName);
    CFRange rangeToProcess = CFRangeMake(0, length);
    
    CFStringGetBytes((CFStringRef)contactName, rangeToProcess, kCFStringEncodingUTF32, 0, FALSE, (UInt8 *)contact_name_wide, sizeof(contact_name_wide), NULL);
    
    const char* szPattern = [pattern UTF8String];
    int score = contact_match(isFuzzy, contact_name_wide, szPattern, isDigital, NULL);
    return (score > 0);
}

@end
