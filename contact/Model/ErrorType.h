/*
 *  ErrorType.h
 *  Db
 *
 *  Created by aminby on 2010-7-23.
 *  Copyright 2010 __MyCompanyName__. All rights reserved.
 *
 */

#ifndef _ERROR_TYPE_
#define _ERROR_TYPE_

typedef enum {
    MM_DB_OK = 0
    , MM_DB_NULL
    , MM_DB_KEY_EXISTED
    , MM_DB_KEY_NOT_EXISTED
    , MM_DB_FAILED_OPEN
    , MM_DB_FAILED_QUERY
    , MM_DB_FAILED_INVALID_STATEMENT
    , MM_DB_WRITE_ABADDRESSBOOK_FAILED
}_errorType;

typedef int MMErrorType;
//#define MMErrorType NSInteger 

#endif