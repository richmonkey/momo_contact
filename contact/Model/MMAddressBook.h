//
//  MMAddressBook.h
//  Momo
//
//  Created by zdh on 5/14/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#ifndef _MMADDRESSBOOK_H_
#define _MMADDRESSBOOK_H_

#import <Foundation/Foundation.h>
#import <AddressBook/AddressBook.h>
#import "ErrorType.h"
#import "DefineEnum.h"
#import "DbStruct.h"

@class DbContact;

enum {
    MM_AB_OK,
    MM_AB_RECORD_NOT_EXIST,
    MM_AB_SAVE_FAILED,
    MM_AB_FAILED
};
typedef int MMABErrorType;

@interface MMAddressBook : NSObject {
	
}
+ (MMErrorType)clearAddressBook;
+ (BOOL)ABRecord2DbStruct:(DbContact*) dbContact withDataList:(NSMutableArray*) dbDataList withPerson:(ABRecordRef)person;
+(ABRecordRef)ABRecordFromDbStruct:(DbContact *)dbcontact withDataList:(NSArray *)listData;



+(int)getContactCount;



+(NSArray*)insertContacts:(NSArray*)fullContacts;

/*
 * 向Iphone的AddressBook插入联系人数据
 */
+(MMABErrorType)insertContact:(DbContact*)dbcontact withDataList:(NSArray*)listData returnCellId:(int32_t*)cellId;

/*
 * 删除IPHONE的ADDRESSBOOK的联系人
 */
+(MMABErrorType)deleteContact:(int32_t)cellId;

/*
 * 更新联系人数据
 */
+(MMABErrorType)updateContact:(DbContact*)dbcontact withDataList:(NSArray*)listData;

/*
 * 只更新联系人的多元数据
 */
+(MMABErrorType)updateData:(int32_t)cellId withDataList:(NSArray*)listData;


+(NSDate*) getContactModifyDate:(int32_t)cellId;

+(MMErrorType) updateContactAvatar:(NSData*)avatar byPhoneId:(int32_t)phoneContactId;

+(NSData*)getAvatarData:(int32_t)phonecid;
+(UIImage *)getAvatar:(int32_t)phonecid;


@end

#endif