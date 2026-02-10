import Foundation

/// A type that specifies the appearance and behavior of a tab view.
///
/// Use tab view styles to customize how tabs are displayed and interact with users.
/// Apply styles using the `.tabViewStyle()` modifier on a TabView.
///
/// ## Built-in Styles
///
/// Raven provides the following built-in tab view styles:
///
/// - ``AutomaticTabViewStyle``: Platform-appropriate default (top on WASI)
/// - ``DefaultTabViewStyle``: Standard tab bar at the bottom
/// - ``TopTabViewStyle``: Tab bar at the top
/// - ``PageTabViewStyle``: Swipeable pages without visible tab bar
///
/// ## Example
///
/// ```swift
/// TabView {
///     HomeView()
///         .tabItem { Label("Home", systemImage: "house") }
///     ProfileView()
///         .tabItem { Label("Profile", systemImage: "person") }
/// }
/// .tabViewStyle(.automatic)
/// ```
///
/// ## See Also
///
/// - ``TabView``
/// - ``DefaultTabViewStyle``
/// - ``PageTabViewStyle``
public protocol TabViewStyle: Sendable {
    /// The tab bar position for this style.
    var tabBarPosition: TabBarPosition { get }

    /// Whether tabs are swipeable in this style.
    var isSwipeable: Bool { get }

    /// Whether to show the tab bar in this style.
    var showsTabBar: Bool { get }
}

// MARK: - Tab Bar Position

/// The position of the tab bar in a tab view.
public enum TabBarPosition: Sendable {
    /// Tab bar at the top of the view
    case top
    /// Tab bar at the bottom of the view
    case bottom
    /// No tab bar (page style)
    case none
}

// MARK: - Automatic Tab View Style

/// A platform-appropriate tab view style.
///
/// This is the default style used by Raven when no explicit `.tabViewStyle(...)`
/// is applied.
///
/// On `os(WASI)` (web), top tabs tend to match common web navigation patterns.
/// On other platforms, this follows the iOS convention of a bottom tab bar.
public struct AutomaticTabViewStyle: TabViewStyle {
    public var tabBarPosition: TabBarPosition {
        #if os(WASI)
        .top
        #else
        .bottom
        #endif
    }

    public var isSwipeable: Bool { false }
    public var showsTabBar: Bool { true }

    public init() {}
}

// MARK: - Default Tab View Style

/// The default tab view style with a tab bar at the bottom.
///
/// This style displays a horizontal tab bar at the bottom of the view,
/// with each tab showing its icon and label. Clicking a tab switches
/// to that tab's content.
///
/// ## Example
///
/// ```swift
/// TabView {
///     HomeView().tabItem { Label("Home", systemImage: "house") }
///     ProfileView().tabItem { Label("Profile", systemImage: "person") }
/// }
/// .tabViewStyle(.bottom)
/// ```
///
/// ## Appearance
///
/// - Tab bar fixed at the bottom
/// - Tabs arranged horizontally
/// - Active tab highlighted
/// - Badges displayed on tab icons
/// - Accessible with ARIA tabs role
///
/// ## See Also
///
/// - ``TabViewStyle``
/// - ``TabView``
public struct DefaultTabViewStyle: TabViewStyle {
    public var tabBarPosition: TabBarPosition { .bottom }
    public var isSwipeable: Bool { false }
    public var showsTabBar: Bool { true }

    /// Creates a default tab view style.
    public init() {}
}

// MARK: - Top Tab View Style

/// A tab view style with a tab bar at the top.
///
/// This style is useful for web/desktop layouts where top navigation is more
/// common than a bottom tab bar.
public struct TopTabViewStyle: TabViewStyle {
    public var tabBarPosition: TabBarPosition { .top }
    public var isSwipeable: Bool { false }
    public var showsTabBar: Bool { true }

    public init() {}
}

// MARK: - Page Tab View Style

/// A tab view style that presents tabs as swipeable pages.
///
/// This style displays each tab's content as a full-screen page without
/// a visible tab bar. Users can swipe between pages or use programmatic
/// navigation via selection binding.
///
/// ## Example
///
/// ```swift
/// TabView {
///     OnboardingPage1()
///     OnboardingPage2()
///     OnboardingPage3()
/// }
/// .tabViewStyle(.page)
/// ```
///
/// ## Example with Index Display
///
/// ```swift
/// TabView {
///     ForEach(pages) { page in
///         PageView(page: page)
///     }
/// }
/// .tabViewStyle(.page(indexDisplayMode: .always))
/// ```
///
/// ## Appearance
///
/// - No visible tab bar
/// - Full-screen content pages
/// - Optional page indicator dots
/// - Swipeable between pages
///
/// ## Use Cases
///
/// - Onboarding flows
/// - Image galleries
/// - Tutorial screens
/// - Full-screen content carousels
///
/// ## See Also
///
/// - ``TabViewStyle``
/// - ``TabView``
/// - ``PageIndexDisplayMode``
public struct PageTabViewStyle: TabViewStyle {
    /// The display mode for page indices.
    public let indexDisplayMode: PageIndexDisplayMode

