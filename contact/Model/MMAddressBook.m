//
//  MMAddressBook.m
//  Momo
//
//  Created by zdh on 5/14/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//
#import "MMAddressBook.h"
#import <AddressBook/AddressBook.h>
#import "JSON.h"
#import "GTMBase64.h"

#define PARSE_NULL_STR(nsstr) nsstr ? nsstr : @""

@interface MMAddressBook()

+(NSString*) getIphoneLabelByMMLabel:(NSString*)label andByProperty:(NSInteger) property;

+(NSString*) getTelIphoneLabelByMMLabel:(NSString*)label;

+(NSString*) getMailIphoneLabelByMMLabel:(NSString*)label;

+(NSString*) getIMIphoneLabelByMMLabel:(NSString*)label;

+(NSString*) getURLIphoneLabelByMMLabel:(NSString*)label;

+(NSString*) getPersonIphoneLabelByMMLabel:(NSString*)label;

+(NSString*) getAdrIphoneLabelByMMLabel:(NSString*)label;

+(NSString*) getBdayIphoneLabelByMMLabel:(NSString*)label;

+(NSString*) getMMLabelByIphoneLabel:(NSString*)label andByProperty:(NSInteger) property;

+(NSString*) getTelMMLabelByIphoneLabel:(NSString*)label;

+(NSString*) getMailMMLabelByIphoneLabel:(NSString*)label;

+(NSString*) getIMMMLabelByIphoneLabel:(NSString*)label;

+(NSString*) getURLMMLabelByIphoneLabel:(NSString*)label;

+(NSString*) getPersonMMLabelByIphoneLabel:(NSString*)label;

+(NSString*) getAdrMMLabelByIphoneLabel:(NSString*)label;

+(NSString*) getBdayMMLabelByIphoneLabel:(NSString*)label;

+(MMABErrorType)setRecordData:(ABRecordRef) person andDatalist:(NSArray*) listData;

+ (DbContact*)getContact:(int32_t)cellId withError:(MMABErrorType*)error;



+ (BOOL)dbContactFromABRecord:(DbContact*)dbContact abRecord:(ABRecordRef)person;

+ (BOOL)dbDataListFromABRecord:(NSMutableArray*)dbDataList abRecord:(ABRecordRef)person;

@end

@implementation MMAddressBook

+ (MMErrorType)clearAddressBook {
    //删除AddressBook		
    ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, NULL);
    CFArrayRef people = ABAddressBookCopyArrayOfAllPeople(addressBook);
    CFIndex count = CFArrayGetCount(people);	
    
    CFErrorRef errorRef = nil;
    for(CFIndex idx = 0; idx < count; ++idx){						
        ABRecordRef person = CFArrayGetValueAtIndex(people, idx);		
        ABAddressBookRemoveRecord(addressBook, person, &errorRef);			
    }
    CFRelease(people);
    
    //删除category
    CFArrayRef groups = ABAddressBookCopyArrayOfAllGroups(addressBook);
    CFIndex count_group = CFArrayGetCount(groups);		
    for(CFIndex idx = 0; idx < count_group; ++idx) {
        ABRecordRef group = CFArrayGetValueAtIndex(groups, idx);
        ABAddressBookRemoveRecord(addressBook, group, &errorRef) ;
    }
    CFRelease(groups);
    ABAddressBookSave(addressBook, &errorRef);		
    CFRelease(addressBook);
    NSLog(@"success: delete from addressBook ");
    return MM_AB_OK;
}

NSString* formatTelNumber(NSString* strTel){
    int count = [strTel length];
    NSString* str = @"";
    for(int i = 0; i < count; i++){
        char ch = [strTel characterAtIndex:i];
        if((ch >= '0' && ch <= '9') || ch == '+')
            str = [str stringByAppendingFormat:@"%c", ch];
    }
    return str;
}

+(MMABErrorType)setRecordData:(ABRecordRef) person andDatalist:(NSArray*) listData {
    NSMutableDictionary* multiValueDictionary = [NSMutableDictionary dictionary];
    
    CFErrorRef errorRef = nil;
    
    MMABErrorType ret = MM_DB_OK;
    
    do {
        for(DbData* data in listData) {
            ABPropertyID aPropertyID = 0;
            ABPropertyType aPropertyType = kABInvalidPropertyType;
            switch(data.property){
                case kMoTel:
                    aPropertyID = kABPersonPhoneProperty;
                    aPropertyType = kABMultiStringPropertyType;
                    break;
                case kMoMail:
                    aPropertyID = kABPersonEmailProperty;
                    aPropertyType = kABMultiStringPropertyType;
                    break;
                case kMoUrl:
                    aPropertyID = kABPersonURLProperty;
                    aPropertyType = kABMultiStringPropertyType;
                    break;
                case kMoAdr:
                    aPropertyID = kABPersonAddressProperty;
                    aPropertyType = kABMultiDictionaryPropertyType;
                    break;
                case kMoBday:
                    aPropertyID = kABPersonDateProperty;
                    aPropertyType = kABMultiDateTimePropertyType;
                    break;
                case kMoPerson:
                    aPropertyID = kABPersonRelatedNamesProperty;
                    aPropertyType = kABMultiStringPropertyType;
                    break;
                case kMoImAIM:
                case kMoImJabber:
                case kMoImMSN:
                case kMoImYahoo:
                case kMoImICQ:
                case kMoIm91U:
                case kMoImQQ:
                case kMoImGtalk:
                case kMoImSkype:
                    aPropertyID = kABPersonInstantMessageProperty;
                    aPropertyType = kABMultiDictionaryPropertyType;
                    break;
            }
            
            if(!aPropertyID) {
                ret = MM_AB_FAILED;
                break;
            }
        
            ABMutableMultiValueRef multiData = (ABMutableMultiValueRef)[multiValueDictionary valueForKey:[NSString stringWithFormat:@"%d", aPropertyID]];
			
            BOOL isValueNeedsRelease = NO;
            if(!multiData) {
                isValueNeedsRelease = YES;
//                multiData = ABMultiValueCreateMutable(aPropertyID);
                multiData = ABMultiValueCreateMutable(aPropertyType);
                [multiValueDictionary setObject:(id)multiData forKey:[NSString stringWithFormat:@"%d", aPropertyID]];
            }
            
            CFStringRef label = (CFStringRef)[MMAddressBook getIphoneLabelByMMLabel:data.label andByProperty:data.property];
            switch(data.property){
                case kMoTel:
                case kMoMail:
                case kMoUrl:
                case kMoPerson:
                    ABMultiValueAddValueAndLabel(multiData, data.value, label, nil);
                    break;
                case kMoAdr:{
                    SBJSON* sbjson = [SBJSON new];
                    NSMutableArray *listItems = [sbjson objectWithString:data.value];
                    [sbjson release];
					
                    NSMutableDictionary* dictKey = [NSMutableDictionary dictionary];
                    [dictKey setObject:(NSString*)kABPersonAddressStreetKey forKey:[NSString stringWithFormat:@"%d", 2]];
                    [dictKey setObject:(NSString*)kABPersonAddressCityKey forKey:[NSString stringWithFormat:@"%d", 3]];
                    [dictKey setObject:(NSString*)kABPersonAddressStateKey forKey:[NSString stringWithFormat:@"%d", 4]];
                    [dictKey setObject:(NSString*)kABPersonAddressZIPKey forKey:[NSString stringWithFormat:@"%d", 5]];
                    [dictKey setObject:(NSString*)kABPersonAddressCountryKey forKey:[NSString stringWithFormat:@"%d", 6]];
                    
                    NSMutableDictionary* addressDict = [NSMutableDictionary dictionary];
                    for(int i = 2; i < 7; i++) {
                        NSString* str = [listItems objectAtIndex:i];
                        if(str && ![str isEqualToString:@""])
                            [addressDict setObject:str forKey:(NSString*)[dictKey valueForKey:[NSString stringWithFormat:@"%d", i]]];
                    }
                    ABMultiValueAddValueAndLabel(multiData, addressDict, label, nil);
                }
                    break;
                case kMoBday: 
                    if(data.value && ![data.value isEqualToString:@""]) {
                        NSDateFormatter* formater = [NSDateFormatter new];
                        [formater setDateFormat:@"YYYY-MM-dd"];
                        NSDate* date = [formater dateFromString:data.value];
                        [formater release];
                        if (date)
                            ABMultiValueAddValueAndLabel(multiData, date, label, nil);
                    }
                    break;
                case kMoImAIM:
                case kMoImJabber:
                case kMoImMSN:
                case kMoImYahoo:
                case kMoImICQ:
                case kMoIm91U:
                case kMoImQQ:
                case kMoImGtalk:
                case kMoImSkype:
                    if(data.value && ![data.value isEqualToString:@""]) {
                        CFStringRef aService = kABPersonInstantMessageServiceICQ;
						
                        switch(data.property) {
                            case kMoImAIM:
                                aService = kABPersonInstantMessageServiceAIM;
                                break;
                            case kMoImJabber:
                                aService = kABPersonInstantMessageServiceJabber;
                                break;
                            case kMoImMSN:
                                aService = kABPersonInstantMessageServiceMSN;
                                break;
                            case kMoImYahoo:
                                aService = kABPersonInstantMessageServiceYahoo;
                                break;	
							case kMoImICQ:
								aService = kABPersonInstantMessageServiceICQ;
								break;
							case kMoIm91U:
								aService = (CFStringRef)@"91U";   //这些key（如 kABPersonInstantMessageServiceQQ等）没有对外开放。先用自己定义的字符串代替。
								break;
							case kMoImQQ:
								aService = (CFStringRef)@"QQ";
								break;
							case kMoImGtalk:
								aService = (CFStringRef)@"Gtalk";
								break;
							case kMoImSkype:
								aService = (CFStringRef)@"Skype";
								break;
							default:
								aService = kABPersonInstantMessageServiceICQ;
								break;
                        }
                        NSMutableDictionary* instanceMessage = [NSMutableDictionary dictionary];
                        [instanceMessage setObject:(NSString*)aService forKey:(NSString*)kABPersonInstantMessageServiceKey];
                        [instanceMessage setObject:data.value forKey:(NSString*)kABPersonInstantMessageUsernameKey];
                        ABMultiValueAddValueAndLabel(multiData, instanceMessage, label, nil);
                    }
                    break;
            }
            
            if (isValueNeedsRelease) {
                CFRelease(multiData);
            }
        }
        
        for(NSString* key in [multiValueDictionary allKeys]) {
            ABPropertyID aPropertyID = [key intValue];
            ABMutableMultiValueRef multiData = (ABMutableMultiValueRef)[multiValueDictionary valueForKey:key];
            ABRecordSetValue(person, aPropertyID, multiData, &errorRef);
        }
    }
    while(0);
    
    return ret;
}

