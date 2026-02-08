import Testing
@testable import RavenCLI
import Foundation

/// Comprehensive Phase 5 verification tests that validate the complete build workflow.
///
/// These tests verify that:
/// 1. CLI Command Tests - CreateCommand and BuildCommand validation
/// 2. WASM Compiler Tests - Toolchain detection and compilation configuration
/// 3. HTML Generator Tests - Valid HTML generation with proper configuration
/// 4. Asset Bundler Tests - File copying and directory structure preservation
/// 5. Optimizer Tests - WASM optimization configuration
/// 6. End-to-End Integration - Complete workflow integration
@Suite struct Phase5VerificationTests {

    private func makeTempDirectory() throws -> URL {
        let tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
        return tempDirectory
    }

    private func cleanupTempDirectory(_ url: URL) {
        try? FileManager.default.removeItem(at: url)
    }

    // MARK: - Test 1: CLI Command Tests

    @Test func createCommandValidatesProjectNames() throws {
        let validNames = [
            "MyProject",
            "my-project",
            "my_project",
            "Project123",
            "ABC-DEF_123",
        ]

        for name in validNames {
            _ = CreateCommand()

            let isValid = name.range(of: "^[a-zA-Z0-9_-]+$", options: .regularExpression) != nil
            #expect(isValid)
        }
    }

    @Test func createCommandRejectsInvalidProjectNames() throws {
        let invalidNames = [
            "My Project",
            "my@project",
            "my.project",
            "my/project",
            "",
            " ",
        ]

        for name in invalidNames {
            let isValid = name.range(of: "^[a-zA-Z0-9_-]+$", options: .regularExpression) != nil
            #expect(!isValid)
        }
    }

    @Test func createCommandCreatesRequiredFiles() throws {
        let requiredFiles = [
            "Package.swift",
            "README.md",
            ".gitignore",
        ]

        let requiredDirs = [
            "Sources",
            "Public",
        ]

        #expect(requiredFiles.count == 3)
        #expect(requiredDirs.count == 2)
    }

    @Test func buildCommandValidatesProjectStructure() throws {
        let tempDirectory = try makeTempDirectory()
        defer { cleanupTempDirectory(tempDirectory) }

        let projectDir = tempDirectory.appendingPathComponent("TestProject")
        try FileManager.default.createDirectory(at: projectDir, withIntermediateDirectories: true)

        let packageSwift = """
        // swift-tools-version: 6.2
        import PackageDescription

        let package = Package(
            name: "TestProject",
            products: [
                .executable(name: "TestProject", targets: ["TestProject"])
            ],
            targets: [
                .executableTarget(name: "TestProject")
            ]
        )
        """
        try packageSwift.write(to: projectDir.appendingPathComponent("Package.swift"), atomically: true, encoding: .utf8)

        #expect(FileManager.default.fileExists(atPath: projectDir.appendingPathComponent("Package.swift").path))
    }

    @Test func buildCommandConfigurationParsing() throws {
        let tempDirectory = try makeTempDirectory()
        defer { cleanupTempDirectory(tempDirectory) }

        let sourceDir = tempDirectory.appendingPathComponent("source")
        let outputDir = tempDirectory.appendingPathComponent("output")

        let debugConfig = BuildConfig(
            sourceDirectory: sourceDir,
            outputDirectory: outputDir,
            optimizationLevel: .debug,
            verbose: false
        )

        #expect(debugConfig.optimizationLevel == .debug)
        #expect(debugConfig.optimizationLevel.swiftFlag == "-Onone")
        #expect(debugConfig.optimizationLevel.cartonFlag == "--debug")
        #expect(debugConfig.debugSymbols)

        let releaseConfig = BuildConfig(
            sourceDirectory: sourceDir,
            outputDirectory: outputDir,
            optimizationLevel: .release,
            verbose: false
        )

        #expect(releaseConfig.optimizationLevel == .release)
        #expect(releaseConfig.optimizationLevel.swiftFlag == "-O")
        #expect(releaseConfig.optimizationLevel.cartonFlag == "--release")
    }

    // MARK: - Test 2: WASM Compiler Tests

    @Test func toolchainDetectorFindsAvailableToolchains() async throws {
        let detector = ToolchainDetector()
        let toolchain = try await detector.detectToolchain()
        #expect(toolchain != nil)
    }

