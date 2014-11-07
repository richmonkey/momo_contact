//
//  MMCommonAPI.m
//  momo
//
//  Created by mfm on 7/24/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "MMCommonAPI.h"
#import "MMGlobalPara.h"
#import "MMGlobalData.h"
#import "MMUapRequest.h"
#import "MMPhoneticAbbr.h"
#import "MMContact.h"
#import "RegexKitLite.h"

@implementation MMCommonAPI

+ (NSString *)getClientName:(NSInteger)clientId {
	switch (clientId) {
		case 0:
		//default:
			return @"来自momo.im网站";
		case 1:
			return @"来自Android版";
		case 2:
			return @"来自iPhone版";
		case 3:
			return @"来自Windows Mobile版";
		case 4:
			return @"来自S60v3版";
		case 5:
			return @"来自S60v5版";
		case 6:
			return @"来自Java版";
		case 7:
			return @"来自webOS版";
		case 8:
			return @"来自BlackBerry版";
		case 9:
			return @"来自iPad版";
		case 10:
			return @"来自网站手机版";
		case 11:
			return @"来自手机触屏版";
		case 12:
			return @"来自手机短信";
		default:
			return @"来自momo.im网站";
	}
	
}

+ (void)dial:(NSString *)numberStr {
	NSString *number = [NSString stringWithFormat:@"tel://%@", numberStr];
	//拨号
	BOOL bSuccess = [[UIApplication sharedApplication] openURL:[NSURL URLWithString:number ]];
	if (!bSuccess)
	{
		[MMCommonAPI showFailAlertViewTitle:@"拨号失败" 
								 andMessage:[NSString stringWithFormat:@"拨号失败，请检查网络！号码:%@", number]];
	}
}

+ (void)sendMessage:(NSString *)numberStr {
	
	NSString *number = [NSString stringWithFormat:@"sms://%@", numberStr];
	//发信息
	BOOL bSuccess = [[UIApplication sharedApplication] openURL:[NSURL URLWithString:number ]];
	if (!bSuccess)
	{
		[MMCommonAPI showFailAlertViewTitle:@"发送短信失败" 
								 andMessage:[NSString stringWithFormat:@"发送短信失败，请检查网络！号码:%@", numberStr]];
	}
}

+ (void)sendEmail:(NSString *)numberStr {
	
	NSString *number = [NSString stringWithFormat:@"mailto://%@", numberStr];
	//发信息
	BOOL bSuccess = [[UIApplication sharedApplication] openURL:[NSURL URLWithString:number ]];
	if (!bSuccess)
	{
		[MMCommonAPI showFailAlertViewTitle:@"发送邮件失败" 
							     andMessage:[NSString stringWithFormat:@"发送邮件失败，请检查网络！邮箱:%@", numberStr]];
	}
}

+ (void)showFailAlertViewTitle:(NSString*) title andMessage:(NSString*)message {
	
	UIAlertView *failView = [[UIAlertView alloc] initWithTitle:title
													   message:message
													  delegate:self
											 cancelButtonTitle:@"OK"
											 otherButtonTitles:nil];
	[failView show];
	[failView release];
}



+ (NSString *)getErrorInfoByErrorCode:(NSInteger)errorcode {
	switch (errorcode) {
		case MM_ERRCODE_SUCCESS: {
			return @"成功";
			break;
		}
		case MM_ERRCODE_CALLFAIL: {
			return @"拨号失败";
			break;
		}	
		case MM_ERRCODE_SYNCING: {
			return @"正在同步，无法操作";
			break;
		}			
		default: {
			return @"未知错误";
			break;
		}
			
	}
	
}

+ (NSDate*) getDateBySting:(NSString*)stringDate {		
	
	if ((nil == stringDate) 
		|| (0 == stringDate.length)){
		return nil;
	}
	
	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
	dateFormatter.dateStyle = NSDateFormatterMediumStyle;
	[dateFormatter setLocale:[NSLocale currentLocale]];	
	[dateFormatter setDateFormat:@"yyyy-MM-dd"];
	
	NSDate *date = [dateFormatter dateFromString:stringDate];
	[dateFormatter release];
	return date;
}

