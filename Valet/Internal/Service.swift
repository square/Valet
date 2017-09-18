//
//  Service.swift
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


internal enum Service: CustomStringConvertible {
    case standard(Identifier, Accessibility, Flavor)
    case sharedAccessGroup(Identifier, Accessibility, Flavor)
    
    // MARK: Equatable
    
    internal static func ==(lhs: Service, rhs: Service) -> Bool {
        return lhs.description == rhs.description
    }

    // MARK: CustomStringConvertible
    
    internal var description: String {
        switch self {
        case let .standard(identifier, accessibility, flavor):
            return "VAL_\(flavor)_initWithIdentifier:accessibility:_\(identifier)_\(accessibility)"
        case let .sharedAccessGroup(identifier, accessibility, flavor):
            return "VAL_\(flavor)_initWithSharedAccessGroupIdentifier:accessibility:_\(identifier)_\(accessibility)"
        }
    }
    
    // MARK: Internal Properties
    
    internal var baseQuery: [String : AnyHashable] {
        return [
            kSecClass as String : kSecClassGenericPassword as String,
            kSecAttrService as String : description,
            kSecAttrAccessible as String : accessability.secAccessibilityAttribute
        ]
    }
    
    // MARK: Internal Methods
    
    internal func baseQuery(with options: [String : AnyHashable]) -> [String : AnyHashable] {
        return baseQuery.merging(options, uniquingKeysWith: { (baseValue, optionValue) -> AnyHashable in
            return optionValue
        })
    }
    
    // MARK: Private Properties
    
    private var accessability: Accessibility {
        switch self {
        case let .standard(_, accessability, _):
            return accessability
        case let .sharedAccessGroup(_, accessability, _):
            return accessability
        }
    }
}
