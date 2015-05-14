//
//  ValetSecureElementTestViewController.m
//  ValetSecureElementTest
//
//  Created by Dan Federman on 5/14/15.
//  Copyright (c) 2015 Square, Inc. All rights reserved.
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

#import <Valet/VALSecureEnclaveValet.h>

#import "ValetSecureElementTestViewController.h"


@interface ValetSecureElementTestViewController ()

@property (nonatomic, strong) IBOutlet UITextView *textView;
@property (nonatomic, copy) VALSecureEnclaveValet *secureEnclaveValet;
@property (nonatomic, copy) NSString *username;

@end


@implementation ValetSecureElementTestViewController

#pragma mark - UIViewController

- (void)viewDidLoad;
{
    [super viewDidLoad];
    
    self.secureEnclaveValet = [[VALSecureEnclaveValet alloc] initWithIdentifier:@"UserPresence"];
    self.username = @"CustomerPresentProof";
}

#pragma mark - Actions

- (IBAction)setOrUpdateItem:(id)sender;
{
    BOOL setOrUpdatedItem = [self.secureEnclaveValet setString:[NSString stringWithFormat:@"I am here! %@", [[NSUUID new] UUIDString]] forKey:self.username userPrompt:@"Use TouchID to update this password"];
    
    self.textView.text = [self.textView.text stringByAppendingFormat:@"\n%s %@", __PRETTY_FUNCTION__, (setOrUpdatedItem ? @"Success" : @"Failure")];
}

- (IBAction)getItem:(id)sender;
{
    NSString *password = [self.secureEnclaveValet stringForKey:self.username userPrompt:@"Use TouchID to retreive password"];
    
    self.textView.text = [self.textView.text stringByAppendingFormat:@"\n%s %@", __PRETTY_FUNCTION__, password];
}

- (IBAction)removeItem:(id)sender;
{
    BOOL removedItem = [self.secureEnclaveValet removeObjectForKey:self.username];
    
    self.textView.text = [self.textView.text stringByAppendingFormat:@"\n%s %@", __PRETTY_FUNCTION__, (removedItem ? @"Success" : @"Failure")];
}

@end
