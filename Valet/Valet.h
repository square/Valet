//
//  Valet.h
//  Valet
//
//  Created by Dan Federman on 1/21/15.
//  Copyright (c) 2015 Square, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface Valet : NSObject

/* TODO:
 • Can we remove options from the public header?
 • Package test app into project
 */

+ (BOOL)supportsSynchronizableKeychainItems;
+ (BOOL)supportsLocalAuthentication;

+ (BOOL)setUsername:(NSString *)username password:(NSString *)password service:(NSString *)service options:(NSDictionary *)options;
+ (BOOL)setUsername:(NSString *)username password:(NSString *)password service:(NSString *)service;
/// Sets a username and password in the iCloud keychain that will be synced across devices.
+ (BOOL)setSynchronizableUsername:(NSString *)username password:(NSString *)password service:(NSString *)service;
/// Sets a username and password that can only be retrieved via TouchID or entering the phone's passcode. Will return NO if the phone has no passcode set.
+ (BOOL)setUserPresenceRequiredPasswordWithPrompt:(NSString *)prompt username:(NSString *)username password:(NSString *)password service:(NSString *)service;
/// Removes a username and password pair from the keychain. Both local and iCloud keychain entries will be removed.
+ (BOOL)removeUsername:(NSString *)username service:(NSString *)service;
+ (BOOL)removeAllEntriesservice:(NSString *)service;

+ (NSSet *)usernamesForService:(NSString *)service;
+ (NSString *)passwordWithUsername:(NSString *)username service:(NSString *)service;
/// Gets a password from the iCloud keychain.
+ (NSString *)synchronizablePasswordWithUsername:(NSString *)username service:(NSString *)service;
/// Gets a password that requires the user to prove their presence via TouchID or entering their phone's passcode. If the phone has no passcode set, the return return value to be nil.
+ (NSString *)userPresenceRequiredPasswordWithPrompt:(NSString *)prompt forUsername:(NSString *)username service:(NSString *)service;

@end
