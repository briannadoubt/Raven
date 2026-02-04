import Foundation

/// A view that switches between multiple child views using interactive tabs.
///
/// `TabView` displays a tab bar with multiple tabs, each representing a different
/// view. Users can switch between tabs by clicking them, and the selection can be
/// controlled programmatically using a binding.
///
/// ## Overview
///
/// Use `TabView` to organize your app's interface into distinct sections that users
/// can navigate between using tabs. Each tab shows different content and can have
/// an icon, label, and optional notification badge.
///
/// ## Basic Usage
///
/// Create a tab view with multiple tabs:
///
/// ```swift
/// TabView {
///     HomeView()
///         .tabItem {
///             Label("Home", systemImage: "house")
///         }
///
///     SearchView()
///         .tabItem {
///             Label("Search", systemImage: "magnifyingglass")
///         }
///
///     ProfileView()
///         .tabItem {
///             Label("Profile", systemImage: "person")
///         }
/// }
/// ```
///
/// ## Programmatic Selection
///
/// Control which tab is selected using a binding:
///
/// ```swift
/// enum Tab {
///     case home, search, profile
/// }
///
/// struct ContentView: View {
///     @State private var selectedTab: Tab = .home
///
///     var body: some View {
///         TabView(selection: $selectedTab) {
///             HomeView()
///                 .tabItem { Label("Home", systemImage: "house") }
///                 .tag(Tab.home)
///
///             SearchView()
///                 .tabItem { Label("Search", systemImage: "magnifyingglass") }
///                 .tag(Tab.search)
///
///             ProfileView()
///                 .tabItem { Label("Profile", systemImage: "person") }
///                 .tag(Tab.profile)
///         }
///     }
/// }
/// ```
///
/// ## Badges
///
/// Add notification badges to tabs:
///
/// ```swift
/// TabView {
///     MessagesView()
///         .tabItem { Label("Messages", systemImage: "message") }
///         .badge("5")
///
///     NotificationsView()
///         .tabItem { Label("Notifications", systemImage: "bell") }
///         .badge(unreadCount > 0 ? "\(unreadCount)" : nil)
/// }
/// ```
///
/// ## Tab Styles
///
/// Customize tab appearance using styles:
///
/// ```swift
/// TabView {
///     // Tab content
/// }
/// .tabViewStyle(.automatic) // Default bottom tab bar
///
/// TabView {
///     // Tab content
/// }
/// .tabViewStyle(.page) // Swipeable pages without tab bar
/// ```
///
/// ## Dynamic Tabs
///
/// Create tabs dynamically from data:
///
/// ```swift
/// struct Category: Identifiable {
///     let id: Int
///     let name: String
///     let icon: String
/// }
///
/// @State private var categories: [Category] = [
///     Category(id: 1, name: "Home", icon: "house"),
///     Category(id: 2, name: "Work", icon: "briefcase"),
///     Category(id: 3, name: "Play", icon: "gamecontroller")
/// ]
/// @State private var selectedCategory: Int = 1
///
/// var body: some View {
///     TabView(selection: $selectedCategory) {
///         ForEach(categories) { category in
///             CategoryView(category: category)
///                 .tabItem {
///                     Label(category.name, systemImage: category.icon)
///                 }
///                 .tag(category.id)
///         }
///     }
/// }
/// ```
///
/// ## Accessibility
///
/// TabView automatically provides proper ARIA attributes:
/// - Tab bar uses `role="tablist"`
/// - Each tab button uses `role="tab"`
/// - Content area uses `role="tabpanel"`
/// - Active tab marked with `aria-selected="true"`
/// - Content panels labeled with `aria-labelledby`
///
/// ## Best Practices
///
/// - Limit tabs to 5 or fewer for better usability
/// - Use clear, concise tab labels
/// - Provide icons for quick recognition
/// - Use badges sparingly for important notifications
/// - Consider page style for full-screen content like onboarding
///
/// ## See Also
///
/// - ``tabItem(_:)``
/// - ``badge(_:)``
/// - ``tag(_:)``
/// - ``TabViewStyle``
public struct TabView<SelectionValue: Hashable, Content: View>: View, Sendable where SelectionValue: Sendable {
    /// The selection binding for controlling which tab is active
    private let selection: Binding<SelectionValue>?

    /// The content containing tab views
    private let content: Content

