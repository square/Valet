//
//  Keychain.swift
//  Valet
//
//  Created by Dan Federman and Eric Muller on 9/16/17.
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


internal final class Keychain {
    
    // MARK: Private Static Properties
    
    private static let canaryKey = "VAL_KeychainCanaryUsername"
    private static let canaryValue = "VAL_KeychainCanaryPassword"
    
    // MARK: Keychain Accessibility
    
    internal static func canAccess(attributes: [String : AnyHashable]) -> Bool {
        func isCanaryValueInKeychain() -> Bool {
            if case let .success(retrievedCanaryValue) = string(forKey: canaryKey, options: attributes),
                retrievedCanaryValue == canaryValue {
                return true
                
            } else {
                return false
            }
        }
        
        if isCanaryValueInKeychain() {
            return true
            
        } else {
            var secItemQuery = attributes
            secItemQuery[kSecAttrAccount as String] = canaryKey
            secItemQuery[kSecValueData as String] = Data(canaryValue.utf8)
            _ = SecItem.add(attributes: secItemQuery)
            
            return isCanaryValueInKeychain()
        }
    }
    
    // MARK: Getters
    
    internal static func string(forKey key: String, options: [String : AnyHashable]) -> SecItem.DataResult<String> {
        switch object(forKey: key, options: options) {
        case let .success(data):
            if let string = String(data: data, encoding: .utf8) {
                return SecItem.DataResult.success(string)
            } else {
                return SecItem.DataResult.error(errSecItemNotFound)
            }
        case let .error(status):
            return SecItem.DataResult.error(status)
        }
    }
    
    internal static func object(forKey key: String, options: [String : AnyHashable]) -> SecItem.DataResult<Data> {
        guard !key.isEmpty else {
            ErrorHandler.assertionFailure("Can not set a value with an empty key.")
            return SecItem.DataResult.error(errSecParam)
        }
        
        var secItemQuery = options
        secItemQuery[kSecAttrAccount as String] = key
        secItemQuery[kSecMatchLimit as String] = kSecMatchLimitOne
        secItemQuery[kSecReturnData as String] = true
        
        return SecItem.copy(matching: secItemQuery)
    }
    
    // MARK: Setters
    
    internal static func set(string: String, forKey key: String, options: [String: AnyHashable]) -> SecItem.Result {
        let data = Data(string.utf8)
        guard !data.isEmpty else {
            ErrorHandler.assertionFailure("Can not set an empty value.")
            return .error(errSecParam)
        }
        
        return set(object: data, forKey: key, options: options)
    }
    
    internal static func set(object: Data, forKey key: String, options: [String: AnyHashable]) -> SecItem.Result {
        guard !key.isEmpty else {
            ErrorHandler.assertionFailure("Can not set a value with an empty key.")
            return .error(errSecParam)
        }
        
        guard !object.isEmpty else {
            ErrorHandler.assertionFailure("Can not set an empty value.")
            return .error(errSecParam)
        }
        
        var secItemQuery = options
        secItemQuery[kSecAttrAccount as String] = key
        
        #if os(macOS)
            // Never update an existing keychain item on OS X, since the existing item could have unauthorized apps in the Access Control List. Fixes zero-day Keychain vuln found here: https://drive.google.com/file/d/0BxxXk1d3yyuZOFlsdkNMSGswSGs/view
            _ = SecItem.deleteItems(matching: secItemQuery)
            secItemQuery[kSecValueData as String] = object
            return SecItem.add(attributes: secItemQuery)
        #else
            
            if case .success = containsObject(forKey: key, options: options) {
                return SecItem.update(attributes: [kSecValueData as String: object], forItemsMatching: secItemQuery)
            } else {
                secItemQuery[kSecValueData as String] = object
                return SecItem.add(attributes: secItemQuery)
            }
        #endif
    }
    
    // MARK: Removal
    
    internal static func removeObject(forKey key: String, options: [String : AnyHashable]) -> SecItem.Result {
        guard !key.isEmpty else {
            ErrorHandler.assertionFailure("Can not set a value with an empty key.")
            return .error(errSecParam)
        }
        
        var secItemQuery = options
        secItemQuery[kSecAttrAccount as String] = key
        
        switch SecItem.deleteItems(matching: secItemQuery) {
        case .success:
            return .success
            
        case let .error(status):
            switch status {
            case errSecInteractionNotAllowed, errSecMissingEntitlement:
                return .error(status)
                
            default:
                // We succeeded as long as we can confirm that the item is not in the keychain.
                return .success
            }
        }
    }
    
