//
//  MMServerContactManager.m
//  momo
//
//  Created by houxh on 11-7-6.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "MMServerContactManager.h"
#import "MMUapRequest.h"
#import "SBJSON.h"
#import "ASIHTTPRequest.h"
#import "MMCommonAPI.h"
#import "oauth.h"
#import "MMGlobalData.h"


@implementation MMServerContactManager


+(NSString*)getOriginUrl:(NSString*)md5 {
    NSMutableDictionary *dic = [NSMutableDictionary dictionary];
    [dic setObject:[NSArray arrayWithObject:md5] forKey:@"md5"];
    [dic setObject:[NSNumber numberWithInt:0] forKey:@"size"];

    ASIHTTPRequest *request = [ASIHTTPRequest requestWithPath:@"photo/origin.json" withObject:dic];
    [ASIHTTPRequest startSynchronous:request];
    if ([request responseStatusCode] != 200) {
        return nil;
    }
    NSArray *array = [request responseObject];
    if ([array count] == 0) {
        return nil;
    }
    return [[array objectAtIndex:0] objectForKey:@"src"];
}

+(BOOL)uploadAvatar:(NSData*)imgData url:(NSString**)url {
    assert(url);
	if (nil == imgData) {
		*url = @"";
		return YES;
	}
	NSString* md5 = [MMUapRequest data_md5:imgData];
	NSString *originUrl = [self getOriginUrl:md5];
    if (originUrl && [originUrl length] > 0) {
        *url = [[originUrl retain] autorelease];
        return YES;
    }
    *url = [MMUapRequest uploadPhoto:imgData];
    if (nil == *url) {
        return NO;
    }
    return YES;
}

+(BOOL)getContactCount:(int*)count {
    NSDictionary *response = nil;
	NSInteger statusCode = [MMUapRequest getSync:@"contact/count.json" jsonValue:&response compress:YES];
	if (statusCode != 200 || !response) {
		return NO;
	}
    if ([response objectForKey:@"all_count"] && count != NULL) {
        *count = [[response objectForKey:@"all_count"] intValue];
        return YES;
    }
    return NO;
}

+(NSArray*)getSimpleContactList {
	NSArray *response = nil;
	NSInteger statusCode = [MMUapRequest getSync:@"contact.json?contact_group_id=all&info=0" jsonValue:&response compress:YES];
	if (statusCode != 200 || !response) {
		return nil;
	}
	NSMutableArray *array = [NSMutableArray array];
	for (NSDictionary *dic in response) {
		MMMomoContactSimple *c = [[[MMMomoContactSimple alloc] init] autorelease];
		c.contactId = [[dic objectForKey:@"id"] intValue];
		c.modifyDate = [[dic objectForKey:@"modified_at"] longLongValue];
		[array addObject:c];
	}
	return array;
}
+(NSArray*)getContactListUp100:(NSArray *)ids {
	assert([ids count] <= 100);
	if ([ids count] == 0) {
		return nil;
	}

	NSMutableString *str = [NSMutableString string];
	for (NSNumber *n in ids) {
		if ([str length] > 0) {
			[str appendString:@","];
		}
		[str appendFormat:@"%d", [n intValue]];
	}
	NSDictionary *dic = [NSDictionary dictionaryWithObject:str forKey:@"ids"];
	
	NSArray *response = nil;
	NSInteger statusCode = [MMUapRequest postSync:@"contact/show_batch.json" withObject:dic jsonValue:&response];
	if (statusCode != 200) {
		return nil;
	}
	NSMutableArray *array = [NSMutableArray array];
	for (NSDictionary *dic in response) {
//        NSLog(@"add contact:%@",dic);
		MMMomoContact *contact = [self decodeContact:dic];
		[array addObject:contact];
	}
	return array; 
}
+(NSArray*)getContactList:(NSArray*)ids {
	NSMutableArray *array = [NSMutableArray array];
	for (unsigned int i = 0; i < [ids count]; i+= 100) {
		int len = (int)MIN(100, [ids count] - i);
		NSArray *tmp = [self getContactListUp100:[ids subarrayWithRange:NSMakeRange(i, len)]];
		[array addObjectsFromArray:tmp];
	}
	return array;
}

