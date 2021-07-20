
### Basic Initialization

```swift
let myValet = Valet.valet(with: Identifier(nonEmpty: "Druidia")!, accessibility: .whenUnlocked)
```

```objc
VALValet *const myValet = [VALValet valetWithIdentifier:@"Druidia" accessibility:VALAccessibilityWhenUnlocked];
```

To begin storing data securely using Valet, you need to create a Valet instance with:

* An identifier – a non-empty string that is used to identify this Valet. The Swift API uses an `Identifier` wrapper class to enforce the non-empty constraint.
* An accessibility value – an enum ([Accessibility](Sources/Valet/Accessibility.swift#L25)) that defines when you will be able to persist and retrieve data.

This `myValet` instance can be used to store and retrieve data securely on this device, but only when the device is unlocked.

#### Choosing the Best Identifier

The identifier you choose for your Valet is used to create a sandbox for the data your Valet writes to the keychain. Two Valets of the same type created via the same initializer, accessibility value, and identifier will be able to read and write the same key:value pairs; Valets with different identifiers each have their own sandbox. Choose an identifier that describes the kind of data your Valet will protect. You do not need to include your application name or bundle identifier in your Valet’s identifier.

#### Choosing a User-friendly Identifier on macOS

```swift
let myValet = Valet.valet(withExplicitlySet: Identifier(nonEmpty: "Druidia")!, accessibility: .whenUnlocked)
```

```objc
VALValet *const myValet = [VALValet valetWithExplicitlySetIdentifier:@"Druidia" accessibility:VALAccessibilityWhenUnlocked];
```

Mac apps signed with a developer ID may see their Valet’s identifier [shown to their users](https://github.com/square/Valet/issues/140). ⚠️⚠️ While it is possible to explicitly set a user-friendly identifier, note that doing so bypasses this project’s guarantee that one Valet type will not have access to one another type’s key:value pairs ⚠️⚠️. To maintain this guarantee, ensure that each Valet’s identifier is globally unique.

#### Choosing the Best Accessibility Value

The Accessibility enum is used to determine when your secrets can be accessed. It’s a good idea to use the strictest accessibility possible that will allow your app to function. For example, if your app does not run in the background you will want to ensure the secrets can only be read when the phone is unlocked by using `.whenUnlocked` or `.whenUnlockedThisDeviceOnly`.

#### Changing an Accessibility Value After Persisting Data

```swift
let myOldValet = Valet.valet(withExplicitlySet: Identifier(nonEmpty: "Druidia")!, accessibility: .whenUnlocked)
let myNewValet = Valet.valet(withExplicitlySet: Identifier(nonEmpty: "Druidia")!, accessibility: .afterFirstUnlock)
try? myNewValet.migrateObjects(from: myOldValet, removeOnCompletion: true)
```

```objc
VALValet *const myOldValet = [VALValet valetWithExplicitlySetIdentifier:@"Druidia" accessibility:VALAccessibilityWhenUnlocked];
VALValet *const myNewValet = [VALValet valetWithExplicitlySetIdentifier:@"Druidia" accessibility:VALAccessibilityAfterFirstUnlock];
[myNewValet migrateObjectsFrom:myOldValet removeOnCompletion:true error:nil];
```

The Valet type, identifier, accessibility value, and initializer chosen to create a Valet are combined to create a sandbox within the keychain. This behavior ensures that different Valets can not read or write one another's key:value pairs. If you change a Valet's accessibility after persisting key:value pairs, you must migrate the key:value pairs from the Valet with the no-longer-desired accessibility to the Valet with the desired accessibility to avoid data loss.

### Reading and Writing

```swift
let username = "Skroob"
try? myValet.setString("12345", forKey: username)
let myLuggageCombination = myValet.string(forKey: username)
```

```objc
NSString *const username = @"Skroob";
[myValet setString:@"12345" forKey:username error:nil];
NSString *const myLuggageCombination = [myValet stringForKey:username error:nil];
```

In addition to allowing the storage of strings, Valet allows the storage of `Data` objects via `setObject(_ object: Data, forKey key: Key)` and `object(forKey key: String)`. Valets created with a different class type, via a different initializer, or with a different accessibility attribute will not be able to read or modify values in `myValet`.

### Sharing Secrets Among Multiple Applications Using a Keychain Sharing Entitlement

```swift
let mySharedValet = Valet.sharedGroupValet(with: SharedGroupIdentifier(appIDPrefix: "AppID12345", nonEmptyGroup: "Druidia")!, accessibility: .whenUnlocked)
```

```objc
VALValet *const mySharedValet = [VALValet sharedGroupValetWithAppIDPrefix:@"AppID12345" sharedGroupIdentifier:@"Druidia" accessibility:VALAccessibilityWhenUnlocked];
```

This instance can be used to store and retrieve data securely across any app written by the same developer that has `AppID12345.Druidia` (or `$(AppIdentifierPrefix)Druidia`) set as a value for the `keychain-access-groups` key in the app’s `Entitlements`, where `AppID12345` is the application’s [App ID prefix](https://developer.apple.com/documentation/security/keychain_services/keychain_items/sharing_access_to_keychain_items_among_a_collection_of_apps#2974920). This Valet is accessible when the device is unlocked. Note that `myValet` and `mySharedValet` can not read or modify one another’s values because the two Valets were created with different initializers. All Valet types can share secrets across applications written by the same developer by using the `sharedGroupValet` initializer.

### Sharing Secrets Among Multiple Applications Using an App Groups Entitlement

```swift
let mySharedValet = Valet.sharedGroupValet(with: SharedGroupIdentifier(groupPrefix: "group", nonEmptyGroup: "Druidia")!, accessibility: .whenUnlocked)
```

```objc
VALValet *const mySharedValet = [VALValet sharedGroupValetWithGroupPrefix:@"group" sharedGroupIdentifier:@"Druidia" accessibility:VALAccessibilityWhenUnlocked];
```

This instance can be used to store and retrieve data securely across any app written by the same developer that has `group.Druidia` set as a value for the `com.apple.security.application-groups` key in the app’s `Entitlements`. This Valet is accessible when the device is unlocked. Note that `myValet` and `mySharedValet` cannot read or modify one another’s values because the two Valets were created with different initializers. All Valet types can share secrets across applications written by the same developer by using the `sharedGroupValet` initializer. Note that on macOS, the `groupPrefix` [must be the App ID prefix](https://developer.apple.com/documentation/bundleresources/entitlements/com_apple_security_application-groups#discussion).

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

Already using the Keychain and no longer want to maintain your own Keychain code? We feel you. That’s why we wrote `migrateObjects(matching query: [String : AnyHashable], removeOnCompletion: Bool)`. This method allows you to migrate all your existing Keychain entries to a Valet instance in one line. Just pass in a Dictionary with the `kSecClass`, `kSecAttrService`, and any other `kSecAttr*` attributes you use – we’ll migrate the data for you. If you need more control over how your data is migrated, use `migrateObjects(matching query: [String : AnyHashable], compactMap: (MigratableKeyValuePair<AnyHashable>) throws -> MigratableKeyValuePair<String>?)` to filter or remap key:value pairs as part of your migration.

### Integrating Valet into a macOS application

Your macOS application must have the Keychain Sharing entitlement in order to use Valet, even if your application does not intend to share keychain data between applications. For instructions on how to add a Keychain Sharing entitlement to your application, read [Apple's documentation on the subject](https://developer.apple.com/documentation/security/keychain_services/keychain_items/sharing_access_to_keychain_items_among_a_collection_of_apps#2974918). For more information on why this requirement exists, see [issue #213](https://github.com/square/Valet/issues/213).

If your macOS application supports macOS 10.14 or prior, you must run `myValet.migrateObjectsFromPreCatalina()` before reading values from a Valet. macOS Catalina introduced a breaking change to the macOS keychain, requiring that macOS keychain items that utilize `kSecAttrAccessible` or `kSecAttrAccessGroup` set `kSecUseDataProtectionKeychain` to `true` [when writing or accessing](https://developer.apple.com/documentation/security/ksecusedataprotectionkeychain) these items. Valet’s `migrateObjectsFromPreCatalina()` upgrades items entered into the keychain on older macOS devices or other operating systems to include the key:value pair `kSecUseDataProtectionKeychain:true`. Note that Valets that share keychain items between devices with iCloud are exempt from this requirement. Similarly, `SecureEnclaveValet` and `SinglePromptSecureEnclaveValet` are exempt from this requirement.

### Debugging

Valet guarantees that reading and writing operations will succeed as long as written data is valid and `canAccessKeychain()` returns `true`. There are only a few cases that can lead to the keychain being inaccessible:

1. Using the wrong `Accessibility` for your use case. Examples of improper use include using `.whenPasscodeSetThisDeviceOnly` when there is no passcode set on the device, or using `.whenUnlocked` when running in the background.
1. Initializing a Valet with shared access group Valet when the shared access group identifier is not in your entitlements file.
1. Using `SecureEnclaveValet` on an iOS device that doesn’t have a Secure Enclave. The Secure Enclave was introduced with the [A7 chip](https://www.apple.com/business/docs/iOS_Security_Guide.pdf), which [first appeared](https://en.wikipedia.org/wiki/Apple_A7#Products_that_include_the_Apple_A7) in the iPhone 5S, iPad Air, and iPad Mini 2.
1. Running your app in DEBUG from Xcode. Xcode sometimes does not properly sign your app, which causes a [failure to access keychain](https://github.com/square/Valet/issues/10#issuecomment-114408954) due to entitlements. If you run into this issue, just hit Run in Xcode again. This signing issue will not occur in properly signed (not DEBUG) builds.
1. Running your app on device or in the simulator with a debugger attached may also [cause an entitlements error](https://forums.developer.apple.com/thread/4743) to be returned when reading from or writing to the keychain. To work around this issue on device, run the app without the debugger attached. After running once without the debugger attached the keychain will usually behave properly for a few runs with the debugger attached before the process needs to be repeated.
1. Running your app or unit tests without the application-identifier entitlement. Xcode 8 introduced a requirement that all schemes must be signed with the application-identifier entitlement to access the keychain. To satisfy this requirement when running unit tests, your unit tests must be run inside of a host application.
1. Attempting to write data larger than 4kb. The Keychain is built to securely store small secrets – writing large blobs is not supported by Apple's Security daemon.
