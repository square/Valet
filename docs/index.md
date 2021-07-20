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
    .package(url: "https://github.com/Square/Valet", from: "4.0.0"),
],
```

### Submodules

Or manually checkout the submodule with `git submodule add git@github.com:Square/Valet.git`, drag Valet.xcodeproj to your project, and add Valet as a build dependency.
