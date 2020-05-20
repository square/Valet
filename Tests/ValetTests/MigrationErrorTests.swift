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


final class MigrationErrorTests: XCTestCase {

    func test_description_createsHumanReadableDescription() {
        MigrationError.allCases.forEach {
            switch $0 {
            case .invalidQuery:
                XCTAssertEqual($0.description, "MigrationError.invalidQuery")
            case .keyToMigrateInvalid:
                XCTAssertEqual($0.description, "MigrationError.keyToMigrateInvalid")
            case .dataToMigrateInvalid:
                XCTAssertEqual($0.description, "MigrationError.dataToMigrateInvalid")
            case .duplicateKeyToMigrate:
                XCTAssertEqual($0.description, "MigrationError.duplicateKeyToMigrate")
            case .keyToMigrateAlreadyExistsInValet:
                XCTAssertEqual($0.description, "MigrationError.keyToMigrateAlreadyExistsInValet")
            case .removalFailed:
                XCTAssertEqual($0.description, "MigrationError.removalFailed")
            }
        }
    }
}
