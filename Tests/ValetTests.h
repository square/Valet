//
//  ValetTests.h
//  Valet
//
//  Created by Eric Muller on 9/16/17.
//  Copyright © 2017 Square, Inc.
//

#import "VALLegacyValet.h"

NS_ASSUME_NONNULL_BEGIN

@interface VALLegacyValet (Testing)

@property (copy, readonly) NSDictionary *baseQuery;

- (NSString *)_sharedAccessGroupPrefix;
- (NSDictionary *)_secItemFormatDictionaryWithKey:(NSString *)key;

@end

NS_ASSUME_NONNULL_END
