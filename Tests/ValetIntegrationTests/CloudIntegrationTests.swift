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
            ? Valet.iCloudPermutations(with: CloudIntegrationTests.identifier) + Valet.iCloudPermutations(with: ValetIntegrationTests.identifier, shared: true)
            : [])
    }
    let key = "key"
    let passcode = "topsecret"
    
    override func setUp()
    {
        super.setUp()
        
        ErrorHandler.customAssertBody = { _, _, _, _ in
            // Nothing to do here.
        }

        allPermutations.forEach { testValet in testValet.removeAllObjects() }
    }
    
    func test_synchronizableValet_isDistinctFromVanillaValetWithEqualConfiguration()
    {
        guard testEnvironmentIsSigned() else {
            return
        }

        let identifier = Identifier(nonEmpty: "DistinctTest")!
        let vanillaValet = Valet.valet(with: identifier, accessibility: .afterFirstUnlock)
        let iCloudValet = Valet.iCloudValet(with: identifier, accessibility: .afterFirstUnlock)

        // Setting
        XCTAssertTrue(iCloudValet.set(string: "butts", forKey: "cloud"))
        XCTAssertEqual("butts", iCloudValet.string(forKey: "cloud"))
        XCTAssertNil(vanillaValet.string(forKey: "cloud"))
        
        // Removal
        XCTAssertTrue(vanillaValet.set(string: "snake people", forKey: "millennials"))
        XCTAssertTrue(iCloudValet.removeObject(forKey: "millennials"))
        XCTAssertEqual("snake people", vanillaValet.string(forKey: "millennials"))
    }
    
    func test_setStringForKey()
    {
        allPermutations.forEach { valet in
            XCTAssertNil(valet.string(forKey: key), "\(valet) read item from keychain that should not exist")
            XCTAssertTrue(valet.set(string: passcode, forKey: key), "\(valet) could not set item in keychain")
            XCTAssertEqual(passcode, valet.string(forKey: key))
        }
    }
    
    func test_removeObjectForKey()
    {
        allPermutations.forEach { valet in
            XCTAssertTrue(valet.set(string: passcode, forKey: key), "\(valet) could not set item in keychain")
            XCTAssertEqual(passcode, valet.string(forKey: key), "\(valet) read incorrect value from keychain.")

            XCTAssertTrue(valet.removeObject(forKey: key), "\(valet) did not remove item from keychain.")
            XCTAssertNil(valet.string(forKey: key), "\(valet) found removed item in keychain.")
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
