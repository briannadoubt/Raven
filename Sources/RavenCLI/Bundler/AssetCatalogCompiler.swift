import Foundation
import RavenAssetSupport

/// Compiles `.xcassets` from the app package and its SwiftPM dependencies into web-friendly files.
///
/// Outputs:
/// - `<outputRoot>/assets/...` (copied payloads)
/// - `<outputRoot>/assets/raven-asset-manifest.json`
/// - a JS injection script string suitable for insertion into HTML.
struct AssetCatalogCompiler: Sendable {
    struct Result: Sendable {
        let manifest: AssetCatalogManifest
        let injectionScript: String
        let discoveredCatalogPaths: [String]
    }

    private enum Origin: Sendable, Comparable {
        case app(catalogPath: String)
        case dependency(identity: String, catalogPath: String)

        static func < (lhs: Origin, rhs: Origin) -> Bool {
            switch (lhs, rhs) {
            case (.app(let l), .app(let r)):
                return l < r
            case (.app, .dependency):
                return true
            case (.dependency, .app):
                return false
            case (.dependency(let lid, let lp), .dependency(let rid, let rp)):
                if lid != rid { return lid < rid }
                return lp < rp
            }
        }
    }

    private let projectPath: String
    private let outputRoot: String
    private let verbose: Bool

    init(projectPath: String, outputRoot: String, verbose: Bool = false) {
        self.projectPath = projectPath
        self.outputRoot = outputRoot
        self.verbose = verbose
    }