+ (NSString*) getStingByDate:(NSDate*)date {	
	if (nil == date) {
		return nil;
	}
	
	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
	dateFormatter.dateStyle = NSDateFormatterMediumStyle;
	[dateFormatter setLocale:[NSLocale currentLocale]];	 
	[dateFormatter setDateFormat:@"yyyy-MM-dd"];	
	
	NSString *stringDate = [dateFormatter stringFromDate:date];
	[dateFormatter release];
	return stringDate;
}

+ (NSString*)getDateString:(NSDate*)date {
	if (nil == date) {
		return nil;
	}
	
	NSString* retString = nil;
	unsigned unitFlags = NSYearCalendarUnit | NSMonthCalendarUnit |  NSDayCalendarUnit | NSHourCalendarUnit | NSMinuteCalendarUnit;
	
	
	NSDateComponents *dateComponents = [[NSCalendar currentCalendar] components:unitFlags fromDate:date];
	NSDateComponents *todayComponents = [[NSCalendar currentCalendar] components:unitFlags fromDate:[NSDate date]];
	
	if ([dateComponents day] == [todayComponents day] &&
		[dateComponents month] == [todayComponents month] &&
		[dateComponents year] == [todayComponents year]) {
		retString = [NSString stringWithFormat:@"%02d:%02d", [dateComponents hour], [dateComponents minute]];
	} else {
		if ([dateComponents year] != [todayComponents year]) {
			retString = [NSString stringWithFormat:@"%d年%d月%d日", [dateComponents year], [dateComponents month], [dateComponents day]];
		} else {
			retString = [NSString stringWithFormat:@"%d月%d日 %02d:%02d", [dateComponents month], [dateComponents day], [dateComponents hour], [dateComponents minute]];
		}
	}
	
	return retString;
}

+ (UIImage*)imageWithImage:(UIImage*)image scaledToSize:(CGSize)newSize
{
    UIGraphicsBeginImageContext(newSize);
    [image drawInRect:CGRectMake(0,0,newSize.width,newSize.height)];
    UIImage* newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return newImage;
}

+ (UIImage*)scaleAndRotateImage:(UIImage *)image scaleSize:(NSInteger)scaleSize{
	int kMaxResolution = scaleSize; // Or whatever
	
    CGImageRef imgRef = image.CGImage;
	
    CGFloat width = CGImageGetWidth(imgRef);
    CGFloat height = CGImageGetHeight(imgRef);
	
    CGAffineTransform transform = CGAffineTransformIdentity;
    CGRect bounds = CGRectMake(0, 0, width, height);
    if (width > kMaxResolution || height > kMaxResolution) {
        CGFloat ratio = width/height;
        if (ratio > 1) {
            bounds.size.width = kMaxResolution;
            bounds.size.height = roundf(bounds.size.width / ratio);
        }
        else {
            bounds.size.height = kMaxResolution;
            bounds.size.width = roundf(bounds.size.height * ratio);
        }
    }
	
    CGFloat scaleRatio = bounds.size.width / width;
    CGSize imageSize = CGSizeMake(CGImageGetWidth(imgRef), CGImageGetHeight(imgRef));
    CGFloat boundHeight;
    UIImageOrientation orient = image.imageOrientation;
    switch(orient) {
			
        case UIImageOrientationUp: //EXIF = 1
            transform = CGAffineTransformIdentity;
            break;
			
        case UIImageOrientationUpMirrored: //EXIF = 2
            transform = CGAffineTransformMakeTranslation(imageSize.width, 0.0);
            transform = CGAffineTransformScale(transform, -1.0, 1.0);
            break;
			
        case UIImageOrientationDown: //EXIF = 3
            transform = CGAffineTransformMakeTranslation(imageSize.width, imageSize.height);
            transform = CGAffineTransformRotate(transform, M_PI);
            break;
			
        case UIImageOrientationDownMirrored: //EXIF = 4
            transform = CGAffineTransformMakeTranslation(0.0, imageSize.height);
            transform = CGAffineTransformScale(transform, 1.0, -1.0);
            break;
			
        case UIImageOrientationLeftMirrored: //EXIF = 5
            boundHeight = bounds.size.height;
            bounds.size.height = bounds.size.width;
            bounds.size.width = boundHeight;
            transform = CGAffineTransformMakeTranslation(imageSize.height, imageSize.width);
            transform = CGAffineTransformScale(transform, -1.0, 1.0);
            transform = CGAffineTransformRotate(transform, 3.0 * M_PI / 2.0);
            break;
			
        case UIImageOrientationLeft: //EXIF = 6
            boundHeight = bounds.size.height;
            bounds.size.height = bounds.size.width;
            bounds.size.width = boundHeight;
            transform = CGAffineTransformMakeTranslation(0.0, imageSize.width);
            transform = CGAffineTransformRotate(transform, 3.0 * M_PI / 2.0);
            break;
			
        case UIImageOrientationRightMirrored: //EXIF = 7
            boundHeight = bounds.size.height;
            bounds.size.height = bounds.size.width;
            bounds.size.width = boundHeight;
            transform = CGAffineTransformMakeScale(-1.0, 1.0);
            transform = CGAffineTransformRotate(transform, M_PI / 2.0);
            break;
			
        case UIImageOrientationRight: //EXIF = 8
            boundHeight = bounds.size.height;
            bounds.size.height = bounds.size.width;
            bounds.size.width = boundHeight;
            transform = CGAffineTransformMakeTranslation(imageSize.height, 0.0);
            transform = CGAffineTransformRotate(transform, M_PI / 2.0);
            break;
			
        default:
            [NSException raise:NSInternalInconsistencyException format:@"Invalid image orientation"];
			
    }
	
    UIGraphicsBeginImageContext(bounds.size);
	
    CGContextRef context = UIGraphicsGetCurrentContext();
	
    if (orient == UIImageOrientationRight || orient == UIImageOrientationLeft) {
        CGContextScaleCTM(context, -scaleRatio, scaleRatio);
        CGContextTranslateCTM(context, -height, 0);
    }
    else {
        CGContextScaleCTM(context, scaleRatio, -scaleRatio);
        CGContextTranslateCTM(context, 0, -height);
    }
	
    CGContextConcatCTM(context, transform);
	
    CGContextDrawImage(UIGraphicsGetCurrentContext(), CGRectMake(0, 0, width, height), imgRef);
    UIImage *imageCopy = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
	
    return imageCopy;
}

