//  Created by Dan Federman on 9/18/17.
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
#if !os(watchOS)
import LocalAuthentication
#endif

/// Reads and writes keychain elements that are stored on the Secure Enclave using Accessibility attribute `.whenPasscodeSetThisDeviceOnly`. Accessing these keychain elements will require the user to confirm their presence via Touch ID, Face ID, or passcode entry. If no passcode is set on the device, accessing the keychain via a `SecureEnclaveValet` will fail. Data is removed from the Secure Enclave when the user removes a passcode from the device.
@objc(VALSecureEnclaveValet)
public final class SecureEnclaveValet: NSObject {
    
    // MARK: Public Class Methods

    /// - Parameters:
    ///   - identifier: A non-empty string that uniquely identifies a SecureEnclaveValet.
    ///   - accessControl: The desired access control for the SecureEnclaveValet.
    /// - Returns: A SecureEnclaveValet that reads/writes keychain elements with the desired flavor.
    public class func valet(with identifier: Identifier, accessControl: SecureEnclaveAccessControl) -> SecureEnclaveValet {
        let key = Service.standard(identifier, .secureEnclave(accessControl)).description as NSString
        if let existingValet = identifierToValetMap.object(forKey: key) {
            return existingValet
            
        } else {
            let valet = SecureEnclaveValet(identifier: identifier, accessControl: accessControl)
            identifierToValetMap.setObject(valet, forKey: key)
            return valet
        }
    }

    /// - Parameters:
    ///   - identifier: A non-empty string that must correspond with the value for keychain-access-groups in your Entitlements file.
    ///   - accessControl: The desired access control for the SecureEnclaveValet.
    /// - Returns: A SecureEnclaveValet that reads/writes keychain elements that can be shared across applications written by the same development team.
    public class func sharedGroupValet(with identifier: SharedGroupIdentifier, accessControl: SecureEnclaveAccessControl) -> SecureEnclaveValet {
        let key = Service.sharedGroup(identifier, .secureEnclave(accessControl)).description as NSString
        if let existingValet = identifierToValetMap.object(forKey: key) {
            return existingValet
            
        } else {
            let valet = SecureEnclaveValet(sharedAccess: identifier, accessControl: accessControl)
            identifierToValetMap.setObject(valet, forKey: key)
            return valet
        }
    }
    
    // MARK: Equatable
    
    /// - Returns: `true` if lhs and rhs both read from and write to the same sandbox within the keychain.
    public static func ==(lhs: SecureEnclaveValet, rhs: SecureEnclaveValet) -> Bool {
        lhs.service == rhs.service
    }
    
    // MARK: Private Class Properties
    
    private static let identifierToValetMap = NSMapTable<NSString, SecureEnclaveValet>.strongToWeakObjects()
    
    // MARK: Initialization
    
    @available(*, unavailable)
    public override init() {
        fatalError("Use the class methods above to create usable SecureEnclaveValet objects")
    }
    
    private convenience init(identifier: Identifier, accessControl: SecureEnclaveAccessControl) {
        self.init(
            identifier: identifier,
            service: .standard(identifier, .secureEnclave(accessControl)),
            accessControl: accessControl)
    }
    
    private convenience init(sharedAccess groupIdentifier: SharedGroupIdentifier, accessControl: SecureEnclaveAccessControl) {
        self.init(
            identifier: groupIdentifier.asIdentifier,
            service: .sharedGroup(groupIdentifier, .secureEnclave(accessControl)),
            accessControl: accessControl)
    }

    private init(identifier: Identifier, service: Service, accessControl: SecureEnclaveAccessControl) {
        self.identifier = identifier
        self.service = service
        self.accessControl = accessControl
        baseKeychainQuery = service.generateBaseQuery()
    }
    
    // MARK: Hashable
    
    public override var hash: Int {
        service.description.hashValue
    }
    
    // MARK: Public Properties
    
    public let identifier: Identifier
    @objc
    public let accessControl: SecureEnclaveAccessControl
    
    // MARK: Public Methods
    
