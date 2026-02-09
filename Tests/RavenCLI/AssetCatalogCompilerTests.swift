import Testing
@testable import RavenCLI
import Foundation
import RavenAssetSupport

@Suite struct AssetCatalogCompilerTests {
    private let tempDir: URL
    private let projectDir: URL
    private let distDir: URL

    init() throws {
        tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("raven-xcassets-\(UUID().uuidString)")
        projectDir = tempDir.appendingPathComponent("MyApp")
        distDir = tempDir.appendingPathComponent("dist")

        try FileManager.default.createDirectory(at: projectDir, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: distDir, withIntermediateDirectories: true)
    }

    private func writePNG(to url: URL) throws {
        let b64 = "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+X2E8AAAAASUVORK5CYII="
        let data = Data(base64Encoded: b64)!
        try data.write(to: url)
    }

    private func makeImageSet(root: URL, name: String, scales: [String]) throws {
        let setDir = root
            .appendingPathComponent("\(name).imageset")
        try FileManager.default.createDirectory(at: setDir, withIntermediateDirectories: true)

        var images: [[String: Any]] = []
        for scale in scales {
            let filename = "\(name)-\(scale).png"
            images.append([
                "idiom": "universal",
                "filename": filename,
                "scale": scale,
            ])
            try writePNG(to: setDir.appendingPathComponent(filename))
        }

        let contents: [String: Any] = [
            "images": images,
            "info": ["version": 1, "author": "xcode"],
        ]
        let data = try JSONSerialization.data(withJSONObject: contents, options: [.sortedKeys])
        try data.write(to: setDir.appendingPathComponent("Contents.json"))
    }

    private func makeColorSet(root: URL, name: String, lightHex: String, darkHex: String?) throws {
        let setDir = root.appendingPathComponent("\(name).colorset")
        try FileManager.default.createDirectory(at: setDir, withIntermediateDirectories: true)

        func colorEntry(hex: String, dark: Bool) -> [String: Any] {
            let r = "0x" + hex.prefix(2)
            let g = "0x" + hex.dropFirst(2).prefix(2)
            let b = "0x" + hex.dropFirst(4).prefix(2)
            var entry: [String: Any] = [
                "idiom": "universal",
                "color": [
                    "color-space": "srgb",
                    "components": [
                        "red": String(r),
                        "green": String(g),
                        "blue": String(b),
                        "alpha": "1.0",
                    ],
                ],
            ]
            if dark {
                entry["appearances"] = [["appearance": "luminosity", "value": "dark"]]
            }
            return entry
        }

        var colors: [[String: Any]] = [colorEntry(hex: lightHex, dark: false)]
        if let darkHex {
            colors.append(colorEntry(hex: darkHex, dark: true))
        }

        let contents: [String: Any] = [
            "colors": colors,
            "info": ["version": 1, "author": "xcode"],
        ]
        let data = try JSONSerialization.data(withJSONObject: contents, options: [.sortedKeys])
        try data.write(to: setDir.appendingPathComponent("Contents.json"))
    }

    private func makeDataSet(root: URL, name: String, filename: String, content: Data) throws {
        let setDir = root.appendingPathComponent("\(name).dataset")
        try FileManager.default.createDirectory(at: setDir, withIntermediateDirectories: true)

        try content.write(to: setDir.appendingPathComponent(filename))
        let contents: [String: Any] = [
            "data": [["idiom": "universal", "filename": filename]],
            "info": ["version": 1, "author": "xcode"],
        ]
        let data = try JSONSerialization.data(withJSONObject: contents, options: [.sortedKeys])
        try data.write(to: setDir.appendingPathComponent("Contents.json"))
    }

    private func writeWorkspaceState(deps: [(identity: String, subpath: String)]) throws {
        let buildDir = projectDir.appendingPathComponent(".build")
        try FileManager.default.createDirectory(at: buildDir, withIntermediateDirectories: true)

        let depObjs: [[String: Any]] = deps.map { dep in
            [
                "basedOn": NSNull(),
                "packageRef": [
                    "identity": dep.identity,
                    "kind": "remoteSourceControl",
                    "location": "https://example.com/\(dep.identity).git",
                    "name": dep.identity,
                ],
                "state": [
                    "name": "sourceControlCheckout",
                    "checkoutState": [
                        "revision": "deadbeef",
                        "version": "1.0.0",
                    ],
                ],
                "subpath": dep.subpath,
            ]
        }

        let obj: [String: Any] = [
            "object": [
                "artifacts": [],
                "dependencies": depObjs,
                "prebuilts": [],
            ],
            "version": 7,
        ]
        let data = try JSONSerialization.data(withJSONObject: obj, options: [.sortedKeys])
        try data.write(to: buildDir.appendingPathComponent("workspace-state.json"))
    }

    @Test func imagesetEmitsSrcAndSrcset() throws {
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let appAssets = projectDir
            .appendingPathComponent("Sources/MyApp/Assets.xcassets")
        try FileManager.default.createDirectory(at: appAssets, withIntermediateDirectories: true)
        try makeImageSet(root: appAssets, name: "Logo", scales: ["1x", "2x"])

        let compiler = AssetCatalogCompiler(projectPath: projectDir.path, outputRoot: distDir.path, verbose: false)
        let result = try compiler.compile()

        let entry = try #require(result.manifest.images["Logo"])
        #expect(entry.src.contains("-1x"))
        #expect(entry.srcset?["1x"] != nil)
        #expect(entry.srcset?["2x"] != nil)

        let id = AssetID.fromName("Logo")
        let oneX = distDir.appendingPathComponent("assets/\(id)-1x.png")
        #expect(FileManager.default.fileExists(atPath: oneX.path))
    }

