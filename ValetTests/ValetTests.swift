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


extension VALValet: KeychainQueryConvertible {
    public var keychainQuery: [String : AnyHashable] {
        return keychainQuery as! [String : AnyHashable]
    }
}


class ValetTests: XCTestCase
{
    static let identifier = Identifier(nonEmpty: "valet_testing")!
//    let valet = Valet.valet(with: identifier, accessibility: .whenUnlocked)!
    let valet = Valet.valet(with: identifier, accessibility: .whenUnlocked)
    let otherValet = Valet.valet(with: Identifier(nonEmpty: "valet_testing_2")!, accessibility: .whenUnlocked)
    let key = "key"
    let passcode = "topsecret"

    // MARK: XCTestCase

    override func setUp()
    {
        super.setUp()
        valet.removeAllObjects()
        XCTAssert(valet.allKeys().isEmpty)
        otherValet.removeAllObjects()
    }

    // MARK: Equality

    func test_valetsWithSameConfiguration_areEqual()
    {
        let otherValet = Valet.valet(with: ValetTests.identifier, accessibility: .whenUnlocked)
        XCTAssertTrue(otherValet == valet)
        XCTAssertTrue(otherValet === valet)
    }

    func test_differingSubclassesWithEquivalentConfiguration_areNotEqual()
    {
        XCTAssertFalse(valet == otherValet)
        XCTAssertFalse(valet === otherValet)
    }

    func test_equivalentSubclassesWithEquivalentConfiguration_areEqual()
    {
        let secondOtherValet = Valet.valet(with: ValetTests.identifier, accessibility: .whenUnlocked)
        XCTAssertTrue(otherValet == secondOtherValet)
        XCTAssertTrue(otherValet === secondOtherValet)
    }

    func test_valetsWithDifferingIdentifier_areNotEqual()
    {
        let differingIdentifier = Valet.valet(with: Identifier(nonEmpty: "nope")!, accessibility: valet.accessibility)
        XCTAssertNotEqual(valet, differingIdentifier)
    }

    func test_valetsWithDifferingAccessibility_areNotEqual()
    {
        let differingAccessibility = Valet.valet(with: valet.identifier, accessibility: .always)
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
        XCTAssertFalse(valet.containsObject(for: key))

        XCTAssertTrue(valet.set(string: passcode, for: key))
        XCTAssertTrue(valet.containsObject(for: key))

        XCTAssertTrue(valet.removeObject(for: key))
        XCTAssertFalse(valet.containsObject(for: key))
    }

    // MARK: allKeys

    func test_allKeys()
    {
        XCTAssertEqual(valet.allKeys(), Set())

        XCTAssertTrue(valet.set(string: passcode, for: key))
        XCTAssertEqual(valet.allKeys(), Set(arrayLiteral: key))

        XCTAssertTrue(valet.set(string: "monster", for: "cookie"))
        XCTAssertEqual(valet.allKeys(), Set(arrayLiteral: key, "cookie"))

        valet.removeAllObjects()
        XCTAssertEqual(valet.allKeys(), Set())
    }

    func test_allKeys_remainsUntouchedForUnequalValets()
    {
        valet.set(string: passcode, for: key)
        XCTAssertEqual(valet.allKeys(), Set(arrayLiteral: key))

        // Different Identifier
        let differingIdentifier = Valet.valet(with: Identifier(nonEmpty: "nope")!, accessibility: valet.accessibility)
        XCTAssertEqual(differingIdentifier.allKeys(), Set())

        // Different Accessibility
        let differingAccessibility = Valet.valet(with: valet.identifier, accessibility: .always)
        XCTAssertEqual(differingAccessibility.allKeys(), Set())

        // Different Class
        XCTAssertEqual(otherValet.allKeys(), Set())
    }

    // MARK: stringForKey / setStringForKey

    func test_stringForKey_isNilForInvalidKey()
    {
        XCTAssertNil(valet.string(for: key))
    }

    func test_stringForKey_retrievesStringForValidKey()
    {
        XCTAssertTrue(valet.set(string: passcode, for: key))
        XCTAssertEqual(passcode, valet.string(for: key))
    }

    func test_stringForKey_equivalentValetsCanAccessSameData()
    {
        let equalValet = Valet.valet(with: valet.identifier, accessibility: valet.accessibility)
        XCTAssertEqual(0, equalValet.allKeys().count)
        XCTAssertEqual(valet, equalValet)
        XCTAssertTrue(valet.set(string: "monster", for: "cookie"))
        XCTAssertEqual("monster", equalValet.string(for: "cookie"))
    }

