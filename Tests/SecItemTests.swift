//
//  SecItemTests.swift
//  Valet
//
//  Created by Dan Federman and Eric Muller on 9/16/17.
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


class SecItemTests: XCTestCase {

    func test_sharedAccessGroupPrefix_findsPrefix() {
        #if os(watchOS) || os(tvOS) || os(iOS)
            // CocoaPods app host DSL does not provide ability to edit the app host settings such
            // the `DEVELOPER TEAM` so for now skip this assertion.
            #if !COCOAPODS
                XCTAssertEqual(SecItem.sharedAccessGroupPrefix, "9XUJ7M53NG")
            #endif
        #elseif os(macOS)
            // Do nothing.
        #else
            // Currently unsupported build configuration. This next line will compile-time error.
            doNotCommentOutThisLine()
        #endif
    }
    
}