    /// - Returns: `true` if the keychain is accessible for reading and writing, `false` otherwise.
    /// - Note: Determined by writing a value to the keychain and then reading it back out. Will never prompt the user for Face ID, Touch ID, or password.
    @objc
    public func canAccessKeychain() -> Bool {
        SecureEnclave.canAccessKeychain(with: service)
    }

    /// - Parameters:
    ///   - object: A Data value to be inserted into the keychain.
    ///   - key: A key that can be used to retrieve the `object` from the keychain.
    /// - Throws: An error of type `KeychainError`.
    /// - Important: Inserted data should be no larger than 4kb.
    @objc
    public func setObject(_ object: Data, forKey key: String) throws {
        try execute(in: lock) {
            try SecureEnclave.setObject(object, forKey: key, options: baseKeychainQuery)
        }
    }

    /// - Parameters:
    ///   - key: A key used to retrieve the desired object from the keychain.
    ///   -  userPrompt: The prompt displayed to the user in Apple's Face ID, Touch ID, or passcode entry UI.
    /// - Returns: The data currently stored in the keychain for the provided key.
    /// - Throws: An error of type `KeychainError`.
    @objc
    public func object(forKey key: String, withPrompt userPrompt: String) throws -> Data {
        try execute(in: lock) {
            try SecureEnclave.object(forKey: key, withPrompt: userPrompt, options: baseKeychainQuery)
        }
    }

    /// - Parameter key: The key to look up in the keychain.
    /// - Returns: `true` if a value has been set for the given key, `false` otherwise.
    /// - Throws: An error of type `KeychainError`.
    /// - Note: Will never prompt the user for Face ID, Touch ID, or password.
    public func containsObject(forKey key: String) throws -> Bool {
        try execute(in: lock) {
            try SecureEnclave.containsObject(forKey: key, options: baseKeychainQuery)
        }
    }

    /// - Parameters:
    ///   - string: A String value to be inserted into the keychain.
    ///   - key: A key that can be used to retrieve the `string` from the keychain.
    /// - Throws: An error of type `KeychainError`.
    /// - Important: Inserted data should be no larger than 4kb.
    @objc
    public func setString(_ string: String, forKey key: String) throws {
        try execute(in: lock) {
            try SecureEnclave.setString(string, forKey: key, options: baseKeychainQuery)
        }
    }

    /// - Parameters:
    ///   - key: A key used to retrieve the desired object from the keychain.
    ///   - userPrompt: The prompt displayed to the user in Apple's Face ID, Touch ID, or passcode entry UI.
    /// - Returns: The string currently stored in the keychain for the provided key.
    /// - Throws: An error of type `KeychainError`.
    @objc
    public func string(forKey key: String, withPrompt userPrompt: String) throws -> String {
        try execute(in: lock) {
            try SecureEnclave.string(forKey: key, withPrompt: userPrompt, options: baseKeychainQuery)
        }
    }

    #if !os(watchOS)
    /// Attempts to retrieve the string at the given key, allowing a custom `fallbackTitle` to be specified to be
    /// shown to the user in the case that the biometric authentication fails.
    ///
    /// Not available on watchOS and only available on tvOS 10.0+
    ///
    /// - Parameters:
    ///   - key: A key used to retrieve the desired object from the keychain.
    ///   - userPrompt: The prompt displayed to the user in Apple's Face ID, Touch ID, or passcode entry UI.
    ///   - fallbackTitle:  The title of the fallback button shown to the user after 2 failed retrieval attempts.
    ///                     If the user taps this button, an `SecureEnclaveError.userFallback` will be thrown.
    /// - Returns: The string currently stored in the keychain for the provided key.
    /// - Throws: An error of type `KeychainError` or `SecureEnclaveError`.
    @objc
    @available(tvOS 10.0, *)
    public func string(
        forKey key: String,
        withPrompt userPrompt: String,
        withFallbackTitle fallbackTitle: String
    ) throws -> String {
        try execute(in: lock) {
            try synchronouslyEvaluatePolicy(forKey: key, withPrompt: userPrompt, withFallbackTitle: fallbackTitle)
        }
    }
    #endif

