import Foundation

/// A collection of environment values that propagate through the view hierarchy.
///
/// `EnvironmentValues` stores configuration data that can be read by any view
/// in the hierarchy. Values are set using the `.environment()` modifier and
/// accessed using the `@Environment` property wrapper.
///
/// Example:
/// ```swift
/// struct MyView: View {
///     @Environment(\.colorScheme) var colorScheme
///
///     var body: some View {
///         Text(colorScheme == .dark ? "Dark Mode" : "Light Mode")
///     }
/// }
/// ```
public struct EnvironmentValues: Sendable {
    /// Internal storage for environment values using type erasure
    internal var storage: [String: any Sendable]

    /// Creates a new set of environment values with default values.
    public init() {
        self.storage = [:]
    }

    /// Creates a new set of environment values with custom storage.
    ///
    /// This initializer is used internally when propagating environment values.
    internal init(storage: [String: any Sendable]) {
        self.storage = storage
    }

    /// Creates a copy of the environment values with modified storage.
    ///
    /// - Parameter storage: The new storage dictionary.
    /// - Returns: A new `EnvironmentValues` instance with the given storage.
    internal func with(storage: [String: any Sendable]) -> EnvironmentValues {
        EnvironmentValues(storage: storage)
    }
}

// MARK: - ColorScheme

/// The color scheme of the environment.
///
/// Use this to adapt your UI based on whether the user has selected
/// light or dark appearance.
public enum ColorScheme: String, Sendable, CaseIterable {
    /// Light color scheme (light backgrounds, dark text)
    case light

    /// Dark color scheme (dark backgrounds, light text)
    case dark
}

/// Environment key for the color scheme.
private struct ColorSchemeKey: EnvironmentKey {
    static let defaultValue: ColorScheme = .light
}

extension EnvironmentValues {
    /// The current color scheme (light or dark mode).
    ///
    /// Use this to adapt your UI based on the user's appearance preference:
    /// ```swift
    /// @Environment(\.colorScheme) var colorScheme
    ///
    /// var textColor: Color {
    ///     colorScheme == .dark ? .white : .black
    /// }
    /// ```
    public var colorScheme: ColorScheme {
        get { self[ColorSchemeKey.self] }
        set { self[ColorSchemeKey.self] = newValue }
    }
}

// MARK: - Font

// Note: Font type is defined in Views/Primitives/Font.swift
// This section only contains the environment integration

/// Environment key for the font.
private struct FontKey: EnvironmentKey {
    static let defaultValue: Font? = nil
}

extension EnvironmentValues {
    /// The default font to use for text in this environment.
    ///
    /// Use this to set a custom font for all text in a view hierarchy:
    /// ```swift
    /// VStack {
    ///     Text("Hello")
    ///     Text("World")
    /// }
    /// .environment(\.font, .headline)
    /// ```
    public var font: Font? {
        get { self[FontKey.self] }
        set { self[FontKey.self] = newValue }
    }
}

// MARK: - Content Size Category

// Note: ContentSizeCategory type is defined in Views/Primitives/Font.swift

/// Environment key for the content size category.
private struct ContentSizeCategoryKey: EnvironmentKey {
    static let defaultValue: ContentSizeCategory = .large
}

extension EnvironmentValues {
    /// The current content size category for Dynamic Type support.
    ///
    /// This value determines the text size scaling for accessibility.
    /// Full Dynamic Type support is planned for a future release.
    ///
    /// ```swift
    /// @Environment(\.sizeCategory) var sizeCategory
    /// ```
    public var sizeCategory: ContentSizeCategory {
        get { self[ContentSizeCategoryKey.self] }
        set { self[ContentSizeCategoryKey.self] = newValue }
    }
}

// MARK: - LayoutDirection

/// The layout direction for views.
public enum LayoutDirection: String, Sendable {
    /// Layout flows from left to right
    case leftToRight

    /// Layout flows from right to left
    case rightToLeft
}

/// Environment key for layout direction.
private struct LayoutDirectionKey: EnvironmentKey {
    static let defaultValue: LayoutDirection = .leftToRight
}

extension EnvironmentValues {
    /// The layout direction for views in this environment.
    ///
    /// This affects how views like HStack and text alignment work:
    /// ```swift
    /// @Environment(\.layoutDirection) var layoutDirection
    /// ```
    public var layoutDirection: LayoutDirection {
        get { self[LayoutDirectionKey.self] }
        set { self[LayoutDirectionKey.self] = newValue }
    }
}

// MARK: - DisplayScale

/// Environment key for display scale.
private struct DisplayScaleKey: EnvironmentKey {
    static let defaultValue: Double = 1.0
}

extension EnvironmentValues {
    /// The display scale of the current display.
    ///
    /// This represents the number of pixels per point (e.g., 2.0 for Retina displays).
    /// ```swift
    /// @Environment(\.displayScale) var displayScale
    /// ```
    public var displayScale: Double {
        get { self[DisplayScaleKey.self] }
        set { self[DisplayScaleKey.self] = newValue }
    }
}

// MARK: - IsEnabled

/// Environment key for the enabled state.
private struct IsEnabledKey: EnvironmentKey {
    static let defaultValue: Bool = true
}

extension EnvironmentValues {
    /// Whether views in this environment are enabled for user interaction.
    ///
    /// When set to false, views will be disabled and typically appear dimmed:
    /// ```swift
    /// Button("Click me") { }
    ///     .environment(\.isEnabled, false)
    /// ```
    public var isEnabled: Bool {
        get { self[IsEnabledKey.self] }
        set { self[IsEnabledKey.self] = newValue }
    }
}
