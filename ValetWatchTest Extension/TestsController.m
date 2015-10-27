//
//  TestsController.m
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

#import "TestsController.h"

@implementation TestsController
@synthesize lblResult;

- (void)awakeWithContext:(id)context {
    [super awakeWithContext:context];
    [self runTests];
}

- (void) runTests {
    [self setUp];
    [self test_initialization_twoValetsWithSameConfigurationHaveEqualPointers];
}

- (void)setUp;
{
    
    NSString *const valetTestingIdentifier = @"valet_testing";
    self.valet = [[VALValet alloc] initWithIdentifier:valetTestingIdentifier accessibility:VALAccessibilityWhenUnlocked];
    self.testingValet = [[VALTestingValet alloc] initWithIdentifier:valetTestingIdentifier accessibility:VALAccessibilityWhenUnlocked];
    self.synchronizableValet = [[VALSynchronizableValet alloc] initWithIdentifier:valetTestingIdentifier accessibility:VALAccessibilityWhenUnlocked];
    self.secureEnclaveValet = [[VALSecureEnclaveValet alloc] initWithIdentifier:valetTestingIdentifier accessibility:VALAccessibilityWhenPasscodeSetThisDeviceOnly];
    
    // In case testing quit unexpectedly, clean up the keychain from last time.
    [self.valet removeAllObjects];
    [self.testingValet removeAllObjects];
    [self.synchronizableValet removeAllObjects];
    
    for (VALValet *additionalValet in self.additionalValets) {
        [additionalValet removeAllObjects];
    }
    
    self.key = @"foo";
    self.string = @"bar";
    self.secondaryString = @"bar2";
    self.additionalValets = [NSMutableArray new];
}

- (void)test_initialization_twoValetsWithSameConfigurationHaveEqualPointers;
{
    [self failTest:@"initialization_twoValetsWithSameConfigurationHaveEqualPointers"];
}

-(void) passedTest:(NSString *)testTitle {
    NSLog(@"💚 👻 🙏  -> %@ : TEST PASSED \n ----------------------------------------------------------------------------------------------------------------------------------",testTitle);
}

-(void) failTest:(NSString *)testTitle {
    NSLog(@"😓 ✋ 💔 -> %@ : TEST FAILED \n ----------------------------------------------------------------------------------------------------------------------------------",testTitle);
}

@end
