//  Created by Dan Federman on 1/20/20.
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
import XCTest

@testable import Valet


class ConfigurationTests: XCTestCase {

    func test_description_valet_mirrorsLegacyName() {
        Accessibility.allValues().forEach {
            XCTAssertEqual(Configuration.valet($0).description, "VALValet")
        }
    }

    func test_description_iCloud_mirrorsLegacyName() {
        CloudAccessibility.allValues().forEach {
            XCTAssertEqual(Configuration.iCloud($0).description, "VALSynchronizableValet")
        }
    }

    func test_description_secureEnclave_mirrorsLegacyName() {
        SecureEnclaveAccessControl.allValues().forEach {
            XCTAssertEqual(Configuration.secureEnclave($0).description, "VALSecureEnclaveValet")
        }
    }

    func test_description_singlePromptSecureEnclave_mirrorsLegacyName() {
        SecureEnclaveAccessControl.allValues().forEach {
            XCTAssertEqual(Configuration.singlePromptSecureEnclave($0).description, "VALSinglePromptSecureEnclaveValet")
        }
    }

    func test_accessibility_valet_returnsPassedInAccessibility() {
        Accessibility.allValues().forEach {
            XCTAssertEqual(Configuration.valet($0).accessibility, $0)
        }
    }

    func test_accessibility_iCloud_returnsPassedInAccessibility() {
        CloudAccessibility.allValues().forEach {
            XCTAssertEqual(Configuration.iCloud($0).accessibility, $0.accessibility)
        }
    }

    func test_accessibility_secureEnclave_returnsWhenPassCodeSetThisDeviceOnly() {
        SecureEnclaveAccessControl.allValues().forEach {
            XCTAssertEqual(Configuration.secureEnclave($0).accessibility, Accessibility.whenPasscodeSetThisDeviceOnly)
        }
    }

    func test_accessibility_singlePromptSecureEnclave_returnsWhenPassCodeSetThisDeviceOnly() {
        SecureEnclaveAccessControl.allValues().forEach {
            XCTAssertEqual(Configuration.singlePromptSecureEnclave($0).accessibility, Accessibility.whenPasscodeSetThisDeviceOnly)
        }
    }

    func test_prettyDescription_valet_isHumanReadable() {
        Accessibility.allValues().forEach {
            XCTAssertEqual(Configuration.valet($0).prettyDescription, "\($0) (Valet)")
        }
    }

    func test_prettyDescription_iCloud_isHumanReadable() {
        CloudAccessibility.allValues().forEach {
            XCTAssertEqual(Configuration.iCloud($0).prettyDescription, "\($0) (iCloud)")
        }
    }

    func test_prettyDescription_secureEnclave_isHumanReadable() {
        SecureEnclaveAccessControl.allValues().forEach {
            XCTAssertEqual(Configuration.secureEnclave($0).prettyDescription, "\(Accessibility.whenPasscodeSetThisDeviceOnly) (Secure Enclave)")
        }
    }

    func test_prettyDescription_singlePromptSecureEnclave_isHumanReadable() {
        SecureEnclaveAccessControl.allValues().forEach {
            XCTAssertEqual(Configuration.singlePromptSecureEnclave($0).prettyDescription, "\(Accessibility.whenPasscodeSetThisDeviceOnly) (Single Prompt)")
        }
    }

}
