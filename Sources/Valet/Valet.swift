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
    
    /// - parameter identifier: A non-empty string that uniquely identifies a Valet.
    /// - parameter accessibility: The desired accessibility for the Valet.
    /// - returns: A Valet that reads/writes keychain elements with the desired accessibility and identifier.
    public class func valet(with identifier: Identifier, accessibility: Accessibility) -> Valet {
        return findOrCreate(identifier, configuration: .valet(accessibility))
    }

    /// - parameter identifier: A non-empty string that uniquely identifies a Valet.
    /// - parameter accessibility: The desired accessibility for the Valet.
    /// - returns: A Valet (synchronized with iCloud) that reads/writes keychain elements with the desired accessibility and identifier.
    public class func iCloudValet(with identifier: Identifier, accessibility: CloudAccessibility) -> Valet {
        return findOrCreate(identifier, configuration: .iCloud(accessibility))
    }

    /// - parameter identifier: A non-empty string that must correspond with the value for keychain-access-groups in your Entitlements file.
    /// - parameter accessibility: The desired accessibility for the Valet.
    /// - returns: A Valet that reads/writes keychain elements that can be shared across applications written by the same development team.
    public class func sharedAccessGroupValet(with identifier: Identifier, accessibility: Accessibility) -> Valet {
        return findOrCreate(identifier, configuration: .valet(accessibility), sharedAccessGroup: true)
    }

    /// - parameter identifier: A non-empty string that must correspond with the value for keychain-access-groups in your Entitlements file.
    /// - parameter accessibility: The desired accessibility for the Valet.
    /// - returns: A Valet (synchronized with iCloud) that reads/writes keychain elements that can be shared across applications written by the same development team.
    public class func iCloudSharedAccessGroupValet(with identifier: Identifier, accessibility: CloudAccessibility) -> Valet {
        return findOrCreate(identifier, configuration: .iCloud(accessibility), sharedAccessGroup: true)
    }

    #if os(macOS)
    /// Creates a Valet with an explicitly set kSecAttrService.
    /// See https://github.com/square/Valet/issues/140 for more information.
    /// - parameter identifier: A non-empty string that uniquely identifies a Valet. Must be unique relative to other Valet identifiers.
    /// - parameter accessibility: The desired accessibility for the Valet.
    /// - returns: A Valet that reads/writes keychain elements with the desired accessibility and identifier.
    public class func valet(withExplicitlySet identifier: Identifier, accessibility: Accessibility) -> Valet {
        return findOrCreate(explicitlySet: identifier, configuration: .valet(accessibility))
    }

    /// Creates an iCloud Valet with an explicitly set kSecAttrService.
    /// See https://github.com/square/Valet/issues/140 for more information.
    /// - parameter identifier: A non-empty string that uniquely identifies a Valet. Must be unique relative to other Valet identifiers.
    /// - parameter accessibility: The desired accessibility for the Valet.
    /// - returns: A Valet (synchronized with iCloud) that reads/writes keychain elements with the desired accessibility and identifier.
    public class func iCloudValet(withExplicitlySet identifier: Identifier, accessibility: CloudAccessibility) -> Valet {
        return findOrCreate(explicitlySet: identifier, configuration: .iCloud(accessibility))
    }

    /// Creates a shared-access-group Valet with an explicitly set kSecAttrService.
    /// See https://github.com/square/Valet/issues/140 for more information.
    /// - parameter identifier: A non-empty string that must correspond with the value for keychain-access-groups in your Entitlements file. Must be unique relative to other Valet identifiers.
    /// - parameter accessibility: The desired accessibility for the Valet.
    /// - returns: A Valet that reads/writes keychain elements that can be shared across applications written by the same development team.
    public class func sharedAccessGroupValet(withExplicitlySet identifier: Identifier, accessibility: Accessibility) -> Valet {
        return findOrCreate(explicitlySet: identifier, configuration: .valet(accessibility), sharedAccessGroup: true)
    }

    /// Creates an iCloud-shared-access-group Valet with an explicitly set kSecAttrService.
    /// See https://github.com/square/Valet/issues/140 for more information.
    /// - parameter identifier: A non-empty string that must correspond with the value for keychain-access-groups in your Entitlements file. Must be unique relative to other Valet identifiers.
    /// - parameter accessibility: The desired accessibility for the Valet.
    /// - returns: A Valet (synchronized with iCloud) that reads/writes keychain elements that can be shared across applications written by the same development team.
    public class func iCloudSharedAccessGroupValet(withExplicitlySet identifier: Identifier, accessibility: CloudAccessibility) -> Valet {
        return findOrCreate(explicitlySet: identifier, configuration: .iCloud(accessibility), sharedAccessGroup: true)
    }
    #endif
    
    // MARK: Equatable
    
    /// - returns: `true` if lhs and rhs both read from and write to the same sandbox within the keychain.
    public static func ==(lhs: Valet, rhs: Valet) -> Bool {
        return lhs.service == rhs.service
    }
    
    // MARK: Private Class Properties
    
    private static let identifierToValetMap = NSMapTable<NSString, Valet>.strongToWeakObjects()

    // MARK: Private Class Functions

    /// - returns: a Valet with the given Identifier, Flavor (and a shared access group service if requested)
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

    #if os(macOS)
    /// - returns: a Valet with the given Identifier, Flavor (and a shared access group service if requested)
    private class func findOrCreate(explicitlySet identifier: Identifier, configuration: Configuration, sharedAccessGroup: Bool = false) -> Valet {
        let service: Service = sharedAccessGroup ? .sharedAccessGroupOverride(service: identifier, configuration) : .standardOverride(service: identifier, configuration)
        let key = service.description as NSString
        if let existingValet = identifierToValetMap.object(forKey: key) {
            return existingValet

        } else {
            let valet: Valet
            if sharedAccessGroup {
                valet = Valet(overrideSharedAccess: identifier, configuration: configuration)
            } else {
                valet = Valet(overrideIdentifier: identifier, configuration: configuration)
            }
            identifierToValetMap.setObject(valet, forKey: key)
            return valet
        }
    }
    #endif
    
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
        _keychainQuery = service.generateBaseQuery()
    }

    #if os(macOS)
    private init(overrideIdentifier: Identifier, configuration: Configuration) {
        self.identifier = overrideIdentifier
        self.configuration = configuration
        service = .standardOverride(service: identifier, configuration)
        accessibility = configuration.accessibility
        _keychainQuery = service.generateBaseQuery()
    }

    private init(overrideSharedAccess identifier: Identifier, configuration: Configuration) {
        self.identifier = identifier
        self.configuration = configuration
        service = .sharedAccessGroupOverride(service: identifier, configuration)
        accessibility = configuration.accessibility
        _keychainQuery = service.generateBaseQuery()
    }
    #endif

    // MARK: CustomStringConvertible

    public override var description: String {
        return "\(super.description) \(identifier.description) \(configuration.prettyDescription)"
    }

    // MARK: Hashable
    
    public override var hash: Int {
        return service.description.hashValue
    }
    
    // MARK: Public Properties
    
    @objc
    public let accessibility: Accessibility
    public let identifier: Identifier

    // MARK: Public Methods
    
    /// - returns: `true` if the keychain is accessible for reading and writing, `false` otherwise.
    /// - note: Determined by writing a value to the keychain and then reading it back out.
    @objc
    public func canAccessKeychain() -> Bool {
        return execute(in: lock) {
            guard let keychainQuery = keychainQuery else {
                return false
            }
            return Keychain.canAccess(attributes: keychainQuery)
        }
    }
    
    /// - parameter object: A Data value to be inserted into the keychain.
    /// - parameter key: A Key that can be used to retrieve the `object` from the keychain.
    /// - returns: `false` if the keychain is not accessible.
    @objc(setObject:forKey:)
    @discardableResult
    public func set(object: Data, forKey key: String) -> Bool {
        return execute(in: lock) {
            guard let keychainQuery = keychainQuery else {
                return false
            }
            return Keychain.set(object: object, forKey: key, options: keychainQuery).didSucceed
        }
    }
    
    /// - parameter key: A Key used to retrieve the desired object from the keychain.
    /// - returns: The data currently stored in the keychain for the provided key. Returns `nil` if no object exists in the keychain for the specified key, or if the keychain is inaccessible.
    @objc(objectForKey:)
    public func object(forKey key: String) -> Data? {
        return execute(in: lock) {
            guard let keychainQuery = keychainQuery else {
                return nil
            }
            return Keychain.object(forKey: key, options: keychainQuery).value
        }
    }
    
    /// - parameter key: The key to look up in the keychain.
    /// - returns: `true` if a value has been set for the given key, `false` otherwise. Will return `false` if the keychain is not accessible.
    @objc(containsObjectForKey:)
    public func containsObject(forKey key: String) -> Bool {
        return execute(in: lock) {
            guard let keychainQuery = keychainQuery else {
                return false
            }
            return Keychain.containsObject(forKey: key, options: keychainQuery).didSucceed
        }
    }
    
    /// - parameter string: A String value to be inserted into the keychain.
    /// - parameter key: A Key that can be used to retrieve the `string` from the keychain.
    /// - returns: `true` if the operation succeeded, or `false` if the keychain is not accessible.
    @objc(setString:forKey:)
    @discardableResult
    public func set(string: String, forKey key: String) -> Bool {
        return execute(in: lock) {
            guard let keychainQuery = keychainQuery else {
                return false
            }
            return Keychain.set(string: string, forKey: key, options: keychainQuery).didSucceed
        }
    }
    
    /// - parameter key: A Key used to retrieve the desired object from the keychain.
    /// - returns: The string currently stored in the keychain for the provided key. Returns `nil` if no string exists in the keychain for the specified key, or if the keychain is inaccessible.
    @objc(stringForKey:)
    public func string(forKey key: String) -> String? {
        return execute(in: lock) {
            guard let keychainQuery = keychainQuery else {
                return nil
            }
            return Keychain.string(forKey: key, options: keychainQuery).value
        }
    }
    
    /// - returns: The set of all (String) keys currently stored in this Valet instance. Will return an empty set if the keychain is not accessible.
    @objc
    public func allKeys() -> Set<String> {
        return execute(in: lock) {
            guard let keychainQuery = keychainQuery else {
                return Set()
            }
            return Keychain.allKeys(options: keychainQuery).value ?? Set()
        }
    }
    
    /// Removes a key/object pair from the keychain.
    /// - returns: `false` if the keychain is not accessible.
    @objc(removeObjectForKey:)
    @discardableResult
    public func removeObject(forKey key: String) -> Bool {
        return execute(in: lock) {
            guard let keychainQuery = keychainQuery else {
                return false
            }
            return Keychain.removeObject(forKey: key, options: keychainQuery).didSucceed
        }
    }
    
    /// Removes all key/object pairs accessible by this Valet instance from the keychain.
    /// - returns: `false` if the keychain is not accessible.
    @objc
    @discardableResult
    public func removeAllObjects() -> Bool {
        return execute(in: lock) {
            guard let keychainQuery = keychainQuery else {
                return false
            }
            return Keychain.removeAllObjects(matching: keychainQuery).didSucceed
        }
    }
    
    /// Migrates objects matching the input query into the receiving Valet instance.
    /// - parameter query: The query with which to retrieve existing keychain data via a call to SecItemCopyMatching.
    /// - parameter removeOnCompletion: If `true`, the migrated data will be removed from the keychain if the migration succeeds.
    /// - returns: Whether the migration succeeded or failed.
    /// - note: The keychain is not modified if a failure occurs.
    @objc(migrateObjectsMatchingQuery:removeOnCompletion:)
    public func migrateObjects(matching query: [String : AnyHashable], removeOnCompletion: Bool) -> MigrationResult {
        return execute(in: lock) {
            guard let keychainQuery = keychainQuery else {
                return .couldNotReadKeychain
            }
            return Keychain.migrateObjects(matching: query, into: keychainQuery, removeOnCompletion: removeOnCompletion)
        }
    }
    
    /// Migrates objects in the input Valet into the receiving Valet instance.
    /// - parameter valet: A Valet whose objects should be migrated.
    /// - parameter removeOnCompletion: If `true`, the migrated data will be removed from the keychain if the migration succeeds.
    /// - returns: Whether the migration succeeded or failed.
    /// - note: The keychain is not modified if a failure occurs.
    @objc(migrateObjectsFromValet:removeOnCompletion:)
    public func migrateObjects(from valet: Valet, removeOnCompletion: Bool) -> MigrationResult {
        guard let keychainQuery = valet.keychainQuery else {
            return .couldNotReadKeychain
        }
        return migrateObjects(matching: keychainQuery, removeOnCompletion: removeOnCompletion)
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
    internal var keychainQuery: [String : AnyHashable]? {
        if let keychainQuery = _keychainQuery {
            return keychainQuery
        } else {
            _keychainQuery = service.generateBaseQuery()
            return _keychainQuery
        }
    }

    // MARK: Private Properties

    private let lock = NSLock()
    private var _keychainQuery: [String : AnyHashable]?
}


