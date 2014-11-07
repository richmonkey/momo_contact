//
//  MMContact.m
//  Db
//
//  Created by aminby on 2010-7-23.
//  Copyright 2010 NetDragon.Co. All rights reserved.
//

#import "MMContact.h"
#import "MMPhoneticAbbr.h"
#import <AddressBook/AddressBook.h>
#import "MMAddressBook.h"
#import "MMGlobalData.h"
#import "MMCommonAPI.h"
#import "MMServerContactManager.h"

@implementation NSString (NSStringCompare)

- (NSComparisonResult)compareWithOther:(NSString *)other {
    
    assert([other length] > 0);
    
    if ([self isEqualToString:@"#"]) {
        return NSOrderedDescending;
    }
    
    if ([other isEqualToString:@"#"]) {
        return NSOrderedAscending;
    }
    
    return [self compare:other];
}
@end


#define PARSE_NULL_STR(nsstr) nsstr ? nsstr : @""
@interface DbContactSimple(MMContactManager)
-(id)initWithResultSet:(id<PLResultSet>)results;
@end
@implementation DbContactSimple(MMContactManager)

-(id)initWithResultSet:(id<PLResultSet>)results {
    self = [self init];
    if (self) {
        DbContactSimple *contactSimple = self;
        [contactSimple setContactId:[results intForColumn:@"contact_id"]];
        contactSimple.firstName = [results stringForColumn:@"first_name"];
        contactSimple.middleName = [results stringForColumn:@"middle_name"];
        contactSimple.lastName = [results stringForColumn:@"last_name"];
        contactSimple.avatarUrl = [results stringForColumn:@"avatar_url"];
        contactSimple.namePhonetic = [results stringForColumn:@"name_phonetic"];
        
        if (![results isNullForColumn:@"phone_cid"]) {
            contactSimple.phoneCid = [results intForColumn:@"phone_cid"];
        }
        
    }
    return self;
}

@end

@interface DbContact(MMContactManager)
-(id)initWithResultSet:(id<PLResultSet>)results;
@end

@implementation  DbContact(MMContactManager)

-(id)initWithResultSet:(id<PLResultSet>)results {
    self = [super initWithResultSet:results];
    if (self) {
        DbContact *contact = self;
        
        contact.organization = [results stringForColumn:@"organization"];
        contact.department = [results stringForColumn:@"department"];
        contact.note = [results stringForColumn:@"note"];
        
        if ([results isNullForColumn:@"birthday"]) {
            contact.birthday = nil;
        } else {
            contact.birthday = [NSDate dateWithTimeIntervalSince1970:[results bigIntForColumn:@"birthday"]];
        }
        
        contact.jobTitle = [results stringForColumn:@"job_title"];
        contact.nickName = [results stringForColumn:@"nick_name"];
        
        
        contact.modifyDate = [results bigIntForColumn:@"modify_date"];
    }
    return self;
}

@end

@interface MMContactManager() 
@property (nonatomic, retain) NSMutableArray *contactArray;
@end

@implementation MMContactManager

@synthesize contactArray = contactArray_;

+(MMContactManager*) instance{
    static id _instance = nil;
    @synchronized(self) {
        if(_instance == nil) 
			_instance = [[[MMContactManager alloc] init] autorelease];
    }
    return _instance;
}

- (id)init {
	if (self = [super init]) {
		contactArray_ = [(NSMutableArray *)[self getSimpleContactListNew:nil] retain];
        
		friendArray_ = [[NSMutableArray alloc] init];
        
	}
	return self;
}

- (void)dealloc {
	[contactArray_ release];
	[friendArray_ release];
	[super dealloc];
}

-(NSArray*) getContactSyncInfoList:(MMErrorType*)error {
	// 错误码
    MMErrorType ret = MM_DB_OK;
    // 结果存放处
    NSMutableArray* array = [NSMutableArray array];
    NSError* outError = nil;
    
    PLResultSetStatus status;
    do{
        // 如果数据没打开
        if(![[self db]  goodConnection]) {
            ret = MM_DB_FAILED_OPEN;
            break;
        }
		
        // 返回结果
        id<PLResultSet> results = [[self db]  executeQueryAndReturnError:&outError statement:@"SELECT contact_id, avatar_url, modify_date "
                                   @" from contact "];
        
        if([outError code] != SQLITE_OK) {
            ret = MM_DB_FAILED_QUERY;
            break;
        }
		
        // 如果出错
        status = [results nextAndReturnError:&outError];
		
        // 循环返回结果
        while(status) {
            DbContactSyncInfo* info = [[[DbContactSyncInfo alloc] init] autorelease];
			info.contactId = [results intForColumn:@"contact_id"];
			info.modifyDate = [results bigIntForColumn:@"modify_date"];
            [array addObject:info];
            status = [results nextAndReturnError:nil];
        }
        [results close];
    }
    while(0);
    
    // 返回错误码
    if(error != nil)
        *error = ret;
    
    return array;
	
}

-(NSArray*)getContactSyncInfoList:(NSArray*)ids withError:(MMErrorType*)error {
	NSString* strContactIds = [ids componentsJoinedByString:@", "];
	
	NSMutableArray *array = [NSMutableArray array];
	NSError *outError = nil;
	NSString* sql = [NSString stringWithFormat:@"select * from contact where contact_id in (%@)", strContactIds];
	id<PLResultSet> results = [[self db]  executeQueryAndReturnError:&outError statement:sql];
	
	if(SQLITE_OK != [outError code]) {
		return nil;
	}
	PLResultSetStatus status = [results nextAndReturnError:nil];
	while (status) {
		DbContactSyncInfo* info = [[[DbContactSyncInfo alloc] init] autorelease];
		info.contactId = [results intForColumn:@"contact_id"];
		info.modifyDate = [results bigIntForColumn:@"modify_date"];
		[array addObject:info];
		status = [results nextAndReturnError:nil];
	}
	[results close];
	return array;
}

