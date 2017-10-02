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
@testable import Valet
import XCTest


/// - returns: `true` when the test environment is signed.
/// - The Valet Mac Tests target is left without a host app on master. Mac test host app signing requires CI to have the Developer team credentials down in keychain, which we can't easily accomplish.
/// - note: In order to test changes locally, set the Valet Mac Tests host to Valet macOS Test Host App, delete all VAL_* keychain items in your keychain via Keychain Access.app, and run Mac tests.
func testEnvironmentIsSigned() -> Bool {
    // Our test host apps for iOS and Mac are both signed, so testing for a bundle identifier is analogous to testing signing.
    guard Bundle.main.bundleIdentifier != nil else {
        #if os(iOS)
            XCTFail("iOS test bundle should be signed")
        #endif
        
        return false
    }
    
    return true
}


class ValetTests: XCTestCase
{
    static let identifier = Identifier(nonEmpty: "valet_testing")!
    static let accessibility = Accessibility.whenUnlocked
    let valet = Valet.valet(with: identifier, flavor: .vanilla(accessibility))
    
    // FIXME: Need a different flavor (Synchronizable can't be tested on Mac currently
    let anotherFlavor = Valet.valet(with: identifier, flavor: .iCloud(.whenUnlocked))

    let key = "key"
    let passcode = "topsecret"
    lazy var passcodeData: Data = { return self.passcode.data(using: .utf8)! }()
    
    // MARK: XCTestCase

    override func setUp()
    {
        super.setUp()
        
        ErrorHandler.customAssertBody = { _, _, _, _ in
            // Nothing to do here.
        }
        
        valet.removeAllObjects()
        anotherFlavor.removeAllObjects()
        XCTAssert(valet.allKeys().isEmpty)
        XCTAssert(anotherFlavor.allKeys().isEmpty)
    }

    // MARK: Equality

    func test_valetsWithSameConfiguration_areEqual()
    {
        let equalValet = Valet.valet(with: valet.identifier, flavor: valet.flavor)
        XCTAssertTrue(equalValet == valet)
        XCTAssertTrue(equalValet === valet)
    }

    func test_differentValetFlavorsWithEquivalentConfiguration_areNotEqual()
    {
        XCTAssertFalse(valet == anotherFlavor)
        XCTAssertFalse(valet === anotherFlavor)
    }

    func test_valetsWithDifferingIdentifier_areNotEqual()
    {
        let differingIdentifier = Valet.valet(with: Identifier(nonEmpty: "nope")!, flavor: .vanilla(valet.accessibility))
        XCTAssertNotEqual(valet, differingIdentifier)
    }

    func test_valetsWithDifferingAccessibility_areNotEqual()
    {
        let differingAccessibility = Valet.valet(with: valet.identifier, flavor: .vanilla(.always))
        XCTAssertNotEqual(valet, differingAccessibility)
    }

    // MARK: canAccessKeychain

    func test_canAccessKeychain()
    {
        let permutations: [Valet] = Accessibility.allValues().flatMap { accessibility in
            return .valet(with: valet.identifier, flavor: .vanilla(accessibility))
        }
        for permutation in permutations {
            XCTAssertTrue(permutation.canAccessKeychain())
        }
    }
    
    func test_canAccessKeychain_sharedAccessGroup()
    {
        guard testEnvironmentIsSigned() else {
            return
        }
        
        let sharedAccessGroupIdentifier: Identifier
        #if os(iOS)
            sharedAccessGroupIdentifier = Identifier(nonEmpty: "com.squareup.Valet-iOS-Test-Host-App")!
        #elseif os(OSX)
            sharedAccessGroupIdentifier = Identifier(nonEmpty: "com.squareup.Valet-macOS-Test-Host-App")!
        #else
            XCTFail()
        #endif
        
        let permutations: [Valet] = Accessibility.allValues().flatMap { accessibility in
            return .sharedAccessGroupValet(with: sharedAccessGroupIdentifier, flavor: .vanilla(accessibility))
        }
        for permutation in permutations {
            XCTAssertTrue(permutation.canAccessKeychain())
        }
    }

