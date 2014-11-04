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


typedef enum {
    MMDataRecordExist,		//已有记录 界面上已经被创建出来的 但并不一定已经入库
	MMDataRecordNoExist,	//记录还未被创建
	MMDataRecordAddRow,		//虚拟记录 只为了绘制界面而造出来的记录 增加一条记录
	MMDataRecordMoreInfo,	//虚拟记录 只为了绘制界面而造出来的记录 转到更多字段的页面
	MMDataRecordDelContact,  //虚拟记录 只为了绘制界面而造出来的记录 删除联系人
} MMDataRecordStateEnum;



@interface DbContactId : NSObject {
	NSInteger contactId;
}
@property(nonatomic)NSInteger contactId;
@end

@interface DbContactSyncInfo : DbContactId {
	int64_t modifyDate;//服务器联系人的时间戳
}
@property(nonatomic)int64_t modifyDate;
@end

//简单联系人
@interface DbContactSimple : DbContactId {
    
	NSString    *avatarUrl;
	NSString	*firstName;	//姓名
	NSString	*middleName;//(姓)名	
	NSString	*lastName;	//姓
	NSString	*namePhonetic;	//姓名
    
    NSMutableSet    *cellPhoneNums; //用户手机号数组
}
@property (nonatomic) NSInteger	phoneCid;
@property (copy, nonatomic) NSString *firstName;
@property (copy, nonatomic) NSString *middleName;
@property (copy, nonatomic) NSString *lastName;
@property (nonatomic, readonly)NSString *fullName;
@property (copy, nonatomic) NSString *avatarUrl;
@property (nonatomic, readonly) NSString *avatarPlatformUrl;
@property (nonatomic, readonly) NSString *avatarBigUrl;
@property (copy, nonatomic) NSString *namePhonetic;
@property (nonatomic, retain) NSMutableSet    *cellPhoneNums;

-(id)init;

- (BOOL)isEnglishName;

@end

@interface MMLunarDate : NSObject {
    NSArray *array_;
}
@property(nonatomic, readonly) NSString *year;
@property(nonatomic, readonly) NSString *month;
@property(nonatomic, readonly) NSString *day;
@property(nonatomic, readonly) NSInteger nyear;
@property(nonatomic, readonly) NSInteger nmonth;
@property(nonatomic, readonly) NSInteger nday;
-(id)initWithString:(NSString*)str;
@end



//联系人
@interface DbContact : DbContactSimple {
	NSString	*organization;//公司
	NSString	*department;//部门
	NSString	*note;//备注
	NSDate		*birthday;//生日
	int64_t     modifyDate;
	NSString	*jobTitle;//职称
	NSString	*nickName;//昵称
    
}
@property (nonatomic, copy) NSString *organization;
@property (nonatomic, copy) NSString *department;
@property (nonatomic, copy) NSString *note;
@property (nonatomic, copy) NSString *jobTitle;
@property (nonatomic, copy) NSString *nickName;
@property (nonatomic, copy) NSDate *birthday;
@property(nonatomic)int64_t modifyDate;


-(id)initWithContact:(DbContact*)dbcontact;
@end

@class DbData, MMCard;

@interface MMFullContact : DbContact <NSCopying>
{
	NSArray *properties;
}

@property(nonatomic, retain)NSArray *properties;
@property(nonatomic, readonly)DbData *mainTelephone;

-(id)initWithCard:(MMCard*)card;
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


@interface MMDataRecord : DbData <NSCopying>
{
    
}

@property (nonatomic)	NSInteger	dataRecordState;	
@property (nonatomic, copy) NSString *reserve;   //用于界面文字显示用

- (id)init;

//对号码与邮箱进行排序 主号码总在最前。号码在邮箱之前。
- (NSComparisonResult)compareWithOther:(MMDataRecord *)other;
//对微博排序 微博在前，开心网在后。
- (NSComparisonResult)compareUrlWithOther:(MMDataRecord *)other;

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


//根据联系人获取简单电话信息
@interface DbContactPhone : NSObject {
	NSString	*label;		//标签(home,work等)
	NSString	*value;		//联系方式(电话号码)
	NSString	*location;	//归属地
}

@property (copy, nonatomic) NSString  *label;
@property (copy, nonatomic) NSString  *value;
@property (copy, nonatomic) NSString  *location;

@end

