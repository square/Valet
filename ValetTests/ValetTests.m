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

#import <XCTest/XCTest.h>

#import <Valet/Valet.h>


@interface VALValet (Testing)

- (NSString *)_sharedAccessGroupPrefix;
- (NSDictionary *)_secItemFormatDictionaryWithKey:(NSString *)key;

@end


@interface VALTestingValet : VALValet
@end


@implementation VALTestingValet
@end


@interface KeychainTests : XCTestCase

@property (nonatomic, readwrite) VALValet *valet;
@property (nonatomic, readwrite) VALTestingValet *testingValet;
@property (nonatomic, readwrite) VALSynchronizableValet *synchronizableValet;
@property (nonatomic, copy, readwrite) NSString *key;
@property (nonatomic, copy, readwrite) NSString *string;
@property (nonatomic, copy, readwrite) NSString *secondaryString;
@property (nonatomic, strong, readwrite) NSMutableArray *additionalValets;

@end


@implementation KeychainTests

#pragma mark - Setup

- (void)setUp;
{
    [super setUp];
    
    self.valet = [[VALValet alloc] initWithIdentifier:@"valet_testing" accessibility:VALAccessibleWhenUnlocked];
    self.testingValet = [[VALTestingValet alloc] initWithIdentifier:@"valet_testing" accessibility:VALAccessibleWhenUnlocked];
    self.synchronizableValet = [[VALSynchronizableValet alloc] initWithIdentifier:@"valet_testing" accessibility:VALAccessibleWhenUnlocked];
    
    // In case testing quit unexpectedly, clean up the keychain from last time.
    [self.valet removeAllObjects];
    [self.testingValet removeAllObjects];
    [self.synchronizableValet removeAllObjects];
    
    for (VALValet *additionalValet in self.additionalValets) {
        [additionalValet removeAllObjects];
    }
    
    self.key = @"foo";
    self.string = @"bar";
    self.secondaryString = @"bar2";
    self.additionalValets = [NSMutableArray new];
}

#pragma mark - Behavior Tests

