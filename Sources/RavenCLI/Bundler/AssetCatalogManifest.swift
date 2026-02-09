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

    struct SymbolEntry: Codable, Sendable {
        let id: String
        let url: String
    }

    let version: Int
    var images: [String: ImageEntry]
    var symbols: [String: SymbolEntry]
    var colors: [String: ColorEntry]
    var data: [String: DataEntry]
    var icons: [String: IconEntry]

    enum CodingKeys: String, CodingKey {
        case version
        case images
        case symbols
        case colors
        case data
        case icons
    }

    init(
        version: Int = 1,
        images: [String: ImageEntry] = [:],
        symbols: [String: SymbolEntry] = [:],
        colors: [String: ColorEntry] = [:],
        data: [String: DataEntry] = [:],
        icons: [String: IconEntry] = [:]
    ) {
        self.version = version
        self.images = images
        self.symbols = symbols
        self.colors = colors
        self.data = data
        self.icons = icons
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        version = try container.decode(Int.self, forKey: .version)
        images = try container.decodeIfPresent([String: ImageEntry].self, forKey: .images) ?? [:]
        symbols = try container.decodeIfPresent([String: SymbolEntry].self, forKey: .symbols) ?? [:]
        colors = try container.decodeIfPresent([String: ColorEntry].self, forKey: .colors) ?? [:]
        data = try container.decodeIfPresent([String: DataEntry].self, forKey: .data) ?? [:]
        icons = try container.decodeIfPresent([String: IconEntry].self, forKey: .icons) ?? [:]
    }
}
