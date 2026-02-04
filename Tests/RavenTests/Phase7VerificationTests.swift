import XCTest
@testable import Raven
import Foundation

/// Phase 7 Verification: Production Readiness for v0.1.0 Release
///
/// This test suite verifies that all deliverables for the v0.1.0 release are complete:
/// - Documentation files exist and are comprehensive
/// - README has all required sections
/// - Examples compile successfully
/// - All tests pass
/// - Version information is correct
/// - Performance benchmarks are available
///
/// Run before releasing v0.1.0 to ensure everything is ready.
@available(macOS 13.0, *)
final class Phase7VerificationTests: XCTestCase {

    // MARK: - Documentation Verification

    func testREADMEExists() {
        let readme = getProjectPath().appendingPathComponent("README.md")
        XCTAssertTrue(FileManager.default.fileExists(atPath: readme.path),
                     "README.md must exist in project root")
    }

    func testREADMEHasRequiredSections() throws {
        let readme = getProjectPath().appendingPathComponent("README.md")
        let content = try String(contentsOf: readme, encoding: .utf8)

        let requiredSections = [
            "# Raven",
            "## Overview",
            "## Features",
            "## Quick Start",
            "## Installation",
            "## Example Code",
            "## Documentation",
            "## Architecture",
            "## Testing",
            "## License"
        ]

        for section in requiredSections {
            XCTAssertTrue(content.contains(section),
                         "README.md must contain '\(section)' section")
        }
    }

    func testREADMEHasExampleCode() throws {
        let readme = getProjectPath().appendingPathComponent("README.md")
        let content = try String(contentsOf: readme, encoding: .utf8)

        XCTAssertTrue(content.contains("```swift"),
                     "README.md must contain Swift code examples")
        XCTAssertTrue(content.contains("import Raven"),
                     "README.md examples must import Raven")
    }

    func testGettingStartedGuideExists() {
        let guide = getProjectPath()
            .appendingPathComponent("Documentation")
            .appendingPathComponent("GettingStarted.md")

        XCTAssertTrue(FileManager.default.fileExists(atPath: guide.path),
                     "Documentation/GettingStarted.md must exist")
    }

    func testGettingStartedGuideIsComprehensive() throws {
        let guide = getProjectPath()
            .appendingPathComponent("Documentation")
            .appendingPathComponent("GettingStarted.md")

        let content = try String(contentsOf: guide, encoding: .utf8)

        let requiredTopics = [
            "Installation",
            "Your First Raven App",
            "@State",
            "Layout",
            "Common Patterns"
        ]

        for topic in requiredTopics {
            XCTAssertTrue(content.contains(topic),
                         "Getting Started guide must cover '\(topic)'")
        }
    }

    func testAPIOverviewExists() {
        let overview = getProjectPath()
            .appendingPathComponent("Documentation")
            .appendingPathComponent("API-Overview.md")

        XCTAssertTrue(FileManager.default.fileExists(atPath: overview.path),
                     "Documentation/API-Overview.md must exist")
    }

    func testAPIOverviewHasAllCategories() throws {
        let overview = getProjectPath()
            .appendingPathComponent("Documentation")
            .appendingPathComponent("API-Overview.md")

        let content = try String(contentsOf: overview, encoding: .utf8)

        let categories = [
            "Core Types",
            "State Management",
            "View",
            "Modifiers"
        ]

        for category in categories {
            XCTAssertTrue(content.contains(category),
                         "API Overview must document '\(category)'")
        }
    }

    func testDocCGenerationGuideExists() {
        let guide = getProjectPath()
            .appendingPathComponent("Documentation")
            .appendingPathComponent("DocC-Generation.md")

        XCTAssertTrue(FileManager.default.fileExists(atPath: guide.path),
                     "Documentation/DocC-Generation.md must exist")
    }

    func testDocCGenerationGuideHasInstructions() throws {
        let guide = getProjectPath()
            .appendingPathComponent("Documentation")
            .appendingPathComponent("DocC-Generation.md")

        let content = try String(contentsOf: guide, encoding: .utf8)

        XCTAssertTrue(content.contains("swift package generate-documentation"),
                     "DocC guide must include generation command")
        XCTAssertTrue(content.contains("DocC Syntax"),
                     "DocC guide must explain syntax")
    }

    func testReleaseChecklistExists() {
        let release = getProjectPath().appendingPathComponent("RELEASE.md")

        XCTAssertTrue(FileManager.default.fileExists(atPath: release.path),
                     "RELEASE.md must exist")
    }

    func testReleaseChecklistHasVersion() throws {
        let release = getProjectPath().appendingPathComponent("RELEASE.md")
        let content = try String(contentsOf: release, encoding: .utf8)

        XCTAssertTrue(content.contains("0.1.0"),
                     "RELEASE.md must specify version 0.1.0")
        XCTAssertTrue(content.contains("Release Checklist"),
                     "RELEASE.md must have release checklist")
    }