- (DbContactSimple *)dbContactSimpleFromPLResultSet:(id)object {
	id<PLResultSet> results = object;
	
	DbContactSimple* contactSimple = [[[DbContactSimple alloc] initWithResultSet:results] autorelease];
	
	return contactSimple;
}

- (NSArray*) getSimpleContactListNew:(MMErrorType*)error {
    // 错误码
    MMErrorType ret = MM_DB_OK;
    // 结果存放处
    NSMutableArray* array = [NSMutableArray array];
    NSError* outError = nil;
    
    PLResultSetStatus status;
    do{
        // 如果数据没打开
        if(![[self db]  goodConnection]) {
            ret = MM_DB_FAILED_OPEN;
            break;
        }
        
        // 返回结果
        id<PLResultSet> results = [[self db]  executeQueryAndReturnError:&outError statement:@"SELECT contact_id, first_name, middle_name, last_name, avatar_url, name_phonetic,  phone_cid "
                                   @" from contact "
                                   @" order by name_phonetic"];
        if([outError code] != SQLITE_OK) {
            ret = MM_DB_FAILED_QUERY;
            break;
        }
        
        // 如果出错
        status = [results nextAndReturnError:&outError];
        
        // 循环返回结果
        while(status) {
            
            DbContactSimple* contactSimple = [self dbContactSimpleFromPLResultSet:results];
            [array addObject:contactSimple];
            status = [results nextAndReturnError:nil];
        }
        [results close];
        
        //读取手机号
        NSDictionary* allPhoneDataDict = [self getAllTelDict:nil];
        for (DbContactSimple* contactSimple in array) {
            NSArray* telList = [allPhoneDataDict objectForKey:[NSNumber numberWithInt:contactSimple.contactId]];
            if (telList.count > 0) {
                [contactSimple.cellPhoneNums addObjectsFromArray:telList];
            }
        }
    }
    while(0);
    
    // 返回错误码
    if(error != nil)
        *error = ret;
    
    
    return array;
}

- (NSInteger) getContactCount {
	return [contactArray_ count];
}

- (NSArray*) getSimpleContactList:(MMErrorType*)error {
    NSArray* tmpArray = [NSArray arrayWithArray:contactArray_];
	return tmpArray;
}

- (NSDictionary*) getAllTelDict:(MMErrorType*)error {
    // 错误码
    MMErrorType ret = MM_DB_OK;
    NSError* outError = nil;
    
    // 结果存放处
    NSMutableDictionary* retDict = [NSMutableDictionary dictionary];
    
    PLResultSetStatus status;
    do{
        // 如果数据没打开
        if(![[self db]  goodConnection]) {
            ret = MM_DB_FAILED_OPEN;
            break;
        }
        
        // 返回结果
        id<PLResultSet> results = [[self db]  executeQueryAndReturnError:&outError statement:@"SELECT contact_id, value from data "
                                   @" where property = 1"];
        
        if(SQLITE_OK != [outError code]) {
            ret = MM_DB_FAILED_QUERY;
            break;
        }
        
        // 如果出错
        status = [results nextAndReturnError:nil];
        
        // 循环返回结果
        while(status) {
            NSInteger contactId = [results intForColumn:@"contact_id"];
            NSString* value = [results stringForColumn:@"value"];
            
            if (value.length > 0) {
                NSMutableArray* array = [retDict objectForKey:[NSNumber numberWithInt:contactId]];
                if (!array) {
                    array = [NSMutableArray array];
                    [retDict setObject:array forKey:[NSNumber numberWithInt:contactId]];
                }
                [array addObject:value];
            }
            
            status = [results nextAndReturnError:nil];
        }
        [results close];
    }
    while(0);
    
    // 返回错误码
    if(error != nil)
        *error = ret;
    
    
    return retDict;
}

- (NSArray*) getAllTelList:(MMErrorType*)error {
    // 错误码
    MMErrorType ret = MM_DB_OK;
    NSError* outError = nil;
    
    // 结果存放处
    NSMutableSet* numberSet = [NSMutableSet set];
    
    PLResultSetStatus status;
    do{
        // 如果数据没打开
        if(![[self db]  goodConnection]) {
            ret = MM_DB_FAILED_OPEN;
            break;
        }
        
        // 返回结果
        id<PLResultSet> results = [[self db]  executeQueryAndReturnError:&outError statement:@"SELECT value from data "
                                   @" where property = 1"];
        
        if(SQLITE_OK != [outError code]) {
            ret = MM_DB_FAILED_QUERY;
            break;
        }
        
        // 如果出错
        status = [results nextAndReturnError:nil];
        
        // 循环返回结果
        while(status) {
            NSString* value = [results stringForColumn:@"value"];
            
            if (![numberSet containsObject:value]) {
                [numberSet addObject:value];
            }
            
            status = [results nextAndReturnError:nil];
        }
        [results close];
    }
    while(0);
    
    // 返回错误码
    if(error != nil)
        *error = ret;
    
    
    return [numberSet allObjects];
}

/*
 - * 获得联系人某种类型数据, 返回DbData元素的NSArray
 - */
-(NSArray*) getDataList:(NSInteger)contactId withType:(ContactType)type withError:(MMErrorType*)error {
    NSArray *dataList = [self getDataList:contactId withError:error];
    NSMutableArray *array = [NSMutableArray array];
    for (DbData *data in dataList) {
        if (data.property == type) {
            [array addObject:data];
        }
    }
    return array;
}

