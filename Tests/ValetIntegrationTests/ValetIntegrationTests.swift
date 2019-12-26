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

@testable import Valet


/// - Returns: `true` when the test environment is signed.
/// - The Valet Mac Tests target is left without a host app on master. Mac test host app signing requires CI to have the Developer team credentials down in keychain, which we can't easily accomplish.
/// - Note: In order to test changes locally, set the Valet Mac Tests host to Valet macOS Test Host App, delete all VAL_* keychain items in your keychain via Keychain Access.app, and run Mac tests.
func testEnvironmentIsSigned() -> Bool {
    // Our test host apps for iOS and Mac are both signed, so testing for a custom bundle identifier is analogous to testing signing.
    guard Bundle.main.bundleIdentifier != nil && Bundle.main.bundleIdentifier != "com.apple.dt.xctest.tool" else {
        #if os(iOS) || os(tvOS)
            XCTFail("test bundle should be signed")
        #endif
        
        return false
    }

    return true
}

func testEnvironmentSupportsWhenPasscodeSet() -> Bool {
    if let simulatorVersionInfo = ProcessInfo.processInfo.environment["SIMULATOR_VERSION_INFO"],
        simulatorVersionInfo.contains("iOS 13") || simulatorVersionInfo.contains("tvOS 13")
    {
        // iOS and tvOS 13 simulators fail to store items in a Valet that has a
        // kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly flag. The documentation for this flag says:
        // "No items can be stored in this class on devices without a passcode". I currently do not
        // understand why prior simulators work with this flag, given that no simulators have a passcode.
        return false

    } else {
        return true
    }
}


internal extension Valet {

    // MARK: Shared Access Group

    static var sharedAccessGroupIdentifier: Identifier = {
        let sharedAccessGroupIdentifier: Identifier
        #if os(iOS)
            sharedAccessGroupIdentifier = Identifier(nonEmpty: "com.squareup.Valet-iOS-Test-Host-App")!
        #elseif os(macOS)
            sharedAccessGroupIdentifier = Identifier(nonEmpty: "com.squareup.Valet-macOS-Test-Host-App")!
        #elseif os(tvOS)
            sharedAccessGroupIdentifier = Identifier(nonEmpty: "com.squareup.Valet-tvOS-Test-Host-App")!
        #elseif os(watchOS)
            sharedAccessGroupIdentifier = Identifier(nonEmpty: "com.squareup.ValetTouchIDTestApp.watchkitapp.watchkitextension")!
        #else
            XCTFail()
        #endif
        return sharedAccessGroupIdentifier
    }()

}


class ValetIntegrationTests: XCTestCase
{
    static let identifier = Identifier(nonEmpty: "valet_testing")!
    let valet = Valet.valet(with: identifier, accessibility: .whenUnlocked)

    // FIXME: Need a different flavor (Synchronizable can't be tested on Mac currently
    let anotherFlavor = Valet.iCloudValet(with: identifier, accessibility: .whenUnlocked)

    let key = "key"
    let passcode = "topsecret"
    lazy var passcodeData: Data = { return Data(self.passcode.utf8) }()
    
    // MARK: XCTestCase

    override func setUp()
    {
        super.setUp()

        try? valet.removeAllObjects()
        try? anotherFlavor.removeAllObjects()

        let identifier = ValetTests.identifier
        let allPermutations = Valet.permutations(with: identifier) + Valet.permutations(with: identifier, shared: true)
        allPermutations.forEach { testingValet in try? testingValet.removeAllObjects() }

        XCTAssertEqual(try? valet.allKeys(), Set())
        XCTAssertEqual(try? anotherFlavor.allKeys(), Set())
    }

    // MARK: Initialization

    func test_init_createsCorrectBackingService() {
        let identifier = ValetTests.identifier

        Accessibility.allValues().forEach { accessibility in
            let backingService = Valet.valet(with: identifier, accessibility: accessibility).service
            XCTAssertEqual(backingService, Service.standard(identifier, .valet(accessibility)))
        }
    }

