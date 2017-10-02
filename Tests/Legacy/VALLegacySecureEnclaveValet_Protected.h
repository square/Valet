//
//  VALLegacySecureEnclaveValet_Protected.h
//  Valet
//
//  Created by Dan Federman on 1/23/17.
//  Copyright © 2017 Square, Inc.
//

#import "VALLegacySecureEnclaveValet.h"


@interface VALLegacySecureEnclaveValet ()

- (nullable NSData *)objectForKey:(nonnull NSString *)key userPrompt:(nullable NSString *)userPrompt userCancelled:(nullable inout BOOL *)userCancelled options:(nullable NSDictionary *)options;

- (nullable NSString *)stringForKey:(nonnull NSString *)key userPrompt:(nullable NSString *)userPrompt userCancelled:(nullable inout BOOL *)userCancelled options:(nullable NSDictionary *)options;

@end
