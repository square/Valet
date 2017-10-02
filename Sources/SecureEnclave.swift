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
    
    // MARK: Result
    
    public enum Result<Type: Equatable>: Equatable {
        /// Data was retrieved from the keychain.
        case success(Type)
        /// User dismissed the user-presence prompt.
        case userCancelled
        /// No data was found for the requested key.
        case itemNotFound
        
        // MARK: Equatable
        
        public static func ==(lhs: Result<Type>, rhs: Result<Type>) -> Bool {
            switch lhs {
            case let .success(lhsResult):
                if case let .success(rhsResult) = rhs, lhsResult == rhsResult {
                    return true
                } else {
                    return false
                }
            case .userCancelled:
                if case .userCancelled = rhs {
                    return true
                } else {
                    return false
                }
            case .itemNotFound:
                if case .itemNotFound = rhs {
                    return true
                } else {
                    return false
                }
            }
        }
    }
    
    // MARK: Flavor
    
    internal enum Flavor {
        /// Can read multiple items from the Secure Enclave with only a single user-presence prompt to retrieve multiple items.
        case singlePrompt(SecureEnclaveAccessControl)
        /// Requires a user-presence prompt to retrieve each item in the Secure Enclave.
        case alwaysPrompt(SecureEnclaveAccessControl)
    }
    
    // MARK: Internal Methods
    
    /// - parameter service: The service of the keychain slice we want to check if we can access.
    /// - parameter identifier: A non-empty identifier that scopes the slice of keychain we want to access.
    /// - returns: `true` if the keychain is accessible for reading and writing, `false` otherwise.
    /// - note: Determined by writing a value to the keychain and then reading it back out.
    internal static func canAccessKeychain(with service: Service, identifier: Identifier) -> Bool {
        // To avoid prompting the user for Touch ID or passcode, create a Valet with our identifier and accessibility and ask it if it can access the keychain.
        let noPromptValet: Valet
        switch service {
        case .standard:
            noPromptValet = .valet(with: identifier, flavor: .vanilla(.whenPasscodeSetThisDeviceOnly))
        case .sharedAccessGroup:
            noPromptValet = .sharedAccessGroupValet(with: identifier, flavor: .vanilla(.whenPasscodeSetThisDeviceOnly))
        }
        
        return noPromptValet.canAccessKeychain()
    }
    
    /// - parameter object: A Data value to be inserted into the keychain.
    /// - parameter key: A Key that can be used to retrieve the `object` from the keychain.
    /// - parameter options: A base query used to scope the calls in the keychain.
    /// - returns: `false` if the keychain is not accessible.
    @discardableResult
    internal static func set(object: Data, for key: Key, options: [String : AnyHashable]) -> Bool {
        // Remove the key before trying to set it. This will prevent us from calling SecItemUpdate on an item stored on the Secure Enclave, which would cause iOS to prompt the user for authentication.
        _ = Keychain.removeObject(for: key, options: options)
        
        switch Keychain.set(object: object, for: key, options: options) {
        case .success:
            return true
            
        case .error:
            return false
        }
    }
    
    /// - parameter key: A Key used to retrieve the desired object from the keychain.
    /// - parameter userPrompt: The prompt displayed to the user in Apple's Face ID, Touch ID, or passcode entry UI.
    /// - parameter options: A base query used to scope the calls in the keychain.
    /// - returns: The data currently stored in the keychain for the provided key. Returns `nil` if no object exists in the keychain for the specified key, or if the keychain is inaccessible.
    internal static func object(for key: Key, withPrompt userPrompt: String, options: [String : AnyHashable]) -> Result<Data> {
        var secItemQuery = options
        if !userPrompt.isEmpty {
            secItemQuery[kSecUseOperationPrompt as String] = userPrompt
        }
        
        switch Keychain.object(for: key, options: secItemQuery) {
        case let .success(data):
            return .success(data)
            
        case let .error(status):
            let userCancelled = (status == errSecUserCanceled || status == errSecAuthFailed)
            if userCancelled {
                return .userCancelled
            } else {
                return .itemNotFound
            }
        }
    }
    
    /// - parameter key: The key to look up in the keychain.
    /// - parameter options: A base query used to scope the calls in the keychain.
    /// - returns: `true` if a value has been set for the given key, `false` otherwise.
    internal static func containsObject(for key: Key, options: [String : AnyHashable]) -> Bool {
        var secItemQuery = options
        secItemQuery[kSecUseAuthenticationUI as String] = kSecUseAuthenticationUIFail
        
        switch Keychain.containsObject(for: key, options: secItemQuery) {
        case .success:
            return true
            
        case let .error(status):
            let keyAlreadyInKeychain = (status == errSecInteractionNotAllowed || status == errSecSuccess)
            return keyAlreadyInKeychain
        }
    }
    
    /// - parameter string: A String value to be inserted into the keychain.
    /// - parameter key: A Key that can be used to retrieve the `string` from the keychain.
    /// - parameter options: A base query used to scope the calls in the keychain.
    /// @return NO if the keychain is not accessible.
    @discardableResult
    internal static func set(string: String, for key: Key, options: [String : AnyHashable]) -> Bool {
        // Remove the key before trying to set it. This will prevent us from calling SecItemUpdate on an item stored on the Secure Enclave, which would cause iOS to prompt the user for authentication.
        _ = Keychain.removeObject(for: key, options: options)
        
        switch Keychain.set(string: string, for: key, options: options) {
        case .success:
            return true
            
        case .error:
            return false
        }
    }
    
    /// - parameter key: A Key used to retrieve the desired object from the keychain.
    /// - parameter userPrompt: The prompt displayed to the user in Apple's Face ID, Touch ID, or passcode entry UI.
    /// - parameter options: A base query used to scope the calls in the keychain.
    /// - returns: The string currently stored in the keychain for the provided key. Returns `nil` if no string exists in the keychain for the specified key, or if the keychain is inaccessible.
    internal static func string(for key: Key, withPrompt userPrompt: String, options: [String : AnyHashable]) -> Result<String> {
        var secItemQuery = options
        if !userPrompt.isEmpty {
            secItemQuery[kSecUseOperationPrompt as String] = userPrompt
        }
        
        switch Keychain.string(for: key, options: secItemQuery) {
        case let .success(string):
            return .success(string)
            
        case let .error(status):
            let userCancelled = (status == errSecUserCanceled || status == errSecAuthFailed)
            if userCancelled {
                return .userCancelled
            } else {
                return .itemNotFound
            }
        }
    }    
}
