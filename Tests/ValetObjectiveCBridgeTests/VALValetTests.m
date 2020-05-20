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

@interface VALValetTests : XCTestCase
@end

@implementation VALValetTests

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

- (void)test_valetWithIdentifier_accessibility_returnsCorrectValet_VALAccessibilityWhenUnlocked;
{
    VALValet *const valet = [VALValet valetWithIdentifier:self.identifier accessibility:VALAccessibilityWhenUnlocked];
    XCTAssertEqual(valet.accessibility, VALAccessibilityWhenUnlocked);
    XCTAssertEqual([valet class], [VALValet class]);
}

- (void)test_valetWithIdentifier_accessibility_returnsCorrectValet_VALAccessibilityAfterFirstUnlock;
{
    VALValet *const valet = [VALValet valetWithIdentifier:self.identifier accessibility:VALAccessibilityAfterFirstUnlock];
    XCTAssertEqual(valet.accessibility, VALAccessibilityAfterFirstUnlock);
    XCTAssertEqual([valet class], [VALValet class]);
}

- (void)test_valetWithIdentifier_accessibility_returnsCorrectValet_VALAccessibilityWhenPasscodeSetThisDeviceOnly;
{
    VALValet *const valet = [VALValet valetWithIdentifier:self.identifier accessibility:VALAccessibilityWhenPasscodeSetThisDeviceOnly];
    XCTAssertEqual(valet.accessibility, VALAccessibilityWhenPasscodeSetThisDeviceOnly);
    XCTAssertEqual([valet class], [VALValet class]);
}

- (void)test_valetWithIdentifier_accessibility_returnsCorrectValet_VALAccessibilityWhenUnlockedThisDeviceOnly;
{
    VALValet *const valet = [VALValet valetWithIdentifier:self.identifier accessibility:VALAccessibilityWhenUnlockedThisDeviceOnly];
    XCTAssertEqual(valet.accessibility, VALAccessibilityWhenUnlockedThisDeviceOnly);
    XCTAssertEqual([valet class], [VALValet class]);
}

- (void)test_valetWithIdentifier_accessibility_returnsCorrectValet_VALAccessibilityAfterFirstUnlockThisDeviceOnly;
{
    VALValet *const valet = [VALValet valetWithIdentifier:self.identifier accessibility:VALAccessibilityAfterFirstUnlockThisDeviceOnly];
    XCTAssertEqual(valet.accessibility, VALAccessibilityAfterFirstUnlockThisDeviceOnly);
    XCTAssertEqual([valet class], [VALValet class]);
}

- (void)test_valetWithIdentifier_accessibility_returnsNilWhenIdentifierIsEmpty;
{
    VALValet *const valet = [VALValet valetWithIdentifier:@"" accessibility:VALAccessibilityAfterFirstUnlockThisDeviceOnly];
    XCTAssertNil(valet);
}

- (void)test_iCloudValetWithIdentifier_accessibility_returnsCorrectValet_VALCloudAccessibilityWhenUnlocked;
{
    VALValet *const valet = [VALValet iCloudValetWithIdentifier:self.identifier accessibility:VALCloudAccessibilityWhenUnlocked];
    XCTAssertEqual(valet.accessibility, VALAccessibilityWhenUnlocked);
    XCTAssertEqual([valet class], [VALValet class]);
}

- (void)test_iCloudValetWithIdentifier_accessibility_returnsCorrectValet_VALCloudAccessibilityAfterFirstUnlock;
{
    VALValet *const valet = [VALValet iCloudValetWithIdentifier:self.identifier accessibility:VALCloudAccessibilityAfterFirstUnlock];
    XCTAssertEqual(valet.accessibility, VALAccessibilityAfterFirstUnlock);
    XCTAssertEqual([valet class], [VALValet class]);
}

- (void)test_iCloudValetWithIdentifier_accessibility_returnsNilWhenIdentifierIsEmpty;
{
    VALValet *const valet = [VALValet iCloudValetWithIdentifier:@"" accessibility:VALCloudAccessibilityAfterFirstUnlock];
    XCTAssertNil(valet);
}

- (void)test_valetWithSharedAccessGroupIdentifier_accessibility_returnsCorrectValet_VALAccessibilityWhenUnlocked;
{
    VALValet *const valet = [VALValet sharedGroupValetWithAppIDPrefix:self.appIDPrefix sharedGroupIdentifier:self.sharedAccessGroupIdentifier accessibility:VALAccessibilityWhenUnlocked];
    XCTAssertEqual(valet.accessibility, VALAccessibilityWhenUnlocked);
    XCTAssertEqual([valet class], [VALValet class]);
}

