import Foundation
import JavaScriptKit

/// Generates and manages web app manifest for Progressive Web Apps
///
/// ManifestGenerator provides a type-safe API for creating and managing
/// web app manifests, which define how the PWA appears when installed.
///
/// Example usage:
/// ```swift
/// let manifest = WebAppManifest(
///     name: "My App",
///     shortName: "App",
///     description: "A great PWA",
///     startUrl: "/",
///     display: .standalone,
///     backgroundColor: "#ffffff",
///     themeColor: "#000000",
///     icons: [
///         ManifestIcon(
///             src: "/icon-192.png",
///             sizes: "192x192",
///             type: "image/png"
///         ),
///         ManifestIcon(
///             src: "/icon-512.png",
///             sizes: "512x512",
///             type: "image/png",
///             purpose: .maskable
///         )
///     ]
/// )
///
/// let generator = ManifestGenerator()
/// let json = generator.generate(manifest: manifest)
/// print(json)
/// ```
@MainActor
public final class ManifestGenerator: Sendable {

    // MARK: - Public API

    /// Generate JSON manifest from WebAppManifest
    /// - Parameter manifest: Manifest configuration
    /// - Returns: JSON string representation
    public func generate(manifest: WebAppManifest) -> String {
        let dict = manifestToDictionary(manifest)
        return dictionaryToJSON(dict)
    }

    /// Generate manifest and inject into document
    /// - Parameter manifest: Manifest configuration
    /// - Throws: ManifestError if injection fails
    public func injectManifest(manifest: WebAppManifest) throws {
        let json = generate(manifest: manifest)

        // Create blob URL
        let blob = createBlob(json, type: "application/json")
        let url = createObjectURL(blob)

        // Inject link element
        injectManifestLink(url: url)
    }

    /// Update theme color dynamically
    /// - Parameter color: New theme color (hex format)
    public func updateThemeColor(_ color: String) {
        let document = JSObject.global.document

        // Update or create theme-color meta tag
        let queryResult = document.querySelector.function!("meta[name='theme-color']")
        var themeColorMeta = queryResult.isNull ? nil : queryResult.object

        if themeColorMeta == nil {
            themeColorMeta = document.createElement.function!("meta").object
            themeColorMeta?.setAttribute.function!("name", "theme-color")
            _ = document.head.appendChild.function!(themeColorMeta!)
        }

        themeColorMeta?.setAttribute.function!("content", color)
    }

    // MARK: - Private Methods

    /// Convert WebAppManifest to dictionary
    private func manifestToDictionary(_ manifest: WebAppManifest) -> [String: Any] {
        var dict: [String: Any] = [:]

        dict["name"] = manifest.name
        dict["short_name"] = manifest.shortName
        dict["start_url"] = manifest.startUrl
        dict["display"] = manifest.display.rawValue

        if let description = manifest.description {
            dict["description"] = description
        }

        if let backgroundColor = manifest.backgroundColor {
            dict["background_color"] = backgroundColor
        }

        if let themeColor = manifest.themeColor {
            dict["theme_color"] = themeColor
        }

        if let orientation = manifest.orientation {
            dict["orientation"] = orientation.rawValue
        }

        if let scope = manifest.scope {
            dict["scope"] = scope
        }

        if let lang = manifest.lang {
            dict["lang"] = lang
        }

        if let dir = manifest.dir {
            dict["dir"] = dir.rawValue
        }

        // Icons
        if !manifest.icons.isEmpty {
            dict["icons"] = manifest.icons.map { iconToDictionary($0) }
        }

        // Screenshots
        if !manifest.screenshots.isEmpty {
            dict["screenshots"] = manifest.screenshots.map { screenshotToDictionary($0) }
        }

        // Shortcuts
        if !manifest.shortcuts.isEmpty {
            dict["shortcuts"] = manifest.shortcuts.map { shortcutToDictionary($0) }
        }

        // Categories
        if !manifest.categories.isEmpty {
            dict["categories"] = manifest.categories
        }

        // Share target
        if let shareTarget = manifest.shareTarget {
            dict["share_target"] = shareTargetToDictionary(shareTarget)
        }

        // Protocol handlers
        if !manifest.protocolHandlers.isEmpty {
            dict["protocol_handlers"] = manifest.protocolHandlers.map { protocolHandlerToDictionary($0) }
        }

        return dict
    }

