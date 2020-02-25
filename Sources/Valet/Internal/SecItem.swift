//
//  SecItem.swift
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


internal func execute<ReturnType>(in lock: NSLock, block: () throws -> ReturnType) rethrows -> ReturnType {
    lock.lock()
    defer {
        lock.unlock()
    }
    return try block()
}


internal final class SecItem {
        
    // MARK: Internal Class Methods
    
    internal static func copy<DesiredType>(matching query: [String : AnyHashable]) throws -> DesiredType {
        if query.isEmpty {
            assertionFailure("Must provide a query with at least one item")
        }
        
        var status = errSecNotAvailable
        var result: AnyObject? = nil
        execute(in: secItemLock) {
            status = SecItemCopyMatching(query as CFDictionary, &result)
        }
        
        if status == errSecSuccess {
            if let result = result as? DesiredType {
                return result
                
            } else {
                // The query failed to pull out a value object of the desired type, but did find metadata matching this query.
                // This can happen because either the query didn't ask for return data via [kSecReturnData : true], or because a metadata-only item existed in the keychain.
                throw KeychainError.itemNotFound
            }
            
        } else {
            throw KeychainError(status: status)
        }
    }
    
    internal static func performCopy(matching query: [String : AnyHashable]) -> OSStatus {
        guard !query.isEmpty else {
            // Must provide a query with at least one item
            return errSecParam
        }
        
        var status = errSecNotAvailable
        execute(in: secItemLock) {
            status = SecItemCopyMatching(query as CFDictionary, nil)
        }

        return status
    }
    
    internal static func add(attributes: [String : AnyHashable]) throws {
        if attributes.isEmpty {
            assertionFailure("Must provide attributes with at least one item")
        }
        
        var status = errSecNotAvailable
        var result: AnyObject? = nil
        execute(in: secItemLock) {
            status = SecItemAdd(attributes as CFDictionary, &result)
        }
        
        switch status {
        case errSecSuccess:
            // We're done!
            break
        default:
            throw KeychainError(status: status)
        }
    }
    
    internal static func update(attributes: [String : AnyHashable], forItemsMatching query: [String : AnyHashable]) throws {
        if attributes.isEmpty {
            assertionFailure("Must provide attributes with at least one item")
        }
        
        if query.isEmpty {
            assertionFailure("Must provide a query with at least one item")
        }
        
        var status = errSecNotAvailable
        execute(in: secItemLock) {
            status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        }
        
        switch status {
        case errSecSuccess:
            // We're done!
            break
        default:
            throw KeychainError(status: status)
        }
    }
    
    internal static func deleteItems(matching query: [String : AnyHashable]) throws {
        if query.isEmpty {
            assertionFailure("Must provide a query with at least one item")
        }
        
        var secItemQuery = query
        #if os(macOS)
            // This line must exist on OS X, but must not exist on iOS.
            secItemQuery[kSecMatchLimit as String] = kSecMatchLimitAll
        #endif
        var status = errSecNotAvailable
        execute(in: secItemLock) {
            status = SecItemDelete(secItemQuery as CFDictionary)
        }
        
        if status == errSecSuccess {
            // We're done!
            
        } else {
            switch KeychainError(status: status) {
            case .couldNotAccessKeychain:
                throw KeychainError.couldNotAccessKeychain

            case .missingEntitlement:
                throw KeychainError.missingEntitlement

            case .emptyKey,
                 .emptyValue,
                 .itemNotFound,
                 .userCancelled:
                // We succeeded as long as we can confirm that the item is not in the keychain.
                break
            }
        }
    }
    
    // MARK: Private Properties
    
    private static let secItemLock = NSLock()
}
