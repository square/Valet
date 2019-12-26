//
//  Valet.swift
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


/// Reads and writes keychain elements.
@objc(VALValet)
public final class Valet: NSObject {

    // MARK: Public Class Methods

    /// - Parameters:
    ///   - identifier: A non-empty string that uniquely identifies a Valet.
    ///   - accessibility: The desired accessibility for the Valet.
    /// - Returns: A Valet that reads/writes keychain elements with the desired accessibility and identifier.
    public class func valet(with identifier: Identifier, accessibility: Accessibility) -> Valet {
        findOrCreate(identifier, configuration: .valet(accessibility))
    }

    /// - Parameters:
    ///   - identifier: A non-empty string that uniquely identifies a Valet.
    ///   - accessibility: The desired accessibility for the Valet.
    /// - Returns: A Valet (synchronized with iCloud) that reads/writes keychain elements with the desired accessibility and identifier.
    public class func iCloudValet(with identifier: Identifier, accessibility: CloudAccessibility) -> Valet {
        findOrCreate(identifier, configuration: .iCloud(accessibility))
    }

    /// - Parameters:
    ///   - identifier: A non-empty string that must correspond with the value for keychain-access-groups in your Entitlements file.
    ///   - accessibility: The desired accessibility for the Valet.
    /// - Returns: A Valet that reads/writes keychain elements that can be shared across applications written by the same development team.
    public class func sharedAccessGroupValet(with identifier: Identifier, accessibility: Accessibility) -> Valet {
        findOrCreate(identifier, configuration: .valet(accessibility), sharedAccessGroup: true)
    }

    /// - Parameters:
    ///   - identifier: A non-empty string that must correspond with the value for keychain-access-groups in your Entitlements file.
    ///   - accessibility: The desired accessibility for the Valet.
    /// - Returns: A Valet (synchronized with iCloud) that reads/writes keychain elements that can be shared across applications written by the same development team.
    public class func iCloudSharedAccessGroupValet(with identifier: Identifier, accessibility: CloudAccessibility) -> Valet {
        findOrCreate(identifier, configuration: .iCloud(accessibility), sharedAccessGroup: true)
    }
    
    // MARK: Equatable
    
    /// - Returns: `true` if lhs and rhs both read from and write to the same sandbox within the keychain.
    public static func ==(lhs: Valet, rhs: Valet) -> Bool {
        lhs.service == rhs.service
    }
    
    // MARK: Private Class Properties
    
    private static let identifierToValetMap = NSMapTable<NSString, Valet>.strongToWeakObjects()

    // MARK: Private Class Functions

    /// - Returns: a Valet with the given Identifier, Flavor (and a shared access group service if requested)
    private class func findOrCreate(_ identifier: Identifier, configuration: Configuration, sharedAccessGroup: Bool = false) -> Valet {
        let service: Service = sharedAccessGroup ? .sharedAccessGroup(identifier, configuration) : .standard(identifier, configuration)
        let key = service.description as NSString
        if let existingValet = identifierToValetMap.object(forKey: key) {
            return existingValet

        } else {
            let valet: Valet
            if sharedAccessGroup {
                valet = Valet(sharedAccess: identifier, configuration: configuration)
            } else {
                valet = Valet(identifier: identifier, configuration: configuration)
            }
            identifierToValetMap.setObject(valet, forKey: key)
            return valet
        }
    }
    
    // MARK: Initialization

    @available(*, unavailable)
    public override init() {
        fatalError("Use the class methods above to create usable Valet objects")
    }
    
    private convenience init(identifier: Identifier, configuration: Configuration) {
        self.init(
            identifier: identifier,
            service: .standard(identifier, configuration),
            configuration: configuration)
    }
    
    private convenience init(sharedAccess identifier: Identifier, configuration: Configuration) {
        self.init(
            identifier: identifier,
            service: .sharedAccessGroup(identifier, configuration),
            configuration: configuration)
    }

