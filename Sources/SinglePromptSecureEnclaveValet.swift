//
//  SinglePromptSecureEnclaveValet.swift
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

import LocalAuthentication
import Foundation


/// Reads and writes keychain elements that are stored on the Secure Enclave using Accessibility attribute `.whenPasscodeSetThisDeviceOnly`. The first access of these keychain elements will require the user to confirm their presence via Touch ID, Face ID, or passcode entry. If no passcode is set on the device, accessing the keychain via a `SinglePromptSecureEnclaveValet` will fail. Data is removed from the Secure Enclave when the user removes a passcode from the device.
@available(macOS 10.11, *)
@objc(VALSinglePromptSecureEnclaveValet)
public final class SinglePromptSecureEnclaveValet: NSObject {
    
    // MARK: Public Class Methods
    
    /// - parameter identifier: A non-empty string that uniquely identifies a SinglePromptSecureEnclaveValet.
    /// - returns: A SinglePromptSecureEnclaveValet that reads/writes keychain elements with the desired flavor.
    public class func valet(with identifier: Identifier, accessControl: SecureEnclaveAccessControl) -> SinglePromptSecureEnclaveValet {
        let key = Service.standard(identifier, .singlePromptSecureEnclave(accessControl)).description as NSString
        if let existingValet = identifierToValetMap.object(forKey: key) {
            return existingValet
            
        } else {
            let valet = SinglePromptSecureEnclaveValet(identifier: identifier, accessControl: accessControl)
            identifierToValetMap.setObject(valet, forKey: key)
            return valet
        }
    }
    
    /// - parameter identifier: A non-empty string that must correspond with the value for keychain-access-groups in your Entitlements file.
    /// - returns: A SinglePromptSecureEnclaveValet that reads/writes keychain elements that can be shared across applications written by the same development team.
    public class func sharedAccessGroupValet(with identifier: Identifier, accessControl: SecureEnclaveAccessControl) -> SinglePromptSecureEnclaveValet {
        let key = Service.sharedAccessGroup(identifier, .singlePromptSecureEnclave(accessControl)).description as NSString
        if let existingValet = identifierToValetMap.object(forKey: key) {
            return existingValet
            
        } else {
            let valet = SinglePromptSecureEnclaveValet(sharedAccess: identifier, accessControl: accessControl)
            identifierToValetMap.setObject(valet, forKey: key)
            return valet
        }
    }
    
    // MARK: Equatable
    
    /// - returns: `true` if lhs and rhs both read from and write to the same sandbox within the keychain.
    public static func ==(lhs: SinglePromptSecureEnclaveValet, rhs: SinglePromptSecureEnclaveValet) -> Bool {
        return lhs.service == rhs.service
    }
    
    // MARK: Private Class Properties
    
    private static let identifierToValetMap = NSMapTable<NSString, SinglePromptSecureEnclaveValet>.strongToWeakObjects()
    
    // MARK: Initialization
    
    @available(*, unavailable)
    public override init() {
        fatalError("Use the class methods above to create usable SinglePromptSecureEnclaveValet objects")
    }
    
    private init(identifier: Identifier, accessControl: SecureEnclaveAccessControl) {
        service = .standard(identifier, .singlePromptSecureEnclave(accessControl))
        baseKeychainQuery = service.generateBaseQuery()
        self.identifier = identifier
        self.accessControl = accessControl
    }
    
    private init(sharedAccess identifier: Identifier, accessControl: SecureEnclaveAccessControl) {
        service = .sharedAccessGroup(identifier, .singlePromptSecureEnclave(accessControl))
        baseKeychainQuery = service.generateBaseQuery()
        self.identifier = identifier
        self.accessControl = accessControl
    }
    
    // MARK: Hashable
    
    public override var hash: Int {
        return service.description.hashValue
    }
    
    // MARK: Public Properties
    
    public let identifier: Identifier
    @objc
    public let accessControl: SecureEnclaveAccessControl
    
    // MARK: Public Methods
    
    /// - returns: `true` if the keychain is accessible for reading and writing, `false` otherwise.
    /// - note: Determined by writing a value to the keychain and then reading it back out. Will never prompt the user for Face ID, Touch ID, or password.
    @objc
    public func canAccessKeychain() -> Bool {
        return SecureEnclave.canAccessKeychain(with: service, identifier: identifier)
    }
    
    /// - parameter object: A Data value to be inserted into the keychain.
    /// - parameter key: A Key that can be used to retrieve the `object` from the keychain.
    /// - returns: `false` if the keychain is not accessible.
    @objc(setObject:forKey:)
    @discardableResult
    public func set(object: Data, forKey key: String) -> Bool {
        return execute(in: lock) {
            return SecureEnclave.set(object: object, forKey: key, options: baseKeychainQuery)
        }
    }
    
