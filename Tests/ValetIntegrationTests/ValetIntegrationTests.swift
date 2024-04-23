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


/// - Returns: `true` when the test environment is signed and does not require entitlement.
/// - The Valet Mac Tests target is left without a host app on master. Mac test host app signing requires CI to have the Developer team credentials down in keychain, which we can't easily accomplish.
/// - Note: In order to test changes locally, set the Valet Mac Tests host to Valet macOS Test Host App, delete all VAL_* keychain items in your keychain via Keychain Access.app, and run Mac tests.
func testEnvironmentIsSignedOrDoesNotRequireEntitlement() -> Bool {
    #if targetEnvironment(simulator)
    if #available(iOS 16, tvOS 16, macOS 13, watchOS 9, *) {
        return false
    }
    #endif
    
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
        simulatorVersionInfo.contains("iOS 13")
        || simulatorVersionInfo.contains("tvOS 13")
        || simulatorVersionInfo.contains("iOS 15")
        || simulatorVersionInfo.contains("tvOS 15")
        || simulatorVersionInfo.contains("iOS 16")
        || simulatorVersionInfo.contains("tvOS 16")
        || simulatorVersionInfo.contains("iOS 17")
        || simulatorVersionInfo.contains("tvOS 17")
    {
        // iOS 13, tvOS 13, iOS 15, tvOS 15, and later simulators fail to store items in a Valet that has a
        // kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly flag. The documentation for this flag says:
        // "No items can be stored in this class on devices without a passcode". I currently do not
        // understand why prior simulators work with this flag, given that no simulators have a passcode.
        // Tests that fail this check must be run on device.
        return false

    } else {
        return true
    }
}


internal extension Valet {

    // MARK: Shared Access Group

    static var sharedAccessGroupIdentifier: SharedGroupIdentifier = {
        #if os(iOS)
        return SharedGroupIdentifier(appIDPrefix: "9XUJ7M53NG", nonEmptyGroup: "com.squareup.Valet-iOS-Test-Host-App")!
        #elseif os(macOS)
        return SharedGroupIdentifier(appIDPrefix: "9XUJ7M53NG", nonEmptyGroup: "com.squareup.Valet-macOS-Test-Host-App")!
        #elseif os(tvOS)
        return SharedGroupIdentifier(appIDPrefix: "9XUJ7M53NG", nonEmptyGroup: "com.squareup.Valet-tvOS-Test-Host-App")!
        #elseif os(watchOS)
        return SharedGroupIdentifier(appIDPrefix: "9XUJ7M53NG", nonEmptyGroup: "com.squareup.ValetTouchIDTestApp.watchkitapp.watchkitextension")!
        #else
        XCTFail()
        #endif
    }()

    static var sharedAccessGroupIdentifier2: SharedGroupIdentifier = {
        #if os(iOS)
        return SharedGroupIdentifier(appIDPrefix: "9XUJ7M53NG", nonEmptyGroup: "com.squareup.Valet-iOS-Test-Host-App2")!
        #elseif os(macOS)
        return SharedGroupIdentifier(appIDPrefix: "9XUJ7M53NG", nonEmptyGroup: "com.squareup.Valet-macOS-Test-Host-App2")!
        #elseif os(tvOS)
        return SharedGroupIdentifier(appIDPrefix: "9XUJ7M53NG", nonEmptyGroup: "com.squareup.Valet-tvOS-Test-Host-App2")!
        #elseif os(watchOS)
        return SharedGroupIdentifier(appIDPrefix: "9XUJ7M53NG", nonEmptyGroup: "com.squareup.ValetTouchIDTestApp.watchkitapp.watchkitextension2")!
        #else
        XCTFail()
        #endif
    }()

    // MARK: Shared App Group

    static var sharedAppGroupIdentifier: SharedGroupIdentifier = {
        #if os(iOS)
        return SharedGroupIdentifier(groupPrefix: "group", nonEmptyGroup: "valet.test")!
        #elseif os(macOS)
        return SharedGroupIdentifier(groupPrefix: "9XUJ7M53NG", nonEmptyGroup: "valet.test")!
        #elseif os(tvOS)
        return SharedGroupIdentifier(groupPrefix: "group", nonEmptyGroup: "valet.test")!
        #elseif os(watchOS)
        return SharedGroupIdentifier(groupPrefix: "group", nonEmptyGroup: "valet.test")!
        #else
        XCTFail()
        #endif
    }()

}


class ValetIntegrationTests: XCTestCase
{
    static let sharedAccessGroupIdentifier = Valet.sharedAccessGroupIdentifier
    static let sharedAccessGroupIdentifier2 = Valet.sharedAccessGroupIdentifier2
    static let sharedAppGroupIdentifier = Valet.sharedAppGroupIdentifier
    var allPermutations: [Valet] {
        var signedPermutations = Valet.permutations(with: ValetIntegrationTests.sharedAccessGroupIdentifier)
        signedPermutations += Valet.permutations(with: ValetIntegrationTests.sharedAccessGroupIdentifier, identifier: Identifier(nonEmpty: "UniquenessIdentifier"))
        #if !os(macOS)
        // We can't test app groups on macOS without a paid developer account, which we don't have.
        signedPermutations += Valet.permutations(with: ValetIntegrationTests.sharedAppGroupIdentifier)
        #endif
        return Valet.permutations(with: ValetIntegrationTests.sharedAccessGroupIdentifier.asIdentifier)
            + (testEnvironmentIsSignedOrDoesNotRequireEntitlement()
                ? signedPermutations
                : [])
    }

    let vanillaValet = Valet.valet(with: sharedAccessGroupIdentifier.asIdentifier, accessibility: .whenUnlocked)
    // FIXME: Need a different flavor (Synchronizable must be tested in a signed environment)
    let anotherFlavor = Valet.iCloudValet(with: sharedAccessGroupIdentifier.asIdentifier, accessibility: .whenUnlocked)

    let key = "key"
    let passcode = "topsecret"
    lazy var passcodeData: Data = { return Data(self.passcode.utf8) }()
    
    // MARK: XCTestCase

