//
//  DbStruch.m
//  Momo
//
//  Created by zdh on 5/13/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "DbStruct.h"
#import "SBJSON.h"
#import "RegexKitLite.h"
#import "MMGlobalData.h"
//#import "MMUapRequest.h"
#import "MMPhoneticAbbr.h"

@implementation DbContactId 
@synthesize contactId;

- (BOOL)isEqual:(id)object {
    return self.contactId == [object contactId];
}

- (NSUInteger)hash {
    return contactId;
}

@end

@implementation DbContactSyncInfo
@synthesize modifyDate;

-(id)init {
	self = [super init];
	if (self) {
	}
	return self;
}
-(void)dealloc {
	[super dealloc];
}
@end

//简单联系人
@implementation DbContactSimple
@synthesize firstName,middleName,lastName,avatarUrl,namePhonetic, cellPhoneNums;

- (BOOL)isEnglishName {
    NSString* tmpString = [NSString stringWithFormat:@"%@%@%@", PARSE_NULL_STR(lastName), PARSE_NULL_STR(middleName), PARSE_NULL_STR(firstName)];
    NSInteger length = tmpString.length;
    for (int i = 0; i < length; i++) {
        if ([tmpString characterAtIndex:i] > 256) {
            return NO;
        }
    }
    return YES;
}

-(NSString*)fullName {
    if ([self isEnglishName]) {
        NSMutableString* name = [NSMutableString stringWithString:PARSE_NULL_STR(lastName)];
        if (middleName.length > 0) {
            [name appendFormat:@"%@%@", name.length ? @" " : @"", PARSE_NULL_STR(middleName)];
        }
        if (firstName.length > 0) {
            [name appendFormat:@"%@%@", name.length ? @" " : @"", PARSE_NULL_STR(firstName)];
        }
        
        return name;
    } else {
        return [NSString stringWithFormat:@"%@%@%@", PARSE_NULL_STR(lastName), PARSE_NULL_STR(middleName), PARSE_NULL_STR(firstName)];
    }
}
-(NSString*) avatarPlatformUrl {
	return avatarUrl;
}

-(NSString*)avatarBigUrl {
    if (!avatarUrl) {
        return nil;
    }
    NSString* desireSizeStr = [NSString stringWithFormat:@"_%d.", BIG_AVATAR_SIZE];
    return [avatarUrl stringByReplacingOccurrencesOfString:@"_130." withString:desireSizeStr];
}

-(void)setPhoneCid:(NSInteger)pid {
	contactId = pid;
}
-(NSInteger)phoneCid {
	return contactId;
}

-(id)init{
	self = [super init];
	if (self) {
		firstName = @"";
		middleName = @"";
		lastName = @"";
		avatarUrl = @"";
		namePhonetic = @"";
        self.cellPhoneNums = [NSMutableSet set];
    }
    return self;
}

- (void)dealloc {
	self.avatarUrl = nil;
	self.firstName = nil;
	self.middleName = nil;
	self.lastName = nil;
	self.namePhonetic = nil;
    self.cellPhoneNums = nil;
	[super dealloc];
}
@end
@implementation MMLunarDate
@synthesize year, month, day, nyear, nmonth, nday;

-(NSString*)year {
    return [array_ objectAtIndex:3];
}
-(NSString*)month {
    return [array_ objectAtIndex:1];
}
-(NSString*)day {
    return [array_ objectAtIndex:2];
}
-(NSInteger)nyear {
    return [[array_ objectAtIndex:0] intValue];
}
-(NSInteger)nmonth {
    return [[array_ objectAtIndex:4] intValue];
}
-(NSInteger)nday {
    return [[array_ objectAtIndex:5] intValue];
}

- (NSString *)description {
    return [array_ componentsJoinedByString:@","];
}

-(id)initWithString:(NSString*)str {
    self = [super init];
    if (self) {
        if ([str length] > 0) {
            array_ = [str componentsSeparatedByString:@","];
            assert([array_ count] == 8);
            [array_ retain];
        }
    }
    return self;
}

-(void)dealloc {
    [array_ release];
    [super dealloc];
}

@end
//联系人
@implementation DbContact
@synthesize organization,department;
@synthesize  note,birthday,modifyDate,jobTitle,nickName;

-(id) init{
    self = [super init];
    if (self) {
		organization = @"";
		department = @"";
		note = @"";
		jobTitle = @"";
		nickName = @"";
		birthday = nil;
	}
    return self;
}

-(id)initWithContact:(DbContact*)dbcontact {
    self = [super init];
    if (self) {
        self.contactId = dbcontact.contactId;
        self.avatarUrl = dbcontact.avatarUrl;
        self.firstName = dbcontact.firstName;
        self.lastName = dbcontact.lastName;
        self.namePhonetic = dbcontact.namePhonetic;
        self.middleName = dbcontact.middleName;
        self.organization = dbcontact.organization;
        
        self.department = dbcontact.department;
        self.note = dbcontact.note;
        self.jobTitle = dbcontact.jobTitle;
        self.nickName = dbcontact.nickName;
        self.birthday = dbcontact.birthday;
        self.modifyDate = dbcontact.modifyDate;
        
    }
    return self;
}