/*
 * 如果label isa NSNumber 那么他是个内置标签,可以多国语言化
 * 如果label isa NSString 那么是自定义标签,直接显示
 */
@interface MMContactInfo : NSObject {
    id label;
    NSString *value;
}
@property (copy, nonatomic) NSString  *value;
@property (nonatomic,retain) id  label;
@end



//评论消息结构
@interface MMCommentInfo : NSObject {
	NSUInteger ownerId;
	NSString*	commentId;
	NSString*	statusId;
	NSUInteger	uid;
	NSString	*text;
	uint64_t	createDate;
	NSString	*sourceName;
	NSString	*realName;
	NSString	*avatarImageUrl;
    NSString    *srcText;
    BOOL        ignoreTimeLine;
	
	//for upload use
	UploadStatus uploadStatus;
	NSUInteger	draftId;
}
@property (nonatomic) NSUInteger ownerId;
@property (nonatomic, copy) NSString* commentId;
@property (nonatomic, copy) NSString* statusId;
@property (nonatomic) NSUInteger uid;
@property (nonatomic, copy) NSString *text;
@property (nonatomic) uint64_t createDate;
@property (nonatomic, copy) NSString	*sourceName;
@property (nonatomic, copy) NSString *realName;
@property (nonatomic, copy) NSString *avatarImageUrl;
@property (nonatomic, copy) NSString *srcText;
@property (nonatomic) BOOL ignoreTimeLine;

//for upload use
@property (nonatomic) UploadStatus uploadStatus;
@property (nonatomic) NSUInteger draftId;

- (NSString*)plainText;

@end

//动态消息结构
@interface MMMessageInfo : NSObject {
	NSString* statusId;
	NSUInteger ownerId;
	NSUInteger	uid;
	NSString	*text;
	NSUInteger	createDate;
	uint64_t	modifiedDate;
	BOOL		liked;
	NSUInteger	likeCount;
	NSString	*likeList;
	BOOL		storaged;
	NSString	*sourceName;
	NSUInteger	commentCount;
	NSString*	recentCommentId;
	NSUInteger	groupType;
	NSUInteger	groupId;
	NSString	*groupName;
	NSString	*summary;
	NSArray		*attachImageURLs;
	NSArray		*voteOptions;
	BOOL		ignoreDateLine;
	NSString	*realName;
	NSString	*avatarImageUrl;
	
	MMMessageType	typeId;	//动态类型:活动.日志等
	BOOL		allowRetweet;
	BOOL		allowComment;
	BOOL		allowPraise;
	BOOL		allowDel;
	BOOL		allowHide;
	NSString	*retweetStatusId;
	uint64_t	applicationId;
	NSString	*applicationTitle;
	NSString	*applicationUrl;
	
	//后面加的类型都存储到json中
	NSArray		*accessoryArray;	//存储 MMMessageAccessoryInfo 数组
	
	BOOL		syncToWeibo;	//是否同步到微薄
    NSArray     *syncToWeiboInfos; //同步到微薄信息数组, 包含微薄名称和是否同步成功
    
    //地理信息
    double      longitude;
    double      latitude;
    NSString*   address;
    BOOL        isCorrect;
    
    //长文本
    BOOL        isLongText;
    NSString*   longTextUrl;
    NSString    *longText;
	////////////////////////////////////
    //for cache
	MMCommentInfo *recentComment;
	
    //for upload use
	UploadStatus uploadStatus;
    
    CGPoint     contentOffset;
}
@property (nonatomic, copy) NSString* statusId;
@property (nonatomic) NSUInteger ownerId;
@property (nonatomic) NSUInteger uid;
@property (nonatomic, copy) NSString *text;
@property (nonatomic) NSUInteger createDate;
@property (nonatomic) uint64_t modifiedDate;
@property (nonatomic) BOOL liked;
@property (nonatomic) NSUInteger likeCount;
@property (nonatomic, copy) NSString *likeList;
@property (nonatomic) BOOL storaged;
@property (nonatomic, copy) NSString	*sourceName;
@property (nonatomic) NSUInteger commentCount;
@property (nonatomic, copy) NSString*  recentCommentId;
@property (nonatomic) NSUInteger groupType;
@property (nonatomic) NSUInteger groupId;
@property (nonatomic, copy) NSString *groupName;
@property (nonatomic, copy) NSString *summary;
@property (nonatomic, retain) NSArray *attachImageURLs;
@property (nonatomic, retain) NSArray *voteOptions;
@property (nonatomic) BOOL		ignoreDateLine;
@property (nonatomic, copy) NSString *realName;
@property (nonatomic, copy) NSString *avatarImageUrl;
@property (nonatomic) MMMessageType typeId;
@property (nonatomic) BOOL	allowRetweet;
@property (nonatomic) BOOL	allowComment;
@property (nonatomic) BOOL	allowPraise;
@property (nonatomic) BOOL	allowDel;
@property (nonatomic) BOOL	allowHide;
@property (nonatomic, copy) NSString *retweetStatusId;
@property (nonatomic) uint64_t applicationId;
@property (nonatomic, copy) NSString *applicationTitle;
@property (nonatomic, copy) NSString *applicationUrl;
@property (nonatomic, retain) NSArray *accessoryArray;
@property (nonatomic) BOOL	syncToSinaWeibo;
@property (nonatomic) BOOL	syncToSinaWeiboSuccess;