    private init(identifier: Identifier, service: Service, configuration: Configuration) {
        self.identifier = identifier
        self.configuration = configuration
        self.service = service
        accessibility = configuration.accessibility
        _keychainQuery = try? service.generateBaseQuery()
    }

    // MARK: CustomStringConvertible

    public override var description: String {
        "\(super.description) \(identifier.description) \(configuration.prettyDescription)"
    }

    // MARK: Hashable
    
    public override var hash: Int {
        service.description.hashValue
    }
    
    // MARK: Public Properties
    
    @objc
    public let accessibility: Accessibility
    public let identifier: Identifier

    // MARK: Public Methods
    
    /// - Returns: `true` if the keychain is accessible for reading and writing, `false` otherwise.
    /// - Note: Determined by writing a value to the keychain and then reading it back out.
    @objc
    public func canAccessKeychain() -> Bool {
        execute(in: lock) {
            guard let keychainQuery = try? keychainQuery() else {
                return false
            }
            return Keychain.canAccess(attributes: keychainQuery)
        }
    }
    
    /// - Parameters:
    ///   - object: A Data value to be inserted into the keychain.
    ///   - key: A key that can be used to retrieve the `object` from the keychain.
    /// - Note: Method will throw a `KeychainError` if an error occurs.
    @objc
    public func set(object: Data, forKey key: String) throws {
        try execute(in: lock) {
            try Keychain.set(object: object, forKey: key, options: try keychainQuery())
        }
    }
    
    /// - Parameter key: A Key used to retrieve the desired object from the keychain.
    /// - Returns: The data currently stored in the keychain for the provided key.
    /// - Note: Method will throw a `KeychainError` if an error occurs.
    @objc
    public func object(forKey key: String) throws -> Data {
        try execute(in: lock) {
            try Keychain.object(forKey: key, options: try keychainQuery())
        }
    }
    
    /// - Parameter key: The key to look up in the keychain.
    /// - Returns: `true` if a value has been set for the given key, `false` otherwise.
    @objc
    public func containsObject(forKey key: String) -> Bool {
        execute(in: lock) {
            guard let keychainQuery = try? self.keychainQuery() else {
                return false
            }
            switch Keychain.containsObject(forKey: key, options: keychainQuery) {
            case errSecSuccess:
                return true
            default:
                return false
            }
        }
    }
    
    /// - Parameters:
    ///   - string: A String value to be inserted into the keychain.
    ///   - key: A key that can be used to retrieve the `string` from the keychain.
    /// - Note: Method will throw a `KeychainError` if an error occurs.
    @objc
    public func set(string: String, forKey key: String) throws {
        try execute(in: lock) {
            try Keychain.set(string: string, forKey: key, options: try keychainQuery())
        }
    }

    /// - Parameter key: A key used to retrieve the desired object from the keychain.
    /// - Note: Method will throw a `KeychainError` if an error occurs.
    @objc
    public func string(forKey key: String) throws -> String {
        try execute(in: lock) {
            try Keychain.string(forKey: key, options: try keychainQuery())
        }
    }
    
    /// - Returns: The set of all (String) keys currently stored in this Valet instance. If no items are found, will return an empty set.
    /// - Note: Method will throw a `KeychainError` if an error occurs.
    @objc
    public func allKeys() throws -> Set<String> {
        try execute(in: lock) {
            try Keychain.allKeys(options: try keychainQuery())
        }
    }
    
    /// Removes a key/object pair from the keychain.
    /// - Parameter key: A key used to remove the desired object from the keychain.
    /// - Note: Method will throw a `KeychainError` if an error occurs.
    @objc
    public func removeObject(forKey key: String) throws {
        try execute(in: lock) {
            try Keychain.removeObject(forKey: key, options: try keychainQuery())
        }
    }
    
    /// Removes all key/object pairs accessible by this Valet instance from the keychain.
    /// - Note: Method will throw a `KeychainError` if an error occurs.
    @objc
    public func removeAllObjects() throws {
        try execute(in: lock) {
            try Keychain.removeAllObjects(matching: try keychainQuery())
        }
    }

