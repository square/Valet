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
public final class Valet: NSObject, KeychainQueryConvertible {
    
    // MARK: Flavor
    
    public enum Flavor: Equatable {
        /// Reads and writes keychain elements that do not sync to other devices.
        case vanilla(Accessibility)
        /// Reads and writes keychain elements that are synchronized with iCloud.
        case iCloud(CloudAccessibility)
        
        // MARK: Equatable
        
        public static func ==(lhs: Flavor, rhs: Flavor) -> Bool {
            switch lhs {
            case let .vanilla(lhsAccessibility):
                if case let .vanilla(rhsAccessibility) = rhs, lhsAccessibility == rhsAccessibility {
                    return true
                } else {
                    return false
                }
            case let .iCloud(lhsAccessibility):
                if case let .iCloud(rhsAccessibility) = rhs, lhsAccessibility == rhsAccessibility {
                    return true
                } else {
                    return false
                }
            }
        }
    }
    
    // MARK: Public Class Methods
    
    /// - parameter identifier: A non-empty string that uniquely identifies a Valet.
    /// - parameter flavor: A description of the Valet's capabilities.
    /// - returns: A Valet that reads/writes keychain elements with the desired flavor.
    public class func valet(with identifier: Identifier, flavor: Flavor) -> Valet {
        let key = Service.standard(identifier, .valet(flavor)).description as NSString
        if let existingValet = identifierToValetMap.object(forKey: key) {
            return existingValet
            
        } else {
            let valet = Valet(identifier: identifier, flavor: flavor)
            identifierToValetMap.setObject(valet, forKey: key)
            return valet
        }
    }

    /// - parameter identifier: A non-empty string that must correspond with the value for keychain-access-groups in your Entitlements file.
    /// - parameter flavor: A description of the Valet's capabilities.
    /// - returns: A Valet that reads/writes keychain elements that can be shared across applications written by the same development team.
    public class func sharedAccessGroupValet(with identifier: Identifier, flavor: Flavor) -> Valet {
        let key = Service.sharedAccessGroup(identifier, .valet(flavor)).description as NSString
        if let existingValet = identifierToValetMap.object(forKey: key) {
            return existingValet
            
        } else {
            let valet = Valet(sharedAccess: identifier, flavor: flavor)
            identifierToValetMap.setObject(valet, forKey: key)
            return valet
        }
    }
    
    // MARK: Equatable
    
    /// - returns: `true` if lhs and rhs both read from and write to the same sandbox within the keychain.
    public static func ==(lhs: Valet, rhs: Valet) -> Bool {
        return lhs.service == rhs.service
    }
    
    // MARK: Private Class Properties
    
    private static let identifierToValetMap = NSMapTable<NSString, Valet>.strongToWeakObjects()
    
    // MARK: Initialization
    
    @available(*, deprecated)
    public override init() {
        fatalError("Do not use this initializer")
    }
    
    private init(identifier: Identifier, flavor: Flavor) {
        self.identifier = identifier
        
        switch flavor {
        case let .vanilla(accessibility):
            service = .standard(identifier, .valet(flavor))
            self.accessibility = accessibility
            self.flavor = flavor
        case let .iCloud(synchronizableAccessibility):
            service = .standard(identifier, .valet(flavor))
            accessibility = synchronizableAccessibility.accessibility
            self.flavor = flavor
        }
        
        keychainQuery = service.generateBaseQuery()
    }
    
    private init(sharedAccess identifier: Identifier, flavor: Flavor) {
        self.identifier = identifier
        
        switch flavor {
        case let .vanilla(accessibility):
            service = .sharedAccessGroup(identifier, .valet(flavor))
            self.accessibility = accessibility
            self.flavor = flavor
            
        case let .iCloud(synchronizableAccessibility):
            service = .sharedAccessGroup(identifier, .valet(flavor))
            accessibility = synchronizableAccessibility.accessibility
            self.flavor = flavor
        }
        
        keychainQuery = service.generateBaseQuery()
    }
    
