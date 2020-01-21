//
//  SecureEnclaveValet.swift
//  Valet
//
//  Created by Dan Federman on 9/18/17.
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


/// Reads and writes keychain elements that are stored on the Secure Enclave using Accessibility attribute `.whenPasscodeSetThisDeviceOnly`. Accessing these keychain elements will require the user to confirm their presence via Touch ID, Face ID, or passcode entry. If no passcode is set on the device, accessing the keychain via a `SecureEnclaveValet` will fail. Data is removed from the Secure Enclave when the user removes a passcode from the device.
@objc(VALSecureEnclaveValet)
public final class SecureEnclaveValet: NSObject {
    
    // MARK: Public Class Methods

    /// - Parameters:
    ///   - identifier: A non-empty string that uniquely identifies a SecureEnclaveValet.
    ///   - accessControl: The desired access control for the SecureEnclaveValet.
    /// - Returns: A SecureEnclaveValet that reads/writes keychain elements with the desired flavor.
    public class func valet(with identifier: Identifier, accessControl: SecureEnclaveAccessControl) -> SecureEnclaveValet {
        let key = Service.standard(identifier, .secureEnclave(accessControl)).description as NSString
        if let existingValet = identifierToValetMap.object(forKey: key) {
            return existingValet
            
        } else {
            let valet = SecureEnclaveValet(identifier: identifier, accessControl: accessControl)
            identifierToValetMap.setObject(valet, forKey: key)
            return valet
        }
    }

    /// - Parameters:
    ///   - identifier: A non-empty string that must correspond with the value for keychain-access-groups in your Entitlements file.
    ///   - accessControl: The desired access control for the SecureEnclaveValet.
    /// - Returns: A SecureEnclaveValet that reads/writes keychain elements that can be shared across applications written by the same development team.
    public class func sharedAccessGroupValet(with identifier: Identifier, accessControl: SecureEnclaveAccessControl) -> SecureEnclaveValet {
        let key = Service.sharedAccessGroup(identifier, .secureEnclave(accessControl)).description as NSString
        if let existingValet = identifierToValetMap.object(forKey: key) {
            return existingValet
            
        } else {
            let valet = SecureEnclaveValet(sharedAccess: identifier, accessControl: accessControl)
            identifierToValetMap.setObject(valet, forKey: key)
            return valet
        }
    }
    
    // MARK: Equatable
    
    /// - Returns: `true` if lhs and rhs both read from and write to the same sandbox within the keychain.
    public static func ==(lhs: SecureEnclaveValet, rhs: SecureEnclaveValet) -> Bool {
        lhs.service == rhs.service
    }
    
    // MARK: Private Class Properties
    
    private static let identifierToValetMap = NSMapTable<NSString, SecureEnclaveValet>.strongToWeakObjects()
    
    // MARK: Initialization
    
    @available(*, unavailable)
    public override init() {
        fatalError("Use the class methods above to create usable SecureEnclaveValet objects")
    }
    
    private convenience init(identifier: Identifier, accessControl: SecureEnclaveAccessControl) {
        self.init(
            identifier: identifier,
            service: .standard(identifier, .secureEnclave(accessControl)),
            accessControl: accessControl)
    }
    
    private convenience init(sharedAccess identifier: Identifier, accessControl: SecureEnclaveAccessControl) {
        self.init(
            identifier: identifier,
            service: .sharedAccessGroup(identifier, .secureEnclave(accessControl)),
            accessControl: accessControl)
    }

    private init(identifier: Identifier, service: Service, accessControl: SecureEnclaveAccessControl) {
        self.identifier = identifier
        self.service = service
        self.accessControl = accessControl
        _keychainQuery = try? service.generateBaseQuery()
    }
    
    // MARK: Hashable
    
    public override var hash: Int {
        service.description.hashValue
    }
    
    // MARK: Public Properties
    
    public let identifier: Identifier
    @objc
    public let accessControl: SecureEnclaveAccessControl
    
    // MARK: Public Methods
    
    /// - Returns: `true` if the keychain is accessible for reading and writing, `false` otherwise.
    /// - Note: Determined by writing a value to the keychain and then reading it back out. Will never prompt the user for Face ID, Touch ID, or password.
    @objc
    public func canAccessKeychain() -> Bool {
        SecureEnclave.canAccessKeychain(with: service, identifier: identifier)
    }

    /// - Parameters:
    ///   - object: A Data value to be inserted into the keychain.
    ///   - key: A key that can be used to retrieve the `object` from the keychain.
    /// - Throws: An error of type `KeychainError`.
    @objc
    public func setObject(_ object: Data, forKey key: String) throws {
        try execute(in: lock) {
            try SecureEnclave.setObject(object, forKey: key, options: try keychainQuery())
        }
    }

    /// - Parameters:
    ///   - key: A key used to retrieve the desired object from the keychain.
    ///   -  userPrompt: The prompt displayed to the user in Apple's Face ID, Touch ID, or passcode entry UI.
    /// - Returns: The data currently stored in the keychain for the provided key.
    /// - Throws: An error of type `KeychainError`.
    @objc
    public func object(forKey key: String, withPrompt userPrompt: String) throws -> Data {
        try execute(in: lock) {
            try SecureEnclave.object(forKey: key, withPrompt: userPrompt, options: try keychainQuery())
        }
    }

    /// - Parameter key: The key to look up in the keychain.
    /// - Returns: `true` if a value has been set for the given key, `false` otherwise.
    /// - Throws: An error of type `KeychainError`.
    /// - Note: Will never prompt the user for Face ID, Touch ID, or password.
    public func containsObject(forKey key: String) throws -> Bool {
        try execute(in: lock) {
            try SecureEnclave.containsObject(forKey: key, options: try keychainQuery())
        }
    }