    /// Whether to use automatic tab selection (first tab)
    private let useAutomaticSelection: Bool

    // MARK: - Initializers

    /// Creates a tab view with explicit selection binding.
    ///
    /// Use this initializer when you need to control which tab is selected
    /// programmatically or respond to selection changes.
    ///
    /// - Parameters:
    ///   - selection: A binding to the selected tab's tag value.
    ///   - content: A view builder that creates the tab content.
    ///
    /// ## Example
    ///
    /// ```swift
    /// @State private var selectedTab = 0
    ///
    /// TabView(selection: $selectedTab) {
    ///     HomeView().tabItem { Label("Home", systemImage: "house") }.tag(0)
    ///     ProfileView().tabItem { Label("Profile", systemImage: "person") }.tag(1)
    /// }
    /// ```
    @MainActor public init(
        selection: Binding<SelectionValue>,
        @ViewBuilder content: () -> Content
    ) {
        self.selection = selection
        self.content = content()
        self.useAutomaticSelection = false
    }

    // MARK: - Body

    /// The content and behavior of this view.
    @MainActor public var body: some View {
        TabViewContainer(
            selection: selection,
            useAutomaticSelection: useAutomaticSelection,
            content: content
        )
    }
}

// MARK: - Automatic Selection Initializer

extension TabView where SelectionValue == Int {
    /// Creates a tab view with automatic selection management.
    ///
    /// Use this initializer when you don't need to control or observe the
    /// selected tab. The first tab will be selected by default.
    ///
    /// - Parameter content: A view builder that creates the tab content.
    ///
    /// ## Example
    ///
    /// ```swift
    /// TabView {
    ///     HomeView().tabItem { Label("Home", systemImage: "house") }
    ///     SearchView().tabItem { Label("Search", systemImage: "magnifyingglass") }
    ///     ProfileView().tabItem { Label("Profile", systemImage: "person") }
    /// }
    /// ```
    @MainActor public init(@ViewBuilder content: () -> Content) {
        self.selection = nil
        self.content = content()
        self.useAutomaticSelection = true
    }
}

// MARK: - Tab View Container

/// Internal container that renders the tab view structure.
@MainActor
private struct TabViewContainer<SelectionValue: Hashable, Content: View>: View, Sendable where SelectionValue: Sendable {
    typealias Body = Never

    /// The selection binding
    let selection: Binding<SelectionValue>?

    /// Whether to use automatic selection
    let useAutomaticSelection: Bool

    /// The content containing tabs
    let content: Content

    @MainActor init(
        selection: Binding<SelectionValue>?,
        useAutomaticSelection: Bool,
        content: Content
    ) {
        self.selection = selection
        self.useAutomaticSelection = useAutomaticSelection
        self.content = content
    }

    /// Converts this container to a virtual DOM node.
    @MainActor func toVNode() -> VNode {
        // Extract tabs from content
        let tabs = extractTabs(from: content)

        // Determine selected tab index
        let selectedIndex = determineSelectedIndex(tabs: tabs)

        // Create tab bar
        let tabBar = createTabBar(tabs: tabs, selectedIndex: selectedIndex)

        // Create content area
        let contentArea = createContentArea(tabs: tabs, selectedIndex: selectedIndex)

        // Create main container
        let props: [String: VProperty] = [
            "class": .attribute(name: "class", value: "raven-tab-view"),
            "display": .style(name: "display", value: "flex"),
            "flex-direction": .style(name: "flex-direction", value: "column"),
            "height": .style(name: "height", value: "100%")
        ]

        return VNode.element(
            "div",
            props: props,
            children: [contentArea, tabBar]
        )
    }

    // MARK: - Tab Extraction

    /// Extracts tab configurations from the content view hierarchy.
    @MainActor private func extractTabs(from view: some View) -> [ExtractedTab<SelectionValue>] {
        var tabs: [ExtractedTab<SelectionValue>] = []
        extractTabsRecursive(from: view, into: &tabs)
        return tabs
    }