+(int)getContactCount {
    ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, NULL);
    CFIndex count = ABAddressBookGetPersonCount(addressBook);
    CFRelease(addressBook);
    return (int)count;
}

+(NSArray*) getContactSyncInfoList {
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
    
    NSMutableArray* contactSimplelist = [NSMutableArray array];
    CFIndex count = CFArrayGetCount(peoples);
    for(NSUInteger i = 0; i < count; ++i) {
        ABRecordRef person = (ABRecordRef) CFArrayGetValueAtIndex(peoples, i);
        
        
        DbContactSyncInfo* contact = [DbContactSyncInfo new];
        NSInteger cellId = ABRecordGetRecordID(person);
        contact.contactId = cellId;
        CFTypeRef modifydateRef = ABRecordCopyValue(person, kABPersonModificationDateProperty);
        NSDate* modifydate = (NSDate*)modifydateRef;
        contact.modifyDate = [modifydate timeIntervalSince1970];
        CFRelease(modifydateRef);
        [contactSimplelist addObject:contact];
        [contact release];
    }
    CFRelease(peoples);
    CFRelease(addressBook);
    return contactSimplelist;
}

+(MMFullContact*)getContact:(int32_t)cellId {
    ABAddressBookRef abAddressbook = ABAddressBookCreateWithOptions(NULL, NULL);
    ABRecordRef person = ABAddressBookGetPersonWithRecordID(abAddressbook, cellId);
    if(nil == person) {
        CFRelease(abAddressbook);
        return nil;
    }
    NSMutableArray *datas = [NSMutableArray array];
    MMFullContact *contact = [[[MMFullContact alloc] init] autorelease];
    if (![self ABRecord2DbStruct:contact withDataList:datas withPerson:person]) {
        CFRelease(abAddressbook);
        return nil;
    }
    contact.properties = datas;
    contact.phoneCid = cellId;
    CFRelease(abAddressbook);
    return contact;
}

/*
 *用DbContact和DataList来创建ABPerson。
 */
+(ABRecordRef)ABRecordFromDbStruct:(DbContact *)dbcontact withDataList:(NSArray *)listData {
    CFErrorRef errorRef = NULL; 
    
    ABRecordRef newPerson = ABPersonCreate();
    
        //firstname
	if (nil == dbcontact.firstName) {
		dbcontact.firstName = @"";
	}
	ABRecordSetValue(newPerson, kABPersonFirstNameProperty, dbcontact.firstName, &errorRef);
    
        //中间名字
	if(dbcontact.middleName && [dbcontact.middleName caseInsensitiveCompare:@""] != NSOrderedSame) {
		ABRecordSetValue(newPerson, kABPersonMiddleNameProperty, dbcontact.middleName, &errorRef);
	}
    
        //lastname
	if(dbcontact.lastName && [dbcontact.lastName caseInsensitiveCompare:@""] != NSOrderedSame) {
		ABRecordSetValue(newPerson, kABPersonLastNameProperty, dbcontact.lastName, &errorRef);
	}
    
        //公司
    if(dbcontact.organization && [dbcontact.organization caseInsensitiveCompare:@""] != NSOrderedSame)
        ABRecordSetValue(newPerson, kABPersonOrganizationProperty, dbcontact.organization, &errorRef);
    
        //部门
    if(dbcontact.department && [dbcontact.department caseInsensitiveCompare:@""] != NSOrderedSame)
        ABRecordSetValue(newPerson, kABPersonDepartmentProperty, dbcontact.department, &errorRef);
    
        //备注
    if(dbcontact.note && [dbcontact.note caseInsensitiveCompare:@""] != NSOrderedSame)
        ABRecordSetValue(newPerson, kABPersonNoteProperty, dbcontact.note, &errorRef);
    
        //生日
    if(dbcontact.birthday)
        ABRecordSetValue(newPerson, kABPersonBirthdayProperty, dbcontact.birthday, &errorRef);
    
        //职称
    if(dbcontact.jobTitle && [dbcontact.jobTitle caseInsensitiveCompare:@""] != NSOrderedSame)
        ABRecordSetValue(newPerson, kABPersonJobTitleProperty, dbcontact.jobTitle, &errorRef);
    
        //昵称
    if(dbcontact.nickName &&[dbcontact.nickName caseInsensitiveCompare:@""] != NSOrderedSame)
        ABRecordSetValue(newPerson, kABPersonNicknameProperty, dbcontact.nickName, &errorRef);
	else 
		ABRecordRemoveValue(newPerson, kABPersonNicknameProperty, &errorRef);
    
    if (dbcontact.avatarB64.length > 0) {
        NSData *newData = [GTMBase64 decodeString:dbcontact.avatarB64];
        ABPersonSetImageData(newPerson, (CFDataRef)newData, &errorRef);
    } else {
        //不清空本地头像
    }
	
    // 副表数据
    if(listData)
		[MMAddressBook setRecordData:newPerson andDatalist:listData];
    
    
    return newPerson;
}

