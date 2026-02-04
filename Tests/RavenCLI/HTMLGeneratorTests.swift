import XCTest
@testable import RavenCLI

final class HTMLGeneratorTests: XCTestCase {
    var generator: HTMLGenerator!

    override func setUp() {
        super.setUp()
        generator = HTMLGenerator()
    }

    func testBasicHTMLGeneration() {
        let config = HTMLConfig(projectName: "TestApp")
        let html = generator.generate(config: config)

        XCTAssertTrue(html.contains("<!DOCTYPE html>"))
        XCTAssertTrue(html.contains("<html lang=\"en\">"))
        XCTAssertTrue(html.contains("<meta charset=\"UTF-8\">"))
        XCTAssertTrue(html.contains("<meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">"))
        XCTAssertTrue(html.contains("<title>TestApp</title>"))
        XCTAssertTrue(html.contains("<div id=\"app\"></div>"))
    }

    func testCustomTitle() {
        let config = HTMLConfig(
            projectName: "TestApp",
            title: "My Custom App"
        )
        let html = generator.generate(config: config)

        XCTAssertTrue(html.contains("<title>My Custom App</title>"))
        XCTAssertFalse(html.contains("<title>TestApp</title>"))
    }

    func testWASMAndRuntimeInclusion() {
        let config = HTMLConfig(
            projectName: "TestApp",
            wasmFile: "custom.wasm",
            runtimeJSFile: "custom-runtime.js"
        )
        let html = generator.generate(config: config)

        XCTAssertTrue(html.contains("src=\"custom-runtime.js\""))
        XCTAssertTrue(html.contains("from './custom.wasm'"))
    }

    func testCSSFiles() {
        let config = HTMLConfig(
            projectName: "TestApp",
            cssFiles: ["styles.css", "theme.css", "custom.css"]
        )
        let html = generator.generate(config: config)

        XCTAssertTrue(html.contains("<link rel=\"stylesheet\" href=\"styles.css\">"))
        XCTAssertTrue(html.contains("<link rel=\"stylesheet\" href=\"theme.css\">"))
        XCTAssertTrue(html.contains("<link rel=\"stylesheet\" href=\"custom.css\">"))
    }

    func testMetaTags() {
        let config = HTMLConfig(
            projectName: "TestApp",
            metaTags: [
                "description": "A test app",
                "author": "Test Author",
                "keywords": "swift, wasm, raven"
            ]
        )
        let html = generator.generate(config: config)

        XCTAssertTrue(html.contains("name=\"description\" content=\"A test app\""))
        XCTAssertTrue(html.contains("name=\"author\" content=\"Test Author\""))
        XCTAssertTrue(html.contains("name=\"keywords\" content=\"swift, wasm, raven\""))
    }

    func testCustomLanguage() {
        let config = HTMLConfig(
            projectName: "TestApp",
            language: "es"
        )
        let html = generator.generate(config: config)

        XCTAssertTrue(html.contains("<html lang=\"es\">"))
    }

    func testCustomMountElementID() {
        let config = HTMLConfig(
            projectName: "TestApp",
            mountElementID: "root"
        )
        let html = generator.generate(config: config)

        XCTAssertTrue(html.contains("<div id=\"root\"></div>"))
    }

    func testHTMLEscaping() {
        let config = HTMLConfig(
            projectName: "Test<App>",
            title: "Test & \"Demo\" App",
            metaTags: [
                "description": "Contains <special> & \"chars\""
            ]
        )
        let html = generator.generate(config: config)

        // Should escape special characters in title
        XCTAssertTrue(html.contains("Test &amp; &quot;Demo&quot; App"))
        // Should escape special characters in meta tags
        XCTAssertTrue(html.contains("Contains &lt;special&gt; &amp; &quot;chars&quot;"))

        // Should NOT contain unescaped special characters in title
        XCTAssertFalse(html.contains("Test & \"Demo\" App"))
    }

    func testHTMLEscapingInProjectName() {
        // Test escaping when project name is used as title
        let config = HTMLConfig(
            projectName: "Test<App>",
            metaTags: [:]
        )
        let html = generator.generate(config: config)

        // Project name should be escaped when used as title
        XCTAssertTrue(html.contains("Test&lt;App&gt;"))
        // Should NOT contain unescaped project name
        XCTAssertFalse(html.contains("Test<App>"))
    }

    func testScriptInclusion() {
        let config = HTMLConfig(projectName: "TestApp")
        let html = generator.generate(config: config)

        // Should include runtime script with defer
        XCTAssertTrue(html.contains("<script src=\"runtime.js\" defer></script>"))

        // Should include module script with init
        XCTAssertTrue(html.contains("<script type=\"module\">"))
        XCTAssertTrue(html.contains("import init from"))
        XCTAssertTrue(html.contains("await init();"))
        XCTAssertTrue(html.contains("console.log('Raven app initialized successfully');"))
    }

    func testFileWriting() throws {
        let config = HTMLConfig(projectName: "TestApp")
        let tempDir = FileManager.default.temporaryDirectory
        let testFile = tempDir.appendingPathComponent("test-\(UUID().uuidString).html")

        try generator.writeToFile(config: config, path: testFile.path)

        // Verify file exists
        XCTAssertTrue(FileManager.default.fileExists(atPath: testFile.path))

        // Read back and verify content
        let content = try String(contentsOf: testFile, encoding: .utf8)
        XCTAssertTrue(content.contains("<!DOCTYPE html>"))
        XCTAssertTrue(content.contains("<title>TestApp</title>"))

        // Clean up
        try? FileManager.default.removeItem(at: testFile)
    }

    func testFileWritingCreatesDirectory() throws {
        let tempDir = FileManager.default.temporaryDirectory
        let subDir = tempDir.appendingPathComponent("test-dir-\(UUID().uuidString)")
        let testFile = subDir.appendingPathComponent("index.html")

        let config = HTMLConfig(projectName: "TestApp")
        try generator.writeToFile(config: config, path: testFile.path)

        // Verify directory was created
        XCTAssertTrue(FileManager.default.fileExists(atPath: subDir.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: testFile.path))

        // Clean up
        try? FileManager.default.removeItem(at: subDir)
    }

    func testConvenienceGenerateMethod() {
        let html = generator.generate(projectName: "SimpleApp")

        XCTAssertTrue(html.contains("<title>SimpleApp</title>"))
        XCTAssertTrue(html.contains("<!DOCTYPE html>"))
    }

    func testConvenienceWriteMethod() throws {
        let tempDir = FileManager.default.temporaryDirectory
        let testFile = tempDir.appendingPathComponent("convenience-\(UUID().uuidString).html")

        try generator.writeToFile(
            projectName: "ConvenienceApp",
            title: "Custom Title",
            outputPath: testFile.path,
            wasmFile: "app.wasm",
            runtimeJSFile: "runtime.js",
            cssFiles: ["main.css"],
            metaTags: ["description": "Test"]
        )

        let content = try String(contentsOf: testFile, encoding: .utf8)
        XCTAssertTrue(content.contains("<title>Custom Title</title>"))
        XCTAssertTrue(content.contains("main.css"))
        XCTAssertTrue(content.contains("name=\"description\" content=\"Test\""))

        // Clean up
        try? FileManager.default.removeItem(at: testFile)
    }
}