    // MARK: KeychainQueryConvertible
    
    public let keychainQuery: [String : AnyHashable]
    
    // MARK: Hashable
    
    public override var hashValue: Int {
        return service.description.hashValue
    }
    
    // MARK: Public Properties
    
    @objc
    public let accessibility: Accessibility
    public let identifier: Identifier
    public let flavor: Flavor
    
    // MARK: Public Methods
    
    /// - returns: `true` if the keychain is accessible for reading and writing, `false` otherwise.
    /// - note: Determined by writing a value to the keychain and then reading it back out.
    @objc
    public func canAccessKeychain() -> Bool {
        return execute(in: lock) {
            return Keychain.canAccess(attributes: keychainQuery)
        }
    }
    
    /// - parameter object: A Data value to be inserted into the keychain.
    /// - parameter key: A Key that can be used to retrieve the `object` from the keychain.
    /// - returns: `false` if the keychain is not accessible.
    @objc(setObject:forKey:)
    @discardableResult
    public func set(object: Data, for key: Key) -> Bool {
        return execute(in: lock) {
            switch Keychain.set(object: object, for: key, options: keychainQuery) {
            case .success:
                return true
                
            case .error:
                return false
            }
        }
    }
    
    /// - parameter key: A Key used to retrieve the desired object from the keychain.
    /// - returns: The data currently stored in the keychain for the provided key. Returns `nil` if no object exists in the keychain for the specified key, or if the keychain is inaccessible.
    @objc(objectForKey:)
    public func object(for key: Key) -> Data? {
        return execute(in: lock) {
            switch Keychain.object(for: key, options: keychainQuery) {
            case let .success(data):
                return data
                
            case .error:
                return nil
            }
        }
    }
    
    /// - parameter key: The key to look up in the keychain.
    /// - returns: `true` if a value has been set for the given key, `false` otherwise.
    @objc(containsObjectForKey:)
    public func containsObject(for key: Key) -> Bool {
        return execute(in: lock) {
            switch Keychain.containsObject(for: key, options: keychainQuery) {
            case .success:
                return true
            case .error:
                return false
            }
        }
    }
    
    /// - parameter string: A String value to be inserted into the keychain.
    /// - parameter key: A Key that can be used to retrieve the `string` from the keychain.
    /// @return NO if the keychain is not accessible.
    @objc(setString:forKey:)
    @discardableResult
    public func set(string: String, for key: Key) -> Bool {
        return execute(in: lock) {
            switch Keychain.set(string: string, for: key, options: keychainQuery) {
            case .success:
                return true
                
            case .error:
                return false
            }
        }
    }
    
    /// - parameter key: A Key used to retrieve the desired object from the keychain.
    /// - returns: The string currently stored in the keychain for the provided key. Returns `nil` if no string exists in the keychain for the specified key, or if the keychain is inaccessible.
    @objc(stringforKey:)
    public func string(for key: Key) -> String? {
        return execute(in: lock) {
            switch Keychain.string(for: key, options: keychainQuery) {
            case let .success(data):
                return data
                
            case .error:
                return nil
            }
        }
    }
    
    /// - returns: The set of all (String) keys currently stored in this Valet instance.
    @objc
    public func allKeys() -> Set<String> {
        return execute(in: lock) {
            switch Keychain.allKeys(options: keychainQuery) {
            case let .success(allKeys):
                return allKeys
                
            case .error:
                return Set()
            }
        }
    }
    
    /// Removes a key/object pair from the keychain.
    /// - returns: `false` if the keychain is not accessible.
    @objc(removeObjectForKey:)
    @discardableResult
    public func removeObject(for key: Key) -> Bool {
        return execute(in: lock) {
            switch Keychain.removeObject(for: key, options: keychainQuery) {
            case .success:
                return true
                
            case .error:
                return false
            }
        }
    }
    
