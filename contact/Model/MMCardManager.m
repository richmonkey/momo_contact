//
//  MMCardManager.m
//  momo
//
//  Created by  on 12-5-25.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "MMCardManager.h"
#import "SBJson.h"
#import "MMGlobalDefine.h"
#import "MMLogger.h"
#import "MMCommonAPI.h"
#import "MMMomoUserMgr.h"
#import "MMUapRequest.h"

@interface MMCardManager () 

@property (nonatomic, retain) NSMutableDictionary* numberUidCacheDic;

- (BOOL)loadNumberAndUID;

- (NSDictionary*)getAllCard;

@end

@implementation MMCardManager
@synthesize numberUidCacheDic;

+ (id)instance {
	static id _instance = nil;
    @synchronized(self) {
        if(_instance == nil) 
            _instance = [[self class] new];
    }
    return _instance;
}

- (id)init {
	if (self = [super init]) {
		numberUidCacheDic = [[NSMutableDictionary alloc] init];
        [self loadNumberAndUID];
	}
	return self;
}

- (void)dealloc {
	[numberUidCacheDic release];
	[super dealloc];
}

- (NSMutableDictionary*)numberUidCacheDic {
    if ([NSThread isMainThread]) {
        return numberUidCacheDic;
    } else {
        return [NSMutableDictionary dictionaryWithDictionary:numberUidCacheDic];
    }
}

#pragma mark momo名片 momo_card
- (BOOL)saveCard:(MMCard *)card {
	//有效期两天 暂定
	NSDate *expiredDate = [NSDate dateWithTimeIntervalSinceNow:2*24*60*60];
	
	NSDictionary *cardDic = [MMCardManager encodeCard:card];
    //	NSLog(@"encodeCard:%@",cardDic);
    
	NSString *sql = @"REPLACE INTO momo_card (uid, extend_json, expired_date) VALUES (?, ?, ?)";
	
	SBJSON *json = [[[SBJSON alloc] init] autorelease];
	NSString *extendStr = [json stringWithObject:cardDic];
	
	if (![[self db] executeUpdate:sql, 
		  [NSNumber numberWithInteger:card.uid], 
		  PARSE_NULL_STR(extendStr),
		  [NSNumber numberWithInt:[expiredDate timeIntervalSince1970]]]) {
        
		return NO;
	}
	return YES;
}

- (BOOL)deleteCard:(NSInteger)uid {
	NSString* sql = @"DELETE FROM momo_card WHERE uid = ? ";
	
	if(![[self db]  executeUpdate:sql, 
		 [NSNumber numberWithInteger:uid]]) {
        
		return NO;
	}
	return YES;
}

- (MMCard *)getCardByUid:(NSInteger)uid {
	NSError *outError = nil;
	MMCard *card = nil;
	NSString *sql = [NSString stringWithFormat:@"SELECT * FROM momo_card WHERE uid = %d",uid] ;
	
	id<PLResultSet> results = [[self db] executeQueryAndReturnError:&outError statement:sql];
	if(SQLITE_OK != [outError code]) {
		return nil;
	}
	PLResultSetStatus status = [results nextAndReturnError:nil];
	if(status) {
		int64_t expiredDate = 0;			
		if (![results isNullForColumn:@"expired_date"]) {
			expiredDate = [results bigIntForColumn:@"expired_date"];
		}
		NSString *extendStr = [results stringForColumn:@"extend_json"];
		SBJSON *json = [[[SBJSON alloc] init] autorelease];        
		NSDictionary *cardDic = [json objectWithString:extendStr];
		
		if (cardDic && (expiredDate >= [[NSDate date] timeIntervalSince1970])) {
			card = [MMCardManager decodeCard:cardDic];
		} else {
			card = nil;
		}
	}
	[results close];
	
	return card;
}

