import Foundation

/// Analyzes and reports on WASM bundle sizes
@available(macOS 13.0, *)
struct BundleSizeAnalyzer: Sendable {
    struct BundleReport: Sendable, CustomStringConvertible {
        let uncompressedSize: Int64
        let brotliSize: Int64?
        let gzipSize: Int64?
        let timestamp: Date

        var compressionRatio: Double? {
            guard let compressed = brotliSize ?? gzipSize else { return nil }
            return Double(compressed) / Double(uncompressedSize)
        }

        var description: String {
            var lines: [String] = []
            lines.append("Bundle Size Report")
            lines.append(String(repeating: "=", count: 50))
            lines.append("")
            lines.append("Uncompressed: \(formatBytes(uncompressedSize))")

            if let brotli = brotliSize {
                let ratio = Double(brotli) / Double(uncompressedSize) * 100.0
                lines.append("Brotli:       \(formatBytes(brotli)) (\(String(format: "%.1f%%", ratio)))")
            }

            if let gzip = gzipSize {
                let ratio = Double(gzip) / Double(uncompressedSize) * 100.0
                lines.append("Gzip:         \(formatBytes(gzip)) (\(String(format: "%.1f%%", ratio)))")
            }

            lines.append("")
            lines.append(sizeAssessment())

            return lines.joined(separator: "\n")
        }

        func sizeAssessment() -> String {
            let targetSize: Int64 = 500_000  // 500KB target

            if uncompressedSize <= targetSize {
                let underBy = targetSize - uncompressedSize
                return "✓ Target met! Under by \(formatBytes(underBy))"
            } else {
                let overBy = uncompressedSize - targetSize
                return "⚠ Over target by \(formatBytes(overBy))"
            }
        }

        private func formatBytes(_ bytes: Int64) -> String {
            let kb = Double(bytes) / 1024.0
            if kb < 1024 {
                return String(format: "%.1f KB", kb)
            }
            let mb = kb / 1024.0
            return String(format: "%.2f MB", mb)
        }
    }

    enum AnalyzerError: Error, LocalizedError {
        case fileNotFound(String)
        case compressionFailed(String)

        var errorDescription: String? {
            switch self {
            case .fileNotFound(let path):
                return "File not found: \(path)"
            case .compressionFailed(let message):
                return "Compression failed: \(message)"
            }
        }
    }

    private let verbose: Bool

    init(verbose: Bool = false) {
        self.verbose = verbose
    }

    /// Analyzes a WASM bundle and generates a comprehensive report
    func analyze(wasmPath: String) async throws -> BundleReport {
        let fileManager = FileManager.default

        guard fileManager.fileExists(atPath: wasmPath) else {
            throw AnalyzerError.fileNotFound(wasmPath)
        }

        // Get uncompressed size
        guard let attributes = try? fileManager.attributesOfItem(atPath: wasmPath),
              let size = attributes[.size] as? Int64 else {
            throw AnalyzerError.fileNotFound(wasmPath)
        }

        if verbose {
            print("Analyzing bundle: \(wasmPath)")
            print("Uncompressed size: \(formatBytes(size))")
        }

        // Try to compress and measure sizes
        let brotliSize = await compressWithBrotli(wasmPath: wasmPath)
        let gzipSize = await compressWithGzip(wasmPath: wasmPath)

        return BundleReport(
            uncompressedSize: size,
            brotliSize: brotliSize,
            gzipSize: gzipSize,
            timestamp: Date()
        )
    }

