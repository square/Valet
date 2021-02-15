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

### Testing changes on watchOS

When making changes that change how the keychain works on watchOS, you must test this change locally. Unfortunately, Apple doesn't yet ship a native XCTest library on watchOS, which means we currently cannot easily run these tests in CI. We have, however, hooked up [a custom implementation of XCTest](https://github.com/dfed/XCTest-watchOS) to enable running tests locally. If you're interested in helping us get this test suite running in CI, check out issue [#128](https://github.com/square/Valet/issues/128).

To run tests against watchOS, you'll need to select the `Valet watchOS Test Host App` target, select an Apple Watch simulator, and then run the target. You'll know that tests have succeeded because the application run will not hit an assertion failure and will print `ALL TESTS PASSED` to the Xcode console.
