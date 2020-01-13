//
//  ValetBackwardsCompatibilityTests.swift
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


// MARK: – Backwards Compatibility Extensions


internal extension Valet {

    var legacyIdentifier: String {
        return identifier.description
    }

    var legacyAccessibility: VALLegacyAccessibility {
        switch accessibility {
        case .afterFirstUnlock: return .afterFirstUnlock
        case .afterFirstUnlockThisDeviceOnly: return .afterFirstUnlockThisDeviceOnly
        case .whenPasscodeSetThisDeviceOnly: return .whenPasscodeSetThisDeviceOnly
        case .whenUnlocked: return .whenUnlocked
        case .whenUnlockedThisDeviceOnly: return .whenUnlockedThisDeviceOnly
        }
    }

    var legacyValet: VALLegacyValet {
        switch configuration {
        case .valet:
            switch service {
            case .standard:
                return VALLegacyValet(identifier: legacyIdentifier, accessibility: legacyAccessibility)!
            case .sharedAccessGroup:
                return VALLegacyValet(sharedAccessGroupIdentifier: legacyIdentifier, accessibility: legacyAccessibility)!
            }
        case .iCloud:
            switch service {
            case .standard:
                return VALSynchronizableValet(identifier: legacyIdentifier, accessibility: legacyAccessibility)!
            case .sharedAccessGroup:
                return VALSynchronizableValet(sharedAccessGroupIdentifier: legacyIdentifier, accessibility: legacyAccessibility)!
            }

        default:
            fatalError()
        }
    }

    // MARK: Permutations

    class func currentAndLegacyPermutations(with identifier: Identifier, shared: Bool = false) -> [(Valet, VALLegacyValet)] {
        permutations(with: identifier, shared: shared).map {
            ($0, $0.legacyValet)
        }
    }

    class func iCloudCurrentAndLegacyPermutations(with identifier: Identifier, shared: Bool = false) -> [(Valet, VALSynchronizableValet)] {
        iCloudPermutations(with: identifier, shared: shared).map {
            ($0, $0.legacyValet as! VALSynchronizableValet)
        }
    }
}

// MARK: - Tests

class ValetBackwardsCompatibilityIntegrationTests: ValetIntegrationTests {

    // MARK: Tests

    func test_backwardsCompatibility_withLegacyValet() {
        Valet.currentAndLegacyPermutations(with: vanillaValet.identifier).forEach { permutation, legacyValet in
            legacyValet.setString(passcode, forKey: key)

            XCTAssertNotNil(legacyValet.string(forKey: key))
            XCTAssertEqual(legacyValet.string(forKey: key), permutation.string(forKey: key), "\(permutation) was not able to read from legacy counterpart: \(legacyValet)")
        }
    }

    func test_backwardsCompatibility_withLegacySharedAccessGroupValet() {
        guard testEnvironmentIsSigned() else {
            return
        }
        Valet.currentAndLegacyPermutations(with: Valet.sharedAccessGroupIdentifier, shared: true).forEach { permutation, legacyValet in
            legacyValet.setString(passcode, forKey: key)

            XCTAssertNotNil(legacyValet.string(forKey: key))
            XCTAssertEqual(legacyValet.string(forKey: key), permutation.string(forKey: key), "\(permutation) was not able to read from legacy counterpart: \(legacyValet)")
        }
    }

    func test_migrateObjectsFromAlwaysAccessibleValet_forwardsCompatibility_fromLegacyValet() {
        let alwaysAccessibleLegacyValet = VALLegacyValet(identifier: vanillaValet.identifier.description, accessibility: .always)!
        alwaysAccessibleLegacyValet.setString(passcode, forKey: key)

        let valet = Valet.valet(with: vanillaValet.identifier, accessibility: .afterFirstUnlock)
        XCTAssertEqual(valet.migrateObjectsFromAlwaysAccessibleValet(removeOnCompletion: true), .success)
        XCTAssertEqual(valet.string(forKey: key), passcode)
    }

    func test_migrateObjectsFromAlwaysAccessibleThisDeviceOnlyValet_forwardsCompatibility_fromLegacyValet() {
        let alwaysAccessibleLegacyValet = VALLegacyValet(identifier: vanillaValet.identifier.description, accessibility: .alwaysThisDeviceOnly)!
        alwaysAccessibleLegacyValet.setString(passcode, forKey: key)

        let valet = Valet.valet(with: vanillaValet.identifier, accessibility: .afterFirstUnlockThisDeviceOnly)
        XCTAssertEqual(valet.migrateObjectsFromAlwaysAccessibleThisDeviceOnlyValet(removeOnCompletion: true), .success)
        XCTAssertEqual(valet.string(forKey: key), passcode)
    }

    func test_migrateObjectsFromAlwaysAccessibleValet_forwardsCompatibility_withLegacySharedAccessGroupValet() {
        guard testEnvironmentIsSigned() else {
            return
        }
        let alwaysAccessibleLegacyValet = VALLegacyValet(sharedAccessGroupIdentifier: Valet.sharedAccessGroupIdentifier.description, accessibility: .always)!
        alwaysAccessibleLegacyValet.setString(passcode, forKey: key)

        let valet = Valet.sharedAccessGroupValet(with: Valet.sharedAccessGroupIdentifier, accessibility: .afterFirstUnlock)
        XCTAssertEqual(valet.migrateObjectsFromAlwaysAccessibleValet(removeOnCompletion: true), .success)
        XCTAssertEqual(valet.string(forKey: key), passcode)
    }

    func test_migrateObjectsFromAlwaysAccessibleThisDeviceOnlyValet_forwardsCompatibility_withLegacySharedAccessGroupValet() {
        guard testEnvironmentIsSigned() else {
            return
        }
        let alwaysAccessibleLegacyValet = VALLegacyValet(sharedAccessGroupIdentifier: Valet.sharedAccessGroupIdentifier.description, accessibility: .alwaysThisDeviceOnly)!
        alwaysAccessibleLegacyValet.setString(passcode, forKey: key)

        let valet = Valet.sharedAccessGroupValet(with: Valet.sharedAccessGroupIdentifier, accessibility: .afterFirstUnlockThisDeviceOnly)
        XCTAssertEqual(valet.migrateObjectsFromAlwaysAccessibleThisDeviceOnlyValet(removeOnCompletion: true), .success)
        XCTAssertEqual(valet.string(forKey: key), passcode)
    }

}