    /// Removes a key/object pair from the keychain.
    /// - Parameter key: A key used to remove the desired object from the keychain.
    /// - Throws: An error of type `KeychainError`.
    @objc
    public func removeObject(forKey key: String) throws {
        try execute(in: lock) {
            try Keychain.removeObject(forKey: key, options: baseKeychainQuery)
        }
    }
    
    /// Removes all key/object pairs accessible by this Valet instance from the keychain.
    /// - Throws: An error of type `KeychainError`.
    @objc
    public func removeAllObjects() throws {
        try execute(in: lock) {
            try Keychain.removeAllObjects(matching: baseKeychainQuery)
        }
    }
    
    /// Migrates objects matching the input query into the receiving SecureEnclaveValet instance.
    /// - Parameters:
    ///   - query: The query with which to retrieve existing keychain data via a call to SecItemCopyMatching.
    ///   - removeOnCompletion: If `true`, the migrated data will be removed from the keychain if the migration succeeds.
    /// - Throws: An error of type `KeychainError` or `MigrationError`.
    /// - Note: The keychain is not modified if an error is thrown.
    @objc
    public func migrateObjects(matching query: [String : AnyHashable], removeOnCompletion: Bool) throws {
        try execute(in: lock) {
            try Keychain.migrateObjects(matching: query, into: baseKeychainQuery, removeOnCompletion: removeOnCompletion)
        }
    }
    
    /// Migrates objects matching the vended keychain query into the receiving SecureEnclaveValet instance.
    /// - Parameters:
    ///   - valet: A Valet whose vended keychain query is used to retrieve existing keychain data via a call to SecItemCopyMatching.
    ///   - removeOnCompletion: If `true`, the migrated data will be removed from the keychfain if the migration succeeds.
    /// - Throws: An error of type `KeychainError` or `MigrationError`.
    /// - Note: The keychain is not modified if an error is thrown.
    @objc
    public func migrateObjects(from valet: Valet, removeOnCompletion: Bool) throws {
        try migrateObjects(matching: valet.baseKeychainQuery, removeOnCompletion: removeOnCompletion)
    }

    // MARK: Renamed Methods
    
    @available(*, unavailable, renamed: "setObject(_:forKey:)")
    public func set(object: Data, forKey key: String) -> Bool { fatalError() }
    
    @available(*, unavailable, renamed: "setString(_:forKey:)")
    public func set(string: String, forKey key: String) -> Bool { fatalError() }

    // MARK: Internal Properties

    /// A provider of an `LAContext` used when needing to manually evaluate an authentication policy
    /// prior to retrieving a value from the keychain in order to allow the evaluation prompt to show a
    /// custom fallback button to the user.  Should always return a new instance of `LAContext` in
    /// practice, but specified as an internal var to allow it to be overridden in tests.
    #if !os(watchOS)
    @available(tvOS 10.0, *)
    internal lazy var authenticationContextProvider: () -> LAContext = { LAContext() }
    #endif

    internal let service: Service

    // MARK: Private Properties

    private let lock = NSLock()
    private let baseKeychainQuery: [String : AnyHashable]

    // MARK: - Private Methods

