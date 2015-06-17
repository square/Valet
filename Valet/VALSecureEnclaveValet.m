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

- (instancetype)initWithIdentifier:(NSString *)identifier;
{
    return [self initWithIdentifier:identifier accessibility:VALAccessibilityWhenPasscodeSetThisDeviceOnly];
}

- (instancetype)initWithIdentifier:(NSString *)identifier accessibility:(VALAccessibility)accessibility;
{
    VALCheckCondition(accessibility == VALAccessibilityWhenPasscodeSetThisDeviceOnly, nil, @"Accessibility on SecureEnclaveValet must be VALAccessibilityWhenPasscodeSetThisDeviceOnly");
    VALCheckCondition([[self class] supportsSecureEnclaveKeychainItems], nil, @"This device does not support storing data on the secure enclave.");
    
    return [super initWithIdentifier:identifier accessibility:accessibility];
}

- (instancetype)initWithSharedAccessGroupIdentifier:(NSString *)sharedAccessGroupIdentifier;
{
    return [self initWithSharedAccessGroupIdentifier:sharedAccessGroupIdentifier accessibility:VALAccessibilityWhenPasscodeSetThisDeviceOnly];
}

- (instancetype)initWithSharedAccessGroupIdentifier:(NSString *)sharedAccessGroupIdentifier accessibility:(VALAccessibility)accessibility;
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

- (BOOL)containsObjectForKey:(NSString *)key;
{
#if VAL_IOS_8_OR_LATER
    OSStatus status = [self containsObjectForKey:key options:@{ (__bridge id)kSecUseNoAuthenticationUI : @YES }];
    BOOL const keyAlreadyInKeychain = (status == errSecInteractionNotAllowed || status == errSecSuccess);
    return keyAlreadyInKeychain;
#else
    return NO;
#endif
}

- (NSSet *)allKeys;
{
    VALCheckCondition(NO, nil, @"%s is not supported on %@", __PRETTY_FUNCTION__, NSStringFromClass([self class]));
}

- (BOOL)removeAllObjects;
{
    VALCheckCondition(NO, NO, @"%s is not supported on %@", __PRETTY_FUNCTION__, NSStringFromClass([self class]));
}

- (NSError *)migrateObjectsMatchingQuery:(NSDictionary *)secItemQuery removeOnCompletion:(BOOL)remove;
{
#if VAL_IOS_8_OR_LATER
    if ([[self class] supportsSecureEnclaveKeychainItems]) {
        VALCheckCondition(secItemQuery[(__bridge id)kSecUseOperationPrompt] == nil, [NSError errorWithDomain:VALMigrationErrorDomain code:VALMigrationErrorInvalidQuery userInfo:nil], @"kSecUseOperationPrompt is not supported in a migration query. Keychain items can not be migrated en masse from the Secure Enclave.");
    }
#endif
    
    return [super migrateObjectsMatchingQuery:secItemQuery removeOnCompletion:remove];
}

#pragma mark - Public Methods

- (BOOL)setObject:(NSData *)value forKey:(NSString *)key userPrompt:(NSString *)userPrompt
{
#if VAL_IOS_8_OR_LATER
    return [self setObject:value forKey:key options:@{ (__bridge id)kSecUseOperationPrompt : userPrompt }];
#else
    return NO;
#endif
}

- (NSData *)objectForKey:(NSString *)key userPrompt:(NSString *)userPrompt;
{
#if VAL_IOS_8_OR_LATER
    return [self objectForKey:key options:@{ (__bridge id)kSecUseOperationPrompt : userPrompt }];
#else
    return nil;
#endif
}

- (BOOL)setString:(NSString *)string forKey:(NSString *)key userPrompt:(NSString *)userPrompt;
{
#if VAL_IOS_8_OR_LATER
    return [self setString:string forKey:key options:@{ (__bridge id)kSecUseOperationPrompt : userPrompt }];
#else
    return NO;
#endif
}

- (NSString *)stringForKey:(NSString *)key userPrompt:(NSString *)userPrompt;
{
#if VAL_IOS_8_OR_LATER
    return [self stringForKey:key options:@{ (__bridge id)kSecUseOperationPrompt : userPrompt }];
#else
    return nil;
#endif
}

#pragma mark - Protected Methods

- (NSMutableDictionary *)mutableBaseQueryWithIdentifier:(NSString *)identifier initializer:(SEL)initializer accessibility:(VALAccessibility)accessibility;
{
#if VAL_IOS_8_OR_LATER
    NSMutableDictionary *mutableBaseQuery = [super mutableBaseQueryWithIdentifier:identifier initializer:initializer accessibility:accessibility];
    
    // Add the access control, which opts us in to Secure Element storage.
    mutableBaseQuery[(__bridge id)kSecAttrAccessControl] = (__bridge id)SecAccessControlCreateWithFlags(NULL, kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly, kSecAccessControlUserPresence, NULL);
    
    // kSecAttrAccessControl and kSecAttrAccessible are mutually exclusive, so remove kSecAttrAccessible from our query.
    [mutableBaseQuery removeObjectForKey:(__bridge id)kSecAttrAccessible];
    
    return mutableBaseQuery;
#else
    return nil;
#endif
}

- (BOOL)setObject:(NSData *)value forKey:(NSString *)key options:(NSDictionary *)options;
{
    // Remove the key before trying to set it. This will prevent us from calling SecItemUpdate on an item stored on the Secure Enclave, which would cause iOS to prompt the user for authentication.
    [self removeObjectForKey:key];
    
    return [super setObject:value forKey:key options:options];
}

@end
