//
//  DetailController.h
//  Valet
//
//  Created by Rodrigo de Souza Reis on 26/10/15.
//  Copyright © 2015 Square, Inc. All rights reserved.
//
//  Copyright 2015 Square, Inc.
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

#import "DetailController.h"

@implementation DetailController
@synthesize lblResult;


- (void)awakeWithContext:(id)context {
    [super awakeWithContext:context];
    NSDictionary *data = (NSDictionary *) context;
    lblResult.text = [data valueForKey:@"data"];
}

@end
