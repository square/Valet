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
    
    // MARK: Internal Class Properties

    /// Programatically grab the required prefix for the shared access group (i.e. Bundle Seed ID). The value for the kSecAttrAccessGroup key in queries for data that is shared between apps must be of the format bundleSeedID.sharedAccessGroup. For more information on the Bundle Seed ID, see https://developer.apple.com/library/ios/qa/qa1713/_index.html
    internal static var sharedAccessGroupPrefix: String? {
        var query: [CFString : Any] = [
            kSecClass : kSecClassGenericPassword,
            kSecAttrAccount : "SharedAccessGroupPrefixPlaceholder",
            kSecReturnAttributes : true,
            kSecAttrAccessible : Accessibility.afterFirstUnlockThisDeviceOnly.secAccessibilityAttribute
        ]

        if #available(iOS 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, *) {
            // Add kSecUseDataProtectionKeychain to the query to ensure we can retrieve the shared access group prefix.
            query[kSecUseDataProtectionKeychain] = true
        }

        secItemLock.lock()
        defer {
            secItemLock.unlock()
        }
        
        var result: AnyObject? = nil
        var status = SecItemCopyMatching(query as CFDictionary, &result)
        
        if status == errSecItemNotFound {
            status = SecItemAdd(query as CFDictionary, &result)
        }
        
        guard status == errSecSuccess, let queryResult = result as? [CFString : AnyHashable], let accessGroup = queryResult[kSecAttrAccessGroup] as? String else {
            // We may not be able to access the shared access group prefix because the accessibility of the above keychain data is set to `afterFirstUnlock`.
            // Consumers should always check `canAccessKeychain()` after creating a Valet and before using it. Doing so will catch this error.
            return nil
        }
        
        let components = accessGroup.components(separatedBy: ".")
        if let bundleSeedIdentifier = components.first, !bundleSeedIdentifier.isEmpty {
            return bundleSeedIdentifier
            
        } else {
            // We may not be able to access the shared access group prefix because the accessibility of the above keychain data is set to `afterFirstUnlock`.
            // Consumers should always check `canAccessKeychain()` after creating a Valet and before using it. Doing so will catch this error.
            return nil
        }
    }
    
    // MARK: Internal Class Methods
    
    internal static func copy<DesiredType>(matching query: [String : AnyHashable]) throws -> DesiredType? {
        if query.isEmpty {
            assertionFailure("Must provide a query with at least one item")
        }
        
        var status = errSecNotAvailable
        var result: AnyObject? = nil
        execute(in: secItemLock) {
            status = SecItemCopyMatching(query as CFDictionary, &result)
        }

        switch status {
        case errSecSuccess:
            if let result = result as? DesiredType {
                return result

            } else {
                // The query failed to pull out a value object of the desired type, but did find metadata matching this query.
                // This can happen because either the query didn't ask for return data via [kSecReturnData : true], or because a metadata-only item existed in the keychain.
                return nil
            }

        case errSecItemNotFound:
            return nil

        default:
            throw KeychainError(status: status)
        }
    }
    
    internal static func containsObject(matching query: [String : AnyHashable]) -> OSStatus {
        guard query.count > 0 else {
            // "Must provide a query with at least one item
            return errSecParam
        }
        
        var status = errSecNotAvailable
        execute(in: secItemLock) {
            status = SecItemCopyMatching(query as CFDictionary, nil)
        }
        assert(status != errSecMissingEntitlement, "A 'Missing Entitlements' error occurred. This is likely due to an Apple Keychain bug. As a workaround try running on a device that is not attached to a debugger.\n\nMore information: https://forums.developer.apple.com/thread/4743")

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

        switch status {
        case errSecSuccess,
             errSecItemNotFound:
            // We're done!
            break

        default:
            switch KeychainError(status: status) {
            case .couldNotAccessKeychain:
                throw KeychainError.couldNotAccessKeychain

            case .missingEntitlement:
                throw KeychainError.missingEntitlement

            default:
                // We succeeded as long as we can confirm that the item is not in the keychain.
                break
            }
        }
    }
    
    // MARK: Private Properties
    
    private static let secItemLock = NSLock()
}