/*
 * 向Iphone的AddressBook插入联系人数据
 */
+(ABRecordRef)insertContact:(ABAddressBookRef)abAddressbook contact:(DbContact *)dbcontact
                 withDataList:(NSArray*)listData {

    CFErrorRef errorRef = NULL;
    ABRecordRef newPerson = [self ABRecordFromDbStruct:dbcontact withDataList:listData];
    
    // 保存,获取cellId
    if (!ABAddressBookAddRecord(abAddressbook, newPerson, &errorRef)) {
        CFRelease(newPerson);
        return nil;
    }
    
    return newPerson;
}

/*
 * 向Iphone的AddressBook插入联系人数据
 */
+(MMABErrorType)insertContact:(DbContact *)dbcontact withDataList:(NSArray*)listData returnCellId:(int32_t*)cellId{
    CFErrorRef errorRef = NULL; 
    
    ABAddressBookRef abAddressbook = ABAddressBookCreateWithOptions(NULL, NULL);
    
    ABRecordRef newPerson = [self insertContact:abAddressbook contact:dbcontact withDataList:listData];
    if (nil == newPerson) {
        CFRelease(abAddressbook);
        return MM_AB_FAILED;
    }
    if(!ABAddressBookSave(abAddressbook, &errorRef)) {
        CFRelease(newPerson);
        CFRelease(abAddressbook);
        return MM_AB_SAVE_FAILED;
	}
    
    if (cellId) {
        *cellId = ABRecordGetRecordID(newPerson);
    }
    CFRelease(newPerson);
    CFRelease(abAddressbook);
    return MM_AB_OK;
}

+(NSArray*)insertContacts:(NSArray*)fullContacts {
    CFErrorRef errorRef = NULL;
    ABAddressBookRef abAddressbook = ABAddressBookCreateWithOptions(NULL, NULL);
    NSMutableArray *newPersons = [NSMutableArray array];
    NSMutableArray *array = [NSMutableArray array];
  
    for (MMFullContact *contact in fullContacts) {
        ABRecordRef person = [self insertContact:abAddressbook contact:contact withDataList:contact.properties];
        if (nil == person) {
            break;
        }

        [newPersons addObject:(id)person];
        CFRelease(person);
    }

    
    if ([newPersons count] != [fullContacts count]) {
        [newPersons removeAllObjects];
        CFRelease(abAddressbook);
        return nil;
    }
    if(!ABAddressBookSave(abAddressbook, &errorRef)) {
        [newPersons removeAllObjects];
        CFRelease(abAddressbook);
        return nil;
	}

    for (id person in newPersons) {
        ABRecordRef newPerson = (ABRecordRef)person;
        int32_t cellId = ABRecordGetRecordID(newPerson);
        [array addObject:[NSNumber numberWithInt:cellId]];
    }
    [newPersons removeAllObjects];
    CFRelease(abAddressbook);
    return array;
}


/*
 * 删除IPHONE的ADDRESSBOOK的联系人
 */
+(MMABErrorType)deleteContact:(int32_t)cellId{
    MMABErrorType ret = MM_AB_OK;
    
    if(cellId <= 0) {
        ret = MM_AB_RECORD_NOT_EXIST;
        return ret;
    }
    
    ABAddressBookRef abAddressbook = ABAddressBookCreateWithOptions(NULL, NULL);
    CFErrorRef errorRef = nil;
    
    ABRecordRef person = ABAddressBookGetPersonWithRecordID(abAddressbook, cellId);
    if(person)
        ABAddressBookRemoveRecord(abAddressbook, person, &errorRef);
    
    if(!errorRef && !ABAddressBookSave(abAddressbook, &errorRef))
        ret = MM_AB_SAVE_FAILED;
    
    CFRelease(abAddressbook);
    return ret;
}

/*
 * 更新联系人数据
 */
+(MMABErrorType)updateContact:(DbContact*)dbcontact withDataList:(NSArray*)listData{
    MMABErrorType ret = 0;
    CFErrorRef errorRef = NULL; 

    ABAddressBookRef abAddressbook = ABAddressBookCreateWithOptions(NULL, NULL);
    do {
        if (dbcontact.phoneCid <= 0) {
            ret = MM_AB_RECORD_NOT_EXIST;
            break;
        }
        
        ABRecordRef updatePerson = ABAddressBookGetPersonWithRecordID(abAddressbook,dbcontact.phoneCid);
        if(updatePerson == nil) {
            ret = MM_AB_RECORD_NOT_EXIST;
            break;
        }
        
        //firstname
        if(dbcontact.firstName && [dbcontact.firstName caseInsensitiveCompare:@""] != NSOrderedSame) {
            ABRecordSetValue(updatePerson, kABPersonFirstNameProperty, dbcontact.firstName, &errorRef);
        }
        else {
			ABRecordSetValue(updatePerson, kABPersonFirstNameProperty, @"", &errorRef);
            ABRecordRemoveValue(updatePerson, kABPersonFirstNamePhoneticProperty, &errorRef);
        }
        
        //中间名字
        if(dbcontact.middleName && [dbcontact.middleName caseInsensitiveCompare:@""] != NSOrderedSame) {
            ABRecordSetValue(updatePerson, kABPersonMiddleNameProperty, dbcontact.middleName, &errorRef);
        }
        else {
            ABRecordRemoveValue(updatePerson, kABPersonMiddleNameProperty, &errorRef);
            ABRecordRemoveValue(updatePerson, kABPersonMiddleNamePhoneticProperty, &errorRef);
        }
        
        //lastname
        if(dbcontact.lastName && [dbcontact.lastName caseInsensitiveCompare:@""] != NSOrderedSame) {
            ABRecordSetValue(updatePerson, kABPersonLastNameProperty, dbcontact.lastName, &errorRef);
        }
        else {
            ABRecordRemoveValue(updatePerson, kABPersonLastNameProperty, &errorRef);
            ABRecordRemoveValue(updatePerson, kABPersonLastNamePhoneticProperty, &errorRef);
        }
        
        //公司
        if(dbcontact.organization && [dbcontact.organization caseInsensitiveCompare:@""] != NSOrderedSame)
            ABRecordSetValue(updatePerson, kABPersonOrganizationProperty, dbcontact.organization, &errorRef);
        else
            ABRecordRemoveValue(updatePerson, kABPersonOrganizationProperty, &errorRef);
        
        //部门
        if(dbcontact.department && [dbcontact.department caseInsensitiveCompare:@""] != NSOrderedSame)
            ABRecordSetValue(updatePerson, kABPersonDepartmentProperty, dbcontact.department, &errorRef);
        else
            ABRecordRemoveValue(updatePerson, kABPersonDepartmentProperty, &errorRef);
        
        //备注
        if(dbcontact.note && [dbcontact.note caseInsensitiveCompare:@""] != NSOrderedSame)
            ABRecordSetValue(updatePerson, kABPersonNoteProperty, dbcontact.note, &errorRef);
        else
            ABRecordRemoveValue(updatePerson, kABPersonNoteProperty, &errorRef);
        
        //生日
        if(dbcontact.birthday)
            ABRecordSetValue(updatePerson, kABPersonBirthdayProperty, dbcontact.birthday, &errorRef);
        else
            ABRecordRemoveValue(updatePerson, kABPersonBirthdayProperty, &errorRef);
        
        //职称
        if(dbcontact.jobTitle && [dbcontact.jobTitle caseInsensitiveCompare:@""] != NSOrderedSame)
            ABRecordSetValue(updatePerson, kABPersonJobTitleProperty, dbcontact.jobTitle, &errorRef);
        else
            ABRecordRemoveValue(updatePerson, kABPersonJobTitleProperty, &errorRef);
        
        //昵称
        if(dbcontact.nickName && [dbcontact.nickName caseInsensitiveCompare:@""] != NSOrderedSame)
            ABRecordSetValue(updatePerson, kABPersonNicknameProperty, dbcontact.nickName, &errorRef);
        else
            ABRecordRemoveValue(updatePerson, kABPersonNicknameProperty, &errorRef);
        
        if (dbcontact.avatarB64.length > 0) {
            NSData *newData = [GTMBase64 decodeString:dbcontact.avatarB64];
            ABPersonSetImageData(updatePerson, (CFDataRef)newData, &errorRef);
        } else {
            //不清空本地头像
        }
        
        if(listData) {
            // delete multiple data 删除副表数据
            ABRecordRemoveValue(updatePerson, kABPersonPhoneProperty,  &errorRef);
            ABRecordRemoveValue(updatePerson, kABPersonEmailProperty,  &errorRef);
            ABRecordRemoveValue(updatePerson, kABPersonURLProperty,  &errorRef);
            ABRecordRemoveValue(updatePerson, kABPersonAddressProperty,  &errorRef);
            ABRecordRemoveValue(updatePerson, kABPersonDateProperty,  &errorRef);
            ABRecordRemoveValue(updatePerson, kABPersonRelatedNamesProperty,  &errorRef);
            ABRecordRemoveValue(updatePerson, kABPersonInstantMessageProperty,  &errorRef);
            
            // 副表数据
			[MMAddressBook setRecordData:updatePerson andDatalist:listData];
        }
        
        // 保存
        if (!ABAddressBookSave(abAddressbook, &errorRef))
            ret = MM_AB_SAVE_FAILED;
		
    }
    while(0);

    CFRelease(abAddressbook);
    
    return ret;
}