    override func setUp()
    {
        super.setUp()

        let permutations: [Valet]
        if testEnvironmentIsSignedOrDoesNotRequireEntitlement() {
            permutations = [vanillaValet, anotherFlavor] + allPermutations
        } else {
            permutations = [vanillaValet] + allPermutations
        }
        permutations.forEach { testingValet in
            do {
                try testingValet.removeAllObjects()
            } catch {
                XCTFail("Error removing objects from Valet \(testingValet): \(error)")
            }
        }

        XCTAssertEqual(try? vanillaValet.allKeys(), Set())
        XCTAssertEqual(try? anotherFlavor.allKeys(), Set())
    }

    // MARK: Initialization

    func test_init_createsCorrectBackingService() {
        let identifier = ValetTests.identifier

        Accessibility.allCases.forEach { accessibility in
            let backingService = Valet.valet(with: identifier, accessibility: accessibility).service
            XCTAssertEqual(backingService, Service.standard(identifier, .valet(accessibility)))
        }
    }

    func test_init_createsCorrectBackingService_sharedAccess() {
        let identifier = Valet.sharedAccessGroupIdentifier

        Accessibility.allCases.forEach { accessibility in
            let backingService = Valet.sharedGroupValet(with: identifier, accessibility: accessibility).service
            XCTAssertEqual(backingService, Service.sharedGroup(identifier, nil, .valet(accessibility)))
        }
    }

    func test_init_createsCorrectBackingService_sharedAccess_withIdentifier() {
        let sharedIdentifier = Valet.sharedAccessGroupIdentifier
        let identifier = Identifier(nonEmpty: "id")

        Accessibility.allCases.forEach { accessibility in
            let backingService = Valet.sharedGroupValet(with: sharedIdentifier, identifier: identifier, accessibility: accessibility).service
            XCTAssertEqual(backingService, Service.sharedGroup(sharedIdentifier, identifier, .valet(accessibility)))
        }
    }

    func test_init_createsCorrectBackingService_cloud() {
        let identifier = ValetTests.identifier

        CloudAccessibility.allCases.forEach { accessibility in
            let backingService = Valet.iCloudValet(with: identifier, accessibility: accessibility).service
            XCTAssertEqual(backingService, Service.standard(identifier, .iCloud(accessibility)))
        }
    }

    func test_init_createsCorrectBackingService_cloudSharedAccess() {
        let identifier = Valet.sharedAccessGroupIdentifier

        CloudAccessibility.allCases.forEach { accessibility in
            let backingService = Valet.iCloudSharedGroupValet(with: identifier, accessibility: accessibility).service
            XCTAssertEqual(backingService, Service.sharedGroup(identifier, nil, .iCloud(accessibility)))
        }
    }

