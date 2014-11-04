//
//  MMSyncContact.m
//  momo
//
//  Created by houxh on 11-7-6.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//
#import "MMContactSync.h"
#import "MMUapRequest.h"
#import "DbStruct.h"
#import <AddressBook/AddressBook.h>
#import "MMAddressBook.h"
#import "SBJSON.h"
#import "MMServerContactManager.h"
#import "MMContact.h"
#import "MMLogger.h"
#import "MMCommonAPI.h"
#import "MMSyncThread.h"

//避免momo模块重复下载本地上传的联系人
#define UPDATE_MOMO_DATEBASE

@interface MMContactSyncInfo : DbContactId
{
	NSInteger phoneContactId;
	int64_t modifyDate;
	int64_t phoneModifyDate;
	NSString *avatarUrl;
	NSData *avatarPart;
	NSString *avatarMd5;

}
@property(nonatomic)NSInteger phoneContactId;
@property(nonatomic)int64_t modifyDate;
@property(nonatomic)int64_t phoneModifyDate;
@property(nonatomic, copy)NSString *avatarUrl;
@property(nonatomic, retain)NSData *avatarPart;
@property(nonatomic, copy)NSString *avatarMd5;


-(id)initWithResultSet:(id<PLResultSet>)results;

@end

@implementation MMContactSyncInfo
@synthesize phoneContactId, modifyDate, phoneModifyDate, avatarUrl, avatarPart, avatarMd5;

-(id)initWithResultSet:(id<PLResultSet>)results {
	self = [super init];
	if (self) {
		self.contactId = [results intForColumn:@"contact_id"];
		self.phoneContactId = [results intForColumn:@"phone_contact_id"];
		self.modifyDate = [results bigIntForColumn:@"modify_date"];
		self.phoneModifyDate = [results bigIntForColumn:@"phone_modify_date"];
		if (![results isNullForColumn:@"avatar_url"]) {
			self.avatarUrl = [results stringForColumn:@"avatar_url"];
		} else {
			self.avatarUrl = @"";
		}

		if (![results isNullForColumn:@"avatar_part"]) {
			self.avatarPart = [results dataForColumn:@"avatar_part"];
		}
		if (![results isNullForColumn:@"avatar_md5"]) {
			self.avatarMd5 = [results stringForColumn:@"avatar_md5"];
		}


	}
	return self;
}

-(void)dealloc {

	[avatarUrl release];
	[avatarPart release];
	[avatarMd5 release];
	[super dealloc];
}

@end


@implementation MMContactSync(Contact)
-(NSInteger)getContactIdByCellId:(NSInteger)cellId {
	NSError *outError = nil;
	NSString* sql = @"select contact_id from contact_sync where phone_contact_id = ? ";
	id<PLResultSet> results = [[self db]  executeQueryAndReturnError:&outError statement:sql, [NSNumber numberWithInt:cellId]];
	
	if(SQLITE_OK != [outError code]) {
		return 0;
	}
	
	PLResultSetStatus status = [results nextAndReturnError:nil];
	
	NSInteger contactId = 0;
	if(status) {
		contactId = [results intForColumn:@"contact_id"];
	}
	
	[results close];
	return contactId;
}
-(NSInteger)getCellIdByContactId:(NSInteger)contactId {
	NSError *outError = nil;
	NSString* sql = @"select phone_contact_id from contact_sync where contact_id = ? ";
	id<PLResultSet> results = [[self db]  executeQueryAndReturnError:&outError statement:sql, [NSNumber numberWithInt:contactId]];
	
	if(SQLITE_OK != [outError code]) {
		return 0;
	}
	
	PLResultSetStatus status = [results nextAndReturnError:nil];
	
	NSInteger cellId = 0;
	if(status) {
		cellId = [results intForColumn:@"phone_contact_id"];
	}
	
	[results close];
	return cellId;
}

-(BOOL)touchPhoneContact:(NSInteger)contactId {
	NSString* sql = @"update contact_sync set phone_modify_date = 0 where contact_id = ? ";
	if(![[self db]  executeUpdate:sql, [NSNumber numberWithInt:contactId]]) {
		return NO;
	}
	return YES;
}