- (void)test_valetWithSharedAccessGroupIdentifier_accessibility_returnsCorrectValet_VALAccessibilityAfterFirstUnlock;
{
    VALValet *const valet = [VALValet sharedGroupValetWithAppIDPrefix:self.appIDPrefix sharedGroupIdentifier:self.sharedAccessGroupIdentifier accessibility:VALAccessibilityAfterFirstUnlock];
    XCTAssertEqual(valet.accessibility, VALAccessibilityAfterFirstUnlock);
    XCTAssertEqual([valet class], [VALValet class]);
}

- (void)test_valetWithSharedAccessGroupIdentifier_accessibility_returnsCorrectValet_VALAccessibilityWhenPasscodeSetThisDeviceOnly;
{
    VALValet *const valet = [VALValet sharedGroupValetWithAppIDPrefix:self.appIDPrefix sharedGroupIdentifier:self.sharedAccessGroupIdentifier accessibility:VALAccessibilityWhenPasscodeSetThisDeviceOnly];
    XCTAssertEqual(valet.accessibility, VALAccessibilityWhenPasscodeSetThisDeviceOnly);
    XCTAssertEqual([valet class], [VALValet class]);
}

- (void)test_valetWithSharedAccessGroupIdentifier_accessibility_returnsCorrectValet_VALAccessibilityWhenUnlockedThisDeviceOnly;
{
    VALValet *const valet = [VALValet sharedGroupValetWithAppIDPrefix:self.appIDPrefix sharedGroupIdentifier:self.sharedAccessGroupIdentifier accessibility:VALAccessibilityWhenUnlockedThisDeviceOnly];
    XCTAssertEqual(valet.accessibility, VALAccessibilityWhenUnlockedThisDeviceOnly);
    XCTAssertEqual([valet class], [VALValet class]);
}

- (void)test_valetWithSharedAccessGroupIdentifier_accessibility_returnsCorrectValet_VALAccessibilityAfterFirstUnlockThisDeviceOnly;
{
    VALValet *const valet = [VALValet sharedGroupValetWithAppIDPrefix:self.appIDPrefix sharedGroupIdentifier:self.sharedAccessGroupIdentifier accessibility:VALAccessibilityAfterFirstUnlockThisDeviceOnly];
    XCTAssertEqual(valet.accessibility, VALAccessibilityAfterFirstUnlockThisDeviceOnly);
    XCTAssertEqual([valet class], [VALValet class]);
}

- (void)test_valetWithSharedAccessGroupIdentifier_accessibility_returnsNilWhenIdentifierIsEmpty;
{
    VALValet *const valet = [VALValet sharedGroupValetWithAppIDPrefix:self.appIDPrefix sharedGroupIdentifier:@"" accessibility:VALAccessibilityAfterFirstUnlockThisDeviceOnly];
    XCTAssertNil(valet);
}

- (void)test_iCloudValetWithSharedAccessGroupIdentifier_accessibility_returnsCorrectValet_VALCloudAccessibilityWhenUnlocked;
{
    VALValet *const valet = [VALValet iCloudValetWithAppIDPrefix:self.appIDPrefix sharedGroupIdentifier:self.sharedAccessGroupIdentifier accessibility:VALCloudAccessibilityWhenUnlocked];
    XCTAssertEqual(valet.accessibility, VALAccessibilityWhenUnlocked);
    XCTAssertEqual([valet class], [VALValet class]);
}

- (void)test_iCloudValetWithSharedAccessGroupIdentifier_accessibility_returnsCorrectValet_VALCloudAccessibilityAfterFirstUnlock;
{
    VALValet *const valet = [VALValet iCloudValetWithAppIDPrefix:self.appIDPrefix sharedGroupIdentifier:self.sharedAccessGroupIdentifier accessibility:VALCloudAccessibilityAfterFirstUnlock];
    XCTAssertEqual(valet.accessibility, VALAccessibilityAfterFirstUnlock);
    XCTAssertEqual([valet class], [VALValet class]);
}

- (void)test_iCloudValetWithSharedAccessGroupIdentifier_accessibility_returnsNilWhenIdentifierIsEmpty;
{
    VALValet *const valet = [VALValet iCloudValetWithAppIDPrefix:self.appIDPrefix sharedGroupIdentifier:@"" accessibility:VALCloudAccessibilityAfterFirstUnlock];
    XCTAssertNil(valet);
}

// MARK: Mac Tests

#if TARGET_OS_OSX

