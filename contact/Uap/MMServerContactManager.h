//
//  MMServerContactManager.h
//  momo
//
//  Created by houxh on 11-7-6.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DbStruct.h"
#import "MMModel.h"

typedef MMFullContact MMUserCard;
@interface MMMomoContact : MMFullContact
{
	NSInteger	phoneCid;//手机联系人本身自增ID 
}
@end
typedef DbContactSyncInfo MMMomoContactSimple;

@interface MMServerContactManager : NSObject {

}
+(BOOL)uploadAvatar:(NSData*)data url:(NSString**)url;
+(NSArray*)getSimpleContactList;
+(NSArray*)getContactList:(NSArray*)ids;
+(NSInteger)addContacts:(NSArray*)contacts response:(NSArray**)response;
+(NSInteger)addContact:(MMMomoContact*)contact response:(NSDictionary**)res;

+(NSInteger)updateContact:(MMMomoContact*)contact response:(NSDictionary**)response;
+(BOOL)deleteContacts:(NSArray*)contactIds;
+(BOOL)deleteContacts:(NSArray*)contactIds response:(NSArray**)response;
+(NSInteger)deleteContact:(NSInteger)contactId;
+(NSDictionary*)encodeContact:(MMFullContact *)contact;
+(MMMomoContact*)decodeContact:(NSDictionary*)dic;

+(NSArray*)addContactStarState:(NSArray*)contactIds;
+(NSArray*)removeContactStarState:(NSArray*)contactIds;

+ (NSArray*)getContactChangeHistory:(NSInteger)page withErrorString:(NSString**)errorString;
+ (BOOL)recoverContactChangeHistory:(NSInteger)dateLine;

#pragma mark -
#pragma mark 联系人界面上的机器人
+ (NSArray*)getAllRobot;

#pragma mark -
#pragma mark momo名片 服务器操作


+(BOOL)changeMobile:(NSString *)mobile password:(NSString *)password withErrorString:(NSString**)errorString;
+(BOOL)bindingWeibo:(NSDictionary *)weiboDic withErrorString:(NSString**)errorString;
+ (BOOL)cancelBindingWeiboWithErrorString:(NSString**)errorString; 

@end
