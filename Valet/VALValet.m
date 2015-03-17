//
//  VALValet.m
//  Valet
//
//  Created by Dan Federman on 3/16/15.
//  Copyright (c) 2015 Square, Inc. All rights reserved.
//

#import "VALValet.h"
#import "VALValet_Protected.h"


NSString *VALStringForAccessibility(VALAccessibility accessibility)
{
    switch (accessibility) {
        case VALAccessibleWhenUnlocked:
            return @"AccessibleWhenUnlocked";
        case VALAccessibleAfterFirstUnlock:
            return @"AccessibleAfterFirstUnlock";
        case VALAccessibleAlways:
            return @"AccessibleAlways";
        case VALAccessibleWhenPasscodeSetThisDeviceOnly:
            return @"AccessibleWhenPasscodeSetThisDeviceOnly";
        case VALAccessibleWhenUnlockedThisDeviceOnly:
            return @"AccessibleWhenUnlockedThisDeviceOnly";
        case VALAccessibleAfterFirstUnlockThisDeviceOnly:
            return @"AccessibleAfterFirstUnlockThisDeviceOnly";
        case VALAccessibleAlwaysThisDeviceOnly:
            return @"AccessibleAlwaysThisDeviceOnly";
        default:
            // Default to a secure option if we get something insane.
            return @"Unknown";
    }
}


@interface VALValet ()

@property (copy, readonly) NSDictionary *baseQuery;

@end


@implementation VALValet

#pragma mark - Initialization

- (instancetype)initWithIdentifier:(NSString *)identifier accessibility:(VALAccessibility)accessibility;
{
    VALCheckCondition(identifier.length > 0, nil, @"Valet requires a identifier");
    VALCheckCondition(accessibility > 0, nil, @"Valet requires a valid accessibility setting");
    
    self = [self init];
    if (self != nil) {
        _baseQuery = [[self mutableBaseQueryWithIdentifier:identifier initializer:_cmd accessibility:accessibility] copy];
        _identifier = [identifier copy];
        _sharedAcrossApplications = NO;
        _accessibility = accessibility;
    }
    
    return self;
}

- (instancetype)initWithSharedAccessGroupIdentifier:(NSString *)sharedAccessGroupIdentifier accessibility:(VALAccessibility)accessibility;
{
    VALCheckCondition(sharedAccessGroupIdentifier.length > 0, nil, @"Valet requires a sharedAccessGroupIdentifier");
    VALCheckCondition(accessibility > 0, nil, @"Valet requires a valid accessibility setting");
    
    self = [self init];
    if (self != nil) {
        NSMutableDictionary *baseQuery = [self mutableBaseQueryWithIdentifier:sharedAccessGroupIdentifier initializer:_cmd accessibility:accessibility];
        baseQuery[(__bridge id)kSecAttrAccessGroup] = [NSString stringWithFormat:@"%@.%@", [self _sharedAccessGroupPrefix], sharedAccessGroupIdentifier];
        
        _baseQuery = [baseQuery copy];
        _identifier = [sharedAccessGroupIdentifier copy];
        _sharedAcrossApplications = YES;
        _accessibility = accessibility;
    }
    
    return self;
}

#pragma mark - NSObject

- (BOOL)isEqual:(id)object;
{
    VALValet *otherValet = (VALValet *)object;
    return [self isMemberOfClass:[object class]] && [self.baseQuery isEqualToDictionary:otherValet.baseQuery];
}

- (NSString *)description;
{
    return [NSString stringWithFormat:@"%@: %@ %@%@", [super description], self.identifier, (self.sharedAcrossApplications ? @"Shared " : @""), VALStringForAccessibility(self.accessibility)];
}

#pragma mark - Public Methods

- (BOOL)canAccessKeychain;
{
    NSString *canaryKey = @"VAL_KeychainCanaryUsername";
    NSString *canaryValue = @"VAL_KeychainCanaryPassword";
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (![[self objectForKey:canaryKey] isEqual:canaryValue]) {
            [self setString:canaryValue forKey:canaryKey];
        }
    });
    
    NSString *const retrievedCanaryValue = [self stringForKey:canaryKey];
    return [retrievedCanaryValue isEqualToString:canaryValue];
}

- (BOOL)setObject:(NSData *)value forKey:(NSString *)key;
{
    return [self setObject:value forKey:key options:nil];
}

- (NSData *)objectForKey:(NSString *)key;
{
    return [self objectForKey:key options:nil];
}

- (BOOL)setString:(NSString *)string forKey:(NSString *)key;
{
    return [self setString:string forKey:key options:nil];
}

- (NSString *)stringForKey:(NSString *)key;
{
    return [self stringForKey:key options:nil];
}

- (BOOL)containsObjectForKey:(NSString *)key;
{
    OSStatus status = [self containsObjectForKey:key options:nil];
    BOOL keyAlreadyInKeychain = (status == errSecSuccess);
    return keyAlreadyInKeychain;
}

- (NSSet *)allKeys;
{
    return [self allKeysWithOptions:nil];
}