-(NSMutableArray*)getContactSyncInfoList:(NSArray*)ids {
	NSString* strContactIds = [ids componentsJoinedByString:@", "];
	
	NSMutableArray *array = [NSMutableArray array];
	NSError *outError = nil;
	NSString* sql = [NSString stringWithFormat:@"select * from contact_sync where contact_id in (%@)", strContactIds];
	id<PLResultSet> results = [[self db]  executeQueryAndReturnError:&outError statement:sql];
	
	if(SQLITE_OK != [outError code]) {
		return nil;
	}
	PLResultSetStatus status = [results nextAndReturnError:nil];
	while (status) {
		MMContactSyncInfo *info = [[[MMContactSyncInfo alloc] initWithResultSet:results] autorelease];
		[array addObject:info];
		status = [results nextAndReturnError:nil];
	}
	[results close];
	return array;
}
-(MMContactSyncInfo*)getContactSyncInfo:(NSInteger)contactId {
	NSMutableArray *array = [self getContactSyncInfoList:[NSArray arrayWithObject:[NSNumber numberWithInt:contactId]]];
	if ([array count] == 0) {
		return nil;
	}
	return [array objectAtIndex:0];
}
-(NSMutableArray*)getContactSyncInfoList {
	NSMutableArray *array = [NSMutableArray array];
	NSError *outError = nil;
	NSString* sql = @"select * from contact_sync ";
	id<PLResultSet> results = [[self db]  executeQueryAndReturnError:&outError statement:sql];
	
	if(SQLITE_OK != [outError code]) {
		return nil;
	}
	PLResultSetStatus status = [results nextAndReturnError:nil];
	while (status) {
		MMContactSyncInfo *info = [[[MMContactSyncInfo alloc] initWithResultSet:results] autorelease];
		[array addObject:info];
		status = [results nextAndReturnError:nil];
	}
	[results close];
	return array;
}

-(BOOL)addContactSyncInfo:(MMContactSyncInfo*)info {
	NSString* sql = @"INSERT INTO contact_sync (contact_id, phone_contact_id, modify_date, phone_modify_date, "
					@"avatar_url, avatar_part, avatar_md5) VALUES(?, ?, ?, ?, ?, ?, ?) ";


	if(![[self db]  executeUpdate:sql, 
		 [NSNumber numberWithInteger:info.contactId],
		 [NSNumber numberWithInteger:info.phoneContactId],
		 [NSNumber numberWithLongLong:info.modifyDate],
		 [NSNumber numberWithLongLong:info.phoneModifyDate],
		 info.avatarUrl,
		 info.avatarPart, 
		 info.avatarMd5 ]){

		return NO;
	}

	return YES;
}
-(BOOL)deleteContactSyncInfo:(NSInteger)contactId {
	NSString* sql = @"DELETE FROM contact_sync where contact_id = ? ";
	
	if(![[self db]  executeUpdate:sql, 
		 [NSNumber numberWithInteger:contactId]]) {
		return NO;
	}
	
	return YES;
}

-(BOOL)updateContactSyncInfo:(MMContactSyncInfo*)info {
	NSString* sql = @"UPDATE contact_sync SET "
					@"modify_date = ?, phone_modify_date = ?, avatar_url = ?, "
					@"avatar_part = ?, avatar_md5 = ? where contact_id = ? ";
	

	if(![[self db]  executeUpdate:sql, 
		 [NSNumber numberWithLongLong:info.modifyDate],
		 [NSNumber numberWithLongLong:info.phoneModifyDate],
		 info.avatarUrl,
		 info.avatarPart,
		 info.avatarMd5,
         [NSNumber numberWithInteger:info.contactId]]) {
		return NO;
	}
	return YES;
}

-(BOOL)setContactSyncInfoModifyTime:(int64_t)modifyTime contactId:(NSInteger)contactId{
	NSString* sql = @"UPDATE contact_sync SET modify_date = ? where contact_id = ? ";
	
	if(![[self db]  executeUpdate:sql, 
		 [NSNumber numberWithLongLong:modifyTime],
		 [NSNumber numberWithInteger:contactId]]) {
		return NO;
	}
	
	return YES;
}

-(BOOL)setContactSyncInfoPhoneModifyTime:(int64_t)modifyTime contactId:(NSInteger)contactId {
	NSString* sql = @"UPDATE contact_sync SET phone_modify_date = ? where contact_id = ? ";
	
	if(![[self db]  executeUpdate:sql, 
		 [NSNumber numberWithLongLong:modifyTime],
		 [NSNumber numberWithInteger:contactId]]) {
		return NO;
	}
	
	return YES;
}