    func test_canAccessKeychain_Performance()
    {
        measure {
            _ = self.valet.canAccessKeychain()
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
    
    func test_allKeys_doesNotReflectValetImplementationDetails() {
        // Under the hood, Valet inserts a canary when calling `canAccessKeychain()` - this should not appear in `allKeys()`.
        _ = valet.canAccessKeychain()
        XCTAssertEqual(valet.allKeys(), Set())
    }

    func test_allKeys_remainsUntouchedForUnequalValets()
    {
        valet.set(string: passcode, for: key)
        XCTAssertEqual(valet.allKeys(), Set(arrayLiteral: key))

        // Different Identifier
        let differingIdentifier = Valet.valet(with: Identifier(nonEmpty: "nope")!, flavor: .vanilla(valet.accessibility))
        XCTAssertEqual(differingIdentifier.allKeys(), Set())

        // Different Accessibility
        let differingAccessibility = Valet.valet(with: valet.identifier, flavor: .vanilla(.always))
        XCTAssertEqual(differingAccessibility.allKeys(), Set())

        // Different Kind
        XCTAssertEqual(anotherFlavor.allKeys(), Set())
    }

    // MARK: string(for:)

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
        let equalValet = Valet.valet(with: valet.identifier, flavor: .vanilla(valet.accessibility))
        XCTAssertEqual(0, equalValet.allKeys().count)
        XCTAssertEqual(valet, equalValet)
        XCTAssertTrue(valet.set(string: "monster", for: "cookie"))
        XCTAssertEqual("monster", equalValet.string(for: "cookie"))
    }

    func test_stringForKey_withDifferingIdentifier_isNil()
    {
        XCTAssertTrue(valet.set(string: passcode, for: key))
        XCTAssertEqual(passcode, valet.string(for: key))
        
        let differingIdentifier = Valet.valet(with: Identifier(nonEmpty: "wat")!, flavor: .vanilla(valet.accessibility))
        XCTAssertNil(differingIdentifier.string(for: key))
    }

    func test_stringForKey_withDifferingAccessibility_isNil()
    {
        XCTAssertTrue(valet.set(string: passcode, for: key))
        XCTAssertEqual(passcode, valet.string(for: key))
        
        let differingAccessibility = Valet.valet(with: valet.identifier, flavor: .vanilla(.afterFirstUnlockThisDeviceOnly))
        XCTAssertNil(differingAccessibility.string(for: key))
    }

    func test_stringForKey_withEquivalentConfigurationButDifferingFlavor_isNil()
    {
        guard testEnvironmentIsSigned() else {
            return
        }
        
        XCTAssertTrue(valet.set(string: "monster", for: "cookie"))
        XCTAssertEqual("monster", valet.string(for: "cookie"))

        XCTAssertNil(anotherFlavor.string(for: "cookie"))
    }
    
    // MARK: set(string:for:)

    func test_setStringForKey_successfullyUpdatesExistingKey()
    {
        XCTAssertNil(valet.string(for: key))
        valet.set(string: "1", for: key)
        XCTAssertEqual("1", valet.string(for: key))
        valet.set(string: "2", for: key)
        XCTAssertEqual("2", valet.string(for: key))
    }
    
    func test_setStringForKey_failsForInvalidValue() {
        XCTAssertFalse(valet.set(string: "", for: key))
    }
    
    func test_setStringForKey_failsForInvalidKey() {
        XCTAssertFalse(valet.set(string: passcode, for: ""))
    }
    
    // MARK: object(for:)
    
    func test_objectForKey_isNilForInvalidKey() {
        XCTAssertNil(valet.object(for: key))
    }
    
    func test_objectForKey_succeedsForValidKey() {
        valet.set(object: passcodeData, for: key)
        XCTAssertEqual(passcodeData, valet.object(for: key))
    }
    
    func test_objectForKey_equivalentValetsCanAccessSameData() {
        let equalValet = Valet.valet(with: valet.identifier, flavor: .vanilla(valet.accessibility))
        XCTAssertEqual(0, equalValet.allKeys().count)
        XCTAssertEqual(valet, equalValet)
        XCTAssertTrue(valet.set(object: passcodeData, for: key))
        XCTAssertEqual(passcodeData, equalValet.object(for: key))
    }
    
    func test_objectForKey_withDifferingIdentifier_isNil() {
        XCTAssertTrue(valet.set(object: passcodeData, for: key))
        XCTAssertEqual(passcodeData, valet.object(for: key))
        
        let differingIdentifier = Valet.valet(with: Identifier(nonEmpty: "wat")!, flavor: .vanilla(valet.accessibility))
        XCTAssertNil(differingIdentifier.object(for: key))
    }
    
    func test_objectForKey_withDifferingAccessibility_isNil() {
        XCTAssertTrue(valet.set(object: passcodeData, for: key))
        XCTAssertEqual(passcodeData, valet.object(for: key))
        
        let differingAccessibility = Valet.valet(with: valet.identifier, flavor: .vanilla(.afterFirstUnlockThisDeviceOnly))
        XCTAssertNil(differingAccessibility.object(for: key))
    }
    
    func test_objectForKey_withEquivalentConfigurationButDifferingFlavor_isNil() {
        guard testEnvironmentIsSigned() else {
            return
        }
        
        XCTAssertTrue(valet.set(object: passcodeData, for: key))
        XCTAssertEqual(passcodeData, valet.object(for: key))
        
        XCTAssertNil(anotherFlavor.object(for: key))
    }
    
    // MARK: set(object:for:)
    
    func test_setObjectForKey_successfullyUpdatesExistingKey() {
        guard let firstValue = "first".data(using: .utf8), let secondValue = "second".data(using: .utf8) else {
            XCTFail()
            return
        }
        valet.set(object: firstValue, for: key)
        XCTAssertEqual(firstValue, valet.object(for: key))
        valet.set(object: secondValue, for: key)
        XCTAssertEqual(secondValue, valet.object(for: key))
    }
    
    func test_setObjectForKey_failsForInvalidKey() {
        XCTAssertFalse(valet.set(object: passcodeData, for: ""))
    }
    
    func test_setObjectForKey_failsForEmptyData() {
        let emptyData = Data()
        XCTAssert(emptyData.isEmpty)
        XCTAssertFalse(valet.set(object: emptyData, for: key))
    }
    
    // Mark: String/Object Equivalence
    
    func test_stringForKey_succeedsForDataBackedByString() {
        XCTAssertTrue(valet.set(object: passcodeData, for: key))
        XCTAssertEqual(passcode, valet.string(for: key))
    }
    
    func test_stringForKey_failsForDataNotBackedByString() {
        let dictionary = [ "that's no" : "moon" ]
        let nonStringData = NSKeyedArchiver.archivedData(withRootObject: dictionary)
        XCTAssertTrue(valet.set(object: nonStringData, for: key))
        XCTAssertNil(valet.string(for: key))
    }
    
    func test_objectForKey_succeedsForStrings() {
        XCTAssertTrue(valet.set(string: passcode, for: key))
        XCTAssertEqual(passcodeData, valet.object(for: key))
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
            let backgroundValet = Valet.valet(with: backgroundIdentifier, flavor: .vanilla(.whenUnlocked))
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
        let differingAccessibility = Valet.valet(with: valet.identifier, flavor: .vanilla(.always))
        XCTAssertTrue(valet.set(string: passcode, for: key))

        XCTAssertTrue(differingAccessibility.removeObject(for: key))

        XCTAssertEqual(passcode, valet.string(for: key))
    }

    func test_removeObjectForKey_isDistinctForDifferingIdentifier()
    {
        let differingIdentifier = Valet.valet(with: Identifier(nonEmpty: "no")!, flavor: .vanilla(valet.accessibility))
        XCTAssertTrue(valet.set(string: passcode, for: key))

        XCTAssertTrue(differingIdentifier.removeObject(for: key))

        XCTAssertEqual(passcode, valet.string(for: key))
    }

    func test_removeObjectForKey_isDistinctForDifferingClasses()
    {
        guard testEnvironmentIsSigned() else {
            return
        }
        
        XCTAssertTrue(valet.set(string: passcode, for: key))
        XCTAssertTrue(anotherFlavor.set(string: passcode, for: key))

        XCTAssertTrue(valet.removeObject(for: key))

        XCTAssertNil(valet.string(for: key))
        XCTAssertEqual(passcode, anotherFlavor.string(for: key))
    }

    // MARK: Migration - Query

    func test_migrateObjectsMatching_failsIfNoItemsMatchQuery()
    {
        guard testEnvironmentIsSigned() else {
            return
        }
        
        let noItemsFoundError = MigrationResult.noItemsToMigrateFound

        let queryWithNoMatches = [
            kSecClass as String: kSecClassGenericPassword as String,
            kSecAttrService as String: "Valet_Does_Not_Exist"
        ]

        XCTAssertEqual(noItemsFoundError, valet.migrateObjects(matching: queryWithNoMatches, removeOnCompletion: false))
        XCTAssertEqual(noItemsFoundError, valet.migrateObjects(matching: queryWithNoMatches, removeOnCompletion: true))

        // Our test Valet has not yet been written to, migration should fail:
        XCTAssertEqual(noItemsFoundError, anotherFlavor.migrateObjects(matching: valet.keychainQuery, removeOnCompletion: false))
        XCTAssertEqual(noItemsFoundError, anotherFlavor.migrateObjects(matching: valet.keychainQuery, removeOnCompletion: true))
    }

    func test_migrateObjectsMatching_failsIfQueryHasNoInputClass()
    {
        guard testEnvironmentIsSigned() else {
            return
        }
        
        valet.set(string: passcode, for: key)

        // Test for base query success.
        XCTAssertEqual(anotherFlavor.migrateObjects(matching: valet.keychainQuery, removeOnCompletion: false), .success)
        XCTAssertEqual(passcode, anotherFlavor.string(for: key))

        var mutableQuery = valet.keychainQuery
        mutableQuery.removeValue(forKey: kSecClass as String)

        // Without a kSecClass, the migration should fail.
        XCTAssertEqual(.invalidQuery, anotherFlavor.migrateObjects(matching: mutableQuery, removeOnCompletion: false))
    }

    func test_migrateObjectsMatching_failsForBadQueries()
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
            kSecAttrAccessControl as String: NSNull()
        ]
        // Migration queries must not have kSecAttrAccessControl set
        XCTAssertEqual(invalidQueryError, valet.migrateObjects(matching: invalidQuery, removeOnCompletion: false))
    }

    // FIXME: Looks to me like this test may no longer be valid, need to dig a bit
    func disabled_test_migrateObjectsMatching_bailsOutIfConflictExistsInQueryResult()
    {
        guard testEnvironmentIsSigned() else {
            return
        }
        
        let migrationValet = Valet.valet(with: Identifier(nonEmpty: "Migrate_Me")!, flavor: .vanilla(.afterFirstUnlock))
        migrationValet.removeAllObjects()
        
        XCTAssertTrue(valet.set(string: passcode, for: key))
        XCTAssertTrue(anotherFlavor.set(string: passcode, for:key))

        let conflictingQuery = [
            kSecClass as String: kSecClassGenericPassword as String,
            kSecAttrAccount as String: key
        ]

        XCTAssertEqual(.duplicateKeyInQueryResult, migrationValet.migrateObjects(matching: conflictingQuery, removeOnCompletion: false))
    }

    func test_migrateObjectsMatching_withAccountNameAsData_doesNotRaiseException()
    {
        let identifier = "Keychain_With_Account_Name_As_NSData"
        
        // kSecAttrAccount entry is expected to be a CFString, but a CFDataRef can also be stored as a value.
        let keychainData = [
            kSecAttrService: identifier,
            kSecClass : kSecClassGenericPassword,
            kSecAttrAccount: passcodeData,
            kSecValueData: passcodeData
            ] as CFDictionary
        
        SecItemDelete(keychainData)
        let status = SecItemAdd(keychainData, nil)
        XCTAssertEqual(status, errSecSuccess)
        
        let query: [String : AnyHashable] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: identifier
        ]
        let migrationResult = valet.migrateObjects(matching: query, removeOnCompletion: false)
        
        XCTAssertEqual(migrationResult, .keyInQueryResultInvalid)
    }
    
    // MARK: Migration - Valet
    
    func test_migrateObjectsFromValet_migratesSingleKeyValuePairSuccessfully()
    {
        guard testEnvironmentIsSigned() else {
            return
        }
        
        anotherFlavor.set(string: "foo", for: "bar")
        _ = valet.migrateObjects(from: anotherFlavor, removeOnCompletion: false)
        _ = valet.allKeys()
        XCTAssertEqual("foo", valet.string(for: "bar"))
    }
    
    func test_migrateObjectsFromValet_migratesMultipleKeyValuePairsSuccessfully()
    {
        guard testEnvironmentIsSigned() else {
            return
        }
        
        let keyValuePairs = [
            "yo": "dawg",
            "we": "heard",
            "you": "like",
            "migrating": "to",
            "other": "valets"
        ]

        for (key, value) in keyValuePairs {
            anotherFlavor.set(string: value, for: key)
        }

        XCTAssertEqual(valet.migrateObjects(from: anotherFlavor, removeOnCompletion: false), .success)

        // Both the migration target and the previous Valet should hold all key/value pairs.
        XCTAssertEqual(valet.allKeys(), anotherFlavor.allKeys())
        for (key, value) in keyValuePairs {
            XCTAssertEqual(valet.string(for: key), value)
            XCTAssertEqual(anotherFlavor.string(for: key), value)
        }
    }

    func test_migrateObjectsFromValet_removesOnCompletionWhenRequested()
    {
        guard testEnvironmentIsSigned() else {
            return
        }
        
        let keyValuePairs = [
            "yo": "dawg",
            "we": "heard",
            "you": "like",
            "migrating": "to",
            "other": "valets"
        ]

        for (key, value) in keyValuePairs {
            anotherFlavor.set(string: value, for: key)
        }

        XCTAssertEqual(valet.migrateObjects(from: anotherFlavor, removeOnCompletion: true), .success)

        // The migration target should hold all key/value pairs, the previous Valet should be empty.
        XCTAssertEqual(0, anotherFlavor.allKeys().count)
        for (key, value) in keyValuePairs {
            XCTAssertEqual(valet.string(for: key), value)
            XCTAssertNil(anotherFlavor.string(for: key))
        }
    }

    func test_migrateObjectsFromValet_leavesKeychainUntouchedWhenConflictsExist()
    {
        guard testEnvironmentIsSigned() else {
            return
        }
        
        let keyValuePairs = [
            "yo": "dawg",
            "we": "heard",
            "you": "like",
            "migrating": "to",
            "other": "valets"
        ]

        for (key, value) in keyValuePairs {
            anotherFlavor.set(string: value, for: key)
        }

        valet.set(string: "adrian", for: "yo")

        XCTAssertEqual(1, valet.allKeys().count)
        XCTAssertEqual(keyValuePairs.count, anotherFlavor.allKeys().count)

        XCTAssertEqual(.keyInQueryResultAlreadyExistsInValet, valet.migrateObjects(from: anotherFlavor, removeOnCompletion: true))

        // Neither Valet should have seen any changes.
        XCTAssertEqual(1, valet.allKeys().count)
        XCTAssertEqual(keyValuePairs.count, anotherFlavor.allKeys().count)
        
        XCTAssertEqual("adrian", valet.string(for: "yo"))
        for (key, value) in keyValuePairs {
            XCTAssertEqual(anotherFlavor.string(for: key), value)
        }
    }

    func test_migrateObjectsFromValetRemoveOnCompletion_migratesDataSuccessfullyWhenBothValetsHavePreviouslyCalled_canAccessKeychain() {
        let otherValet = Valet.valet(with: Identifier(nonEmpty: "Migrate_Me_To_Valet")!, flavor: .vanilla(.afterFirstUnlock))

        // Clean up any dangling keychain items before we start this test.
        otherValet.removeAllObjects()

        let keyStringPairToMigrateMap = ["foo" : "bar", "testing" : "migration", "is" : "quite", "entertaining" : "if", "you" : "don't", "screw" : "up"]
        for (key, value) in keyStringPairToMigrateMap {
            XCTAssertTrue(otherValet.set(string: value, for: key))
        }

        XCTAssertTrue(valet.canAccessKeychain())
        XCTAssertTrue(otherValet.canAccessKeychain())
        XCTAssertEqual(valet.migrateObjects(from: otherValet, removeOnCompletion: false), .success)

        for (key, value) in keyStringPairToMigrateMap {
            XCTAssertEqual(valet.string(for: key), value )
            XCTAssertEqual(otherValet.string(for: key), value)
        }
    }
    
    // MARK: Backwards Compatibility
    
    func test_backwardsCompatibilityWithObjectiveCValet() {
        XCTAssert(valet.accessibility == .whenUnlocked)
        let legacyValet = VALLegacyValet(identifier: valet.identifier.description, accessibility: VALLegacyAccessibility.whenUnlocked)!
        
        legacyValet.setString(passcode, forKey: key)
        
        XCTAssertNotNil(legacyValet.string(forKey: key))
        XCTAssertEqual(legacyValet.string(forKey: key), valet.string(for: key))
    }

}
