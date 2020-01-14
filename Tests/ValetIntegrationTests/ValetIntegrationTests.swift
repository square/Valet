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


/// - returns: `true` when the test environment is signed.
/// - The Valet Mac Tests target is left without a host app on master. Mac test host app signing requires CI to have the Developer team credentials down in keychain, which we can't easily accomplish.
/// - note: In order to test changes locally, set the Valet Mac Tests host to Valet macOS Test Host App, delete all VAL_* keychain items in your keychain via Keychain Access.app, and run Mac tests.
func testEnvironmentIsSigned() -> Bool {
    // Our test host apps for iOS and Mac are both signed, so testing for a custom bundle identifier is analogous to testing signing.
    guard Bundle.main.bundleIdentifier != nil && Bundle.main.bundleIdentifier != "com.apple.dt.xctest.tool" else {
        #if os(iOS) || os(tvOS)
            XCTFail("test bundle should be signed")
        #endif
        
        return false
    }

    if let simulatorVersionInfo = ProcessInfo.processInfo.environment["SIMULATOR_VERSION_INFO"],
        simulatorVersionInfo.contains("iOS 13") || simulatorVersionInfo.contains("tvOS 13")
    {
        // Xcode 11's simulator does not support code-signing.
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
    static let identifier = Valet.sharedAccessGroupIdentifier
    var allPermutations: [Valet] {
        return Valet.permutations(with: ValetIntegrationTests.identifier)
            + (testEnvironmentIsSigned() ? Valet.permutations(with: ValetIntegrationTests.identifier, shared: true) : [])
    }

    let vanillaValet = Valet.valet(with: identifier, accessibility: .whenUnlocked)
    // FIXME: Need a different flavor (Synchronizable must be tested in a signed environment)
    let anotherFlavor = Valet.iCloudValet(with: identifier, accessibility: .whenUnlocked)

    let key = "key"
    let passcode = "topsecret"
    lazy var passcodeData: Data = { return Data(self.passcode.utf8) }()
    
    // MARK: XCTestCase

    override func setUp()
    {
        super.setUp()
        
        ErrorHandler.customAssertBody = { _, _, _, _ in
            // Nothing to do here.
        }
        
        vanillaValet.removeAllObjects()
        anotherFlavor.removeAllObjects()

        allPermutations.forEach { testingValet in testingValet.removeAllObjects() }

        XCTAssertTrue(vanillaValet.allKeys().isEmpty)
        XCTAssertTrue(anotherFlavor.allKeys().isEmpty)
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

    // MARK: canAccessKeychain

    func test_canAccessKeychain()
    {
        Valet.permutations(with: vanillaValet.identifier).forEach { permutation in
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
            _ = self.vanillaValet.canAccessKeychain()
        }
    }

    // MARK: containsObjectForKey

    func test_containsObjectForKey()
    {
        allPermutations.forEach { valet in
            XCTAssertFalse(valet.containsObject(forKey: key), "\(valet) found object for key that should not exist")

            XCTAssertTrue(valet.set(string: passcode, forKey: key), "\(valet) could not set item in keychain")
            XCTAssertTrue(valet.containsObject(forKey: key), "\(valet) could not find item it has set in keychain")

            XCTAssertTrue(valet.removeObject(forKey: key), "\(valet) could not remove item in keychain")
            XCTAssertFalse(valet.containsObject(forKey: key), "\(valet) found removed item in keychain")
        }
    }

    // MARK: allKeys

    func test_allKeys()
    {
        allPermutations.forEach { valet in
            XCTAssertEqual(valet.allKeys(), Set(), "\(valet) found keys that should not exist")

            XCTAssertTrue(valet.set(string: passcode, forKey: key), "\(valet) could not set item in keychain")
            XCTAssertEqual(valet.allKeys(), Set(arrayLiteral: key))

            XCTAssertTrue(valet.set(string: "monster", forKey: "cookie"), "\(valet) could not set item in keychain")
            XCTAssertEqual(valet.allKeys(), Set(arrayLiteral: key, "cookie"))

            valet.removeAllObjects()
            XCTAssertEqual(valet.allKeys(), Set(), "\(valet) found keys that should not exist")
        }
    }
    
    func test_allKeys_doesNotReflectValetImplementationDetails() {
        allPermutations.forEach { valet in
            // Under the hood, Valet inserts a canary when calling `canAccessKeychain()` - this should not appear in `allKeys()`.
            _ = valet.canAccessKeychain()
            XCTAssertEqual(valet.allKeys(), Set())
        }
    }

    func test_allKeys_remainsUntouchedForUnequalValets()
    {
        vanillaValet.set(string: passcode, forKey: key)
        XCTAssertEqual(vanillaValet.allKeys(), Set(arrayLiteral: key))

        // Different Identifier
        let differingIdentifier = Valet.valet(with: Identifier(nonEmpty: "nope")!, accessibility: vanillaValet.accessibility)
        XCTAssertEqual(differingIdentifier.allKeys(), Set())

        // Different Accessibility
        let differingAccessibility = Valet.valet(with: vanillaValet.identifier, accessibility: .always)
        XCTAssertEqual(differingAccessibility.allKeys(), Set())

        // Different Kind
        XCTAssertEqual(anotherFlavor.allKeys(), Set())
    }

    // MARK: string(forKey:)

    func test_stringForKey_isNilForInvalidKey()
    {
        allPermutations.forEach { valet in
            XCTAssertNil(valet.string(forKey: key), "\(valet) found item that should not exit")
        }
    }

    func test_stringForKey_retrievesStringForValidKey()
    {
        allPermutations.forEach { valet in
            XCTAssertTrue(valet.set(string: passcode, forKey: key), "\(valet) could not set item in keychain")
            XCTAssertEqual(passcode, valet.string(forKey: key))
        }
    }

    func test_stringForKey_equivalentValetsCanAccessSameData()
    {
        let equalValet = Valet.valet(with: vanillaValet.identifier, accessibility: vanillaValet.accessibility)
        XCTAssertEqual(0, equalValet.allKeys().count)
        XCTAssertEqual(vanillaValet, equalValet)
        XCTAssertTrue(vanillaValet.set(string: "monster", forKey: "cookie"))
        XCTAssertEqual("monster", equalValet.string(forKey: "cookie"))
    }

    func test_stringForKey_withDifferingIdentifier_isNil()
    {
        XCTAssertTrue(vanillaValet.set(string: passcode, forKey: key))
        XCTAssertEqual(passcode, vanillaValet.string(forKey: key))
        
        let differingIdentifier = Valet.valet(with: Identifier(nonEmpty: "wat")!, accessibility: vanillaValet.accessibility)
        XCTAssertNil(differingIdentifier.string(forKey: key))
    }

    func test_stringForKey_withDifferingAccessibility_isNil()
    {
        XCTAssertTrue(vanillaValet.set(string: passcode, forKey: key))
        XCTAssertEqual(passcode, vanillaValet.string(forKey: key))
        
        let differingAccessibility = Valet.valet(with: vanillaValet.identifier, accessibility: .afterFirstUnlockThisDeviceOnly)
        XCTAssertNil(differingAccessibility.string(forKey: key))
    }

    func test_stringForKey_withEquivalentConfigurationButDifferingFlavor_isNil()
    {
        guard testEnvironmentIsSigned() else {
            return
        }
        
        XCTAssertTrue(vanillaValet.set(string: "monster", forKey: "cookie"))
        XCTAssertEqual("monster", vanillaValet.string(forKey: "cookie"))

        XCTAssertNil(anotherFlavor.string(forKey: "cookie"))
    }

    #if !os(macOS)
    func test_objectForKey_canReadItemsWithout_kSecUseDataProtectionKeychain_when_kSecUseDataProtectionKeychain_isSetToTrueInKeychainQuery() {
        let valet = Valet.valet(with: Identifier(nonEmpty: "DataProtectionTest")!, accessibility: .afterFirstUnlock)
        var dataProtectionWriteQuery = valet.keychainQuery
        #if swift(>=5.1)
        dataProtectionWriteQuery[kSecUseDataProtectionKeychain as String] = nil
        #else
        dataProtectionWriteQuery["nleg"] = nil // kSecUseDataProtectionKeychain for Xcode 9 and Xcode 10 compatibility.
        #endif

        let key = "DataProtectionKey"
        let object = Data("DataProtectionValue".utf8)
        dataProtectionWriteQuery[kSecAttrAccount as String] = key
        dataProtectionWriteQuery[kSecValueData as String] = object

        // Make sure the item is not in the keychain before we start this test
        SecItemDelete(dataProtectionWriteQuery as CFDictionary)

        XCTAssertEqual(SecItemAdd(dataProtectionWriteQuery as CFDictionary, nil), errSecSuccess)
        XCTAssertEqual(valet.object(forKey: key), object) // If this breaks, it means Apple has changed behavior of SecItemCopy. It means that we need to remove `kSecUseDataProtectionKeychain` from our query on non-Mac platforms.
    }
    #endif
    
    // MARK: set(string:forKey:)

    func test_setStringForKey_successfullyUpdatesExistingKey()
    {
        allPermutations.forEach { valet in
            XCTAssertNil(valet.string(forKey: key))
            valet.set(string: "1", forKey: key)
            XCTAssertEqual("1", valet.string(forKey: key))
            valet.set(string: "2", forKey: key)
            XCTAssertEqual("2", valet.string(forKey: key))
        }
    }
    
    func test_setStringForKey_failsForInvalidValue() {
        allPermutations.forEach { valet in
            XCTAssertFalse(valet.set(string: "", forKey: key))
        }
    }
    
    func test_setStringForKey_failsForInvalidKey() {
        allPermutations.forEach { valet in
            XCTAssertFalse(valet.set(string: passcode, forKey: ""))
        }
    }
    
    // MARK: object(forKey:)
    
    func test_objectForKey_isNilForInvalidKey() {
        allPermutations.forEach { valet in
            XCTAssertNil(valet.object(forKey: key))
        }
    }
    
    func test_objectForKey_succeedsForValidKey() {
        allPermutations.forEach { valet in
            valet.set(object: passcodeData, forKey: key)
            XCTAssertEqual(passcodeData, valet.object(forKey: key))
        }
    }
    
    func test_objectForKey_equivalentValetsCanAccessSameData() {
        let equalValet = Valet.valet(with: vanillaValet.identifier, accessibility: vanillaValet.accessibility)
        XCTAssertEqual(0, equalValet.allKeys().count)
        XCTAssertEqual(vanillaValet, equalValet)
        XCTAssertTrue(vanillaValet.set(object: passcodeData, forKey: key))
        XCTAssertEqual(passcodeData, equalValet.object(forKey: key))
    }
    
    func test_objectForKey_withDifferingIdentifier_isNil() {
        XCTAssertTrue(vanillaValet.set(object: passcodeData, forKey: key))
        XCTAssertEqual(passcodeData, vanillaValet.object(forKey: key))
        
        let differingIdentifier = Valet.valet(with: Identifier(nonEmpty: "wat")!, accessibility: vanillaValet.accessibility)
        XCTAssertNil(differingIdentifier.object(forKey: key))
    }
    
    func test_objectForKey_withDifferingAccessibility_isNil() {
        XCTAssertTrue(vanillaValet.set(object: passcodeData, forKey: key))
        XCTAssertEqual(passcodeData, vanillaValet.object(forKey: key))
        
        let differingAccessibility = Valet.valet(with: vanillaValet.identifier, accessibility: .afterFirstUnlockThisDeviceOnly)
        XCTAssertNil(differingAccessibility.object(forKey: key))
    }
    
    func test_objectForKey_withEquivalentConfigurationButDifferingFlavor_isNil() {
        guard testEnvironmentIsSigned() else {
            return
        }
        
        XCTAssertTrue(vanillaValet.set(object: passcodeData, forKey: key))
        XCTAssertEqual(passcodeData, vanillaValet.object(forKey: key))
        
        XCTAssertNil(anotherFlavor.object(forKey: key))
    }
    
    // MARK: set(object:forKey:)
    
    func test_setObjectForKey_successfullyUpdatesExistingKey() {
        allPermutations.forEach { valet in
            let firstValue = Data("first".utf8)
            let secondValue = Data("second".utf8)
            valet.set(object: firstValue, forKey: key)
            XCTAssertEqual(firstValue, valet.object(forKey: key))
            valet.set(object: secondValue, forKey: key)
            XCTAssertEqual(secondValue, valet.object(forKey: key))
        }
    }
    
    func test_setObjectForKey_failsForInvalidKey() {
        allPermutations.forEach { valet in
            XCTAssertFalse(valet.set(object: passcodeData, forKey: ""))
        }
    }
    
    func test_setObjectForKey_failsForEmptyData() {
        allPermutations.forEach { valet in
            let emptyData = Data()
            XCTAssertTrue(emptyData.isEmpty)
            XCTAssertFalse(valet.set(object: emptyData, forKey: key))
        }
    }
    
    // Mark: String/Object Equivalence
    
    func test_stringForKey_succeedsForDataBackedByString() {
        allPermutations.forEach { valet in
            XCTAssertTrue(valet.set(object: passcodeData, forKey: key))
            XCTAssertEqual(passcode, valet.string(forKey: key))
        }
    }
    
    func test_stringForKey_failsForDataNotBackedByString() {
        allPermutations.forEach { valet in
            let dictionary = [ "that's no" : "moon" ]
            let nonStringData = NSKeyedArchiver.archivedData(withRootObject: dictionary)
            XCTAssertTrue(valet.set(object: nonStringData, forKey: key))
            XCTAssertNil(valet.string(forKey: key))
        }
    }
    
    func test_objectForKey_succeedsForStrings() {
        allPermutations.forEach { valet in
            XCTAssertTrue(valet.set(string: passcode, forKey: key))
            XCTAssertEqual(passcodeData, valet.object(forKey: key))
        }
    }

    // MARK: Concurrency

    func test_concurrentSetAndRemoveOperations()
    {
        let setQueue = DispatchQueue(label: "Set String Queue", attributes: .concurrent)
        let removeQueue = DispatchQueue(label: "Remove Object Queue", attributes: .concurrent)

        for _ in 1...50 {
            setQueue.async { XCTAssertTrue(self.vanillaValet.set(string: self.passcode, forKey: self.key)) }
            removeQueue.async { XCTAssertTrue(self.vanillaValet.removeObject(forKey: self.key)) }
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
            XCTAssertTrue(self.vanillaValet.set(string: self.passcode, forKey: self.key))
            stringForKeyQueue.async {
                XCTAssertEqual(self.vanillaValet.string(forKey: self.key), self.passcode)
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
            XCTAssertTrue(backgroundValet.set(string: self.passcode, forKey: self.key))
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
        allPermutations.forEach { valet in
            XCTAssertTrue(valet.removeObject(forKey: "derp"))
        }
    }

    func test_removeObjectForKey_succeedsWhenKeyIsPresent()
    {
        allPermutations.forEach { valet in
            XCTAssertTrue(valet.set(string: passcode, forKey: key))
            XCTAssertTrue(valet.removeObject(forKey: key))
            XCTAssertNil(valet.string(forKey: key))
        }
    }

    func test_removeObjectForKey_isDistinctForDifferingAccessibility()
    {
        let differingAccessibility = Valet.valet(with: vanillaValet.identifier, accessibility: .always)
        XCTAssertTrue(vanillaValet.set(string: passcode, forKey: key))

        XCTAssertTrue(differingAccessibility.removeObject(forKey: key))

        XCTAssertEqual(passcode, vanillaValet.string(forKey: key))
    }

    func test_removeObjectForKey_isDistinctForDifferingIdentifier()
    {
        let differingIdentifier = Valet.valet(with: Identifier(nonEmpty: "no")!, accessibility: vanillaValet.accessibility)
        XCTAssertTrue(vanillaValet.set(string: passcode, forKey: key))

        XCTAssertTrue(differingIdentifier.removeObject(forKey: key))

        XCTAssertEqual(passcode, vanillaValet.string(forKey: key))
    }

    func test_removeObjectForKey_isDistinctForDifferingClasses()
    {
        guard testEnvironmentIsSigned() else {
            return
        }
        
        XCTAssertTrue(vanillaValet.set(string: passcode, forKey: key))
        XCTAssertTrue(anotherFlavor.set(string: passcode, forKey: key))

        XCTAssertTrue(vanillaValet.removeObject(forKey: key))

        XCTAssertNil(vanillaValet.string(forKey: key))
        XCTAssertEqual(passcode, anotherFlavor.string(forKey: key))
    }

    // MARK: Migration - Query

    func test_migrateObjectsMatching_failsIfQueryHasNoInputClass()
    {
        guard testEnvironmentIsSigned() else {
            return
        }

        vanillaValet.set(string: passcode, forKey: key)

        // Test for base query success.
        XCTAssertEqual(anotherFlavor.migrateObjects(matching: vanillaValet.keychainQuery, removeOnCompletion: false), .success)
        XCTAssertEqual(passcode, anotherFlavor.string(forKey: key))

        var mutableQuery = vanillaValet.keychainQuery
        mutableQuery.removeValue(forKey: kSecClass as String)

        // Without a kSecClass, the migration should fail.
        XCTAssertEqual(.invalidQuery, anotherFlavor.migrateObjects(matching: mutableQuery, removeOnCompletion: false))

        mutableQuery[kSecClass as String] = kSecClassInternetPassword
        // Without a kSecClass set to something other than kSecClassGenericPassword, the migration should fail.
        XCTAssertEqual(.invalidQuery, anotherFlavor.migrateObjects(matching: mutableQuery, removeOnCompletion: false))
    }

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

        XCTAssertEqual(noItemsFoundError, vanillaValet.migrateObjects(matching: queryWithNoMatches, removeOnCompletion: false))
        XCTAssertEqual(noItemsFoundError, vanillaValet.migrateObjects(matching: queryWithNoMatches, removeOnCompletion: true))

        // Our test Valet has not yet been written to, migration should fail:
        XCTAssertEqual(noItemsFoundError, anotherFlavor.migrateObjects(matching: vanillaValet.keychainQuery, removeOnCompletion: false))
        XCTAssertEqual(noItemsFoundError, anotherFlavor.migrateObjects(matching: vanillaValet.keychainQuery, removeOnCompletion: true))
    }

    func test_migrateObjectsMatching_bailsOutIfConflictExistsInQueryResult()
    {
        let migrationValet = Valet.valet(with: Identifier(nonEmpty: "Migrate_Me")!, accessibility: .afterFirstUnlock)
        migrationValet.removeAllObjects()
        
        XCTAssertTrue(vanillaValet.set(string: passcode, forKey: key))
        let anotherValet = Valet.valet(with: Identifier(nonEmpty: #function)!, accessibility: .whenUnlocked)
        XCTAssertTrue(anotherValet.set(string: passcode, forKey: key))

        let conflictingQuery = [
            kSecClass as String: kSecClassGenericPassword as String,
            kSecAttrAccount as String: key
        ]

        XCTAssertEqual(.duplicateKeyInQueryResult, migrationValet.migrateObjects(matching: conflictingQuery, removeOnCompletion: false))
        anotherValet.removeAllObjects()
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
        let migrationResult = vanillaValet.migrateObjects(matching: query, removeOnCompletion: false)
        
        XCTAssertEqual(migrationResult, .keyInQueryResultInvalid)
    }
    
    // MARK: Migration - Valet
    
    func test_migrateObjectsFromValet_migratesSingleKeyValuePairSuccessfully()
    {
        guard testEnvironmentIsSigned() else {
            return
        }
        
        anotherFlavor.set(string: "foo", forKey: "bar")
        _ = vanillaValet.migrateObjects(from: anotherFlavor, removeOnCompletion: false)
        _ = vanillaValet.allKeys()
        XCTAssertEqual("foo", vanillaValet.string(forKey: "bar"))
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
            anotherFlavor.set(string: value, forKey: key)
        }

        XCTAssertEqual(vanillaValet.migrateObjects(from: anotherFlavor, removeOnCompletion: false), .success)

        // Both the migration target and the previous Valet should hold all key/value pairs.
        XCTAssertEqual(vanillaValet.allKeys(), anotherFlavor.allKeys())
        for (key, value) in keyValuePairs {
            XCTAssertEqual(vanillaValet.string(forKey: key), value)
            XCTAssertEqual(anotherFlavor.string(forKey: key), value)
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
            anotherFlavor.set(string: value, forKey: key)
        }

        XCTAssertEqual(vanillaValet.migrateObjects(from: anotherFlavor, removeOnCompletion: true), .success)

        // The migration target should hold all key/value pairs, the previous Valet should be empty.
        XCTAssertEqual(0, anotherFlavor.allKeys().count)
        for (key, value) in keyValuePairs {
            XCTAssertEqual(vanillaValet.string(forKey: key), value)
            XCTAssertNil(anotherFlavor.string(forKey: key))
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
            anotherFlavor.set(string: value, forKey: key)
        }

        vanillaValet.set(string: "adrian", forKey: "yo")

        XCTAssertEqual(1, vanillaValet.allKeys().count)
        XCTAssertEqual(keyValuePairs.count, anotherFlavor.allKeys().count)

        XCTAssertEqual(.keyInQueryResultAlreadyExistsInValet, vanillaValet.migrateObjects(from: anotherFlavor, removeOnCompletion: true))

        // Neither Valet should have seen any changes.
        XCTAssertEqual(1, vanillaValet.allKeys().count)
        XCTAssertEqual(keyValuePairs.count, anotherFlavor.allKeys().count)
        
        XCTAssertEqual("adrian", vanillaValet.string(forKey: "yo"))
        for (key, value) in keyValuePairs {
            XCTAssertEqual(anotherFlavor.string(forKey: key), value)
        }
    }

    func test_migrateObjectsFromValetRemoveOnCompletion_migratesDataSuccessfullyWhenBothValetsHavePreviouslyCalled_canAccessKeychain() {
        let otherValet = Valet.valet(with: Identifier(nonEmpty: "Migrate_Me_To_Valet")!, accessibility: .afterFirstUnlock)

        // Clean up any dangling keychain items before we start this test.
        otherValet.removeAllObjects()

        let keyStringPairToMigrateMap = ["foo" : "bar", "testing" : "migration", "is" : "quite", "entertaining" : "if", "you" : "don't", "screw" : "up"]
        for (key, value) in keyStringPairToMigrateMap {
            XCTAssertTrue(otherValet.set(string: value, forKey: key))
        }

        XCTAssertTrue(vanillaValet.canAccessKeychain())
        XCTAssertTrue(otherValet.canAccessKeychain())
        XCTAssertEqual(vanillaValet.migrateObjects(from: otherValet, removeOnCompletion: false), .success)

        for (key, value) in keyStringPairToMigrateMap {
            XCTAssertEqual(vanillaValet.string(forKey: key), value )
            XCTAssertEqual(otherValet.string(forKey: key), value)
        }
    }

}