-(NSData*)getAvatarPart:(NSData*)avatarData {
	return [avatarData subdataWithRange:NSMakeRange(0, MIN(128, avatarData.length))];
}

-(BOOL)addContactUp:(NSArray*)phoneContactIds addressBook:(ABAddressBookRef)addressBook {
	if ([phoneContactIds count] == 0) {
		return YES;
	}

	NSMutableArray *array = [NSMutableArray array];
	unsigned int index= 0;
	while (index < [phoneContactIds count]) {
		unsigned int len = MIN(10, [phoneContactIds count] - index);
        
        for (unsigned int i  = 0; i < len; i++) {
            NSNumber *phoneid = [phoneContactIds objectAtIndex:index + i];
            MMMomoContact* dbContact = [[[MMMomoContact alloc] init] autorelease];	
            ABRecordRef person = ABAddressBookGetPersonWithRecordID(addressBook, [phoneid intValue]);
            dbContact.avatarUrl = @"";
            NSMutableArray* dbDataList = [[[NSMutableArray alloc] init] autorelease];
            dbContact.phoneCid = [phoneid intValue];
            [MMAddressBook ABRecord2DbStruct:dbContact withDataList:dbDataList  withPerson:person];
            dbContact.properties = dbDataList;
            [array addObject:dbContact];
        }
        
		NSArray *response = nil;
		NSInteger statusCode = [MMServerContactManager addContacts:[array subarrayWithRange:NSMakeRange(index, len)] response:&response];
		if (statusCode != 200){
			MLOG(@"向服务器添加联系人失败, %@", [array subarrayWithRange:NSMakeRange(index, len)]);
			return NO;
		}
        
		if ([response count] != len) {
            assert(0);
			MLOG(@"服务器返回错误, ids:%@, response:%@", [array subarrayWithRange:NSMakeRange(index, len)], response);
			return NO;
		}
        
        [[[MMContactManager instance] db] beginTransaction];
		for (NSDictionary *dic in response) {
			MMMomoContact *contact = [array objectAtIndex:index];
			int status = [[dic objectForKey:@"status"] intValue];
			if ( 201 == status) {
				MMContactSyncInfo *info = [[[MMContactSyncInfo alloc] init] autorelease];	
				info.contactId = [[dic objectForKey:@"id"] intValue];
				info.phoneContactId = contact.phoneCid;
				info.modifyDate = [[dic objectForKey:@"modified_at"] longLongValue];
				info.phoneContactId = [[phoneContactIds objectAtIndex:index] intValue];//contact.phoneCid;
				NSDate *phoneModifyDate = [MMAddressBook getContactModifyDate:[[phoneContactIds objectAtIndex:index] intValue]];
				info.phoneModifyDate = [phoneModifyDate timeIntervalSince1970];
				info.avatarUrl = contact.avatarBigUrl;
				[self addContactSyncInfo:info];
#ifdef UPDATE_MOMO_DATEBASE
				contact.contactId = [[dic objectForKey:@"id"] intValue];
				contact.modifyDate = [[dic objectForKey:@"modified_at"] longLongValue];
				if ([[MMContactManager instance] insertContact:contact withDataList:contact.properties] == MM_DB_OK) {
					syncResult_.momoDownloadAddCount = syncResult_.momoDownloadAddCount + 1;
				}
#endif
			} else if (303 == status) {
				NSArray *array = [NSArray arrayWithObject:[dic objectForKey:@"id"]];
                
				NSArray *tmp = [self getContactSyncInfoList:array];
				if ([tmp count] == 0) {
					MMContactSyncInfo *info = [[[MMContactSyncInfo alloc] init] autorelease];	
					info.contactId = [[dic objectForKey:@"id"] intValue];
                    if(info.contactId == 72010)
                        NSLog(@"debug");
					info.phoneContactId = [[phoneContactIds objectAtIndex:index] intValue];
					info.modifyDate = [[dic objectForKey:@"modified_at"] longLongValue];
					info.phoneContactId = contact.phoneCid;
					NSDate *phoneModifyDate = [MMAddressBook getContactModifyDate:[[phoneContactIds objectAtIndex:index] intValue]];
					info.phoneModifyDate = [phoneModifyDate timeIntervalSince1970] ;
					info.avatarUrl = contact.avatarBigUrl;
					[self addContactSyncInfo:info];
                    
                    
				} else {
					MMContactSyncInfo *info = [tmp objectAtIndex:0];
					info.modifyDate = [[dic objectForKey:@"modified_at"] longLongValue];
					[self updateContactSyncInfo:info];
 
                    
					[MMAddressBook deleteContact:[[phoneContactIds objectAtIndex:index] intValue]];
				}
                
			} else {
				MLOG(@"添加联系人失败, statusCode:%d, %@", status, dic);
			}
            
			index++;
            syncProgress_.stageOperationIndex++;
		}
        [[[MMContactManager instance] db] commitTransaction];
	}
	return YES;
}

