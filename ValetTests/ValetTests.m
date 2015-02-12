//
//  ValetTests.m
//  Valet
//
//  Created by Dan Federman on 2/11/15.
//  Copyright (c) 2015 Square, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

#import "Valet.h"


@interface Valet (Testing)

+ (NSDictionary *)_secItemFormatDictionaryWithPassword:(NSString *)password;
+ (NSMutableDictionary *)_mutableQueryWithService:(NSString *)service username:(NSString *)username options:(NSDictionary *)options;

@end


@interface KeychainTests : XCTestCase

@property (nonatomic, copy, readwrite) NSString *username;
@property (nonatomic, copy, readwrite) NSString *service;
@property (nonatomic, copy, readwrite) NSString *password;
@property (nonatomic, copy, readwrite) NSString *secondaryPassword;

@end


@implementation KeychainTests

#pragma mark Setup

- (void)setUp;
{
    [super setUp];
    
    self.username = @"foo";
    self.service = @"bar";
    self.password = @"This is a password";
    self.secondaryPassword = @"This is another password";
}

- (void)tearDown;
{
    for (NSString *username in [Valet usernamesForService:self.service]) {
        [Valet removeUsername:username service:self.service];
    }
    
    [super tearDown];
}

#pragma mark Tests

- (void)test_passwordWithUsernameForService_retrievesPassword;
{
    XCTAssertNil([Valet passwordWithUsername:self.username service:self.service]);
    
    XCTAssertTrue([Valet setUsername:self.username password:self.password service:self.service]);
    XCTAssertEqualObjects([Valet passwordWithUsername:self.username service:self.service], self.password);
}

- (void)test_passwordWithUsernameForService_invalidUsernameFailsToRetrievePassword;
{
    NSString *password = [Valet passwordWithUsername:@"abcdefg" service:self.service];
    XCTAssertNil(password, @"Expected password with username for non-existent user to be nil but instead it was %@", password);
}

- (void)test_passwordWithUsernameForService_invalidServiceFailsToRetrievePassword;
{
    [Valet setUsername:self.username password:self.password service:self.service];
    
    NSString *password = [Valet passwordWithUsername:self.username service:@"abcdefg"];
    XCTAssertNil(password, @"Expected password with username for incorrect service to be nil but instead it was %@", password);
}

- (void)test_setUsernameWithPasswordForService_invalidArgumentsCauseFailure;
{
    XCTAssertFalse([Valet setUsername:self.username password:nil service:self.service]);
    XCTAssertFalse([Valet setUsername:self.username password:@"" service:self.service]);
    XCTAssertFalse([Valet setUsername:self.username password:self.password service:nil]);
    XCTAssertFalse([Valet setUsername:nil password:self.password service:self.service]);
    XCTAssertFalse([Valet setUsername:@"" password:nil service:self.service]);
}

- (void)test_setUsernameWithPasswordForService_successfullySetsAndUpdatesPassword;
{
    // Ensure the password doesn't already exist.
    XCTAssertNil([Valet passwordWithUsername:self.username service:self.service]);
    
    // Set the password.
    XCTAssertTrue([Valet setUsername:self.username password:self.password service:self.service]);
    
    // Verify the updated password is there.
    XCTAssertEqualObjects([Valet passwordWithUsername:self.username service:self.service], self.password);
    
    // Setting the password a second time should update the existing record.
    XCTAssertTrue([Valet setUsername:self.username password:self.secondaryPassword service:self.service]);
    
    // Verify the updated password is there.
    XCTAssertEqualObjects([Valet passwordWithUsername:self.username service:self.service], self.secondaryPassword);
}

- (void)test_removeUsernameForService_failsWhenNoUsernameExists;
{
    XCTAssertFalse([Valet removeUsername:@"gfdsa" service:self.service]);
}

- (void)test_removeUsernameForService_successfullyRemovesUsername;
{
    XCTAssertNil([Valet passwordWithUsername:self.username service:self.service]);
    
    XCTAssertTrue([Valet setUsername:self.username password:self.password service:self.service]);
    XCTAssertTrue([Valet removeUsername:self.username service:self.service]);
    XCTAssertNil([Valet passwordWithUsername:self.username service:self.service], @"Expected no password to be retrieved after removing password");
}

- (void)test_removeUsernameForService_incorrectCallsFail;
{
    XCTAssertNil([Valet passwordWithUsername:self.username service:self.service]);
    
    XCTAssertTrue([Valet setUsername:self.username password:self.password service:self.service]);
    XCTAssertFalse([Valet removeUsername:self.username service:@"abcdefg"], @"Expected removing username foo with incorrect service to fail");
    XCTAssertFalse([Valet removeUsername:self.username service:@""], @"Expected removing username foo with empty service to fail");
}

- (void)test_usernamesForService_returnsNilWhenNoUsernamesPresent;
{
    XCTAssertNil([Valet passwordWithUsername:self.username service:self.service]);
    
    XCTAssertNil([Valet usernamesForService:self.service]);
}

