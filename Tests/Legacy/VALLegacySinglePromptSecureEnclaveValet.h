//
//  VALLegacySinglePromptSecureEnclaveValet.h
//  Valet
//
//  Created by Dan Federman on 1/23/17.
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

#import "VALLegacySecureEnclaveValet.h"


/// Reads and writes keychain elements that are stored on the Secure Enclave (available on iOS 8.0 and later and macOS 10.11 and later) using accessibility attribute VALLegacyAccessibilityWhenPasscodeSetThisDeviceOnly. The first access of these keychain elements will require the user to confirm their presence via Touch ID or passcode entry.
/// @see VALLegacySecureEnclaveValet
/// @version Available on iOS 8 or later, and macOS 10.11 or later.
@interface VALLegacySinglePromptSecureEnclaveValet : VALLegacySecureEnclaveValet

/// Forces a prompt for Touch ID or passcode entry on the next data retrieval from the Secure Enclave.
- (void)requirePromptOnNextAccess;

@end
