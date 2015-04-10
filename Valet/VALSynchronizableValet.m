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

#pragma mark - Class Methods

+ (BOOL)supportsSynchronizableKeychainItems;
{
#if TARGET_OS_IPHONE && (__IPHONE_8_2 || (__IPHONE_7_0 && !TARGET_IPHONE_SIMULATOR))
    return (&kSecAttrSynchronizable != NULL && &kSecAttrSynchronizableAny != NULL);
#else
    return NO;
#endif
}

#pragma mark - Initialization

- (instancetype)initWithIdentifier:(NSString *)identifier accessibility:(VALAccessibility)accessibility;
{
    VALCheckCondition(accessibility == VALAccessibleWhenUnlocked || accessibility == VALAccessibleAfterFirstUnlock || accessibility == VALAccessibleAlways, nil, @"Accessibility must not be scoped to this device");
    VALCheckCondition([[self class] supportsSynchronizableKeychainItems], nil, @"This device does not support synchronizing data to iCloud.");
    
    return [super initWithIdentifier:identifier accessibility:accessibility];
}

- (instancetype)initWithSharedAccessGroupIdentifier:(NSString *)sharedAccessGroupIdentifier accessibility:(VALAccessibility)accessibility;
{
    VALCheckCondition(accessibility == VALAccessibleWhenUnlocked || accessibility == VALAccessibleAfterFirstUnlock || accessibility == VALAccessibleAlways, nil, @"Accessibility must not be scoped to this device");
    VALCheckCondition([[self class] supportsSynchronizableKeychainItems], nil, @"This device does not support synchronizing data to iCloud.");
    
    return [super initWithSharedAccessGroupIdentifier:sharedAccessGroupIdentifier accessibility:accessibility];
}

#pragma mark - Protected Methods

- (NSMutableDictionary *)mutableBaseQueryWithIdentifier:(NSString *)identifier initializer:(SEL)initializer accessibility:(VALAccessibility)accessibility;
{
    NSMutableDictionary *mutableBaseQuery = [super mutableBaseQueryWithIdentifier:identifier initializer:initializer accessibility:accessibility];
    
#if TARGET_OS_IPHONE && __IPHONE_7_0
    mutableBaseQuery[(__bridge id)kSecAttrSynchronizable] = @YES;
#endif
    
    return mutableBaseQuery;
}

@end