+(NSString*)getImProtocol:(NSInteger)property {
	switch (property) {
		case kMoIm91U:return @"91u";
		case kMoImQQ:return @"qq";
		case kMoImMSN:return @"msn";
		case kMoImICQ:return @"icq";
		case kMoImGtalk:return @"gtalk";			
		case kMoImYahoo:return @"yahoo";
		case kMoImSkype:return @"skype";
		case kMoImAIM:return @"aim";
		case kMoImJabber:return @"jabber";
		default:
			assert(0);
			break;
	}
	return nil;
}
+(int)getImProperty:(NSString*)protocol {
	if ([protocol isEqualToString:@"91u"]) {
		return kMoIm91U;
	} else if ([protocol isEqualToString:@"qq"] ) {
		return kMoImQQ;
	} else if ([protocol isEqualToString:@"msn"]) {
		return kMoImMSN;
	} else if ([protocol isEqualToString:@"icq"]) {
		return kMoImICQ;
	} else if ([protocol isEqualToString:@"gtalk"]) {
		return kMoImGtalk;
	} else if ([protocol isEqualToString:@"yahoo"]) {
		return kMoImYahoo;
	} else if ([protocol isEqualToString:@"skype"]) {
		return kMoImSkype;
	} else if ([protocol isEqualToString:@"aim"]) {
		return kMoImAIM;
	} else if ([protocol isEqualToString:@"jabber"]) {
		return kMoImJabber;
	} else {
		assert(0);
	}

	return 0;
}

+(NSDictionary*)encodeContact:(MMFullContact *)contact {
	NSMutableDictionary *dic = [NSMutableDictionary dictionary];
	[dic setObject:[NSNumber numberWithLongLong:contact.contactId] forKey:@"id"];
	[dic setObject:PARSE_NULL_STR(contact.lastName) forKey:@"family_name"];
	[dic setObject:PARSE_NULL_STR(contact.firstName) forKey:@"given_name"];
	[dic setObject:PARSE_NULL_STR(contact.middleName) forKey:@"middle_name"];
	[dic setObject:PARSE_NULL_STR(contact.nickName) forKey:@"nickname"];
	
	if (contact.birthday) {
		[dic setObject:[MMCommonAPI getStingByDate:contact.birthday] forKey:@"birthday"];
	}
    
	[dic setObject:PARSE_NULL_STR(contact.organization) forKey:@"organization"];
	[dic setObject:PARSE_NULL_STR(contact.department) forKey:@"department"];
	[dic setObject:PARSE_NULL_STR(contact.jobTitle) forKey:@"title"];
	[dic setObject:PARSE_NULL_STR(contact.note) forKey:@"note"];
    
	[dic setObject:[NSNumber numberWithLongLong:contact.modifyDate] forKey:@"modified_at"];
    if (contact.avatarB64.length < (128*1024*4/3)) {
        [dic setObject:PARSE_NULL_STR(contact.avatarB64) forKey:@"avatar_b64"];
    }
    
	NSMutableArray *addressArray = [NSMutableArray array];
	NSMutableArray *imArray = [NSMutableArray array];
	
	NSMutableArray *emailArray = [NSMutableArray array];
	NSMutableArray *telArray = [NSMutableArray array];
	NSMutableArray *urlArray = [NSMutableArray array];
	NSMutableArray *personArray = [NSMutableArray array];
	NSMutableArray *bdayArray = [NSMutableArray array];
	for (DbData *property in contact.properties) {
		switch(property.property) {
			case kMoMail:
			{
            NSMutableDictionary *propertyDic = [NSMutableDictionary dictionary];
            [propertyDic setObject:PARSE_NULL_STR(property.label) forKey:@"type"];
            [propertyDic setObject:PARSE_NULL_STR(property.value) forKey:@"value"];
            [emailArray addObject:propertyDic];
			}
				break;
			case kMoUrl:
			{
            NSMutableDictionary *propertyDic = [NSMutableDictionary dictionary];
            [propertyDic setObject:PARSE_NULL_STR(property.label) forKey:@"type"];
            [propertyDic setObject:PARSE_NULL_STR(property.value) forKey:@"value"];
            [urlArray addObject:propertyDic];
			}
				break;
			case kMoTel:
			{
            NSMutableDictionary *propertyDic = [NSMutableDictionary dictionary];
            if (property.isMainTelephone) {
                [propertyDic setObject:[NSNumber numberWithBool:YES] forKey:@"pref"];
                //[propertyDic setObject:@"cell" forKey:@"type"];
                [propertyDic setObject:PARSE_NULL_STR(property.label) forKey:@"type"];
            } else {
                [propertyDic setObject:PARSE_NULL_STR(property.label) forKey:@"type"];
            }
            
            [propertyDic setObject:PARSE_NULL_STR(property.value) forKey:@"value"];
            [telArray addObject:propertyDic];
			}
				break;
			case kMoPerson:
			{
            NSMutableDictionary *propertyDic = [NSMutableDictionary dictionary];
            [propertyDic setObject:PARSE_NULL_STR(property.label) forKey:@"type"];
            [propertyDic setObject:PARSE_NULL_STR(property.value) forKey:@"value"];
            [personArray addObject:propertyDic];
			}
				break;
			case kMoBday:
			{
            NSMutableDictionary *propertyDic = [NSMutableDictionary dictionary];
            [propertyDic setObject:PARSE_NULL_STR(property.label) forKey:@"type"];
            [propertyDic setObject:PARSE_NULL_STR(property.value) forKey:@"value"];
            [bdayArray addObject:propertyDic];
			}
				break;
			case kMoIm91U:
			case kMoImQQ:
			case kMoImMSN:
			case kMoImICQ:
			case kMoImGtalk:
			case kMoImYahoo:
			case kMoImSkype:
			case kMoImAIM:
			case kMoImJabber:
			{
            NSMutableDictionary *propertyDic = [NSMutableDictionary dictionary];
            [propertyDic setObject:[self getImProtocol:property.property] forKey:@"protocol"];
            [propertyDic setObject:PARSE_NULL_STR(property.label) forKey:@"type"];
            [propertyDic setObject:PARSE_NULL_STR(property.value) forKey:@"value"];
            [imArray addObject:propertyDic];
			}
				break;
                
			case kMoAdr:
			{
            NSMutableDictionary *propertyDic = [NSMutableDictionary dictionary];
            NSString *country = nil;
            NSString *region = nil;
            NSString *city = nil;
            NSString *street = nil;
            NSString *postal = nil;
            [DbData ParseAddressValue:property.value country:&country region:&region city:&city street:&street postal:&postal];
            [propertyDic setObject:property.label forKey:@"type"];
            [propertyDic setObject:country forKey:@"country"];
            [propertyDic setObject:region forKey:@"region"];
            [propertyDic setObject:city forKey:@"city"];
            [propertyDic setObject:street forKey:@"street"];
            [propertyDic setObject:postal forKey:@"postal"];
            [addressArray addObject:propertyDic];
			}
				break;
			default:
				break;
		}
	}
	if ([addressArray count] > 0) {
		[dic setObject:addressArray forKey:@"addresses"];
	}
	if ([imArray count] > 0) {
		[dic setObject:imArray forKey:@"ims"];
	}
	if ([emailArray count] > 0) {
		[dic setObject:emailArray forKey:@"emails"];
	}
	if ([telArray count] > 0) {
		[dic setObject:telArray forKey:@"tels"];
	}
	if ([urlArray count] > 0) {
		[dic setObject:urlArray forKey:@"urls"];
	}
	if ([personArray count] > 0) {
		[dic setObject:personArray forKey:@"relations"];
	}
	if ([bdayArray count] > 0) {
		[dic setObject:bdayArray forKey:@"events"];
	}
    
	return dic;
}