-(BOOL)deleteContactUp:(NSArray*)contactIds phoneCids:(NSArray*)phoneCids{
	if ([contactIds count] == 0) {
		return YES;
	}
    unsigned int index= 0;
    NSMutableArray *deleteErrorArr = [NSMutableArray array];
	while (index < [contactIds count]) {
		unsigned int len = MIN(10, [contactIds count] - index);

        NSArray *response = nil;
        if (![MMServerContactManager deleteContacts:[contactIds subarrayWithRange:NSMakeRange(index, len)] response:&response] ){
            MLOG(@"删除服务器联系人失败, %@", contactIds);
            return NO;
        }

        for (NSDictionary *dic in response) {
            //删除momo小秘 或者 删除失败的联系人。
            if ([[dic objectForKey:@"status"] intValue] != 200) {
                [deleteErrorArr addObject:[contactIds objectAtIndex:index]];
            }
        }
     
        index += len;
        syncProgress_.stageOperationIndex += len;
    }

	for (NSNumber *n in contactIds) {
		[self deleteContactSyncInfo:[n intValue]];
	}
    
	for (NSNumber *e in deleteErrorArr) {
        NSMutableDictionary *dic1 = [NSMutableDictionary dictionary];
        [dic1 setObject:e forKey:@"id"];
        [[NSNotificationCenter defaultCenter] postNotificationName:kMMMQContactChangedMsg
                                                            object:[NSArray arrayWithObject:dic1]];        
	}
        
	return YES;
}


-(BOOL)isAvatarChanged:(NSData*)avatar syncInfo:(MMContactSyncInfo*)info {
	NSData *part = [self getAvatarPart:avatar];
	if (0 == [part length] && 0 == [info.avatarPart length]) {
		return NO;
	}
	if([info.avatarPart isEqualToData:part]) {
		//todo check md5	
		return NO;
	}
	return YES;
}

-(BOOL)isAvatarDownFail:(MMContactSyncInfo*)info {
	if ([info.avatarUrl length] >= 2) {
		if([info.avatarUrl hasPrefix:@"#"] && [info.avatarUrl hasSuffix:@"#"]) {
			return YES;
		}
	}
	return NO;
}

- (BOOL)isBigAvatarUrl:(NSString*)avatarURL {
    NSString* str = [NSString stringWithFormat:@"_%d.", BIG_AVATAR_SIZE];
    return [avatarURL rangeOfString:str].location != NSNotFound;
}