- (void)test_valetWithExplicitlySetIdentifier_accessibility_returnsCorrectValet_VALAccessibilityWhenUnlocked;
{
    VALValet *const valet = [VALValet valetWithExplicitlySetIdentifier:self.identifier accessibility:VALAccessibilityWhenUnlocked];
    XCTAssertEqual(valet.accessibility, VALAccessibilityWhenUnlocked);
    XCTAssertEqual([valet class], [VALValet class]);
}

- (void)test_valetWithExplicitlySetIdentifier_accessibility_returnsCorrectValet_VALAccessibilityAfterFirstUnlock;
{
    VALValet *const valet = [VALValet valetWithExplicitlySetIdentifier:self.identifier accessibility:VALAccessibilityAfterFirstUnlock];
    XCTAssertEqual(valet.accessibility, VALAccessibilityAfterFirstUnlock);
    XCTAssertEqual([valet class], [VALValet class]);
}

- (void)test_valetWithExplicitlySetIdentifier_accessibility_returnsCorrectValet_VALAccessibilityWhenPasscodeSetThisDeviceOnly;
{
    VALValet *const valet = [VALValet valetWithExplicitlySetIdentifier:self.identifier accessibility:VALAccessibilityWhenPasscodeSetThisDeviceOnly];
    XCTAssertEqual(valet.accessibility, VALAccessibilityWhenPasscodeSetThisDeviceOnly);
    XCTAssertEqual([valet class], [VALValet class]);
}

- (void)test_valetWithExplicitlySetIdentifier_accessibility_returnsCorrectValet_VALAccessibilityWhenUnlockedThisDeviceOnly;
{
    VALValet *const valet = [VALValet valetWithExplicitlySetIdentifier:self.identifier accessibility:VALAccessibilityWhenUnlockedThisDeviceOnly];
    XCTAssertEqual(valet.accessibility, VALAccessibilityWhenUnlockedThisDeviceOnly);
    XCTAssertEqual([valet class], [VALValet class]);
}

- (void)test_valetWithExplicitlySetIdentifier_accessibility_returnsCorrectValet_VALAccessibilityAfterFirstUnlockThisDeviceOnly;
{
    VALValet *const valet = [VALValet valetWithExplicitlySetIdentifier:self.identifier accessibility:VALAccessibilityAfterFirstUnlockThisDeviceOnly];
    XCTAssertEqual(valet.accessibility, VALAccessibilityAfterFirstUnlockThisDeviceOnly);
    XCTAssertEqual([valet class], [VALValet class]);
}

- (void)test_valetWithExplicitlySetIdentifier_accessibility_returnsNilWhenIdentifierIsEmpty;
{
    VALValet *const valet = [VALValet valetWithExplicitlySetIdentifier:@"" accessibility:VALAccessibilityAfterFirstUnlockThisDeviceOnly];
    XCTAssertNil(valet);
}

- (void)test_iCloudValetWithExplicitlySetIdentifier_accessibility_returnsCorrectValet_VALCloudAccessibilityWhenUnlocked;
{
    VALValet *const valet = [VALValet iCloudValetWithExplicitlySetIdentifier:self.identifier accessibility:VALCloudAccessibilityWhenUnlocked];
    XCTAssertEqual(valet.accessibility, VALAccessibilityWhenUnlocked);
    XCTAssertEqual([valet class], [VALValet class]);
}

- (void)test_iCloudValetWithExplicitlySetIdentifier_accessibility_returnsCorrectValet_VALCloudAccessibilityAfterFirstUnlock;
{
    VALValet *const valet = [VALValet iCloudValetWithExplicitlySetIdentifier:self.identifier accessibility:VALCloudAccessibilityAfterFirstUnlock];
    XCTAssertEqual(valet.accessibility, VALAccessibilityAfterFirstUnlock);
    XCTAssertEqual([valet class], [VALValet class]);
}

- (void)test_iCloudValetWithExplicitlySetIdentifier_accessibility_returnsNilWhenIdentifierIsEmpty;
{
    VALValet *const valet = [VALValet iCloudValetWithExplicitlySetIdentifier:@"" accessibility:VALCloudAccessibilityAfterFirstUnlock];
    XCTAssertNil(valet);
}

- (void)test_valetWithExplicitlySetSharedGroupIdentifier_accessibility_returnsCorrectValet_VALAccessibilityWhenUnlocked;
{
    VALValet *const valet = [VALValet valetWithAppIDPrefix:self.appIDPrefix explicitlySetSharedGroupIdentifier:self.sharedAccessGroupIdentifier accessibility:VALAccessibilityWhenUnlocked];
    XCTAssertEqual(valet.accessibility, VALAccessibilityWhenUnlocked);
    XCTAssertEqual([valet class], [VALValet class]);
}

