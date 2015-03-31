//
//  VALValet.h
//  Valet
//
//  Created by Dan Federman on 3/16/15.
//  Copyright (c) 2015 Square, Inc. All rights reserved.
//


typedef NS_ENUM(NSUInteger, VALAccessibility) {
    /// Valet data can only be accessed while the device is unlocked. This attribute is recommended for data that only needs to be accesible while the application is in the foreground. Valet data with this accessibility will migrate to a new device when using encrypted backups.
    VALAccessibleWhenUnlocked = 1,
    /// Valet data can only be accessed once the device has been unlocked after a restart. This attribute is recommended for data that needs to be accesible by background applications. Valet data with this attribute will migrate to a new device when using encrypted backups.
    VALAccessibleAfterFirstUnlock,
    /// Valet data can always be accessed regardless of the lock state of the device. This attribute is not recommended. Valet data with this attribute will migrate to a new device when using encrypted backups.
    VALAccessibleAlways,
    
    /// Valet data can only be accessed while the device is unlocked. This class is only available if a passcode is set on the device. This is recommended for items that only need to be accessible while the application is in the foreground. Valet data with this attribute will never migrate to a new device, so these items will be missing after a backup is restored to a new device. No items can be stored in this class on devices without a passcode. Disabling the device passcode will cause all items in this class to be deleted.
    VALAccessibleWhenPasscodeSetThisDeviceOnly,
    /// Valet data can only be accessed while the device is unlocked. This is recommended for data that only needs to be accesible while the application is in the foreground. Valet data with this attribute will never migrate to a new device, so these items will be missing after a backup is restored to a new device.
    VALAccessibleWhenUnlockedThisDeviceOnly,
    /// Valet data can only be accessed once the device has been unlocked after a restart. This is recommended for items that need to be accessible by background applications. Valet data with this attribute will never migrate to a new device, so these items will be missing after a backup is restored to a new device.
    VALAccessibleAfterFirstUnlockThisDeviceOnly,
    /// Valet data can always be accessed regardless of the lock state of the device. This option is not recommended. Valet data with this attribute will never migrate to a new device, so these items will be missing after a backup is restored to a new device.
    VALAccessibleAlwaysThisDeviceOnly,
};

extern NSString *const VALMigrationErrorDomain;

typedef NS_ENUM(NSUInteger, VALMigrationError) {
    /// Migration failed because the keychain query was not valid.
    VAlMigrationInvalidQueryError = 1,
    /// Migration failed because no items to migrate were found.
    VALMigrationNoItemsToMigrateFoundError,
    /// Migration failed because the keychain could not be read.
    VALMigrationCouldNotReadKeychainError,
    /// Migraiton failed because a key in the query result could not be read.
    VALMigrationKeyInQueryResultInvalidError,
    /// Migraiton failed because some data in the query result could not be read.
    VAlMigrationDataInQueryResultInvalidError,
    /// Migraiton failed because two keys with the same value were found in the keychain.
    VAlMigrationDuplicateKeyInQueryResultError,
    /// Migraiton failed because a key in the keychain duplicates a key already managed by Valet.
    VAlMigrationKeyInQueryResultAlreadyExistsInValetError,
    /// Migraiton failed because writing to the keychain failed.
    VAlMigrationCouldNotWriteToKeychainError,
    /// Migration failed because removing the migrated data from the keychain failed.
    VAlMigrationRemovalFailedError,
};


/// Reads and writes keychain elements.
@interface VALValet : NSObject <NSCopying>

/// Creates a Valet that reads/writes keychain elements with the desired accessibility.
- (instancetype)initWithIdentifier:(NSString *)identifier accessibility:(VALAccessibility)accessibility __attribute__((nonnull(1))) NS_DESIGNATED_INITIALIZER;

/// Creates a Valet that reads/writes keychain elements that can be shared across applications written by the same development team. The sharedAccessGroupIdentifier must correspond with the value for keychain-access-groups in your Entitlements file.
- (instancetype)initWithSharedAccessGroupIdentifier:(NSString *)sharedAccessGroupIdentifier accessibility:(VALAccessibility)accessibility __attribute__((nonnull(1))) NS_DESIGNATED_INITIALIZER;

@property (copy, readonly) NSString *identifier;
@property (readonly, getter=isSharedAcrossApplications) BOOL sharedAcrossApplications;
@property (readonly) VALAccessibility accessibility;

/// Checks whether the keychain is currently accessible by writing a value to the keychain and then reading it back out.
- (BOOL)canAccessKeychain;

/// Inserts data into the keychain. Returns NO if the keychain is not accessible.
- (BOOL)setObject:(NSData *)value forKey:(NSString *)key __attribute__((nonnull(1,2)));
/// Retreives data from the keychain.
- (NSData *)objectForKey:(NSString *)key __attribute__((nonnull(1)));

/// Convenience method for adding a string to the keychain.
- (BOOL)setString:(NSString *)string forKey:(NSString *)key __attribute__((nonnull(1,2)));
/// Convenience method for retreiving a string from the keychain.
- (NSString *)stringForKey:(NSString *)key __attribute__((nonnull(1)));

- (BOOL)containsObjectForKey:(NSString *)key __attribute__((nonnull(1)));
- (NSSet *)allKeys;

/// Removes a key/object pair from the keychain. Returns NO if the keychain is not accessible.
- (BOOL)removeObjectForKey:(NSString *)key __attribute__((nonnull(1)));
/// Removes all key/object pairs accessible by this Valet instance from the keychain. Returns NO if the keychain is not accessible.
- (BOOL)removeAllObjects;

/// Migrates objects matching the secItemQuery into the receiving Valet instance. Error domain will be VALMigrationErrorDomain, and codes can will be from VALMigrationError. The keychain is not modified if a failure occurs.
- (NSError *)migrateObjectsMatchingQuery:(NSDictionary *)secItemQuery removeOnCompletion:(BOOL)remove;
/// Migrates objects from the passed-in Valet into the receiving Valet instance.
- (NSError *)migrateObjectsFromValet:(VALValet *)valet removeOnCompletion:(BOOL)remove;

@end
