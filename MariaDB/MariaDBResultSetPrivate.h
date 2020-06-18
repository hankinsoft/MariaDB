//
//  MariaDBResultSetPrivate.h
//  MariaDBKit
//
//  Created by Kyle Hankinson on 2020-06-18.
//  Copyright © 2020 Kyle Hankinson. All rights reserved.
//

#ifndef MariaDBResultSetPrivate_h
#define MariaDBResultSetPrivate_h

#import "mysql.h"

@interface MariaDBResultSet(Private)

- (id) initWithResult: (MYSQL_RES*) result;

@end

#endif /* MariaDBResultSetPrivate_h */
