// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription
import CompilerPluginSupport

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
        // TipKit compatibility shims (including macros) for Raven.
        .library(
            name: "TipKit",
            targets: ["TipKit"]
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
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.5.0"),
        // SwiftSyntax for macro implementations (used by TipKit shims).
        .package(url: "https://github.com/swiftlang/swift-syntax.git", exact: "602.0.0")
    ],
    targets: [
        // MARK: - Main Library Targets

        // Shared support for asset catalogs (IDs, normalization) used by both CLI and runtime.
        .target(
            name: "RavenAssetSupport",
            path: "Sources/RavenAssetSupport"
        ),

        // Core Raven library with SwiftUI API (views, modifiers, VDOM, state).
        .target(
            name: "RavenCore",
            dependencies: [
                "RavenAssetSupport",
                "RavenPreviewMacros",
                .product(name: "JavaScriptKit", package: "JavaScriptKit"),
                .product(name: "JavaScriptEventLoop", package: "JavaScriptKit")
            ],
            path: "Sources/RavenCore",
            exclude: [
                "Rendering/Virtualization/README.md",
                "Accessibility/QUICK_REFERENCE.md",
                "Accessibility/ARIA_COVERAGE.md",
                "Presentation/Rendering/README.md",
                "State/STATE_OBJECT_README.md",
                "State/OBSERVABLE_OBJECT_README.md",
                "State/OBSERVABLE_README.md",
                "State/README.md",
                "Modifiers/INTERACTION_MODIFIERS_README.md",
                "Modifiers/LAYOUT_MODIFIERS_README.md",
                "Modifiers/README.md",
                "Debug/README.md",
                "Drawing/PATH_README.md",
                "Performance/IMPLEMENTATION_SUMMARY.md",
                "Performance/README.md",
                "Views/Layout/DisclosureGroup.css",
                "Views/Layout/ListFeatures/README.md",
            ]
        ),

        // Umbrella module: "import Raven" should pull in both the API surface and runtime.
        .target(
            name: "Raven",
            dependencies: [
                "RavenCore",
                "RavenRuntime"
            ],
            path: "Sources/Raven"
        ),

        // TipKit API shims for Raven (including macros).
        //
        // This is a "compat" module that lets Raven apps compile TipKit-style code
        // when targeting WASM, where the system TipKit framework isn't available.
        .target(
            name: "TipKit",
            dependencies: [
                "RavenCore",
                "TipKitMacros"
            ],
            path: "Sources/TipKit"
        ),
        .macro(
            name: "TipKitMacros",
            dependencies: [
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftSyntaxBuilder", package: "swift-syntax"),
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax")
            ],
            path: "Sources/TipKitMacros"
        ),

        // SwiftUI Preview compatibility shims (including the `#Preview` macro).
        .macro(
            name: "RavenPreviewMacros",
            dependencies: [
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftSyntaxBuilder", package: "swift-syntax"),
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax")
            ],
            path: "Sources/RavenPreviewMacros"
        ),

        // Runtime support library
        .target(
            name: "RavenRuntime",
            dependencies: [
                "RavenCore",
                .product(name: "JavaScriptKit", package: "JavaScriptKit"),
                .product(name: "JavaScriptEventLoop", package: "JavaScriptKit")
            ],
            path: "Sources/RavenRuntime",
            swiftSettings: []
        ),

        // CLI executable for build tooling
        .executableTarget(
            name: "RavenCLI",
            dependencies: [
                "Raven",
                "RavenAssetSupport",
                "RavenRuntime",
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ],
            path: "Sources/RavenCLI",
            swiftSettings: []
        ),

        // MARK: - Test Targets

        // Core Raven tests
        .testTarget(
            name: "RavenTests",
            dependencies: ["Raven", "RavenCore", "RavenAssetSupport"],
            path: "Tests/RavenTests",
            swiftSettings: []
        ),

        // VirtualDOM-specific tests
        .testTarget(
            name: "VirtualDOMTests",
            dependencies: ["Raven"],
            path: "Tests/VirtualDOMTests",
            swiftSettings: []
        ),

        // Integration tests
        .testTarget(
            name: "IntegrationTests",
            dependencies: [
                "Raven",
                "RavenRuntime"
            ],
            path: "Tests/IntegrationTests",
            swiftSettings: []
        ),

        // RavenCLI tests
        .testTarget(
            name: "RavenCLITests",
            dependencies: [
                "RavenCLI",
                "RavenAssetSupport",
            ],
            path: "Tests/RavenCLI",
            swiftSettings: []
        )
    ]
)