/*
 * 只更新联系人的多元数据
 */
+(MMABErrorType)updateData:(int32_t)cellId withDataList:(NSArray*)listData{
    MMABErrorType ret = MM_AB_OK;
    CFErrorRef errorRef = NULL; 
    
    ABAddressBookRef abAddressbook = ABAddressBookCreateWithOptions(NULL, NULL);
    do {
        
        ABRecordRef updatePerson = ABAddressBookGetPersonWithRecordID(abAddressbook, cellId);
        if(updatePerson == nil) {
            ret = MM_AB_RECORD_NOT_EXIST;
            break;
        }
        
        if(listData) {
            // delete multiple data 删除副表数据
            ABRecordRemoveValue(updatePerson, kABPersonPhoneProperty,  &errorRef);
            ABRecordRemoveValue(updatePerson, kABPersonEmailProperty,  &errorRef);
            ABRecordRemoveValue(updatePerson, kABPersonURLProperty,  &errorRef);
            ABRecordRemoveValue(updatePerson, kABPersonAddressProperty,  &errorRef);
            ABRecordRemoveValue(updatePerson, kABPersonDateProperty,  &errorRef);
            ABRecordRemoveValue(updatePerson, kABPersonRelatedNamesProperty,  &errorRef);
            ABRecordRemoveValue(updatePerson, kABPersonInstantMessageProperty,  &errorRef);
            
            // 副表数据
			[MMAddressBook setRecordData:updatePerson andDatalist:listData];
			
        }
        // 保存
        if (!ABAddressBookSave(abAddressbook, &errorRef))
            ret = MM_AB_SAVE_FAILED;
    }
    while(0);
    
    CFRelease(abAddressbook);
    
    return ret;
}



+(NSDate*)getContactModifyDate:(int32_t)cellId {
	
	ABAddressBookRef abAddressbook = ABAddressBookCreateWithOptions(NULL, NULL);
	ABRecordRef person = ABAddressBookGetPersonWithRecordID(abAddressbook, cellId);
	if (nil == person) {
		CFRelease(abAddressbook);
		return nil;
	}
	CFTypeRef modifydateRef = ABRecordCopyValue(person, kABPersonModificationDateProperty);
	NSDate* modifydate = (NSDate*)modifydateRef;
	
	CFTypeRef createdateRef = ABRecordCopyValue(person, kABPersonCreationDateProperty);
	NSDate* createdate = (NSDate*)createdateRef;
	
	NSDate *retDate = nil;
	
	if (nil == modifydate) {
		NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
		dateFormatter.dateStyle = NSDateFormatterMediumStyle;
		[dateFormatter setLocale:[NSLocale currentLocale]];	 
		[dateFormatter setDateFormat:@"yyyy-MM-dd-hh-mm-ss"];	
		[dateFormatter release];	
		
		retDate = [NSDate dateWithTimeIntervalSince1970:[createdate timeIntervalSince1970]];
		
	} else {
        retDate = [NSDate dateWithTimeIntervalSince1970:[modifydate timeIntervalSince1970]];	
	}
	
	if (createdateRef != NULL) CFRelease(createdateRef);
	if (modifydateRef != NULL) CFRelease(modifydateRef);
    if (abAddressbook != NULL) CFRelease(abAddressbook);
	
	return retDate;
}


+ (DbContact*)getContact:(int32_t)cellId withError:(MMABErrorType*)error {
	ABAddressBookRef abAddressbook = ABAddressBookCreateWithOptions(NULL, NULL);
    ABRecordRef person = ABAddressBookGetPersonWithRecordID(abAddressbook,cellId);
	if (person == NULL) {
		if (error) {
			*error = MM_AB_RECORD_NOT_EXIST;
            CFRelease(abAddressbook);
			return nil;
		}
	}
	
	DbContact* dbContact = [[[DbContact alloc] init] autorelease];
	dbContact.phoneCid = ABRecordGetRecordID(person);
	if (![self dbContactFromABRecord:dbContact abRecord:person]) {
		if (error) {
			*error = MM_AB_FAILED;
		} 
		CFRelease(abAddressbook);
		return nil;
	}
	CFRelease(abAddressbook);
	if (error) {
		*error = MM_AB_OK;
	}
	
	return dbContact;
}



