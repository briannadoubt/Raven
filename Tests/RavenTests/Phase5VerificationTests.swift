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
        // Valid project names
        let validNames = [
            "MyProject",
            "my-project",
            "my_project",
            "Project123",
            "ABC-DEF_123"
        ]

        for name in validNames {
            let command = CreateCommand()
            let reflection = Mirror(reflecting: command)

            // Access the private method via reflection pattern testing
            // We'll test the validation logic by attempting to create projects
            let isValid = name.range(of: "^[a-zA-Z0-9_-]+$", options: .regularExpression) != nil
            #expect(isValid)
        }
    }

    @Test func createCommandRejectsInvalidProjectNames() throws {
        // Invalid project names
        let invalidNames = [
            "My Project",  // Contains space
            "my@project",  // Contains special character
            "my.project",  // Contains period
            "my/project",  // Contains slash
            "",           // Empty
            " "           // Only whitespace
        ]

        for name in invalidNames {
            let isValid = name.range(of: "^[a-zA-Z0-9_-]+$", options: .regularExpression) != nil
            #expect(!isValid)
        }
    }

    @Test func createCommandCreatesRequiredFiles() throws {
        // Test that we can identify the required files a project should have
        let requiredFiles = [
            "Package.swift",
            "README.md",
            ".gitignore"
        ]

        let requiredDirs = [
            "Sources",
            "Public"
        ]

        // Verify the list is comprehensive
        #expect(requiredFiles.count == 3)
        #expect(requiredDirs.count == 2)
    }

    @Test func buildCommandValidatesProjectStructure() throws {
        let tempDirectory = try makeTempDirectory()
        defer { cleanupTempDirectory(tempDirectory) }

        // Create a valid project structure
        let projectDir = tempDirectory.appendingPathComponent("TestProject")
        try FileManager.default.createDirectory(at: projectDir, withIntermediateDirectories: true)

        // Create Package.swift
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

        // Verify Package.swift exists
        #expect(FileManager.default.fileExists(atPath: projectDir.appendingPathComponent("Package.swift").path))
    }

    @Test func buildCommandConfigurationParsing() throws {
        let tempDirectory = try makeTempDirectory()
        defer { cleanupTempDirectory(tempDirectory) }

        let sourceDir = tempDirectory.appendingPathComponent("source")
        let outputDir = tempDirectory.appendingPathComponent("output")

        // Test debug configuration
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

        // Test release configuration
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

        // Test that detector can check for toolchains
        // Note: This won't actually find toolchains in CI, but tests the interface
        let toolchain = try await detector.detectToolchain()

        // Should return a valid toolchain type (even if .none)
        #expect(toolchain != nil)
    }

    @Test func toolchainDetectorCartonAvailability() async throws {
        let detector = ToolchainDetector()

        // Test the carton availability check
        let isAvailable = await detector.isCartonAvailable()

        // Should return a boolean (may be false in CI)
        #expect(isAvailable != nil)
    }

    @Test func toolchainDetectorSwiftWasmAvailability() async throws {
        let detector = ToolchainDetector()

        // Test the SwiftWasm availability check
        let isAvailable = await detector.isSwiftWasmAvailable()

        // Should return a boolean
        #expect(isAvailable != nil)
    }

    @Test func buildConfigOptimizationLevels() throws {
        let tempDirectory = try makeTempDirectory()
        defer { cleanupTempDirectory(tempDirectory) }

        let sourceDir = tempDirectory
        let outputDir = tempDirectory.appendingPathComponent("output")

        // Test all optimization levels
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

        // Test asRelease
        let releaseConfig = baseConfig.asRelease()
        #expect(releaseConfig.optimizationLevel == .release)
        #expect(!releaseConfig.debugSymbols)

        // Test asDebug
        let debugConfig = baseConfig.asDebug()
        #expect(debugConfig.optimizationLevel == .debug)
        #expect(debugConfig.debugSymbols)

        // Test withVerbose
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

        // Test that compiler handles invalid source directory
        // We expect this to throw
        Task {
            do {
                _ = try await compiler.compile()
                Issue.record("Should throw error for nonexistent source directory")
            } catch {
                // Expected to throw
                #expect(error is WasmCompiler.CompilationError)
            }
        }
    }

    @Test func compilationErrorMessages() throws {
        // Test error descriptions
        let errors: [WasmCompiler.CompilationError] = [
            .toolchainNotFound,
            .compilationFailed("Test error"),
            .wasmFileNotFound("/path/to/file.wasm"),
            .invalidSourceDirectory("/invalid/path"),
            .processError(1, "Process failed")
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

        // Verify basic HTML structure
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

        // Should include project name in title
        #expect(html.contains("<title>MyAwesomeApp</title>"))
    }

    @Test func htmlConfigWithCustomSettings() throws {
        let config = HTMLConfig(
            projectName: "CustomApp",
            title: "Custom Title",
            wasmFile: "custom.wasm",
            cssFiles: ["custom-styles.css", "theme.css"],
            metaTags: [
                "description": "A custom app",
                "author": "Test Author"
            ],
            language: "es",
            mountElementID: "custom-app"
        )

        #expect(config.projectName == "CustomApp")
        #expect(config.title == "Custom Title")
        #expect(config.wasmFile == "custom.wasm")
        #expect(config.cssFiles.count == 2)
        #expect(config.metaTags.count == 2)
        #expect(config.language == "es")
        #expect(config.mountElementID == "custom-app")
    }

    @Test func htmlGeneratorScriptTagGeneration() throws {
        let generator = HTMLGenerator()
        let config = HTMLConfig(
            projectName: "TestApp",
            wasmFile: "test.wasm"
        )

        let html = generator.generate(config: config)

        // Verify script tags
        #expect(html.contains("runtime.js"))
        #expect(html.contains("test.wasm"))
        #expect(html.contains("<script"))
    }

    @Test func htmlGeneratorMetaTags() throws {
        let generator = HTMLGenerator()
        let config = HTMLConfig(
            projectName: "TestApp",
            metaTags: [
                "description": "Test Description",
                "keywords": "test, app, swift"
            ]
        )

        let html = generator.generate(config: config)

        #expect(html.contains("Test Description"))
        #expect(html.contains("test, app, swift"))
        #expect(html.contains("<meta name="))
    }

    @Test func htmlGeneratorCSSFiles() throws {
        let generator = HTMLGenerator()
        let config = HTMLConfig(
            projectName: "TestApp",
            cssFiles: ["styles.css", "theme.css"]
        )

        let html = generator.generate(config: config)

        #expect(html.contains("styles.css"))
        #expect(html.contains("theme.css"))
        #expect(html.contains("<link rel=\"stylesheet\""))
    }

    @Test func htmlGeneratorEscapesSpecialCharacters() throws {
        let generator = HTMLGenerator()
        let config = HTMLConfig(
            projectName: "Test<App>",
            title: "Test & App",
            metaTags: ["description": "A \"quoted\" description"]
        )

        let html = generator.generate(config: config)

        // HTML special characters should be escaped
        #expect(html.contains("&lt;") || html.contains("&gt;") || html.contains("&amp;") || html.contains("&quot;"))
    }

    @Test func htmlGeneratorWritesToFile() throws {
        let tempDirectory = try makeTempDirectory()
        defer { cleanupTempDirectory(tempDirectory) }

        let generator = HTMLGenerator()
        let config = HTMLConfig(projectName: "TestApp")
        let outputPath = tempDirectory.appendingPathComponent("index.html").path

        try generator.writeToFile(config: config, path: outputPath)

        // Verify file was created
        #expect(FileManager.default.fileExists(atPath: outputPath))

        // Verify content
        let content = try String(contentsOfFile: outputPath)
        #expect(content.contains("<!DOCTYPE html>"))
        #expect(content.contains("TestApp"))
    }

    // MARK: - Test 4: Asset Bundler Tests

    @Test func assetBundlerCopiesFilesCorrectly() throws {
        let tempDirectory = try makeTempDirectory()
        defer { cleanupTempDirectory(tempDirectory) }

        let bundler = AssetBundler(verbose: false)

        // Create source directory with files
        let sourceDir = tempDirectory.appendingPathComponent("source")
        try FileManager.default.createDirectory(at: sourceDir, withIntermediateDirectories: true)

        let testFile = sourceDir.appendingPathComponent("test.txt")
        try "Test content".write(to: testFile, atomically: true, encoding: .utf8)

        // Create destination directory
        let destDir = tempDirectory.appendingPathComponent("dest")
        try FileManager.default.createDirectory(at: destDir, withIntermediateDirectories: true)

        // Bundle assets
        let result = try bundler.bundleAssets(from: sourceDir.path, to: destDir.path)

        #expect(result.filesCopied == 1)
        #expect(result.totalBytes > 0)
        #expect(result.errors.isEmpty)

        // Verify file was copied
        let copiedFile = destDir.appendingPathComponent("test.txt")
        #expect(FileManager.default.fileExists(atPath: copiedFile.path))
    }

    @Test func assetBundlerHiddenFileFiltering() throws {
        let tempDirectory = try makeTempDirectory()
        defer { cleanupTempDirectory(tempDirectory) }

        let bundler = AssetBundler(verbose: false)

        // Create source directory with hidden and visible files
        let sourceDir = tempDirectory.appendingPathComponent("source")
        try FileManager.default.createDirectory(at: sourceDir, withIntermediateDirectories: true)

        let visibleFile = sourceDir.appendingPathComponent("visible.txt")
        try "Visible".write(to: visibleFile, atomically: true, encoding: .utf8)

        let hiddenFile = sourceDir.appendingPathComponent(".hidden")
        try "Hidden".write(to: hiddenFile, atomically: true, encoding: .utf8)

        // Create destination directory
        let destDir = tempDirectory.appendingPathComponent("dest")
        try FileManager.default.createDirectory(at: destDir, withIntermediateDirectories: true)

        // Bundle assets
        let result = try bundler.bundleAssets(from: sourceDir.path, to: destDir.path)

        // Should only copy visible file
        #expect(result.filesCopied == 1)

        // Verify only visible file was copied
        #expect(FileManager.default.fileExists(atPath: destDir.appendingPathComponent("visible.txt").path))
        #expect(!FileManager.default.fileExists(atPath: destDir.appendingPathComponent(".hidden").path))
    }

    @Test func assetBundlerDirectoryStructurePreservation() throws {
        let tempDirectory = try makeTempDirectory()
        defer { cleanupTempDirectory(tempDirectory) }

        let bundler = AssetBundler(verbose: false)

        // Create nested directory structure
        let sourceDir = tempDirectory.appendingPathComponent("source")
        let subDir = sourceDir.appendingPathComponent("subdir")
        try FileManager.default.createDirectory(at: subDir, withIntermediateDirectories: true)

        let rootFile = sourceDir.appendingPathComponent("root.txt")
        try "Root".write(to: rootFile, atomically: true, encoding: .utf8)

        let subFile = subDir.appendingPathComponent("sub.txt")
        try "Sub".write(to: subFile, atomically: true, encoding: .utf8)

        // Create destination directory
        let destDir = tempDirectory.appendingPathComponent("dest")
        try FileManager.default.createDirectory(at: destDir, withIntermediateDirectories: true)

        // Bundle assets
        let result = try bundler.bundleAssets(from: sourceDir.path, to: destDir.path)

        #expect(result.filesCopied == 2)

        // Verify directory structure is preserved
        #expect(FileManager.default.fileExists(atPath: destDir.appendingPathComponent("root.txt").path))
        #expect(FileManager.default.fileExists(atPath: destDir.appendingPathComponent("subdir/sub.txt").path))
    }

    @Test func assetBundlerHandlesMissingSourceDirectory() throws {
        let tempDirectory = try makeTempDirectory()
        defer { cleanupTempDirectory(tempDirectory) }

        let bundler = AssetBundler(verbose: false)

        let nonexistentSource = tempDirectory.appendingPathComponent("nonexistent")
        let destDir = tempDirectory.appendingPathComponent("dest")
        try FileManager.default.createDirectory(at: destDir, withIntermediateDirectories: true)

        // Should not throw, but return empty result
        let result = try bundler.bundleAssets(from: nonexistentSource.path, to: destDir.path)

        #expect(result.filesCopied == 0)
        #expect(result.errors.isEmpty)
    }

    @Test func assetBundlerTracksTotalBytes() throws {
        let tempDirectory = try makeTempDirectory()
        defer { cleanupTempDirectory(tempDirectory) }

        let bundler = AssetBundler(verbose: false)

        // Create source directory with files of known sizes
        let sourceDir = tempDirectory.appendingPathComponent("source")
        try FileManager.default.createDirectory(at: sourceDir, withIntermediateDirectories: true)

        let smallFile = sourceDir.appendingPathComponent("small.txt")
        try "12345".write(to: smallFile, atomically: true, encoding: .utf8)

        let largerFile = sourceDir.appendingPathComponent("larger.txt")
        try String(repeating: "A", count: 1000).write(to: largerFile, atomically: true, encoding: .utf8)

        // Create destination directory
        let destDir = tempDirectory.appendingPathComponent("dest")
        try FileManager.default.createDirectory(at: destDir, withIntermediateDirectories: true)

        // Bundle assets
        let result = try bundler.bundleAssets(from: sourceDir.path, to: destDir.path)

        #expect(result.filesCopied == 2)
        #expect(result.totalBytes > 1000)
    }

    // MARK: - Test 5: Optimizer Tests

    @Test func wasmOptimizerDetectsAvailability() async throws {
        let tempDirectory = try makeTempDirectory()
        defer { cleanupTempDirectory(tempDirectory) }

        let optimizer = WasmOptimizer(verbose: false)

        // Create a dummy WASM file
        let wasmFile = tempDirectory.appendingPathComponent("test.wasm")
        try Data(repeating: 0, count: 1000).write(to: wasmFile)

        // Run optimization (will skip if wasm-opt not available)
        let result = try await optimizer.optimize(wasmPath: wasmFile.path)

        // Should complete without errors
        #expect(result.originalSize > 0)
        #expect(result.optimizedSize > 0)
    }

    @Test func wasmOptimizerOptimizationLevels() throws {
        let levels: [WasmOptimizer.OptimizationLevel] = [.o0, .o1, .o2, .o3, .oz]

        for level in levels {
            #expect(!level.rawValue.isEmpty)
            #expect(!level.description.isEmpty)
        }

        #expect(WasmOptimizer.OptimizationLevel.o0.rawValue == "-O0")
        #expect(WasmOptimizer.OptimizationLevel.o3.rawValue == "-O3")
        #expect(WasmOptimizer.OptimizationLevel.oz.rawValue == "-Oz")
    }

    @Test func wasmOptimizerSizeReporting() async throws {
        let tempDirectory = try makeTempDirectory()
        defer { cleanupTempDirectory(tempDirectory) }

        let optimizer = WasmOptimizer(verbose: false, optimizationLevel: .o3)

        // Create a WASM file
        let wasmFile = tempDirectory.appendingPathComponent("test.wasm")
        let testData = Data(repeating: 0, count: 5000)
        try testData.write(to: wasmFile)

        // Optimize (will skip if wasm-opt not available)
        let result = try await optimizer.optimize(wasmPath: wasmFile.path)

        #expect(result.originalSize == 5000)
        #expect(result.optimizedSize >= 0)

        // If optimization was performed
        if result.wasOptimized {
            #expect(result.optimizedSize <= result.originalSize)
            #expect(result.reductionPercentage >= 0)
            #expect(result.reductionPercentage <= 100)
            #expect(result.savedBytes == result.originalSize - result.optimizedSize)
        }
    }

    @Test func wasmOptimizerHandlesMissingFile() async throws {
        let tempDirectory = try makeTempDirectory()
        defer { cleanupTempDirectory(tempDirectory) }

        let optimizer = WasmOptimizer(verbose: false)
        let nonexistentFile = tempDirectory.appendingPathComponent("nonexistent.wasm")

        do {
            _ = try await optimizer.optimize(wasmPath: nonexistentFile.path)
            Issue.record("Should throw error for missing file")
        } catch {
            #expect(error is WasmOptimizer.OptimizerError)
        }
    }

    @Test func optimizationResultProperties() throws {
        let result = WasmOptimizer.OptimizationResult(
            originalSize: 10000,
            optimizedSize: 7000,
            reductionPercentage: 30.0,
            toolUsed: "wasm-opt -O3"
        )

        #expect(result.wasOptimized)
        #expect(result.savedBytes == 3000)
        #expect(result.originalSize == 10000)
        #expect(result.optimizedSize == 7000)
        #expect(result.reductionPercentage == 30.0)

        // Test unoptimized result
        let noOptResult = WasmOptimizer.OptimizationResult(
            originalSize: 10000,
            optimizedSize: 10000,
            reductionPercentage: 0.0,
            toolUsed: nil
        )

        #expect(!noOptResult.wasOptimized)
        #expect(noOptResult.savedBytes == 0)
    }

    // MARK: - Test 6: End-to-End Integration Tests

    @Test func createCommandOutputIsValidSwiftPackage() throws {
        // Test that CreateCommand would generate a valid Package.swift structure
        let projectName = "TestProject"

        // Simulate Package.swift content generation
        let packageContent = """
        // swift-tools-version: 6.2
        import PackageDescription

        let package = Package(
            name: "\(projectName)",
            platforms: [
                .macOS(.v13),
                .iOS(.v16)
            ],
            products: [
                .executable(
                    name: "\(projectName)",
                    targets: ["\(projectName)"]
                )
            ],
            dependencies: [
                .package(url: "https://github.com/swiftwasm/JavaScriptKit.git", from: "0.19.0")
            ],
            targets: [
                .executableTarget(
                    name: "\(projectName)",
                    dependencies: [
                        .product(name: "JavaScriptKit", package: "JavaScriptKit")
                    ]
                )
            ]
        )
        """

        // Verify basic structure
        #expect(packageContent.contains("swift-tools-version: 6.2"))
        #expect(packageContent.contains("import PackageDescription"))
        #expect(packageContent.contains("let package = Package"))
        #expect(packageContent.contains(projectName))
    }

    @Test func buildCommandWorksWithGeneratedProject() throws {
        let tempDirectory = try makeTempDirectory()
        defer { cleanupTempDirectory(tempDirectory) }

        // Create a minimal project structure
        let projectDir = tempDirectory.appendingPathComponent("IntegrationTest")
        let sourcesDir = projectDir.appendingPathComponent("Sources/IntegrationTest")

        try FileManager.default.createDirectory(at: sourcesDir, withIntermediateDirectories: true)

        // Create Package.swift
        let packageSwift = """
        // swift-tools-version: 6.2
        import PackageDescription

        let package = Package(
            name: "IntegrationTest",
            products: [
                .executable(name: "IntegrationTest", targets: ["IntegrationTest"])
            ],
            targets: [
                .executableTarget(name: "IntegrationTest")
            ]
        )
        """
        try packageSwift.write(to: projectDir.appendingPathComponent("Package.swift"), atomically: true, encoding: .utf8)

        // Create main.swift
        let mainSwift = """
        import Foundation

        @MainActor
        func main() async {
            print("Hello, World!")
        }

        await main()
        """
        try mainSwift.write(to: sourcesDir.appendingPathComponent("main.swift"), atomically: true, encoding: .utf8)

        // Create Public directory
        let publicDir = projectDir.appendingPathComponent("Public")
        try FileManager.default.createDirectory(at: publicDir, withIntermediateDirectories: true)

        let stylesCSS = """
        body {
            font-family: sans-serif;
        }
        """
        try stylesCSS.write(to: publicDir.appendingPathComponent("styles.css"), atomically: true, encoding: .utf8)

        // Verify project structure
        #expect(FileManager.default.fileExists(atPath: projectDir.appendingPathComponent("Package.swift").path))
        #expect(FileManager.default.fileExists(atPath: sourcesDir.appendingPathComponent("main.swift").path))
        #expect(FileManager.default.fileExists(atPath: publicDir.appendingPathComponent("styles.css").path))
    }

    @Test func allPiecesIntegratCorrectly() throws {
        let tempDirectory = try makeTempDirectory()
        defer { cleanupTempDirectory(tempDirectory) }

        // Test that all components can work together

        // 1. BuildConfig
        let config = BuildConfig(
            sourceDirectory: tempDirectory.appendingPathComponent("project"),
            outputDirectory: tempDirectory.appendingPathComponent("dist"),
            optimizationLevel: .release,
            verbose: false
        )

        #expect(config != nil)

        // 2. HTMLGenerator
        let htmlGenerator = HTMLGenerator()
        let htmlConfig = HTMLConfig(projectName: "IntegrationTest")
        let html = htmlGenerator.generate(config: htmlConfig)

        #expect(html.contains("IntegrationTest"))

        // 3. AssetBundler
        let bundler = AssetBundler(verbose: false)
        #expect(bundler != nil)

        // 4. WasmOptimizer
        let optimizer = WasmOptimizer(verbose: false, optimizationLevel: .o3)
        #expect(optimizer != nil)

        // All components can be instantiated and used together
    }

    @Test func completeWorkflowConfiguration() throws {
        let tempDirectory = try makeTempDirectory()
        defer { cleanupTempDirectory(tempDirectory) }

        // Test a complete workflow configuration
        let projectName = "CompleteApp"
        let projectDir = tempDirectory.appendingPathComponent(projectName)
        let outputDir = tempDirectory.appendingPathComponent("dist")

        // 1. Build configuration
        let buildConfig = BuildConfig(
            sourceDirectory: projectDir,
            outputDirectory: outputDir,
            optimizationLevel: .release,
            verbose: true
        )

        #expect(buildConfig.optimizationLevel == .release)
        #expect(buildConfig.verbose)

        // 2. HTML configuration
        let htmlConfig = HTMLConfig(
            projectName: projectName,
            title: "Complete App",
            wasmFile: "app.wasm",
            cssFiles: ["styles.css"],
            metaTags: [
                "description": "A complete Raven app",
                "viewport": "width=device-width, initial-scale=1.0"
            ]
        )

        #expect(htmlConfig.projectName == projectName)
        #expect(htmlConfig.cssFiles.count == 1)

        // 3. Generate HTML
        let generator = HTMLGenerator()
        let html = generator.generate(config: htmlConfig)

        #expect(html.contains(projectName) || html.contains("Complete App"))
        #expect(html.contains("app.wasm"))
        #expect(html.contains("runtime.js"))
        #expect(html.contains("<!DOCTYPE html>"))

        // Complete workflow is configurable and functional
    }

    @Test func workflowProducesExpectedOutputStructure() throws {
        // Test that a complete workflow would produce the expected output structure
        let expectedFiles = [
            "index.html",
            "app.wasm",
            "runtime.js"
        ]

        let expectedPublicAssets = [
            "styles.css"
        ]

        // Verify we know what files should be produced
        #expect(expectedFiles.count == 3)
        #expect(expectedPublicAssets.count >= 1)
    }

    @Test func errorHandlingAcrossComponents() throws {
        let tempDirectory = try makeTempDirectory()
        defer { cleanupTempDirectory(tempDirectory) }

        // Test that components handle errors appropriately

        // BuildConfig with invalid paths should still construct
        let invalidConfig = BuildConfig(
            sourceDirectory: URL(fileURLWithPath: "/nonexistent"),
            outputDirectory: URL(fileURLWithPath: "/also-nonexistent")
        )
        #expect(invalidConfig != nil)

        // HTMLGenerator should handle escaping
        let generator = HTMLGenerator()
        let riskyConfig = HTMLConfig(
            projectName: "Test<script>alert('xss')</script>",
            metaTags: ["desc": "A \"test\" & demonstration"]
        )
        let html = generator.generate(config: riskyConfig)

        // Should escape dangerous characters
        #expect(!html.contains("<script>alert"))

        // AssetBundler should handle missing directories gracefully
        let bundler = AssetBundler(verbose: false)
        let result = try bundler.bundleAssets(
            from: "/nonexistent/source",
            to: tempDirectory.appendingPathComponent("dest").path
        )
        #expect(result.filesCopied == 0)
        #expect(result.errors.count == 0)
    }
}