- (void)dealloc {
	self.organization = nil;
	self.department = nil;
	self.note = nil;
	self.jobTitle = nil;
	self.nickName = nil;
	self.birthday = nil;
    
	[super dealloc];
}

@end

@implementation MMFullContact
@synthesize   properties;


-(id)initWithCard:(MMCard*)card {
    self = [super init];
    if (self) {
        
        self.firstName = card.registerName;
        self.middleName = @"";
        self.lastName = @"";
        
        self.avatarUrl = card.avatarUrl;
        self.organization = card.organization;
        self.note = card.note;
        self.birthday = card.birthday;
        
        self.properties = card.properties;
    }
    return self;
}

-(void)dealloc {
	self.properties = nil;
	[super dealloc];
}

-(DbData*)mainTelephone {
    for (DbData *data in properties) {
        if ([data isMainTelephone]) {
            return data;
        }
    }
    return nil;
}

- (id)copyWithZone:(NSZone *)zone {
	
	MMFullContact *newFullcontact = [[MMFullContact allocWithZone:zone] initWithContact:self];
	
    
	NSMutableArray *newArray = [NSMutableArray array];
	for (DbData *data in self.properties) {
		DbData *newData = [[[DbData alloc] initWithDbData:data] autorelease];
		[newArray addObject:newData];
	}
	
	newFullcontact.properties = newArray;
    
	return newFullcontact;
}

@end

//联系人数据
@implementation DbData
@synthesize rowId,contactId,property,label,value;
@synthesize isMainTelephone;

- (id)init {
	
    self = [super init];
    if (self) {
        rowId = 0;
        contactId = 0;
        property = 0;
        label = @"";
        value = @"";
		isMainTelephone = NO;
    }
    return self;
}

- (id)initWithDbData:(DbData *)data {
	self = [self init];
    if (self) {
        self.isMainTelephone = data.isMainTelephone;   
        self.rowId = data.rowId;
        self.contactId = data.contactId;
        self.property = data.property;
        self.label = data.label;
        self.value = data.value;
    }
	
	return self;
}

- (id)copyWithZone:(NSZone *)zone {
	DbData *newData = [[DbData allocWithZone:zone] init];
	
    newData.isMainTelephone = self.isMainTelephone;   
	newData.rowId = self.rowId;
	newData.contactId = self.contactId;
	newData.property = self.property;
	newData.label = [[self.label copyWithZone:zone] autorelease];
	newData.value = [[self.value copyWithZone:zone] autorelease];
	
	return newData;
}

- (void)dealloc {
	self.label = nil;
	self.value = nil;
	[super dealloc];
}

+(NSString*)AddressValue:(NSString*)country region:(NSString*)region city:(NSString*)city 
				  street:(NSString*)street postal:(NSString*)postal{
	NSMutableArray *array = [[[NSMutableArray alloc] init] autorelease];
	[array addObject:@""];
	[array addObject:@""]; // 添加两个空值
	
	[array addObject:street];
	[array addObject:city];
	[array addObject:region];
	[array addObject:postal];
	[array addObject:country];		
	
	SBJSON* sbjson = [[SBJSON new] autorelease];
	return [sbjson stringWithObject:array];
}

+(void)ParseAddressValue:(NSString*)value country:(NSString**)country region:(NSString**)region 
					city:(NSString**)city street:(NSString**)street postal:(NSString**)postal {
	// patched for address order 0-6: 0:nil 1:nil 2:street 3:city 4:province 5:zip 6:country
	// the patched order is: state, province, city, street, zip -> 6 4 3 2 5
	SBJSON* sbjson = [[SBJSON new] autorelease];
	NSArray *array = [sbjson objectWithString:value];
    
	*country = [[[array objectAtIndex:6] copy] autorelease];
	*region = [[[array objectAtIndex:4] copy] autorelease];
	*city = [[[array objectAtIndex:3] copy] autorelease];
	*street = [[[array objectAtIndex:2] copy] autorelease];
	*postal = [[[array objectAtIndex:5] copy] autorelease];
	return;
}
@end

@implementation MMDataRecord

@synthesize dataRecordState;
@synthesize reserve;

- (id)init{
    self = [super init];
    if (self) {
        self.dataRecordState = MMDataRecordExist;
		self.reserve = @"";
    }
    return self;
}
- (void)dealloc {
	self.reserve = nil;
	[super dealloc];
}

- (id)copyWithZone:(NSZone *)zone {
	MMDataRecord *newDataRcd = [[MMDataRecord allocWithZone:zone] init];
	
	newDataRcd.rowId = self.rowId;
	newDataRcd.contactId = self.contactId;
	newDataRcd.property = self.property;
	newDataRcd.label = [[self.label copyWithZone:zone] autorelease];
	newDataRcd.value = [[self.value copyWithZone:zone] autorelease];
	
	newDataRcd.dataRecordState = self.dataRecordState;
	newDataRcd.reserve = [[self.reserve copyWithZone:zone] autorelease];
	
	return newDataRcd;
}

