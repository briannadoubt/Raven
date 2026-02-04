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

    enum OptimizationLevel: String, Sendable {
        case debug = "debug"
        case release = "release"

        var swiftFlag: String {
            switch self {
            case .debug:
                return "-Onone"
            case .release:
                return "-O"
            }
        }

        var cartonFlag: String {
            switch self {
            case .debug:
                return "--debug"
            case .release:
                return "--release"
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
        verbose: Bool = false
    ) {
        self.sourceDirectory = sourceDirectory
        self.outputDirectory = outputDirectory
        self.optimizationLevel = optimizationLevel
        self.targetTriple = targetTriple
        self.additionalFlags = additionalFlags
        self.debugSymbols = debugSymbols
        self.verbose = verbose
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
            verbose: verbose
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
            verbose: verbose
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
            verbose: enabled
        )
    }
}