    func test_init_createsCorrectBackingService_cloudSharedAccess_withIdentifier() {
        let groupIdentifier = Valet.sharedAccessGroupIdentifier
        let identifier = Identifier(nonEmpty: "id")

        CloudAccessibility.allCases.forEach { accessibility in
            let backingService = Valet.iCloudSharedGroupValet(with: groupIdentifier, identifier: identifier, accessibility: accessibility).service
            XCTAssertEqual(backingService, Service.sharedGroup(groupIdentifier, identifier, .iCloud(accessibility)))
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
        guard testEnvironmentIsSignedOrDoesNotRequireEntitlement() else {
            return
        }

        Valet.permutations(with: Valet.sharedAccessGroupIdentifier).forEach { permutation in
            XCTAssertTrue(permutation.canAccessKeychain(), "\(permutation) could not access keychain.")
        }
    }

    #if !os(macOS)
    // We can't test app groups on macOS without a paid developer account, which we don't have.
    func test_canAccessKeychain_sharedAppGroup()
    {
        guard testEnvironmentIsSignedOrDoesNotRequireEntitlement() else {
            return
        }

        Valet.permutations(with: Valet.sharedAppGroupIdentifier).forEach { permutation in
            XCTAssertTrue(permutation.canAccessKeychain(), "\(permutation) could not access keychain.")
        }
    }
    #endif

    func test_canAccessKeychain_Performance()
    {
        measure {
            _ = self.vanillaValet.canAccessKeychain()
        }
    }

    // MARK: containsObjectForKey

    func test_containsObjectForKey() throws
    {
        try allPermutations.forEach { valet in
            XCTAssertFalse(try valet.containsObject(forKey: key), "\(valet) found object for key that should not exist")

            try valet.setString(passcode, forKey: key)
            XCTAssertTrue(try valet.containsObject(forKey: key), "\(valet) could not find item it has set in keychain")

            try valet.removeObject(forKey: key)
            XCTAssertFalse(try valet.containsObject(forKey: key), "\(valet) found removed item in keychain")
        }
    }

    // MARK: allKeys

    func test_allKeys() throws
    {
        try allPermutations.forEach { valet in
            XCTAssertEqual(try valet.allKeys(), Set(), "\(valet) found keys that should not exist")

            try valet.setString(passcode, forKey: key)
            XCTAssertEqual(try valet.allKeys(), Set(arrayLiteral: key))

            try valet.setString("monster", forKey: "cookie")
            XCTAssertEqual(try valet.allKeys(), Set(arrayLiteral: key, "cookie"))

            try valet.removeAllObjects()
            XCTAssertEqual(try valet.allKeys(), Set(), "\(valet) found keys that should not exist")
        }
    }
    
    func test_allKeys_doesNotReflectValetImplementationDetails() throws {
        try allPermutations.forEach { valet in
            // Under the hood, Valet inserts a canary when calling `canAccessKeychain()` - this should not appear in `allKeys()`.
            _ = valet.canAccessKeychain()
            XCTAssertEqual(try valet.allKeys(), Set(), "\(valet) found keys that should not exist")
        }
    }

    func test_allKeys_remainsUntouchedForUnequalValets() throws
    {
        try vanillaValet.setString(passcode, forKey: key)
        XCTAssertEqual(try vanillaValet.allKeys(), Set(arrayLiteral: key))

        // Different Identifier
        let differingIdentifier = Valet.valet(with: Identifier(nonEmpty: "nope")!, accessibility: vanillaValet.accessibility)
        XCTAssertEqual(try differingIdentifier.allKeys(), Set())

        // Different Accessibility
        let differingAccessibility = Valet.valet(with: vanillaValet.identifier, accessibility: .whenUnlockedThisDeviceOnly)
        XCTAssertEqual(try differingAccessibility.allKeys(), Set())

        // Different Kind
        XCTAssertEqual(try anotherFlavor.allKeys(), Set())
    }

    // MARK: string(forKey:)

    func test_stringForKey_throwsItemNotFoundForKeyWithNoValue() throws
    {
        try allPermutations.forEach { valet in
            XCTAssertThrowsError(try valet.string(forKey: key), "\(valet) found item that should not exit") { error in
                XCTAssertEqual(error as? KeychainError, .itemNotFound)
            }
        }
    }

    func test_stringForKey_retrievesStringForValidKey() throws
    {
        try allPermutations.forEach { valet in
            try valet.setString(passcode, forKey: key)
            XCTAssertEqual(passcode, try valet.string(forKey: key))
        }
    }

    func test_stringForKey_equivalentValetsCanAccessSameData() throws
    {
        let equalValet = Valet.valet(with: vanillaValet.identifier, accessibility: vanillaValet.accessibility)
        XCTAssertEqual(0, try equalValet.allKeys().count)
        XCTAssertEqual(vanillaValet, equalValet)
        try vanillaValet.setString("monster", forKey: "cookie")
        XCTAssertEqual("monster", try equalValet.string(forKey: "cookie"))
    }

    func test_stringForKey_withDifferingIdentifier_throwsItemNotFound() throws
    {
        try vanillaValet.setString(passcode, forKey: key)
        XCTAssertEqual(passcode, try vanillaValet.string(forKey: key))
        
        let differingIdentifier = Valet.valet(with: Identifier(nonEmpty: "wat")!, accessibility: vanillaValet.accessibility)
        XCTAssertThrowsError(try differingIdentifier.string(forKey: key)) { error in
            XCTAssertEqual(error as? KeychainError, .itemNotFound)
        }
    }

    func test_stringForKey_withDifferingIdentifierInSameAccessGroup_throwsItemNotFound() throws
    {
        guard testEnvironmentIsSignedOrDoesNotRequireEntitlement() else {
            return
        }

        let valet1 = Valet.sharedGroupValet(with: Self.sharedAccessGroupIdentifier, identifier: Identifier(nonEmpty: "valet1")!, accessibility: vanillaValet.accessibility)
        let valet2 = Valet.sharedGroupValet(with: Self.sharedAccessGroupIdentifier, identifier: Identifier(nonEmpty: "valet2")!, accessibility: vanillaValet.accessibility)

        try valet1.setString(passcode, forKey: key)
        XCTAssertEqual(passcode, try valet1.string(forKey: key))

        XCTAssertThrowsError(try valet2.string(forKey: key)) { error in
            XCTAssertEqual(error as? KeychainError, .itemNotFound)
        }
    }

    func test_stringForKey_withSameIdentifierInDifferentAccessGroup_throwsItemNotFound() throws
    {
        guard testEnvironmentIsSignedOrDoesNotRequireEntitlement() else {
            return
        }

        let valet1 = Valet.sharedGroupValet(with: Self.sharedAccessGroupIdentifier, identifier: Identifier(nonEmpty: "valet1")!, accessibility: vanillaValet.accessibility)
        let valet2 = Valet.sharedGroupValet(with: Self.sharedAccessGroupIdentifier2, identifier: Identifier(nonEmpty: "valet1")!, accessibility: vanillaValet.accessibility)

        try valet1.setString(passcode, forKey: key)
        XCTAssertEqual(passcode, try valet1.string(forKey: key))

        XCTAssertThrowsError(try valet2.string(forKey: key)) { error in
            XCTAssertEqual(error as? KeychainError, .itemNotFound)
        }
    }

    func test_stringForKey_withDifferingIdentifierInSameiCloudGroup_throwsItemNotFound() throws
    {
        guard testEnvironmentIsSignedOrDoesNotRequireEntitlement() else {
            return
        }

        let valet1 = Valet.iCloudSharedGroupValet(with: Self.sharedAccessGroupIdentifier, identifier: Identifier(nonEmpty: "valet1")!, accessibility: .afterFirstUnlock)
        let valet2 = Valet.iCloudSharedGroupValet(with: Self.sharedAccessGroupIdentifier, identifier: Identifier(nonEmpty: "valet2")!, accessibility: .afterFirstUnlock)

        try valet1.setString(passcode, forKey: key)
        XCTAssertEqual(passcode, try valet1.string(forKey: key))

        XCTAssertThrowsError(try valet2.string(forKey: key)) { error in
            XCTAssertEqual(error as? KeychainError, .itemNotFound)
        }
    }

    func test_stringForKey_withDifferingAccessibility_throwsItemNotFound() throws
    {
        try vanillaValet.setString(passcode, forKey: key)
        XCTAssertEqual(passcode, try vanillaValet.string(forKey: key))
        
        let differingAccessibility = Valet.valet(with: vanillaValet.identifier, accessibility: .afterFirstUnlockThisDeviceOnly)
        XCTAssertThrowsError(try differingAccessibility.string(forKey: key)) { error in
            XCTAssertEqual(error as? KeychainError, .itemNotFound)
        }
    }

    func test_stringForKey_withEquivalentConfigurationButDifferingFlavor_throwsItemNotFound() throws
    {
        guard testEnvironmentIsSignedOrDoesNotRequireEntitlement() else {
            return
        }
        
        try vanillaValet.setString("monster", forKey: "cookie")
        XCTAssertEqual("monster", try vanillaValet.string(forKey: "cookie"))

        XCTAssertThrowsError(try anotherFlavor.string(forKey: "cookie")) { error in
            XCTAssertEqual(error as? KeychainError, .itemNotFound)
        }
    }

    #if !os(macOS)
    func test_objectForKey_canReadItemsWithout_kSecUseDataProtectionKeychain_when_kSecUseDataProtectionKeychain_isSetToTrueInKeychainQuery() throws {
        let valet = Valet.valet(with: Identifier(nonEmpty: "DataProtectionTest")!, accessibility: .afterFirstUnlock)
        var dataProtectionWriteQuery = valet.baseKeychainQuery
        if #available(iOS 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, *) {
            dataProtectionWriteQuery[kSecUseDataProtectionKeychain as String] = nil
        }

        let key = "DataProtectionKey"
        let object = Data("DataProtectionValue".utf8)
        dataProtectionWriteQuery[kSecAttrAccount as String] = key
        dataProtectionWriteQuery[kSecValueData as String] = object

        // Make sure the item is not in the keychain before we start this test
        SecItemDelete(dataProtectionWriteQuery as CFDictionary)

        XCTAssertEqual(SecItemAdd(dataProtectionWriteQuery as CFDictionary, nil), errSecSuccess)
        XCTAssertEqual(try valet.object(forKey: key), object) // If this breaks, it means Apple has changed behavior of SecItemCopy. It means that we need to remove `kSecUseDataProtectionKeychain` from our query on non-Mac platforms.
    }
    #endif
    
