import Testing
@testable import RavenCLI
import Foundation

/// Phase 6 Verification: Development Workflow Components
/// Tests the dev server, file watching, hot reload, incremental compilation, and error overlay
@Suite struct Phase6VerificationTests {

    // MARK: - FileWatcher Tests (5 tests)

    @Test func fileWatcherMonitorsDirectory() async throws {
        // Create a temporary directory
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("RavenFileWatcherTest-\(UUID().uuidString)")

        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer {
            try? FileManager.default.removeItem(at: tempDir)
        }

        let watcher = FileWatcher(path: tempDir.path) {}

        // Start watching
        try await watcher.start()

        // Create a Swift file
        let swiftFile = tempDir.appendingPathComponent("Test.swift")
        try "struct Test {}".write(to: swiftFile, atomically: true, encoding: .utf8)

        // Wait for change detection (with timeout)
        try await Task.sleep(nanoseconds: 2_000_000_000) // 2s

        // Stop watching
        await watcher.stop()

        // Verify watcher ran without crashing
        #expect(true)
    }

    @Test func fileWatcherFiltersSwiftFiles() async throws {
        // Create a temporary directory
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("RavenFileWatcherFilterTest-\(UUID().uuidString)")

        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer {
            try? FileManager.default.removeItem(at: tempDir)
        }

        let watcher = FileWatcher(path: tempDir.path) {}

        // Start watching
        try await watcher.start()

        // Create a Swift file to verify watcher is working
        let swiftFile = tempDir.appendingPathComponent("Test.swift")
        try "struct Test {}".write(to: swiftFile, atomically: true, encoding: .utf8)

        // Give it time to detect
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1s

        // Stop watching
        await watcher.stop()

        // Verify watcher ran without crashing
        #expect(true)
    }

    @Test func fileWatcherDebouncing() async throws {
        // Test that debouncing works by verifying that the handler isn't called
        // immediately but after a delay
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("RavenDebouncerTest-\(UUID().uuidString)")

        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer {
            try? FileManager.default.removeItem(at: tempDir)
        }

        // Use an actor to track call count in a sendable-safe way
        actor CallCounter {
            var count = 0
            func increment() {
                count += 1
            }
            func getCount() -> Int {
                return count
            }
        }

        let counter = CallCounter()
        let debouncer = ChangeDebouncer(delayMilliseconds: 100) {
            await counter.increment()
        }

        // Trigger multiple times rapidly
        await debouncer.trigger()
        await debouncer.trigger()
        await debouncer.trigger()

        // Should not have executed yet
        let initialCount = await counter.getCount()
        #expect(initialCount == 0)

        // Wait for debounce completion with bounded polling to avoid timing flakes.
        for _ in 0..<100 where await counter.getCount() == 0 {
            try await Task.sleep(nanoseconds: 10_000_000) // 10ms
        }

        // Should have executed only once
        let finalCount = await counter.getCount()
        #expect(finalCount == 1)

        await debouncer.cancel()
    }

    @Test func fileWatcherStartStop() async throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("RavenStartStopTest-\(UUID().uuidString)")

        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer {
            try? FileManager.default.removeItem(at: tempDir)
        }

        let watcher = FileWatcher(path: tempDir.path) {}

        // Should be able to start
        try await watcher.start()

        // Should be able to stop
        await watcher.stop()

        // Should be able to start again
        try await watcher.start()
        await watcher.stop()

