//
//  KeychainUtility.swift
//  Valet
//
//  Created by Dan Federman and Eric Muller on 9/16/17.
//  Copyright © 2017 Square, Inc.
//
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


internal func object(forKey key: String, options: [String : AnyHashable]) -> SecItem.Result<Data, OSStatus> {
    guard !key.isEmpty else {
        ErrorHandler.assertionFailure("Can not set a value with an empty key.")
        return SecItem.Result.error(errSecParam)
    }
    
    var secItemQuery = options
    secItemQuery[kSecAttrAccount as String] = key
    secItemQuery[kSecMatchLimit as String] = kSecMatchLimitOne
    secItemQuery[kSecReturnData as String] = true
    
    return SecItem.copy(matching: secItemQuery)
}

internal func containsObject(forKey key: String, options: [String : AnyHashable]) -> SecItem.Result<Void?, OSStatus> {
    guard !key.isEmpty else {
        ErrorHandler.assertionFailure("Can not set a value with an empty key.")
        return SecItem.Result.error(errSecParam)
    }
    
    var secItemQuery = options
    secItemQuery[kSecAttrAccount as String] = key
    
    return SecItem.copy(matching: secItemQuery)
}


// TODO: The remaining *:options: methods in the VALValet_Protected header should be implemented statically here as we did above.
