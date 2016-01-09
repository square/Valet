//
//  Created by Nic Wise on 9/01/16.
//  Copyright 2016 Square, Inc.
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

#import <Foundation/Foundation.h>
#import "VALSecureEnclaveValet.h"

typedef NS_ENUM(NSUInteger, VALTouchIdSensitivity) {
    /// Valet data can only be accessed with a fingerprint, not the device PIN
            VALTouchIdFingerPrintAny __OSX_AVAILABLE_STARTING(__MAC_10_10, __IPHONE_9_0) = 1,
    /// Valet data can only be accessed with _the current set_ of fingerprints, and never the pin
            VALTouchIdFingerPrintCurrentSetOnly __OSX_AVAILABLE_STARTING(__MAC_10_10, __IPHONE_9_0)
};


/// Reads and writes keychain elements that are stored on the Secure Enclave
// (supported on iOS 8.0 or later) using accessibility attribute VALAccessibilityWhenPasscodeSetThisDeviceOnly.
// Accessing or modifying these items will require the user to confirm their presence via Touch ID or passcode entry.
// If no passcode is set on the device, the below methods will fail.
// Data is removed from the Secure Enclave when the user removes a passcode from the device.
// Use the userPrompt methods to display custom text to the user in Apple's Touch ID and passcode entry UI.
//
//
// Extends the base VALSecureEnclaveValet to disallow the fallback to PIN, and to control invalidating the
// item when the fingerprint list changes.
NS_CLASS_AVAILABLE_IOS(9_0)
@interface VALSecureEnclaveBiometricValet : VALSecureEnclaveValet

/// Creates a Valet that reads/writes Secure Enclave keychain elements.
- (nullable instancetype)initWithIdentifier:(nonnull NSString *)identifier sensitivity:(VALTouchIdSensitivity)sensitivity;

/// Creates a Valet that reads/writes Secure Enclave keychain elements that can be shared across applications written by the same development team.
/// @param sharedAccessGroupIdentifier This must correspond with the value for keychain-access-groups in your Entitlements file.
- (nullable instancetype)initWithSharedAccessGroupIdentifier:(nonnull NSString *)sharedAccessGroupIdentifier sensitivity:(VALTouchIdSensitivity)sensitivity;



@end