//对号码与邮箱进行排序 主号码总在最前。号码在邮箱之前。
- (NSComparisonResult)compareWithOther:(MMDataRecord *)other {
	
	assert(other.property == kMoTel || other.property == kMoMail);
    
	if (self.isMainTelephone && !other.isMainTelephone) {
		return NSOrderedAscending;
	}
	
	if (!self.isMainTelephone && other.isMainTelephone) {
		return NSOrderedDescending;
	}
    
	if (self.property == kMoTel && other.property == kMoMail) {
		return NSOrderedAscending;
	}
	
	if (self.property == kMoMail && other.property == kMoTel) {
		return NSOrderedDescending;
	}
	
	return NSOrderedSame;	
}

//对微博排序 微博在前，开心网在后。
- (NSComparisonResult)compareUrlWithOther:(MMDataRecord *)other {
	
	assert(other.property == kMoUrl);
    
    if ([self.label isEqualToString:@"weibo.com"]) {
        return NSOrderedAscending; 
    }
    
    if ([self.label isEqualToString:@"kaixin001.com"]) {
        return NSOrderedDescending;
    }
    
    return NSOrderedSame;
}


@end

//图片
@implementation DbContactImage
@synthesize url,image;

- (void)dealloc {
	self.url = nil;
	self.image = nil;
	[super dealloc];
}
@end

//分组成员
@implementation DbCategoryMember
@synthesize contactId,categoryId,categoryName,contactName;

- (void)dealloc {
	self.categoryName = nil;
	self.contactName = nil;
	[super dealloc];
}

@end

//分组成员
@implementation DbCategory
@synthesize categoryId,categoryName,phoneCategoryId;

- (BOOL)isEqual:(id)object {
    return self.categoryId == [object categoryId];
}

- (NSUInteger)hash {
    return categoryId;
}

- (void)dealloc {
	self.categoryName = nil;
	[super dealloc];
}

@end

@interface MMImageInfo : NSObject {
    NSInteger	imageId;
	NSString	*url;
	NSString	*originalUrl;
	NSInteger	lastUpdateTime;
	NSData		*imageData;
	NSData		*originalImageData;
	NSInteger	createState;
	NSInteger	updateState;
	NSInteger	deleteState;
}
@property (nonatomic)			NSInteger	imageId;
@property (nonatomic,retain)	NSString	*url;
@property (nonatomic,retain)	NSString	*originalUrl;
@property (nonatomic)			NSInteger	lastUpdateTime;
@property (nonatomic,retain)	NSData		*imageData;
@property (nonatomic,retain)	NSData		*originalImageData;

@property (nonatomic)			NSInteger	createState;
@property (nonatomic)			NSInteger	updateState;
@property (nonatomic)			NSInteger	deleteState;

@end

@interface MMSimpleImageInfo : NSObject {
    NSInteger	imageId;
	NSString	*url;
	NSString	*originalUrl;	
}
@property (nonatomic)			NSInteger	imageId;
@property (nonatomic,retain)	NSString	*url;
@property (nonatomic,retain)	NSString	*originalUrl;


@end
@implementation MMImageInfo
@synthesize imageId,url,originalUrl,lastUpdateTime,imageData;
@synthesize originalImageData,createState,updateState,deleteState;

- (void)dealloc {
	self.originalUrl = nil;
	self.url = nil;
	self.imageData = nil;
	self.originalImageData = nil;
	[super dealloc];
}
@end

@implementation MMSimpleImageInfo
@synthesize imageId,url,originalUrl;

- (void)dealloc {
	self.url = nil;
	self.originalUrl = nil;
	[super dealloc];
}
@end

@implementation MMCommentInfo
@synthesize ownerId, commentId, statusId, uid, text, createDate, sourceName;
@synthesize realName, avatarImageUrl, srcText, ignoreTimeLine;
@synthesize uploadStatus, draftId; //upload use

- (id)init {
	if (self = [super init]) {
		ownerId = 0;
		uid = 0;
		createDate = 0;
		
		draftId = 0;
	}
	return self;
}

- (void)dealloc {
	self.statusId = nil;
	self.commentId = nil;
	self.text = nil;
	self.sourceName = nil;
	self.realName = nil;
	self.avatarImageUrl = nil;
    self.srcText = nil;
	[super dealloc];
}

- (NSString*)plainText {
    return [text stringByReplacingOccurrencesOfRegex:@"<.*?>" withString:@""];
}

@end

@implementation MMMessageInfo
@synthesize statusId, ownerId, uid, text, createDate, modifiedDate, liked, likeCount, contentOffset;
@synthesize likeList, storaged, sourceName, commentCount, recentCommentId;
@synthesize groupType, groupId, groupName, summary, attachImageURLs, voteOptions, ignoreDateLine;
@synthesize realName, avatarImageUrl, typeId, retweetStatusId;
@synthesize allowRetweet, allowComment, allowPraise, allowDel, allowHide;
@synthesize applicationId, applicationTitle, applicationUrl, accessoryArray;
@synthesize syncToSinaWeibo, syncToSinaWeiboSuccess;
@synthesize recentComment; //not in db
@synthesize uploadStatus, draftId; //upload use
@synthesize longitude, latitude, address, isLongText, longTextUrl, longText, isCorrect;

