/*
 *  MMUapRequest.cpp
 *  libSync
 *
 *  Created by aminby on 2010-6-24.
 *  Copyright 2010 __MyCompanyName__. All rights reserved.
 *
 */

#import "MMUapRequest.h"
#import <CommonCrypto/CommonDigest.h>
#import "json.h"
#import "GTMBase64.h"
#import "MMGlobalData.h"
#import "DbStruct.h"
#import "MMCommonAPI.h"
#import "ASIHTTPRequest.h"
#import "oauth.h"
#import "ASIFormDataRequest.h"
#import "Config.h"

@implementation MMUapRequest
+ (MMUapRequest*)shareInstance {
	static MMUapRequest* instance = nil;
	if(!instance) {
		@synchronized(self) {
			if(!instance) {
				instance = [[MMUapRequest alloc] init];
			}
		}
	}
	return instance;
}

// 计算字符串的MD5
+(NSString*) md5:(NSString*) str {    
    const char *cStr = [str UTF8String];
	unsigned char result[CC_MD5_DIGEST_LENGTH];
	CC_MD5( cStr, strlen(cStr), result );
    
	return [NSString stringWithFormat:
            @"%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X",
            result[0], result[1], result[2], result[3], 
            result[4], result[5], result[6], result[7],
            result[8], result[9], result[10], result[11],
            result[12], result[13], result[14], result[15]
            ];
}

// 计算某个文件的MD5
#define CHUNK_SIZE 1024
+(NSString *)file_md5:(NSString*) path {
    NSFileHandle* handle = [NSFileHandle fileHandleForReadingAtPath:path];
    if(handle == nil)
        return nil;
    
    CC_MD5_CTX md5_ctx;
    CC_MD5_Init(&md5_ctx);
    
    
    
    NSData* filedata;
    do {
        filedata = [handle readDataOfLength:CHUNK_SIZE];
        CC_MD5_Update(&md5_ctx, [filedata bytes], [filedata length]);
    } 
    while([filedata length]);
    
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    CC_MD5_Final(result, &md5_ctx);
    
    [handle closeFile];
    
    return [NSString stringWithFormat:
            @"%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X",
            result[0], result[1], result[2], result[3], 
            result[4], result[5], result[6], result[7],
            result[8], result[9], result[10], result[11],
            result[12], result[13], result[14], result[15]
            ];
}

+ (NSString*)data_md5:(NSData*)data {
	CC_MD5_CTX md5_ctx;
    CC_MD5_Init(&md5_ctx);
	
	NSData* sectionData = nil;
	NSInteger sections = data.length / CHUNK_SIZE;
	if (data.length % CHUNK_SIZE == 0) {
		for (int i = 0; i < sections; ++i) {
			sectionData = [data subdataWithRange:NSMakeRange(i * CHUNK_SIZE, CHUNK_SIZE)];
			CC_MD5_Update(&md5_ctx, [sectionData bytes], [sectionData length]);
		}
	} else {
		for (int i = 0; i < sections + 1; ++i) {
			if (i == sections) {
				sectionData = [data subdataWithRange:NSMakeRange(i * CHUNK_SIZE, data.length % CHUNK_SIZE)];
			}
			else {
				sectionData = [data subdataWithRange:NSMakeRange(i * CHUNK_SIZE, CHUNK_SIZE)];
			}
			
			CC_MD5_Update(&md5_ctx, [sectionData bytes], [sectionData length]);
		}
	}
	
	unsigned char result[CC_MD5_DIGEST_LENGTH];
    CC_MD5_Final(result, &md5_ctx);
    return [NSString stringWithFormat:
            @"%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X",
            result[0], result[1], result[2], result[3], 
            result[4], result[5], result[6], result[7],
            result[8], result[9], result[10], result[11],
            result[12], result[13], result[14], result[15]
            ];
}

// 获得文件的大小
+(NSNumber*) file_size:(NSString*) path{
    FILE* file;
    int filesize = 0;
    file = fopen([path UTF8String], "r");
    if(file > 0) {
        fseek(file, 0, SEEK_END);
        filesize = ftell(file);
        fseek(file,0, SEEK_SET);
        fclose(file);
    }
    return [NSNumber numberWithInt:filesize];
}

