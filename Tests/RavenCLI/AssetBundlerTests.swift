import Testing
@testable import RavenCLI
import Foundation

@Suite struct AssetBundlerTests {
    let tempDir: URL
    let publicDir: URL
    let distDir: URL

    init() throws {
        tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        publicDir = tempDir.appendingPathComponent("Public")
        distDir = tempDir.appendingPathComponent("dist")

        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: publicDir, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: distDir, withIntermediateDirectories: true)
    }

    @Test func bundleEmptyDirectory() throws {
        defer { try? FileManager.default.removeItem(at: tempDir) }
        let bundler = AssetBundler(verbose: false)
        let result = try bundler.bundleAssets(from: publicDir.path, to: distDir.path)

        #expect(result.filesCopied == 0)
        #expect(result.totalBytes == 0)
        #expect(result.errors.isEmpty)
    }

    @Test func bundleSingleFile() throws {
        defer { try? FileManager.default.removeItem(at: tempDir) }
        // Create a test file
        let testFile = publicDir.appendingPathComponent("test.txt")
        let content = "Hello, Raven!"
        try content.write(to: testFile, atomically: true, encoding: .utf8)

        let bundler = AssetBundler(verbose: false)
        let result = try bundler.bundleAssets(from: publicDir.path, to: distDir.path)

        #expect(result.filesCopied == 1)
        #expect(result.totalBytes > 0)
        #expect(result.errors.isEmpty)

        // Verify file was copied
        let copiedFile = distDir.appendingPathComponent("test.txt")
        #expect(FileManager.default.fileExists(atPath: copiedFile.path))

        let copiedContent = try String(contentsOf: copiedFile)
        #expect(copiedContent == content)
    }

    @Test func bundleMultipleFiles() throws {
        defer { try? FileManager.default.removeItem(at: tempDir) }
        // Create multiple test files
        for i in 1...5 {
            let file = publicDir.appendingPathComponent("test\(i).txt")
            try "Content \(i)".write(to: file, atomically: true, encoding: .utf8)
        }

        let bundler = AssetBundler(verbose: false)
        let result = try bundler.bundleAssets(from: publicDir.path, to: distDir.path)

        #expect(result.filesCopied == 5)
        #expect(result.totalBytes > 0)
        #expect(result.errors.isEmpty)
    }

    @Test func bundleNestedDirectories() throws {
        defer { try? FileManager.default.removeItem(at: tempDir) }
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

        #expect(result.filesCopied == 3)
        #expect(result.totalBytes > 0)
        #expect(result.errors.isEmpty)

        // Verify directory structure was preserved
        #expect(FileManager.default.fileExists(atPath: distDir.appendingPathComponent("css/styles.css").path))
        #expect(FileManager.default.fileExists(atPath: distDir.appendingPathComponent("js/app.js").path))
        #expect(FileManager.default.fileExists(atPath: distDir.appendingPathComponent("README.md").path))
    }

    @Test func skipHiddenFiles() throws {
        defer { try? FileManager.default.removeItem(at: tempDir) }
        // Create visible and hidden files
        try "visible".write(to: publicDir.appendingPathComponent("visible.txt"), atomically: true, encoding: .utf8)
        try "hidden".write(to: publicDir.appendingPathComponent(".hidden"), atomically: true, encoding: .utf8)
        try "DS_Store".write(to: publicDir.appendingPathComponent(".DS_Store"), atomically: true, encoding: .utf8)

        let bundler = AssetBundler(verbose: false)
        let result = try bundler.bundleAssets(from: publicDir.path, to: distDir.path)

        // Should only copy the visible file
        #expect(result.filesCopied == 1)
        #expect(FileManager.default.fileExists(atPath: distDir.appendingPathComponent("visible.txt").path))
        #expect(!FileManager.default.fileExists(atPath: distDir.appendingPathComponent(".hidden").path))
        #expect(!FileManager.default.fileExists(atPath: distDir.appendingPathComponent(".DS_Store").path))
    }

    @Test func nonExistentSourceDirectory() throws {
        defer { try? FileManager.default.removeItem(at: tempDir) }
        let nonExistent = tempDir.appendingPathComponent("nonexistent")
        let bundler = AssetBundler(verbose: false)

        // Should not throw - just return empty result
        let result = try bundler.bundleAssets(from: nonExistent.path, to: distDir.path)
        #expect(result.filesCopied == 0)
        #expect(result.totalBytes == 0)
    }

    @Test func overwriteExistingFiles() throws {
        defer { try? FileManager.default.removeItem(at: tempDir) }
        // Create initial file in dist
        let distFile = distDir.appendingPathComponent("test.txt")
        try "old content".write(to: distFile, atomically: true, encoding: .utf8)

        // Create new file in public
        let publicFile = publicDir.appendingPathComponent("test.txt")
        try "new content".write(to: publicFile, atomically: true, encoding: .utf8)

        let bundler = AssetBundler(verbose: false)
        let result = try bundler.bundleAssets(from: publicDir.path, to: distDir.path)

        #expect(result.filesCopied == 1)

        // Verify file was overwritten
        let content = try String(contentsOf: distFile)
        #expect(content == "new content")
    }
}
