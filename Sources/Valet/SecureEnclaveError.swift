//  Created by Allison Moyer on 5/28/21.
//  Copyright © 2021 Square, Inc. All rights reserved.
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

@objc(VALSecureEnclaveError)
public enum SecureEnclaveError: Int, CaseIterable, CustomStringConvertible, Error, Equatable {
    /// Access to the secure enclave was not attempted because it was not available (due to biometrics not being available or enrolled
    /// or being locked out, or the authentication context being invalidated)
    case couldNotAccess

    /// Access to the secure enclave was not attempted because the user canceled the prompt.
    case userCancelled

    /// Access to the secure enclave was not attempted because the user opted to the fallback option (i.e. 'Enter Password').
    /// Callers should handle this as a custom alternative option to satisfying authentication.
    case userFallback

    /// Access to the secure enclave was not attempted because authentication could not start because
    /// passcode is not set on the device
    case passcodeNotSet

    /// Access to the secure enclave was not attempted due to an unexpected internal error.
    /// This error condition should never be reached – it is indicative of Apple's Objective-C API breaking its nullability contract.
    case internalError

    // MARK: CustomStringConvertible

    public var description: String {
        switch self {
        case .couldNotAccess: return "SecureEnclaveError.couldNotAccess"
        case .userCancelled: return "SecureEnclaveError.userCancelled"
        case .userFallback: return "SecureEnclaveError.userFallback"
        case .passcodeNotSet: return "SecureEnclaveError.passcodeNotSet"
        case .internalError: return "SecureEnclaveError.internalError"
        }
    }

}
