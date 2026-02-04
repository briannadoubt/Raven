import ArgumentParser
import Foundation

struct BuildCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "build",
        abstract: "Build a Raven project for production"
    )

    @Option(name: .shortAndLong, help: "The input SwiftUI project directory")
    var input: String?

    @Option(name: .shortAndLong, help: "The output directory for built files")
    var output: String?

    @Flag(name: .long, help: "Enable verbose logging")
    var verbose: Bool = false

    @Flag(name: .long, help: "Build in debug mode (default is release)")
    var debug: Bool = false

    @Flag(name: .long, help: "Optimize WASM binary with wasm-opt (requires binaryen)")
    var optimize: Bool = false

    func run() throws {
        let startTime = Date()

        // Resolve paths
        let inputPath = resolveInputPath()
        let outputPath = resolveOutputPath()

        print("Building Raven project...")
        if verbose {
            print("  Input: \(inputPath)")
            print("  Output: \(outputPath)")
            print("  Configuration: \(debug ? "debug" : "release")")
        }

        // Determine number of steps
        let totalSteps = optimize ? 8 : 7

        // Step 1: Validate project structure
        print("\n[1/\(totalSteps)] Validating project structure...")
        try validateProjectStructure(at: inputPath)

        // Step 2: Compile Swift to WASM
        print("[2/\(totalSteps)] Compiling Swift to WASM...")
        let wasmPath = try compileToWasm(projectPath: inputPath, outputPath: outputPath)

        // Step 3: Copy WASM to dist/
        print("[3/\(totalSteps)] Copying WASM binary...")
        let wasmOutputPath = (outputPath as NSString).appendingPathComponent("app.wasm")
        try copyWasmBinary(from: wasmPath.path, to: wasmOutputPath)

        // Step 4: Optimize WASM (if requested)
        if optimize {
            print("[4/\(totalSteps)] Optimizing WASM binary...")
            try optimizeWasm(at: wasmOutputPath)
        }

        // Step 5: Generate index.html
        print("[\(optimize ? 5 : 4)/\(totalSteps)] Generating index.html...")
        try generateHTML(outputPath: outputPath, projectPath: inputPath)

        // Step 6: Copy runtime.js to dist/
        print("[\(optimize ? 6 : 5)/\(totalSteps)] Copying runtime.js...")
        try copyRuntimeJS(to: outputPath)

        // Step 7: Copy Public/ assets to dist/
        print("[\(optimize ? 7 : 6)/\(totalSteps)] Copying assets...")
        try bundleAssets(from: inputPath, to: outputPath)

        // Step 8: Show success message
        print("[\(totalSteps)/\(totalSteps)] Finalizing build...")

        let duration = Date().timeIntervalSince(startTime)

        // Get WASM file size
        let wasmSize = try? FileManager.default.attributesOfItem(atPath: wasmOutputPath)[.size] as? Int64
        printSuccessSummary(
            outputPath: outputPath,
            wasmSize: wasmSize ?? 0,
            duration: duration
        )
    }

    // MARK: - Build Steps

    private func validateProjectStructure(at path: String) throws {
        let fileManager = FileManager.default

        // Check if directory exists
        var isDirectory: ObjCBool = false
        guard fileManager.fileExists(atPath: path, isDirectory: &isDirectory),
              isDirectory.boolValue else {
            throw BuildError.invalidInput("Input path is not a directory: \(path)")
        }

        // Check for Package.swift
        let packagePath = (path as NSString).appendingPathComponent("Package.swift")
        guard fileManager.fileExists(atPath: packagePath) else {
            throw BuildError.invalidProject("No Package.swift found. Is this a Swift package?")
        }

        if verbose {
            print("  ✓ Project structure is valid")
        }
    }

    private func compileToWasm(projectPath: String, outputPath: String) throws -> URL {
        let sourceDir = URL(fileURLWithPath: projectPath)
        let outputDir = URL(fileURLWithPath: outputPath)

        let optimizationLevel: BuildConfig.OptimizationLevel = debug ? .debug : .release
        let config = BuildConfig(
            sourceDirectory: sourceDir,
            outputDirectory: outputDir,
            optimizationLevel: optimizationLevel,
            verbose: verbose
        )

        let compiler = WasmCompiler(config: config)

        // Use a simple blocking call for now (async/await requires more infrastructure)
        let wasmPath = try runAsync {
            try await compiler.compile()
        }

        if verbose {
            let fileSize = try? FileManager.default.attributesOfItem(atPath: wasmPath.path)[.size] as? Int64
            if let size = fileSize {
                print("  ✓ Compilation complete (\(formatBytes(size)))")
            }
        }

        return wasmPath
    }

    private func copyWasmBinary(from source: String, to destination: String) throws {
        let fileManager = FileManager.default

        if fileManager.fileExists(atPath: destination) {
            try fileManager.removeItem(atPath: destination)
        }

        try fileManager.copyItem(atPath: source, toPath: destination)

        // Clean up temp file
        if source.contains(".temp.wasm") {
            try? fileManager.removeItem(atPath: source)
        }

        if verbose {
            print("  ✓ WASM binary copied to \(destination)")
        }
    }

    private func generateHTML(outputPath: String, projectPath: String) throws {
        // Extract project name from path or Package.swift
        let projectName = extractProjectName(from: projectPath)

        let config = HTMLConfig(
            projectName: projectName,
            title: projectName,
            wasmFile: "app.wasm",
            runtimeJSFile: "runtime.js",
            cssFiles: checkForStylesheet(in: projectPath) ? ["styles.css"] : [],
            metaTags: [
                "description": "Built with Raven - SwiftUI to DOM",
                "generator": "Raven 0.1.0"
            ]
        )

        let generator = HTMLGenerator()
        let htmlPath = (outputPath as NSString).appendingPathComponent("index.html")
        try generator.writeToFile(config: config, path: htmlPath)

        if verbose {
            print("  ✓ Generated index.html")
        }
    }

    private func copyRuntimeJS(to outputPath: String) throws {
        let fileManager = FileManager.default

        // Find runtime.js in Resources
        let possiblePaths = [
            // Relative to current directory (development)
            "Resources/runtime.js",
            // Relative to package root
            "../../../Resources/runtime.js",
            // Installed location
            "/usr/local/share/raven/runtime.js"
        ]

        var runtimeSource: String?
        for path in possiblePaths {
            let fullPath = (fileManager.currentDirectoryPath as NSString).appendingPathComponent(path)
            if fileManager.fileExists(atPath: fullPath) {
                runtimeSource = fullPath
                break
            }
        }

        guard let source = runtimeSource else {
            throw BuildError.resourceNotFound("runtime.js not found. Please ensure Raven is properly installed.")
        }

        let destination = (outputPath as NSString).appendingPathComponent("runtime.js")
        if fileManager.fileExists(atPath: destination) {
            try fileManager.removeItem(atPath: destination)
        }

        try fileManager.copyItem(atPath: source, toPath: destination)

        if verbose {
            print("  ✓ Copied runtime.js")
        }
    }

    private func bundleAssets(from inputPath: String, to outputPath: String) throws {
        let publicPath = (inputPath as NSString).appendingPathComponent("Public")
        let bundler = AssetBundler(verbose: verbose)

        let result = try bundler.bundleAssets(from: publicPath, to: outputPath)

        if result.filesCopied == 0 {
            if verbose {
                print("  ℹ No assets to copy")
            }
        } else if !verbose {
            print("  ✓ Copied \(result.filesCopied) asset(s) (\(formatBytes(result.totalBytes)))")
        }

        // Report any errors
        if !result.errors.isEmpty {
            print("  ⚠ \(result.errors.count) error(s) occurred while copying assets")
            if verbose {
                for error in result.errors {
                    print("    - \(error.localizedDescription)")
                }
            }
        }
    }

    private func optimizeWasm(at wasmPath: String) throws {
        let optimizer = WasmOptimizer(verbose: verbose, optimizationLevel: .o3)

        let result = try runAsync {
            try await optimizer.optimize(wasmPath: wasmPath)
        }

        if result.wasOptimized {
            if !verbose {
                print("  ✓ Optimized: \(formatBytes(result.originalSize)) → \(formatBytes(result.optimizedSize))")
                print("    Saved: \(formatBytes(result.savedBytes)) (\(String(format: "%.1f%%", result.reductionPercentage)))")
            }
        } else {
            print("  ℹ Optimization skipped (wasm-opt not available)")
            print("  ℹ Install with: brew install binaryen")
        }
    }

    // MARK: - Helpers

    private func resolveInputPath() -> String {
        let path = input ?? "."
        let fileManager = FileManager.default

        if path.hasPrefix("/") {
            return path
        } else {
            return (fileManager.currentDirectoryPath as NSString).appendingPathComponent(path)
        }
    }

    private func resolveOutputPath() -> String {
        let path = output ?? "./dist"
        let fileManager = FileManager.default

        let resolvedPath = path.hasPrefix("/")
            ? path
            : (fileManager.currentDirectoryPath as NSString).appendingPathComponent(path)

        // Create output directory if it doesn't exist
        try? fileManager.createDirectory(
            atPath: resolvedPath,
            withIntermediateDirectories: true
        )

        return resolvedPath
    }

    private func extractProjectName(from path: String) -> String {
        // Try to extract from path
        let pathComponents = (path as NSString).pathComponents
        let lastComponent = pathComponents.last ?? "RavenApp"

        // Remove leading dot if present
        if lastComponent.hasPrefix(".") {
            return "RavenApp"
        }

        return lastComponent
    }

    private func checkForStylesheet(in projectPath: String) -> Bool {
        let fileManager = FileManager.default
        let publicPath = (projectPath as NSString).appendingPathComponent("Public")
        let stylesPath = (publicPath as NSString).appendingPathComponent("styles.css")
        return fileManager.fileExists(atPath: stylesPath)
    }

    private func printSuccessSummary(outputPath: String, wasmSize: Int64, duration: TimeInterval) {
        print("\n✓ Build complete!")
        print("\nOutput files:")
        print("  \(outputPath)/")
        print("  ├── index.html")
        print("  ├── app.wasm (\(formatBytes(wasmSize)))")
        print("  └── runtime.js")

        print("\nBuild time: \(String(format: "%.2fs", duration))")
        print("\nTo serve the app, run:")
        print("  cd \(outputPath) && python3 -m http.server 8000")
    }

    private func formatBytes(_ bytes: Int64) -> String {
        let kb = Double(bytes) / 1024.0
        if kb < 1024 {
            return String(format: "%.1f KB", kb)
        }
        let mb = kb / 1024.0
        return String(format: "%.1f MB", mb)
    }

    private func runAsync<T: Sendable>(_ block: @Sendable @escaping () async throws -> T) throws -> T {
        var result: Result<T, Error>?
        let semaphore = DispatchSemaphore(value: 0)

        Task {
            do {
                let value = try await block()
                result = .success(value)
            } catch {
                result = .failure(error)
            }
            semaphore.signal()
        }

        semaphore.wait()

        switch result {
        case .success(let value):
            return value
        case .failure(let error):
            throw error
        case .none:
            fatalError("Async operation completed without result")
        }
    }
}

// MARK: - Errors

enum BuildError: Error, LocalizedError {
    case invalidInput(String)
    case invalidProject(String)
    case resourceNotFound(String)

    var errorDescription: String? {
        switch self {
        case .invalidInput(let message):
            return "Invalid input: \(message)"
        case .invalidProject(let message):
            return "Invalid project: \(message)"
        case .resourceNotFound(let message):
            return "Resource not found: \(message)"
        }
    }
}
