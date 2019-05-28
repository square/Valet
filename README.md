# Valet

[![CI Status](https://travis-ci.org/square/Valet.svg?branch=master)](https://travis-ci.org/square/Valet)
[![Carthage Compatibility](https://img.shields.io/badge/carthage-✓-e2c245.svg)](https://github.com/Carthage/Carthage/)
[![Version](https://img.shields.io/cocoapods/v/Valet.svg)](https://cocoapods.org/pods/Valet)
[![License](https://img.shields.io/cocoapods/l/Valet.svg)](https://cocoapods.org/pods/Valet)
[![Platform](https://img.shields.io/cocoapods/p/Valet.svg)](https://cocoapods.org/pods/Valet)

Valet lets you securely store data in the iOS, tvOS, watchOS, or macOS Keychain without knowing a thing about how the Keychain works. It’s easy. We promise.

## Getting Started

### CocoaPods

Install with [CocoaPods](http://cocoapods.org) by adding the following to your `Podfile`:

on iOS:

```
platform :ios, '9.0'
use_frameworks!
pod 'Valet'
```

on tvOS:

```
platform :tvos, '9.0'
use_frameworks!
pod 'Valet'
```

on watchOS:

```
platform :watchos, '2.0'
use_frameworks!
pod 'Valet'
```

on macOS:

```
platform :osx, '10.11'
use_frameworks!
pod 'Valet'
```

### Carthage

Install with [Carthage](https://github.com/Carthage/Carthage) by adding the following to your `Cartfile`:

```ogdl
github "Square/Valet"
```

Run `carthage` to build the framework and drag the built `Valet.framework` into your Xcode project.

### Swift Package Manager

Install with [Swift Package Manager](https://github.com/apple/swift-package-manager) by adding the following to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/Square/Valet", from: "3.0.0"),
],
```

### Submodules

Or manually checkout the submodule with `git submodule add git@github.com:Square/Valet.git`, drag Valet.xcodeproj to your project, and add Valet as a build dependency.

## Usage

### Basic Initialization

```swift
let myValet = Valet.valet(with: Identifier(nonEmpty: "Druidia")!, accessibility: .whenUnlocked)
```

```objc
VALValet *const myValet = [VALValet valetWithIdentifier:@"Druidia" accessibility:VALAccessibilityWhenUnlocked];
```

To begin storing data securely using Valet, you need to create a Valet instance with:

* An identifier – a non-empty string that is used to identify this Valet. The Swift API uses an `Identifier` wrapper class to enforce the non-empty constraint.
* An accessibility value – an enum ([Accessibility](Sources/Accessibility.swift#L25)) that defines when you will be able to persist and retrieve data.

This `myValet` instance can be used to store and retrieve data securely on this device, but only when the device is unlocked.

#### Choosing the Best Identifier

The identifier you choose for your Valet is used to create a sandbox for the data your Valet writes to the keychain. Two Valets of the same type created via the same initializer, accessibility value, and identifier will be able to read and write the same key:value pairs; Valets with different identifiers each have their own sandbox. Choose an identifier that describes the kind of data your Valet will protect. You do not need to include your application name or bundleIdentifier in your Valet’s identifier.

#### Choosing the Best Accessibility Value

The Accessibility enum is used to determine when your secrets can be accessed. It’s a good idea to use the strictest accessibility possible that will allow your app to function. For example, if your app does not run in the background you will want to ensure the secrets can only be read when the phone is unlocked by using `.whenUnlocked` or `.whenUnlockedThisDeviceOnly`.

### Reading and Writing

```swift
let username = "Skroob"
myValet.set(string: "12345", forKey: username)
let myLuggageCombination = myValet.string(forKey: username)
```

```objc
NSString *const username = @"Skroob";
[myValet setString:@"12345" forKey:username];
NSString *const myLuggageCombination = [myValet stringForKey:username];
```

In addition to allowing the storage of strings, Valet allows the storage of `Data` objects via `set(object: Data, forKey key: Key)` and `-objectForKey:`. Valets created with a different class type, via a different initializer, or with a different accessibility attribute will not be able to read or modify values in `myValet`.

### Sharing Secrets Among Multiple Applications

```swift
let mySharedValet = Valet.sharedAccessGroupValet(with: Identifier(nonEmpty: "Druidia")!, accessibility: .whenUnlocked)
```

```objc
VALValet *const mySharedValet = [VALValet valetWithSharedAccessGroupIdentifier:@"Druidia" accessibility:VALAccessibilityWhenUnlocked];
```

This instance can be used to store and retrieve data securely across any app written by the same developer with the value `Druidia` under the `keychain-access-groups` key in the app’s `Entitlements` file, when the device is unlocked. Note that `myValet` and `mySharedValet` can not read or modify one another’s values because the two Valets were created with different initializers. All Valet types can share secrets across applications written by the same developer by using the `sharedAccessGroupValet` initializer.

### Sharing Secrets Across Devices with iCloud

```swift
let myCloudValet = Valet.iCloudValet(with: Identifier(nonEmpty: "Druidia")!, accessibility: .whenUnlocked)
```

```objc
VALValet *const myCloudValet = [VALValet iCloudValetWithIdentifier:@"Druidia" accessibility:VALAccessibilityWhenUnlocked];
```

This instance can be used to store and retrieve data that can be retrieved by this app on other devices logged into the same iCloud account with iCloud Keychain enabled. If iCloud Keychain is not enabled on this device, secrets can still be read and written, but will not sync to other devices. Note that  `myCloudValet` can not read or modify values in either `myValet` or `mySharedValet` because `myCloudValet` was created a different initializer.

### Protecting Secrets with Face ID, Touch ID, or device Passcode

```swift
let mySecureEnclaveValet = SecureEnclaveValet.valet(with: Identifier(nonEmpty: "Druidia")!, accessControl: .userPresence)
```

```objc
VALSecureEnclaveValet *const mySecureEnclaveValet = [VALSecureEnclaveValet valetWithIdentifier:@"Druidia" accessControl:VALAccessControlUserPresence];
```

This instance can be used to store and retrieve data in the Secure Enclave. Each time data is retrieved from this Valet, the user will be prompted to confirm their presence via Face ID, Touch ID, or by entering their device passcode. *If no passcode is set on the device, this instance will be unable to access or store data.* Data is removed from the Secure Enclave when the user removes a passcode from the device. Storing data using `SecureEnclaveValet` is the most secure way to store data on iOS, tvOS, watchOS, and macOS.

```swift
let mySecureEnclaveValet = SinglePromptSecureEnclaveValet.valet(with: Identifier(nonEmpty: "Druidia")!, accessControl: .userPresence)
```

```objc
VALSinglePromptSecureEnclaveValet *const mySecureEnclaveValet = [VALSinglePromptSecureEnclaveValet valetWithIdentifier:@"Druidia" accessControl:VALAccessControlUserPresence];
```

This instance also stores and retrieves data in the Secure Enclave, but does not require the user to confirm their presence each time data is retrieved. Instead, the user will be prompted to confirm their presence only on the first data retrieval. A `SinglePromptSecureEnclaveValet` instance can be forced to prompt the user on the next data retrieval by calling the instance method `requirePromptOnNextAccess()`.

**In order for your customers not to receive a prompt that your app does not yet support Face ID, you must set a value for the Privacy - Face ID Usage Description [(NSFaceIDUsageDescription)](https://developer.apple.com/library/content/documentation/General/Reference/InfoPlistKeyReference/Articles/CocoaKeys.html#//apple_ref/doc/uid/TP40009251-SW75) key in your app’s Info.plist.**

### Thread Safety

Valet is built to be thread safe: it is possible to use a Valet instance on any queue or thread. Valet instances ensure that code that talks to the Keychain is atomic – it is impossible to corrupt data in Valet by reading and writing on multiple queues simultaneously.

However, because the Keychain is effectively disk storage, there is no guarantee that reading and writing items is fast - accessing a Valet instance from the main queue can result in choppy animations or blocked UI. As a result, we recommend utilizing your Valet instance on a background queue; treat Valet like you treat other code that reads from and writes to disk.

### Migrating Existing Keychain Values into Valet

Already using the Keychain and no longer want to maintain your own Keychain code? We feel you. That’s why we wrote `migrateObjects(matching query: [String : AnyHashable], removeOnCompletion: Bool)`. This method allows you to migrate all your existing Keychain entries to a Valet instance in one line. Just pass in a Dictionary with the `kSecClass`, `kSecAttrService`, and any other `kSecAttr*` attributes you use – we’ll migrate the data for you.

### Debugging

Valet guarantees it will never fail to write to or read from the keychain unless `canAccessKeychain()` returns `false`. There are only a few cases that can lead to the keychain being inaccessible:

1. Using the wrong `Accessibility` for your use case. Examples of improper use include using `.whenPasscodeSetThisDeviceOnly` when there is no passcode set on the device, or using `.whenUnlocked` when running in the background.
2. Initializing a Valet with shared access group Valet when the shared access group identifier is not in your entitlements file.
3. Using `SecureEnclaveValet` on an iOS device that doesn’t have a Secure Enclave. The Secure Enclave was introduced with the [A7 chip](https://www.apple.com/business/docs/iOS_Security_Guide.pdf), which [first appeared](https://en.wikipedia.org/wiki/Apple_A7#Products_that_include_the_Apple_A7) in the iPhone 5S, iPad Air, and iPad Mini 2.
4. Running your app in DEBUG from Xcode. Xcode sometimes does not properly sign your app, which causes a [failure to access keychain](https://github.com/square/Valet/issues/10#issuecomment-114408954) due to entitlements. If you run into this issue, just hit Run in Xcode again. This signing issue will not occur in properly signed (not DEBUG) builds.
5. Running your app on device or in the simulator with a debugger attached may also [cause an entitlements error](https://forums.developer.apple.com/thread/4743) to be returned when reading from or writing to the keychain. To work around this issue on device, run the app without the debugger attached. After running once without the debugger attached the keychain will usually behave properly for a few runs with the debugger attached before the process needs to be repeated.
6. Running your app or unit tests without the application-identifier entitlement. Xcode 8 introduced a requirement that all schemes must be signed with the application-identifier entitlement to access the keychain. To satisfy this requirement when running unit tests, your unit tests must be run inside of a host application.

## Requirements

* Xcode 9.0 or later. Earlier versions of Xcode require [Valet version 2.4.2](https://github.com/square/Valet/releases/tag/2.4.2).
* iOS 9 or later.
* tvOS 9 or later.
* watchOS 2 or later.
* macOS 10.11 or later.

### Migrating from Valet 2.*

First the good news: you will _not_ have to migrate your keychain data when upgrading from Valet 2.* to Valet 3.*. All Valet objects are backwards compatible with their Valet 2 counterparts. We have exhaustive unit tests to prove it (search for `test_backwardsCompatibility`).

Now the bad news: the Swift Valet API has slight differences from the Objective-C Valet API. You may have noticed a few of the differences in the sample code above, but here’s a rundown of the changes that may affect you.

1. Initializers have changed in both Swift and Objective-C - both languages use class methods now, which felt more semantically honest (a lot of the time you’re not instantiating a new Valet, you’re re-accessing one you’ve already created). [See example usage above](#basic-initialization).
2. `VALSynchronizableValet` (which allowed keychains to be synced to iCloud) has been replaced by a `Valet.iCloudValet(with:accessibility:)`  (or `+[VALValet iCloudValetWithIdentifier:accessibility:]` in Objective-C). [See examples above](#sharing-secrets-across-devices-with-icloud).
3. `setObject(_:forKey:)` has become `set(object:forKey:)` in Swift. The Objective-C API `-setObject:forKey:` remains the same.
4. `setString(_:forKey:)` has become `set(string:forKey:)` in Swift. The Objective-C API `-setString:forKey:` remains the same.
5. `SecureEnclaveValet` and `SinglePromptSecureEnclaveValet` data retrieval methods now return a single enum [SecureEnclave.Result](Sources/SecureEnclave.swift#L28) rather than using an `inout` boolean to signal whether a user cancelled. The Objective-C API remains the same.
6. `migrateObjects(matching:)` and `migrateObjects(from:)` now both return a nonnull [MigrationResult](Sources/MigrationResult.swift#L24).
7. `VALAccessControl` has been renamed to `SecureEnclaveAccessControl` (`VALSecureEnclaveAccessControl` in Objective-C). This enum no longer references `TouchID`; instead it refers to unlocking with `biometric` due to the introduction of Face ID.
8. `Valet`, `SecureEnclaveValet`, and `SinglePromptSecureEnclaveValet` are no longer in the same inheritance tree. All three now inherit directly from `NSObject` and use composition to share code. If you were relying on the subclass hierarchy before, 1) that might be a code smell 2) consider declaring a protocol for the shared behavior you were expecting to make your migration to Valet 3 easier.

## Contributing

We’re glad you’re interested in Valet, and we’d love to see where you take it. Please read our [contributing guidelines](Contributing.md) prior to submitting a Pull Request.

Thanks, and please *do* take it for a joyride!