-(BOOL)updateContactUp:(MMContactSyncInfo*)info  person:(ABRecordRef)person{
	MMMomoContact* dbContact = [[[MMMomoContact alloc] init] autorelease];	
	NSMutableArray* dbDataList = [[NSMutableArray alloc] init];
	dbContact.phoneCid = info.phoneContactId;
	dbContact.contactId = info.contactId;
	[MMAddressBook ABRecord2DbStruct:dbContact withDataList:dbDataList withPerson:person];
	dbContact.properties = dbDataList;
	[dbDataList release];
	dbContact.modifyDate = info.modifyDate;
    
    dbContact.avatarUrl = info.avatarUrl;
    if ([self isAvatarDownFail:info]) {
        NSRange range = NSMakeRange(1, [info.avatarUrl length] - 2);
        dbContact.avatarUrl = [info.avatarUrl substringWithRange:range];
    }
    

	NSDictionary *response = nil;
	NSInteger statusCode = [MMServerContactManager updateContact:dbContact response:&response];
	if (statusCode == 200 || statusCode == 303) {
		int64_t modifyDate = [[response  objectForKey:@"modified_at"] longLongValue];
		info.modifyDate = modifyDate;
		info.phoneModifyDate = [[MMAddressBook getContactModifyDate:info.phoneContactId] timeIntervalSince1970];
		[self updateContactSyncInfo:info];
		return YES;
	} else if(statusCode == 409) {
		NSArray *array = [NSArray arrayWithObject:dbContact];
		NSArray *addResponse = nil;
		NSInteger statusCode = [MMServerContactManager addContacts:array response:&addResponse];
		if (statusCode != 200){
			MLOG(@"向服务器添加联系人失败 status code:%d", statusCode);
			return NO;
		}
		[self deleteContactSyncInfo:info.contactId];
        
        NSMutableDictionary *dic1 = [NSMutableDictionary dictionary];
        [dic1 setObject:[NSNumber numberWithInt:info.contactId] forKey:@"id"];
        [dic1 setObject:[NSNumber numberWithLongLong:info.modifyDate]    forKey:@"modified_at"];
        [[NSNotificationCenter defaultCenter] postNotificationName:kMMMQContactChangedMsg 
                                                            object:[NSArray arrayWithObject:dic1]];
        
		NSAssert([addResponse count] == 1, @"len invalid");
		NSDictionary *dic = [addResponse objectAtIndex:0] ;
		info.contactId = [[dic objectForKey:@"id"] intValue];
		info.modifyDate = [[dic objectForKey:@"modified_at"] longLongValue];
		info.phoneModifyDate = [[MMAddressBook getContactModifyDate:info.phoneContactId] timeIntervalSince1970];
		[self addContactSyncInfo:info];
        
		return YES;
	} else {
        NSString *errorStr = [response  objectForKey:@"error"];
        if (errorStr.length >= 6 && [[errorStr substringToIndex:6] intValue] == 400215) {
            return YES;
        } 

		MLOG(@"修改服务器联系人失败 status code:%d", statusCode);	
		return NO;
	}
	return YES;
}

-(BOOL) uploadContact {
	NSMutableArray *idsToAdd = [NSMutableArray array];
	NSMutableArray *syncInfos = [self getContactSyncInfoList];
	
    ABAddressBookRef addressBook = ABAddressBookCreate();

    CFArrayRef peoples = ABAddressBookCopyArrayOfAllPeople(addressBook);

    {
        CFMutableArrayRef peopleMutable = CFArrayCreateMutableCopy(kCFAllocatorDefault,
                                                                   CFArrayGetCount(peoples),
                                                                   peoples
                                                                   );
        
        
        CFArraySortValues(peopleMutable,
                          CFRangeMake(0, CFArrayGetCount(peopleMutable)),
                          (CFComparatorFunction) ABPersonComparePeopleByName,
                          (void*)ABPersonGetSortOrdering()
                          );
        CFRelease(peoples);
        peoples = peopleMutable;
    }

    //获取须要上传的联系人
    CFIndex count = CFArrayGetCount(peoples);	
    for(CFIndex idx = 0; idx < count; ++idx){
        ABRecordRef person = CFArrayGetValueAtIndex(peoples, idx);
        
		CFTypeRef typeRef = ABRecordCopyValue(person, kABPersonModificationDateProperty);
		NSTimeInterval modifyDate = [(NSDate*)typeRef timeIntervalSince1970];
		CFRelease(typeRef);
		
        ABRecordID phoneid = ABRecordGetRecordID(person);
		
		int index = [syncInfos indexOfObjectPassingTest:^(id obj, NSUInteger idx, BOOL *stop){
			MMContactSyncInfo *info = (MMContactSyncInfo*)obj;
			if(info.phoneContactId == phoneid)
				return YES;
			return NO;
		}];
		
		if (NSNotFound == index) {
			[idsToAdd addObject:[NSNumber numberWithInteger:phoneid]];
		} else {
			MMContactSyncInfo *info = [syncInfos objectAtIndex:index];
			if (modifyDate > info.phoneModifyDate ) {
				if (![self updateContactUp:info person:person]) {
					CFRelease(peoples);
					CFRelease(addressBook);
					return NO;
				} else {
					syncResult_.uploadUpdateCount = syncResult_.uploadUpdateCount + 1;					
				}
			}

			[syncInfos removeObjectAtIndex:index];
		}
    }
    
    //获取本地已删除联系人
    NSMutableArray *contactIdsToDel = [NSMutableArray array];
	NSMutableArray *phoneContactIdsToDel = [NSMutableArray array];
	
	for (MMContactSyncInfo *info in syncInfos) {
		[contactIdsToDel addObject:[NSNumber numberWithInteger:info.contactId]];
		[phoneContactIdsToDel addObject:[NSNumber numberWithInteger:info.phoneContactId]];
	}
    
    syncProgress_.stageOperationCount = idsToAdd.count + contactIdsToDel.count;

    //上传本地新增联系人
	if (![self addContactUp:idsToAdd addressBook:addressBook]) {
        CFRelease(peoples);
        CFRelease(addressBook);
        return NO;
    }
	syncResult_.uploadAddCount = syncResult_.uploadAddCount + [idsToAdd count];

    //上传本地删除联系人
	[self deleteContactUp:contactIdsToDel phoneCids:phoneContactIdsToDel];
	syncResult_.uploadDelCount = syncResult_.uploadDelCount + [contactIdsToDel count];
    
    CFRelease(peoples);
	CFRelease(addressBook);
	return YES;
}


