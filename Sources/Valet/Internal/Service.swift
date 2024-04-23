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


internal enum Service: CustomStringConvertible, Equatable, Sendable {
    case standard(Identifier, Configuration)
    case sharedGroup(SharedGroupIdentifier, Identifier?, Configuration)

    #if os(macOS)
    case standardOverride(service: Identifier, Configuration)
    case sharedGroupOverride(service: SharedGroupIdentifier, Configuration)
    #endif

    // MARK: Equatable
    
    internal static func ==(lhs: Service, rhs: Service) -> Bool {
        lhs.description == rhs.description
    }

    // MARK: CustomStringConvertible
    
    internal var description: String {
        secService
    }

    // MARK: Internal Static Methods

    internal static func standard(with configuration: Configuration, identifier: Identifier, accessibilityDescription: String) -> String {
        "VAL_\(configuration.description)_initWithIdentifier:accessibility:_\(identifier)_\(accessibilityDescription)"
    }

    internal static func sharedGroup(with configuration: Configuration, groupIdentifier: SharedGroupIdentifier, identifier: Identifier?, accessibilityDescription: String) -> String {
        if let identifier = identifier {
            return "VAL_\(configuration.description)_initWithSharedAccessGroupIdentifier:accessibility:_\(groupIdentifier.groupIdentifier)_\(identifier)_\(accessibilityDescription)"
        } else {
            return "VAL_\(configuration.description)_initWithSharedAccessGroupIdentifier:accessibility:_\(groupIdentifier.groupIdentifier)_\(accessibilityDescription)"
        }
    }

    internal static func sharedGroup(with configuration: Configuration, explicitlySetIdentifier identifier: Identifier, accessibilityDescription: String) -> String {
        "VAL_\(configuration.description)_initWithSharedAccessGroupIdentifier:accessibility:_\(identifier)_\(accessibilityDescription)"
    }

    // MARK: Internal Methods
    
    internal func generateBaseQuery() -> [String : AnyHashable] {
        var baseQuery: [String : AnyHashable] = [
            kSecClass as String : kSecClassGenericPassword as String,
            kSecAttrService as String : secService,
        ]

        if #available(iOS 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, *) {
            baseQuery[kSecUseDataProtectionKeychain as String] = true
        }

        let configuration: Configuration
        switch self {
        case let .standard(_, desiredConfiguration):
            configuration = desiredConfiguration
            
        case let .sharedGroup(groupIdentifier, _, desiredConfiguration):
            baseQuery[kSecAttrAccessGroup as String] = groupIdentifier.description
            configuration = desiredConfiguration

        #if os(macOS)
        case let .standardOverride(_, desiredConfiguration):
            configuration = desiredConfiguration

        case let .sharedGroupOverride(identifier, desiredConfiguration):
            baseQuery[kSecAttrAccessGroup as String] = identifier.description
            configuration = desiredConfiguration
        #endif
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
            service = Service.standard(with: configuration, identifier: identifier, accessibilityDescription: configuration.accessibility.description)
        case let .sharedGroup(groupIdentifier, identifier, configuration):
            service = Service.sharedGroup(with: configuration, groupIdentifier: groupIdentifier, identifier: identifier, accessibilityDescription: configuration.accessibility.description)
        #if os(macOS)
        case let .standardOverride(identifier, _):
            service = identifier.description
        case let .sharedGroupOverride(identifier, _):
            service = identifier.groupIdentifier
        #endif
        }

        switch self {
        case let .standard(_, configuration),
             let .sharedGroup(_, _, configuration):
            switch configuration {
            case .valet, .iCloud:
                // Nothing to do here.
                break

            case let .secureEnclave(accessControl),
                 let .singlePromptSecureEnclave(accessControl):
                service += accessControl.description
            }

            return service

        #if os(macOS)
        case .standardOverride,
             .sharedGroupOverride:
            return service
        #endif
        }
    }
}