    func test_stringForKey_withDifferingIdentifier_isNil()
    {
        XCTAssertTrue(valet.set(string: passcode, for: key))
        XCTAssertEqual(passcode, valet.string(for: key))
        
        let differingIdentifier = Valet.valet(with: Identifier(nonEmpty: "wat")!, accessibility: valet.accessibility)
        XCTAssertNil(differingIdentifier.string(for: key))
    }

    func test_stringForKey_withDifferingAccessibility_isNil()
    {
        XCTAssertTrue(valet.set(string: passcode, for: key))
        XCTAssertEqual(passcode, valet.string(for: key))
        
        let differingAccessibility = Valet.valet(with: valet.identifier, accessibility: .afterFirstUnlockThisDeviceOnly)
        XCTAssertNil(differingAccessibility.string(for: key))
    }

    func test_stringForKey_withEquivalentConfigurationButDifferingSubclass_isNil()
    {
        XCTAssertTrue(valet.set(string: "monster", for: "cookie"))
        XCTAssertEqual("monster", valet.string(for: "cookie"))

        XCTAssertNil(otherValet.string(for: "cookie"))
    }

    func test_setStringForKey_successfullyUpdatesExistingKey()
    {
        XCTAssertNil(valet.string(for: key))
        valet.set(string: "1", for: key)
        XCTAssertEqual("1", valet.string(for: key))
        valet.set(string: "2", for: key)
        XCTAssertEqual("2", valet.string(for: key))
    }

    // MARK: Concurrency

    func test_concurrentSetAndRemoveOperations()
    {
        let setQueue = DispatchQueue(label: "Set String Queue", attributes: .concurrent)
        let removeQueue = DispatchQueue(label: "Remove Object Queue", attributes: .concurrent)

        for _ in 1...50 {
            setQueue.async { XCTAssertTrue(self.valet.set(string: self.passcode, for: self.key)) }
            removeQueue.async { XCTAssertTrue(self.valet.removeObject(for: self.key)) }
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
            XCTAssertTrue(self.valet.set(string: self.passcode, for: self.key))
            stringForKeyQueue.async {
                XCTAssertEqual(self.valet.string(for: self.key), self.passcode)
                expectation.fulfill()
            }
        }

        waitForExpectations(timeout: 5.0, handler: nil)
    }

