//
//  VALLegacySecureEnclaveValet_Protected.h
//  Valet
//
//  Created by Dan Federman on 1/23/17.
//  Copyright © 2017 Square, Inc.
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

#import "VALLegacySecureEnclaveValet.h"


@interface VALLegacySecureEnclaveValet ()

- (nullable NSData *)objectForKey:(nonnull NSString *)key userPrompt:(nullable NSString *)userPrompt userCancelled:(nullable inout BOOL *)userCancelled options:(nullable NSDictionary *)options;

- (nullable NSString *)stringForKey:(nonnull NSString *)key userPrompt:(nullable NSString *)userPrompt userCancelled:(nullable inout BOOL *)userCancelled options:(nullable NSDictionary *)options;

@end