+ (BOOL)dbContactFromABRecord:(DbContact*)dbContact abRecord:(ABRecordRef)person {
	ABPropertyID propertyIDs[] = {
		kABPersonFirstNameProperty 
        , kABPersonLastNameProperty
        , kABPersonMiddleNameProperty
        , kABPersonNicknameProperty
        , kABPersonOrganizationProperty
        , kABPersonJobTitleProperty
        , kABPersonDepartmentProperty
        , kABPersonBirthdayProperty
        , kABPersonNoteProperty
        , kABPersonModificationDateProperty
    };
    int count = sizeof(propertyIDs)/sizeof(ABPropertyID);
    
    for(int i = 0; i < count; ++i){
        ABPropertyID aPropertyID = propertyIDs[i];
        ABPropertyType aPropertyType = ABPersonGetTypeOfProperty(aPropertyID);
        CFTypeRef typeRef = ABRecordCopyValue(person, aPropertyID);
        switch (aPropertyType) {
            case kABStringPropertyType:{
                NSString* str = (NSString*)typeRef;
                if (str == nil) {
                    break;
                }
                
					// firstName
                if(kABPersonFirstNameProperty == aPropertyID) {
                    [dbContact setFirstName:str];
                }
					// lastName
                if(kABPersonLastNameProperty == aPropertyID) {
                    [dbContact setLastName:str];
                }
					// middleName
                if(kABPersonMiddleNameProperty == aPropertyID) {
                    [dbContact setMiddleName:str];
                }
					// nickname
                if(kABPersonNicknameProperty == aPropertyID) {
                    [dbContact setNickName:str];
                }
					// 组织
                if(kABPersonOrganizationProperty == aPropertyID) {
                    [dbContact setOrganization:str];
                }
					// 职业
                if(kABPersonJobTitleProperty == aPropertyID) {
                    [dbContact setJobTitle:str];
                }
					// 部门
                if(kABPersonDepartmentProperty == aPropertyID) {
                    [dbContact setDepartment:str];
                }
					// NOTE
                if(kABPersonNoteProperty == aPropertyID) {
                    [dbContact setNote:str];
                }
            }
                break;
            case kABMultiStringPropertyType:
                break;
            case kABDateTimePropertyType:{
                NSDate* date = (NSDate*)typeRef;
                if(kABPersonBirthdayProperty == aPropertyID) {
                    [dbContact setBirthday:date];
                }
				
				if(kABPersonModificationDateProperty == aPropertyID) {
                    dbContact.modifyDate = [date timeIntervalSince1970];
				}
     
            }
                break;
            case kABMultiDictionaryPropertyType:
                break;
            case kABMultiDateTimePropertyType:
                break;
            case kABIntegerPropertyType:{
		
            }
                break;
            default:
                break;
        }
		if (nil != typeRef) {
			CFRelease(typeRef);
		}
    }
    

    CFDataRef data = ABPersonCopyImageDataWithFormat(person, kABPersonImageFormatOriginalSize);
    if (data != nil && CFDataGetLength(data) >= 128*1024) {
        CFRelease(data);
        data = ABPersonCopyImageDataWithFormat(person, kABPersonImageFormatThumbnail);
    }
    if (data != nil) {
        NSData *imageData = (NSData*)data;
        dbContact.avatarB64 = [GTMBase64 stringByEncodingData:imageData];
        CFRelease(data);
    }
    return YES;
}

+ (BOOL)dbDataListFromABRecord:(NSMutableArray*)dbDataList abRecord:(ABRecordRef)person {
	ABPropertyID propertyIDs[] = {
          kABPersonFirstNamePhoneticProperty
        , kABPersonLastNamePhoneticProperty
        , kABPersonMiddleNamePhoneticProperty
        , kABPersonPrefixProperty
        , kABPersonSuffixProperty
        , kABPersonEmailProperty
        , kABPersonCreationDateProperty 
        , kABPersonAddressProperty
        , kABPersonDateProperty
        , kABPersonKindProperty
        , kABPersonPhoneProperty
        , kABPersonInstantMessageProperty
        , kABPersonURLProperty
        , kABPersonRelatedNamesProperty
    };
    int count = sizeof(propertyIDs)/sizeof(ABPropertyID);
	//int recordId = ABRecordGetRecordID(person);
    
    for(int i = 0; i < count; ++i){
        ABPropertyID aPropertyID = propertyIDs[i];
        ABPropertyType aPropertyType = ABPersonGetTypeOfProperty(aPropertyID);
        CFTypeRef typeRef = ABRecordCopyValue(person, aPropertyID);
        switch (aPropertyType) {
            case kABStringPropertyType:
                break;
            case kABMultiStringPropertyType:{
                NSArray* mutistrs = (NSMutableArray*)typeRef;
                
                int num = ABMultiValueGetCount(mutistrs);
                for (int j = 0; j < num; ++j) {
                    DbData* dbData = [[DbData alloc] init];
//					dbData.phonecid = recordId;
                    NSMutableArray* lblArray = [NSMutableArray new];
                    
						// label
                    NSString* label = (NSString*)ABMultiValueCopyLabelAtIndex(mutistrs, j);
                    [dbData setLabel:[MMAddressBook getMMLabelByIphoneLabel:label andByProperty:aPropertyID]];
                    [label release];                        
                    
						// value
                    NSString* value = (NSString*)ABMultiValueCopyValueAtIndex(mutistrs, j);
                    [dbData setValue:value];
                    [value release];
                    
						// property
						// 邮箱
                    if(kABPersonEmailProperty == aPropertyID) {
                        [dbData setProperty:kMoMail];
                    }
						// 电话
                    if(kABPersonPhoneProperty == aPropertyID) {
                        [dbData setProperty:kMoTel];
                        dbData.value = formatTelNumber(dbData.value);
                    }
						// URL
                    if(kABPersonURLProperty == aPropertyID) {
                        [dbData setProperty:kMoUrl];
                    }
						// 关系人
                    if(kABPersonRelatedNamesProperty == aPropertyID) {
                        [dbData setProperty:kMoPerson];
                    }
                    
                    [dbDataList addObject:dbData];
                    [dbData release];
                    [lblArray release];
                }
            }
                break;
            case kABDateTimePropertyType:
                break;
            case kABMultiDictionaryPropertyType:{
                
                NSMutableArray* multiDictionary = (NSMutableArray*)typeRef;
                int localcount = ABMultiValueGetCount(multiDictionary);
                
                for(int j = 0; j < localcount; j++) {
                    CFDictionaryRef dict = (CFDictionaryRef)ABMultiValueCopyValueAtIndex(multiDictionary, j);
                    
                    DbData* dbData = [[DbData alloc] init];
//					dbData.phonecid = recordId;
                    
                    NSMutableArray* val_array = [NSMutableArray array];
                    
						// label
                    NSString* label = (NSString*)ABMultiValueCopyLabelAtIndex(multiDictionary, j);
                    
                    if(label != nil) {
						[dbData setLabel:[MMAddressBook getMMLabelByIphoneLabel:label andByProperty:aPropertyID]];
                        CFRelease(label);
                    }
                    
						// 地址
                    if(kABPersonAddressProperty == aPropertyID) {
							// property 
                        [dbData setProperty:kMoAdr];
                        
							// value
                        CFStringRef ABPAKeys[] = {kABPersonAddressStreetKey, kABPersonAddressCityKey, kABPersonAddressStateKey, kABPersonAddressZIPKey, kABPersonAddressCountryKey};
                        [val_array addObject:@""];[val_array addObject:@""]; // 添加两个空值
                        int num = sizeof(ABPAKeys)/sizeof(CFStringRef);
                        for(int k = 0; k < num; ++k){
                            if(k == 0) { 
									// ;str1;str2
                                NSString* streets = (NSString*)CFDictionaryGetValue(dict, ABPAKeys[k]);
                                streets = [streets stringByReplacingOccurrencesOfString:@"\n" withString:@" "];
                                [val_array addObject:(streets == nil ? @"" : streets) ];
                            }
                            else  { // ;city; state; zip ; country
                                NSString* var = (NSString*)CFDictionaryGetValue(dict, ABPAKeys[k]);   
                                [val_array addObject: (var == nil ? @"" : var)];
                            }
                        }
                        
                        SBJSON* sbjson = [SBJSON new];
                        [dbData setValue:[sbjson stringWithObject:val_array]];
                        [sbjson release];
                    }
						// 即时通信
                    if(kABPersonInstantMessageProperty == aPropertyID) {
							// property
                        NSString* service = (NSString*)CFDictionaryGetValue(dict, kABPersonInstantMessageServiceKey);
                        do{
                            dbData.property = kMoImICQ;
							if([service isEqualToString:(NSString*)kABPersonInstantMessageServiceAIM]){
                                [dbData setProperty:kMoImAIM];
                                break;
                            }
							if([service isEqualToString:(NSString*)kABPersonInstantMessageServiceJabber]){
                                [dbData setProperty:kMoImJabber];
                                break;
                            }
							if([service isEqualToString:(NSString*)kABPersonInstantMessageServiceMSN]){
                                [dbData setProperty:kMoImMSN];
                                break;
                            }
                            if([service isEqualToString:(NSString*)kABPersonInstantMessageServiceYahoo]){
                                [dbData setProperty:kMoImYahoo];
                                break;
                            }                                                         
                            if([service isEqualToString:(NSString*)kABPersonInstantMessageServiceICQ]){
                                [dbData setProperty:kMoImICQ];
                                break;
                            } 
							if([service isEqualToString:@"91U"]){
                                [dbData setProperty:kMoIm91U];
                                break;
                            }
							if([service isEqualToString:@"QQ"]){
                                [dbData setProperty:kMoImQQ];
                                break;
                            }
							if([service isEqualToString:@"Gtalk"]){
                                [dbData setProperty:kMoImGtalk];
                                break;
                            }
                            if([service isEqualToString:@"Skype"]){
                                [dbData setProperty:kMoImSkype];
                                break;
                            }
                        }
                        while(0);
                        
							// value
                        NSString* username = (NSString*)CFDictionaryGetValue(dict, kABPersonInstantMessageUsernameKey);
                        [dbData setValue:username];
                    }
                    
                    [dbDataList addObject:dbData];
                    [dbData release];
                    
                    CFRelease(dict);
                }
            }
                break;
            case kABMultiDateTimePropertyType:{
                NSMutableArray* multiValue = (NSMutableArray*)typeRef;
                
                int num = ABMultiValueGetCount(multiValue);
                for(int j = 0; j < num; j++){
                    DbData* dbData = [DbData new];
//					dbData.phonecid = recordId;
					
					// label
                    NSString* label = (NSString*)ABMultiValueCopyLabelAtIndex(multiValue, j);
                    [dbData setLabel:[MMAddressBook getMMLabelByIphoneLabel:label andByProperty:aPropertyID]];
                    [label release];
                    
						// value
                    NSDate* date = (NSDate*)ABMultiValueCopyValueAtIndex(multiValue, j);
                    NSDateFormatter* formater = [NSDateFormatter new];
                    [formater setDateFormat:@"yyyy-MM-dd"];
                    [dbData setValue:[formater stringFromDate:date]];
                    [formater release];
                    [date release];
                    
						// 纪念日
                    if(kABPersonDateProperty == aPropertyID) {
							// property
                        [dbData setProperty:kMoBday];
                    }
                    
                    [dbDataList addObject:dbData];
                    [dbData release];
                }
            }
                break;
            case kABIntegerPropertyType:{
             
            }
                break;
            default:
                break;
        }
		if (nil != typeRef) {
			CFRelease(typeRef);
		}
    }
    return YES;
}

