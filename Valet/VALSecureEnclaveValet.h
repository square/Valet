//
//  VALSecureEnclaveValet.h
//  Valet
//
//  Created by Dan Federman on 3/16/15.
//  Copyright 2015 Square, Inc.
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

#import "VALValet.h"


/// Reads and writes keychain elements that are stored on the Secure Enclave (supported on iOS 8.0 or later) using accessibility attribute VALAccessibilityWhenPasscodeSetThisDeviceOnly. Accessing or modifying these items will require the user to confirm their presence via Touch ID or passcode entry. If no passcode is set on the device, the below methods will fail. Data is removed from the Secure Enclave when the user removes a passcode from the device. Use the userPrompt methods to display custom text to the user in Apple's Touch ID and passcode entry UI.
@interface VALSecureEnclaveValet : VALValet

/// Retuns YES if Secure Enclave storage is supported on the current iOS version (8.0 and later).
+ (BOOL)supportsSecureEnclaveKeychainItems;

/// Creates a Valet that reads/writes Secure Enclave keychain elements.
- (instancetype)initWithIdentifier:(NSString *)identifier __attribute__((nonnull(1)));

/// Creates a Valet that reads/writes Secure Enclave keychain elements that can be shared across applications written by the same development team. The sharedAccessGroupIdentifier must correspond with the value for keychain-access-groups in your Entitlements file.
- (instancetype)initWithSharedAccessGroupIdentifier:(NSString *)sharedAccessGroupIdentifier __attribute__((nonnull(1)));

/// Convenience method for inserting data into the keychain with a user prompt. The userPrompt is displayed to the user in Apple's Touch ID and passcode entry UI when updating a value.
- (BOOL)setObject:(NSData *)value forKey:(NSString *)key userPrompt:(NSString *)userPrompt __attribute__((nonnull(1,2)));
/// Convenience method for retreiving data from the keychain with a user prompt. The userPrompt is displayed to the user in Apple's Touch ID and passcode entry UI.
- (NSData *)objectForKey:(NSString *)key userPrompt:(NSString *)userPrompt __attribute__((nonnull(1)));

/// Convenience method for retreiving a string into the keychain with a user prompt. The userPrompt is displayed to the user in Apple's Touch ID and passcode entry UI when updating a value.
- (BOOL)setString:(NSString *)string forKey:(NSString *)key userPrompt:(NSString *)userPrompt __attribute__((nonnull(1,2)));
/// Convenience method for retreiving a string from the keychain with a user prompt. The userPrompt is displayed to the user in Apple's Touch ID and passcode entry UI.
- (NSString *)stringForKey:(NSString *)key userPrompt:(NSString *)userPrompt __attribute__((nonnull(1)));

/// This method is not supported on VALSecureEnclaveValet.
- (NSSet *)allKeys __attribute__((unavailable("VALSecureEnclaveValet does not support -allKeys")));

@end
