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
import Valet
import XCTest


@available (iOS 8.2, OSX 10.11, *)
class ValetSynchronizableTests: XCTestCase
{
    static let identifier = Identifier(nonEmpty: "valet_testing")!
    static let accessibility = CloudAccessibility.whenUnlocked
    let valet = Valet.valet(with: identifier, of: Valet.Flavor.iCloud(ValetSynchronizableTests.accessibility))
    let key = "key"
    let passcode = "topsecret"
    
    override func setUp()
    {
        super.setUp()
        
        ErrorHandler.customAssertBody = { _, _, _, _ in
            // Nothing to do here.
        }
        
        valet.removeAllObjects()
    }
    
    func test_synchronizableValet_isDistinctFromVanillaValetWithEqualConfiguration()
    {
        let localValet = Valet.valet(with: valet.identifier, of: Valet.Flavor.vanilla(valet.accessibility))
        XCTAssertFalse(valet == localValet)
        XCTAssertFalse(valet === localValet)
        
        // Setting
        XCTAssertTrue(valet.set(string: "butts", for: "cloud"))
        XCTAssertEqual("butts", valet.string(for: "cloud"))
        XCTAssertNil(localValet.string(for: "cloud"))
        
        // Removal
        XCTAssertTrue(localValet.set(string: "snake people", for: "millennials"))
        XCTAssertTrue(valet.removeObject(for: "millennials"))
        XCTAssertEqual("snake people", localValet.string(for: "millennials"))
    }
    
    func test_synchronizableValets_withEquivalentConfigurationsAreEqual() {
        let otherValet = Valet.valet(with: valet.identifier, of: valet.flavor)
        XCTAssert(valet == otherValet)
        XCTAssert(valet === otherValet)
    }
    
    func test_setStringForKey()
    {
        XCTAssertNil(valet.string(for: key))
        XCTAssertTrue(valet.set(string: passcode, for: key))
        XCTAssertEqual(passcode, valet.string(for: key))
    }
    
    func test_removeObjectForKey()
    {
        XCTAssertTrue(valet.set(string: passcode, for: key))
        XCTAssertEqual(passcode, valet.string(for: key))
        
        XCTAssertTrue(valet.removeObject(for: key))
        XCTAssertNil(valet.string(for: key))
    }
    
    // MARK: Backwards Compatibility
    
    func test_backwardsCompatibilityWithObjectiveCValet() {
        XCTAssert(valet.accessibility == .whenUnlocked)
        let legacyValet = VALSynchronizableValet(identifier: valet.identifier.description, accessibility: VALAccessibility.whenUnlocked)!
        
        let key = "yo"
        legacyValet.setString("dawg", forKey: key)
        
        XCTAssertEqual(legacyValet.string(forKey: "yo"), valet.string(for: key))
    }
}
