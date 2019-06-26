//
//  SinglePromptSecureEnclaveTests.swift
//  Valet
//
//  Created by Eric Muller on 10/1/17.
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
@testable import Valet
import XCTest


class SinglePromptSecureEnclaveTests: XCTestCase
{
    static let identifier = Identifier(nonEmpty: "valet_testing")!
    let valet = SinglePromptSecureEnclaveValet.valet(with: SinglePromptSecureEnclaveTests.identifier, accessControl: .userPresence)

    override func setUp()
    {
        super.setUp()
        
        ErrorHandler.customAssertBody = { _, _, _, _ in
            // Nothing to do here.
        }
    }

    // MARK: Initialization

    func test_init_createsCorrectBackingService() {
        let identifier = ValetTests.identifier

        SecureEnclaveAccessControl.allValues().forEach { accessControl in
            let backingService = SinglePromptSecureEnclaveValet.valet(with: identifier, accessControl: accessControl).service
            XCTAssertEqual(backingService, Service.standard(identifier, .singlePromptSecureEnclave(accessControl)))
        }
    }

    func test_init_createsCorrectBackingService_sharedAccess() {
        let identifier = ValetTests.identifier

        SecureEnclaveAccessControl.allValues().forEach { accessControl in
            let backingService = SinglePromptSecureEnclaveValet.sharedAccessGroupValet(with: identifier, accessControl: accessControl).service
            XCTAssertEqual(backingService, Service.sharedAccessGroup(identifier, .singlePromptSecureEnclave(accessControl)))
        }
    }

    // MARK: Equality
    
    func test_SinglePromptSecureEnclaveValetsWithEqualConfiguration_haveEqualPointers()
    {
        let equivalentValet = SinglePromptSecureEnclaveValet.valet(with: valet.identifier, accessControl: valet.accessControl)
        XCTAssertTrue(valet == equivalentValet)
        XCTAssertTrue(valet === equivalentValet)
    }
}
