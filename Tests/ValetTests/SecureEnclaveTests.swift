//  Created by Dan Federman and Eric Muller on 9/17/17.
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
import XCTest

@testable import Valet


class SecureEnclaveTests: XCTestCase
{
    static let identifier = Identifier(nonEmpty: "valet_testing")!
    let valet = SecureEnclaveValet.valet(with: identifier, accessControl: .userPresence)

    // MARK: Initialization

    func test_init_createsCorrectBackingService() {
        let identifier = ValetTests.identifier

        SecureEnclaveAccessControl.allValues().forEach { accessControl in
            let backingService = SecureEnclaveValet.valet(with: identifier, accessControl: accessControl).service
            XCTAssertEqual(backingService, Service.standard(identifier, .secureEnclave(accessControl)))
        }
    }

    func test_init_createsCorrectBackingService_sharedAccess() {
        let identifier = Valet.sharedAccessGroupIdentifier

        SecureEnclaveAccessControl.allValues().forEach { accessControl in
            let backingService = SecureEnclaveValet.sharedGroupValet(with: identifier, accessControl: accessControl).service
            XCTAssertEqual(backingService, Service.sharedGroup(identifier, nil, .secureEnclave(accessControl)))
        }
    }

    func test_init_createsCorrectBackingService_sharedAccess_withIdentifier() {
        let groupIdentifier = Valet.sharedAccessGroupIdentifier
        let identifier = Identifier(nonEmpty: "id")

        SecureEnclaveAccessControl.allValues().forEach { accessControl in
            let backingService = SecureEnclaveValet.sharedGroupValet(with: groupIdentifier, identifier: identifier, accessControl: accessControl).service
            XCTAssertEqual(backingService, Service.sharedGroup(groupIdentifier, identifier, .secureEnclave(accessControl)))
        }
    }

    // MARK: Equality

    func test_secureEnclaveValetsWithEqualConfiguration_haveEqualPointers()
    {
        let equivalentValet = SecureEnclaveValet.valet(with: valet.identifier, accessControl: valet.accessControl)
        XCTAssertTrue(valet == equivalentValet)
        XCTAssertTrue(valet === equivalentValet)
    }

}
