import Testing
@testable import RavenCLI
import Foundation

@Suite struct HTMLGeneratorTests {
    let generator = HTMLGenerator()

    @Test func basicHTMLGeneration() {
        let config = HTMLConfig(projectName: "TestApp")
        let html = generator.generate(config: config)

        #expect(html.contains("<!DOCTYPE html>"))
        #expect(html.contains("<html lang=\"en\">"))
        #expect(html.contains("<meta charset=\"UTF-8\">"))
        #expect(html.contains("<meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">"))
        #expect(html.contains("<title>TestApp</title>"))
        #expect(html.contains("<div id=\"root\""))
    }

    @Test func customTitle() {
        let config = HTMLConfig(
            projectName: "TestApp",
            title: "My Custom App"
        )
        let html = generator.generate(config: config)

        #expect(html.contains("<title>My Custom App</title>"))
        #expect(!html.contains("<title>TestApp</title>"))
    }

    @Test func wasmFileInBootstrap() {
        let config = HTMLConfig(
            projectName: "TestApp",
            wasmFile: "custom.wasm"
        )
        let html = generator.generate(config: config)

        #expect(html.contains("custom.wasm"))
    }

    @Test func inlinedJSKitRuntime() {
        let config = HTMLConfig(
            projectName: "TestApp",
            javaScriptKitRuntimeSource: "// Fake JSKit Runtime\nvar JavaScriptKit = {};"
        )
        let html = generator.generate(config: config)

        // Should inline the runtime, not reference external file
        #expect(html.contains("// Fake JSKit Runtime"))
        #expect(!html.contains("src=\"runtime.js\""))
    }

    @Test func fallbackToExternalRuntime() {
        let config = HTMLConfig(
            projectName: "TestApp",
            javaScriptKitRuntimeSource: nil
        )
        let html = generator.generate(config: config)

        // Should fall back to external runtime.js
        #expect(html.contains("src=\"runtime.js\""))
    }

    @Test func cssFiles() {
        let config = HTMLConfig(
            projectName: "TestApp",
            cssFiles: ["styles.css", "theme.css", "custom.css"]
        )
        let html = generator.generate(config: config)

        #expect(html.contains("<link rel=\"stylesheet\" href=\"styles.css\">"))
        #expect(html.contains("<link rel=\"stylesheet\" href=\"theme.css\">"))
        #expect(html.contains("<link rel=\"stylesheet\" href=\"custom.css\">"))
    }

    @Test func metaTags() {
        let config = HTMLConfig(
            projectName: "TestApp",
            metaTags: [
                "description": "A test app",
                "author": "Test Author",
                "keywords": "swift, wasm, raven"
            ]
        )
        let html = generator.generate(config: config)

        #expect(html.contains("name=\"description\" content=\"A test app\""))
        #expect(html.contains("name=\"author\" content=\"Test Author\""))
        #expect(html.contains("name=\"keywords\" content=\"swift, wasm, raven\""))
    }

    @Test func customLanguage() {
        let config = HTMLConfig(
            projectName: "TestApp",
            language: "es"
        )
        let html = generator.generate(config: config)

        #expect(html.contains("<html lang=\"es\">"))
    }

    @Test func customMountElementID() {
        let config = HTMLConfig(
            projectName: "TestApp",
            mountElementID: "custom-root"
        )
        let html = generator.generate(config: config)

        #expect(html.contains("id=\"custom-root\""))
    }

    @Test func htmlEscaping() {
        let config = HTMLConfig(
            projectName: "Test<App>",
            title: "Test & \"Demo\" App",
            metaTags: [
                "description": "Contains <special> & \"chars\""
            ]
        )
        let html = generator.generate(config: config)

        // Should escape special characters in title
        #expect(html.contains("Test &amp; &quot;Demo&quot; App"))
        // Should escape special characters in meta tags
        #expect(html.contains("Contains &lt;special&gt; &amp; &quot;chars&quot;"))

        // Should NOT contain unescaped special characters in title
        #expect(!html.contains("Test & \"Demo\" App"))
    }

    @Test func htmlEscapingInProjectName() {
        let config = HTMLConfig(
            projectName: "Test<App>",
            metaTags: [:]
        )
        let html = generator.generate(config: config)

        // Project name should be escaped when used as title
        #expect(html.contains("Test&lt;App&gt;"))
        // Should NOT contain unescaped project name
        #expect(!html.contains("Test<App>"))
    }

    @Test func wasiPolyfillIncluded() {
        let config = HTMLConfig(projectName: "TestApp")
        let html = generator.generate(config: config)

        // Should include WASI polyfill
        #expect(html.contains("wasi_snapshot_preview1"))
        #expect(html.contains("fd_write"))
        // Should include WASM bootstrap
        #expect(html.contains("WebAssembly.instantiate"))
        #expect(html.contains("_start"))
    }

    @Test func ravenEventHelpers() {
        let config = HTMLConfig(projectName: "TestApp")
        let html = generator.generate(config: config)

        #expect(html.contains("__ravenAddEventListener"))
        #expect(html.contains("__ravenRemoveEventListener"))
    }

    @Test func loadingScreen() {
        let config = HTMLConfig(projectName: "TestApp")
        let html = generator.generate(config: config)

        #expect(html.contains("id=\"loading\""))
        #expect(html.contains("Loading TestApp..."))
    }

    @Test func fileWriting() throws {
        let config = HTMLConfig(projectName: "TestApp")
        let tempDir = FileManager.default.temporaryDirectory
        let testFile = tempDir.appendingPathComponent("test-\(UUID().uuidString).html")

        try generator.writeToFile(config: config, path: testFile.path)

        // Verify file exists
        #expect(FileManager.default.fileExists(atPath: testFile.path))

        // Read back and verify content
        let content = try String(contentsOf: testFile, encoding: .utf8)
        #expect(content.contains("<!DOCTYPE html>"))
        #expect(content.contains("<title>TestApp</title>"))

        // Clean up
        try? FileManager.default.removeItem(at: testFile)
    }

    @Test func fileWritingCreatesDirectory() throws {
        let tempDir = FileManager.default.temporaryDirectory
        let subDir = tempDir.appendingPathComponent("test-dir-\(UUID().uuidString)")
        let testFile = subDir.appendingPathComponent("index.html")

        let config = HTMLConfig(projectName: "TestApp")
        try generator.writeToFile(config: config, path: testFile.path)

        // Verify directory was created
        #expect(FileManager.default.fileExists(atPath: subDir.path))
        #expect(FileManager.default.fileExists(atPath: testFile.path))

        // Clean up
        try? FileManager.default.removeItem(at: subDir)
    }

    @Test func developmentModeIncludesHotReload() {
        let config = HTMLConfig(
            projectName: "TestApp",
            isDevelopment: true,
            hotReloadPort: 35729
        )
        let html = generator.generate(config: config)

        #expect(html.contains("EventSource"))
        #expect(html.contains("__ravenErrorOverlay"))
    }

    @Test func productionModeExcludesHotReload() {
        let config = HTMLConfig(
            projectName: "TestApp",
            isDevelopment: false
        )
        let html = generator.generate(config: config)

        #expect(!html.contains("EventSource"))
        #expect(!html.contains("__ravenErrorOverlay"))
    }
}