    func test_init_createsCorrectBackingService_sharedAccess() {
        let identifier = ValetTests.identifier

        Accessibility.allValues().forEach { accessibility in
            let backingService = Valet.sharedAccessGroupValet(with: identifier, accessibility: accessibility).service
            XCTAssertEqual(backingService, Service.sharedAccessGroup(identifier, .valet(accessibility)))
        }
    }

    func test_init_createsCorrectBackingService_cloud() {
        let identifier = ValetTests.identifier

        CloudAccessibility.allValues().forEach { accessibility in
            let backingService = Valet.iCloudValet(with: identifier, accessibility: accessibility).service
            XCTAssertEqual(backingService, Service.standard(identifier, .iCloud(accessibility)))
        }
    }

    func test_init_createsCorrectBackingService_cloudSharedAccess() {
        let identifier = ValetTests.identifier

        CloudAccessibility.allValues().forEach { accessibility in
            let backingService = Valet.iCloudSharedAccessGroupValet(with: identifier, accessibility: accessibility).service
            XCTAssertEqual(backingService, Service.sharedAccessGroup(identifier, .iCloud(accessibility)))
        }
    }

    // MARK: Equality

    func test_valetsWithSameConfiguration_areEqual()
    {
        let equalValet = Valet.valet(with: valet.identifier, accessibility: valet.accessibility)
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
        let differingIdentifier = Valet.valet(with: Identifier(nonEmpty: "nope")!, accessibility: valet.accessibility)
        XCTAssertNotEqual(valet, differingIdentifier)
    }

    func test_valetsWithDifferingAccessibility_areNotEqual()
    {
        let differingAccessibility = Valet.valet(with: valet.identifier, accessibility: .whenUnlockedThisDeviceOnly)
        XCTAssertNotEqual(valet, differingAccessibility)
    }

    // MARK: canAccessKeychain

    func test_canAccessKeychain()
    {
        Valet.permutations(with: valet.identifier).forEach { permutation in
            XCTAssertTrue(permutation.canAccessKeychain(), "\(permutation) could not access keychain.")
        }
    }
    
    func test_canAccessKeychain_sharedAccessGroup()
    {
        guard testEnvironmentIsSigned() else {
            return
        }

        Valet.permutations(with: Valet.sharedAccessGroupIdentifier, shared: true).forEach { permutation in
            XCTAssertTrue(permutation.canAccessKeychain(), "\(permutation) could not access keychain.")
        }
    }

    func test_canAccessKeychain_Performance()
    {
        measure {
            _ = self.valet.canAccessKeychain()
        }
    }

    // MARK: containsObjectForKey

    func test_containsObjectForKey() throws
    {
        XCTAssertFalse(valet.containsObject(forKey: key))

        try valet.set(string: passcode, forKey: key)
        XCTAssertTrue(valet.containsObject(forKey: key))

        try valet.removeObject(forKey: key)
        XCTAssertFalse(valet.containsObject(forKey: key))
    }

    // MARK: allKeys

    func test_allKeys() throws
    {
        XCTAssertEqual(try valet.allKeys(), Set())

        try valet.set(string: passcode, forKey: key)
        XCTAssertEqual(try valet.allKeys(), Set(arrayLiteral: key))

        try valet.set(string: "monster", forKey: "cookie")
        XCTAssertEqual(try valet.allKeys(), Set(arrayLiteral: key, "cookie"))

        try valet.removeAllObjects()
        XCTAssertEqual(try valet.allKeys(), Set())
    }
    
    func test_allKeys_doesNotReflectValetImplementationDetails() throws {
        // Under the hood, Valet inserts a canary when calling `canAccessKeychain()` - this should not appear in `allKeys()`.
        _ = valet.canAccessKeychain()
        XCTAssertEqual(try valet.allKeys(), Set())
    }

    func test_allKeys_remainsUntouchedForUnequalValets() throws
    {
        try valet.set(string: passcode, forKey: key)
        XCTAssertEqual(try valet.allKeys(), Set(arrayLiteral: key))

        // Different Identifier
        let differingIdentifier = Valet.valet(with: Identifier(nonEmpty: "nope")!, accessibility: valet.accessibility)
        XCTAssertEqual(try differingIdentifier.allKeys(), Set())

        // Different Accessibility
        let differingAccessibility = Valet.valet(with: valet.identifier, accessibility: .whenUnlockedThisDeviceOnly)
        XCTAssertEqual(try differingAccessibility.allKeys(), Set())

        // Different Kind
        XCTAssertEqual(try anotherFlavor.allKeys(), Set())
    }