    /// Synchronously calls `LAContext.evaluatePolicy`, passing the evaluated context
    /// via `kSecUseAuthenticationContext` when querying for the string at the given
    /// key in the secure enclave.
    #if !os(watchOS)
    @available(tvOS 10.0, *)
    private func synchronouslyEvaluatePolicy(
        forKey key: String,
        withPrompt userPrompt: String,
        withFallbackTitle fallbackTitle: String
    ) throws -> String {
        // Use a semaphore to block the thread and perform the evaluation synchronously.
        let semaphore = DispatchSemaphore(value: 0)
        var result: Result<String, Error>?

        let authenticationContext = authenticationContextProvider()
        authenticationContext.localizedFallbackTitle = fallbackTitle
        authenticationContext.evaluatePolicy(
            accessControl.policy,
            localizedReason: userPrompt,
            reply: { success, error in
                if success {
                    do {
                        var keychainQuery = self.baseKeychainQuery
                        keychainQuery[kSecUseAuthenticationContext as String] = authenticationContext
                        let string = try SecureEnclave.string(
                            forKey: key,
                            withPrompt: userPrompt,
                            options: keychainQuery
                        )
                        result = .success(string)

                    } catch {
                        result = .failure(error)
                    }

                } else if let error = error as? LAError {
                    let transformedError = LAErrorTransformer.transform(
                        error: error,
                        accessControl: self.accessControl
                    )
                    switch transformedError {
                    case let .keychain(error):      result = .failure(error)
                    case let .secureEnclave(error): result = .failure(error)
                    }
                }

                semaphore.signal()
            }
        )

        semaphore.wait()

        switch result {
        case let .success(resultString):
            return resultString

        case let .failure(error):
            throw error

        case .none:
            // Unexpected to get here
            throw SecureEnclaveError.internalError
        }
    }
    #endif

}


// MARK: - Objective-C Compatibility


extension SecureEnclaveValet {
    
    // MARK: Public Class Methods
    /// - Parameters:
    ///   - identifier: A non-empty string that uniquely identifies a SecureEnclaveValet.
    ///   - accessControl: The desired access control for the SecureEnclaveValet.
    /// - Returns: A SecureEnclaveValet that reads/writes keychain elements with the desired flavor.
    @objc(valetWithIdentifier:accessControl:)
    public class func 🚫swift_valet(with identifier: String, accessControl: SecureEnclaveAccessControl) -> SecureEnclaveValet? {
        guard let identifier = Identifier(nonEmpty: identifier) else {
            return nil
        }
        return valet(with: identifier, accessControl: accessControl)
    }

    /// - Parameters:
    ///   - appIDPrefix: The application's App ID prefix. This string can be found by inspecting the application's provisioning profile, or viewing the application's App ID Configuration on developer.apple.com. This string must not be empty.
    ///   - identifier: An identifier that cooresponds to a value in keychain-access-groups in the application's Entitlements file. This string must not be empty.
    ///   - accessControl: The desired access control for the SecureEnclaveValet.
    /// - Returns: A SecureEnclaveValet that reads/writes keychain elements that can be shared across applications written by the same development team.
    /// - SeeAlso: https://developer.apple.com/documentation/security/keychain_services/keychain_items/sharing_access_to_keychain_items_among_a_collection_of_apps
    @objc(sharedGroupValetWithAppIDPrefix:sharedGroupIdentifier:accessControl:)
    public class func 🚫swift_sharedGroupValet(appIDPrefix: String, nonEmptyIdentifier identifier: String, accessControl: SecureEnclaveAccessControl) -> SecureEnclaveValet? {
        guard let identifier = SharedGroupIdentifier(appIDPrefix: appIDPrefix, nonEmptyGroup: identifier) else {
            return nil
        }
        return sharedGroupValet(with: identifier, accessControl: accessControl)
    }

    /// - Parameters:
    ///   - groupPrefix: On iOS, iPadOS, watchOS, and tvOS, this prefix must equal "group". On macOS, this prefix is the application's App ID prefix, which can be found by inspecting the application's provisioning profile, or viewing the application's App ID Configuration on developer.apple.com. This string must not be empty.
    ///   - identifier: An identifier that corresponds to a value in com.apple.security.application-groups in the application's Entitlements file. This string must not be empty.
    ///   - accessControl: The desired access control for the SecureEnclaveValet.
    /// - Returns: A SecureEnclaveValet that reads/writes keychain elements that can be shared across applications written by the same development team.
    /// - SeeAlso: https://developer.apple.com/documentation/security/keychain_services/keychain_items/sharing_access_to_keychain_items_among_a_collection_of_apps
    @objc(sharedGroupValetWithGroupPrefix:sharedGroupIdentifier:accessControl:)
    public class func 🚫swift_sharedGroupValet(groupPrefix: String, nonEmptyIdentifier identifier: String, accessControl: SecureEnclaveAccessControl) -> SecureEnclaveValet? {
        guard let identifier = SharedGroupIdentifier(groupPrefix: groupPrefix, nonEmptyGroup: identifier) else {
            return nil
        }
        return sharedGroupValet(with: identifier, accessControl: accessControl)
    }