    // MARK: set(string:forKey:)

    func test_setStringForKey_successfullyUpdatesExistingKey() throws
    {
        try allPermutations.forEach { valet in
            XCTAssertThrowsError(try valet.string(forKey: key)) { error in
                XCTAssertEqual(error as? KeychainError, .itemNotFound)
            }

            try valet.setString("1", forKey: key)
            XCTAssertEqual("1", try valet.string(forKey: key))
            try valet.setString("2", forKey: key)
            XCTAssertEqual("2", try valet.string(forKey: key))
        }
    }
    
    func test_setStringForKey_throwsEmptyValueOnInvalidValue() throws {
        try allPermutations.forEach { valet in
            XCTAssertThrowsError(try valet.setString("", forKey: key)) { error in
                XCTAssertEqual(error as? KeychainError, KeychainError.emptyValue)
            }
        }
    }

    func test_setStringForKey_throwsEmptyKeyOnInvalidKey() throws {
        try allPermutations.forEach { valet in
            XCTAssertThrowsError(try valet.setString(passcode, forKey: "")) { error in
                XCTAssertEqual(error as? KeychainError, KeychainError.emptyKey)
            }
        }
    }

    // MARK: object(forKey:)

    func test_objectForKey_throwsItemNotFoundWhenNoObjectExists() throws {
        try allPermutations.forEach { valet in
            XCTAssertThrowsError(try valet.object(forKey: key)) { error in
                XCTAssertEqual(error as? KeychainError, .itemNotFound)
            }
        }
    }
    
    func test_objectForKey_succeedsForValidKey() throws {
        try allPermutations.forEach { valet in
            try valet.setObject(passcodeData, forKey: key)
            XCTAssertEqual(passcodeData, try valet.object(forKey: key))
        }
    }
    
    func test_objectForKey_equivalentValetsCanAccessSameData() throws {
        let equalValet = Valet.valet(with: vanillaValet.identifier, accessibility: vanillaValet.accessibility)
        XCTAssertEqual(0, try equalValet.allKeys().count)
        XCTAssertEqual(vanillaValet, equalValet)
        try vanillaValet.setObject(passcodeData, forKey: key)
        XCTAssertEqual(passcodeData, try equalValet.object(forKey: key))
    }
    
    func test_objectForKey_withDifferingIdentifier_throwsItemNotFound() throws {
        try allPermutations.forEach { valet in
            try valet.setObject(passcodeData, forKey: key)
            XCTAssertEqual(passcodeData, try valet.object(forKey: key))

            let differingIdentifier = Valet.valet(with: Identifier(nonEmpty: "wat")!, accessibility: valet.accessibility)
            XCTAssertThrowsError(try differingIdentifier.object(forKey: key)) { error in
                XCTAssertEqual(error as? KeychainError, .itemNotFound)
            }
        }
    }

    func test_objectForKey_withDifferingIdentifierInSameAccessGroup_throwsItemNotFound() throws
    {
        guard testEnvironmentIsSignedOrDoesNotRequireEntitlement() else {
            return
        }

        let valet1 = Valet.sharedGroupValet(with: Self.sharedAccessGroupIdentifier, identifier: Identifier(nonEmpty: "valet1")!, accessibility: vanillaValet.accessibility)
        let valet2 = Valet.sharedGroupValet(with: Self.sharedAccessGroupIdentifier, identifier: Identifier(nonEmpty: "valet2")!, accessibility: vanillaValet.accessibility)

        try valet1.setObject(passcodeData, forKey: key)
        XCTAssertEqual(passcodeData, try valet1.object(forKey: key))

        XCTAssertThrowsError(try valet2.object(forKey: key)) { error in
            XCTAssertEqual(error as? KeychainError, .itemNotFound)
        }
    }

    func test_objectForKey_withDifferingIdentifierInSameiCloudGroup_throwsItemNotFound() throws
    {
        guard testEnvironmentIsSignedOrDoesNotRequireEntitlement() else {
            return
        }

        let valet1 = Valet.iCloudSharedGroupValet(with: Self.sharedAccessGroupIdentifier, identifier: Identifier(nonEmpty: "valet1")!, accessibility: .afterFirstUnlock)
        let valet2 = Valet.iCloudSharedGroupValet(with: Self.sharedAccessGroupIdentifier, identifier: Identifier(nonEmpty: "valet2")!, accessibility: .afterFirstUnlock)

        try valet1.setObject(passcodeData, forKey: key)
        XCTAssertEqual(passcodeData, try valet1.object(forKey: key))

        XCTAssertThrowsError(try valet2.object(forKey: key)) { error in
            XCTAssertEqual(error as? KeychainError, .itemNotFound)
        }
    }
    
    func test_objectForKey_withDifferingAccessibility_throwsItemNotFound() throws {
        try vanillaValet.setObject(passcodeData, forKey: key)
        XCTAssertEqual(passcodeData, try vanillaValet.object(forKey: key))
        
        let differingAccessibility = Valet.valet(with: vanillaValet.identifier, accessibility: .afterFirstUnlockThisDeviceOnly)
        XCTAssertThrowsError(try differingAccessibility.object(forKey: key)) { error in
            XCTAssertEqual(error as? KeychainError, .itemNotFound)
        }
    }
    