    internal static func removeAllObjects(matching options: [String : AnyHashable]) -> SecItem.Result {
        switch SecItem.deleteItems(matching: options) {
        case .success:
            return .success
            
        case let .error(status):
            switch status {
            case errSecInteractionNotAllowed, errSecMissingEntitlement:
                return .error(status)
                
            default:
                // We succeeded as long as we can confirm that the item is not in the keychain.
                return .success
            }
        }
    }
    
    // MARK: Contains
    
    internal static func containsObject(forKey key: String, options: [String : AnyHashable]) -> SecItem.Result {
        guard !key.isEmpty else {
            ErrorHandler.assertionFailure("Can not set a value with an empty key.")
            return .error(errSecParam)
        }
        
        var secItemQuery = options
        secItemQuery[kSecAttrAccount as String] = key
        
        switch SecItem.containsObject(matching: secItemQuery) {
        case .success:
            return .success
            
        case let .error(status):
            return .error(status)
        }
    }
    
    // MARK: AllObjects
    
    internal static func allKeys(options: [String: AnyHashable]) -> SecItem.DataResult<Set<String>> {
        var secItemQuery = options
        secItemQuery[kSecMatchLimit as String] = kSecMatchLimitAll
        secItemQuery[kSecReturnAttributes as String] = true
        
        let result: SecItem.DataResult<Any> = SecItem.copy(matching: secItemQuery)
        switch result {
        case let .success(collection):
            if let singleMatch = collection as? [String : AnyHashable], let singleKey = singleMatch[kSecAttrAccount as String] as? String, singleKey != canaryKey {
                return SecItem.DataResult.success(Set([singleKey]))
                
            } else if let multipleMatches = collection as? [[String: AnyHashable]] {
                return SecItem.DataResult.success(Set(multipleMatches.compactMap({ attributes in
                    let key = attributes[kSecAttrAccount as String] as? String
                    return key != canaryKey ? key : nil
                })))

            } else {
                return SecItem.DataResult.success(Set())
            }
            
        case let .error(status):
            return SecItem.DataResult.error(status)
        }
    }
    
    // MARK: Migration
    
