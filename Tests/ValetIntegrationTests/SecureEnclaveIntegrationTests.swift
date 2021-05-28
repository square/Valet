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
import LocalAuthentication
import XCTest

@testable import Valet


class SecureEnclaveIntegrationTests: XCTestCase
{
    static let identifier = Identifier(nonEmpty: "valet_testing")!
    let valet = SecureEnclaveValet.valet(with: identifier, accessControl: .userPresence)
    let fallback = "fallback"
    let key = "key"
    let passcode = "topsecret"
    let prompt = "prompt"

    override func setUp()
    {
        super.setUp()

        guard testEnvironmentIsSigned() else {
            return
        }
        do {
            try valet.removeAllObjects()
        } catch {
            XCTFail("Error removing objects from Valet \(valet): \(error)")
        }
    }

    // MARK: Equality
    
    func test_secureEnclaveValetsWithEqualConfiguration_canAccessSameData() throws
    {
        guard testEnvironmentIsSigned() && testEnvironmentSupportsWhenPasscodeSet() else {
            return
        }
        
        try valet.setString(passcode, forKey: key)
        let equivalentValet = SecureEnclaveValet.valet(with: valet.identifier, accessControl: valet.accessControl)
        XCTAssertEqual(valet, equivalentValet)
        XCTAssertEqual(passcode, try equivalentValet.string(forKey: key, withPrompt: ""))
    }
    
    func test_secureEnclaveValetsWithDifferingAccessControl_canNotAccessSameData() throws
    {
        guard testEnvironmentIsSigned() && testEnvironmentSupportsWhenPasscodeSet() else {
            return
        }
        
        try valet.setString(passcode, forKey: key)
        let similarValet = SecureEnclaveValet.valet(with: valet.identifier, accessControl: .devicePasscode)
        XCTAssertNotEqual(valet, similarValet)
        XCTAssertEqual(passcode, try valet.string(forKey: key, withPrompt: ""))
        XCTAssertThrowsError(try similarValet.string(forKey: key, withPrompt: "")) { error in
            XCTAssertEqual(error as? KeychainError, .itemNotFound)
        }
    }
        
    // MARK: canAccessKeychain
    
