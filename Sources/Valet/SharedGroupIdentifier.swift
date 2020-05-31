//
//  SharedGroupIdentifier.swift
//  Valet
//
//  Created by Dan Federman on 2/25/20.
//  Copyright © 2020 Square, Inc.
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


public struct SharedGroupIdentifier: CustomStringConvertible {

    // MARK: Initialization

    /// A representation of a shared access group identifier.
    /// - Parameters:
    ///   - appIDPrefix: The application's App ID prefix. This string can be found by inspecting the application's provisioning profile, or viewing the application's App ID Configuration on developer.apple.com. This string must not be empty.
    ///   - groupIdentifier: An identifier that cooresponds to a value in keychain-access-groups in the application's Entitlements file. This string must not be empty.
    /// - SeeAlso: https://developer.apple.com/documentation/security/keychain_services/keychain_items/sharing_access_to_keychain_items_among_a_collection_of_apps
    public init?(appIDPrefix: String, nonEmptyGroup groupIdentifier: String?) {
        guard !appIDPrefix.isEmpty, let groupIdentifier = groupIdentifier, !groupIdentifier.isEmpty else {
            return nil
        }

        self.prefix = appIDPrefix
        self.groupIdentifier = groupIdentifier
    }

    /// A representation of a shared app group identifier.
    /// - Parameters:
    ///   - groupPrefix: On iOS, iPadOS, watchOS, and tvOS, this prefix must equal "group". On macOS, this prefix is the application's App ID prefix, which can be found by inspecting the application's provisioning profile, or viewing the application's App ID Configuration on developer.apple.com. This string must not be empty.
    ///   - groupIdentifier: An identifier that corresponds to a value in com.apple.security.application-groups in the application's Entitlements file. This string must not be empty.
    /// - SeeAlso: https://developer.apple.com/documentation/security/keychain_services/keychain_items/sharing_access_to_keychain_items_among_a_collection_of_apps
    public init?(groupPrefix: String, nonEmptyGroup groupIdentifier: String?) {
        #if os(macOS)
        guard !groupPrefix.isEmpty, let groupIdentifier = groupIdentifier, !groupIdentifier.isEmpty else {
            return nil
        }
        #else
        guard groupPrefix == Self.appGroupPrefix, let groupIdentifier = groupIdentifier, !groupIdentifier.isEmpty else {
            return nil
        }
        #endif

        self.prefix = groupPrefix
        self.groupIdentifier = groupIdentifier
    }

    // MARK: CustomStringConvertible

    public var description: String {
        prefix + "." + groupIdentifier
    }

    // MARK: Internal Properties

    internal let prefix: String
    internal let groupIdentifier: String

    internal var asIdentifier: Identifier {
        // It is safe to force unwrap because we've already validated that our description is non-empty.
        Identifier(nonEmpty: description)!
    }

    // MARK: Private Static Properties

    private static let appGroupPrefix = "group"
}
