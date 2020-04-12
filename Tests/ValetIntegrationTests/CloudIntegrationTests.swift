//
//  SynchronizableTests.swift
//  Valet iOS Tests
//
//  Created by Dan Federman and Eric Muller on 9/17/17.
//  Copyright © 2017 Square, Inc.
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


class CloudIntegrationTests: XCTestCase
{
    static let identifier = Valet.sharedAccessGroupIdentifier
    static let accessibility = CloudAccessibility.whenUnlocked
    var allPermutations: [Valet] {
        return (testEnvironmentIsSigned()
            ? Valet.iCloudPermutations(with: CloudIntegrationTests.identifier.asIdentifier) + Valet.iCloudPermutations(with: CloudIntegrationTests.identifier)
            : [])
    }
    let key = "key"
    let passcode = "topsecret"
    
    override func setUp()
    {
        super.setUp()

        allPermutations.forEach { testValet in
            do {
                try testValet.removeAllObjects()
            } catch {
                XCTFail("Error removing objects from Valet \(testValet): \(error)")
            }
        }
    }
    
    func test_synchronizableValet_isDistinctFromVanillaValetWithEqualConfiguration() throws
    {
        guard testEnvironmentIsSigned() else {
            return
        }

        let identifier = Identifier(nonEmpty: "DistinctTest")!
        let vanillaValet = Valet.valet(with: identifier, accessibility: .afterFirstUnlock)
        let iCloudValet = Valet.iCloudValet(with: identifier, accessibility: .afterFirstUnlock)

        // Setting
        try iCloudValet.setString("butts", forKey: "cloud")
        XCTAssertEqual("butts", try iCloudValet.string(forKey: "cloud"))
        XCTAssertThrowsError(try vanillaValet.string(forKey: "cloud")) { error in
            XCTAssertEqual(error as? KeychainError, .itemNotFound)
        }
        
        // Removal
        try vanillaValet.setString("snake people", forKey: "millennials")
        try iCloudValet.removeObject(forKey: "millennials")
        XCTAssertEqual("snake people", try vanillaValet.string(forKey: "millennials"))
    }
    
    func test_setStringForKey() throws
    {
        try allPermutations.forEach { valet in
            XCTAssertThrowsError(try valet.string(forKey: key)) { error in
                XCTAssertEqual(error as? KeychainError, .itemNotFound)
            }
            try valet.setString(passcode, forKey: key)
            XCTAssertEqual(passcode, try valet.string(forKey: key))
        }
    }
    
    func test_removeObjectForKey() throws
    {
       try allPermutations.forEach { valet in
            try valet.setString(passcode, forKey: key)
            XCTAssertEqual(passcode, try valet.string(forKey: key))

            try valet.removeObject(forKey: key)
            XCTAssertThrowsError(try valet.string(forKey: key)) { error in
                XCTAssertEqual(error as? KeychainError, .itemNotFound)
            }
        }
    }
    
    // MARK: canAccessKeychain
    
    func test_canAccessKeychain()
    {
        allPermutations.forEach { valet in
            XCTAssertTrue(valet.canAccessKeychain(), "\(valet) could not access keychain.")
        }
    }
}