- (NSArray*) getDataList:(NSInteger)contactId withError:(MMErrorType*)error{
    // 错误码
    MMErrorType ret = MM_DB_OK;
    NSError* outError = nil;
    
    // 结果存放处
    NSMutableArray* array = [NSMutableArray array];
    
    PLResultSetStatus status;
    do{
        // 如果数据没打开
        if(![[self db]  goodConnection]) {
            ret = MM_DB_FAILED_OPEN;
            break;
        }
        
        // 返回结果
        id<PLResultSet> results = [[self db]  executeQueryAndReturnError:&outError statement:@"SELECT row_id, contact_id, property, label, value "
                                   @" from data "
                                   @" where contact_id = ? "
                                   , [NSNumber numberWithInt:contactId]];
        
        if(SQLITE_OK != [outError code]) {
            ret = MM_DB_FAILED_QUERY;
            break;
        }
        
        // 如果出错
        status = [results nextAndReturnError:nil];
        
        // 循环返回结果
        while(status) {
            DbData* data = [DbData new];
			data.rowId = [results intForColumn:@"row_id"];
            data.contactId = [results intForColumn:@"contact_id"];
            data.property = [results intForColumn:@"property"];
            data.label = [results stringForColumn:@"label"];
            data.value = [results stringForColumn:@"value"];
            [array addObject:data];
            [data release];
            
            status = [results nextAndReturnError:nil];
        }
        [results close];
    }
    while(0);
    
    // 返回错误码
    if(error != nil)
        *error = ret;
    
    
    return array;
}



- (DbContact*) getContact:(NSInteger)contactId withError:(MMErrorType*)error {
    if ([NSThread isMainThread]) {
        for (DbContactSimple* contactInfo in contactArray_) {
            if (contactInfo.contactId == contactId) {
                if ([contactInfo isKindOfClass:[DbContact class]]) {
                    return (DbContact*)contactInfo;
                }
                break;
            }
        }
    }
    
    // 错误码
    MMErrorType ret = MM_DB_OK;
    NSError* outError = nil;
    // 结果存放处
    DbContact* contact = nil;
    
    PLResultSetStatus status;
    do{
        // 如果数据没打开
        if(![[self db]  goodConnection]) {
            ret = MM_DB_FAILED_OPEN;
            break;
        }
        
        // 获得
        id<PLResultSet> results = [[self db]  executeQueryAndReturnError:&outError statement:@"select * "
                                   @" from contact "
                                   @" where contact_id = ?"
                                   , [NSNumber numberWithInt:contactId]];
		
		if(SQLITE_OK != [outError code]) {
            ret = MM_DB_FAILED_QUERY;
            break;
        }		
        
        // 如果出错
        status = [results nextAndReturnError:nil];
        if(status == PLResultSetStatusError) {
            ret = MM_DB_FAILED_QUERY;
            break;
        }
        
        // 返回结果
        if(status) {
            contact = [[[DbContact alloc] initWithResultSet:results] autorelease];
        }
        [results close];
    }
    while(0);
    
    // 返回错误码
    if(error != nil)
        *error = ret;
    
    
    return contact;
}

- (DbContactSimple*)getContactSimple:(NSInteger)contactId {
    DbContactSimple* retContact = nil;
    for (DbContactSimple *contact in contactArray_) {
        if ([contact contactId] == contactId) {
            retContact = contact;
            break;
        }
    }
    
    return retContact;
}

- (MMErrorType) insertContact:(DbContact*)contact returnContactId:(NSInteger*)contactId{
	
	return [self _insertContact:contact returnContactId:contactId];
}

- (MMErrorType) _insertContact:(DbContact*)contact returnContactId:(NSInteger*)contactId{
    MMErrorType ret = MM_DB_OK;
    
    do{
        // 如果数据没打开
        if(![[self db]  goodConnection]) {
            ret = MM_DB_FAILED_OPEN;
            break;
        }
        
        NSString* full_name = [contact.lastName stringByAppendingString:contact.firstName];
        NSString* first_name_phonetic = [MMPhoneticAbbr getPinyin:contact.firstName];
        NSString* last_name_phonetic = [MMPhoneticAbbr getPinyin:contact.lastName];
        NSString* name_phonetic = [MMPhoneticAbbr getPinyin:full_name];
        NSString* name_abbr = [MMPhoneticAbbr getPinyinAbbr:full_name];
        NSString* name_phonetic_key = [MMPhoneticAbbr get_key_num:[last_name_phonetic stringByAppendingString:first_name_phonetic]];
        NSString* name_abbr_key = [MMPhoneticAbbr get_key_num:name_abbr];
		
		NSString *stringBirthdayValue = nil;
		
		NSMutableDictionary* parameters = [NSMutableDictionary dictionary];
		[parameters setObject:[NSNumber numberWithInt:contact.contactId]		forKey:@"contact_id"];
   		//phoneCid被删除
		[parameters setObject:[NSNumber numberWithInt:contact.contactId]		forKey:@"phoneCid"];
        
		[parameters setObject:contact.avatarUrl									forKey:@"avatar_url"];
        [parameters setObject:PARSE_NULL_STR(contact.firstName)					forKey:@"first_name"];
        [parameters setObject:PARSE_NULL_STR(contact.middleName)				forKey:@"middle_name"];
        [parameters setObject:PARSE_NULL_STR(contact.lastName)					forKey:@"last_name"];
        [parameters setObject:first_name_phonetic								forKey:@"first_name_phonetic"];
        [parameters setObject:last_name_phonetic								forKey:@"last_name_phonetic"];
        [parameters setObject:name_phonetic										forKey:@"name_phonetic"];
        [parameters setObject:name_abbr											forKey:@"name_abbr"];
        [parameters setObject:PARSE_NULL_STR(contact.organization)              forKey:@"organization"];
        [parameters setObject:PARSE_NULL_STR(contact.department)                forKey:@"department"];
        [parameters setObject:PARSE_NULL_STR(contact.note)                      forKey:@"note"];
		NSNumber *modifyDate = [NSNumber numberWithLongLong:contact.modifyDate];
		[parameters setObject:modifyDate										forKey:@"modify_date"];
        
        int64_t birthdayInterval = 0;
        if(contact.birthday) {
			birthdayInterval = [contact.birthday timeIntervalSince1970];
			[parameters setObject:[NSNumber numberWithLongLong:birthdayInterval] forKey:@"birthday"];
			stringBirthdayValue = [NSMutableString stringWithFormat:@":birthday"];
		} else {					
			stringBirthdayValue = [NSMutableString stringWithFormat:@"null"];
		}		
        
        [parameters setObject:PARSE_NULL_STR(contact.jobTitle)                         forKey:@"job_title"];
        [parameters setObject:PARSE_NULL_STR(contact.nickName)                         forKey:@"nick_name"];
        [parameters setObject:name_phonetic_key                                 forKey:@"name_phonetic_key"];
        [parameters setObject:name_abbr_key                                     forKey:@"name_abbr_key"];
        
        
		NSString *sql = [NSString stringWithFormat:@"INSERT INTO contact (contact_id, phone_cid, avatar_url, first_name, middle_name, last_name"
						 @", first_name_phonetic, last_name_phonetic, name_phonetic, name_abbr, organization, department"
						 @", note, birthday, job_title, nick_name, name_phonetic_key, name_abbr_key, modify_date)"
						 @" VALUES(:contact_id, :phoneCid,  :avatar_url, :first_name, :middle_name, :last_name,"
						 @" :first_name_phonetic, :last_name_phonetic, :name_phonetic, :name_abbr, :organization, :department,"
						 @" :note, %@, :job_title, :nick_name, :name_phonetic_key,"
						 @" :name_abbr_key, :modify_date)", stringBirthdayValue];
        
        
		
		
		id<PLPreparedStatement> stmt = [[self db]  prepareStatement:sql];        
        
        // 绑定参数
        [stmt bindParameterDictionary:parameters];
        
        // 如果执行失败
        if(![stmt executeUpdate]) {
			
            ret = MM_DB_FAILED_INVALID_STATEMENT;
            break;
        }
		
        
        if(contactId) {
            *contactId = [self getLastInsertId:&ret];
        }		
        
    }
    while(0);
    
    return ret;
}

