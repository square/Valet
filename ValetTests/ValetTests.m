//
//  ValetTests.m
//  Valet
//
//  Created by Dan Federman on 2/11/15.
//  Copyright (c) 2015 Square, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "Valet.h"


@interface VALValet (Testing)

- (NSString *)_sharedAccessGroupPrefix;
- (NSDictionary *)_secItemFormatDictionaryWithKey:(NSString *)Key;

@end


@interface KeychainTests : XCTestCase

@property (nonatomic, readwrite) VALValet *valet;
@property (nonatomic, readwrite) VALSynchronizableValet *synchronizableValet;
@property (nonatomic, readwrite) VALSecureElementValet *secureElementValet;
@property (nonatomic, copy, readwrite) NSString *key;
@property (nonatomic, copy, readwrite) NSString *string;
@property (nonatomic, copy, readwrite) NSString *secondaryString;
@property (nonatomic, strong, readwrite) NSMutableArray *additionalValets;

@end


@implementation KeychainTests

#pragma mark Setup

- (void)setUp;
{
    [super setUp];
    
    self.valet = [[VALValet alloc] initWithIdentifier:@"valet_testing" accessibility:VALAccessibleAlways];
    self.synchronizableValet = [[VALSynchronizableValet alloc] initWithIdentifier:@"valet_testing" accessibility:VALAccessibleAlways];
    self.secureElementValet = [[VALSecureElementValet alloc] initWithIdentifier:@"valet_testing" accessibility:VALAccessibleWhenPasscodeSetThisDeviceOnly];
    
    self.key = @"foo";
    self.string = @"bar";
    self.secondaryString = @"bar2";
    self.additionalValets = [NSMutableArray new];
}

- (void)tearDown;
{
    [self.valet removeAllObjects];
    [self.synchronizableValet removeAllObjects];
    [self.secureElementValet removeAllObjects];
    
    for (VALValet *additionalValet in self.additionalValets) {
        [additionalValet removeAllObjects];
    }
    
    [super tearDown];
}

#pragma mark Tests

- (void)test_initialization_invalidArgumentsCauseFailure;
{
    XCTAssertNil([[VALValet alloc] initWithIdentifier:@"" accessibility:VALAccessibleAlways]);
    XCTAssertNil([[VALValet alloc] initWithIdentifier:@"test" accessibility:0]);
    XCTAssertNil([[VALSynchronizableValet alloc] initWithIdentifier:@"test" accessibility:VALAccessibleWhenPasscodeSetThisDeviceOnly]);
    XCTAssertNil([[VALSecureElementValet alloc] initWithIdentifier:@"test" accessibility:VALAccessibleWhenUnlockedThisDeviceOnly]);
}

- (void)test_canAccessKeychain;
{
    // Testing environments should always be able to access the keychain.
    XCTAssertTrue([self.valet canAccessKeychain]);
}

- (void)test_stringForKey_retrievesString;
{
    XCTAssertNil([self.valet stringForKey:self.key]);
    
    XCTAssertTrue([self.valet setString:self.string forKey:self.key]);
    XCTAssertEqualObjects([self.valet stringForKey:self.key], self.string);
}

- (void)test_stringForKey_invalidKeyFailsToRetrieveString;
{
    NSString *string = [self.valet stringForKey:@"abcdefg"];
    XCTAssertNil(string, @"Expected string with Key for non-existent user to be nil but instead it was %@", string);
}

- (void)test_stringForKey_differentIdentifierFailsToRetrieveString;
{
    XCTAssertTrue([self.valet setString:self.string forKey:self.key]);
    VALValet *otherValet = [[VALValet alloc] initWithIdentifier:[self.valet.identifier stringByAppendingString:@"_different"] accessibility:VALAccessibleAlways];
    [self.additionalValets addObject:otherValet];
    
    NSString *string = [otherValet stringForKey:self.key];
    XCTAssertNil(string, @"Expected string with Key with different identifier to be nil but instead it was %@", string);
}

- (void)test_stringForKey_differentAccessGroupFailsToRetrieveString;
{
    XCTAssertTrue([self.valet setString:self.string forKey:self.key]);
    VALValet *otherValet = [[VALValet alloc] initWithIdentifier:self.valet.identifier accessibility:VALAccessibleAfterFirstUnlockThisDeviceOnly];
    [self.additionalValets addObject:otherValet];
    
    NSString *string = [otherValet stringForKey:self.key];
    XCTAssertNil(string, @"Expected string with Key with different access group to be nil but instead it was %@", string);
}

- (void)test_stringForKey_differentValetTypeFailsToRetrieveString;
{
    XCTAssertTrue([self.valet setString:self.string forKey:self.key]);
    VALValet *otherValet = [[VALValet alloc] initWithIdentifier:self.valet.identifier accessibility:VALAccessibleAfterFirstUnlockThisDeviceOnly];
    [self.additionalValets addObject:otherValet];
    
    NSString *string = [otherValet stringForKey:self.key];
    XCTAssertNil(string, @"Expected string with Key with different Valet type to be nil but instead it was %@", string);
}