    func test_canAccessKeychain()
    {
        guard testEnvironmentIsSigned() else {
            return
        }

        let permutations: [SecureEnclaveValet] = SecureEnclaveAccessControl.allValues().compactMap { accessControl in
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

        let permutations: [SecureEnclaveValet] = SecureEnclaveAccessControl.allValues().compactMap { accessControl in
            return .sharedGroupValet(with: Valet.sharedAccessGroupIdentifier, accessControl: accessControl)
        }
        
        for permutation in permutations {
            XCTAssertTrue(permutation.canAccessKeychain())
        }
    }

    #if !os(macOS)
    // We can't test app groups on macOS without a paid developer account, which we don't have.
    func test_canAccessKeychain_sharedAppGroup() {
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
    #endif

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
        XCTAssertThrowsError(try valet.migrateObjects(matching: invalidQuery, removeOnCompletion: false)) { error in
            XCTAssertEqual(error as? MigrationError, .invalidQuery)
        }
    }
    
    func test_migrateObjectsFromValet_migratesSuccessfullyToSecureEnclave() throws
    {
        guard testEnvironmentIsSigned() && testEnvironmentSupportsWhenPasscodeSet() else {
            return
        }
        
        let plainOldValet = Valet.valet(with: Identifier(nonEmpty: "Migrate_Me")!, accessibility: .afterFirstUnlock)
        
        // Clean up any dangling keychain items before we start this test.
        try valet.removeAllObjects()
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
        
        try valet.migrateObjects(from: plainOldValet, removeOnCompletion: true)
        
        for (key, value) in keyValuePairs {
            XCTAssertEqual(value, try valet.string(forKey: key, withPrompt: ""))
            XCTAssertThrowsError(try plainOldValet.string(forKey: key)) { error in
                XCTAssertEqual(error as? KeychainError, .itemNotFound)
            }
        }
        
        // Clean up items for the next test run (allKeys and removeAllObjects are unsupported in VALSecureEnclaveValet).
        for key in keyValuePairs.keys {
            try valet.removeObject(forKey: key)
        }
    }
    
    func test_migrateObjectsFromValet_migratesSuccessfullyAfterCanAccessKeychainCalls() throws {
        guard testEnvironmentIsSigned() && testEnvironmentSupportsWhenPasscodeSet() else {
            return
        }
        
        let otherValet = Valet.valet(with: Identifier(nonEmpty: "Migrate_Me_To_Valet")!, accessibility: .afterFirstUnlock)
        
        // Clean up any dangling keychain items before we start this test.
        try valet.removeAllObjects()
        try otherValet.removeAllObjects()
        
        let keyStringPairToMigrateMap = ["foo" : "bar", "testing" : "migration", "is" : "quite", "entertaining" : "if", "you" : "don't", "screw" : "up"]
        for (key, value) in keyStringPairToMigrateMap {
            try otherValet.setString(value, forKey: key)
        }
        
        XCTAssertTrue(valet.canAccessKeychain())
        XCTAssertTrue(otherValet.canAccessKeychain())
        try valet.migrateObjects(from: otherValet, removeOnCompletion: false)
        
        for (key, value) in keyStringPairToMigrateMap {
            XCTAssertEqual(try valet.string(forKey: key, withPrompt: ""), value)
            XCTAssertEqual(try otherValet.string(forKey: key), value)
        }
    }

    // MARK: string(forKey:withPrompt:)

    func test_stringForKeyWithPrompt_throwsItemNotFoundForKeyWithNoValue() throws {
        XCTAssertThrowsError(try valet.string(forKey: key, withPrompt: prompt)) { error in
            XCTAssertEqual(error as? KeychainError, .itemNotFound)
        }
    }

    func test_stringForKeyWithPrompt_retrievesStringForValidKey() throws {
        try valet.setString(passcode, forKey: key)
        XCTAssertEqual(passcode, try valet.string(forKey: key, withPrompt: prompt))
    }

    // MARK: string(forKey:withPrompt:withFallbackTitle:)

    func test_stringForKeyWithPromptWithFallbackTitle_userPresenceUsesDeviceOwnerAuthentication() throws {
        let valet = SecureEnclaveValet.valet(with: type(of: self).identifier, accessControl: .userPresence)
        try valet.setString(passcode, forKey: key)
        let authContext = MockLAContext(evaluatePolicyReply: (true, nil))
        valet.authenticationContextProvider = { authContext }
        _ = try valet.string(forKey: key, withPrompt: prompt, withFallbackTitle: fallback)

        XCTAssertEqual(authContext.evaluatePolicyCalls.count, 1)
        XCTAssertEqual(authContext.evaluatePolicyCalls.first, .deviceOwnerAuthentication)
    }

    func test_stringForKeyWithPromptWithFallbackTitle_biometricCurrentSetUsesDeviceOwnerAuthenticationWithBiometrics() throws {
        let valet = SecureEnclaveValet.valet(with: type(of: self).identifier, accessControl: .biometricCurrentSet)
        try valet.setString(passcode, forKey: key)
        let authContext = MockLAContext(evaluatePolicyReply: (true, nil))
        valet.authenticationContextProvider = { authContext }
        _ = try valet.string(forKey: key, withPrompt: prompt, withFallbackTitle: fallback)

        XCTAssertEqual(authContext.evaluatePolicyCalls.count, 1)
        XCTAssertEqual(authContext.evaluatePolicyCalls.first, .deviceOwnerAuthenticationWithBiometrics)
    }

    func test_stringForKeyWithPromptWithFallbackTitle_throwsItemNotFoundForKeyWithNoValue() throws {
        let authContext = MockLAContext(evaluatePolicyReply: (true, nil))
        valet.authenticationContextProvider = { authContext }
        XCTAssertThrowsError(try valet.string(forKey: key, withPrompt: prompt, withFallbackTitle: fallback)) { error in
            XCTAssertEqual(error as? KeychainError, .itemNotFound)
            XCTAssertEqual(authContext.evaluatePolicyCalls.count, 1)
        }
    }

    func test_stringForKeyWithPromptWithFallbackTitle_retrievesStringForValidKey() throws {
        try valet.setString(passcode, forKey: key)

        let authContext = MockLAContext(evaluatePolicyReply: (true, nil))
        valet.authenticationContextProvider = { authContext }
        XCTAssertEqual(passcode, try valet.string(forKey: key, withPrompt: prompt, withFallbackTitle: fallback))
        XCTAssertEqual(authContext.evaluatePolicyCalls.count, 1)
    }

    func test_stringForKeyWithPromptWithFallbackTitle_throwsLAError() throws {
        try valet.setString(passcode, forKey: key)

        let expectedError = LAError(.authenticationFailed)
        let authContext = MockLAContext(evaluatePolicyReply: (false, expectedError))
        valet.authenticationContextProvider = { authContext }

        XCTAssertThrowsError(try valet.string(forKey: key, withPrompt: prompt, withFallbackTitle: fallback)) { error in
            XCTAssertEqual(error as? LAError, expectedError)
            XCTAssertEqual(authContext.evaluatePolicyCalls.count, 1)
        }
    }

}

// MARK: -

/// A class faking biometric user verification
private final class MockLAContext: LAContext {

    // MARK: - Private Properties

    private let evaluatePolicyReply: (Bool, Error?)

    // MARK: - Life Cycle

    init(evaluatePolicyReply: (Bool, Error?)) {
        self.evaluatePolicyReply = evaluatePolicyReply
    }

    // MARK: - LAContext

    private(set) var evaluatePolicyCalls = [LAPolicy]()
    override func evaluatePolicy(
        _ policy: LAPolicy,
        localizedReason: String,
        reply: @escaping (Bool, Error?) -> Void
    ) {
        evaluatePolicyCalls.append(policy)
        reply(evaluatePolicyReply.0, evaluatePolicyReply.1)
    }

}
