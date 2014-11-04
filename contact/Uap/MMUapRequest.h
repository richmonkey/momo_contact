/*
 *  MMUapRequest.h
 *  libSync
 *
 *  Created by aminby on 2010-6-24.
 *  Copyright 2010 __MyCompanyName__. All rights reserved.
 *
 */

#ifndef _MMUAPREQUEST_H_
#define _MMUAPREQUEST_H_

#import "ASIHTTPRequest.h"
#include "MMUapRequest.h"
#import "MMThread.h"
#import "MMGlobalDefine.h"

#define STATUS @"status"

typedef enum {
    MMUapRequestResultOK = 0,
    MMUapRequestResultNetworkFailed,
    
    MMUapRequestResultLoginEmptyCellNumber,     // 401 手机号码为空 
    MMUapRequestResultLoginInvalidNumber,       // 402 手机号码格式不对 
    MMUapRequestResultLoginInvalidPassword,     // 403 密码错误
    MMUapRequestResultLoginEmptyPassword,       // 404 密码为空 	
	
	MMUapRequestResultRegisterEmptyCellNumber,	//	401 手机号码为空 
    MMUapRequestResultRegisterInvalidNumber,	//	402 手机号码格式不对 
	MMUapRequestResultRegisterInvalidName,		//	403 姓名不是中文或者长度不合法 
	MMUapRequestResultRegisterEmptyPassword,	//	405 密码为空 
	MMUapRequestResultRegisterHasBeenRegisted,	//	406 该手机号码已注册过 
	MMUapRequestResultRegisterTooManyRetrys,	//	407 一天的验证码发送不能超过3次 
	MMUapRequestResultRegisterSystemError,		//	408 系统异常，请稍候再试 
	MMUapRequestResultRegisterSMSSendFailed,	//	409 短信发送失败 
	
	MMUapRequestResultActiveEmptyCode,			//	401 验证码为空 
	MMUapRequestResultActiveEmptyCellNumber,	//	402 手机号码为空 
	MMUapRequestResultActiveInvalidNumber,		//	403 手机号码格式不对 
	MMUapRequestResultActiveHasBeenRegisted,	//	404 该手机号码已注册过 
	MMUapRequestResultActiveUnRegisted,			//	405 该手机号码未注册，不能激活 
	MMUapRequestResultActiveHasBeenActived,		//	406 该手机号码已验证过 
	MMUapRequestResultActiveErrorCode,			//	407 验证码不正确 
	MMUapRequestResultActiveOutdateCode,		//	408 该验证码已过期 
	MMUapRequestResultActiveInvalidCode,		//	409 未查到该手机号对应的验证码 
	MMUapRequestResultActiveFail,				//	410 MOMO帐号激活失败 
	
    
    MMUapRequestResultValidateInvalidFormat,
    MMUapRequestResultValidateFailedMoreThan3Times,
    MMUapRequestResultValidateSendFailed,
    
    MMUapRequestResultValidateCheckInvalidCodeFormat,
    MMUapRequestResultValidateCheckInvalidCode,
    MMUapRequestResultValidateCheckOutOfDate,
    MMUapRequestResultValidateCheckNotFound,
	
	//上传头像
	MMUapRequestResultUploadImageErrorSid,		//401 非法sid
	MMUapRequestResultUploadImageErrorPara,		//405 参数错误
	MMUapRequestResultUploadImageFail,			//500 失败
	
} MMUapRequestResult;

@interface MMUapRequest : NSObject
{
}


+ (MMUapRequest*)shareInstance;

/************************** 公用函数 ************************/
/*
 * 字符串的MD5
 * 
 * @param str: 原文
 *
 * @return : 原文的MD5
 */
+(NSString*) md5:(NSString*)str;

/*
 * 文件的MD5
 * 
 * @param path: 文件路径
 *
 * @return : 文件的MD5
 */
+(NSString *)file_md5:(NSString*) path;

+ (NSString*)data_md5:(NSData*)data;

/*
 * 文件的大小(字节)
 * 
 * @param str: 文件路径
 *
 * @return : 文件的大小(字节数)
 */
+(NSNumber*) file_size:(NSString*) path;

/*
 * 文件的文件名
 * 
 * @param str: 文件路径
 *
 * @return : 文件的文件名
 */
+(NSString*) file_name:(NSString*) path;


/**************************************** 可以提为公用函数 ****************************************/
/*
 * 同步发起HTTP POST请求
 * 
 * @param source: 请求资源
 * @param object: 请求参数
 * @param sid: Session ID
 *
 * @return: JSON转化成的结构
 */
+(NSDictionary*)postSync:(NSString*)source withObject:(NSObject*)object;
+(NSInteger)postSync:(NSString *)source withObject:(NSObject *)object responseData:(NSData**)response;
+(NSInteger)postSync:(NSString *)source withObject:(NSObject *)object responseString:(NSString**)response;
+(NSInteger)postSync:(NSString *)source withObject:(NSObject *)object jsonValue:(id*)value;
+(NSInteger)responseError:(NSDictionary*)response;

+ (ASIHTTPRequest*)postAsync:(NSString*)source withObject:(NSDictionary*)object withDelegate:(id)delegate;
+ (ASIHTTPRequest*)uploadPhotoStep1Async:(NSData*)imgData withDelegate:(id)delegate;
+ (ASIHTTPRequest*)uploadPhotoStep2Async:(NSData*)imgData uploadId:(NSString*)uploadId withDelegate:(id)delegate;
+ (NSString*)uploadPhoto:(NSData*)imgData;
+ (BOOL)uploadFile:(NSString*)filePath fileUrl:(NSString**)url fileMimeType:(NSString**)type;
/*
 * 同步发起HTTP GET请求
 * 
 * @param source: 请求资源
 * @param sid: Session ID
 *
 * @return: JSON转化成的结构
 */
+(NSDictionary*)getSync:(NSString*)source compress:(BOOL)isCompress;
+(NSInteger)getSync:(NSString*)source jsonValue:(id*)value compress:(BOOL)isCompress;
+(NSInteger)getSync:(NSString*)source responseData:(NSData**)response compress:(BOOL)isCompress;
+(NSInteger)getSync:(NSString*)source responseString:(NSString**)response compress:(BOOL)isCompress;

@end

@interface ASIHTTPRequest(MMHttpRequest)

+ (id)requestWithPath:(NSString*)path;
+ (id)requestWithPath:(NSString *)path usingSSL:(BOOL)usingSSL;
+ (id)requestWithPath:(NSString*)path withObject:(NSObject*)object;
+ (id)requestWithPath:(NSString*)path withObject:(NSObject*)object usingSSL:(BOOL)usingSSL;
- (id)responseObject;
- (NSInteger)responseError;
+ (void)startSynchronous:(ASIHTTPRequest*)request;

@end

//http sync request
@interface MMHttpRequestThread : MMThread {
	ASIHTTPRequest *request_;
}
@property(retain) ASIHTTPRequest *request;

@end

#endif