- (id)init {
	if (self = [super init]) {
		ownerId = 0;
		uid = 0;
		commentCount = 0;
		likeCount = 0;
		createDate = 0;
		modifiedDate = 0;
		liked = NO;
		storaged = NO;
		ignoreDateLine = NO;
		typeId = 0;
		allowRetweet = YES;
		allowComment = YES;
		allowPraise = YES;
		allowDel = YES;
		allowHide = YES;
		applicationId = 0;
		syncToSinaWeibo = NO;
		syncToSinaWeiboSuccess = NO;
        typeId = MessageTypeText;
        
        longitude = 0;
        latitude = 0;
        isLongText = NO;
		
		//not in db
		recentComment = nil;
		
		draftId = 0;
		groupId = 0;
        contentOffset = CGPointMake(0,0);
	}
	return self;
}

- (BOOL)isEqual:(id)object {
	MMMessageInfo* messageInfo = (MMMessageInfo*)object;
	if (self == messageInfo) {
		return YES;
	}
	
	if (!object) {
		return NO;
	}
	
	if ([self.statusId isEqualToString:messageInfo.statusId]) {
		return YES;
	}
	return NO;
}

- (MMMessageType)messageTypeFromString:(NSString*)type {
    if ([type compare:@"text" options:NSCaseInsensitiveSearch] == NSOrderedSame) {
        return MessageTypeText;
    } else if ([type compare:@"pic" options:NSCaseInsensitiveSearch] == NSOrderedSame) {
        return MMMessageTypePhoto;
    }
    return MessageTypeText;
}

- (void)dealloc {
	self.statusId = nil;
	self.recentCommentId = nil;
	self.text = nil;
	self.likeList = nil;
	self.sourceName = nil;
	self.groupName = nil;
	self.summary = nil;
	self.attachImageURLs = nil;
	self.voteOptions = nil;
	self.realName = nil;
	self.avatarImageUrl = nil;
	self.recentComment = nil;
	self.retweetStatusId = nil;
	self.applicationTitle = nil;
	self.applicationUrl = nil;
	self.accessoryArray = nil;
    self.address = nil;
    self.longTextUrl = nil;
    self.longText = nil;
	[super dealloc];
}

- (NSString*)plainText {
    return [text stringByReplacingOccurrencesOfRegex:@"<.*?>" withString:@""];
}

@end

@implementation MMMomoUserInfo
@synthesize uid, realName, avatarImageUrl, contactId, registerNumber;
@synthesize isSelected;

- (id)init {
    self = [super init];
    if (self) {
        uid = 0;
    }
    return self;
}

- (id)initWithUserId:(NSUInteger)userId 
			realName:(NSString*)name
	  avatarImageUrl:(NSString*)url {
	if (self = [self init]) {
		self.uid = userId;
		self.realName = name;
		self.avatarImageUrl = url;
	}
	return self;
}

-(id)initWithDictionary:(NSDictionary*)dic {
    NSInteger user_id = [[dic objectForKey:@"id"] intValue];
    NSString *name = [dic objectForKey:@"name"];
    NSString *avatar = [dic objectForKey:@"avatar"];
    return [self initWithUserId:user_id realName:name avatarImageUrl:avatar];
}


- (id)copyWithZone:(NSZone *)zone {
	MMMomoUserInfo* newUserInfo = [[MMMomoUserInfo allocWithZone:zone] init];
	newUserInfo.uid = self.uid;
	newUserInfo.realName = [[self.realName copyWithZone:zone] autorelease];
	newUserInfo.avatarImageUrl = [[self.avatarImageUrl copyWithZone:zone] autorelease];
	newUserInfo.registerNumber = [[self.registerNumber copyWithZone:zone] autorelease];
    
	newUserInfo.contactId = self.contactId;
	newUserInfo.isSelected = self.isSelected;
	return newUserInfo;
}

- (void)dealloc {
	self.realName = nil;
	self.avatarImageUrl = nil;
	self.registerNumber = nil;
	[super dealloc];
}

- (BOOL)isEqual:(id)object {
    if (!object && ![object isKindOfClass:[MMMomoUserInfo class]]) {
        return NO;
    }
    
    MMMomoUserInfo* friendInfo = (MMMomoUserInfo*)object;
    //    if (friendInfo == self || self.uid == friendInfo.uid || self.contactId == friendInfo.contactId) {
    //        return YES;
    //    }
	
	if (friendInfo == self || self.uid == friendInfo.uid) {
        return YES;
    }
    return NO;
}

@end

@implementation MMAboutMeInfo
@synthesize ownerId, aboutMeId, textReply, text, uid, statusId, groupType, groupId, groupName, reply, commentIds, createdAt, isNew;
@synthesize statusUid, realName, avatarImageUrl;

- (id)init {
	if (self = [super init]) {
		ownerId = 0;
		uid = 0;
		groupType = 0;
		groupId = 0;
		reply = YES;
		createdAt = 0;
		isNew = NO;
		statusUid = 0;
		
		//not in db
		realName = nil;
		avatarImageUrl = nil;
	}
	return self;
}