- (BOOL)removeObjectForKey:(NSString *)key;
{
    return [self removeObjectForKey:key options:nil];
}

- (BOOL)removeAllObjects;
{
    return [self removeAllObjectsWithOptions:nil];
}

#pragma mark Protected Methods

- (BOOL)supportsSynchronizableKeychainItems;
{
#if TARGET_IPHONE_SIMULATOR
    return NO;
#else
    return (&kSecAttrSynchronizable != NULL && &kSecAttrSynchronizableAny != NULL);
#endif
}

- (BOOL)supportsLocalAuthentication;
{
#if TARGET_IPHONE_SIMULATOR
    return NO;
#else
    return (&kSecAttrAccessControl != NULL && &kSecUseOperationPrompt != NULL);
#endif
}

- (NSMutableDictionary *)mutableBaseQueryWithIdentifier:(NSString *)identifier initializer:(SEL)initializer accessibility:(VALAccessibility)accessibility;
{
    return [@{
              // Valet only handles passwords.
              (__bridge id)kSecClass : (__bridge id)kSecClassGenericPassword,
              // Use the identifier, Valet type and accessibility settings to create the keychain service name.
              (__bridge id)kSecAttrService : [NSString stringWithFormat:@"VAL_%@_%@_%@_%@", NSStringFromClass([self class]), NSStringFromSelector(initializer), identifier, VALStringForAccessibility(accessibility)],
              // Set our accessibility.
              (__bridge id)kSecAttrAccessible : [self _secAccessibilityAttributeForAccessibility:accessibility],
              } mutableCopy];
}

- (BOOL)setObject:(NSData *)value forKey:(NSString *)key options:(NSDictionary *)options;
{
    VALCheckCondition(key.length > 0, NO, @"Can not set a value with an empty key.");
    VALCheckCondition(value != nil, NO, @"Can not set nil value");
    
    OSStatus status = errSecUnimplemented;
    NSMutableDictionary *query = [self.baseQuery mutableCopy];
    [query addEntriesFromDictionary:[self _secItemFormatDictionaryWithKey:key]];
    if (options.count > 0) {
        [query addEntriesFromDictionary:options];
    }
    
    if ([self containsObjectForKey:key]) {
        // The item already exists, so just update it.
        status = SecItemUpdate((__bridge CFDictionaryRef)query, (__bridge CFDictionaryRef)@{ (__bridge id)kSecValueData : value });
        
    } else {
        // No previous item found, add the new one.
        NSMutableDictionary *keychainData = [query mutableCopy];
        [keychainData addEntriesFromDictionary:@{ (__bridge id)kSecValueData : value }];
        
        status = SecItemAdd((__bridge CFDictionaryRef)keychainData, NULL);
    }
    
    return (status == errSecSuccess);
}

- (NSData *)objectForKey:(NSString *)key options:(NSDictionary *)options;
{
    VALCheckCondition(key.length > 0, nil, @"Can not retrieve value with empty key.");
    NSMutableDictionary *query = [self.baseQuery mutableCopy];
    [query addEntriesFromDictionary:[self _secItemFormatDictionaryWithKey:key]];
    [query addEntriesFromDictionary:@{ (__bridge id)kSecMatchLimit : (__bridge id)kSecMatchLimitOne,
                                       (__bridge id)kSecReturnData : @YES }];
    if (options.count > 0) {
        [query addEntriesFromDictionary:options];
    }
    
    CFTypeRef outTypeRef = NULL;
    
    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)query, &outTypeRef);
    NSData *value = (__bridge_transfer NSData *)outTypeRef;
    return (status == errSecSuccess) ? value : nil;
}

- (BOOL)setString:(NSString *)string forKey:(NSString *)key options:(NSDictionary *)options;
{
    VALCheckCondition(string.length > 0, nil, @"Can not set empty string for key.");
    NSData *stringData = [string dataUsingEncoding:NSUTF8StringEncoding];
    if (stringData.length > 0) {
        return [self setObject:stringData forKey:key options:options];
    }
    
    return NO;
}

- (NSString *)stringForKey:(NSString *)key options:(NSDictionary *)options;
{
    NSData *stringData = [self objectForKey:key options:options];
    if (stringData.length > 0) {
        return [[NSString alloc] initWithBytes:stringData.bytes length:stringData.length encoding:NSUTF8StringEncoding];
    }
    
    return nil;
}

- (OSStatus)containsObjectForKey:(NSString *)key options:(NSDictionary *)options;
{
    VALCheckCondition(key.length > 0, NO, @"Can not check if empty key exists in the keychain.");
    
    NSMutableDictionary *query = [self.baseQuery mutableCopy];
    [query addEntriesFromDictionary:[self _secItemFormatDictionaryWithKey:key]];
    if (options.count > 0) {
        [query addEntriesFromDictionary:options];
    }
    
    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)query, NULL);
    return status;
}