    // MARK: string(forKey:)

    func test_stringForKey_throwsItemNotFoundForKeyWithNoValue()
    {
        XCTAssertThrowsError(try valet.string(forKey: key)) { error in
            XCTAssertEqual(error as? KeychainError, .itemNotFound)
        }
    }

    func test_stringForKey_retrievesStringForValidKey() throws
    {
        try valet.set(string: passcode, forKey: key)
        XCTAssertEqual(passcode, try valet.string(forKey: key))
    }

    func test_stringForKey_equivalentValetsCanAccessSameData() throws
    {
        let equalValet = Valet.valet(with: valet.identifier, accessibility: valet.accessibility)
        XCTAssertEqual(0, try equalValet.allKeys().count)
        XCTAssertEqual(valet, equalValet)
        try valet.set(string: "monster", forKey: "cookie")
        XCTAssertEqual("monster", try equalValet.string(forKey: "cookie"))
    }

    func test_stringForKey_withDifferingIdentifier_throwsItemNotFound() throws
    {
        try valet.set(string: passcode, forKey: key)
        XCTAssertEqual(passcode, try valet.string(forKey: key))
        
        let differingIdentifier = Valet.valet(with: Identifier(nonEmpty: "wat")!, accessibility: valet.accessibility)
        XCTAssertThrowsError(try differingIdentifier.string(forKey: key)) { error in
            XCTAssertEqual(error as? KeychainError, .itemNotFound)
        }
    }

    func test_stringForKey_withDifferingAccessibility_throwsItemNotFound() throws
    {
        try valet.set(string: passcode, forKey: key)
        XCTAssertEqual(passcode, try valet.string(forKey: key))
        
        let differingAccessibility = Valet.valet(with: valet.identifier, accessibility: .afterFirstUnlockThisDeviceOnly)
        XCTAssertThrowsError(try differingAccessibility.string(forKey: key)) { error in
            XCTAssertEqual(error as? KeychainError, .itemNotFound)
        }
    }

    func test_stringForKey_withEquivalentConfigurationButDifferingFlavor_throwsItemNotFound() throws
    {
        guard testEnvironmentIsSigned() else {
            return
        }
        
        try valet.set(string: "monster", forKey: "cookie")
        XCTAssertEqual("monster", try valet.string(forKey: "cookie"))

        XCTAssertThrowsError(try anotherFlavor.string(forKey: "cookie")) { error in
            XCTAssertEqual(error as? KeychainError, .itemNotFound)
        }
    }
    
    // MARK: set(string:forKey:)

    func test_setStringForKey_successfullyUpdatesExistingKey() throws
    {
        XCTAssertThrowsError(try valet.string(forKey: key)) { error in
            XCTAssertEqual(error as? KeychainError, .itemNotFound)
        }

        try valet.set(string: "1", forKey: key)
        XCTAssertEqual("1", try valet.string(forKey: key))
        try valet.set(string: "2", forKey: key)
        XCTAssertEqual("2", try valet.string(forKey: key))
    }
    
    func test_setStringForKey_throwsEmptyValueOnInvalidValue() {
        XCTAssertThrowsError(try valet.set(string: "", forKey: key)) { error in
            XCTAssertEqual(error as? KeychainError, KeychainError.emptyValue)
        }
    }
    
    func test_setStringForKey_throwsEmptyKeyOnInvalidKey() throws {
        XCTAssertThrowsError(try valet.set(string: passcode, forKey: "")) { error in
            XCTAssertEqual(error as? KeychainError, KeychainError.emptyKey)
        }
    }
    
    // MARK: object(forKey:)
    
    func test_objectForKey_throwsItemNotFound() {
        XCTAssertThrowsError(try valet.object(forKey: key)) { error in
            XCTAssertEqual(error as? KeychainError, .itemNotFound)
        }
    }
    
