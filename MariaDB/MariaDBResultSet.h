//
//  MariaDBResultSet.h
//  MariaDBKit
//
//  Created by Kyle Hankinson on 2019-03-06.
//  Copyright © 2019 Kyle Hankinson. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "mysql.h"

NS_ASSUME_NONNULL_BEGIN

@interface MariaDBResultSet : NSObject

- (id) initWithResult: (MYSQL_RES*) result;
- (BOOL) next: (NSError*__autoreleasing*) error;
- (id) objectForColumnIndex: (NSUInteger) columnIndex;

@end

NS_ASSUME_NONNULL_END
