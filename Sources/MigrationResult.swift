//
//  MigrationResult.swift
//  Valet
//
//  Created by Dan Federman and Eric Muller on 9/16/17.
//  Copyright © 2017 Square Inc.
//
//  Licensed under the Apache License Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing software
//  distributed under the License is distributed on an "AS IS" BASIS
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import Foundation

@objc(VALMigrationResult)
public enum MigrationResult: Int, Equatable {
    /// Migration succeeded.
    case success = 1
    /// Migration failed because the keychain query was not valid.
    case invalidQuery
    /// Migration failed because no items to migrate were found.
    case noItemsToMigrateFound
    /// Migration failed because the keychain could not be read.
    case couldNotReadKeychain
    /// Migration failed because a key in the query result could not be read.
    case keyInQueryResultInvalid
    /// Migration failed because some data in the query result could not be read.
    case dataInQueryResultInvalid
    /// Migration failed because two keys with the same value were found in the keychain.
    case duplicateKeyInQueryResult
    /// Migration failed because a key in the keychain duplicates a key already managed by Valet.
    case keyInQueryResultAlreadyExistsInValet
    /// Migration failed because writing to the keychain failed.
    case couldNotWriteToKeychain
    /// Migration failed because removing the migrated data from the keychain failed.
    case removalFailed
}
