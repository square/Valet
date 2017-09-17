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
import Valet
import XCTest


extension Error
{
    // The Error.code -> VALMigrationError conversion is gross right now:
    var valetMigrationError: VALMigrationError { return VALMigrationError(rawValue: UInt((self as NSError).code))! }
}


class TestValet: VALValet {}


class ValetTests: XCTestCase
{
    static let identifier = "valet_testing"
    let valet = VALValet(identifier: identifier, accessibility: .whenUnlocked)!
    let subclassValet = TestValet(identifier: identifier, accessibility: .whenUnlocked)!
    let key = "key"
    let passcode = "topsecret"

    // MARK: XCTestCase

    override func setUp()
    {
        super.setUp()
        let baseQuery: [String : AnyHashable] = valet.baseQuery as! [String: AnyHashable]
        valet.removeAllObjects()
        XCTAssert(valet.allKeys().isEmpty)
        subclassValet.removeAllObjects()
    }

    // MARK: Equality

    func test_valetsWithSameConfiguration_areEqual()
    {
        let otherValet = VALValet(identifier: ValetTests.identifier, accessibility: .whenUnlocked)
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
        let secondSubclassValet = TestValet(identifier: ValetTests.identifier, accessibility: .whenUnlocked)
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
        let differingAccessibility = VALValet(identifier: valet.identifier, accessibility: .always)!
        XCTAssertNotEqual(valet, differingAccessibility)
    }

    // MARK: canAccessKeychain

    func test_canAccessKeychain()
    {
        XCTAssertTrue(valet.canAccessKeychain())
    }

    func test_canAccessKeychain_Performance()
    {
        measure {
            self.valet.canAccessKeychain()
        }
    }

    // MARK: containsObjectForKey

    func test_containsObjectForKey()
    {
        XCTAssertFalse(valet.containsObject(forKey: key))

        XCTAssertTrue(valet.setString(passcode, forKey: key))
        XCTAssertTrue(valet.containsObject(forKey: key))

        XCTAssertTrue(valet.removeObject(forKey: key))
        XCTAssertFalse(valet.containsObject(forKey: key))
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
        let differingAccessibility = VALValet(identifier: valet.identifier, accessibility: .always)!
        XCTAssertEqual(differingAccessibility.allKeys(), Set())

        // Different Class
        XCTAssertEqual(subclassValet.allKeys(), Set())
    }

    // MARK: stringForKey / setStringForKey

    func test_stringForKey_isNilForInvalidKey()
    {
        XCTAssertNil(valet.string(forKey: key))
    }

    func test_stringForKey_retrievesStringForValidKey()
    {
        XCTAssertTrue(valet.setString(passcode, forKey: key))
        XCTAssertEqual(passcode, valet.string(forKey: key))
    }

    func test_stringForKey_equivalentValetsCanAccessSameData()
    {
        let equalValet = VALValet(identifier: valet.identifier, accessibility: valet.accessibility)!
        XCTAssertEqual(0, equalValet.allKeys().count)
        XCTAssertEqual(valet, equalValet)
        XCTAssertTrue(valet.setString("monster", forKey: "cookie"))
        XCTAssertEqual("monster", equalValet.string(forKey: "cookie"))
    }

    func test_stringForKey_withDifferingIdentifier_isNil()
    {
        XCTAssertTrue(valet.setString(passcode, forKey: key))
        XCTAssertEqual(passcode, valet.string(forKey: key))
        
        let differingIdentifier = VALValet(identifier: "wat", accessibility: valet.accessibility)!
        XCTAssertNil(differingIdentifier.string(forKey: key))
    }

    func test_stringForKey_withDifferingAccessibility_isNil()
    {
        XCTAssertTrue(valet.setString(passcode, forKey: key))
        XCTAssertEqual(passcode, valet.string(forKey: key))
        
        let differingAccessibility = VALValet(identifier: valet.identifier, accessibility: .afterFirstUnlockThisDeviceOnly)!
        XCTAssertNil(differingAccessibility.string(forKey: key))
    }

    func test_stringForKey_withEquivalentConfigurationButDifferingSubclass_isNil()
    {
        XCTAssertTrue(valet.setString("monster", forKey: "cookie"))
        XCTAssertEqual("monster", valet.string(forKey: "cookie"))

        XCTAssertNil(subclassValet.string(forKey: "cookie"))
    }