+(BOOL) ABRecord2DbStruct:(DbContact*) dbContact withDataList:(NSMutableArray*) dbDataList withPerson:(ABRecordRef) person {
    if (![self dbContactFromABRecord:dbContact abRecord:person])
        return NO;
    if (![self dbDataListFromABRecord:dbDataList abRecord:person])
        return NO;
    return YES;
}



+ (NSData*)getAvatarData:(int32_t)phonecid {
	ABAddressBookRef abAddressbook = ABAddressBookCreateWithOptions(NULL, NULL);
    ABRecordRef person = ABAddressBookGetPersonWithRecordID(abAddressbook,phonecid);
	if (person == NULL) {
		CFRelease(abAddressbook);
		return nil;
	}
	CFDataRef data = ABPersonCopyImageData(person);
	CFRelease(abAddressbook);
    return [(NSData*)data autorelease];
}

+ (UIImage *)getAvatar:(int32_t)phonecid {
    NSData *data = [self getAvatarData:phonecid];
    if (nil == data) {
        return nil;
    }
    UIImage *image = [[[UIImage alloc] initWithData:(NSData*)data] autorelease];
    return image;
}



+ (MMErrorType) updateContactAvatar:(NSData*)avatar byPhoneId:(int32_t)phoneContactId {
    CFErrorRef  error;
	ABAddressBookRef abAddressbook = ABAddressBookCreateWithOptions(NULL, NULL);
    ABRecordRef person = ABAddressBookGetPersonWithRecordID(abAddressbook,phoneContactId);
	
	MMErrorType iRet = MM_DB_OK;
	do {
		if (person == NULL) {			
			iRet =  MM_DB_KEY_NOT_EXISTED;
			break;
		}		
		
		if (nil == avatar) {
			iRet = ABPersonRemoveImageData(person, &error) ? MM_DB_OK : MM_DB_WRITE_ABADDRESSBOOK_FAILED;
			break;
		}
		
		NSData *newData = avatar;
		if (nil == newData) {
			iRet =  MM_DB_WRITE_ABADDRESSBOOK_FAILED;
			break;
		}
		
		if (!ABPersonSetImageData(person, (CFDataRef)newData, &error)) {
			iRet =  MM_DB_WRITE_ABADDRESSBOOK_FAILED;
			break;
		}		
        
	} while (0);
	
	if (MM_DB_OK == iRet) {
		if(!ABAddressBookSave(abAddressbook, &error)) {
			iRet =  MM_DB_WRITE_ABADDRESSBOOK_FAILED;
		}		
	}
	
	CFRelease(abAddressbook);
	return iRet;

}




+(NSString*) getIphoneLabelByMMLabel:(NSString*)label andByProperty:(NSInteger) property {
    
	switch (property) {
		case kMoTel:{	
			return [MMAddressBook getTelIphoneLabelByMMLabel:label];
			break;
		}			
		case kMoMail:{
			return [MMAddressBook getMailIphoneLabelByMMLabel:label];
			break;
		}			
		case kMoUrl:{
			return [MMAddressBook getURLIphoneLabelByMMLabel:label];
			break;
		}
		case kMoAdr:{
			return [MMAddressBook getAdrIphoneLabelByMMLabel:label];
			break;
		}
		case kMoBday:{
			return [MMAddressBook getBdayIphoneLabelByMMLabel:label];
			break;
		}
		case kMoPerson:{
			return [MMAddressBook getPersonIphoneLabelByMMLabel:label];
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
			return [MMAddressBook getIMIphoneLabelByMMLabel:label];
			break;
		}
		default:{
			break;
		}
	}
	
	return label;			   
}


