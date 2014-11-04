//
//  contact.h
//  Db
//
//  Created by aminby on 2010-7-22.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PlausibleDatabase.h"
#import "PLSqliteDatabase.h"
#import <pthread.h>
// @interface PLSqliteDatabase;

#include "ErrorType.h"
#include "DefineEnum.h"
#import "DbStruct.h"

@interface MMModel : NSObject {
//    PLSqliteDatabase* database;
}

+ (pthread_key_t)threadDBKey;

+ (NSString*)getDbPath;

// @property (readonly, retain) PLSqliteDatabase* db;
- (id)init;

- (NSInteger) getLastInsertId:(MMErrorType*)error;

- (PLSqliteDatabase*)db;


@end