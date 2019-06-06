//
//  Accessibility.swift
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


@objc(VALAccessibility)
public enum Accessibility: Int, CustomStringConvertible, Equatable {
    /// Valet data can only be accessed while the device is unlocked. This attribute is recommended for data that only needs to be accessible while the application is in the foreground. Valet data with this attribute will migrate to a new device when using encrypted backups.
    case whenUnlocked = 1
    /// Valet data can only be accessed once the device has been unlocked after a restart. This attribute is recommended for data that needs to be accessible by background applications. Valet data with this attribute will migrate to a new device when using encrypted backups.
    case afterFirstUnlock
    /// Valet data can always be accessed regardless of the lock state of the device. This attribute is not recommended. Valet data with this attribute will migrate to a new device when using encrypted backups.
    case always
    
    /// Valet data can only be accessed while the device is unlocked. This attribute is recommended for items that only need to be accessible while the application is in the foreground. Valet data with this attribute will never migrate to a new device, so these items will be missing after a backup is restored to a new device. No items can be stored in this class on devices without a passcode. Disabling the device passcode will cause all items in this class to be deleted.
    case whenPasscodeSetThisDeviceOnly
    /// Valet data can only be accessed while the device is unlocked. This is recommended for data that only needs to be accessible while the application is in the foreground. Valet data with this attribute will never migrate to a new device, so these items will be missing after a backup is restored to a new device.
    case whenUnlockedThisDeviceOnly
    /// Valet data can only be accessed once the device has been unlocked after a restart. This is recommended for items that need to be accessible by background applications. Valet data with this attribute will never migrate to a new device, so these items will be missing after a backup is restored to a new device.
    case afterFirstUnlockThisDeviceOnly
    /// Valet data can always be accessed regardless of the lock state of the device. This option is not recommended. Valet data with this attribute will never migrate to a new device, so these items will be missing after a backup is restored to a new device.
    case alwaysThisDeviceOnly
    
    // MARK: CustomStringConvertible
    
    public var description: String {
        switch self {
        case .afterFirstUnlock:
            return "AccessibleAfterFirstUnlock"
        case .afterFirstUnlockThisDeviceOnly:
            return "AccessibleAfterFirstUnlockThisDeviceOnly"
        case .always:
            return "AccessibleAlways"
        case .alwaysThisDeviceOnly:
            return "AccessibleAlwaysThisDeviceOnly"
        case .whenPasscodeSetThisDeviceOnly:
            return "AccessibleWhenPasscodeSetThisDeviceOnly"
        case .whenUnlocked:
            return "AccessibleWhenUnlocked"
        case .whenUnlockedThisDeviceOnly:
            return "AccessibleWhenUnlockedThisDeviceOnly"
        }
    }
    
    // MARK: Public Properties
    
    public var secAccessibilityAttribute: String {
        let accessibilityAttribute: CFString
        
        switch self {
        case .afterFirstUnlock:
            accessibilityAttribute = kSecAttrAccessibleAfterFirstUnlock
        case .afterFirstUnlockThisDeviceOnly:
            accessibilityAttribute = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        case .always:
            accessibilityAttribute = kSecAttrAccessibleAlways
        case .alwaysThisDeviceOnly:
            accessibilityAttribute = kSecAttrAccessibleAlwaysThisDeviceOnly
        case .whenPasscodeSetThisDeviceOnly:
            accessibilityAttribute = kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly
        case .whenUnlocked:
            accessibilityAttribute = kSecAttrAccessibleWhenUnlocked
        case .whenUnlockedThisDeviceOnly:
            accessibilityAttribute = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        }
        
        return accessibilityAttribute as String
    }
    
    // MARK: Internal
    
    internal static func allValues() -> [Accessibility] {
        return [
            .whenUnlocked,
            .afterFirstUnlock,
            .always,
            .whenPasscodeSetThisDeviceOnly,
            .whenUnlockedThisDeviceOnly,
            .afterFirstUnlockThisDeviceOnly,
            .alwaysThisDeviceOnly
        ]
    }
}