- (void)test_setStringForKey_invalidArgumentsCauseFailure;
{
    XCTAssertFalse([self.valet setString:@"" forKey:self.key]);
    XCTAssertFalse([self.valet setString:self.string forKey:@""]);
    XCTAssertFalse([self.valet setString:@"" forKey:@""]);
}

- (void)test_setStringForKey_successfullySetsAndUpdatesString;
{
    // Ensure the string doesn't already exist.
    XCTAssertNil([self.valet stringForKey:self.key]);
    
    // Set the string.
    XCTAssertTrue([self.valet setString:self.string forKey:self.key]);
    
    // Verify the updated string is there.
    XCTAssertEqualObjects([self.valet stringForKey:self.key], self.string);
    
    // Setting the string a second time should update the existing record.
    XCTAssertTrue([self.valet setString:self.secondaryString forKey:self.key]);
    
    // Verify the updated string is there.
    XCTAssertEqualObjects([self.valet stringForKey:self.key], self.secondaryString);
}

- (void)test_setStringForKey_ValetsWithSameIdentifierButDifferentAccessibilityCanSetStringForSameKey;
{
    VALValet *otherValet = [[VALValet alloc] initWithIdentifier:self.valet.identifier accessibility:self.valet.accessibility+1];
    [self.additionalValets addObject:otherValet];
    
    XCTAssertTrue([self.valet setString:self.string forKey:self.key]);
    XCTAssertTrue([otherValet setString:self.secondaryString forKey:self.key]);
    
    XCTAssertEqualObjects([self.valet stringForKey:self.key], self.string);
    XCTAssertEqualObjects([otherValet stringForKey:self.key], self.secondaryString);
}

- (void)test_setStringForKey_nonStringData;
{
    XCTAssertTrue([self.valet setString:self.string forKey:self.key]);
    XCTAssertEqualObjects([self.valet stringForKey:self.key], self.string);
}

- (void)test_removeObjectForKey_succeedsWhenNoKeyExists;
{
    XCTAssertTrue([self.valet removeObjectForKey:@"gfdsa"]);
}

- (void)test_removeObjectForKey_successfullyRemovesKey;
{
    XCTAssertNil([self.valet stringForKey:self.key]);
    
    XCTAssertTrue([self.valet setString:self.string forKey:self.key]);
    XCTAssertTrue([self.valet removeObjectForKey:self.key]);
    XCTAssertNil([self.valet stringForKey:self.key], @"Expected no string to be retrieved after removing string");
}

- (void)test_removeObjectForKey_wrongIdentifierSucceeds;
{
    XCTAssertNil([self.valet stringForKey:self.key]);
    
    XCTAssertTrue([self.valet setString:self.string forKey:self.key]);
    
    VALValet *otherValet = [[VALValet alloc] initWithIdentifier:[self.valet.identifier stringByAppendingString:@"_different"] accessibility:VALAccessibleAfterFirstUnlockThisDeviceOnly];
    XCTAssertTrue([otherValet removeObjectForKey:self.key], @"Expected removing Key foo with different identifier to succeed since the object is not in the keychain");
}

- (void)test_removeObjectForKey_ValetsWithSameIdentifierButDifferentAccessibilityRemoveDistinctDataFromKeychain;
{
    VALValet *otherValet = [[VALValet alloc] initWithIdentifier:self.valet.identifier accessibility:self.valet.accessibility+1];
    [self.additionalValets addObject:otherValet];
    
    XCTAssertTrue([self.valet setString:self.string forKey:self.key]);
    XCTAssertTrue([otherValet setString:self.secondaryString forKey:self.key]);
    
    XCTAssertEqualObjects([self.valet stringForKey:self.key], self.string);
    XCTAssertEqualObjects([otherValet stringForKey:self.key], self.secondaryString);
    
    XCTAssertTrue([self.valet removeObjectForKey:self.key]);
    XCTAssertNil([self.valet stringForKey:self.key]);
    XCTAssertEqualObjects([otherValet stringForKey:self.key], self.secondaryString);
    
    XCTAssertTrue([otherValet removeObjectForKey:self.key]);
    XCTAssertNil([otherValet stringForKey:self.key]);
}

- (void)test_removeObjectForKey_ValetsWithSameIdentifierAndAccessibilityButDifferentClassTypeRemoveDistinctDataFromKeychain;
{
    if (self.synchronizableValet == nil) {
        return;
    }
    
    XCTAssertTrue([self.valet setString:self.string forKey:self.key]);
    XCTAssertTrue([self.synchronizableValet setString:self.secondaryString forKey:self.key]);
    
    XCTAssertEqualObjects([self.valet stringForKey:self.key], self.string);
    XCTAssertEqualObjects([self.synchronizableValet stringForKey:self.key], self.secondaryString);
    
    XCTAssertTrue([self.valet removeObjectForKey:self.key]);
    XCTAssertNil([self.valet stringForKey:self.key]);
    XCTAssertEqualObjects([self.synchronizableValet stringForKey:self.key], self.secondaryString);
    
    XCTAssertTrue([self.synchronizableValet removeObjectForKey:self.key]);
    XCTAssertNil([self.synchronizableValet stringForKey:self.key]);
}