    func test_stringForKey_canReadDataWrittenToValetAllocatedOnDifferentThread()
    {
        let setStringQueue = DispatchQueue(label: "Set String Queue", attributes: .concurrent)
        let stringForKeyQueue = DispatchQueue(label: "String For Key Queue", attributes: .concurrent)

        let backgroundIdentifier = Identifier(nonEmpty: "valet_background_testing")!
        let expectation = self.expectation(description: #function)

        setStringQueue.async {
            let backgroundValet = Valet.valet(with: backgroundIdentifier, accessibility: .whenUnlocked)
            XCTAssertTrue(backgroundValet.set(string: self.passcode, for: self.key))
            stringForKeyQueue.async {
                XCTAssertEqual(backgroundValet.string(for: self.key), self.passcode)
                expectation.fulfill()
            }
        }

        waitForExpectations(timeout: 5.0, handler: nil)
    }

    // MARK: Removal

    func test_removeObjectForKey_succeedsWhenKeyIsNotPresent()
    {
        XCTAssertTrue(valet.removeObject(for: "derp"))
    }

    func test_removeObjectForKey_succeedsWhenKeyIsPresent()
    {
        XCTAssertTrue(valet.set(string: passcode, for: key))
        XCTAssertTrue(valet.removeObject(for: key))
        XCTAssertNil(valet.string(for: key))
    }

    func test_removeObjectForKey_isDistinctForDifferingAccessibility()
    {
        let differingAccessibility = Valet.valet(with: valet.identifier, accessibility: .always)
        XCTAssertTrue(valet.set(string: passcode, for: key))

        XCTAssertTrue(differingAccessibility.removeObject(for: key))

        XCTAssertEqual(passcode, valet.string(for: key))
    }

    func test_removeObjectForKey_isDistinctForDifferingIdentifier()
    {
        let differingIdentifier = Valet.valet(with: Identifier(nonEmpty: "no")!, accessibility: valet.accessibility)
        XCTAssertTrue(valet.set(string: passcode, for: key))

        XCTAssertTrue(differingIdentifier.removeObject(for: key))

        XCTAssertEqual(passcode, valet.string(for: key))
    }

    func test_removeObjectForKey_isDistinctForDifferingClasses()
    {
        XCTAssertTrue(valet.set(string: passcode, for: key))
        XCTAssertTrue(otherValet.set(string: passcode, for: key))

        XCTAssertTrue(valet.removeObject(for: key))

        XCTAssertNil(valet.string(for: key))
        XCTAssertEqual(passcode, otherValet.string(for: key))
    }

    // MARK: Migration - Query

    func test_migrateObjectsmatching_failsIfNoItemsMatchQuery()
    {
        let noItemsFoundError = MigrationResult.noItemsToMigrateFound

        let queryWithNoMatches = [
            kSecClass as String: kSecClassGenericPassword as String,
            kSecAttrService as String: "Valet_Does_Not_Exist"
        ]

        XCTAssertEqual(noItemsFoundError, valet.migrateObjects(matching: queryWithNoMatches, removeOnCompletion: false))
        XCTAssertEqual(noItemsFoundError, valet.migrateObjects(matching: queryWithNoMatches, removeOnCompletion: true))

        // Our test Valet has not yet been written to, migration should fail:
        XCTAssertEqual(noItemsFoundError, otherValet.migrateObjects(matching: valet.keychainQuery, removeOnCompletion: false))
        XCTAssertEqual(noItemsFoundError, otherValet.migrateObjects(matching: valet.keychainQuery, removeOnCompletion: true))
    }

    func test_migrateObjectsmatching_failsIfQueryHasNoInputClass()
    {
        valet.set(string: passcode, for: key)

        // Test for base query success.
        XCTAssertNil(otherValet.migrateObjects(matching: valet.keychainQuery, removeOnCompletion: false))
        XCTAssertEqual(passcode, otherValet.string(for: key))

        var mutableQuery = valet.keychainQuery
        mutableQuery.removeValue(forKey: kSecClass as String)

        // Without a kSecClass, the migration should fail.
        XCTAssertEqual(MigrationResult.invalidQuery, otherValet.migrateObjects(matching: mutableQuery, removeOnCompletion: false))
    }

    func test_migrateObjectsmatching_failsForBadQueries()
    {
        let invalidQueryError = MigrationResult.invalidQuery

        XCTAssertEqual(invalidQueryError, valet.migrateObjects(matching: [:], removeOnCompletion: false))
        XCTAssertEqual(invalidQueryError, valet.migrateObjects(matching: [:], removeOnCompletion: true))

        var invalidQuery: [String: AnyHashable] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        // Migration queries should have kSecMatchLimit set to .All
        XCTAssertEqual(invalidQueryError, valet.migrateObjects(matching: invalidQuery, removeOnCompletion: false))

        invalidQuery = [
            kSecClass as String: kSecClassGenericPassword,
            kSecReturnData as String: kCFBooleanTrue
        ]
        // Migration queries do not support kSecReturnData
        XCTAssertEqual(invalidQueryError, valet.migrateObjects(matching: invalidQuery, removeOnCompletion: false))

        invalidQuery = [
            kSecClass as String: kSecClassGenericPassword,
            kSecReturnRef as String: kCFBooleanTrue
        ]
        // Migration queries do not support kSecReturnRef
        XCTAssertEqual(invalidQueryError, valet.migrateObjects(matching: invalidQuery, removeOnCompletion: false))

        invalidQuery = [
            kSecClass as String: kSecClassGenericPassword,
            kSecReturnPersistentRef as String: kCFBooleanFalse
        ]
        // Migration queries must have kSecReturnPersistentRef set to true
        XCTAssertEqual(invalidQueryError, valet.migrateObjects(matching: invalidQuery, removeOnCompletion: false))


        invalidQuery = [
            kSecClass as String: kSecClassGenericPassword,
            kSecReturnAttributes as String: kCFBooleanFalse
        ]
        // Migration queries must have kSecReturnAttributes set to true
        XCTAssertEqual(invalidQueryError, valet.migrateObjects(matching: invalidQuery, removeOnCompletion: false))
        
        invalidQuery = [
            kSecClass as String: kSecClassGenericPassword,
            kSecUseOperationPrompt as String: "This should fail"
        ]
        // Migration queries must not have kSecUseOperationPrompt set
        XCTAssertEqual(invalidQueryError, valet.migrateObjects(matching: invalidQuery, removeOnCompletion: false))
        
    }

    func test_migrateObjectsmatching_bailsOutIfConflictExistsInQueryResult()
    {
        let migrationValet = Valet.valet(with: Identifier(nonEmpty: "Migrate_Me")!, accessibility: .afterFirstUnlock)

        XCTAssertTrue(valet.set(string: passcode, for: key))
        XCTAssertTrue(otherValet.set(string: passcode, for:key))

        let conflictingQuery = [
            kSecClass as String: kSecClassGenericPassword as String,
            kSecAttrAccount as String: key
        ]

        XCTAssertEqual(MigrationResult.duplicateKeyInQueryResult, migrationValet.migrateObjects(matching: conflictingQuery, removeOnCompletion: false))
    }

    func test_migrateObjectsmatching_withAccountNameAsData_doesNotRaiseException()
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
        let error = valet.migrateObjects(matching: query, removeOnCompletion: false)
        
        #if os(iOS)
            XCTAssertNil(error)
        #elseif os(macOS)
            XCTAssertEqual(error, .keyInQueryResultInvalid)
        #else
            XCTFail("Unsupported/undefined OS")
        #endif
        
    }
    