- (NSSet *)allKeysWithOptions:(NSDictionary *)options;
{
    NSSet *keys = nil;
    NSMutableDictionary *query = [self.baseQuery mutableCopy];
    [query addEntriesFromDictionary:@{ (__bridge id)kSecMatchLimit : (__bridge id)kSecMatchLimitAll,
                                       (__bridge id)kSecReturnAttributes : @YES }];
    if (options.count > 0) {
        [query addEntriesFromDictionary:options];
    }
    
    CFTypeRef outTypeRef = NULL;
    NSDictionary *queryResult = nil;
    
    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)query, &outTypeRef);
    queryResult = (__bridge_transfer NSDictionary *)outTypeRef;
    if (status == errSecSuccess) {
        if ([queryResult isKindOfClass:[NSArray class]]) {
            NSMutableSet *allKeys = [NSMutableSet new];
            for (NSDictionary *attributes in queryResult) {
                // There were many matches.
                if (attributes[(__bridge id)kSecAttrAccount]) {
                    [allKeys addObject:attributes[(__bridge id)kSecAttrAccount]];
                }
            }
            
            keys = [allKeys copy];
        } else if (queryResult[(__bridge id)kSecAttrAccount]) {
            // There was only one match.
            keys = [NSSet setWithObject:queryResult[(__bridge id)kSecAttrAccount]];
        }
    }
    
    return keys;
}

- (BOOL)removeObjectForKey:(NSString *)key options:(NSDictionary *)options;
{
    VALCheckCondition(key.length > 0, NO, @"Can not remove object for empty key from the keychain.");
    
    NSMutableDictionary *query = [self.baseQuery mutableCopy];
    [query addEntriesFromDictionary:[self _secItemFormatDictionaryWithKey:key]];
    if (options.count > 0) {
        [query addEntriesFromDictionary:options];
    }
    
    OSStatus status = SecItemDelete((__bridge CFDictionaryRef)query);
    // We succeeded as long as we can confirm that the item is not in the keychain.
    return (status != errSecInteractionNotAllowed);
}

- (BOOL)removeAllObjectsWithOptions:(NSDictionary *)options;
{
    for (NSString *key in [self allKeys]) {
        if (![self removeObjectForKey:key options:options]) {
            return NO;
        }
    }
    
    return YES;
}

#pragma mark Private Methods

/// Programatically grab the required prefix for the shared access group (i.e. Bundle Seed ID). The value for the kSecAttrAccessGroup key in queries for data that is shared between apps must be of the format bundleSeedID.sharedAccessGroup. For more information on the Bundle Seed ID, see https://developer.apple.com/library/ios/qa/qa1713/_index.html
- (NSString *)_sharedAccessGroupPrefix;
{
    NSDictionary *query = @{ (__bridge NSString *)kSecClass : (__bridge NSString *)kSecClassGenericPassword,
                             (__bridge id)kSecAttrAccount : @"SharedAccessGroupPrefixPlaceholder",
                             (__bridge id)kSecReturnAttributes : @YES };
    
    CFTypeRef outTypeRef = NULL;
    NSDictionary *queryResult = nil;
    
    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)query, &outTypeRef);
    queryResult = (__bridge_transfer NSDictionary *)outTypeRef;
    
    if (status == errSecItemNotFound) {
        status = SecItemAdd((__bridge CFDictionaryRef)query, &outTypeRef);
        queryResult = (__bridge_transfer NSDictionary *)outTypeRef;
    }
    
    if (status == errSecSuccess) {
        NSString *accessGroup = queryResult[(__bridge id)kSecAttrAccessGroup];
        NSArray *components = [accessGroup componentsSeparatedByString:@"."];
        NSString *bundleSeedID = components.firstObject;
        
        return bundleSeedID;
    }
    
    return nil;
}

- (id)_secAccessibilityAttributeForAccessibility:(VALAccessibility)accessibility;
{
    switch (accessibility) {
        case VALAccessibleWhenUnlocked:
            return (__bridge id)kSecAttrAccessibleWhenUnlocked;
        case VALAccessibleAfterFirstUnlock:
            return (__bridge id)kSecAttrAccessibleAfterFirstUnlock;
        case VALAccessibleAlways:
            return (__bridge id)kSecAttrAccessibleAlways;
        case VALAccessibleWhenPasscodeSetThisDeviceOnly:
            return (__bridge id)kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly;
        case VALAccessibleWhenUnlockedThisDeviceOnly:
            return (__bridge id)kSecAttrAccessibleWhenUnlockedThisDeviceOnly;
        case VALAccessibleAfterFirstUnlockThisDeviceOnly:
            return (__bridge id)kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly;
        case VALAccessibleAlwaysThisDeviceOnly:
            return (__bridge id)kSecAttrAccessibleAlwaysThisDeviceOnly;
        default:
            // Default to a secure option if we get something insane.
            VALCheckCondition(NO, (__bridge id)kSecAttrAccessibleWhenUnlockedThisDeviceOnly, @"Unexpected accessibility option %@", @(accessibility));
    }
}

- (NSDictionary *)_secItemFormatDictionaryWithKey:(NSString *)key;
{
    if (key.length > 0) {
        return @{ (__bridge id)kSecAttrAccount : key };
    }
    
    return @{};
}

@end
