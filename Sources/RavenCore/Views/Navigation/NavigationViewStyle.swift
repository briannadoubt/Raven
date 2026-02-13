import Foundation

/// Configuration payload for navigation view styles.
///
/// Raven currently uses this as a lightweight parity surface so style values can
/// be selected via `.navigationViewStyle(...)` and resolved during rendering.
public struct NavigationViewStyleConfiguration: Sendable {
    public let content: AnyView

    public init(content: AnyView) {
        self.content = content
    }
}

/// A type that specifies the appearance and interaction behavior of navigation views.
public protocol NavigationViewStyle: Sendable {
    /// Internal style variant used by Raven's navigation renderer.
    var _variant: _NavigationViewStyleVariant { get }
}

/// Internal style variants for `NavigationView` rendering.
public enum _NavigationViewStyleVariant: String, Sendable {
    case automatic
    case `default`
    case stack
    case doubleColumn
    case columns
}

/// The automatic navigation view style.
public struct AutomaticNavigationViewStyle: NavigationViewStyle {
    public var _variant: _NavigationViewStyleVariant { .automatic }
    public init() {}
}

/// The default navigation view style.
public struct DefaultNavigationViewStyle: NavigationViewStyle {
    public var _variant: _NavigationViewStyleVariant { .default }
    public init() {}
}

/// A stack-based navigation view style.
public struct StackNavigationViewStyle: NavigationViewStyle {
    public var _variant: _NavigationViewStyleVariant { .stack }
    public init() {}
}

/// A two-column navigation view style.
public struct DoubleColumnNavigationViewStyle: NavigationViewStyle {
    public var _variant: _NavigationViewStyleVariant { .doubleColumn }
    public init() {}
}

/// A column-oriented navigation view style.
public struct ColumnNavigationViewStyle: NavigationViewStyle {
    public var _variant: _NavigationViewStyleVariant { .columns }
    public init() {}
}

extension NavigationViewStyle where Self == AutomaticNavigationViewStyle {
    /// The automatic navigation view style.
    public static var automatic: AutomaticNavigationViewStyle { AutomaticNavigationViewStyle() }
}

extension NavigationViewStyle where Self == DefaultNavigationViewStyle {
    /// The default navigation view style.
    public static var `default`: DefaultNavigationViewStyle { DefaultNavigationViewStyle() }
}

extension NavigationViewStyle where Self == StackNavigationViewStyle {
    /// A stack-based navigation view style.
    public static var stack: StackNavigationViewStyle { StackNavigationViewStyle() }
}

extension NavigationViewStyle where Self == DoubleColumnNavigationViewStyle {
    /// A two-column navigation view style.
    public static var doubleColumn: DoubleColumnNavigationViewStyle { DoubleColumnNavigationViewStyle() }
}

extension NavigationViewStyle where Self == ColumnNavigationViewStyle {
    /// A column-oriented navigation view style.
    public static var columns: ColumnNavigationViewStyle { ColumnNavigationViewStyle() }
}

private struct NavigationViewStyleEnvironmentKey: EnvironmentKey {
    static let defaultValue: any NavigationViewStyle = AutomaticNavigationViewStyle()
}

extension EnvironmentValues {
    var navigationViewStyle: any NavigationViewStyle {
        get { self[NavigationViewStyleEnvironmentKey.self] }
        set { self[NavigationViewStyleEnvironmentKey.self] = newValue }
    }
}

extension View {
    /// Sets the style for navigation views within this view hierarchy.
    @MainActor public func navigationViewStyle(_ style: some NavigationViewStyle) -> some View {
        environment(\.navigationViewStyle, style)
    }
}