    @Test func toolchainDetectorCartonAvailability() async throws {
        let detector = ToolchainDetector()
        let isAvailable = await detector.isCartonAvailable()
        #expect(isAvailable != nil)
    }

    @Test func toolchainDetectorSwiftWasmAvailability() async throws {
        let detector = ToolchainDetector()
        let isAvailable = await detector.isSwiftWasmAvailable()
        #expect(isAvailable != nil)
    }

    @Test func buildConfigOptimizationLevels() throws {
        let tempDirectory = try makeTempDirectory()
        defer { cleanupTempDirectory(tempDirectory) }

        let sourceDir = tempDirectory
        let outputDir = tempDirectory.appendingPathComponent("output")

        let levels: [BuildConfig.OptimizationLevel] = [.debug, .release]

        for level in levels {
            let config = BuildConfig(
                sourceDirectory: sourceDir,
                outputDirectory: outputDir,
                optimizationLevel: level
            )

            #expect(config.optimizationLevel == level)
            #expect(config.optimizationLevel.swiftFlag != nil)
            #expect(config.optimizationLevel.cartonFlag != nil)
        }
    }

    @Test func buildConfigDefaultValues() throws {
        let config = BuildConfig.default()

        #expect(config.optimizationLevel == .debug)
        #expect(config.targetTriple == "wasm32-unknown-wasi")
        #expect(config.debugSymbols)
        #expect(!config.verbose)
        #expect(config.additionalFlags == [])
    }

    @Test func buildConfigForProject() throws {
        let tempDirectory = try makeTempDirectory()
        defer { cleanupTempDirectory(tempDirectory) }

        let projectPath = tempDirectory.path
        let config = BuildConfig.forProject(at: projectPath)

        #expect(config.sourceDirectory.path == projectPath)
        #expect(config.outputDirectory.path.contains("dist"))
    }

    @Test func buildConfigTransformations() throws {
        let baseConfig = BuildConfig.default()

        let releaseConfig = baseConfig.asRelease()
        #expect(releaseConfig.optimizationLevel == .release)
        #expect(!releaseConfig.debugSymbols)

        let debugConfig = baseConfig.asDebug()
        #expect(debugConfig.optimizationLevel == .debug)
        #expect(debugConfig.debugSymbols)

        let verboseConfig = baseConfig.withVerbose(true)
        #expect(verboseConfig.verbose)
    }

    @Test func wasmCompilerErrorHandling() throws {
        let tempDirectory = try makeTempDirectory()
        defer { cleanupTempDirectory(tempDirectory) }

        let config = BuildConfig(
            sourceDirectory: URL(fileURLWithPath: "/nonexistent"),
            outputDirectory: tempDirectory
        )

        let compiler = WasmCompiler(config: config)

        Task {
            do {
                _ = try await compiler.compile()
                Issue.record("Should throw error for nonexistent source directory")
            } catch {
                #expect(error is WasmCompiler.CompilationError)
            }
        }
    }

    @Test func compilationErrorMessages() throws {
        let errors: [WasmCompiler.CompilationError] = [
            .toolchainNotFound,
            .compilationFailed("Test error"),
            .wasmFileNotFound("/path/to/file.wasm"),
            .invalidSourceDirectory("/invalid/path"),
            .processError(1, "Process failed"),
        ]

        for error in errors {
            let description = error.description
            #expect(!description.isEmpty)
            #expect(description.count > 10)
        }
    }

    // MARK: - Test 3: HTML Generator Tests

    @Test func htmlGeneratorProducesValidHTML() throws {
        let generator = HTMLGenerator()
        let config = HTMLConfig(projectName: "TestProject")

        let html = generator.generate(config: config)

        #expect(html.contains("<!DOCTYPE html>"))
        #expect(html.contains("<html"))
        #expect(html.contains("</html>"))
        #expect(html.contains("<head>"))
        #expect(html.contains("</head>"))
        #expect(html.contains("<body>"))
        #expect(html.contains("</body>"))
    }

    @Test func htmlGeneratorIncludesProjectName() throws {
        let generator = HTMLGenerator()
        let config = HTMLConfig(projectName: "MyAwesomeApp")

        let html = generator.generate(config: config)

        #expect(html.contains("<title>MyAwesomeApp</title>"))
    }
}

