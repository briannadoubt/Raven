// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Raven",
    platforms: [
        .macOS(.v14),
        .iOS(.v17)
    ],
    products: [
        // Main library product
        .library(
            name: "Raven",
            targets: ["Raven"]
        ),
        // Runtime support library
        .library(
            name: "RavenRuntime",
            targets: ["RavenRuntime"]
        ),
        // CLI executable
        .executable(
            name: "raven",
            targets: ["RavenCLI"]
        )
    ],
    dependencies: [
        // JavaScriptKit for WASM/JavaScript interop
        .package(url: "https://github.com/swiftwasm/JavaScriptKit.git", exact: "0.19.2"),
        // ArgumentParser for CLI
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.5.0")
    ],
    targets: [
        // MARK: - Main Library Targets

        // Main Raven library with SwiftUI API
        .target(
            name: "Raven",
            dependencies: [
                .product(name: "JavaScriptKit", package: "JavaScriptKit"),
                .product(name: "JavaScriptEventLoop", package: "JavaScriptKit")
            ],
            path: "Sources/Raven",
            swiftSettings: [

                .enableExperimentalFeature("AccessLevelOnImport"),
                // Size optimization for release builds
                .unsafeFlags(["-Osize"], .when(configuration: .release)),
                .unsafeFlags(["-whole-module-optimization"], .when(configuration: .release)),
            ],
            linkerSettings: [
                // Link-time optimization for smaller binaries
                .unsafeFlags(["-Xlinker", "--lto-O3"], .when(configuration: .release)),
                // Dead code elimination
                .unsafeFlags(["-Xlinker", "--gc-sections"], .when(configuration: .release)),
                // Strip debug info in release
                .unsafeFlags(["-Xlinker", "--strip-debug"], .when(configuration: .release))
            ]
        ),

        // Runtime support library
        .target(
            name: "RavenRuntime",
            dependencies: [
                "Raven",
                .product(name: "JavaScriptKit", package: "JavaScriptKit")
            ],
            path: "Sources/RavenRuntime",
            swiftSettings: [

                .enableExperimentalFeature("AccessLevelOnImport"),
                // Size optimization for release builds
                .unsafeFlags(["-Osize"], .when(configuration: .release)),
                .unsafeFlags(["-whole-module-optimization"], .when(configuration: .release)),
            ],
            linkerSettings: [
                // Link-time optimization for smaller binaries
                .unsafeFlags(["-Xlinker", "--lto-O3"], .when(configuration: .release)),
                // Dead code elimination
                .unsafeFlags(["-Xlinker", "--gc-sections"], .when(configuration: .release)),
                // Strip debug info in release
                .unsafeFlags(["-Xlinker", "--strip-debug"], .when(configuration: .release))
            ]
        ),

        // CLI executable for build tooling
        .executableTarget(
            name: "RavenCLI",
            dependencies: [
                "Raven",
                "RavenRuntime",
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ],
            path: "Sources/RavenCLI",
            swiftSettings: [

                .enableExperimentalFeature("AccessLevelOnImport")
            ]
        ),

        // MARK: - Test Targets

        // Core Raven tests
        .testTarget(
            name: "RavenTests",
            dependencies: ["Raven"],
            path: "Tests/RavenTests",
            swiftSettings: [

                .enableExperimentalFeature("AccessLevelOnImport")
            ]
        ),

        // VirtualDOM-specific tests
        .testTarget(
            name: "VirtualDOMTests",
            dependencies: ["Raven"],
            path: "Tests/VirtualDOMTests",
            swiftSettings: [

                .enableExperimentalFeature("AccessLevelOnImport")
            ]
        ),

        // Integration tests
        .testTarget(
            name: "IntegrationTests",
            dependencies: [
                "Raven",
                "RavenRuntime"
            ],
            path: "Tests/IntegrationTests",
            swiftSettings: [

                .enableExperimentalFeature("AccessLevelOnImport")
            ]
        ),

        // RavenCLI tests
        .testTarget(
            name: "RavenCLITests",
            dependencies: [
                "RavenCLI"
            ],
            path: "Tests/RavenCLI",
            swiftSettings: [

                .enableExperimentalFeature("AccessLevelOnImport")
            ]
        )
    ]
)
