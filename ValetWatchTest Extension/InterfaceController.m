//
//  InterfaceController.m
//  ValetWatchTest Extension
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

#import "InterfaceController.h"
#import <Valet/VALSecureEnclaveValet.h>

@interface InterfaceController()

@property (nonatomic, copy) VALSecureEnclaveValet *secureEnclaveValet;
@property (nonatomic, copy) NSString *username;

@end


@implementation InterfaceController

- (void)awakeWithContext:(id)context {
    [super awakeWithContext:context];

    self.secureEnclaveValet = [[VALSecureEnclaveValet alloc] initWithIdentifier:@"UserPresence"];
    self.username = @"CustomerPresentProof";
}

- (void)willActivate {
    [super willActivate];
}

- (void)didDeactivate {
    // This method is called when watch view controller is no longer visible
    [super didDeactivate];
}

#pragma mark - Actions
-(IBAction) setOrUpdateRandomValue:(id)sender {
    NSString *strUUID = [[NSUUID new] UUIDString];
    BOOL setOrUpdatedItem = [self.secureEnclaveValet setString:[NSString stringWithFormat:@"I am here! %@",strUUID]  forKey:self.username];
    if (setOrUpdatedItem) {
        [self presentControllerWithName:@"DetailVC" context:@{@"segue":@"detail",@"data":[NSString stringWithFormat:@"I am here! %@", strUUID]}];
    }
}
    

-(IBAction) getRandomValue:(id)sender {
    NSString *password = [self.secureEnclaveValet stringForKey:self.username userPrompt:@"Use TouchID to retreive password"];
    
    [self presentControllerWithName:@"DetailVC" context:@{@"segue":@"detail",@"data":[NSString stringWithFormat:@"%@ \n %@", @"Value:", password]}];
}

-(IBAction) removeRandomValue:(id)sender {
    BOOL removedItem = [self.secureEnclaveValet removeObjectForKey:self.username];
    
    [self presentControllerWithName:@"DetailVC" context:@{@"segue":@"detail",@"data":[NSString stringWithFormat:@"%@\n %@", @"Delete:", (removedItem ? @"Success" : @"Failure")]}];
}

-(IBAction) executeUnitTests:(id)sender {
    [self presentControllerWithName:@"TestsVC" context:@{@"segue":@"tests"}];
}


@end