    func compile() throws -> Result {
        let catalogs = discoverCatalogs()
        if catalogs.isEmpty {
            // Still write an empty manifest so runtime lookups remain predictable.
            let empty = AssetCatalogManifest()
            let (json, script) = try emitManifestAndScript(empty, writeManifestFile: true)
            _ = json
            return Result(manifest: empty, injectionScript: script, discoveredCatalogPaths: [])
        }

        var manifest = AssetCatalogManifest()
        var winners: [String: Origin] = [:]

        let assetsDir = (outputRoot as NSString).appendingPathComponent("assets")
        let dataDir = (assetsDir as NSString).appendingPathComponent("data")
        let iconsDir = (assetsDir as NSString).appendingPathComponent("icons")
        let symbolsDir = (assetsDir as NSString).appendingPathComponent("symbols")

        try FileManager.default.createDirectory(atPath: assetsDir, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(atPath: dataDir, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(atPath: iconsDir, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(atPath: symbolsDir, withIntermediateDirectories: true)

        let sortedCatalogs = catalogs.sorted { a, b in
            if a.origin != b.origin { return a.origin < b.origin }
            return a.path < b.path
        }

        for (origin, catalogPath) in sortedCatalogs {
            try compileCatalog(
                catalogPath: catalogPath,
                origin: origin,
                winners: &winners,
                manifest: &manifest,
                assetsDir: assetsDir,
                dataDir: dataDir,
                iconsDir: iconsDir,
                symbolsDir: symbolsDir
            )
        }

        let (_, injectionScript) = try emitManifestAndScript(manifest, writeManifestFile: true)
        let discoveredCatalogPaths = catalogs.map(\.path).sorted()
        return Result(manifest: manifest, injectionScript: injectionScript, discoveredCatalogPaths: discoveredCatalogPaths)
    }

    // MARK: - Discovery

    private func discoverCatalogs() -> [(origin: Origin, path: String)] {
        var results: [(Origin, String)] = []

        // App package catalogs.
        let appSources = (projectPath as NSString).appendingPathComponent("Sources")
        results.append(contentsOf: findXcassetsRoots(under: appSources).map { (.app(catalogPath: $0), $0) })

        // Dependency catalogs (SwiftPM checkouts).
        let workspaceStatePath = (projectPath as NSString).appendingPathComponent(".build/workspace-state.json")
        if let data = try? Data(contentsOf: URL(fileURLWithPath: workspaceStatePath)),
           let state = try? JSONDecoder().decode(SwiftPMWorkspaceState.self, from: data) {
            for dep in state.object.dependencies {
                if dep.state.name == "sourceControlCheckout" {
                    let checkoutRoot = (projectPath as NSString).appendingPathComponent(".build/checkouts/\(dep.subpath)")
                    let depSources = (checkoutRoot as NSString).appendingPathComponent("Sources")
                    let identity = dep.packageRef.identity
                    let found = findXcassetsRoots(under: depSources)
                    for catalogPath in found {
                        results.append((.dependency(identity: identity, catalogPath: catalogPath), catalogPath))
                    }
                } else if dep.packageRef.kind == "fileSystem" {
                    // Future-proof: path-based dependencies can include a location. If it looks like a path, scan it.
                    let location = dep.packageRef.location
                    if location.hasPrefix("/") {
                        let depSources = (location as NSString).appendingPathComponent("Sources")
                        let identity = dep.packageRef.identity
                        let found = findXcassetsRoots(under: depSources)
                        for catalogPath in found {
                            results.append((.dependency(identity: identity, catalogPath: catalogPath), catalogPath))
                        }
                    }
                }
            }
        } else if verbose {
            print("  ℹ No workspace-state.json found/readable; skipping dependency asset catalogs.")
        }

        // Deduplicate by path in case a root is encountered twice.
        var seen = Set<String>()
        return results.filter { seen.insert($0.1).inserted }
    }

    private func findXcassetsRoots(under sourcesPath: String) -> [String] {
        let fm = FileManager.default
        guard fm.fileExists(atPath: sourcesPath) else { return [] }

        let url = URL(fileURLWithPath: sourcesPath)
        let enumerator = fm.enumerator(
            at: url,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles, .skipsPackageDescendants]
        )

        var found: [String] = []
        while let next = enumerator?.nextObject() as? URL {
            if next.pathExtension == "xcassets" {
                found.append(next.path)
                enumerator?.skipDescendants()
            }
        }
        return found.sorted()
    }

    // MARK: - Catalog Compilation

    private func compileCatalog(
        catalogPath: String,
        origin: Origin,
        winners: inout [String: Origin],
        manifest: inout AssetCatalogManifest,
        assetsDir: String,
        dataDir: String,
        iconsDir: String,
        symbolsDir: String
    ) throws {
        let fm = FileManager.default
        let url = URL(fileURLWithPath: catalogPath)
        guard fm.fileExists(atPath: url.path) else { return }

        let enumerator = fm.enumerator(
            at: url,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        )

        while let next = enumerator?.nextObject() as? URL {
            var isDir: ObjCBool = false
            guard fm.fileExists(atPath: next.path, isDirectory: &isDir), isDir.boolValue else { continue }

            switch next.pathExtension {
            case "imageset":
                try compileImageSet(imagesetDir: next, origin: origin, winners: &winners, manifest: &manifest, assetsDir: assetsDir)
                enumerator?.skipDescendants()
            case "symbolset":
                try compileSymbolSet(symbolsetDir: next, origin: origin, winners: &winners, manifest: &manifest, symbolsDir: symbolsDir)
                enumerator?.skipDescendants()
            case "colorset":
                try compileColorSet(colorsetDir: next, origin: origin, winners: &winners, manifest: &manifest)
                enumerator?.skipDescendants()
            case "dataset":
                try compileDataSet(datasetDir: next, origin: origin, winners: &winners, manifest: &manifest, dataDir: dataDir)
                enumerator?.skipDescendants()
            case "appiconset":
                try compileAppIconSet(appiconsetDir: next, origin: origin, manifest: &manifest, iconsDir: iconsDir)
                enumerator?.skipDescendants()
            default:
                break
            }
        }
    }

    private func compileSymbolSet(
        symbolsetDir: URL,
        origin: Origin,
        winners: inout [String: Origin],
        manifest: inout AssetCatalogManifest,
        symbolsDir: String
    ) throws {
        let name = symbolsetDir.deletingPathExtension().lastPathComponent
        guard shouldAccept(name: name, origin: origin, winners: &winners) else { return }

        let contentsURL = symbolsetDir.appendingPathComponent("Contents.json")
        guard let data = try? Data(contentsOf: contentsURL),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let symbols = json["symbols"] as? [[String: Any]] else {
            if verbose { print("  ⚠ Missing/invalid Contents.json for symbolset: \(symbolsetDir.path)") }
            return
        }

        var filename: String?
        for sym in symbols {
            let idiom = sym["idiom"] as? String
            if let idiom, idiom != "universal" { continue }
            if let f = sym["filename"] as? String {
                filename = f
                break
            }
        }
        if filename == nil {
            filename = symbols.compactMap { $0["filename"] as? String }.first
        }

        guard let filename else { return }

        let src = symbolsetDir.appendingPathComponent(filename)
        let ext = src.pathExtension.isEmpty ? "svg" : src.pathExtension.lowercased()
        let id = AssetID.fromName(name)
        let destName = "\(id).\(ext)"
        let destPath = (symbolsDir as NSString).appendingPathComponent(destName)
        try copyFile(from: src.path, to: destPath)

        manifest.symbols[name] = .init(id: id, url: "/assets/symbols/\(destName)")
    }

    private func shouldAccept(name: String, origin: Origin, winners: inout [String: Origin]) -> Bool {
        if let existing = winners[name] {
            if existing <= origin {
                // Existing winner has higher or equal priority.
                if verbose, existing != origin {
                    print("  ⚠ Asset name conflict '\(name)' keeping \(existing) over \(origin)")
                }
                return false
            } else {
                if verbose {
                    print("  ⚠ Asset name conflict '\(name)' overriding \(existing) with \(origin)")
                }
                winners[name] = origin
                return true
            }
        } else {
            winners[name] = origin
            return true
        }
    }

    private func compileImageSet(
        imagesetDir: URL,
        origin: Origin,
        winners: inout [String: Origin],
        manifest: inout AssetCatalogManifest,
        assetsDir: String
    ) throws {
        let name = imagesetDir.deletingPathExtension().lastPathComponent
        guard shouldAccept(name: name, origin: origin, winners: &winners) else { return }

        let contentsURL = imagesetDir.appendingPathComponent("Contents.json")
        guard let data = try? Data(contentsOf: contentsURL),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let images = json["images"] as? [[String: Any]] else {
            if verbose { print("  ⚠ Missing/invalid Contents.json for imageset: \(imagesetDir.path)") }
            return
        }

        // Map scale -> filename
        var byScale: [String: String] = [:]
        for img in images {
            guard let filename = img["filename"] as? String else { continue }
            let idiom = img["idiom"] as? String
            if let idiom, idiom != "universal" { continue }
            let scale = (img["scale"] as? String) ?? "1x"
            byScale[scale] = filename
        }

        // If universal entries were missing, accept first filenames regardless of idiom.
        if byScale.isEmpty {
            for img in images {
                guard let filename = img["filename"] as? String else { continue }
                let scale = (img["scale"] as? String) ?? "1x"
                byScale[scale] = filename
            }
        }

        guard !byScale.isEmpty else { return }

        let id = AssetID.fromName(name)
        var srcset: [String: String] = [:]
        var defaultSrc: String? = nil

        let preferredScales = ["1x", "2x", "3x"]
        for scale in preferredScales {
            guard let filename = byScale[scale] else { continue }
            let src = imagesetDir.appendingPathComponent(filename)
            let ext = src.pathExtension.isEmpty ? "bin" : src.pathExtension.lowercased()
            let destName = "\(id)-\(scale).\(ext)"
            let destPath = (assetsDir as NSString).appendingPathComponent(destName)
            try copyFile(from: src.path, to: destPath)
            let urlPath = "/assets/\(destName)"
            srcset[scale] = urlPath
            if defaultSrc == nil {
                defaultSrc = urlPath
            }
        }

        // Fallback: if no preferred scale copied, copy whatever exists.
        if defaultSrc == nil {
            for (scale, filename) in byScale.sorted(by: { $0.key < $1.key }) {
                let src = imagesetDir.appendingPathComponent(filename)
                let ext = src.pathExtension.isEmpty ? "bin" : src.pathExtension.lowercased()
                let destName = "\(id)-\(scale).\(ext)"
                let destPath = (assetsDir as NSString).appendingPathComponent(destName)
                try copyFile(from: src.path, to: destPath)
                let urlPath = "/assets/\(destName)"
                srcset[scale] = urlPath
                defaultSrc = urlPath
                break
            }
        }

        guard let src = defaultSrc else { return }

        manifest.images[name] = .init(
            id: id,
            src: src,
            srcset: srcset.isEmpty ? nil : srcset
        )
    }

    private func compileColorSet(
        colorsetDir: URL,
        origin: Origin,
        winners: inout [String: Origin],
        manifest: inout AssetCatalogManifest
    ) throws {
        let name = colorsetDir.deletingPathExtension().lastPathComponent
        guard shouldAccept(name: name, origin: origin, winners: &winners) else { return }

        let contentsURL = colorsetDir.appendingPathComponent("Contents.json")
        guard let data = try? Data(contentsOf: contentsURL),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let colors = json["colors"] as? [[String: Any]] else {
            if verbose { print("  ⚠ Missing/invalid Contents.json for colorset: \(colorsetDir.path)") }
            return
        }

        var light: String?
        var dark: String?

        for entry in colors {
            let idiom = entry["idiom"] as? String
            if let idiom, idiom != "universal" { continue }

            let appearances = entry["appearances"] as? [[String: Any]] ?? []
            let isDark = appearances.contains { ($0["appearance"] as? String) == "luminosity" && ($0["value"] as? String) == "dark" }

            guard let colorDict = entry["color"] as? [String: Any],
                  let cs = colorDict["color-space"] as? String,
                  cs.lowercased().contains("srgb"),
                  let comps = colorDict["components"] as? [String: Any] else {
                continue
            }

            guard let css = parseSRGBComponentsToCSS(comps) else { continue }
            if isDark { dark = css } else { light = css }
        }

        guard let light else { return }
        let id = AssetID.fromName(name)
        manifest.colors[name] = .init(id: id, light: light, dark: dark)
    }

    private func compileDataSet(
        datasetDir: URL,
        origin: Origin,
        winners: inout [String: Origin],
        manifest: inout AssetCatalogManifest,
        dataDir: String
    ) throws {
        let name = datasetDir.deletingPathExtension().lastPathComponent
        guard shouldAccept(name: name, origin: origin, winners: &winners) else { return }

        let contentsURL = datasetDir.appendingPathComponent("Contents.json")
        guard let data = try? Data(contentsOf: contentsURL),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let entries = json["data"] as? [[String: Any]] else {
            if verbose { print("  ⚠ Missing/invalid Contents.json for dataset: \(datasetDir.path)") }
            return
        }

        guard let first = entries.first(where: { ($0["filename"] as? String) != nil }),
              let filename = first["filename"] as? String else {
            return
        }

        let id = AssetID.fromName(name)
        let src = datasetDir.appendingPathComponent(filename)
        let ext = src.pathExtension.isEmpty ? "bin" : src.pathExtension.lowercased()
        let destName = "\(id).\(ext)"
        let destPath = (dataDir as NSString).appendingPathComponent(destName)
        try copyFile(from: src.path, to: destPath)

        let urlPath = "/assets/data/\(destName)"
        manifest.data[name] = .init(id: id, url: urlPath)
    }

    private func compileAppIconSet(
        appiconsetDir: URL,
        origin: Origin,
        manifest: inout AssetCatalogManifest,
        iconsDir: String
    ) throws {
        _ = origin // app icons are not name-addressable; no conflict logic needed.

        let contentsURL = appiconsetDir.appendingPathComponent("Contents.json")
        guard let data = try? Data(contentsOf: contentsURL),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let images = json["images"] as? [[String: Any]] else {
            return
        }

        // Desired icon sizes (px) mapped to rel.
        let desired: [(px: Int, rel: String)] = [
            (16, "icon"),
            (32, "icon"),
            (180, "apple-touch-icon"),
            (192, "icon"),
            (512, "icon"),
        ]

        // Build candidates by computed px.
        struct Candidate {
            let px: Int
            let filename: String
        }

        var candidates: [Candidate] = []
        for img in images {
            guard let filename = img["filename"] as? String else { continue }
            guard filename.lowercased().hasSuffix(".png") else { continue }

            guard let sizeStr = img["size"] as? String,
                  let scaleStr = img["scale"] as? String else { continue }

            // size is like "20x20", scale like "2x"
            let comps = sizeStr.split(separator: "x")
            guard comps.count == 2, let base = Int(comps[0]) else { continue }
            let scale = Int(scaleStr.replacingOccurrences(of: "x", with: "")) ?? 1
            candidates.append(.init(px: base * scale, filename: filename))
        }

        for (px, rel) in desired {
            guard let match = candidates.first(where: { $0.px == px }) else { continue }
            let src = appiconsetDir.appendingPathComponent(match.filename)
            let destName = "icon-\(px)x\(px).png"
            let destPath = (iconsDir as NSString).appendingPathComponent(destName)
            try copyFile(from: src.path, to: destPath)

            manifest.icons["\(px)"] = .init(
                url: "/assets/icons/\(destName)",
                sizes: "\(px)x\(px)",
                rel: rel
            )
        }
    }

    // MARK: - Manifest + Injection Script

    private func emitManifestAndScript(_ manifest: AssetCatalogManifest, writeManifestFile: Bool) throws -> (json: String, injectionScript: String) {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        let jsonData = try encoder.encode(manifest)
        let jsonString = String(data: jsonData, encoding: .utf8) ?? "{}"

        if writeManifestFile {
            let manifestPath = (outputRoot as NSString).appendingPathComponent("assets/raven-asset-manifest.json")
            try FileManager.default.createDirectory(
                atPath: (manifestPath as NSString).deletingLastPathComponent,
                withIntermediateDirectories: true
            )
            try jsonData.write(to: URL(fileURLWithPath: manifestPath))
        }

        let injection = AssetInjectionScriptGenerator.generate(manifestJSON: jsonString)
        return (jsonString, injection)
    }

    // MARK: - Helpers

    private func copyFile(from source: String, to destination: String) throws {
        let fm = FileManager.default
        try fm.createDirectory(atPath: (destination as NSString).deletingLastPathComponent, withIntermediateDirectories: true)
        if fm.fileExists(atPath: destination) {
            try fm.removeItem(atPath: destination)
        }
        try fm.copyItem(atPath: source, toPath: destination)
    }

    private func parseSRGBComponentsToCSS(_ comps: [String: Any]) -> String? {
        func parseComponent(_ v: Any?) -> Double? {
            guard let v else { return nil }
            if let s = v as? String {
                if s.hasPrefix("0x") || s.hasPrefix("0X") {
                    let hex = s.dropFirst(2)
                    if let n = UInt64(hex, radix: 16) {
                        return Double(n) / 255.0
                    }
                }
                return Double(s)
            }
            if let n = v as? Double { return n }
            if let n = v as? Int { return Double(n) }
            return nil
        }

        guard let r = parseComponent(comps["red"]),
              let g = parseComponent(comps["green"]),
              let b = parseComponent(comps["blue"]) else {
            return nil
        }
        let a = parseComponent(comps["alpha"]) ?? 1.0

        let rr = Int((min(max(r, 0), 1) * 255.0).rounded())
        let gg = Int((min(max(g, 0), 1) * 255.0).rounded())
        let bb = Int((min(max(b, 0), 1) * 255.0).rounded())
        let aa = min(max(a, 0), 1)

        if aa < 1.0 {
            return "rgba(\(rr), \(gg), \(bb), \(String(format: "%.3f", aa)))"
        }
        return String(format: "#%02X%02X%02X", rr, gg, bb)
    }
}

// MARK: - SwiftPM workspace-state.json

private struct SwiftPMWorkspaceState: Codable, Sendable {
    struct Object: Codable, Sendable {
        let dependencies: [Dependency]
    }

    struct Dependency: Codable, Sendable {
        let packageRef: PackageRef
        let state: State
        let subpath: String
    }

    struct PackageRef: Codable, Sendable {
        let identity: String
        let kind: String
        let location: String
    }

    struct State: Codable, Sendable {
        let name: String
    }

    let object: Object
}

// MARK: - Injection Script Generator

private enum AssetInjectionScriptGenerator {
    static func generate(manifestJSON: String) -> String {
        // Keep this script small and idempotent. It should be safe to run multiple times.
        return """
        (function(){
          if (typeof window === 'undefined' || typeof document === 'undefined') return;
          if (window.__ravenAssetManifest) return;
          window.__ravenAssetManifest = \(manifestJSON);

          // Colors -> CSS variables
          try {
            if (!document.getElementById('__raven_asset_colors')) {
              var style = document.createElement('style');
              style.id = '__raven_asset_colors';

              var lightLines = [];
              var darkLines = [];
              var colors = (window.__ravenAssetManifest && window.__ravenAssetManifest.colors) || {};
              for (var name in colors) {
                if (!Object.prototype.hasOwnProperty.call(colors, name)) continue;
                var entry = colors[name];
                if (!entry || !entry.id || !entry.light) continue;
                lightLines.push('  --raven-color-' + entry.id + ': ' + entry.light + ';');
                if (entry.dark) {
                  darkLines.push('  --raven-color-' + entry.id + ': ' + entry.dark + ';');
                }
              }

              var css = '';
              if (lightLines.length) {
                css += ':root{\\n' + lightLines.join('\\n') + '\\n}\\n';
              }
              if (darkLines.length) {
                css += '@media (prefers-color-scheme: dark){\\n:root{\\n' + darkLines.join('\\n') + '\\n}\\n}\\n';
              }
              style.textContent = css;
              document.head && document.head.appendChild(style);
            }
          } catch (e) {}

          // Icons -> link tags
          try {
            if (!document.getElementById('__raven_asset_icons_marker')) {
              var marker = document.createElement('meta');
              marker.id = '__raven_asset_icons_marker';
              document.head && document.head.appendChild(marker);
              var icons = (window.__ravenAssetManifest && window.__ravenAssetManifest.icons) || {};
              for (var key in icons) {
                if (!Object.prototype.hasOwnProperty.call(icons, key)) continue;
                var icon = icons[key];
                if (!icon || !icon.url) continue;
                var link = document.createElement('link');
                link.rel = icon.rel || 'icon';
                link.href = icon.url;
                if (icon.sizes) link.sizes = icon.sizes;
                document.head && document.head.appendChild(link);
              }
            }
          } catch (e) {}
        })();
        """
    }
}
