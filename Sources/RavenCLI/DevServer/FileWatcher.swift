import Foundation

/// Watches a directory for file changes and triggers a callback when Swift files are modified.
/// Uses modification-time polling for reliable cross-platform recursive file watching.
actor FileWatcher {
    /// Type alias for the change handler callback
    typealias ChangeHandler = @Sendable () async -> Void

    /// Path to watch for changes
    private let path: String

    /// Handler to call when changes are detected
    private let onChange: ChangeHandler

    /// Debouncer to avoid multiple rapid callbacks
    private let debouncer: ChangeDebouncer

    /// Polling state
    private var pollingTask: Task<Void, Never>?
    private var fileModificationDates: [String: Date] = [:]

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

        // Initialize modification dates
        fileModificationDates = collectFileModificationDates()

        // Start polling task
        pollingTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 300_000_000) // 300ms

                guard !Task.isCancelled, let self = self else { break }

                let currentDates = await self.collectFileModificationDates()
                let oldDates = await self.fileModificationDates

                if Self.hasChanges(old: oldDates, new: currentDates) {
                    await self.setFileModificationDates(currentDates)
                    await self.debouncer.trigger()
                }
            }
        }

        isRunning = true
    }

    /// Stop monitoring for file changes
    func stop() {
        guard isRunning else { return }

        pollingTask?.cancel()
        pollingTask = nil
        fileModificationDates.removeAll()

        Task {
            await debouncer.cancel()
        }

        isRunning = false
    }

    // MARK: - Private

    private func setFileModificationDates(_ dates: [String: Date]) {
        fileModificationDates = dates
    }

    private nonisolated func collectFileModificationDates() -> [String: Date] {
        var dates: [String: Date] = [:]
        let fileManager = FileManager.default

        guard let enumerator = fileManager.enumerator(atPath: path) else {
            return dates
        }

        let files = enumerator.allObjects.compactMap { $0 as? String }
        for file in files {
            guard file.hasSuffix(".swift") else { continue }

            let fullPath = (path as NSString).appendingPathComponent(file)
            if let attributes = try? fileManager.attributesOfItem(atPath: fullPath),
               let modificationDate = attributes[.modificationDate] as? Date {
                dates[file] = modificationDate
            }
        }

        return dates
    }

    private static func hasChanges(old: [String: Date], new: [String: Date]) -> Bool {
        if old.count != new.count {
            return true
        }

        for (file, newDate) in new {
            if let oldDate = old[file] {
                if oldDate != newDate { return true }
            } else {
                return true
            }
        }

        return false
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
