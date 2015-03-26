//
//  VALSecureElementValet.h
//  Valet
//
//  Created by Dan Federman on 3/16/15.
//  Copyright (c) 2015 Square, Inc. All rights reserved.
//

#import "VALValet.h"


/// Reads and writes keychain elements that are stored on the Secure Element (supported on iOS 8.0 or later) using accessibility attribute VALAccessibleWhenPasscodeSetThisDeviceOnly. Accessing or modifying these items will require the user to confirm their presence via Touch ID or passcode entry. If no passcode is set on the device, the below methods will fail. Data is removed from the Secure Element when the user removes a passcode from the device. Use the userPrompt methods to display custom text to the user in Apple's Touch ID and passcode entry UI.
@interface VALSecureElementValet : VALValet

/// Retuns YES if Secure Element storage is supported on the current iOS version (8.0 and later).
- (BOOL)supportsSecureElementKeychainItems;

- (NSData *)objectForKey:(NSString *)key userPrompt:(NSString *)userPrompt __attribute__((nonnull(1)));
- (BOOL)setObject:(NSData *)value forKey:(NSString *)key userPrompt:(NSString *)userPrompt __attribute__((nonnull(1,2)));

- (NSString *)stringForKey:(NSString *)key userPrompt:(NSString *)userPrompt __attribute__((nonnull(1)));
- (BOOL)setString:(NSString *)string forKey:(NSString *)key userPrompt:(NSString *)userPrompt __attribute__((nonnull(1,2)));

@end
