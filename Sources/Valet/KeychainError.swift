//
//  KeychainError.swift
//  Valet
//
//  Created by Dan Federman and Eric Muller on 9/16/17.
//  Copyright © 2017 Square Inc.
//
//  Licensed under the Apache License Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing software
//  distributed under the License is distributed on an "AS IS" BASIS
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import Foundation


@objc(VALKeychainError)
public enum KeychainError: Int, CaseIterable, CustomStringConvertible, Error, Equatable {
    /// The keychain could not be accessed.
    case couldNotAccessKeychain
    /// User dismissed the user-presence prompt.
    case userCancelled
    /// No data was found for the requested key.
    case itemNotFound
    /// The application does not have the proper entitlements to perform the requested action.
    /// This may be due to an Apple Keychain bug. As a workaround try running on a device that is not attached to a debugger.
    /// - SeeAlso: https://forums.developer.apple.com/thread/4743
    case missingEntitlement
    /// The key provided is empty.
    case emptyKey
    /// The value provided is empty.
    case emptyValue

    init(status: OSStatus) {
        switch status {
        case errSecItemNotFound:
            self = .itemNotFound
        case errSecUserCanceled,
             errSecAuthFailed:
            self = .userCancelled
        case errSecMissingEntitlement:
            self = .missingEntitlement
        default:
            self = .couldNotAccessKeychain
        }
    }

    // MARK: CustomStringConvertible

    public var description: String {
        switch self {
        case .couldNotAccessKeychain: return "KeychainError.couldNotAccessKeychain"
        case .emptyKey: return "KeychainError.emptyKey"
        case .emptyValue: return "KeychainError.emptyValue"
        case .itemNotFound: return "KeychainError.itemNotFound"
        case .missingEntitlement: return "KeychainError.missingEntitlement"
        case .userCancelled: return "KeychainError.userCancelled"
        }
    }

}
