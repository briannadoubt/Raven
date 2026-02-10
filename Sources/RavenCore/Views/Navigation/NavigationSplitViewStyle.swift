import Foundation

/// A type that specifies the appearance and behavior of a navigation split view.
///
/// Raven models split-view styling as a small set of layout parameters (column
/// proportions and minimum widths) instead of SwiftUI's associated-type-based
/// style protocol, so styles can be stored in the environment as existentials.
public protocol NavigationSplitViewStyle: Sendable {
    /// The layout parameters to use when rendering the split view.
    var layout: NavigationSplitViewLayout { get }
}

/// The default navigation split view style.
public struct AutomaticNavigationSplitViewStyle: NavigationSplitViewStyle {
    public var layout: NavigationSplitViewLayout { .automatic }
    public init() {}
}

/// A balanced navigation split view style that gives each column equal emphasis.
public struct BalancedNavigationSplitViewStyle: NavigationSplitViewStyle {
    public var layout: NavigationSplitViewLayout { .balanced }
    public init() {}
}

/// A navigation split view style that emphasizes the detail column.
public struct ProminentDetailNavigationSplitViewStyle: NavigationSplitViewStyle {
    public var layout: NavigationSplitViewLayout { .prominentDetail }
    public init() {}
}

extension NavigationSplitViewStyle where Self == AutomaticNavigationSplitViewStyle {
    /// The automatic navigation split view style.
    public static var automatic: AutomaticNavigationSplitViewStyle {
        AutomaticNavigationSplitViewStyle()
    }
}

extension NavigationSplitViewStyle where Self == BalancedNavigationSplitViewStyle {
    /// A balanced navigation split view style.
    public static var balanced: BalancedNavigationSplitViewStyle {
        BalancedNavigationSplitViewStyle()
    }
}

extension NavigationSplitViewStyle where Self == ProminentDetailNavigationSplitViewStyle {
    /// A style that emphasizes the detail column.
    public static var prominentDetail: ProminentDetailNavigationSplitViewStyle {
        ProminentDetailNavigationSplitViewStyle()
    }
}

private struct NavigationSplitViewStyleEnvironmentKey: EnvironmentKey {
    static let defaultValue: any NavigationSplitViewStyle = AutomaticNavigationSplitViewStyle()
}

extension EnvironmentValues {
    var navigationSplitViewStyle: any NavigationSplitViewStyle {
        get { self[NavigationSplitViewStyleEnvironmentKey.self] }
        set { self[NavigationSplitViewStyleEnvironmentKey.self] = newValue }
    }
}

extension View {
    /// Sets the style for navigation split views within this view.
    @MainActor public func navigationSplitViewStyle<S: NavigationSplitViewStyle>(_ style: S) -> some View {
        environment(\.navigationSplitViewStyle, style)
    }
}

