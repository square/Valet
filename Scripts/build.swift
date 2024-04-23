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
    case iOS_15
    case iOS_16
    case iOS_17
    case tvOS_15
    case tvOS_16
    case tvOS_17
    case macOS_12
    case macOS_13
    case macOS_14
    case watchOS_8
    case watchOS_9
    case watchOS_10

    var destination: String {
        switch self {
        case .iOS_15:
            return "platform=iOS Simulator,OS=15.5,name=iPad Pro (12.9-inch) (5th generation)"
        case .iOS_16:
            return "platform=iOS Simulator,OS=16.4,name=iPad Pro (12.9-inch) (6th generation)"
        case .iOS_17:
            return "platform=iOS Simulator,OS=17.4,name=iPad Pro (12.9-inch) (6th generation)"

        case .tvOS_15:
            return "platform=tvOS Simulator,OS=15.4,name=Apple TV"
        case .tvOS_16:
            return "platform=tvOS Simulator,OS=16.4,name=Apple TV"
        case .tvOS_17:
            return "platform=tvOS Simulator,OS=17.4,name=Apple TV"

        case .macOS_12,
             .macOS_13,
             .macOS_14:
            return "platform=OS X"

        case .watchOS_8:
            return "OS=8.5,name=Apple Watch Series 6 - 44mm"
        case .watchOS_9:
            return "OS=9.4,name=Apple Watch Series 6 (44mm)"
        case .watchOS_10:
            return "OS=10.4,name=Apple Watch Series 9 (45mm)"
        }
    }

    var sdk: String {
        switch self {
        case .iOS_15,
             .iOS_16,
             .iOS_17:
            return "iphonesimulator"

        case .tvOS_15,
             .tvOS_16,
             .tvOS_17:
            return "appletvsimulator"

        case .macOS_12:
            return "macosx12.3"
        case .macOS_13:
            return "macosx13.3"
        case .macOS_14:
            return "macosx14.4"

        case .watchOS_8,
             .watchOS_9,
             .watchOS_10:
            return "watchsimulator"
        }
    }

    /// Whether the platform's Xcode version requires modern SPM integration in xcodebuild, given the removal of generate-xcodeproj.
    var requiresModernSPMIntegration: Bool {
        switch self {
        case .iOS_16, .tvOS_16, .watchOS_9, .macOS_13,
            .iOS_17, .tvOS_17, .watchOS_10, .macOS_14:
            return true
        default:
            return false
        }
    }

    var derivedDataPath: String {
        ".build/derivedData/" + description
    }

    var scheme: String {
        switch self {
        case .iOS_15,
             .iOS_16,
             .iOS_17:
            return "Valet iOS"

        case .tvOS_15,
             .tvOS_16,
             .tvOS_17:
            return "Valet tvOS"

        case .macOS_12,
             .macOS_13,
             .macOS_14:
            return "Valet Mac"

        case .watchOS_8,
             .watchOS_9,
             .watchOS_10:
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

    func project(for platform: Platform) -> String? {
        if platform.requiresModernSPMIntegration {
            return nil
        } else {
            switch self {
            case .spm:
                return "generated/Valet.xcodeproj"
            case .xcode:
                return "Valet.xcodeproj"
            }
        }
    }

    func shouldGenerateXcodeProject(for platform: Platform) -> Bool {
        if platform.requiresModernSPMIntegration {
            return false
        } else {
            switch self {
            case .spm:
                return true
            case .xcode:
                return false
            }
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
            if platform.requiresModernSPMIntegration {
                return "Valet"
            } else {
                return "Valet-Package"
            }
        case .xcode:
            return platform.scheme
        }
    }

    func shouldTest(on platform: Platform) -> Bool {
        switch self {
        case .spm:
            // Our Package isn't set up with unit test targets, because SPM can't run unit tests in a codesigned environment.
            return false
        case .xcode:
            return true
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

// Only generate xcodeproj for SPM on platforms that require it.
let shouldGenerateXcodeproj = task == .spm && platforms.map { task.shouldGenerateXcodeProject(for: $0) }.contains(true)
if shouldGenerateXcodeproj {
    try execute(commandPath: "/usr/bin/xcrun", arguments: ["/usr/bin/swift", "package", "generate-xcodeproj", "--output=generated/"])
}

for platform in platforms {
    var deletedXcodeproj = false
    var xcodeBuildArguments: [String] = []
    // If necessary, delete Valet.xcodeproj, otherwise xcodebuild won't generate the SPM scheme.
    // If deleted, the xcodeproj will be restored by git at the end of the loop.
    if task == .spm && platform.requiresModernSPMIntegration {
        do {
            print("Deleting Valet.xcodeproj, any uncommitted changes will be lost.")
            try execute(commandPath: "/bin/rm", arguments: ["-r", "Valet.xcodeproj"])
            deletedXcodeproj = true
        } catch {
            print("Could not delete Valet.xcodeproj due to error: \(error)")
            throw TaskError.code(1)
        }
    }

    if let project = task.project(for: platform) {
        xcodeBuildArguments.append("-project")
        xcodeBuildArguments.append(project)
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