    func test_setStringForKey_successfullyUpdatesExistingKey()
    {
        XCTAssertNil(valet.string(forKey: key))
        valet.setString("1", forKey: key)
        XCTAssertEqual("1", valet.string(forKey: key))
        valet.setString("2", forKey: key)
        XCTAssertEqual("2", valet.string(forKey: key))
    }

    // MARK: Concurrency

    func test_concurrentSetAndRemoveOperations()
    {
        let setQueue = DispatchQueue(label: "Set String Queue", attributes: .concurrent)
        let removeQueue = DispatchQueue(label: "Remove Object Queue", attributes: .concurrent)

        for _ in 1...50 {
            setQueue.async { XCTAssertTrue(self.valet.setString(self.passcode, forKey: self.key)) }
            removeQueue.async { XCTAssertTrue(self.valet.removeObject(forKey: self.key)) }
        }
        
        let setQueueExpectation = expectation(description: "\(#function): Set String Queue")
        let removeQueueExpectation = expectation(description: "\(#function): Remove String Queue")
        
        setQueue.async(flags: .barrier) {
            setQueueExpectation.fulfill()
        }
        removeQueue.async(flags: .barrier) {
            removeQueueExpectation.fulfill()
        }
        
        waitForExpectations(timeout: 5.0, handler: nil)
    }

