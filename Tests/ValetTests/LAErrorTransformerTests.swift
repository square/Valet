//  Created by Allison Moyer on 6/2/21.
//  Copyright © 2021 Square, Inc.
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

import XCTest

@testable import Valet

@available(tvOS 11.0, macOS 11.2, *)
final class LAErrorTransformerTests: XCTestCase {

    // MARK: - Tests

    func test_transform_returnsUserCancelledErrorFrom_userCancel_forAllAccessControls() {
        SecureEnclaveAccessControl.allValues().forEach {
            XCTAssertEqual(
                LAErrorTransformer.transform(
                    error: .init(.userCancel),
                    accessControl: $0
                ),
                .keychain(.userCancelled)
            )
        }
    }

    func test_transform_returnsUserCancelledErrorFrom_systemCancel_forAllAccessControls() {
        SecureEnclaveAccessControl.allValues().forEach {
            XCTAssertEqual(
                LAErrorTransformer.transform(
                    error: .init(.systemCancel),
                    accessControl: $0
                ),
                .keychain(.userCancelled)
            )
        }
    }

    func test_transform_returnsUserCancelledErrorFrom_authenticationFailed_forAllAccessControls() {
        SecureEnclaveAccessControl.allValues().forEach {
            XCTAssertEqual(
                LAErrorTransformer.transform(
                    error: .init(.authenticationFailed),
                    accessControl: $0
                ),
                .keychain(.userCancelled)
            )
        }
    }

    func test_transform_returnsUserCancelledErrorFrom_appCancel_forAllAccessControls() {
        SecureEnclaveAccessControl.allValues().forEach {
            XCTAssertEqual(
                LAErrorTransformer.transform(
                    error: .init(.appCancel),
                    accessControl: $0
                ),
                .keychain(.userCancelled)
            )
        }
    }

    func test_transform_returnsUserFallbackErrorFrom_userFallback_forAllAccessControls() {
        SecureEnclaveAccessControl.allValues().forEach {
            XCTAssertEqual(
                LAErrorTransformer.transform(
                    error: .init(.userFallback),
                    accessControl: $0
                ),
                .secureEnclave(.userFallback)
            )
        }
    }

    func test_transform_returnsCouldNotAccessKeychainErrorFrom_touchIDLockout_forAllAccessControls() {
        SecureEnclaveAccessControl.allValues().forEach {
            XCTAssertEqual(
                LAErrorTransformer.transform(
                    error: .init(.touchIDLockout),
                    accessControl: $0
                ),
                .keychain(.couldNotAccessKeychain)
            )
        }
    }

    @available(iOS 11.0, *)
    func test_transform_returnsCouldNotAccessKeychainErrorFrom_biometryLockout_forAllAccessControls() {
        SecureEnclaveAccessControl.allValues().forEach {
            XCTAssertEqual(
                LAErrorTransformer.transform(
                    error: .init(.biometryLockout),
                    accessControl: $0
                ),
                .keychain(.couldNotAccessKeychain)
            )
        }
    }

    #if os(macOS)
    func test_transform_returnsCouldNotAccessKeychainErrorFrom_biometryDisconnected_forAllAccessControls() {
        SecureEnclaveAccessControl.allValues().forEach {
            XCTAssertEqual(
                LAErrorTransformer.transform(
                    error: .init(.biometryDisconnected),
                    accessControl: $0
                ),
                .keychain(.couldNotAccessKeychain)
            )
        }
    }
    #endif

    func test_transform_returnsItemNotFoundErrorFrom_passcodeNotSet_forAllAccessControls() {
        SecureEnclaveAccessControl.allValues().forEach {
            XCTAssertEqual(
                LAErrorTransformer.transform(
                    error: .init(.passcodeNotSet),
                    accessControl: $0
                ),
                .keychain(.itemNotFound)
            )
        }
    }

    func test_transform_returnsItemNotFoundErrorFrom_touchIDNotAvailable_forBiometricAccessControls() {
        let biometricAccessControls: [SecureEnclaveAccessControl] = [
            .biometricAny,
            .biometricCurrentSet,
        ]
        biometricAccessControls.forEach {
            XCTAssertEqual(
                LAErrorTransformer.transform(
                    error: .init(.touchIDNotAvailable),
                    accessControl: $0
                ),
                .keychain(.itemNotFound)
            )
        }
    }

    func test_transform_returnsItemNotFoundErrorFrom_touchIDNotEnrolled_forBiometricAccessControls() {
        let biometricAccessControls: [SecureEnclaveAccessControl] = [
            .biometricAny,
            .biometricCurrentSet,
        ]
        biometricAccessControls.forEach {
            XCTAssertEqual(
                LAErrorTransformer.transform(
                    error: .init(.touchIDNotEnrolled),
                    accessControl: $0
                ),
                .keychain(.itemNotFound)
            )
        }
    }

    @available(iOS 11.0, *)
    func test_transform_returnsItemNotFoundErrorFrom_biometryNotAvailable_forBiometricAccessControls() {
        let biometricAccessControls: [SecureEnclaveAccessControl] = [
            .biometricAny,
            .biometricCurrentSet,
        ]
        biometricAccessControls.forEach {
            XCTAssertEqual(
                LAErrorTransformer.transform(
                    error: .init(.biometryNotAvailable),
                    accessControl: $0
                ),
                .keychain(.itemNotFound)
            )
        }
    }