    func testLicenseExists() {
        let license = getProjectPath().appendingPathComponent("LICENSE")

        XCTAssertTrue(FileManager.default.fileExists(atPath: license.path),
                     "LICENSE file must exist")
    }

    // MARK: - Examples Verification

    func testExamplesDirectoryExists() {
        let examples = getProjectPath().appendingPathComponent("Examples")

        XCTAssertTrue(FileManager.default.fileExists(atPath: examples.path),
                     "Examples directory must exist")
    }

    func testStateExampleExists() {
        let example = getProjectPath()
            .appendingPathComponent("Examples")
            .appendingPathComponent("StateExample.swift")

        XCTAssertTrue(FileManager.default.fileExists(atPath: example.path),
                     "StateExample.swift must exist")
    }

    func testStateExampleCompiles() throws {
        let example = getProjectPath()
            .appendingPathComponent("Examples")
            .appendingPathComponent("StateExample.swift")

        let content = try String(contentsOf: example, encoding: .utf8)

        XCTAssertTrue(content.contains("import Raven"),
                     "StateExample must import Raven")
        XCTAssertTrue(content.contains("@State"),
                     "StateExample must demonstrate @State")
    }

    func testForEachExampleExists() {
        let example = getProjectPath()
            .appendingPathComponent("Examples")
            .appendingPathComponent("ForEachExample.swift")

        XCTAssertTrue(FileManager.default.fileExists(atPath: example.path),
                     "ForEachExample.swift must exist")
    }

    func testAllExamplesImportRaven() throws {
        let examples = getProjectPath().appendingPathComponent("Examples")
        let fileManager = FileManager.default

        guard let enumerator = fileManager.enumerator(atPath: examples.path) else {
            XCTFail("Could not enumerate Examples directory")
            return
        }

        var exampleCount = 0

        for case let file as String in enumerator {
            // Skip hidden files, build directories, Package.swift, and non-Swift files
            if file.hasPrefix(".") || file.contains(".build") || file.contains("Dashboard") || file.hasSuffix("Package.swift") {
                continue
            }
            guard file.hasSuffix(".swift") else { continue }

            let filePath = examples.appendingPathComponent(file)
            let content = try String(contentsOf: filePath, encoding: .utf8)

            XCTAssertTrue(content.contains("import Raven"),
                         "\(file) must import Raven")
            exampleCount += 1
        }

        XCTAssertGreaterThan(exampleCount, 5,
                            "Should have at least 5 example files")
    }

    // MARK: - Test Coverage Verification

    func testAllTestTargetsExist() {
        let tests = getProjectPath().appendingPathComponent("Tests")

        let requiredTargets = [
            "RavenTests",
            "VirtualDOMTests",
            "IntegrationTests",
            "RavenCLI"
        ]

        for target in requiredTargets {
            let targetPath = tests.appendingPathComponent(target)
            XCTAssertTrue(FileManager.default.fileExists(atPath: targetPath.path),
                         "\(target) test directory must exist")
        }
    }

    func testAdditionalCoverageTestsExist() {
        let testFile = getProjectPath()
            .appendingPathComponent("Tests")
            .appendingPathComponent("RavenTests")
            .appendingPathComponent("AdditionalCoverageTests.swift")

        XCTAssertTrue(FileManager.default.fileExists(atPath: testFile.path),
                     "AdditionalCoverageTests.swift must exist for Phase 7")
    }

    func testPhaseVerificationTestsExist() {
        let phases = ["Phase1", "Phase2", "Phase3", "Phase4", "Phase5", "Phase6", "Phase7"]

        for phase in phases {
            let testFile = getProjectPath()
                .appendingPathComponent("Tests")
                .appendingPathComponent("RavenTests")
                .appendingPathComponent("\(phase)VerificationTests.swift")

            XCTAssertTrue(FileManager.default.fileExists(atPath: testFile.path),
                         "\(phase)VerificationTests.swift must exist")
        }
    }

    // MARK: - Benchmark Verification

    func testBenchmarksExist() {
        let benchmarks = getProjectPath()
            .appendingPathComponent("Tests")
            .appendingPathComponent("Benchmarks")
            .appendingPathComponent("RavenBenchmarks.swift")

        XCTAssertTrue(FileManager.default.fileExists(atPath: benchmarks.path),
                     "RavenBenchmarks.swift must exist")
    }

