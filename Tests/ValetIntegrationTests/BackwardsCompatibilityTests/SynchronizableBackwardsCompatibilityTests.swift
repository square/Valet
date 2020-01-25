//
//  SynchronizableBackwardsCompatibilityTests.swift
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


//extension CloudIntegrationTests {
//
//    // MARK: Backwards Compatibility
//
//    func test_backwardsCompatibility_withLegacyValet() {
//        guard testEnvironmentIsSigned() else {
//            return
//        }
//
//        let identifier = Identifier(nonEmpty: "BackwardsCompatibilityTest")!
//        Valet.iCloudCurrentAndLegacyPermutations(with: identifier).forEach { permutation, legacyValet in
//            legacyValet.setString(passcode, forKey: key)
//
//            XCTAssertNotNil(legacyValet.string(forKey: key))
//            XCTAssertEqual(legacyValet.string(forKey: key), permutation.string(forKey: key), "\(permutation) was not able to read from legacy counterpart: \(legacyValet)")
//        }
//    }
//
//    func test_backwardsCompatibility_withSharedAccessGroupLegacyValet() {
//        guard testEnvironmentIsSigned() else {
//            return
//        }
//
//        Valet.iCloudCurrentAndLegacyPermutations(with: Valet.sharedAccessGroupIdentifier, shared: true).forEach { permutation, legacyValet in
//            legacyValet.setString(passcode, forKey: key)
//
//            XCTAssertNotNil(legacyValet.string(forKey: key))
//            XCTAssertEqual(legacyValet.string(forKey: key), permutation.string(forKey: key), "\(permutation) was not able to read from legacy counterpart: \(legacyValet)")
//        }
//    }
//  
//}
