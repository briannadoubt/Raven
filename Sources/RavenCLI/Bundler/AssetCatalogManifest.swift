import Foundation

/// JSON manifest injected into HTML and exposed on `window.__ravenAssetManifest`.
/// This is consumed by the Raven runtime to resolve assets by name.
struct AssetCatalogManifest: Codable, Sendable {
    struct ImageEntry: Codable, Sendable {
        let id: String
        let src: String
        let srcset: [String: String]?
    }

    struct ColorEntry: Codable, Sendable {
        let id: String
        let light: String
        let dark: String?
    }

    struct DataEntry: Codable, Sendable {
        let id: String
        let url: String
    }

    struct IconEntry: Codable, Sendable {
        let url: String
        let sizes: String
        let rel: String
    }

    let version: Int
    var images: [String: ImageEntry]
    var colors: [String: ColorEntry]
    var data: [String: DataEntry]
    var icons: [String: IconEntry]

    init(
        version: Int = 1,
        images: [String: ImageEntry] = [:],
        colors: [String: ColorEntry] = [:],
        data: [String: DataEntry] = [:],
        icons: [String: IconEntry] = [:]
    ) {
        self.version = version
        self.images = images
        self.colors = colors
        self.data = data
        self.icons = icons
    }
}