@property (nonatomic) double longitude;
@property (nonatomic) double latitude;
@property (nonatomic) BOOL isCorrect;
@property (nonatomic, copy) NSString*  address;
@property (nonatomic) BOOL  isLongText;
@property (nonatomic, copy) NSString*  longTextUrl;
@property (nonatomic, copy) NSString*  longText;
@property (nonatomic) CGPoint contentOffset;

//not in db
@property (nonatomic, retain) MMCommentInfo *recentComment;

//for upload use
@property (nonatomic) UploadStatus uploadStatus;
@property (nonatomic) NSUInteger draftId;

- (MMMessageType)messageTypeFromString:(NSString*)type;

- (NSString*)plainText;

@end



@interface MMMomoUserInfo : NSObject <NSCopying>
{
	NSUInteger uid;
	NSString* realName;
	NSString* avatarImageUrl;
    
    NSUInteger contactId;	
	NSString *registerNumber;
}
@property (nonatomic) NSUInteger uid;
@property (nonatomic, copy) NSString* realName;
@property (nonatomic, copy) NSString* avatarImageUrl;

@property (nonatomic) NSUInteger contactId;
@property (nonatomic, copy) NSString *registerNumber;

@property (nonatomic) BOOL isSelected;  //用于选择联系人页面的选择状态

- (id)initWithUserId:(NSUInteger)userId 
			realName:(NSString*)name
	  avatarImageUrl:(NSString*)url;

- (id)initWithDictionary:(NSDictionary*)dic;

@end

//about me消息结构
@interface MMAboutMeInfo : NSObject {
	NSUInteger ownerId;
	NSString	*aboutMeId;
	NSString	*textReply;
	NSString	*text;
	NSUInteger	uid;
	NSString	*realName;
	NSString	*avatarImageUrl;
	
	NSString	*statusId;
	NSUInteger  statusUid;
	
	NSUInteger	groupType;
	NSUInteger	groupId;
	NSString	*groupName;
	BOOL		reply;
	NSArray		*commentIds;
	NSUInteger	createdAt;
	BOOL		isNew;
}
@property (nonatomic) NSUInteger ownerId;
@property (nonatomic, copy) NSString	*aboutMeId;
@property (nonatomic, copy) NSString *textReply;
@property (nonatomic, copy) NSString *text;
@property (nonatomic) NSUInteger	uid;
@property (nonatomic, copy) NSString *realName;
@property (nonatomic, copy) NSString *avatarImageUrl;

@property (nonatomic, copy) NSString *statusId;
@property (nonatomic) NSUInteger	statusUid;
@property (nonatomic) NSUInteger	groupType;
@property (nonatomic) NSUInteger	groupId;
@property (nonatomic, copy) NSString *groupName;
@property (nonatomic) BOOL		reply;
@property (nonatomic, retain) NSArray		*commentIds;
@property (nonatomic) NSUInteger	createdAt;
@property (nonatomic) BOOL		isNew;
@end

@interface MMDraftInfo : NSObject {
	NSUInteger	ownerId;
	NSUInteger draftId;
	NSString* text;
	DraftType draftType;
	NSUInteger	createDate;
	
    //message use
	NSArray* attachImagePaths;	//已上传或未上传的图片路径
	NSUInteger groupId;
	MMAppType  appType;		//应用类型, 群组或活动
	NSString*  groupName;
	BOOL	   syncToWeibo;	//同步到微薄
	
