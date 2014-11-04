/*
 * Copyright (c) 2008 Plausible Labs Cooperative, Inc.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. Neither the name of the copyright holder nor the names of any contributors
 *    may be used to endorse or promote products derived from this
 *    software without specific prior written permission.
 * 
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */

#import "PlausibleDatabase.h"

#pragma mark Parameter Strategy

/**
 * @internal
 * Parameter fetching strategy.
 */
@protocol PLSqliteParameterStrategy <NSObject>

/**
 * Return the number of available parameters
 */
- (int) count;

/**
 * Return the value for the given parameter. May
 * return nil if the parameter is unavailable,
 * and NSNull if the parameter's value is null.
 */
- (id) valueForParameter: (int) parameterIndex withStatement: (sqlite3_stmt *) stmt;

@end

/**
 * @internal
 * NSArray parameter strategy.
 */
@interface PLSqliteArrayParameterStrategy : NSObject <PLSqliteParameterStrategy> {
@private
    NSArray *_values;
}
@end

@implementation PLSqliteArrayParameterStrategy

- (id) initWithValues: (NSArray *) values {
    if ((self = [super init]) == nil)
        return nil;

    _values = [values retain];

    return self;
}

- (void) dealloc {
    [_values release];
    [super dealloc];
}

- (int) count {
    return [_values count];
}

- (id) valueForParameter: (int) parameterIndex withStatement: (sqlite3_stmt *) stmt {
    /* Arrays are zero-index, sqlite is 1-indexed, so adjust the index
     * for the array */
    return [_values objectAtIndex: parameterIndex - 1];
}

@end


/**
 * @internal
 * NSDictionary parameter strategy.
 */
@interface PLSqliteDictionaryParameterStrategy : NSObject <PLSqliteParameterStrategy> {
@private
    NSDictionary *_values;
}
@end

@implementation PLSqliteDictionaryParameterStrategy

- (id) initWithValueDictionary: (NSDictionary *) values {
    if ((self = [super init]) == nil)
        return nil;

    _values = [values retain];

    return self;
}

- (void) dealloc {
    [_values release];
    [super dealloc];
}

- (int) count {
    return [_values count];
}

- (id) valueForParameter: (int) parameterIndex withStatement: (sqlite3_stmt *) stmt {
    const char *sqlite_name;

    /* Fetch the parameter name. */
    sqlite_name = sqlite3_bind_parameter_name(stmt, parameterIndex);
    
    /* If there is no name, or if it's blank, we can't retrieve the value. */
    if (sqlite_name == NULL || *sqlite_name == '\0')
        return NULL;

    /* Fetch the value, stripping the initial ':' characeter. */
    assert(*sqlite_name != '\0'); // checked above.
    return [_values objectForKey: [NSString stringWithUTF8String: sqlite_name + 1]];
}

@end


#pragma mark Private Declarations

@interface PLSqlitePreparedStatement (PLSqlitePreparedStatementPrivate)

- (int) bindValueForParameter: (int) parameterIndex withValue: (id) value;

- (void) assertNotClosed;
- (void) assertNotInUse;

- (PLSqliteResultSet *) checkoutResultSet;

@end

#pragma mark Public Implementation

/**
 * @internal
 * SQLite prepared query implementation.
 *
 * @par Thread Safety
 * PLSqlitePreparedStatement instances implement no locking and must not be shared between threads
 * without external synchronization.
 */
@implementation PLSqlitePreparedStatement

/**
 * @internal
 *
 * Initialize the prepared statement with an open database and an sqlite3 prepared statement.
 *
 * @param db A reference to the managing PLSqliteDatabase instance.
 * @param sqliteStmt The prepared sqlite statement. This class will assume ownership of the reference.
 * @param queryString The original SQL query string, used for error reporting.
 * @param closeAtCheckin A flag specifying whether the statement should be closed at first checkin. Used to support returning
 * only the result set to a caller. When the result set is closed, the prepared statement is closed.
 *
 * MEMORY OWNERSHIP WARNING:
 * We are passed an sqlite3_stmt reference which now we now assume authority for releasing
 * that statement using sqlite3_finalize().
 *
 * @par Designated Initializer
 * This method is the designated initializer for the PLSqlitePreparedStatement class.
 */
