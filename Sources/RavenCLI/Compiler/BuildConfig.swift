import Foundation

/// Configuration for WASM compilation
struct BuildConfig: Sendable {
    /// The source directory containing the Swift package
    let sourceDirectory: URL

    /// The output directory for compiled artifacts
    let outputDirectory: URL

    /// Optimization level for compilation
    let optimizationLevel: OptimizationLevel

    /// Target triple for WASM compilation
    let targetTriple: String

    /// Additional compiler flags
    let additionalFlags: [String]

    /// Whether to enable debug symbols
    let debugSymbols: Bool

    /// Whether to enable verbose output
    let verbose: Bool

    /// The name of the Swift SDK to use (e.g. "swift-6.2.3-RELEASE_wasm")
    let swiftSDKName: String?

    /// The name of the executable target (e.g. "TodoApp")
    let executableTargetName: String?

    enum OptimizationLevel: String, Sendable {
        case debug = "debug"
        case release = "release"
        case size = "size"  // Optimize for size (-Osize)

        var swiftFlag: String {
            switch self {
            case .debug:
                return "-Onone"
            case .release:
                return "-O"
            case .size:
                return "-Osize"
            }
        }

        var cartonFlag: String {
            switch self {
            case .debug:
                return "--debug"
            case .release, .size:
                return "--release"
            }
        }

        var description: String {
            switch self {
            case .debug:
                return "Debug (no optimization)"
            case .release:
                return "Release (speed optimization)"
            case .size:
                return "Size (binary size optimization)"
            }
        }
    }

    init(
        sourceDirectory: URL,
        outputDirectory: URL,
        optimizationLevel: OptimizationLevel = .debug,
        targetTriple: String = "wasm32-unknown-wasi",
        additionalFlags: [String] = [],
        debugSymbols: Bool = true,
        verbose: Bool = false,
        swiftSDKName: String? = nil,
        executableTargetName: String? = nil
    ) {
        self.sourceDirectory = sourceDirectory
        self.outputDirectory = outputDirectory
        self.optimizationLevel = optimizationLevel
        self.targetTriple = targetTriple
        self.additionalFlags = additionalFlags
        self.debugSymbols = debugSymbols
        self.verbose = verbose
        self.swiftSDKName = swiftSDKName
        self.executableTargetName = executableTargetName
    }

    /// The build directory path
    var buildDirectory: URL {
        sourceDirectory.appendingPathComponent(".build")
    }

    /// The expected WASM output path for carton builds
    var cartonWasmPath: URL {
        buildDirectory
            .appendingPathComponent(optimizationLevel.rawValue + ".wasm")
            .appendingPathComponent("app.wasm")
    }

    /// The expected WASM output path for swiftc builds
    var swiftcWasmPath: URL {
        buildDirectory
            .appendingPathComponent(targetTriple)
            .appendingPathComponent(optimizationLevel.rawValue)
            .appendingPathComponent("app.wasm")
    }

    /// The expected WASM output path for swift SDK builds
    var swiftSDKWasmPath: URL {
        let targetName = executableTargetName ?? "App"
        return buildDirectory
            .appendingPathComponent(optimizationLevel == .debug ? "debug" : "release")
            .appendingPathComponent("\(targetName).wasm")
    }

    /// Creates a BuildConfig with default values for the current directory
    static func `default`() -> BuildConfig {
        let currentDir = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        let outputDir = currentDir.appendingPathComponent("dist")

        return BuildConfig(
            sourceDirectory: currentDir,
            outputDirectory: outputDir
        )
    }

    /// Creates a BuildConfig for a specific project path
    static func forProject(at path: String, outputPath: String? = nil) -> BuildConfig {
        let sourceDir = URL(fileURLWithPath: path)
        let outputDir = if let outputPath {
            URL(fileURLWithPath: outputPath)
        } else {
            sourceDir.appendingPathComponent("dist")
        }

        return BuildConfig(
            sourceDirectory: sourceDir,
            outputDirectory: outputDir
        )
    }

    /// Creates a release build configuration
    func asRelease() -> BuildConfig {
        BuildConfig(
            sourceDirectory: sourceDirectory,
            outputDirectory: outputDirectory,
            optimizationLevel: .release,
            targetTriple: targetTriple,
            additionalFlags: additionalFlags,
            debugSymbols: false,
            verbose: verbose,
            swiftSDKName: swiftSDKName,
            executableTargetName: executableTargetName
        )
    }

    /// Creates a size-optimized build configuration
    func asSize() -> BuildConfig {
        BuildConfig(
            sourceDirectory: sourceDirectory,
            outputDirectory: outputDirectory,
            optimizationLevel: .size,
            targetTriple: targetTriple,
            additionalFlags: additionalFlags,
            debugSymbols: false,
            verbose: verbose,
            swiftSDKName: swiftSDKName,
            executableTargetName: executableTargetName
        )
    }

    /// Creates a debug build configuration
    func asDebug() -> BuildConfig {
        BuildConfig(
            sourceDirectory: sourceDirectory,
            outputDirectory: outputDirectory,
            optimizationLevel: .debug,
            targetTriple: targetTriple,
            additionalFlags: additionalFlags,
            debugSymbols: true,
            verbose: verbose,
            swiftSDKName: swiftSDKName,
            executableTargetName: executableTargetName
        )
    }

    /// Creates a configuration with verbose output enabled
    func withVerbose(_ enabled: Bool = true) -> BuildConfig {
        BuildConfig(
            sourceDirectory: sourceDirectory,
            outputDirectory: outputDirectory,
            optimizationLevel: optimizationLevel,
            targetTriple: targetTriple,
            additionalFlags: additionalFlags,
            debugSymbols: debugSymbols,
            verbose: enabled,
            swiftSDKName: swiftSDKName,
            executableTargetName: executableTargetName
        )
    }
}