    func test_objectForKey_withEquivalentConfigurationButDifferingFlavor_throwsItemNotFound() throws {
        guard testEnvironmentIsSignedOrDoesNotRequireEntitlement() else {
            return
        }
        
        try vanillaValet.setObject(passcodeData, forKey: key)
        XCTAssertEqual(passcodeData, try vanillaValet.object(forKey: key))

        XCTAssertThrowsError(try anotherFlavor.object(forKey: key)) { error in
            XCTAssertEqual(error as? KeychainError, .itemNotFound)
        }
    }
    
    // MARK: set(object:forKey:)

    func test_setObjectForKey_successfullyUpdatesExistingKey() throws {
        try allPermutations.forEach { valet in
            let firstValue = Data("first".utf8)
            let secondValue = Data("second".utf8)
            try valet.setObject(firstValue, forKey: key)
            XCTAssertEqual(firstValue, try valet.object(forKey: key))
            try valet.setObject(secondValue, forKey: key)
            XCTAssertEqual(secondValue, try valet.object(forKey: key))
        }
    }
    
    func test_setObjectForKey_throwsEmptyKeyOnInvalidKey() throws {
        try allPermutations.forEach { valet in
            XCTAssertThrowsError(try valet.setObject(passcodeData, forKey: "")) { error in
                XCTAssertEqual(error as? KeychainError, .emptyKey)
            }
        }
    }
    
    func test_setObjectForKey_throwsEmptyValueOnEmptyData() throws {
        try allPermutations.forEach { valet in
            let emptyData = Data()
            XCTAssertTrue(emptyData.isEmpty)
            XCTAssertThrowsError(try valet.setObject(emptyData, forKey: key)) { error in
                XCTAssertEqual(error as? KeychainError, .emptyValue)
            }
        }
    }
    
    // Mark: String/Object Equivalence
    
    func test_stringForKey_succeedsForDataBackedByString() throws {
        try allPermutations.forEach { valet in
            try valet.setObject(passcodeData, forKey: key)
            XCTAssertEqual(passcode, try valet.string(forKey: key))
        }
    }
    
    func test_stringForKey_failsForDataNotBackedByString() throws {
        try allPermutations.forEach { valet in
            let dictionary = [ "that's no" : "moon" ]
            let nonStringData = NSKeyedArchiver.archivedData(withRootObject: dictionary)
            try valet.setObject(nonStringData, forKey: key)
            XCTAssertThrowsError(try valet.string(forKey: key)) { error in
                XCTAssertEqual(error as? KeychainError, .itemNotFound)
            }
        }
    }
    
    func test_objectForKey_succeedsForStrings() throws {
        try allPermutations.forEach { valet in
            try valet.setString(passcode, forKey: key)
            XCTAssertEqual(passcodeData, try valet.object(forKey: key))
        }
    }

    // MARK: Concurrency

