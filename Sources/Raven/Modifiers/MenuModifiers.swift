import Foundation

// MARK: - Menu Styles

/// A type that specifies the appearance and behavior of a menu.
///
/// Menu styles define how a menu is rendered in the user interface.
/// Different styles are appropriate for different contexts and use cases.
///
/// ## Overview
///
/// Use the `.menuStyle()` modifier to apply a style to a menu or to all
/// menus within a view hierarchy.
///
/// ## Available Styles
///
/// - ``DefaultMenuStyle``: Standard dropdown menu (default)
/// - ``ButtonMenuStyle``: Menu styled as a button
///
/// ## Example
///
/// ```swift
/// Menu("Actions") {
///     Button("Copy") { copy() }
///     Button("Paste") { paste() }
/// }
/// .menuStyle(.button)
/// ```
public protocol MenuStyle: Sendable {
    /// The type of view representing the body of the menu style.
    associatedtype Body: View

    /// Creates a view representing the styled menu.
    ///
    /// - Parameter configuration: The properties of the menu.
    /// - Returns: A view representing the menu with this style applied.
    @MainActor func makeBody(configuration: Configuration) -> Body

    /// The properties of a menu.
    typealias Configuration = MenuStyleConfiguration
}

/// The properties of a menu.
///
/// This configuration is passed to menu styles to provide the necessary
/// information for rendering the menu.
public struct MenuStyleConfiguration: Sendable {
    /// The label for the menu trigger
    public let label: AnyView

    /// The menu's content view (menu items)
    public let content: AnyView

    /// Creates a menu style configuration.
    public init(label: AnyView, content: AnyView) {
        self.label = label
        self.content = content
    }
}

// MARK: - Default Menu Style

/// A menu style that displays a standard dropdown menu.
///
/// This is the default menu style and renders as a button that opens
/// a dropdown containing menu items. The dropdown appears below the
/// trigger button and is dismissed when clicking outside.
///
/// ## Example
///
/// ```swift
/// Menu("Options") {
///     Button("Edit") { edit() }
///     Button("Delete") { delete() }
/// }
/// .menuStyle(.default)
/// ```
///
/// ## Appearance
///
/// The default menu style displays:
/// - A clickable button with the menu label
/// - A dropdown that appears on click
/// - Menu items in a vertical list
/// - Hover effects on menu items
///
/// ## Best Practices
///
/// - Use for standard menus with 2-10 items
/// - Keep labels concise and action-oriented
/// - Group related actions together
/// - Use dividers to separate action groups
public struct DefaultMenuStyle: MenuStyle {
    /// Creates a default menu style.
    public init() {}

    /// Creates the default dropdown menu appearance.
    @MainActor public func makeBody(configuration: Configuration) -> some View {
        // The default menu implementation already renders as a dropdown
        // This style doesn't need to modify the appearance
        configuration.content
    }
}

// MARK: - Button Menu Style

/// A menu style that displays the menu as a button.
///
/// This style presents the menu label as a standard button, with the
/// dropdown appearing when the button is clicked. It's useful for menus
/// that should look like primary actions.
///
/// ## Example
///
/// ```swift
/// Menu("Actions") {
///     Button("Copy") { copy() }
///     Button("Paste") { paste() }
/// }
/// .menuStyle(.button)
/// ```
///
/// ## Appearance
///
/// The button menu style displays:
/// - A prominently styled button
/// - Clear visual affordance for interaction
/// - Dropdown with enhanced shadow
///
/// ## Best Practices
///
/// - Use for primary action menus
/// - Suitable for toolbars and action bars
/// - Good for menus that deserve visual prominence
public struct ButtonMenuStyle: MenuStyle {
    /// Creates a button menu style.
    public init() {}

    /// Creates the button menu appearance.
    @MainActor public func makeBody(configuration: Configuration) -> some View {
        // The rendering is handled in Menu.toVNode()
        // This protocol method is provided for SwiftUI compatibility
        configuration.content
    }
}

// MARK: - Style Modifier

extension View {
    /// Sets the style for menus within this view.
    ///
    /// Use this modifier to customize the appearance of menus in a view hierarchy.
    /// The style applies to all menus within the modified view.
    ///
    /// Example:
    /// ```swift
    /// VStack {
    ///     Menu("File") {
    ///         Button("New") { }
    ///         Button("Open") { }
    ///     }
    ///     Menu("Edit") {
    ///         Button("Copy") { }
    ///         Button("Paste") { }
    ///     }
    /// }
    /// .menuStyle(.button)  // Applies to both menus
    /// ```
    ///
    /// - Parameter style: The menu style to apply.
    /// - Returns: A view with the specified menu style.
    @MainActor public func menuStyle<S: MenuStyle>(_ style: S) -> some View {
        environment(\.menuStyle, style)
    }
}

// MARK: - Convenience Extensions

extension MenuStyle where Self == DefaultMenuStyle {
    /// The default menu style.
    ///
    /// Displays a standard dropdown menu.
    public static var `default`: DefaultMenuStyle {
        DefaultMenuStyle()
    }
}

extension MenuStyle where Self == ButtonMenuStyle {
    /// A button menu style.
    ///
    /// Displays the menu as a button.
    public static var button: ButtonMenuStyle {
        ButtonMenuStyle()
    }
}

// MARK: - Environment Key

private struct MenuStyleEnvironmentKey: EnvironmentKey {
    static let defaultValue: any MenuStyle = DefaultMenuStyle()
}

extension EnvironmentValues {
    var menuStyle: any MenuStyle {
        get { self[MenuStyleEnvironmentKey.self] }
        set { self[MenuStyleEnvironmentKey.self] = newValue }
    }
}

// MARK: - Context Menu Modifier

extension View {
    /// Adds a context menu to this view.
    ///
    /// A context menu appears when the user right-clicks (or long-presses on touch devices)
    /// on the view. It presents a list of actions related to the content.
    ///
    /// ## Example
    ///
    /// ```swift
    /// Text("Right-click me")
    ///     .contextMenu {
    ///         Button("Copy") { copy() }
    ///         Button("Share") { share() }
    ///         Button("Delete", role: .destructive) { delete() }
    ///     }
    /// ```
    ///
    /// ## Behavior
    ///
    /// - Desktop: Appears on right-click
    /// - Touch devices: Appears on long-press
    /// - Dismissed by clicking/tapping outside
    /// - Can contain buttons and nested menus
    ///
    /// ## Best Practices
    ///
    /// - Use for contextual actions related to the content
    /// - Keep the list short (3-7 items ideally)
    /// - Put the most common action first
    /// - Use destructive role for dangerous actions
    /// - Consider adding keyboard shortcuts
    ///
    /// ## Accessibility
    ///
    /// Context menus should also be accessible through keyboard navigation
    /// and alternative input methods. Provide alternative ways to access
    /// the same actions when possible.
    ///
    /// - Parameter menuItems: A view builder that creates the context menu items.
    /// - Returns: A view with a context menu attached.
    @MainActor public func contextMenu<MenuItems: View>(
        @ViewBuilder menuItems: () -> MenuItems
    ) -> some View {
        modifier(ContextMenuModifier(menuItems: menuItems()))
    }
}

/// A modifier that adds a context menu to a view.
private struct ContextMenuModifier<MenuItems: View>: ViewModifier {
    let menuItems: MenuItems

    @MainActor func body(content: Content) -> some View {
        // For now, this is a simplified implementation
        // Full implementation would attach context menu handlers to the content
        // and render a menu on right-click/long-press
        content
    }
}
