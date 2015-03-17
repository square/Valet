//
//  Header.h
//  Valet
//
//  Created by Dan Federman on 3/16/15.
//  Copyright (c) 2015 Square, Inc. All rights reserved.
//

extern NSString *VALStringForAccessibility(VALAccessibility accessibility);


@interface VALValet ()

- (BOOL)supportsSynchronizableKeychainItems;
- (BOOL)supportsLocalAuthentication;
- (NSMutableDictionary *)mutableBaseQueryWithIdentifier:(NSString *)identifier initializer:(SEL)initializer accessibility:(VALAccessibility)accessibility;

- (BOOL)setObject:(NSData *)value forKey:(NSString *)key options:(NSDictionary *)options;
- (NSData *)objectForKey:(NSString *)key options:(NSDictionary *)options;
- (BOOL)setString:(NSString *)string forKey:(NSString *)key options:(NSDictionary *)options;
- (NSString *)stringForKey:(NSString *)key options:(NSDictionary *)options;
- (OSStatus)containsObjectForKey:(NSString *)key options:(NSDictionary *)options;
- (NSSet *)allKeysWithOptions:(NSDictionary *)options;
- (BOOL)removeObjectForKey:(NSString *)key options:(NSDictionary *)options;
- (BOOL)removeAllObjectsWithOptions:(NSDictionary *)options;

@end