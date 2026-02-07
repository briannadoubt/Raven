import Foundation

/// Compiles Swift code to WebAssembly using SwiftWasm toolchain
@available(macOS 13.0, *)
actor WasmCompiler {
    private let config: BuildConfig
    private let toolchainDetector: ToolchainDetector
    private let errorReporter: EnhancedErrorReporter

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
        self.errorReporter = EnhancedErrorReporter()
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

        guard !toolchain.isNone else {
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
        case .swiftSDK(let name):
            wasmPath = try await compileWithSwiftSDK(sdkName: name, isIncremental: isIncremental)
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
            let enhancedMessage = enhanceCompilerOutput(errorMessage)
            throw CompilationError.processError(exitCode, enhancedMessage)
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
            let enhancedMessage = enhanceCompilerOutput(errorMessage)
            throw CompilationError.processError(exitCode, enhancedMessage)
        }

        if config.verbose && !output.isEmpty {
            print(output)
        }

        return outputPath
    }

    /// Compiles using swift build with Swift SDK
    private func compileWithSwiftSDK(sdkName: String, isIncremental: Bool = false) async throws -> URL {
        if config.verbose {
            print("Compiling with Swift SDK: \(sdkName)...")
            if isIncremental {
                print("  Using incremental build")
            }
        }

        let useSwiftly = await shouldUseSwiftlyForSDK(sdkName: sdkName)

        var arguments: [String]
        if useSwiftly {
            arguments = ["swiftly", "run", "swift", "build", "--swift-sdk", sdkName]
            if config.verbose {
                print("Using Swiftly-managed Swift toolchain for SDK builds")
            }
        } else {
            arguments = ["swift", "build", "--swift-sdk", sdkName]
        }

        // JavaScriptKit requires the WASI reactor ABI execution model
        arguments.append(contentsOf: ["-Xswiftc", "-Xclang-linker", "-Xswiftc", "-mexec-model=reactor"])

        // Export the main entry point so JS can call it after _initialize()
        arguments.append(contentsOf: ["-Xlinker", "--export-if-defined=main"])
        arguments.append(contentsOf: ["-Xlinker", "--export-if-defined=__main_argc_argv"])

        // Add release configuration if needed
        if config.optimizationLevel != .debug {
            arguments.append(contentsOf: ["-c", "release"])
        }

        // Add verbose flag
        if config.verbose {
            arguments.append("--verbose")
        }

        // Add additional flags
        arguments.append(contentsOf: config.additionalFlags)

        let (exitCode, output, error) = try await runProcess(
            executable: "/usr/bin/env",
            arguments: arguments,
            workingDirectory: config.sourceDirectory
        )

        guard exitCode == 0 else {
            let errorMessage = error.isEmpty ? output : error
            let enhancedMessage = enhanceCompilerOutput(errorMessage)
            throw CompilationError.processError(exitCode, enhancedMessage)
        }

        if config.verbose && !output.isEmpty {
            print(output)
        }

        // Find the built wasm file
        return try findBuiltWasm()
    }

    /// Returns true when `swiftly` is available and can see the requested SDK.
    private func shouldUseSwiftlyForSDK(sdkName: String) async -> Bool {
        let checkProcess = Process()
        checkProcess.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        checkProcess.arguments = ["swiftly", "run", "swift", "sdk", "list"]
        checkProcess.currentDirectoryURL = config.sourceDirectory

        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        checkProcess.standardOutput = stdoutPipe
        checkProcess.standardError = stderrPipe

        do {
            try checkProcess.run()
            checkProcess.waitUntilExit()
            guard checkProcess.terminationStatus == 0 else {
                return false
            }

            let data = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
            guard let output = String(data: data, encoding: .utf8) else {
                return false
            }
            return output
                .components(separatedBy: .newlines)
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .contains(sdkName)
        } catch {
            return false
        }
    }

    /// Finds the built .wasm file in the build directory
    private func findBuiltWasm() throws -> URL {
        // If we have an explicit target name, use the computed path directly
        if config.executableTargetName != nil {
            let path = config.swiftSDKWasmPath
            if FileManager.default.fileExists(atPath: path.path) {
                return path
            }
        }

        // Otherwise scan for .wasm files in the build output
        let debugDir = config.buildDirectory.appendingPathComponent(
            config.optimizationLevel == .debug ? "debug" : "release"
        )

        if let contents = try? FileManager.default.contentsOfDirectory(
            at: debugDir,
            includingPropertiesForKeys: nil
        ) {
            // Find .wasm files, excluding intermediates
            let wasmFiles = contents.filter { $0.pathExtension == "wasm" }
            if let first = wasmFiles.first {
                return first
            }
        }

        // Try the explicit path as last resort
        let fallback = config.swiftSDKWasmPath
        throw CompilationError.wasmFileNotFound(fallback.path)
    }

    /// Detects the executable target name from Package.swift
    static func detectExecutableTarget(in projectDir: URL) -> String? {
        let packagePath = projectDir.appendingPathComponent("Package.swift")
        guard let content = try? String(contentsOf: packagePath, encoding: .utf8) else {
            return nil
        }

        // Look for .executableTarget(name: "TargetName"
        // Pattern matches both .executableTarget(name: "X" and .executableTarget(\n    name: "X"
        let pattern = #"\.executableTarget\s*\(\s*name\s*:\s*"([^"]+)""#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators]),
              let match = regex.firstMatch(in: content, range: NSRange(content.startIndex..., in: content)),
              let range = Range(match.range(at: 1), in: content) else {
            return nil
        }

        return String(content[range])
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

    /// Enhances compiler output with better error messages and suggestions
    private func enhanceCompilerOutput(_ output: String) -> String {
        let errors = parseCompilationErrors(output)

        if errors.isEmpty {
            // No structured errors found, return original output
            return output
        }

        var enhancedOutput = ""

        for error in errors {
            let enhanced = errorReporter.enhanceError(error)
            enhancedOutput += errorReporter.formatError(enhanced)
        }

        return enhancedOutput
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

// MARK: - JavaScriptKit Runtime Discovery

extension WasmCompiler {
    /// Finds the JavaScriptKit runtime JavaScript source for inlining into HTML.
    ///
    /// Searches for the runtime in the build checkouts directory.
    /// - Parameter projectPath: The root path of the Swift package project.
    /// - Returns: The JavaScript source code as a string, or nil if not found.
    static func findJavaScriptKitRuntime(in projectPath: String) -> String? {
        let searchPaths = [
            (projectPath as NSString).appendingPathComponent(
                ".build/checkouts/JavaScriptKit/Sources/JavaScriptKit/Runtime/index.js"
            ),
            (projectPath as NSString).appendingPathComponent(
                ".build/checkouts/JavaScriptKit/Runtime/index.js"
            ),
        ]

        for path in searchPaths {
            if FileManager.default.fileExists(atPath: path),
               let contents = try? String(contentsOfFile: path, encoding: .utf8) {
                return contents
            }
        }

        return nil
    }
}

/// Represents a compilation error message
public struct CompilationErrorMessage: Sendable {
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
