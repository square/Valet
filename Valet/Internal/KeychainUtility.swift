//
//  KeychainUtility.swift
//  Valet
//
//  Created by Dan Federman and Eric Muller on 9/16/17.
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

// MARK: Getters

internal func string(forKey key: String, options: [String : AnyHashable]) -> SecItem.Result<String, OSStatus> {
    switch object(forKey: key, options: options) {
    case let .success(data):
        if let string = String(data: data, encoding: .utf8) {
            return SecItem.Result.success(string)
        } else {
            return SecItem.Result.error(errSecItemNotFound)
        }
    case let .error(status):
        return SecItem.Result.error(status)
    }
}

internal func object(forKey key: String, options: [String : AnyHashable]) -> SecItem.Result<Data, OSStatus> {
    guard !key.isEmpty else {
        ErrorHandler.assertionFailure("Can not set a value with an empty key.")
        return SecItem.Result.error(errSecParam)
    }
    
    var secItemQuery = options
    secItemQuery[kSecAttrAccount as String] = key
    secItemQuery[kSecMatchLimit as String] = kSecMatchLimitOne
    secItemQuery[kSecReturnData as String] = true
    
    return SecItem.copy(matching: secItemQuery)
}

// MARK: Setters

internal func set(string: String, forKey key: String, options: [String: AnyHashable]) -> SecItem.Result<Void?, OSStatus> {
    guard let data = string.data(using: .utf8), !data.isEmpty else {
        ErrorHandler.assertionFailure("Can not set an empty value.")
        return SecItem.Result.error(errSecParam)
    }
    
    return Valet.set(object: data, forKey: key, options: options)
}

internal func set(object: Data, forKey key: String, options: [String: AnyHashable]) -> SecItem.Result<Void?, OSStatus> {
    guard !key.isEmpty else {
        ErrorHandler.assertionFailure("Can not set a value with an empty key.")
        return SecItem.Result.error(errSecParam)
    }
    
    guard !object.isEmpty else {
        ErrorHandler.assertionFailure("Can not set an empty value.")
        return SecItem.Result.error(errSecParam)
    }
    
    var secItemQuery = options
    secItemQuery[kSecAttrAccount as String] = key

    
    #if os(macOS)
        // Never update an existing keychain item on OS X, since the existing item could have unauthorized apps in the Access Control List. Fixes zero-day Keychain vuln found here: https://drive.google.com/file/d/0BxxXk1d3yyuZOFlsdkNMSGswSGs/view
        _ = SecItem.delete(itemsMatching: secItemQuery)
        secItemQuery[kSecValueData as String] = object
        return SecItem.add(attributes: secItemQuery)
    #else
        
        if case .success = Valet.containsObject(forKey: key, options: options) {
            return SecItem.update(attributes: [kSecValueData as String: object], forItemsMatching: secItemQuery)
        } else {
            secItemQuery[kSecValueData as String] = object
            return SecItem.add(attributes: secItemQuery)
        }
    #endif
}

// MARK: Removal

internal func removeObject(forKey key: String, options: [String : AnyHashable]) -> SecItem.Result<Void?, OSStatus> {
    guard !key.isEmpty else {
        ErrorHandler.assertionFailure("Can not set a value with an empty key.")
        return SecItem.Result.error(errSecParam)
    }
    
    var secItemQuery = options
    secItemQuery[kSecAttrAccount as String] = key
    
    switch SecItem.delete(itemsMatching: secItemQuery) {
    case .success:
        return SecItem.Result.success(())
        
    case let .error(status):
        switch status {
        case errSecInteractionNotAllowed, errSecMissingEntitlement:
            return SecItem.Result.error(status)
            
        default:
            // We succeeded as long as we can confirm that the item is not in the keychain.
            return SecItem.Result.success(())
        }
    }
}

internal func removeAllObjects(matching options: [String : AnyHashable]) -> SecItem.Result<Void, OSStatus> {
    return SecItem.delete(itemsMatching: options)
}

// MARK: Contains

internal func containsObject(forKey key: String, options: [String : AnyHashable]) -> SecItem.Result<Void?, OSStatus> {
    guard !key.isEmpty else {
        ErrorHandler.assertionFailure("Can not set a value with an empty key.")
        return SecItem.Result.error(errSecParam)
    }
    
    var secItemQuery = options
    secItemQuery[kSecAttrAccount as String] = key
    
    return SecItem.copy(matching: secItemQuery)
}

// MARK: AllObjects

internal func allKeys(options: [String: AnyHashable]) -> SecItem.Result<Set<String>, OSStatus> {
    var secItemQuery = options
    secItemQuery[kSecMatchLimit as String] = kSecMatchLimitAll
    secItemQuery[kSecReturnAttributes as String] = true
    
    let result: SecItem.Result<Any, OSStatus> = SecItem.copy(matching: secItemQuery)
    switch result {
    case let .success(collection):
        if let singleMatch = collection as? [String : AnyHashable], let singleKey = singleMatch[kSecAttrAccount as String] as? String {
            return SecItem.Result.success(Set([singleKey]))
            
        } else if let multipleMatches = collection as? [[String: AnyHashable]] {
            return SecItem.Result.success(Set(multipleMatches.flatMap({ attributes in
                return attributes[kSecAttrAccount as String] as? String
            })))
            
        } else {
            return SecItem.Result.success(Set())
        }
        
    case let .error(status):
        return SecItem.Result.error(status)
    }
}


// TODO: The remaining *:options: methods in the VALValet_Protected header should be implemented statically here as we did above.
