//
//  ValetTests.swift
//  Valet
//
//  Created by Eric Muller on 4/25/16.
//  Copyright © 2016 Square, Inc.
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

import Foundation
import XCTest


extension NSError
{
    // The NSError.code -> VALMigrationError conversion is gross right now:
    var valetMigrationError: VALMigrationError { return VALMigrationError(rawValue: UInt(code))! }
}


class TestValet: VALValet {}


class ValetTests: XCTestCase
{
    static let identifier = "valet_testing"
    let valet = VALValet(identifier: identifier, accessibility: .WhenUnlocked)!
    let subclassValet = TestValet(identifier: identifier, accessibility: .WhenUnlocked)!
    let key = "key"
    let passcode = "topsecret"

    // MARK: XCTestCase

    override func setUp()
    {
        super.setUp()
        valet.removeAllObjects()
        subclassValet.removeAllObjects()
    }

    // MARK: Equality

    func test_valetsWithSameConfiguration_areEqual()
    {
        let otherValet = VALValet(identifier: ValetTests.identifier, accessibility: .WhenUnlocked)
        XCTAssertTrue(otherValet == valet)
        XCTAssertTrue(otherValet === valet)
    }

    func test_differingSubclassesWithEquivalentConfiguration_areNotEqual()
    {
        XCTAssertFalse(valet == subclassValet)
        XCTAssertFalse(valet === subclassValet)
    }

    func test_equivalentSubclassesWithEquivalentConfiguration_areEqual()
    {
        let secondSubclassValet = TestValet(identifier: ValetTests.identifier, accessibility: .WhenUnlocked)
        XCTAssertTrue(subclassValet == secondSubclassValet)
        XCTAssertTrue(subclassValet === secondSubclassValet)
    }

    func test_valetsWithDifferingIdentifier_areNotEqual()
    {
        let differingIdentifier = VALValet(identifier: "nope", accessibility: valet.accessibility)!
        XCTAssertNotEqual(valet, differingIdentifier)
    }

    func test_valetsWithDifferingAccessibility_areNotEqual()
    {
        let differingAccessibility = VALValet(identifier: valet.identifier, accessibility: .Always)!
        XCTAssertNotEqual(valet, differingAccessibility)
    }

    // MARK: canAccessKeychain

    func test_canAccessKeychain()
    {
        XCTAssertTrue(valet.canAccessKeychain())
    }

    func test_canAccessKeychain_Performance()
    {
        measureBlock {
            self.valet.canAccessKeychain()
        }
    }

    // MARK: containsObjectForKey

    func test_containsObjectForKey()
    {
        XCTAssertFalse(valet.containsObjectForKey(key))

        XCTAssertTrue(valet.setString(passcode, forKey: key))
        XCTAssertTrue(valet.containsObjectForKey(key))

        XCTAssertTrue(valet.removeObjectForKey(key))
        XCTAssertFalse(valet.containsObjectForKey(key))
    }

    // MARK: allKeys

    func test_allKeys()
    {
        XCTAssertEqual(valet.allKeys(), Set())

        XCTAssertTrue(valet.setString(passcode, forKey: key))
        XCTAssertEqual(valet.allKeys(), Set(arrayLiteral: key))

        XCTAssertTrue(valet.setString("monster", forKey: "cookie"))
        XCTAssertEqual(valet.allKeys(), Set(arrayLiteral: key, "cookie"))

        valet.removeAllObjects()
        XCTAssertEqual(valet.allKeys(), Set())
    }

    func test_allKeys_remainsUntouchedForUnequalValets()
    {
        valet.setString(passcode, forKey: key)
        XCTAssertEqual(valet.allKeys(), Set(arrayLiteral: key))

        // Different Identifier
        let differingIdentifier = VALValet(identifier: "nope", accessibility: valet.accessibility)!
        XCTAssertEqual(differingIdentifier.allKeys(), Set())

        // Different Accessibility
        let differingAccessibility = VALValet(identifier: valet.identifier, accessibility: .Always)!
        XCTAssertEqual(differingAccessibility.allKeys(), Set())

        // Different Class
        XCTAssertEqual(subclassValet.allKeys(), Set())
    }

    // MARK: stringForKey / setStringForKey

