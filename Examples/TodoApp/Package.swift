// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "TodoApp",
    platforms: [
        .macOS(.v14),
        .iOS(.v17)
    ],
    products: [
        .executable(
            name: "TodoApp",
            targets: ["TodoApp"]
        )
    ],
    dependencies: [
        // Local dependency on Raven
        .package(path: "../../")
    ],
    targets: [
        .executableTarget(
            name: "TodoApp",
            dependencies: [
                .product(name: "Raven", package: "Raven"),
                .product(name: "RavenRuntime", package: "Raven")
            ],
            path: "Sources/TodoApp",
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency"),
                .enableExperimentalFeature("AccessLevelOnImport")
            ],
            linkerSettings: [
                // Increase WASM stack size to 1MB (default is ~64KB) to handle
                // deeply nested view modifier chains without stack overflow
                .unsafeFlags(["-Xlinker", "-z", "-Xlinker", "stack-size=1048576"])
            ]
        )
    ]
)
