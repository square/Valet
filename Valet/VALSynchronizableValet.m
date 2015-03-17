//
//  VALSynchronizableValet.m
//  Valet
//
//  Created by Dan Federman on 3/16/15.
//  Copyright (c) 2015 Square, Inc. All rights reserved.
//

#import "VALSynchronizableValet.h"
#import "VALValet_Protected.h"


@implementation VALSynchronizableValet

#pragma mark - Initialization

- (instancetype)initWithIdentifier:(NSString *)identifier accessibility:(VALAccessibility)accessibility;
{
    VALCheckCondition(accessibility == VALAccessibleWhenUnlocked || accessibility == VALAccessibleAfterFirstUnlock || accessibility == VALAccessibleAlways, nil, @"Accessibility must not be scoped to this device");
    VALCheckCondition([self supportsSynchronizableKeychainItems], nil, @"This device does not support synchronizing data to iCloud.");
    
    return [super initWithIdentifier:identifier accessibility:accessibility];
}

- (instancetype)initWithSharedAccessGroupIdentifier:(NSString *)sharedAccessGroupIdentifier accessibility:(VALAccessibility)accessibility;
{
    VALCheckCondition(accessibility == VALAccessibleWhenUnlocked || accessibility == VALAccessibleAfterFirstUnlock || accessibility == VALAccessibleAlways, nil, @"Accessibility must not be scoped to this device");
    VALCheckCondition([self supportsSynchronizableKeychainItems], nil, @"This device does not support synchronizing data to iCloud.");
    
    return [super initWithSharedAccessGroupIdentifier:sharedAccessGroupIdentifier accessibility:accessibility];
}

#pragma mark - Protected Methods

- (NSMutableDictionary *)mutableBaseQueryWithIdentifier:(NSString *)identifier initializer:(SEL)initializer accessibility:(VALAccessibility)accessibility;
{
    NSMutableDictionary *mutableBaseQuery = [super mutableBaseQueryWithIdentifier:identifier initializer:initializer accessibility:accessibility];
    mutableBaseQuery[(__bridge id)kSecAttrSynchronizable] = @YES;
    
    return mutableBaseQuery;
}

@end
