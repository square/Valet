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
    static let identifier = Identifier(nonEmpty: "valet_testing")!
    static let accessibility = CloudAccessibility.whenUnlocked
    let valet = Valet.iCloudValet(with: identifier, accessibility: accessibility)
    let key = "key"
    let passcode = "topsecret"
    
    override func setUp()
    {
        super.setUp()
        
        try? valet.removeAllObjects()
        let identifier = CloudTests.identifier
        let allPermutations = Valet.iCloudPermutations(with: identifier) + Valet.iCloudPermutations(with: identifier, shared: true)
        allPermutations.forEach { testValet in try? testValet.removeAllObjects() }
    }
    
    func test_synchronizableValet_isDistinctFromVanillaValetWithEqualConfiguration() throws
    {
        guard testEnvironmentIsSigned() else {
            return
        }
        
        let localValet = Valet.valet(with: valet.identifier, accessibility: valet.accessibility)

        // Setting
        try valet.set(string: "butts", forKey: "cloud")
        XCTAssertEqual("butts", try valet.string(forKey: "cloud"))
        XCTAssertThrowsError(try localValet.string(forKey: "cloud")) { error in
            XCTAssertEqual(error as? KeychainError, .itemNotFound)
        }
        
        // Removal
        try localValet.set(string: "snake people", forKey: "millennials")
        try valet.removeObject(forKey: "millennials")
        XCTAssertEqual("snake people", try localValet.string(forKey: "millennials"))
    }
    
    func test_setStringForKey() throws
    {
        guard testEnvironmentIsSigned() else {
            return
        }

        XCTAssertThrowsError(try valet.string(forKey: key)) { error in
            XCTAssertEqual(error as? KeychainError, .itemNotFound)
        }
        try valet.set(string: passcode, forKey: key)
        XCTAssertEqual(passcode, try valet.string(forKey: key))
    }
    
    func test_removeObjectForKey() throws
    {
        guard testEnvironmentIsSigned() else {
            return
        }
        
        try valet.set(string: passcode, forKey: key)
        XCTAssertEqual(passcode, try valet.string(forKey: key))
        
        try valet.removeObject(forKey: key)
        XCTAssertThrowsError(try valet.string(forKey: key)) { error in
            XCTAssertEqual(error as? KeychainError, .itemNotFound)
        }
    }
    
    // MARK: canAccessKeychain
    
    func test_canAccessKeychain()
    {
        guard testEnvironmentIsSigned() else {
            return
        }
        
        Valet.iCloudPermutations(with: valet.identifier).forEach { permutation in
            XCTAssertTrue(permutation.canAccessKeychain(), "\(permutation) could not access keychain.")
        }
    }
    
    func test_canAccessKeychain_sharedAccessGroup()
    {
        guard testEnvironmentIsSigned() else {
            return
        }
        
        Valet.iCloudPermutations(with: Valet.sharedAccessGroupIdentifier, shared: true).forEach { permutation in
            XCTAssertTrue(permutation.canAccessKeychain(), "\(permutation) could not access keychain.")
        }
    }    
}
