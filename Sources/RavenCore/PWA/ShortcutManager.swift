import Foundation
import JavaScriptKit

/// Manages app shortcuts and quick actions for installed PWAs
///
/// ShortcutManager provides runtime control over app shortcuts that appear
/// in the app icon's context menu or launcher, enabling dynamic shortcut updates.
///
/// Example usage:
/// ```swift
/// let shortcutManager = ShortcutManager()
///
/// // Check if shortcuts are supported
/// if shortcutManager.isSupported {
///     // Update shortcuts
///     let shortcuts = [
///         QuickAction(
///             id: "compose",
///             title: "Compose Message",
///             description: "Create a new message",
///             url: "/compose",
///             icon: QuickActionIcon(src: "/icons/compose.png")
///         ),
///         QuickAction(
///             id: "search",
///             title: "Search",
///             description: "Search content",
///             url: "/search",
///             icon: QuickActionIcon(src: "/icons/search.png")
///         )
///     ]
///
///     try await shortcutManager.updateShortcuts(shortcuts)
/// }
/// ```
@MainActor
public final class ShortcutManager: Sendable {

    // MARK: - Properties

    /// Whether shortcuts are supported
    public var isSupported: Bool {
        !JSObject.global.navigator.shortcuts.isUndefined
    }

    /// Cached shortcuts
    private var cachedShortcuts: [QuickAction] = []

    /// Maximum number of shortcuts allowed (platform dependent)
    private let maxShortcuts: Int = 4

    // MARK: - Public API

    /// Update app shortcuts
    /// - Parameter shortcuts: Array of quick actions to set
    /// - Throws: ShortcutError if update fails
    public func updateShortcuts(_ shortcuts: [QuickAction]) async throws {
        guard isSupported else {
            throw ShortcutError.notSupported
        }

        // Limit to max shortcuts
        let limitedShortcuts = Array(shortcuts.prefix(maxShortcuts))

        // Convert to JavaScript objects
        let shortcutsArray = JSObject.global.Array.function!.new()
        for shortcut in limitedShortcuts {
            let jsShortcut = shortcutToJSObject(shortcut)
            _ = shortcutsArray.push!(jsShortcut)
        }

        // Update shortcuts
        do {
            let navigator = JSObject.global.navigator
            let updatePromise = navigator.shortcuts.update.function!(shortcutsArray)
            _ = try await JSPromise(from: updatePromise)!.getValue()

            cachedShortcuts = limitedShortcuts
        } catch {
            throw ShortcutError.updateFailed(error.localizedDescription)
        }
    }

    /// Get current shortcuts
    /// - Returns: Array of current shortcuts
    public func getShortcuts() async throws -> [QuickAction] {
        guard isSupported else {
            throw ShortcutError.notSupported
        }

        do {
            let navigator = JSObject.global.navigator
            let getPromise = navigator.shortcuts.get.function!()
            let result = try await JSPromise(from: getPromise)!.getValue()

            if let shortcutsArray = result.object {
                let length = Int(shortcutsArray.length.number ?? 0)
                var shortcuts: [QuickAction] = []

                for i in 0..<length {
                    if let jsShortcut = shortcutsArray[i].object {
                        let shortcut = jsObjectToShortcut(jsShortcut)
                        shortcuts.append(shortcut)
                    }
                }

                cachedShortcuts = shortcuts
                return shortcuts
            }

            return []
        } catch {
            throw ShortcutError.fetchFailed(error.localizedDescription)
        }
    }

    /// Clear all shortcuts
    /// - Throws: ShortcutError if clearing fails
    public func clearShortcuts() async throws {
        try await updateShortcuts([])
    }

    /// Add a shortcut
    /// - Parameter shortcut: Quick action to add
    /// - Throws: ShortcutError if adding fails
    public func addShortcut(_ shortcut: QuickAction) async throws {
        var shortcuts = cachedShortcuts

        // Check if shortcut already exists
        if let existingIndex = shortcuts.firstIndex(where: { $0.id == shortcut.id }) {
            // Replace existing
            shortcuts[existingIndex] = shortcut
        } else {
            // Add new
            shortcuts.append(shortcut)
        }

        try await updateShortcuts(shortcuts)
    }

    /// Remove a shortcut
    /// - Parameter id: Shortcut ID to remove
    /// - Throws: ShortcutError if removing fails
    public func removeShortcut(id: String) async throws {
        let shortcuts = cachedShortcuts.filter { $0.id != id }
        try await updateShortcuts(shortcuts)
    }

    /// Get cached shortcuts (synchronous)
    /// - Returns: Cached shortcuts
    public func getCachedShortcuts() -> [QuickAction] {
        cachedShortcuts
    }

    /// Get maximum number of shortcuts allowed
    /// - Returns: Maximum shortcuts
    public func getMaxShortcuts() -> Int {
        maxShortcuts
    }

    // MARK: - Private Methods

