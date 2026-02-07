// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "{{ProjectName}}",
    platforms: [
        .macOS(.v13),
        .iOS(.v16)
    ],
    products: [
        .executable(
            name: "{{ProjectName}}",
            targets: ["{{ProjectName}}"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/swiftwasm/JavaScriptKit.git", from: "0.19.0"),
        // Add Raven dependency - adjust path/URL as needed
        // .package(path: "../Raven"),
        // .package(url: "https://github.com/yourusername/Raven.git", from: "0.10.0"),
    ],
    targets: [
        .executableTarget(
            name: "{{ProjectName}}",
            dependencies: [
                // "Raven",
                // "RavenRuntime",
                .product(name: "JavaScriptKit", package: "JavaScriptKit")
            ],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency"),
                .enableExperimentalFeature("AccessLevelOnImport")
            ]
        )
    ]
)
