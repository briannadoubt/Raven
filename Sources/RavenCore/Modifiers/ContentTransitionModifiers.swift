import Foundation

/// A transition that defines how view content changes animate.
public struct ContentTransition: Sendable, Hashable {
    fileprivate let rawValue: String

    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }

    /// No special content transition.
    public static let identity = ContentTransition("identity")
    /// Fade between old and new content.
    public static let opacity = ContentTransition("opacity")
    /// Interpolate text and numeric content where possible.
    public static let interpolate = ContentTransition("interpolate")
}

extension ContentTransition {
    /// Numeric text transition variant matching SwiftUI surface.
    public static func numericText() -> ContentTransition {
        ContentTransition("numericText")
    }
}

/// Dynamic Type sizing buckets.
public enum DynamicTypeSize: String, Sendable, Hashable, CaseIterable {
    case xSmall
    case small
    case medium
    case large
    case xLarge
    case xxLarge
    case xxxLarge
    case accessibility1
    case accessibility2
    case accessibility3
    case accessibility4
    case accessibility5
}

extension DynamicTypeSize {
    fileprivate var contentSizeCategory: ContentSizeCategory {
        switch self {
        case .xSmall: return .extraSmall
        case .small: return .small
        case .medium: return .medium
        case .large: return .large
        case .xLarge: return .extraLarge
        case .xxLarge: return .extraExtraLarge
        case .xxxLarge: return .extraExtraExtraLarge
        case .accessibility1: return .accessibilityMedium
        case .accessibility2: return .accessibilityLarge
        case .accessibility3: return .accessibilityExtraLarge
        case .accessibility4: return .accessibilityExtraExtraLarge
        case .accessibility5: return .accessibilityExtraExtraExtraLarge
        }
    }
}

/// Visual contrast preference of the current color scheme.
public enum ColorSchemeContrast: String, Sendable, Hashable, CaseIterable {
    case standard
    case increased
}

private struct ContentTransitionKey: EnvironmentKey {
    static let defaultValue: ContentTransition = .identity
}

private struct DynamicTypeSizeKey: EnvironmentKey {
    static let defaultValue: DynamicTypeSize = .large
}

private struct ColorSchemeContrastKey: EnvironmentKey {
    static let defaultValue: ColorSchemeContrast = .standard
}

extension EnvironmentValues {
    /// The preferred transition for changing view content.
    public var contentTransition: ContentTransition {
        get { self[ContentTransitionKey.self] }
        set { self[ContentTransitionKey.self] = newValue }
    }

    /// The current Dynamic Type size category.
    public var dynamicTypeSize: DynamicTypeSize {
        get { self[DynamicTypeSizeKey.self] }
        set { self[DynamicTypeSizeKey.self] = newValue }
    }

    /// The current color contrast preference.
    public var colorSchemeContrast: ColorSchemeContrast {
        get { self[ColorSchemeContrastKey.self] }
        set { self[ColorSchemeContrastKey.self] = newValue }
    }
}

public struct _ContentTransitionModifierView<Content: View>: View, PrimitiveView, Sendable {
    let content: Content
    let transition: ContentTransition

    public typealias Body = Never

    @MainActor public func toVNode() -> VNode {
        VNode.element(
            "div",
            props: [
                "data-content-transition": .attribute(name: "data-content-transition", value: transition.rawValue)
            ],
            children: []
        )
    }
}

extension _ContentTransitionModifierView: _ModifierRenderable {
    public var _modifiedContent: Content { content }
}

extension View {
    /// Sets the transition used when this view's content changes.
    @MainActor public func contentTransition(_ transition: ContentTransition) -> some View {
        _ContentTransitionModifierView(content: self, transition: transition)
            .environment(\.contentTransition, transition)
    }

    /// Sets a specific Dynamic Type size for this view hierarchy.
    @MainActor public func dynamicTypeSize(_ size: DynamicTypeSize) -> some View {
        environment(\.dynamicTypeSize, size)
            .environment(\.sizeCategory, size.contentSizeCategory)
    }

    /// Sets the preferred color scheme contrast for this view hierarchy.
    @MainActor public func colorSchemeContrast(_ contrast: ColorSchemeContrast) -> some View {
        environment(\.colorSchemeContrast, contrast)
    }
}
