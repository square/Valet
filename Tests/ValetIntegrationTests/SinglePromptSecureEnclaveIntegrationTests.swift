//
//  SinglePromptSecureEnclaveTests.swift
//  Valet
//
//  Created by Eric Muller on 10/1/17.
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
@testable import Valet
import XCTest

#if canImport(LocalAuthentication)

class SinglePromptSecureEnclaveIntegrationTests: XCTestCase
{
    static let identifier = Identifier(nonEmpty: "valet_testing")!

    @available(tvOS 11.0, *)
    func valet() -> SinglePromptSecureEnclaveValet {
        .valet(with: SinglePromptSecureEnclaveTests.identifier, accessControl: .userPresence)
    }
    let key = "key"
    let passcode = "topsecret"

    override func setUp()
    {
        super.setUp()
        
        ErrorHandler.customAssertBody = { _, _, _, _ in
            // Nothing to do here.
        }

        if #available(tvOS 11.0, *) {
            valet().removeObject(forKey: key)
        }
    }

    // MARK: Equality
        
    func test_SinglePromptSecureEnclaveValetsWithEqualConfiguration_canAccessSameData()
    {
        guard #available(tvOS 11.0, *) else {
            return
        }
        guard testEnvironmentIsSigned() && testEnvironmentSupportsWhenPasscodeSet() else {
            return
        }
        
        XCTAssertTrue(valet().setString(passcode, forKey: key))
        let equivalentValet = SinglePromptSecureEnclaveValet.valet(with: valet().identifier, accessControl: valet().accessControl)
        XCTAssertEqual(valet(), equivalentValet)
        XCTAssertEqual(.success(passcode), equivalentValet.string(forKey: key, withPrompt: ""))
    }
    
    func test_SinglePromptSecureEnclaveValetsWithDifferingAccessControl_canNotAccessSameData()
    {
        guard #available(tvOS 11.0, *) else {
            return
        }
        guard testEnvironmentIsSigned() && testEnvironmentSupportsWhenPasscodeSet() else {
            return
        }
        
        XCTAssertTrue(valet().setString(passcode, forKey: key))
        let equivalentValet = SecureEnclaveValet.valet(with: valet().identifier, accessControl: .devicePasscode)
        XCTAssertNotEqual(valet(), equivalentValet)
        XCTAssertEqual(.success(passcode), valet().string(forKey: key, withPrompt: ""))
        XCTAssertEqual(.itemNotFound, equivalentValet.string(forKey: key, withPrompt: ""))
    }

    // MARK: allKeys
    
    func test_allKeys()
    {
        guard #available(tvOS 11.0, *) else {
            return
        }
        guard testEnvironmentIsSigned() && testEnvironmentSupportsWhenPasscodeSet() else {
            return
        }
        
        XCTAssertEqual(valet().allKeys(userPrompt: ""), Set())
        
        XCTAssertTrue(valet().setString(passcode, forKey: key))
        XCTAssertEqual(valet().allKeys(userPrompt: ""), Set(arrayLiteral: key))
        
        XCTAssertTrue(valet().setString("monster", forKey: "cookie"))
        XCTAssertEqual(valet().allKeys(userPrompt: ""), Set(arrayLiteral: key, "cookie"))
        
        valet().removeAllObjects()
        XCTAssertEqual(valet().allKeys(userPrompt: ""), Set())
    }
    
    func test_allKeys_doesNotReflectValetImplementationDetails() {
        guard #available(tvOS 11.0, *) else {
            return
        }
        // Under the hood, Valet inserts a canary when calling `canAccessKeychain()` - this should not appear in `allKeys()`.
        _ = valet().canAccessKeychain()
        XCTAssertEqual(valet().allKeys(userPrompt: "it me"), Set())
    }
    
    // MARK: canAccessKeychain
    
    func test_canAccessKeychain()
    {
        guard #available(tvOS 11.0, *) else {
            return
        }
        guard testEnvironmentIsSigned() else {
            return
        }

        let permutations: [SecureEnclaveValet] = SecureEnclaveAccessControl.allValues().compactMap { accessControl in
            return .valet(with: valet().identifier, accessControl: accessControl)
        }

        for permutation in permutations {
            XCTAssertTrue(permutation.canAccessKeychain())
        }
    }
    
    func test_canAccessKeychain_sharedAccessGroup() {
        guard #available(tvOS 11.0, *) else {
            return
        }
        guard testEnvironmentIsSigned() else {
            return
        }
        
        let sharedAccessGroupIdentifier: Identifier
        #if os(iOS)
            sharedAccessGroupIdentifier = Identifier(nonEmpty: "com.squareup.Valet-iOS-Test-Host-App")!
        #elseif os(macOS)
            sharedAccessGroupIdentifier = Identifier(nonEmpty: "com.squareup.Valet-macOS-Test-Host-App")!
        #elseif os(tvOS)
            sharedAccessGroupIdentifier = Identifier(nonEmpty: "com.squareup.Valet-tvOS-Test-Host-App")!
        #else
            XCTFail()
        #endif

        let permutations: [SecureEnclaveValet] = SecureEnclaveAccessControl.allValues().compactMap { accessControl in
            return .sharedAccessGroupValet(with: sharedAccessGroupIdentifier, accessControl: accessControl)
        }

        for permutation in permutations {
            XCTAssertTrue(permutation.canAccessKeychain())
        }
    }
    
    // MARK: Migration
    
    func test_migrateObjectsMatchingQuery_failsForBadQuery()
    {
        guard #available(tvOS 11.0, *) else {
            return
        }
        guard testEnvironmentIsSigned() else {
            return
        }
        
        let invalidQuery = [
            kSecClass as String: kSecClassGenericPassword as String,
            kSecAttrAccessControl as String: "Fake access control"
        ]
        XCTAssertEqual(.invalidQuery, valet().migrateObjects(matching: invalidQuery, removeOnCompletion: false))
    }
    
    func test_migrateObjectsFromValet_migratesSuccessfullyToSecureEnclave()
    {
        guard #available(tvOS 11.0, *) else {
            return
        }
        guard testEnvironmentIsSigned() && testEnvironmentSupportsWhenPasscodeSet() else {
            return
        }
        
        let plainOldValet = Valet.valet(with: Identifier(nonEmpty: "Migrate_Me")!, accessibility: .afterFirstUnlock)
        
        // Clean up any dangling keychain items before we start this test.
        valet().removeAllObjects()
        plainOldValet.removeAllObjects()
        
        let keyValuePairs = [
            "yo": "dawg",
            "we": "heard",
            "you": "like",
            "migrating": "to",
            "other": "valets"
        ]
        
        for (key, value) in keyValuePairs {
            plainOldValet.setString(value, forKey: key)
        }
        
        XCTAssertEqual(.success, valet().migrateObjects(from: plainOldValet, removeOnCompletion: true))
        
        for (key, value) in keyValuePairs {
            XCTAssertEqual(.success(value), valet().string(forKey: key, withPrompt: ""))
            XCTAssertNil(plainOldValet.string(forKey: key))
        }
        
        // Clean up items for the next test run (allKeys and removeAllObjects are unsupported in VALSecureEnclaveValet.
        for key in keyValuePairs.keys {
            XCTAssertTrue(valet().removeObject(forKey: key))
        }
    }
    
    func test_migrateObjectsFromValet_migratesSuccessfullyAfterCanAccessKeychainCalls() {
        guard #available(tvOS 11.0, *) else {
            return
        }
        guard testEnvironmentIsSigned() && testEnvironmentSupportsWhenPasscodeSet() else {
            return
        }
        
        let otherValet = Valet.valet(with: Identifier(nonEmpty: "Migrate_Me_To_Valet")!, accessibility: .afterFirstUnlock)
        
        // Clean up any dangling keychain items before we start this test.
        valet().removeAllObjects()
        otherValet.removeAllObjects()
        
        let keyStringPairToMigrateMap = ["foo" : "bar", "testing" : "migration", "is" : "quite", "entertaining" : "if", "you" : "don't", "screw" : "up"]
        for (key, value) in keyStringPairToMigrateMap {
            XCTAssertTrue(otherValet.setString(value, forKey: key))
        }
        
        XCTAssertTrue(valet().canAccessKeychain())
        XCTAssertTrue(otherValet.canAccessKeychain())
        XCTAssertEqual(.success, valet().migrateObjects(from: otherValet, removeOnCompletion: false))
        
        for (key, value) in keyStringPairToMigrateMap {
            XCTAssertEqual(valet().string(forKey: key, withPrompt: ""), .success(value))
            XCTAssertEqual(otherValet.string(forKey: key), value)
        }
    }
}

#endif
