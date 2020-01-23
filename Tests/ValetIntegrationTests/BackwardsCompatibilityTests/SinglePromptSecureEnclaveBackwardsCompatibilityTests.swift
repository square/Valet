//
//  SecureEnclaveSinglePromptBackwardsCompatibilityTests.swift
//  Valet
//
//  Created by Dan Federman on 3/3/18.
//  Copyright © 2018 Square, Inc.
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
@testable import Valet
import LegacyValet
import XCTest


@available(tvOS 11.0, *)
extension SinglePromptSecureEnclaveIntegrationTests {

    @available (*, deprecated)
    func test_backwardsCompatibility_withLegacyValet() throws
    {
        guard testEnvironmentIsSigned() && testEnvironmentSupportsWhenPasscodeSet() else {
            return
        }

        let deprecatedValet = VALLegacySinglePromptSecureEnclaveValet(identifier: valet().identifier.description)!
        XCTAssertTrue(deprecatedValet.setString(passcode, forKey: key))
        XCTAssertEqual(passcode, try valet().string(forKey: key, withPrompt: ""))
    }

}
