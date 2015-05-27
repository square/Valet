//
//  VALValet.m
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

#import "VALValet.h"
#import "VALValet_Protected.h"

#import "ValetDefines.h"


NSString * const VALMigrationErrorDomain = @"VALMigrationErrorDomain";


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
    }
}

/// We can't be sure that SecItem calls are atomic, so ensure atomicity ourselves.
void VALAtomicSecItemLock(dispatch_block_t block)
{
    VALCheckCondition(block != NULL, , @"Must pass in a block");
    
    static NSLock *sSecItemLock = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sSecItemLock = [NSLock new];
    });
    
    [sSecItemLock lock];
    block();
    [sSecItemLock unlock];
}

OSStatus VALAtomicSecItemCopyMatching(CFDictionaryRef query, CFTypeRef *result)
{
    VALCheckCondition(CFDictionaryGetCount(query) > 0, errSecParam, @"Must provide a query with at least one item");
    
    __block OSStatus status = errSecNotAvailable;
    VALAtomicSecItemLock(^{
        status = SecItemCopyMatching(query, result);
    });
    
    return status;
}

OSStatus VALAtomicSecItemAdd(CFDictionaryRef attributes, CFTypeRef *result)
{
    VALCheckCondition(CFDictionaryGetCount(attributes) > 0, errSecParam, @"Must provide attributes with at least one item");
    
    __block OSStatus status = errSecNotAvailable;
    VALAtomicSecItemLock(^{
        status = SecItemAdd(attributes, result);
    });
    
    return status;
}

OSStatus VALAtomicSecItemUpdate(CFDictionaryRef query, CFDictionaryRef attributesToUpdate)
{
    VALCheckCondition(CFDictionaryGetCount(query) > 0, errSecParam, @"Must provide a query with at least one item");
    VALCheckCondition(CFDictionaryGetCount(attributesToUpdate) > 0, errSecParam, @"Must provide a attributesToUpdate with at least one item");
    
    __block OSStatus status = errSecNotAvailable;
    VALAtomicSecItemLock(^{
        status = SecItemUpdate(query, attributesToUpdate);
    });
    
    return status;
}

OSStatus VALAtomicSecItemDelete(CFDictionaryRef query)
{
    VALCheckCondition(CFDictionaryGetCount(query) > 0, errSecParam, @"Must provide a query with at least one item");
    
    __block OSStatus status = errSecNotAvailable;
    VALAtomicSecItemLock(^{
        status = SecItemDelete(query);
    });
    
    return status;
}


@interface VALValet ()

/// Stores the root query to be used in all SecItem queries.
@property (copy, readonly) NSDictionary *baseQuery;

/// Set and Remove must be atomic operations relative to one another to ensure that SecItemUpdate is never called on an item that has been removed from the keychain.
@property (copy, readonly) NSLock *lockForSetAndRemoveOperations;

@end


@implementation VALValet

#pragma mark - Initialization

- (instancetype)initWithIdentifier:(NSString *)identifier accessibility:(VALAccessibility)accessibility;
{
    VALCheckCondition(identifier.length > 0, nil, @"Valet requires an identifier");
    VALCheckCondition(accessibility > 0, nil, @"Valet requires a valid accessibility setting");
    
    self = [super init];
    if (self != nil) {
        _baseQuery = [[self mutableBaseQueryWithIdentifier:identifier initializer:_cmd accessibility:accessibility] copy];
        _identifier = [identifier copy];
        _sharedAcrossApplications = NO;
        _accessibility = accessibility;
        _lockForSetAndRemoveOperations = [NSLock new];
    }
    
    return self;
}

