//
//  MMDbProfile.m
//  momo
//
//  Created by m fm on 11-3-16.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "MMDbProfile.h"
#import "MMContact.h"


@implementation MMDbProfile

+ (id)instance {
	static id _instance = nil;
    @synchronized(self) {
        if(_instance == nil) 
            _instance = [[self class] new];
    }
    return _instance;
}

- (NSArray*) getAllLabelInProfileWithError:(MMErrorType*)error{
	
	//查询出所有带有此label的联系人
	MMErrorType ret = MM_DB_OK;
	NSError* outError = nil;
	PLResultSetStatus status;
	
	NSMutableArray *arrayLabel = [[[NSMutableArray alloc]init] autorelease];
	
	do {
		// 如果数据没打开
        if(![[self db]  goodConnection]) {
            ret = MM_DB_FAILED_OPEN;
            break;
        }
		
		// 返回结果
        NSString* sql = @"select distinct value from profile where key like 'DataLable-%%' ";
        id<PLResultSet> results = [[self db]  
								   executeQueryAndReturnError:&outError 
								   statement:sql];
        
        if(SQLITE_OK != [outError code]) {
            ret = MM_DB_FAILED_QUERY;
            break;
        }
		
        
        status = [results nextAndReturnError:nil];
		while(status) {
			NSString *label = [results stringForColumn:@"value"];
			[arrayLabel addObject:label];
			status = [results nextAndReturnError:nil];
		}
		[results close];	
		
		
	} while (0);
	
	if (nil != error) {
		*error = ret;
	}
	
	
	
	return arrayLabel;
}

- (MMErrorType)insertLabel:(NSString*)label{
	MMErrorType ret = MM_DB_OK;
	
	do {
		// 如果数据没打开
		if(![[self db]  goodConnection]) {
			ret = MM_DB_FAILED_OPEN;
			break;
		}
		
		NSString* strKey = [NSString stringWithFormat:@"DataLable-%@", label];
		
		
		if (![[self db]  executeUpdate:
			  @"insert into profile (key, value) values (?, ?) ", strKey, label]) {
			
			ret = MM_DB_FAILED_INVALID_STATEMENT;
			break;
		}		
		
		
	} while (0);
	
	return ret;
}

- (MMErrorType)deleteLabel:(NSString*)label{
	MMErrorType ret = MM_DB_OK;
	
	do{
        // 如果数据没打开
        if(![[self db]  goodConnection]) {
            ret = MM_DB_FAILED_OPEN;
            break;
        }		
	
		
		if (![[self db]  executeUpdate:
			  @"delete from profile where key like 'DataLable-%%' and value = ? ", label]) {
			
            ret = MM_DB_FAILED_INVALID_STATEMENT;
            break;
        }		
		
	}
    while(0);
    
    return ret;
}

- (void)setObject:(NSString*)anObject forKey:(NSString*)aKey {
	[self removeObjectForKey:aKey];
	if (![[self db]  executeUpdate:
		  @"insert into profile (key, value) values (?, ?) ", aKey, anObject]) {
		NSLog(@"insert data into profile fail");
	}		
	
}

- (NSString*)objectForKey:(NSString*)aKey {
	NSError* outError = nil;

	NSString* sql = @"select value from profile where key = ?";
	id<PLResultSet> results = [[self db]  
							   executeQueryAndReturnError:&outError 
							   statement:sql, aKey];
	
	if(SQLITE_OK != [outError code]) {
		return nil;
	}
	NSString *value = nil;
	PLResultSetStatus status = [results nextAndReturnError:nil];
	if (status) {
		value = [results stringForColumn:@"value"];
		[[value retain] autorelease];
	}
	[results close];
	return value;
}

- (void)removeObjectForKey:(NSString*)aKey {
	if (![[self db]  executeUpdate:
		  @"delete from profile where key = ? ", aKey]) {
		NSLog(@"delete data from profile fail");
	}	
}

- (void)clearLastCharTime {
    //查询出所有带有此label的联系人
	NSError* outError = nil;
	PLResultSetStatus status;
	
	NSMutableArray *arrayLabel = [NSMutableArray array];
	
	do {
		// 如果数据没打开
        if(![[self db]  goodConnection]) {
            break;
        }
		
		// 返回结果
        NSString* sql = @"select * from profile where key like 'lastChatTime%%' ";
        id<PLResultSet> results = [[self db]  
								   executeQueryAndReturnError:&outError 
								   statement:sql];
        
        if(SQLITE_OK != [outError code]) {
            break;
        }
		
        
        status = [results nextAndReturnError:nil];
		while(status) {
			NSString *label = [results stringForColumn:@"key"];
			[arrayLabel addObject:label];
			status = [results nextAndReturnError:nil];
		}
		[results close];	
		
        for (NSString* key in arrayLabel) {
            [self removeObjectForKey:key];
        }
	} while (0);
}

@end
