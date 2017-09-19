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
import Valet
import XCTest


extension VALSecureEnclaveValet {
    
    class var supportsSecureEnclaveKeychainTests: Bool {
        // Until we can write a signed host app on macOS, we can only test the iCloud Keychain (SynchronizableValet) code on iOS.
        #if TARGET_IPHONE_SIMULATOR
            return supportsSecureEnclaveKeychainItems
        #else
            return false
        #endif
    }
    
}


extension Error
{
    // The Error.code -> VALMigrationError conversion is gross right now:
    var valetMigrationError: VALMigrationError { return VALMigrationError(rawValue: UInt((self as NSError).code))! }
}


@available (iOS 8, OSX 10.11, *)
class ValetSecureEnclaveTests: XCTestCase
{
    static let identifier = "valet_testing"
    let valet = VALSecureEnclaveValet(identifier: identifier, accessControl: .userPresence)!
    let key = "key"
    let passcode = "topsecret"
    
    override func setUp()
    {
        super.setUp()
        valet.removeObject(forKey: key)
    }
    
    // MARK: Equality
    
    func test_secureEnclaveValetsWithEqualConfiguration_haveEqualPointers()
    {
        guard VALSecureEnclaveValet.supportsSecureEnclaveKeychainTests else {
            return
        }
        
        let equivalentValet = VALSecureEnclaveValet(identifier: valet.identifier, accessControl: valet.accessControl)!
        XCTAssertTrue(valet == equivalentValet)
        XCTAssertTrue(valet === equivalentValet)
    }
    
    func test_secureEnclaveValetsWithEqualConfiguration_canAccessSameData()
    {
        guard VALSecureEnclaveValet.supportsSecureEnclaveKeychainTests else {
            return
        }
        
        XCTAssertTrue(valet.setString(passcode, forKey: key))
        let equivalentValet = VALSecureEnclaveValet(identifier: valet.identifier, accessControl: valet.accessControl)!
        XCTAssertEqual(valet, equivalentValet)
        XCTAssertEqual(passcode, equivalentValet.string(forKey: key, userPrompt: ""))
    }
    
    func test_secureEnclaveValetsWithDifferingAccessControl_canNotAccessSameData()
    {
        guard VALSecureEnclaveValet.supportsSecureEnclaveKeychainTests else {
            return
        }
        
        XCTAssertTrue(valet.setString(passcode, forKey: key))
        let equivalentValet = VALSecureEnclaveValet(identifier: valet.identifier, accessControl: .devicePasscode)!
        XCTAssertNotEqual(valet, equivalentValet)
        XCTAssertEqual(passcode, valet.string(forKey: key, userPrompt: ""))
        XCTAssertNil(equivalentValet.string(forKey: key, userPrompt: ""))
    }
    
    @available (*, deprecated)
    func test_secureEnclaveValet_backwardsCompatibility()
    {
        guard VALSecureEnclaveValet.supportsSecureEnclaveKeychainTests else {
            return
        }
        
        let deprecatedValet = VALSecureEnclaveValet(identifier: valet.identifier)!
        XCTAssertEqual(valet, deprecatedValet)
        XCTAssertTrue(deprecatedValet.setString(passcode, forKey: key))
        XCTAssertEqual(passcode, valet.string(forKey: key, userPrompt: ""))
    }
    
    // MARK: canAccessKeychain
    
    func test_canAccessKeychain()
    {
        guard VALSecureEnclaveValet.supportsSecureEnclaveKeychainTests else {
            return
        }
        
        XCTAssertTrue(valet.canAccessKeychain())
    }
    
    // MARK: Migration
    
    func test_migrateObjectsMatchingQuery_failsForBadQuery()
    {
        guard VALSecureEnclaveValet.supportsSecureEnclaveKeychainTests else {
            return
        }
        
        let invalidQuery = [
            kSecClass as String: kSecClassGenericPassword as String,
            kSecUseOperationPrompt as String: "Migration Prompt"
        ]
        XCTAssertEqual(VALMigrationError.invalidQuery, valet.migrateObjects(matchingQuery: invalidQuery, removeOnCompletion: false)?.valetMigrationError)
    }
    
    func test_migrateObjectsFromValet_migratesSuccessfullyToSecureEnclave()
    {
        guard VALSecureEnclaveValet.supportsSecureEnclaveKeychainTests else {
            return
        }
        
        let keyValuePairs = [
            "yo": "dawg",
            "we": "heard",
            "you": "like",
            "migrating": "to",
            "other": "valets"
        ]
        
        let plainOldValet = VALValet(identifier: "Migrate_Me", accessibility: .afterFirstUnlock)!
        
        for (key, value) in keyValuePairs {
            plainOldValet.setString(value, forKey: key)
        }
        
        XCTAssertNil(valet.migrateObjects(from: plainOldValet, removeOnCompletion: true))
        
        for (key, value) in keyValuePairs {
            XCTAssertEqual(value, valet.string(forKey: key))
            XCTAssertNil(plainOldValet.string(forKey: key))
        }
        
        // Clean up items for the next test run (allKeys and removeAllObjects are unsupported in VALSecureEnclaveValet.
        for key in keyValuePairs.keys {
            XCTAssertTrue(valet.removeObject(forKey: key))
        }
    }
    
    func test_migrateObjectsFromValet_migratesSuccessfullyAfterCanAccessKeychainCalls() {
        guard VALSecureEnclaveValet.supportsSecureEnclaveKeychainTests else {
            return
        }
        
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
    
    // MARK: Protected Methods
    
    func test_secItemFormatDictionaryWithKey()
    {
        let secItemDictionary = valet._secItemFormatDictionary(withKey: key)
        XCTAssertEqual(key, secItemDictionary[kSecAttrAccount as AnyHashable] as? String)
    }
}