+(MMMomoContact*)decodeContact:(NSDictionary*)dic {
	
	MMMomoContact *contact = [[[MMMomoContact alloc] init] autorelease];
	
	contact.contactId = [[dic objectForKey:@"id"] intValue];
	if (contact.contactId > 0) {
		
		contact.lastName = PARSE_NULL_STR([dic objectForKey:@"family_name"]);
		contact.firstName = PARSE_NULL_STR([dic objectForKey:@"given_name"]);
		contact.middleName = PARSE_NULL_STR([dic objectForKey:@"middle_name"]);
		contact.nickName = PARSE_NULL_STR([dic objectForKey:@"nickname"]);
		contact.department = PARSE_NULL_STR([dic objectForKey:@"department"]);
		contact.jobTitle = PARSE_NULL_STR([dic objectForKey:@"title"]);

	}

	contact.birthday = [MMCommonAPI getDateBySting:[dic objectForKey:@"birthday"]];
	contact.organization = [dic objectForKey:@"organization"];
	
	
	contact.note = [dic objectForKey:@"note"];

	contact.modifyDate = [[dic objectForKey:@"modified_at"] longLongValue];
    contact.avatarB64 = [dic objectForKey:@"avatar_b64"];
        
	NSMutableArray *properties = [NSMutableArray array];
	for (NSDictionary *propertyDic in [dic objectForKey:@"tels"]) {
		DbData *property = [[[DbData alloc] init] autorelease];

		property.property = kMoTel;
		property.label = [propertyDic objectForKey:@"type"];
		property.value = [propertyDic objectForKey:@"value"];
        if ([[propertyDic objectForKey:@"pref"] boolValue]) {
            property.isMainTelephone = YES;
        }
		[properties addObject:property];
	}
	for (NSDictionary *propertyDic in [dic objectForKey:@"emails"]) {
		DbData *property = [[[DbData alloc] init] autorelease];
		property.property = kMoMail;
		property.label = [propertyDic objectForKey:@"type"];
		property.value = [propertyDic objectForKey:@"value"];
		[properties addObject:property];
	}
	
	for (NSDictionary *propertyDic in [dic objectForKey:@"urls"]) {
		DbData *property = [[[DbData alloc] init] autorelease];
		property.property = kMoUrl;
		property.label = [propertyDic objectForKey:@"type"];
		property.value = [propertyDic objectForKey:@"value"];
		[properties addObject:property];
	}
	
	for (NSDictionary *propertyDic in [dic objectForKey:@"relations"]) {
		DbData *property = [[[DbData alloc] init] autorelease];
		property.property = kMoPerson;
		property.label = [propertyDic objectForKey:@"type"];
		property.value = [propertyDic objectForKey:@"value"];
		[properties addObject:property];
	}
	
	for (NSDictionary *propertyDic in [dic objectForKey:@"events"]) {
		DbData *property = [[[DbData alloc] init] autorelease];
		property.property = kMoBday;
		property.label = [propertyDic objectForKey:@"type"];
		property.value = [propertyDic objectForKey:@"value"];
		[properties addObject:property];
	}
	
	for (NSDictionary *propertyDic in [dic objectForKey:@"addresses"]) {
		DbData *property = [[[DbData alloc] init] autorelease];
		property.property = kMoAdr;
		NSString *postal = [propertyDic objectForKey:@"postal"];
		NSString *country = [propertyDic objectForKey:@"country"];
		NSString *region = [propertyDic objectForKey:@"region"];
		NSString *city = [propertyDic objectForKey:@"city"];
		NSString *street = [propertyDic objectForKey:@"street"];
		property.value = [DbData AddressValue:country region:region city:city 
									   street:street postal:postal];
		property.label = [propertyDic objectForKey:@"type"];
		[properties addObject:property];
	}
	
	for (NSDictionary *propertyDic in [dic objectForKey:@"ims"]) {
		DbData *property = [[[DbData alloc] init] autorelease];
		property.property = [self getImProperty:[propertyDic objectForKey:@"protocol"]];
		property.label = [propertyDic objectForKey:@"type"];
		property.value = [propertyDic objectForKey:@"value"];
		[properties addObject:property];
	}
	contact.properties = properties;
	return contact;
}





