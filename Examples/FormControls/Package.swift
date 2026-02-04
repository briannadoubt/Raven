// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "FormControls",
    platforms: [
        .macOS(.v13),
        .iOS(.v16)
    ],
    products: [
        .executable(
            name: "FormControls",
            targets: ["FormControls"]
        )
    ],
    dependencies: [
        // Local dependency on Raven
        .package(path: "../../")
    ],
    targets: [
        .executableTarget(
            name: "FormControls",
            dependencies: [
                .product(name: "Raven", package: "Raven"),
                .product(name: "RavenRuntime", package: "Raven")
            ],
            path: "Sources/FormControls",
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency"),
                .enableExperimentalFeature("AccessLevelOnImport")
            ]
        )
    ]
)