- (void)dealloc {
	self.aboutMeId = nil;
	self.text = nil;
	self.textReply = nil;
	self.realName = nil;
	self.avatarImageUrl = nil;
	[super dealloc];
}

@end

@implementation MMDraftInfo
@synthesize ownerId, draftId, text, draftType, attachImagePaths, groupId, appType, syncToWeibo;
@synthesize groupName, createDate, retweetStatusId, replyStatusId, replyCommentId, extendInfo;
@synthesize attachImages;
@synthesize uploadStatus, uploadErrorString; //upload use

- (id)init {
	if (self = [super init]) {
		ownerId = 0;
		draftId = 0;
		draftType = draftMessage;
		groupId = 0;
	    appType = MMAppTypeUnknow;
		syncToWeibo = NO;
		createDate = [[NSDate date] timeIntervalSince1970];
        extendInfo = [[NSMutableDictionary alloc] init];
		uploadStatus = uploadNone;
	}
	return self;
}

- (void)dealloc {
	self.text = nil;
	self.retweetStatusId = nil;
	self.replyStatusId = nil;
	self.attachImagePaths = nil;
	self.attachImages = nil;
	self.groupName = nil;
	self.replyCommentId = nil;
    self.extendInfo = nil;
    self.uploadErrorString = nil;
	[super dealloc];
}

- (NSString*)textWithoutUid {
    return [text stringByReplacingOccurrencesOfRegex:@"հ[\\d]*?հ" 
                                          withString:@"" 
                                             options:(RKLCaseless | RKLDotAll) 
                                               range:NSMakeRange(0, text.length) 
                                               error:nil];
}

- (NSString*)textToUpload {
    return [text stringByReplacingOccurrencesOfRegex:@"հ([\\d]*?)հ" 
                                          withString:@"($1)"
                                             options:(RKLCaseless | RKLDotAll) 
                                               range:NSMakeRange(0, text.length) 
                                               error:nil];
}

@end

@implementation MMSyncHistoryInfo
@synthesize syncId, beginTime, endTime, syncType, errorcode, detailInfo;

- (void)dealloc {
	self.detailInfo = nil;
	[super dealloc];
}
@end

@implementation MMAboutMeMessage
@synthesize id, kind, statusId, dateLine, ownerId, ownerName, isRead, commentId, comment, sourceComment;

-(id)initWithMessage:(MMAboutMeMessage*)msg {
	self = [super init];
	if (self) {
		self.id = msg.id;
		self.kind = msg.kind;
		self.statusId = msg.statusId;
		self.dateLine = msg.dateLine;
		self.ownerId = msg.ownerId;
		self.ownerName = msg.ownerName;
		self.isRead = msg.isRead;
		self.commentId = msg.commentId;
		self.comment = msg.comment;
		self.sourceComment = msg.sourceComment;
	}
	return self;
}


+(NSString *)stringWithUnescapeHTML:(NSString*)string
{
	string = [string stringByReplacingOccurrencesOfString:@"&quot;" withString:@"\""];
	string = [string stringByReplacingOccurrencesOfString:@"&apos;" withString:@"'"];
	string = [string stringByReplacingOccurrencesOfString:@"&amp;" withString:@"&"];
	string = [string stringByReplacingOccurrencesOfString:@"&lt;" withString:@"<"];
	string = [string stringByReplacingOccurrencesOfString:@"&gt;" withString:@">"];
	string = [string stringByReplacingOccurrencesOfString:@"\n" withString:@" "];
	return string;
} 

+(NSString*)parseAt:(NSArray*)atList text:(NSString*)text {
    //	text = [self stringWithUnescapeHTML:text];
    if (![atList isKindOfClass:[NSArray class]]) {
        return text;
    }
    
	text = [text stringByReplacingOccurrencesOfString:@"\n" withString:@" "];
	for (NSUInteger i = 0; i < [atList count]; i++) {
		NSDictionary* atDict = [atList objectAtIndex:i];
		
		NSUInteger uid = [[atDict objectForKey:@"id"] intValue];
		NSString*  userName = [atDict objectForKey:@"name"];
		NSString* atLink = [NSString stringWithFormat:@"<A href=\"momo://user=%d\">@%@</A>", uid, userName]; 
		NSString* target = [NSString stringWithFormat:@"[@%d]", i];
		text = [text stringByReplacingOccurrencesOfString:target withString:atLink];
	}
	return text;
}

