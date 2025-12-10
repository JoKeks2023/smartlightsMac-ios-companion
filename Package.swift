// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SmartLightsIOSCompanion",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "SmartLightsIOSCompanion",
            targets: ["SmartLightsIOSCompanion"]
        ),
    ],
    dependencies: [
        // Add any external dependencies here
    ],
    targets: [
        .target(
            name: "SmartLightsIOSCompanion",
            dependencies: [],
            path: "Sources"
        ),
        .testTarget(
            name: "SmartLightsIOSCompanionTests",
            dependencies: ["SmartLightsIOSCompanion"],
            path: "Tests"
        ),
    ]
)
