//  Created by Dan Federman on 1/16/20.
//  Copyright © 2020 Square, Inc.
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

#import <Valet/Valet.h>
#import <XCTest/XCTest.h>

#if !TARGET_OS_TV

@interface VALSinglePromptSecureEnclaveValetTests : XCTestCase
@end

@implementation VALSinglePromptSecureEnclaveValetTests

- (NSString *)identifier;
{
    return @"identifier";
}

- (NSString *)appIDPrefix;
{
    return @"9XUJ7M53NG";
}

- (NSString *)sharedAccessGroupIdentifier;
{
#if TARGET_OS_IPHONE
    return @"com.squareup.Valet-iOS-Test-Host-App";
#elif TARGET_OS_WATCH
    return @"com.squareup.ValetTouchIDTestApp.watchkitapp.watchkitextension";
#elif TARGET_OS_MAC
    return @"com.squareup.Valet-macOS-Test-Host-App";
#else
    // This will fail
    return @"";
#endif
}

- (NSString *)groupPrefix;
{
#if TARGET_OS_IPHONE
    return @"group";
#elif TARGET_OS_WATCH
    return @"group";
#elif TARGET_OS_MAC
    return self.appIDPrefix;
#else
    // This will fail
    return @"";
#endif
}

- (NSString *)sharedAppGroupIdentifier;
{
    return @"valet.test";
}

- (void)test_valetWithIdentifier_accessControl_returnsCorrectValet_VALSecureEnclaveAccessControlDevicePasscode;
{
    VALSinglePromptSecureEnclaveValet *const valet = [VALSinglePromptSecureEnclaveValet valetWithIdentifier:self.identifier accessControl:VALSecureEnclaveAccessControlDevicePasscode];
    XCTAssertEqual(valet.accessControl, VALSecureEnclaveAccessControlDevicePasscode);
    XCTAssertEqual([valet class], [VALSinglePromptSecureEnclaveValet class]);
}

- (void)test_valetWithIdentifier_accessControl_returnsCorrectValet_VALSecureEnclaveAccessControlUserPresence;
{
    VALSinglePromptSecureEnclaveValet *const valet = [VALSinglePromptSecureEnclaveValet valetWithIdentifier:self.identifier accessControl:VALSecureEnclaveAccessControlUserPresence];
    XCTAssertEqual(valet.accessControl, VALSecureEnclaveAccessControlUserPresence);
    XCTAssertEqual([valet class], [VALSinglePromptSecureEnclaveValet class]);
}

- (void)test_valetWithIdentifier_accessControl_returnsCorrectValet_VALSecureEnclaveAccessControlBiometricAny;
{
    VALSinglePromptSecureEnclaveValet *const valet = [VALSinglePromptSecureEnclaveValet valetWithIdentifier:self.identifier accessControl:VALSecureEnclaveAccessControlBiometricAny];
    XCTAssertEqual(valet.accessControl, VALSecureEnclaveAccessControlBiometricAny);
    XCTAssertEqual([valet class], [VALSinglePromptSecureEnclaveValet class]);
}

- (void)test_valetWithIdentifier_accessControl_returnsCorrectValet_VALSecureEnclaveAccessControlBiometricCurrentSet;
{
    VALSinglePromptSecureEnclaveValet *const valet = [VALSinglePromptSecureEnclaveValet valetWithIdentifier:self.identifier accessControl:VALSecureEnclaveAccessControlBiometricCurrentSet];
    XCTAssertEqual(valet.accessControl, VALSecureEnclaveAccessControlBiometricCurrentSet);
    XCTAssertEqual([valet class], [VALSinglePromptSecureEnclaveValet class]);
}

- (void)test_valetWithIdentifier_accessibility_returnsNilWhenIdentifierIsEmpty;
{
    VALSinglePromptSecureEnclaveValet *const valet = [VALSinglePromptSecureEnclaveValet valetWithIdentifier:@"" accessControl:VALSecureEnclaveAccessControlBiometricCurrentSet];
    XCTAssertNil(valet);
}

- (void)test_sharedAccessGroupValetWithIdentifier_accessControl_returnsCorrectValet_VALSecureEnclaveAccessControlDevicePasscode;
{
    VALSinglePromptSecureEnclaveValet *const valet = [VALSinglePromptSecureEnclaveValet sharedGroupValetWithAppIDPrefix:self.appIDPrefix sharedGroupIdentifier:self.sharedAccessGroupIdentifier accessControl:VALSecureEnclaveAccessControlDevicePasscode];
    XCTAssertEqual(valet.accessControl, VALSecureEnclaveAccessControlDevicePasscode);
    XCTAssertEqual([valet class], [VALSinglePromptSecureEnclaveValet class]);
}

- (void)test_sharedAccessGroupValetWithIdentifier_accessControl_returnsCorrectValet_VALSecureEnclaveAccessControlUserPresence;
{
    VALSinglePromptSecureEnclaveValet *const valet = [VALSinglePromptSecureEnclaveValet sharedGroupValetWithAppIDPrefix:self.appIDPrefix sharedGroupIdentifier:self.sharedAccessGroupIdentifier accessControl:VALSecureEnclaveAccessControlUserPresence];
    XCTAssertEqual(valet.accessControl, VALSecureEnclaveAccessControlUserPresence);
    XCTAssertEqual([valet class], [VALSinglePromptSecureEnclaveValet class]);
}