-(id)initWithDictionary:(NSDictionary*)dic {
	self = [super init];
	if (self) {
		self.id = [dic objectForKey:@"id"];
		self.statusId = [dic objectForKey:@"statuses_id"];
		self.ownerId = [[[dic objectForKey:@"user"] objectForKey:@"id"] intValue];
		self.ownerName = [[dic objectForKey:@"user"] objectForKey:@"name"];
		self.dateLine = [[dic objectForKey:@"created_at"] longLongValue];
		self.kind = [[dic objectForKey:@"kind"] intValue];
        
		if ([[dic objectForKey:@"new"] intValue] == 0) {
			self.isRead = YES;
		} else {
			self.isRead = NO;
		}
        
		if (MMAboutMeMessageKindBroadcast == self.kind || MMAboutMeMessageKindLeaveMessage == self.kind) {
			NSArray *atList = [[[dic objectForKey:@"opt"] objectForKey:@"statuses"] objectForKey:@"at"];
			NSString *text = [[[dic objectForKey:@"opt"] objectForKey:@"statuses"] objectForKey:@"text"];
			self.comment = [[self class] parseAt:atList text:text];
		} else if(MMAboutMeMessageKindComment == self.kind || MMAboutMeMessageKindAtComment == self.kind || MMAboutMeMessageKindReply == self.kind) {
			self.commentId = [[[dic objectForKey:@"opt"] objectForKey:@"comment"] objectForKey:@"id"];
			NSArray *atList = [[[dic objectForKey:@"opt"] objectForKey:@"comment"] objectForKey:@"at"];
			NSString *text = [[[dic objectForKey:@"opt"] objectForKey:@"comment"] objectForKey:@"text"];
			self.comment = [[self class] parseAt:atList text:text];
        } else if (MMAboutMeMessageKindPraise == self.kind) {
            self.comment = [dic objectForKey:@"text"];
        } else if (MMAboutMeMessageKindReply == self.kind) {
			NSArray *atList = [[[dic objectForKey:@"opt"] objectForKey:@"reply_source"] objectForKey:@"at"];
			NSString *text = [[[dic objectForKey:@"opt"] objectForKey:@"reply_source"] objectForKey:@"text"];
			self.sourceComment = [[self class] parseAt:atList text:text];
		}
	}
	return self;
}


- (BOOL)isEqual:(id)object {
	if([object isKindOfClass:[MMAboutMeMessage class]]){
		MMAboutMeMessage *other = (MMAboutMeMessage*)object;
		return [self.id isEqualToString:other.id];
	}
	return NO;
    
}

- (void)dealloc {
	self.id = nil;
	self.ownerName = nil;
	self.statusId = nil;
	self.commentId = nil;
	self.comment = nil;
	self.sourceComment = nil;
	[super dealloc];
}

@end


////////////////////////////////////////////////////////
//动态中的附件结构
@implementation MMAccessoryInfo
@synthesize accessoryType, type, accessoryId, title, url;

- (id)init {
	if (self = [super init]) {
		accessoryType = MMAccessoryTypeNone;
	}
	return self;
}

+ (MMAccessoryType)typeFromString:(NSString*)typeString {
    if ([typeString compare:@"pic" options:NSCaseInsensitiveSearch] == NSOrderedSame) {
        return MMAccessoryTypeImage;
    } else if ([typeString compare:@"file" options:NSCaseInsensitiveSearch] == NSOrderedSame) {
        return MMAccessoryTypeFile;
    } else {
        return MMAccessoryTypeNone;
    }
}

+ (MMAccessoryInfo*)accessoryInfoFromDict:(NSDictionary*)accessoryDict {
	NSUInteger accessoryType = [MMAccessoryInfo typeFromString:[accessoryDict objectForKey:@"type"]];
    MMAccessoryInfo* accessoryInfo = nil;
	switch (accessoryType) {
		case MMAccessoryTypeFile:
		{
        accessoryInfo = [[[MMFileAccessoryInfo alloc] init] autorelease];
        [accessoryInfo loadFromDict:accessoryDict];
		}
			break;
        case MMAccessoryTypeImage:
		{
        accessoryInfo =  [[[MMImageAccessoryInfo alloc] init] autorelease];
        [accessoryInfo loadFromDict:accessoryDict];
		}
			break;
		default:
        {
        accessoryInfo = [[[MMAccessoryInfo alloc] init] autorelease];
        [accessoryInfo loadFromDict:accessoryDict];
        }
			break;
	}
    accessoryInfo.accessoryType = accessoryType;
	return accessoryInfo;
}

- (void)loadFromDict:(NSDictionary*)accessoryDict {
    self.type = [accessoryDict objectForKey:@"type"];
    self.accessoryId = [[accessoryDict objectForKey:@"id"] unsignedLongLongValue];
	self.title = [accessoryDict objectForKey:@"title"];
	self.url = [accessoryDict objectForKey:@"url"];
}

- (NSMutableDictionary*)toDict {
	NSMutableDictionary* accessoryDict = [NSMutableDictionary dictionary];
    [accessoryDict setObject:self.type forKey:@"type"];
	[accessoryDict setObject:[NSNumber numberWithUnsignedLongLong:self.accessoryId] forKey:@"id"];
	[accessoryDict setObject:self.title forKey:@"title"];
	[accessoryDict setObject:self.url forKey:@"url"];
    return accessoryDict;
}

- (void)dealloc {
    self.type = nil;
    self.title = nil;
    self.url = nil;
    [super dealloc];
}

@end

@implementation MMFileAccessoryInfo
@synthesize size, mime;

- (void)dealloc {
    self.mime = nil;
	
	[super dealloc];
}

- (void)loadFromDict:(NSDictionary*)accessoryDict {
    [super loadFromDict:accessoryDict];
	
    NSDictionary* metaDict = [accessoryDict objectForKey:@"meta"];
    if (metaDict && [metaDict isKindOfClass:[NSDictionary class]]) {
        self.size = [[metaDict objectForKey:@"size"] longLongValue];
        self.mime = [metaDict objectForKey:@"mime"];
    }
}

