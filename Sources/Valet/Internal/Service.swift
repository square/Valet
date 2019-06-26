//
//  Service.swift
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


internal enum Service: CustomStringConvertible, Equatable {
    case standard(Identifier, Configuration)
    case sharedAccessGroup(Identifier, Configuration)
    
    // MARK: Equatable
    
    internal static func ==(lhs: Service, rhs: Service) -> Bool {
        return lhs.description == rhs.description
    }

    // MARK: CustomStringConvertible
    
    internal var description: String {
        return secService
    }
    
    // MARK: Internal Methods
    
    internal func generateBaseQuery() -> [String : AnyHashable] {
        var baseQuery: [String : AnyHashable] = [
            kSecClass as String : kSecClassGenericPassword as String,
            kSecAttrService as String : secService
        ]
        
        let configuration: Configuration
        switch self {
        case let .standard(_, desiredConfiguration):
            configuration = desiredConfiguration
            
        case let .sharedAccessGroup(identifier, desiredConfiguration):
            ErrorHandler.assert(!identifier.description.hasPrefix("\(SecItem.sharedAccessGroupPrefix)."), "Do not add the Bundle Seed ID as a prefix to your identifier. Valet prepends this value for you. Your Valet will not be able to access the keychain with the provided configuration")
            baseQuery[kSecAttrAccessGroup as String] = "\(SecItem.sharedAccessGroupPrefix).\(identifier.description)"
            configuration = desiredConfiguration
        }
        
        switch configuration {
        case .valet:
            baseQuery[kSecAttrAccessible as String] = configuration.accessibility.secAccessibilityAttribute

        case .iCloud:
            baseQuery[kSecAttrSynchronizable as String] = true
            baseQuery[kSecAttrAccessible as String] = configuration.accessibility.secAccessibilityAttribute

        case let .secureEnclave(desiredAccessControl),
             let .singlePromptSecureEnclave(desiredAccessControl):
            // Note that kSecAttrAccessControl and kSecAttrAccessible are mutually exclusive.
            baseQuery[kSecAttrAccessControl as String] = SecAccessControlCreateWithFlags(nil, kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly, desiredAccessControl.secAccessControl, nil)
        }
        
        return baseQuery
    }
    
    // MARK: Private Methods
    
    private var secService: String {
        var service: String
        switch self {
        case let .standard(identifier, configuration):
            service = "VAL_\(configuration.description)_initWithIdentifier:accessibility:_\(identifier)_\(configuration.accessibility.description)"
        case let .sharedAccessGroup(identifier, configuration):
            service = "VAL_\(configuration.description)_initWithSharedAccessGroupIdentifier:accessibility:_\(identifier)_\(configuration.accessibility.description)"
        }
        
        let configuration: Configuration
        switch self {
        case let .standard(_, desiredConfiguration),
             let .sharedAccessGroup(_, desiredConfiguration):
            configuration = desiredConfiguration
        }
        
        switch configuration {
        case .valet, .iCloud:
            // Nothing to do here.
            break

        case let .secureEnclave(accessControl),
             let .singlePromptSecureEnclave(accessControl):
            service += accessControl.description
        }
        
        return service
    }
}
