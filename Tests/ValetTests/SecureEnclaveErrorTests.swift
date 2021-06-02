//  Created by Allison Moyer on 6/1/21.
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

final class SecureEnclaveErrorTests: XCTestCase {

    // MARK: - Tests - Description

    func test_description_createsHumanReadableDescription() {
        SecureEnclaveError.allCases.forEach {
            switch $0 {
            case .couldNotAccess:
                XCTAssertEqual($0.description, "SecureEnclaveError.couldNotAccess")
            case .userCancelled:
                XCTAssertEqual($0.description, "SecureEnclaveError.userCancelled")
            case .userFallback:
                XCTAssertEqual($0.description, "SecureEnclaveError.userFallback")
            case .passcodeNotSet:
                XCTAssertEqual($0.description, "SecureEnclaveError.passcodeNotSet")
            case .internalError:
                XCTAssertEqual($0.description, "SecureEnclaveError.internalError")
            }

        }
    }

}
