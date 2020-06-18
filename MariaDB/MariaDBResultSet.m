//
//  MariaDBResultSet.m
//  MariaDBKit
//
//  Created by Kyle Hankinson on 2019-03-06.
//  Copyright © 2019 Kyle Hankinson. All rights reserved.
//

#import "MariaDBResultSet.h"
#import "MariaDBResultSetPrivate.h"

@interface MariaDBResultSet ()
{
    NSInteger           affectedRows;
    
    unsigned long long  totalRows;
    NSUInteger          totalFields;
    
    MYSQL_RES           * internalMySQLResult;
    MYSQL_ROW           internalMySQLRow;
    
    MYSQL_FIELD         * internalFields;
    
    NSNumberFormatter   * numberFormatter;
    NSDataDetector      * dateDetector;
}

@property(nonatomic,copy) NSArray * columnNames;
@property(nonatomic,copy) NSArray * columnTypes;

@end

@implementation MariaDBResultSet
{
    NSArray * currentRowFieldLengths;
}

@synthesize columnNames, columnTypes;

- (id) initWithResult: (MYSQL_RES*) result
{
    self = [super init];
    if(self)
    {
        affectedRows = 0;
        
        // The number formatter
        numberFormatter = [[NSNumberFormatter alloc] init];
        [numberFormatter setNumberStyle: NSNumberFormatterDecimalStyle];
        
        // Data detector
        dateDetector = [NSDataDetector dataDetectorWithTypes: NSTextCheckingTypeDate
                                                       error: nil];
        
        internalMySQLResult = result;
        if(NULL != internalMySQLResult)
        {
            totalFields = mysql_num_fields(internalMySQLResult);
            totalRows   = mysql_num_rows(internalMySQLResult);
            
            internalFields = mysql_fetch_fields(result);
            
            NSMutableArray * _columnNames  = [NSMutableArray array];
            NSMutableArray * _columnTypes = [NSMutableArray array];
            NSMutableArray * _charSets    = [NSMutableArray array];
            
            for(int i = 0; i < totalFields; i++)
            {
                [_columnNames addObject: [NSString stringWithUTF8String: internalFields[i].name]];
                [_columnTypes addObject: [NSNumber numberWithInt: internalFields[i].type]];
                [_charSets addObject: [NSNumber numberWithInt: internalFields[i].charsetnr]];
            } // End of finished
            
            // Get our field names
            columnNames         = _columnNames.copy;
            columnTypes         = _columnTypes.copy;
        } // End of we have an internalMySQLResult
    } // End of if self init
    
    return self;
} // End of init

- (void) dealloc
{
    if(NULL != internalMySQLResult)
    {
        mysql_free_result(internalMySQLResult);
        internalMySQLResult = NULL;
    } // End of clear the result set
} // End of dealloc

- (NSInteger) numberOfAffectedRows
{
    return affectedRows;
} // End of numberOfAffectedRows

- (BOOL) next: (NSError*__autoreleasing*) error
{
    if(NULL == internalMySQLResult)
    {
        return NO;
    } // End of we have no internal mysql results
    
    // If we have a row
    internalMySQLRow = mysql_fetch_row(internalMySQLResult);
    
    if(NULL != internalMySQLRow)
    {
        unsigned long * myLengths = mysql_fetch_lengths(internalMySQLResult);
        NSMutableArray * outLengths = [NSMutableArray array];
        for(NSUInteger index = 0;
            index < columnNames.count;
            ++index)
        {
            outLengths[index] = [NSNumber numberWithUnsignedLong: myLengths[index]];
        }
        
        // Set our currentRowField lengths
        currentRowFieldLengths = outLengths.copy;
        
        return YES;
    }
    
    // Whenever we fail to query, check if we have an error.
    if(error != NULL)
    {
        *error = [NSError errorWithDomain: @""
                                     code: 0
                                 userInfo: @{NSLocalizedDescriptionKey :@"Error"}];
    } // End of failed to query
    
    return NO;
} // End of next

- (NSUInteger)columnCount
{
    return totalFields;
}

- (NSString*)columnNameForIndex:(int)columnIdx
{
    return columnNames[columnIdx];
}

- (id) objectForColumn: (NSString*) columnName
{
    // Get our columnIndex
    NSUInteger columnIndex = [columnNames indexOfObject: columnName];
    
    NSAssert1(NSNotFound != columnIndex, @"Column %@ could not be found.", columnName);
    
    return [self objectForColumnIndex: columnIndex];
}