    //retweet use
	NSString* retweetStatusId;	//转发的动态ID
	
    //comment use
	NSString*	replyStatusId;
	NSString*	replyCommentId;
    
    NSMutableDictionary* extendInfo; //
	
	/////////////////////////////////////
	//not in db
	NSArray* attachImages;
	
	//for upload use
	UploadStatus uploadStatus;
    NSString*    uploadErrorString;
}
@property (nonatomic) NSUInteger createDate;
@property (nonatomic) NSUInteger ownerId;
@property (nonatomic) NSUInteger	draftId;
@property (nonatomic, copy) NSString *text;
@property (nonatomic) DraftType	draftType;
@property (nonatomic, retain) NSArray* attachImagePaths;
@property (nonatomic) NSUInteger	groupId;
@property (nonatomic) MMAppType  appType;
@property (nonatomic) BOOL syncToWeibo;
@property (nonatomic, copy) NSString*  groupName;
@property (nonatomic, copy) NSString*	retweetStatusId;
@property (nonatomic, copy) NSString*	replyStatusId;
@property (nonatomic, copy) NSString* 	replyCommentId;
@property (nonatomic, retain) NSMutableDictionary* extendInfo;

@property (nonatomic, retain) NSArray* attachImages;

//for upload use
@property (nonatomic) UploadStatus uploadStatus;
@property (nonatomic, copy) NSString*   uploadErrorString;

- (NSString*)textWithoutUid;  //将@用户后面的ID去除
- (NSString*)textToUpload;     //将@格式转为上传需要的格式

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


@interface MMAboutMeMessage : NSObject {
	NSString* id;
	NSInteger kind;
	NSString *statusId;
	NSUInteger	ownerId;
	NSString *ownerName;
	
	int64_t dateLine;
	BOOL isRead;
	
	NSString *commentId;
	NSString *comment;
	NSString *sourceComment;
}
@property (nonatomic, copy) NSString* id;
@property (nonatomic) NSInteger kind;
@property (nonatomic, copy)NSString *statusId;
@property (nonatomic) int64_t dateLine;
@property (nonatomic) NSUInteger	ownerId;
@property (nonatomic, copy) NSString *ownerName;
@property (nonatomic) BOOL isRead;

@property (nonatomic, copy)NSString *commentId;
@property (nonatomic, copy)NSString *comment;
@property (nonatomic, copy)NSString *sourceComment;

-(id)initWithMessage:(MMAboutMeMessage*)msg;
-(id)initWithDictionary:(NSDictionary*)dic;
@end


//动态中的附件结构
@interface MMAccessoryInfo : NSObject
{
	MMAccessoryType	accessoryType;
    
    NSString* type;
    uint64_t accessoryId;
	NSString* title;
	NSString* url;
}
@property (nonatomic) MMAccessoryType accessoryType;
@property (nonatomic, copy) NSString* type;
@property (nonatomic) uint64_t accessoryId;
@property (nonatomic, copy) NSString* title;
@property (nonatomic, copy) NSString* url;

+ (MMAccessoryInfo*)accessoryInfoFromDict:(NSDictionary*)accessoryDict;
+ (MMAccessoryType)typeFromString:(NSString*)typeString;

- (void)loadFromDict:(NSDictionary*)accessoryDict;
- (NSMutableDictionary*)toDict;

@end

@interface MMFileAccessoryInfo : MMAccessoryInfo
{
    uint64_t size;
    NSString* mime;
}
@property (nonatomic) uint64_t size;
@property (nonatomic, copy) NSString* mime;

@end

//图片附件结构
@interface MMImageAccessoryInfo : MMAccessoryInfo
{
    NSString* statusId;
	NSUInteger width;
	NSUInteger height;
}
@property (nonatomic, copy) NSString* statusId;
@property (nonatomic) NSUInteger width;
@property (nonatomic) NSUInteger height;

@end

@interface MMCountryInfo : NSObject {
    NSString* enCountryName;  //国家英文名称
    NSString* cnCountryName; //国家中文名称
    NSString* isoCountryCode; //国家缩写
    NSString* telCode;  //电话区号
    
    //for validation
    NSArray*  validPhoneLen; //合法的手机号长度
    NSArray*  validPhonePrefix; //合法的手机号前缀
}
@property (nonatomic, copy) NSString* enCountryName;
@property (nonatomic, copy) NSString* cnCountryName;
@property (nonatomic, copy) NSString* isoCountryCode;
@property (nonatomic, copy) NSString* telCode;
@property (nonatomic, retain) NSArray*  validPhoneLen;
@property (nonatomic, retain) NSArray*  validPhonePrefix;

