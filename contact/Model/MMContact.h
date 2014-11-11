//
//  MMContact.h
//  Db
//
//  Created by aminby on 2010-7-23.
//  Copyright 2010 NetDragon.Co. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MMModel.h"

@interface MMContactManager : MMModel {

	NSMutableArray *contactArray_;
	NSMutableArray *friendArray_;
}

+(MMContactManager*) instance;

-(NSArray*) getContactSyncInfoList:(MMErrorType*)error;
-(NSArray*) getContactSyncInfoList:(NSArray*)ids withError:(MMErrorType*)error;
/*
 * 获取联系人简单信息列表 返回DbContact元素的NSArray
 */

- (NSInteger)getContactCount;

- (NSArray*)getSimpleContactListNew:(MMErrorType*)error ;

- (NSArray*)getSimpleContactList:(MMErrorType*)error;


- (NSDictionary*) getAllTelDict:(MMErrorType*)error;

- (NSArray*) getAllTelList:(MMErrorType*)error;

/*
 * 获得联系人某种类型数据, 返回DbData元素的NSArray
 */
- (NSArray*)getDataList:(NSInteger)contactId withType:(ContactType)type withError:(MMErrorType*)error;
/*
 * 获得联系人数据, 返回DbData元素的NSArray
 */
- (NSArray*)getDataList:(NSInteger)contactId withError:(MMErrorType*)error;


/*
 * 获得联系人信息
 */
- (DbContact*) getContact:(NSInteger)contactId withError:(MMErrorType*)error;
- (DbContactSimple*)getContactSimple:(NSInteger)contactId;

/*
 * 插入联系人, 使用DbContact和DdData List, 已设置contactId
 */
- (MMErrorType)insertContact:(DbContact *)contact withDataList:(NSArray*)listData;

/*
 * 插入联系人, 使用DbContact和DdData List
 */
- (MMErrorType)insertContact:(DbContact *)contact withDataList:(NSArray*)listData returnContactId:(NSInteger*)contactId;


/*
 * 更新联系人, 使用DbContact和DdData List
 */
- (MMErrorType) updateContact:(DbContact*)contact withDataList:(NSArray*)listData;
/*
 * 删除某个联系人
 */
- (MMErrorType) deleteContact:(NSInteger)contactId;


//modifyDate没有用了么？？？
- (NSDate*) getModifyDate:(NSInteger)contactId withError:(MMErrorType*)error;
- (MMErrorType) setModifyDate:(NSDate*)modifydate byContactId:(NSInteger)contactId;

- (MMErrorType)clearContactDB;
- (MMErrorType)clearMomoContact;
- (MMErrorType)clearAddressBookContact;


//都没有用了呀？
- (NSArray*) getContactListByDataLabel:(NSString *)label withError:(MMErrorType*)error;
- (MMErrorType)changeCustomLabelToDefault:(NSString*)label;
- (NSArray*) getAllLabelWithError:(MMErrorType*)error;


// 这是个自杀函数 勿用 
- (void)killSelf;


//contact
- (NSArray*)getContactListNeedName:(BOOL)needName needPhone:(BOOL)needPhone; 

//匹配联系人
- (NSArray*)searchContact:(NSString*)searchString
                 needName:(BOOL)needName    //是否包含没有名字联系人
                needPhone:(BOOL)needPhone; //是否包含没有手机号的联系人  


//@private

- (MMErrorType) _insertContact:(DbContact*)contact returnContactId:(NSInteger*)contactId;
- (MMErrorType) _updateContact:(DbContact*)contact;
- (MMErrorType) _deleteContact:(NSInteger)contactId;
- (MMErrorType) _insertData:(DbData*)data;
- (MMErrorType) _updateData:(DbData*)data;
- (MMErrorType) _deleteData:(NSInteger)row_id;
- (MMErrorType) _deleteAllData:(NSInteger)contactId;
- (MMErrorType) _updateContact:(DbContact*)contact withDataList:(NSArray*)listData;
- (MMErrorType) _updatePhoneticAbbr:(NSInteger)contactId;

-(NSString*) getDefaulMMLabelByProperty:(NSInteger) property;
@end

typedef MMContactManager MMContact ;