    /// Generates a detailed JSON report for CI/CD integration
    func generateJSONReport(wasmPath: String) async throws -> String {
        let report = try await analyze(wasmPath: wasmPath)

        var json: [String: Any] = [
            "timestamp": ISO8601DateFormatter().string(from: report.timestamp),
            "uncompressed_bytes": report.uncompressedSize,
            "uncompressed_kb": Double(report.uncompressedSize) / 1024.0,
            "target_kb": 500.0,
            "meets_target": report.uncompressedSize <= 500_000
        ]

        if let brotli = report.brotliSize {
            json["brotli_bytes"] = brotli
            json["brotli_kb"] = Double(brotli) / 1024.0
            json["brotli_ratio"] = Double(brotli) / Double(report.uncompressedSize)
        }

        if let gzip = report.gzipSize {
            json["gzip_bytes"] = gzip
            json["gzip_kb"] = Double(gzip) / 1024.0
            json["gzip_ratio"] = Double(gzip) / Double(report.uncompressedSize)
        }

        let jsonData = try JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)
        return String(data: jsonData, encoding: .utf8) ?? "{}"
    }

    /// Compares current bundle size against a previous baseline
    func compareWithBaseline(
        currentPath: String,
        baselinePath: String
    ) async throws -> String {
        let current = try await analyze(wasmPath: currentPath)
        let baseline = try await analyze(wasmPath: baselinePath)

        let diff = current.uncompressedSize - baseline.uncompressedSize
        let percentChange = (Double(diff) / Double(baseline.uncompressedSize)) * 100.0

        var report = """
        Bundle Size Comparison
        ======================

        Baseline:  \(formatBytes(baseline.uncompressedSize))
        Current:   \(formatBytes(current.uncompressedSize))
        Change:    \(diff >= 0 ? "+" : "")\(formatBytes(diff)) (\(String(format: "%+.1f%%", percentChange)))

        """

        if diff > 0 {
            report += "⚠ Bundle size increased\n"
        } else if diff < 0 {
            report += "✓ Bundle size decreased\n"
        } else {
            report += "→ No change\n"
        }

        return report
    }

    // MARK: - Private Helpers

    private func compressWithBrotli(wasmPath: String) async -> Int64? {
        guard await isToolAvailable("brotli") else {
            if verbose {
                print("  Brotli not available")
            }
            return nil
        }

        let tempPath = wasmPath + ".br.tmp"
        defer { try? FileManager.default.removeItem(atPath: tempPath) }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = ["brotli", "-f", "-q", "11", "-o", tempPath, wasmPath]
        process.standardOutput = Pipe()
        process.standardError = Pipe()

        do {
            try process.run()
            process.waitUntilExit()

            guard process.terminationStatus == 0 else {
                if verbose {
                    print("  Brotli compression failed")
                }
                return nil
            }

            guard let attributes = try? FileManager.default.attributesOfItem(atPath: tempPath),
                  let size = attributes[.size] as? Int64 else {
                return nil
            }

            if verbose {
                print("  Brotli compressed: \(formatBytes(size))")
            }

            return size
        } catch {
            if verbose {
                print("  Brotli error: \(error.localizedDescription)")
            }
            return nil
        }
    }

    private func compressWithGzip(wasmPath: String) async -> Int64? {
        guard await isToolAvailable("gzip") else {
            if verbose {
                print("  Gzip not available")
            }
            return nil
        }

        let tempPath = wasmPath + ".gz.tmp"
        defer { try? FileManager.default.removeItem(atPath: tempPath) }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = ["gzip", "-c", "-9", wasmPath]

        let outputPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = Pipe()

        do {
            try process.run()

            let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
            process.waitUntilExit()

            guard process.terminationStatus == 0 else {
                if verbose {
                    print("  Gzip compression failed")
                }
                return nil
            }

            try outputData.write(to: URL(fileURLWithPath: tempPath))

            guard let attributes = try? FileManager.default.attributesOfItem(atPath: tempPath),
                  let size = attributes[.size] as? Int64 else {
                return nil
            }

            if verbose {
                print("  Gzip compressed: \(formatBytes(size))")
            }

            return size
        } catch {
            if verbose {
                print("  Gzip error: \(error.localizedDescription)")
            }
            return nil
        }
    }

    private func isToolAvailable(_ tool: String) async -> Bool {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = ["which", tool]
        process.standardOutput = Pipe()
        process.standardError = Pipe()

        do {
            try process.run()
            process.waitUntilExit()
            return process.terminationStatus == 0
        } catch {
            return false
        }
    }

    private func formatBytes(_ bytes: Int64) -> String {
        let kb = Double(bytes) / 1024.0
        if kb < 1024 {
            return String(format: "%.1f KB", kb)
        }
        let mb = kb / 1024.0
        return String(format: "%.2f MB", mb)
    }
}