-(BOOL) deleteContactDown:(NSInteger)contactId {
	NSInteger cellId = [self getCellIdByContactId:contactId];
	if (0 == cellId) {
		return YES;
	}
	if ([MMAddressBook deleteContact:cellId] != MM_AB_OK) {
		MLOG(@"删除联系人失败, phone contact id:%d", cellId);
		return NO;
	}
	[self deleteContactSyncInfo:contactId];
	return YES;
}


-(BOOL) addContactDown:(MMMomoContact*)contact {
	NSInteger cellId = 0;
	MMABErrorType ret = [MMAddressBook insertContact:contact withDataList:contact.properties returnCellId:&cellId];
	if (ret != MM_AB_OK) {
		MLOG(@"添加联系人失败, contact id:%d", contact.contactId);
		return NO;
	}
	contact.phoneCid = cellId;

	MMContactSyncInfo *info = [[[MMContactSyncInfo alloc] init] autorelease];
	info.contactId = contact.contactId;
	info.phoneContactId = cellId;
	info.modifyDate = contact.modifyDate;
	info.phoneModifyDate = [[MMAddressBook getContactModifyDate:cellId] timeIntervalSince1970];
	info.avatarUrl = contact.avatarBigUrl;
	[self addContactSyncInfo:info];
	return YES;
}

-(BOOL) updateContactDown:(MMMomoContact*)contact {
    MMContactSyncInfo *info = [self getContactSyncInfo:contact.contactId];
    if (nil == info) {
        MLOG(@"update contct fail contactid:%d", contact.contactId);
        return NO;
    }
	[MMAddressBook updateContact:contact withDataList:contact.properties];
	info.modifyDate = contact.modifyDate;
	int64_t phoneModifyDate = [[MMAddressBook getContactModifyDate:info.phoneContactId] timeIntervalSince1970];
	info.phoneModifyDate = phoneModifyDate;
	info.avatarUrl = contact.avatarBigUrl;
	[self updateContactSyncInfo:info];
	return YES;
}