- (MMErrorType)insertContact:(DbContact *)contact withDataList:(NSArray*)listData{
	NSInteger tmpContactId;
    
	
    MMErrorType ret = [self insertContact:contact returnContactId:&tmpContactId];
    if (ret != MM_DB_OK)
        return ret;
	
    contact.contactId = tmpContactId;
    for (DbData* data in listData) {
        data.contactId = contact.contactId;
        ret = [self _insertData:data];
        if(ret != MM_DB_OK) {
            return ret;
        }
        
        if (kMoTel == data.property && data.value.length > 0) {
            [contact.cellPhoneNums addObject:data.value];
        }
    }
    NSString* name_phonetic = [MMPhoneticAbbr getPinyin:contact.fullName];
    contact.namePhonetic = name_phonetic;
    
	dispatch_async(dispatch_get_main_queue(), ^{
		[[self mutableArrayValueForKeyPath:@"contactArray"] addObject:(DbContactSimple *)contact];
	});
	
    return ret;
}

- (MMErrorType)insertContact:(DbContact *)contact withDataList:(NSArray*)listData returnContactId:(NSInteger*)contactId{
    NSInteger tmpContactId = 0;
    MMErrorType ret = [self _insertContact:contact returnContactId:&tmpContactId];
    do{
        if(ret != MM_DB_OK)
            break;
        
        for(DbData* data in listData) {
            data.contactId = tmpContactId;
            ret = [self _insertData:data];
            if(ret != MM_DB_OK) {
                break;
            }
        }
    }
    while(0);
    
    if(contactId)
        *contactId = tmpContactId;
    
    return ret;
}

- (MMErrorType) _updateContact:(DbContact*)contact{
    MMErrorType ret = MM_DB_OK;
    
    do{
        // 如果数据没打开
        if(![[self db]  goodConnection]) {
            ret = MM_DB_FAILED_OPEN;
            break;
        }
        
        NSString* full_name = [contact.lastName stringByAppendingString:contact.firstName];
        NSString* first_name_phonetic = [MMPhoneticAbbr getPinyin:contact.firstName];
        NSString* last_name_phonetic = [MMPhoneticAbbr getPinyin:contact.lastName];
        NSString* name_phonetic = [MMPhoneticAbbr getPinyin:full_name];
        NSString* name_abbr = [MMPhoneticAbbr getPinyinAbbr:full_name];
        NSString* name_phonetic_key = [MMPhoneticAbbr get_key_num:[last_name_phonetic stringByAppendingString:first_name_phonetic]];
        NSString* name_abbr_key = [MMPhoneticAbbr get_key_num:name_abbr];
		
		NSString* stringBirthdayValue = nil;
        
		NSMutableDictionary* parameters = [NSMutableDictionary dictionary];
        [parameters setObject:[NSNumber numberWithInt:contact.contactId]                forKey:@"contact_id"];        
		[parameters setObject:contact.avatarUrl                                         forKey:@"avatar_url"];
        [parameters setObject:PARSE_NULL_STR(contact.firstName)                         forKey:@"first_name"];
        [parameters setObject:PARSE_NULL_STR(contact.middleName)                        forKey:@"middle_name"];
        [parameters setObject:PARSE_NULL_STR(contact.lastName)                          forKey:@"last_name"];
        [parameters setObject:first_name_phonetic                                       forKey:@"first_name_phonetic"];
        [parameters setObject:last_name_phonetic                                        forKey:@"last_name_phonetic"];
        [parameters setObject:name_phonetic                                             forKey:@"name_phonetic"];
        [parameters setObject:name_abbr                                                 forKey:@"name_abbr"];
        [parameters setObject:PARSE_NULL_STR(contact.organization)                      forKey:@"organization"];
        [parameters setObject:PARSE_NULL_STR(contact.department)                        forKey:@"department"];
        [parameters setObject:PARSE_NULL_STR(contact.note)                              forKey:@"note"];
		[parameters setObject:[NSNumber numberWithLongLong:contact.modifyDate]          forKey:@"modify_date"];
        
        int64_t birthdayInterval = 0;
        if(nil != contact.birthday) {
			birthdayInterval = [contact.birthday timeIntervalSince1970];
			[parameters setObject:[NSNumber numberWithLongLong:birthdayInterval] forKey:@"birthday"];
			stringBirthdayValue = @":birthday";
		} else {
			stringBirthdayValue = @"null";
		}
        
        [parameters setObject:PARSE_NULL_STR(contact.jobTitle)                          forKey:@"job_title"];
        [parameters setObject:PARSE_NULL_STR(contact.nickName)                          forKey:@"nick_name"];
        [parameters setObject:name_phonetic_key                                         forKey:@"name_phonetic_key"];
        [parameters setObject:name_abbr_key                                             forKey:@"name_abbr_key"];
		
		NSString *sql = [NSString stringWithFormat:@"update contact set avatar_url = :avatar_url, first_name = :first_name, "
						 @" middle_name = :middle_name, last_name = :last_name, first_name_phonetic = :first_name_phonetic, "
						 @" last_name_phonetic = :last_name_phonetic, name_phonetic = :name_phonetic, name_abbr = :name_abbr, "
						 @" organization = :organization, department = :department, note = :note, "
                         @" birthday = %@, job_title = :job_title, nick_name = :nick_name, name_phonetic_key = :name_phonetic_key, "
						 @" name_abbr_key = :name_abbr_key, modify_date = :modify_date "
                         @" where contact_id = :contact_id", stringBirthdayValue];
		
        
		id<PLPreparedStatement> stmt = [[self db] prepareStatement:sql];
        
        // 绑定参数
        [stmt bindParameterDictionary:parameters];
        
        // 如果执行失败
        if(![stmt executeUpdate]) {
			
            ret = MM_DB_FAILED_INVALID_STATEMENT;
            break;
        }        
		
    }
    while(0);
    
    return ret;
}