    @available(iOS 11.0, *)
    func test_transform_returnsItemNotFoundErrorFrom_biometryNotEnrolled_forBiometricAccessControls() {
        let biometricAccessControls: [SecureEnclaveAccessControl] = [
            .biometricAny,
            .biometricCurrentSet,
        ]
        biometricAccessControls.forEach {
            XCTAssertEqual(
                LAErrorTransformer.transform(
                    error: .init(.biometryNotEnrolled),
                    accessControl: $0
                ),
                .keychain(.itemNotFound)
            )
        }
    }

    #if os(macOS)
    func test_transform_returnsItemNotFoundErrorFrom_watchNotAvailable_forAllAccessControls() {
        SecureEnclaveAccessControl.allValues().forEach {
            XCTAssertEqual(
                LAErrorTransformer.transform(
                    error: .init(.watchNotAvailable),
                    accessControl: $0
                ),
                .keychain(.itemNotFound)
            )
        }
    }
    #endif

    #if os(macOS)
    func test_transform_returnsItemNotFoundErrorFrom_biometryNotPaired_forBiometricAccessControls() {
        let biometricAccessControls: [SecureEnclaveAccessControl] = [
            .biometricAny,
            .biometricCurrentSet,
        ]
        biometricAccessControls.forEach {
            XCTAssertEqual(
                LAErrorTransformer.transform(
                    error: .init(.biometryNotPaired),
                    accessControl: $0
                ),
                .keychain(.itemNotFound)
            )
        }
    }
    #endif

    func test_transform_returnsInternalErrorErrorFrom_touchIDNotAvailable_forNonBiometricAccessControls() {
        let nonBiometricAccessControls: [SecureEnclaveAccessControl] = [
            .devicePasscode,
            .userPresence
        ]
        nonBiometricAccessControls.forEach {
            XCTAssertEqual(
                LAErrorTransformer.transform(
                    error: .init(.touchIDNotAvailable),
                    accessControl: $0
                ),
                .secureEnclave(.internalError)
            )
        }
    }

    func test_transform_returnsInternalErrorErrorFrom_touchIDNotEnrolled_forNonBiometricAccessControls() {
        let nonBiometricAccessControls: [SecureEnclaveAccessControl] = [
            .devicePasscode,
            .userPresence
        ]
        nonBiometricAccessControls.forEach {
            XCTAssertEqual(
                LAErrorTransformer.transform(
                    error: .init(.touchIDNotEnrolled),
                    accessControl: $0
                ),
                .secureEnclave(.internalError)
            )
        }
    }

    @available(iOS 11.0, *)
    func test_transform_returnsInternalErrorErrorFrom_biometryNotAvailable_forNonBiometricAccessControls() {
        let nonBiometricAccessControls: [SecureEnclaveAccessControl] = [
            .devicePasscode,
            .userPresence
        ]
        nonBiometricAccessControls.forEach {
            XCTAssertEqual(
                LAErrorTransformer.transform(
                    error: .init(.biometryNotAvailable),
                    accessControl: $0
                ),
                .secureEnclave(.internalError)
            )
        }
    }

    @available(iOS 11.0, *)
    func test_transform_returnsInternalErrorErrorFrom_biometryNotEnrolled_forNonBiometricAccessControls() {
        let nonBiometricAccessControls: [SecureEnclaveAccessControl] = [
            .devicePasscode,
            .userPresence
        ]
        nonBiometricAccessControls.forEach {
            XCTAssertEqual(
                LAErrorTransformer.transform(
                    error: .init(.biometryNotEnrolled),
                    accessControl: $0
                ),
                .secureEnclave(.internalError)
            )
        }
    }

    #if os(macOS)
    func test_transform_returnsInternalErrorErrorFrom_biometryNotPaired_forNonBiometricAccessControls() {
        let nonBiometricAccessControls: [SecureEnclaveAccessControl] = [
            .devicePasscode,
            .userPresence
        ]
        nonBiometricAccessControls.forEach {
            XCTAssertEqual(
                LAErrorTransformer.transform(
                    error: .init(.biometryNotPaired),
                    accessControl: $0
                ),
                .secureEnclave(.internalError)
            )
        }
    }
    #endif

    func test_transform_returnsInternalErrorErrorFrom_invalidContext_forAllAccessControls() {
        SecureEnclaveAccessControl.allValues().forEach {
            XCTAssertEqual(
                LAErrorTransformer.transform(
                    error: .init(.invalidContext),
                    accessControl: $0
                ),
                .secureEnclave(.internalError)
            )
        }
    }

    func test_transform_returnsInternalErrorError_notInteractive_forAllAccessControls() {
        SecureEnclaveAccessControl.allValues().forEach {
            XCTAssertEqual(
                LAErrorTransformer.transform(
                    error: .init(.notInteractive),
                    accessControl: $0
                ),
                .secureEnclave(.internalError)
            )
        }
    }

}
