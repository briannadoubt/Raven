import ArgumentParser
import Foundation

struct DevCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "dev",
        abstract: "Start a development server with hot reload"
    )

    @Option(name: .shortAndLong, help: "The port to run the dev server on")
    var port: Int = 3000

    @Option(name: .long, help: "The host to bind the dev server to")
    var host: String = "localhost"

    @Option(name: .shortAndLong, help: "The input SwiftUI project directory")
    var input: String?

    @Option(name: .shortAndLong, help: "The output directory for built files")
    var output: String?

    @Flag(name: .long, help: "Enable verbose logging")
    var verbose: Bool = false

    @Option(name: .long, help: "Port for hot reload WebSocket server")
    var hotReloadPort: Int = 35729

    func run() throws {
        print("Starting Raven development server...")

        if verbose {
            print("Host: \(host)")
            print("Port: \(port)")
            print("Hot reload port: \(hotReloadPort)")
        }

        // Run the async dev server
        try runAsync {
            try await self.runDevServer()
        }
    }

    private func runDevServer() async throws {
        let startTime = Date()

        // Resolve paths
        let inputPath = resolveInputPath()
        let outputPath = resolveOutputPath()

        if verbose {
            print("  Input: \(inputPath)")
            print("  Output: \(outputPath)")
        }

        // Step 1: Initial build
        print("\n[1/5] Performing initial build...")
        try await performBuild(inputPath: inputPath, outputPath: outputPath)

        let initialBuildTime = Date().timeIntervalSince(startTime)
        print("  ✓ Initial build complete (\(String(format: "%.2fs", initialBuildTime)))")

        // Step 2: Start HTTP server
        print("[2/5] Starting HTTP server...")
        let httpServer = HTTPServer(
            port: port,
            serveDirectory: outputPath,
            injectHotReload: true,
            hotReloadPort: hotReloadPort
        )
        try await httpServer.start()
        print("  ✓ HTTP server started on http://\(host):\(port)")

        // Step 3: Start hot reload server
        print("[3/5] Starting hot reload server...")
        let hotReloadServer = WebSocketServer(port: hotReloadPort)
        try await hotReloadServer.start()
        print("  ✓ Hot reload server started on port \(hotReloadPort)")

        // Step 4: Start file watcher
        print("[4/5] Starting file watcher...")
        let sourcesPath = (inputPath as NSString).appendingPathComponent("Sources")
        let debouncer = ChangeDebouncer(delayMilliseconds: 300) { [inputPath, outputPath, hotReloadServer] in
            print("\n[File Change Detected] Rebuilding...")
            let rebuildStart = Date()

            do {
                // Send notification that build started
                await hotReloadServer.sendNotification("Building...")

                try await self.performBuild(inputPath: inputPath, outputPath: outputPath, incremental: true)
                let rebuildTime = Date().timeIntervalSince(rebuildStart)
                print("  ✓ Rebuild complete (\(String(format: "%.2fs", rebuildTime)))")

                // Broadcast reload to clients with metrics
                await hotReloadServer.sendReloadWithMetrics(buildTime: rebuildTime, changeDescription: "Source files")
            } catch {
                let errorMessage = error.localizedDescription
                print("  ✗ Build failed: \(errorMessage)")

                // Broadcast error to clients
                await hotReloadServer.sendError(errorMessage)
            }
        }

        let fileWatcher = FileWatcher(path: sourcesPath) {
            await debouncer.trigger()
        }
        try await fileWatcher.start()
        print("  ✓ Watching for changes in \(sourcesPath)")

        // Step 5: Ready
        print("[5/5] Development server ready!")
        print("\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("  🚀 Raven Development Server")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("  Server:      http://\(host):\(port)")
        print("  Hot Reload:  ws://\(host):\(hotReloadPort)")
        print("  Project:     \(inputPath)")
        print("  Output:      \(outputPath)")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("\nPress Ctrl+C to stop the server\n")

        // Keep running until interrupted
        // Set up signal handler for Ctrl+C
        let shutdownFlag = ShutdownFlag()

        signal(SIGINT, SIG_IGN) // Ignore default handler
        let signalSource = DispatchSource.makeSignalSource(signal: SIGINT, queue: .main)
        signalSource.setEventHandler {
            print("\n\nShutting down development server...")
            shutdownFlag.shutdown()
        }
        signalSource.resume()

        // Wait for shutdown signal
        await shutdownFlag.wait()
        signalSource.cancel()

        // Cleanup
        await httpServer.stop()
        await hotReloadServer.stop()
        await fileWatcher.stop()
        await debouncer.cancel()

        print("Server stopped.")
    }

    // MARK: - Build Logic

    private func performBuild(inputPath: String, outputPath: String, incremental: Bool = false) async throws {
        // Validate project structure
        try validateProjectStructure(at: inputPath)

        // Compile Swift to WASM (use incremental compilation for rebuilds)
        let wasmPath = try await compileToWasm(projectPath: inputPath, outputPath: outputPath, isIncremental: incremental)

        // Copy WASM to dist/
        let wasmOutputPath = (outputPath as NSString).appendingPathComponent("app.wasm")
        try copyWasmBinary(from: wasmPath.path, to: wasmOutputPath)

        // Generate index.html (only if it doesn't exist or not incremental)
        let htmlPath = (outputPath as NSString).appendingPathComponent("index.html")
        if !incremental || !FileManager.default.fileExists(atPath: htmlPath) {
            try generateHTML(outputPath: outputPath, projectPath: inputPath)
        }

        // Copy runtime.js (only if it doesn't exist or not incremental)
        let runtimePath = (outputPath as NSString).appendingPathComponent("runtime.js")
        if !incremental || !FileManager.default.fileExists(atPath: runtimePath) {
            try copyRuntimeJS(to: outputPath)
        }

        // Copy assets (only if not incremental)
        if !incremental {
            try bundleAssets(from: inputPath, to: outputPath)
        }
    }

    private func validateProjectStructure(at path: String) throws {
        let fileManager = FileManager.default

        var isDirectory: ObjCBool = false
        guard fileManager.fileExists(atPath: path, isDirectory: &isDirectory),
              isDirectory.boolValue else {
            throw DevError.invalidInput("Input path is not a directory: \(path)")
        }

        let packagePath = (path as NSString).appendingPathComponent("Package.swift")
        guard fileManager.fileExists(atPath: packagePath) else {
            throw DevError.invalidProject("No Package.swift found. Is this a Swift package?")
        }
    }

    private func compileToWasm(projectPath: String, outputPath: String, isIncremental: Bool = false) async throws -> URL {
        let sourceDir = URL(fileURLWithPath: projectPath)
        let outputDir = URL(fileURLWithPath: outputPath)

        let config = BuildConfig(
            sourceDirectory: sourceDir,
            outputDirectory: outputDir,
            optimizationLevel: .debug, // Always use debug for dev mode
            verbose: verbose
        )

        let compiler = WasmCompiler(config: config)
        return try await compiler.compile(isIncremental: isIncremental)
    }

    private func copyWasmBinary(from source: String, to destination: String) throws {
        let fileManager = FileManager.default

        if fileManager.fileExists(atPath: destination) {
            try fileManager.removeItem(atPath: destination)
        }

        try fileManager.copyItem(atPath: source, toPath: destination)

        if source.contains(".temp.wasm") {
            try? fileManager.removeItem(atPath: source)
        }
    }

    private func generateHTML(outputPath: String, projectPath: String) throws {
        let projectName = extractProjectName(from: projectPath)

        let config = HTMLConfig(
            projectName: projectName,
            title: projectName,
            wasmFile: "app.wasm",
            runtimeJSFile: "runtime.js",
            cssFiles: checkForStylesheet(in: projectPath) ? ["styles.css"] : [],
            metaTags: [
                "description": "Built with Raven - SwiftUI to DOM",
                "generator": "Raven 0.1.0 (dev)"
            ],
            isDevelopment: true, // Enable development mode with error overlay
            hotReloadPort: hotReloadPort
        )

        let generator = HTMLGenerator()
        let htmlPath = (outputPath as NSString).appendingPathComponent("index.html")
        try generator.writeToFile(config: config, path: htmlPath)
    }

    private func copyRuntimeJS(to outputPath: String) throws {
        let fileManager = FileManager.default

        let possiblePaths = [
            "Resources/runtime.js",
            "../../../Resources/runtime.js",
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
            throw DevError.resourceNotFound("runtime.js not found. Please ensure Raven is properly installed.")
        }

        let destination = (outputPath as NSString).appendingPathComponent("runtime.js")
        if fileManager.fileExists(atPath: destination) {
            try fileManager.removeItem(atPath: destination)
        }

        try fileManager.copyItem(atPath: source, toPath: destination)
    }

    private func bundleAssets(from inputPath: String, to outputPath: String) throws {
        let publicPath = (inputPath as NSString).appendingPathComponent("Public")
        let bundler = AssetBundler(verbose: verbose)
        _ = try bundler.bundleAssets(from: publicPath, to: outputPath)
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

        try? fileManager.createDirectory(
            atPath: resolvedPath,
            withIntermediateDirectories: true
        )

        return resolvedPath
    }

    private func extractProjectName(from path: String) -> String {
        let pathComponents = (path as NSString).pathComponents
        let lastComponent = pathComponents.last ?? "RavenApp"

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

enum DevError: Error, LocalizedError {
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

// MARK: - Shutdown Flag

/// Thread-safe flag for coordinating shutdown
final class ShutdownFlag: @unchecked Sendable {
    private var shouldShutdown = false
    private let lock = NSLock()

    func shutdown() {
        lock.lock()
        shouldShutdown = true
        lock.unlock()
    }

    func isShutdown() -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return shouldShutdown
    }

    func wait() async {
        while !isShutdown() {
            try? await Task.sleep(nanoseconds: 100_000_000) // 100ms
        }
    }
}
