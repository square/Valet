//
//  SecureEnclaveValet.swift
//  Valet
//
//  Created by Dan Federman on 9/18/17.
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


/// Reads and writes keychain elements that are stored on the Secure Enclave using Accessibility attribute `.whenPasscodeSetThisDeviceOnly`. Accessing these keychain elements will require the user to confirm their presence via Touch ID, Face ID, or passcode entry. If no passcode is set on the device, accessing the keychain via a `SecureEnclaveValet` will fail. Data is removed from the Secure Enclave when the user removes a passcode from the device.
public final class SecureEnclaveValet: NSObject, KeychainQueryConvertible {
    
    // MARK: Flavor
    
    public enum Flavor {
        /// Can read multiple items from the Secure Enclave with only a single user-presence prompt to retrieve multiple items.
        case singlePrompt(SecureEnclaveAccessControl)
        /// Requires a user-presence prompt to retrieve each item in the Secure Enclave.
        case alwaysPrompt(SecureEnclaveAccessControl)
    }
    
    // MARK: Public Class Methods
    
    /// - parameter identifier: A non-empty string that uniquely identifies a SecureEnclaveValet.
    /// - parameter flavor: A description of the SecureEnclaveValet's capabilities.
    /// - returns: A SecureEnclaveValet that reads/writes keychain elements with the desired flavor.
    public class func valet(with identifier: Identifier, of flavor: Flavor) -> SecureEnclaveValet {
        let key = Service.standard(identifier, .secureEnclave(flavor)).description as NSString
        if let existingValet = identifierToValetMap.object(forKey: key) {
            return existingValet
            
        } else {
            let valet = SecureEnclaveValet(identifier: identifier, flavor: flavor)
            identifierToValetMap.setObject(valet, forKey: key)
            return valet
        }
    }
    
    /// - parameter identifier: A non-empty string that must correspond with the value for keychain-access-groups in your Entitlements file.
    /// - parameter flavor: A description of the SecureEnclaveValet's capabilities.
    /// - returns: A SecureEnclaveValet that reads/writes keychain elements that can be shared across applications written by the same development team.
    public class func sharedAccessGroupValet(with identifier: Identifier, of flavor: Flavor) -> SecureEnclaveValet {
        let key = Service.standard(identifier, .secureEnclave(flavor)).description as NSString
        if let existingValet = identifierToValetMap.object(forKey: key) {
            return existingValet
            
        } else {
            let valet = SecureEnclaveValet(sharedAccess: identifier, flavor: flavor)
            identifierToValetMap.setObject(valet, forKey: key)
            return valet
        }
    }
    
    // MARK: Equatable
    
    /// - returns: `true` if lhs and rhs both read from and write to the same sandbox within the keychain.
    public static func ==(lhs: SecureEnclaveValet, rhs: SecureEnclaveValet) -> Bool {
        return lhs.service == rhs.service
    }
    
    // MARK: Private Class Properties
    
    private static let identifierToValetMap = NSMapTable<NSString, SecureEnclaveValet>.strongToWeakObjects()
    
    // MARK: Initialization
    
    @available(*, deprecated)
    public override init() {
        fatalError("Do not use this initializer")
    }
    
    private init(identifier: Identifier, flavor: Flavor) {
        service = .standard(identifier, .secureEnclave(flavor))
        keychainQuery = service.baseQuery
        self.flavor = flavor
        self.identifier = identifier
    }
    
    private init(sharedAccess identifier: Identifier, flavor: Flavor) {
        service = .sharedAccessGroup(identifier, .secureEnclave(flavor))
        keychainQuery = service.baseQuery
        self.flavor = flavor
        self.identifier = identifier
    }
    
    // MARK: KeychainQueryConvertible
    
    public let keychainQuery: [String : AnyHashable]
    
    // MARK: Hashable
    
    public override var hashValue: Int {
        return service.description.hashValue
    }
    
    // MARK: Public Properties
    
    public let identifier: Identifier
    public let flavor: Flavor
    
    // MARK: Private Properties
    
    private let service: Service
    private let lock = NSLock()
}


// Use the `userPrompt` methods to display custom text to the user in Apple's Touch ID, Face ID, and passcode entry UI.