- (MMErrorType) deleteContact:(NSInteger)contactId {
	
	MMErrorType error = MM_DB_OK;
	
	error = [self _deleteContact:contactId];
	
	if (MM_DB_OK != error) {
		return error;
	} 
    
	dispatch_async(dispatch_get_main_queue(), ^{
		NSInteger index = [contactArray_ indexOfObjectPassingTest:^(id obj, NSUInteger idx, BOOL *stop) {
			DbContactSimple *rcd = (DbContactSimple *)obj;
			if (contactId == rcd.contactId) {
				return YES;
			}
			return NO;
		}];
		
		if (NSNotFound == index) {
			DLOG(@"deleteContact error");
			return ;
		}
		
		DbContactSimple *contact = [contactArray_ objectAtIndex:index];	
		[[self mutableArrayValueForKeyPath:@"contactArray"] removeObject:contact];
		
	});
	
	return MM_DB_OK;
}

- (MMErrorType) _deleteContact:(NSInteger)contactId{
    MMErrorType ret = MM_DB_OK;
    
    do{
        // 如果数据没打开
        if(![[self db]  goodConnection]) {
            ret = MM_DB_FAILED_OPEN;
            break;
        }
        
        // 如果执行失败
        if(![[self db]  executeUpdate:@"DELETE FROM contact where contact_id = ? ", [NSNumber numberWithInt:contactId]]) {
            ret = MM_DB_FAILED_INVALID_STATEMENT;
            break;
        }
		
        
        // TODO: delete from category and data
        ret = [self _deleteAllData:contactId];
        if(ret != MM_DB_OK)
            break;
    }
    while(0);
    
    return ret;
}

- (MMErrorType) updateContact:(DbContact*)contact withDataList:(NSArray*)listData {
	MMErrorType error = MM_DB_OK;
	
	
	error = [self _updateContact:contact withDataList:listData];
	
    if (MM_DB_OK != error) {
		
		return error;
	} 
    
	dispatch_async(dispatch_get_main_queue(), ^{
		NSInteger index = [contactArray_ indexOfObjectPassingTest:^(id obj, NSUInteger idx, BOOL *stop) {
			DbContactSimple *rcd = (DbContactSimple *)obj;
			if (contact.contactId == rcd.contactId) {
				return YES;
			}
			return NO;
		}];
        
		if (NSNotFound == index) {
			NSLog(@"updateContact error");
			return ;
		}
        
        //读取手机号
        for (DbData *data in listData) {
            if (kMoTel == data.property && data.value.length > 0 ) {
                [contact.cellPhoneNums addObject:data.value];
            }
        }
        
		NSString* name_phonetic = [MMPhoneticAbbr getPinyin:contact.fullName];
		contact.namePhonetic = name_phonetic;
		[[self mutableArrayValueForKeyPath:@"contactArray"] replaceObjectAtIndex:index withObject:contact];
        
	});
	
	return MM_DB_OK;
}


- (MMErrorType) _updateContact:(DbContact*)contact withDataList:(NSArray*)listData{
    MMErrorType error = MM_DB_OK;
    do {
        error = [self _updateContact:contact];
        if(error != MM_DB_OK)
            break;
        
        error = [self _deleteAllData:contact.contactId];
        if(error != MM_DB_OK)
            break;
        
        for(DbData* data in listData) {
            data.contactId = contact.contactId;
            error = [self _insertData:data];
            if(error != MM_DB_OK)
                break;
        }
        if(error != MM_DB_OK)
            break;
    }
    while(0);
    
    return error;
}

- (MMErrorType) _insertData:(DbData*)data {
    MMErrorType ret = MM_DB_OK;
    
    do{
        if(![[self db]  goodConnection]) {
            ret = MM_DB_FAILED_OPEN;
            break;
        }
        
		
        id<PLPreparedStatement> stmt = [[self db]  prepareStatement:@"INSERT INTO data (contact_id, property, label, value) VALUES(?, ?, ?, ?)"];
        
        [stmt bindParameters:[NSArray arrayWithObjects:[NSNumber numberWithInt:[data contactId]]
                              , [NSNumber numberWithInt:[data property]]
                              , data.label
                              , data.value
                              , nil]
         ];
        
        NSError* outError;
        if(![stmt executeUpdateAndReturnError:&outError]) {
			
            ret = MM_DB_FAILED_INVALID_STATEMENT;
            break;
        }
		data.rowId = [self getLastInsertId:&ret];
		
    }
    while(0);
    
    return ret;
}




