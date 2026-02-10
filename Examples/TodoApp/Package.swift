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
                    name: "RavenSwiftUI",
                    package: "Raven",
                    // Alias the umbrella module to "SwiftUI" for WASI builds, so app
                    // sources can be:
                    //   import SwiftUI
                    // and still get RavenRuntime's default `App.main()` implementation.
                    // SwiftPM moduleAliases produce `-module-alias <key>=<value>`.
                    // We want app sources to be able to `import SwiftUI`, backed by the
                    // actual module `RavenSwiftUI`.
                    moduleAliases: ["SwiftUI": "RavenSwiftUI"],
                    condition: .when(platforms: [.wasi])
                )
            ],
            path: "Sources/TodoApp",
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
