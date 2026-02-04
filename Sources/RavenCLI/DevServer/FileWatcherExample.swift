import Foundation

/// Example usage of FileWatcher for monitoring Swift source files
///
/// This example demonstrates how to use FileWatcher to monitor a directory
/// for changes to Swift files and trigger a rebuild when changes are detected.
///
/// Example usage:
/// ```swift
/// let watcher = FileWatcher(path: "/path/to/Sources") {
///     print("Swift files changed, triggering rebuild...")
///     // Trigger rebuild logic here
/// }
///
/// try await watcher.start()
///
/// // Keep running until interrupted
/// try await Task.sleep(for: .seconds(3600))
///
/// watcher.stop()
/// ```
///
/// Platform-specific behavior:
/// - macOS: Uses efficient FSEvents API for real-time monitoring
/// - Linux/Other: Uses polling every 500ms to check for modifications
///
/// Features:
/// - Recursive directory monitoring
/// - Filters for .swift files only
/// - 100ms debouncing to avoid multiple rapid callbacks
/// - Automatic cleanup on stop()
struct FileWatcherExample {
    static func runExample() async throws {
        print("Starting FileWatcher example...")

        // Create a FileWatcher for the current directory
        let currentPath = FileManager.default.currentDirectoryPath
        let sourcesPath = (currentPath as NSString).appendingPathComponent("Sources")

        let watcher = FileWatcher(path: sourcesPath) {
            print("[\(Date())] Swift files changed in \(sourcesPath)")
        }

        print("Watching directory: \(sourcesPath)")
        print("Monitoring for .swift file changes...")
        print("Press Ctrl+C to stop")

        try await watcher.start()

        // Run indefinitely (or until cancelled)
        while true {
            try await Task.sleep(for: .seconds(1))
        }
    }
}
