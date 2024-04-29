### Sign the CLA

All contributors to your PR must sign our [Individual Contributor License Agreement (CLA)](https://spreadsheets.google.com/spreadsheet/viewform?formkey=dDViT2xzUHAwRkI3X3k5Z0lQM091OGc6MQ&ndplr=1). The CLA is a short form that ensures that you are eligible to contribute.

### One issue or bug per Pull Request

Keep your Pull Requests small. Small PRs are easier to reason about which makes them significantly more likely to get merged.

### Issues before features

If you want to add a feature, please file an [Issue](https://github.com/square/Valet/issues) first. An Issue gives us the opportunity to discuss the requirements and implications of a feature with you before you start writing code.

### Backwards compatibility

Respect the minimum deployment target. If you are adding code that uses new APIs, make sure to prevent older clients from crashing or misbehaving. Our CI runs against our minimum deployment targets, so you will not get a green build unless your code is backwards compatible. 

### Forwards compatibility

Please do not write new code using deprecated APIs.

### Testing changes on macOS

When making changes that change how the keychain works on macOS, you must test this change locally. Unfortunately, running our integration test suite on macOS requires a signed environment, and the esoteric nature of codesigning on macOS means we currently cannot run these tests in CI.

To run macOS tests locally, you'll need to do the following in the Valet Xcode project settings:

1. Read through all the following steps before starting this process!
1. Commit your current work to `git` so you can easily clear the following changes.
1. Select the `Valet Mac Tests` target's "General" settings and change the "Host Application" setting from `None` to `Valet macOS Test Host App`
1. Select the `Valet Mac Tests` target's "Signing & Capabilities" settings and change the "Team" to be your personal team.
1. Select the  `Valet macOS Test Host App` target's "Signing & Capabilities" settings and select the "Team" to be your personal team. This will result in an error – this is expected and continuing to follow the below steps will resolve the error.
1. Select the  `Valet macOS Test Host App` target's "Signing & Capabilities" settings and change the Bundle Identifier to be a unique bundle identifier that references your team name. Run a find and replace over the code to change all `com.squareup.Valet-macOS-Test-Host-App` strings to be your new bundle identifier.
1. Run a find and replace over the code to change all instances of `9XUJ7M53NG` to reference your personal team ID. Your personal team ID is the same as the prefix shown in the App Groups entitlement.  
1. Make the `_sharedAccessGroupPrefix` method of `VALLegacyValet` return your personal team ID by adding `return @"Your_Team_ID_Here";` to the first line of this method.
1. Select the `Valet Mac` scheme.

You can now run all macOS tests locally. Note that you will be required to enter your computer password _many_ times in order for the tests to successfully complete. Failing to enter your password will cause a test to fail. Make sure not to commit these project configuration and code changes after testing your change.

If you encounter entitlement errors when running tests after following the above steps, you can address by opening `/System/Applications/Utilities/Keychain\ Access.app` and deleting all entries that start with `VAL_VAL`. Note that this will delete any secrets from your macOS applications that utilize Valet, so this step should be taken only as a last resort.
