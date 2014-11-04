//
//  MMContactSync.h
//  momo
//
//  Created by houxh on 11-7-5.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AddressBook/AddressBook.h>
#import "MMModel.h"

#define kMMSyncProgress @"SyncProgress" //同步进度

@interface MMSyncResult : NSObject
{
	NSInteger downloadAddCount;
	NSInteger downloadDelCount;
	NSInteger downloadUpdateCount;
	NSInteger uploadAddCount;
	NSInteger uploadDelCount;
	NSInteger uploadUpdateCount;
	
	NSInteger momoDownloadAddCount;
	NSInteger momoDownloadDelCount;
	NSInteger momoDownloadUpdateCount;
	
	NSInteger momoCardDownloadCount;
}
@property(nonatomic)NSInteger downloadAddCount;
@property(nonatomic)NSInteger downloadDelCount;
@property(nonatomic)NSInteger downloadUpdateCount;
@property(nonatomic)NSInteger uploadAddCount;
@property(nonatomic)NSInteger uploadDelCount;
@property(nonatomic)NSInteger uploadUpdateCount;
@property(nonatomic)NSInteger momoDownloadAddCount;
@property(nonatomic)NSInteger momoDownloadDelCount;
@property(nonatomic)NSInteger momoDownloadUpdateCount;
@property(nonatomic)NSInteger momoCardDownloadCount;
@end

//同步进度
@interface MMSyncProgressInfo : NSObject {
    NSString* stageTitle_;
    NSInteger stageCount_;
    NSInteger currentStageIndex_;
    
    NSInteger stageOperationCount_;
    NSInteger stageOperationIndex_;
    float currentProgress_;
    
    BOOL infoChanged_;
}
@property (nonatomic, copy) NSString* stageTitle;
@property (nonatomic) NSInteger stageCount;
@property (nonatomic) NSInteger currentStageIndex;
@property (nonatomic) NSInteger stageOperationCount;
@property (nonatomic) NSInteger stageOperationIndex;
@property (nonatomic, readonly) float currentProgress;

- (void)notifyProgressIfNeed;

@end

//同步联系人（包含头像）及其分组
@interface MMContactSync : MMModel {
	NSDictionary *categoryCache_;
	MMSyncResult *syncResult_;
	
    MMSyncProgressInfo* syncProgress_;
}
@property(nonatomic, readonly)MMSyncResult *syncResult;
@property (nonatomic, retain) MMSyncProgressInfo* syncProgress;

-(BOOL) isCancelled;
-(BOOL) clearSyncDb;
@end


@interface MMContactSync(Category)

-(void) loadCategoryCache:(ABAddressBookRef)addressBook;
-(void) clearCategoryCache;

-(NSArray*) getContactCategoryByPhoneContactId:(NSInteger)phoneCid;

@end

@interface MMContactSync(Contact)
-(BOOL) addressBookToMomo;
-(BOOL) downloadContactToMomo;
-(BOOL) downloadContactToMomo:(NSArray*)simpleList;
-(BOOL) uploadContact;
-(BOOL) downloadContact;
-(BOOL) downloadContact:(NSArray*)simpleList;

-(NSMutableArray*)getContactSyncInfoList;

-(NSInteger)getCellIdByContactId:(NSInteger)contactId;
-(BOOL) deleteContactDown:(NSInteger)contactId;
-(NSInteger)getContactIdByCellId:(NSInteger)cellId;
-(BOOL)touchPhoneContact:(NSInteger)contactId;

@end