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
    case iOS_11
    case iOS_12
    case iOS_13
    case tvOS_11
    case tvOS_12
    case tvOS_13
    case macOS_10_13
    case macOS_10_14
    case macOS_10_15
    case watchOS_4
    case watchOS_5
    case watchOS_6

    var destination: String {
        switch self {
        case .iOS_11:
            return "platform=iOS Simulator,OS=11.0,name=iPad Pro (12.9-inch) (2nd generation)"
        case .iOS_12:
            return "platform=iOS Simulator,OS=12.2,name=iPad Pro (12.9-inch) (3rd generation)"
        case .iOS_13:
            return "platform=iOS Simulator,OS=13.0,name=iPad Pro (12.9-inch) (3rd generation)"

        case .tvOS_11:
            return "platform=tvOS Simulator,OS=11.0,name=Apple TV"
        case .tvOS_12:
            return "platform=tvOS Simulator,OS=12.2,name=Apple TV"
        case .tvOS_13:
            return "platform=tvOS Simulator,OS=13.0,name=Apple TV"

        case .macOS_10_13,
             .macOS_10_14,
             .macOS_10_15:
            return "platform=OS X"

        case .watchOS_4:
            return "OS=4.0,name=Apple Watch Series 2 - 42mm"
        case .watchOS_5:
            return "OS=5.2,name=Apple Watch Series 4 - 44mm"
        case .watchOS_6:
            return "OS=6.0,name=Apple Watch Series 4 - 44mm"
        }
    }

    var sdk: String {
        switch self {
        case .iOS_11,
             .iOS_12,
             .iOS_13:
            return "iphonesimulator"

        case .tvOS_11,
             .tvOS_12,
             .tvOS_13:
            return "appletvsimulator"

        case .macOS_10_13:
            return "macosx10.13"
        case .macOS_10_14:
            return "macosx10.14"
        case .macOS_10_15:
            return "macosx10.15"

        case .watchOS_4,
             .watchOS_5,
             .watchOS_6:
            return "watchsimulator"
        }
    }

    var shouldTest: Bool {
        switch self {
        case .iOS_11,
             .iOS_12,
             .iOS_13,
             .tvOS_11,
             .tvOS_12,
             .tvOS_13,
             .macOS_10_13,
             .macOS_10_14,
             .macOS_10_15:
            return true

        case .watchOS_4,
             .watchOS_5,
             .watchOS_6:
            // watchOS does not support unit testing (yet?).
            return false
        }
    }

    var scheme: String {
        switch self {
        case .iOS_11,
             .iOS_12,
             .iOS_13:
            return "Valet iOS"

        case .tvOS_11,
             .tvOS_12,
             .tvOS_13:
            return "Valet tvOS"

        case .macOS_10_13,
             .macOS_10_14,
             .macOS_10_15:
            return "Valet Mac"

        case .watchOS_4,
             .watchOS_5,
             .watchOS_6:
            return "Valet watchOS"
        }
    }

    var description: String {
        return rawValue
    }
}

enum Task: String, CustomStringConvertible {
    case spm
    case xcode

    var description: String {
        return rawValue
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
    try execute(commandPath: "/usr/bin/swift", arguments: ["package", "generate-xcodeproj", "--output=generated/"])
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
    xcodeBuildArguments.append("build")
    if task.shouldTest(on: platform) {
        xcodeBuildArguments.append("test")
    }

    try execute(commandPath: "/usr/bin/xcodebuild", arguments: xcodeBuildArguments)
}