    func test_stringForKey_isNilForInvalidKey()
    {
        XCTAssertNil(valet.stringForKey(key))
    }

    func test_stringForKey_retrievesStringForValidKey()
    {
        XCTAssertTrue(valet.setString(passcode, forKey: key))
        XCTAssertEqual(passcode, valet.stringForKey(key))
    }

    func test_stringForKey_equivalentValetsCanAccessSameData()
    {
        let equalValet = VALValet(identifier: valet.identifier, accessibility: valet.accessibility)!
        XCTAssertEqual(0, equalValet.allKeys().count)
        XCTAssertEqual(valet, equalValet)
        XCTAssertTrue(valet.setString("monster", forKey: "cookie"))
        XCTAssertEqual("monster", equalValet.stringForKey("cookie"))
    }

    func test_stringForKey_withDifferingIdentifier_isNil()
    {
        XCTAssertTrue(valet.setString(passcode, forKey: key))

        let differingIdentifier = VALValet(identifier: "wat", accessibility: valet.accessibility)!
        XCTAssertNil(differingIdentifier.stringForKey(key))
    }

    func test_stringForKey_withDifferingAccessibility_isNil()
    {
        XCTAssertTrue(valet.setString(passcode, forKey: key))

        let differingAccessibility = VALValet(identifier: valet.identifier, accessibility: .AfterFirstUnlockThisDeviceOnly)!
        XCTAssertNil(differingAccessibility.stringForKey(key))
    }

    func test_stringForKey_withEquivalentConfigurationButDifferingSubclass_isNil()
    {
        XCTAssertTrue(valet.setString("monster", forKey: "cookie"))
        XCTAssertNil(subclassValet.stringForKey("cookie"))
    }

    func test_setStringForKey_successfullyUpdatesExistingKey()
    {
        XCTAssertNil(valet.stringForKey(key))
        valet.setString("1", forKey: key)
        XCTAssertEqual("1", valet.stringForKey(key))
        valet.setString("2", forKey: key)
        XCTAssertEqual("2", valet.stringForKey(key))
    }

    // MARK: Concurrency

    func test_concurrentSetAndRemoveOperations()
    {
        let setQueue = dispatch_queue_create("Set String Queue", DISPATCH_QUEUE_CONCURRENT)
        let removeQueue = dispatch_queue_create("Remove Object Queue", DISPATCH_QUEUE_CONCURRENT)

        for _ in 1...50 {
            dispatch_async(setQueue, { XCTAssertTrue(self.valet.setString(self.passcode, forKey: self.key)) })
            dispatch_async(removeQueue, { XCTAssertTrue(self.valet.removeObjectForKey(self.key)) })
        }

        let setQueueExpectation = expectationWithDescription("\(#function): Set String Queue")
        let removeQueueExpectation = expectationWithDescription("\(#function): Remove String Queue")

        dispatch_barrier_async(setQueue, { setQueueExpectation.fulfill() })
        dispatch_barrier_async(removeQueue, { removeQueueExpectation.fulfill() })

        waitForExpectationsWithTimeout(5.0, handler: nil)
    }

