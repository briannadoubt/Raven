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
            let keys = JSObject.global.Object.keys(srcsetObj)
            let length = Int(keys.length.number ?? 0)
            for i in 0..<length {
                guard let key = keys[i].string else { continue }
                if let value = srcsetObj[dynamicMember: key].string {
                    srcsetDict[key] = value
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