- (id) objectForColumnIndex: (NSUInteger) columnIndex
{
    id result = nil;
    /*
     enum enum_field_types { MYSQL_TYPE_DECIMAL, MYSQL_TYPE_TINY,
     MYSQL_TYPE_SHORT,  MYSQL_TYPE_LONG,
     MYSQL_TYPE_FLOAT,  MYSQL_TYPE_DOUBLE,
     MYSQL_TYPE_NULL,   MYSQL_TYPE_TIMESTAMP,
     MYSQL_TYPE_LONGLONG,MYSQL_TYPE_INT24,
     MYSQL_TYPE_DATE,   MYSQL_TYPE_TIME,
     MYSQL_TYPE_DATETIME, MYSQL_TYPE_YEAR,
     MYSQL_TYPE_NEWDATE, MYSQL_TYPE_VARCHAR,
     MYSQL_TYPE_BIT,
     MYSQL_TYPE_NEWDECIMAL=246,
     MYSQL_TYPE_ENUM=247,
     MYSQL_TYPE_SET=248,
     MYSQL_TYPE_TINY_BLOB=249,
     MYSQL_TYPE_MEDIUM_BLOB=250,
     MYSQL_TYPE_LONG_BLOB=251,
     MYSQL_TYPE_BLOB=252,
     MYSQL_TYPE_VAR_STRING=253,
     MYSQL_TYPE_STRING=254,
     MYSQL_TYPE_GEOMETRY=255,
     MAX_NO_FIELD_TYPES
     */
    //    NSLog(@"Internal row: %s", );
    MYSQL_FIELD currentField = internalFields[columnIndex];
    
    // No data, then we are a null.
    if(NULL == internalMySQLRow[columnIndex])
    {
        result = [NSNull null];
    }
    else
    {
        BOOL isEnum = NO;
        BOOL isSet  = NO;
        
        if((currentField.flags & ENUM_FLAG) == ENUM_FLAG)
        {
            isEnum = YES;
        }
        
        if((currentField.flags & SET_FLAG) == SET_FLAG)
        {
            isSet = YES;
        }
        
        if(isEnum || isSet)
        {
            NSLog(@"Is flag or enum.");
        }
        
        switch(currentField.type)
        {
            case MYSQL_TYPE_YEAR:
            case MYSQL_TYPE_INT24:
            case MYSQL_TYPE_TINY:
            case MYSQL_TYPE_SHORT:
            case MYSQL_TYPE_LONG:
            case MYSQL_TYPE_LONGLONG:
            {
                NSString * tempString = [NSString stringWithUTF8String: internalMySQLRow[columnIndex]];
                result = [numberFormatter numberFromString: tempString];
                break;
            }
            case MYSQL_TYPE_TIME:
            case MYSQL_TYPE_TIMESTAMP:
            case MYSQL_TYPE_DATETIME:
            case MYSQL_TYPE_DATE:
            {
                NSString * dateString = [NSString stringWithUTF8String: internalMySQLRow[columnIndex]];
                
                NSRange decimalRange = [dateString rangeOfString: @"."
                                                         options: NSBackwardsSearch];
                
                NSUInteger nanoseconds = 0;
                if(NSNotFound != decimalRange.location)
                {
                    NSString * nanosecondsString = [dateString substringFromIndex: decimalRange.location + 1];
                    nanoseconds = nanosecondsString.integerValue;
                } // End of we have milliseconds
                
                // TempFix -- 0000-00-00 00:00:00 is not handled by dateDetector, so we check
                // and handle it ourself.
                NSString * tempString = [dateString stringByReplacingOccurrencesOfString: @"0"
                                                                              withString: @""];
                
                tempString = [tempString stringByReplacingOccurrencesOfString: @":"
                                                                   withString: @""];
                
                tempString = [tempString stringByReplacingOccurrencesOfString: @"-"
                                                                   withString: @""];
                
                tempString = [tempString stringByReplacingOccurrencesOfString: @" "
                                                                   withString: @""];
                
                if(0 == tempString.length)
                {
                    result = dateString;
                }
                else
                {
                    __block NSDate * detectedDate = nil;
                    [dateDetector enumerateMatchesInString: dateString
                                                   options: kNilOptions
                                                     range: NSMakeRange(0, [dateString length])
                                                usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop)
                     {
                         detectedDate = result.date;
                     }];
                    
                    if(nil == detectedDate || 0 != nanoseconds)
                    {
                        result = dateString;
                    } // End of we have millseconds
                    else
                    {
                        result = detectedDate;
                    }
                }
                
                break;
            }
            case MYSQL_TYPE_LONG_BLOB:
            case MYSQL_TYPE_MEDIUM_BLOB:
            case MYSQL_TYPE_BLOB:
            case MYSQL_TYPE_STRING:
            case MYSQL_TYPE_VAR_STRING:
            case MYSQL_TYPE_JSON:
            {
                if(MYSQL_TYPE_JSON == currentField.type)
                {
                    result = [NSString stringWithUTF8String: internalMySQLRow[columnIndex]];
                }
                else if(63 == currentField.charsetnr)
                {
                    result = [NSData dataWithBytes: internalMySQLRow[columnIndex]
                                            length: [currentRowFieldLengths[columnIndex] unsignedIntegerValue]];
                    
                    if(nil != result)
                    {
                        NSString * stringResult = [[NSString alloc] initWithData: result
                                                                        encoding: NSUTF8StringEncoding];
                        
                        if(stringResult.length == ((NSData*)result).length)
                        {
                            result = stringResult;
                        }
                    }
                }
                else
                {
                    result = [NSString stringWithUTF8String: internalMySQLRow[columnIndex]];
                }
                break;
            }
            case MYSQL_TYPE_BIT:
            {
                if(0 == internalMySQLRow[columnIndex][0])
                {
                    result = [NSNumber numberWithBool: NO];
                }
                else
                {
                    result = [NSNumber numberWithBool: YES];
                }
                break;
            }
            case MYSQL_TYPE_FLOAT:
            case MYSQL_TYPE_DECIMAL:
            case MYSQL_TYPE_DOUBLE:
            case MYSQL_TYPE_NEWDECIMAL:
            {
                NSString * stringValue =
                [NSString stringWithUTF8String: internalMySQLRow[columnIndex]];
                
                NSDecimalNumber * number =
                [NSDecimalNumber decimalNumberWithString: stringValue];
                
                result = number;
                
                break;
            }
            default:
            {
                NSAssert2(false, @"Invalid field type %d (column %@).",
                          internalFields[columnIndex].type,
                          columnNames[columnIndex]);
                break;
            }
        } // End of data type switch
    } // End of data was not null
    
    // If we were unable to set our result, then null it.
    if(nil == result)
    {
        result = [NSNull null];
    }
    
    return result;
} // End of objectForColumnIndex

