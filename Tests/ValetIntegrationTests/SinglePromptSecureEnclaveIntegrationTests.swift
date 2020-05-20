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

        guard #available(tvOS 11.0, *) else {
            return
        }
        guard testEnvironmentIsSigned() else {
            return
        }
        do {
            try valet().removeAllObjects()
        } catch {
            XCTFail("Error removing objects from Valet \(valet()): \(error)")
        }
    }

    // MARK: Equality
        
    func test_SinglePromptSecureEnclaveValetsWithEqualConfiguration_canAccessSameData() throws
    {
        guard #available(tvOS 11.0, *) else {
            return
        }
        guard testEnvironmentIsSigned() && testEnvironmentSupportsWhenPasscodeSet() else {
            return
        }
        
        try valet().setString(passcode, forKey: key)
        let equivalentValet = SinglePromptSecureEnclaveValet.valet(with: valet().identifier, accessControl: valet().accessControl)
        XCTAssertEqual(valet(), equivalentValet)
        XCTAssertEqual(passcode, try equivalentValet.string(forKey: key, withPrompt: ""))
    }
    
    func test_SinglePromptSecureEnclaveValetsWithDifferingAccessControl_canNotAccessSameData() throws
    {
        guard #available(tvOS 11.0, *) else {
            return
        }
        guard testEnvironmentIsSigned() && testEnvironmentSupportsWhenPasscodeSet() else {
            return
        }
        
        try valet().setString(passcode, forKey: key)
        let equivalentValet = SecureEnclaveValet.valet(with: valet().identifier, accessControl: .devicePasscode)
        XCTAssertNotEqual(valet(), equivalentValet)
        XCTAssertEqual(passcode, try valet().string(forKey: key, withPrompt: ""))
        XCTAssertThrowsError(try equivalentValet.string(forKey: key, withPrompt: "")) { error in
            XCTAssertEqual(error as? KeychainError, .itemNotFound)
        }
    }

    // MARK: allKeys
    
    func test_allKeys() throws
    {
        guard #available(tvOS 11.0, *) else {
            return
        }
        guard testEnvironmentIsSigned() && testEnvironmentSupportsWhenPasscodeSet() else {
            return
        }
        
        XCTAssertEqual(try valet().allKeys(userPrompt: ""), Set())
        
        try valet().setString(passcode, forKey: key)
        XCTAssertEqual(try valet().allKeys(userPrompt: ""), Set(arrayLiteral: key))
        
        try valet().setString("monster", forKey: "cookie")
        XCTAssertEqual(try valet().allKeys(userPrompt: ""), Set(arrayLiteral: key, "cookie"))
        
        try valet().removeAllObjects()
        XCTAssertEqual(try valet().allKeys(userPrompt: ""), Set())
    }
    
    func test_allKeys_doesNotReflectValetImplementationDetails() throws {
        guard #available(tvOS 11.0, *) else {
            return
        }
        guard testEnvironmentIsSigned() && testEnvironmentSupportsWhenPasscodeSet() else {
            return
        }

        // Under the hood, Valet inserts a canary when calling `canAccessKeychain()` - this should not appear in `allKeys()`.
        _ = valet().canAccessKeychain()
        XCTAssertEqual(try valet().allKeys(userPrompt: "it me"), Set())
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
        
        let permutations: [SecureEnclaveValet] = SecureEnclaveAccessControl.allValues().compactMap { accessControl in
            return .sharedGroupValet(with: Valet.sharedAccessGroupIdentifier, accessControl: accessControl)
        }

        for permutation in permutations {
            XCTAssertTrue(permutation.canAccessKeychain())
        }
    }

    func test_canAccessKeychain_sharedAppGroup() {
        guard #available(tvOS 11.0, *) else {
            return
        }
        guard testEnvironmentIsSigned() else {
            return
        }

        let permutations: [SecureEnclaveValet] = SecureEnclaveAccessControl.allValues().compactMap { accessControl in
            return .sharedGroupValet(with: Valet.sharedAppGroupIdentifier, accessControl: accessControl)
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
        XCTAssertThrowsError(try valet().migrateObjects(matching: invalidQuery, removeOnCompletion: false)) { error in
            XCTAssertEqual(error as? MigrationError, MigrationError.invalidQuery)
        }
    }
    
    func test_migrateObjectsFromValet_migratesSuccessfullyToSecureEnclave() throws
    {
        guard #available(tvOS 11.0, *) else {
            return
        }
        guard testEnvironmentIsSigned() && testEnvironmentSupportsWhenPasscodeSet() else {
            return
        }
        
        let plainOldValet = Valet.valet(with: Identifier(nonEmpty: "Migrate_Me")!, accessibility: .afterFirstUnlock)
        
        // Clean up any dangling keychain items before we start this test.
        try valet().removeAllObjects()
        try plainOldValet.removeAllObjects()

        let keyValuePairs = [
            "yo": "dawg",
            "we": "heard",
            "you": "like",
            "migrating": "to",
            "other": "valets"
        ]
        
        for (key, value) in keyValuePairs {
            try plainOldValet.setString(value, forKey: key)
        }
        
        try valet().migrateObjects(from: plainOldValet, removeOnCompletion: true)
        
        for (key, value) in keyValuePairs {
            XCTAssertEqual(value, try valet().string(forKey: key, withPrompt: ""))
            XCTAssertThrowsError(try plainOldValet.string(forKey: key)) { error in
                XCTAssertEqual(error as? KeychainError, .itemNotFound)
            }
        }
        
        // Clean up items for the next test run (allKeys and removeAllObjects are unsupported in VALSecureEnclaveValet.
        for key in keyValuePairs.keys {
            try valet().removeObject(forKey: key)
        }
    }
    
    func test_migrateObjectsFromValet_migratesSuccessfullyAfterCanAccessKeychainCalls() throws {
        guard #available(tvOS 11.0, *) else {
            return
        }
        guard testEnvironmentIsSigned() && testEnvironmentSupportsWhenPasscodeSet() else {
            return
        }
        
        let otherValet = Valet.valet(with: Identifier(nonEmpty: "Migrate_Me_To_Valet")!, accessibility: .afterFirstUnlock)
        
        // Clean up any dangling keychain items before we start this test.
        try valet().removeAllObjects()
        try otherValet.removeAllObjects()

        let keyStringPairToMigrateMap = ["foo" : "bar", "testing" : "migration", "is" : "quite", "entertaining" : "if", "you" : "don't", "screw" : "up"]
        for (key, value) in keyStringPairToMigrateMap {
            try otherValet.setString(value, forKey: key)
        }
        
        XCTAssertTrue(valet().canAccessKeychain())
        XCTAssertTrue(otherValet.canAccessKeychain())
        try valet().migrateObjects(from: otherValet, removeOnCompletion: false)
        
        for (key, value) in keyStringPairToMigrateMap {
            XCTAssertEqual(try valet().string(forKey: key, withPrompt: ""), value)
            XCTAssertEqual(try otherValet.string(forKey: key), value)
        }
    }
}

#endif
