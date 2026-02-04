import Foundation

/// Handles copying static assets from Public/ to the distribution directory
struct AssetBundler: Sendable {
    struct BundleResult: Sendable {
        let filesCopied: Int
        let totalBytes: Int64
        let errors: [Error]
    }

    enum BundleError: Error, LocalizedError {
        case sourceNotFound(String)
        case destinationNotAccessible(String)
        case copyFailed(source: String, destination: String, error: Error)

        var errorDescription: String? {
            switch self {
            case .sourceNotFound(let path):
                return "Source directory not found: \(path)"
            case .destinationNotAccessible(let path):
                return "Cannot access destination directory: \(path)"
            case .copyFailed(let source, let destination, let error):
                return "Failed to copy \(source) to \(destination): \(error.localizedDescription)"
            }
        }
    }

    private let verbose: Bool

    init(verbose: Bool = false) {
        self.verbose = verbose
    }

    /// Copies all assets from the Public/ directory to the distribution directory
    /// - Parameters:
    ///   - publicPath: Path to the Public/ directory
    ///   - distPath: Path to the distribution directory
    /// - Returns: BundleResult containing statistics about the operation
    func bundleAssets(from publicPath: String, to distPath: String) throws -> BundleResult {
        let fileManager = FileManager.default

        // Check if source exists
        var isDirectory: ObjCBool = false
        guard fileManager.fileExists(atPath: publicPath, isDirectory: &isDirectory),
              isDirectory.boolValue else {
            // Not an error - just no assets to copy
            if verbose {
                print("  ℹ No Public/ directory found at \(publicPath)")
            }
            return BundleResult(filesCopied: 0, totalBytes: 0, errors: [])
        }

        // Ensure destination exists
        if !fileManager.fileExists(atPath: distPath) {
            try fileManager.createDirectory(
                atPath: distPath,
                withIntermediateDirectories: true
            )
        }

        // Copy files recursively
        var filesCopied = 0
        var totalBytes: Int64 = 0
        var errors: [Error] = []

        try copyDirectory(
            from: publicPath,
            to: distPath,
            fileManager: fileManager,
            filesCopied: &filesCopied,
            totalBytes: &totalBytes,
            errors: &errors
        )

        if verbose && filesCopied > 0 {
            print("  ✓ Copied \(filesCopied) asset(s) (\(formatBytes(totalBytes)))")
        }

        return BundleResult(
            filesCopied: filesCopied,
            totalBytes: totalBytes,
            errors: errors
        )
    }

    /// Recursively copies a directory and its contents
    private func copyDirectory(
        from sourcePath: String,
        to destPath: String,
        fileManager: FileManager,
        filesCopied: inout Int,
        totalBytes: inout Int64,
        errors: inout [Error]
    ) throws {
        let contents = try fileManager.contentsOfDirectory(atPath: sourcePath)

        for item in contents {
            // Skip hidden files
            if item.hasPrefix(".") {
                if verbose {
                    print("  ⊘ Skipping hidden file: \(item)")
                }
                continue
            }

            let sourceItemPath = (sourcePath as NSString).appendingPathComponent(item)
            let destItemPath = (destPath as NSString).appendingPathComponent(item)

            var isDirectory: ObjCBool = false
            guard fileManager.fileExists(atPath: sourceItemPath, isDirectory: &isDirectory) else {
                continue
            }

            if isDirectory.boolValue {
                // Create destination directory
                try? fileManager.createDirectory(
                    atPath: destItemPath,
                    withIntermediateDirectories: true
                )

                // Recursively copy subdirectory
                try copyDirectory(
                    from: sourceItemPath,
                    to: destItemPath,
                    fileManager: fileManager,
                    filesCopied: &filesCopied,
                    totalBytes: &totalBytes,
                    errors: &errors
                )
            } else {
                // Copy file
                do {
                    // Remove existing file if present
                    if fileManager.fileExists(atPath: destItemPath) {
                        try fileManager.removeItem(atPath: destItemPath)
                    }

                    try fileManager.copyItem(atPath: sourceItemPath, toPath: destItemPath)

                    // Track file size
                    if let attributes = try? fileManager.attributesOfItem(atPath: destItemPath),
                       let size = attributes[.size] as? Int64 {
                        totalBytes += size
                    }

                    filesCopied += 1

                    if verbose {
                        if let size = try? fileManager.attributesOfItem(atPath: destItemPath)[.size] as? Int64 {
                            print("  → \(item) (\(formatBytes(size)))")
                        } else {
                            print("  → \(item)")
                        }
                    }
                } catch {
                    let bundleError = BundleError.copyFailed(
                        source: sourceItemPath,
                        destination: destItemPath,
                        error: error
                    )
                    errors.append(bundleError)

                    if verbose {
                        print("  ⚠ Failed to copy \(item): \(error.localizedDescription)")
                    }
                }
            }
        }
    }

    /// Formats byte count into human-readable string
    private func formatBytes(_ bytes: Int64) -> String {
        let kb = Double(bytes) / 1024.0
        if kb < 1024 {
            return String(format: "%.1f KB", kb)
        }
        let mb = kb / 1024.0
        return String(format: "%.1f MB", mb)
    }
}
