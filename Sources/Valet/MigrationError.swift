//
//  MigrationError.swift
//  Valet
//
//  Created by Dan Federman and Eric Muller on 9/16/17.
//  Copyright © 2017 Square Inc.
//
//  Licensed under the Apache License Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing software
//  distributed under the License is distributed on an "AS IS" BASIS
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import Foundation


@objc(VALMigrationResult)
public enum MigrationError: Int, CaseIterable, CustomStringConvertible, Error, Equatable {
    /// Migration failed because the keychain query was not valid.
    case invalidQuery
    /// Migration failed because a key staged for migration was invalid.
    case keyToMigrateInvalid
    /// Migration failed because some data staged for migration was invalid.
    case dataToMigrateInvalid
    /// Migration failed because two equivalent keys were staged for migration.
    case duplicateKeyToMigrate
    /// Migration failed because a key staged for migration duplicates a key already managed by Valet.
    case keyToMigrateAlreadyExistsInValet
    /// Migration failed because removing the migrated data from the keychain failed.
    case removalFailed

    // MARK: CustomStringConvertible

    public var description: String {
        switch self {
        case .invalidQuery: return "MigrationError.invalidQuery"
        case .keyToMigrateInvalid: return "MigrationError.keyToMigrateInvalid"
        case .dataToMigrateInvalid: return "MigrationError.dataToMigrateInvalid"
        case .duplicateKeyToMigrate: return "MigrationError.duplicateKeyToMigrate"
        case .keyToMigrateAlreadyExistsInValet: return "MigrationError.keyToMigrateAlreadyExistsInValet"
        case .removalFailed: return "MigrationError.removalFailed"
        }
    }
}