    /// Migrates objects matching the input query into the receiving Valet instance.
    /// - Parameters:
    ///   - query: The query with which to retrieve existing keychain data via a call to SecItemCopyMatching.
    ///   - removeOnCompletion: If `true`, the migrated data will be removed from the keychain if the migration succeeds.
    /// - Note: The keychain is not modified if an error is thrown. Method will throw a `KeychainError` or `MigrationError` if an error occurs.
    @objc
    public func migrateObjects(matching query: [String : AnyHashable], removeOnCompletion: Bool) throws {
        try execute(in: lock) {
            try Keychain.migrateObjects(matching: query, into: try keychainQuery(), removeOnCompletion: removeOnCompletion)
        }
    }
    
    /// Migrates objects in the input Valet into the receiving Valet instance.
    /// - Parameters:
    ///   - valet: An objects whose vended keychain query is used to retrieve existing keychain data via a call to SecItemCopyMatching.
    ///   - removeOnCompletion: If `true`, the migrated data will be removed from the keychfain if the migration succeeds.
    /// - Note: The keychain is not modified if an error is thrown. Method will throw a `KeychainError` or `MigrationError` if an error occurs.
    @objc
    public func migrateObjects(from valet: Valet, removeOnCompletion: Bool) throws {
        try migrateObjects(matching: try valet.keychainQuery(), removeOnCompletion: removeOnCompletion)
    }

    /// Call this method if your Valet used to have its accessibility set to `always`.
    /// This method migrates objects set on a Valet with the same type and identifier, but with its accessibility set to `always` (which was possible prior to Valet 4.0) to the current Valet.
    /// - parameter removeOnCompletion: If `true`, the migrated data will be removed from the keychain if the migration succeeds.
    /// - returns: Whether the migration succeeded or failed.
    /// - note: The keychain is not modified if a failure occurs.
    @objc(migrateObjectsFromAlwaysAccessibleValetAndRemoveOnCompletion:)
    public func migrateObjectsFromAlwaysAccessibleValet(removeOnCompletion: Bool) -> MigrationResult {
        guard var keychainQuery = keychainQuery else {
            return .couldNotReadKeychain
        }
        keychainQuery[kSecAttrAccessible as String] = "dk" // kSecAttrAccessibleAlways, but with the value hardcoded to avoid a build warning.
        return migrateObjects(matching: keychainQuery, removeOnCompletion: removeOnCompletion)
    }

    /// Call this method if your Valet used to have its accessibility set to `alwaysThisDeviceOnly`.
    /// This method migrates objects set on a Valet with the same type and identifier, but with its accessibility set to `alwaysThisDeviceOnly` (which was possible prior to Valet 4.0) to the current Valet.
    /// - parameter removeOnCompletion: If `true`, the migrated data will be removed from the keychain if the migration succeeds.
    /// - returns: Whether the migration succeeded or failed.
    /// - note: The keychain is not modified if a failure occurs.
    @objc(migrateObjectsFromAlwaysAccessibleThisDeviceOnlyValetAndRemoveOnCompletion:)
    public func migrateObjectsFromAlwaysAccessibleThisDeviceOnlyValet(removeOnCompletion: Bool) -> MigrationResult {
        guard var keychainQuery = keychainQuery else {
            return .couldNotReadKeychain
        }
        keychainQuery[kSecAttrAccessible as String] = "dku" // kSecAttrAccessibleAlwaysThisDeviceOnly, but with the value hardcoded to avoid a build warning.
        return migrateObjects(matching: keychainQuery, removeOnCompletion: removeOnCompletion)
    }

    // MARK: Internal Properties

    internal let configuration: Configuration
    internal let service: Service

    // MARK: Internal Methods

