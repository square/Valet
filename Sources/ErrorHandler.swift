//
//  ErrorHandler.swift
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


public final class ErrorHandler {
    
    // MARK: Public Static Properties
    
    public static var customAssertBody: ((_ condition: Bool, _ message: String, _ file: StaticString, _ line: UInt) -> Void)? = nil

    // MARK: Internal Static Properties

    internal static let defaultAssertBody: (_ condition: Bool, _ message: String, _ file: StaticString, _ line: UInt) -> Void = { condition, message, file, line in
        guard !condition else {
            return
        }
        
        Swift.assertionFailure(message, file: file, line: line)
    }
    
    // MARK: Public Static Methods
    
    public static func assert(_ condition: Bool, _ message: String, file: StaticString = #file, line: UInt = #line) -> Void {
        (ErrorHandler.customAssertBody ?? ErrorHandler.defaultAssertBody)(condition, message, file, line)
    }
    
    public static func assertionFailure(_ message: String, file: StaticString = #file, line: UInt = #line) -> Void {
        assert(false, message, file: file, line: line)
    }
}