- (void)test_initialization_invalidArgumentsCauseFailure;
{
    XCTAssertNil([[VALValet alloc] initWithIdentifier:@"" accessibility:VALAccessibleAlways]);
    XCTAssertNil([[VALValet alloc] initWithIdentifier:@"test" accessibility:0]);
    XCTAssertNil([[VALSynchronizableValet alloc] initWithIdentifier:@"test" accessibility:VALAccessibleWhenPasscodeSetThisDeviceOnly]);
    XCTAssertNil([[VALSecureEnclaveValet alloc] initWithIdentifier:@"test" accessibility:VALAccessibleWhenUnlockedThisDeviceOnly]);
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

- (void)test_setStringForKey_setsSynchronizableString;
{
    if (self.synchronizableValet == nil) {
        return;
    }
    
    XCTAssertNil([self.synchronizableValet stringForKey:self.key]);
    
    XCTAssertTrue([self.synchronizableValet setString:self.string forKey:self.key]);
    XCTAssertEqualObjects(self.string, [self.synchronizableValet stringForKey:self.key]);
    
    XCTAssertNil([self.valet stringForKey:self.key], @"Expected no non-synchronizable string to be found.");
}

- (void)test_setStringForKey_nonStringData;
{
    XCTAssertTrue([self.valet setString:self.string forKey:self.key]);
    XCTAssertEqualObjects([self.valet stringForKey:self.key], self.string);
}

- (void)test_setStringForKey_successfullyUpdatesWhenRemoveObjectForKeyIsCalledConcurrently;
{
    dispatch_queue_t setStringQueue = dispatch_queue_create("Set String Queue", DISPATCH_QUEUE_CONCURRENT);
    dispatch_queue_t removeObjectQueue = dispatch_queue_create("Remove Object Queue", DISPATCH_QUEUE_CONCURRENT);
    
    for (NSUInteger testCount = 0; testCount < 50; testCount++) {
        dispatch_async(setStringQueue, ^{
            XCTAssertTrue([self.valet setString:self.string forKey:self.key]);
        });
        
        dispatch_async(removeObjectQueue, ^{
            XCTAssertTrue([self.valet removeObjectForKey:self.key]);
        });
    }
    
    // Now that we've enqueued 50 concurrent setString:forKey: and removeObjectForKey: calls, wait for them all to finish.
    XCTestExpectation *expectationSetStringQueue = [self expectationWithDescription:@"Set String Queue"];
    XCTestExpectation *expectationRemoveObjectQueue = [self expectationWithDescription:@"Remove Object Queue"];
    
    dispatch_barrier_async(setStringQueue, ^{
        [expectationSetStringQueue fulfill];
    });
    
    dispatch_barrier_async(removeObjectQueue, ^{
        [expectationRemoveObjectQueue fulfill];
    });
    
    [self waitForExpectationsWithTimeout:1.0 handler:nil];
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

- (void)test_removeObjectForKey_successfullyRemovesSynchronizableKey;
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
    XCTAssertTrue([self.valet setString:self.string forKey:self.key]);
    XCTAssertTrue([self.testingValet setString:self.secondaryString forKey:self.key]);
    
    XCTAssertEqualObjects([self.valet stringForKey:self.key], self.string);
    XCTAssertEqualObjects([self.testingValet stringForKey:self.key], self.secondaryString);
    
    XCTAssertTrue([self.valet removeObjectForKey:self.key]);
    XCTAssertNil([self.valet stringForKey:self.key]);
    XCTAssertEqualObjects([self.testingValet stringForKey:self.key], self.secondaryString);
    
    XCTAssertTrue([self.testingValet removeObjectForKey:self.key]);
    XCTAssertNil([self.testingValet stringForKey:self.key]);
}

- (void)test_removeObjectForKey_ValetsWithSameIdentifierAndAccessibilityButDifferentSyncronizableTypeRemoveDistinctDataFromKeychain;
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

- (void)test_migrateObjectsMatchingQueryRemoveOnCompletion_failsIfNoItemsFoundMatchingQueryInput;
{
    NSDictionary *queryWithNoMathces = @{ (__bridge id)kSecClass : (__bridge id)kSecClassGenericPassword, (__bridge id)kSecAttrService : @"Valet_Does_Not_Exist" };
    XCTAssertEqual([self.valet migrateObjectsMatchingQuery:queryWithNoMathces removeOnCompletion:NO].code, VALMigrationNoItemsToMigrateFoundError);
    XCTAssertEqual([self.valet migrateObjectsMatchingQuery:queryWithNoMathces removeOnCompletion:YES].code, VALMigrationNoItemsToMigrateFoundError);
}

- (void)test_migrateObjectsMatchingQueryRemoveOnCompletion_failsOnBadQueryInput;
{
    XCTAssertEqual([self.valet migrateObjectsMatchingQuery:@{} removeOnCompletion:NO].code, VALMigrationInvalidQueryError);
    XCTAssertEqual([self.valet migrateObjectsMatchingQuery:@{} removeOnCompletion:YES].code, VALMigrationInvalidQueryError);
    
    XCTAssertEqual([self.valet migrateObjectsMatchingQuery:@{ (__bridge id)kSecMatchLimit : (__bridge id)kSecMatchLimitOne } removeOnCompletion:NO].code, VALMigrationInvalidQueryError);
    XCTAssertEqual([self.valet migrateObjectsMatchingQuery:@{ (__bridge id)kSecReturnData : (__bridge id)kCFBooleanFalse } removeOnCompletion:NO].code, VALMigrationInvalidQueryError);
    XCTAssertEqual([self.valet migrateObjectsMatchingQuery:@{ (__bridge id)kSecReturnAttributes : (__bridge id)kCFBooleanFalse } removeOnCompletion:NO].code, VALMigrationInvalidQueryError);
    XCTAssertEqual([self.valet migrateObjectsMatchingQuery:@{ (__bridge id)kSecReturnRef : (__bridge id)kCFBooleanTrue } removeOnCompletion:NO].code, VALMigrationInvalidQueryError);
    XCTAssertEqual([self.valet migrateObjectsMatchingQuery:@{ (__bridge id)kSecReturnPersistentRef : (__bridge id)kCFBooleanTrue } removeOnCompletion:NO].code, VALMigrationInvalidQueryError);
    
#if VAL_SUPPORTS_SECURE_ENCLAVE
    if ([VALSecureEnclaveValet supportsSecureEnclaveKeychainItems]) {
        XCTAssertEqual([self.valet migrateObjectsMatchingQuery:@{ (__bridge id)kSecUseOperationPrompt : @"Migration Prompt" } removeOnCompletion:NO].code, VALMigrationInvalidQueryError);
    }
#endif
}

- (void)test_migrateObjectsMatchingQueryRemoveOnCompletion_bailsOutIfConflictExistsInMigrationQueryResult;
{
    VALValet *otherValet1 = [[VALValet alloc] initWithIdentifier:@"Migrate_Me_To_Valet" accessibility:VALAccessibleAfterFirstUnlock];
    [self.additionalValets addObject:otherValet1];
    XCTAssertTrue([otherValet1 setString:self.string forKey:self.key]);
    
    VALValet *otherValet2 = [[VALTestingValet alloc] initWithIdentifier:@"Migrate_Me_To_Valet" accessibility:VALAccessibleAfterFirstUnlock];
    [self.additionalValets addObject:otherValet2];
    XCTAssertTrue([otherValet2 setString:self.string forKey:self.key]);
    
    NSDictionary *queryWithConflict = @{ (__bridge id)kSecClass : (__bridge id)kSecClassGenericPassword, (__bridge id)kSecAttrAccount : self.key };
    XCTAssertEqual([self.valet migrateObjectsMatchingQuery:queryWithConflict removeOnCompletion:NO].code, VALMigrationDuplicateKeyInQueryResultError);
}

- (void)test_migrateObjectsFromValetRemoveOnCompletion_migratesDataSuccessfullyWithoutRemovingOnCompletion;
{
    VALValet *otherValet = [[VALValet alloc] initWithIdentifier:@"Migrate_Me_To_Valet" accessibility:VALAccessibleAfterFirstUnlock];
    [self.additionalValets addObject:otherValet];
    
    NSDictionary *keyStringPairToMigrateMap = @{ @"foo" : @"bar", @"testing" : @"migration", @"is" : @"quite", @"entertaining" : @"if", @"you" : @"don't", @"screw" : @"up" };
    
    for (NSString *key in keyStringPairToMigrateMap) {
        XCTAssertTrue([otherValet setString:keyStringPairToMigrateMap[key] forKey:key]);
    }
    
    XCTAssertNil([self.valet migrateObjectsFromValet:otherValet removeOnCompletion:NO]);
    
    for (NSString *key in keyStringPairToMigrateMap) {
        XCTAssertEqualObjects([self.valet stringForKey:key], keyStringPairToMigrateMap[key]);
        XCTAssertEqualObjects([otherValet stringForKey:key], keyStringPairToMigrateMap[key]);
    }
}

- (void)test_migrateObjectsFromValetRemoveOnCompletion_migratesDataSuccessfullyWhenRemovingOnCompletion;
{
    VALValet *otherValet = [[VALValet alloc] initWithIdentifier:@"Migrate_Me_To_Valet" accessibility:VALAccessibleAfterFirstUnlock];
    [self.additionalValets addObject:otherValet];
    
    NSDictionary *keyStringPairToMigrateMap = @{ @"foo" : @"bar", @"testing" : @"migration", @"is" : @"quite", @"entertaining" : @"if", @"you" : @"don't", @"screw" : @"up" };
    
    for (NSString *key in keyStringPairToMigrateMap) {
        XCTAssertTrue([otherValet setString:keyStringPairToMigrateMap[key] forKey:key]);
    }
    
    XCTAssertNil([self.valet migrateObjectsFromValet:otherValet removeOnCompletion:YES]);
    
    for (NSString *key in keyStringPairToMigrateMap) {
        XCTAssertEqualObjects([self.valet stringForKey:key], keyStringPairToMigrateMap[key]);
        XCTAssertEqualObjects([otherValet stringForKey:key], nil);
    }
}

- (void)test_migrateObjectsFromValetRemoveOnCompletion_bailsOutAndLeavesKeychainUntouchedIfConflictExists;
{
    VALValet *otherValet = [[VALValet alloc] initWithIdentifier:@"Migrate_Me_To_Valet" accessibility:VALAccessibleAfterFirstUnlock];
    [self.additionalValets addObject:otherValet];
    
    NSDictionary *keyStringPairToMigrateMap = @{ @"foo" : @"bar", @"testing" : @"migration", @"is" : @"quite", @"entertaining" : @"if", @"you" : @"don't", @"screw" : @"up" };
    
    for (NSString *key in keyStringPairToMigrateMap) {
        XCTAssertTrue([otherValet setString:keyStringPairToMigrateMap[key] forKey:key]);
    }
    
    // Insert conflict.
    NSString *conflictKey = keyStringPairToMigrateMap.allKeys.firstObject;
    XCTAssertTrue([self.valet setString:keyStringPairToMigrateMap[conflictKey] forKey:conflictKey]);
    NSSet *allValetKeysPreMigration = self.valet.allKeys;
    
    XCTAssertEqual([self.valet migrateObjectsFromValet:otherValet removeOnCompletion:YES].code, VALMigrationKeyInQueryResultAlreadyExistsInValetError);

    XCTAssertEqualObjects(self.valet.allKeys, allValetKeysPreMigration);
    XCTAssertEqualObjects([self.valet stringForKey:conflictKey], keyStringPairToMigrateMap[conflictKey]);
    
    for (NSString *key in keyStringPairToMigrateMap) {
        XCTAssertEqualObjects([otherValet stringForKey:key], keyStringPairToMigrateMap[key]);
    }
}

- (void)test_isEqual_equivalentValetsCanAccessSameData;
{
    VALValet *otherValet = [[VALValet alloc] initWithIdentifier:self.valet.identifier accessibility:self.valet.accessibility];
    [self.additionalValets addObject:otherValet];
    XCTAssertTrue([self.valet isEqual:otherValet]);
    
    XCTAssertTrue([self.valet setString:self.string forKey:self.key]);
    XCTAssertEqualObjects([self.valet stringForKey:self.key], [otherValet stringForKey:self.key]);
}

- (void)test_isEqual_ValetsWithSameIdentifierButDifferentClassAreNotEquivalentAndCanNotAccessSameData;
{
    XCTAssertFalse([self.valet isEqual:self.testingValet]);
    
    XCTAssertTrue([self.valet setString:self.string forKey:self.key]);
    XCTAssertEqualObjects([self.valet stringForKey:self.key], self.string);
    XCTAssertNil([self.testingValet stringForKey:self.key]);
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
