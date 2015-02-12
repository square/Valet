//
//  Valet.m
//  Valet
//
//  Created by Dan Federman on 1/21/15.
//  Copyright (c) 2015 Square, Inc. All rights reserved.
//

#import "Valet.h"

#import "ValetDefines.h"


@implementation Valet

#pragma mark Public Class Methods

+ (BOOL)supportsSynchronizableKeychainItems;
{
#if TARGET_IPHONE_SIMULATOR
    return NO;
#else
    return (&kSecAttrSynchronizable != NULL && &kSecAttrSynchronizableAny != NULL);
#endif
}

+ (BOOL)supportsLocalAuthentication;
{
#if TARGET_IPHONE_SIMULATOR
    return NO;
#else
    return (&kSecAttrAccessControl != NULL && &kSecUseOperationPrompt != NULL);
#endif
}

+ (BOOL)setUsername:(NSString *)username password:(NSString *)password service:(NSString *)service options:(NSDictionary *)options;
{
    VALCheckCondition(username.length > 0, NO, @"Can not set password with empty username.");
    VALCheckCondition(password.length > 0, NO, @"Can not set empty password");
    VALCheckCondition(service.length > 0, NO, @"Can not set password with empty service");
    
    NSMutableDictionary *noAuthenticationQuery = [self _mutableQueryWithService:service username:username options:options];
    // We don't want to pop authentication UI when we're just checking if the item is in the keychain.
    if ([self supportsLocalAuthentication]) {
        noAuthenticationQuery[(__bridge id)kSecUseNoAuthenticationUI] = @YES;
    }
    
    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)noAuthenticationQuery, NULL);
    
    BOOL itemAlreadyInKeychain = (status == errSecSuccess || status == errSecInteractionNotAllowed);
    if (itemAlreadyInKeychain) {
        // The item already exists, so just update it.
        
        status = SecItemUpdate((__bridge CFDictionaryRef)[self _mutableQueryWithService:service username:username options:options], (__bridge CFDictionaryRef)[self _secItemFormatDictionaryWithPassword:password]);
    } else {
        // No previous item found, add the new one.
        NSMutableDictionary *keychainData = [self _mutableQueryWithService:service username:username options:options];
        [keychainData addEntriesFromDictionary:[self _secItemFormatDictionaryWithPassword:password]];
        
        status = SecItemAdd((__bridge CFDictionaryRef)keychainData, NULL);
    }
    
    return (status == errSecSuccess);
}

+ (BOOL)setUsername:(NSString *)username password:(NSString *)password service:(NSString *)service;
{
    return [self setUsername:username password:password service:service options:nil];
}

+ (BOOL)setSynchronizableUsername:(NSString *)username password:(NSString *)password service:(NSString *)service;
{
    VALCheckCondition([self supportsSynchronizableKeychainItems], NO, @"Attempting to use synchronizable keychain calls from a pre iOS 7.0.3 device!");
    
    return [self setUsername:username password:password service:service options:@{ (__bridge id)kSecAttrSynchronizable : @YES, (__bridge id)kSecAttrAccessible : (__bridge id)kSecAttrAccessibleWhenUnlocked }];
}

+ (BOOL)setUserPresenceRequiredPasswordWithPrompt:(NSString *)prompt username:(NSString *)username password:(NSString *)password service:(NSString *)service;
{
    VALCheckCondition([self supportsLocalAuthentication], NO, @"Attempting to use LocalAuthentication calls from a pre iOS 8.0 device!");
    VALCheckCondition(prompt.length > 0, NO, @"Can not set user presense password with an empty prompt!");
    
    return [self setUsername:username password:password service:service options:@{ (__bridge id)kSecAttrAccessControl : (__bridge id)SecAccessControlCreateWithFlags(NULL, kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly, kSecAccessControlUserPresence, NULL), (__bridge id)kSecUseOperationPrompt : prompt }];
}

+ (BOOL)_removeUsername:(NSString *)username service:(NSString *)service;
{
    VALCheckCondition(service.length > 0, NO, @"Can not remove username for invalid service!");
    
    NSDictionary *options = nil;
    // Make sure to look at both the iCloud and local keychain if iCloud keychain is supported.
    if ([self supportsSynchronizableKeychainItems]) {
        options = @{ (__bridge id)kSecAttrSynchronizable : (__bridge id)kSecAttrSynchronizableAny };
    }
    
    NSMutableDictionary *query = [self _mutableQueryWithService:service username:username options:options];
    OSStatus status = SecItemDelete((__bridge CFDictionaryRef)query);
    
    return (status == errSecSuccess);
}

+ (BOOL)removeUsername:(NSString *)username service:(NSString *)service;
{
    VALCheckCondition(username.length > 0, NO, @"No username provided to %s", __PRETTY_FUNCTION__);
    
    return [self _removeUsername:username service:service];
}