+(NSInteger)addContacts:(NSArray*)contacts response:(NSArray**)response {
	NSMutableArray *array = [NSMutableArray array];
	for (MMMomoContact *contact in contacts ) {
		NSDictionary *dic = [self encodeContact:contact];
		[array addObject:dic];
	}
	NSDictionary *dic = [NSDictionary dictionaryWithObject:array forKey:@"data"];
	NSInteger statusCode = [MMUapRequest postSync:@"contact/create_batch.json" withObject:dic jsonValue:response];
    return statusCode;
}

+(NSInteger)addContact:(MMMomoContact*)contact response:(NSDictionary**)res {
	NSArray *array = [NSArray arrayWithObject:contact];
	NSArray *response = nil;
	NSInteger statusCode = [self addContacts:array response:&response];
	if (statusCode != 200) {
		return statusCode;
	}
	assert([response count] == 1);
	*res = [response objectAtIndex:0];
	return statusCode;
}
+(NSInteger)updateContact:(MMMomoContact*)contact response:(NSDictionary**)response{
//    NSLog(@"update contactId:%d",contact.contactId);
//    NSLog(@"update name:%@",contact.fullName);
    
	NSDictionary *dic = [self encodeContact:contact];
	NSString *request = [NSString stringWithFormat:@"contact/update/%lld.json", contact.contactId];
	return [MMUapRequest postSync:request withObject:dic jsonValue:response];
}

+(BOOL)deleteContacts:(NSArray*)contactIds {
	if ([contactIds count] == 0) {
		return YES;
	}
	NSMutableString *str = [NSMutableString string];
	for (NSNumber *n in contactIds) {
		if ([str length] > 0) {
			[str appendString:@","];
		}
		[str appendFormat:@"%d", [n intValue]];
	}
	NSDictionary *dic = [NSDictionary dictionaryWithObject:str forKey:@"ids"];
	id response = nil;
	NSInteger statusCode = [MMUapRequest postSync:@"contact/destroy_batch.json" withObject:dic jsonValue:&response];
	if (statusCode != 200) {
		return NO;
	}
	return YES;
}