-(BOOL)downloadContactToMomo:(NSArray*)simpleList contacts:(NSMutableArray*)contacts {
	NSMutableArray *idsToDown = [NSMutableArray array];
	NSMutableArray *contactsToUpdate = [NSMutableArray array];
	
    //需要下载的联系人列表
	for (MMMomoContactSimple *c in simpleList) {
		int index = [contacts indexOfObjectPassingTest:^(id obj, NSUInteger idx, BOOL *stop){
			DbContactSyncInfo *info = (DbContactSyncInfo*)obj;
			if(info.contactId == c.contactId)
				return YES;
			return NO;
		}];
		
		if (NSNotFound == index) {
			[idsToDown addObject:[NSNumber numberWithInteger:c.contactId]];
		} else {
			DbContactSyncInfo *info = [contacts objectAtIndex:index];
			if (c.modifyDate > info.modifyDate ) {
				[idsToDown addObject:[NSNumber numberWithInteger:c.contactId]];
				[contactsToUpdate addObject:info];
			}
			[contacts removeObjectAtIndex:index];
		}
	}
	
    //需要删除本地的列表
    if (contacts.count > 0) {
        [[self db] beginTransaction];
        for (MMMomoContactSimple *c in contacts) {
            [[MMContactManager instance] deleteContact:c.contactId];
        }
        [[self db] commitTransaction];
    }
    
	syncResult_.momoDownloadDelCount = syncResult_.momoDownloadDelCount + [contacts count];
    syncProgress_.stageOperationCount = idsToDown.count;
    
    NSMutableArray* downloadedContacts = [NSMutableArray array];
    for (unsigned int i = 0; i < [idsToDown count]; i+= 50) {
		int len = MIN(50, [idsToDown count] - i);
		NSArray *array = [MMServerContactManager getContactList:[idsToDown subarrayWithRange:NSMakeRange(i, len)]];
        if (nil == array) {
            break;
        }
        [downloadedContacts addObjectsFromArray:array];
        
        [[self db] beginTransaction];
        for (MMMomoContact *contact in array ){
            int index = [contactsToUpdate indexOfObjectPassingTest:^(id obj, NSUInteger idx, BOOL *stop){
                DbContactSimple *info = (DbContactSimple*)obj;
                if(info.contactId == contact.contactId)
                    return YES;
                return NO;
            }];
            if (self.isCancelled) {
                break;
            }
            if (NSNotFound == index) {
                if ([[MMContactManager instance] insertContact:contact withDataList:contact.properties] != MM_DB_OK) {
                    MLOG(@"insert contact fail, contact id:%d", contact.contactId);
                }
                
                syncResult_.momoDownloadAddCount = syncResult_.momoDownloadAddCount + 1;

            } else {
                if ([[MMContactManager instance] updateContact:contact withDataList:contact.properties] != MM_DB_OK) {
                    MLOG(@"update contact fail contact id:%d", contact.contactId);
                }
                syncResult_.momoDownloadUpdateCount = syncResult_.momoDownloadUpdateCount + 1;
            }
            
            syncProgress_.stageOperationIndex++;
        }
        [[self db] commitTransaction];

        if (self.isCancelled) {
            return NO;
        }
	}
    
    if (idsToDown.count > downloadedContacts.count) {
        return NO;
    }
    
    if (self.isCancelled) {
        return NO;
    }

	return YES;
}

-(BOOL) downloadContactToMomo {
	NSArray *tmp = [[MMContactManager instance] getContactSyncInfoList:nil];
	NSMutableArray *syncInfos = [NSMutableArray arrayWithArray:tmp];
	NSArray *simpleList = [MMServerContactManager getSimpleContactList];
	if (nil == simpleList) {
		return NO;
	}
    
    //从服务器返回的数据为空,
    if (simpleList.count == 0) {
        NSLog(@"server db is empty");
    }
    
	return [self downloadContactToMomo:simpleList contacts:syncInfos];
}

-(BOOL) downloadContactToMomo:(NSArray*)simpleList {
	if ([simpleList count] == 0)
		return YES;
	NSMutableArray *array = [NSMutableArray array];
	for (MMMomoContactSimple *c in simpleList) {
		[array addObject:[NSNumber numberWithInteger:c.contactId]];
	}
	NSArray *tmp = [[MMContactManager instance] getContactSyncInfoList:array withError:nil];
	NSMutableArray *syncInfos = [NSMutableArray arrayWithArray:tmp];
	return [self downloadContactToMomo:simpleList contacts:syncInfos];
}

-(NSArray*)getContactListFromMomoDb:(NSArray*)ids {
	NSMutableArray *array = [NSMutableArray array];
	for (NSNumber *n in ids){
		NSInteger contactId = [n intValue];
		DbContact *tmp = [[MMContactManager instance] getContact:contactId withError:nil];
        MMMomoContact *contact = [[[MMMomoContact alloc] initWithContact:tmp] autorelease];
		NSArray *datas = [[MMContactManager instance] getDataList:contactId withError:nil];
		contact.properties = datas;
		[array addObject:contact];
	}

	return array;
}