    func test_objectForKey_succeedsForValidKey() throws {
        try valet.set(object: passcodeData, forKey: key)
        XCTAssertEqual(passcodeData, try valet.object(forKey: key))
    }
    
    func test_objectForKey_equivalentValetsCanAccessSameData() throws {
        let equalValet = Valet.valet(with: valet.identifier, accessibility: valet.accessibility)
        XCTAssertEqual(0, try equalValet.allKeys().count)
        XCTAssertEqual(valet, equalValet)
        try valet.set(object: passcodeData, forKey: key)
        XCTAssertEqual(passcodeData, try equalValet.object(forKey: key))
    }
    
    func test_objectForKey_withDifferingIdentifier_throwsItemNotFound() throws {
        try valet.set(object: passcodeData, forKey: key)
        XCTAssertEqual(passcodeData, try valet.object(forKey: key))
        
        let differingIdentifier = Valet.valet(with: Identifier(nonEmpty: "wat")!, accessibility: valet.accessibility)
        XCTAssertThrowsError(try differingIdentifier.object(forKey: key)) { error in
            XCTAssertEqual(error as? KeychainError, .itemNotFound)
        }
    }
    
    func test_objectForKey_withDifferingAccessibility_throwsItemNotFound() throws {
        try valet.set(object: passcodeData, forKey: key)
        XCTAssertEqual(passcodeData, try valet.object(forKey: key))
        
        let differingAccessibility = Valet.valet(with: valet.identifier, accessibility: .afterFirstUnlockThisDeviceOnly)
        XCTAssertThrowsError(try differingAccessibility.object(forKey: key)) { error in
            XCTAssertEqual(error as? KeychainError, .itemNotFound)
        }
    }
    
    func test_objectForKey_withEquivalentConfigurationButDifferingFlavor_throwsItemNotFound() throws {
        guard testEnvironmentIsSigned() else {
            return
        }
        
        try valet.set(object: passcodeData, forKey: key)
        XCTAssertEqual(passcodeData, try valet.object(forKey: key))

        XCTAssertThrowsError(try anotherFlavor.object(forKey: key)) { error in
            XCTAssertEqual(error as? KeychainError, .itemNotFound)
        }
    }
    
    // MARK: set(object:forKey:)
    
    func test_setObjectForKey_successfullyUpdatesExistingKey() throws {
        let firstValue = Data("first".utf8)
        let secondValue = Data("second".utf8)
        try valet.set(object: firstValue, forKey: key)
        XCTAssertEqual(firstValue, try valet.object(forKey: key))
        try valet.set(object: secondValue, forKey: key)
        XCTAssertEqual(secondValue, try valet.object(forKey: key))
    }
    
    func test_setObjectForKey_throwsEmptyKeyOnInvalidKey() {
        XCTAssertThrowsError(try valet.set(object: passcodeData, forKey: "")) { error in
            XCTAssertEqual(error as? KeychainError, .emptyKey)
        }
    }
    
    func test_setObjectForKey_throwsEmptyValueOnEmptyData() {
        let emptyData = Data()
        XCTAssertTrue(emptyData.isEmpty)
        XCTAssertThrowsError(try valet.set(object: emptyData, forKey: key)) { error in
            XCTAssertEqual(error as? KeychainError, .emptyValue)
        }
    }
    
    // Mark: String/Object Equivalence
    
    func test_stringForKey_succeedsForDataBackedByString() throws {
        try valet.set(object: passcodeData, forKey: key)
        XCTAssertEqual(passcode, try valet.string(forKey: key))
    }
    
    func test_stringForKey_failsForDataNotBackedByString() throws {
        let dictionary = [ "that's no" : "moon" ]
        let nonStringData = NSKeyedArchiver.archivedData(withRootObject: dictionary)
        try valet.set(object: nonStringData, forKey: key)
        XCTAssertThrowsError(try valet.string(forKey: key)) { error in
            XCTAssertEqual(error as? KeychainError, .itemNotFound)
        }
    }
    
