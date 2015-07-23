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
        case VALAccessibilityWhenUnlocked:
            return @"AccessibleWhenUnlocked";
        case VALAccessibilityAfterFirstUnlock:
            return @"AccessibleAfterFirstUnlock";
        case VALAccessibilityAlways:
            return @"AccessibleAlways";
#if VAL_IOS_8_OR_LATER || __MAC_10_10
        case VALAccessibilityWhenPasscodeSetThisDeviceOnly:
            return @"AccessibleWhenPasscodeSetThisDeviceOnly";
#endif
        case VALAccessibilityWhenUnlockedThisDeviceOnly:
            return @"AccessibleWhenUnlockedThisDeviceOnly";
        case VALAccessibilityAfterFirstUnlockThisDeviceOnly:
            return @"AccessibleAfterFirstUnlockThisDeviceOnly";
        case VALAccessibilityAlwaysThisDeviceOnly:
            return @"AccessibleAlwaysThisDeviceOnly";
    }
}

void VALExecuteBlockInLock(dispatch_block_t block, NSLock *lock)
{
    VALCheckCondition(block != NULL, , @"Must pass in a block");
    VALCheckCondition(lock != nil, , @"Must pass in a lock");
    
    [lock lock];
    @try {
        block();
    }
    @finally {
        [lock unlock];
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
    
    VALExecuteBlockInLock(block, sSecItemLock);
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

/// The service identifier within the baseQuery (kSecAttrService).
@property (copy, readonly) NSString *secServiceIdentifier;

/// Set and Remove must be atomic operations relative to one another to ensure that SecItemUpdate is never called on an item that has been removed from the keychain.
@property (copy, readonly) NSLock *lockForSetAndRemoveOperations;

@end


@implementation VALValet

#pragma mark - Private Class Methods

/// Ensure the atomicity for set and remove operations by limiting ourselves to one instance per configuration.
+ (VALValet *)_sharedValetForValet:(VALValet *)valet;
{
    @synchronized(self) {
        static NSMapTable *sServiceIdentifierToWeakValet = nil;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            sServiceIdentifierToWeakValet = [NSMapTable strongToWeakObjectsMapTable];
        });
        
        VALValet *existingValet = [sServiceIdentifierToWeakValet objectForKey:valet.secServiceIdentifier];
        if (existingValet != nil) {
            return existingValet;
        }
        
        [sServiceIdentifierToWeakValet setObject:valet forKey:valet.secServiceIdentifier];
        return valet;
    }
}

#pragma mark - Initialization

- (nullable instancetype)init NS_UNAVAILABLE;
{
    VALCheckCondition(NO, nil, @"Use a designated initializer");
}

- (nullable instancetype)initWithIdentifier:(nonnull NSString *)identifier accessibility:(VALAccessibility)accessibility;
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
    
    return [[self class] _sharedValetForValet:self];
}

- (nullable instancetype)initWithSharedAccessGroupIdentifier:(nonnull NSString *)sharedAccessGroupIdentifier accessibility:(VALAccessibility)accessibility;
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
    
    return [[self class] _sharedValetForValet:self];
}

#pragma mark - NSObject

- (BOOL)isEqual:(id)object;
{
    VALValet *otherValet = (VALValet *)object;
    return [otherValet isKindOfClass:[VALValet class]] && [self isEqualToValet:otherValet];
}

- (NSUInteger)hash;
{
    return [self.secServiceIdentifier hash];
}

- (NSString *)description;
{
    return [NSString stringWithFormat:@"%@: %@ %@%@", [super description], self.identifier, (self.sharedAcrossApplications ? @"Shared " : @""), VALStringForAccessibility(self.accessibility)];
}

#pragma mark - NSCopying

- (nonnull instancetype)copyWithZone:(nullable NSZone *)zone;
{
    // We're immutable, so just return self.
    return self;
}

#pragma mark - Public Methods

- (BOOL)isEqualToValet:(nonnull VALValet *)otherValet;
{
    return [self.baseQuery isEqualToDictionary:otherValet.baseQuery];
}

