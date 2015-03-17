//
//  ValetDefines.h
//  Valet
//
//  Created by Dan Federman on 2/11/15.
//  Copyright (c) 2015 Square, Inc. All rights reserved.
//

/**
 Throws a caught exception and returns "return_statement" if "condition" is false.
 
 Example:
 VALCheckCondition(isProperlyConfigured, nil, @"Foo was not properly configured.");
 
 */
#define VALCheckCondition(condition, result, desc, ...) \
    do { \
        const BOOL conditionResult = !!(condition); \
        if (!conditionResult) { \
            @try { \
                NSAssert(conditionResult, (desc), ##__VA_ARGS__); \
            } @catch (NSException *exception) { \
                NSLog(@"Valet API Misuse: %s %@", __PRETTY_FUNCTION__, exception.reason); \
                return result;\
            } \
        } \
    } while(0)