//MFM ADD
- (MMErrorType) _updateData:(DbData*)data{
    MMErrorType ret = MM_DB_OK;
    
    do{
        // 如果数据没打开
        if(![[self db]  goodConnection]) {
            ret = MM_DB_FAILED_OPEN;
            break;
        }
		
		NSString* sql = @"UPDATE data SET label = ?, value = ? WHERE row_id = ? ";
        
        if(![[self db] executeUpdate:sql, data.label, data.value, [NSNumber numberWithInt:data.rowId]]) {
			
            ret = MM_DB_FAILED_INVALID_STATEMENT;
            break;
        }
    }
    while(0);
    
    return ret;
}



- (MMErrorType) _deleteData:(NSInteger)row_id{
    MMErrorType ret = MM_DB_OK;
    
    do{
        // 如果数据没打开
        if(![[self db]  goodConnection]) {
            ret = MM_DB_FAILED_OPEN;
            break;
        }
        
        // 如果执行失败
		
        if(![[self db]  executeUpdate:@"delete from data where row_id = ?", [NSNumber numberWithInt:row_id]]) {
			
            ret = MM_DB_FAILED_INVALID_STATEMENT;
            break;
        }
		
    }
    while(0);
    
    return ret;
    
}

- (MMErrorType) _deleteAllData:(NSInteger)contactId{
    MMErrorType ret = MM_DB_OK;
    
    do{
        // 如果数据没打开
        if(![[self db]  goodConnection]) {
            ret = MM_DB_FAILED_OPEN;
            break;
        }
        
        // 如果执行失败
		
        if(![[self db]  executeUpdate:@"delete from data where contact_id = ?", [NSNumber numberWithInt:contactId]]) {
			
            ret = MM_DB_FAILED_INVALID_STATEMENT;
            break;
        }
		
    }
    while(0);
    
    return ret;
}

- (NSDate*)getModifyDate:(NSInteger)contactId withError:(MMErrorType*)error {
	// 错误码
	if (error)
		*error = MM_DB_FAILED_QUERY;
    NSError* outError = nil;
    
	NSDate *modifydate = nil;
    
    PLResultSetStatus status;
    do{
        // 如果数据没打开
        if(![[self db]  goodConnection]) {
			if (error) 
				*error = MM_DB_FAILED_OPEN;
            break;
        }
        
        // 返回结果
        NSString* sql = @"select modify_date from contact where contact_id = ? ";
        id<PLResultSet> results = [[self db] executeQueryAndReturnError:&outError statement:sql,
								   [NSNumber numberWithInt:contactId]];
        
        if(SQLITE_OK != [outError code]) {
			if (error)
				*error = MM_DB_FAILED_QUERY;
            break;
        }
		
        // 如果出错
        status = [results nextAndReturnError:nil];
        
        // 返回结果
        if(status) {
			NSInteger iDate = 0;
			if (![results isNullForColumn:@"modify_date"]) {
				iDate = [results intForColumn:@"modify_date"];				
			} 
			modifydate = [NSDate dateWithTimeIntervalSince1970:iDate];
			if (error) 
				*error = MM_DB_OK;				
        }        
        [results close];
    }
    while(0); 
    
    
    return modifydate;
}

- (MMErrorType) setModifyDate:(NSDate*)modifydate byContactId:(NSInteger)contactId {
	MMErrorType ret = MM_DB_OK;
    
    do{
        NSString* sql = @"UPDATE contact set modify_date = ? where contact_id = ? ";
        if(ret != MM_DB_OK)
            break;
        
		
        if(![[self db]  executeUpdate:sql, 
             [NSNumber numberWithInt:[modifydate timeIntervalSince1970]],
             [NSNumber numberWithInt:contactId]]) {
			
            ret = MM_DB_FAILED_INVALID_STATEMENT;
            break;
        }
		
    }
    while(0);
    return ret;
}

- (MMErrorType) _updatePhoneticAbbr:(NSInteger)contactId{
	
	// 错误码
    MMErrorType ret = MM_DB_OK;
    // 结果存放处
	NSString *first_name = nil;
	NSString *last_name = nil;
    NSError* outError = nil;
    
    PLResultSetStatus status;
    do{
        // 如果数据没打开
        if(![[self db]  goodConnection]) {
            ret = MM_DB_FAILED_OPEN;
            break;
        }
		
        // 返回结果
        id<PLResultSet> results = [[self db]  executeQueryAndReturnError:&outError statement:@"SELECT first_name, last_name  "
                                   @" from contact "
                                   @" where contact_id = ? "
                                   , [NSNumber numberWithInt:contactId]];
        if([outError code] != SQLITE_OK) {
            ret = MM_DB_FAILED_QUERY;
            break;
        }
		
        // 如果出错
        status = [results nextAndReturnError:&outError];
		
        // 循环返回结果
        if(status) {            
            first_name = [results stringForColumn:@"first_name"];
            last_name = [results stringForColumn:@"last_name"];
        }
        [results close];
    }
    while(0);  
    
	
    // error handle
    if (ret != MM_DB_OK) {
        return ret;
    }
	
    // prefix: ret is MM_DB_OK;
	do{
        // 如果数据没打开
        if(![[self db]  goodConnection]) {
            ret = MM_DB_FAILED_OPEN;
            break;
        }
        
		NSString* full_name = [last_name stringByAppendingString:first_name];
		NSString* first_name_phonetic = [MMPhoneticAbbr getPinyin:first_name];
		NSString* last_name_phonetic = [MMPhoneticAbbr getPinyin:last_name];
		NSString* name_phonetic = [MMPhoneticAbbr getPinyin:full_name];
		NSString* name_abbr = [MMPhoneticAbbr getPinyinAbbr:full_name];
		NSString* name_phonetic_key = [MMPhoneticAbbr get_key_num:[last_name_phonetic stringByAppendingString:first_name_phonetic]];
		NSString* name_abbr_key = [MMPhoneticAbbr get_key_num:name_abbr];
		
		NSMutableDictionary* parameters = [NSMutableDictionary dictionary];
        [parameters setObject:first_name_phonetic                      forKey:@"first_name_phonetic"];
        [parameters setObject:last_name_phonetic                       forKey:@"last_name_phonetic"];
        [parameters setObject:name_phonetic                            forKey:@"name_phonetic"];
        [parameters setObject:name_abbr                                forKey:@"name_abbr"];
        [parameters setObject:name_phonetic_key                        forKey:@"name_phonetic_key"];
        [parameters setObject:name_abbr_key                            forKey:@"name_abbr_key"];
        
		NSString *sql = [NSString stringWithFormat:
						 @"update contact set first_name_phonetic = :first_name_phonetic, "
						 @" last_name_phonetic = :last_name_phonetic, name_phonetic = :name_phonetic, name_abbr = :name_abbr, "
						 @" name_phonetic_key = :name_phonetic_key, name_abbr_key = :name_abbr_key"
						 @" where contact_id = :contact_id"];
		
		
		
		id<PLPreparedStatement> stmt = [[self db] prepareStatement:sql];
        
        // 绑定参数
        [stmt bindParameterDictionary:parameters];
        
        // 如果执行失败
        if(![stmt executeUpdate]) {
			
            ret = MM_DB_FAILED_INVALID_STATEMENT;
            break;
        }        
		
    }
    while(0);
    
    return ret;	
}