- (id) initWithDatabase: (PLSqliteDatabase *) db 
             sqliteStmt: (sqlite3_stmt *) sqlite_stmt
            queryString: (NSString *) queryString 
         closeAtCheckin: (BOOL) closeAtCheckin 
{
    if ((self = [super init]) == nil)
        return nil;

    /* Mark whether we should close when the first result set is checked in */
    _closeAtCheckin = closeAtCheckin;

    /* Save our database and statement reference. */
    _database = [db retain];
    _sqlite_stmt = sqlite_stmt;
    _queryString = [queryString retain];
    _inUse = NO;

    /* Cache parameter count */
    _parameterCount = sqlite3_bind_parameter_count(_sqlite_stmt);
    assert(_parameterCount >= 0); // sanity check

    return self;
}


/* GC */
- (void) finalize {
    // XXX: May cause a memory leak when garbage collecting due
    // to Apple's finalization rules. No ordering is maintained,
    // and such, there's no way to ensure that the sqlite3_stmt
    // is released before sqlite3_close() is called.
    [self close];
    [super finalize];
}

/* Manual */
- (void) dealloc {
    /* The statement must be released before the database is released, as the statement has a reference
     * to the database which would cause a SQLITE_BUSY error when the database is released. */
    [self close];
    
    /* Now release the database. */
    [_database release];
    
    /* Release the query statement */
    [_queryString release];

#ifdef PL_SQLITE_LEGACY_STMT_PREPARE
    [_boundParameterStrategy release];
#endif /* PL_SQLITE_LEGACY_STMT_PREPARE */
    
    [super dealloc];
}


/* from PLPreparedStatement */
- (void) close {
    if (_sqlite_stmt == NULL)
        return;
    
    /* The finalization may return the last error returned by sqlite3_next(), but this has already
     * been handled by the -[PLSqliteResultSet next] implementation. Any remaining memory and
     * resources are released regardless of the error code, so we do not check it here. */
    sqlite3_finalize(_sqlite_stmt);
    _sqlite_stmt = NULL;
}

/**
 * @internal
 *
 * Populate an NSError (if not nil) and log it, using this prepared statement's query string
 * and database connection. The vendor error code and message will be populated.
 *
 * Should only be called by PLSqliteResultSet.
 *
 * @param error Pointer to NSError instance to populate. If nil, the error message will be logged instead.
 * @param errorCode A PLDatabaseError error code.
 * @param description A localized description of the error message.
 */
- (void) populateError: (NSError **) error withErrorCode: (PLDatabaseError) errorCode description: (NSString *) localizedDescription {
    [_database populateError: error withErrorCode: errorCode description: localizedDescription queryString: _queryString];
}

/* from PLPreparedStatement */
- (int) parameterCount {
    [self assertNotClosed];

    return _parameterCount;
}


/**
 * @internal
 * Bind all parameters, fetching their value using the provided selector.
 */
- (void) bindParametersWithStrategy: (id<PLSqliteParameterStrategy>) strategy {
    [self assertNotInUse];
    
#ifdef PL_SQLITE_LEGACY_STMT_PREPARE
    if (_boundParameterStrategy != strategy) {
        /* Save the new strategy, in case the statement must be reparsed */
        if (_boundParameterStrategy != nil)
            [_boundParameterStrategy release];

        _boundParameterStrategy = [strategy retain];
    }
#endif /* PL_SQLITE_LEGACY_STMT_PREPARE */

    /* Verify that a complete parameter list was provided */
    if ([strategy count] < _parameterCount)
        [NSException raise: PLSqliteException 
                    format: @"%@ prepared statement provided invalid parameter count (expected %d, but %d were provided)", [self class], _parameterCount, [strategy count]];

    /* Sqlite counts parameters starting at 1. */
    for (int valueIndex = 1; valueIndex <= _parameterCount; valueIndex++) {
        /* (Note that NSArray indexes from 0, so we subtract one to get the current value) */
        id value = [strategy valueForParameter: valueIndex withStatement: _sqlite_stmt];
        if (value == nil) {
            [NSException raise: PLSqliteException
                        format: @"Missing parameter %d binding for query %@", valueIndex, _queryString];
        }

        /* Bind the parameter */
        int ret = [self bindValueForParameter: valueIndex
                                    withValue: value];
        
        /* If the bind fails, throw an exception (programmer error). */
        if (ret != SQLITE_OK) {
            [NSException raise: PLSqliteException
                        format: @"SQlite error binding parameter %d for query %@: %@", valueIndex - 1, _queryString, [_database lastErrorMessage]];
        }
    }
    
    /* If you got this far, all is well */
}