    func test_concurrentSetAndRemoveOperations()
    {
        let setQueue = DispatchQueue(label: "Set String Queue", attributes: .concurrent)
        let removeQueue = DispatchQueue(label: "Remove Object Queue", attributes: .concurrent)

        for _ in 1...50 {
            setQueue.async {
                do {
                    try self.vanillaValet.setString(self.passcode, forKey: self.key)
                } catch {
                    XCTFail("Threw \(error) trying to write value")
                }
            }
            removeQueue.async {
                do {
                    try self.vanillaValet.removeObject(forKey: self.key)
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
                try self.vanillaValet.setString(self.passcode, forKey: self.key)
            } catch {
                XCTFail("Threw \(error) trying to set value")
            }

            stringForKeyQueue.async {
                do {
                    let stringForKey = try self.vanillaValet.string(forKey: self.key)
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
                try backgroundValet.setString(self.passcode, forKey: self.key)
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
        try allPermutations.forEach { valet in
            try valet.removeObject(forKey: "derp")
        }
    }

    func test_removeObjectForKey_succeedsWhenKeyIsPresent() throws
    {
        try allPermutations.forEach { valet in
            try valet.setString(passcode, forKey: key)
            try valet.removeObject(forKey: key)
            XCTAssertThrowsError(try valet.string(forKey: key)) { error in
                XCTAssertEqual(error as? KeychainError, .itemNotFound)
            }
        }
    }

    func test_removeObjectForKey_isDistinctForDifferingAccessibility() throws
    {
        let differingAccessibility = Valet.valet(with: vanillaValet.identifier, accessibility: .whenUnlockedThisDeviceOnly)
        try vanillaValet.setString(passcode, forKey: key)

        try differingAccessibility.removeObject(forKey: key)

        XCTAssertEqual(passcode, try vanillaValet.string(forKey: key))
    }

    func test_removeObjectForKey_isDistinctForDifferingIdentifier() throws
    {
        let differingIdentifier = Valet.valet(with: Identifier(nonEmpty: "no")!, accessibility: vanillaValet.accessibility)
        try vanillaValet.setString(passcode, forKey: key)

        try differingIdentifier.removeObject(forKey: key)

        XCTAssertEqual(passcode, try vanillaValet.string(forKey: key))
    }

    func test_removeObjectForKey_isDistinctForDifferingIdentifierInSameAccessGroup() throws
    {
        guard testEnvironmentIsSignedOrDoesNotRequireEntitlement() else {
            return
        }

        let valet1 = Valet.sharedGroupValet(with: Self.sharedAccessGroupIdentifier, identifier: Identifier(nonEmpty: "valet1")!, accessibility: vanillaValet.accessibility)
        let valet2 = Valet.sharedGroupValet(with: Self.sharedAccessGroupIdentifier, identifier: Identifier(nonEmpty: "valet2")!, accessibility: vanillaValet.accessibility)

        try valet1.setString(passcode, forKey: key)
        try valet2.setString(passcode, forKey: key)

        try valet2.removeObject(forKey: key)

        XCTAssertEqual(passcode, try valet1.string(forKey: key))
        XCTAssertThrowsError(try valet2.string(forKey: key)) { error in
            XCTAssertEqual(error as? KeychainError, .itemNotFound)
        }
    }

    func test_removeObjectForKey_isDistinctForDifferingIdentifierInSameiCloudGroup() throws
    {
        guard testEnvironmentIsSignedOrDoesNotRequireEntitlement() else {
            return
        }

        let valet1 = Valet.iCloudSharedGroupValet(with: Self.sharedAccessGroupIdentifier, identifier: Identifier(nonEmpty: "valet1")!, accessibility: .afterFirstUnlock)
        let valet2 = Valet.iCloudSharedGroupValet(with: Self.sharedAccessGroupIdentifier, identifier: Identifier(nonEmpty: "valet2")!, accessibility: .afterFirstUnlock)

        try valet1.setString(passcode, forKey: key)
        try valet2.setString(passcode, forKey: key)

        try valet2.removeObject(forKey: key)

        XCTAssertEqual(passcode, try valet1.string(forKey: key))
        XCTAssertThrowsError(try valet2.string(forKey: key)) { error in
            XCTAssertEqual(error as? KeychainError, .itemNotFound)
        }
    }

    func test_removeObjectForKey_isDistinctForDifferingClasses() throws
    {
        guard testEnvironmentIsSignedOrDoesNotRequireEntitlement() else {
            return
        }
        
        try vanillaValet.setString(passcode, forKey: key)
        try anotherFlavor.setString(passcode, forKey: key)

        try vanillaValet.removeObject(forKey: key)

        XCTAssertThrowsError(try vanillaValet.string(forKey: key)) { error in
            XCTAssertEqual(error as? KeychainError, .itemNotFound)
        }
        XCTAssertEqual(passcode, try anotherFlavor.string(forKey: key))
    }

    // MARK: Migration - Query

    func test_migrateObjectsMatching_failsIfQueryHasNoInputClass() throws
    {
        guard testEnvironmentIsSignedOrDoesNotRequireEntitlement() else {
            return
        }

        try vanillaValet.setString(passcode, forKey: key)

        let valetKeychainQuery = vanillaValet.baseKeychainQuery

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
        guard testEnvironmentIsSignedOrDoesNotRequireEntitlement() else {
            return
        }

        let queryWithNoMatches = [
            kSecClass as String: kSecClassGenericPassword as String,
            kSecAttrService as String: "Valet_Does_Not_Exist"
        ]

        XCTAssertThrowsError(try vanillaValet.migrateObjects(matching: queryWithNoMatches, removeOnCompletion: false)) { error in
            XCTAssertEqual(error as? KeychainError, .itemNotFound)
        }
        XCTAssertThrowsError(try vanillaValet.migrateObjects(matching: queryWithNoMatches, removeOnCompletion: true)) { error in
            XCTAssertEqual(error as? KeychainError, .itemNotFound)
        }

        let valetKeychainQuery = vanillaValet.baseKeychainQuery

        // Our test Valet has not yet been written to, migration should fail:
        XCTAssertThrowsError(try anotherFlavor.migrateObjects(matching: valetKeychainQuery, removeOnCompletion: false)) { error in
            XCTAssertEqual(error as? KeychainError, .itemNotFound)
        }
        XCTAssertThrowsError(try anotherFlavor.migrateObjects(matching: valetKeychainQuery, removeOnCompletion: true)) { error in
            XCTAssertEqual(error as? KeychainError, .itemNotFound)
        }
    }

    func test_migrateObjectsMatching_bailsOutIfConflictExistsToMigrate() throws
    {
        let migrationValet = Valet.valet(with: Identifier(nonEmpty: "Migrate_Me")!, accessibility: .afterFirstUnlock)
        try migrationValet.removeAllObjects()

        let anotherValet = Valet.valet(with: Identifier(nonEmpty: #function)!, accessibility: .whenUnlocked)
        try vanillaValet.setString(passcode, forKey: key)
        try anotherValet.setString(passcode, forKey:key)

        let conflictingQuery = [
            kSecClass as String: kSecClassGenericPassword as String,
            kSecAttrAccount as String: key
        ]

        XCTAssertThrowsError(try migrationValet.migrateObjects(matching: conflictingQuery, removeOnCompletion: false)) { error in
            XCTAssertEqual(error as? MigrationError, .duplicateKeyToMigrate)
        }
    }

    func test_migrateObjectsMatching_withAccountNameAsData_raisesException() throws
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
        XCTAssertThrowsError(try vanillaValet.migrateObjects(matching: query, removeOnCompletion: false)) { error in
            XCTAssertEqual(error as? MigrationError, .keyToMigrateInvalid)
        }
    }

    func test_migrateObjectsMatchingCompactMap_successfullyMigratesTransformedKey() throws {
        guard testEnvironmentIsSignedOrDoesNotRequireEntitlement() else {
            return
        }

        let migrationValet = Valet.valet(with: Identifier(nonEmpty: "Migrate_Me")!, accessibility: .afterFirstUnlock)
        try migrationValet.removeAllObjects()

        let anotherValet = Valet.valet(with: Identifier(nonEmpty: #function)!, accessibility: .whenUnlocked)
        try anotherValet.removeAllObjects()

        try migrationValet.setString("password", forKey: #function)

        try anotherValet.migrateObjects(matching: [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: migrationValet.service.description,
        ]) { pair in
            MigratableKeyValuePair<String>(key: "transformed_key", value: pair.value)
        }

        XCTAssertEqual(try? anotherValet.string(forKey: "transformed_key"), "password")
    }

    func test_migrateObjectsMatchingCompactMap_successfullyMigratesTransformedValue() throws {
        guard testEnvironmentIsSignedOrDoesNotRequireEntitlement() else {
            return
        }

        let migrationValet = Valet.valet(with: Identifier(nonEmpty: "Migrate_Me")!, accessibility: .afterFirstUnlock)
        try migrationValet.removeAllObjects()

        let anotherValet = Valet.valet(with: Identifier(nonEmpty: #function)!, accessibility: .whenUnlocked)
        try anotherValet.removeAllObjects()

        try migrationValet.setString("password", forKey: #function)

        try anotherValet.migrateObjects(matching: [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: migrationValet.service.description,
        ]) { _ in
            MigratableKeyValuePair<String>(key: #function, value: "12345")
        }

        XCTAssertEqual(try? anotherValet.string(forKey: #function), "12345")
    }

    func test_migrateObjectsMatchingCompactMap_returningNilDoesNotMigratePair() throws {
        guard testEnvironmentIsSignedOrDoesNotRequireEntitlement() else {
            return
        }

        let migrationValet = Valet.valet(with: Identifier(nonEmpty: "Migrate_Me")!, accessibility: .afterFirstUnlock)
        try migrationValet.removeAllObjects()

        let anotherValet = Valet.valet(with: Identifier(nonEmpty: #function)!, accessibility: .whenUnlocked)
        try anotherValet.removeAllObjects()

        let key1 = #function + "1"
        let key2 = #function + "2"
        try migrationValet.setString("password1", forKey: key1)
        try migrationValet.setString("password2", forKey: key2)

        try anotherValet.migrateObjects(matching: [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: migrationValet.service.description,
        ]) { input in
            guard let key = input.key as? String else {
                return nil
            }
            if key == key1 {
                return nil
            } else {
                return MigratableKeyValuePair<String>(key: key, value: input.value)
            }
        }

        XCTAssertFalse(try anotherValet.containsObject(forKey: key1))
        XCTAssertEqual(try? anotherValet.string(forKey: key2), "password2")
    }

    func test_migrateObjectsMatchingCompactMap_throwingErrorPreventsAllMigration() throws {
        guard testEnvironmentIsSignedOrDoesNotRequireEntitlement() else {
            return
        }

        let migrationValet = Valet.valet(with: Identifier(nonEmpty: "Migrate_Me")!, accessibility: .afterFirstUnlock)
        try migrationValet.removeAllObjects()

        let anotherValet = Valet.valet(with: Identifier(nonEmpty: #function)!, accessibility: .whenUnlocked)
        try anotherValet.removeAllObjects()

        let key1 = #function + "1"
        let key2 = #function + "2"
        try migrationValet.setString("password1", forKey: key1)
        try migrationValet.setString("password2", forKey: key2)

        try? anotherValet.migrateObjects(matching: [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: migrationValet.service.description,
        ]) { input in
            guard let key = input.key as? String else {
                return nil
            }
            if key == key1 {
                return MigratableKeyValuePair<String>(key: key, value: input.value)
            } else {
                struct FakeError: Error {}
                throw FakeError()
            }
        }

        XCTAssertFalse(try anotherValet.containsObject(forKey: key1))
        XCTAssertFalse(try anotherValet.containsObject(forKey: key2))
    }

    func test_migrateObjectsMatchingCompactMap_thrownErrorFromCompactMapIsRethrown() throws {
        guard testEnvironmentIsSignedOrDoesNotRequireEntitlement() else {
            return
        }

        let migrationValet = Valet.valet(with: Identifier(nonEmpty: "Migrate_Me")!, accessibility: .afterFirstUnlock)
        try migrationValet.removeAllObjects()

        let anotherValet = Valet.valet(with: Identifier(nonEmpty: #function)!, accessibility: .whenUnlocked)
        try anotherValet.removeAllObjects()

        try migrationValet.setString("password", forKey: #function)

        struct FakeError: Error {}
        var caughtExpectedError = false
        do {
            try anotherValet.migrateObjects(matching: [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: migrationValet.service.description,
            ]) { _ in
                throw FakeError()
            }
        } catch is FakeError {
            caughtExpectedError = true
        } catch {
            // Nothing to do
        }

        XCTAssertTrue(caughtExpectedError)
    }

    // MARK: Migration - Valet
    
    func test_migrateObjectsFromValet_migratesSingleKeyValuePairSuccessfully() throws
    {
        guard testEnvironmentIsSignedOrDoesNotRequireEntitlement() else {
            return
        }
        
        try anotherFlavor.setString("foo", forKey: "bar")
        try vanillaValet.migrateObjects(from: anotherFlavor, removeOnCompletion: false)
        _ = try vanillaValet.allKeys()
        XCTAssertEqual("foo", try vanillaValet.string(forKey: "bar"))
    }
    
    func test_migrateObjectsFromValet_migratesMultipleKeyValuePairsSuccessfully() throws
    {
        guard testEnvironmentIsSignedOrDoesNotRequireEntitlement() else {
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
            try anotherFlavor.setString(value, forKey: key)
        }

        try vanillaValet.migrateObjects(from: anotherFlavor, removeOnCompletion: false)

        // Both the migration target and the previous Valet should hold all key/value pairs.
        XCTAssertEqual(try vanillaValet.allKeys(), try anotherFlavor.allKeys())
        for (key, value) in keyValuePairs {
            XCTAssertEqual(try vanillaValet.string(forKey: key), value)
            XCTAssertEqual(try anotherFlavor.string(forKey: key), value)
        }
    }

    func test_migrateObjectsFromValet_removesOnCompletionWhenRequested() throws
    {
        guard testEnvironmentIsSignedOrDoesNotRequireEntitlement() else {
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
            try anotherFlavor.setString(value, forKey: key)
        }

        try vanillaValet.migrateObjects(from: anotherFlavor, removeOnCompletion: true)

        // The migration target should hold all key/value pairs, the previous Valet should be empty.
        XCTAssertEqual(0, try anotherFlavor.allKeys().count)
        for (key, value) in keyValuePairs {
            XCTAssertEqual(try vanillaValet.string(forKey: key), value)
            XCTAssertThrowsError(try anotherFlavor.string(forKey: key)) { error in
                XCTAssertEqual(error as? KeychainError, .itemNotFound)
            }
        }
    }

    func test_migrateObjectsFromValet_leavesKeychainUntouchedWhenConflictsExist() throws
    {
        guard testEnvironmentIsSignedOrDoesNotRequireEntitlement() else {
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
            try anotherFlavor.setString(value, forKey: key)
        }

        try vanillaValet.setString("adrian", forKey: "yo")

        XCTAssertEqual(1, try vanillaValet.allKeys().count)
        XCTAssertEqual(keyValuePairs.count, try anotherFlavor.allKeys().count)

        XCTAssertThrowsError(try vanillaValet.migrateObjects(from: anotherFlavor, removeOnCompletion: true)) { error in
            XCTAssertEqual(error as? MigrationError, .keyToMigrateAlreadyExistsInValet)
        }

        // Neither Valet should have seen any changes.
        XCTAssertEqual(1, try vanillaValet.allKeys().count)
        XCTAssertEqual(keyValuePairs.count, try anotherFlavor.allKeys().count)
        
        XCTAssertEqual("adrian", try vanillaValet.string(forKey: "yo"))
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
            try otherValet.setString(value, forKey: key)
        }

        XCTAssertTrue(vanillaValet.canAccessKeychain())
        XCTAssertTrue(otherValet.canAccessKeychain())
        try vanillaValet.migrateObjects(from: otherValet, removeOnCompletion: false)

        for (key, value) in keyStringPairToMigrateMap {
            XCTAssertEqual(try vanillaValet.string(forKey: key), value)
            XCTAssertEqual(try otherValet.string(forKey: key), value)
        }
    }

    func test_migrateObjectsFromValetCompactMap_successfullyMigratesTransformedKey() throws {
        guard testEnvironmentIsSignedOrDoesNotRequireEntitlement() else {
            return
        }

        let migrationValet = Valet.valet(with: Identifier(nonEmpty: "Migrate_Me")!, accessibility: .afterFirstUnlock)
        try migrationValet.removeAllObjects()

        let anotherValet = Valet.valet(with: Identifier(nonEmpty: #function)!, accessibility: .whenUnlocked)
        try anotherValet.removeAllObjects()

        try migrationValet.setString("password", forKey: #function)

        try anotherValet.migrateObjects(from: migrationValet) { pair in
            MigratableKeyValuePair<String>(key: "transformed_key", value: pair.value)
        }

        XCTAssertEqual(try? anotherValet.string(forKey: "transformed_key"), "password")
    }

    func test_migrateObjectsFromValetCompactMap_successfullyMigratesTransformedValue() throws {
        guard testEnvironmentIsSignedOrDoesNotRequireEntitlement() else {
            return
        }

        let migrationValet = Valet.valet(with: Identifier(nonEmpty: "Migrate_Me")!, accessibility: .afterFirstUnlock)
        try migrationValet.removeAllObjects()

        let anotherValet = Valet.valet(with: Identifier(nonEmpty: #function)!, accessibility: .whenUnlocked)
        try anotherValet.removeAllObjects()

        try migrationValet.setString("password", forKey: #function)

        try anotherValet.migrateObjects(from: migrationValet) { _ in
            MigratableKeyValuePair<String>(key: #function, value: "12345")
        }

        XCTAssertEqual(try? anotherValet.string(forKey: #function), "12345")
    }

    func test_migrateObjectsFromValetCompactMap_returningNilDoesNotMigratePair() throws {
        guard testEnvironmentIsSignedOrDoesNotRequireEntitlement() else {
            return
        }

        let migrationValet = Valet.valet(with: Identifier(nonEmpty: "Migrate_Me")!, accessibility: .afterFirstUnlock)
        try migrationValet.removeAllObjects()

        let anotherValet = Valet.valet(with: Identifier(nonEmpty: #function)!, accessibility: .whenUnlocked)
        try anotherValet.removeAllObjects()

        let key1 = #function + "1"
        let key2 = #function + "2"
        try migrationValet.setString("password1", forKey: key1)
        try migrationValet.setString("password2", forKey: key2)

        try anotherValet.migrateObjects(from: migrationValet) { input in
            guard let key = input.key as? String else {
                return nil
            }
            if key == key1 {
                return nil
            } else {
                return MigratableKeyValuePair<String>(key: key, value: input.value)
            }
        }

        XCTAssertFalse(try anotherValet.containsObject(forKey: key1))
        XCTAssertEqual(try? anotherValet.string(forKey: key2), "password2")
    }

    func test_migrateObjectsFromValetCompactMap_throwingErrorPreventsAllMigration() throws {
        guard testEnvironmentIsSignedOrDoesNotRequireEntitlement() else {
            return
        }

        let migrationValet = Valet.valet(with: Identifier(nonEmpty: "Migrate_Me")!, accessibility: .afterFirstUnlock)
        try migrationValet.removeAllObjects()

        let anotherValet = Valet.valet(with: Identifier(nonEmpty: #function)!, accessibility: .whenUnlocked)
        try anotherValet.removeAllObjects()

        let key1 = #function + "1"
        let key2 = #function + "2"
        try migrationValet.setString("password1", forKey: key1)
        try migrationValet.setString("password2", forKey: key2)

        try? anotherValet.migrateObjects(from: migrationValet) { input in
            guard let key = input.key as? String else {
                return nil
            }
            if key == key1 {
                return MigratableKeyValuePair<String>(key: key, value: input.value)
            } else {
                struct FakeError: Error {}
                throw FakeError()
            }
        }

        XCTAssertFalse(try anotherValet.containsObject(forKey: key1))
        XCTAssertFalse(try anotherValet.containsObject(forKey: key2))
    }

    func test_migrateObjectsFromValetCompactMap_thrownErrorFromCompactMapIsRethrown() throws {
        guard testEnvironmentIsSignedOrDoesNotRequireEntitlement() else {
            return
        }

        let migrationValet = Valet.valet(with: Identifier(nonEmpty: "Migrate_Me")!, accessibility: .afterFirstUnlock)
        try migrationValet.removeAllObjects()

        let anotherValet = Valet.valet(with: Identifier(nonEmpty: #function)!, accessibility: .whenUnlocked)
        try anotherValet.removeAllObjects()

        try migrationValet.setString("password", forKey: #function)

        struct FakeError: Error {}
        var caughtExpectedError = false
        do {
            try anotherValet.migrateObjects(from: migrationValet) { _ in
                throw FakeError()
            }
        } catch is FakeError {
            caughtExpectedError = true
        } catch {
            // Nothing to do
        }

        XCTAssertTrue(caughtExpectedError)
    }

}