    /// - parameter key: A Key used to retrieve the desired object from the keychain.
    /// - parameter userPrompt: The prompt displayed to the user in Apple's Face ID, Touch ID, or passcode entry UI. If the `SinglePromptSecureEnclaveValet` has already been unlocked, no prompt will be shown.
    /// - returns: The data currently stored in the keychain for the provided key. Returns `.itemNotFound` if no object exists in the keychain for the specified key, or if the keychain is inaccessible. Returns `.userCancelled` if the user cancels the user-presence prompt.
    public func object(forKey key: String, withPrompt userPrompt: String) -> SecureEnclave.Result<Data> {
        return execute(in: lock) {
            return SecureEnclave.object(forKey: key, withPrompt: userPrompt, options: continuedAuthenticationKeychainQuery)
        }
    }
    
    /// - parameter key: The key to look up in the keychain.
    /// - returns: `true` if a value has been set for the given key, `false` otherwise.
    /// - note: Will never prompt the user for Face ID, Touch ID, or password.
    @objc(containsObjectForKey:)
    public func containsObject(forKey key: String) -> Bool {
        return execute(in: lock) {
            return SecureEnclave.containsObject(forKey: key, options: baseKeychainQuery)
        }
    }
    
    /// - parameter string: A String value to be inserted into the keychain.
    /// - parameter key: A Key that can be used to retrieve the `string` from the keychain.
    /// - returns: `true` if the operation succeeded, or `false` if the keychain is not accessible.
    @objc(setString:forKey:)
    @discardableResult
    public func set(string: String, forKey key: String) -> Bool {
        return execute(in: lock) {
            return SecureEnclave.set(string: string, forKey: key, options: baseKeychainQuery)
        }
    }
    
    /// - parameter key: A Key used to retrieve the desired object from the keychain.
    /// - parameter userPrompt: The prompt displayed to the user in Apple's Face ID, Touch ID, or passcode entry UI. If the `SinglePromptSecureEnclaveValet` has already been unlocked, no prompt will be shown.
    /// - returns: The string currently stored in the keychain for the provided key. Returns `nil` if no string exists in the keychain for the specified key, or if the keychain is inaccessible.
    public func string(forKey key: String, withPrompt userPrompt: String) -> SecureEnclave.Result<String> {
        return execute(in: lock) {
            return SecureEnclave.string(forKey: key, withPrompt: userPrompt, options: continuedAuthenticationKeychainQuery)
        }
    }
    
    /// Forces a prompt for Face ID, Touch ID, or passcode entry on the next data retrieval from the Secure Enclave.
    @objc
    public func requirePromptOnNextAccess() {
        execute(in: lock) {
            localAuthenticationContext.invalidate()
            localAuthenticationContext = LAContext()
        }
    }
    
    /// - parameter userPrompt: The prompt displayed to the user in Apple's Face ID, Touch ID, or passcode entry UI. If the `SinglePromptSecureEnclaveValet` has already been unlocked, no prompt will be shown.
    /// - returns: The set of all (String) keys currently stored in this Valet instance.
    @objc(allKeysWithUserPrompt:)
    public func allKeys(userPrompt: String) -> Set<String> {
        return execute(in: lock) {
            var secItemQuery = continuedAuthenticationKeychainQuery
            if !userPrompt.isEmpty {
                secItemQuery[kSecUseOperationPrompt as String] = userPrompt
            }
            
            return Keychain.allKeys(options: secItemQuery).value ?? Set()
        }
    }
    
    /// Removes a key/object pair from the keychain.
    /// - returns: `false` if the keychain is not accessible.
    @objc(removeObjectForKey:)
    @discardableResult
    public func removeObject(forKey key: String) -> Bool {
        return execute(in: lock) {
            return Keychain.removeObject(forKey: key, options: baseKeychainQuery).didSucceed
        }
    }
    
    /// Removes all key/object pairs accessible by this Valet instance from the keychain.
    /// - returns: `false` if the keychain is not accessible.
    @objc
    @discardableResult
    public func removeAllObjects() -> Bool {
        return execute(in: lock) {
            return Keychain.removeAllObjects(matching: baseKeychainQuery).didSucceed
        }
    }
    
    /// Migrates objects matching the input query into the receiving SinglePromptSecureEnclaveValet instance.
    /// - parameter query: The query with which to retrieve existing keychain data via a call to SecItemCopyMatching.
    /// - parameter removeOnCompletion: If `true`, the migrated data will be removed from the keychain if the migration succeeds.
    /// - returns: Whether the migration succeeded or failed.
    /// - note: The keychain is not modified if a failure occurs.
    @objc(migrateObjectsMatchingQuery:removeOnCompletion:)
    public func migrateObjects(matching query: [String : AnyHashable], removeOnCompletion: Bool) -> MigrationResult {
        return execute(in: lock) {
            return Keychain.migrateObjects(matching: query, into: baseKeychainQuery, removeOnCompletion: removeOnCompletion)
        }
    }
    