// MARK: - Objective-C Compatibility


extension Valet {

    // MARK: Public Class Methods
    
    /// - parameter identifier: A non-empty string that uniquely identifies a Valet.
    /// - parameter accessibility: The desired accessibility for the Valet.
    /// - returns: A Valet that reads/writes keychain elements with the desired accessibility.
    @available(swift, obsoleted: 1.0)
    @objc(valetWithIdentifier:accessibility:)
    public class func 🚫swift_vanillaValet(with identifier: String, accessibility: Accessibility) -> Valet? {
        guard let identifier = Identifier(nonEmpty: identifier) else {
            return nil
        }
        return valet(with: identifier, accessibility: accessibility)
    }
    
    /// - parameter identifier: A non-empty string that uniquely identifies a Valet.
    /// - parameter accessibility: The desired accessibility for the Valet.
    /// - returns: A Valet that reads/writes iCloud-shared keychain elements with the desired accessibility.
    @available(swift, obsoleted: 1.0)
    @objc(iCloudValetWithIdentifier:accessibility:)
    public class func 🚫swift_iCloudValet(with identifier: String, accessibility: CloudAccessibility) -> Valet? {
        guard let identifier = Identifier(nonEmpty: identifier) else {
            return nil
        }
        return iCloudValet(with: identifier, accessibility: accessibility)
    }
    