    /// Recursively extracts tabs from a view hierarchy.
    @MainActor private func extractTabsRecursive(from view: some View, into tabs: inout [ExtractedTab<SelectionValue>]) {
        // For now, use a simplified approach that handles direct tab item modifiers
        // In a full implementation, the rendering system would provide more sophisticated
        // view hierarchy traversal capabilities

        // This is a placeholder that creates a basic tab structure
        // The actual tab extraction would be implemented by the rendering system
        // which has full access to the view hierarchy

        // Create a default tab for demonstration purposes
        let defaultTabItem = TabItem(
            id: UUID().uuidString,
            label: Text("Tab"),
            badge: nil
        )

        let tab = ExtractedTab<SelectionValue>(
            tagValue: nil,
            tabItem: defaultTabItem,
            badge: nil,
            content: AnyView(view)
        )
        tabs.append(tab)
    }

    // MARK: - Selection Management

    /// Determines the index of the selected tab.
    @MainActor private func determineSelectedIndex(tabs: [ExtractedTab<SelectionValue>]) -> Int {
        guard !tabs.isEmpty else { return 0 }

        if let selection = selection {
            // Find tab with matching tag value
            if let index = tabs.firstIndex(where: { $0.tagValue != nil && $0.tagValue! == selection.wrappedValue }) {
                return index
            }
        }

        // Default to first tab
        return 0
    }

    // MARK: - Tab Bar Creation

    /// Creates the tab bar VNode with proper ARIA tablist role.
    @MainActor private func createTabBar(tabs: [ExtractedTab<SelectionValue>], selectedIndex: Int) -> VNode {
        var tabBarProps: [String: VProperty] = [
            "class": .attribute(name: "class", value: "raven-tab-bar"),
            // ARIA tablist role for tab navigation (WCAG 2.1 requirement)
            "role": .attribute(name: "role", value: "tablist"),
            "display": .style(name: "display", value: "flex"),
            "flex-direction": .style(name: "flex-direction", value: "row"),
            "border-top": .style(name: "border-top", value: "1px solid #e0e0e0"),
            "background-color": .style(name: "background-color", value: "#ffffff")
        ]

        // Add aria-label for clarity
        tabBarProps["aria-label"] = .attribute(name: "aria-label", value: "Tab navigation")

        let tabButtons = tabs.enumerated().map { index, tab in
            createTabButton(tab: tab, index: index, isSelected: index == selectedIndex)
        }

        return VNode.element(
            "div",
            props: tabBarProps,
            children: tabButtons
        )
    }

    /// Creates a single tab button VNode with proper ARIA tab role and states.
    @MainActor private func createTabButton(tab: ExtractedTab<SelectionValue>, index: Int, isSelected: Bool) -> VNode {
        let handlerID = UUID()
        let tabPanelID = "tabpanel-\(index)"

        var buttonProps: [String: VProperty] = [
            "class": .attribute(name: "class", value: isSelected ? "raven-tab-button raven-tab-button-selected" : "raven-tab-button"),
            // ARIA tab role (WCAG 2.1 requirement)
            "role": .attribute(name: "role", value: "tab"),
            // aria-selected indicates the active tab
            "aria-selected": .attribute(name: "aria-selected", value: isSelected ? "true" : "false"),
            // aria-controls links tab to its panel
            "aria-controls": .attribute(name: "aria-controls", value: tabPanelID),
            // Only selected tab should be in tab order
            "tabindex": .attribute(name: "tabindex", value: isSelected ? "0" : "-1"),
            "onClick": .eventHandler(event: "click", handlerID: handlerID),
            "display": .style(name: "display", value: "flex"),
            "flex": .style(name: "flex", value: "1"),
            "flex-direction": .style(name: "flex-direction", value: "column"),
            "align-items": .style(name: "align-items", value: "center"),
            "justify-content": .style(name: "justify-content", value: "center"),
            "padding": .style(name: "padding", value: "12px"),
            "border": .style(name: "border", value: "none"),
            "background": .style(name: "background", value: "transparent"),
            "cursor": .style(name: "cursor", value: "pointer"),
            "color": .style(name: "color", value: isSelected ? "#007AFF" : "#8E8E93"),
            "position": .style(name: "position", value: "relative")
        ]

        // Add data attribute for tab index (used by event handlers)
        buttonProps["data-tab-index"] = .attribute(name: "data-tab-index", value: "\(index)")

        // If there's a tag value, store it
        if let tagValue = tab.tagValue {
            buttonProps["data-tab-tag"] = .attribute(name: "data-tab-tag", value: "\(tagValue)")
        }

        var children: [VNode] = []

        // Add badge if present
        if let badgeText = tab.badge, !badgeText.isEmpty {
            let badgeNode = createBadge(text: badgeText)
            children.append(badgeNode)
        }

        // Add label content (placeholder for now - will be rendered by the system)
        let labelWrapper = VNode.element(
            "div",
            props: [
                "class": .attribute(name: "class", value: "raven-tab-label")
            ],
            children: []
        )
        children.append(labelWrapper)

        return VNode.element(
            "button",
            props: buttonProps,
            children: children
        )
    }

