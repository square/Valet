//
//  ValetTests.h
//  Valet
//
//  Created by Eric Muller on 9/16/17.
//  Copyright © 2017 Square, Inc. All rights reserved.
//

#import <Valet/Valet.h>

NS_ASSUME_NONNULL_BEGIN

@interface VALValet (Testing)

@property (copy, readonly) NSDictionary *baseQuery;

- (NSString *)_sharedAccessGroupPrefix;
- (NSDictionary *)_secItemFormatDictionaryWithKey:(NSString *)key;

@end

NS_ASSUME_NONNULL_END