- (NSNumber*) boolForColumn: (NSString*) columnName
{
    // Get our columnIndex
    NSUInteger columnIndex = [columnNames indexOfObject: columnName];
    
    NSAssert1(NSNotFound != columnIndex, @"Column %@ could not be found.", columnName);
    
    return [self boolForColumnIndex: columnIndex];
}

- (NSNumber*) boolForColumnIndex: (NSUInteger) columnIndex
{
    if(nil == internalMySQLRow[columnIndex])
    {
        return nil;
    }
    
    NSString * tempString = [NSString stringWithUTF8String: internalMySQLRow[columnIndex]];
    return [NSNumber numberWithBool: [tempString boolValue]];
} // End of boolForColumnIndex

- (NSString*) stringForColumn: (NSString*) columnName
{
    // Get our columnIndex
    NSUInteger columnIndex = [columnNames indexOfObject: columnName];
    
    NSAssert1(NSNotFound != columnIndex, @"Column %@ could not be found.", columnName);
    
    return [self stringForColumnIndex: columnIndex];
}

- (NSString*) stringForColumnIndex: (NSUInteger) columnIndex
{
    if(nil == internalMySQLRow[columnIndex])
    {
        return nil;
    } // End of entry is nil
    
    id result = [[NSString alloc] initWithUTF8String: internalMySQLRow[columnIndex]];
    
    if([NSNull null] == result)
    {
        return nil;
    }
    
    return result;
} // End of stringForColumnIndex

- (NSNumber*) numberForColumn: (NSString*) columnName
{
    // Get our columnIndex
    NSUInteger columnIndex = [columnNames indexOfObject: columnName];
    
    NSAssert1(NSNotFound != columnIndex, @"Column %@ could not be found.", columnName);
    
    return [self numberForColumnIndex: columnIndex];
}

- (NSNumber*) numberForColumnIndex: (NSUInteger) columnIndex
{
    if(nil == internalMySQLRow[columnIndex])
    {
        return nil;
    } // End of entry is nil
    
    NSString * temp = [NSString stringWithUTF8String: internalMySQLRow[columnIndex]];
    
    NSNumberFormatter * formatter = [[NSNumberFormatter alloc] init];
    [formatter setNumberStyle:NSNumberFormatterDecimalStyle];
    
    return [formatter numberFromString: temp];
} // End of numberForColumnIndex:

@end
