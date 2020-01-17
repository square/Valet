//  Created by Dan Federman on 1/16/20.
//  Copyright © 2020 Dan Federman.
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

@interface VALSecureEnclaveValetTests : XCTestCase
@end

@implementation VALSecureEnclaveValetTests

- (NSString *)identifier;
{
    return @"identifier";
}

- (void)test_valetWithIdentifier_accessControl_returnsCorrectValet_VALSecureEnclaveAccessControlDevicePasscode;
{
    VALSecureEnclaveValet *const valet = [VALSecureEnclaveValet valetWithIdentifier:self.identifier accessControl:VALSecureEnclaveAccessControlDevicePasscode];
    XCTAssertEqual(valet.accessControl, VALSecureEnclaveAccessControlDevicePasscode);
    XCTAssertEqual([valet class], [VALSecureEnclaveValet class]);
}

- (void)test_valetWithIdentifier_accessControl_returnsCorrectValet_VALSecureEnclaveAccessControlUserPresence;
{
    VALSecureEnclaveValet *const valet = [VALSecureEnclaveValet valetWithIdentifier:self.identifier accessControl:VALSecureEnclaveAccessControlUserPresence];
    XCTAssertEqual(valet.accessControl, VALSecureEnclaveAccessControlUserPresence);
    XCTAssertEqual([valet class], [VALSecureEnclaveValet class]);
}

- (void)test_valetWithIdentifier_accessControl_returnsCorrectValet_VALSecureEnclaveAccessControlBiometricAny;
{
    VALSecureEnclaveValet *const valet = [VALSecureEnclaveValet valetWithIdentifier:self.identifier accessControl:VALSecureEnclaveAccessControlBiometricAny];
    XCTAssertEqual(valet.accessControl, VALSecureEnclaveAccessControlBiometricAny);
    XCTAssertEqual([valet class], [VALSecureEnclaveValet class]);
}

- (void)test_valetWithIdentifier_accessControl_returnsCorrectValet_VALSecureEnclaveAccessControlBiometricCurrentSet;
{
    VALSecureEnclaveValet *const valet = [VALSecureEnclaveValet valetWithIdentifier:self.identifier accessControl:VALSecureEnclaveAccessControlBiometricCurrentSet];
    XCTAssertEqual(valet.accessControl, VALSecureEnclaveAccessControlBiometricCurrentSet);
    XCTAssertEqual([valet class], [VALSecureEnclaveValet class]);
}

- (void)test_valetWithIdentifier_accessibility_returnsNilWhenIdentifierIsEmpty;
{
    VALSecureEnclaveValet *const valet = [VALSecureEnclaveValet valetWithIdentifier:@"" accessControl:VALSecureEnclaveAccessControlBiometricCurrentSet];
    XCTAssertNil(valet);
}

- (void)test_sharedAccessGroupValetWithIdentifier_accessControl_returnsCorrectValet_VALSecureEnclaveAccessControlDevicePasscode;
{
    VALSecureEnclaveValet *const valet = [VALSecureEnclaveValet sharedAccessGroupValetWithIdentifier:self.identifier accessControl:VALSecureEnclaveAccessControlDevicePasscode];
    XCTAssertEqual(valet.accessControl, VALSecureEnclaveAccessControlDevicePasscode);
    XCTAssertEqual([valet class], [VALSecureEnclaveValet class]);
}

- (void)test_sharedAccessGroupValetWithIdentifier_accessControl_returnsCorrectValet_VALSecureEnclaveAccessControlUserPresence;
{
    VALSecureEnclaveValet *const valet = [VALSecureEnclaveValet sharedAccessGroupValetWithIdentifier:self.identifier accessControl:VALSecureEnclaveAccessControlUserPresence];
    XCTAssertEqual(valet.accessControl, VALSecureEnclaveAccessControlUserPresence);
    XCTAssertEqual([valet class], [VALSecureEnclaveValet class]);
}

- (void)test_sharedAccessGroupValetWithIdentifier_accessControl_returnsCorrectValet_VALSecureEnclaveAccessControlBiometricAny;
{
    VALSecureEnclaveValet *const valet = [VALSecureEnclaveValet sharedAccessGroupValetWithIdentifier:self.identifier accessControl:VALSecureEnclaveAccessControlBiometricAny];
    XCTAssertEqual(valet.accessControl, VALSecureEnclaveAccessControlBiometricAny);
    XCTAssertEqual([valet class], [VALSecureEnclaveValet class]);
}

- (void)test_sharedAccessGroupValetWithIdentifier_accessControl_returnsCorrectValet_VALSecureEnclaveAccessControlBiometricCurrentSet;
{
    VALSecureEnclaveValet *const valet = [VALSecureEnclaveValet sharedAccessGroupValetWithIdentifier:self.identifier accessControl:VALSecureEnclaveAccessControlBiometricCurrentSet];
    XCTAssertEqual(valet.accessControl, VALSecureEnclaveAccessControlBiometricCurrentSet);
    XCTAssertEqual([valet class], [VALSecureEnclaveValet class]);
}

- (void)test_sharedAccessGroupValetWithIdentifier_accessibility_returnsNilWhenIdentifierIsEmpty;
{
    VALSecureEnclaveValet *const valet = [VALSecureEnclaveValet sharedAccessGroupValetWithIdentifier:@"" accessControl:VALSecureEnclaveAccessControlBiometricCurrentSet];
    XCTAssertNil(valet);
}

@end