- (NSDictionary*)getAllCard {
    NSError *outError = nil;
	
	NSString *sql = [NSString stringWithFormat:@"SELECT * FROM momo_card"];
	
	id<PLResultSet> results = [[self db] executeQueryAndReturnError:&outError statement:sql];
	if(SQLITE_OK != [outError code]) {
		return nil;
	}
    
    NSMutableDictionary* retDict = [NSMutableDictionary dictionary];
	PLResultSetStatus status = [results nextAndReturnError:nil];
	while (status == PLResultSetStatusRow) {
        MMCard* card = nil;
        
        int64_t expiredDate = 0;			
		if (![results isNullForColumn:@"expired_date"]) {
			expiredDate = [results bigIntForColumn:@"expired_date"];
		}
        
		NSString *extendStr = [results stringForColumn:@"extend_json"];
		SBJSON *json = [[[SBJSON alloc] init] autorelease];        
		NSDictionary *cardDic = [json objectWithString:extendStr];
		
		if (cardDic && (expiredDate >= [[NSDate date] timeIntervalSince1970])) {
			card = [MMCardManager decodeCard:cardDic];
            [retDict setObject:card forKey:[NSNumber numberWithInt:card.uid]];
		}
        
        status = [results nextAndReturnError:nil];
	}
	[results close];
    
    return retDict;
}

//判断是否存在uid对应名片，以后再加是否更新名片（要有修改名片时间撮）
- (BOOL)hasUid:(NSInteger)uid {
	NSInteger count = 0;
	NSError *outError = nil;
	
	NSString *sql = [NSString stringWithFormat:@"SELECT COUNT(uid) count FROM momo_card WHERE uid = %d",uid];
	
	id<PLResultSet> results = [[self db] executeQueryAndReturnError:&outError statement:sql];
	if(SQLITE_OK != [outError code]) {
		return NO;
	}
	PLResultSetStatus status = [results nextAndReturnError:nil];
	if(status) {
		count = [results intForColumn:@"count"];
	}
	[results close];
	
	if (count) {
		return YES;
	} else {
		return NO;
	}	
}

- (int64_t)getExpiredDate:(NSInteger)uid {
	
	int64_t expiredDate = 0;
	NSError *outError = nil;
    
	NSString *sql = [NSString stringWithFormat:@"SELECT expired_date FROM momo_card WHERE uid = %d",uid];
    
	id<PLResultSet> results = [[self db] executeQueryAndReturnError:&outError statement:sql];
	if(SQLITE_OK != [outError code]) {
        return NO;
	}
	PLResultSetStatus status = [results nextAndReturnError:nil];
	if(status) {
        
		if (![results isNullForColumn:@"expired_date"]) {
			expiredDate = [results bigIntForColumn:@"expired_date"];
		}
	}
	[results close];
	
	return expiredDate;	
}	

#pragma mark momo名片 number_uid Db操作
//对外用 momo_card
- (MMCard *)getCardByNumber:(NSString *)number {
	
	NSError *outError = nil;
	MMCard *card = nil;
	NSString *sql = [NSString stringWithFormat:@"SELECT momo_card.* FROM momo_card, number_uid WHERE momo_card.uid = number_uid.uid and number = '%@'",number];
	
	id<PLResultSet> results = [[self db] executeQueryAndReturnError:&outError statement:sql];
	if(SQLITE_OK != [outError code]) {
		return nil;
	}
	PLResultSetStatus status = [results nextAndReturnError:nil];
	if(status) {
		
		int64_t expiredDate = 0;			
		if (![results isNullForColumn:@"expired_date"]) {
			expiredDate = [results bigIntForColumn:@"expired_date"];
		}
		
		NSString *extendStr = [results stringForColumn:@"extend_json"];
		SBJSON *json = [[[SBJSON alloc] init] autorelease];        
		NSDictionary *cardDic = [json objectWithString:extendStr];
		
		if (cardDic && (expiredDate >= [[NSDate date] timeIntervalSince1970])) {
			card = [MMCardManager decodeCard:cardDic];
		} else {
			card = nil;
		}
	}
	[results close];
	
	return card;
}

