import Foundation

/// A view that represents a tab item in a TabView.
///
/// `TabItem` is used internally by the TabView system to represent individual
/// tabs with their associated content, label, and optional badge. You typically
/// don't create TabItem instances directly; instead, use the `.tabItem()` modifier
/// on views within a TabView.
///
/// ## See Also
///
/// - ``TabView``
/// - ``View/tabItem(_:)``
/// - ``View/badge(_:)``
public struct TabItem: Sendable {
    /// Unique identifier for this tab item
    let id: String

    /// The label content for the tab
    let label: AnyView

    /// Optional badge value to display on the tab
    let badge: String?

    /// Creates a tab item with a label and optional badge.
    ///
    /// - Parameters:
    ///   - id: Unique identifier for this tab.
    ///   - label: The view to display as the tab's label.
    ///   - badge: Optional badge text to display on the tab.
    @MainActor init<Label: View>(id: String, label: Label, badge: String?) {
        self.id = id
        self.label = AnyView(label)
        self.badge = badge
    }
}

// MARK: - TabItem Modifier

/// Internal view wrapper that stores tab item configuration.
struct TabItemModifier<Content: View>: View, PrimitiveView, Sendable {
    typealias Body = Never

    /// The content view
    let content: Content

    /// The tab item configuration
    let tabItem: TabItem

    @MainActor init(content: Content, tabItem: TabItem) {
        self.content = content
        self.tabItem = tabItem
    }
}

// MARK: - Badge Modifier

/// Internal view wrapper that stores badge configuration.
struct BadgeModifier<Content: View>: View, PrimitiveView, Sendable {
    typealias Body = Never

    /// The content view
    let content: Content

    /// The badge value
    let badge: String?

    @MainActor init(content: Content, badge: String?) {
        self.content = content
        self.badge = badge
    }
}

// MARK: - View Extensions

extension View {
    /// Sets the tab bar item to represent this view in a TabView.
    ///
    /// Use this modifier to provide a label for a tab in a TabView. The label
    /// typically contains an icon and text that describes the tab's content.
    ///
    /// ## Example
    ///
    /// ```swift
    /// TabView {
    ///     HomeView()
    ///         .tabItem {
    ///             Label("Home", systemImage: "house")
    ///         }
    ///
    ///     SettingsView()
    ///         .tabItem {
    ///             Label("Settings", systemImage: "gear")
    ///         }
    /// }
    /// ```
    ///
    /// ## With Text Only
    ///
    /// ```swift
    /// TabView {
    ///     ContentView()
    ///         .tabItem {
    ///             Text("Content")
    ///         }
    /// }
    /// ```
    ///
    /// ## With Custom Views
    ///
    /// ```swift
    /// TabView {
    ///     ProfileView()
    ///         .tabItem {
    ///             VStack {
    ///                 Image("profile-icon")
    ///                 Text("Profile")
    ///             }
    ///         }
    /// }
    /// ```
    ///
    /// - Parameter label: A view builder that creates the tab's label content.
    /// - Returns: A view with tab item configuration.
    ///
    /// - Note: This modifier should only be used on direct children of a TabView.
    ///
    /// ## See Also
    ///
    /// - ``TabView``
    /// - ``badge(_:)``
    /// - ``tag(_:)``
    @MainActor public func tabItem<Label: View>(@ViewBuilder _ label: () -> Label) -> some View {
        let tabItem = TabItem(
            id: UUID().uuidString,
            label: label(),
            badge: nil
        )
        return TabItemModifier(content: self, tabItem: tabItem)
    }

    /// Adds a badge to a view, typically used with tab items.
    ///
    /// Use this modifier to display a notification badge on a tab item or other
    /// view. The badge typically shows a count or indicator for pending items,
    /// notifications, or updates.
    ///
    /// ## Example
    ///
    /// ```swift
    /// TabView {
    ///     MessagesView()
    ///         .tabItem {
    ///             Label("Messages", systemImage: "message")
    ///         }
    ///         .badge("5")
    ///
    ///     SettingsView()
    ///         .tabItem {
    ///             Label("Settings", systemImage: "gear")
    ///         }
    ///         .badge("1")
    /// }
    /// ```
    ///
    /// ## Dynamic Badges
    ///
    /// ```swift
    /// @State private var unreadCount = 3
    ///
    /// var body: some View {
    ///     TabView {
    ///         InboxView()
    ///             .tabItem {
    ///                 Label("Inbox", systemImage: "tray")
    ///             }
    ///             .badge(unreadCount > 0 ? "\(unreadCount)" : nil)
    ///     }
    /// }
    /// ```
    ///
    /// ## Clearing Badges
    ///
    /// Pass `nil` to remove the badge:
    ///
    /// ```swift
    /// .badge(nil)
    /// ```
    ///
    /// - Parameter value: The text to display in the badge, or `nil` to hide it.
    /// - Returns: A view with badge configuration.
    ///
    /// ## See Also
    ///
    /// - ``tabItem(_:)``
    /// - ``TabView``
    @MainActor public func badge(_ value: String?) -> some View {
        BadgeModifier(content: self, badge: value)
    }

    /// Adds a badge with an integer value to a view.
    ///
    /// This is a convenience method that converts an integer to a string badge.
    ///
    /// ## Example
    ///
    /// ```swift
    /// TabView {
    ///     NotificationsView()
    ///         .tabItem {
    ///             Label("Notifications", systemImage: "bell")
    ///         }
    ///         .badge(unreadNotifications)
    /// }
    /// ```
    ///
    /// - Parameter count: The integer value to display in the badge.
    /// - Returns: A view with badge configuration.
    @MainActor public func badge(_ count: Int) -> some View {
        BadgeModifier(content: self, badge: "\(count)")
    }
}