    /// Convert QuickAction to JavaScript object
    private func shortcutToJSObject(_ shortcut: QuickAction) -> JSObject {
        let obj = JSObject.global.Object.function!.new()

        obj.name = .string(shortcut.title)
        obj.url = .string(shortcut.url)

        if let shortName = shortcut.shortName {
            obj.short_name = .string(shortName)
        }

        if let desc = shortcut.description {
            obj[dynamicMember: "description"] = .string(desc)
        }

        // Icons
        if !shortcut.icons.isEmpty {
            let iconsArray = JSObject.global.Array.function!.new()
            for icon in shortcut.icons {
                let iconObj = iconToJSObject(icon)
                _ = iconsArray.push!(iconObj)
            }
            obj.icons = JSValue.object(iconsArray)
        }

        return obj
    }

    /// Convert icon to JavaScript object
    private func iconToJSObject(_ icon: QuickActionIcon) -> JSObject {
        let obj = JSObject.global.Object.function!.new()
        obj.src = .string(icon.src)

        if let sizes = icon.sizes {
            obj.sizes = .string(sizes)
        }

        if let type = icon.type {
            obj.type = .string(type)
        }

        return obj
    }

    /// Convert JavaScript object to QuickAction
    private func jsObjectToShortcut(_ jsShortcut: JSObject) -> QuickAction {
        let title = jsShortcut.name.string ?? ""
        let url = jsShortcut.url.string ?? ""
        let shortName = jsShortcut.short_name.string
        let description = jsShortcut[dynamicMember: "description"].string

        // Parse icons
        var icons: [QuickActionIcon] = []
        if let iconsArray = jsShortcut.icons.object {
            let length = Int(iconsArray.length.number ?? 0)
            for i in 0..<length {
                if let iconObj = iconsArray[i].object {
                    let icon = jsObjectToIcon(iconObj)
                    icons.append(icon)
                }
            }
        }

        // Generate ID from URL
        let id = url.split(separator: "/").last.map(String.init) ?? "shortcut"

        return QuickAction(
            id: id,
            title: title,
            shortName: shortName,
            description: description,
            url: url,
            icons: icons
        )
    }

    /// Convert JavaScript object to QuickActionIcon
    private func jsObjectToIcon(_ iconObj: JSObject) -> QuickActionIcon {
        let src = iconObj.src.string ?? ""
        let sizes = iconObj.sizes.string
        let type = iconObj.type.string

        return QuickActionIcon(
            src: src,
            sizes: sizes,
            type: type
        )
    }
}

// MARK: - Supporting Types

/// Quick action (app shortcut)
public struct QuickAction: Sendable, Identifiable {
    public let id: String
    public let title: String
    public let shortName: String?
    public let description: String?
    public let url: String
    public let icons: [QuickActionIcon]

    public init(
        id: String,
        title: String,
        shortName: String? = nil,
        description: String? = nil,
        url: String,
        icons: [QuickActionIcon] = []
    ) {
        self.id = id
        self.title = title
        self.shortName = shortName
        self.description = description
        self.url = url
        self.icons = icons
    }
}

/// Quick action icon
public struct QuickActionIcon: Sendable {
    public let src: String
    public let sizes: String?
    public let type: String?

    public init(src: String, sizes: String? = nil, type: String? = nil) {
        self.src = src
        self.sizes = sizes
        self.type = type
    }
}

/// Shortcut errors
public enum ShortcutError: Error, Sendable {
    case notSupported
    case updateFailed(String)
    case fetchFailed(String)
}

// MARK: - Shortcut Action Handler

/// Handles shortcut activation events
@MainActor
public final class ShortcutActionHandler: Sendable {

    /// Callback for shortcut activation
    public var onShortcutActivated: (@Sendable @MainActor (String) -> Void)?

    public init() {
        setupShortcutListener()
    }

    /// Set up listener for shortcut activations
    private func setupShortcutListener() {
        // Monitor URL changes from shortcuts
        let window = JSObject.global

        // Check initial URL for shortcut parameter
        checkURLForShortcut()

        // Listen for navigation events
        let popStateHandler = JSClosure { [weak self] _ -> JSValue in
            Task { @MainActor in
                self?.checkURLForShortcut()
            }
            return .undefined
        }

        _ = window.addEventListener!("popstate", popStateHandler)

        // Store closure
        window.__ravenShortcutHandler = JSValue.object(popStateHandler)
    }

    /// Check URL for shortcut parameter
    private func checkURLForShortcut() {
        let location = JSObject.global.location
        let href = location.href.string ?? ""

        // Parse URL
        if let url = URL(string: href),
           let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
           let queryItems = components.queryItems {

            // Look for shortcut parameter
            if let shortcutParam = queryItems.first(where: { $0.name == "shortcut" }),
               let shortcutId = shortcutParam.value {
                onShortcutActivated?(shortcutId)
            }
        }
    }
}
