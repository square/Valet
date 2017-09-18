//
//  Valet.swift
//  Valet
//
//  Created by Dan Federman and Eric Muller on 9/17/17.
//  Copyright © 2017 Square, Inc.
//
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


public final class Valet: NSObject, KeychainQueryConvertible {

    // MARK: Public Class Methods
    
    public class func valet(with identifier: Identifier, accessibility: Accessibility) -> Valet {
        let key = Service.standard(identifier, accessibility, .vanilla).description as NSString
        if let existingValet = identifierToValetMap.object(forKey: key) {
            return existingValet
            
        } else {
            let valet = Valet(identifier: identifier, accessibility: accessibility)
            identifierToValetMap.setObject(valet, forKey: key)
            return valet
        }
    }
    
    public class func sharedAccessGroupValet(with identifier: Identifier, accessibility: Accessibility) -> Valet {
        let key = Service.sharedAccessGroup(identifier, accessibility, .vanilla).description as NSString
        if let existingValet = identifierToValetMap.object(forKey: key) {
            return existingValet
            
        } else {
            let valet = Valet(sharedAccess: identifier, accessibility: accessibility)
            identifierToValetMap.setObject(valet, forKey: key)
            return valet
        }
    }
    
    // MARK: Equatable
    
    public static func ==(lhs: Valet, rhs: Valet) -> Bool {
        return lhs.service == rhs.service
    }
    
    // MARK: Private Class Properties
    
    private static let identifierToValetMap = NSMapTable<NSString, Valet>.strongToWeakObjects()
    
    // MARK: Initialization
    
    private init(identifier: Identifier, accessibility: Accessibility) {
        service = .standard(identifier, accessibility, .vanilla)
        keychainQuery = service.baseQuery
        self.accessibility = accessibility
        self.identifier = identifier
    }
    
    private init(sharedAccess identifier: Identifier, accessibility: Accessibility) {
        service = .sharedAccessGroup(identifier, accessibility, .vanilla)
        keychainQuery = service.baseQuery
        self.accessibility = accessibility
        self.identifier = identifier
    }
    
    // MARK: KeychainQueryConvertible
    
    public let keychainQuery: [String : AnyHashable]
    
    // MARK: Hashable
    
    public override var hashValue: Int {
        return service.description.hashValue
    }
    
    // MARK: Public Properties
    
    public let accessibility: Accessibility
    public let identifier: Identifier
    
    // MARK: Public Methods
    
    public func canAccessKeychain() -> Bool {
        return execute(in: lock) {
            return Keychain.canAccess(attributes: keychainQuery)
        }
    }

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
    
    public func migrateObjects(matching query: [String : AnyHashable], removeOnCompletion: Bool) -> MigrationResult {
        return execute(in: lock) {
            return Keychain.migrateObjects(matching: query, into: keychainQuery, removeOnCompletion: removeOnCompletion)
        }
    }
    
    public func migrateObjects(from keychain: KeychainQueryConvertible, removeOnCompletion: Bool) -> MigrationResult {
        return migrateObjects(matching: keychain.keychainQuery, removeOnCompletion: removeOnCompletion)
    }
    
    // MARK: Private Properties
    
    private let service: Service
    private let lock = NSLock()
}
