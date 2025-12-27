// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SmartLightsIOSCompanion",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .executable(
            name: "SmartLightsIOSCompanion",
            targets: ["SmartLightsIOSCompanion"]
        )
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "SmartLightsIOSCompanion",
            dependencies: [],
            path: "SmartLightsIOSCompanion",
            resources: [
                .process("Assets.xcassets"),
                .process("Preview Content")
            ]
        )
    ]
)