    /// Migrates objects matching the vended keychain query into the receiving SinglePromptSecureEnclaveValet instance.
    /// - parameter keychain: An objects whose vended keychain query is used to retrieve existing keychain data via a call to SecItemCopyMatching.
    /// - parameter removeOnCompletion: If `true`, the migrated data will be removed from the keychfain if the migration succeeds.
    /// - returns: Whether the migration succeeded or failed.
    /// - note: The keychain is not modified if a failure occurs.
    @objc(migrateObjectsFromKeychain:removeOnCompletion:)
    public func migrateObjects(from keychain: KeychainQueryConvertible, removeOnCompletion: Bool) -> MigrationResult {
        return migrateObjects(matching: keychain.keychainQuery, removeOnCompletion: removeOnCompletion)
    }

    // MARK: Internal Properties

    internal let service: Service

    // MARK: Private Properties

    private let lock = NSLock()
    private let baseKeychainQuery: [String : AnyHashable]
    private var localAuthenticationContext = LAContext()

    /// A keychain query dictionary that allows for continued read access to the Secure Enclave after the a single unlock event.
    /// This query should be used when retrieving keychain data, but should not be used for keychain writes or `containsObject` checks.
    /// Using this query in a `containsObject` check can cause a false positive in the case where an element has been removed from
    /// the keychain by the operating system due to a face, fingerprint, or password change.
    private var continuedAuthenticationKeychainQuery: [String : AnyHashable] {
        var keychainQuery = baseKeychainQuery
        keychainQuery[kSecUseAuthenticationContext as String] = localAuthenticationContext
        return keychainQuery
    }
}


// MARK: - Objective-C Compatibility


@available(macOS 10.11, *)
extension SinglePromptSecureEnclaveValet {
    
    // MARK: Public Class Methods
    
    /// - parameter identifier: A non-empty string that uniquely identifies a SinglePromptSecureEnclaveValet.
    /// - returns: A SinglePromptSecureEnclaveValet that reads/writes keychain elements with the desired flavor.
    @objc(valetWithIdentifier:accessControl:)
    public class func 🚫swift_valet(with identifier: String, accessControl: SecureEnclaveAccessControl) -> SinglePromptSecureEnclaveValet? {
        guard let identifier = Identifier(nonEmpty: identifier) else {
            return nil
        }
        
        return valet(with: identifier, accessControl: accessControl)
    }
    
    /// - parameter identifier: A non-empty string that must correspond with the value for keychain-access-groups in your Entitlements file.
    /// - returns: A SinglePromptSecureEnclaveValet that reads/writes keychain elements that can be shared across applications written by the same development team.
    @objc(sharedAccessGroupValetWithIdentifier:accessControl:)
    public class func 🚫swift_sharedAccessGroupValet(with identifier: String, accessControl: SecureEnclaveAccessControl) -> SinglePromptSecureEnclaveValet? {
        guard let identifier = Identifier(nonEmpty: identifier) else {
            return nil
        }
        return sharedAccessGroupValet(with: identifier, accessControl: accessControl)
    }
    
    // MARK: Public Methods
    
    /// - parameter key: A Key used to retrieve the desired object from the keychain.
    /// - parameter userPrompt: The prompt displayed to the user in Apple's Face ID, Touch ID, or passcode entry UI.
    /// - returns: The data currently stored in the keychain for the provided key. Returns `nil` if no object exists in the keychain for the specified key, or if the keychain is inaccessible.
    @available(swift, obsoleted: 1.0)
    @objc(objectForKey:userPrompt:userCancelled:)
    public func 🚫swift_object(forKey key: String, withPrompt userPrompt: String, userCancelled: UnsafeMutablePointer<ObjCBool>?) -> Data? {
        switch object(forKey: key, withPrompt: userPrompt) {
        case let .success(data):
            return data
        case .userCancelled:
            userCancelled?.pointee = true
            return nil
        case .itemNotFound:
            return nil
        }
    }
    
    /// - parameter key: A Key used to retrieve the desired object from the keychain.
    /// - parameter userPrompt: The prompt displayed to the user in Apple's Face ID, Touch ID, or passcode entry UI.
    /// - returns: The string currently stored in the keychain for the provided key. Returns `nil` if no string exists in the keychain for the specified key, or if the keychain is inaccessible.
    @available(swift, obsoleted: 1.0)
    @objc(stringForKey:userPrompt:userCancelled:)
    public func 🚫swift_string(forKey key: String, withPrompt userPrompt: String, userCancelled: UnsafeMutablePointer<ObjCBool>?) -> String? {
        switch string(forKey: key, withPrompt: userPrompt) {
        case let .success(string):
            return string
        case .userCancelled:
            userCancelled?.pointee = true
            return nil
        case .itemNotFound:
            return nil
        }
    }
}
