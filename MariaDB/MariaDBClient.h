//
//  MariaDBClient.h
//  MariaDBKit
//
//  Created by Kyle Hankinson on 2019-03-06.
//  Copyright © 2019 Kyle Hankinson. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MariaDBResultSet.h"

#define kMariaDBKitDomain      @"MariaDBKit"

NS_ASSUME_NONNULL_BEGIN

@interface MariaDBClient : NSObject

- (BOOL) connect: (NSString*) host
        username: (NSString*) username
        password: (NSString*) password
        database: (NSString*) database
           error: (NSError**) pError;

- (BOOL) connect: (NSString*) host
        username: (NSString*) username
        password: (NSString*) password
        database: (NSString*) database
            port: (NSUInteger) port
           error: (NSError**) pError;

- (NSError*) lastError;

- (MariaDBResultSet*) executeQuery: (NSString*) sql
                             error: (NSError**) pError __attribute__((swift_error(nonnull_error)));

@end

NS_ASSUME_NONNULL_END
