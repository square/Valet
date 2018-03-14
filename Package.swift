// swift-tools-version:4.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Valet",
    products: [
        .library(name: "Valet", targets: ["Valet"]),
    ],
    targets: [
        .target(name: "Valet", path: "Sources"),
    ]
)