- (void)test_containsObjectForKey_returnsYESWhenKeyExists;
{
    XCTAssertTrue([self.valet setString:self.string forKey:self.key]);
    XCTAssertTrue([self.valet containsObjectForKey:self.key]);
}

- (void)test_containsObjectForKey_returnsNOWhenKeyDoesNotExist;
{
    XCTAssertFalse([self.valet containsObjectForKey:self.key]);
}

- (void)test_containsObjectForKey_returnsYESWithoutPromptingUserOnSecureElementValet;
{
    if (self.secureElementValet == nil) {
        return;
    }
    
    XCTAssertTrue([self.secureElementValet setString:self.string forKey:self.key]);
    XCTAssertTrue([self.valet containsObjectForKey:self.key]);
}

- (void)test_allKeys_returnsNilWhenNoAllKeysPresent;
{
    XCTAssertNil([self.valet stringForKey:self.key]);
    XCTAssertNil([self.valet allKeys]);
}

- (void)test_allKeys_returnsOneKeyWhenOnlyOneKey;
{
    XCTAssertNil([self.valet stringForKey:self.key]);
    
    XCTAssertTrue([self.valet setString:self.string forKey:self.key]);
    XCTAssertEqualObjects([self.valet allKeys], [NSSet setWithObject:self.key]);
}

- (void)test_allKeys_returnsAllKeys;
{
    XCTAssertNil([self.valet stringForKey:self.key]);
    
    XCTAssertTrue([self.valet setString:self.string forKey:self.key]);
    XCTAssertTrue([self.valet setString:self.string forKey:@"anotherfoo"]);
    
    NSSet *allKeys = [NSSet setWithArray:@[ self.key, @"anotherfoo" ]];
    XCTAssertEqualObjects([self.valet allKeys], allKeys);
}

- (void)test_allKeys_differentIdentifierReturnsNil;
{
    XCTAssertNil([self.valet stringForKey:self.key]);
    
    XCTAssertTrue([self.valet setString:self.string forKey:self.key]);
    
    VALValet *otherValet = [[VALValet alloc] initWithIdentifier:[self.valet.identifier stringByAppendingString:@"_different"] accessibility:VALAccessibleAfterFirstUnlockThisDeviceOnly];
    [self.additionalValets addObject:otherValet];
    
    NSSet *allKeys = [otherValet allKeys];
    XCTAssertNil(allKeys, @"Expected allKeys with different identifier to be nil but instead it was %@", allKeys);
}

- (void)test_setSynchronizableKeyString_setsSynchronizableString;
{
    if (self.synchronizableValet == nil) {
        return;
    }
    
    XCTAssertNil([self.synchronizableValet stringForKey:self.key]);
    
    XCTAssertTrue([self.synchronizableValet setString:self.string forKey:self.key]);
    XCTAssertEqualObjects(self.string, [self.synchronizableValet stringForKey:self.key]);
    
    XCTAssertNil([self.synchronizableValet stringForKey:self.key], @"Expected no non-synchronizable string to be found.");
}

- (void)test_removeObjectForKey_removesSynchronizableString;
{
    if (self.synchronizableValet == nil) {
        return;
    }
    
    XCTAssertNil([self.synchronizableValet stringForKey:self.key]);
    
    XCTAssertTrue([self.synchronizableValet setString:self.string forKey:self.key]);
    XCTAssertEqualObjects(self.string, [self.synchronizableValet stringForKey:self.key]);
    
    XCTAssertTrue([self.synchronizableValet removeObjectForKey:self.key]);
    XCTAssertNil([self.synchronizableValet stringForKey:self.key]);
}

- (void)test_secItemFormatDictionaryWithKey_stringInDictionaryAsData;
{
    NSDictionary *KeyDictionary = [self.valet _secItemFormatDictionaryWithKey:self.key];
    XCTAssertEqualObjects(KeyDictionary[(__bridge id)kSecAttrAccount], self.key);
}

- (void)test_sharedAccessGroupPrefix_returnsValidValue;
{
    XCTAssertTrue([self.valet _sharedAccessGroupPrefix].length > 0);
}

#pragma mark - XCTestCase

// These fail when running from the command line
- (XCTestRun *)run;
{
    if ([self _skipTestCase]) {
        return [[XCTestRun alloc] initWithTest:self];
    }
    
    return [super run];
}

#pragma mark - Private Methods

- (BOOL)_skipTestCase;
{
    // When running tests from the command line, the process arguments do not have this parameter
    BOOL isRunningFromCommandLine = [[NSProcessInfo processInfo].arguments indexOfObject:@"-ApplePersistenceIgnoreState"] == NSNotFound;
    return isRunningFromCommandLine;
}

@end