    private func iconToDictionary(_ icon: ManifestIcon) -> [String: Any] {
        var dict: [String: Any] = [
            "src": icon.src,
            "sizes": icon.sizes,
            "type": icon.type
        ]

        if let purpose = icon.purpose {
            dict["purpose"] = purpose.rawValue
        }

        return dict
    }

    private func screenshotToDictionary(_ screenshot: ManifestScreenshot) -> [String: Any] {
        var dict: [String: Any] = [
            "src": screenshot.src,
            "sizes": screenshot.sizes,
            "type": screenshot.type
        ]

        if let label = screenshot.label {
            dict["label"] = label
        }

        return dict
    }

    private func shortcutToDictionary(_ shortcut: AppShortcut) -> [String: Any] {
        var dict: [String: Any] = [
            "name": shortcut.name,
            "url": shortcut.url
        ]

        if let shortName = shortcut.shortName {
            dict["short_name"] = shortName
        }

        if let description = shortcut.description {
            dict["description"] = description
        }

        if !shortcut.icons.isEmpty {
            dict["icons"] = shortcut.icons.map { iconToDictionary($0) }
        }

        return dict
    }

    private func shareTargetToDictionary(_ shareTarget: ManifestShareTarget) -> [String: Any] {
        var dict: [String: Any] = [
            "action": shareTarget.action,
            "method": shareTarget.method.rawValue,
            "enctype": shareTarget.enctype.rawValue
        ]

        var params: [String: String] = [:]
        if let title = shareTarget.params.title {
            params["title"] = title
        }
        if let text = shareTarget.params.text {
            params["text"] = text
        }
        if let url = shareTarget.params.url {
            params["url"] = url
        }
        if !shareTarget.params.files.isEmpty {
            // Note: files parameter is more complex, simplified here
            params["files"] = "files"
        }

        dict["params"] = params

        return dict
    }

    private func protocolHandlerToDictionary(_ handler: ProtocolHandler) -> [String: Any] {
        [
            "protocol": handler.protocol,
            "url": handler.url
        ]
    }

    /// Convert dictionary to JSON string
    private func dictionaryToJSON(_ dict: [String: Any]) -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        do {
            // Convert to JSONSerialization-compatible format
            let data = try JSONSerialization.data(withJSONObject: dict, options: [.prettyPrinted, .sortedKeys])
            return String(data: data, encoding: .utf8) ?? "{}"
        } catch {
            print("⚠️ ManifestGenerator: Failed to encode JSON: \(error)")
            return "{}"
        }
    }

    /// Create a blob from string content
    private func createBlob(_ content: String, type: String) -> JSObject {
        let array = JSObject.global.Array.function!.new()
        _ = array.push.function!(content)

        let options = JSObject.global.Object.function!.new()
        options.type = .string(type)

        return JSObject.global.Blob.function!.new(array, options)
    }

    /// Create object URL from blob
    private func createObjectURL(_ blob: JSObject) -> String {
        JSObject.global.URL.createObjectURL.function!(blob).string ?? ""
    }

    /// Inject manifest link into document
    private func injectManifestLink(url: String) {
        let document = JSObject.global.document

        // Remove existing manifest link
        let existingResult = document.querySelector.function!("link[rel='manifest']")
        if !existingResult.isNull, let existingLink = existingResult.object {
            _ = existingLink.remove.function!()
        }

        // Create new link element
        let link = document.createElement.function!("link").object!
        link.setAttribute.function!("rel", "manifest")
        link.setAttribute.function!("href", url)

        // Append to head
        _ = document.head.appendChild.function!(link)
    }
}

// MARK: - Supporting Types

/// Web app manifest configuration
public struct WebAppManifest: Sendable {
    public let name: String
    public let shortName: String
    public let description: String?
    public let startUrl: String
    public let display: DisplayMode
    public let backgroundColor: String?
    public let themeColor: String?
    public let orientation: Orientation?
    public let scope: String?
    public let lang: String?
    public let dir: TextDirection?
    public let icons: [ManifestIcon]
    public let screenshots: [ManifestScreenshot]
    public let shortcuts: [AppShortcut]
    public let categories: [String]
    public let shareTarget: ManifestShareTarget?
    public let protocolHandlers: [ProtocolHandler]