    func test_stringForKey_canReadDataWrittenOnAnotherThread()
    {
        let setStringQueue = DispatchQueue(label: "Set String Queue", attributes: .concurrent)
        let stringForKeyQueue = DispatchQueue(label: "String For Key Queue", attributes: .concurrent)

        let expectation = self.expectation(description: #function)

        setStringQueue.async {
            XCTAssertTrue(self.valet.setString(self.passcode, forKey: self.key))
            stringForKeyQueue.async {
                XCTAssertEqual(self.valet.string(forKey: self.key), self.passcode)
                expectation.fulfill()
            }
        }

        waitForExpectations(timeout: 5.0, handler: nil)
    }

    func test_stringForKey_canReadDataWrittenToValetAllocatedOnDifferentThread()
    {
        let setStringQueue = DispatchQueue(label: "Set String Queue", attributes: .concurrent)
        let stringForKeyQueue = DispatchQueue(label: "String For Key Queue", attributes: .concurrent)

        let backgroundIdentifier = "valet_background_testing"
        let expectation = self.expectation(description: #function)

        setStringQueue.async {
            let backgroundValet = VALValet(identifier: backgroundIdentifier, accessibility: .whenUnlocked)!
            XCTAssertTrue(backgroundValet.setString(self.passcode, forKey: self.key))
            stringForKeyQueue.async {
                XCTAssertEqual(backgroundValet.string(forKey: self.key), self.passcode)
                expectation.fulfill()
            }
        }

        waitForExpectations(timeout: 5.0, handler: nil)
    }

    // MARK: Removal

    func test_removeObjectForKey_succeedsWhenKeyIsNotPresent()
    {
        XCTAssertTrue(valet.removeObject(forKey: "derp"))
    }

    func test_removeObjectForKey_succeedsWhenKeyIsPresent()
    {
        XCTAssertTrue(valet.setString(passcode, forKey: key))
        XCTAssertTrue(valet.removeObject(forKey: key))
        XCTAssertNil(valet.string(forKey: key))
    }

    func test_removeObjectForKey_isDistinctForDifferingAccessibility()
    {
        let differingAccessibility = VALValet(identifier: valet.identifier, accessibility: .always)!
        XCTAssertTrue(valet.setString(passcode, forKey: key))

        XCTAssertTrue(differingAccessibility.removeObject(forKey: key))

        XCTAssertEqual(passcode, valet.string(forKey: key))
    }

    func test_removeObjectForKey_isDistinctForDifferingIdentifier()
    {
        let differingIdentifier = VALValet(identifier: "no", accessibility: valet.accessibility)!
        XCTAssertTrue(valet.setString(passcode, forKey: key))

        XCTAssertTrue(differingIdentifier.removeObject(forKey: key))

        XCTAssertEqual(passcode, valet.string(forKey: key))
    }

    func test_removeObjectForKey_isDistinctForDifferingClasses()
    {
        XCTAssertTrue(valet.setString(passcode, forKey: key))
        XCTAssertTrue(subclassValet.setString(passcode, forKey: key))

        XCTAssertTrue(valet.removeObject(forKey: key))

        XCTAssertNil(valet.string(forKey: key))
        XCTAssertEqual(passcode, subclassValet.string(forKey: key))
    }

    // MARK: Migration - Query

    func test_migrateObjectsMatchingQuery_failsIfNoItemsMatchQuery()
    {
        let noItemsFoundError = VALMigrationError.noItemsToMigrateFound

        let queryWithNoMatches = [
            kSecClass as String: kSecClassGenericPassword as String,
            kSecAttrService as String: "Valet_Does_Not_Exist"
        ]

        XCTAssertEqual(noItemsFoundError, valet.migrateObjects(matchingQuery: queryWithNoMatches, removeOnCompletion: false)?.valetMigrationError)
        XCTAssertEqual(noItemsFoundError, valet.migrateObjects(matchingQuery: queryWithNoMatches, removeOnCompletion: true)?.valetMigrationError)

        // Our test Valet has not yet been written to, migration should fail:
        XCTAssertEqual(noItemsFoundError, subclassValet.migrateObjects(matchingQuery: valet.baseQuery, removeOnCompletion: false)?.valetMigrationError)
        XCTAssertEqual(noItemsFoundError, subclassValet.migrateObjects(matchingQuery: valet.baseQuery, removeOnCompletion: true)?.valetMigrationError)
    }

    func test_migrateObjectsMatchingQuery_failsIfQueryHasNoInputClass()
    {
        valet.setString(passcode, forKey: key)

        // Test for base query success.
        XCTAssertNil(subclassValet.migrateObjects(matchingQuery: valet.baseQuery, removeOnCompletion: false))
        XCTAssertEqual(passcode, subclassValet.string(forKey: key))

        var mutableQuery = valet.baseQuery
        mutableQuery.removeValue(forKey: kSecClass as AnyHashable)

        // Without a kSecClass, the migration should fail.
        XCTAssertEqual(VALMigrationError.invalidQuery, subclassValet.migrateObjects(matchingQuery: mutableQuery, removeOnCompletion: false)?.valetMigrationError)
    }

    func test_migrateObjectsMatchingQuery_failsForBadQueries()
    {
        let invalidQueryError = VALMigrationError.invalidQuery

        XCTAssertEqual(invalidQueryError, valet.migrateObjects(matchingQuery: [:], removeOnCompletion: false)?.valetMigrationError)
        XCTAssertEqual(invalidQueryError, valet.migrateObjects(matchingQuery: [:], removeOnCompletion: true)?.valetMigrationError)

        var invalidQuery: [String: AnyHashable] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        // Migration queries should have kSecMatchLimit set to .All
        XCTAssertEqual(invalidQueryError, valet.migrateObjects(matchingQuery: invalidQuery, removeOnCompletion: false)?.valetMigrationError)

        invalidQuery = [
            kSecClass as String: kSecClassGenericPassword,
            kSecReturnData as String: kCFBooleanTrue
        ]
        // Migration queries do not support kSecReturnData
        XCTAssertEqual(invalidQueryError, valet.migrateObjects(matchingQuery: invalidQuery, removeOnCompletion: false)?.valetMigrationError)

        invalidQuery = [
            kSecClass as String: kSecClassGenericPassword,
            kSecReturnRef as String: kCFBooleanTrue
        ]
        // Migration queries do not support kSecReturnRef
        XCTAssertEqual(invalidQueryError, valet.migrateObjects(matchingQuery: invalidQuery, removeOnCompletion: false)?.valetMigrationError)

        invalidQuery = [
            kSecClass as String: kSecClassGenericPassword,
            kSecReturnPersistentRef as String: kCFBooleanFalse
        ]
        // Migration queries must have kSecReturnPersistentRef set to true
        XCTAssertEqual(invalidQueryError, valet.migrateObjects(matchingQuery: invalidQuery, removeOnCompletion: false)?.valetMigrationError)


        invalidQuery = [
            kSecClass as String: kSecClassGenericPassword,
            kSecReturnAttributes as String: kCFBooleanFalse
        ]
        // Migration queries must have kSecReturnAttributes set to true
        XCTAssertEqual(invalidQueryError, valet.migrateObjects(matchingQuery: invalidQuery, removeOnCompletion: false)?.valetMigrationError)
    }

    func test_migrateObjectsMatchingQuery_bailsOutIfConflictExistsInQueryResult()
    {
        let migrationValet = VALValet(identifier: "Migrate_Me", accessibility: .afterFirstUnlock)!

        XCTAssertTrue(valet.setString(passcode, forKey: key))
        XCTAssertTrue(subclassValet.setString(passcode, forKey:key))

        let conflictingQuery = [
            kSecClass as String: kSecClassGenericPassword as String,
            kSecAttrAccount as String: key
        ]

        XCTAssertEqual(VALMigrationError.duplicateKeyInQueryResult, migrationValet.migrateObjects(matchingQuery: conflictingQuery, removeOnCompletion: false)?.valetMigrationError)
    }

    func test_migrateObjectsMatchingQuery_withAccountNameAsData_doesNotRaiseException()
    {
        let identifier = "Keychain_With_Account_Name_As_NSData"
        guard let dataBlob = "foo".data(using: .utf8) else {
            XCTFail()
            return
        }
        
        // kSecAttrAccount entry is expected to be a CFString, but a CFDataRef can also be stored as a value.
        let keychainData = [
            kSecAttrService: identifier,
            kSecClass : kSecClassGenericPassword,
            kSecAttrAccount: dataBlob,
            kSecValueData: dataBlob
            ] as CFDictionary
        
        SecItemDelete(keychainData)
        let status = SecItemAdd(keychainData, nil)
        XCTAssertEqual(status, errSecSuccess)
        
        let query: [String : AnyHashable] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: identifier
        ]
        let error = valet.migrateObjects(matchingQuery: query, removeOnCompletion: false)
        
        #if os(iOS)
            XCTAssertNil(error)
        #elseif os(macOS)
            XCTAssertEqual(error?.valetMigrationError, .keyInQueryResultInvalid)
        #else
            XCTFail("Unsupported/undefined OS")
        #endif
        
    }
    
    // MARK: Migration - Valet

    func test_migrateObjectsFromValet_migratesSingleKeyValuePairSuccessfully()
    {
        subclassValet.setString("foo", forKey: "bar")
        valet.migrateObjects(from: subclassValet, removeOnCompletion: false)
        XCTAssertEqual("foo", valet.string(forKey: "bar"))
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

        XCTAssertNil(valet .migrateObjects(from: subclassValet, removeOnCompletion: false))

        // Both the migration target and the previous Valet should hold all key/value pairs.
        XCTAssertEqual(valet.allKeys(), subclassValet.allKeys())
        for (key, value) in keyValuePairs {
            XCTAssertEqual(valet.string(forKey: key), value)
            XCTAssertEqual(subclassValet.string(forKey: key), value)
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

        XCTAssertNil(valet .migrateObjects(from: subclassValet, removeOnCompletion: true))

        // The migration target should hold all key/value pairs, the previous Valet should be empty.
        XCTAssertEqual(0, subclassValet.allKeys().count)
        for (key, value) in keyValuePairs {
            XCTAssertEqual(valet.string(forKey: key), value)
            XCTAssertNil(subclassValet.string(forKey: key))
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

        XCTAssertEqual(VALMigrationError.keyInQueryResultAlreadyExistsInValet, valet.migrateObjects(from: subclassValet, removeOnCompletion: true)?.valetMigrationError)

        // Neither Valet should have seen any changes.
        XCTAssertEqual("adrian", valet.string(forKey: "yo"))
        for (key, value) in keyValuePairs {
            XCTAssertEqual(subclassValet.string(forKey: key), value)
        }
    }

    func test_migrateObjectsFromValetRemoveOnCompletion_migratesDataSuccessfullyWhenBothValetsHavePreviouslyCalled_canAccessKeychain() {
        let otherValet = VALValet(identifier: "Migrate_Me_To_Valet", accessibility: .afterFirstUnlock)!

        // Clean up any dangling keychain items before we start this tests.
        otherValet.removeAllObjects()

        let keyStringPairToMigrateMap = ["foo" : "bar", "testing" : "migration", "is" : "quite", "entertaining" : "if", "you" : "don't", "screw" : "up"]
        for (key, value) in keyStringPairToMigrateMap {
            XCTAssertTrue(otherValet.setString(value, forKey: key))
        }

        XCTAssertTrue(valet.canAccessKeychain())
        XCTAssertTrue(otherValet.canAccessKeychain())
        XCTAssertNil(valet.migrateObjects(from: otherValet, removeOnCompletion: false))

        for (key, value) in keyStringPairToMigrateMap {
            XCTAssertEqual(valet.string(forKey: key), value)
            XCTAssertEqual(otherValet.string(forKey: key), value)
        }
    }
}