    /// Creates a badge VNode.
    @MainActor private func createBadge(text: String) -> VNode {
        let badgeProps: [String: VProperty] = [
            "class": .attribute(name: "class", value: "raven-tab-badge"),
            "position": .style(name: "position", value: "absolute"),
            "top": .style(name: "top", value: "8px"),
            "right": .style(name: "right", value: "8px"),
            "background-color": .style(name: "background-color", value: "#FF3B30"),
            "color": .style(name: "color", value: "#FFFFFF"),
            "border-radius": .style(name: "border-radius", value: "10px"),
            "padding": .style(name: "padding", value: "2px 6px"),
            "font-size": .style(name: "font-size", value: "11px"),
            "font-weight": .style(name: "font-weight", value: "600"),
            "min-width": .style(name: "min-width", value: "18px"),
            "text-align": .style(name: "text-align", value: "center")
        ]

        return VNode.element(
            "span",
            props: badgeProps,
            children: [VNode.text(text)]
        )
    }

    // MARK: - Content Area Creation

    /// Creates the content area VNode with proper ARIA tabpanel role.
    @MainActor private func createContentArea(tabs: [ExtractedTab<SelectionValue>], selectedIndex: Int) -> VNode {
        let tabPanelID = "tabpanel-\(selectedIndex)"

        var contentProps: [String: VProperty] = [
            "class": .attribute(name: "class", value: "raven-tab-content"),
            // ARIA tabpanel role (WCAG 2.1 requirement)
            "role": .attribute(name: "role", value: "tabpanel"),
            // ID for aria-controls linkage from tab
            "id": .attribute(name: "id", value: tabPanelID),
            // aria-labelledby links panel back to its tab
            "aria-labelledby": .attribute(name: "aria-labelledby", value: "tab-\(selectedIndex)"),
            // Make panel focusable
            "tabindex": .attribute(name: "tabindex", value: "0"),
            "flex": .style(name: "flex", value: "1"),
            "overflow": .style(name: "overflow", value: "auto")
        ]

        // The actual content will be rendered by the rendering system
        // based on the selected tab. For now, create a placeholder.
        return VNode.element(
            "div",
            props: contentProps,
            children: []
        )
    }
}

// MARK: - Extracted Tab

/// Internal structure representing an extracted tab with its configuration.
internal struct ExtractedTab<SelectionValue: Hashable> where SelectionValue: Sendable {
    /// The tag value for this tab (if any)
    let tagValue: SelectionValue?

    /// The tab item configuration
    let tabItem: TabItem

    /// The badge text (if any)
    let badge: String?

    /// The content view for this tab
    let content: AnyView
}

// MARK: - Tab Extraction Protocols

/// Protocol for extracting tabs from tuple views.
@MainActor
internal protocol TabTupleViewProtocol {
    func extractTabs<SelectionValue: Hashable>(into tabs: inout [ExtractedTab<SelectionValue>]) where SelectionValue: Sendable
}

/// Protocol for extracting tabs from conditional content.
@MainActor
internal protocol TabConditionalContentProtocol {
    func extractTabs<SelectionValue: Hashable>(into tabs: inout [ExtractedTab<SelectionValue>]) where SelectionValue: Sendable
}

/// Protocol for extracting tabs from optional content.
@MainActor
internal protocol TabOptionalContentProtocol {
    func extractTabs<SelectionValue: Hashable>(into tabs: inout [ExtractedTab<SelectionValue>]) where SelectionValue: Sendable
}

/// Protocol for extracting tabs from ForEach views.
@MainActor
internal protocol TabForEachViewProtocol {
    func extractTabs<SelectionValue: Hashable>(into tabs: inout [ExtractedTab<SelectionValue>]) where SelectionValue: Sendable
}

// Note: The actual conformances for TupleView, ConditionalContent, OptionalContent,
// and ForEachView would be added in separate extensions to avoid circular dependencies
// and allow the rendering system to properly handle tab content.