    /// - parameter identifier: A non-empty string that must correspond with the value for keychain-access-groups in your Entitlements file.
    /// - parameter accessibility: The desired accessibility for the Valet.
    /// - returns: A Valet that reads/writes keychain elements that can be shared across applications written by the same development team.
    @available(swift, obsoleted: 1.0)
    @objc(valetWithSharedAccessGroupIdentifier:accessibility:)
    public class func 🚫swift_vanillaSharedAccessGroupValet(with identifier: String, accessibility: Accessibility) -> Valet? {
        guard let identifier = Identifier(nonEmpty: identifier) else {
            return nil
        }
        return sharedAccessGroupValet(with: identifier, accessibility: accessibility)
    }
    
    /// - parameter identifier: A non-empty string that must correspond with the value for keychain-access-groups in your Entitlements file.
    /// - parameter accessibility: The desired accessibility for the Valet.
    /// - returns: A Valet that reads/writes iCloud-shared keychain elements that can be shared across applications written by the same development team.
    @available(swift, obsoleted: 1.0)
    @objc(iCloudValetWithSharedAccessGroupIdentifier:accessibility:)
    public class func 🚫swift_iCloudSharedAccessGroupValet(with identifier: String, accessibility: CloudAccessibility) -> Valet? {
        guard let identifier = Identifier(nonEmpty: identifier) else {
            return nil
        }
        return iCloudSharedAccessGroupValet(with: identifier, accessibility: accessibility)
    }