/* from PLPreparedStatement */
- (void) bindParameters: (NSArray *) parameters {
    PLSqliteArrayParameterStrategy *strategy;
    
    strategy = [[[PLSqliteArrayParameterStrategy alloc] initWithValues: parameters] autorelease];
    [self bindParametersWithStrategy: strategy];
}

- (void) bindParameterDictionary: (NSDictionary *) parameters {
    PLSqliteDictionaryParameterStrategy *strategy;
    
    strategy = [[[PLSqliteDictionaryParameterStrategy alloc] initWithValueDictionary: parameters] autorelease];
    [self bindParametersWithStrategy: strategy];
}

#ifdef PL_SQLITE_LEGACY_STMT_PREPARE

/**
 * @internal
 *
 * Re-create and return the backing prepared statement.
 *
 * Must only be called by PLSqliteResultSet. This method is only available
 * to support SQLite 3.0.9 and earlier, where sqlite3_prepare_v2() is unavailable.
 *
 * The implementation should be dropped if sqlite3_prepare() support is dropped.
 *
 * MEMORY OWNERSHIP WARNING:
 * The reference to the returned sqlite3_stmt object is borrowed.
 */
- (sqlite3_stmt *) reloadStatementAndReturnError: (NSError **) error {
    sqlite3_stmt *newStmt;
    
    /* Try re-creating the statement */
    newStmt = [_database createStatement: _queryString error: error];
    if (newStmt == NULL)
        return NULL;
    
    /* Free the current prepared statement */
    sqlite3_finalize(_sqlite_stmt);
    
    /* Set the new prepared statement */
    _sqlite_stmt = newStmt;
    
    /* Re-bind parameters */
    if (_boundParameterStrategy != nil) {
        BOOL useFlag = _inUse;
        _inUse = NO; // evil! allows re-bind even if the prepared statement is currently checked out.
        [self bindParametersWithStrategy: _boundParameterStrategy];
        _inUse = useFlag;
    }

    /* Provide the new statement to the caller */
    return _sqlite_stmt;
}

#endif /* PL_SQLITE_LEGACY_STMT_PREPARE */


/* from PLPreparedStatement */
- (BOOL) executeUpdate {
    return [self executeUpdateAndReturnError: NULL];
}


/* from PLPreparedStatement */
- (BOOL) executeUpdateAndReturnError: (NSError **) outError {
    [self assertNotInUse];

    PLSqliteResultSet *rs;
    BOOL ret;

    /* Execute the query */
    rs = [self executeQueryAndReturnError: outError];
    if (rs == nil)
        return NO;


    /* Step the virtual machine once to execute the statement. */
    if ([rs nextAndReturnError: outError] == PLResultSetStatusError) {
        /* Error occured. outError has been populated. */
        ret = NO;
    } else {
        ret = YES;
    }

    /* Clean up the result set */
    [rs close];

    /* Finished */
    return ret;
}


/* from PLPreparedStatement */
- (id<PLResultSet>) executeQuery {
    return [self executeQueryAndReturnError: NULL];
}

/* from PLPreparedStatement */
- (id<PLResultSet>) executeQueryAndReturnError: (NSError **) outError {
    /*
     * Check out a new PLSqliteResultSet statement.
     * At this point, is there any way for the query to actually fail? It has already been compiled and verified.
     */
    return [self checkoutResultSet];
}

/**
 * @internal
 *
 * Check a result set back in, releasing any associated data
 * and releasing any exclusive ownership on the prepared statement.
 */
