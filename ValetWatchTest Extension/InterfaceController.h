//
//  InterfaceController.h
//  ValetWatchTest Extension
//
//  Created by Rodrigo de Souza Reis on 26/10/15.
//  Copyright © 2015 Square, Inc. All rights reserved.
//

#import <WatchKit/WatchKit.h>
#import <Foundation/Foundation.h>

@interface InterfaceController : WKInterfaceController

-(IBAction) setOrUpdateRandomValue:(id)sender;
-(IBAction) getRandomValue:(id)sender;
-(IBAction) removeRandomValue:(id)sender;

@end