    // MARK: Migration - Valet

    func test_migrateObjectsFromValet_migratesSingleKeyValuePairSuccessfully()
    {
        otherValet.set(string: "foo", for: "bar")
        valet.migrateObjects(from: otherValet, removeOnCompletion: false)
        valet.allKeys()
        XCTAssertEqual("foo", valet.string(for: "bar"))
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
            otherValet.set(string: value, for: key)
        }

        XCTAssertNil(valet .migrateObjects(from: otherValet, removeOnCompletion: false))

        // Both the migration target and the previous Valet should hold all key/value pairs.
        XCTAssertEqual(valet.allKeys(), otherValet.allKeys())
        for (key, value) in keyValuePairs {
            XCTAssertEqual(valet.string(for: key), value)
            XCTAssertEqual(otherValet.string(for: key), value)
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
            otherValet.set(string: value, for: key)
        }

        XCTAssertNil(valet .migrateObjects(from: otherValet, removeOnCompletion: true))

        // The migration target should hold all key/value pairs, the previous Valet should be empty.
        XCTAssertEqual(0, otherValet.allKeys().count)
        for (key, value) in keyValuePairs {
            XCTAssertEqual(valet.string(for: key), value)
            XCTAssertNil(otherValet.string(for: key))
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
            otherValet.set(string: value, for: key)
        }

        valet.set(string: "adrian", for: "yo")

        XCTAssertEqual(1, valet.allKeys().count)
        XCTAssertEqual(keyValuePairs.count, otherValet.allKeys().count)

        XCTAssertEqual(.keyInQueryResultAlreadyExistsInValet, valet.migrateObjects(from: otherValet, removeOnCompletion: true))

        // Neither Valet should have seen any changes.
        XCTAssertEqual("adrian", valet.string(for: "yo"))
        for (key, value) in keyValuePairs {
            XCTAssertEqual(otherValet.string(for: key), value)
        }
    }

    func test_migrateObjectsFromValetRemoveOnCompletion_migratesDataSuccessfullyWhenBothValetsHavePreviouslyCalled_canAccessKeychain() {
        let otherValet = Valet.valet(with: Identifier(nonEmpty: "Migrate_Me_To_Valet")!, accessibility: .afterFirstUnlock)

        // Clean up any dangling keychain items before we start this tests.
        otherValet.removeAllObjects()

        let keyStringPairToMigrateMap = ["foo" : "bar", "testing" : "migration", "is" : "quite", "entertaining" : "if", "you" : "don't", "screw" : "up"]
        for (key, value) in keyStringPairToMigrateMap {
            XCTAssertTrue(otherValet.set(string: value, for: key))
        }

        XCTAssertTrue(valet.canAccessKeychain())
        XCTAssertTrue(otherValet.canAccessKeychain())
        XCTAssertNil(valet.migrateObjects(from: otherValet, removeOnCompletion: false))

        for (key, value) in keyStringPairToMigrateMap {
            XCTAssertEqual(valet.string(for: key), value)
            XCTAssertEqual(otherValet.string(for: key), value)
        }
    }
}
