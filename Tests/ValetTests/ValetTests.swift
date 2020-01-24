//
//  ValetTests.swift
//  Valet
//
//  Created by Eric Muller on 4/25/16.
//  Copyright © 2016 Square, Inc.
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


class ValetTests: XCTestCase
{
    static let identifier = Identifier(nonEmpty: "valet_testing")!
    let valet = Valet.valet(with: identifier, accessibility: .whenUnlocked)

    // MARK: Initialization

    func test_init_createsCorrectBackingService() {
        let identifier = ValetTests.identifier

        Accessibility.allCases.forEach { accessibility in
            let backingService = Valet.valet(with: identifier, accessibility: accessibility).service
            XCTAssertEqual(backingService, Service.standard(identifier, .valet(accessibility)))
        }
    }

    func test_init_createsCorrectBackingService_sharedAccess() {
        let identifier = ValetTests.identifier

        Accessibility.allCases.forEach { accessibility in
            let backingService = Valet.sharedAccessGroupValet(with: identifier, accessibility: accessibility).service
            XCTAssertEqual(backingService, Service.sharedAccessGroup(identifier, .valet(accessibility)))
        }
    }

    func test_init_createsCorrectBackingService_cloud() {
        let identifier = ValetTests.identifier

        CloudAccessibility.allCases.forEach { accessibility in
            let backingService = Valet.iCloudValet(with: identifier, accessibility: accessibility).service
            XCTAssertEqual(backingService, Service.standard(identifier, .iCloud(accessibility)))
        }
    }

    func test_init_createsCorrectBackingService_cloudSharedAccess() {
        let identifier = ValetTests.identifier

        CloudAccessibility.allCases.forEach { accessibility in
            let backingService = Valet.iCloudSharedAccessGroupValet(with: identifier, accessibility: accessibility).service
            XCTAssertEqual(backingService, Service.sharedAccessGroup(identifier, .iCloud(accessibility)))
        }
    }

    // MARK: Equality

    func test_valetsWithSameConfiguration_areEqual()
    {
        let equalValet = Valet.valet(with: valet.identifier, accessibility: valet.accessibility)
        XCTAssertTrue(equalValet == valet)
        XCTAssertTrue(equalValet === valet)
    }

    func test_differentValetFlavorsWithEquivalentConfiguration_areNotEqual()
    {
        let anotherFlavor = Valet.iCloudValet(with: ValetTests.identifier, accessibility: .whenUnlocked)
        XCTAssertFalse(valet == anotherFlavor)
        XCTAssertFalse(valet === anotherFlavor)
    }

    func test_valetsWithDifferingIdentifier_areNotEqual()
    {
        let differingIdentifier = Valet.valet(with: Identifier(nonEmpty: "nope")!, accessibility: valet.accessibility)
        XCTAssertNotEqual(valet, differingIdentifier)
    }

    func test_valetsWithDifferingAccessibility_areNotEqual()
    {
        let differingAccessibility = Valet.valet(with: valet.identifier, accessibility: .whenUnlockedThisDeviceOnly)
        XCTAssertNotEqual(valet, differingAccessibility)
    }

    // MARK: Migration - Query

    func test_migrateObjectsMatching_failsForBadQueries()
    {
        XCTAssertThrowsError(try valet.migrateObjects(matching: [:], removeOnCompletion: false)) { error in
            XCTAssertEqual(error as? MigrationError, .invalidQuery)
        }
        XCTAssertThrowsError(try valet.migrateObjects(matching: [:], removeOnCompletion: true)) { error in
            XCTAssertEqual(error as? MigrationError, .invalidQuery)
        }

        var invalidQuery: [String: AnyHashable] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        // Migration queries should have kSecMatchLimit set to .All
        XCTAssertThrowsError(try valet.migrateObjects(matching: invalidQuery, removeOnCompletion: false)) { error in
            XCTAssertEqual(error as? MigrationError, .invalidQuery)
        }

        invalidQuery = [
            kSecClass as String: kSecClassGenericPassword,
            kSecReturnData as String: kCFBooleanTrue
        ]
        // Migration queries do not support kSecReturnData
        XCTAssertThrowsError(try valet.migrateObjects(matching: invalidQuery, removeOnCompletion: false)) { error in
            XCTAssertEqual(error as? MigrationError, .invalidQuery)
        }

        invalidQuery = [
            kSecClass as String: kSecClassGenericPassword,
            kSecReturnRef as String: kCFBooleanTrue
        ]
        // Migration queries do not support kSecReturnRef
        XCTAssertThrowsError(try valet.migrateObjects(matching: invalidQuery, removeOnCompletion: false)) { error in
            XCTAssertEqual(error as? MigrationError, .invalidQuery)
        }

        invalidQuery = [
            kSecClass as String: kSecClassGenericPassword,
            kSecReturnPersistentRef as String: kCFBooleanFalse
        ]
        // Migration queries must have kSecReturnPersistentRef set to true
        XCTAssertThrowsError(try valet.migrateObjects(matching: invalidQuery, removeOnCompletion: false)) { error in
            XCTAssertEqual(error as? MigrationError, .invalidQuery)
        }


        invalidQuery = [
            kSecClass as String: kSecClassGenericPassword,
            kSecReturnAttributes as String: kCFBooleanFalse
        ]
        // Migration queries must have kSecReturnAttributes set to true
        XCTAssertThrowsError(try valet.migrateObjects(matching: invalidQuery, removeOnCompletion: false)) { error in
            XCTAssertEqual(error as? MigrationError, .invalidQuery)
        }
        
        invalidQuery = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccessControl as String: NSNull()
        ]
        // Migration queries must not have kSecAttrAccessControl set
        XCTAssertThrowsError(try valet.migrateObjects(matching: invalidQuery, removeOnCompletion: false)) { error in
            XCTAssertEqual(error as? MigrationError, .invalidQuery)
        }
    }

}
