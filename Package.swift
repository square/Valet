// swift-tools-version:6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Valet",
    platforms: [
        .iOS(.v12),
        .tvOS(.v12),
        .watchOS(.v4),
        .macOS(.v10_13),
    ],
    products: [
        .library(
            name: "Valet",
            targets: ["Valet"]
        ),
    ],
    targets: [
        .target(
            name: "Valet",
            dependencies: [],
            swiftSettings: [
                .swiftLanguageMode(.v6),
            ]
        ),
    ]
)