- (BOOL)insertUserCard:(MMCard *)card withNumber:(NSString *)number {
	
    //  名片为空，退出  
    if (!card) {
		MLOG(@"insert card is nil");
        return NO;
    }
    
    //没有
    if ([self getUidByNumber:number] != card.uid) {
        //    先插入号码与uid对应关系
        if (![self insertNumber:number withUid:card.uid]) {
            MLOG(@"insertNumber to number_uid error");
            //return NO;
        }
    }
    
	if (![self saveCard:card]) {
		MLOG(@"insertCard error");
		return NO;
	}
	
	return YES;
}


- (void)deleteCardByUid:(NSInteger)uid {
    [self deleteCard:uid];
}

- (void)deleteCardByNumber:(NSString *)number {
    
    NSInteger uid = 0;
    
    for (NSString *numberKey in [numberUidCacheDic allKeys]) {
        
        NSRange searchResult = [numberKey rangeOfString:number 
                                                options:NSNumericSearch];
        
        if (searchResult.location != NSNotFound) {
            NSNumber *uidNumber = [numberUidCacheDic objectForKey:number];
            uid = [uidNumber intValue];
        }        
    }
    
    if (uid != 0) {
        [self deleteCard:uid];
    }
}

+ (MMCard *)getUserCardByTel:(NSString *)mobile andName:(NSString *)name {
	if (![MMCommonAPI isValidTelNumber:mobile]) {
		MLOG(@"号码不合法");
		return nil;
	}
	
	if (!name || ![name length]) {
		MLOG(@"名字不合法");
		return nil;
	}
	
	
	NSMutableDictionary *postObject = [NSMutableDictionary dictionary];
	[postObject setValue:mobile forKey:@"mobile"];
	[postObject setValue:name forKey:@"name"];
	
	NSString* strSource = @"user/show_by_mobile.json";
	NSDictionary *dicRet = [MMUapRequest postSync:strSource withObject:postObject];	
    
	NSUInteger lastError = [[dicRet valueForKey:@"status"] intValue];
	if (lastError != 200) {
		return nil;
	}
	
	
	MMCard *contact = [self decodeCard:dicRet];
	
	[[MMMomoUserMgr shareInstance] setUserId:contact.uid 
									realName:contact.registerName 
							  avatarImageUrl:contact.avatarUrl];
	return contact;
}

+ (MMCard *)getUserCard:(NSUInteger)uid {
	NSString* strSource = [NSString stringWithFormat:@"user/show/%d.json",uid];
	NSDictionary *dicRet = [MMUapRequest getSync:strSource compress:YES];
	NSUInteger lastError = [[dicRet valueForKey:@"status"] intValue];

	if (lastError != 200) {
		return nil;
	}
	
	MMCard *card = [self decodeCard:dicRet];
    
	[[MMMomoUserMgr shareInstance] setUserId:card.uid 
									realName:card.registerName 
							  avatarImageUrl:card.avatarUrl];
	return card;
}

+ (BOOL)updateUserCard:(MMCard *)card withErrorString:(NSString**)errorString {
	
	NSDictionary *postObject = [self encodeCard:card];
    
	NSString* strSource = @"user/update.json";
	NSDictionary *dicRet = [MMUapRequest postSync:strSource withObject:postObject];	
	
	NSUInteger lastError = [[dicRet valueForKey:@"status"] intValue];
	if (lastError != 200) {
		NSLog(@"changed UserCard failed, status code = %d", lastError);
        if (dicRet && [dicRet isKindOfClass:[NSDictionary class]]) {
			if (errorString) *errorString = [dicRet objectForKey:@"error"];
		}
        if (lastError == 0) {
            if (errorString) *errorString = @"网络连接失败";
        }
		return NO;
	}
	
	return YES;
}