- (NSDictionary*)toDict {
	NSMutableDictionary* accessoryDict = [super toDict];
    
    NSMutableDictionary* metaDict = [NSMutableDictionary dictionary];
    [metaDict setObject:[NSNumber numberWithLongLong:size] forKey:@"size"];
    [metaDict setObject:PARSE_NULL_STR(mime) forKey:@"mime"];
    [accessoryDict setObject:metaDict forKey:@"meta"];
    
	return accessoryDict;
}

@end

@implementation MMImageAccessoryInfo
@synthesize statusId, width, height;

- (void)loadFromDict:(NSDictionary*)accessoryDict {
    [super loadFromDict:accessoryDict];
	self.statusId = [accessoryDict objectForKey:@"status_id"];
    NSDictionary* metaDict = [accessoryDict objectForKey:@"meta"];
    if (metaDict && [metaDict isKindOfClass:[NSDictionary class]]) {
        width = [[metaDict objectForKey:@"width"] intValue];
        height = [[metaDict objectForKey:@"height"] intValue];
    }
}

- (NSDictionary*)toDict {
	NSMutableDictionary* accessoryDict = [super toDict];
    [accessoryDict setObject:statusId forKey:@"status_id"];
    
    NSMutableDictionary* metaDict = [NSMutableDictionary dictionary];
    [metaDict setObject:[NSNumber numberWithLongLong:width] forKey:@"width"];
    [metaDict setObject:[NSNumber numberWithLongLong:height] forKey:@"height"];
    [accessoryDict setObject:metaDict forKey:@"meta"];
    
	return accessoryDict;
}

- (void)dealloc {
    self.statusId = nil;
    [super dealloc];
}

@end

@implementation MMCountryInfo
@synthesize enCountryName, cnCountryName, isoCountryCode, telCode, validPhoneLen, validPhonePrefix;

+ (id)countryInfoFromDictionary:(NSDictionary*)dictionary {
    MMCountryInfo* countryInfo = [[[MMCountryInfo alloc] init] autorelease];
    countryInfo.enCountryName = [dictionary objectForKey:@"en"];
    countryInfo.cnCountryName = [dictionary objectForKey:@"cn"];
    countryInfo.isoCountryCode = [dictionary objectForKey:@"iso"];
    countryInfo.telCode = [dictionary objectForKey:@"ic"];
    countryInfo.validPhoneLen = [dictionary objectForKey:@"len"];
    countryInfo.validPhonePrefix = [dictionary objectForKey:@"mc"];
    
    return countryInfo;
}

- (void)dealloc {
    self.enCountryName = nil;
    self.cnCountryName = nil;
    self.isoCountryCode = nil;
    self.telCode = nil;
    self.validPhoneLen = nil;
    self.validPhonePrefix = nil;
    [super dealloc];
}

@end

@implementation MMMyMoInfo
@synthesize sms = sms_;

@end


//名片结构
@implementation MMCard

@synthesize uid, registerName, gender, animalSign, zodiac, residence, note, organization, avatarUrl, userLink;
@synthesize isInMyContact, userStatus, birthday, lunarBirthday, isHideBirthdayYear, isLunar;
@synthesize completeLevel, sendedCardCount, properties;


- (id)init {
	if (self = [super init]) {
        
        uid = 0;                 //用户ID(整型)
        registerName = @"";      //注册名
        gender = 0;              //性别
        animalSign = @"";        //生肖
        zodiac = @"";            //星座
        residence = @"";         //居住地
        note = @"";              //个人描述
        organization = @"";      //公司/学校 
        avatarUrl = @"";         //用户头像地址
        userLink = 0;            //用户标识， 0：陌生人，1：对方有我的手机号，2：对方给我授权, 3:自己
        isInMyContact = NO;      //我的联系人是否有他
        userStatus = 0;          //用户状态
        
        birthday = nil;          //生日
        lunarBirthday = nil;     //农历生日
        isHideBirthdayYear = NO; //是否隐藏年份
        isLunar = NO;            //是否过农历
        
        completeLevel = 0;       //完善度0-100
        sendedCardCount = 0;     //发送名片个数
        
        properties = nil;        //邮箱类型,电话类型,微博类型 （DbData）
        
	}
	return self;
}

- (void)dealloc {
    
    self.registerName = nil;
    self.animalSign = nil;
    self.zodiac = nil;
    self.residence = nil;
    self.note = nil;
    self.organization = nil;
    self.avatarUrl = nil;
    self.birthday = nil;
    self.lunarBirthday = nil;
    self.properties = nil;
    
	[super dealloc];
}

