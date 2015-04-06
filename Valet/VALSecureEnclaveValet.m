//
//  VALSecureEnclaveValet.m
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

#import "VALSecureEnclaveValet.h"
#import "VALValet_Protected.h"


@implementation VALSecureEnclaveValet

#pragma mark - Initialization

- (instancetype)initWithIdentifier:(NSString *)identifier accessibility:(VALAccessibility)accessibility;
{
    VALCheckCondition(accessibility == VALAccessibleWhenPasscodeSetThisDeviceOnly, nil, @"Accessibility on SecureEnclaveValet must be VALAccessibleWhenPasscodeSetThisDeviceOnly");
    VALCheckCondition([self supportsSecureEnclaveKeychainItems], nil, @"This device does not support storing data on the secure enclave.");
    
    return [super initWithIdentifier:identifier accessibility:accessibility];
}

- (instancetype)initWithSharedAccessGroupIdentifier:(NSString *)sharedAccessGroupIdentifier accessibility:(VALAccessibility)accessibility;
{
    VALCheckCondition(accessibility == VALAccessibleWhenPasscodeSetThisDeviceOnly, nil, @"Accessibility on SecureEnclaveValet must be VALAccessibleWhenPasscodeSetThisDeviceOnly");
    VALCheckCondition([self supportsSecureEnclaveKeychainItems], nil, @"This device does not support storing data on the secure enclave.");
    
    return [super initWithSharedAccessGroupIdentifier:sharedAccessGroupIdentifier accessibility:accessibility];
}

#pragma mark - Public Methods

- (BOOL)supportsSecureEnclaveKeychainItems;
{
#if TARGET_IPHONE_SIMULATOR
    return NO;
#else
    return (&kSecAttrAccessControl != NULL && &kSecUseOperationPrompt != NULL);
#endif
}

- (BOOL)setObject:(NSData *)value forKey:(NSString *)key userPrompt:(NSString *)userPrompt
{
    return [self setObject:value forKey:key options:@{ (__bridge id)kSecUseOperationPrompt : userPrompt }];
}

- (NSData *)objectForKey:(NSString *)key userPrompt:(NSString *)userPrompt;
{
    return [self objectForKey:key options:@{ (__bridge id)kSecUseOperationPrompt : userPrompt }];
}

- (BOOL)setString:(NSString *)string forKey:(NSString *)key userPrompt:(NSString *)userPrompt;
{
    return [self setString:string forKey:key options:@{ (__bridge id)kSecUseOperationPrompt : userPrompt }];
}

- (NSString *)stringForKey:(NSString *)key userPrompt:(NSString *)userPrompt;
{
    return [self stringForKey:key options:@{ (__bridge id)kSecUseOperationPrompt : userPrompt }];
}

- (BOOL)containsObjectForKey:(NSString *)key;
{
    OSStatus status = [self containsObjectForKey:key options:@{ (__bridge id)kSecUseNoAuthenticationUI : @YES }];
    BOOL const keyAlreadyInKeychain = (status == errSecInteractionNotAllowed);
    return keyAlreadyInKeychain;
}

- (NSSet *)allKeys;
{
    VALCheckCondition(NO, nil, @"%s is not supported on %@", __PRETTY_FUNCTION__, NSStringFromClass([self class]));
}

#pragma mark - Protected Methods

- (NSMutableDictionary *)mutableBaseQueryWithIdentifier:(NSString *)identifier initializer:(SEL)initializer accessibility:(VALAccessibility)accessibility;
{
    NSMutableDictionary *mutableBaseQuery = [super mutableBaseQueryWithIdentifier:identifier initializer:initializer accessibility:accessibility];
    mutableBaseQuery[(__bridge id)kSecAttrAccessControl] = (__bridge id)SecAccessControlCreateWithFlags(NULL, kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly, kSecAccessControlUserPresence, NULL);
    
    return mutableBaseQuery;
}

@end
