
* Xcode 11.0 or later. Xcode 10 and Xcode 9 require [Valet version 3.2.8](https://github.com/square/Valet/releases/tag/3.2.8). Earlier versions of Xcode require [Valet version 2.4.2](https://github.com/square/Valet/releases/tag/2.4.2).
* iOS 9 or later.
* tvOS 9 or later.
* watchOS 2 or later.
* macOS 10.11 or later.

## Migrating from prior Valet versions

The good news: most Valet configurations do _not_ have to migrate keychain data when upgrading from an older version of Valet. All Valet objects are backwards compatible with their counterparts from prior versions. We have exhaustive unit tests to prove it (search for `test_backwardsCompatibility`). Valets that have had their configurations deprecated by Apple will need to migrate stored data.

The bad news: there are multiple source-breaking API changes from prior versions.

Both guides below explain the changes required to upgrade to Valet 4. 

### Migrating from Valet 2

1. Initializers have changed in both Swift and Objective-C - both languages use class methods now, which felt more semantically honest (a lot of the time you’re not instantiating a new Valet, you’re re-accessing one you’ve already created). [See example usage above](#basic-initialization).
1. `VALSynchronizableValet` (which allowed keychains to be synced to iCloud) has been replaced by a `Valet.iCloudValet(with:accessibility:)` (or `+[VALValet iCloudValetWithIdentifier:accessibility:]` in Objective-C). [See examples above](#sharing-secrets-across-devices-with-icloud).
1. `VALAccessControl` has been renamed to `SecureEnclaveAccessControl` (`VALSecureEnclaveAccessControl` in Objective-C). This enum no longer references `TouchID`; instead it refers to unlocking with `biometric` due to the introduction of Face ID.
1. `Valet`, `SecureEnclaveValet`, and `SinglePromptSecureEnclaveValet` are no longer in the same inheritance tree. All three now inherit directly from `NSObject` and use composition to share code. If you were relying on the subclass hierarchy before, 1) that might be a code smell 2) consider declaring a protocol for the shared behavior you were expecting to make your migration to Valet 3 easier.

You'll also need to continue reading through the [migration from Valet 3](#migration-from-valet-3) section below.

### Migrating from Valet 3

1. The accessibility values `always` and `alwaysThisDeviceOnly` have been removed from Valet, because Apple has deprecated their counterparts (see the documentation for [kSecAttrAccessibleAlways](https://developer.apple.com/documentation/security/ksecattraccessiblealways) and [kSecAttrAccessibleAlwaysThisDeviceOnly](https://developer.apple.com/documentation/security/ksecattraccessiblealwaysthisdeviceonly)). To migrate values stored with `always` accessibility, use the method `migrateObjectsFromAlwaysAccessibleValet(removeOnCompletion:)` on a Valet with your new preferred accessibility. To migrate values stored with `alwaysThisDeviceOnly` accessibility, use the method `migrateObjectsFromAlwaysAccessibleThisDeviceOnlyValet(removeOnCompletion:)` on a Valet with your new preferred accessibility.
1. Most APIs that returned optionals or `Bool` values have been migrated to returning a nonoptional and throwing if an error is encountered. Ignoring the error that can be thrown by each API will keep your code flow behaving the same as it did before. Walking through one example: in Swift, `let secret: String? = myValet.string(forKey: myKey)` becomes `let secret: String? = try? myValet.string(forKey: myKey)`. In Objective-C, `NSString *const secret = [myValet stringForKey:myKey];` becomes `NSString *const secret = [myValet stringForKey:myKey error:nil];`. If you're interested in the reason data wasn't returned, use a [do-catch](https://docs.swift.org/swift-book/LanguageGuide/ErrorHandling.html#ID541) statement in Swift, or pass in an `NSError` to each API call and inspect the output in Objective-C. Each method clearly documents the `Error` type it can `throw`. [See examples above](#reading-and-writing).
1. The class method used to create a Valet that can share secrets between applications using keychain shared access groups has changed. In order to prevent the incorrect detection of the App ID prefix [in rare circumstances](https://github.com/square/Valet/pull/218), the App ID prefix must now be explicitly passed into these methods. To create a shared access groups Valet, you'll need to create a `SharedGroupIdentifier(appIDPrefix:nonEmptyGroup:)`. [See examples above](#sharing-secrets-among-multiple-applications-using-an-app-groups-entitlement).

## Contributing

We’re glad you’re interested in Valet, and we’d love to see where you take it. Please read our [contributing guidelines](Contributing.md) prior to submitting a Pull Request.

Thanks, and please *do* take it for a joyride!
