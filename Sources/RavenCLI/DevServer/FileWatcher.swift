import Foundation
#if canImport(Darwin)
import Darwin
#endif

/// Watches a directory for file changes and triggers a callback when Swift files are modified.
/// Uses FSEvents on macOS and polling on other platforms.
actor FileWatcher {
    /// Type alias for the change handler callback
    typealias ChangeHandler = @Sendable () async -> Void

    /// Path to watch for changes
    private let path: String

    /// Handler to call when changes are detected
    private let onChange: ChangeHandler

    /// Debouncer to avoid multiple rapid callbacks
    private let debouncer: ChangeDebouncer

    /// Platform-specific monitoring state
    #if canImport(Darwin)
    private var dispatchSource: DispatchSourceFileSystemObject?
    private var fileDescriptor: Int32?
    #else
    private var pollingTask: Task<Void, Never>?
    private var fileModificationDates: [String: Date] = [:]
    #endif

    /// Whether the watcher is currently running
    private var isRunning = false

    /// Initialize file watcher
    /// - Parameters:
    ///   - path: Directory path to watch for changes
    ///   - onChange: Callback to invoke when changes are detected
    init(path: String, onChange: @escaping ChangeHandler) {
        self.path = path
        self.onChange = onChange
        self.debouncer = ChangeDebouncer(delayMilliseconds: 100) {
            await onChange()
        }
    }

    /// Start monitoring for file changes
    func start() async throws {
        guard !isRunning else { return }

        // Verify the path exists
        let fileManager = FileManager.default
        var isDirectory: ObjCBool = false
        guard fileManager.fileExists(atPath: path, isDirectory: &isDirectory) else {
            throw FileWatcherError.pathNotFound(path)
        }
        guard isDirectory.boolValue else {
            throw FileWatcherError.notADirectory(path)
        }

        #if canImport(Darwin)
        try startMacOSMonitoring()
        #else
        try await startPollingMonitoring()
        #endif

        isRunning = true
    }

    /// Stop monitoring for file changes
    func stop() {
        guard isRunning else { return }

        #if canImport(Darwin)
        stopMacOSMonitoring()
        #else
        stopPollingMonitoring()
        #endif

        Task {
            await debouncer.cancel()
        }

        isRunning = false
    }

    // MARK: - macOS FSEvents Implementation

    #if canImport(Darwin)
    private func startMacOSMonitoring() throws {
        // Open the directory for monitoring
        let fd = open(path, O_EVTONLY)
        guard fd >= 0 else {
            throw FileWatcherError.cannotOpenPath(path)
        }

        fileDescriptor = fd

        // Create dispatch source for file system events
        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fd,
            eventMask: [.write, .extend, .delete, .rename],
            queue: DispatchQueue.global(qos: .utility)
        )

        source.setEventHandler { [weak self] in
            guard let self = self else { return }
            Task {
                await self.handleChange()
            }
        }

        source.setCancelHandler { [fd] in
            close(fd)
        }

        dispatchSource = source
        source.resume()
    }

    private func stopMacOSMonitoring() {
        dispatchSource?.cancel()
        dispatchSource = nil
        fileDescriptor = nil
    }
    #endif

    // MARK: - Linux/Other Polling Implementation

    #if !canImport(Darwin)
    private func startPollingMonitoring() async throws {
        // Initialize modification dates
        fileModificationDates = try await collectFileModificationDates()

        // Start polling task
        pollingTask = Task {
            while !Task.isCancelled {
                // Wait 500ms between checks
                try? await Task.sleep(nanoseconds: 500_000_000)

                guard !Task.isCancelled else { break }

                // Check for changes
                do {
                    let currentDates = try await collectFileModificationDates()
                    if hasChanges(old: fileModificationDates, new: currentDates) {
                        await handleChange()
                        fileModificationDates = currentDates
                    }
                } catch {
                    // Ignore errors during polling
                    continue
                }
            }
        }
    }

    private func stopPollingMonitoring() {
        pollingTask?.cancel()
        pollingTask = nil
        fileModificationDates.removeAll()
    }

    private func collectFileModificationDates() async throws -> [String: Date] {
        // Run file enumeration on a detached task to avoid async context issues
        return try await Task.detached {
            var dates: [String: Date] = [:]
            let fileManager = FileManager.default

            guard let enumerator = fileManager.enumerator(atPath: self.path) else {
                return dates
            }

            // Convert to array to avoid iterator issues in async context
            let files = enumerator.allObjects.compactMap { $0 as? String }
            for file in files {
                // Only track .swift files
                guard file.hasSuffix(".swift") else { continue }

                let fullPath = (self.path as NSString).appendingPathComponent(file)
                if let attributes = try? fileManager.attributesOfItem(atPath: fullPath),
                   let modificationDate = attributes[.modificationDate] as? Date {
                    dates[file] = modificationDate
                }
            }

            return dates
        }.value
    }

    private func hasChanges(old: [String: Date], new: [String: Date]) -> Bool {
        // Check if any files were added or removed
        if old.keys.count != new.keys.count {
            return true
        }

        // Check if any files were modified
        for (file, newDate) in new {
            if let oldDate = old[file], oldDate != newDate {
                return true
            } else if old[file] == nil {
                return true
            }
        }

        return false
    }
    #endif

    // MARK: - Common Change Handling

    private func handleChange() async {
        // Only process changes for .swift files
        guard await hasSwiftFileChanges() else { return }

        // Trigger debounced handler
        await debouncer.trigger()
    }

    private func hasSwiftFileChanges() async -> Bool {
        // On macOS, we check if any Swift files exist in the directory
        // On other platforms, this is already filtered by collectFileModificationDates
        #if canImport(Darwin)
        // Run file enumeration on a detached task to avoid async context issues
        return await Task.detached {
            let fileManager = FileManager.default
            guard let enumerator = fileManager.enumerator(atPath: self.path) else {
                return false
            }

            // Convert to array to avoid iterator issues in async context
            let files = enumerator.allObjects.compactMap { $0 as? String }
            for file in files {
                if file.hasSuffix(".swift") {
                    return true
                }
            }

            return false
        }.value
        #else
        // Polling implementation already filters for .swift files
        return true
        #endif
    }
}

// MARK: - Errors

enum FileWatcherError: Error, CustomStringConvertible {
    case pathNotFound(String)
    case notADirectory(String)
    case cannotOpenPath(String)

    var description: String {
        switch self {
        case .pathNotFound(let path):
            return "Path not found: \(path)"
        case .notADirectory(let path):
            return "Path is not a directory: \(path)"
        case .cannotOpenPath(let path):
            return "Cannot open path for monitoring: \(path)"
        }
    }
}
