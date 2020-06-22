//  Created by Dan Federman and Eric Muller on 9/16/17.
//  Copyright © 2017 Square, Inc.
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

#if os(macOS)
class ValetMacTests: XCTestCase
{
    // This test verifies that we are neutralizing the zero-day Mac OS X Access Control List vulnerability.
    // Whitepaper: https://drive.google.com/file/d/0BxxXk1d3yyuZOFlsdkNMSGswSGs/view
    // Square Corner blog post: https://corner.squareup.com/2015/06/valet-beats-the-ox-x-keychain-access-control-list-zero-day-vulnerability.html
    func test_setStringForKey_neutralizesMacOSAccessControlListVuln() throws
    {
        let valet = Valet.valet(with: Identifier(nonEmpty: "MacOSVulnTest")!, accessibility: .whenUnlocked)
        let vulnKey = "KeepIt"
        let vulnValue = "Secret"
        try valet.removeObject(forKey: vulnKey)

        var query = valet.baseKeychainQuery
        query[kSecAttrAccount as String] = vulnKey

        var accessList: SecAccess?
        var trustedAppSelf: SecTrustedApplication?
        var trustedAppSystemUIServer: SecTrustedApplication?

        let kSecReturnWorkingReference: CFString
        let kSecValueWorkingReference: CFString
        if #available(macOS 10.15, *) {
            // macOS Catalina requires a persistent ref to pass this test.
            kSecReturnWorkingReference = kSecReturnPersistentRef
            kSecValueWorkingReference = kSecValuePersistentRef
        } else {
            kSecReturnWorkingReference = kSecReturnRef
            kSecValueWorkingReference = kSecValueRef
        }

        XCTAssertEqual(SecTrustedApplicationCreateFromPath(nil, &trustedAppSelf), errSecSuccess)
        XCTAssertEqual(SecTrustedApplicationCreateFromPath("/System/Library/CoreServices/SystemUIServer.app", &trustedAppSystemUIServer), errSecSuccess);
        let trustedList = [trustedAppSelf!, trustedAppSystemUIServer!] as NSArray?

        // Add an entry to the keychain with an access control list.
        XCTAssertEqual(SecAccessCreate("Access Control List" as CFString, trustedList, &accessList), errSecSuccess)
        var accessListQuery = query
        accessListQuery[kSecAttrAccess as String] = accessList
        accessListQuery[kSecValueData as String] = Data(vulnValue.utf8)
        XCTAssertEqual(SecItemAdd(accessListQuery as CFDictionary, nil), errSecSuccess)

        // The potentially vulnerable keychain item should exist in our Valet now.
        XCTAssertTrue(try valet.containsObject(forKey: vulnKey))

        // Obtain a reference to the vulnerable keychain entry.
        query[kSecReturnWorkingReference as String] = true
        query[kSecReturnAttributes as String] = true
        var vulnerableEntryReference: CFTypeRef?
        XCTAssertEqual(SecItemCopyMatching(query as CFDictionary, &vulnerableEntryReference), errSecSuccess)

        guard let vulnerableKeychainEntry = vulnerableEntryReference as! NSDictionary? else {
            XCTFail()
            return
        }
        guard let vulnerableValueRef = vulnerableKeychainEntry[kSecValueWorkingReference as String] else {
            XCTFail()
            return
        }

        let queryWithVulnerableReference = [
            kSecValueWorkingReference as String: vulnerableValueRef
            ] as CFDictionary
        // Demonstrate that the item is accessible with the reference.
        XCTAssertEqual(SecItemCopyMatching(queryWithVulnerableReference, nil), errSecSuccess)

        // Update the vulnerable value with Valet - we should have deleted the existing item, making the entry no longer vulnerable.
        let updatedValue = "Safe"
        try valet.setString(updatedValue, forKey: vulnKey)

        // We should no longer be able to access the keychain item via the ref.
        let queryWithVulnerableReferenceAndAttributes = [
            kSecValueWorkingReference as String: vulnerableValueRef,
            kSecReturnAttributes as String: true
            ] as CFDictionary
        XCTAssertEqual(SecItemCopyMatching(queryWithVulnerableReferenceAndAttributes, nil), errSecItemNotFound)