- (BOOL)canAccessKeychain;
{
    __block BOOL canAccessKeychain = NO;
    VALExecuteBlockInLock(^{
        NSString *const canaryKey = @"VAL_KeychainCanaryUsername";
        NSString *const canaryValue = @"VAL_KeychainCanaryPassword";
        
        // Manually add the key to the keychain since we don't care about duplicates and are optimizing for speed.
        NSMutableDictionary *query = [self.baseQuery mutableCopy];
        [query addEntriesFromDictionary:[self _secItemFormatDictionaryWithKey:canaryKey]];
        query[(__bridge id)kSecValueData] = [canaryValue dataUsingEncoding:NSUTF8StringEncoding];
        (void)VALAtomicSecItemAdd((__bridge CFDictionaryRef)query, NULL);
        
        NSString *const retrievedCanaryValue = [self stringForKey:canaryKey];
        canAccessKeychain = [canaryValue isEqualToString:retrievedCanaryValue];
    }, self.lockForSetAndRemoveOperations);
    
    return canAccessKeychain;
}

- (BOOL)setObject:(nonnull NSData *)value forKey:(nonnull NSString *)key;
{
    return [self setObject:value forKey:key options:nil];
}

- (nullable NSData *)objectForKey:(nonnull NSString *)key;
{
    return [self objectForKey:key options:nil];
}

- (BOOL)setString:(nonnull NSString *)string forKey:(nonnull NSString *)key;
{
    return [self setString:string forKey:key options:nil];
}

- (nullable NSString *)stringForKey:(nonnull NSString *)key;
{
    return [self stringForKey:key options:nil];
}

- (BOOL)containsObjectForKey:(nonnull NSString *)key;
{
    OSStatus status = [self containsObjectForKey:key options:nil];
    BOOL const keyAlreadyInKeychain = (status == errSecSuccess);
    return keyAlreadyInKeychain;
}

- (nonnull NSSet *)allKeys;
{
    return [self allKeysWithOptions:nil];
}

#pragma mark - Public Methods - Removal

- (BOOL)removeObjectForKey:(NSString *)key;
{
    return [self removeObjectForKey:key options:nil];
}

- (BOOL)removeAllObjects;
{
    return [self removeAllObjectsWithOptions:nil];
}

#pragma mark - Public Methods - Migration