    /// Removes all key/object pairs accessible by this Valet instance from the keychain.
    /// - returns: `false` if the keychain is not accessible.
    @objc
    @discardableResult
    public func removeAllObjects() -> Bool {
        return execute(in: lock) {
            switch Keychain.removeAllObjects(matching: keychainQuery) {
            case .success:
                return true
                
            case .error:
                return false
            }
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
            return Keychain.migrateObjects(matching: query, into: keychainQuery, removeOnCompletion: removeOnCompletion)
        }
    }
    
    /// Migrates objects matching the vended keychain query into the receiving Valet instance.
    /// - parameter keychain: An objects whose vended keychain query is used to retrieve existing keychain data via a call to SecItemCopyMatching.
    /// - parameter removeOnCompletion: If `true`, the migrated data will be removed from the keychfain if the migration succeeds.
    /// - returns: Whether the migration succeeded or failed.
    /// - note: The keychain is not modified if a failure occurs.
    @objc(migrateObjectsFromKeychain:removeOnCompletion:)
    public func migrateObjects(from keychain: KeychainQueryConvertible, removeOnCompletion: Bool) -> MigrationResult {
        return migrateObjects(matching: keychain.keychainQuery, removeOnCompletion: removeOnCompletion)
    }
    
    // MARK: Private Properties
    
    private let service: Service
    private let lock = NSLock()
}


// MARK: - Objective-C Compatibility

extension Valet {

    // MARK: Public Class Methods
    
    /// - parameter identifier: A non-empty string that uniquely identifies a Valet.
    /// - parameter accessibility: The desired accessibility for the Valet.
    /// - returns: A Valet that reads/writes keychain elements with the desired accessibility.
    @available(swift, obsoleted: 1.0)
    @objc(vanillaValetWithIdentifier:accessibility:)
    public class func notforswift_vanillaValet(with identifier: String, accessibility: Accessibility) -> Valet? {
        guard let identifier = Identifier(nonEmpty: identifier) else {
            return nil
        }
        return valet(with: identifier, flavor: .vanilla(accessibility))
    }
    
    /// - parameter identifier: A non-empty string that uniquely identifies a Valet.
    /// - parameter accessibility: The desired accessibility for the Valet.
    /// - returns: A Valet that reads/writes iCloud-shared keychain elements with the desired accessibility.
    @available(swift, obsoleted: 1.0)
    @objc(iCloudValetWithIdentifier:accessibility:)
    public class func notforswift_iCloudValet(with identifier: String, accessibility: CloudAccessibility) -> Valet? {
        guard let identifier = Identifier(nonEmpty: identifier) else {
            return nil
        }
        return valet(with: identifier, flavor: .iCloud(accessibility))
    }
    
    /// - parameter identifier: A non-empty string that must correspond with the value for keychain-access-groups in your Entitlements file.
    /// - parameter accessibility: The desired accessibility for the Valet.
    /// - returns: A Valet that reads/writes keychain elements that can be shared across applications written by the same development team.
    @available(swift, obsoleted: 1.0)
    @objc(vanillaValetWithSharedAccessGroupIdentifier:accessibility:)
    public class func notforswift_vanillaSharedAccessGroupValet(with identifier: String, accessibility: Accessibility) -> Valet? {
        guard let identifier = Identifier(nonEmpty: identifier) else {
            return nil
        }
        return sharedAccessGroupValet(with: identifier, flavor: .vanilla(accessibility))
    }
    
    /// - parameter identifier: A non-empty string that must correspond with the value for keychain-access-groups in your Entitlements file.
    /// - parameter accessibility: The desired accessibility for the Valet.
    /// - returns: A Valet that reads/writes iCloud-shared keychain elements that can be shared across applications written by the same development team.
    @available(swift, obsoleted: 1.0)
    @objc(iCloudValetWithSharedAccessGroupIdentifier:accessibility:)
    public class func notforswift_iCloudSharedAccessGroupValet(with identifier: String, accessibility: CloudAccessibility) -> Valet? {
        guard let identifier = Identifier(nonEmpty: identifier) else {
            return nil
        }
        return sharedAccessGroupValet(with: identifier, flavor: .iCloud(accessibility))
    }
    
}
