// swift-tools-version:5.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Valet",
    platforms: [
        .iOS(.v9),
        .tvOS(.v9),
        .watchOS(.v2),
        .macOS(.v10_11),
    ],
    products: [
        .library(
            name: "Valet",
            targets: ["Valet"]),
    ],
    targets: [
        .target(
            name: "Valet",
            dependencies: []),
    ],
    swiftLanguageVersions: [.v5]
)
