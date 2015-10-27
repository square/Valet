//
//  TestsController.h
//  Valet
//
//  Created by Rodrigo de Souza Reis on 26/10/15.
//  Copyright © 2015 Square, Inc. All rights reserved.
//
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.

#import <WatchKit/WatchKit.h>
#import <Valet/Valet.h>
#import <Valet/ValetDefines.h>


@interface VALValet (Testing)

@property (copy, readonly) NSDictionary *baseQuery;

- (NSString *)_sharedAccessGroupPrefix;
- (NSDictionary *)_secItemFormatDictionaryWithKey:(NSString *)key;

@end


@interface VALTestingValet : VALValet
@end

@implementation VALTestingValet
@end

@interface TestsController : WKInterfaceController

@property (nonatomic, weak) IBOutlet WKInterfaceLabel *lblResult;
@property (nonatomic, readwrite) VALValet *valet;
@property (nonatomic, readwrite) VALTestingValet *testingValet;
@property (nonatomic, readwrite) VALSynchronizableValet *synchronizableValet;
@property (nonatomic, readwrite) VALSecureEnclaveValet *secureEnclaveValet;
@property (nonatomic, copy, readwrite) NSString *key;
@property (nonatomic, copy, readwrite) NSString *string;
@property (nonatomic, copy, readwrite) NSString *secondaryString;
@property (nonatomic, strong, readwrite) NSMutableArray *additionalValets;

@end