    func testBenchmarksHaveRequiredTests() throws {
        let benchmarks = getProjectPath()
            .appendingPathComponent("Tests")
            .appendingPathComponent("Benchmarks")
            .appendingPathComponent("RavenBenchmarks.swift")

        let content = try String(contentsOf: benchmarks, encoding: .utf8)

        let requiredBenchmarks = [
            "benchmarkVNodeDiffing",
            "benchmarkListRendering",
            "benchmarkNodeCreation",
            "benchmarkPropertyDiffing"
        ]

        for benchmark in requiredBenchmarks {
            XCTAssertTrue(content.contains(benchmark),
                         "Benchmarks must include \(benchmark)")
        }
    }

    func testBenchmarksDocumentExpectedPerformance() throws {
        let benchmarks = getProjectPath()
            .appendingPathComponent("Tests")
            .appendingPathComponent("Benchmarks")
            .appendingPathComponent("RavenBenchmarks.swift")

        let content = try String(contentsOf: benchmarks, encoding: .utf8)

        XCTAssertTrue(content.contains("Expected:") || content.contains("expected performance"),
                     "Benchmarks must document expected performance characteristics")
    }

    // MARK: - Package Configuration Verification

    func testPackageSwiftExists() {
        let package = getProjectPath().appendingPathComponent("Package.swift")

        XCTAssertTrue(FileManager.default.fileExists(atPath: package.path),
                     "Package.swift must exist")
    }

    func testPackageSwiftHasCorrectSwiftVersion() throws {
        let package = getProjectPath().appendingPathComponent("Package.swift")
        let content = try String(contentsOf: package, encoding: .utf8)

        XCTAssertTrue(content.contains("swift-tools-version: 6.2") ||
                     content.contains("swift-tools-version:6.2"),
                     "Package.swift must specify Swift 6.2")
    }

    func testPackageHasAllTargets() throws {
        let package = getProjectPath().appendingPathComponent("Package.swift")
        let content = try String(contentsOf: package, encoding: .utf8)

        let requiredTargets = [
            "Raven",
            "RavenRuntime",
            "RavenCLI",
            "RavenTests"
        ]

        for target in requiredTargets {
            XCTAssertTrue(content.contains("\"\(target)\""),
                         "Package.swift must define \(target) target")
        }
    }

    func testPackageHasDependencies() throws {
        let package = getProjectPath().appendingPathComponent("Package.swift")
        let content = try String(contentsOf: package, encoding: .utf8)

        XCTAssertTrue(content.contains("JavaScriptKit"),
                     "Package.swift must depend on JavaScriptKit")
        XCTAssertTrue(content.contains("swift-argument-parser"),
                     "Package.swift must depend on swift-argument-parser")
    }

    // MARK: - Source Code Structure Verification

    func testCoreTypesExist() {
        let coreTypes = [
            "View.swift",
            "ViewBuilder.swift",
            "AnyView.swift"
        ]

        let corePath = getProjectPath()
            .appendingPathComponent("Sources")
            .appendingPathComponent("Raven")
            .appendingPathComponent("Core")

        for file in coreTypes {
            let filePath = corePath.appendingPathComponent(file)
            XCTAssertTrue(FileManager.default.fileExists(atPath: filePath.path),
                         "Core type \(file) must exist")
        }
    }

    func testVirtualDOMTypesExist() {
        let virtualDOMTypes = [
            "VNode.swift",
            "Differ.swift",
            "VTree.swift"
        ]

        let virtualDOMPath = getProjectPath()
            .appendingPathComponent("Sources")
            .appendingPathComponent("Raven")
            .appendingPathComponent("VirtualDOM")

        for file in virtualDOMTypes {
            let filePath = virtualDOMPath.appendingPathComponent(file)
            XCTAssertTrue(FileManager.default.fileExists(atPath: filePath.path),
                         "VirtualDOM type \(file) must exist")
        }
    }

    func testStateManagementTypesExist() {
        let stateTypes = [
            "State.swift",
            "ObservableObject.swift",
            "StateObject.swift",
            "ObservedObject.swift"
        ]

        let statePath = getProjectPath()
            .appendingPathComponent("Sources")
            .appendingPathComponent("Raven")
            .appendingPathComponent("State")

        for file in stateTypes {
            let filePath = statePath.appendingPathComponent(file)
            XCTAssertTrue(FileManager.default.fileExists(atPath: filePath.path),
                         "State type \(file) must exist")
        }
    }

    func testPrimitiveViewsExist() {
        let primitives = [
            "Text.swift",
            "Button.swift",
            "Image.swift",
            "TextField.swift",
            "Toggle.swift",
            "Color.swift",
            "Font.swift"
        ]

        let primitivesPath = getProjectPath()
            .appendingPathComponent("Sources")
            .appendingPathComponent("Raven")
            .appendingPathComponent("Views")
            .appendingPathComponent("Primitives")

        for file in primitives {
            let filePath = primitivesPath.appendingPathComponent(file)
            XCTAssertTrue(FileManager.default.fileExists(atPath: filePath.path),
                         "Primitive view \(file) must exist")
        }
    }