+(NSString*) getMMLabelByIphoneLabel:(NSString*)label andByProperty:(NSInteger) property {	
    
	if (kABPersonPhoneProperty == property) {
		return [MMAddressBook getTelMMLabelByIphoneLabel:label];		
	}
	
	if (kABPersonEmailProperty == property) {
		return [MMAddressBook getMailMMLabelByIphoneLabel:label];		
	}
	
	if (kABPersonURLProperty == property) {
		return [MMAddressBook getURLMMLabelByIphoneLabel:label];		
	}
	
	if (kABPersonAddressProperty == property) {
		return [MMAddressBook getAdrMMLabelByIphoneLabel:label];		
	}
	
	if (kABPersonDateProperty == property) {
		return [MMAddressBook getBdayMMLabelByIphoneLabel:label];		
	}
	
	if (kABPersonRelatedNamesProperty == property) {
		return [MMAddressBook getPersonMMLabelByIphoneLabel:label];		
	}
	
	if (kABPersonInstantMessageProperty == property) {
		return [MMAddressBook getIMMMLabelByIphoneLabel:label];		
	}
	
	return label;
}


+(NSString*) getTelIphoneLabelByMMLabel:(NSString*)label {
	NSString *strIphoneLabel = label;
	
	do {
		if (0 == [label caseInsensitiveCompare:@"work"]) {
			strIphoneLabel = (NSString*)kABWorkLabel;
			break;
		}
		if (0 == [label caseInsensitiveCompare:@"home"]) {
			strIphoneLabel = (NSString*)kABHomeLabel;
			break;
		}
		if (0 == [label caseInsensitiveCompare:@"cell"]) {
			strIphoneLabel = (NSString*)kABPersonPhoneMobileLabel;
			break;
		}
        if (0 == [label caseInsensitiveCompare:@"main"]) {
            strIphoneLabel = (NSString*)kABPersonPhoneMainLabel;
            break;
        }
		if (0 == [label caseInsensitiveCompare:@"home,fax"]) {
			strIphoneLabel = (NSString*)kABPersonPhoneHomeFAXLabel;
			break;
		}
		if (0 == [label caseInsensitiveCompare:@"work,fax"]) {
			strIphoneLabel = (NSString*)kABPersonPhoneWorkFAXLabel;
			break;
		}
		if (0 == [label caseInsensitiveCompare:@"pager"]) {
			strIphoneLabel = (NSString*)kABPersonPhonePagerLabel;
			break;
		}
		if (0 == [label caseInsensitiveCompare:@"car"]) {
			//iphone没有此默认值
			strIphoneLabel = label;
			break;
		}
		if (0 == [label caseInsensitiveCompare:@"other"]) {
			strIphoneLabel = (NSString*)kABOtherLabel;
			break;			
		}
	} while (0);
	
	return strIphoneLabel;
}

+(NSString*) getMailIphoneLabelByMMLabel:(NSString*)label {
	NSString *strIphoneLabel = label;
	
	do {
		if (0 == [label caseInsensitiveCompare:@"home"]) {
			strIphoneLabel = (NSString*)kABHomeLabel;
			break;
		}
		if (0 == [label caseInsensitiveCompare:@"work"]) {
			strIphoneLabel = (NSString*)kABWorkLabel;
			break;
		}	
		if (0 == [label caseInsensitiveCompare:@"other"]) {
			strIphoneLabel = (NSString*)kABOtherLabel;
			break;
		}
	} while(0);
	
	return strIphoneLabel;
}

+(NSString*) getIMIphoneLabelByMMLabel:(NSString*)label {
	NSString *strIphoneLabel = label;
	
	do {
		if (0 == [label caseInsensitiveCompare:@"home"]) {
			strIphoneLabel = (NSString*)kABHomeLabel;
			break;
		}
		if (0 == [label caseInsensitiveCompare:@"work"]) {
			strIphoneLabel = (NSString*)kABWorkLabel;
			break;
		}	
		if (0 == [label caseInsensitiveCompare:@"other"]) {
			strIphoneLabel = (NSString*)kABOtherLabel;
			break;
		}
	} while(0);
	
	return strIphoneLabel;
}

+(NSString*) getURLIphoneLabelByMMLabel:(NSString*)label {
	NSString *strIphoneLabel = label;
	
	do {
		if (0 == [label caseInsensitiveCompare:@"homepage"]) {
			strIphoneLabel = (NSString*)kABPersonHomePageLabel;
			break;
		}
		if (0 == [label caseInsensitiveCompare:@"ftp"]) {
			//iphone没有此默认值
			strIphoneLabel = label;
			break;
		}	
		if (0 == [label caseInsensitiveCompare:@"blog"]) {
			//iphone没有此默认值
			strIphoneLabel = label;
			break;
		}
		if (0 == [label caseInsensitiveCompare:@"profile"]) {
			//iphone没有此默认值
			strIphoneLabel = label;
			break;
		}
	} while(0);
	return strIphoneLabel;
}


+(NSString*) getPersonIphoneLabelByMMLabel:(NSString*)label {
	NSString *strIphoneLabel = label;
	
	do {
		if (0 == [label caseInsensitiveCompare:@"spouse"]) {
			strIphoneLabel = (NSString*)kABPersonSpouseLabel;
			break;
		}
		if (0 == [label caseInsensitiveCompare:@"child"]) {		
			strIphoneLabel = (NSString*)kABPersonChildLabel;
			break;
		}	
		if (0 == [label caseInsensitiveCompare:@"father"]) {			
			strIphoneLabel = (NSString*)kABPersonFatherLabel;
			break;
		}
		if (0 == [label caseInsensitiveCompare:@"mother"]) {			
			strIphoneLabel = (NSString*)kABPersonMotherLabel;
			break;
		}
		if (0 == [label caseInsensitiveCompare:@"parent"]) {
			strIphoneLabel = (NSString*)kABPersonParentLabel;
			break;
		}
		if (0 == [label caseInsensitiveCompare:@"brother"]) {
			strIphoneLabel = (NSString*)kABPersonBrotherLabel;
			break;
		}	
		if (0 == [label caseInsensitiveCompare:@"sister"]) {
			strIphoneLabel = (NSString*)kABPersonSisterLabel;
			break;
		}
		if (0 == [label caseInsensitiveCompare:@"friend"]) {
			strIphoneLabel = (NSString*)kABPersonFriendLabel;
			break;
		}
		if (0 == [label caseInsensitiveCompare:@"relative"]) {
			//iphone没有此默认值
			strIphoneLabel = label;
			break;
		}	
		if (0 == [label caseInsensitiveCompare:@"domestic_partner"]) {
			//iphone没有此默认值
			strIphoneLabel = label;
			break;
		}
		if (0 == [label caseInsensitiveCompare:@"manager"]) {
			strIphoneLabel = (NSString*)kABPersonManagerLabel;
			break;
		}
		if (0 == [label caseInsensitiveCompare:@"assistant"]) {
			strIphoneLabel = (NSString*)kABPersonAssistantLabel;
			break;
		}
		if (0 == [label caseInsensitiveCompare:@"partner"]) {
			strIphoneLabel = (NSString*)kABPersonPartnerLabel;
			break;
		}	
		if (0 == [label caseInsensitiveCompare:@"referred_by"]) {
			//iphone没有此默认值
			strIphoneLabel = label;
			break;
		}
		if (0 == [label caseInsensitiveCompare:@"other"]) {			
			strIphoneLabel = (NSString*)kABOtherLabel;
			break;
		}
	} while(0);	
	
	return strIphoneLabel;
}

+(NSString*) getAdrIphoneLabelByMMLabel:(NSString*)label {
	NSString *strIphoneLabel = label;	
	
	do {
		if (0 == [label caseInsensitiveCompare:@"home"]) {
			strIphoneLabel = (NSString*)kABHomeLabel;
			break;
		}
		if (0 == [label caseInsensitiveCompare:@"work"]) {
			strIphoneLabel = (NSString*)kABWorkLabel;
			break;
		}	
		if (0 == [label caseInsensitiveCompare:@"other"]) {
			strIphoneLabel = (NSString*)kABOtherLabel;
			break;
		}
	} while(0);
	
	return strIphoneLabel;
}