    func test_objectForKey_succeedsForStrings() throws {
        try valet.set(string: passcode, forKey: key)
        XCTAssertEqual(passcodeData, try valet.object(forKey: key))
    }

    // MARK: Concurrency

    func test_concurrentSetAndRemoveOperations()
    {
        let setQueue = DispatchQueue(label: "Set String Queue", attributes: .concurrent)
        let removeQueue = DispatchQueue(label: "Remove Object Queue", attributes: .concurrent)

        for _ in 1...50 {
            setQueue.async {
                do {
                    try self.valet.set(string: self.passcode, forKey: self.key)
                } catch {
                    XCTFail("Threw \(error) trying to write value")
                }
            }
            removeQueue.async {
                do {
                    try self.valet.removeObject(forKey: self.key)
                } catch {
                    XCTFail("Threw \(error) trying to remove value")
                }
            }
        }
        
        let setQueueExpectation = expectation(description: "\(#function): Set String Queue")
        let removeQueueExpectation = expectation(description: "\(#function): Remove String Queue")
        
        setQueue.async(flags: .barrier) {
            setQueueExpectation.fulfill()
        }
        removeQueue.async(flags: .barrier) {
            removeQueueExpectation.fulfill()
        }
        
        waitForExpectations(timeout: 10.0, handler: nil)
    }