+ (UIImage*)rotateImage:(UIImage*)image {
    NSInteger scaleSize = MAX(image.size.width, image.size.height);
    return [self scaleAndRotateImage:image scaleSize:scaleSize];
}

+ (BOOL)isNetworkReachable {
	Reachability * curReach = [Reachability reachabilityForInternetConnection];
	return [curReach currentReachabilityStatus] != NotReachable;
}

+ (NetworkStatus)getNetworkStatus {
	Reachability * curReach = [Reachability reachabilityForInternetConnection];
	return [curReach currentReachabilityStatus];
}

+ (NSString*)createGUIDStr
{
    CFUUIDRef theUUID = CFUUIDCreate(NULL);
	CFStringRef stringGUID = CFUUIDCreateString(NULL,theUUID);
	CFRelease(theUUID);
	return [(NSString *) stringGUID autorelease];
}

+ (NSString*)temporaryURLHost {
    return  @"http://temporary.momo.im/";
}

+ (NSString*)originalImageURL:(NSString*)smallImageURL {
    NSString* originImageUrl = [smallImageURL stringByReplacingOccurrencesOfString:@"_130." withString:@"_780."];
    return originImageUrl;
}

+ (NSString *) getStringByDate:(NSDate*)date byFormatter:(NSString *)stringFormatter {	
	if (nil == date) {
		return nil;
	}
	
	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
	dateFormatter.dateStyle = NSDateFormatterMediumStyle;
	[dateFormatter setLocale:[NSLocale currentLocale]];	 
	[dateFormatter setDateFormat:stringFormatter];
	
	NSString *stringDate = [dateFormatter stringFromDate:date];
	[dateFormatter release];
	return stringDate;
}

+ (void)alert:(NSString *)message {
    UIAlertView *alert = [[UIAlertView alloc] init];
    [alert setTitle:nil];
    [alert setMessage:message];
    [alert addButtonWithTitle:@"确定"];
    [alert show];
    [alert release];
}