+(NSString*) getBdayIphoneLabelByMMLabel:(NSString*)label {
	NSString *strIphoneLabel = label;	
	
	do {
		if (0 == [label caseInsensitiveCompare:@"anniversary"]) {
			strIphoneLabel = (NSString*)kABPersonAnniversaryLabel;
			break;
		}			
		if (0 == [label caseInsensitiveCompare:@"other"]) {
			strIphoneLabel = (NSString*)kABOtherLabel;
			break;
		}
	} while(0);
	
	return strIphoneLabel;
}



+(NSString*) getTelMMLabelByIphoneLabel:(NSString*)label {
	NSString *strMMLabel = label;
	
	do {
		if(NSOrderedSame == [label caseInsensitiveCompare:(NSString *)kABWorkLabel]) {
            strMMLabel = @"work";
            break;
        }
		if(NSOrderedSame == [label caseInsensitiveCompare:(NSString *)kABHomeLabel]) {
            strMMLabel = @"home";
            break;
        }
		if(NSOrderedSame == [label caseInsensitiveCompare:(NSString *)kABPersonPhoneMobileLabel]) {
            strMMLabel = @"cell";
            break;
        }		
        if (NSOrderedSame == [label caseInsensitiveCompare:(NSString*)kABPersonPhoneMainLabel]) {
            strMMLabel = @"main";
            break;
        }
		if(NSOrderedSame == [label caseInsensitiveCompare:(NSString *)kABPersonPhoneHomeFAXLabel]) {
            strMMLabel = @"home,fax";
            break;
        }
		if(NSOrderedSame == [label caseInsensitiveCompare:(NSString *)kABPersonPhoneWorkFAXLabel]) {
            strMMLabel = @"work,fax";
            break;
        }
		if(NSOrderedSame == [label caseInsensitiveCompare:(NSString *)kABPersonPhonePagerLabel]) {
            strMMLabel = @"pager";
            break;
        }		
		if(NSOrderedSame == [label caseInsensitiveCompare:(NSString *)kABOtherLabel]) {
            strMMLabel = @"other";
            break;
        }		
		
	} while(0);
	
	return strMMLabel;
}

+(NSString*) getMailMMLabelByIphoneLabel:(NSString*)label {
	NSString *strMMLabel = label;
	do {
		if(NSOrderedSame == [label caseInsensitiveCompare:(NSString *)kABWorkLabel]) {
            strMMLabel = @"work";
            break;
        }
		if(NSOrderedSame == [label caseInsensitiveCompare:(NSString *)kABHomeLabel]) {
            strMMLabel = @"home";
            break;
        }			
		if(NSOrderedSame == [label caseInsensitiveCompare:(NSString *)kABOtherLabel]) {
            strMMLabel = @"other";
            break;
        }		
		
	} while(0);
	return strMMLabel;
}


+(NSString*) getIMMMLabelByIphoneLabel:(NSString*)label {
	NSString *strMMLabel = label;
	do {
		if(NSOrderedSame == [label caseInsensitiveCompare:(NSString *)kABWorkLabel]) {
            strMMLabel = @"work";
            break;
        }
		if(NSOrderedSame == [label caseInsensitiveCompare:(NSString *)kABHomeLabel]) {
            strMMLabel = @"home";
            break;
        }			
		if(NSOrderedSame == [label caseInsensitiveCompare:(NSString *)kABOtherLabel]) {
            strMMLabel = @"other";
            break;
        }		
		
	} while(0);
	return strMMLabel;
}


+(NSString*) getURLMMLabelByIphoneLabel:(NSString*)label {
	NSString *strMMLabel = label;
	do {
		if(NSOrderedSame == [label caseInsensitiveCompare:(NSString *)kABPersonHomePageLabel]) {
            strMMLabel = @"homepage";
            break;
        }	
		
	} while(0);
	return strMMLabel;
}


+(NSString*) getPersonMMLabelByIphoneLabel:(NSString*)label {
	NSString *strMMLabel = label;
	do {		
		if (NSOrderedSame == [label caseInsensitiveCompare:(NSString *)kABPersonSpouseLabel]) {
			strMMLabel = @"spouse";
			break;
		}
		if (NSOrderedSame == [label caseInsensitiveCompare:(NSString *)kABPersonChildLabel]) {
			strMMLabel = @"child";
			break;
		}
		if (NSOrderedSame == [label caseInsensitiveCompare:(NSString *)kABPersonFatherLabel]) {
			strMMLabel = @"father";
			break;
		}
		if (NSOrderedSame == [label caseInsensitiveCompare:(NSString *)kABPersonMotherLabel]) {
			strMMLabel = @"mother";
			break;
		}
		if (NSOrderedSame == [label caseInsensitiveCompare:(NSString *)kABPersonParentLabel]) {
			strMMLabel = @"parent";
			break;
		}
		if (NSOrderedSame == [label caseInsensitiveCompare:(NSString *)kABPersonBrotherLabel]) {
			strMMLabel = @"brother";
			break;
		}
		if (NSOrderedSame == [label caseInsensitiveCompare:(NSString *)kABPersonSisterLabel]) {
			strMMLabel = @"sister";
			break;
		}
		if (NSOrderedSame == [label caseInsensitiveCompare:(NSString *)kABPersonFriendLabel]) {
			strMMLabel = @"friend";
			break;
		}
		if (NSOrderedSame == [label caseInsensitiveCompare:(NSString *)kABPersonManagerLabel]) {
			strMMLabel = @"manager";
			break;
		}
		if (NSOrderedSame == [label caseInsensitiveCompare:(NSString *)kABPersonAssistantLabel]) {
			strMMLabel = @"assistant";
			break;
		}
		if (NSOrderedSame == [label caseInsensitiveCompare:(NSString *)kABPersonPartnerLabel]) {
			strMMLabel = @"partner";
			break;
		}
		if (NSOrderedSame == [label caseInsensitiveCompare:(NSString *)kABOtherLabel]) {
			strMMLabel = @"other";
			break;
		}
        
	} while(0);
	
	return strMMLabel;
}


+(NSString*) getAdrMMLabelByIphoneLabel:(NSString*)label {
	NSString *strMMLabel = label;
	do {
		if(NSOrderedSame == [label caseInsensitiveCompare:(NSString *)kABWorkLabel]) {
            strMMLabel = @"work";
            break;
        }
		if(NSOrderedSame == [label caseInsensitiveCompare:(NSString *)kABHomeLabel]) {
            strMMLabel = @"home";
            break;
        }			
		if(NSOrderedSame == [label caseInsensitiveCompare:(NSString *)kABOtherLabel]) {
            strMMLabel = @"other";
            break;
        }		
		
	} while(0);
	return strMMLabel;
}


+(NSString*) getBdayMMLabelByIphoneLabel:(NSString*)label {
	NSString *strMMLabel = label;
	do {
		if(NSOrderedSame == [label caseInsensitiveCompare:(NSString *)kABPersonAnniversaryLabel]) {
            strMMLabel = @"anniversary";
            break;
        }					
		if(NSOrderedSame == [label caseInsensitiveCompare:(NSString *)kABOtherLabel]) {
            strMMLabel = @"other";
            break;
        }		
		
	} while(0);
	return strMMLabel;
}


@end

