//  Created by Dan Federman on 9/18/17.
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


@objc(VALSecureEnclaveAccessControl)
public enum SecureEnclaveAccessControl: Int, CustomStringConvertible, Equatable {
    /// Access to keychain elements requires user presence verification via Touch ID, Face ID, or device Passcode. On macOS 10.15 and later, this element may also be accessed via a prompt on a paired watch. Keychain elements are still accessible by Touch ID even if fingers are added or removed. Touch ID does not have to be available or enrolled.
    case userPresence = 1
    
    /// Access to keychain elements requires user presence verification via Face ID, or any finger enrolled in Touch ID. Keychain elements remain accessible via Face ID or Touch ID after faces or fingers are added or removed. Face ID must be enabled with at least one face enrolled, or Touch ID must be available and at least one finger must be enrolled.
    @available(macOS 10.12.1, *)
    case biometricAny
    
    /// Access to keychain elements requires user presence verification via the face currently enrolled in Face ID, or fingers currently enrolled in Touch ID. Previously written keychain elements become inaccessible when faces or fingers are added or removed. Face ID must be enabled with at least one face enrolled, or Touch ID must be available and at least one finger must be enrolled.
    @available(macOS 10.12.1, *)
    case biometricCurrentSet
    
    /// Access to keychain elements requires user presence verification via device Passcode.
    case devicePasscode
    
    // MARK: CustomStringConvertible
    
    public var description: String {
        switch self {
        case .userPresence:
            /*
             VALSecureEnclaveValet v1.0-v2.0.7 used UserPresence without a suffix – the concept of a customizable AccessControl was added in v2.1.
             For backwards compatibility, do not append an access control suffix for UserPresence.
             */
            return ""
        case .biometricAny:
            if #available(macOS 10.12.1, *) {
                return "_AccessControlTouchIDAnyFingerprint"
            } else {
                assertionFailure(".biometricAny requires macOS 10.12.1.")
                return ""
            }
        case .biometricCurrentSet:
            if #available(macOS 10.12.1, *) {
                return "_AccessControlTouchIDCurrentFingerprintSet"
            } else {
                assertionFailure(".biometricCurrentSet requires macOS 10.12.1.")
                return ""
            }
        case .devicePasscode:
            return "_AccessControlDevicePasscode"
        }
    }
    
    // MARK: Internal Properties
    
    internal var secAccessControl: SecAccessControlCreateFlags {
        switch self {
        case .userPresence:
            return .userPresence
        case .biometricAny:
            if #available(iOS 11.3, tvOS 11.3, watchOS 4.3, macOS 10.13.4, *) {
                return .biometryAny
            } else if #available(macOS 10.12.1, *) {
                return .touchIDAny
            } else {
                assertionFailure(".biometricAny requires macOS 10.12.1.")
                return .userPresence
            }
        case .biometricCurrentSet:
            if #available(iOS 11.3, tvOS 11.3, watchOS 4.3, macOS 10.13.4, *) {
                return .biometryCurrentSet
            } else if #available(macOS 10.12.1, *) {
                return .touchIDCurrentSet
            } else {
                assertionFailure(".biometricCurrentSet requires macOS 10.12.1.")
                return .userPresence
            }
        case .devicePasscode:
            if #available(macOS 10.11, *) {
                return .devicePasscode
            } else {
                assertionFailure(".devicePasscode requires macOS 10.11.")
                return .userPresence
            }
        }
    }

    internal static func allValues() -> [SecureEnclaveAccessControl] {
        var values: [SecureEnclaveAccessControl] = [
            .userPresence,
            .devicePasscode
        ]
        if #available(macOS 10.12.1, *) {
            values += [
                .biometricAny,
                .biometricCurrentSet,
            ]
        }
        return values
    }
}