- (void)killSelf {	
	
	do{		
        [MMAddressBook clearAddressBook];
		
		if(![[self db]  goodConnection]) {            
            break;
        }
        
        NSArray* tableArray = [NSArray arrayWithObjects:@"image", 
                               @"contact", 
                               @"data", 
                               @"category", 
                               @"category_member", 
                               @"group_info", 
                               @"group_image", 
                               @"group_contact", 
                               @"group_data", 
                               @"call_history", 
                               @"number_uid",
                               nil];
        
        for (NSString* table in tableArray) {
            NSString* sql = [NSString stringWithFormat:@"delete from %@", table];
            if (![[self db] executeUpdate:sql]) {
                NSLog(@"fail: delete from %@", table);
            } else {
                NSLog(@"success: delete from %@", table);
            }
        }
	}
    while(0);
	
}

- (MMErrorType)clearContactDB {
	
	MMErrorType ret = MM_DB_OK;
	
	do{
        // 如果数据没打开
        if(![[self db]  goodConnection]) {
            ret = MM_DB_FAILED_OPEN;
            break;
        }						 
		[[self  db] beginTransaction];
        
        NSArray* tableArray = [NSArray arrayWithObjects:@"image", 
                               @"contact", 
                               @"data", 
                               @"group_info", 
                               @"group_image", 
                               @"group_contact", 
                               @"group_data", 
                               @"call_history", 
                               @"sync_history",
                               @"momo_card",
                               @"mq_im_message",
                               @"number_uid",
                               nil];
        
        for (NSString* table in tableArray) {
            NSString* sql = [NSString stringWithFormat:@"delete from %@", table];
            if (![[self db] executeUpdate:sql]) {
                NSLog(@"fail: delete from %@", table);
            }
        }
		
		[[self db] commitTransaction];
        
	}
    while(0);
    
	[[self mutableArrayValueForKeyPath:@"contactArray"] removeAllObjects];
	
    return ret;
}
- (MMErrorType)clearMomoContact {
    [[self db] beginTransaction];
    //删除contact
    if (![[self db]  executeUpdate:@"delete from contact where contact_id > 0 "]) {
        NSLog(@"delete contact fail");            
    }
    
    //删除data
    if (![[self db]  executeUpdate:@"delete from data where contact_id > 0 "]) {
        NSLog(@"delete contact fail");            
    }
    [[self db] commitTransaction];
    dispatch_async(dispatch_get_main_queue(), ^{
        NSMutableArray *array = [NSMutableArray array];
        for (DbContactSimple *contact in contactArray_) {
            if (contact.contactId > 0) {
                [array addObject:contact];
            }
        }
        for (DbContactSimple *contact in array) {
            [[self mutableArrayValueForKeyPath:@"contactArray"] removeObject:contact];
        }
        
    });
    return MM_DB_OK;
}

- (MMErrorType)clearAddressBookContact {
    [[self db] beginTransaction];
    //删除contact
    if (![[self db]  executeUpdate:@"delete from contact where contact_id < 0 "]) {
        NSLog(@"delete contact fail");            
    }
    
    //删除data
    if (![[self db]  executeUpdate:@"delete from data where contact_id < 0 "]) {
        NSLog(@"delete contact fail");            
    }
    [[self db] commitTransaction];
    dispatch_async(dispatch_get_main_queue(), ^{
        NSMutableArray *array = [NSMutableArray array];
        for (DbContactSimple *contact in contactArray_) {
            if (contact.contactId < 0) {
                [array addObject:contact];
            }
        }
        for (DbContactSimple *contact in array) {
            [[self mutableArrayValueForKeyPath:@"contactArray"] removeObject:contact];
        }
    });
    return MM_DB_OK;
}

- (NSArray*) getContactListByDataLabel:(NSString *)label withError:(MMErrorType*)error {
	
	//查询出所有带有此label的联系人
	MMErrorType ret = MM_DB_OK;
	NSError* outError = nil;
	PLResultSetStatus status;
	
	NSMutableArray *arrayContactId = [[[NSMutableArray alloc]init] autorelease];
	
	do {
		// 如果数据没打开
        if(![[[MMContact instance] db]  goodConnection]) {
            ret = MM_DB_FAILED_OPEN;
            break;
        }
		
		// 返回结果
        NSString* sql = @"select distinct contact_id from data where label = ? ";
        id<PLResultSet> results = [[self db]  
								   executeQueryAndReturnError:&outError 
								   statement:sql, label];
        
        if(SQLITE_OK != [outError code]) {
            ret = MM_DB_FAILED_QUERY;
            break;
        }
		
        
        status = [results nextAndReturnError:nil];
		while(status) {
			NSNumber *cid = [NSNumber numberWithInt:[results intForColumn:@"contact_id"]];
			[arrayContactId addObject:cid];
			status = [results nextAndReturnError:nil];
		}
		[results close];
	} while (0);
	
	if (nil != error) {
		*error = ret;
	}
	
	return arrayContactId;	
}