    public var tabBarPosition: TabBarPosition { .none }
    public var isSwipeable: Bool { true }
    public var showsTabBar: Bool { false }

    /// Creates a page tab view style.
    ///
    /// - Parameter indexDisplayMode: How to display page indices (dots).
    public init(indexDisplayMode: PageIndexDisplayMode = .automatic) {
        self.indexDisplayMode = indexDisplayMode
    }
}

// MARK: - Page Index Display Mode

/// The display mode for page indices in a page-style tab view.
public enum PageIndexDisplayMode: Sendable {
    /// Automatically show or hide indices based on context
    case automatic
    /// Always show page indices
    case always
    /// Never show page indices
    case never
}

// MARK: - Tab View Style Environment

/// Environment key for tab view style.
private struct TabViewStyleKey: EnvironmentKey {
    static let defaultValue: any TabViewStyle = AutomaticTabViewStyle()
}

extension EnvironmentValues {
    /// The tab view style in the current environment.
    internal var tabViewStyle: any TabViewStyle {
        get { self[TabViewStyleKey.self] }
        set { self[TabViewStyleKey.self] = newValue }
    }
}

// MARK: - View Extension

extension View {
    /// Sets the style for tab views within this view.
    ///
    /// Use this modifier to customize the appearance and behavior of TabViews
    /// in the view hierarchy. The style affects all TabViews within this view
    /// unless overridden by a nested modifier.
    ///
    /// ## Example
    ///
    /// ```swift
    /// TabView {
    ///     HomeView().tabItem { Label("Home", systemImage: "house") }
    ///     ProfileView().tabItem { Label("Profile", systemImage: "person") }
    /// }
    /// .tabViewStyle(.automatic)
    /// ```
    ///
    /// ## Page Style
    ///
    /// ```swift
    /// TabView {
    ///     ForEach(images) { image in
    ///         ImageView(image: image)
    ///     }
    /// }
    /// .tabViewStyle(.page)
    /// ```
    ///
    /// - Parameter style: The tab view style to apply.
    /// - Returns: A view with the specified tab view style.
    ///
    /// ## See Also
    ///
    /// - ``TabViewStyle``
    /// - ``DefaultTabViewStyle``
    /// - ``PageTabViewStyle``
    @MainActor public func tabViewStyle<S: TabViewStyle>(_ style: S) -> some View {
        environment(\.tabViewStyle, style)
    }
}

// MARK: - Style Shortcuts

extension TabViewStyle where Self == AutomaticTabViewStyle {
    /// A platform-appropriate default style.
    ///
    /// ## Example
    ///
    /// ```swift
    /// TabView {
    ///     HomeView().tabItem { Label("Home", systemImage: "house") }
    /// }
    /// .tabViewStyle(.automatic)
    /// ```
    public static var automatic: AutomaticTabViewStyle {
        AutomaticTabViewStyle()
    }
}

extension TabViewStyle where Self == DefaultTabViewStyle {
    /// A bottom tab bar style (iOS-like).
    public static var bottom: DefaultTabViewStyle {
        DefaultTabViewStyle()
    }
}

extension TabViewStyle where Self == TopTabViewStyle {
    /// A tab view style with a top tab bar.
    public static var top: TopTabViewStyle {
        TopTabViewStyle()
    }
}

extension TabViewStyle where Self == PageTabViewStyle {
    /// A page-style tab view with optional page indicators.
    ///
    /// ## Example
    ///
    /// ```swift
    /// TabView {
    ///     Page1()
    ///     Page2()
    /// }
    /// .tabViewStyle(.page)
    /// ```
    ///
    /// - Parameter indexDisplayMode: How to display page indices.
    public static func page(indexDisplayMode: PageIndexDisplayMode = .automatic) -> PageTabViewStyle {
        PageTabViewStyle(indexDisplayMode: indexDisplayMode)
    }

    /// A page-style tab view with automatic page indicator display.
    public static var page: PageTabViewStyle {
        PageTabViewStyle()
    }
}