- (void)test_usernamesForService_returnsOneUsernameWhenOnlyOneUsername;
{
    XCTAssertNil([Valet passwordWithUsername:self.username service:self.service]);
    
    XCTAssertTrue([Valet setUsername:self.username password:self.password service:self.service]);
    XCTAssertEqualObjects([Valet usernamesForService:self.service], [NSSet setWithObject:self.username]);
}

- (void)test_usernamesForService_returnsAllUsernames;
{
    XCTAssertNil([Valet passwordWithUsername:self.username service:self.service]);
    
    XCTAssertTrue([Valet setUsername:self.username password:self.password service:self.service]);
    XCTAssertTrue([Valet setUsername:@"anotherfoo" password:self.password service:self.service]);
    
    NSSet *usernames = [NSSet setWithArray:@[ self.username, @"anotherfoo" ]];
    XCTAssertEqualObjects([Valet usernamesForService:self.service], usernames);
}

- (void)test_usernamesForService_nonexistentServiceReturnsNil;
{
    XCTAssertNil([Valet passwordWithUsername:self.username service:self.service]);
    
    XCTAssertTrue([Valet setUsername:self.username password:self.password service:self.service]);
    
    NSSet *usernames = [Valet usernamesForService:@"abcdefg"];
    XCTAssertNil(usernames, @"Expected username for service with non-existent service to be nil but instead it was %@", usernames);
}

- (void)test_usernamesForService_emptyServiceFails;
{
    XCTAssertFalse([Valet usernamesForService:@""], @"Expected usernames for service with empty service to fail");
}

- (void)test_setSynchronizableUsernameWithPasswordForService_setsSynchronizablePassword;
{
    if (![Valet supportsSynchronizableKeychainItems]) {
        return;
    }
    
    XCTAssertNil([Valet passwordWithUsername:self.username service:self.service]);
    
    XCTAssertTrue([Valet setSynchronizableUsername:self.username password:self.password service:self.service]);
    XCTAssertEqualObjects(self.password, [Valet synchronizablePasswordWithUsername:self.username service:self.service]);
    
    XCTAssertNil([Valet passwordWithUsername:self.username service:self.service], @"Expected no non-synchronizable password to be found.");
}

- (void)test_removeUsernameForService_removesSynchronizablePassword;
{
    if (![Valet supportsSynchronizableKeychainItems]) {
        return;
    }
    
    XCTAssertNil([Valet passwordWithUsername:self.username service:self.service]);
    
    XCTAssertTrue([Valet setSynchronizableUsername:self.username password:self.password service:self.service]);
    XCTAssertEqualObjects(self.password, [Valet synchronizablePasswordWithUsername:self.username service:self.service]);
    
    XCTAssertTrue([Valet removeUsername:self.username service:self.service]);
    XCTAssertNil([Valet synchronizablePasswordWithUsername:self.username service:self.service]);
}

- (void)test_secItemFormatDictionaryWithPassword_passwordInDictionaryAsData;
{
    NSDictionary *passwordDictionary = [Valet _secItemFormatDictionaryWithPassword:self.password];
    NSData *passwordData = [passwordDictionary objectForKey:(__bridge id)kSecValueData];
    XCTAssertTrue([passwordData isKindOfClass:[NSData class]], @"Expected password to be in data format but instead it was a %@", NSStringFromClass([passwordData class]));
}

- (void)test_mutableQueryWithServiceUsernameOptions_serviceIsCorrect;
{
    NSString *service = self.service;
    NSString *username = self.username;
    NSMutableDictionary *query = [Valet _mutableQueryWithService:service username:username options:nil];
    
    NSString *serviceInQuery = [query objectForKey:(__bridge id)kSecAttrService];
    XCTAssertEqualObjects(serviceInQuery, service, @"Expected query with service to contain service %@ but instead it has %@", service, serviceInQuery);
}

- (void)test_mutableQueryWithServiceUsernameOptions_usernameIsCorrect;
{
    NSString *service = self.service;
    NSString *username = self.username;
    NSMutableDictionary *query = [Valet _mutableQueryWithService:service username:username options:nil];
    
    NSString *usernameInQuery = [query objectForKey:(__bridge id)kSecAttrAccount];
    XCTAssertEqualObjects(usernameInQuery, username, @"Expected query with username to contain username %@ but instead it has %@", username, usernameInQuery);
}

- (void)test_mutableQueryWithServiceUsernameOptions_optionsArePreserved;
{
    NSString *service = self.service;
    NSString *username = self.username;
    NSDictionary *options = @{@"Hey" : @"There", @"What" : @"Indeed", @"Option" : @YES};
    NSMutableDictionary *query = [Valet _mutableQueryWithService:service username:username options:options];
    
    for (NSString *key in options.allKeys) {
        XCTAssertEqualObjects(query[key], options[key]);
    }
}

- (void)test_mutableQueryWithServiceUsernameOptions_queryHasExpectedSecItems;
{
    NSString *service = self.service;
    NSString *username = self.username;
    NSMutableDictionary *query = [Valet _mutableQueryWithService:service username:username options:nil];
    
    XCTAssertNotNil(query[(__bridge id)kSecClass], @"Expected query to have a type class");
}

// These fail when running from the command line
- (BOOL)onlyRunFromXcode;
{
    return YES;
}

@end