- (instancetype)initWithSharedAccessGroupIdentifier:(NSString *)sharedAccessGroupIdentifier accessibility:(VALAccessibility)accessibility;
{
    VALCheckCondition(sharedAccessGroupIdentifier.length > 0, nil, @"Valet requires a sharedAccessGroupIdentifier");
    VALCheckCondition(accessibility > 0, nil, @"Valet requires a valid accessibility setting");
    
    self = [super init];
    if (self != nil) {
        NSMutableDictionary *baseQuery = [self mutableBaseQueryWithIdentifier:sharedAccessGroupIdentifier initializer:_cmd accessibility:accessibility];
        baseQuery[(__bridge id)kSecAttrAccessGroup] = [NSString stringWithFormat:@"%@.%@", [self _sharedAccessGroupPrefix], sharedAccessGroupIdentifier];
        
        _baseQuery = [baseQuery copy];
        _identifier = [sharedAccessGroupIdentifier copy];
        _sharedAcrossApplications = YES;
        _accessibility = accessibility;
        _lockForSetAndRemoveOperations = [NSLock new];
    }
    
    return self;
}

#pragma mark - NSObject

- (BOOL)isEqual:(id)object;
{
    VALValet *otherValet = (VALValet *)object;
    return [self isMemberOfClass:[object class]] && [self.baseQuery isEqualToDictionary:otherValet.baseQuery];
}

- (NSUInteger)hash;
{
    return [self.baseQuery[(__bridge id)kSecAttrService] hash];
}

- (NSString *)description;
{
    return [NSString stringWithFormat:@"%@: %@ %@%@", [super description], self.identifier, (self.sharedAcrossApplications ? @"Shared " : @""), VALStringForAccessibility(self.accessibility)];
}

#pragma mark - NSCopying

