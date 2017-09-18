//
//  SecItem.swift
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


internal func execute<ReturnType>(in lock: NSLock, block: () -> ReturnType) -> ReturnType {
    lock.lock()
    defer {
        lock.unlock()
    }
    return block()
}


internal final class SecItem {
    
    // MARK: Internal Enum
    
    internal enum DataResult<SuccessType, FailureType> {
        case success(SuccessType)
        case error(FailureType)
    }
    
    internal enum Result<FailureType> {
        case success
        case error(FailureType)
    }
    
    // MARK: Internal Class Properties
    
    internal static var sharedAccessGroupPrefix: String? {
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
            return nil
        }
        
        let components = accessGroup.components(separatedBy: ".")
        let bundleSeedIdentifier = components.first
        
        return Identifier(nonEmpty: bundleSeedIdentifier)?.description
    }
    
    // MARK: Internal Class Methods
    
    internal static func copy<DesiredType>(matching query: [String : AnyHashable]) -> DataResult<DesiredType, OSStatus> {
        guard query.count > 0 else {
            ErrorHandler.assertionFailure("Must provide a query with at least one item")
            return .error(errSecParam)
        }
        
        var status = errSecNotAvailable
        var result: AnyObject? = nil
        execute(in: secItemLock) {
            status = SecItemCopyMatching(query as CFDictionary, &result)
        }
        
        if status == errSecSuccess, let result = result {
            return .success(result as! DesiredType)
            
        } else {
            ErrorHandler.assert(status != errSecMissingEntitlement, "A 'Missing Entitlements' error occurred. This is likely due to an Apple Keychain bug. As a workaround try running on a device that is not attached to a debugger.\n\nMore information: https://forums.developer.apple.com/thread/4743")
            
            return .error(status)
        }
    }
    
    internal static func containsObject(matching query: [String : AnyHashable]) -> Result<OSStatus> {
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
    
    internal static func add(attributes: [String : AnyHashable]) -> Result<OSStatus> {
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
    
    internal static func update(attributes: [String : AnyHashable], forItemsMatching query: [String : AnyHashable]) -> Result<OSStatus> {
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
    
    internal static func delete(itemsMatching query: [String : AnyHashable]) -> Result<OSStatus> {
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
