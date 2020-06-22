//
//  KeychainIntegrationTests.swift
//  Valet iOS
//
//  Created by Dan Federman on 5/20/20.
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


final class KeychainIntegrationTests: XCTestCase {

    func test_revertMigration_removesAllMigratedKeys() throws {
        try XCTSkipUnless(testEnvironmentIsSigned())

        let migrationValet = Valet.valet(with: Identifier(nonEmpty: "Migrate_Me")!, accessibility: .afterFirstUnlock)
        try migrationValet.removeAllObjects()

        let anotherValet = Valet.valet(with: Identifier(nonEmpty: #function)!, accessibility: .whenUnlocked)
        try anotherValet.removeAllObjects()

        let keyValuePairsToMigrate = [
            "yo": "dawg",
            "we": "heard",
            "you": "like",
            "migrating": "to",
            "other": "valets"
        ]

        for (key, value) in keyValuePairsToMigrate {
            try migrationValet.setString(value, forKey: key)
        }

        try anotherValet.setString("password", forKey: "accountName")
        try anotherValet.migrateObjects(from: migrationValet, removeOnCompletion: false)
        Keychain.revertMigration(into: anotherValet.baseKeychainQuery, keysInKeychainPreMigration: Set(["accountName"]))

        XCTAssertEqual(try anotherValet.allKeys().count, 1)
        XCTAssertEqual(try anotherValet.string(forKey: "accountName"), "password")
    }

}
