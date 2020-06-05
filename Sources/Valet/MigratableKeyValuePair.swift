//
//  MigratableKeyValuePair.swift
//  Valet
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

/// A struct that represented a key:value pair that can be migrated.
public struct MigratableKeyValuePair<Key: Hashable>: Hashable {

    // MARK: Initialization

    /// Creates a migratable key:value pair with the provided inputs.
    /// - Parameters:
    ///   - key: The key in the key:value pair.
    ///   - value: The value in the key:value pair.
    public init(key: Key, value: Data) {
        self.key = key
        self.value = value
    }

    /// Creates a migratable key:value pair with the provided inputs.
    /// - Parameters:
    ///   - key: The key in the key:value pair.
    ///   - value: The desired value in the key:value pair, represented as a String.
    public init(key: Key, value: String) {
        self.key = key
        self.value = Data(value.utf8)
    }

    // MARK: Public

    /// The key in the key:value pair.
    public let key: Key
    /// The value in the key:value pair.
    public let value: Data
}

// MARK: - Objective-C Compatibility

@objc(VALMigratableKeyValuePairInput)
public final class ObjectiveCCompatibilityMigratableKeyValuePairInput: NSObject {

    // MARK: Initialization

    internal init(key: Any, value: Data) {
        self.key = key
        self.value = value
    }

    // MARK: Public

    /// The key in the key:value pair.
    @objc
    public let key: Any
    /// The value in the key:value pair.
    @objc
    public let value: Data
}

@objc(VALMigratableKeyValuePairOutput)
public class ObjectiveCCompatibilityMigratableKeyValuePairOutput: NSObject {

    // MARK: Initialization

    /// Creates a migratable key:value pair with the provided inputs.
    /// - Parameters:
    ///   - key: The key in the key:value pair.
    ///   - value: The value in the key:value pair.
    @objc
    public init(key: String, value: Data) {
        self.key = key
        self.value = value
        preventMigration = false
    }

    /// Creates a migratable key:value pair with the provided inputs.
    /// - Parameters:
    ///   - key: The key in the key:value pair.
    ///   - stringValue: The desired value in the key:value pair, represented as a String.
    @objc
    public init(key: String, stringValue: String) {
        self.key = key
        self.value = Data(stringValue.utf8)
        preventMigration = false
    }

    // MARK: Public Static Methods

    /// A sentinal `ObjectiveCCompatibilityMigratableKeyValuePairOutput` that conveys that the migration should be prevented.
    @available(swift, obsoleted: 1.0)
    @objc
    public static func preventMigration() -> ObjectiveCCompatibilityMigratableKeyValuePairOutput {
        ObjectiveCCompatibilityPreventMigrationOutput()
    }

    // MARK: Public

    /// The key in the key:value pair.
    @objc
    public let key: String
    /// The value in the key:value pair.
    @objc
    public let value: Data

    // MARK: Internal

    internal fileprivate(set) var preventMigration: Bool

}

private final class ObjectiveCCompatibilityPreventMigrationOutput: ObjectiveCCompatibilityMigratableKeyValuePairOutput {

    init() {
        super.init(key: "", stringValue: "")
        preventMigration = true
    }

}
