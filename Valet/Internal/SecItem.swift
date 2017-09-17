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


internal func execute(in lock: NSLock, block: () -> Void) {
    lock.lock()
    block()
    lock.unlock()
}


internal final class SecItem {
    
    // MARK: Internal Enum
    
    internal enum Result<SuccessType, FailureType> {
        case success(SuccessType)
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
        
        guard status == errSecSuccess else {
            ErrorHandler.assertionFailure("Could not find shared access group prefix.")
            return nil
        }
        
        let queryResult = result as! [CFString : AnyHashable]
        guard let accessGroup = queryResult[kSecAttrAccessGroup] as? String else {
            ErrorHandler.assertionFailure("Could not find shared access group prefix.")
            return nil
        }
        
        let components = accessGroup.components(separatedBy: ".")
        let bundleSeedIdentifier = components.first
        
        return Identifier(nonEmpty: bundleSeedIdentifier)?.description
    }
    
    // MARK: Internal Class Methods
    
    internal static func copy<DesiredType>(matching query: [String : AnyHashable]) -> Result<DesiredType, OSStatus> {
        return execute(secItemFunction: SecItemCopyMatching, query: query)
    }
    
    internal static func add<DesiredType>(attributes: [String : AnyHashable]) -> Result<DesiredType, OSStatus> {
        return execute(secItemFunction: SecItemAdd, query: attributes)
    }
    
    internal static func update(attributes: [String : AnyHashable], forItemsMatching query: [String : AnyHashable]) -> Result<Void?, OSStatus> {
        guard attributes.count > 0 else {
            ErrorHandler.assertionFailure("Must provide attributes with at least one item")
            return Result.error(errSecParam)
        }
        
        guard query.count > 0 else {
            ErrorHandler.assertionFailure("Must provide a query with at least one item")
            return Result.error(errSecParam)
        }
        
        var status = errSecNotAvailable
        Valet.execute(in: secItemLock) {
            status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        }
        
        if status == errSecSuccess {
            return Result.success(())
            
        } else {
            ErrorHandler.assert(status != errSecMissingEntitlement, "A 'Missing Entitlements' error occurred. This is likely due to an Apple Keychain bug. As a workaround try running on a device that is not attached to a debugger.\n\nMore information: https://forums.developer.apple.com/thread/4743")
            
            return Result.error(status)
        }
    }
    
    internal static func delete(itemsMatching query: [String : AnyHashable]) -> Result<Void, OSStatus> {
        guard query.count > 0 else {
            ErrorHandler.assertionFailure("Must provide a query with at least one item")
            return Result.error(errSecParam)
        }
        
        var status = errSecNotAvailable
        Valet.execute(in: secItemLock) {
            status = SecItemDelete(query as CFDictionary)
        }
        
        if status == errSecSuccess {
            return Result.success(())
            
        } else {
            ErrorHandler.assert(status != errSecMissingEntitlement, "A 'Missing Entitlements' error occurred. This is likely due to an Apple Keychain bug. As a workaround try running on a device that is not attached to a debugger.\n\nMore information: https://forums.developer.apple.com/thread/4743")
            
            return Result.error(status)
        }
    }
    
    // MARK: Private Class Methods
    
    private static func execute<DesiredType>(secItemFunction: (CFDictionary, UnsafeMutablePointer<CoreFoundation.CFTypeRef?>?) -> OSStatus, query: [String : AnyHashable]) -> Result<DesiredType, OSStatus> {
        guard query.count > 0 else {
            ErrorHandler.assertionFailure("Must provide a query with at least one item")
            return Result.error(errSecParam)
        }
        
        var status = errSecNotAvailable
        var result: AnyObject? = nil
        Valet.execute(in: secItemLock) {
            status = secItemFunction(query as CFDictionary, &result)
        }
        
        if status == errSecSuccess {
            return Result.success(result as! DesiredType)
            
        } else {
            ErrorHandler.assert(status != errSecMissingEntitlement, "A 'Missing Entitlements' error occurred. This is likely due to an Apple Keychain bug. As a workaround try running on a device that is not attached to a debugger.\n\nMore information: https://forums.developer.apple.com/thread/4743")
            
            return Result.error(status)
        }
    }
    
    // MARK: Private Properties
    
    private static let secItemLock = NSLock()
    
}
