//
//  DetailController.m
//  Valet
//
//  Created by Rodrigo de Souza Reis on 26/10/15.
//  Copyright © 2015 Square, Inc. All rights reserved.
//

#import "DetailController.h"

@implementation DetailController
@synthesize lblResult;


- (void)awakeWithContext:(id)context {
    [super awakeWithContext:context];
    NSDictionary *data = (NSDictionary *) context;
    lblResult.text = [data valueForKey:@"data"];
}

- (void)willActivate {
    // This method is called when watch view controller is about to be visible to user
    [super willActivate];
}

- (void)didDeactivate {
    // This method is called when watch view controller is no longer visible
    [super didDeactivate];
}

@end