+(NSDictionary*)encodeCard:(MMCard *)card {
	NSMutableDictionary *dic = [NSMutableDictionary dictionary];
    
    [dic setObject:[NSNumber numberWithInt:card.uid] forKey:@"user_id"];
    [dic setObject:PARSE_NULL_STR(card.registerName) forKey:@"name"];
    [dic setObject:[NSNumber numberWithInt:card.gender] forKey:@"gender"];
    [dic setObject:PARSE_NULL_STR(card.animalSign) forKey:@"animal_sign"];
    [dic setObject:PARSE_NULL_STR(card.zodiac) forKey:@"zodiac"];
    [dic setObject:PARSE_NULL_STR(card.residence) forKey:@"residence"];
    [dic setObject:PARSE_NULL_STR(card.note) forKey:@"note"];
	[dic setObject:PARSE_NULL_STR(card.organization) forKey:@"organization"];	
	[dic setObject:PARSE_NULL_STR(card.avatarUrl) forKey:@"avatar"];
    [dic setObject:[NSNumber numberWithInt:card.userLink] forKey:@"user_link"];
    [dic setObject:[NSNumber numberWithBool:card.isInMyContact] forKey:@"in_my_contact"];
    [dic setObject:[NSNumber numberWithInt:card.userStatus] forKey:@"user_status"];
    
	if (card.birthday) {
		[dic setObject:[MMCommonAPI getStingByDate:card.birthday] forKey:@"birthday"];
	}
    
    NSString *lunarBirthdayString = [card.lunarBirthday description];
	if ([lunarBirthdayString length]) {
		[dic setObject:lunarBirthdayString forKey:@"lunar_bday"];
	}
    
    [dic setObject:[NSNumber numberWithBool:card.isHideBirthdayYear] forKey:@"is_hide_year"];
    [dic setObject:[NSNumber numberWithBool:card.isLunar] forKey:@"is_lunar"];
	[dic setObject:[NSNumber numberWithInteger:card.completeLevel] forKey:@"completed"];
    
    
	NSMutableArray *emailArray = [NSMutableArray array];
	NSMutableArray *telArray = [NSMutableArray array];
	NSMutableArray *urlArray = [NSMutableArray array];
    
	for (DbData *property in card.properties) {
		switch(property.property) {
			case kMoMail:
			{
            NSMutableDictionary *propertyDic = [NSMutableDictionary dictionary];
            [propertyDic setObject:property.label forKey:@"type"];
            [propertyDic setObject:property.value forKey:@"value"];
            [emailArray addObject:propertyDic];
			}
				break;
			case kMoUrl:
			{
            NSMutableDictionary *propertyDic = [NSMutableDictionary dictionary];
            [propertyDic setObject:property.label forKey:@"type"];
            [propertyDic setObject:property.value forKey:@"value"];
            [urlArray addObject:propertyDic];
			}
				break;
			case kMoTel:
			{
            NSMutableDictionary *propertyDic = [NSMutableDictionary dictionary];
            if (property.isMainTelephone) {
                [propertyDic setObject:[NSNumber numberWithBool:YES] forKey:@"pref"];
                [propertyDic setObject:property.label forKey:@"type"];
            } else {
                [propertyDic setObject:property.label forKey:@"type"];
            }
            
            [propertyDic setObject:property.value forKey:@"value"];
            [telArray addObject:propertyDic];
			}
				break;
			default:
				break;
		}
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
    
	return dic;
}

+(MMCard *)decodeCard:(NSDictionary*)dic {
	
	MMCard *card = [[[MMCard alloc] init] autorelease];
    
    card.uid = [[dic objectForKey:@"user_id"] intValue];
    card.registerName = [dic objectForKey:@"name"];
    card.gender = [[dic objectForKey:@"gender"] intValue];
    card.animalSign = [dic objectForKey:@"animal_sign"];
    card.zodiac = [dic objectForKey:@"zodiac"];
    card.residence = [dic objectForKey:@"residence"];
    card.note = [dic objectForKey:@"note"];
    card.organization = [dic objectForKey:@"organization"];
    card.avatarUrl = [dic objectForKey:@"avatar"];
    card.userLink = [[dic objectForKey:@"user_link"] intValue];
    card.isInMyContact = [[dic objectForKey:@"in_my_contact"] boolValue];  
    card.userStatus = [[dic objectForKey:@"user_status"] intValue];
    card.birthday = [MMCommonAPI getDateBySting:[dic objectForKey:@"birthday"]];
    NSString *lunarBirthdayString = [dic objectForKey:@"lunar_bday"];
    if ([lunarBirthdayString length] > 0) {
        card.lunarBirthday = [[[MMLunarDate alloc] initWithString:lunarBirthdayString] autorelease];
    }
    card.isHideBirthdayYear = [[dic objectForKey:@"is_hide_year"] boolValue];
	card.isLunar = [[dic objectForKey:@"is_lunar"] boolValue];
    card.completeLevel = [[dic objectForKey:@"completed"] intValue];
    card.sendedCardCount = [[dic objectForKey:@"send_card_count"] intValue];
    
    
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
	
    
	card.properties = properties;
    
	return card;
}

#pragma mark Number And UID 
- (BOOL)loadNumberAndUID {
	NSError *outError = nil;
	NSString *sql = [NSString stringWithFormat:@"SELECT * FROM number_uid"];
	
	id<PLResultSet> results = [[self db]  executeQueryAndReturnError:&outError statement:sql];
	if(SQLITE_OK != [outError code]) {
		return NO;
	}
	
	PLResultSetStatus status = [results nextAndReturnError:nil];
	while (status == PLResultSetStatusRow) {
        NSInteger uid = [results intForColumn:@"uid"];
        NSString* number = [results stringForColumn:@"number"];
        
        [numberUidCacheDic setObject:[NSNumber numberWithInt:uid] forKey:number];
        
        status = [results nextAndReturnError:nil];
    }
	[results close];
	
	return YES;
}

//number_uid 
- (BOOL)insertToDbWithNumber:(NSString *)number withUid:(NSInteger)uid {
	if (!number || ![number length]) {
		MLOG(@"insert number is nil or length is 0");
		return NO;
	}
	
	NSString *sql = @"REPLACE INTO number_uid (number, uid) VALUES (?, ?)";
	
	if (![[self db] executeUpdate:sql,
		  number,
		  [NSNumber numberWithInteger:uid]]) {
		
		return NO;
	}
	return YES;
}

- (NSInteger)getUidByNumberFromDb:(NSString *)number {
	NSInteger uid = 0;
	NSError *outError = nil;
	NSString *sql = [NSString stringWithFormat:@"SELECT uid FROM number_uid WHERE number = '%@'",number];
	
	id<PLResultSet> results = [[self db]  executeQueryAndReturnError:&outError statement:sql];
	if(SQLITE_OK != [outError code]) {
		return 0;
	}
	
	PLResultSetStatus status = [results nextAndReturnError:nil];
	if(status) {
		uid = [results intForColumn:@"uid"];
	}
	[results close];
	
	return uid;
}

- (BOOL)insertNumber:(NSString *)number withUid:(NSInteger)uid {
	[numberUidCacheDic setObject:[NSNumber numberWithInteger:uid] forKey:number];
    
	return [self insertToDbWithNumber:number withUid:uid];
}

- (NSInteger)getUidByNumber:(NSString *)number {
	NSNumber *uid = [numberUidCacheDic objectForKey:number];
	
	if (!uid) {
		uid = [NSNumber numberWithInteger:[self getUidByNumberFromDb:number]];
        if (uid != 0) {
            [numberUidCacheDic setObject:uid forKey:number];
        }
	}
    
	return [uid intValue];
}

- (NSString*)numberByUID:(NSInteger)uid {
    //ToDo
    NSArray* allUid = [numberUidCacheDic allValues];
    for (NSNumber* uidValue in allUid) {
        if (uidValue.intValue == uid) {
            return [numberUidCacheDic objectForKey:uidValue];
        }
    }
    return nil;
}

+ (BOOL)isInvalidNumber:(NSString*)number {
    if (![MMCommonAPI isValidTelNumber:number]) {
        return YES;
    }
    
    return [[self instance] getUidByNumber:number] == mobileInvalid;
}

+ (BOOL)isRegisterNumber:(NSString*)number {
    return [[self instance] getUidByNumber:number] > 0;
}

#pragma mark Card HTTP Operations

- (NSDictionary *)getCardListUp100:(NSArray *)numberArr {
	assert([numberArr count] <= 100);
	if ([numberArr count] == 0) {
		return nil;
	}
	
	NSMutableArray* postArray = [NSMutableArray arrayWithArray:numberArr];
	NSString* strSource = @"user/show_batch_by_mobile.json";
	
	ASIHTTPRequest *request = [ASIHTTPRequest requestWithPath:strSource withObject:postArray];
	[ASIHTTPRequest startSynchronous:request];
	NSObject *retObject = [request responseObject];
	
	if ([request responseStatusCode] != 200) {
		MLOG(@"[request responseStatusCode] != 200");
		return nil;
	}
	
	NSDictionary *retDic = (NSDictionary *)retObject;
    if (!retDic || ![retDic isKindOfClass:[NSDictionary class]]) {
        MLOG(@"!retDic || ![retDic isKindOfClass:[NSDictionary class]]");
        return nil;
    }
	
	NSMutableDictionary *cardDic = [NSMutableDictionary dictionary];
    
	for (NSString *numberKey in numberArr) {
		
		NSDictionary *dicRet = [retDic objectForKey:numberKey];
		if (!dicRet) {
			continue;
		}
		
		MMCard *card = [MMCardManager decodeCard:dicRet];
		
		if (![[dicRet objectForKey:@"user_id"] intValue]) {
			
			NSString *error = [dicRet objectForKey:@"error"];
			if ([error isEqualToString:@"user.mobile_not_register"]) {
				//uid=-1 表示该号码未注册 mobileNotRegister
				//uid=-2 表示该号码为非法号码
                [cardDic setObject:[NSNumber numberWithInt:mobileNotRegister] forKey:numberKey];
			} else {
                [cardDic setObject:[NSNumber numberWithInt:mobileInvalid] forKey:numberKey];
			}
            continue;
		} else {			
			[[MMMomoUserMgr shareInstance] setUserId:card.uid 
											realName:card.registerName 
									  avatarImageUrl:card.avatarUrl];		
		}
		[cardDic setObject:card forKey:numberKey];
	}
    
	return cardDic;
}

- (NSDictionary *)getCardList:(NSArray *)numbers {
	NSMutableDictionary *dic = [NSMutableDictionary dictionary];
	for (unsigned int i = 0; i < [numbers count]; i+= 100) {
		int len = MIN(100, [numbers count] - i);
		NSDictionary *tmp = [self getCardListUp100:[numbers subarrayWithRange:NSMakeRange(i, len)]];
		[dic addEntriesFromDictionary:tmp];
	}
	return dic;
}

- (void)downloadCards:(NSArray*)numbers {
    NSDictionary *cardDic = [self getCardList:numbers];
	
	if (!cardDic || ![cardDic count]) {
		return;
	} 
    
	[[self db] beginTransaction];
	for (NSString *numberKey in numbers) {
		MMCard *value = (MMCard *)[cardDic objectForKey:numberKey];

        if ([value isKindOfClass:[MMCard class]]) {
            if (![[MMCardManager instance] insertUserCard:value withNumber:numberKey] ) {
                MLOG(@"insert card and number fail, card uid:%d , number:%@", value.uid, numberKey);
            }
        } else if ([value isKindOfClass:[NSNumber class]]) {
            [self insertNumber:numberKey withUid:[(NSNumber*)value intValue]];
        }
	}
	
	[[self db] commitTransaction];
}

- (void)refreshNeedDownloadCards:(NSArray*)numbers {
    NSMutableArray* numbersNeedDownloadArray = [NSMutableArray array];
    
    NSDictionary* allCard = [self getAllCard];
    NSDictionary* numbersAndUids = [self numberUidCacheDic];
    
    for (NSString* number in numbers) {
        //是否合法号码
        if (![MMCommonAPI isValidTelNumber:number]) {
            continue;
        }
        
        NSNumber* uidValue = [numbersAndUids objectForKey:number];
        if (uidValue) {
            if (uidValue.intValue == mobileInvalid) {
                continue;
            }
            
            //名片是否存在
            if ([allCard objectForKey:uidValue]) {
                continue;
            }
        }
        
        [numbersNeedDownloadArray addObject:number];
    }
    
    [self downloadCards:numbersNeedDownloadArray];
}

@end