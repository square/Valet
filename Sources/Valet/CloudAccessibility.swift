//
//  CloudAccessibility.swift
//  Valet
//
//  Created by Dan Federman on 9/17/17.
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


@objc(VALCloudAccessibility)
public enum CloudAccessibility: Int, CaseIterable, CustomStringConvertible, Equatable {
    /// Valet data can only be accessed while the device is unlocked. This attribute is recommended for data that only needs to be accessible while the application is in the foreground. Valet data with this attribute will migrate to a new device when using encrypted backups.
    case whenUnlocked = 1
    /// Valet data can only be accessed once the device has been unlocked after a restart. This attribute is recommended for data that needs to be accessible by background applications. Valet data with this attribute will migrate to a new device when using encrypted backups.
    case afterFirstUnlock = 2

    // MARK: CustomStringConvertible
    
    public var description: String {
        accessibility.description
    }
    
    // MARK: Public Properties
    
    public var accessibility: Accessibility {
        switch self {
        case .whenUnlocked:
            return .whenUnlocked
        case .afterFirstUnlock:
            return .afterFirstUnlock
        }
    }
    
    public var secAccessibilityAttribute: String {
        accessibility.secAccessibilityAttribute
    }

}
