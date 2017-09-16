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

#import "ValetTests.h"

// The iPhone simulator fakes entitlements, allowing us to test the iCloud Keychain (VALSynchronizableValet) and the secure enclave (VALSecureEnclaveValet) code without writing a signed host app.
#define TARGET_HAS_ENTITLEMENTS TARGET_IPHONE_SIMULATOR



@interface VALTestingValet : VALValet
@end


@implementation VALTestingValet
@end


@interface KeychainTests : XCTestCase

@property (nonatomic, readwrite) VALValet *valet;
@property (nonatomic, readwrite) VALTestingValet *testingValet;
@property (nonatomic, readwrite) VALSynchronizableValet *synchronizableValet;
#if VAL_SECURE_ENCLAVE_SDK_AVAILABLE && TARGET_HAS_ENTITLEMENTS
@property (nonatomic, readwrite) VALSecureEnclaveValet *secureEnclaveValet;
#endif
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
    
    NSString *const valetTestingIdentifier = @"valet_testing";
    self.valet = [[VALValet alloc] initWithIdentifier:valetTestingIdentifier accessibility:VALAccessibilityWhenUnlocked];
    self.testingValet = [[VALTestingValet alloc] initWithIdentifier:valetTestingIdentifier accessibility:VALAccessibilityWhenUnlocked];
    self.synchronizableValet = [[VALSynchronizableValet alloc] initWithIdentifier:valetTestingIdentifier accessibility:VALAccessibilityWhenUnlocked];
#if VAL_SECURE_ENCLAVE_SDK_AVAILABLE && TARGET_HAS_ENTITLEMENTS
    self.secureEnclaveValet = [[VALSecureEnclaveValet alloc] initWithIdentifier:valetTestingIdentifier accessControl:VALAccessControlUserPresence];
#endif
    
    // In case testing quit unexpectedly, clean up the keychain from last time.
    [self.valet removeAllObjects];
    [self.testingValet removeAllObjects];
    [self.synchronizableValet removeAllObjects];
    
    for (VALValet *const additionalValet in self.additionalValets) {
        [additionalValet removeAllObjects];
    }
    
    self.key = @"foo";
    self.string = @"bar";
    self.secondaryString = @"bar2";
    self.additionalValets = [NSMutableArray new];
}

- (void)tearDown;
{
    [super tearDown];
    
    for (VALValet *const additionalValet in self.additionalValets) {
        [additionalValet removeAllObjects];
    }
}

#pragma mark - Behavior Tests

- (void)test_initialization_twoValetsWithSameConfigurationHaveEqualPointers;
{
    // Attempting to initialize a second Valet with an equivalent configuration to one already in existance should return a shared instance.
    VALValet *otherValet = [[VALValet alloc] initWithIdentifier:self.valet.identifier accessibility:self.valet.accessibility];
    [self.additionalValets addObject:otherValet];
    
    XCTAssertEqual(self.valet, otherValet);
    XCTAssertEqualObjects(self.valet, otherValet);
    
    // This should be true for subclasses, as well.
    VALTestingValet *otherTestingValet = [[VALTestingValet alloc] initWithIdentifier:self.testingValet.identifier accessibility:self.testingValet.accessibility];
    [self.additionalValets addObject:otherTestingValet];
    
    XCTAssertEqual(self.testingValet, otherTestingValet);
    XCTAssertEqualObjects(self.testingValet, otherTestingValet);
    
    // Subclass instances should not be semantically equivalent to the parent class instances.
    XCTAssertNotEqual(self.valet, otherTestingValet);
    XCTAssertNotEqualObjects(self.valet, otherTestingValet);
}

- (void)test_initialization_invalidArgumentsCauseFailure;
{
    id nilValue = nil;
    XCTAssertNil([[VALValet alloc] initWithIdentifier:nilValue accessibility:VALAccessibilityAlways]);
    XCTAssertNil([[VALValet alloc] initWithIdentifier:@"" accessibility:VALAccessibilityAlways]);
    XCTAssertNil([[VALValet alloc] initWithIdentifier:@"test" accessibility:0]);
    XCTAssertNil([[VALSynchronizableValet alloc] initWithIdentifier:@"test" accessibility:VALAccessibilityWhenUnlockedThisDeviceOnly]);
}

