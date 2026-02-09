import Foundation
#if arch(wasm32)
import JavaScriptKit
#endif

/// Resolves asset-catalog resources injected by RavenCLI into `window.__ravenAssetManifest`.
@MainActor
enum AssetRegistry {
    struct ResolvedImage: Sendable {
        let src: String
        let srcset: [String: String]?
    }

    #if arch(wasm32)
    private static var manifestObject: JSObject?
    #endif

    #if arch(wasm32)
    private static func loadManifestIfNeeded() -> JSObject? {
        if let manifestObject { return manifestObject }
        guard let obj = JSObject.global.__ravenAssetManifest.object else { return nil }
        manifestObject = obj
        return obj
    }
    #endif

    static func resolveImage(_ name: String) -> ResolvedImage? {
        #if arch(wasm32)
        guard let manifest = loadManifestIfNeeded() else { return nil }
        guard let images = manifest[dynamicMember: "images"].object else { return nil }
        guard let entry = images[dynamicMember: name].object else { return nil }

        guard let src = entry[dynamicMember: "src"].string else { return nil }

        var srcsetDict: [String: String] = [:]
        if let srcsetObj = entry[dynamicMember: "srcset"].object {
            // JavaScriptKit's `JSValue[dynamicMember: String] -> ((...) -> JSValue)`
            // is unsafe and will trap if the member isn't callable. Avoid `Object.keys`
            // and just probe the expected scales we emit from the bundler.
            for scale in ["1x", "2x", "3x"] {
                if let value = srcsetObj[dynamicMember: scale].string {
                    srcsetDict[scale] = value
                }
            }
        }

        return ResolvedImage(src: src, srcset: srcsetDict.isEmpty ? nil : srcsetDict)
        #else
        _ = name
        return nil
        #endif
    }

    static func resolveDataURL(_ name: String) -> String? {
        #if arch(wasm32)
        guard let manifest = loadManifestIfNeeded() else { return nil }
        guard let dataObj = manifest[dynamicMember: "data"].object else { return nil }
        guard let entry = dataObj[dynamicMember: name].object else { return nil }
        return entry[dynamicMember: "url"].string
        #else
        _ = name
        return nil
        #endif
    }
}