+ (BOOL)removeAllEntriesservice:(NSString *)service;
{
    return [self _removeUsername:nil service:service];
}

+ (NSSet *)usernamesForService:(NSString *)service;
{
    VALCheckCondition(service.length > 0, nil, @"Can not retrieve username for empty service!");
    
    NSSet *usernames = nil;
    NSMutableDictionary *query = [self _mutableQueryWithService:service username:nil options:@{ (__bridge id)kSecMatchLimit : (__bridge id)kSecMatchLimitAll,
                                                                                                (__bridge id)
                                                                                                kSecReturnAttributes : @YES }];
    
    CFTypeRef outTypeRef = NULL;
    NSDictionary *queryResult = nil;
    
    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)query, &outTypeRef);
    queryResult = (__bridge_transfer NSDictionary *)outTypeRef;
    if (status == errSecSuccess) {
        if ([queryResult isKindOfClass:[NSArray class]]) {
            NSMutableSet *allUsernames = [NSMutableSet new];
            for (NSDictionary *attributes in queryResult) {
                // There were many matches.
                if (attributes[(__bridge id)kSecAttrAccount]) {
                    [allUsernames addObject:attributes[(__bridge id)kSecAttrAccount]];
                }
            }
            
            usernames = [allUsernames copy];
        } else if (queryResult[(__bridge id)kSecAttrAccount]) {
            // There was only one match.
            usernames = [NSSet setWithObject:queryResult[(__bridge id)kSecAttrAccount]];
        }
    }
    
    return usernames;
}

+ (NSString *)synchronizablePasswordWithUsername:(NSString *)username service:(NSString *)service;
{
    VALCheckCondition([self supportsSynchronizableKeychainItems], nil, @"Attempting to use synchronizable keychain calls from a pre iOS 7.0.3 device!");
    
    return [self _passwordWithUsername:username service:service options:@{ (__bridge id)kSecAttrSynchronizable : @YES }];
}

+ (NSString *)userPresenceRequiredPasswordWithPrompt:(NSString *)prompt forUsername:(NSString *)username service:(NSString *)service;
{
    VALCheckCondition([self supportsLocalAuthentication], nil, @"Attempting to use LocalAuthentication calls from a pre iOS 8.0 device!");
    VALCheckCondition(prompt.length > 0, nil, @"Can not access user presense password with an empty prompt!");
    
    return [self _passwordWithUsername:username service:service options:@{ (__bridge id)kSecUseOperationPrompt : prompt }];
}

+ (NSString *)passwordWithUsername:(NSString *)username service:(NSString *)service;
{
    return [self _passwordWithUsername:username service:service options:nil];
}

#pragma mark Private Class Methods

+ (NSString *)_passwordWithUsername:(NSString *)username service:(NSString *)service options:(NSDictionary *)options;
{
    VALCheckCondition(username.length > 0, nil, @"Can not retrieve password for empty username!");
    
    NSMutableDictionary *query = [self _mutableQueryWithService:service username:username options:options];
    query[(__bridge id)kSecMatchLimit] = (__bridge id)kSecMatchLimitOne;
    query[(__bridge id)kSecReturnData] = @YES;
    
    CFTypeRef outTypeRef = NULL;
    
    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)query, &outTypeRef);
    NSData *passwordData = (__bridge_transfer NSData *)outTypeRef;
    if (status == errSecSuccess) {
        return [[NSString alloc] initWithBytes:[passwordData bytes] length:[passwordData length] encoding:NSUTF8StringEncoding];
    }
    
    return nil;
}

+ (NSDictionary *)_secItemFormatDictionaryWithPassword:(NSString *)password;
{
    NSData *passwordData = [password dataUsingEncoding:NSUTF8StringEncoding];
    if (passwordData.length > 0) {
        return @{ (__bridge id)kSecValueData : passwordData };
    }
    
    return @{};
}

+ (NSMutableDictionary *)_mutableQueryWithService:(NSString *)service username:(NSString *)username options:(NSDictionary *)options;
{
    NSMutableDictionary *query = [NSMutableDictionary new];
    // SQKeychain only stores passwords.
    query[(__bridge id)kSecClass] = (__bridge id)kSecClassGenericPassword;
    
    VALCheckCondition(service.length > 0, nil, @"Expected a valid service");
    query[(__bridge id)kSecAttrService] = service;
    
    if (username.length > 0) {
        // Only add a account:username key:value pair if a username was supplied since username is an optional argument.
        query[(__bridge id)kSecAttrAccount] = username;
    }
    
    [query addEntriesFromDictionary:options];
    
    return query;
}

@end
