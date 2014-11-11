//
//  contact.m
//  Db
//
//  Created by aminby on 2010-7-22.
//  Copyright 2010 NetDragon.Co. All rights reserved.
//

#import "MMModel.h"
#import "MMGlobalPara.h"


#define DB_FILENAME @"momo.db"
static pthread_key_t threadDBKey = NULL;

@implementation MMModel

void closeThreadDBConnenction(void* parameter) {
	PLSqliteDatabase* dbConnenction = (PLSqliteDatabase*)parameter;
	if (dbConnenction && [(PLSqliteDatabase*)dbConnenction isKindOfClass:[PLSqliteDatabase class]]) {
		[dbConnenction close];
		[dbConnenction release];
	}
}

+ (void)initialize {
	if (self == [MMModel class]) {
		pthread_key_create(&threadDBKey, closeThreadDBConnenction);
	}
}

+ (pthread_key_t)threadDBKey {
	return threadDBKey;
}

+(NSString*)getDbPath{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError* error;
    
    // 如果文件已经存在, 则返回路径
    NSString *documentsDirectory = [MMGlobalPara documentDirectory];
    NSString *dbPath = [documentsDirectory stringByAppendingPathComponent:DB_FILENAME];
    if([fileManager fileExistsAtPath:dbPath])
        return dbPath;

    // 如果文件不存在, 拷贝一份, 返回路径
    NSString *defaultDBPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:DB_FILENAME];
	NSLog(@"%@ \n %@", dbPath, defaultDBPath);
    if( [fileManager copyItemAtPath:defaultDBPath toPath:dbPath error:&error])
        return dbPath;
    
    return nil;
}

-(id) init{
//    database = nil;
	if (self = [super init]) {
		
	}
    return self;
}

-(BOOL) isDbOK {
    return [[self db] goodConnection];
}

- (NSInteger) getLastInsertId:(MMErrorType*)error{
    // 错误码
    MMErrorType ret = MM_DB_OK;
    NSInteger last_insert_id = 0;
    
    NSError* nserror = nil;
    
    PLResultSetStatus status;
    do{
        // 如果数据没打开
        if(![[self db] goodConnection]) {
            ret = MM_DB_FAILED_OPEN;
            break;
        }
        
        // 返回结果
        id<PLResultSet> results = [[self db] executeQueryAndReturnError:&nserror statement:@"SELECT last_insert_rowid() last_insert_id "];

        // 如果出错        
        if(nserror && [nserror code] != SQLITE_OK) {
            ret = MM_DB_FAILED_QUERY;
            break;
        }
        
        status = [results nextAndReturnError:nil];
        
        // 循环返回结果
        if(status) {
            last_insert_id = [results intForColumn:@"last_insert_id"];
        }
        [results close];
    }
    while(0);
    
    // 返回错误码
    if(error != nil)
        *error = ret;
    
    return last_insert_id;
}

- (PLSqliteDatabase*)db{
	PLSqliteDatabase* currentThreadDB = (PLSqliteDatabase*)pthread_getspecific(threadDBKey);
	if (!currentThreadDB || ![currentThreadDB isKindOfClass:[PLSqliteDatabase class]]) {
		NSString* path = [MMModel getDbPath];
        
        currentThreadDB = [[PLSqliteDatabase alloc] initWithPath:path];
        if(path) {
            [currentThreadDB open];
        }
		
		pthread_setspecific(threadDBKey, (void*)currentThreadDB);
	}
	
	return currentThreadDB;
}

@end
