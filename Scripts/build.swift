#!/usr/bin/env swift

import Foundation

// Usage: build.swift platforms [spm|xcode]

func execute(commandPath: String, arguments: [String]) throws {
    let task = Process()
    task.launchPath = commandPath
    task.arguments = arguments
    print("Launching command: \(commandPath) \(arguments.joined(separator: " "))")
    task.launch()
    task.waitUntilExit()
    guard task.terminationStatus == 0 else {
        throw TaskError.code(task.terminationStatus)
    }
}

enum TaskError: Error {
    case code(Int32)
}

enum Platform: String, CustomStringConvertible {
    case iOS_13
    case iOS_14
    case iOS_15
    case tvOS_13
    case tvOS_14
    case tvOS_15
    case macOS_10_15
    case macOS_11
    case macOS_12
    case watchOS_6
    case watchOS_7
    case watchOS_8

    var destination: String {
        switch self {
        case .iOS_13:
            return "platform=iOS Simulator,OS=13.7,name=iPad Pro (12.9-inch) (4th generation)"
        case .iOS_14:
            return "platform=iOS Simulator,OS=14.4,name=iPad Pro (12.9-inch) (4th generation)"
        case .iOS_15:
            return "platform=iOS Simulator,OS=15.5,name=iPad Pro (12.9-inch) (5th generation)"

        case .tvOS_13:
            return "platform=tvOS Simulator,OS=13.4,name=Apple TV"
        case .tvOS_14:
            return "platform=tvOS Simulator,OS=14.3,name=Apple TV"
        case .tvOS_15:
            return "platform=tvOS Simulator,OS=15.4,name=Apple TV"

        case .macOS_10_15,
             .macOS_11,
             .macOS_12:
            return "platform=OS X"

        case .watchOS_6:
            return "OS=6.2.1,name=Apple Watch Series 4 - 44mm"
        case .watchOS_7:
            return "OS=7.2,name=Apple Watch Series 6 - 44mm"
        case .watchOS_8:
            return "OS=8.5,name=Apple Watch Series 6 (44mm)"
        }
    }

    var sdk: String {
        switch self {
        case .iOS_13,
             .iOS_14,
             .iOS_15:
            return "iphonesimulator"

        case .tvOS_13,
             .tvOS_14,
             .tvOS_15:
            return "appletvsimulator"

        case .macOS_10_15:
            return "macosx10.15"
        case .macOS_11:
            return "macosx11.1"
        case .macOS_12:
            return "macosx12.3"

        case .watchOS_6,
             .watchOS_7,
             .watchOS_8:
            return "watchsimulator"
        }
    }

    var shouldTest: Bool {
        switch self {
        case .iOS_13,
             .iOS_14,
             .iOS_15,
             .tvOS_13,
             .tvOS_14,
             .tvOS_15,
             .macOS_10_15,
             .macOS_11,
             .macOS_12:
            return true

        case .watchOS_6,
             .watchOS_7,
             .watchOS_8:
            // watchOS does not support unit testing (yet?).
            return false
        }
    }

    var derivedDataPath: String {
        ".build/derivedData/" + description
    }

    var scheme: String {
        switch self {
        case .iOS_13,
             .iOS_14,
             .iOS_15:
            return "Valet iOS"

        case .tvOS_13,
             .tvOS_14,
             .tvOS_15:
            return "Valet tvOS"

        case .macOS_10_15,
             .macOS_11,
             .macOS_12:
            return "Valet Mac"

        case .watchOS_6,
             .watchOS_7,
             .watchOS_8:
            return "Valet watchOS"
        }
    }

    var description: String {
        rawValue
    }
}

enum Task: String, CustomStringConvertible {
    case spm
    case xcode

    var description: String {
        rawValue
    }

    var project: String {
        switch self {
        case .spm:
            return "generated/Valet.xcodeproj"
        case .xcode:
            return "Valet.xcodeproj"
        }
    }

    var shouldGenerateXcodeProject: Bool {
        switch self {
        case .spm:
            return true
        case .xcode:
            return false
        }
    }

    var shouldUseLegacyBuildSystem: Bool {
        switch self {
        case .spm:
            return false
        case .xcode:
            // The new build system choked on our XCTest framework.
            // Once this project compiles with the new build system,
            // we can change this to false.
            return true
        }
    }

    var configuration: String {
        switch self {
        case .spm:
            return "Release"
        case .xcode:
            return "Debug"
        }
    }

    func scheme(for platform: Platform) -> String {
        switch self {
        case .spm:
            return "Valet-Package"
        case .xcode:
            return platform.scheme
        }
    }

    func shouldTest(on platform: Platform) -> Bool {
        switch self {
        case .spm:
            // Our Package isn't set up with unit test targets, becuase SPM can't run unit tests in a codesigned environment.
            return false
        case .xcode:
            return platform.shouldTest
        }
    }
}

guard CommandLine.arguments.count > 2 else {
    print("Usage: build.swift platforms [spm|xcode]")
    throw TaskError.code(1)
}
let rawPlatforms = CommandLine.arguments[1].components(separatedBy: ",")
let rawTask = CommandLine.arguments[2]

guard let task = Task(rawValue: rawTask) else {
    print("Received unknown task \(rawTask)")
    throw TaskError.code(1)
}

if task.shouldGenerateXcodeProject {
    try execute(commandPath: "/usr/bin/xcrun", arguments: ["/usr/bin/swift", "package", "generate-xcodeproj", "--output=generated/"])
}


for rawPlatform in rawPlatforms {
    guard let platform = Platform(rawValue: rawPlatform) else {
        print("Received unknown platform type \(rawPlatform)")
        throw TaskError.code(1)
    }
    var xcodeBuildArguments = [
        "-project", task.project,
        "-scheme", task.scheme(for: platform),
        "-sdk", platform.sdk,
        "-configuration", task.configuration,
        "-PBXBuildsContinueAfterErrors=0",
    ]
    if !platform.destination.isEmpty {
        xcodeBuildArguments.append("-destination")
        xcodeBuildArguments.append(platform.destination)
    }
    if task.shouldUseLegacyBuildSystem {
        xcodeBuildArguments.append("-UseModernBuildSystem=0")
    }
    let shouldTest = task.shouldTest(on: platform)
    if shouldTest {
        xcodeBuildArguments.append("-enableCodeCoverage")
        xcodeBuildArguments.append("YES")
        xcodeBuildArguments.append("-derivedDataPath")
        xcodeBuildArguments.append(platform.derivedDataPath)
    }
    xcodeBuildArguments.append("build")
    if shouldTest {
        xcodeBuildArguments.append("test")
    }

    try execute(commandPath: "/usr/bin/xcodebuild", arguments: xcodeBuildArguments)
}
