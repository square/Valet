#!/usr/bin/env swift

import Foundation

// Usage: build.swift platforms [spm|xcode]

func execute(commandPath: String, arguments: [String]) throws {
    let task = Process()
    task.executableURL = .init(filePath: commandPath)
    task.arguments = arguments
    print("Launching command: \(commandPath) \(arguments.joined(separator: " "))")
    try task.run()
    task.waitUntilExit()
    guard task.terminationStatus == 0 else {
        throw TaskError.code(task.terminationStatus)
    }
}

enum TaskError: Error {
    case code(Int32)
}

enum Platform: String, CustomStringConvertible {
    case iOS_18
    case tvOS_18
    case macOS_15
    case watchOS_11

    var destination: String {
        switch self {
        case .iOS_18:
            "platform=iOS Simulator,OS=18.4,name=iPhone 16"

        case .tvOS_18:
            "platform=tvOS Simulator,OS=18.2,name=Apple TV"

        case .macOS_15:
            "platform=OS X"

        case .watchOS_11:
            "OS=11.2,name=Apple Watch Series 10 (46mm)"
        }
    }

    var sdk: String {
        switch self {
        case .iOS_18:
            "iphonesimulator"

        case .tvOS_18:
            "appletvsimulator"

        case .macOS_15:
            "macosx15.5"

        case .watchOS_11:
            "watchsimulator"
        }
    }

    var derivedDataPath: String {
        ".build/derivedData/" + description
    }

    var scheme: String {
        switch self {
        case .iOS_18:
            "Valet iOS"

        case .tvOS_18:
            "Valet tvOS"

        case .macOS_15:
            "Valet Mac"

        case .watchOS_11:
            "Valet watchOS"
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

    var shouldUseLegacyBuildSystem: Bool {
        switch self {
        case .spm:
            false
        case .xcode:
            // The new build system choked on our XCTest framework.
            // Once this project compiles with the new build system,
            // we can change this to false.
            true
        }
    }

    var configuration: String {
        switch self {
        case .spm:
            "Release"
        case .xcode:
            "Debug"
        }
    }

    func scheme(for platform: Platform) -> String {
        switch self {
        case .spm:
            "Valet"
        case .xcode:
            platform.scheme
        }
    }

    func shouldTest(on platform: Platform) -> Bool {
        switch self {
        case .spm:
            // Our Package isn't set up with unit test targets, because SPM can't run unit tests in a codesigned environment.
            false
        case .xcode:
            true
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

let platforms = try rawPlatforms.map { rawPlatform -> Platform in
    guard let platform = Platform(rawValue: rawPlatform) else {
        print("Received unknown platform type \(rawPlatform)")
        throw TaskError.code(1)
    }

    return platform
}

for platform in platforms {
    var deletedXcodeproj = false
    var xcodeBuildArguments: [String] = []
    // If necessary, delete Valet.xcodeproj, otherwise xcodebuild won't generate the SPM scheme.
    // If deleted, the xcodeproj will be restored by git at the end of the loop.
    if task == .spm {
        do {
            print("Deleting Valet.xcodeproj, any uncommitted changes will be lost.")
            try execute(commandPath: "/bin/rm", arguments: ["-r", "Valet.xcodeproj"])
            deletedXcodeproj = true
        } catch {
            print("Could not delete Valet.xcodeproj due to error: \(error)")
            throw TaskError.code(1)
        }
    }

    xcodeBuildArguments.append(contentsOf: [
        "-scheme", task.scheme(for: platform),
        "-sdk", platform.sdk,
        "-configuration", task.configuration,
        "-PBXBuildsContinueAfterErrors=0",
    ])
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

    if deletedXcodeproj {
        do {
            print("Restoring Valet.xcodeproj")
            try execute(commandPath: "/usr/bin/git", arguments: ["restore", "Valet.xcodeproj"])
        } catch {
            print("Failed to reset Valet.xcodeproj to last committed version due to error: \(error)")
        }
    }
}
