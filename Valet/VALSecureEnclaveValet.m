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

#import "ValetDefines.h"


@implementation VALSecureEnclaveValet

#pragma mark - Class Methods

+ (BOOL)supportsSecureEnclaveKeychainItems;
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wtautological-compare"
#if VAL_IOS_8_OR_LATER
    return (&kSecAttrAccessControl != NULL && &kSecUseOperationPrompt != NULL);
#else
    return NO;
#endif
#pragma clang diagnostic pop
}

#pragma mark - Initialization

- (nullable instancetype)initWithIdentifier:(nonnull NSString *)identifier;
{
    return [self initWithIdentifier:identifier accessibility:VALAccessibilityWhenPasscodeSetThisDeviceOnly];
}

- (nullable instancetype)initWithIdentifier:(nonnull NSString *)identifier accessibility:(VALAccessibility)accessibility;
{
    VALCheckCondition(accessibility == VALAccessibilityWhenPasscodeSetThisDeviceOnly, nil, @"Accessibility on SecureEnclaveValet must be VALAccessibilityWhenPasscodeSetThisDeviceOnly");
    VALCheckCondition([[self class] supportsSecureEnclaveKeychainItems], nil, @"This device does not support storing data on the secure enclave.");
    
    return [super initWithIdentifier:identifier accessibility:accessibility];
}

- (nullable instancetype)initWithSharedAccessGroupIdentifier:(nonnull NSString *)sharedAccessGroupIdentifier;
{
    return [self initWithSharedAccessGroupIdentifier:sharedAccessGroupIdentifier accessibility:VALAccessibilityWhenPasscodeSetThisDeviceOnly];
}

- (nullable instancetype)initWithSharedAccessGroupIdentifier:(nonnull NSString *)sharedAccessGroupIdentifier accessibility:(VALAccessibility)accessibility;
{
    VALCheckCondition(accessibility == VALAccessibilityWhenPasscodeSetThisDeviceOnly, nil, @"Accessibility on SecureEnclaveValet must be VALAccessibilityWhenPasscodeSetThisDeviceOnly");
    VALCheckCondition([[self class] supportsSecureEnclaveKeychainItems], nil, @"This device does not support storing data on the secure enclave.");
    
    return [super initWithSharedAccessGroupIdentifier:sharedAccessGroupIdentifier accessibility:accessibility];
}

#pragma mark - VALValet

- (BOOL)canAccessKeychain;
{
    // To avoid prompting the user for Touch ID or passcode, create a VALValet with our identifier and accessibility and ask it if it can access the keychain.
    VALValet *noPromptValet = nil;
    if ([self isSharedAcrossApplications]) {
        noPromptValet = [[VALValet alloc] initWithSharedAccessGroupIdentifier:self.identifier accessibility:self.accessibility];
    } else {
        noPromptValet = [[VALValet alloc] initWithIdentifier:self.identifier accessibility:self.accessibility];
    }
    
    return [noPromptValet canAccessKeychain];
}

- (BOOL)containsObjectForKey:(nonnull NSString *)key;
{
#if VAL_IOS_8_OR_LATER
    NSDictionary *options = nil;
    
#if VAL_IOS_9_OR_LATER
    if (&kSecUseAuthenticationUI != NULL) {
        options = @{ (__bridge id)kSecUseAuthenticationUI : (__bridge id)kSecUseAuthenticationUIFail };
    } else {
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"
        // kSecUseNoAuthenticationUI is deprecated in the iOS 9 SDK, but we still need it on iOS 8.
        options = @{ (__bridge id)kSecUseNoAuthenticationUI : @YES };
#pragma GCC diagnostic pop
    }
#else
    options = @{ (__bridge id)kSecUseNoAuthenticationUI : @YES };
#endif
    
    OSStatus status = [self containsObjectForKey:key options:options];
    
    BOOL const keyAlreadyInKeychain = (status == errSecInteractionNotAllowed || status == errSecSuccess);
    return keyAlreadyInKeychain;
    
#else
    return NO;
#endif
}

- (nonnull NSSet *)allKeys;
{
    VALCheckCondition(NO, [NSSet new], @"%s is not supported on %@", __PRETTY_FUNCTION__, NSStringFromClass([self class]));
}

- (BOOL)removeAllObjects;
{
    VALCheckCondition(NO, NO, @"%s is not supported on %@", __PRETTY_FUNCTION__, NSStringFromClass([self class]));
}

- (nullable NSError *)migrateObjectsMatchingQuery:(nonnull NSDictionary *)secItemQuery removeOnCompletion:(BOOL)remove;
{
#if VAL_IOS_8_OR_LATER
    if ([[self class] supportsSecureEnclaveKeychainItems]) {
        VALCheckCondition(secItemQuery[(__bridge id)kSecUseOperationPrompt] == nil, [NSError errorWithDomain:VALMigrationErrorDomain code:VALMigrationErrorInvalidQuery userInfo:nil], @"kSecUseOperationPrompt is not supported in a migration query. Keychain items can not be migrated en masse from the Secure Enclave.");
    }
#endif
    
    return [super migrateObjectsMatchingQuery:secItemQuery removeOnCompletion:remove];
}

#pragma mark - Public Methods

- (nullable NSData *)objectForKey:(nonnull NSString *)key userPrompt:(nonnull NSString *)userPrompt;
{
#if VAL_IOS_8_OR_LATER
    return [self objectForKey:key options:@{ (__bridge id)kSecUseOperationPrompt : userPrompt }];
#else
    return nil;
#endif
}

- (nullable NSString *)stringForKey:(nonnull NSString *)key userPrompt:(nonnull NSString *)userPrompt;
{
#if VAL_IOS_8_OR_LATER
    return [self stringForKey:key options:@{ (__bridge id)kSecUseOperationPrompt : userPrompt }];
#else
    return nil;
#endif
}

#pragma mark - Protected Methods

- (nonnull NSMutableDictionary *)mutableBaseQueryWithIdentifier:(nonnull NSString *)identifier initializer:(SEL)initializer accessibility:(VALAccessibility)accessibility;
{
#if VAL_IOS_8_OR_LATER
    NSMutableDictionary *mutableBaseQuery = [super mutableBaseQueryWithIdentifier:identifier initializer:initializer accessibility:accessibility];
    
    // Add the access control, which opts us in to Secure Element storage.
    mutableBaseQuery[(__bridge id)kSecAttrAccessControl] = (__bridge_transfer id)SecAccessControlCreateWithFlags(NULL, kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly, kSecAccessControlUserPresence, NULL);
    
    // kSecAttrAccessControl and kSecAttrAccessible are mutually exclusive, so remove kSecAttrAccessible from our query.
    [mutableBaseQuery removeObjectForKey:(__bridge id)kSecAttrAccessible];
    
    return mutableBaseQuery;
#else
    return [NSMutableDictionary new];
#endif
}

- (BOOL)setObject:(nonnull NSData *)value forKey:(nonnull NSString *)key options:(NSDictionary *)options;
{
    // Remove the key before trying to set it. This will prevent us from calling SecItemUpdate on an item stored on the Secure Enclave, which would cause iOS to prompt the user for authentication.
    [self removeObjectForKey:key];
    
    return [super setObject:value forKey:key options:options];
}

@end