    func test_stringForKey_canReadDataWrittenOnAnotherThread()
    {
        let setStringQueue = DispatchQueue(label: "Set String Queue", attributes: .concurrent)
        let stringForKeyQueue = DispatchQueue(label: "String For Key Queue", attributes: .concurrent)

        let expectation = self.expectation(description: #function)

        setStringQueue.async {
            do {
                try self.valet.set(string: self.passcode, forKey: self.key)
            } catch {
                XCTFail("Threw \(error) trying to set value")
            }

            stringForKeyQueue.async {
                do {
                    let stringForKey = try self.valet.string(forKey: self.key)
                    XCTAssertEqual(stringForKey, self.passcode)
                } catch {
                    XCTFail("Threw \(error) trying to read value")
                }

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
            do {
                try backgroundValet.set(string: self.passcode, forKey: self.key)
            } catch {
                XCTFail("Threw \(error) trying to write value")
                expectation.fulfill()
            }
            stringForKeyQueue.async {
                do {
                    let stringForKey = try backgroundValet.string(forKey: self.key)
                    XCTAssertEqual(stringForKey, self.passcode)
                    expectation.fulfill()
                } catch {
                    XCTFail("Threw \(error) trying to read value")
                    expectation.fulfill()
                }
            }
        }

        waitForExpectations(timeout: 5.0, handler: nil)
    }

    // MARK: Removal

    func test_removeObjectForKey_succeedsWhenKeyIsNotPresent() throws
    {
        try valet.removeObject(forKey: "derp")
    }

    func test_removeObjectForKey_succeedsWhenKeyIsPresent() throws
    {
        try valet.set(string: passcode, forKey: key)
        try valet.removeObject(forKey: key)
        XCTAssertThrowsError(try valet.string(forKey: key)) { error in
            XCTAssertEqual(error as? KeychainError, .itemNotFound)
        }
    }

    func test_removeObjectForKey_isDistinctForDifferingAccessibility() throws
    {
        let differingAccessibility = Valet.valet(with: valet.identifier, accessibility: .whenUnlockedThisDeviceOnly)
        try valet.set(string: passcode, forKey: key)

        try differingAccessibility.removeObject(forKey: key)

        XCTAssertEqual(passcode, try valet.string(forKey: key))
    }

    func test_removeObjectForKey_isDistinctForDifferingIdentifier() throws
    {
        let differingIdentifier = Valet.valet(with: Identifier(nonEmpty: "no")!, accessibility: valet.accessibility)
        try valet.set(string: passcode, forKey: key)

        try differingIdentifier.removeObject(forKey: key)

        XCTAssertEqual(passcode, try valet.string(forKey: key))
    }

    func test_removeObjectForKey_isDistinctForDifferingClasses() throws
    {
        guard testEnvironmentIsSigned() else {
            return
        }
        
        try valet.set(string: passcode, forKey: key)
        try anotherFlavor.set(string: passcode, forKey: key)

        try valet.removeObject(forKey: key)

        XCTAssertThrowsError(try valet.string(forKey: key)) { error in
            XCTAssertEqual(error as? KeychainError, .itemNotFound)
        }
        XCTAssertEqual(passcode, try anotherFlavor.string(forKey: key))
    }

    // MARK: Migration - Query

    func test_migrateObjectsMatching_failsIfQueryHasNoInputClass() throws
    {
        guard testEnvironmentIsSigned() else {
            return
        }

        try valet.set(string: passcode, forKey: key)

        let valetKeychainQuery = try valet.keychainQuery()
        // Test for base query success.
        try anotherFlavor.migrateObjects(matching: valetKeychainQuery, removeOnCompletion: false)
        XCTAssertEqual(passcode, try anotherFlavor.string(forKey: key))

        var mutableQuery = valetKeychainQuery
        mutableQuery.removeValue(forKey: kSecClass as String)

        // Without a kSecClass, the migration should fail.
        XCTAssertThrowsError(try anotherFlavor.migrateObjects(matching: mutableQuery, removeOnCompletion: false)) { error in
            XCTAssertEqual(error as? MigrationError, .invalidQuery)
        }

        mutableQuery[kSecClass as String] = kSecClassInternetPassword
        // Without a kSecClass set to something other than kSecClassGenericPassword, the migration should fail.
        XCTAssertThrowsError(try anotherFlavor.migrateObjects(matching: mutableQuery, removeOnCompletion: false)) { error in
            XCTAssertEqual(error as? MigrationError, .invalidQuery)
        }
    }

    func test_migrateObjectsMatching_failsIfNoItemsMatchQuery() throws
    {
        guard testEnvironmentIsSigned() else {
            return
        }

        let queryWithNoMatches = [
            kSecClass as String: kSecClassGenericPassword as String,
            kSecAttrService as String: "Valet_Does_Not_Exist"
        ]

        XCTAssertThrowsError(try valet.migrateObjects(matching: queryWithNoMatches, removeOnCompletion: false)) { error in
            XCTAssertEqual(error as? KeychainError, .itemNotFound)
        }
        XCTAssertThrowsError(try valet.migrateObjects(matching: queryWithNoMatches, removeOnCompletion: true)) { error in
            XCTAssertEqual(error as? KeychainError, .itemNotFound)
        }

        let valetKeychainQuery = try valet.keychainQuery()

        // Our test Valet has not yet been written to, migration should fail:
        XCTAssertThrowsError(try anotherFlavor.migrateObjects(matching: valetKeychainQuery, removeOnCompletion: false)) { error in
            XCTAssertEqual(error as? KeychainError, .itemNotFound)
        }
        XCTAssertThrowsError(try anotherFlavor.migrateObjects(matching: valetKeychainQuery, removeOnCompletion: true)) { error in
            XCTAssertEqual(error as? KeychainError, .itemNotFound)
        }
    }

    // FIXME: Looks to me like this test may no longer be valid, need to dig a bit
    func disabled_test_migrateObjectsMatching_bailsOutIfConflictExistsInQueryResult() throws
    {
        guard testEnvironmentIsSigned() else {
            return
        }
        
        let migrationValet = Valet.valet(with: Identifier(nonEmpty: "Migrate_Me")!, accessibility: .afterFirstUnlock)
        try migrationValet.removeAllObjects()
        
        try valet.set(string: passcode, forKey: key)
        try anotherFlavor.set(string: passcode, forKey:key)

        let conflictingQuery = [
            kSecClass as String: kSecClassGenericPassword as String,
            kSecAttrAccount as String: key
        ]

        XCTAssertThrowsError(try migrationValet.migrateObjects(matching: conflictingQuery, removeOnCompletion: false)) { error in
            XCTAssertEqual(error as? MigrationError, .duplicateKeyInQueryResult)
        }
    }

    func test_migrateObjectsMatching_withAccountNameAsData_doesNotRaiseException() throws
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
        XCTAssertThrowsError(try valet.migrateObjects(matching: query, removeOnCompletion: false)) { error in
            XCTAssertEqual(error as? MigrationError, .keyInQueryResultInvalid)
        }
    }
    
    // MARK: Migration - Valet
    
    func test_migrateObjectsFromValet_migratesSingleKeyValuePairSuccessfully() throws
    {
        guard testEnvironmentIsSigned() else {
            return
        }
        
        try anotherFlavor.set(string: "foo", forKey: "bar")
        try valet.migrateObjects(from: anotherFlavor, removeOnCompletion: false)
        _ = try valet.allKeys()
        XCTAssertEqual("foo", try valet.string(forKey: "bar"))
    }
    
    func test_migrateObjectsFromValet_migratesMultipleKeyValuePairsSuccessfully() throws
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
            try anotherFlavor.set(string: value, forKey: key)
        }