- (void)test_initWithIdentifier_accessControl_isBackwardsCompatibleWithDeprecatedInitializer;
{
#if VAL_SECURE_ENCLAVE_SDK_AVAILABLE && TARGET_HAS_ENTITLEMENTS
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"
    if ([VALSecureEnclaveValet supportsSecureEnclaveKeychainItems]) {
        NSString *const valetTestingIdentifier = @"valet_backwards_compatibility_testing";
        
        VALSecureEnclaveValet *const secureEnclaveValet = [[VALSecureEnclaveValet alloc] initWithIdentifier:valetTestingIdentifier accessControl:VALAccessControlUserPresence];
        VALSecureEnclaveValet *const deprecatedSecureEnclaveValet = [[VALSecureEnclaveValet alloc] initWithIdentifier:valetTestingIdentifier];
        
        XCTAssertEqual(secureEnclaveValet, deprecatedSecureEnclaveValet);
        
        NSString *const secretDeprecatedString = @"secret deprecated string";
        NSString *const key = @"Backwards compatible key?";
        
        XCTAssertTrue([deprecatedSecureEnclaveValet setString:secretDeprecatedString forKey:key]);
        XCTAssertEqualObjects([secureEnclaveValet stringForKey:key], secretDeprecatedString);
    }
#pragma GCC diagnostic pop
#endif
}

- (void)test_initWithIdentifier_accessControl_canBeUsedTwiceWithNoSideEffects;
{
#if VAL_SECURE_ENCLAVE_SDK_AVAILABLE && TARGET_HAS_ENTITLEMENTS
    if ([VALSecureEnclaveValet supportsSecureEnclaveKeychainItems]) {
        NSString *const valetTestingIdentifier = @"valet_shared_valet_testing";
        
        VALSecureEnclaveValet *const secureEnclaveValet = [[VALSecureEnclaveValet alloc] initWithIdentifier:valetTestingIdentifier accessControl:VALAccessControlUserPresence];
        
        NSString *const secretDeprecatedString = @"secret shared string";
        NSString *const key = @"shared key?";
        
        XCTAssertTrue([secureEnclaveValet setString:secretDeprecatedString forKey:key]);
        
        VALSecureEnclaveValet *const sameSecureEnclaveValet = [[VALSecureEnclaveValet alloc] initWithIdentifier:valetTestingIdentifier accessControl:VALAccessControlUserPresence];
        
        XCTAssertEqual(secureEnclaveValet, sameSecureEnclaveValet);
        
        XCTAssertEqualObjects([sameSecureEnclaveValet stringForKey:key], secretDeprecatedString);
    }
#endif
}

- (void)test_canAccessKeychain;
{
    // Testing environments should always be able to access the keychain.
    XCTAssertTrue([self.valet canAccessKeychain]);
    
#if VAL_SECURE_ENCLAVE_SDK_AVAILABLE && TARGET_HAS_ENTITLEMENTS
    if ([VALSecureEnclaveValet supportsSecureEnclaveKeychainItems]) {
        XCTAssertTrue([self.secureEnclaveValet canAccessKeychain]);
    }
#endif
}

- (void)test_canAccessKeychain_performance;
{
    [self measureBlock:^{
        [self.valet canAccessKeychain];
    }];
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
    VALValet *otherValet = [[VALValet alloc] initWithIdentifier:[self.valet.identifier stringByAppendingString:@"_different"] accessibility:VALAccessibilityAlways];
    [self.additionalValets addObject:otherValet];
    
    NSString *string = [otherValet stringForKey:self.key];
    XCTAssertNil(string, @"Expected string with Key with different identifier to be nil but instead it was %@", string);
}

- (void)test_stringForKey_differentAccessibilityFailsToRetrieveString;
{
    XCTAssertTrue([self.valet setString:self.string forKey:self.key]);
    VALValet *otherValet = [[VALValet alloc] initWithIdentifier:self.valet.identifier accessibility:VALAccessibilityAfterFirstUnlockThisDeviceOnly];
    [self.additionalValets addObject:otherValet];
    
    NSString *string = [otherValet stringForKey:self.key];
    XCTAssertNil(string, @"Expected string with Key with different accessibility to be nil but instead it was %@", string);
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

#if TARGET_HAS_ENTITLEMENTS
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
#endif

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
    
    [self waitForExpectationsWithTimeout:10.0 handler:nil];
}