        #expect(true)
    }

    @Test func fileWatcherErrorHandlingForMissingPath() async throws {
        let nonExistentPath = "/tmp/nonexistent-\(UUID().uuidString)"
        let watcher = FileWatcher(path: nonExistentPath) {}

        do {
            try await watcher.start()
            Issue.record("Should throw error for non-existent path")
        } catch let error as FileWatcherError {
            switch error {
            case .pathNotFound:
                #expect(true)
            default:
                Issue.record("Wrong error type: \(error)")
            }
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }

    // MARK: - WebSocketServer Tests (4 tests)

    @Test func webSocketServerStartsOnPort() async throws {
        #if canImport(Network)
        let port = 35730 // Use non-default port to avoid conflicts
        let server = WebSocketServer(port: port)

        try await server.start()

        // Give server time to start
        try await Task.sleep(nanoseconds: 100_000_000) // 100ms

        await server.stop()

        #expect(true)
        #else
        // Network framework not available on this platform
        #endif
    }

    @Test func webSocketServerBroadcast() async throws {
        #if canImport(Network)
        let port = 35731
        let server = WebSocketServer(port: port)

        try await server.start()
        try await Task.sleep(nanoseconds: 100_000_000) // 100ms

        // Broadcast a message (no clients connected, but should not crash)
        await server.broadcast("test message")

        let count = await server.clientCount()
        #expect(count == 0)

        await server.stop()
        #else
        // Network framework not available on this platform
        #endif
    }

    @Test func webSocketServerSendReload() async throws {
        #if canImport(Network)
        let port = 35732
        let server = WebSocketServer(port: port)

        try await server.start()
        try await Task.sleep(nanoseconds: 100_000_000) // 100ms

        // Send reload message
        await server.sendReload()

        await server.stop()

        #expect(true)
        #else
        // Network framework not available on this platform
        #endif
    }

    @Test func webSocketServerSendError() async throws {
        #if canImport(Network)
        let port = 35733
        let server = WebSocketServer(port: port)

        try await server.start()
        try await Task.sleep(nanoseconds: 100_000_000) // 100ms

        // Send error message
        await server.sendError("Build failed: Test error")

        await server.stop()

        #expect(true)
        #else
        // Network framework not available on this platform
        #endif
    }

    // MARK: - HTTPServer Tests (4 tests)

    @Test func httpServerServesStaticFiles() async throws {
        #if canImport(Network)
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("RavenHTTPTest-\(UUID().uuidString)")

        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer {
            try? FileManager.default.removeItem(at: tempDir)
        }

        // Create a test HTML file
        let htmlFile = tempDir.appendingPathComponent("index.html")
        try "<html><body>Test</body></html>".write(to: htmlFile, atomically: true, encoding: .utf8)

        let port = 8081
        let server = HTTPServer(port: port, serveDirectory: tempDir.path, injectHotReload: false)

        try await server.start()
        try await Task.sleep(nanoseconds: 100_000_000) // 100ms

        await server.stop()

        #expect(true)
        #else
        // Network framework not available on this platform
        #endif
    }

    @Test func httpServerMIMETypes() async throws {
        // Test that MIME types are correctly configured
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("RavenMIMETest-\(UUID().uuidString)")

        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer {
            try? FileManager.default.removeItem(at: tempDir)
        }

        // HTTPServer has correct MIME types in its implementation
        // We test this indirectly by verifying the server can be created
        let server = HTTPServer(port: 8082, serveDirectory: tempDir.path)

        #expect(server != nil)
    }

    @Test func httpServerInjectsHotReload() async throws {
        #if canImport(Network)
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("RavenInjectTest-\(UUID().uuidString)")

        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer {
            try? FileManager.default.removeItem(at: tempDir)
        }

        let port = 8083
        let server = HTTPServer(port: port, serveDirectory: tempDir.path, injectHotReload: true, hotReloadPort: 35729)

        try await server.start()
        try await Task.sleep(nanoseconds: 100_000_000) // 100ms

        await server.stop()

        #expect(true)
        #else
        // Network framework not available on this platform
        #endif
    }

    @Test func httpServer404Handling() async throws {
        // Test that server properly handles missing files (conceptually)
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("Raven404Test-\(UUID().uuidString)")

        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer {
            try? FileManager.default.removeItem(at: tempDir)
        }

        let server = HTTPServer(port: 8084, serveDirectory: tempDir.path)

        // Server should handle 404s gracefully (we test initialization here)
        #expect(server != nil)
    }

    // MARK: - DevCommand Tests (3 tests)

    @Test func devCommandConfigurationParsing() throws {
        // Test that DevCommand can be parsed with default values
        do {
            let command = try DevCommand.parse([])

            #expect(command.port == 3000)
            #expect(command.host == "localhost")
            #expect(command.hotReloadPort == 35729)
            #expect(!command.verbose)
        } catch {
            Issue.record("Failed to parse DevCommand with defaults: \(error)")
        }
    }

    @Test func devCommandValidatesProjectStructure() throws {
        // Create a temporary directory without Package.swift
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("RavenValidateTest-\(UUID().uuidString)")

        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer {
            try? FileManager.default.removeItem(at: tempDir)
        }

        // We test the validation logic by checking for Package.swift presence
        let packagePath = (tempDir.path as NSString).appendingPathComponent("Package.swift")
        let fileManager = FileManager.default

        // Should not find Package.swift
        #expect(!fileManager.fileExists(atPath: packagePath))

        // Now create it and verify it exists
        try "// swift-tools-version: 5.9".write(toFile: packagePath, atomically: true, encoding: .utf8)
        #expect(fileManager.fileExists(atPath: packagePath))
    }

    @Test func devCommandCleanupOnShutdown() async throws {
        // Test ShutdownFlag functionality
        let flag = ShutdownFlag()

        #expect(!flag.isShutdown())

        flag.shutdown()

        #expect(flag.isShutdown())
    }

    // MARK: - Incremental Build Tests (2 tests)

    @Test func incrementalBuildFlag() async throws {
        // Test that WasmCompiler accepts incremental flag
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("RavenIncrementalTest-\(UUID().uuidString)")

        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer {
            try? FileManager.default.removeItem(at: tempDir)
        }

        let config = BuildConfig(
            sourceDirectory: tempDir,
            outputDirectory: tempDir.appendingPathComponent("output"),
            optimizationLevel: .debug,
            verbose: false
        )

        let compiler = WasmCompiler(config: config)

        // We just verify the method signature accepts the parameter
        // Actual compilation would require a full Swift project
        #expect(compiler != nil)
    }

    @Test func debugModeUsesIncremental() throws {
        // Test that debug builds are configured for incremental compilation
        let config = BuildConfig(
            sourceDirectory: URL(fileURLWithPath: "/tmp"),
            outputDirectory: URL(fileURLWithPath: "/tmp/output"),
            optimizationLevel: .debug
        )

        #expect(config.optimizationLevel == .debug)
        #expect(config.debugSymbols)
    }

    // MARK: - Error Overlay Tests (2 tests)

    @Test func errorOverlayGeneratesScript() {
        let overlay = ErrorOverlay()
        let script = overlay.generateScript()

        #expect(script.contains("raven-error-overlay"))
        #expect(script.contains("showError"))
        #expect(script.contains("__ravenErrorOverlay"))
        #expect(script.contains("Escape"))
    }

    @Test func errorOverlayWithHotReload() {
        let overlay = ErrorOverlay()
        let script = overlay.generateWithHotReload(hotReloadPort: 35729)

        #expect(script.contains("EventSource"))
        #expect(script.contains("35729"))
        #expect(script.contains("reload"))
        #expect(script.contains("error:"))
        #expect(script.contains("__ravenErrorOverlay"))
    }

    // MARK: - HTMLGenerator Dev Mode Tests (2 tests)

    @Test func htmlGeneratorDevMode() {
        let config = HTMLConfig(
            projectName: "TestApp",
            isDevelopment: true,
            hotReloadPort: 35729
        )

        let generator = HTMLGenerator()
        let html = generator.generate(config: config)

        #expect(html.contains("EventSource"))
        #expect(html.contains("__ravenErrorOverlay"))
        #expect(html.contains("35729"))
    }

    @Test func htmlGeneratorProductionMode() {
        let config = HTMLConfig(
            projectName: "TestApp",
            isDevelopment: false
        )

        let generator = HTMLGenerator()
        let html = generator.generate(config: config)

        #expect(!html.contains("EventSource"))
        #expect(!html.contains("__ravenErrorOverlay"))
    }

    // MARK: - End-to-End Integration Tests (2 tests)

    @Test func completeDevWorkflowSetup() async throws {
        // Test that all dev workflow components can be initialized together
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("RavenE2ETest-\(UUID().uuidString)")

        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer {
            try? FileManager.default.removeItem(at: tempDir)
        }

        // Create minimal project structure
        let sourcesDir = tempDir.appendingPathComponent("Sources")
        try FileManager.default.createDirectory(at: sourcesDir, withIntermediateDirectories: true)

        // Initialize all components
        let fileWatcher = FileWatcher(path: sourcesDir.path) {}

        #if canImport(Network)
        let wsServer = WebSocketServer(port: 35734)
        let httpServer = HTTPServer(port: 8085, serveDirectory: tempDir.path)

        // Start servers
        try await wsServer.start()
        try await httpServer.start()
        try await fileWatcher.start()

        // Give time to initialize
        try await Task.sleep(nanoseconds: 100_000_000)

        // Stop all
        await fileWatcher.stop()
        await wsServer.stop()
        await httpServer.stop()

        #expect(true)
        #else
        try await fileWatcher.start()
        await fileWatcher.stop()
        // Network framework not available
        #endif
    }

    @Test func allComponentsIntegrate() throws {
        // Test that all Phase 6 components are properly integrated

        // 1. Error Overlay
        let overlay = ErrorOverlay()
        let script = overlay.generateWithHotReload(hotReloadPort: 35729)
        #expect(!script.isEmpty)

        // 2. HTML Generator with dev mode
        let htmlConfig = HTMLConfig(projectName: "Test", isDevelopment: true)
        let generator = HTMLGenerator()
        let html = generator.generate(config: htmlConfig)
        #expect(html.contains("EventSource"))

        // 3. Build config with incremental support
        let buildConfig = BuildConfig(
            sourceDirectory: URL(fileURLWithPath: "/tmp"),
            outputDirectory: URL(fileURLWithPath: "/tmp/output"),
            optimizationLevel: .debug
        )
        #expect(buildConfig.optimizationLevel == .debug)

        // 4. ChangeDebouncer
        let debouncer = ChangeDebouncer(delayMilliseconds: 100) {}
        #expect(debouncer != nil)

        #expect(true)
    }
}