    internal func keychainQuery() throws -> [String : AnyHashable] {
        if let keychainQuery = _keychainQuery {
            return keychainQuery
        } else {
            let keychainQuery = try service.generateBaseQuery()
            _keychainQuery = keychainQuery
            return keychainQuery
        }
    }

    // MARK: Private Properties

    private let lock = NSLock()
    private var _keychainQuery: [String : AnyHashable]?
}


// MARK: - Objective-C Compatibility


extension Valet {

    // MARK: Public Class Methods

    /// - Parameters:
    ///   - identifier: A non-empty string that uniquely identifies a Valet.
    ///   - accessibility: The desired accessibility for the Valet.
    /// - Returns: A Valet that reads/writes keychain elements with the desired accessibility.
    @available(swift, obsoleted: 1.0)
    @objc(valetWithIdentifier:accessibility:)
    public class func 🚫swift_vanillaValet(with identifier: String, accessibility: Accessibility) -> Valet? {
        guard let identifier = Identifier(nonEmpty: identifier) else {
            return nil
        }
        return valet(with: identifier, accessibility: accessibility)
    }
    
    /// - Parameters:
    ///   - identifier: A non-empty string that uniquely identifies a Valet.
    ///   - accessibility: The desired accessibility for the Valet.
    /// - Returns: A Valet that reads/writes iCloud-shared keychain elements with the desired accessibility.
    @available(swift, obsoleted: 1.0)
    @objc(iCloudValetWithIdentifier:accessibility:)
    public class func 🚫swift_iCloudValet(with identifier: String, accessibility: CloudAccessibility) -> Valet? {
        guard let identifier = Identifier(nonEmpty: identifier) else {
            return nil
        }
        return iCloudValet(with: identifier, accessibility: accessibility)
    }

    /// - Parameters:
    ///   - identifier: A non-empty string that must correspond with the value for keychain-access-groups in your Entitlements file.
    ///   - accessibility: The desired accessibility for the Valet.
    /// - Returns: A Valet that reads/writes keychain elements that can be shared across applications written by the same development team.
    @available(swift, obsoleted: 1.0)
    @objc(valetWithSharedAccessGroupIdentifier:accessibility:)
    public class func 🚫swift_vanillaSharedAccessGroupValet(with identifier: String, accessibility: Accessibility) -> Valet? {
        guard let identifier = Identifier(nonEmpty: identifier) else {
            return nil
        }
        return sharedAccessGroupValet(with: identifier, accessibility: accessibility)
    }

    /// - Parameters:
    ///   - identifier: A non-empty string that must correspond with the value for keychain-access-groups in your Entitlements file.
    ///   - accessibility: The desired accessibility for the Valet.
    /// - Returns: A Valet that reads/writes iCloud-shared keychain elements that can be shared across applications written by the same development team.
    @available(swift, obsoleted: 1.0)
    @objc(iCloudValetWithSharedAccessGroupIdentifier:accessibility:)
    public class func 🚫swift_iCloudSharedAccessGroupValet(with identifier: String, accessibility: CloudAccessibility) -> Valet? {
        guard let identifier = Identifier(nonEmpty: identifier) else {
            return nil
        }
        return iCloudSharedAccessGroupValet(with: identifier, accessibility: accessibility)
    }
    
}

// MARK: - Testing

internal extension Valet {

    // MARK: Permutations

    class func permutations(with identifier: Identifier, shared: Bool = false) -> [Valet] {
        Accessibility.allValues().map { accessibility in
            shared ? .sharedAccessGroupValet(with: identifier, accessibility: accessibility) : .valet(with: identifier, accessibility: accessibility)
        }
    }

    class func iCloudPermutations(with identifier: Identifier, shared: Bool = false) -> [Valet] {
        CloudAccessibility.allValues().map { cloudAccessibility in
            shared ? .iCloudSharedAccessGroupValet(with: identifier, accessibility: cloudAccessibility) : .iCloudValet(with: identifier, accessibility: cloudAccessibility)
        }
    }

}
