//
//  VALSecureEnclaveBiometricValet.m
//  Valet
//
//  Created by Nic Wise on 01/09/16.
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

#import "VALSecureEnclaveBiometricValet.h"

#import "VALValet_Protected.h"


@implementation VALSecureEnclaveBiometricValet {

}

//this feels hacky, but the baseQuery is setup before the init returns, so I need to store it somewhere
static VALTouchIdSensitivity baseSensitivity;

- (instancetype)initWithIdentifier:(NSString *)identifier sensitivity:(VALTouchIdSensitivity)sensitivity {
    baseSensitivity = sensitivity;

    self = [super initWithIdentifier:identifier];
    return self;
}

- (instancetype)initWithSharedAccessGroupIdentifier:(NSString *)sharedAccessGroupIdentifier sensitivity:(VALTouchIdSensitivity)sensitivity {
    baseSensitivity = sensitivity;

    self = [super initWithSharedAccessGroupIdentifier:sharedAccessGroupIdentifier];
    return self;
}


- (nonnull NSMutableDictionary *)mutableBaseQueryWithIdentifier:(nonnull NSString *)identifier initializer:(SEL)initializer accessibility:(VALAccessibility)accessibility;
{

    NSMutableDictionary *baseQuery = [super mutableBaseQueryWithIdentifier:identifier initializer:initializer accessibility:accessibility];
    [baseQuery removeObjectForKey:(__bridge id)kSecAttrAccessControl];

    baseQuery[(__bridge id)kSecAttrAccessControl] = (__bridge_transfer id)SecAccessControlCreateWithFlags(
        kCFAllocatorDefault,
        kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly,
        [self touchIdAccessControl],
        NULL);

    return baseQuery;
}

- (enum SecAccessControlCreateFlags) touchIdAccessControl {
    switch (baseSensitivity) {
        case VALTouchIdFingerPrintCurrentSetOnly:
            return kSecAccessControlTouchIDCurrentSet;
        default:
            return kSecAccessControlTouchIDAny;

    }
}

@end