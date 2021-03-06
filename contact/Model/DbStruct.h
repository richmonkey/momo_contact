//
//  DbStruch.h
//  Momo
//
//  Created by zdh on 5/13/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//


#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <UIKit/UIImage.h>
#import <MapKit/MapKit.h>
#import "DefineEnum.h"

@interface DbContactId : NSObject {
	int64_t contactId;
}
@property(nonatomic)int64_t contactId;
@end

@interface DbContactSyncInfo : DbContactId {
	int64_t modifyDate;//服务器联系人的时间戳
}
@property(nonatomic)int64_t modifyDate;
@end

//联系人
@interface DbContact : DbContactId {
  	int32_t	phoneCid;//手机联系人本身自增ID
    
    NSString   *avatarB64;
	NSString	*firstName;	//姓名
	NSString	*middleName;//(姓)名
	NSString	*lastName;	//姓
	NSString	*namePhonetic;	//姓名
    
    NSMutableSet    *cellPhoneNums; //用户手机号数组
    
    
	NSString	*organization;//公司
	NSString	*department;//部门
	NSString	*note;//备注
	NSDate		*birthday;//生日
	int64_t     modifyDate;
	NSString	*jobTitle;//职称
	NSString	*nickName;//昵称
}

@property (nonatomic) int32_t	phoneCid;
@property (copy, nonatomic) NSString *firstName;
@property (copy, nonatomic) NSString *middleName;
@property (copy, nonatomic) NSString *lastName;
@property (nonatomic, readonly)NSString *fullName;

//KB size
@property (nonatomic, copy) NSString *avatarB64;

@property (copy, nonatomic) NSString *namePhonetic;
@property (nonatomic, retain) NSMutableSet    *cellPhoneNums;

- (BOOL)isEnglishName;

@property (nonatomic, copy) NSString *organization;
@property (nonatomic, copy) NSString *department;
@property (nonatomic, copy) NSString *note;
@property (nonatomic, copy) NSString *jobTitle;
@property (nonatomic, copy) NSString *nickName;
@property (nonatomic, copy) NSDate *birthday;
@property(nonatomic)int64_t modifyDate;


-(id)initWithContact:(DbContact*)dbcontact;
@end

@class DbData;

@interface MMFullContact : DbContact <NSCopying>
{
	NSArray *properties;
}

@property(nonatomic, retain)NSArray *properties;

@end

//联系人数据
@interface DbData : NSObject <NSCopying> {
	NSInteger	rowId;//表记录ID
	NSInteger	contactId;//联系人ID
	ContactType	property;//
	NSString	*label;//联系方式的标签
	NSString	*value;//联系人的值
    
}
@property (nonatomic) NSInteger rowId;
@property (nonatomic) NSInteger contactId;
@property ContactType property;
@property (copy, nonatomic) NSString  *label;
@property (copy, nonatomic) NSString *value;
@property (nonatomic) BOOL isMainTelephone;
- (id)init;

- (id)initWithDbData:(DbData *)data;
@end


@interface DbData(Address)
+(NSString*)AddressValue:(NSString*)country region:(NSString*)region city:(NSString*)city street:(NSString*)street postal:(NSString*)postal;
+(void)ParseAddressValue:(NSString*)value country:(NSString**)country region:(NSString**)region city:(NSString**)city street:(NSString**)street postal:(NSString**)postal;
@end


//联系人头像
@interface DbContactImage : NSObject {
	//	NSInteger	imageId;//头像自增ID
	NSString	*url;	//头像URL
	UIImage		*image;	//头像
	
}
//@property (nonatomic) NSInteger imageId;
@property (copy, nonatomic) NSString *url;
@property (nonatomic, retain) UIImage *image;
@end

//分组成员,是否要加头像
@interface DbCategoryMember : NSObject {
	NSInteger	categoryId;		//联系人组ID
	NSInteger	contactId;		//联系人ID
	NSString	*categoryName;	//联系人组名称
	NSString	*contactName;	//联系人名称
}

@property (nonatomic) NSInteger categoryId;
@property (nonatomic) NSInteger contactId;
@property (copy, nonatomic) NSString *categoryName;
@property (copy, nonatomic) NSString *contactName;

@end

//分组信息
@interface DbCategory : NSObject {
	NSInteger	categoryId;	//分组ID
	NSInteger	phoneCategoryId;	//address book中的分组id
	NSString	*categoryName;	//分组名称
}

@property (nonatomic) NSInteger categoryId;
@property (nonatomic) NSInteger phoneCategoryId;
@property (copy, nonatomic) NSString  *categoryName;

@end



//同步记录
@interface MMSyncHistoryInfo : NSObject {
	NSInteger	syncId;
	NSInteger	beginTime;
	NSInteger	endTime;
	NSInteger	syncType;
	NSInteger	errorcode;
	NSString	*detailInfo;	
}
@property (nonatomic) NSInteger syncId;
@property (nonatomic) NSInteger beginTime;
@property (nonatomic) NSInteger endTime;
@property (nonatomic) NSInteger syncType;
@property (nonatomic) NSInteger	errorcode;
@property (copy, nonatomic) NSString *detailInfo;
@end


@interface MMContactChangeInfo : NSObject {
    NSInteger userID_;
    NSInteger dateLine_;
    NSString* source_;
    NSString* operation_;
    NSInteger addCount_;
    NSInteger updateCount_;
    NSInteger deleteCount_;
}
@property (nonatomic) NSInteger userID;
@property (nonatomic) NSInteger dateLine;
@property (nonatomic, copy) NSString* source;
@property (nonatomic, copy) NSString* operation;
@property (nonatomic) NSInteger addCount;
@property (nonatomic) NSInteger updateCount;
@property (nonatomic) NSInteger deleteCount;

- (id)initWithDictionary:(NSDictionary*)dict;

@end

typedef MMFullContact MMMomoContact;

typedef DbContactSyncInfo MMMomoContactSimple;