    internal static func migrateObjects(matching query: [String : AnyHashable], into destinationAttributes: [String : AnyHashable], removeOnCompletion: Bool) -> MigrationResult {
        guard query.count > 0 else {
            ErrorHandler.assertionFailure("Migration requires secItemQuery to contain values.")
            return .invalidQuery
        }
        
        guard query[kSecMatchLimit as String] as? String as CFString? != kSecMatchLimitOne else {
            ErrorHandler.assertionFailure("Migration requires kSecMatchLimit to be set to kSecMatchLimitAll.")
            return .invalidQuery
        }
        
        guard query[kSecReturnData as String] as? Bool != true else {
            ErrorHandler.assertionFailure("kSecReturnData is not supported in a migration query.")
            return .invalidQuery
        }
        
        guard query[kSecReturnAttributes as String] as? Bool != false else {
            ErrorHandler.assertionFailure("Migration requires kSecReturnAttributes to be set to kCFBooleanTrue.")
            return .invalidQuery
        }
        
        guard query[kSecReturnRef as String] as? Bool != true else {
            ErrorHandler.assertionFailure("kSecReturnRef is not supported in a migration query.")
            return .invalidQuery
        }
        
        guard query[kSecReturnPersistentRef as String] as? Bool != false else {
            ErrorHandler.assertionFailure("Migration requires kSecReturnPersistentRef to be set to kCFBooleanTrue.")
            return .invalidQuery
        }
        
        guard query[kSecClass as String] as? String as CFString? == kSecClassGenericPassword else {
            ErrorHandler.assertionFailure("Migration requires kSecClass to be set to kSecClassGenericPassword to avoid data loss.")
            return .invalidQuery
        }
        
        guard query[kSecAttrAccessControl as String] == nil else {
            ErrorHandler.assertionFailure("kSecAttrAccessControl is not supported in a migration query. Keychain items can not be migrated en masse from the Secure Enclave.")
            return .invalidQuery
        }
        
        var secItemQuery = query
        secItemQuery[kSecMatchLimit as String] = kSecMatchLimitAll
        secItemQuery[kSecReturnAttributes as String] = true
        secItemQuery[kSecReturnData as String] = false
        secItemQuery[kSecReturnRef as String] = false
        secItemQuery[kSecReturnPersistentRef as String] = true
        
        let result: SecItem.DataResult<Any> = SecItem.copy(matching: secItemQuery)
        let retrievedItemsToMigrate: [[String: AnyHashable]]
        switch result {
        case let .success(collection):
            if let singleMatch = collection as? [String : AnyHashable] {
                retrievedItemsToMigrate = [singleMatch]
                
            } else if let multipleMatches = collection as? [[String: AnyHashable]] {
                retrievedItemsToMigrate = multipleMatches
                
            } else {
                return .dataInQueryResultInvalid
            }
            
        case let .error(status):
            switch status {
            case errSecItemNotFound:
                return .noItemsToMigrateFound
                
            case errSecParam:
                return .invalidQuery
                
            default:
                return .couldNotReadKeychain
            }
        }
        
        // Now that we have the persistent refs with attributes, get the data associated with each keychain entry.
        var retrievedItemsToMigrateWithData = [[String : AnyHashable]]()
        for retrievedItem in retrievedItemsToMigrate {
            guard let retrievedPersistentRef = retrievedItem[kSecValuePersistentRef as String] else {
                return .couldNotReadKeychain
            }
            
            let retrieveDataQuery: [String : AnyHashable] = [
                kSecValuePersistentRef as String : retrievedPersistentRef,
                kSecReturnData as String : true
            ]
            
            let retrievedData: SecItem.DataResult<Data> = SecItem.copy(matching: retrieveDataQuery)
            switch retrievedData {
            case let .success(data):
                guard !data.isEmpty else {
                    return .dataInQueryResultInvalid
                }
                
                var retrievedItemToMigrateWithData = retrievedItem
                retrievedItemToMigrateWithData[kSecValueData as String] = data
                retrievedItemsToMigrateWithData.append(retrievedItemToMigrateWithData)
                
            case let .error(status):
                if status == errSecItemNotFound {
                    // It is possible for metadata-only items to exist in the keychain that do not have data associated with them. Ignore this entry.
                    continue
                    
                } else {
                    return .couldNotReadKeychain
                }
            }
        }
        
        // Sanity check that we are capable of migrating the data.
        var keysToMigrate = Set<String>()
        for keychainEntry in retrievedItemsToMigrateWithData {
            guard let key = keychainEntry[kSecAttrAccount as String] as? String, key != Keychain.canaryKey else {
                // We don't care about this key. Move along.
                continue
            }
            
            guard !key.isEmpty else {
                return .keyInQueryResultInvalid
            }
            
            guard !keysToMigrate.contains(key) else {
                return .duplicateKeyInQueryResult
            }
            
            guard let data = keychainEntry[kSecValueData as String] as? Data, !data.isEmpty else {
                return .dataInQueryResultInvalid
            }
            
            guard case let .error(status) = Keychain.containsObject(forKey: key, options: destinationAttributes), status == errSecItemNotFound else {
                return .keyInQueryResultAlreadyExistsInValet
            }
            
            keysToMigrate.insert(key)
        }
        
        // All looks good. Time to actually migrate.
        var alreadyMigratedKeys = [String]()
        func revertMigration() {
            // Something has gone wrong. Remove all migrated items.
            for alreadyMigratedKey in alreadyMigratedKeys {
                _ = Keychain.removeObject(forKey: alreadyMigratedKey, options: destinationAttributes)
            }
        }
        
        for keychainEntry in retrievedItemsToMigrateWithData {
            guard let key = keychainEntry[kSecAttrAccount as String] as? String else {
                revertMigration()
                return .keyInQueryResultInvalid
            }

            guard let value = keychainEntry[kSecValueData as String] as? Data else {
                revertMigration()
                return .dataInQueryResultInvalid
            }
            
            switch Keychain.set(object: value, forKey: key, options: destinationAttributes) {
            case .success:
                alreadyMigratedKeys.append(key)
                
            case .error:
                revertMigration()
                return .couldNotWriteToKeychain
            }
        }
        
        // Remove data if requested.
        if removeOnCompletion {
            guard Keychain.removeAllObjects(matching: query).didSucceed else {
                revertMigration()
                return .removalFailed
            }

            // We're done!
        }
        
        return .success
    }
}
