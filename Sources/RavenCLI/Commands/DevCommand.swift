import ArgumentParser
import Foundation

struct DevCommand: AsyncParsableCommand {
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

    @Flag(name: .long, help: "Enable verbose logging")
    var verbose: Bool = false

    @Option(name: .long, help: "Port for hot reload WebSocket server")
    var hotReloadPort: Int = 35729

    @Option(name: .long, help: "Override the Swift SDK name for WASM compilation")
    var swiftSdk: String?

    @Flag(name: .long, help: "Build in release mode")
    var release: Bool = false

    @Flag(name: .long, inversion: .prefixedNo, help: "Open browser after starting server")
    var open: Bool = false

    func run() async throws {
        print("Starting Raven development server...")

        if verbose {
            print("Host: \(host)")
            print("Port: \(port)")
            print("Hot reload port: \(hotReloadPort)")
        }

        try await runDevServer()
    }

    private func runDevServer() async throws {
        let startTime = Date()

        // Resolve project path
        let projectPath = resolveInputPath()

        // Validate project structure
        try validateProjectStructure(at: projectPath)

        // Detect executable target name from Package.swift
        let targetName = WasmCompiler.detectExecutableTarget(
            in: URL(fileURLWithPath: projectPath)
        )

        if verbose {
            print("  Project: \(projectPath)")
            if let targetName {
                print("  Target: \(targetName)")
            }
        }

        // Resolve the public/ directory (where we serve from)
        let publicPath = resolvePublicDirectory(in: projectPath)
        try ensureDirectoryExists(at: publicPath)

        if verbose {
            print("  Serve directory: \(publicPath)")
        }

        // Determine if we should use generated HTML (no custom index.html in public/)
        let hasCustomHTML = FileManager.default.fileExists(
            atPath: (publicPath as NSString).appendingPathComponent("index.html")
        )

        // Step 1: Initial build
        print("\n[1/5] Performing initial build...")
        try await performBuild(
            projectPath: projectPath,
            publicPath: publicPath,
            targetName: targetName,
            copyWasmToPublic: true
        )

        let initialBuildTime = Date().timeIntervalSince(startTime)
        print("  Build complete (\(String(format: "%.2fs", initialBuildTime)))")

        // Generate HTML if no custom index.html exists
        var generatedHTML: String? = nil
        if !hasCustomHTML {
            // Find JavaScriptKit runtime for inlining
            let jsKitRuntime = WasmCompiler.findJavaScriptKitRuntime(in: projectPath)
            if verbose && jsKitRuntime == nil {
                print("  Warning: JavaScriptKit runtime not found in .build/checkouts/")
                print("  HTML will fall back to loading runtime.js from disk")
            }

            let wasmFileName = targetName.map { "\($0).wasm" } ?? "app.wasm"
            let htmlConfig = HTMLConfig(
                projectName: targetName ?? "RavenApp",
                wasmFile: wasmFileName,
                isDevelopment: true,
                hotReloadPort: hotReloadPort,
                javaScriptKitRuntimeSource: jsKitRuntime
            )

            let generator = HTMLGenerator()
            generatedHTML = generator.generate(config: htmlConfig)
            print("  Generated index.html (all JS inlined)")
        }

        // Step 2: Start HTTP server
        print("[2/5] Starting HTTP server...")
        let httpServer = HTTPServer(
            port: port,
            serveDirectory: publicPath,
            injectHotReload: hasCustomHTML, // Only inject for custom HTML; generated HTML already has it
            hotReloadPort: hotReloadPort,
            generatedHTML: generatedHTML
        )
        try await httpServer.start()
        print("  HTTP server started on http://\(host):\(port)")

        // Step 3: Start hot reload server
        print("[3/5] Starting hot reload server...")
        let hotReloadServer = WebSocketServer(port: hotReloadPort)
        try await hotReloadServer.start()
        print("  Hot reload server started on port \(hotReloadPort)")

        // Step 4: Start file watcher
        print("[4/5] Starting file watcher...")
        let sourcesPath = (projectPath as NSString).appendingPathComponent("Sources")
        let debouncer = ChangeDebouncer(delayMilliseconds: 300) { [projectPath, publicPath, hasCustomHTML, hotReloadServer] in
            print("\n[File Change Detected] Rebuilding...")
            let rebuildStart = Date()

            do {
                await hotReloadServer.sendNotification("Building...")

                try await self.performBuild(
                    projectPath: projectPath,
                    publicPath: publicPath,
                    targetName: targetName,
                    incremental: true,
                    copyWasmToPublic: true
                )
                let rebuildTime = Date().timeIntervalSince(rebuildStart)
                print("  Rebuild complete (\(String(format: "%.2fs", rebuildTime)))")

                await hotReloadServer.sendReloadWithMetrics(buildTime: rebuildTime, changeDescription: "Source files")
            } catch {
                let errorMessage = error.localizedDescription
                print("  Build failed: \(errorMessage)")
                await hotReloadServer.sendError(errorMessage)
            }
        }

        let fileWatcher = FileWatcher(path: sourcesPath) {
            await debouncer.trigger()
        }
        try await fileWatcher.start()
        print("  Watching for changes in \(sourcesPath)")

        // Step 5: Ready
        print("[5/5] Development server ready!")
        let serverURL = "http://\(host):\(port)"
        print("")
        print("  Raven Development Server")
        print("  Server:      \(serverURL)")
        print("  Hot Reload:  ws://\(host):\(hotReloadPort)")
        print("  Project:     \(projectPath)")
        print("")
        print("Press Ctrl+C to stop the server\n")

        // Open browser
        if open {
            openBrowser(url: serverURL)
        }

        // Keep running until interrupted
        let shutdownFlag = ShutdownFlag()

        signal(SIGINT, SIG_IGN)
        let signalSource = DispatchSource.makeSignalSource(signal: SIGINT, queue: .main)
        signalSource.setEventHandler {
            print("\n\nShutting down development server...")
            shutdownFlag.shutdown()
        }
        signalSource.resume()

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

    private func performBuild(
        projectPath: String,
        publicPath: String,
        targetName: String?,
        incremental: Bool = false,
        copyWasmToPublic: Bool = true
    ) async throws {
        // Compile Swift to WASM
        let wasmPath = try await compileToWasm(
            projectPath: projectPath,
            targetName: targetName,
            isIncremental: incremental
        )

        // Copy .wasm to public/ only if needed (custom HTML setup)
        if copyWasmToPublic {
            let wasmFileName = targetName.map { "\($0).wasm" } ?? wasmPath.lastPathComponent
            let wasmDestination = (publicPath as NSString).appendingPathComponent(wasmFileName)
            try copyFile(from: wasmPath.path, to: wasmDestination)
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

    private func compileToWasm(
        projectPath: String,
        targetName: String?,
        isIncremental: Bool = false
    ) async throws -> URL {
        let sourceDir = URL(fileURLWithPath: projectPath)

        let config = BuildConfig(
            sourceDirectory: sourceDir,
            outputDirectory: sourceDir, // not used for swift SDK builds
            optimizationLevel: release ? .release : .debug,
            verbose: verbose,
            swiftSDKName: swiftSdk,
            executableTargetName: targetName
        )

        let compiler = WasmCompiler(config: config)
        return try await compiler.compile(isIncremental: isIncremental)
    }

    private func copyFile(from source: String, to destination: String) throws {
        let fileManager = FileManager.default

        if fileManager.fileExists(atPath: destination) {
            try fileManager.removeItem(atPath: destination)
        }

        try fileManager.copyItem(atPath: source, toPath: destination)
    }

    private func ensureDirectoryExists(at path: String) throws {
        let fileManager = FileManager.default
        var isDirectory: ObjCBool = false
        if fileManager.fileExists(atPath: path, isDirectory: &isDirectory) {
            if isDirectory.boolValue {
                return
            }
            throw DevError.invalidProject("Expected directory but found file at: \(path)")
        }
        try fileManager.createDirectory(atPath: path, withIntermediateDirectories: true)
    }

    // MARK: - Helpers

    private func resolveInputPath() -> String {
        if let input, input.hasPrefix("/") {
            return input
        } else if let input {
            return (FileManager.default.currentDirectoryPath as NSString)
                .appendingPathComponent(input)
        } else {
            return FileManager.default.currentDirectoryPath
        }
    }

    /// Finds the public/ directory in the project (checks lowercase then uppercase)
    private func resolvePublicDirectory(in projectPath: String) -> String {
        let fileManager = FileManager.default

        // Check lowercase first (preferred convention)
        let lowercasePath = (projectPath as NSString).appendingPathComponent("public")
        if fileManager.fileExists(atPath: lowercasePath) {
            return lowercasePath
        }

        // Check uppercase
        let uppercasePath = (projectPath as NSString).appendingPathComponent("Public")
        if fileManager.fileExists(atPath: uppercasePath) {
            return uppercasePath
        }

        // Default to lowercase (will be created if needed, or HTTP server will 404)
        return lowercasePath
    }

    private func openBrowser(url: String) {
        #if os(macOS)
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        process.arguments = [url]
        try? process.run()
        #elseif os(Linux)
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/xdg-open")
        process.arguments = [url]
        try? process.run()
        #endif
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
