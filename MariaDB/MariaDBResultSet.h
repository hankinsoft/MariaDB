//
//  MariaDBResultSet.h
//  MariaDBKit
//
//  Created by Kyle Hankinson on 2019-03-06.
//  Copyright © 2019 Kyle Hankinson. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MariaDBResultSet : NSObject

- (BOOL) next: (NSError*__autoreleasing*) error NS_SWIFT_NOTHROW;
- (id) objectForColumnIndex: (NSUInteger) columnIndex;

@property(nonatomic,retain,readonly) NSArray<NSString*>* columnNames;

@end

NS_ASSUME_NONNULL_END
