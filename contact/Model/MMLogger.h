//
//  MMLogger.h
//  momo
//
//  Created by jackie on 11-6-28.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#if defined(__cplusplus)
extern "C" {
#endif
	void simulatorLog(NSString *logStr,const char* sourceFile, int line);
	void simulatorLogCString(char *logStr,const char* sourceFile, int line);
#if defined(__cplusplus)
}
#endif

#define DLOG(...) simulatorLog([NSString stringWithFormat:__VA_ARGS__], __FILE__, __LINE__)

#define MLOG(...) {simulatorLog([NSString stringWithFormat:__VA_ARGS__], __FILE__, __LINE__); \
					LOG(__VA_ARGS__);} 

//#if TARGET_IPHONE_SIMULATOR
//#define MLOG(...) simulatorLog([NSString stringWithFormat:__VA_ARGS__], __FILE__, __LINE__)
//#else
//#define MLOG(...) LOG(__VA_ARGS__)
//#endif

#define LOG(...) [MMLogger log:[NSString stringWithFormat:__VA_ARGS__] sourceFile:__FILE__ lineNum:__LINE__];
@interface MMLogger : NSObject {
	NSFileHandle *logFile_;
}
- (MMLogger*)initWithFilePath:(NSString*)path;
+ (void)log:(NSString*)logString sourceFile:(const char*)sourceFile lineNum:(int)lineNum;

@end

#define BEGIN_TICKET(name) NSTimeInterval begin##name = [[NSDate date] timeIntervalSince1970]

#define END_TICKET(name) do {NSTimeInterval end##name = [[NSDate date] timeIntervalSince1970]; DLOG(@#name@" time used:%f second", end##name - begin##name);}while(0)

//计算实际间隔
#if defined(__cplusplus)
extern "C" {
#endif
	void start_time_count(const char* sourceFile, int line, bool writeToLogFile, NSString* label);
	void print_time_count(const char* sourceFile, int line, bool writeToLogFile, NSString* label);
#if defined(__cplusplus)
}
#endif

#define START_COUNT1(label) start_time_count(__FILE__, __LINE__, 0, label)
#define PRINT_COUNT1(label) print_time_count(__FILE__, __LINE__, 0, label)
#define START_COUNT START_COUNT1(@"")
#define PRINT_COUNT PRINT_COUNT1(@"")




