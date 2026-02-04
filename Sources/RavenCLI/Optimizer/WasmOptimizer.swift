import Foundation

/// Optimizes WASM binaries for production deployment
@available(macOS 13.0, *)
struct WasmOptimizer: Sendable {
    struct OptimizationResult: Sendable {
        let originalSize: Int64
        let optimizedSize: Int64
        let reductionPercentage: Double
        let toolUsed: String?

        var wasOptimized: Bool {
            toolUsed != nil
        }

        var savedBytes: Int64 {
            originalSize - optimizedSize
        }
    }

    enum OptimizationLevel: String, Sendable {
        case o0 = "-O0"  // No optimization
        case o1 = "-O1"  // Basic optimizations
        case o2 = "-O2"  // More optimizations
        case o3 = "-O3"  // Maximum optimizations
        case oz = "-Oz"  // Optimize for size

        var description: String {
            switch self {
            case .o0: return "No optimization"
            case .o1: return "Basic optimization"
            case .o2: return "Medium optimization"
            case .o3: return "Maximum optimization"
            case .oz: return "Size optimization"
            }
        }
    }

    enum OptimizerError: Error, LocalizedError {
        case wasmFileNotFound(String)
        case optimizationFailed(String)

        var errorDescription: String? {
            switch self {
            case .wasmFileNotFound(let path):
                return "WASM file not found: \(path)"
            case .optimizationFailed(let message):
                return "Optimization failed: \(message)"
            }
        }
    }

    private let verbose: Bool
    private let optimizationLevel: OptimizationLevel

    init(verbose: Bool = false, optimizationLevel: OptimizationLevel = .o3) {
        self.verbose = verbose
        self.optimizationLevel = optimizationLevel
    }

    /// Optimizes a WASM binary file
    /// - Parameter wasmPath: Path to the WASM file to optimize
    /// - Returns: OptimizationResult with before/after statistics
    func optimize(wasmPath: String) async throws -> OptimizationResult {
        let fileManager = FileManager.default

        // Verify file exists
        guard fileManager.fileExists(atPath: wasmPath) else {
            throw OptimizerError.wasmFileNotFound(wasmPath)
        }

        // Get original size
        guard let originalAttributes = try? fileManager.attributesOfItem(atPath: wasmPath),
              let originalSize = originalAttributes[.size] as? Int64 else {
            throw OptimizerError.wasmFileNotFound(wasmPath)
        }

        // Check if wasm-opt is available
        guard await isWasmOptAvailable() else {
            if verbose {
                print("  ℹ wasm-opt not found - skipping optimization")
                print("  ℹ Install with: brew install binaryen")
            }
            return OptimizationResult(
                originalSize: originalSize,
                optimizedSize: originalSize,
                reductionPercentage: 0.0,
                toolUsed: nil
            )
        }

        // Run wasm-opt
        if verbose {
            print("  → Running wasm-opt \(optimizationLevel.rawValue)...")
        }

        let tempPath = wasmPath + ".tmp"
        let success = await runWasmOpt(inputPath: wasmPath, outputPath: tempPath)

        guard success else {
            // Optimization failed - return original
            try? fileManager.removeItem(atPath: tempPath)
            if verbose {
                print("  ⚠ wasm-opt failed - using unoptimized binary")
            }
            return OptimizationResult(
                originalSize: originalSize,
                optimizedSize: originalSize,
                reductionPercentage: 0.0,
                toolUsed: nil
            )
        }

        // Get optimized size
        guard let optimizedAttributes = try? fileManager.attributesOfItem(atPath: tempPath),
              let optimizedSize = optimizedAttributes[.size] as? Int64 else {
            // Can't read optimized file
            try? fileManager.removeItem(atPath: tempPath)
            throw OptimizerError.optimizationFailed("Could not read optimized file")
        }

        // Replace original with optimized version
        try fileManager.removeItem(atPath: wasmPath)
        try fileManager.moveItem(atPath: tempPath, toPath: wasmPath)

        let reduction = originalSize > 0
            ? (Double(originalSize - optimizedSize) / Double(originalSize)) * 100.0
            : 0.0

        if verbose {
            print("  ✓ Optimized: \(formatBytes(originalSize)) → \(formatBytes(optimizedSize))")
            print("    Saved: \(formatBytes(originalSize - optimizedSize)) (\(String(format: "%.1f%%", reduction)))")
        }

        return OptimizationResult(
            originalSize: originalSize,
            optimizedSize: optimizedSize,
            reductionPercentage: reduction,
            toolUsed: "wasm-opt \(optimizationLevel.rawValue)"
        )
    }

    /// Checks if wasm-opt tool is available
    private func isWasmOptAvailable() async -> Bool {
        await runCommand("which", arguments: ["wasm-opt"]) != nil
    }

    /// Runs wasm-opt on a WASM file
    private func runWasmOpt(inputPath: String, outputPath: String) async -> Bool {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = [
            "wasm-opt",
            optimizationLevel.rawValue,
            inputPath,
            "-o",
            outputPath
        ]

        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe

        do {
            try process.run()
            process.waitUntilExit()

            if process.terminationStatus != 0 {
                if verbose {
                    let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
                    if let errorOutput = String(data: errorData, encoding: .utf8) {
                        print("  ⚠ wasm-opt error: \(errorOutput)")
                    }
                }
                return false
            }

            return true
        } catch {
            if verbose {
                print("  ⚠ Failed to run wasm-opt: \(error.localizedDescription)")
            }
            return false
        }
    }

    /// Runs a command and returns its output, or nil if it fails
    private func runCommand(_ command: String, arguments: [String]) async -> String? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = [command] + arguments

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()

        do {
            try process.run()
            process.waitUntilExit()

            guard process.terminationStatus == 0 else {
                return nil
            }

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8)?
                .trimmingCharacters(in: .whitespacesAndNewlines)

            return output?.isEmpty == false ? output : nil
        } catch {
            return nil
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
