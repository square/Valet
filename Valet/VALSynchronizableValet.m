//
//  VALSynchronizableValet.m
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

#import "VALSynchronizableValet.h"
#import "VALValet_Protected.h"

#import "ValetDefines.h"


@implementation VALSynchronizableValet

@synthesize baseQuery = _baseQuery;

#pragma mark - Class Methods

+ (BOOL)supportsSynchronizableKeychainItems;
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wtautological-compare"
    
#define SUPPORTS_SYNCHRONIZABLE_KEYCHAIN_MAC (TARGET_OS_MAC && __MAC_10_9)
#define SUPPORTS_SYNCHRONIZABLE_KEYCHAIN_IOS (TARGET_OS_IPHONE && (__IPHONE_8_2 || (__IPHONE_7_0 && !TARGET_IPHONE_SIMULATOR)))
    
#if SUPPORTS_SYNCHRONIZABLE_KEYCHAIN_MAC || SUPPORTS_SYNCHRONIZABLE_KEYCHAIN_IOS
    return (&kSecAttrSynchronizable != NULL && &kSecAttrSynchronizableAny != NULL);
#else
    return NO;
#endif
    
#pragma clang diagnostic pop
}

#pragma mark - Private Class Methods

+ (void)_augmentBaseQuery:(nonnull NSMutableDictionary *)mutableBaseQuery;
{
#if SUPPORTS_SYNCHRONIZABLE_KEYCHAIN_MAC || SUPPORTS_SYNCHRONIZABLE_KEYCHAIN_IOS
    mutableBaseQuery[(__bridge id)kSecAttrSynchronizable] = @YES;
#endif
}

#pragma mark - Initialization

- (nullable instancetype)initWithIdentifier:(nonnull NSString *)identifier accessibility:(VALAccessibility)accessibility;
{
    VALCheckCondition(accessibility == VALAccessibilityWhenUnlocked || accessibility == VALAccessibilityAfterFirstUnlock || accessibility == VALAccessibilityAlways, nil, @"Accessibility must not be scoped to this device");
    VALCheckCondition([[self class] supportsSynchronizableKeychainItems], nil, @"This device does not support synchronizing data to iCloud.");
    
    self = [super initWithIdentifier:identifier accessibility:accessibility];
    if (self != nil) {
        NSMutableDictionary *const baseQuery = [[self class] mutableBaseQueryWithIdentifier:identifier
                                                                              accessibility:accessibility
                                                                                initializer:_cmd];
        [[self class] _augmentBaseQuery:baseQuery];
        _baseQuery = baseQuery;
    }
    
    return [[self class] sharedValetForValet:self];
}

- (nullable instancetype)initWithSharedAccessGroupIdentifier:(nonnull NSString *)sharedAccessGroupIdentifier accessibility:(VALAccessibility)accessibility;
{
    VALCheckCondition(accessibility == VALAccessibilityWhenUnlocked || accessibility == VALAccessibilityAfterFirstUnlock || accessibility == VALAccessibilityAlways, nil, @"Accessibility must not be scoped to this device");
    VALCheckCondition([[self class] supportsSynchronizableKeychainItems], nil, @"This device does not support synchronizing data to iCloud.");
    
    self = [super initWithSharedAccessGroupIdentifier:sharedAccessGroupIdentifier accessibility:accessibility];
    if (self != nil) {
#if TARGET_IPHONE_SIMULATOR
        /*
         Access groups do not work on the simulator becuase apps built for the simulator aren't signed.
         Using kSecAttrAccessGroup in the simulator will cause SecItem calls to return -25243 (errSecNoAccessForItem).
         Dropping the kSecAttrAccessGroup key/value pair does not cause problems in development, since all apps can see all keychain items on the simulator.
         */
        NSMutableDictionary *const baseQuery = [[self class] mutableBaseQueryWithIdentifier:sharedAccessGroupIdentifier
                                                                              accessibility:accessibility
                                                                                initializer:_cmd];
#else
        NSMutableDictionary *const baseQuery = [[self class] mutableBaseQueryWithSharedAccessGroupIdentifier:sharedAccessGroupIdentifier
                                                                                               accessibility:accessibility
                                                                                                 initializer:_cmd];
#endif
        [[self class] _augmentBaseQuery:baseQuery];
        _baseQuery = baseQuery;
    }
    
    return [[self class] sharedValetForValet:self];
}

@end