- (id)copyWithZone:(NSZone *)zone {
	
	MMCard *newCard = [[MMCard allocWithZone:zone] init];
    
    newCard.uid = self.uid;                
    newCard.registerName = self.registerName;     
    newCard.gender = self.gender;             
    newCard.animalSign = self.animalSign;       
    newCard.zodiac = self.zodiac;           
    newCard.residence = self.residence;        
    newCard.note = self.note;             
    newCard.organization = self.organization;     
    newCard.avatarUrl = self.avatarUrl;        
    newCard.userLink = self.userLink;           
    newCard.isInMyContact = self.isInMyContact;     
    newCard.userStatus = self.userStatus;         
    newCard.birthday = self.birthday;         
    newCard.lunarBirthday = self.lunarBirthday;    
    newCard.isHideBirthdayYear = self.isHideBirthdayYear;
    newCard.isLunar = self.isLunar;           
    newCard.completeLevel = self.completeLevel;      
    newCard.sendedCardCount = self.sendedCardCount;    
    
	NSMutableArray *newArray = [NSMutableArray array];
	for (DbData *data in self.properties) {
		DbData *newData = [[[DbData alloc] initWithDbData:data] autorelease];
		[newArray addObject:newData];
	}
	
	newCard.properties = newArray;
    
	return newCard;
}

-(DbData*)mainTelephone {
    for (DbData *data in properties) {
        if ([data isMainTelephone]) {
            return data;
        }
    }
    return nil;
}

@end

@implementation MMContactChangeInfo
@synthesize userID = userID_;
@synthesize dateLine = dateLine_;
@synthesize source = source_;
@synthesize operation = operation_;
@synthesize addCount = addCount_;
@synthesize updateCount = updateCount_;
@synthesize deleteCount = deleteCount_;

- (void)dealloc {
    self.source = nil;
    self.operation = nil;
    [super dealloc];
}

- (id)initWithDictionary:(NSDictionary *)dict {
    self = [self init];
    if (self) {
        self.userID = [[dict objectForKey:@"user_id"] intValue];
        self.dateLine = [[dict objectForKey:@"dateline"] intValue];
        self.source = [dict objectForKey:@"source"];
        self.operation = [dict objectForKey:@"operation"];
        self.addCount = [[dict objectForKey:@"add_count"] intValue];
        self.updateCount = [[dict objectForKey:@"update_count"] intValue];
        self.deleteCount = [[dict objectForKey:@"delete_count"] intValue];
    }
    return self;
}

@end

@implementation MMGroupInfo
@synthesize groupId = groupId_;
@synthesize groupName = groupName_;
@synthesize groupOpenType = groupOpenType_;
@synthesize notice = notice_;
@synthesize introduction = introduction_;
@synthesize createTime = createTime_;
@synthesize modifyTime = modifyTime_;
@synthesize creator = creator_;
@synthesize master = master_;
@synthesize managers = managers_;
@synthesize memberCount = memberCount_;
@synthesize isHide = isHide_;

- (void)dealloc {
    self.groupName = nil;
    self.notice = nil;
    self.introduction = nil;
    self.creator = nil;
    self.master = nil;
    self.managers = nil;
    [super dealloc];
}

+ (MMGroupInfo*)groupInfoFromDict:(NSDictionary*)dict {
    MMGroupInfo* groupInfo = [[[MMGroupInfo alloc] init] autorelease];
    
    groupInfo.groupId = [[dict objectForKey:@"id"] intValue];
    groupInfo.groupName = [dict objectForKey:@"name"];
    groupInfo.notice = [dict objectForKey:@"notice"];
    groupInfo.introduction = [dict objectForKey:@"introduction"];
    groupInfo.groupOpenType = [[dict objectForKey:@"type"] intValue];
    groupInfo.createTime = [[dict objectForKey:@"created_at"] intValue];
    groupInfo.modifyTime = [[dict objectForKey:@"modified_at"] intValue];
    
    groupInfo.creator = [[[MMMomoUserInfo alloc] initWithDictionary:[dict objectForKey:@"creator"]] autorelease];
    groupInfo.master = [[[MMMomoUserInfo alloc] initWithDictionary:[dict objectForKey:@"master"]] autorelease];
    
    NSMutableArray* tmpArray = [NSMutableArray array];
    for (NSDictionary* userDict in [dict objectForKey:@"manager"]) {
        MMMomoUserInfo* userInfo = [[[MMMomoUserInfo alloc] initWithDictionary:userDict] autorelease];
        [tmpArray addObject:userInfo];
    }
    
    if (tmpArray.count > 0) {
        groupInfo.managers = tmpArray;
    }
    
    groupInfo.memberCount = [[dict objectForKey:@"member_count"] intValue];
    groupInfo.isHide = [[dict objectForKey:@"is_hide"] boolValue];
    
    return groupInfo;
}

@end

@implementation MMGroupMemberInfo
@synthesize grade = grade_;

+ (MMGroupMemberInfo*)groupMemberInfoFromDict:(NSDictionary*)dict {
    MMGroupMemberInfo* memberInfo = [[[MMGroupMemberInfo alloc] init] autorelease];
    
    memberInfo.uid = [[dict objectForKey:@"id"] intValue];
    memberInfo.realName = [dict objectForKey:@"name"];
    memberInfo.avatarImageUrl = [dict objectForKey:@"avatar"];
    memberInfo.grade = [[dict objectForKey:@"grade"] intValue];
    
    return  memberInfo;
}

- (NSString*)namePinyin {
    return [MMPhoneticAbbr getPinyin:realName];
}

@end