//判断该字符串的首字母是否 不为特殊字符
+ (BOOL) isNoSpecialChar:(NSString *)str {
	if ([str characterAtIndex:0] >= 'A' && [str characterAtIndex:0] <= 'Z') {
		return YES;
	} else {
		return NO;
	}
}

+ (NSString*)getStringFirstLetter:(NSString *)str {
    NSString *firstLetter = @"#";
	
	if (nil != str && [str length] > 0) {
		firstLetter = [[str substringToIndex:1] uppercaseString];
		firstLetter = [self isNoSpecialChar:firstLetter] ? firstLetter : @"#"; 
	}
	
	return firstLetter;
}

+ (void)checkDirectoryExist {
	NSString *documentsDirectory = [MMGlobalPara documentDirectory];
	if (![[NSFileManager defaultManager] fileExistsAtPath:documentsDirectory]) {
		[[NSFileManager defaultManager] createDirectoryAtPath:documentsDirectory withIntermediateDirectories:YES attributes:nil error:nil];
	}
	
	NSString* attachImageDir = [documentsDirectory stringByAppendingString:@"crash"];
	if (![[NSFileManager defaultManager] fileExistsAtPath:attachImageDir]) {
		[[NSFileManager defaultManager] createDirectoryAtPath:attachImageDir withIntermediateDirectories:YES attributes:nil error:nil];
	}
	
	NSString* draftImageDir = [documentsDirectory stringByAppendingString:@"draft_images"];
	if (![[NSFileManager defaultManager] fileExistsAtPath:draftImageDir]) {
		[[NSFileManager defaultManager] createDirectoryAtPath:draftImageDir withIntermediateDirectories:YES attributes:nil error:nil];
	}
    
    NSString* tmpDownloadFilePath = [NSHomeDirectory() stringByAppendingString:@"/tmp/tmp_download"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:tmpDownloadFilePath]) {
		[[NSFileManager defaultManager] createDirectoryAtPath:tmpDownloadFilePath withIntermediateDirectories:YES attributes:nil error:nil];
	}
}

+ (CGRect)properRectForButton:(UIButton*)button maxSize:(CGSize)maxSize {
	CGRect frame = button.frame;
	CGSize size = [button sizeThatFits:button.frame.size];
	if (size.width + 20 > maxSize.width) {
		size.width = maxSize.width;
	} else {
		size.width += 20;
	}
	
	frame.size = size;
	return frame;
}

+ (NSInteger)countWord:(NSString*)text {
	int i, n = [text length], l = 0, a = 0, b = 0;
    unichar c;
    for(i=0;i<n;i++){
        c = [text characterAtIndex:i];
        if(isblank(c)){
            b++;
        }else if(isascii(c)){
            a++;
        }else{
            l++;
        }
    }
	
    if(a==0 && l==0) 
		return 0;
	
    return l+(int)ceilf((float)(a+b)/2.0);
}

+ (NSArray*)sortArrayByAbbr:(NSArray*)objectArray key:(NSString*)key {
	return [objectArray sortedArrayUsingComparator:(NSComparator)^(id obj1, id obj2){
		NSString* value1 = [obj1 valueForKey:key];
		NSString* value2 = [obj2 valueForKey:key];
		
		if (!value1 || value1.length == 0) {
			return NSOrderedAscending;
		} else if (!value2 || value2.length == 0) {
			return NSOrderedDescending;
		}
		
		//第一个字符是英文字母的, 直接比较
		unichar char1 = [value1 characterAtIndex:0];
		unichar char2 = [value2 characterAtIndex:0];
		if (char1 <= 'z' || char2 <= 'z') {
			return (NSInteger)[value1 caseInsensitiveCompare:value2];
		}
		
		//中文字符用拼音比较
		NSString* abbr1 = [MMPhoneticAbbr getPinyinAbbr:value1];
		NSString* abbr2 = [MMPhoneticAbbr getPinyinAbbr:value2];
		return (NSInteger)[abbr1 caseInsensitiveCompare:abbr2];
	}];
}

+ (NSString*)getDetailURL:(NSUInteger)typeId applicationId:(uint64_t)appId {
    return @"";

}

+ (NSString*)getIMLongTextURL:(NSString*)msdId {
    return @"";
}

