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
+(NSInteger)deleteContact:(int64_t)contactId;
+(NSDictionary*)encodeContact:(MMFullContact *)contact;
+(MMMomoContact*)decodeContact:(NSDictionary*)dic;

+(NSArray*)addContactStarState:(NSArray*)contactIds;
+(NSArray*)removeContactStarState:(NSArray*)contactIds;

+ (NSArray*)getContactChangeHistory:(int)page withErrorString:(NSString**)errorString;
+ (BOOL)recoverContactChangeHistory:(int)dateLine;

+(BOOL)getContactCount:(int*)count;

@end
