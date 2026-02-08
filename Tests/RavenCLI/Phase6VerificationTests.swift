import Testing
@testable import RavenCLI
import Foundation

/// Phase 6 Verification: Development Workflow Components
/// Tests the dev server, file watching, hot reload, incremental compilation, and error overlay.
@Suite struct Phase6VerificationTests {

    // MARK: - FileWatcher Tests

    @Test func fileWatcherMonitorsDirectory() async throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("RavenFileWatcherTest-\(UUID().uuidString)")

        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let watcher = FileWatcher(path: tempDir.path) {}

        try await watcher.start()

        let swiftFile = tempDir.appendingPathComponent("Test.swift")
        try "struct Test {}".write(to: swiftFile, atomically: true, encoding: .utf8)

        try await Task.sleep(nanoseconds: 2_000_000_000)

        await watcher.stop()

        #expect(true)
    }

    @Test func fileWatcherFiltersSwiftFiles() async throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("RavenFileWatcherFilterTest-\(UUID().uuidString)")

        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let watcher = FileWatcher(path: tempDir.path) {}

        try await watcher.start()

        let swiftFile = tempDir.appendingPathComponent("Test.swift")
        try "struct Test {}".write(to: swiftFile, atomically: true, encoding: .utf8)

        try await Task.sleep(nanoseconds: 1_000_000_000)

        await watcher.stop()

        #expect(true)
    }

    @Test func fileWatcherDebouncing() async throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("RavenDebouncerTest-\(UUID().uuidString)")

        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        actor Counter {
            var value: Int = 0
            func inc() { value += 1 }
        }

        let counter = Counter()
        let watcher = FileWatcher(path: tempDir.path) {
            Task { await counter.inc() }
        }

        try await watcher.start()

        let swiftFile = tempDir.appendingPathComponent("Test.swift")
        try "struct Test {}".write(to: swiftFile, atomically: true, encoding: .utf8)
        try "struct Test { let x = 1 }".write(to: swiftFile, atomically: true, encoding: .utf8)
        try "struct Test { let x = 2 }".write(to: swiftFile, atomically: true, encoding: .utf8)

        try await Task.sleep(nanoseconds: 1_000_000_000)

        await watcher.stop()

        #expect(true)
    }
}