+ (NSString*)getLongTextURL:(NSString*)statusId {
    return @"";
}


+ (MMMomoUserInfo*)loginUserInfo {
    return nil;
}


+(NSString *)changeToValidNumber:(NSString*)mobile {

	if (!mobile || !mobile.length) {
		return nil;
	}
	
	NSString *validMobile = nil;
	NSString *regex = nil;
	
	do {
		
		if (!mobile || mobile.length < numberLeastLength) {
			validMobile = nil;
			break;
		}
		
		regex = @"^\\+[1-79][0-57-9]\\d{5,12}";
		if ([mobile isMatchedByRegex:regex]) {
			validMobile = nil;
			break;
		}
		
		regex = @"^[^\\+]|^\\+86\\d+";
		if ([mobile isMatchedByRegex:regex]) {
			NSString *str = [mobile stringByReplacingOccurrencesOfRegex:@"^\\+86|^0086|^086|^\\(86\\)|^86" withString:@""];
			
			//NSLog(@"去掉前面的86  str:%@",str);
			NSString *newMobile = [str stringByReplacingOccurrencesOfRegex:@"12593|^17951|^17911|^17910|^17909|^10131|^10193|^96531|^193|^12520|^11808|^17950" 
																withString:@""];
			//NSLog(@"去掉IP拨号  newMobile:%@",newMobile);
			
			if (newMobile.length == 11) {
				validMobile = newMobile;
			} else {
				validMobile = nil;
			}
			
			break;
		}
		
	} while (0);
	
	return validMobile;
}

+(BOOL)isValidTelNumber:(NSString*)mobile {
	
//	验证规则
//	1.对于非+开头或以+86开头的手机号码(“^[^\+]|^\+86\d+”)，执行如下验证
//	
//	①去掉前面的86
//	^\+86|^0086|^086|^\(86\)|^86
//	
//	②去掉IP拨号
//	^12593|^17951|^17911|^17910|^17909|^10131|^10193|^96531|^193|^12520|^11808|^17950
//	
//	③手机号码符合11位，提交服务端验证。
//
//	2.对于以+开头之后非86的手机号码，位数在7-14的手机号码提交服务端验证。
//	^\+[1-79][0-57-9]\d{5,12}
	
	//NSLog(@"mobile:%@",mobile);
	BOOL isValid = YES;
	NSString *regex = nil;
	
	do {

		if (!mobile || mobile.length < numberLeastLength) {
			isValid = NO;
			break;
		}
		
		regex = @"^\\+[1-79][0-57-9]\\d{5,12}";
		if ([mobile isMatchedByRegex:regex]) {
			isValid = YES;
			break;
		}
		
		regex = @"^[^\\+]|^\\+86\\d+";
		if ([mobile isMatchedByRegex:regex]) {
			NSString *str = [mobile stringByReplacingOccurrencesOfRegex:@"^\\+86|^0086|^086|^\\(86\\)|^86" withString:@""];
			
			//NSLog(@"去掉前面的86  str:%@",str);
			NSString *newMobile = [str stringByReplacingOccurrencesOfRegex:@"12593|^17951|^17911|^17910|^17909|^10131|^10193|^96531|^193|^12520|^11808|^17950" 
																withString:@""];
			//NSLog(@"去掉IP拨号  newMobile:%@",newMobile);
			
			if (newMobile.length == 11) {
				isValid = YES;
			} else {
				isValid = NO;
			}
			
			break;
		}
		
	} while (0);
	
	//NSLog(@"isValid: %d",isValid);
	return isValid;
}

