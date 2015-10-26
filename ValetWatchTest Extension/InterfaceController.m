//
//  InterfaceController.m
//  ValetWatchTest Extension
//
//  Created by Rodrigo de Souza Reis on 26/10/15.
//  Copyright © 2015 Square, Inc. All rights reserved.
//

#import "InterfaceController.h"
#import <Valet/VALSecureEnclaveValet.h>

@interface InterfaceController()

@property (nonatomic, copy) VALSecureEnclaveValet *secureEnclaveValet;
@property (nonatomic, copy) NSString *username;

@end


@implementation InterfaceController

- (void)awakeWithContext:(id)context {
    [super awakeWithContext:context];

    // Configure interface objects here.
}

- (void)willActivate {
    // This method is called when watch view controller is about to be visible to user
    [super willActivate];
    self.secureEnclaveValet = [[VALSecureEnclaveValet alloc] initWithIdentifier:@"UserPresence"];
    self.username = @"CustomerPresentProof";
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


@end



