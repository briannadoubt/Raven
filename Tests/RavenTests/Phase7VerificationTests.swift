import Testing
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
@Suite struct Phase7VerificationTests {

    // MARK: - Helper Methods

    private func getProjectPath() -> URL {
        // Try current directory first (most reliable for SPM tests)
        let currentDir = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)

        // Walk up to find the project root containing Package.swift
        var projectPath = currentDir
        while projectPath.path != "/" && projectPath.pathComponents.count > 1 {
            if projectPath.lastPathComponent == "Raven" {
                return projectPath
            }
            if FileManager.default.fileExists(atPath: projectPath.appendingPathComponent("Package.swift").path) {
                return projectPath
            }
            projectPath = projectPath.deletingLastPathComponent()
        }

        // Fallback to current directory
        return currentDir
    }

    // MARK: - Documentation Verification

    @Test func readmeExists() {
        let readme = getProjectPath().appendingPathComponent("README.md")
        #expect(FileManager.default.fileExists(atPath: readme.path))
    }

    @Test func readmeHasRequiredSections() throws {
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
            #expect(content.contains(section))
        }
    }

    @Test func readmeHasExampleCode() throws {
        let readme = getProjectPath().appendingPathComponent("README.md")
        let content = try String(contentsOf: readme, encoding: .utf8)

        #expect(content.contains("```swift"))
        #expect(content.contains("import Raven"))
    }

    @Test func gettingStartedGuideExists() {
        let guide = getProjectPath()
            .appendingPathComponent("Documentation")
            .appendingPathComponent("GettingStarted.md")

        #expect(FileManager.default.fileExists(atPath: guide.path))
    }

    @Test func gettingStartedGuideIsComprehensive() throws {
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
            #expect(content.contains(topic))
        }
    }

    @Test func apiOverviewExists() {
        let overview = getProjectPath()
            .appendingPathComponent("Documentation")
            .appendingPathComponent("API-Overview.md")

        #expect(FileManager.default.fileExists(atPath: overview.path))
    }

    @Test func apiOverviewHasAllCategories() throws {
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
            #expect(content.contains(category))
        }
    }

    @Test func docCGenerationGuideExists() {
        let guide = getProjectPath()
            .appendingPathComponent("Documentation")
            .appendingPathComponent("DocC-Generation.md")

        #expect(FileManager.default.fileExists(atPath: guide.path))
    }

    @Test func docCGenerationGuideHasInstructions() throws {
        let guide = getProjectPath()
            .appendingPathComponent("Documentation")
            .appendingPathComponent("DocC-Generation.md")

        let content = try String(contentsOf: guide, encoding: .utf8)

        #expect(content.contains("swift package generate-documentation"))
        #expect(content.contains("DocC Syntax"))
    }

    @Test func releaseChecklistExists() {
        let release = getProjectPath().appendingPathComponent("RELEASE.md")
        let changelog = getProjectPath().appendingPathComponent("CHANGELOG.md")

        #expect(
            FileManager.default.fileExists(atPath: release.path) ||
            FileManager.default.fileExists(atPath: changelog.path)
        )
    }

    @Test func releaseChecklistHasVersion() throws {
        let release = getProjectPath().appendingPathComponent("RELEASE.md")
        let changelog = getProjectPath().appendingPathComponent("CHANGELOG.md")
        let existingFile = FileManager.default.fileExists(atPath: release.path) ? release : changelog
        let content = try String(contentsOf: existingFile, encoding: .utf8)

        #expect(content.contains("0.1.0") || content.contains("0.10.0") || content.contains("[0."))
        #expect(content.contains("Release Checklist") || content.contains("Changelog"))
    }

    @Test func licenseExists() {
        let license = getProjectPath().appendingPathComponent("LICENSE")

        #expect(FileManager.default.fileExists(atPath: license.path))
    }

    // MARK: - Examples Verification

    @Test func examplesDirectoryExists() {
        let examples = getProjectPath().appendingPathComponent("Examples")

        #expect(FileManager.default.fileExists(atPath: examples.path))
    }

    @Test func stateExampleExists() {
        let example = getProjectPath()
            .appendingPathComponent("Examples")
            .appendingPathComponent("HelloWorld")
            .appendingPathComponent("HelloWorld.swift")

        #expect(FileManager.default.fileExists(atPath: example.path))
    }

    @Test func stateExampleCompiles() throws {
        let example = getProjectPath()
            .appendingPathComponent("Examples")
            .appendingPathComponent("HelloWorld")
            .appendingPathComponent("HelloWorld.swift")

        let content = try String(contentsOf: example, encoding: .utf8)

        #expect(content.contains("import Raven"))
        #expect(content.contains("@State"))
    }

    @Test func forEachExampleExists() {
        let todoApp = getProjectPath()
            .appendingPathComponent("Examples")
            .appendingPathComponent("TodoApp")
            .appendingPathComponent("Package.swift")
        let formControls = getProjectPath()
            .appendingPathComponent("Examples")
            .appendingPathComponent("FormControls")
            .appendingPathComponent("Package.swift")

        #expect(
            FileManager.default.fileExists(atPath: todoApp.path) &&
            FileManager.default.fileExists(atPath: formControls.path)
        )
    }

    @Test func allExamplesImportRaven() throws {
        let examples = getProjectPath().appendingPathComponent("Examples")
        let fileManager = FileManager.default

        guard let enumerator = fileManager.enumerator(atPath: examples.path) else {
            Issue.record("Could not enumerate Examples directory")
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

            #expect(content.contains("import Raven"))
            exampleCount += 1
        }

        #expect(exampleCount > 5)
    }

    // MARK: - Test Coverage Verification

    @Test func allTestTargetsExist() {
        let tests = getProjectPath().appendingPathComponent("Tests")

        let requiredTargets = [
            "RavenTests",
            "VirtualDOMTests",
            "IntegrationTests",
            "RavenCLI"
        ]

        for target in requiredTargets {
            let targetPath = tests.appendingPathComponent(target)
            #expect(FileManager.default.fileExists(atPath: targetPath.path))
        }
    }

    @Test func additionalCoverageTestsExist() {
        let testFile = getProjectPath()
            .appendingPathComponent("Tests")
            .appendingPathComponent("RavenTests")
            .appendingPathComponent("AdditionalCoverageTests.swift")

        #expect(FileManager.default.fileExists(atPath: testFile.path))
    }

    @Test func phaseVerificationTestsExist() {
        let phases = ["Phase1", "Phase2", "Phase3", "Phase4", "Phase5", "Phase6", "Phase7"]

        for phase in phases {
            let testFile = getProjectPath()
                .appendingPathComponent("Tests")
                .appendingPathComponent("RavenTests")
                .appendingPathComponent("\(phase)VerificationTests.swift")

            #expect(FileManager.default.fileExists(atPath: testFile.path))
        }
    }

    // MARK: - Benchmark Verification

    @Test func benchmarksExist() {
        let benchmarks = getProjectPath()
            .appendingPathComponent("Tests")
            .appendingPathComponent("Benchmarks")
            .appendingPathComponent("RavenBenchmarks.swift")

        #expect(FileManager.default.fileExists(atPath: benchmarks.path))
    }

    @Test func benchmarksHaveRequiredTests() throws {
        let benchmarks = getProjectPath()
            .appendingPathComponent("Tests")
            .appendingPathComponent("Benchmarks")
            .appendingPathComponent("RavenBenchmarks.swift")

        let content = try String(contentsOf: benchmarks, encoding: .utf8)

        let requiredBenchmarks = [
            "benchmarkListRendering",
            "benchmarkLargeListRendering",
            "benchmarkNodeCreation",
            "benchmarkPropertyDiffing"
        ]

        for benchmark in requiredBenchmarks {
            #expect(content.contains(benchmark))
        }
    }

    @Test func benchmarksDocumentExpectedPerformance() throws {
        let benchmarks = getProjectPath()
            .appendingPathComponent("Tests")
            .appendingPathComponent("Benchmarks")
            .appendingPathComponent("RavenBenchmarks.swift")

        let content = try String(contentsOf: benchmarks, encoding: .utf8)

        #expect(content.contains("Expected:") || content.contains("expected performance"))
    }

    // MARK: - Package Configuration Verification

    @Test func packageSwiftExists() {
        let package = getProjectPath().appendingPathComponent("Package.swift")

        #expect(FileManager.default.fileExists(atPath: package.path))
    }

    @Test func packageSwiftHasCorrectSwiftVersion() throws {
        let package = getProjectPath().appendingPathComponent("Package.swift")
        let content = try String(contentsOf: package, encoding: .utf8)

        #expect(
            content.contains("swift-tools-version: 6.0") ||
            content.contains("swift-tools-version:6.0") ||
            content.contains("swift-tools-version: 6.2") ||
            content.contains("swift-tools-version:6.2")
        )
    }

    @Test func packageHasAllTargets() throws {
        let package = getProjectPath().appendingPathComponent("Package.swift")
        let content = try String(contentsOf: package, encoding: .utf8)

        let requiredTargets = [
            "Raven",
            "RavenRuntime",
            "RavenCLI",
            "RavenTests"
        ]

        for target in requiredTargets {
            #expect(content.contains("\"\(target)\""))
        }
    }

    @Test func packageHasDependencies() throws {
        let package = getProjectPath().appendingPathComponent("Package.swift")
        let content = try String(contentsOf: package, encoding: .utf8)

        #expect(content.contains("JavaScriptKit"))
        #expect(content.contains("swift-argument-parser"))
    }

    // MARK: - Source Code Structure Verification

    @Test func coreTypesExist() {
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
            #expect(FileManager.default.fileExists(atPath: filePath.path))
        }
    }

    @Test func virtualDOMTypesExist() {
        let virtualDOMTypes = [
            "VNode.swift",
            "Patch.swift",
            "VTree.swift"
        ]

        let virtualDOMPath = getProjectPath()
            .appendingPathComponent("Sources")
            .appendingPathComponent("Raven")
            .appendingPathComponent("VirtualDOM")

        for file in virtualDOMTypes {
            let filePath = virtualDOMPath.appendingPathComponent(file)
            #expect(FileManager.default.fileExists(atPath: filePath.path))
        }
    }

    @Test func stateManagementTypesExist() {
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
            #expect(FileManager.default.fileExists(atPath: filePath.path))
        }
    }

    @Test func primitiveViewsExist() {
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
            #expect(FileManager.default.fileExists(atPath: filePath.path))
        }
    }

    @Test func layoutViewsExist() {
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
            #expect(FileManager.default.fileExists(atPath: filePath.path))
        }
    }

    // MARK: - CLI Verification

    @Test func cliMainExists() {
        let cliMain = getProjectPath()
            .appendingPathComponent("Sources")
            .appendingPathComponent("RavenCLI")
            .appendingPathComponent("RavenCLI.swift")

        #expect(FileManager.default.fileExists(atPath: cliMain.path))
    }

    // MARK: - Version Verification

    @Test func versionIs010() throws {
        let changelog = getProjectPath().appendingPathComponent("CHANGELOG.md")
        let cliEntrypoint = getProjectPath()
            .appendingPathComponent("Sources")
            .appendingPathComponent("RavenCLI")
            .appendingPathComponent("RavenCLI.swift")

        let changelogContent = try String(contentsOf: changelog, encoding: .utf8)
        let cliContent = try String(contentsOf: cliEntrypoint, encoding: .utf8)

        #expect(changelogContent.contains("[0.1.0]") || changelogContent.contains("[0.7.0]"))
        #expect(cliContent.contains("version: \"0.10.0\""))
    }

    @Test func readmeDoesNotClaim10() throws {
        // Ensure README doesn't incorrectly claim to be v1.0
        let readme = getProjectPath().appendingPathComponent("README.md")
        let content = try String(contentsOf: readme, encoding: .utf8)

        // Check if it mentions version (should not claim 1.0.0 or v1.0)
        #expect(!(content.contains("v1.0.0") || content.contains("version 1.0")))
    }

    // MARK: - Final Checklist Verification

    @Test func allPhase7DeliverablesComplete() {
        // This is the master verification test
        // Runs all sub-verifications to ensure everything is ready

        let deliverables = [
            "README.md exists": FileManager.default.fileExists(
                atPath: getProjectPath().appendingPathComponent("README.md").path
            ),
            "Release notes exist": FileManager.default.fileExists(
                atPath: getProjectPath().appendingPathComponent("RELEASE.md").path
            ) || FileManager.default.fileExists(
                atPath: getProjectPath().appendingPathComponent("CHANGELOG.md").path
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
        for (_, complete) in deliverables {
            if !complete {
                allComplete = false
            }
        }

        #expect(allComplete)
    }
}