+ (BOOL)isValidUserName:(NSString*)userName {
    if ([userName length] == 0) {
        return NO;
    }
    
    userName = [userName stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
    for (int i = 0; i < userName.length; i++) {
        unichar word = [userName characterAtIndex:i];
        
        //是否英文
        if ((word >= 65 && word <= 90) || (word >= 97 && word <= 122)) {
            continue;
        }
        
        //是否中文
        if (word >= 0x4e00 && word <= 0x9fa5) {		//一:0x4e00 龥:9fa5
            continue;
        }
        
        return NO;
    }
    
    return YES;
}
#ifndef MOMO_UNITTEST
+ (void)showAlertHud:(NSString*)text detailText:(NSString*)detailText {

}
#endif

+ (BOOL)isJailBreakDevice {
    if (system("ls") == 0) {
        return YES;
    }
    
    return [[NSFileManager defaultManager] fileExistsAtPath:@"/private/var/lib/apt/"];
}

+ (float)getAppFloatVersion {
    NSString* version = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
    NSArray* splitArray = [version componentsSeparatedByString:@"."];
    if (!splitArray.count == 3) {
        return 1.0f;
    }
    
    return [[NSString stringWithFormat:@"%@.%@%@", [splitArray objectAtIndex:0], [splitArray objectAtIndex:1],
            [splitArray objectAtIndex:2]] floatValue];
}

+ (void)waitHTTPThreadsQuit:(NSMutableArray*)backgroundThreads {
    //background threads
	for (MMHttpRequestThread* thread in backgroundThreads) {
		[thread cancel];
		[thread wait];
	}
	[backgroundThreads removeAllObjects];
}


+ (NSString*)avatarUrlBySmallAvatarUrl:(NSString*)smallAvatarUrl desireSize:(NSInteger)desireSize {
    NSString* desireSizeStr = [NSString stringWithFormat:@"_%d.", desireSize];
    return [smallAvatarUrl stringByReplacingOccurrencesOfString:@"_48." withString:desireSizeStr];
}
+ (NSString*)addHTMLLinkTag:(NSString*)srcString {
    if (srcString.length == 0) {
        return nil;
    }
    return [srcString stringByReplacingOccurrencesOfRegex:@"(http://[\\x21-\\x7e]*)" 
                                               withString:@"<a href=\"$1\">$1</a>" 
                                                  options:RKLCaseless 
                                                    range:NSMakeRange(0, srcString.length) 
                                                    error:nil];
}

+ (NSString*)deviceId {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString* appDeviceId = [defaults objectForKey:@"device_id"];
    if (appDeviceId == nil) {
        appDeviceId = [MMCommonAPI createGUIDStr];
        [defaults setObject:appDeviceId forKey:@"device_id"];
        [defaults synchronize];
    }
    return appDeviceId;
}

#pragma mark K码计算
+ (NSString*)numberToKCode:(double)degree {
    const char* coder = "0123456789abcdefghijkmnpqrstuvwxyz";
    
    float second = degree * 60 * 60;
    int minSecond = (int)(second * 10 + 0.5);
    
    char buffer[5];
    memset(buffer, '0', 4);
    buffer[4] = 0;
    
    int count = 0;
    
    while (minSecond > 0) {
        int number = minSecond % 34;
        
        buffer[count] = coder[number];
        
        minSecond = minSecond / 34;
        count++;
    }
    return [NSString stringWithUTF8String:buffer];
}

+ (NSString*)computeKCode:(double)longitude latitude:(double)latitude {
    if (longitude < 70 || longitude > 140 || latitude < 5 || latitude > 75) {
        return @"";
    }
    
    NSMutableString* kCode = [NSMutableString string];
    if (longitude >= 105) {
        if (latitude >= 40) {
            [kCode appendString:@"5"];
        } else {
            [kCode appendString:@"8"];
        }
    } else{
        if (latitude >= 40) {
            [kCode appendString:@"6"];
        } else {
            [kCode appendString:@"7"];
        }
    }
    
    double longitudeDelta = longitude - 70;
    if (longitudeDelta > 35) {
        longitudeDelta = longitudeDelta - 35;
    }
    
    double latitudeDelta = latitude - 5;
    if (latitudeDelta > 35) {
        latitudeDelta = latitudeDelta - 35;
    }
    
    [kCode appendString:[self numberToKCode:longitudeDelta]];
    [kCode appendString:[self numberToKCode:latitudeDelta]];
    return kCode;
}


+ (NSArray*)sortIntArray:(NSArray *)array {
    return  [array sortedArrayUsingComparator:^(id obj1, id obj2) {
        if ([obj1 longLongValue] < [obj2 longLongValue]) {
            return NSOrderedAscending;
        } else if ([obj1 longLongValue] == [obj2 longLongValue]) {
            return NSOrderedSame;
        } else {
            return NSOrderedDescending;
        }
    }];
}

@end