+(BOOL)deleteContacts:(NSArray*)contactIds response:(NSArray**)response {
	if ([contactIds count] == 0) {
		return YES;
	}
	NSMutableString *str = [NSMutableString string];
	for (NSNumber *n in contactIds) {
		if ([str length] > 0) {
			[str appendString:@","];
		}
		[str appendFormat:@"%d", [n intValue]];
	}
	NSDictionary *dic = [NSDictionary dictionaryWithObject:str forKey:@"ids"];
	NSInteger statusCode = [MMUapRequest postSync:@"contact/destroy_batch.json" withObject:dic jsonValue:response];
	if (statusCode != 200) {
		return NO;
	}
	return YES;
}


+(NSInteger)deleteContact:(int64_t)contactId {
	NSDictionary *dic = [NSDictionary dictionaryWithObject:[NSString stringWithFormat:@"%lld", contactId] forKey:@"ids"];
	NSArray *response = nil;
	NSInteger statusCode = [MMUapRequest postSync:@"contact/destroy_batch.json" withObject:dic jsonValue:&response];
	if (statusCode != 200) {
		NSDictionary *dic = (NSDictionary*)response;
		NSString *error = [dic objectForKey:@"error"];
		if (error) {
			error = [error substringToIndex:6];
			return [error intValue];
		} else {
			return statusCode;
		}
	}
	assert([response count] == 1);
	dic = [response objectAtIndex:0];
	statusCode = [[dic objectForKey:@"status"] intValue];
	if (statusCode != 200) {
		return statusCode;
	}
	return 0;
}

+(NSArray*)addContactStarState:(NSArray*)contactIds {
	if ([contactIds count] == 0) {
		return nil;
	}
	NSMutableString *str = [NSMutableString string];
	for (NSNumber *n in contactIds) {
		if ([str length] > 0) {
			[str appendString:@","];
		}
		[str appendFormat:@"%d", [n intValue]];
	}
	NSDictionary *dic = [NSDictionary dictionaryWithObject:str forKey:@"ids"];
	NSArray *value = nil;
	NSInteger statusCode = [MMUapRequest postSync:@"contact/favorite_batch.json" withObject:dic jsonValue:&value];
	if (statusCode != 200) {
		return nil;
	}
	return value;
}

+(NSArray*)removeContactStarState:(NSArray*)contactIds {
	if ([contactIds count] == 0) {
		return nil;
	}
	NSMutableString *str = [NSMutableString string];
	for (NSNumber *n in contactIds) {
		if ([str length] > 0) {
			[str appendString:@","];
		}
		[str appendFormat:@"%d", [n intValue]];
	}
	NSDictionary *dic = [NSDictionary dictionaryWithObject:str forKey:@"ids"];
	NSArray *value = nil;
	NSInteger statusCode = [MMUapRequest postSync:@"contact/remove_favorite_batch.json" withObject:dic jsonValue:&value];
	if (statusCode != 200) {
		return nil;
	}
	return value;
}

+ (NSArray*)getContactChangeHistory:(int)page withErrorString:(NSString**)errorString {
    NSString* requestUrl = [NSString stringWithFormat:@"contact/get_history.json?page=%d&page_size=100", page];
    
    NSArray *arrayValue = nil;
    NSInteger statusCode = [MMUapRequest getSync:requestUrl jsonValue:&arrayValue compress:YES];
    if (statusCode != 200 || !arrayValue) {
        *errorString = @"获取联系人变更历史失败";
        return nil;
    }
    
    NSMutableArray* retArray = [NSMutableArray array];
    for (NSDictionary* dict in arrayValue) {
        MMContactChangeInfo* changeInfo = [[[MMContactChangeInfo alloc] initWithDictionary:dict] autorelease];
        [retArray addObject:changeInfo];
    }
    
    return retArray;
}

+ (BOOL)recoverContactChangeHistory:(int)dateLine {
    NSDictionary* dict = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:dateLine] forKey:@"dateline"];
    NSDictionary* retDict = nil;
    NSInteger statusCode = [MMUapRequest postSync:@"contact/recover_history.json" withObject:dict jsonValue:&retDict];
    if (statusCode != 200) {
        return NO;
    }
    return YES;
}

@end