- (MMErrorType)changeCustomLabelToDefault:(NSString*)label {
	
	MMErrorType ret = MM_DB_OK;
	
	do {
		// 如果数据没打开
		if(![[self db]  goodConnection]) {
			ret = MM_DB_FAILED_OPEN;
			break;
		}
		
		NSArray *arrayProperty = [NSArray arrayWithObjects:
								  [NSNumber numberWithInt:kMoTel], 
								  [NSNumber numberWithInt:kMoMail], 
								  [NSNumber numberWithInt:kMoUrl], 
								  [NSNumber numberWithInt:kMoAdr], 
								  [NSNumber numberWithInt:kMoBday], 
								  [NSNumber numberWithInt:kMoPerson], 							  
								  nil];
		
		NSString* sql = @"UPDATE data SET label = ? "
        @" WHERE label = ? and property = ? ";	
		
		
		for (NSNumber *property in arrayProperty) {
            
			
			if(![[self db] executeUpdate:sql, 
                 [self getDefaulMMLabelByProperty:[property intValue]], 
                 label, property]) {
				ret = MM_DB_FAILED_INVALID_STATEMENT;
				break;
			}
		}
		
        
		NSString* sqlIM = [NSString stringWithFormat: @"UPDATE data SET label = ?  "
                           @" WHERE label = ? and property in (%d, %d, %d, %d, %d, %d, %d, %d, %d) ",
						   kMoImAIM, kMoImJabber, kMoImMSN, kMoImYahoo, kMoImICQ, kMoIm91U,
						   kMoImQQ, kMoImGtalk, kMoImSkype];	
        
		
		if(![[self db] executeUpdate:sqlIM, 
			 [self getDefaulMMLabelByProperty:kMoImAIM], 
			 label]) {
			
			ret = MM_DB_FAILED_INVALID_STATEMENT;
			break;
		}	
		
		
	} while (0);
	
	return ret;
	
}

- (NSArray*) getAllLabelWithError:(MMErrorType*)error {
	//查询出所有带有此label的联系人
	MMErrorType ret = MM_DB_OK;
	NSError* outError = nil;
	PLResultSetStatus status;
	
	NSMutableArray *arrayLabel = [[[NSMutableArray alloc]init] autorelease];
	
	do {
		// 如果数据没打开
        if(![[[MMContact instance] db]  goodConnection]) {
            ret = MM_DB_FAILED_OPEN;
            break;
        }
		
		// 返回结果
        NSString* sql = @"select distinct label from data ";
        id<PLResultSet> results = [[self db]  
								   executeQueryAndReturnError:&outError 
								   statement:sql];
        
        if(SQLITE_OK != [outError code]) {
            ret = MM_DB_FAILED_QUERY;
            break;
        }
		
        
        status = [results nextAndReturnError:nil];
		while(status) {
			NSString *label = [results stringForColumn:@"label"];
			[arrayLabel addObject:label];
			status = [results nextAndReturnError:nil];
		}
		[results close];
	} while (0);
	
	if (nil != error) {
		*error = ret;
	}
	
	return arrayLabel;
}

- (NSArray*)getContactListNeedName:(BOOL)needName needPhone:(BOOL)needPhone {
    NSMutableArray* array = [NSMutableArray array];
    
    NSArray* tmpArray = [NSArray arrayWithArray:contactArray_];
    
    for (DbContactSimple* contactSimple in tmpArray) {
        if (needName && contactSimple.fullName.length == 0) {
            continue;
        }
        if (needPhone && contactSimple.cellPhoneNums.count == 0) {
            continue;
        }
        
		[array addObject:contactSimple];
    }
    return array;
}



- (NSArray*)searchContact:(NSString*)searchString
                 needName:(BOOL)needName    //是否包含没有名字联系人
                needPhone:(BOOL)needPhone //是否包含没有手机号的联系人  
{
    NSMutableArray* array = [NSMutableArray array];
    searchString = [searchString lowercaseString];
    
    NSArray* tmpArray = [NSArray arrayWithArray:contactArray_];
    
    for (DbContactSimple* contactSimple in tmpArray) {
        if (needName && contactSimple.fullName.length == 0) {
            continue;
        }
        if (needPhone && contactSimple.cellPhoneNums.count == 0) {
            continue;
        }
        
        BOOL successMatch = NO;
        do {
            //直接查找
            NSRange searchResult = [contactSimple.fullName rangeOfString:searchString options:NSCaseInsensitiveSearch];
            if (searchResult.location != NSNotFound) {
                successMatch = YES;
                break;
            }
            
            //拼音匹配
            if ([MMPhoneticAbbr contactMatch:contactSimple.fullName pattern:searchString isFuzzy:NO isDigital:NO]) {
                successMatch = YES;
                break;
            }
            
        } while (0);
        
        if (successMatch) {						
            [array addObject:contactSimple];
        }
    }
    
    return array;
}

-(NSString*) getDefaulMMLabelByProperty:(NSInteger) property {
	
	switch (property) {
		case kMoTel:{	
			return @"cell";
			break;
		}			
		case kMoMail:{
			return @"home";
			break;
		}			
		case kMoUrl:{
			return @"homepage";
			break;
		}
		case kMoAdr:{
			return @"home";
			break;
		}
		case kMoBday:{
			return @"anniversary";
			break;
		}
		case kMoPerson:{
			return @"spouse";
			break;
		}
		case kMoImAIM:
		case kMoImJabber:
		case kMoImMSN:
		case kMoImYahoo:
		case kMoImICQ:
		case kMoIm91U:
		case kMoImQQ:
		case kMoImGtalk:
		case kMoImSkype:{
			return @"home";
			break;
		}
		default:{
			return @"other";
			break;
		}
	}
	
	return @"other";			   
}

@end

