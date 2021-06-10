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
    case iOS_10
    case iOS_11
    case iOS_12
    case iOS_13
    case iOS_14
    case tvOS_10
    case tvOS_11
    case tvOS_12
    case tvOS_13
    case tvOS_14
    case macOS_10_12
    case macOS_10_13
    case macOS_10_14
    case macOS_10_15
    case watchOS_3
    case watchOS_4
    case watchOS_5
    case watchOS_6
    case watchOS_7

    var destination: String {
        switch self {
        case .iOS_10:
            return "platform=iOS Simulator,OS=10.3.1,name=iPad Pro (12.9 inch)"
        case .iOS_11:
            return "platform=iOS Simulator,OS=11.4,name=iPad Pro (12.9-inch) (2nd generation)"
        case .iOS_12:
            return "platform=iOS Simulator,OS=12.4,name=iPad Pro (12.9-inch) (3rd generation)"
        case .iOS_13:
            return "platform=iOS Simulator,OS=13.7,name=iPad Pro (12.9-inch) (4th generation)"
        case .iOS_14:
            return "platform=iOS Simulator,OS=14.4,name=iPad Pro (12.9-inch) (4th generation)"

        case .tvOS_10:
            return "platform=tvOS Simulator,OS=10.2,name=Apple TV 1080p"
        case .tvOS_11:
            return "platform=tvOS Simulator,OS=11.4,name=Apple TV"
        case .tvOS_12:
            return "platform=tvOS Simulator,OS=12.4,name=Apple TV"
        case .tvOS_13:
            return "platform=tvOS Simulator,OS=13.4,name=Apple TV"
        case .tvOS_14:
            return "platform=tvOS Simulator,OS=14.3,name=Apple TV"

        case .macOS_10_12,
             .macOS_10_13,
             .macOS_10_14,
             .macOS_10_15:
            return "platform=OS X"

        case .watchOS_3:
            return "OS=3.2,name=Apple Watch Series 2 - 42mm"
        case .watchOS_4:
            return "OS=4.3,name=Apple Watch Series 2 - 42mm"
        case .watchOS_5:
            return "OS=5.3,name=Apple Watch Series 4 - 44mm"
        case .watchOS_6:
            return "OS=6.2.1,name=Apple Watch Series 4 - 44mm"
        case .watchOS_7:
            return "OS=7.2,name=Apple Watch Series 6 - 44mm"
        }
    }

    var sdk: String {
        switch self {
        case .iOS_10,
             .iOS_11,
             .iOS_12,
             .iOS_13,
             .iOS_14:
            return "iphonesimulator"

        case .tvOS_10,
             .tvOS_11,
             .tvOS_12,
             .tvOS_13,
             .tvOS_14:
            return "appletvsimulator"

        case .macOS_10_12:
            return "macosx10.12"
        case .macOS_10_13:
            return "macosx10.13"
        case .macOS_10_14:
            return "macosx10.14"
        case .macOS_10_15:
            return "macosx10.15"

        case .watchOS_3,
             .watchOS_4,
             .watchOS_5,
             .watchOS_6,
             .watchOS_7:
            return "watchsimulator"
        }
    }

    var shouldTest: Bool {
        switch self {
        case .iOS_10,
             .iOS_11,
             .iOS_12,
             .iOS_13,
             .iOS_14,
             .tvOS_10,
             .tvOS_11,
             .tvOS_12,
             .tvOS_13,
             .tvOS_14,
             .macOS_10_12,
             .macOS_10_13,
             .macOS_10_14,
             .macOS_10_15:
            return true

        case .watchOS_3,
             .watchOS_4,
             .watchOS_5,
             .watchOS_6,
             .watchOS_7:
            // watchOS does not support unit testing (yet?).
            return false
        }
    }

    var derivedDataPath: String {
        ".build/derivedData/" + description
    }

    var scheme: String {
        switch self {
        case .iOS_10,
             .iOS_11,
             .iOS_12,
             .iOS_13,
             .iOS_14:
            return "Valet iOS"

        case .tvOS_10,
             .tvOS_11,
             .tvOS_12,
             .tvOS_13,
             .tvOS_14:
            return "Valet tvOS"

        case .macOS_10_12,
             .macOS_10_13,
             .macOS_10_14,
             .macOS_10_15:
            return "Valet Mac"

        case .watchOS_3,
             .watchOS_4,
             .watchOS_5,
             .watchOS_6,
             .watchOS_7:
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
