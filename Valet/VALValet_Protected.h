//
//  VALValet_Protected.h
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


NS_ASSUME_NONNULL_BEGIN


extern NSString *VALStringForAccessibility(VALAccessibility accessibility);


@interface VALValet ()

- (NSMutableDictionary *)mutableBaseQueryWithIdentifier:(NSString *)identifier initializer:(SEL)initializer accessibility:(VALAccessibility)accessibility;

- (BOOL)setObject:(NSData *)value forKey:(NSString *)key options:(nullable NSDictionary *)options;
- (nullable NSData *)objectForKey:(NSString *)key options:(nullable NSDictionary *)options;
- (BOOL)setString:(NSString *)string forKey:(NSString *)key options:(nullable NSDictionary *)options;
- (nullable NSString *)stringForKey:(NSString *)key options:(nullable NSDictionary *)options;
- (OSStatus)containsObjectForKey:(NSString *)key options:(nullable NSDictionary *)options;
- (NSSet *)allKeysWithOptions:(nullable NSDictionary *)options;
- (BOOL)removeObjectForKey:(NSString *)key options:(nullable NSDictionary *)options;
- (BOOL)removeAllObjectsWithOptions:(nullable NSDictionary *)options;

@end


NS_ASSUME_NONNULL_END