- (void)test_stringForKey_canReadDataWrittenToValetOnDifferentThread;
{
    dispatch_queue_t setStringQueue = dispatch_queue_create("Set String Queue", DISPATCH_QUEUE_CONCURRENT);
    dispatch_queue_t stringForKeyQueue = dispatch_queue_create("String For Key Queue", DISPATCH_QUEUE_CONCURRENT);
    
    XCTestExpectation *expectationStringForKeyQueue = [self expectationWithDescription:NSStringFromSelector(_cmd)];
    dispatch_async(setStringQueue, ^{
        XCTAssertTrue([self.valet setString:self.string forKey:self.key]);
        
        dispatch_async(stringForKeyQueue, ^{
            XCTAssertEqualObjects([self.valet stringForKey:self.key], self.string);
            [expectationStringForKeyQueue fulfill];
        });
    });
    
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

- (void)test_stringForKey_canReadDataWrittenToValetAllocatedOnDifferentThread;
{
    dispatch_queue_t setStringQueue = dispatch_queue_create("Set String Queue", DISPATCH_QUEUE_CONCURRENT);
    dispatch_queue_t stringForKeyQueue = dispatch_queue_create("String For Key Queue", DISPATCH_QUEUE_CONCURRENT);
    
    XCTestExpectation *expectationStringForKeyQueue = [self expectationWithDescription:NSStringFromSelector(_cmd)];
    NSString *const valetConcurrencyTestingIdentifier = @"valet_testing_concurrency";
    VALAccessibility valetConcurrencyTestingAccessibility = VALAccessibilityWhenUnlocked;
    
    dispatch_async(setStringQueue, ^{
        VALValet *setStringValet = [[VALValet alloc] initWithIdentifier:valetConcurrencyTestingIdentifier accessibility:valetConcurrencyTestingAccessibility];
        [self.additionalValets addObject:setStringValet];
        XCTAssertTrue([setStringValet setString:self.string forKey:self.key]);
        
        dispatch_async(stringForKeyQueue, ^{
            VALValet *stringForKeyValet = [[VALValet alloc] initWithIdentifier:valetConcurrencyTestingIdentifier accessibility:valetConcurrencyTestingAccessibility];
            [self.additionalValets addObject:stringForKeyValet];
            XCTAssertEqualObjects([stringForKeyValet stringForKey:self.key], self.string);
            [expectationStringForKeyQueue fulfill];
        });
    });
    
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

#if !TARGET_OS_IPHONE
- (void)test_setStringForKey_neutralizesMacOSAccessControlListVuln;
{
    // This test verifies that we are neutralizing the zero-day macOS Access Control List vulnerability published here: https://drive.google.com/file/d/0BxxXk1d3yyuZOFlsdkNMSGswSGs/view
    
    NSOperatingSystemVersion version = [NSProcessInfo processInfo].operatingSystemVersion;
    BOOL macOS1010OrLater = (version.majorVersion == 10 && version.minorVersion >= 10);
    if (!macOS1010OrLater) {
        // This test will fail before 10.10, since SecItemDelete does not actually delete keychain items that have kSecAttrAccess associated with them (bugs!). It is possible to delete the shared keychain item using SecKeychainItemDelete, but then all of Valet would need to be rewritten to support SecKeychainItemDelete on 10.9 because SecItem* and SecKeychainItem* APIs don't play nicely. So, if we're running this test on 10.9 or earlier, bail out.
        return;
    }
    
    VALValet *valet = [[VALValet alloc] initWithIdentifier:@"MacOSVulnTest" accessibility:VALAccessibilityWhenUnlocked];
    [self.additionalValets addObject:valet];
    
    NSString *const vulnKey = @"AccessControlListVulnTestKey";
    NSString *const vulnKeyValue = @"AccessControlListVulnTestValue";
    
    // Add an entry to the keychain with an access control list.
    NSMutableDictionary *query = [valet.baseQuery mutableCopy];
    [query addEntriesFromDictionary:[valet _secItemFormatDictionaryWithKey:vulnKey]];
    
    SecAccessRef accessList = NULL;
    SecTrustedApplicationRef trustedAppSelf = NULL;
    SecTrustedApplicationRef trustedAppSystemUIServer = NULL;
    XCTAssertEqual(SecTrustedApplicationCreateFromPath(NULL, &trustedAppSelf), errSecSuccess);
    XCTAssertEqual(SecTrustedApplicationCreateFromPath("/System/Library/CoreServices/SystemUIServer.app", &trustedAppSystemUIServer), errSecSuccess);
    XCTAssertEqual(SecAccessCreate((__bridge CFStringRef)@"Access Control List",
                                   (__bridge CFArrayRef)@[ (__bridge id)trustedAppSelf, (__bridge id)trustedAppSystemUIServer ],
                                   &accessList),
                   errSecSuccess);
    
    NSMutableDictionary *keychainData = [query mutableCopy];
    keychainData[(__bridge id)kSecAttrAccess] = (__bridge id)accessList;
    keychainData[(__bridge id)kSecValueData] = [vulnKeyValue dataUsingEncoding:NSUTF8StringEncoding];
    XCTAssertEqual(SecItemAdd((__bridge CFDictionaryRef)keychainData, NULL), errSecSuccess);
    
    // The potentially vulnerable keychain item should exist in our Valet now.
    XCTAssertTrue([valet containsObjectForKey:vulnKey]);
    
    // Get a reference to the vulnerable keychain entry.
    query[(__bridge id)kSecReturnRef] = @YES;
    query[(__bridge id)kSecReturnAttributes] = @YES;
    CFTypeRef referenceOutTypeRef = NULL;
    XCTAssertEqual(SecItemCopyMatching((__bridge CFDictionaryRef)query, &referenceOutTypeRef), errSecSuccess);
    NSDictionary *keychainEntryWithReference = (__bridge_transfer NSDictionary *)referenceOutTypeRef;
    
    // Show that we can access the item via the ref.
    NSDictionary *queryWithReference = @{ (__bridge id)kSecValueRef : keychainEntryWithReference[(__bridge id)kSecValueRef] };
    XCTAssertEqual(SecItemCopyMatching((__bridge CFDictionaryRef)queryWithReference, NULL), errSecSuccess);
    
    // Update the vulnerable keychain value with Valet, and see that we have deleted the existing keychain item (rather than updating it) are therefore no longer vulnerable.
    NSString *const vulnKeyOtherValue = @"AccessControlListVulnOtherTestValue";
    [valet setString:vulnKeyOtherValue forKey:vulnKey];
    
    // We can no longer access the keychain item via the ref.
    NSDictionary *queryWithReferenceAndAttributes = @{ (__bridge id)kSecValueRef : keychainEntryWithReference[(__bridge id)kSecValueRef], (__bridge id)kSecReturnAttributes : @YES };
    XCTAssertEqual(SecItemCopyMatching((__bridge CFDictionaryRef)queryWithReferenceAndAttributes, NULL), errSecItemNotFound);
    CFRelease(accessList);
    CFRelease(trustedAppSelf);
    CFRelease(trustedAppSystemUIServer);
    
    // If you add a breakpoint here and manually inspect the keychain via Keychain.app and search for MacOSVulnTest, you'll see that the Access Control for the only item matching this query has only xctest in the Access Control list. You'll see that this is not the case if you break above the line `[valet setString:vulnKeyOtherValue forKey:vulnKey];`.
}
#endif

- (void)test_containsObjectForKey_returnsYESWhenKeyExists;
{
    XCTAssertTrue([self.valet setString:self.string forKey:self.key]);
    XCTAssertTrue([self.valet containsObjectForKey:self.key]);
}

- (void)test_containsObjectForKey_returnsNOWhenKeyDoesNotExist;
{
    XCTAssertFalse([self.valet containsObjectForKey:self.key]);
}

- (void)test_allKeys_returnsEmptySetWhenNoKeysArePresent;
{
    XCTAssertNil([self.valet stringForKey:self.key]);
    XCTAssertEqual(0, [self.valet allKeys].count);
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
    
    VALValet *otherValet = [[VALValet alloc] initWithIdentifier:[self.valet.identifier stringByAppendingString:@"_different"] accessibility:VALAccessibilityAfterFirstUnlockThisDeviceOnly];
    [self.additionalValets addObject:otherValet];
    
    NSSet *allKeys = [otherValet allKeys];
    XCTAssertEqual(0, allKeys.count, @"Expected allKeys with different identifier to be an empty set but instead it was %@", allKeys);
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

#if TARGET_HAS_ENTITLEMENTS
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
#endif

- (void)test_removeObjectForKey_wrongIdentifierSucceeds;
{
    XCTAssertNil([self.valet stringForKey:self.key]);
    
    XCTAssertTrue([self.valet setString:self.string forKey:self.key]);
    
    VALValet *otherValet = [[VALValet alloc] initWithIdentifier:[self.valet.identifier stringByAppendingString:@"_different"] accessibility:VALAccessibilityAfterFirstUnlockThisDeviceOnly];
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

#if TARGET_HAS_ENTITLEMENTS
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
#endif

- (void)test_migrateObjectsMatchingQueryRemoveOnCompletion_failsIfNoItemsFoundMatchingQueryInput;
{
    NSDictionary *queryWithNoMatches = @{ (__bridge id)kSecClass : (__bridge id)kSecClassGenericPassword, (__bridge id)kSecAttrService : @"Valet_Does_Not_Exist" };
    XCTAssertEqual([self.valet migrateObjectsMatchingQuery:queryWithNoMatches removeOnCompletion:NO].code, VALMigrationErrorNoItemsToMigrateFound);
    XCTAssertEqual([self.valet migrateObjectsMatchingQuery:queryWithNoMatches removeOnCompletion:YES].code, VALMigrationErrorNoItemsToMigrateFound);
}

- (void)test_migrateObjectsMatchingQueryRemoveOnCompletion_failsIfQueryInputHasNoClass;
{
    [self.valet setString:self.string forKey:self.key];
    
    // Test that it succeeds before we test to see if it fails.
    XCTAssertNil([self.testingValet migrateObjectsMatchingQuery:self.valet.baseQuery removeOnCompletion:NO]);
    
    NSMutableDictionary *baseQueryNoClass = [self.valet.baseQuery mutableCopy];
    [baseQueryNoClass removeObjectForKey:(__bridge id)kSecClass];
    XCTAssertEqual([self.testingValet migrateObjectsMatchingQuery:baseQueryNoClass removeOnCompletion:NO].code, VALMigrationErrorInvalidQuery);
}

- (void)test_migrateObjectsMatchingQueryRemoveOnCompletion_failsOnBadQueryInput;
{
    XCTAssertEqual([self.valet migrateObjectsMatchingQuery:@{} removeOnCompletion:NO].code, VALMigrationErrorInvalidQuery);
    XCTAssertEqual([self.valet migrateObjectsMatchingQuery:@{} removeOnCompletion:YES].code, VALMigrationErrorInvalidQuery);
    
    NSDictionary *invalidQuery = @{ (__bridge id)kSecClass : (__bridge id)kSecClassGenericPassword,
                                    (__bridge id)kSecMatchLimit : (__bridge id)kSecMatchLimitOne };
    XCTAssertEqual([self.valet migrateObjectsMatchingQuery:invalidQuery removeOnCompletion:NO].code, VALMigrationErrorInvalidQuery);
    
    invalidQuery = @{ (__bridge id)kSecClass : (__bridge id)kSecClassGenericPassword,
                      (__bridge id)kSecReturnData : (__bridge id)kCFBooleanTrue };
    XCTAssertEqual([self.valet migrateObjectsMatchingQuery:invalidQuery removeOnCompletion:NO].code, VALMigrationErrorInvalidQuery);
    
    invalidQuery = @{ (__bridge id)kSecClass : (__bridge id)kSecClassGenericPassword,
                      (__bridge id)kSecReturnAttributes : (__bridge id)kCFBooleanFalse };
    XCTAssertEqual([self.valet migrateObjectsMatchingQuery:invalidQuery removeOnCompletion:NO].code, VALMigrationErrorInvalidQuery);
    
    invalidQuery = @{ (__bridge id)kSecClass : (__bridge id)kSecClassGenericPassword,
                      (__bridge id)kSecReturnRef : (__bridge id)kCFBooleanTrue };
    XCTAssertEqual([self.valet migrateObjectsMatchingQuery:invalidQuery removeOnCompletion:NO].code, VALMigrationErrorInvalidQuery);
    
    invalidQuery = @{ (__bridge id)kSecClass : (__bridge id)kSecClassGenericPassword,
                      (__bridge id)kSecReturnPersistentRef : (__bridge id)kCFBooleanFalse };
    XCTAssertEqual([self.valet migrateObjectsMatchingQuery:invalidQuery removeOnCompletion:NO].code, VALMigrationErrorInvalidQuery);
    
#if VAL_SECURE_ENCLAVE_SDK_AVAILABLE && TARGET_HAS_ENTITLEMENTS
    if ([VALSecureEnclaveValet supportsSecureEnclaveKeychainItems]) {
        invalidQuery = @{ (__bridge id)kSecClass : (__bridge id)kSecClassGenericPassword,
                          (__bridge id)kSecUseOperationPrompt : @"Migration Prompt" };
        XCTAssertEqual([self.secureEnclaveValet migrateObjectsMatchingQuery:invalidQuery removeOnCompletion:NO].code, VALMigrationErrorInvalidQuery);
    }
#endif
}

- (void)test_migrateObjectsMatchingQueryRemoveOnCompletion_bailsOutIfConflictExistsInMigrationQueryResult;
{
    VALValet *otherValet1 = [[VALValet alloc] initWithIdentifier:@"Migrate_Me_To_Valet" accessibility:VALAccessibilityAfterFirstUnlock];
    [self.additionalValets addObject:otherValet1];
    XCTAssertTrue([otherValet1 setString:self.string forKey:self.key]);
    
    VALValet *otherValet2 = [[VALTestingValet alloc] initWithIdentifier:@"Migrate_Me_To_Valet" accessibility:VALAccessibilityAfterFirstUnlock];
    [self.additionalValets addObject:otherValet2];
    XCTAssertTrue([otherValet2 setString:self.string forKey:self.key]);
    
    NSDictionary *queryWithConflict = @{ (__bridge id)kSecClass : (__bridge id)kSecClassGenericPassword, (__bridge id)kSecAttrAccount : self.key };
    XCTAssertEqual([self.valet migrateObjectsMatchingQuery:queryWithConflict removeOnCompletion:NO].code, VALMigrationErrorDuplicateKeyInQueryResult);
}

- (void)test_migrateObjectsMatchingQueryRemoveOnCompletion_withExistingAccountNameNSDataKeychainEntry_doesNotRaiseException;
{
    NSString *identifier = @"Keychain_With_Account_Name_As_NSData";

    NSData *dataBlob = [@"foo" dataUsingEncoding:NSUTF8StringEncoding];

    // kSecAttrAccount entry is expected to be a CFString, but a CFDataRef can also be stored as a value.
    NSDictionary *keychainData = @{ (__bridge id)kSecAttrService : identifier, (__bridge id)kSecClass : (__bridge id)kSecClassGenericPassword, (__bridge id)kSecAttrAccount : dataBlob, (__bridge id)kSecValueData : dataBlob };

    SecItemDelete((__bridge CFDictionaryRef)keychainData);
    OSStatus status = SecItemAdd((__bridge CFDictionaryRef)keychainData, NULL);

    XCTAssertEqual(status, errSecSuccess); // Insert Succeeded

    NSDictionary *query = @{ (__bridge id)kSecClass : (__bridge id)kSecClassGenericPassword, (__bridge id)kSecAttrService : identifier };

    NSError *error = [self.valet migrateObjectsMatchingQuery:query removeOnCompletion:NO];

# if TARGET_OS_IPHONE
    XCTAssertNil(error);
# elif TARGET_OS_MAC
    // iOS allows kSecAttrAccount NSData entries, while OSX sets the value to nil for any non-string entry.
    XCTAssertEqual(error.code, VALMigrationErrorKeyInQueryResultInvalid);
# else
    [NSException raise:@"UnsupportedOperatingSystem" format:@"Only OSX and iOS are supported"];
# endif
}

- (void)test_migrateObjectsFromValetRemoveOnCompletion_migratesSingleKeyValuePairSuccessfully;
{
    VALValet *otherValet = [[VALValet alloc] initWithIdentifier:@"Migrate_Me_To_Valet_Single_Key" accessibility:VALAccessibilityAfterFirstUnlock];
    [self.additionalValets addObject:otherValet];
    
    NSDictionary *keyStringPairToMigrateMap = @{ @"foo" : @"bar" };
    
    for (NSString *const key in keyStringPairToMigrateMap) {
        XCTAssertTrue([otherValet setString:keyStringPairToMigrateMap[key] forKey:key]);
    }
    
    XCTAssertNil([self.valet migrateObjectsFromValet:otherValet removeOnCompletion:NO]);
    
    for (NSString *const key in keyStringPairToMigrateMap) {
        XCTAssertEqualObjects([self.valet stringForKey:key], keyStringPairToMigrateMap[key]);
        XCTAssertEqualObjects([otherValet stringForKey:key], keyStringPairToMigrateMap[key]);
    }
}

- (void)test_migrateObjectsFromValetRemoveOnCompletion_migratesDataSuccessfullyWithoutRemovingOnCompletion;
{
    VALValet *otherValet = [[VALValet alloc] initWithIdentifier:@"Migrate_Me_To_Valet" accessibility:VALAccessibilityAfterFirstUnlock];
    [self.additionalValets addObject:otherValet];
    
    NSDictionary *keyStringPairToMigrateMap = @{ @"foo" : @"bar", @"testing" : @"migration", @"is" : @"quite", @"entertaining" : @"if", @"you" : @"don't", @"screw" : @"up" };
    
    for (NSString *const key in keyStringPairToMigrateMap) {
        XCTAssertTrue([otherValet setString:keyStringPairToMigrateMap[key] forKey:key]);
    }
    
    XCTAssertNil([self.valet migrateObjectsFromValet:otherValet removeOnCompletion:NO]);
    
    for (NSString *const key in keyStringPairToMigrateMap) {
        XCTAssertEqualObjects([self.valet stringForKey:key], keyStringPairToMigrateMap[key]);
        XCTAssertEqualObjects([otherValet stringForKey:key], keyStringPairToMigrateMap[key]);
    }
}

- (void)test_migrateObjectsFromValetRemoveOnCompletion_migratesDataSuccessfullyWhenRemovingOnCompletion;
{
    VALValet *const otherValet = [[VALValet alloc] initWithIdentifier:@"Migrate_Me_To_Valet" accessibility:VALAccessibilityAfterFirstUnlock];
    [self.additionalValets addObject:otherValet];
    
    NSDictionary *const keyStringPairToMigrateMap = @{ @"foo" : @"bar", @"testing" : @"migration", @"is" : @"quite", @"entertaining" : @"if", @"you" : @"don't", @"screw" : @"up" };
    
    for (NSString *const key in keyStringPairToMigrateMap) {
        XCTAssertTrue([otherValet setString:keyStringPairToMigrateMap[key] forKey:key]);
    }
    
    XCTAssertNil([self.valet migrateObjectsFromValet:otherValet removeOnCompletion:YES]);
    
    for (NSString *const key in keyStringPairToMigrateMap) {
        XCTAssertEqualObjects([self.valet stringForKey:key], keyStringPairToMigrateMap[key]);
        XCTAssertEqualObjects([otherValet stringForKey:key], nil);
    }
}

- (void)test_migrateObjectsFromValetRemoveOnCompletion_bailsOutAndLeavesKeychainUntouchedIfConflictExists;
{
    VALValet *const otherValet = [[VALValet alloc] initWithIdentifier:@"Migrate_Me_To_Valet" accessibility:VALAccessibilityAfterFirstUnlock];
    [self.additionalValets addObject:otherValet];
    
    NSDictionary *const keyStringPairToMigrateMap = @{ @"foo" : @"bar", @"testing" : @"migration", @"is" : @"quite", @"entertaining" : @"if", @"you" : @"don't", @"screw" : @"up" };
    
    for (NSString *const key in keyStringPairToMigrateMap) {
        XCTAssertTrue([otherValet setString:keyStringPairToMigrateMap[key] forKey:key]);
    }
    
    // Insert conflict.
    NSString *const conflictKey = keyStringPairToMigrateMap.allKeys.firstObject;
    XCTAssertTrue([self.valet setString:keyStringPairToMigrateMap[conflictKey] forKey:conflictKey]);
    NSSet *const allValetKeysPreMigration = self.valet.allKeys;
    
    XCTAssertEqual([self.valet migrateObjectsFromValet:otherValet removeOnCompletion:YES].code, VALMigrationErrorKeyInQueryResultAlreadyExistsInValet);
    
    XCTAssertEqualObjects(self.valet.allKeys, allValetKeysPreMigration);
    XCTAssertEqualObjects([self.valet stringForKey:conflictKey], keyStringPairToMigrateMap[conflictKey]);
    
    for (NSString *const key in keyStringPairToMigrateMap) {
        XCTAssertEqualObjects([otherValet stringForKey:key], keyStringPairToMigrateMap[key]);
    }
}

- (void)test_migrateObjectsFromValetRemoveOnCompletion_migratesDataSuccessfullyWhenBothValetsHavePreviouslyCalled_canAccessKeychain;
{
    VALValet *otherValet = [[VALValet alloc] initWithIdentifier:@"Migrate_Me_To_Valet" accessibility:VALAccessibilityAfterFirstUnlock];
    [self.additionalValets addObject:otherValet];
    
    NSDictionary *keyStringPairToMigrateMap = @{ @"foo" : @"bar", @"testing" : @"migration", @"is" : @"quite", @"entertaining" : @"if", @"you" : @"don't", @"screw" : @"up" };
    
    for (NSString *const key in keyStringPairToMigrateMap) {
        XCTAssertTrue([otherValet setString:keyStringPairToMigrateMap[key] forKey:key]);
    }
    
    XCTAssertTrue([self.valet canAccessKeychain]);
    XCTAssertTrue([otherValet canAccessKeychain]);
    XCTAssertNil([self.valet migrateObjectsFromValet:otherValet removeOnCompletion:NO]);
    
    for (NSString *const key in keyStringPairToMigrateMap) {
        XCTAssertEqualObjects([self.valet stringForKey:key], keyStringPairToMigrateMap[key]);
        XCTAssertEqualObjects([otherValet stringForKey:key], keyStringPairToMigrateMap[key]);
    }
}

#if VAL_SECURE_ENCLAVE_SDK_AVAILABLE && TARGET_HAS_ENTITLEMENTS
- (void)test_migrateObjectsFromValetRemoveOnCompletion_migratesDataSuccessfullyWhenMigratingToSecureEnclave;
{
    if ([VALSecureEnclaveValet supportsSecureEnclaveKeychainItems]) {
        VALValet *const otherValet = [[VALValet alloc] initWithIdentifier:@"Migrate_Me_To_Valet" accessibility:VALAccessibilityAfterFirstUnlock];
        [self.additionalValets addObject:otherValet];
        
        NSDictionary *const keyStringPairToMigrateMap = @{ @"foo" : @"bar", @"testing" : @"migration", @"is" : @"quite", @"entertaining" : @"if", @"you" : @"don't", @"screw" : @"up" };
        
        for (NSString *const key in keyStringPairToMigrateMap) {
            XCTAssertTrue([otherValet setString:keyStringPairToMigrateMap[key] forKey:key]);
        }
        
        for (NSString *const key in keyStringPairToMigrateMap) {
            XCTAssertFalse([self.secureEnclaveValet containsObjectForKey:key]);
        }
        
        XCTAssertNil([self.secureEnclaveValet migrateObjectsFromValet:otherValet removeOnCompletion:NO]);
        
        for (NSString *const key in keyStringPairToMigrateMap) {
            XCTAssertTrue([self.secureEnclaveValet containsObjectForKey:key]);
        }
        
        // Clean up items for next test run since Secure Enclave Valet does not support allKeys or removeAllObjects.
        for (NSString *const key in keyStringPairToMigrateMap) {
            XCTAssertTrue([self.secureEnclaveValet removeObjectForKey:key]);
        }
    }
}
#endif

- (void)test_isEqual_equivalentValetsCanAccessSameData;
{
    VALValet *const otherValet = [[VALValet alloc] initWithIdentifier:self.valet.identifier accessibility:self.valet.accessibility];
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
    NSDictionary *const secItemDictionary = [self.valet _secItemFormatDictionaryWithKey:self.key];
    XCTAssertEqualObjects(secItemDictionary[(__bridge id)kSecAttrAccount], self.key);
}

@end