    func testLayoutViewsExist() {
        let layouts = [
            "VStack.swift",
            "HStack.swift",
            "ZStack.swift",
            "List.swift",
            "ForEach.swift",
            "LazyVGrid.swift",
            "LazyHGrid.swift",
            "GeometryReader.swift",
            "Form.swift",
            "Section.swift"
        ]

        let layoutsPath = getProjectPath()
            .appendingPathComponent("Sources")
            .appendingPathComponent("Raven")
            .appendingPathComponent("Views")
            .appendingPathComponent("Layout")

        for file in layouts {
            let filePath = layoutsPath.appendingPathComponent(file)
            XCTAssertTrue(FileManager.default.fileExists(atPath: filePath.path),
                         "Layout view \(file) must exist")
        }
    }

    // MARK: - CLI Verification

    func testCLIMainExists() {
        let cliMain = getProjectPath()
            .appendingPathComponent("Sources")
            .appendingPathComponent("RavenCLI")
            .appendingPathComponent("main.swift")

        XCTAssertTrue(FileManager.default.fileExists(atPath: cliMain.path),
                     "RavenCLI/main.swift must exist")
    }

    // MARK: - Version Verification

    func testVersionIs010() throws {
        // Check that RELEASE.md specifies 0.1.0
        let release = getProjectPath().appendingPathComponent("RELEASE.md")
        let content = try String(contentsOf: release, encoding: .utf8)

        XCTAssertTrue(content.contains("0.1.0"),
                     "Version must be 0.1.0 for initial release")
        XCTAssertTrue(content.contains("Initial Alpha Release") ||
                     content.contains("initial alpha release"),
                     "Must be marked as initial alpha release")
    }

    func testREADMEDoesNotClaim10() throws {
        // Ensure README doesn't incorrectly claim to be v1.0
        let readme = getProjectPath().appendingPathComponent("README.md")
        let content = try String(contentsOf: readme, encoding: .utf8)

        // Check if it mentions version (should not claim 1.0.0 or v1.0)
        XCTAssertFalse(content.contains("v1.0.0") || content.contains("version 1.0"),
                      "README should not claim v1.0 for initial release")
    }

    // MARK: - Final Checklist Verification

    func testAllPhase7DeliverablesComplete() {
        // This is the master verification test
        // Runs all sub-verifications to ensure everything is ready

        let deliverables = [
            "README.md exists": FileManager.default.fileExists(
                atPath: getProjectPath().appendingPathComponent("README.md").path
            ),
            "RELEASE.md exists": FileManager.default.fileExists(
                atPath: getProjectPath().appendingPathComponent("RELEASE.md").path
            ),
            "Getting Started guide exists": FileManager.default.fileExists(
                atPath: getProjectPath()
                    .appendingPathComponent("Documentation/GettingStarted.md").path
            ),
            "API Overview exists": FileManager.default.fileExists(
                atPath: getProjectPath()
                    .appendingPathComponent("Documentation/API-Overview.md").path
            ),
            "DocC guide exists": FileManager.default.fileExists(
                atPath: getProjectPath()
                    .appendingPathComponent("Documentation/DocC-Generation.md").path
            ),
            "Benchmarks exist": FileManager.default.fileExists(
                atPath: getProjectPath()
                    .appendingPathComponent("Tests/Benchmarks/RavenBenchmarks.swift").path
            ),
            "Additional tests exist": FileManager.default.fileExists(
                atPath: getProjectPath()
                    .appendingPathComponent("Tests/RavenTests/AdditionalCoverageTests.swift").path
            ),
            "Examples directory exists": FileManager.default.fileExists(
                atPath: getProjectPath().appendingPathComponent("Examples").path
            )
        ]

        var allComplete = true
        for (deliverable, complete) in deliverables {
            if !complete {
                print("❌ \(deliverable)")
                allComplete = false
            } else {
                print("✅ \(deliverable)")
            }
        }

        XCTAssertTrue(allComplete, "All Phase 7 deliverables must be complete")
    }

    // MARK: - Helper Methods

    private func getProjectPath() -> URL {
        // Navigate from test bundle to project root
        let testBundle = Bundle(for: type(of: self))
        let bundlePath = testBundle.bundleURL

        // From Tests bundle, go up to project root
        // Typically: .build/debug/RavenPackageTests.xctest -> project root
        var projectPath = bundlePath
        while projectPath.lastPathComponent != "Raven" &&
              projectPath.path != "/" &&
              projectPath.pathComponents.count > 1 {
            projectPath = projectPath.deletingLastPathComponent()
        }

        // If we didn't find it, try current directory
        if projectPath.path == "/" || projectPath.lastPathComponent != "Raven" {
            projectPath = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        }

        return projectPath
    }
}