    func test_stringForKey_canReadDataWrittenOnAnotherThread()
    {
        let setStringQueue = dispatch_queue_create("Set String Queue", DISPATCH_QUEUE_CONCURRENT)
        let stringForKeyQueue = dispatch_queue_create("String For Key Queue", DISPATCH_QUEUE_CONCURRENT)

        let expectation = expectationWithDescription(#function)

        dispatch_async(setStringQueue) {
            XCTAssertTrue(self.valet.setString(self.passcode, forKey: self.key))
            dispatch_async(stringForKeyQueue, { 
                XCTAssertEqual(self.valet.stringForKey(self.key), self.passcode)
                expectation.fulfill()
            })
        }

        waitForExpectationsWithTimeout(5.0, handler: nil)
    }

    func test_stringForKey_canReadDataWrittenToValetAllocatedOnDifferentThread()
    {
        let setStringQueue = dispatch_queue_create("Set String Queue", DISPATCH_QUEUE_CONCURRENT)
        let stringForKeyQueue = dispatch_queue_create("String For Key Queue", DISPATCH_QUEUE_CONCURRENT)

        let backgroundIdentifier = "valet_background_testing"
        let expectation = expectationWithDescription(#function)

        dispatch_async(setStringQueue) {
            let backgroundValet = VALValet(identifier: backgroundIdentifier, accessibility: .WhenUnlocked)!
            XCTAssertTrue(backgroundValet.setString(self.passcode, forKey: self.key))
            dispatch_async(stringForKeyQueue, {
                XCTAssertEqual(backgroundValet.stringForKey(self.key), self.passcode)
                expectation.fulfill()
            })
        }

        waitForExpectationsWithTimeout(5.0, handler: nil)
    }

    // MARK: Removal

    func test_removeObjectForKey_succeedsWhenKeyIsNotPresent()
    {
        XCTAssertTrue(valet.removeObjectForKey("derp"))
    }

    func test_removeObjectForKey_succeedsWhenKeyIsPresent()
    {
        XCTAssertTrue(valet.setString(passcode, forKey: key))
        XCTAssertTrue(valet.removeObjectForKey(key))
        XCTAssertNil(valet.stringForKey(key))
    }

    func test_removeObjectForKey_isDistinctForDifferingAccessibility()
    {
        let differingAccessibility = VALValet(identifier: valet.identifier, accessibility: .Always)!
        XCTAssertTrue(valet.setString(passcode, forKey: key))

        XCTAssertTrue(differingAccessibility.removeObjectForKey(key))

        XCTAssertEqual(passcode, valet.stringForKey(key))
    }

    func test_removeObjectForKey_isDistinctForDifferingIdentifier()
    {
        let differingIdentifier = VALValet(identifier: "no", accessibility: valet.accessibility)!
        XCTAssertTrue(valet.setString(passcode, forKey: key))

        XCTAssertTrue(differingIdentifier.removeObjectForKey(key))

        XCTAssertEqual(passcode, valet.stringForKey(key))
    }

    func test_removeObjectForKey_isDistinctForDifferingClasses()
    {
        XCTAssertTrue(valet.setString(passcode, forKey: key))
        XCTAssertTrue(subclassValet.setString(passcode, forKey: key))

        XCTAssertTrue(valet.removeObjectForKey(key))

        XCTAssertNil(valet.stringForKey(key))
        XCTAssertEqual(passcode, subclassValet.stringForKey(key))
    }

    // MARK: Migration - Query

    func test_migrateObjectsMatchingQuery_failsIfNoItemsMatchQuery()
    {
        let noItemsFoundError = VALMigrationError.NoItemsToMigrateFound

        let queryWithNoMatches = [
            kSecClass as String: kSecClassGenericPassword as String,
            kSecAttrService as String: "Valet_Does_Not_Exist"
        ]

        XCTAssertEqual(noItemsFoundError, valet.migrateObjectsMatchingQuery(queryWithNoMatches, removeOnCompletion: false)?.valetMigrationError)
        XCTAssertEqual(noItemsFoundError, valet.migrateObjectsMatchingQuery(queryWithNoMatches, removeOnCompletion: true)?.valetMigrationError)

        // Our test Valet has not yet been written to, migration should fail:
        XCTAssertEqual(noItemsFoundError, subclassValet.migrateObjectsMatchingQuery(valet.baseQuery, removeOnCompletion: false)?.valetMigrationError)
        XCTAssertEqual(noItemsFoundError, subclassValet.migrateObjectsMatchingQuery(valet.baseQuery, removeOnCompletion: true)?.valetMigrationError)
    }

    func test_migrateObjectsMatchingQuery_failsIfQueryHasNoInputClass()
    {
        valet.setString(passcode, forKey: key)

        // Test for base query success.
        XCTAssertNil(subclassValet.migrateObjectsMatchingQuery(valet.baseQuery, removeOnCompletion: false))
        XCTAssertEqual(passcode, subclassValet.stringForKey(key))

        var mutableQuery = valet.baseQuery
        mutableQuery.removeValueForKey(kSecClass as String)

        // Without a kSecClass, the migration should fail.
        XCTAssertEqual(VALMigrationError.InvalidQuery, subclassValet.migrateObjectsMatchingQuery(mutableQuery, removeOnCompletion: false)?.valetMigrationError)
    }

    func test_migrateObjectsMatchingQuery_failsForBadQueries()
    {
        let invalidQueryError = VALMigrationError.InvalidQuery

        XCTAssertEqual(invalidQueryError, valet.migrateObjectsMatchingQuery([:], removeOnCompletion: false)?.valetMigrationError)
        XCTAssertEqual(invalidQueryError, valet.migrateObjectsMatchingQuery([:], removeOnCompletion: true)?.valetMigrationError)

        var invalidQuery: [String: AnyObject] = [
            kSecClass as String: kSecClassGenericPassword as String,
            kSecMatchLimit as String: kSecMatchLimitOne as String
        ]
        // Migration queries should have kSecMatchLimit set to .All
        XCTAssertEqual(invalidQueryError, valet.migrateObjectsMatchingQuery(invalidQuery, removeOnCompletion: false)?.valetMigrationError)

        invalidQuery = [
            kSecClass as String: kSecClassGenericPassword as String,
            kSecReturnData as String: kCFBooleanTrue as AnyObject
        ]
        // Migration queries do not support kSecReturnData
        XCTAssertEqual(invalidQueryError, valet.migrateObjectsMatchingQuery(invalidQuery, removeOnCompletion: false)?.valetMigrationError)

        invalidQuery = [
            kSecClass as String: kSecClassGenericPassword as String,
            kSecReturnRef as String: kCFBooleanTrue as AnyObject
        ]
        // Migration queries do not support kSecReturnRef
        XCTAssertEqual(invalidQueryError, valet.migrateObjectsMatchingQuery(invalidQuery, removeOnCompletion: false)?.valetMigrationError)

        invalidQuery = [
            kSecClass as String: kSecClassGenericPassword as String,
            kSecReturnPersistentRef as String: kCFBooleanFalse as AnyObject
        ]
        // Migration queries must have kSecReturnPersistentRef set to true
        XCTAssertEqual(invalidQueryError, valet.migrateObjectsMatchingQuery(invalidQuery, removeOnCompletion: false)?.valetMigrationError)


        invalidQuery = [
            kSecClass as String: kSecClassGenericPassword as String,
            kSecReturnAttributes as String: kCFBooleanFalse as AnyObject
        ]
        // Migration queries must have kSecReturnAttributes set to true
        XCTAssertEqual(invalidQueryError, valet.migrateObjectsMatchingQuery(invalidQuery, removeOnCompletion: false)?.valetMigrationError)
    }

    func test_migrateObjectsMatchingQuery_bailsOutIfConflictExistsInQueryResult()
    {
        let migrationValet = VALValet(identifier: "Migrate_Me", accessibility: .AfterFirstUnlock)!

        XCTAssertTrue(valet.setString(passcode, forKey: key))
        XCTAssertTrue(subclassValet.setString(passcode, forKey:key))

        let conflictingQuery = [
            kSecClass as String: kSecClassGenericPassword as String,
            kSecAttrAccount as String: key
        ]

        XCTAssertEqual(VALMigrationError.DuplicateKeyInQueryResult, migrationValet.migrateObjectsMatchingQuery(conflictingQuery, removeOnCompletion: false)?.valetMigrationError)
    }

    // MARK: Migration - Valet

    func test_migrateObjectsFromValet_migratesSingleKeyValuePairSuccessfully()
    {
        subclassValet.setString("foo", forKey: "bar")
        valet.migrateObjectsFromValet(subclassValet, removeOnCompletion: false)
        XCTAssertEqual("foo", valet.stringForKey("bar"))
    }

    func test_migrateObjectsFromValet_migratesMultipleKeyValuePairsSuccessfully()
    {
        let keyValuePairs = [
            "yo": "dawg",
            "we": "heard",
            "you": "like",
            "migrating": "to",
            "other": "valets"
        ]

        for (key, value) in keyValuePairs {
            subclassValet.setString(value, forKey: key)
        }

        XCTAssertNil(valet .migrateObjectsFromValet(subclassValet, removeOnCompletion: false))

        // Both the migration target and the previous Valet should hold all key/value pairs.
        XCTAssertEqual(valet.allKeys(), subclassValet.allKeys())
        for (key, value) in keyValuePairs {
            XCTAssertEqual(valet.stringForKey(key), value)
            XCTAssertEqual(subclassValet.stringForKey(key), value)
        }
    }

    func test_migrateObjectsFromValet_removesOnCompletionWhenRequested()
    {
        let keyValuePairs = [
            "yo": "dawg",
            "we": "heard",
            "you": "like",
            "migrating": "to",
            "other": "valets"
        ]

        for (key, value) in keyValuePairs {
            subclassValet.setString(value, forKey: key)
        }

        XCTAssertNil(valet .migrateObjectsFromValet(subclassValet, removeOnCompletion: true))

        // The migration target should hold all key/value pairs, the previous Valet should be empty.
        XCTAssertEqual(0, subclassValet.allKeys().count)
        for (key, value) in keyValuePairs {
            XCTAssertEqual(valet.stringForKey(key), value)
            XCTAssertNil(subclassValet.stringForKey(key))
        }
    }

    func test_migrateObjectsFromValet_leavesKeychainUntouchedWhenConflictsExist()
    {
        let keyValuePairs = [
            "yo": "dawg",
            "we": "heard",
            "you": "like",
            "migrating": "to",
            "other": "valets"
        ]

        for (key, value) in keyValuePairs {
            subclassValet.setString(value, forKey: key)
        }

        valet.setString("adrian", forKey: "yo")

        XCTAssertEqual(1, valet.allKeys().count)
        XCTAssertEqual(keyValuePairs.count, subclassValet.allKeys().count)

        XCTAssertEqual(VALMigrationError.KeyInQueryResultAlreadyExistsInValet, valet.migrateObjectsFromValet(subclassValet, removeOnCompletion: true)?.valetMigrationError)

        // Neither Valet should have seen any changes.
        XCTAssertEqual("adrian", valet.stringForKey("yo"))
        for (key, value) in keyValuePairs {
            XCTAssertEqual(subclassValet.stringForKey(key), value)
        }
    }
}


@available (iOS 8, OSX 10.11, *)
class ValetSecureEnclaveTests: XCTestCase
{
    static let identifier = "valet_testing"
    let valet = VALSecureEnclaveValet(identifier: identifier, accessControl: .UserPresence)!
    let key = "key"
    let passcode = "topsecret"

    override func setUp()
    {
        super.setUp()
        valet.removeObjectForKey(key)
    }

    // MARK: Equality

    func test_secureEnclaveValetsWithEqualConfiguration_haveEqualPointers()
    {
        if VALSecureEnclaveValet.supportsSecureEnclaveKeychainItems() {
            let equivalentValet = VALSecureEnclaveValet(identifier: valet.identifier, accessControl: valet.accessControl)!
            XCTAssertTrue(valet == equivalentValet)
            XCTAssertTrue(valet === equivalentValet)
        }
    }

    func test_secureEnclaveValetsWithEqualConfiguration_canAccessSameData()
    {
        if VALSecureEnclaveValet.supportsSecureEnclaveKeychainItems() {
            XCTAssertTrue(valet.setString(passcode, forKey: key))
            let equivalentValet = VALSecureEnclaveValet(identifier: valet.identifier, accessControl: valet.accessControl)!
            XCTAssertEqual(valet, equivalentValet)
            XCTAssertEqual(passcode, equivalentValet.stringForKey(key, userPrompt: ""))
        }
    }

    func test_secureEnclaveValetsWithDifferingAccessControl_canNotAccessSameData()
    {
        if VALSecureEnclaveValet.supportsSecureEnclaveKeychainItems() {
            XCTAssertTrue(valet.setString(passcode, forKey: key))
            let equivalentValet = VALSecureEnclaveValet(identifier: valet.identifier, accessControl: .DevicePasscode)!
            XCTAssertNotEqual(valet, equivalentValet)
            XCTAssertEqual(passcode, valet.stringForKey(key, userPrompt: ""))
            XCTAssertNil(equivalentValet.stringForKey(key, userPrompt: ""))
        }
    }

    @available (*, deprecated)
    func test_secureEnclaveValet_backwardsCompatibility()
    {
        if VALSecureEnclaveValet.supportsSecureEnclaveKeychainItems() {
            let deprecatedValet = VALSecureEnclaveValet(identifier: valet.identifier)!
            XCTAssertEqual(valet, deprecatedValet)
            XCTAssertTrue(deprecatedValet.setString(passcode, forKey: key))
            XCTAssertEqual(passcode, valet.stringForKey(key, userPrompt: ""))
        }
    }

    // MARK: canAccessKeychain

    func test_canAccessKeychain()
    {
        if VALSecureEnclaveValet.supportsSecureEnclaveKeychainItems() {
            XCTAssertTrue(valet.canAccessKeychain())
        }
    }

    // MARK: Migration

    func test_migrateObjectsMatchingQuery_failsForBadQuery()
    {
        if VALSecureEnclaveValet.supportsSecureEnclaveKeychainItems() {
            let invalidQuery = [
                kSecClass as String: kSecClassGenericPassword as String,
                kSecUseOperationPrompt as String: "Migration Prompt"
            ]
            XCTAssertEqual(VALMigrationError.InvalidQuery, valet.migrateObjectsMatchingQuery(invalidQuery, removeOnCompletion: false)?.valetMigrationError)
        }
    }

    func test_migrateObjectsFromValet_migratesSuccessfullyToSecureEnclave()
    {
        if VALSecureEnclaveValet.supportsSecureEnclaveKeychainItems() {
            let keyValuePairs = [
                "yo": "dawg",
                "we": "heard",
                "you": "like",
                "migrating": "to",
                "other": "valets"
            ]

            let plainOldValet = VALValet(identifier: "Migrate_Me", accessibility: .AfterFirstUnlock)!

            for (key, value) in keyValuePairs {
                plainOldValet.setString(value, forKey: key)
            }

            XCTAssertNil(valet.migrateObjectsFromValet(plainOldValet, removeOnCompletion: true))

            for (key, value) in keyValuePairs {
                XCTAssertEqual(value, valet.stringForKey(key))
                XCTAssertNil(plainOldValet.stringForKey(key))
            }

            // Clean up items for the next test run (allKeys and removeAllObjects are unsupported in VALSecureEnclaveValet.
            for key in keyValuePairs.keys {
                XCTAssertTrue(valet.removeObjectForKey(key))
            }
        }
    }

    // MARK: Protected Methods

    func test_secItemFormatDictionaryWithKey()
    {
        let secItemDictionary = valet._secItemFormatDictionaryWithKey(key)
        XCTAssertEqual(key, secItemDictionary[kSecAttrAccount] as? String)
    }
}


// The iPhone simulator fakes entitlements, allowing us to test the iCloud Keychain (VALSynchronizableValet) code without writing a signed host app.
#if (arch(i386) || arch(x86_64)) && os(iOS)

@available (iOS 8.2, OSX 10.11, *)
class ValetSynchronizableTests: XCTestCase
{
    static let identifier = "valet_testing"
    let valet = VALSynchronizableValet(identifier: identifier, accessibility: .WhenUnlocked)!
    let key = "key"
    let passcode = "topsecret"

    override func setUp()
    {
        super.setUp()
        valet.removeAllObjects()
    }

    func test_initializers_withDeviceScopeAreUnsupported()
    {
        XCTAssertNil(VALSynchronizableValet(identifier: valet.identifier, accessibility: .WhenUnlockedThisDeviceOnly))
        XCTAssertNil(VALSynchronizableValet(identifier: valet.identifier, accessibility: .AfterFirstUnlockThisDeviceOnly))
        XCTAssertNil(VALSynchronizableValet(identifier: valet.identifier, accessibility: .WhenPasscodeSetThisDeviceOnly))
        XCTAssertNil(VALSynchronizableValet(identifier: valet.identifier, accessibility: .AlwaysThisDeviceOnly))
    }

    func test_synchronizableValet_isDistinctFromVanillaValetWithEqualConfiguration()
    {
        let localValet = VALValet(identifier: valet.identifier, accessibility: valet.accessibility)!
        XCTAssertFalse(valet == localValet)
        XCTAssertFalse(valet === localValet)

        XCTAssertTrue(valet.setString("butts", forKey: "cloud"))
        XCTAssertEqual("butts", valet.stringForKey("cloud"))
        XCTAssertNil(localValet.stringForKey("cloud"))
    }

    func test_setStringForKey()
    {
        XCTAssertNil(valet.stringForKey(key))
        XCTAssertTrue(valet.setString(passcode, forKey: key))
        XCTAssertEqual(passcode, valet.stringForKey(key))
    }

    func test_removeObjectForKey()
    {
        XCTAssertTrue(valet.setString(passcode, forKey:key))
        XCTAssertEqual(passcode, valet.stringForKey(key))

        XCTAssertTrue(valet.removeObjectForKey(key))
        XCTAssertNil(valet.stringForKey(key))
    }
}

#endif


#if os(OSX)

class ValetMacTests: XCTestCase
{
    // This test verifies that we are neutralizing the zero-day Mac OS X Access Control List vulnerability.
    // Whitepaper: https://drive.google.com/file/d/0BxxXk1d3yyuZOFlsdkNMSGswSGs/view
    // Square Corner blog post: https://corner.squareup.com/2015/06/valet-beats-the-ox-x-keychain-access-control-list-zero-day-vulnerability.html
    @available (OSX 10.10, *)
    func test_setStringForKey_neutralizesMacOSAccessControlListVuln()
    {
        let valet = VALValet(identifier: "MacOSVulnTest", accessibility: .WhenUnlocked)!
        let vulnKey = "KeepIt"
        let vulnValue = "Secret"

        var query = valet.baseQuery

        for (key, value) in valet._secItemFormatDictionaryWithKey(vulnKey) {
            query[key] = value
        }

        var accessList: SecAccessRef?
        var trustedAppSelf: SecTrustedApplicationRef?
        var trustedAppSystemUIServer: SecTrustedApplicationRef?

        XCTAssertEqual(SecTrustedApplicationCreateFromPath(nil, &trustedAppSelf), errSecSuccess)
        XCTAssertEqual(SecTrustedApplicationCreateFromPath("/System/Library/CoreServices/SystemUIServer.app", &trustedAppSystemUIServer), errSecSuccess);
        let trustedList = [trustedAppSelf!, trustedAppSystemUIServer!] as NSArray?

        // Add an entry to the keychain with an access control list.
        XCTAssertEqual(SecAccessCreate("Access Control List", trustedList, &accessList), errSecSuccess)
        var accessListQuery = query
        accessListQuery[kSecAttrAccess] = accessList
        accessListQuery[kSecValueData] = vulnValue.dataUsingEncoding(NSUTF8StringEncoding)
        XCTAssertEqual(SecItemAdd(accessListQuery, nil), errSecSuccess)

        // The potentially vulnerable keychain item should exist in our Valet now.
        XCTAssertTrue(valet.containsObjectForKey(vulnKey))

        // Obtain a reference to the vulnerable keychain entry.
        query[kSecReturnRef] = true
        query[kSecReturnAttributes] = true
        var vulnerableEntryReference: CFTypeRef?
        XCTAssertEqual(SecItemCopyMatching(query, &vulnerableEntryReference), errSecSuccess)

        guard let vulnerableKeychainEntry = vulnerableEntryReference as! NSDictionary? else {
            XCTFail()
            return
        }
        guard let vulnerableValueRef = vulnerableKeychainEntry[kSecValueRef as String] else {
            XCTFail()
            return
        }

        let queryWithVulnerableReference = [
            kSecValueRef as String: vulnerableValueRef
        ]
        // Demonstrate that the item is accessible with the reference.
        XCTAssertEqual(SecItemCopyMatching(queryWithVulnerableReference, nil), errSecSuccess)

        // Update the vulnerable value with Valet - we should have deleted the existing item, making the entry no longer vulnerable.
        let updatedValue = "Safe"
        XCTAssertTrue(valet.setString(updatedValue, forKey: vulnKey))

        // We should no longer be able to access the keychain item via the ref.
        let queryWithVulnerableReferenceAndAttributes = [
            kSecValueRef as String: vulnerableValueRef,
            kSecReturnAttributes as String: true
        ]
        XCTAssertEqual(SecItemCopyMatching(queryWithVulnerableReferenceAndAttributes, nil), errSecItemNotFound)

        // If you add a breakpoint here then manually inspect the keychain via Keychain.app (search for "MacOSVulnTest"), "xctest" should be the only member of the Access Control list.
        // This is not be the case upon setting a breakpoint and inspecting before the valet.setString(, forKey:) call above.
    }
}

#endif