/*
 * 文件的文件名
 * 
 * @param str: 文件路径
 *
 * @return : 文件的文件名
 */
+(NSString*) file_name:(NSString*) path{
    int index;
    for(index = [path length] - 1; index >= 0; index--) {
        unichar ch = [path characterAtIndex:index];
        if(ch == '/')
            break;
    }
    
	//    NSRange rage = [path rangeOfString:@"/" options:NSBackwardsSearch | NSCaseInsensitiveSearch];
    
    NSString* ret = nil;
    if(index >= 0) 
        ret = [path substringFromIndex:(index + 1)];
    return ret;
}


+(NSInteger)postSync:(NSString *)source withObject:(NSObject *)object responseData:(NSData**)response {
    ASIHTTPRequest *request = [ASIHTTPRequest requestWithPath:source withObject:object];
    [ASIHTTPRequest startSynchronous:request];
    *response = [request responseData];
    [[*response retain] autorelease];
    return [request responseStatusCode];
}

+(NSInteger)postSync:(NSString *)source withObject:(NSObject *)object responseString:(NSString**)response {
    ASIHTTPRequest *request = [ASIHTTPRequest requestWithPath:source withObject:object];
    [ASIHTTPRequest startSynchronous:request];
    *response = [request responseString];
    [[*response retain] autorelease];
    return [request responseStatusCode];
}

+(NSInteger)postSync:(NSString *)source withObject:(NSObject *)object jsonValue:(id*)response {
    ASIHTTPRequest *request = [ASIHTTPRequest requestWithPath:source withObject:object];
    [ASIHTTPRequest startSynchronous:request];
    *response = [request responseObject];
    [[*response retain] autorelease];
    return [request responseStatusCode];
}

// 发送POST请求
+(NSDictionary*)postSync:(NSString*)source withObject:(NSDictionary*)object{
	NSDictionary *ret = nil;
	int statusCode = [self postSync:source withObject:object jsonValue:&ret];
	if (!ret) {
		ret = [NSMutableDictionary dictionary];
	}
	
	if ([ret isKindOfClass:[NSDictionary class]]) {
		[ret setValue:[NSNumber numberWithInt:statusCode] forKey:STATUS];
	}
	
	return ret;
}

+(NSInteger)responseError:(NSDictionary*)response {
    NSString *error = [response objectForKey:@"error"];
    if ([error length] < 6) {
        return 0;
    }
    error = [error substringToIndex:6];
    return [error intValue];
}

+ (ASIHTTPRequest*)postAsync:(NSString*)source withObject:(NSDictionary*)object withDelegate:(id)delegate {
    ASIHTTPRequest *request = [ASIHTTPRequest requestWithPath:source withObject:object];
    request.delegate = delegate;
    request.uploadProgressDelegate = delegate;
	return request;
}


+(NSInteger)getSync:(NSString*)source responseData:(NSData**)response compress:(BOOL)isCompress{
    ASIHTTPRequest *request = [ASIHTTPRequest requestWithPath:source];
    if (isCompress) {
		[request setAllowCompressedResponse:YES];
	}
    [ASIHTTPRequest startSynchronous:request];
    *response = [request responseData];
	[[*response retain] autorelease];
    return [request responseStatusCode];
}

+(NSInteger)getSync:(NSString*)source responseData:(NSData**)response{
	return [self getSync:source responseData:response compress:NO];
}

+(NSInteger)getSync:(NSString*)source jsonValue:(id*)value compress:(BOOL)isCompress{
	NSString *response = nil;
	int statusCode = [self getSync:source responseString:&response compress:isCompress];
	id ret = nil;
	switch (statusCode) {
		case 200:
		case 400: 
		{
        ret = [response JSONValue];
		}
			break;
		default:
			break;
	}
    *value = ret;
	return statusCode;
}

