//
//  MariaDBKitTests_ios.m
//  MariaDBKitTests-ios
//
//  Created by Kyle Hankinson on 8/11/17.
//  Copyright © 2017 Kyle Hankinson. All rights reserved.
//

#import <XCTest/XCTest.h>
@import MariaDBKit;

@interface MariaDBKitTests_ios : XCTestCase

@end

@implementation MariaDBKitTests_ios

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void) testConnect {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
