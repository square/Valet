//
//  SynchronizableTests.swift
//  Valet iOS Tests
//
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


class CloudTests: XCTestCase
{
    static let identifier = Identifier(nonEmpty: "valet_testing")!
    static let accessibility = CloudAccessibility.whenUnlocked
    let valet = Valet.iCloudValet(with: identifier, accessibility: accessibility)

    override func setUp()
    {
        super.setUp()
        
        ErrorHandler.customAssertBody = { _, _, _, _ in
            // Nothing to do here.
        }
    }

    // MARK: Equality

    func test_synchronizableValet_isDistinctFromVanillaValetWithEqualConfiguration()
    {
        let localValet = Valet.valet(with: valet.identifier, accessibility: valet.accessibility)
        XCTAssertFalse(valet == localValet)
        XCTAssertFalse(valet === localValet)
    }

    func test_synchronizableValets_withEquivalentConfigurationsAreEqual() {
        guard case let .iCloud(accessibility) = valet.configuration else {
            XCTFail()
            return
        }
        let otherValet = Valet.iCloudValet(with: valet.identifier, accessibility: accessibility)
        XCTAssertEqual(valet, otherValet, "Valet should be equal to otherValet")
        XCTAssertTrue(valet === otherValet, "Valet and otherValet should be the same object")
    }
}
