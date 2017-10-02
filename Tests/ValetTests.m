//
//  ValetTests.m
//  Valet
//
//  Created by Dan Federman on 2/11/15.
//  Copyright 2015 Square, Inc.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

@import Valet;

#import <XCTest/XCTest.h>

#import "ValetTests.h"


@interface KeychainTests : XCTestCase

@property (nonatomic, readwrite) VALLegacyValet *valet;
@property (nonatomic, copy, readwrite) NSString *key;
@property (nonatomic, copy, readwrite) NSString *string;

@end


@implementation KeychainTests

#pragma mark - Setup

- (void)setUp;
{
    [super setUp];
    
    NSString *const valetTestingIdentifier = @"valet_testing";
    self.valet = [[VALLegacyValet alloc] initWithIdentifier:valetTestingIdentifier accessibility:VALLegacyAccessibilityWhenUnlocked];
    
    // In case testing quit unexpectedly, clean up the keychain from last time.
    [self.valet removeAllObjects];
    
    self.key = @"foo";
    self.string = @"bar";
}

#pragma mark - Behavior Tests

- (void)test_initialization_invalidArgumentsCauseFailure;
{
    id nilValue = nil;
    XCTAssertNil([[VALLegacyValet alloc] initWithIdentifier:nilValue accessibility:VALLegacyAccessibilityAlways]);
    XCTAssertNil([[VALLegacyValet alloc] initWithIdentifier:@"" accessibility:VALLegacyAccessibilityAlways]);
    XCTAssertNil([[VALLegacyValet alloc] initWithIdentifier:@"test" accessibility:0]);
}

- (void)test_setObjectForKey_invalidArgumentsCauseFailure;
{
    NSData *stringAsData = [self.string dataUsingEncoding:NSUTF8StringEncoding];
    XCTAssertNotNil(stringAsData);
    
    id nilValue = nil;
    XCTAssertFalse([self.valet setObject:nilValue forKey:self.key]);
    XCTAssertFalse([self.valet setObject:stringAsData forKey:nilValue]);
    XCTAssertFalse([self.valet setObject:nilValue forKey:nilValue]);
    
    NSData *emptyData = [NSData new];
    XCTAssertFalse([self.valet setObject:emptyData forKey:self.key]);
    XCTAssertFalse([self.valet setObject:stringAsData forKey:@""]);
    XCTAssertFalse([self.valet setObject:emptyData forKey:@""]);
}

- (void)test_setStringForKey_invalidArgumentsCauseFailure;
{
    id nilValue = nil;
    XCTAssertFalse([self.valet setString:nilValue forKey:self.key]);
    XCTAssertFalse([self.valet setString:self.string forKey:nilValue]);
    XCTAssertFalse([self.valet setString:nilValue forKey:nilValue]);

    XCTAssertFalse([self.valet setString:@"" forKey:self.key]);
    XCTAssertFalse([self.valet setString:self.string forKey:@""]);
    XCTAssertFalse([self.valet setString:@"" forKey:@""]);
}

// FIXME: We have no idea what this was here for
- (void)test_setStringForKey_nonStringData;
{
    XCTAssertTrue([self.valet setString:self.string forKey:self.key]);
    XCTAssertEqualObjects([self.valet stringForKey:self.key], self.string);
}

@end


// FIXME: emuller - coming soon
@interface SwiftInteropTests : XCTestCase

@property (nonatomic, readwrite) VALValet *valet;
@property (nonatomic, copy, readwrite) NSString *key;
@property (nonatomic, copy, readwrite) NSString *string;

@end

@implementation SwiftInteropTests

- (void)setUp;
{
    [super setUp];

    NSString *const __unused valetTestingIdentifier = @"valet_testing";
//    self.valet = [VALValet vanillaValetWithIdentifier:valetTestingIdentifier accessibility:VALAccessibilityWhenUnlocked];
}

- (void)tearDown;
{
    [super tearDown];
}

@end