    /// - Parameter key: The key to look up in the keychain.
    /// - Returns: `true` if a value has been set for the given key, `false` otherwise. Will return `false` if the keychain is not accessible.
    /// - Note: Will never prompt the user for Face ID, Touch ID, or password.
    @available(swift, obsoleted: 1.0)
    @objc(containsObjectForKey:)
    public func 🚫swift_containsObject(forKey key: String) -> Bool {
        guard let containsObject = try? containsObject(forKey: key) else {
            return false
        }
        return containsObject
    }

}

// MARK: - Private Extensions

extension SecureEnclaveAccessControl {

    /// The `LAPolicy` that the `SecureEnclaveAccessControl` corresponds to.
    #if !os(watchOS)
    @available(tvOS 10.0, *)
    fileprivate var policy: LAPolicy {
        switch self {
        case .userPresence, .devicePasscode:
            return .deviceOwnerAuthentication
        case .biometricAny, .biometricCurrentSet:
            if #available(macOSApplicationExtension 10.12.2, *) {
                return .deviceOwnerAuthenticationWithBiometrics
            } else {
                return .deviceOwnerAuthentication
            }
        }
    }
    #endif

}

// MARK: - Internal Types

/// A type that statically takes an `LAError` and a `SecureEnclaveAccessControl`
/// and transforms it to either a `KeychainError` or `SecureEnclaveError`
enum LAErrorTransformer {

    enum TransformedError: Equatable {
        case keychain(KeychainError)
        case secureEnclave(SecureEnclaveError)
    }

    #if !os(watchOS)
    @available(tvOS 10.0, *)
    static func transform(
        error: LAError,
        accessControl: SecureEnclaveAccessControl
    ) -> TransformedError {
        switch (error.code, accessControl) {
        case (.userCancel, _),
             (.systemCancel, _),
             (.authenticationFailed, _),
             (.appCancel, _):
            return .secureEnclave(.userCancelled)

        case (.userFallback, _):
            return .secureEnclave(.userFallback)

        case (.touchIDLockout, _),
             (.invalidContext, _),
             (.notInteractive, _),
             (.biometryNotPaired, _),
             (.biometryDisconnected, _),
             (.watchNotAvailable, _):
            return .secureEnclave(.couldNotAccess)

        // All of these errors imply that the item does not exist in the Keychain
        // because based on the corresponding `SecureEnclaveAccessControl` type,
        // the item would not be able to be stored in the first place without a
        // passcode or biometry support.
        case (.passcodeNotSet, _),
             (.touchIDNotAvailable, .biometricAny),
             (.touchIDNotAvailable, .biometricCurrentSet),
             (.touchIDNotEnrolled, .biometricAny),
             (.touchIDNotEnrolled, .biometricCurrentSet),
             (.biometryNotAvailable, .biometricAny),
             (.biometryNotAvailable, .biometricCurrentSet),
             (.biometryNotEnrolled, .biometricAny),
             (.biometryNotEnrolled, .biometricCurrentSet):
            return .keychain(.itemNotFound)

        // All of these errors with the corresponding `SecureEnclaveAccessControl`
        // type are unexpected because we should be able to fallback to the device
        // passcode.
        case (.touchIDNotAvailable, .devicePasscode),
             (.touchIDNotAvailable, .userPresence),
             (.touchIDNotEnrolled, .devicePasscode),
             (.touchIDNotEnrolled, .userPresence),
             (.biometryNotAvailable, .devicePasscode),
             (.biometryNotAvailable, .userPresence),
             (.biometryNotEnrolled, .devicePasscode),
             (.biometryNotEnrolled, .userPresence):
            return .secureEnclave(.internalError)

        @unknown default:
            return .secureEnclave(.internalError)
        }
    }
    #endif

}
