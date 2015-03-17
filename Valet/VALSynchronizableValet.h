//
//  VALSynchronizableValet.h
//  Valet
//
//  Created by Dan Federman on 3/16/15.
//  Copyright (c) 2015 Square, Inc. All rights reserved.
//

#import "VALValet.h"


/// Reads and writes keychain elements that are synchronized with iCloud (supported on devices on iOS 7.0.3 and later). Accessibility must not be scoped to this device.
@interface VALSynchronizableValet : VALValet
@end