    public init(
        name: String,
        shortName: String,
        description: String? = nil,
        startUrl: String = "/",
        display: DisplayMode = .standalone,
        backgroundColor: String? = nil,
        themeColor: String? = nil,
        orientation: Orientation? = nil,
        scope: String? = nil,
        lang: String? = nil,
        dir: TextDirection? = nil,
        icons: [ManifestIcon] = [],
        screenshots: [ManifestScreenshot] = [],
        shortcuts: [AppShortcut] = [],
        categories: [String] = [],
        shareTarget: ManifestShareTarget? = nil,
        protocolHandlers: [ProtocolHandler] = []
    ) {
        self.name = name
        self.shortName = shortName
        self.description = description
        self.startUrl = startUrl
        self.display = display
        self.backgroundColor = backgroundColor
        self.themeColor = themeColor
        self.orientation = orientation
        self.scope = scope
        self.lang = lang
        self.dir = dir
        self.icons = icons
        self.screenshots = screenshots
        self.shortcuts = shortcuts
        self.categories = categories
        self.shareTarget = shareTarget
        self.protocolHandlers = protocolHandlers
    }
}

/// Display mode for PWA
public enum DisplayMode: String, Sendable {
    case fullscreen
    case standalone
    case minimalUi = "minimal-ui"
    case browser
}

/// Screen orientation preference
public enum Orientation: String, Sendable {
    case any
    case natural
    case landscape
    case landscapePrimary = "landscape-primary"
    case landscapeSecondary = "landscape-secondary"
    case portrait
    case portraitPrimary = "portrait-primary"
    case portraitSecondary = "portrait-secondary"
}

/// Text direction
public enum TextDirection: String, Sendable {
    case ltr
    case rtl
    case auto
}

/// Manifest icon
public struct ManifestIcon: Sendable {
    public let src: String
    public let sizes: String
    public let type: String
    public let purpose: IconPurpose?

    public init(src: String, sizes: String, type: String, purpose: IconPurpose? = nil) {
        self.src = src
        self.sizes = sizes
        self.type = type
        self.purpose = purpose
    }
}

/// Icon purpose
public enum IconPurpose: String, Sendable {
    case any
    case maskable
    case monochrome
}

/// Manifest screenshot
public struct ManifestScreenshot: Sendable {
    public let src: String
    public let sizes: String
    public let type: String
    public let label: String?

    public init(src: String, sizes: String, type: String, label: String? = nil) {
        self.src = src
        self.sizes = sizes
        self.type = type
        self.label = label
    }
}

/// App shortcut
public struct AppShortcut: Sendable {
    public let name: String
    public let shortName: String?
    public let description: String?
    public let url: String
    public let icons: [ManifestIcon]

    public init(name: String, shortName: String? = nil, description: String? = nil, url: String, icons: [ManifestIcon] = []) {
        self.name = name
        self.shortName = shortName
        self.description = description
        self.url = url
        self.icons = icons
    }
}

/// Share target configuration for the manifest
public struct ManifestShareTarget: Sendable {
    public let action: String
    public let method: HTTPMethod
    public let enctype: EncodingType
    public let params: ShareParams

    public init(action: String, method: HTTPMethod = .post, enctype: EncodingType = .multipartFormData, params: ShareParams) {
        self.action = action
        self.method = method
        self.enctype = enctype
        self.params = params
    }
}

public enum HTTPMethod: String, Sendable {
    case get = "GET"
    case post = "POST"
}

public enum EncodingType: String, Sendable {
    case urlEncoded = "application/x-www-form-urlencoded"
    case multipartFormData = "multipart/form-data"
}

/// Share parameters
public struct ShareParams: Sendable {
    public let title: String?
    public let text: String?
    public let url: String?
    public let files: [FileFilter]

    public init(title: String? = nil, text: String? = nil, url: String? = nil, files: [FileFilter] = []) {
        self.title = title
        self.text = text
        self.url = url
        self.files = files
    }
}

/// File filter for share target
public struct FileFilter: Sendable {
    public let name: String
    public let accept: [String]

    public init(name: String, accept: [String]) {
        self.name = name
        self.accept = accept
    }
}

/// Protocol handler
public struct ProtocolHandler: Sendable {
    public let `protocol`: String
    public let url: String

    public init(protocol: String, url: String) {
        self.protocol = `protocol`
        self.url = url
    }
}

/// Manifest errors
public enum ManifestError: Error, Sendable {
    case invalidManifest
    case injectionFailed(String)
}