- (void)test_valetWithExplicitlySetSharedGroupIdentifier_accessibility_returnsCorrectValet_VALAccessibilityAfterFirstUnlock;
{
    VALValet *const valet = [VALValet valetWithAppIDPrefix:self.appIDPrefix explicitlySetSharedGroupIdentifier:self.sharedAccessGroupIdentifier accessibility:VALAccessibilityAfterFirstUnlock];
    XCTAssertEqual(valet.accessibility, VALAccessibilityAfterFirstUnlock);
    XCTAssertEqual([valet class], [VALValet class]);
}

- (void)test_valetWithExplicitlySetSharedGroupIdentifier_accessibility_returnsCorrectValet_VALAccessibilityWhenPasscodeSetThisDeviceOnly;
{
    VALValet *const valet = [VALValet valetWithAppIDPrefix:self.appIDPrefix explicitlySetSharedGroupIdentifier:self.sharedAccessGroupIdentifier accessibility:VALAccessibilityWhenPasscodeSetThisDeviceOnly];
    XCTAssertEqual(valet.accessibility, VALAccessibilityWhenPasscodeSetThisDeviceOnly);
    XCTAssertEqual([valet class], [VALValet class]);
}

- (void)test_valetWithExplicitlySetSharedGroupIdentifier_accessibility_returnsCorrectValet_VALAccessibilityWhenUnlockedThisDeviceOnly;
{
    VALValet *const valet = [VALValet valetWithAppIDPrefix:self.appIDPrefix explicitlySetSharedGroupIdentifier:self.sharedAccessGroupIdentifier accessibility:VALAccessibilityWhenUnlockedThisDeviceOnly];
    XCTAssertEqual(valet.accessibility, VALAccessibilityWhenUnlockedThisDeviceOnly);
    XCTAssertEqual([valet class], [VALValet class]);
}

- (void)test_valetWithExplicitlySetSharedGroupIdentifier_accessibility_returnsCorrectValet_VALAccessibilityAfterFirstUnlockThisDeviceOnly;
{
    VALValet *const valet = [VALValet valetWithAppIDPrefix:self.appIDPrefix explicitlySetSharedGroupIdentifier:self.sharedAccessGroupIdentifier accessibility:VALAccessibilityAfterFirstUnlockThisDeviceOnly];
    XCTAssertEqual(valet.accessibility, VALAccessibilityAfterFirstUnlockThisDeviceOnly);
    XCTAssertEqual([valet class], [VALValet class]);
}

- (void)test_valetWithExplicitlySetSharedGroupIdentifier_accessibility_returnsNilWhenIdentifierIsEmpty;
{
    VALValet *const valet = [VALValet valetWithAppIDPrefix:self.appIDPrefix explicitlySetSharedGroupIdentifier:@"" accessibility:VALAccessibilityAfterFirstUnlockThisDeviceOnly];
    XCTAssertNil(valet);
}

- (void)test_iCloudValetWithExplicitlySetSharedGroupIdentifier_accessibility_returnsCorrectValet_VALCloudAccessibilityWhenUnlocked;
{
    VALValet *const valet = [VALValet iCloudValetWithAppIDPrefix:self.appIDPrefix explicitlySetSharedGroupIdentifier:self.sharedAccessGroupIdentifier accessibility:VALCloudAccessibilityWhenUnlocked];
    XCTAssertEqual(valet.accessibility, VALAccessibilityWhenUnlocked);
    XCTAssertEqual([valet class], [VALValet class]);
}

- (void)test_iCloudValetWithExplicitlySetSharedGroupIdentifier_accessibility_returnsCorrectValet_VALCloudAccessibilityAfterFirstUnlock;
{
    VALValet *const valet = [VALValet iCloudValetWithAppIDPrefix:self.appIDPrefix explicitlySetSharedGroupIdentifier:self.sharedAccessGroupIdentifier accessibility:VALCloudAccessibilityAfterFirstUnlock];
    XCTAssertEqual(valet.accessibility, VALCloudAccessibilityAfterFirstUnlock);
    XCTAssertEqual([valet class], [VALValet class]);
}

- (void)test_iCloudValetWithExplicitlySetSharedGroupIdentifier_accessibility_returnsNilWhenIdentifierIsEmpty;
{
    VALValet *const valet = [VALValet iCloudValetWithAppIDPrefix:self.appIDPrefix explicitlySetSharedGroupIdentifier:@"" accessibility:VALCloudAccessibilityAfterFirstUnlock];
    XCTAssertNil(valet);
}

#endif

@end
