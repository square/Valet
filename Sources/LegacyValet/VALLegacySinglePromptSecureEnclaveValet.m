//
//  VALLegacySinglePromptSecureEnclaveValet.m
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

#import "VALLegacySinglePromptSecureEnclaveValet.h"
#import "VALLegacySecureEnclaveValet_Protected.h"
#import "VALLegacyValet_Protected.h"

#import "ValetDefines.h"


#if VAL_SECURE_ENCLAVE_SDK_AVAILABLE
#import <LocalAuthentication/LocalAuthentication.h>


@interface VALLegacySinglePromptSecureEnclaveValet ()

@property (nonnull, strong, readwrite) LAContext *context;

@end


@implementation VALLegacySinglePromptSecureEnclaveValet

#pragma mark - Initialization

- (nullable instancetype)initWithIdentifier:(nonnull NSString *)identifier accessControl:(VALAccessControl)accessControl;
{
    self = [super initWithIdentifier:identifier accessControl:accessControl];

    if (self != nil) {
        _context = [LAContext new];
    }

    return self;
}

- (nullable instancetype)initWithSharedAccessGroupIdentifier:(nonnull NSString *)sharedAccessGroupIdentifier accessControl:(VALAccessControl)accessControl;
{
    self = [super initWithSharedAccessGroupIdentifier:sharedAccessGroupIdentifier accessControl:accessControl];

    if (self != nil) {
        _context = [LAContext new];
    }

    return self;
}

#pragma mark - VALValet

- (nullable NSData *)objectForKey:(nonnull NSString *)key;
{
    return [self objectForKey:key options:[self _contextOptions] status:nil];
}

- (nullable NSString *)stringForKey:(nonnull NSString *)key;
{
    return [self stringForKey:key options:[self _contextOptions] status:nil];
}

#pragma mark - VALLegacySecureEnclaveValet

- (nullable NSData *)objectForKey:(nonnull NSString *)key userPrompt:(nullable NSString *)userPrompt;
{
    return [self objectForKey:key userPrompt:userPrompt userCancelled:nil options:[self _contextOptions]];
}

- (nullable NSData *)objectForKey:(nonnull NSString *)key userPrompt:(nullable NSString *)userPrompt userCancelled:(nullable inout BOOL *)userCancelled;
{
    return [self objectForKey:key userPrompt:userPrompt userCancelled:userCancelled options:[self _contextOptions]];
}

- (nullable NSString *)stringForKey:(nonnull NSString *)key userPrompt:(nullable NSString *)userPrompt;
{
    return [self stringForKey:key userPrompt:userPrompt userCancelled:nil options:[self _contextOptions]];
}

- (nullable NSString *)stringForKey:(nonnull NSString *)key userPrompt:(nullable NSString *)userPrompt userCancelled:(nullable inout BOOL *)userCancelled;
{
    return [self stringForKey:key userPrompt:userPrompt userCancelled:userCancelled options:[self _contextOptions]];
}

#pragma mark - Public Methods

- (void)requirePromptOnNextAccess;
{
    VALAtomicSecItemLock(^{
        [self.context invalidate];
        self.context = [LAContext new];
    });
}

#pragma mark - Private Methods

- (nonnull NSDictionary *)_contextOptions;
{
    return @{ (__bridge id)kSecUseAuthenticationContext : self.context };
}

@end

#else // Below this line we're in !VAL_SECURE_ENCLAVE_SDK_AVAILABLE, meaning none of our API is actually usable. Return NO or nil everywhere.

@implementation VALLegacySinglePromptSecureEnclaveValet

- (void)requirePromptOnNextAccess;
{
    VALCheckCondition(NO, , @"VALLegacySinglePromptSecureEnclaveValet unsupported on this SDK");
}

@end

#endif // VAL_SECURE_ENCLAVE_SDK_AVAILABLE