- (nullable NSError *)migrateObjectsMatchingQuery:(nonnull NSDictionary *)secItemQuery removeOnCompletion:(BOOL)remove;
{
    VALCheckCondition(secItemQuery.allKeys.count > 0, [NSError errorWithDomain:VALMigrationErrorDomain code:VALMigrationErrorInvalidQuery userInfo:nil], @"Migration requires secItemQuery to contain values.");
    VALCheckCondition(secItemQuery[(__bridge id)kSecMatchLimit] != (__bridge id)kSecMatchLimitOne, [NSError errorWithDomain:VALMigrationErrorDomain code:VALMigrationErrorInvalidQuery userInfo:nil], @"Migration requires kSecMatchLimit to be set to kSecMatchLimitAll.");
    VALCheckCondition(secItemQuery[(__bridge id)kSecReturnData] != (__bridge id)kCFBooleanTrue, [NSError errorWithDomain:VALMigrationErrorDomain code:VALMigrationErrorInvalidQuery userInfo:nil], @"kSecReturnData is not supported in a migration query.");
    VALCheckCondition(secItemQuery[(__bridge id)kSecReturnAttributes] != (__bridge id)kCFBooleanFalse, [NSError errorWithDomain:VALMigrationErrorDomain code:VALMigrationErrorInvalidQuery userInfo:nil], @"Migration requires kSecReturnAttributes to be set to kCFBooleanTrue.");
    VALCheckCondition(secItemQuery[(__bridge id)kSecReturnRef] != (__bridge id)kCFBooleanTrue, [NSError errorWithDomain:VALMigrationErrorDomain code:VALMigrationErrorInvalidQuery userInfo:nil], @"kSecReturnRef is not supported in a migration query.");
    VALCheckCondition(secItemQuery[(__bridge id)kSecReturnPersistentRef] != (__bridge id)kCFBooleanFalse, [NSError errorWithDomain:VALMigrationErrorDomain code:VALMigrationErrorInvalidQuery userInfo:nil], @"Migration requires SecReturnPersistentRef to be set to kCFBooleanTrue.");
    
    NSMutableDictionary *query = [secItemQuery mutableCopy];
    query[(__bridge id)kSecMatchLimit] = (__bridge id)kSecMatchLimitAll;
    query[(__bridge id)kSecReturnAttributes] = @YES;
    query[(__bridge id)kSecReturnData] = @NO;
    query[(__bridge id)kSecReturnRef] = @NO;
    query[(__bridge id)kSecReturnPersistentRef] = @YES;
    
    CFTypeRef outTypeRef = NULL;
    NSArray *queryResult = nil;
    
    OSStatus status = VALAtomicSecItemCopyMatching((__bridge CFDictionaryRef)query, &outTypeRef);
    queryResult = (__bridge_transfer NSArray *)outTypeRef;
    if (status == errSecItemNotFound) {
        return [NSError errorWithDomain:VALMigrationErrorDomain code:VALMigrationErrorNoItemsToMigrateFound userInfo:nil];;
    }
    
    VALCheckCondition(status == errSecSuccess, [NSError errorWithDomain:VALMigrationErrorDomain code:VALMigrationErrorCouldNotReadKeychain userInfo:nil], @"Could not copy items matching secItemQuery");
    
    // Now that we have the persistent refs with attributes, get the data associated with each keychain entry.
    NSMutableArray *queryResultWithData = [NSMutableArray new];
    for (NSDictionary *keychainEntry in queryResult) {
        CFTypeRef outValueRef = NULL;
        status = VALAtomicSecItemCopyMatching((__bridge CFDictionaryRef)@{ (__bridge id)kSecValuePersistentRef : keychainEntry[(__bridge id)kSecValuePersistentRef], (__bridge id)kSecReturnData : @YES }, &outValueRef);
        NSData *data = (__bridge_transfer NSData *)outValueRef;
        
        VALCheckCondition(status == errSecSuccess, [NSError errorWithDomain:VALMigrationErrorDomain code:VALMigrationErrorCouldNotReadKeychain userInfo:nil], @"Could not copy items matching secItemQuery");
        VALCheckCondition(data.length > 0, [NSError errorWithDomain:VALMigrationErrorDomain code:VALMigrationErrorDataInQueryResultInvalid userInfo:nil], @"Can not migrate keychain entry with no value data");
        
        NSMutableDictionary *keychainEntryWithData = [keychainEntry mutableCopy];
        keychainEntryWithData[(__bridge id)kSecValueData] = data;
        
        [queryResultWithData addObject:keychainEntryWithData];
    }
    
    // Sanity check that we are capable of migrating the data.
    NSMutableSet *keysToMigrate = [NSMutableSet new];
    for (NSDictionary *keychainEntry in queryResultWithData) {
        NSString *key = keychainEntry[(__bridge id)kSecAttrAccount];
        NSData *data = keychainEntry[(__bridge id)kSecValueData];
        
        VALCheckCondition(key.length > 0, [NSError errorWithDomain:VALMigrationErrorDomain code:VALMigrationErrorKeyInQueryResultInvalid userInfo:nil], @"Can not migrate keychain entry with no key");
        VALCheckCondition(data.length > 0, [NSError errorWithDomain:VALMigrationErrorDomain code:VALMigrationErrorDataInQueryResultInvalid userInfo:nil], @"Can not migrate keychain entry with no value data");
        VALCheckCondition(![keysToMigrate containsObject:key], [NSError errorWithDomain:VALMigrationErrorDomain code:VALMigrationErrorDuplicateKeyInQueryResult userInfo:nil], @"Can not migrate keychain entry for key %@ since there are multiple values for key %@ in query %@", key, key, secItemQuery);
        VALCheckCondition(![self containsObjectForKey:key], [NSError errorWithDomain:VALMigrationErrorDomain code:VALMigrationErrorKeyInQueryResultAlreadyExistsInValet userInfo:nil], @"Can not migrate keychain entry for key %@ since %@ already exists in %@", key, key, self);
        [keysToMigrate addObject:key];
    }
    
    // If all looks good, actually migrate.
    NSMutableArray *alreadyMigratedKeys = [NSMutableArray new];
    for (NSDictionary *keychainEntry in queryResultWithData) {
        NSString *key = keychainEntry[(__bridge id)kSecAttrAccount];
        NSData *data = keychainEntry[(__bridge id)kSecValueData];
        
        if ([self setObject:data forKey:key]) {
            [alreadyMigratedKeys addObject:key];
            
        } else {
            // Something went wrong. Remove all migrated items.
            for (NSString *key in alreadyMigratedKeys) {
                [self removeObjectForKey:key];
            }
            
            return [NSError errorWithDomain:VALMigrationErrorDomain code:VALMigrationErrorCouldNotWriteToKeychain userInfo:nil];
        }
    }
    
    // Remove data if requested.
    if (remove) {
        NSMutableDictionary *removeQuery = [secItemQuery mutableCopy];
#if !TARGET_OS_IPHONE
        // This line must exist on OS X, but must not exist on iOS.
        removeQuery[(__bridge id)kSecMatchLimit] = (__bridge id)kSecMatchLimitAll;
#endif
        
        status = VALAtomicSecItemDelete((__bridge CFDictionaryRef)removeQuery);
        if (status != errSecSuccess) {
            // Something went wrong. Remove all migrated items.
            for (NSString *key in alreadyMigratedKeys) {
                [self removeObjectForKey:key];
            }
            
            return [NSError errorWithDomain:VALMigrationErrorDomain code:VALMigrationErrorRemovalFailed userInfo:nil];
        }
    }
    
    return nil;
}

