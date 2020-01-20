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


class KeychainErrorTests: XCTestCase {

    func test_initStatus_createsNotFoundErrorFrom_errSecItemNotFound() {
        XCTAssertEqual(KeychainError(status: errSecItemNotFound), KeychainError.itemNotFound)
    }

    func test_initStatus_createsUserCancelledFrom_errSecUserCanceled() {
        XCTAssertEqual(KeychainError(status: errSecUserCanceled), KeychainError.userCancelled)
    }

    func test_initStatus_createsUserCancelledFrom_errSecAuthFailed() {
        XCTAssertEqual(KeychainError(status: errSecAuthFailed), KeychainError.userCancelled)
    }

    func test_initStatus_createsMissingEntitlementFrom_errSecMissingEntitlement() {
        XCTAssertEqual(KeychainError(status: errSecMissingEntitlement), KeychainError.missingEntitlement)
    }

    func test_initStatus_createsCouldNotAccessKeychainFrom_errSecNotAvailable() {
        XCTAssertEqual(KeychainError(status: errSecNotAvailable), KeychainError.couldNotAccessKeychain)
    }

    func test_description_createsHumanReadableDescription() {
        KeychainError.allCases.forEach {
            switch $0 {
            case .couldNotAccessKeychain:
                XCTAssertEqual($0.description, "KeychainError.couldNotAccessKeychain")
            case .emptyKey:
                XCTAssertEqual($0.description, "KeychainError.emptyKey")
            case .emptyValue:
                XCTAssertEqual($0.description, "KeychainError.emptyValue")
            case .itemNotFound:
                XCTAssertEqual($0.description, "KeychainError.itemNotFound")
            case .missingEntitlement:
                XCTAssertEqual($0.description, "KeychainError.missingEntitlement")
            case .userCancelled:
                XCTAssertEqual($0.description, "KeychainError.userCancelled")
            }

        }
    }
}
