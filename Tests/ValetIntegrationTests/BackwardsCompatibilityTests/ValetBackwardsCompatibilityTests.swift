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
        switch service {
        case let .sharedGroup(sharedAccessGroupIdentifier, _, _):
            return sharedAccessGroupIdentifier.groupIdentifier
        case let .standard(identifier, _):
            return identifier.description
        #if os(macOS)
        case let .sharedGroupOverride(identifier, _):
            return identifier.groupIdentifier
        case let .standardOverride(identifier, _):
            return identifier.description
        #endif
        }
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
            case .sharedGroup:
                return VALLegacyValet(sharedAccessGroupIdentifier: legacyIdentifier, accessibility: legacyAccessibility)!
            #if os(macOS)
                case .standardOverride,
                     .sharedGroupOverride:
                fatalError("There is no legacy Valet for a service override valet")
            #endif
            }
        case .iCloud:
            switch service {
            case .standard:
                return VALSynchronizableValet(identifier: legacyIdentifier, accessibility: legacyAccessibility)!
            case .sharedGroup:
                return VALSynchronizableValet(sharedAccessGroupIdentifier: legacyIdentifier, accessibility: legacyAccessibility)!
            #if os(macOS)
            case .standardOverride,
                 .sharedGroupOverride:
                fatalError("There is no legacy Valet for a service override valet")
            #endif
            }

        default:
            fatalError()
        }
    }

    // MARK: Permutations

    class func currentAndLegacyPermutations(with identifier: Identifier) -> [(Valet, VALLegacyValet)] {
        permutations(with: identifier).map {
            ($0, $0.legacyValet)
        }
    }

    class func currentAndLegacyPermutations(with identifier: SharedGroupIdentifier) -> [(Valet, VALLegacyValet)] {
        permutations(with: identifier).map {
            ($0, $0.legacyValet)
        }
    }

    class func iCloudCurrentAndLegacyPermutations(with identifier: Identifier) -> [(Valet, VALSynchronizableValet)] {
        iCloudPermutations(with: identifier).map {
            ($0, $0.legacyValet as! VALSynchronizableValet)
        }
    }

    class func iCloudCurrentAndLegacyPermutations(with identifier: SharedGroupIdentifier) -> [(Valet, VALSynchronizableValet)] {
        iCloudPermutations(with: identifier).map {
            ($0, $0.legacyValet as! VALSynchronizableValet)
        }
    }
}

// MARK: - Tests

class ValetBackwardsCompatibilityIntegrationTests: ValetIntegrationTests {

    // MARK: Tests

    func test_backwardsCompatibility_withLegacyValet() throws {
        try Valet.currentAndLegacyPermutations(with: vanillaValet.identifier).forEach { permutation, legacyValet in
            legacyValet.setString(passcode, forKey: key)

            XCTAssertNotNil(legacyValet.string(forKey: key))
            if #available(OSX 10.15, *) {
                #if os(macOS)
                try permutation.migrateObjectsFromPreCatalina()
                #endif
            }
            XCTAssertEqual(legacyValet.string(forKey: key), try permutation.string(forKey: key), "\(permutation) was not able to read from legacy counterpart: \(legacyValet)")
        }
    }

    func test_backwardsCompatibility_withLegacySharedAccessGroupValet() throws {
        guard testEnvironmentIsSigned() else {
            return
        }
        try Valet.currentAndLegacyPermutations(with: Valet.sharedAccessGroupIdentifier).forEach { permutation, legacyValet in
            legacyValet.setString(passcode, forKey: key)

            XCTAssertNotNil(legacyValet.string(forKey: key))
            if #available(OSX 10.15, *) {
                #if os(macOS)
                try permutation.migrateObjectsFromPreCatalina()
                #endif
            }
            XCTAssertEqual(legacyValet.string(forKey: key), try permutation.string(forKey: key), "\(permutation) was not able to read from legacy counterpart: \(legacyValet)")
        }
    }

    func test_migrateObjectsFromAlwaysAccessibleValet_forwardsCompatibility_fromLegacyValet() throws {
        let alwaysAccessibleLegacyValet = VALLegacyValet(identifier: vanillaValet.identifier.description, accessibility: .always)!
        alwaysAccessibleLegacyValet.setString(passcode, forKey: key)

        let valet = Valet.valet(with: vanillaValet.identifier, accessibility: .afterFirstUnlock)
        XCTAssertNoThrow(try valet.migrateObjectsFromAlwaysAccessibleValet(removeOnCompletion: true))
        XCTAssertEqual(try valet.string(forKey: key), passcode)
    }

    func test_migrateObjectsFromAlwaysAccessibleThisDeviceOnlyValet_forwardsCompatibility_fromLegacyValet() throws {
        let alwaysAccessibleLegacyValet = VALLegacyValet(identifier: vanillaValet.identifier.description, accessibility: .alwaysThisDeviceOnly)!
        alwaysAccessibleLegacyValet.setString(passcode, forKey: key)

        let valet = Valet.valet(with: vanillaValet.identifier, accessibility: .afterFirstUnlockThisDeviceOnly)
        XCTAssertNoThrow(try valet.migrateObjectsFromAlwaysAccessibleThisDeviceOnlyValet(removeOnCompletion: true))
        XCTAssertEqual(try valet.string(forKey: key), passcode)
    }

    func test_migrateObjectsFromAlwaysAccessibleValet_forwardsCompatibility_withLegacySharedAccessGroupValet() throws {
        guard testEnvironmentIsSigned() else {
            return
        }
        let alwaysAccessibleLegacyValet = VALLegacyValet(sharedAccessGroupIdentifier: Valet.sharedAccessGroupIdentifier.groupIdentifier, accessibility: .always)!
        alwaysAccessibleLegacyValet.setString(passcode, forKey: key)

        let valet = Valet.sharedGroupValet(with: Valet.sharedAccessGroupIdentifier, accessibility: .afterFirstUnlock)
        XCTAssertNoThrow(try valet.migrateObjectsFromAlwaysAccessibleValet(removeOnCompletion: true))
        XCTAssertEqual(try valet.string(forKey: key), passcode)
    }

    func test_migrateObjectsFromAlwaysAccessibleThisDeviceOnlyValet_forwardsCompatibility_withLegacySharedAccessGroupValet() throws {
        guard testEnvironmentIsSigned() else {
            return
        }
        let alwaysAccessibleLegacyValet = VALLegacyValet(sharedAccessGroupIdentifier: Valet.sharedAccessGroupIdentifier.groupIdentifier, accessibility: .alwaysThisDeviceOnly)!
        alwaysAccessibleLegacyValet.setString(passcode, forKey: key)

        let valet = Valet.sharedGroupValet(with: Valet.sharedAccessGroupIdentifier, accessibility: .afterFirstUnlockThisDeviceOnly)
        XCTAssertNoThrow(try valet.migrateObjectsFromAlwaysAccessibleThisDeviceOnlyValet(removeOnCompletion: true))
        XCTAssertEqual(try valet.string(forKey: key), passcode)
    }

}