// MARK: - Internal Tab Configuration Protocol

/// Protocol for extracting tab configuration from views.
///
/// This protocol is used internally by TabView to traverse the view hierarchy
/// and extract tab item configurations.
@MainActor
protocol TabConfigurable {
    /// Extracts tab configuration from this view.
    ///
    /// - Returns: A tuple containing the tab item, badge, and content view, or nil if not a tab.
    func extractTabConfiguration() -> (tabItem: TabItem, badge: String?, content: AnyView)?
}

// MARK: - Tab Path Protocol

/// Protocol for extracting a route path from views in a TabView.
@MainActor
protocol TabPathConfigurable {
    func extractTabPath() -> String?
}

/// Protocol for unwrapping through TabPathModifier to access the inner content.
@MainActor
protocol _TabPathContentProvider {
    var tabPathInnerContent: any View { get }
}

// MARK: - TabItemModifier Conformance

extension TabItemModifier: TabConfigurable {
    @MainActor func extractTabConfiguration() -> (tabItem: TabItem, badge: String?, content: AnyView)? {
        // Check if content has a badge modifier
        if let badgeModifier = content as? any BadgeModifiable {
            let badge = badgeModifier.extractBadge()
            return (tabItem, badge, AnyView(content))
        }
        return (tabItem, nil, AnyView(content))
    }
}

// MARK: - Badge Extraction Protocol

/// Protocol for extracting badge values from views.
@MainActor
protocol BadgeModifiable {
    /// Extracts the badge value from this view.
    ///
    /// - Returns: The badge text, or nil if no badge is set.
    func extractBadge() -> String?
}

extension BadgeModifier: BadgeModifiable {
    @MainActor func extractBadge() -> String? {
        badge
    }
}

// MARK: - _CoordinatorRenderable Conformances

extension TabItemModifier: _CoordinatorRenderable {
    @MainActor public func _render(with context: any _RenderContext) -> VNode {
        context.renderChild(content)
    }

    @MainActor public func toVNode() -> VNode {
        VNode.element("div", props: [:], children: [])
    }
}

extension BadgeModifier: _CoordinatorRenderable {
    @MainActor public func _render(with context: any _RenderContext) -> VNode {
        context.renderChild(content)
    }

    @MainActor public func toVNode() -> VNode {
        VNode.element("div", props: [:], children: [])
    }
}

// MARK: - BadgeModifier TabConfigurable

extension BadgeModifier: TabConfigurable {
    @MainActor func extractTabConfiguration() -> (tabItem: TabItem, badge: String?, content: AnyView)? {
        // Unwrap inner TabConfigurable and overlay badge
        if let inner = content as? any TabConfigurable,
           var config = inner.extractTabConfiguration() {
            config.badge = badge
            return config
        }
        return nil
    }
}

extension BadgeModifier: TabPathConfigurable {
    @MainActor func extractTabPath() -> String? {
        (content as? any TabPathConfigurable)?.extractTabPath()
    }
}

// MARK: - TabPath Modifier

/// Internal view wrapper that stores a URL path for tab-based routing.
struct TabPathModifier<Content: View>: View, PrimitiveView, Sendable {
    typealias Body = Never

    let content: Content
    let path: String

    @MainActor init(content: Content, path: String) {
        self.content = content
        self.path = path
    }
}

extension TabPathModifier: TabPathConfigurable {
    @MainActor func extractTabPath() -> String? {
        path
    }
}

extension TabPathModifier: TabConfigurable {
    @MainActor func extractTabConfiguration() -> (tabItem: TabItem, badge: String?, content: AnyView)? {
        (content as? any TabConfigurable)?.extractTabConfiguration()
    }
}

extension TabPathModifier: _TabPathContentProvider {
    @MainActor var tabPathInnerContent: any View { content }
}

extension TabPathModifier: _CoordinatorRenderable {
    @MainActor public func _render(with context: any _RenderContext) -> VNode {
        context.renderChild(content)
    }

    @MainActor public func toVNode() -> VNode {
        VNode.element("div", props: [:], children: [])
    }
}

// MARK: - TabItemModifier TabPathConfigurable

extension TabItemModifier: TabPathConfigurable {
    @MainActor func extractTabPath() -> String? {
        (content as? any TabPathConfigurable)?.extractTabPath()
    }
}

// MARK: - View Extension for tabPath

extension View {
    /// Associates a URL path with this tab for browser routing.
    ///
    /// When this tab is selected, the browser URL will update to the given path.
    /// Tabs without `.tabPath()` do not change the URL when selected.
    ///
    /// ## Example
    ///
    /// ```swift
    /// TabView(selection: $tab) {
    ///     HomeView()
    ///         .tabItem { Label("Home", systemImage: "house") }
    ///         .tag(Tab.home)
    ///         .tabPath("/home")
    ///
    ///     SearchView()
    ///         .tabItem { Label("Search", systemImage: "magnifyingglass") }
    ///         .tag(Tab.search)
    ///         .tabPath("/search")
    /// }
    /// ```
    ///
    /// - Parameter path: The URL path for this tab (e.g. "/home").
    /// - Returns: A view with tab path configuration.
    @MainActor public func tabPath(_ path: String) -> some View {
        TabPathModifier(content: self, path: path)
    }
}
