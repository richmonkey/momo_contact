//
//  MMLogger.m
//  momo
//
//  Created by jackie on 11-6-28.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "MMLogger.h"
#import <fcntl.h>
#import <QuartzCore/CABase.h>

void simulatorLog(NSString *logStr,const char* sourceFile, int line){
	char *p;
	p = (char*)sourceFile;
	char *cur = (char*)sourceFile;
	while (*p!=0) {
		if(*p=='/') cur = p+1;
		p++;
	}
	NSString *fullstr = [NSString stringWithFormat:@"%s#%d:%@\n", cur, line, logStr];
	printf("%s", [fullstr UTF8String]);
}

void simulatorLogCString(char *logStr,const char* sourceFile, int line) {
	char *p;
	p = (char*)sourceFile;
	char *cur = (char*)sourceFile;
	while (*p!=0) {
		if(*p=='/') cur = p+1;
		p++;
	}
	printf("%s#%d:%s\n", cur, line, logStr);
}

MMLogger *g_logger = NULL;
@implementation MMLogger

+ (MMLogger*)shareInstance{
	if (!g_logger) {
		@synchronized(self) {
			if (!g_logger) {

				
				NSString* path = [NSHomeDirectory() stringByAppendingFormat:@"/tmp/momo.log"];
				if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
					[[NSFileManager defaultManager] createFileAtPath:path contents:nil attributes:nil];
				} else {
                    NSDictionary *dict = [[NSFileManager defaultManager] attributesOfFileSystemForPath:path error:nil];
                    unsigned long long size = [dict fileSize];
                    if (size > 10*1024*1024) {
                        [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
                        [[NSFileManager defaultManager] createFileAtPath:path contents:nil attributes:nil];
                    }
                }
				g_logger = [[MMLogger alloc] initWithFilePath:path];
			}
		}
	}
	return g_logger;
}

- (MMLogger*)initWithFilePath:(NSString*)path{
	if(self=[super init]){
		logFile_ = [[NSFileHandle fileHandleForWritingAtPath:path] retain];
		[logFile_ seekToEndOfFile];
		
		NSDate* date = [NSDate date];
		NSDateFormatter* formatter = [[[NSDateFormatter alloc] init] autorelease];
		[formatter setDateFormat:@"yyy-MM-dd HH:mm:SS"];
		NSString* dateString = [formatter stringFromDate:date];
		NSString *s=[NSString stringWithFormat:
					 @"******************************************************"
					 "\n----------------------------------------------------"
					 "\n%@\n"
					 "----------------------------------------------------\n"
					 ,dateString];
		
		[logFile_ writeData:[s dataUsingEncoding:NSUTF8StringEncoding]];
		[logFile_ synchronizeFile];			
	}
	return self;
}

- (void)log:(NSString*)s{
	[logFile_ seekToEndOfFile];
	[logFile_ writeData:[s dataUsingEncoding:NSUTF8StringEncoding]];
}

- (void)dealloc
{
	[logFile_ closeFile];
	[logFile_ release];
	[super dealloc];
}

+ (void)log:(NSString*)logString sourceFile:(const char*)sourceFile lineNum:(int)lineNum {
	MMLogger* logger = [MMLogger shareInstance];
	if (!logger) {
		return;
	}
	
	char *p;
	p = (char*)sourceFile;
	char *cur = p;
	while (*p!=0) {
		if(*p=='/') cur = p+1;
		p++;
	}

	[logger log:[NSString stringWithFormat:@"%s#%d:%@\n", cur, lineNum, logString]];
}

@end

////////////////////////////////////////////////////////////////////////////
@interface MMTimeCountInfo : NSObject {
    CFTimeInterval startTime_;
    CFTimeInterval lastTime_;
    NSInteger countNum_;
}
@property (nonatomic) CFTimeInterval startTime;
@property (nonatomic) CFTimeInterval lastTime;
@property (nonatomic) NSInteger countNum;

@end

@implementation MMTimeCountInfo
@synthesize startTime = startTime_;
@synthesize lastTime = lastTime_;
@synthesize countNum = countNum_;

- (id)init {
    self = [super init];
    if (self) {
        startTime_ = CACurrentMediaTime();
        lastTime_ = startTime_;
    }
    return self;
}

@end

static CFTimeInterval currentTime = 0;
char buf[256];
static NSMutableDictionary* timeCountDict = nil;

void start_time_count(const char* sourceFile, int line, bool writeToLogFile, NSString* label) {
    if (!timeCountDict) {
        timeCountDict = [[NSMutableDictionary alloc] init];
    }
    
    NSCAssert(label, @"Need A valid label");
    
	currentTime = CACurrentMediaTime();
    
    MMTimeCountInfo* countInfo = [timeCountDict objectForKey:label];
    if (!countInfo) {
        countInfo = [[[MMTimeCountInfo alloc] init] autorelease];
        [timeCountDict setObject:countInfo forKey:label];
    }
    countInfo.startTime = currentTime;
    countInfo.lastTime = currentTime;
    countInfo.countNum = 0;
    
	if (writeToLogFile) {
		[MMLogger log:[NSString stringWithUTF8String:buf] sourceFile:sourceFile lineNum:line];
	}
}

void print_time_count(const char* sourceFile, int line, bool writeToLogFile, NSString* label) {
	CFTimeInterval tmpTime = CACurrentMediaTime();
    
    MMTimeCountInfo* countInfo = [timeCountDict objectForKey:label];
    if (!countInfo) {
        printf("Need invoke Start_Count first for label: %s\n", label.UTF8String);
        return;
    }
    
    CFTimeInterval timeElapsed = tmpTime - countInfo.lastTime;
    countInfo.lastTime = tmpTime;
	
	sprintf(buf, "%s(%d) -- time used: %f", label.UTF8String, countInfo.countNum++,  timeElapsed);
	simulatorLogCString(buf, sourceFile, line);
    
	if (writeToLogFile) {
		[MMLogger log:[NSString stringWithUTF8String:buf] sourceFile:sourceFile lineNum:line];
	}
}