+ (id)countryInfoFromDictionary:(NSDictionary*)dictionary;

@end


@interface MMMyMoInfo : MMAboutMeMessage {
    BOOL sms_;
}
@property (nonatomic) BOOL sms;
@end



// 名片结构
@interface MMCard : NSObject
{
    NSInteger   uid;                //用户ID(整型)
    NSString    *registerName;      //注册名
    
	NSInteger   gender;             //性别
	NSString    *animalSign;        //生肖
    NSString    *zodiac;            //星座
    NSString    *residence;         //居住地
    NSString    *note;              //个人描述
    NSString    *organization;      //公司/学校 
    NSString    *avatarUrl;         //用户头像地址
    NSInteger   userLink;           //用户标识， 0：陌生人，1：对方有我的手机号，2：对方给我授权, 3:自己
    BOOL        isInMyContact;      //我的联系人是否有他
    NSInteger   userStatus;         //用户状态
    
    //    user_link=0，无法获取以下信息
	NSDate		*birthday;          //生日
    MMLunarDate *lunarBirthday;     //农历生日
    BOOL        isHideBirthdayYear; //是否隐藏年份
    BOOL        isLunar;            //是否过农历
    
    //    只有user_link=3即当前用户是自己时，才有这两个信息。
    NSInteger   completeLevel;      //完善度0-100
    NSInteger   sendedCardCount;    //发送名片个数
	
    NSArray     *properties;        //邮箱类型,电话类型,微博类型 （DbData）
}


@property (nonatomic)           NSInteger uid;
@property (nonatomic, copy)     NSString *registerName;
@property (nonatomic)           NSInteger gender;
@property (nonatomic, copy)     NSString *animalSign;
@property (nonatomic, copy)     NSString *zodiac;
@property (nonatomic, copy)     NSString *residence;
@property (nonatomic, copy)     NSString *note;
@property (nonatomic, copy)     NSString *organization;
@property (copy, nonatomic)     NSString *avatarUrl;
@property (nonatomic)           NSInteger userLink;
@property (nonatomic)           BOOL isInMyContact;
@property (nonatomic)           NSInteger userStatus;
@property (nonatomic, copy)     NSDate *birthday;
@property (nonatomic, retain)   MMLunarDate *lunarBirthday;
@property (nonatomic)           BOOL isHideBirthdayYear;
@property (nonatomic)           BOOL isLunar;//是否过农历生日
@property (nonatomic)           NSInteger completeLevel;
@property (nonatomic)           NSInteger sendedCardCount;

@property (nonatomic, retain)   NSArray *properties;
@property (nonatomic, readonly) DbData *mainTelephone;

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


@interface MMGroupInfo : NSObject {
    NSInteger groupId_;
    NSString* groupName_;
    NSString* notice_;
    NSString* introduction_;
    NSInteger groupOpenType_; //1 公开群 2 私密群
    NSInteger createTime_;
    NSInteger modifyTime_;
    MMMomoUserInfo* creator_;
    MMMomoUserInfo* master_;
    NSArray* managers_;
    
    NSInteger memberCount_;
    BOOL isHide_;
}
@property (nonatomic) NSInteger groupId;
@property (nonatomic, copy) NSString* groupName;
@property (nonatomic) NSInteger groupOpenType;
@property (nonatomic, copy) NSString* notice;
@property (nonatomic, copy) NSString* introduction;
@property (nonatomic) NSInteger createTime;
@property (nonatomic) NSInteger modifyTime;
@property (nonatomic, retain) MMMomoUserInfo* creator;
@property (nonatomic, retain) MMMomoUserInfo* master;
@property (nonatomic, retain) NSArray* managers;
@property (nonatomic) NSInteger memberCount;
@property (nonatomic) BOOL isHide;

+ (MMGroupInfo*)groupInfoFromDict:(NSDictionary*)dict;

@end

@interface MMGroupMemberInfo : MMMomoUserInfo {
    MMGroupMemberGrade grade_;
}
@property (nonatomic) MMGroupMemberGrade grade;

+ (MMGroupMemberInfo*)groupMemberInfoFromDict:(NSDictionary*)dict;

- (NSString*)namePinyin;

@end