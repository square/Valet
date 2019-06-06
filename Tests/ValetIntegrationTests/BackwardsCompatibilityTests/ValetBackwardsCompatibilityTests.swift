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
        case .always: return .always
        case .alwaysThisDeviceOnly: return .alwaysThisDeviceOnly
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
        return permutations(with: identifier, shared: shared).map {
            return ($0, $0.legacyValet)
        }
    }

    class func iCloudCurrentAndLegacyPermutations(with identifier: Identifier, shared: Bool = false) -> [(Valet, VALSynchronizableValet)] {
        return iCloudPermutations(with: identifier, shared: shared).map {
            return ($0, $0.legacyValet as! VALSynchronizableValet)
        }
    }
}

// MARK: - Tests

class ValetBackwardsCompatibilityIntegrationTests: ValetIntegrationTests {

    // MARK: Tests

    func test_backwardsCompatibility_withLegacyValet() {
        Valet.currentAndLegacyPermutations(with: valet.identifier).forEach { permutation, legacyValet in
            legacyValet.setString(passcode, forKey: key)

            XCTAssertNotNil(legacyValet.string(forKey: key))
            XCTAssertEqual(legacyValet.string(forKey: key), permutation.string(forKey: key), "\(permutation) was not able to read from legacy counterpart: \(legacyValet)")
        }
    }

    func test_backwardsCompatibility_withLegacySharedAccessGroupValet() {
        Valet.currentAndLegacyPermutations(with: Valet.sharedAccessGroupIdentifier, shared: true).forEach { permutation, legacyValet in
            legacyValet.setString(passcode, forKey: key)

            XCTAssertNotNil(legacyValet.string(forKey: key))
            XCTAssertEqual(legacyValet.string(forKey: key), permutation.string(forKey: key), "\(permutation) was not able to read from legacy counterpart: \(legacyValet)")
        }
    }

}