+(NSInteger)getSync:(NSString*)source responseString:(NSString**)response compress:(BOOL)isCompress{
	NSData *responseData = nil;
	int statusCode = [self getSync:source responseData:&responseData compress:isCompress];
	if (responseData) {
		*response = [[[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding] autorelease];
	}
	return statusCode;
}
// 发送GET请求
+(NSDictionary*)getSync:(NSString*)source withSID:(NSString*)sid compress:(BOOL)isCompress{
	NSDictionary *ret = nil;
	NSInteger statusCode = [self getSync:source jsonValue:&ret compress:isCompress];
	if (!ret) {
		ret = [NSMutableDictionary dictionary];
	}
	
	if ([ret isKindOfClass:[NSDictionary class]]) {
		[ret setValue:[NSNumber numberWithInt:statusCode] forKey:STATUS];
	}
	
	return ret;
}

+(NSDictionary*)getSync:(NSString*)source compress:(BOOL)isCompress{
	return [self getSync:source withSID:nil compress:isCompress];
}



+ (ASIHTTPRequest*)uploadPhotoStep1Async:(NSData*)imgData withDelegate:(id)delegate {
	NSString* md5 = [self data_md5:imgData];
	
	//first step
	NSString* strSource = @"photo/bp_upload.json";
	
	//set parameter
	NSMutableDictionary* objectDict = [NSMutableDictionary dictionary];
	[objectDict setObject:md5 forKey:@"md5"];
	[objectDict setObject:[NSNumber numberWithInt:imgData.length] forKey:@"size"];
	
	ASIHTTPRequest* request = [self postAsync:strSource withObject:objectDict withDelegate:delegate];
	return request;
}

+ (ASIHTTPRequest*)uploadPhotoStep2Async:(NSData*)imgData uploadId:(NSString*)uploadId withDelegate:(id)delegate {
	NSString* strSource = [NSString stringWithFormat:@"photo/bp_upload.json?upload_id=%@&offset=0", uploadId];
	ASIFormDataRequest* request = [ASIFormDataRequest requestWithPath:strSource withObject:nil];
    request.timeOutSeconds = HTTP_REQUEST_TIME_OUT_SECONDS;
	[request setData:imgData withFileName:@"1.jpg" andContentType:@"image/jpeg" forKey:@"photos"];
	request.delegate = delegate;
	return request;
}

+ (NSString*)uploadPhoto:(NSData*)imgData {
    NSString* md5 = [MMUapRequest data_md5:imgData];
    
    //step 1
	NSString* strSource = @"photo/bp_upload.json";
	NSMutableDictionary* objectDict = [NSMutableDictionary dictionary];
	[objectDict setObject:md5 forKey:@"md5"];
	[objectDict setObject:[NSNumber numberWithInt:imgData.length] forKey:@"size"];
	[objectDict setObject:[NSNumber numberWithInt:2] forKey:@"category"];
    
	
	NSDictionary *response = nil;
	NSInteger statusCode = [MMUapRequest postSync:strSource withObject:objectDict jsonValue:&response];
	if (statusCode != 200)
		return NO;
	BOOL isUploaded = [[response objectForKey:@"uploaded"] intValue];
	if (isUploaded) {
		return [[[response objectForKey:@"src"] retain] autorelease];
	}
	//step 2
	NSString *uploadId = [response objectForKey:@"upload_id"];
	ASIHTTPRequest *httpRequest = [MMUapRequest uploadPhotoStep2Async:imgData uploadId:uploadId withDelegate:nil];
	
	MMThread *thread = [MMThread currentThread];
	MMHttpRequestThread *requestThread = nil;
	
	if ([thread isKindOfClass:[MMHttpRequestThread class]]) {
		requestThread = (MMHttpRequestThread*)thread;
	}
	
	requestThread.request = httpRequest;
	if (requestThread.isCancelled) {
		return nil;
	}
	
	[ASIHTTPRequest startSynchronous:httpRequest];
	
	statusCode = [httpRequest responseStatusCode];
	if (statusCode != 200) 
		return nil;
    
	SBJSON* sbjson = [[[SBJSON alloc] init] autorelease];
	NSDictionary *value = [sbjson objectWithString:[httpRequest responseString]];
	NSString *srcUrl = [value objectForKey:@"src"];
	if (!srcUrl) 
		return nil;
	return [[srcUrl retain] autorelease];
}

+ (BOOL)uploadFile:(NSString*)filePath fileUrl:(NSString**)url fileMimeType:(NSString**)type {
    assert(url && type);
    assert([[NSFileManager defaultManager] fileExistsAtPath:filePath]);
	ASIFormDataRequest* request = [ASIFormDataRequest requestWithPath:@"file/upload.json?type=1" withObject:nil];
    request.timeOutSeconds = HTTP_REQUEST_TIME_OUT_SECONDS;
    [request addFile:filePath forKey:@"file"];
    [ASIHTTPRequest startSynchronous:request];
    NSInteger statusCode = [request responseStatusCode];
	if (statusCode != 200) 
		return NO;
    NSDictionary *dic = [request responseObject];
    *url = [dic objectForKey:@"src"];
    *type = [dic objectForKey:@"mime"];
    assert(*url && *type);
    return YES;
}
@end

@implementation MMHttpRequestThread
@synthesize request = request_;

-(void)dealloc {
	self.request = nil;
	[super dealloc];
}

- (void)start {
	//thread对象多次start
	self.request = nil;
	cancelled_ = NO;
	[super start];
}

-(void)main {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    [super main];
    self.request = nil;
    [pool release];
}
-(void)cancel {
	[super cancel];
	[self.request cancel];
}

@end

@implementation ASIHTTPRequest(MMHttpRequest)

+ (id)requestWithPath:(NSString *)path usingSSL:(BOOL)usingSSL {
    NSString* fullUrl = nil;
    fullUrl = [[[Config instance] URL] stringByAppendingFormat:@"%@",path];
	NSURL*url = [NSURL URLWithString:fullUrl];
    
	ASIHTTPRequest* request = [self requestWithURL:url];
	request.timeOutSeconds = HTTP_REQUEST_TIME_OUT_SECONDS;
    
	[request setRequestMethod:@"GET"];
	
	return request;
}

+(id)requestWithPath:(NSString*)path {
	return [self requestWithPath:path usingSSL:NO];
}

+ (id)requestWithPath:(NSString*)path withObject:(NSObject*)object usingSSL:(BOOL)usingSSL {
    NSString* fullUrl = nil;
    fullUrl = [[[Config instance] URL] stringByAppendingFormat:@"%@",path];
	NSURL* url = [NSURL URLWithString:fullUrl];

	ASIHTTPRequest* request = [self requestWithURL:url];
	request.timeOutSeconds = HTTP_REQUEST_TIME_OUT_SECONDS;
	[request setRequestMethod:@"POST"];
	[request addRequestHeader:@"Content-Type" value:@"application/json"];
	
    
    // post body
    if (object != nil) {
		SBJSON* sbjson = [[SBJSON alloc] init];
        NSString* json = [sbjson stringWithObject:object];	
		[request setPostBody:[NSMutableData dataWithData:[json dataUsingEncoding:NSUTF8StringEncoding]]];
		[sbjson release];
    }
	return request;
}

+(id)requestWithPath:(NSString*)path withObject:(NSObject*)object {
    return [self requestWithPath:path withObject:object usingSSL:NO];
}


+ (void)startSynchronous:(ASIHTTPRequest*)request {
	MMThread *thread = [MMThread currentThread];
	MMHttpRequestThread *requestThread = nil;
    
    NSThread *nsthread = [NSThread currentThread];
    NSDictionary *userinfo = [NSDictionary dictionaryWithObject:nsthread forKey:@"thread"];
    request.userInfo = userinfo;
    
	if ([thread isKindOfClass:[MMHttpRequestThread class]]) {
		requestThread = (MMHttpRequestThread*)thread;
	}
	
	requestThread.request = request;
	if (thread.isCancelled) {
		return;
	}
	[request startSynchronous];
}


-(id)responseObject {
	NSString *response = [self responseString];
    if ([self responseStatusCode] != 200) {
        NSLog(@"response:%@", response);
    }
	SBJSON* sbjson = [[[SBJSON alloc] init] autorelease];
    if (response.length == 0) {
        return nil;
    }
	return [sbjson objectWithString:response];
}

- (NSInteger)responseError {
    if ([self responseStatusCode] == 200) 
        return 0;
    return [MMUapRequest responseError:[self responseObject]];
}

@end