        try valet.migrateObjects(from: anotherFlavor, removeOnCompletion: false)

        // Both the migration target and the previous Valet should hold all key/value pairs.
        XCTAssertEqual(try valet.allKeys(), try anotherFlavor.allKeys())
        for (key, value) in keyValuePairs {
            XCTAssertEqual(try valet.string(forKey: key), value)
            XCTAssertEqual(try anotherFlavor.string(forKey: key), value)
        }
    }

    func test_migrateObjectsFromValet_removesOnCompletionWhenRequested() throws
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
            try anotherFlavor.set(string: value, forKey: key)
        }

        try valet.migrateObjects(from: anotherFlavor, removeOnCompletion: true)

        // The migration target should hold all key/value pairs, the previous Valet should be empty.
        XCTAssertEqual(0, try anotherFlavor.allKeys().count)
        for (key, value) in keyValuePairs {
            XCTAssertEqual(try valet.string(forKey: key), value)
            XCTAssertThrowsError(try anotherFlavor.string(forKey: key)) { error in
                XCTAssertEqual(error as? KeychainError, .itemNotFound)
            }
        }
    }

    func test_migrateObjectsFromValet_leavesKeychainUntouchedWhenConflictsExist() throws
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
            try anotherFlavor.set(string: value, forKey: key)
        }

        try valet.set(string: "adrian", forKey: "yo")

        XCTAssertEqual(1, try valet.allKeys().count)
        XCTAssertEqual(keyValuePairs.count, try anotherFlavor.allKeys().count)

        XCTAssertThrowsError(try valet.migrateObjects(from: anotherFlavor, removeOnCompletion: true)) { error in
            XCTAssertEqual(error as? MigrationError, .keyInQueryResultAlreadyExistsInValet)
        }

        // Neither Valet should have seen any changes.
        XCTAssertEqual(1, try valet.allKeys().count)
        XCTAssertEqual(keyValuePairs.count, try anotherFlavor.allKeys().count)
        
        XCTAssertEqual("adrian", try valet.string(forKey: "yo"))
        for (key, value) in keyValuePairs {
            XCTAssertEqual(try anotherFlavor.string(forKey: key), value)
        }
    }

    func test_migrateObjectsFromValetRemoveOnCompletion_migratesDataSuccessfullyWhenBothValetsHavePreviouslyCalled_canAccessKeychain() throws {
        let otherValet = Valet.valet(with: Identifier(nonEmpty: "Migrate_Me_To_Valet")!, accessibility: .afterFirstUnlock)

        // Clean up any dangling keychain items before we start this test.
        try otherValet.removeAllObjects()

        let keyStringPairToMigrateMap = ["foo" : "bar", "testing" : "migration", "is" : "quite", "entertaining" : "if", "you" : "don't", "screw" : "up"]
        for (key, value) in keyStringPairToMigrateMap {
            try otherValet.set(string: value, forKey: key)
        }

        XCTAssertTrue(valet.canAccessKeychain())
        XCTAssertTrue(otherValet.canAccessKeychain())
        try valet.migrateObjects(from: otherValet, removeOnCompletion: false)

        for (key, value) in keyStringPairToMigrateMap {
            XCTAssertEqual(try valet.string(forKey: key), value)
            XCTAssertEqual(try otherValet.string(forKey: key), value)
        }
    }

}
