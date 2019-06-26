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


internal func execute<ReturnType>(in lock: NSLock, block: () -> ReturnType) -> ReturnType {
    lock.lock()
    defer {
        lock.unlock()
    }
    return block()
}


internal final class SecItem {
    
    // MARK: Internal Enum
    
    internal enum DataResult<SuccessType> {
        case success(SuccessType)
        case error(OSStatus)

        var value: SuccessType? {
            switch self {
            case let .success(value):
                return value

            case .error:
                return nil
            }

        }
    }
    
    internal enum Result {
        case success
        case error(OSStatus)

        var didSucceed: Bool {
            switch self {
            case .success:
                return true

            case .error:
                return false
            }

        }
    }
    
    // MARK: Internal Class Properties

    /// Programatically grab the required prefix for the shared access group (i.e. Bundle Seed ID). The value for the kSecAttrAccessGroup key in queries for data that is shared between apps must be of the format bundleSeedID.sharedAccessGroup. For more information on the Bundle Seed ID, see https://developer.apple.com/library/ios/qa/qa1713/_index.html
    internal static var sharedAccessGroupPrefix: String {
        let query = [
            kSecClass : kSecClassGenericPassword,
            kSecAttrAccount : "SharedAccessGroupAlwaysAccessiblePrefixPlaceholder",
            kSecReturnAttributes : true,
            kSecAttrAccessible : Accessibility.alwaysThisDeviceOnly.secAccessibilityAttribute
            ] as CFDictionary
        
        secItemLock.lock()
        defer {
            secItemLock.unlock()
        }
        
        var result: AnyObject? = nil
        var status = SecItemCopyMatching(query, &result)
        
        if status == errSecItemNotFound {
            status = SecItemAdd(query, &result)
        }
        
        guard status == errSecSuccess, let queryResult = result as? [CFString : AnyHashable], let accessGroup = queryResult[kSecAttrAccessGroup] as? String else {
            ErrorHandler.assertionFailure("Could not find shared access group prefix.")
            // We should always be able to access the shared access group prefix because the accessibility of the above keychain data is set to `always`.
            // In other words, we should never hit this code. This code is here as a failsafe to prevent a crash in a scenario where the keychain is entirely hosed.
            // Consumers should always check `canAccessKeychain()` after creating a Valet and before using it. Doing so will catch this error.
            return "INVALID_SHARED_ACCESS_GROUP_PREFIX"
        }
        
        let components = accessGroup.components(separatedBy: ".")
        if let bundleSeedIdentifier = components.first, !bundleSeedIdentifier.isEmpty {
            return bundleSeedIdentifier
            
        } else {
            // We should always be able to access the shared access group prefix because the accessibility of the above keychain data is set to `always`.
            // In other words, we should never hit this code. This code is here as a failsafe to prevent a crash in a scenario where the keychain is entirely hosed.
            // Consumers should always check `canAccessKeychain()` after creating a Valet and before using it. Doing so will catch this error.
            return "INVALID_SHARED_ACCESS_GROUP_PREFIX"
        }
    }
    
    // MARK: Internal Class Methods
    
    internal static func copy<DesiredType>(matching query: [String : AnyHashable]) -> DataResult<DesiredType> {
        guard query.count > 0 else {
            ErrorHandler.assertionFailure("Must provide a query with at least one item")
            return .error(errSecParam)
        }
        
        var status = errSecNotAvailable
        var result: AnyObject? = nil
        execute(in: secItemLock) {
            status = SecItemCopyMatching(query as CFDictionary, &result)
        }
        
        if status == errSecSuccess {
            if let result = result as? DesiredType {
                return .success(result)
                
            } else {
                // The query failed to pull out a value object of the desired type, but did find metadata matching this query.
                // This can happen because either the query didn't ask for return data via [kSecReturnData : true], or because a metadata-only item existed in the keychain.
                return .error(errSecItemNotFound)
            }
            
        } else {
            ErrorHandler.assert(status != errSecMissingEntitlement, "A 'Missing Entitlements' error occurred. This is likely due to an Apple Keychain bug. As a workaround try running on a device that is not attached to a debugger.\n\nMore information: https://forums.developer.apple.com/thread/4743")
            
            return .error(status)
        }
    }
    
    internal static func containsObject(matching query: [String : AnyHashable]) -> Result {
        guard query.count > 0 else {
            ErrorHandler.assertionFailure("Must provide a query with at least one item")
            return .error(errSecParam)
        }
        
        var status = errSecNotAvailable
        execute(in: secItemLock) {
            status = SecItemCopyMatching(query as CFDictionary, nil)
        }
        
        if status == errSecSuccess {
            return .success
            
        } else {
            ErrorHandler.assert(status != errSecMissingEntitlement, "A 'Missing Entitlements' error occurred. This is likely due to an Apple Keychain bug. As a workaround try running on a device that is not attached to a debugger.\n\nMore information: https://forums.developer.apple.com/thread/4743")
            
            return .error(status)
        }
    }
    
    internal static func add(attributes: [String : AnyHashable]) -> Result {
        guard attributes.count > 0 else {
            ErrorHandler.assertionFailure("Must provide attributes with at least one item")
            return .error(errSecParam)
        }
        
        var status = errSecNotAvailable
        var result: AnyObject? = nil
        execute(in: secItemLock) {
            status = SecItemAdd(attributes as CFDictionary, &result)
        }
        
        if status == errSecSuccess {
            return .success
            
        } else {
            ErrorHandler.assert(status != errSecMissingEntitlement, "A 'Missing Entitlements' error occurred. This is likely due to an Apple Keychain bug. As a workaround try running on a device that is not attached to a debugger.\n\nMore information: https://forums.developer.apple.com/thread/4743")
            
            return .error(status)
        }
    }
    
    internal static func update(attributes: [String : AnyHashable], forItemsMatching query: [String : AnyHashable]) -> Result {
        guard attributes.count > 0 else {
            ErrorHandler.assertionFailure("Must provide attributes with at least one item")
            return .error(errSecParam)
        }
        
        guard query.count > 0 else {
            ErrorHandler.assertionFailure("Must provide a query with at least one item")
            return .error(errSecParam)
        }
        
        var status = errSecNotAvailable
        execute(in: secItemLock) {
            status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        }
        
        if status == errSecSuccess {
            return .success
            
        } else {
            ErrorHandler.assert(status != errSecMissingEntitlement, "A 'Missing Entitlements' error occurred. This is likely due to an Apple Keychain bug. As a workaround try running on a device that is not attached to a debugger.\n\nMore information: https://forums.developer.apple.com/thread/4743")
            
            return .error(status)
        }
    }
    
    internal static func deleteItems(matching query: [String : AnyHashable]) -> Result {
        guard query.count > 0 else {
            ErrorHandler.assertionFailure("Must provide a query with at least one item")
            return .error(errSecParam)
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
            return .success
            
        } else {
            ErrorHandler.assert(status != errSecMissingEntitlement, "A 'Missing Entitlements' error occurred. This is likely due to an Apple Keychain bug. As a workaround try running on a device that is not attached to a debugger.\n\nMore information: https://forums.developer.apple.com/thread/4743")
            
            return .error(status)
        }
    }
    
    // MARK: Private Properties
    
    private static let secItemLock = NSLock()
}
