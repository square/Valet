//
//  Identifier.swift
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


public struct Identifier: CustomStringConvertible {
    
    // MARK: Initialization
    
    public init?(nonEmpty string: String?) {
        guard let string = string, !string.isEmpty else {
            return nil
        }
        
        backingString = string
    }
    
    // MARK: CustomStringConvertible
    
    public var description: String {
        return backingString
    }
    
    // MARK: Private Properties
    
    private let backingString: String
}