-(BOOL) downloadContact:(NSArray*)simpleList infoList:(NSMutableArray*)syncInfos {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
	NSMutableArray *idsToDown = [NSMutableArray array];
	NSMutableArray *contactsToUpdate = [NSMutableArray array];

    NSMutableSet *set1 = [NSMutableSet setWithArray:simpleList];
    NSMutableSet *set2 = [NSMutableSet setWithArray:syncInfos];
    
    NSMutableSet *deletedSet = [NSMutableSet setWithSet:set2];
    [deletedSet minusSet:set1];
    NSMutableSet *addedSet = [NSMutableSet setWithSet:set1];
    [addedSet minusSet:set2];
    NSMutableSet *iset = [NSMutableSet setWithSet:set2];
    [iset intersectSet:set1];
    
    for (MMContactSyncInfo *info in deletedSet) {
        [self deleteContactDown:info.contactId];
    }
    
    syncResult_.downloadDelCount = syncResult_.downloadDelCount + [deletedSet count];
    
    for (MMMomoContactSimple *c in addedSet) {
        [idsToDown addObject:[NSNumber numberWithInt:c.contactId]];
    }
    
    syncProgress_.stageOperationCount = idsToDown.count;

	NSArray *addedArray = [self getContactListFromMomoDb:idsToDown];
    unsigned int index = 0;
    while (index < [addedArray count]) {
        if (self.isCancelled) {
            [pool release];
			return NO;
		}
        unsigned int len = MIN(100, [addedArray count] - index);
        NSArray *addedPhoneId = [MMAddressBook insertContacts:[addedArray subarrayWithRange:NSMakeRange(index, len)]];
        
        if (nil == addedPhoneId || [addedPhoneId count] != len) {
            [pool release];
            return NO;
        }
        
        NSMutableArray* addContactSyncArray = [NSMutableArray array];
        for (unsigned int i = index; i < index + len; i++) {
            MMMomoContact *contact = [addedArray objectAtIndex:i];

            NSString *oldUrl = [[contact.avatarUrl copy] autorelease];

            NSInteger cellId = [[addedPhoneId objectAtIndex:i - index] intValue];
            contact.phoneCid = cellId;
            
            MMContactSyncInfo *info = [[[MMContactSyncInfo alloc] init] autorelease];
            info.contactId = contact.contactId;
            info.phoneContactId = cellId;
            info.modifyDate = contact.modifyDate;
            info.phoneModifyDate = [[MMAddressBook getContactModifyDate:cellId] timeIntervalSince1970];
            info.avatarUrl = contact.avatarBigUrl; //下载大头像
            [addContactSyncArray addObject:info];
            contact.avatarUrl = oldUrl;
            syncResult_.downloadAddCount = syncResult_.downloadAddCount + 1; 
            syncProgress_.stageOperationIndex++;
        }
        
        //优化本地数据库写入
        [[self db] beginTransaction];
        for (MMContactSyncInfo* info in addContactSyncArray) {
            [self addContactSyncInfo:info];
        }
        [[self db] commitTransaction];
        
        index += len;
    }
    
    [idsToDown removeAllObjects];
    
    for (MMContactSyncInfo *info in iset) {
        MMMomoContactSimple *c = [set1 member:info];
        assert(c);
        if (c.modifyDate > info.modifyDate) {
            [idsToDown addObject:[NSNumber numberWithInteger:c.contactId]];
            [contactsToUpdate addObject:info];
        } 
    }

    NSArray *array2 = [self getContactListFromMomoDb:idsToDown];
    NSMutableSet *updatedSet = [NSMutableSet setWithArray:array2];
  
    for (MMMomoContact *contact in updatedSet) {
        MMContactSyncInfo *info = [iset member:contact];
        assert(info);
        contact.phoneCid = info.phoneContactId;
        NSString *oldUrl = [[contact.avatarUrl copy] autorelease];
        [self updateContactDown:contact];
        contact.avatarUrl = oldUrl;
        syncResult_.downloadUpdateCount = syncResult_.downloadUpdateCount + 1;
    }

    [pool release];
    
	return YES;
}

-(NSMutableArray*)getContactSimpleListFromMomoDb {
	NSMutableArray *array = [NSMutableArray array];
	NSArray *tmp = [[MMContactManager instance] getContactSyncInfoList:nil];
	for (DbContactSyncInfo *info in tmp) {
		MMMomoContactSimple *i = [[[MMMomoContactSimple alloc] init] autorelease];
		i.contactId = info.contactId;
		i.modifyDate = info.modifyDate;
		[array addObject:i];
	}
	return array;
}

-(BOOL) downloadContact:(NSArray*)simpleList {
	if ([simpleList count] == 0)
		return YES;
	NSMutableArray *array = [NSMutableArray array];
	for (MMMomoContactSimple *c in simpleList) {
		[array addObject:[NSNumber numberWithInteger:c.contactId]];
	}
	NSMutableArray *syncInfos = [self getContactSyncInfoList:array];
	return [self downloadContact:simpleList infoList:syncInfos];
}

-(BOOL) downloadContact{
	NSMutableArray *syncInfos = [self getContactSyncInfoList];
	NSArray *simpleList = [self getContactSimpleListFromMomoDb];
	return [self downloadContact:simpleList infoList:syncInfos];
}

@end
