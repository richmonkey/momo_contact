//
//  MMContactSync.m
//  momo
//
//  Created by houxh on 11-7-5.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "MMContactSync.h"
#import "MMUapRequest.h"
#import "DbStruct.h"
#import <AddressBook/AddressBook.h>
#import "MMAddressBook.h"
#import "SBJSON.h"
#import "MMServerContactManager.h"
#import "MMLogger.h"
#import "MMGlobalDefine.h"

@implementation MMSyncResult

@synthesize 	downloadAddCount, downloadDelCount, downloadUpdateCount, uploadAddCount, 
				uploadDelCount, uploadUpdateCount;


@end


@interface MMContactSyncInfo : DbContactId
{
    int32_t phoneContactId;
    int64_t modifyDate;
    int64_t phoneModifyDate;
    NSString *avatarUrl;
    NSData *avatarPart;
    NSString *avatarMd5;
    
}
@property(nonatomic)int32_t phoneContactId;
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


@implementation MMContactSync


@synthesize syncResult = syncResult_;

-(id)init {
	self = [super init];
	if (self) {
		syncResult_	= [[MMSyncResult alloc] init];
	}
	return self;
}
-(void)dealloc {
	[syncResult_ release];
	[super dealloc];
}

-(BOOL) isCancelled {
	MMThread *thread = [MMThread currentThread];
	MMHttpRequestThread *requestThread = nil;
	
	if ([thread isKindOfClass:[MMHttpRequestThread class]]) {
		requestThread = (MMHttpRequestThread*)thread;
	}

	return requestThread.isCancelled;
}



-(BOOL) clearSyncDb {
	if (![[self db]  executeUpdate:@"delete from category_member_sync"]) {
		MLOG(@"delete from about fail");            
		return NO;
	} 
	
	if (![[self db]  executeUpdate:@"delete from category_sync"]) {
		MLOG(@"delete from about fail"); 
		return NO;
	} 
	
	if (![[self db]  executeUpdate:@"delete from contact_sync"]) {
		MLOG(@"delete from feed fail"); 
		return NO;
	} 

	return YES;
}