- (instancetype)copyWithZone:(NSZone *)zone;
{
    // We're immutable, so just return self.
    return self;
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
    BOOL const keyAlreadyInKeychain = (status == errSecSuccess);
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

- (NSError *)migrateObjectsMatchingQuery:(NSDictionary *)secItemQuery removeOnCompletion:(BOOL)remove;
{
    VALCheckCondition(secItemQuery.allKeys.count > 0, [NSError errorWithDomain:VALMigrationErrorDomain code:VALMigrationInvalidQueryError userInfo:nil], @"Migration requires secItemQuery to contain values.");
    VALCheckCondition(secItemQuery[(__bridge id)kSecMatchLimit] != (__bridge id)kSecMatchLimitOne, [NSError errorWithDomain:VALMigrationErrorDomain code:VALMigrationInvalidQueryError userInfo:nil], @"Migration requires kSecMatchLimit to be set to kSecMatchLimitAll.");
    VALCheckCondition(secItemQuery[(__bridge id)kSecReturnData] != (__bridge id)kCFBooleanFalse, [NSError errorWithDomain:VALMigrationErrorDomain code:VALMigrationInvalidQueryError userInfo:nil], @"Migration requires kSecReturnData to be set to kCFBooleanTrue.");
    VALCheckCondition(secItemQuery[(__bridge id)kSecReturnAttributes] != (__bridge id)kCFBooleanFalse, [NSError errorWithDomain:VALMigrationErrorDomain code:VALMigrationInvalidQueryError userInfo:nil], @"Migration requires kSecReturnAttributes to be set to kCFBooleanTrue.");
    VALCheckCondition(secItemQuery[(__bridge id)kSecReturnRef] != (__bridge id)kCFBooleanTrue, [NSError errorWithDomain:VALMigrationErrorDomain code:VALMigrationInvalidQueryError userInfo:nil], @"kSecReturnRef is not supported in a migration query. Valet can only consume Data values.");
    VALCheckCondition(secItemQuery[(__bridge id)kSecReturnPersistentRef] != (__bridge id)kCFBooleanTrue, [NSError errorWithDomain:VALMigrationErrorDomain code:VALMigrationInvalidQueryError userInfo:nil], @"kSecReturnPersistentRef is not supported in a migration query. Valet can only consume Data values.");
    
    NSMutableDictionary *query = [secItemQuery mutableCopy];
    query[(__bridge id)kSecMatchLimit] = (__bridge id)kSecMatchLimitAll;
    query[(__bridge id)kSecReturnData] = @YES;
    query[(__bridge id)kSecReturnAttributes] = @YES;
    query[(__bridge id)kSecReturnRef] = @NO;
    query[(__bridge id)kSecReturnPersistentRef] = @NO;
    
    CFTypeRef outTypeRef = NULL;
    NSDictionary *queryResult = nil;
    
    OSStatus status = VALAtomicSecItemCopyMatching((__bridge CFDictionaryRef)query, &outTypeRef);
    queryResult = (__bridge_transfer NSDictionary *)outTypeRef;
    if (status == errSecItemNotFound) {
        return [NSError errorWithDomain:VALMigrationErrorDomain code:VALMigrationNoItemsToMigrateFoundError userInfo:nil];;
    }
    
    VALCheckCondition(status == errSecSuccess, [NSError errorWithDomain:VALMigrationErrorDomain code:VALMigrationCouldNotReadKeychainError userInfo:nil], @"Could not copy items matching secItemQuery");
    
    // Sanity check that we are capable of migrating the data.
    NSMutableSet *keysToMigrate = [NSMutableSet new];
    for (NSDictionary *keychainEntry in queryResult) {
        NSString *key = keychainEntry[(__bridge id)kSecAttrAccount];
        NSData *data = keychainEntry[(__bridge id)kSecValueData];
        
        VALCheckCondition(key.length > 0, [NSError errorWithDomain:VALMigrationErrorDomain code:VALMigrationKeyInQueryResultInvalidError userInfo:nil], @"Can not migrate keychain entry with no key");
        VALCheckCondition(data.length > 0, [NSError errorWithDomain:VALMigrationErrorDomain code:VALMigrationDataInQueryResultInvalidError userInfo:nil], @"Can not migrate keychain entry with no value data");
        VALCheckCondition(![keysToMigrate containsObject:key], [NSError errorWithDomain:VALMigrationErrorDomain code:VALMigrationDuplicateKeyInQueryResultError userInfo:nil], @"Can not migrate keychain entry for key %@ since there are multiple values for key %@ in query %@", key, key, secItemQuery);
        VALCheckCondition(![self containsObjectForKey:key], [NSError errorWithDomain:VALMigrationErrorDomain code:VALMigrationKeyInQueryResultAlreadyExistsInValetError userInfo:nil], @"Can not migrate keychain entry for key %@ since %@ already exists in %@", key, key, self);
        [keysToMigrate addObject:key];
    }
    
    // If all looks good, actually migrate.
    NSMutableArray *alreadyMigratedKeys = [NSMutableArray new];
    for (NSDictionary *keychainEntry in queryResult) {
        NSString *key = keychainEntry[(__bridge id)kSecAttrAccount];
        NSData *data = keychainEntry[(__bridge id)kSecValueData];
        
        if ([self setObject:data forKey:key]) {
            [alreadyMigratedKeys addObject:key];
            
        } else {
            // Something went wrong. Remove all migrated items.
            for (NSString *key in alreadyMigratedKeys) {
                [self removeObjectForKey:key];
            }
            
            return [NSError errorWithDomain:VALMigrationErrorDomain code:VALMigrationCouldNotWriteToKeychainError userInfo:nil];
        }
    }
    
    // Remove data if requested.
    if (remove) {
        status = VALAtomicSecItemDelete((__bridge CFDictionaryRef)secItemQuery);
        if (status != errSecSuccess) {
            // Something went wrong. Remove all migrated items.
            for (NSString *key in alreadyMigratedKeys) {
                [self removeObjectForKey:key];
            }
            
            return [NSError errorWithDomain:VALMigrationErrorDomain code:VALMigrationRemovalFailedError userInfo:nil];
        }
    }
    
    return nil;
}

- (NSError *)migrateObjectsFromValet:(VALValet *)valet removeOnCompletion:(BOOL)remove;
{
    return [self migrateObjectsMatchingQuery:valet.baseQuery removeOnCompletion:remove];
}

#pragma mark - Protected Methods

- (NSMutableDictionary *)mutableBaseQueryWithIdentifier:(NSString *)identifier initializer:(SEL)initializer accessibility:(VALAccessibility)accessibility;
{
    return [@{
              // Valet only handles generic passwords.
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
    VALCheckCondition(value.length > 0, NO, @"Can not set an empty value.");
    
    NSMutableDictionary *query = [self.baseQuery mutableCopy];
    [query addEntriesFromDictionary:[self _secItemFormatDictionaryWithKey:key]];
    if (options.count > 0) {
        [query addEntriesFromDictionary:options];
    }
    
    OSStatus status = errSecNotAvailable;
    [self.lockForSetAndRemoveOperations lock];
    {
        if ([self containsObjectForKey:key]) {
            // The item already exists, so just update it.
            status = VALAtomicSecItemUpdate((__bridge CFDictionaryRef)query, (__bridge CFDictionaryRef)@{ (__bridge id)kSecValueData : value });
            
        } else {
            // No previous item found, add the new one.
            NSMutableDictionary *keychainData = [query mutableCopy];
            [keychainData addEntriesFromDictionary:@{ (__bridge id)kSecValueData : value }];
            
            status = VALAtomicSecItemAdd((__bridge CFDictionaryRef)keychainData, NULL);
        }
    }
    [self.lockForSetAndRemoveOperations unlock];
    
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
    
    OSStatus status = VALAtomicSecItemCopyMatching((__bridge CFDictionaryRef)query, &outTypeRef);
    NSData *value = (__bridge_transfer NSData *)outTypeRef;
    return (status == errSecSuccess) ? value : nil;
}

- (BOOL)setString:(NSString *)string forKey:(NSString *)key options:(NSDictionary *)options;
{
    VALCheckCondition(string.length > 0, NO, @"Can not set empty string for key.");
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
    VALCheckCondition(key.length > 0, errSecParam, @"Can not check if empty key exists in the keychain.");
    
    NSMutableDictionary *query = [self.baseQuery mutableCopy];
    [query addEntriesFromDictionary:[self _secItemFormatDictionaryWithKey:key]];
    if (options.count > 0) {
        [query addEntriesFromDictionary:options];
    }
    
    OSStatus status = VALAtomicSecItemCopyMatching((__bridge CFDictionaryRef)query, NULL);
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
    
    OSStatus status = VALAtomicSecItemCopyMatching((__bridge CFDictionaryRef)query, &outTypeRef);
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
    
    OSStatus status = errSecNotAvailable;
    [self.lockForSetAndRemoveOperations lock];
    {
        status = VALAtomicSecItemDelete((__bridge CFDictionaryRef)query);
    }
    [self.lockForSetAndRemoveOperations unlock];
    
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

#pragma mark - Private Methods

/// Programatically grab the required prefix for the shared access group (i.e. Bundle Seed ID). The value for the kSecAttrAccessGroup key in queries for data that is shared between apps must be of the format bundleSeedID.sharedAccessGroup. For more information on the Bundle Seed ID, see https://developer.apple.com/library/ios/qa/qa1713/_index.html
- (NSString *)_sharedAccessGroupPrefix;
{
    NSDictionary *query = @{ (__bridge NSString *)kSecClass : (__bridge NSString *)kSecClassGenericPassword,
                             (__bridge id)kSecAttrAccount : @"SharedAccessGroupPrefixPlaceholder",
                             (__bridge id)kSecReturnAttributes : @YES };
    
    CFTypeRef outTypeRef = NULL;
    NSDictionary *queryResult = nil;
    
    OSStatus status = VALAtomicSecItemCopyMatching((__bridge CFDictionaryRef)query, &outTypeRef);
    queryResult = (__bridge_transfer NSDictionary *)outTypeRef;
    
    if (status == errSecItemNotFound) {
        status = VALAtomicSecItemAdd((__bridge CFDictionaryRef)query, &outTypeRef);
        queryResult = (__bridge_transfer NSDictionary *)outTypeRef;
    }
    
    VALCheckCondition(status == errSecSuccess, nil, @"Could not find shared access group prefix.");
    
    NSString *accessGroup = queryResult[(__bridge id)kSecAttrAccessGroup];
    NSArray *components = [accessGroup componentsSeparatedByString:@"."];
    NSString *bundleSeedID = components.firstObject;
    
    return bundleSeedID;
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
    }
}

- (NSDictionary *)_secItemFormatDictionaryWithKey:(NSString *)key;
{
    VALCheckCondition(key.length > 0, @{}, @"Must provide a valid key");
    return @{ (__bridge id)kSecAttrAccount : key };
}

@end
