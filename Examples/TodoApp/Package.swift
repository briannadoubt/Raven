// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "TodoApp",
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
                .product(
                    name: "Raven",
                    package: "Raven",
                    condition: .when(platforms: [.wasi])
                )
            ],
            path: "Sources/TodoApp",
            resources: [
                // Raven's dev server / bundler consumes the processed resources directory.
                // Declare xcassets so SwiftPM doesn't treat it as an unhandled file.
                .process("Assets.xcassets")
            ],
            swiftSettings: [
                .enableExperimentalFeature("AccessLevelOnImport")
            ],
            linkerSettings: [
                // Increase WASM stack size to 1MB (default is ~64KB) to handle
                // deeply nested view modifier chains without stack overflow
                .unsafeFlags(
                    ["-Xlinker", "-z", "-Xlinker", "stack-size=1048576"],
                    .when(platforms: [.wasi])
                )
            ]
        )
    ]
)