- (void)test_sharedAccessGroupValetWithIdentifier_accessControl_returnsCorrectValet_VALSecureEnclaveAccessControlBiometricAny;
{
    VALSinglePromptSecureEnclaveValet *const valet = [VALSinglePromptSecureEnclaveValet sharedGroupValetWithAppIDPrefix:self.appIDPrefix sharedGroupIdentifier:self.sharedAccessGroupIdentifier accessControl:VALSecureEnclaveAccessControlBiometricAny];
    XCTAssertEqual(valet.accessControl, VALSecureEnclaveAccessControlBiometricAny);
    XCTAssertEqual([valet class], [VALSinglePromptSecureEnclaveValet class]);
}

- (void)test_sharedAccessGroupValetWithIdentifier_accessControl_returnsCorrectValet_VALSecureEnclaveAccessControlBiometricCurrentSet;
{
    VALSinglePromptSecureEnclaveValet *const valet = [VALSinglePromptSecureEnclaveValet sharedGroupValetWithAppIDPrefix:self.appIDPrefix sharedGroupIdentifier:self.sharedAccessGroupIdentifier accessControl:VALSecureEnclaveAccessControlBiometricCurrentSet];
    XCTAssertEqual(valet.accessControl, VALSecureEnclaveAccessControlBiometricCurrentSet);
    XCTAssertEqual([valet class], [VALSinglePromptSecureEnclaveValet class]);
}

- (void)test_sharedAccessGroupValetWithIdentifier_accessibility_returnsNilWhenIdentifierIsEmpty;
{
    VALSinglePromptSecureEnclaveValet *const valet = [VALSinglePromptSecureEnclaveValet sharedGroupValetWithAppIDPrefix:self.appIDPrefix sharedGroupIdentifier:@"" accessControl:VALSecureEnclaveAccessControlBiometricCurrentSet];
    XCTAssertNil(valet);
}

- (void)test_sharedAppGroupValetWithIdentifier_accessControl_returnsCorrectValet_VALSecureEnclaveAccessControlDevicePasscode;
{
    VALSinglePromptSecureEnclaveValet *const valet = [VALSinglePromptSecureEnclaveValet sharedGroupValetWithGroupPrefix:self.groupPrefix sharedGroupIdentifier:self.sharedAppGroupIdentifier accessControl:VALSecureEnclaveAccessControlDevicePasscode];
    XCTAssertEqual(valet.accessControl, VALSecureEnclaveAccessControlDevicePasscode);
    XCTAssertEqual([valet class], [VALSinglePromptSecureEnclaveValet class]);
}

- (void)test_sharedAppGroupValetWithIdentifier_accessControl_returnsCorrectValet_VALSecureEnclaveAccessControlUserPresence;
{
    VALSinglePromptSecureEnclaveValet *const valet = [VALSinglePromptSecureEnclaveValet sharedGroupValetWithGroupPrefix:self.groupPrefix sharedGroupIdentifier:self.sharedAppGroupIdentifier accessControl:VALSecureEnclaveAccessControlUserPresence];
    XCTAssertEqual(valet.accessControl, VALSecureEnclaveAccessControlUserPresence);
    XCTAssertEqual([valet class], [VALSinglePromptSecureEnclaveValet class]);
}

- (void)test_sharedAppGroupValetWithIdentifier_accessControl_returnsCorrectValet_VALSecureEnclaveAccessControlBiometricAny;
{
    VALSinglePromptSecureEnclaveValet *const valet = [VALSinglePromptSecureEnclaveValet sharedGroupValetWithGroupPrefix:self.groupPrefix sharedGroupIdentifier:self.sharedAppGroupIdentifier accessControl:VALSecureEnclaveAccessControlBiometricAny];
    XCTAssertEqual(valet.accessControl, VALSecureEnclaveAccessControlBiometricAny);
    XCTAssertEqual([valet class], [VALSinglePromptSecureEnclaveValet class]);
}

- (void)test_sharedAppGroupValetWithIdentifier_accessControl_returnsCorrectValet_VALSecureEnclaveAccessControlBiometricCurrentSet;
{
    VALSinglePromptSecureEnclaveValet *const valet = [VALSinglePromptSecureEnclaveValet sharedGroupValetWithGroupPrefix:self.groupPrefix sharedGroupIdentifier:self.sharedAppGroupIdentifier accessControl:VALSecureEnclaveAccessControlBiometricCurrentSet];
    XCTAssertEqual(valet.accessControl, VALSecureEnclaveAccessControlBiometricCurrentSet);
    XCTAssertEqual([valet class], [VALSinglePromptSecureEnclaveValet class]);
}

- (void)test_sharedAppGroupValetWithIdentifier_accessibility_returnsNilWhenIdentifierIsEmpty;
{
    VALSinglePromptSecureEnclaveValet *const valet = [VALSinglePromptSecureEnclaveValet sharedGroupValetWithGroupPrefix:self.groupPrefix sharedGroupIdentifier:@"" accessControl:VALSecureEnclaveAccessControlBiometricCurrentSet];
    XCTAssertNil(valet);
}

@end

#endif
