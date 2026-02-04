import XCTest
@testable import RavenCLI

final class AssetBundlerTests: XCTestCase {
    var tempDir: URL!
    var publicDir: URL!
    var distDir: URL!

    override func setUp() {
        super.setUp()
        tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        publicDir = tempDir.appendingPathComponent("Public")
        distDir = tempDir.appendingPathComponent("dist")

        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        try? FileManager.default.createDirectory(at: publicDir, withIntermediateDirectories: true)
        try? FileManager.default.createDirectory(at: distDir, withIntermediateDirectories: true)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: tempDir)
        super.tearDown()
    }

    func testBundleEmptyDirectory() throws {
        let bundler = AssetBundler(verbose: false)
        let result = try bundler.bundleAssets(from: publicDir.path, to: distDir.path)

        XCTAssertEqual(result.filesCopied, 0)
        XCTAssertEqual(result.totalBytes, 0)
        XCTAssertTrue(result.errors.isEmpty)
    }

    func testBundleSingleFile() throws {
        // Create a test file
        let testFile = publicDir.appendingPathComponent("test.txt")
        let content = "Hello, Raven!"
        try content.write(to: testFile, atomically: true, encoding: .utf8)

        let bundler = AssetBundler(verbose: false)
        let result = try bundler.bundleAssets(from: publicDir.path, to: distDir.path)

        XCTAssertEqual(result.filesCopied, 1)
        XCTAssertGreaterThan(result.totalBytes, 0)
        XCTAssertTrue(result.errors.isEmpty)

        // Verify file was copied
        let copiedFile = distDir.appendingPathComponent("test.txt")
        XCTAssertTrue(FileManager.default.fileExists(atPath: copiedFile.path))

        let copiedContent = try String(contentsOf: copiedFile)
        XCTAssertEqual(copiedContent, content)
    }

    func testBundleMultipleFiles() throws {
        // Create multiple test files
        for i in 1...5 {
            let file = publicDir.appendingPathComponent("test\(i).txt")
            try "Content \(i)".write(to: file, atomically: true, encoding: .utf8)
        }

        let bundler = AssetBundler(verbose: false)
        let result = try bundler.bundleAssets(from: publicDir.path, to: distDir.path)

        XCTAssertEqual(result.filesCopied, 5)
        XCTAssertGreaterThan(result.totalBytes, 0)
        XCTAssertTrue(result.errors.isEmpty)
    }

    func testBundleNestedDirectories() throws {
        // Create nested directory structure
        let cssDir = publicDir.appendingPathComponent("css")
        let jsDir = publicDir.appendingPathComponent("js")
        try FileManager.default.createDirectory(at: cssDir, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: jsDir, withIntermediateDirectories: true)

        // Create files in nested directories
        try "body { }".write(to: cssDir.appendingPathComponent("styles.css"), atomically: true, encoding: .utf8)
        try "console.log()".write(to: jsDir.appendingPathComponent("app.js"), atomically: true, encoding: .utf8)
        try "README".write(to: publicDir.appendingPathComponent("README.md"), atomically: true, encoding: .utf8)

        let bundler = AssetBundler(verbose: false)
        let result = try bundler.bundleAssets(from: publicDir.path, to: distDir.path)

        XCTAssertEqual(result.filesCopied, 3)
        XCTAssertGreaterThan(result.totalBytes, 0)
        XCTAssertTrue(result.errors.isEmpty)

        // Verify directory structure was preserved
        XCTAssertTrue(FileManager.default.fileExists(atPath: distDir.appendingPathComponent("css/styles.css").path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: distDir.appendingPathComponent("js/app.js").path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: distDir.appendingPathComponent("README.md").path))
    }

    func testSkipHiddenFiles() throws {
        // Create visible and hidden files
        try "visible".write(to: publicDir.appendingPathComponent("visible.txt"), atomically: true, encoding: .utf8)
        try "hidden".write(to: publicDir.appendingPathComponent(".hidden"), atomically: true, encoding: .utf8)
        try "DS_Store".write(to: publicDir.appendingPathComponent(".DS_Store"), atomically: true, encoding: .utf8)

        let bundler = AssetBundler(verbose: false)
        let result = try bundler.bundleAssets(from: publicDir.path, to: distDir.path)

        // Should only copy the visible file
        XCTAssertEqual(result.filesCopied, 1)
        XCTAssertTrue(FileManager.default.fileExists(atPath: distDir.appendingPathComponent("visible.txt").path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: distDir.appendingPathComponent(".hidden").path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: distDir.appendingPathComponent(".DS_Store").path))
    }

    func testNonExistentSourceDirectory() throws {
        let nonExistent = tempDir.appendingPathComponent("nonexistent")
        let bundler = AssetBundler(verbose: false)

        // Should not throw - just return empty result
        let result = try bundler.bundleAssets(from: nonExistent.path, to: distDir.path)
        XCTAssertEqual(result.filesCopied, 0)
        XCTAssertEqual(result.totalBytes, 0)
    }

    func testOverwriteExistingFiles() throws {
        // Create initial file in dist
        let distFile = distDir.appendingPathComponent("test.txt")
        try "old content".write(to: distFile, atomically: true, encoding: .utf8)

        // Create new file in public
        let publicFile = publicDir.appendingPathComponent("test.txt")
        try "new content".write(to: publicFile, atomically: true, encoding: .utf8)

        let bundler = AssetBundler(verbose: false)
        let result = try bundler.bundleAssets(from: publicDir.path, to: distDir.path)

        XCTAssertEqual(result.filesCopied, 1)

        // Verify file was overwritten
        let content = try String(contentsOf: distFile)
        XCTAssertEqual(content, "new content")
    }
}
