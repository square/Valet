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


// The iPhone simulator fakes entitlements, allowing us to test the iCloud Keychain (VALSynchronizableValet) code without writing a signed host app.
#if (arch(i386) || arch(x86_64)) && os(iOS)
    
    @available (iOS 8.2, OSX 10.11, *)
    class ValetSynchronizableTests: XCTestCase
    {
        static let identifier = "valet_testing"
        let valet = VALSynchronizableValet(identifier: identifier, accessibility: .whenUnlocked)!
        let key = "key"
        let passcode = "topsecret"
        
        override func setUp()
        {
            super.setUp()
            valet.removeAllObjects()
        }
        
        func test_initializers_withDeviceScopeAreUnsupported()
        {
            XCTAssertNil(VALSynchronizableValet(identifier: valet.identifier, accessibility: .whenUnlockedThisDeviceOnly))
            XCTAssertNil(VALSynchronizableValet(identifier: valet.identifier, accessibility: .afterFirstUnlockThisDeviceOnly))
            XCTAssertNil(VALSynchronizableValet(identifier: valet.identifier, accessibility: .whenPasscodeSetThisDeviceOnly))
            XCTAssertNil(VALSynchronizableValet(identifier: valet.identifier, accessibility: .alwaysThisDeviceOnly))
        }
        
        func test_synchronizableValet_isDistinctFromVanillaValetWithEqualConfiguration()
        {
            let localValet = VALValet(identifier: valet.identifier, accessibility: valet.accessibility)!
            XCTAssertFalse(valet == localValet)
            XCTAssertFalse(valet === localValet)
            
            // Setting
            XCTAssertTrue(valet.setString("butts", forKey: "cloud"))
            XCTAssertEqual("butts", valet.string(forKey: "cloud"))
            XCTAssertNil(localValet.string(forKey: "cloud"))
            
            // Removal
            XCTAssertTrue(localValet.setString("snake people", forKey: "millennials"))
            XCTAssertTrue(valet.removeObject(forKey: "millennials"))
            XCTAssertEqual("snake people", localValet.string(forKey: "millennials"))
        }
        
        func test_setStringForKey()
        {
            XCTAssertNil(valet.string(forKey: key))
            XCTAssertTrue(valet.setString(passcode, forKey: key))
            XCTAssertEqual(passcode, valet.string(forKey: key))
        }
        
        func test_removeObjectForKey()
        {
            XCTAssertTrue(valet.setString(passcode, forKey:key))
            XCTAssertEqual(passcode, valet.string(forKey: key))
            
            XCTAssertTrue(valet.removeObject(forKey: key))
            XCTAssertNil(valet.string(forKey: key))
        }
    }
    
#endif