- (void) checkinResultSet: (PLSqliteResultSet *) resultSet {
    assert(_inUse = YES); // That would be strange.

    _inUse = NO;
    sqlite3_reset(_sqlite_stmt);

    /* If the statement is to be closed on the first checkin, do so, and
     * release our database resources */
    if (_closeAtCheckin)
        [self close];
}

@end

#pragma mark Private Implementation

/**
 * @internal
 *
 * Private PLSqliteDatabase methods.
 */
@implementation PLSqlitePreparedStatement (PLSqlitePreparedStatementPrivate)

/**
 * @internal
 * Assert that the result set has not been closed
 */
- (void) assertNotClosed {
    if (_sqlite_stmt == NULL)
        [NSException raise: PLSqliteException format: @"Attempt to access already-closed prepared statement."];
}

/**
 * @internal
 *
 * Assert that this instance is not in use by a PLSqliteResult.
 */
- (void) assertNotInUse {
    [self assertNotClosed];

    if (_inUse)
        [NSException raise: PLSqliteException format: @"A PLSqliteResultSet is already active and has not been properly closed for prepared statement '%@'", _queryString];
}

/**
 * @internal
 *
 * Check out a new PLSqliteResultSet, acquiring exclusive ownership
 * of the prepared statement. If another result set is currently checked
 * out, will throw an exception;
 */
- (PLSqliteResultSet *) checkoutResultSet {
    /* State validation. Only one result set may be checked out at a time */
    [self assertNotInUse];
    _inUse = YES;

   /*
    * MEMORY OWNERSHIP WARNING:
    * We pass our sqlite3_stmt reference to the PLSqliteResultSet, and gaurantee (by contract)
    * that the statement reference will remain valid until checkinResultSet is called for
    * the new PLSqliteResultSet instance.
    */
    return [[[PLSqliteResultSet alloc] initWithPreparedStatement: self sqliteStatemet: _sqlite_stmt] autorelease];
}

/**
 * @internal
 * Bind a value to a statement parameter, returning the SQLite bind result value.
 *
 * @param parameterIndex Index of parameter to be bound.
 * @param value Objective-C object to use as the value.
 */
- (int) bindValueForParameter: (int) parameterIndex withValue: (id) value {
    /* NULL */
    if (value == nil || value == [NSNull null]) {
        return sqlite3_bind_null(_sqlite_stmt, parameterIndex);
    }
    
    /* Data */
    else if ([value isKindOfClass: [NSData class]]) {
        return sqlite3_bind_blob(_sqlite_stmt, parameterIndex, [value bytes], [value length], SQLITE_TRANSIENT);
    }
    
    /* Date */
    else if ([value isKindOfClass: [NSDate class]]) {
        return sqlite3_bind_double(_sqlite_stmt, parameterIndex, [value timeIntervalSince1970]);
    }
    
    /* String */
    else if ([value isKindOfClass: [NSString class]]) {
        return sqlite3_bind_text(_sqlite_stmt, parameterIndex, [value UTF8String], -1, SQLITE_TRANSIENT);
    }
    
    /* Number */
    else if ([value isKindOfClass: [NSNumber class]]) {
        const char *objcType = [value objCType];
        int64_t number = [value longLongValue];
        
        /* Handle floats and doubles */
        if (strcmp(objcType, @encode(float)) == 0 || strcmp(objcType, @encode(double)) == 0) {
            return sqlite3_bind_double(_sqlite_stmt, parameterIndex, [value doubleValue]);
        }
        
        /* If the value can fit into a 32-bit value, use that bind type. */
        else if (number >= INT32_MIN && number <= INT32_MAX) {
            return sqlite3_bind_int(_sqlite_stmt, parameterIndex, number);
            
            /* Otherwise use the 64-bit bind. */
        } else {
            return sqlite3_bind_int64(_sqlite_stmt, parameterIndex, number);
        }
    }
    
    /* Not a known type */
    [NSException raise: PLSqliteException format: @"SQLite error binding unknown parameter type '%@'. Value: '%@'", [value class], value];
    
    /* Unreachable */
    abort();
}

@end