-(int64_t)getContactIdByCellId:(int32_t)cellId {
    NSError *outError = nil;
    NSString* sql = @"select contact_id from contact_sync where phone_contact_id = ? ";
    id<PLResultSet> results = [[self db]  executeQueryAndReturnError:&outError statement:sql, [NSNumber numberWithInt:cellId]];
    
    if(SQLITE_OK != [outError code]) {
        return 0;
    }
    
    PLResultSetStatus status = [results nextAndReturnError:nil];
    
    int64_t contactId = 0;
    if(status) {
        contactId = [results bigIntForColumn:@"contact_id"];
    }
    
    [results close];
    return contactId;
}
-(int32_t)getCellIdByContactId:(int64_t)contactId {
    NSError *outError = nil;
    NSString* sql = @"select phone_contact_id from contact_sync where contact_id = ? ";
    id<PLResultSet> results = [[self db]  executeQueryAndReturnError:&outError statement:sql, [NSNumber numberWithLongLong:contactId]];
    
    if(SQLITE_OK != [outError code]) {
        return 0;
    }
    
    PLResultSetStatus status = [results nextAndReturnError:nil];
    
    int32_t cellId = 0;
    if(status) {
        cellId = [results intForColumn:@"phone_contact_id"];
    }
    
    [results close];
    return cellId;
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
-(MMContactSyncInfo*)getContactSyncInfo:(int64_t)contactId {
    NSMutableArray *array = [self getContactSyncInfoList:[NSArray arrayWithObject:[NSNumber numberWithLongLong:contactId]]];
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
         [NSNumber numberWithLongLong:info.contactId],
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
-(BOOL)deleteContactSyncInfo:(int64_t)contactId {
    NSString* sql = @"DELETE FROM contact_sync where contact_id = ? ";
    
    if(![[self db]  executeUpdate:sql,
         [NSNumber numberWithLongLong:contactId]]) {
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
         [NSNumber numberWithLongLong:info.contactId]]) {
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
        unsigned int len = (unsigned int)MIN(50, [phoneContactIds count] - index);
        
        for (unsigned int i  = 0; i < len; i++) {
            NSNumber *phoneid = [phoneContactIds objectAtIndex:index + i];
            MMMomoContact* dbContact = [[[MMMomoContact alloc] init] autorelease];
            ABRecordRef person = ABAddressBookGetPersonWithRecordID(addressBook, [phoneid intValue]);
            NSMutableArray* dbDataList = [[[NSMutableArray alloc] init] autorelease];
            dbContact.phoneCid = [phoneid intValue];
            [MMAddressBook ABRecord2DbStruct:dbContact withDataList:dbDataList  withPerson:person];
            dbContact.properties = dbDataList;
            [array addObject:dbContact];
            MLOG(@"upload phone contact:%@", phoneid);
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
        
        
        [[self db] beginTransaction];
        for (NSDictionary *dic in response) {
            MMMomoContact *contact = [array objectAtIndex:index];
            int status = [[dic objectForKey:@"status"] intValue];
            if (201 == status) {
                
                MMContactSyncInfo *info = [[[MMContactSyncInfo alloc] init] autorelease];
                info.contactId = [[dic objectForKey:@"id"] intValue];
                info.phoneContactId = contact.phoneCid;
                info.modifyDate = [[dic objectForKey:@"modified_at"] longLongValue];
                info.phoneContactId = [[phoneContactIds objectAtIndex:index] intValue];//contact.phoneCid;
                NSDate *phoneModifyDate = [MMAddressBook getContactModifyDate:[[phoneContactIds objectAtIndex:index] intValue]];
                info.phoneModifyDate = [phoneModifyDate timeIntervalSince1970];
                [self addContactSyncInfo:info];
                MLOG(@"upload phone contact:%ld success, contact id:%ld", (long)contact.phoneCid, (long)info.contactId);
            } else if (303 == status) {
                NSArray *array = [NSArray arrayWithObject:[dic objectForKey:@"id"]];
                
                NSArray *tmp = [self getContactSyncInfoList:array];
                if ([tmp count] == 0) {
                    //本地不存在与此重复的联系人
                    MMContactSyncInfo *info = [[[MMContactSyncInfo alloc] init] autorelease];
                    info.contactId = [[dic objectForKey:@"id"] intValue];
                    info.phoneContactId = [[phoneContactIds objectAtIndex:index] intValue];
                    info.modifyDate = [[dic objectForKey:@"modified_at"] longLongValue];
                    info.phoneContactId = contact.phoneCid;
                    NSDate *phoneModifyDate = [MMAddressBook getContactModifyDate:[[phoneContactIds objectAtIndex:index] intValue]];
                    info.phoneModifyDate = [phoneModifyDate timeIntervalSince1970] ;
                    [self addContactSyncInfo:info];
                    MLOG(@"upload phone contact:%ld, contact id:%ld exists", (long)info.phoneContactId, (long)info.contactId);
                } else {
                    //本地存在与此重复的联系人
                    MLOG(@"delete repeat phone contact:%ld", (long)[[phoneContactIds objectAtIndex:index] intValue]);
                    [MMAddressBook deleteContact:[[phoneContactIds objectAtIndex:index] intValue]];
                }
            } else {
                MLOG(@"添加联系人失败, statusCode:%d, %@", status, dic);
            }
            
            index++;
        }
        [[self db] commitTransaction];
    }
    return YES;
}

-(BOOL)deleteContactUp:(NSArray*)contactIds phoneCids:(NSArray*)phoneCids{
    if ([contactIds count] == 0) {
        return YES;
    }
    unsigned int index= 0;
    while (index < [contactIds count]) {
        unsigned int len = (int)MIN(10, [contactIds count] - index);
        
        NSArray *response = nil;
        if (![MMServerContactManager deleteContacts:[contactIds subarrayWithRange:NSMakeRange(index, len)] response:&response] ){
            MLOG(@"删除服务器联系人失败, %@", contactIds);
            return NO;
        }
        
        for (NSDictionary *dic in response) {
            //删除momo小秘 或者 删除失败的联系人。
            if ([[dic objectForKey:@"status"] intValue] != 200) {
                MLOG(@"delete contact:%@ status:%d", [contactIds objectAtIndex:index], [[dic objectForKey:@"status"] intValue]);
            }
        }
        
        index += len;
    }
    
    for (NSNumber *n in contactIds) {
        [self deleteContactSyncInfo:[n intValue]];
        MLOG(@"delete contact id:%lld", [n longLongValue]);
    }
    return YES;
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

    NSDictionary *response = nil;
    NSInteger statusCode = [MMServerContactManager updateContact:dbContact response:&response];
    if (statusCode == 200 || statusCode == 303) {
        int64_t modifyDate = [[response  objectForKey:@"modified_at"] longLongValue];
        info.modifyDate = modifyDate;
        info.phoneModifyDate = [[MMAddressBook getContactModifyDate:info.phoneContactId] timeIntervalSince1970];
        [self updateContactSyncInfo:info];
        MLOG(@"update phone contact:%d contact:%lld to server success", info.phoneContactId, (int64_t)info.contactId);
        return YES;
    } else if(statusCode == 409) {
        NSArray *array = [NSArray arrayWithObject:dbContact];
        NSArray *addResponse = nil;
        NSInteger statusCode = [MMServerContactManager addContacts:array response:&addResponse];
        if (statusCode != 200){
            MLOG(@"向服务器添加联系人失败 status code:%zd", statusCode);
            return NO;
        }
        [self deleteContactSyncInfo:info.contactId];
        
        NSAssert([addResponse count] == 1, @"len invalid");
        NSDictionary *dic = [addResponse objectAtIndex:0] ;
        info.contactId = [[dic objectForKey:@"id"] intValue];
        info.modifyDate = [[dic objectForKey:@"modified_at"] longLongValue];
        info.phoneModifyDate = [[MMAddressBook getContactModifyDate:info.phoneContactId] timeIntervalSince1970];
        [self addContactSyncInfo:info];
        MLOG(@"add conflicted phone conatct:%ld contact id:%lld to server", (long)info.phoneContactId, (int64_t)info.contactId);
        
        return YES;
    } else {
        NSString *errorStr = [response  objectForKey:@"error"];
        if (errorStr.length >= 6 && [[errorStr substringToIndex:6] intValue] == 400215) {
            return YES;
        }
        
        MLOG(@"修改服务器联系人失败 status code:%zd", statusCode);
        return NO;
    }
    return YES;
}

-(BOOL) uploadContact {
    NSMutableArray *idsToAdd = [NSMutableArray array];
    NSMutableArray *syncInfos = [self getContactSyncInfoList];
    
    ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, NULL);
    
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
        
        NSInteger index = [syncInfos indexOfObjectPassingTest:^(id obj, NSUInteger idx, BOOL *stop){
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
    
    //上传本地新增联系人
    if (![self addContactUp:idsToAdd addressBook:addressBook]) {
        CFRelease(peoples);
        CFRelease(addressBook);
        return NO;
    }
    syncResult_.uploadAddCount = syncResult_.uploadAddCount + [idsToAdd count];
    
    //获取本地已删除联系人
    NSMutableArray *contactIdsToDel = [NSMutableArray array];
    NSMutableArray *phoneContactIdsToDel = [NSMutableArray array];
    
    for (MMContactSyncInfo *info in syncInfos) {
        [contactIdsToDel addObject:[NSNumber numberWithLongLong:info.contactId]];
        [phoneContactIdsToDel addObject:[NSNumber numberWithInteger:info.phoneContactId]];
    }
    
    //上传本地删除联系人
    [self deleteContactUp:contactIdsToDel phoneCids:phoneContactIdsToDel];
    syncResult_.uploadDelCount = syncResult_.uploadDelCount + [contactIdsToDel count];
    
    CFRelease(peoples);
    CFRelease(addressBook);
    return YES;
}


-(BOOL) deleteContactDown:(int64_t)contactId {
    int32_t cellId = [self getCellIdByContactId:contactId];
    if (0 == cellId) {
        return YES;
    }
    if ([MMAddressBook deleteContact:cellId] != MM_AB_OK) {
        MLOG(@"删除联系人失败, phone contact id:%zd", cellId);
        return NO;
    }
    [self deleteContactSyncInfo:contactId];
    MLOG(@"delete phone contact:%zd contact id:%lld from phone", cellId, (int64_t)contactId);
    return YES;
}


-(BOOL) addContactDown:(MMMomoContact*)contact {
    int32_t cellId = 0;
    MMABErrorType ret = [MMAddressBook insertContact:contact withDataList:contact.properties returnCellId:&cellId];
    if (ret != MM_AB_OK) {
        MLOG(@"添加联系人失败, contact id:%lld", contact.contactId);
        return NO;
    }
    contact.phoneCid = cellId;
    
    MMContactSyncInfo *info = [[[MMContactSyncInfo alloc] init] autorelease];
    info.contactId = contact.contactId;
    info.phoneContactId = cellId;
    info.modifyDate = contact.modifyDate;
    info.phoneModifyDate = [[MMAddressBook getContactModifyDate:cellId] timeIntervalSince1970];
    [self addContactSyncInfo:info];
    return YES;
}

-(BOOL) updateContactDown:(MMMomoContact*)contact {
    MMContactSyncInfo *info = [self getContactSyncInfo:contact.contactId];
    if (nil == info) {
        MLOG(@"update contct fail contactid:%lld", contact.contactId);
        return NO;
    }
    [MMAddressBook updateContact:contact withDataList:contact.properties];
    info.modifyDate = contact.modifyDate;
    int64_t phoneModifyDate = [[MMAddressBook getContactModifyDate:info.phoneContactId] timeIntervalSince1970];
    info.phoneModifyDate = phoneModifyDate;
    [self updateContactSyncInfo:info];
    return YES;
}

-(BOOL)downloadContact:(NSArray*)simpleList contacts:(NSMutableArray*)contacts {
    NSMutableArray *idsToAdd = [NSMutableArray array];
    NSMutableArray *idsToUpdate = [NSMutableArray array];
    NSMutableArray *contactsToUpdate = [NSMutableArray array];
    
    //需要下载的联系人列表
    for (MMMomoContactSimple *c in simpleList) {
        NSInteger index = [contacts indexOfObjectPassingTest:^(id obj, NSUInteger idx, BOOL *stop){
            MMContactSyncInfo *info = (MMContactSyncInfo*)obj;
            if(info.contactId == c.contactId)
                return YES;
            return NO;
        }];
        
        if (NSNotFound == index) {
            [idsToAdd addObject:[NSNumber numberWithLongLong:c.contactId]];
        } else {
            MMContactSyncInfo *info = [contacts objectAtIndex:index];
            if (c.modifyDate > info.modifyDate ) {
                [idsToUpdate addObject:[NSNumber numberWithLongLong:c.contactId]];
                [contactsToUpdate addObject:info];
            }
            [contacts removeObjectAtIndex:index];
        }
    }
    
    //需要删除本地的列表
    if (contacts.count > 0) {
        for (MMContactSyncInfo *c in contacts) {
            [self deleteContactDown:c.contactId];
        }
    }
    
    syncResult_.downloadDelCount = syncResult_.downloadDelCount + [contacts count];
    
    NSMutableArray* downloadedContacts = [NSMutableArray array];
    
    for (unsigned int i = 0; i < [idsToAdd count]; i+= 50) {
        int len = (int)MIN(50, [idsToAdd count] - i);
        NSArray *array = [MMServerContactManager getContactList:[idsToAdd subarrayWithRange:NSMakeRange(i, len)]];
        if (nil == array) {
            break;
        }
        [downloadedContacts addObjectsFromArray:array];
        
        
        NSArray *addedPhoneId = [MMAddressBook insertContacts:array];
        
        if (nil == addedPhoneId || [addedPhoneId count] != [array count]) {
            return NO;
        }
        
        NSMutableArray* addContactSyncArray = [NSMutableArray array];
        for (unsigned int i = 0; i < [array count]; i++) {
            MMMomoContact *contact = [array objectAtIndex:i];
            
            int32_t cellId = [[addedPhoneId objectAtIndex:i] intValue];
            contact.phoneCid = cellId;
            
            MMContactSyncInfo *info = [[[MMContactSyncInfo alloc] init] autorelease];
            info.contactId = contact.contactId;
            info.phoneContactId = cellId;
            info.modifyDate = contact.modifyDate;
            info.phoneModifyDate = [[MMAddressBook getContactModifyDate:cellId] timeIntervalSince1970];
            [addContactSyncArray addObject:info];
            
            MLOG(@"add contact:%lld, phone contact id:%d to phone", (int64_t)info.contactId, info.phoneContactId);
            syncResult_.downloadAddCount = syncResult_.downloadAddCount + 1;
        }
        
        //优化本地数据库写入
        [[self db] beginTransaction];
        for (MMContactSyncInfo* info in addContactSyncArray) {
            [self addContactSyncInfo:info];
        }
        [[self db] commitTransaction];
        
        if (self.isCancelled) {
            return NO;
        }
    }
    
    if (idsToAdd.count > downloadedContacts.count) {
        return NO;
    }
    
    
    downloadedContacts = [NSMutableArray array];
    
    for (unsigned int i = 0; i < [idsToUpdate count]; i+= 50) {
        int len = (int)MIN(50, [idsToUpdate count] - i);
        NSArray *array = [MMServerContactManager getContactList:[idsToUpdate subarrayWithRange:NSMakeRange(i, len)]];
        if (nil == array) {
            break;
        }
        [downloadedContacts addObjectsFromArray:array];
        
        [[self db] beginTransaction];
        for (MMMomoContact *contact in array ){
            NSInteger index = [contactsToUpdate indexOfObjectPassingTest:^(id obj, NSUInteger idx, BOOL *stop){
                MMContactSyncInfo *info = (MMContactSyncInfo*)obj;
                if(info.contactId == contact.contactId)
                    return YES;
                return NO;
            }];
            assert(index != NSNotFound);
            MMContactSyncInfo *info = [contactsToUpdate objectAtIndex:index];
            assert(info);
            contact.phoneCid = info.phoneContactId;
            [self updateContactDown:contact];
            
            MLOG(@"update contact:%lld phone contact id:%d to phone", (int64_t)info.contactId, info.phoneContactId);
            syncResult_.downloadUpdateCount = syncResult_.downloadUpdateCount + 1;
        }
        [[self db] commitTransaction];
        
        if (self.isCancelled) {
            return NO;
        }
    }
    
    if (idsToUpdate.count > downloadedContacts.count) {
        return NO;
    }
    
    return YES;
}

-(BOOL) downloadContact {
    NSMutableArray *syncInfos = [self getContactSyncInfoList];
    NSArray *simpleList = [MMServerContactManager getSimpleContactList];
    if (nil == simpleList) {
        return NO;
    }
    
    //从服务器返回的数据为空,
    if (simpleList.count == 0) {
        MLOG(@"server db is empty");
    }
    
    return [self downloadContact:simpleList contacts:syncInfos];
}


@end