    #if os(macOS)
    /// Creates a Valet with an explicitly set kSecAttrService.
    /// See https://github.com/square/Valet/issues/140 for more information.
    /// - parameter identifier: A non-empty string that uniquely identifies a Valet. Must be unique relative to other Valet identifiers.
    /// - parameter accessibility: The desired accessibility for the Valet.
    /// - returns: A Valet that reads/writes keychain elements with the desired accessibility and identifier.
    @available(swift, obsoleted: 1.0)
    @objc(valetWithExplicitlySetIdentifier:accessibility:)
    public class func 🚫swift_valet(withExplicitlySet identifier: String, accessibility: Accessibility) -> Valet? {
        guard let identifier = Identifier(nonEmpty: identifier) else {
            return nil
        }
        return findOrCreate(explicitlySet: identifier, configuration: .valet(accessibility))
    }

    /// Creates an iCloud Valet with an explicitly set kSecAttrService.
    /// See https://github.com/square/Valet/issues/140 for more information.
    /// - parameter identifier: A non-empty string that uniquely identifies a Valet. Must be unique relative to other Valet identifiers.
    /// - parameter accessibility: The desired accessibility for the Valet.
    /// - returns: A Valet (synchronized with iCloud) that reads/writes keychain elements with the desired accessibility and identifier.
    @available(swift, obsoleted: 1.0)
    @objc(iCloudValetWithExplicitlySetIdentifier:accessibility:)
    public class func 🚫swift_iCloudValet(withExplicitlySet identifier: String, accessibility: CloudAccessibility) -> Valet? {
        guard let identifier = Identifier(nonEmpty: identifier) else {
            return nil
        }
        return findOrCreate(explicitlySet: identifier, configuration: .iCloud(accessibility))
    }

