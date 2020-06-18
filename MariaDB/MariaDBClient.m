//
//  MariaDBClient.m
//  MariaDBKit
//
//  Created by Kyle Hankinson on 2019-03-06.
//  Copyright © 2019 Kyle Hankinson. All rights reserved.
//

#import "MariaDBClient.h"

#ifndef MYSQL_SUCCESS
#define MYSQL_SUCCESS           (0)
#endif

@implementation MariaDBClient
{
    MYSQL * mysql;
}

- (id) init
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // 0 == success
        int result = mysql_library_init(0, NULL, NULL);
        NSString * clientInfo = [NSString stringWithUTF8String: mysql_get_client_info()];
        NSLog(@"mysql_library_init result: %d. Client info: %@.", result, clientInfo);
    });

    self = [super init];
    if(self)
    {
        
    } // End of self

    return self;
} // End of init

- (void) dealloc
{
    if(mysql)
    {
        mysql_close(mysql);
        mysql = NULL;
    } // End of we have an open socket
} // End of dealloc

- (BOOL) connect: (NSString*) host
        username: (NSString*) username
        password: (NSString*) password
        database: (NSString*) database
           error: (NSError**) pError
{
    return [self connect: host
                username: username
                password: password
                database: database
                    port: 3306
                   error: pError];
}

- (BOOL) connect: (NSString*) host
        username: (NSString*) username
        password: (NSString*) password
        database: (NSString*) database
            port: (NSUInteger) port
           error: (NSError**) pError
{
    mysql = mysql_init(NULL);
    
    // Compress results
    mysql_options(mysql, MYSQL_OPT_COMPRESS, 0);
    
    // Use TCP
    int protocol = MYSQL_PROTOCOL_TCP;
    mysql_options(mysql, MYSQL_OPT_PROTOCOL, (const void*)&protocol);
    
    // Set our encoding
    mysql_options(mysql, MYSQL_SET_CHARSET_NAME, [@"utf8" UTF8String]);
    
    unsigned long clientFlags = CLIENT_COMPRESS;
    
    if(NULL == mysql_real_connect(mysql,
                                  host.UTF8String,
                                  username.UTF8String,
                                  password.UTF8String,
                                  NULL,
                                  (unsigned int) port,
                                  NULL,
                                  clientFlags))
    {
        if(pError)
        {
            * pError = [self lastError];
        }

        return false;
    } // End of mysql_real_connect

    if(database && database.length)
    {
        if(MYSQL_SUCCESS != mysql_select_db(mysql, database.UTF8String))
        {
            if(pError)
            {
                * pError = [self lastError];
            }

            return false;
        }
    } // End of we have a database specified
    
    return true;
} // End of connect:password:database:error

- (MariaDBResultSet*) executeQuery: (NSString*) sql
                             error: (NSError**) pError
{
    if(NULL == mysql)
    {
        return NULL;
    } // End of mysql was null
    
    const char * queryToExecute = [sql UTF8String];
    unsigned int queryLength    = (unsigned int)strlen(queryToExecute);
    
    // Execute the query
    if(0 != mysql_real_query(mysql, queryToExecute, queryLength))
    {
        if(pError)
        {
            *pError = [self lastError];
        }
        
        return NULL;
    } // End of execute query
    
    // Get our result
    MYSQL_RES * res = mysql_use_result(mysql);

    MariaDBResultSet * resultSet = [[MariaDBResultSet alloc] initWithResult: res];
    
    return resultSet;
} // End of executeQuery

- (NSError*) lastError
{
    @synchronized(self)
    {
        if(mysql)
        {
            const char* ch = mysql_error(mysql);
            unsigned int errorNo = mysql_errno(mysql);
            
            if(ch && 0 != ch[0])
            {
                NSString * errorString = [NSString stringWithUTF8String: ch];
                
                if(nil == errorString)
                {
                    if(nil == errorString)
                    {
                        errorString = [NSString stringWithFormat: @"Unknown error (%u)", errorNo];;
                    } // End of unknown encoding
                } // End of unknown error
                
                return [NSError errorWithDomain: kMariaDBKitDomain
                                           code: 0
                                       userInfo: @{NSLocalizedDescriptionKey : errorString}];
            }
            else
            {
                return NULL;
            }
        } // End of we have a connection

        return [NSError errorWithDomain: kMariaDBKitDomain
                                   code: 0
                               userInfo: @{NSLocalizedDescriptionKey : @"Unknown error. (No connection to the server)."}];
    } // End of synchronized
} // End of lastError

@end