    /// - Parameters:
    ///   - string: A String value to be inserted into the keychain.
    ///   - key: A key that can be used to retrieve the `string` from the keychain.
    /// - Throws: An error of type `KeychainError`.
    @objc
    public func setString(_ string: String, forKey key: String) throws {
        try execute(in: lock) {
            try SecureEnclave.setString(string, forKey: key, options: try keychainQuery())
        }
    }

    /// - Parameters:
    ///   - key: A key used to retrieve the desired object from the keychain.
    ///   - userPrompt: The prompt displayed to the user in Apple's Face ID, Touch ID, or passcode entry UI.
    /// - Returns: The string currently stored in the keychain for the provided key.
    /// - Throws: An error of type `KeychainError`.
    @objc
    public func string(forKey key: String, withPrompt userPrompt: String) throws -> String {
        try execute(in: lock) {
            try SecureEnclave.string(forKey: key, withPrompt: userPrompt, options: try keychainQuery())
        }
    }
    
    /// Removes a key/object pair from the keychain.
    /// - Parameter key: A key used to remove the desired object from the keychain.
    /// - Throws: An error of type `KeychainError`.
    @objc
    public func removeObject(forKey key: String) throws {
        try execute(in: lock) {
            try Keychain.removeObject(forKey: key, options: try keychainQuery())
        }
    }
    
    /// Removes all key/object pairs accessible by this Valet instance from the keychain.
    /// - Throws: An error of type `KeychainError`.
    @objc
    public func removeAllObjects() throws {
        try execute(in: lock) {
            try Keychain.removeAllObjects(matching: try keychainQuery())
        }
    }
    
    /// Migrates objects matching the input query into the receiving SecureEnclaveValet instance.
    /// - Parameters:
    ///   - query: The query with which to retrieve existing keychain data via a call to SecItemCopyMatching.
    ///   - removeOnCompletion: If `true`, the migrated data will be removed from the keychain if the migration succeeds.
    /// - Throws: An error of type `KeychainError` or `MigrationError`.
    /// - Note: The keychain is not modified if an error is thrown.
    @objc
    public func migrateObjects(matching query: [String : AnyHashable], removeOnCompletion: Bool) throws {
        try execute(in: lock) {
            try Keychain.migrateObjects(matching: query, into: try keychainQuery(), removeOnCompletion: removeOnCompletion)
        }
    }
    
    /// Migrates objects matching the vended keychain query into the receiving SecureEnclaveValet instance.
    /// - Parameters:
    ///   - valet: A Valet whose vended keychain query is used to retrieve existing keychain data via a call to SecItemCopyMatching.
    ///   - removeOnCompletion: If `true`, the migrated data will be removed from the keychfain if the migration succeeds.
    /// - Throws: An error of type `KeychainError` or `MigrationError`.
    /// - Note: The keychain is not modified if an error is thrown.
    @objc
    public func migrateObjects(from valet: Valet, removeOnCompletion: Bool) throws {
        try migrateObjects(matching: try valet.keychainQuery(), removeOnCompletion: removeOnCompletion)
    }

    // MARK: Internal Properties

    internal let service: Service

    // MARK: Private Properties

    private let lock = NSLock()
    private var _keychainQuery: [String : AnyHashable]?

    // MARK: Private Methods

    private func keychainQuery() throws -> [String : AnyHashable] {
        if let keychainQuery = _keychainQuery {
            return keychainQuery
        } else {
            let keychainQuery = try service.generateBaseQuery()
            _keychainQuery = keychainQuery
            return keychainQuery
        }
    }
}


// MARK: - Objective-C Compatibility


extension SecureEnclaveValet {
    
    // MARK: Public Class Methods
    /// - Parameters:
    ///   - identifier: A non-empty string that uniquely identifies a SecureEnclaveValet.
    ///   - accessControl: The desired access control for the SecureEnclaveValet.
    /// - Returns: A SecureEnclaveValet that reads/writes keychain elements with the desired flavor.
    @objc(valetWithIdentifier:accessControl:)
    public class func 🚫swift_valet(with identifier: String, accessControl: SecureEnclaveAccessControl) -> SecureEnclaveValet? {
        guard let identifier = Identifier(nonEmpty: identifier) else {
            return nil
        }
        return valet(with: identifier, accessControl: accessControl)
    }
    
    /// - Parameters:
    ///   - identifier: A non-empty string that must correspond with the value for keychain-access-groups in your Entitlements file.
    ///   - accessControl: The desired access control for the SecureEnclaveValet.
    /// - Returns: A SecureEnclaveValet that reads/writes keychain elements that can be shared across applications written by the same development team.
    @objc(sharedAccessGroupValetWithIdentifier:accessControl:)
    public class func 🚫swift_sharedAccessGroupValet(with identifier: String, accessControl: SecureEnclaveAccessControl) -> SecureEnclaveValet? {
        guard let identifier = Identifier(nonEmpty: identifier) else {
            return nil
        }
        return sharedAccessGroupValet(with: identifier, accessControl: accessControl)
    }

    /// - Parameter key: The key to look up in the keychain.
    /// - Returns: `true` if a value has been set for the given key, `false` otherwise. Will return `false` if the keychain is not accessible.
    /// - Note: Will never prompt the user for Face ID, Touch ID, or password.
    @available(swift, obsoleted: 1.0)
    @objc(containsObjectForKey:)
    public func 🚫swift_containsObject(forKey key: String) -> Bool {
        guard let containsObject = try? containsObject(forKey: key) else {
            return false
        }
        return containsObject
    }

}