    /// Creates a shared-access-group Valet with an explicitly set kSecAttrService.
    /// See https://github.com/square/Valet/issues/140 for more information.
    /// - parameter identifier: A non-empty string that must correspond with the value for keychain-access-groups in your Entitlements file. Must be unique relative to other Valet identifiers.
    /// - parameter accessibility: The desired accessibility for the Valet.
    /// - returns: A Valet that reads/writes keychain elements that can be shared across applications written by the same development team.
    @available(swift, obsoleted: 1.0)
    @objc(valetWithExplicitlySetSharedAccessGroupIdentifier:accessibility:)
    public class func 🚫swift_sharedAccessGroupValet(withExplicitlySet identifier: String, accessibility: Accessibility) -> Valet? {
        guard let identifier = Identifier(nonEmpty: identifier) else {
            return nil
        }
        return findOrCreate(explicitlySet: identifier, configuration: .valet(accessibility), sharedAccessGroup: true)
    }

    /// Creates an iCloud-shared-access-group Valet with an explicitly set kSecAttrService.
    /// See https://github.com/square/Valet/issues/140 for more information.
    /// - parameter identifier: A non-empty string that must correspond with the value for keychain-access-groups in your Entitlements file. Must be unique relative to other Valet identifiers.
    /// - parameter accessibility: The desired accessibility for the Valet.
    /// - returns: A Valet (synchronized with iCloud) that reads/writes keychain elements that can be shared across applications written by the same development team.
    @available(swift, obsoleted: 1.0)
    @objc(iCloudValetWithExplicitlySetSharedAccessGroupIdentifier:accessibility:)
    public class func 🚫swift_iCloudSharedAccessGroupValet(withExplicitlySet identifier: String, accessibility: CloudAccessibility) -> Valet? {
        guard let identifier = Identifier(nonEmpty: identifier) else {
            return nil
        }
        return findOrCreate(explicitlySet: identifier, configuration: .iCloud(accessibility), sharedAccessGroup: true)
    }
    #endif
    
}

// MARK: - Testing

internal extension Valet {

    // MARK: Permutations

    class func permutations(with identifier: Identifier, shared: Bool = false) -> [Valet] {
        return Accessibility.allValues().map { accessibility in
            let valet: Valet = shared ? .sharedAccessGroupValet(with: identifier, accessibility: accessibility) : .valet(with: identifier, accessibility: accessibility)
            return valet
        }
    }

    class func iCloudPermutations(with identifier: Identifier, shared: Bool = false) -> [Valet] {
        return CloudAccessibility.allValues().map { cloudAccessibility in
            let valet: Valet = shared ? .iCloudSharedAccessGroupValet(with: identifier, accessibility: cloudAccessibility) : .iCloudValet(with: identifier, accessibility: cloudAccessibility)
            return valet
        }
    }

    #if os(macOS)
    class func permutations(withExplictlySet identifier: Identifier, shared: Bool = false) -> [Valet] {
        return Accessibility.allValues().map { accessibility in
            let valet: Valet = shared ? .sharedAccessGroupValet(withExplicitlySet: identifier, accessibility: accessibility) : .valet(withExplicitlySet: identifier, accessibility: accessibility)
            return valet
        }
    }

    class func iCloudPermutations(withExplictlySet identifier: Identifier, shared: Bool = false) -> [Valet] {
        return CloudAccessibility.allValues().map { cloudAccessibility in
            let valet: Valet = shared ? .iCloudSharedAccessGroupValet(withExplicitlySet: identifier, accessibility: cloudAccessibility) : .iCloudValet(withExplicitlySet: identifier, accessibility: cloudAccessibility)
            return valet
        }
    }
    #endif

}
