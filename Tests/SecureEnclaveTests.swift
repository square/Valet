//
//  SecureEnclaveTests.swift
//  Valet
//
//  Created by Dan Federman and Eric Muller on 9/17/17.
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


@available (iOS 8, OSX 10.11, *)
class SecureEnclaveTests: XCTestCase
{
    static let identifier = Identifier(nonEmpty: "valet_testing")!
    let valet = SecureEnclaveValet.valet(with: identifier, accessControl: .userPresence)
    let key = "key"
    let passcode = "topsecret"
    
    override func setUp()
    {
        super.setUp()
        
        ErrorHandler.customAssertBody = { _, _, _, _ in
            // Nothing to do here.
        }
        
        valet.removeObject(for: key)
    }
    
    // MARK: Equality
    
    func test_secureEnclaveValetsWithEqualConfiguration_haveEqualPointers()
    {
        let equivalentValet = SecureEnclaveValet.valet(with: valet.identifier, accessControl: valet.accessControl)
        XCTAssertTrue(valet == equivalentValet)
        XCTAssertTrue(valet === equivalentValet)
    }
    
    func test_secureEnclaveValetsWithEqualConfiguration_canAccessSameData()
    {
        guard testEnvironmentIsSigned() else {
            return
        }
        
        XCTAssertTrue(valet.set(string: passcode, for: key))
        let equivalentValet = SecureEnclaveValet.valet(with: valet.identifier, accessControl: valet.accessControl)
        XCTAssertEqual(valet, equivalentValet)
        XCTAssertEqual(.success(passcode), equivalentValet.string(for: key, withPrompt: ""))
    }
    
    func test_secureEnclaveValetsWithDifferingAccessControl_canNotAccessSameData()
    {
        guard testEnvironmentIsSigned() else {
            return
        }
        
        XCTAssertTrue(valet.set(string: passcode, for: key))
        let equivalentValet = SecureEnclaveValet.valet(with: valet.identifier, accessControl: .devicePasscode)
        XCTAssertNotEqual(valet, equivalentValet)
        XCTAssertEqual(.success(passcode), valet.string(for: key, withPrompt: ""))
        XCTAssertEqual(.itemNotFound, equivalentValet.string(for: key, withPrompt: ""))
    }
    
    @available (*, deprecated)
    func test_secureEnclaveValet_backwardsCompatibility()
    {
        guard testEnvironmentIsSigned() else {
            return
        }
        
        let deprecatedValet = VALLegacySecureEnclaveValet(identifier: valet.identifier.description)!
        XCTAssertTrue(deprecatedValet.setString(passcode, forKey: key))
        XCTAssertEqual(.success(passcode), valet.string(for: key, withPrompt: ""))
    }
    
    // MARK: canAccessKeychain
    
    func test_canAccessKeychain()
    {
        guard testEnvironmentIsSigned() else {
            return
        }
        
        let permutations: [SecureEnclaveValet] = SecureEnclaveAccessControl.allValues().flatMap { accessControl in
            return .valet(with: valet.identifier, accessControl: accessControl)
        }
        for permutation in permutations {
            XCTAssertTrue(permutation.canAccessKeychain())
        }
    }
    
    func test_canAccessKeychain_sharedAccessGroup() {
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
        
        let permutations: [SecureEnclaveValet] = SecureEnclaveAccessControl.allValues().flatMap { accessControl in
            return .sharedAccessGroupValet(with: sharedAccessGroupIdentifier, accessControl: accessControl)
        }
        for permutation in permutations {
            XCTAssertTrue(permutation.canAccessKeychain())
        }
    }
    
    // MARK: Migration
    
    func test_migrateObjectsMatchingQuery_failsForBadQuery()
    {
        guard testEnvironmentIsSigned() else {
            return
        }
        
        let invalidQuery = [
            kSecClass as String: kSecClassGenericPassword as String,
            kSecAttrAccessControl as String: "Fake access control"
        ]
        XCTAssertEqual(.invalidQuery, valet.migrateObjects(matching: invalidQuery, removeOnCompletion: false))
    }
    
    func test_migrateObjectsFromValet_migratesSuccessfullyToSecureEnclave()
    {
        guard testEnvironmentIsSigned() else {
            return
        }
        
        let plainOldValet = Valet.valet(with: Identifier(nonEmpty: "Migrate_Me")!, of: .vanilla(.afterFirstUnlock))
        
        // Clean up any dangling keychain items before we start this test.
        valet.removeAllObjects()
        plainOldValet.removeAllObjects()
        
        let keyValuePairs = [
            "yo": "dawg",
            "we": "heard",
            "you": "like",
            "migrating": "to",
            "other": "valets"
        ]
        
        for (key, value) in keyValuePairs {
            plainOldValet.set(string: value, for: key)
        }
        
        XCTAssertEqual(.success, valet.migrateObjects(from: plainOldValet, removeOnCompletion: true))
        
        for (key, value) in keyValuePairs {
            XCTAssertEqual(.success(value), valet.string(for: key, withPrompt: ""))
            XCTAssertNil(plainOldValet.string(for: key))
        }
        
        // Clean up items for the next test run (allKeys and removeAllObjects are unsupported in VALSecureEnclaveValet.
        for key in keyValuePairs.keys {
            XCTAssertTrue(valet.removeObject(for: key))
        }
    }
    
    func test_migrateObjectsFromValet_migratesSuccessfullyAfterCanAccessKeychainCalls() {
        guard testEnvironmentIsSigned() else {
            return
        }
        
        let otherValet = Valet.valet(with: Identifier(nonEmpty: "Migrate_Me_To_Valet")!, of: .vanilla(.afterFirstUnlock))
        
        // Clean up any dangling keychain items before we start this test.
        valet.removeAllObjects()
        otherValet.removeAllObjects()
        
        let keyStringPairToMigrateMap = ["foo" : "bar", "testing" : "migration", "is" : "quite", "entertaining" : "if", "you" : "don't", "screw" : "up"]
        for (key, value) in keyStringPairToMigrateMap {
            XCTAssertTrue(otherValet.set(string: value, for: key))
        }
        
        XCTAssertTrue(valet.canAccessKeychain())
        XCTAssertTrue(otherValet.canAccessKeychain())
        XCTAssertEqual(.success, valet.migrateObjects(from: otherValet, removeOnCompletion: false))
        
        for (key, value) in keyStringPairToMigrateMap {
            XCTAssertEqual(valet.string(for: key, withPrompt: ""), .success(value))
            XCTAssertEqual(otherValet.string(for: key), value)
        }
    }
}