- (nullable NSError *)migrateObjectsFromValet:(VALValet *)valet removeOnCompletion:(BOOL)remove;
{
    return [self migrateObjectsMatchingQuery:valet.baseQuery removeOnCompletion:remove];
}

#pragma mark - Protected Methods

- (nonnull NSMutableDictionary *)mutableBaseQueryWithIdentifier:(nonnull NSString *)identifier initializer:(SEL)initializer accessibility:(VALAccessibility)accessibility;
{
    VALCheckCondition(identifier.length > 0, nil, @"Must provide a valid identifier");
    
    return [@{
              // Valet only handles generic passwords.
              (__bridge id)kSecClass : (__bridge id)kSecClassGenericPassword,
              // Use the identifier, Valet type and accessibility settings to create the keychain service name.
              (__bridge id)kSecAttrService : [NSString stringWithFormat:@"VAL_%@_%@_%@_%@", NSStringFromClass([self class]), NSStringFromSelector(initializer), identifier, VALStringForAccessibility(accessibility)],
              // Set our accessibility.
              (__bridge id)kSecAttrAccessible : [self _secAccessibilityAttributeForAccessibility:accessibility],
              } mutableCopy];
}

- (BOOL)setObject:(nonnull NSData *)value forKey:(nonnull NSString *)key options:(nullable NSDictionary *)options;
{
    VALCheckCondition(key.length > 0, NO, @"Can not set a value with an empty key.");
    VALCheckCondition(value.length > 0, NO, @"Can not set an empty value.");
    
    NSMutableDictionary *query = [self.baseQuery mutableCopy];
    [query addEntriesFromDictionary:[self _secItemFormatDictionaryWithKey:key]];
    if (options.count > 0) {
        [query addEntriesFromDictionary:options];
    }
    
    __block OSStatus status = errSecNotAvailable;
#if TARGET_OS_IPHONE
    VALExecuteBlockInLock(^{
        if ([self containsObjectForKey:key]) {
            // The item already exists, so just update it.
            status = VALAtomicSecItemUpdate((__bridge CFDictionaryRef)query, (__bridge CFDictionaryRef)@{ (__bridge id)kSecValueData : value });
            
        } else {
            // No previous item found, add the new one.
            NSMutableDictionary *keychainData = [query mutableCopy];
            keychainData[(__bridge id)kSecValueData] = value;
            
            status = VALAtomicSecItemAdd((__bridge CFDictionaryRef)keychainData, NULL);
        }
    }, self.lockForSetAndRemoveOperations);
#else
    VALExecuteBlockInLock(^{
        // Never update an existing keychain item on OS X, since the existing item could have unauthorized apps in the Access Control List. Fixes zero-day Keychain vuln found here: https://drive.google.com/file/d/0BxxXk1d3yyuZOFlsdkNMSGswSGs/view
        (void)VALAtomicSecItemDelete((__bridge CFDictionaryRef)query);
        
        // If there were an entry in the keychain for this value, we just deleted it. So just add the new value.
        NSMutableDictionary *keychainData = [query mutableCopy];
        keychainData[(__bridge id)kSecValueData] = value;
        
        status = VALAtomicSecItemAdd((__bridge CFDictionaryRef)keychainData, NULL);
    }, self.lockForSetAndRemoveOperations);
#endif
    
    return (status == errSecSuccess);
}