    @Test func colorsetEmitsCSSVariables() throws {
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let appAssets = projectDir
            .appendingPathComponent("Sources/MyApp/Assets.xcassets")
        try FileManager.default.createDirectory(at: appAssets, withIntermediateDirectories: true)
        try makeColorSet(root: appAssets, name: "BrandPrimary", lightHex: "FF0000", darkHex: "00FF00")

        let compiler = AssetCatalogCompiler(projectPath: projectDir.path, outputRoot: distDir.path, verbose: false)
        let result = try compiler.compile()

        let entry = try #require(result.manifest.colors["BrandPrimary"])
        #expect(entry.light.uppercased().contains("FF0000"))
        #expect(entry.dark?.uppercased().contains("00FF00") == true)

        let id = AssetID.fromName("BrandPrimary")
        // The script constructs CSS variable names at runtime, but the embedded manifest JSON includes the ID.
        #expect(result.injectionScript.contains(id))
    }

    @Test func datasetCopiesFileAndExposesURL() throws {
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let appAssets = projectDir
            .appendingPathComponent("Sources/MyApp/Assets.xcassets")
        try FileManager.default.createDirectory(at: appAssets, withIntermediateDirectories: true)
        try makeDataSet(root: appAssets, name: "Config", filename: "config.json", content: Data("{\"ok\":true}".utf8))

        let compiler = AssetCatalogCompiler(projectPath: projectDir.path, outputRoot: distDir.path, verbose: false)
        let result = try compiler.compile()

        let entry = try #require(result.manifest.data["Config"])
        #expect(entry.url.hasPrefix("/assets/data/"))

        let id = AssetID.fromName("Config")
        let file = distDir.appendingPathComponent("assets/data/\(id).json")
        #expect(FileManager.default.fileExists(atPath: file.path))
    }

    @Test func dependencyCatalogsAreDiscoveredAndMerged() throws {
        defer { try? FileManager.default.removeItem(at: tempDir) }

        try writeWorkspaceState(deps: [("dep-a", "DepA"), ("dep-b", "DepB")])

        let depAAssets = projectDir
            .appendingPathComponent(".build/checkouts/DepA/Sources/DepA/Assets.xcassets")
        try FileManager.default.createDirectory(at: depAAssets, withIntermediateDirectories: true)
        try makeImageSet(root: depAAssets, name: "DepLogo", scales: ["1x"])

        let depBAssets = projectDir
            .appendingPathComponent(".build/checkouts/DepB/Sources/DepB/Assets.xcassets")
        try FileManager.default.createDirectory(at: depBAssets, withIntermediateDirectories: true)
        try makeImageSet(root: depBAssets, name: "OtherLogo", scales: ["1x"])

        let compiler = AssetCatalogCompiler(projectPath: projectDir.path, outputRoot: distDir.path, verbose: false)
        let result = try compiler.compile()

        #expect(result.manifest.images["DepLogo"] != nil)
        #expect(result.manifest.images["OtherLogo"] != nil)
    }

    @Test func appBeatsDependencyOnNameConflicts() throws {
        defer { try? FileManager.default.removeItem(at: tempDir) }

        // Dependency has 2x, app has only 1x; app must win -> no 2x in manifest.
        try writeWorkspaceState(deps: [("dep-a", "DepA")])

        let depAssets = projectDir
            .appendingPathComponent(".build/checkouts/DepA/Sources/DepA/Assets.xcassets")
        try FileManager.default.createDirectory(at: depAssets, withIntermediateDirectories: true)
        try makeImageSet(root: depAssets, name: "Logo", scales: ["2x"])

        let appAssets = projectDir
            .appendingPathComponent("Sources/MyApp/Assets.xcassets")
        try FileManager.default.createDirectory(at: appAssets, withIntermediateDirectories: true)
        try makeImageSet(root: appAssets, name: "Logo", scales: ["1x"])

        let compiler = AssetCatalogCompiler(projectPath: projectDir.path, outputRoot: distDir.path, verbose: false)
        let result = try compiler.compile()

        let entry = try #require(result.manifest.images["Logo"])
        #expect(entry.srcset?["1x"] != nil)
        #expect(entry.srcset?["2x"] == nil)
    }

    @Test func dependencyIdentityOrderIsDeterministicOnConflicts() throws {
        defer { try? FileManager.default.removeItem(at: tempDir) }

        // dep-a should win over dep-b because identity sorts first.
        try writeWorkspaceState(deps: [("dep-a", "DepA"), ("dep-b", "DepB")])

        let depAAssets = projectDir
            .appendingPathComponent(".build/checkouts/DepA/Sources/DepA/Assets.xcassets")
        try FileManager.default.createDirectory(at: depAAssets, withIntermediateDirectories: true)
        try makeImageSet(root: depAAssets, name: "Shared", scales: ["1x"])

        let depBAssets = projectDir
            .appendingPathComponent(".build/checkouts/DepB/Sources/DepB/Assets.xcassets")
        try FileManager.default.createDirectory(at: depBAssets, withIntermediateDirectories: true)
        try makeImageSet(root: depBAssets, name: "Shared", scales: ["2x"])

        let compiler = AssetCatalogCompiler(projectPath: projectDir.path, outputRoot: distDir.path, verbose: false)
        let result = try compiler.compile()

        let entry = try #require(result.manifest.images["Shared"])
        #expect(entry.srcset?["1x"] != nil)
        #expect(entry.srcset?["2x"] == nil)
    }
}