        // If you add a breakpoint here then manually inspect the keychain via Keychain.app (search for "MacOSVulnTest"), "xctest" should be the only member of the Access Control list.
        // This is not be the case upon setting a breakpoint and inspecting before the valet.setString(, forKey:) call above.
    }

    func test_withExplicitlySet_assignsExplicitIdentifier() throws {
        let explicitlySetIdentifier = Identifier(nonEmpty: #function)!
        Valet.permutations(withExplictlySet: explicitlySetIdentifier, shared: false).forEach {
            XCTAssertEqual($0.baseKeychainQuery[kSecAttrService as String], explicitlySetIdentifier.description)
        }

        Valet.iCloudPermutations(withExplictlySet: explicitlySetIdentifier, shared: false).forEach {
            XCTAssertEqual($0.baseKeychainQuery[kSecAttrService as String], explicitlySetIdentifier.description)
        }

        guard testEnvironmentIsSigned() else {
            return
        }

        Valet.permutations(withExplictlySet: explicitlySetIdentifier, shared: true).forEach {
            XCTAssertEqual($0.baseKeychainQuery[kSecAttrService as String], explicitlySetIdentifier.description)
        }

        Valet.iCloudPermutations(withExplictlySet: explicitlySetIdentifier, shared: true).forEach {
            XCTAssertEqual($0.baseKeychainQuery[kSecAttrService as String], explicitlySetIdentifier.description)
        }
    }

    func test_withExplicitlySet_canAccessKeychain() throws {
        guard testEnvironmentIsSigned() else {
            return
        }

        let explicitlySetIdentifier = Identifier(nonEmpty: #function)!
        try Valet.permutations(withExplictlySet: explicitlySetIdentifier, shared: false).forEach {
            XCTAssertTrue($0.canAccessKeychain())

            try $0.removeAllObjects()
        }

        try Valet.iCloudPermutations(withExplictlySet: explicitlySetIdentifier, shared: false).forEach {
            XCTAssertTrue($0.canAccessKeychain())

            try $0.removeAllObjects()
        }

        let explicitlySetSharedGroupIdentifier = Identifier(nonEmpty: "9XUJ7M53NG.com.squareup.Valet-macOS-Test-Host-App")!
        try Valet.permutations(withExplictlySet: explicitlySetSharedGroupIdentifier, shared: true).forEach {
            XCTAssertTrue($0.canAccessKeychain())

            try $0.removeAllObjects()
        }

        try Valet.iCloudPermutations(withExplictlySet: explicitlySetSharedGroupIdentifier, shared: true).forEach {
            XCTAssertTrue($0.canAccessKeychain())

            try $0.removeAllObjects()
        }
    }

    func test_withExplicitlySet_canReadWrittenString() throws {
        guard testEnvironmentIsSigned() else {
            return
        }

        let explicitlySetIdentifier = Identifier(nonEmpty: #function)!
        let key = "key"
        let passcode = "12345"

        try Valet.permutations(withExplictlySet: explicitlySetIdentifier, shared: false).forEach {
            try $0.setString(passcode, forKey: key)
            XCTAssertEqual(try $0.string(forKey: key), passcode)

            try $0.removeAllObjects()
        }

        try Valet.iCloudPermutations(withExplictlySet: explicitlySetIdentifier, shared: false).forEach {
            try $0.setString(passcode, forKey: key)
            XCTAssertEqual(try $0.string(forKey: key), passcode)

            try $0.removeAllObjects()
        }

        let explicitlySetSharedGroupIdentifier = Identifier(nonEmpty: "9XUJ7M53NG.com.squareup.Valet-macOS-Test-Host-App")!
        try Valet.permutations(withExplictlySet: explicitlySetSharedGroupIdentifier, shared: true).forEach {
            try $0.setString(passcode, forKey: key)
            XCTAssertEqual(try $0.string(forKey: key), passcode)

            try $0.removeAllObjects()
        }

        try Valet.iCloudPermutations(withExplictlySet: explicitlySetSharedGroupIdentifier, shared: true).forEach {
            try $0.setString(passcode, forKey: key)
            XCTAssertEqual(try $0.string(forKey: key), passcode)

            try $0.removeAllObjects()
        }
    }

    func test_withExplicitlySet_vendsSameObjectWhenSameConfigurationRequested() {
        let explicitlySetIdentifier = Identifier(nonEmpty: #function)!
        var permutations1 = Valet.permutations(withExplictlySet: explicitlySetIdentifier, shared: false)
        var permutations2 = Valet.permutations(withExplictlySet: explicitlySetIdentifier, shared: false)
        for (index, permutation) in permutations1.enumerated() {
            XCTAssertTrue(permutation === permutations2[index], "Two Valets with \(accessibilityValues[index]) were not identical")
        }

        permutations1 = Valet.iCloudPermutations(withExplictlySet: explicitlySetIdentifier, shared: false)
        permutations2 = Valet.iCloudPermutations(withExplictlySet: explicitlySetIdentifier, shared: false)
        for (index, permutation) in permutations1.enumerated() {
            XCTAssertTrue(permutation === permutations2[index], "Two iCloud Valets with \(accessibilityValues[index]) were not identical")
        }

        let explicitlySetSharedGroupIdentifier = Identifier(nonEmpty: "com.squareup.Valet-macOS-Test-Host-App")!
        permutations1 = Valet.permutations(withExplictlySet: explicitlySetSharedGroupIdentifier, shared: true)
        permutations2 = Valet.permutations(withExplictlySet: explicitlySetSharedGroupIdentifier, shared: true)
        for (index, permutation) in permutations1.enumerated() {
            XCTAssertTrue(permutation === permutations2[index], "Two shared Valets with \(accessibilityValues[index]) were not identical")
        }

        permutations1 = Valet.iCloudPermutations(withExplictlySet: explicitlySetSharedGroupIdentifier, shared: true)
        permutations2 = Valet.iCloudPermutations(withExplictlySet: explicitlySetSharedGroupIdentifier, shared: true)
        for (index, permutation) in permutations1.enumerated() {
            XCTAssertTrue(permutation === permutations2[index], "Two shared iCloud Valets with \(accessibilityValues[index]) were not identical")
        }
    }

    func test_withExplicitlySet_createsObjectWithCorrectAccessibility() {
        let explicitlySetIdentifier = Identifier(nonEmpty: #function)!
        var permutations = Valet.permutations(withExplictlySet: explicitlySetIdentifier, shared: false)
        for (index, permutation) in permutations.enumerated() {
            XCTAssertEqual(accessibilityValues[index], permutation.accessibility)
        }

        permutations = Valet.iCloudPermutations(withExplictlySet: explicitlySetIdentifier, shared: false)
        for (index, permutation) in permutations.enumerated() {
            XCTAssertEqual(accessibilityValues[index], permutation.accessibility)
        }

        let explicitlySetSharedGroupIdentifier = Identifier(nonEmpty: "com.squareup.Valet-macOS-Test-Host-App")!
        permutations = Valet.permutations(withExplictlySet: explicitlySetSharedGroupIdentifier, shared: true)
        for (index, permutation) in permutations.enumerated() {
            XCTAssertEqual(accessibilityValues[index], permutation.accessibility)
        }

        permutations = Valet.iCloudPermutations(withExplictlySet: explicitlySetSharedGroupIdentifier, shared: true)
        for (index, permutation) in permutations.enumerated() {
            XCTAssertEqual(accessibilityValues[index], permutation.accessibility)
        }
    }

    // MARK: Migration - PreCatalina

    func test_migrateObjectsFromPreCatalina_migratesDataWrittenPreCatalina() throws {
        guard #available(macOS 10.15, *) else {
            return
        }

        let valet = Valet.valet(with: Identifier(nonEmpty: "PreCatalinaTest")!, accessibility: .afterFirstUnlock)
        var preCatalinaWriteQuery = valet.baseKeychainQuery
        preCatalinaWriteQuery[kSecUseDataProtectionKeychain as String] = nil

        let key = "PreCatalinaKey"
        let object = Data("PreCatalinaValue".utf8)
        preCatalinaWriteQuery[kSecAttrAccount as String] = key
        preCatalinaWriteQuery[kSecValueData as String] = object

        // Make sure the item is not in the keychain before we start this test
        SecItemDelete(preCatalinaWriteQuery as CFDictionary)

        XCTAssertEqual(SecItemAdd(preCatalinaWriteQuery as CFDictionary, nil), errSecSuccess)
        XCTAssertThrowsError(try valet.object(forKey: key)) { error in
            XCTAssertEqual(error as? KeychainError, .itemNotFound)
        }
        XCTAssertNoThrow(try valet.migrateObjectsFromPreCatalina())
        XCTAssertEqual(try valet.object(forKey: key), object)
    }

    private let accessibilityValues = Accessibility.allCases

}
#endif