- (nullable NSData *)objectForKey:(nonnull NSString *)key options:(nullable NSDictionary *)options;
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

- (BOOL)setString:(nonnull NSString *)string forKey:(nonnull NSString *)key options:(nullable NSDictionary *)options;
{
    VALCheckCondition(string.length > 0, NO, @"Can not set empty string for key.");
    NSData *stringData = [string dataUsingEncoding:NSUTF8StringEncoding];
    if (stringData.length > 0) {
        return [self setObject:stringData forKey:key options:options];
    }
    
    return NO;
}

- (nullable NSString *)stringForKey:(nonnull NSString *)key options:(nullable NSDictionary *)options;
{
    NSData *stringData = [self objectForKey:key options:options];
    if (stringData.length > 0) {
        return [[NSString alloc] initWithBytes:stringData.bytes length:stringData.length encoding:NSUTF8StringEncoding];
    }
    
    return nil;
}

- (OSStatus)containsObjectForKey:(nonnull NSString *)key options:(nullable NSDictionary *)options;
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

- (nonnull NSSet *)allKeysWithOptions:(nullable NSDictionary *)options;
{
    NSSet *keys = [NSSet set];
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

- (BOOL)removeObjectForKey:(nonnull NSString *)key options:(nullable NSDictionary *)options;
{
    VALCheckCondition(key.length > 0, NO, @"Can not remove object for empty key from the keychain.");
    
    NSMutableDictionary *query = [self.baseQuery mutableCopy];
    [query addEntriesFromDictionary:[self _secItemFormatDictionaryWithKey:key]];
    if (options.count > 0) {
        [query addEntriesFromDictionary:options];
    }
    
    __block OSStatus status = errSecNotAvailable;
    VALExecuteBlockInLock(^{
        status = VALAtomicSecItemDelete((__bridge CFDictionaryRef)query);
    }, self.lockForSetAndRemoveOperations);
    
    // We succeeded as long as we can confirm that the item is not in the keychain.
    return (status != errSecInteractionNotAllowed);
}

- (BOOL)removeAllObjectsWithOptions:(nullable NSDictionary *)options;
{
    for (NSString *key in [self allKeys]) {
        if (![self removeObjectForKey:key options:options]) {
            return NO;
        }
    }
    
    return YES;
}

#pragma mark - Properties

- (nonnull NSString *)secServiceIdentifier;
{
    return self.baseQuery[(__bridge id)kSecAttrService];
}

#pragma mark - Private Methods

/// Programatically grab the required prefix for the shared access group (i.e. Bundle Seed ID). The value for the kSecAttrAccessGroup key in queries for data that is shared between apps must be of the format bundleSeedID.sharedAccessGroup. For more information on the Bundle Seed ID, see https://developer.apple.com/library/ios/qa/qa1713/_index.html
- (nullable NSString *)_sharedAccessGroupPrefix;
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
        case VALAccessibilityWhenUnlocked:
            return (__bridge id)kSecAttrAccessibleWhenUnlocked;
        case VALAccessibilityAfterFirstUnlock:
            return (__bridge id)kSecAttrAccessibleAfterFirstUnlock;
        case VALAccessibilityAlways:
            return (__bridge id)kSecAttrAccessibleAlways;
#if VAL_IOS_8_OR_LATER || __MAC_10_10
        case VALAccessibilityWhenPasscodeSetThisDeviceOnly:
            return (__bridge id)kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly;
#endif
        case VALAccessibilityWhenUnlockedThisDeviceOnly:
            return (__bridge id)kSecAttrAccessibleWhenUnlockedThisDeviceOnly;
        case VALAccessibilityAfterFirstUnlockThisDeviceOnly:
            return (__bridge id)kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly;
        case VALAccessibilityAlwaysThisDeviceOnly:
            return (__bridge id)kSecAttrAccessibleAlwaysThisDeviceOnly;
    }
}

- (nonnull NSDictionary *)_secItemFormatDictionaryWithKey:(nonnull NSString *)key;
{
    VALCheckCondition(key.length > 0, @{}, @"Must provide a valid key");
    return @{ (__bridge id)kSecAttrAccount : key };
}

@end
