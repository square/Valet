//
//  SecureEnclave.swift
//  Valet
//
//  Created by Dan Federman on 9/19/17.
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


public final class SecureEnclave {
        
    // MARK: Internal Methods

    /// - Parameter service: The service of the keychain slice we want to check if we can access.
    /// - Returns: `true` if the keychain is accessible for reading and writing, `false` otherwise.
    /// - Note: Determined by writing a value to the keychain and then reading it back out.
    internal static func canAccessKeychain(with service: Service) -> Bool {
        // To avoid prompting the user for Touch ID or passcode, create a Valet with our identifier and accessibility and ask it if it can access the keychain.
        let noPromptValet: Valet
        switch service {
        #if os(macOS)
        case let .standardOverride(identifier, _):
            noPromptValet = .valet(with: identifier, accessibility: .whenPasscodeSetThisDeviceOnly)
        #endif
        case let .standard(identifier, _):
            noPromptValet = .valet(with: identifier, accessibility: .whenPasscodeSetThisDeviceOnly)
        #if os(macOS)
        case let .sharedGroupOverride(identifier, _):
            noPromptValet = .sharedGroupValet(withExplicitlySet: identifier, accessibility: .whenPasscodeSetThisDeviceOnly)
        #endif
        case let .sharedGroup(identifier, _):
            noPromptValet = .sharedGroupValet(with: identifier, accessibility: .whenPasscodeSetThisDeviceOnly)
        }
        
        return noPromptValet.canAccessKeychain()
    }

    /// - Parameters:
    ///   - object: A Data value to be inserted into the keychain.
    ///   - key: A key that can be used to retrieve the `object` from the keychain.
    ///   - options: A base query used to scope the calls in the keychain.
    /// - Throws: An error of type `KeychainError`.
    internal static func setObject(_ object: Data, forKey key: String, options: [String : AnyHashable]) throws {
        // Remove the key before trying to set it. This will prevent us from calling SecItemUpdate on an item stored on the Secure Enclave, which would cause iOS to prompt the user for authentication.
        try Keychain.removeObject(forKey: key, options: options)
        
        try Keychain.setObject(object, forKey: key, options: options)
    }

    /// - Parameters:
    ///   - key: A key used to retrieve the desired object from the keychain.
    ///   - userPrompt: The prompt displayed to the user in Apple's Face ID, Touch ID, or passcode entry UI.
    ///   - options: A base query used to scope the calls in the keychain.
    /// - Returns: The data currently stored in the keychain for the provided key.
    /// - Throws: An error of type `KeychainError`.
    internal static func object(forKey key: String, withPrompt userPrompt: String, options: [String : AnyHashable]) throws -> Data {
        var secItemQuery = options
        if !userPrompt.isEmpty {
            secItemQuery[kSecUseOperationPrompt as String] = userPrompt
        }
        
        return try Keychain.object(forKey: key, options: secItemQuery)
    }

    /// - Parameters:
    ///   - key: The key to look up in the keychain.
    ///   - options: A base query used to scope the calls in the keychain.
    /// - Returns: `true` if a value has been set for the given key, `false` otherwise.
    /// - Throws: An error of type `KeychainError`.
    internal static func containsObject(forKey key: String, options: [String : AnyHashable]) throws -> Bool {
        var secItemQuery = options
        secItemQuery[kSecUseAuthenticationUI as String] = kSecUseAuthenticationUIFail

        let status = Keychain.performCopy(forKey: key, options: secItemQuery)
        switch status {
        case errSecSuccess,
             errSecInteractionNotAllowed:
            // An item exists in the keychain if we could successfully copy the item, or if we got an error telling us we weren't allowed to copy the item since we couldn't prompt the user.
            return true
        case errSecItemNotFound:
            return false
        default:
            throw KeychainError(status: status)
        }
    }

    /// - Parameters:
    ///   - string: A String value to be inserted into the keychain.
    ///   - key: A key that can be used to retrieve the `string` from the keychain.
    ///   - options: A base query used to scope the calls in the keychain.
    /// - Throws: An error of type `KeychainError`.
    internal static func setString(_ string: String, forKey key: String, options: [String : AnyHashable]) throws {
        // Remove the key before trying to set it. This will prevent us from calling SecItemUpdate on an item stored on the Secure Enclave, which would cause iOS to prompt the user for authentication.
        try Keychain.removeObject(forKey: key, options: options)
        
        try Keychain.setString(string, forKey: key, options: options)
    }

    /// - Parameters:
    ///   - key: A key used to retrieve the desired object from the keychain.
    ///   - userPrompt: The prompt displayed to the user in Apple's Face ID, Touch ID, or passcode entry UI.
    ///   - options: A base query used to scope the calls in the keychain.
    /// - Returns: The string currently stored in the keychain for the provided key.
    /// - Throws: An error of type `KeychainError`.
    internal static func string(forKey key: String, withPrompt userPrompt: String, options: [String : AnyHashable]) throws -> String {
        var secItemQuery = options
        if !userPrompt.isEmpty {
            secItemQuery[kSecUseOperationPrompt as String] = userPrompt
        }

        return try Keychain.string(forKey: key, options: secItemQuery)
    }
}
