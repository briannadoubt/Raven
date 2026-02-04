import Foundation

/// Compiles Swift code to WebAssembly using SwiftWasm toolchain
@available(macOS 13.0, *)
actor WasmCompiler {
    private let config: BuildConfig
    private let toolchainDetector: ToolchainDetector

    enum CompilationError: Error, CustomStringConvertible {
        case toolchainNotFound
        case compilationFailed(String)
        case wasmFileNotFound(String)
        case invalidSourceDirectory(String)
        case processError(Int32, String)

        var description: String {
            switch self {
            case .toolchainNotFound:
                return "No SwiftWasm toolchain found. Please install carton or SwiftWasm."
            case .compilationFailed(let message):
                return "Compilation failed:\n\(message)"
            case .wasmFileNotFound(let path):
                return "WASM file not found at expected location: \(path)"
            case .invalidSourceDirectory(let path):
                return "Invalid source directory: \(path)"
            case .processError(let code, let message):
                return "Process exited with code \(code):\n\(message)"
            }
        }
    }

    init(config: BuildConfig) {
        self.config = config
        self.toolchainDetector = ToolchainDetector()
    }

    /// Compiles the Swift package to WASM
    /// - Parameter isIncremental: When true, uses incremental compilation (debug builds only).
    ///   SwiftPM automatically performs incremental builds when using `swift build` without clean.
    ///   This parameter controls whether to preserve the build directory between builds.
    func compile(isIncremental: Bool = false) async throws -> URL {
        // Validate source directory
        guard FileManager.default.fileExists(atPath: config.sourceDirectory.path) else {
            throw CompilationError.invalidSourceDirectory(config.sourceDirectory.path)
        }

        // Detect available toolchain
        let toolchain = try await toolchainDetector.detectToolchain()

        guard toolchain != .none else {
            throw CompilationError.toolchainNotFound
        }

        if config.verbose {
            print("Using toolchain: \(toolchain)")
            print("Source directory: \(config.sourceDirectory.path)")
            print("Output directory: \(config.outputDirectory.path)")
            print("Optimization: \(config.optimizationLevel.rawValue)")
        }

        // Compile based on available toolchain
        let wasmPath: URL
        switch toolchain {
        case .carton:
            wasmPath = try await compileWithCarton(isIncremental: isIncremental)
        case .swiftWasm:
            wasmPath = try await compileWithSwiftc(isIncremental: isIncremental)
        case .none:
            throw CompilationError.toolchainNotFound
        }

        // Verify WASM file exists
        guard FileManager.default.fileExists(atPath: wasmPath.path) else {
            throw CompilationError.wasmFileNotFound(wasmPath.path)
        }

        if config.verbose {
            let fileSize = try? FileManager.default.attributesOfItem(atPath: wasmPath.path)[.size] as? UInt64
            if let size = fileSize {
                let sizeInMB = Double(size) / 1_048_576.0
                print("WASM file size: \(String(format: "%.2f", sizeInMB)) MB")
            }
        }

        return wasmPath
    }

    /// Compiles using carton (preferred method)
    /// - Parameter isIncremental: When true, skips clean build. SwiftPM handles incremental builds automatically.
    private func compileWithCarton(isIncremental: Bool = false) async throws -> URL {
        if config.verbose {
            print("Compiling with carton...")
            if isIncremental {
                print("  Using incremental build (preserving build artifacts)")
            }
        }

        var arguments = ["carton", "build"]

        // Add optimization flag
        arguments.append(config.optimizationLevel.cartonFlag)

        // Add verbose flag if enabled
        if config.verbose {
            arguments.append("--verbose")
        }

        // Add additional flags
        arguments.append(contentsOf: config.additionalFlags)

        // Run carton build
        let (exitCode, output, error) = try await runProcess(
            executable: "/usr/bin/env",
            arguments: arguments,
            workingDirectory: config.sourceDirectory
        )

        guard exitCode == 0 else {
            let errorMessage = error.isEmpty ? output : error
            throw CompilationError.processError(exitCode, errorMessage)
        }

        if config.verbose && !output.isEmpty {
            print(output)
        }

        // Return path to compiled WASM
        return config.cartonWasmPath
    }

    /// Compiles using swiftc directly (fallback method)
    /// - Parameter isIncremental: When true, preserves intermediate build artifacts for faster rebuilds
    private func compileWithSwiftc(isIncremental: Bool = false) async throws -> URL {
        if config.verbose {
            print("Compiling with swiftc...")
            if isIncremental {
                print("  Using incremental build (preserving build artifacts)")
            }
        }

        var arguments = [
            "swiftc",
            "-target", config.targetTriple,
            config.optimizationLevel.swiftFlag
        ]

        // Add debug symbols if enabled
        if config.debugSymbols {
            arguments.append("-g")
        }

        // Add Swift 6.2 strict concurrency
        arguments.append(contentsOf: [
            "-Xfrontend", "-enable-upcoming-feature",
            "-Xfrontend", "StrictConcurrency"
        ])

        // Add additional flags
        arguments.append(contentsOf: config.additionalFlags)

        // Add output path
        let outputPath = config.swiftcWasmPath
        try FileManager.default.createDirectory(
            at: outputPath.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )

        arguments.append(contentsOf: [
            "-o", outputPath.path
        ])

        // Find all Swift source files
        let sourceFiles = try findSwiftSourceFiles(in: config.sourceDirectory)

        if sourceFiles.isEmpty {
            throw CompilationError.compilationFailed("No Swift source files found")
        }

        arguments.append(contentsOf: sourceFiles.map { $0.path })

        // Run swiftc
        let (exitCode, output, error) = try await runProcess(
            executable: "/usr/bin/env",
            arguments: arguments,
            workingDirectory: config.sourceDirectory
        )

        guard exitCode == 0 else {
            let errorMessage = error.isEmpty ? output : error
            throw CompilationError.processError(exitCode, errorMessage)
        }

        if config.verbose && !output.isEmpty {
            print(output)
        }

        return outputPath
    }

    /// Finds all Swift source files in a directory
    private func findSwiftSourceFiles(in directory: URL) throws -> [URL] {
        let fileManager = FileManager.default
        var sourceFiles: [URL] = []

        // Look in Sources directory
        let sourcesDir = directory.appendingPathComponent("Sources")
        guard fileManager.fileExists(atPath: sourcesDir.path) else {
            return sourceFiles
        }

        let enumerator = fileManager.enumerator(
            at: sourcesDir,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles, .skipsPackageDescendants]
        )

        guard let enumerator = enumerator else {
            return sourceFiles
        }

        for case let fileURL as URL in enumerator {
            if fileURL.pathExtension == "swift" {
                sourceFiles.append(fileURL)
            }
        }

        return sourceFiles
    }

    /// Runs a process and returns its exit code, stdout, and stderr
    private func runProcess(
        executable: String,
        arguments: [String],
        workingDirectory: URL
    ) async throws -> (exitCode: Int32, stdout: String, stderr: String) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = arguments
        process.currentDirectoryURL = workingDirectory

        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe

        if config.verbose {
            print("Running: \(executable) \(arguments.joined(separator: " "))")
            print("Working directory: \(workingDirectory.path)")
        }

        try process.run()

        // Read output asynchronously
        let stdoutData = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
        let stderrData = stderrPipe.fileHandleForReading.readDataToEndOfFile()

        process.waitUntilExit()

        let stdout = String(data: stdoutData, encoding: .utf8) ?? ""
        let stderr = String(data: stderrData, encoding: .utf8) ?? ""

        return (process.terminationStatus, stdout, stderr)
    }

    /// Parses compilation errors from output
    func parseCompilationErrors(_ output: String) -> [CompilationErrorMessage] {
        var errors: [CompilationErrorMessage] = []
        let lines = output.components(separatedBy: .newlines)

        for line in lines {
            // Parse Swift compiler error format: file:line:column: error: message
            if let match = parseSwiftError(line) {
                errors.append(match)
            }
        }

        return errors
    }

    /// Parses a Swift compiler error line
    private func parseSwiftError(_ line: String) -> CompilationErrorMessage? {
        // Pattern: /path/to/file.swift:10:5: error: message
        let pattern = #"^(.+?):(\d+):(\d+):\s*(error|warning|note):\s*(.+)$"#

        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return nil
        }

        let range = NSRange(line.startIndex..., in: line)
        guard let match = regex.firstMatch(in: line, range: range) else {
            return nil
        }

        guard match.numberOfRanges == 6 else {
            return nil
        }

        let filePath = String(line[Range(match.range(at: 1), in: line)!])
        let lineNumber = Int(String(line[Range(match.range(at: 2), in: line)!])) ?? 0
        let column = Int(String(line[Range(match.range(at: 3), in: line)!])) ?? 0
        let severityStr = String(line[Range(match.range(at: 4), in: line)!])
        let message = String(line[Range(match.range(at: 5), in: line)!])

        let severity: CompilationErrorMessage.Severity = switch severityStr {
        case "error": .error
        case "warning": .warning
        case "note": .note
        default: .error
        }

        return CompilationErrorMessage(
            file: filePath,
            line: lineNumber,
            column: column,
            severity: severity,
            message: message
        )
    }
}

/// Represents a compilation error message
struct CompilationErrorMessage: Sendable {
    enum Severity: String, Sendable {
        case error
        case warning
        case note
    }

    let file: String
    let line: Int
    let column: Int
    let severity: Severity
    let message: String

    var description: String {
        "\(file):\(line):\(column): \(severity.rawValue): \(message)"
    }
}
