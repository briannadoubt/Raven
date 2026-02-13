import Foundation

// MARK: - Label Styles

/// A type that specifies the appearance and interaction behavior of labels.
public protocol LabelStyle: Sendable {
    associatedtype Body: View
    @MainActor func makeBody(configuration: Configuration) -> Body
    typealias Configuration = LabelStyleConfiguration
}

extension LabelStyle {
    @MainActor func _makeBodyAny(configuration: Configuration) -> AnyView {
        AnyView(makeBody(configuration: configuration))
    }
}

/// The properties of a label for style configuration.
public struct LabelStyleConfiguration: Sendable {
    public let title: AnyView
    public let icon: AnyView

    public init(title: AnyView, icon: AnyView) {
        self.title = title
        self.icon = icon
    }
}

/// A style that chooses the best label rendering for the current context.
public struct AutomaticLabelStyle: LabelStyle {
    public init() {}

    @MainActor public func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 8) {
            configuration.icon
            configuration.title
        }
    }
}

/// The default label style.
public struct DefaultLabelStyle: LabelStyle {
    public init() {}

    @MainActor public func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 8) {
            configuration.icon
            configuration.title
        }
    }
}

/// A label style that shows only the icon.
public struct IconOnlyLabelStyle: LabelStyle {
    public init() {}

    @MainActor public func makeBody(configuration: Configuration) -> some View {
        configuration.icon
    }
}

/// A label style that shows only the title.
public struct TitleOnlyLabelStyle: LabelStyle {
    public init() {}

    @MainActor public func makeBody(configuration: Configuration) -> some View {
        configuration.title
    }
}

/// A label style that shows title and icon.
public struct TitleAndIconLabelStyle: LabelStyle {
    public init() {}

    @MainActor public func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 8) {
            configuration.icon
            configuration.title
        }
    }
}

extension LabelStyle where Self == AutomaticLabelStyle {
    /// The automatic label style.
    public static var automatic: AutomaticLabelStyle {
        AutomaticLabelStyle()
    }
}

extension LabelStyle where Self == DefaultLabelStyle {
    /// The default label style.
    public static var `default`: DefaultLabelStyle {
        DefaultLabelStyle()
    }
}

extension LabelStyle where Self == IconOnlyLabelStyle {
    /// A label style that shows only the icon.
    public static var iconOnly: IconOnlyLabelStyle {
        IconOnlyLabelStyle()
    }
}

extension LabelStyle where Self == TitleOnlyLabelStyle {
    /// A label style that shows only the title.
    public static var titleOnly: TitleOnlyLabelStyle {
        TitleOnlyLabelStyle()
    }
}

extension LabelStyle where Self == TitleAndIconLabelStyle {
    /// A label style that shows title and icon.
    public static var titleAndIcon: TitleAndIconLabelStyle {
        TitleAndIconLabelStyle()
    }
}

private struct LabelStyleEnvironmentKey: EnvironmentKey {
    static let defaultValue: any LabelStyle = AutomaticLabelStyle()
}

extension EnvironmentValues {
    var labelStyle: any LabelStyle {
        get { self[LabelStyleEnvironmentKey.self] }
        set { self[LabelStyleEnvironmentKey.self] = newValue }
    }
}

extension View {
    /// Sets the style for labels within this view.
    @MainActor public func labelStyle(_ style: some LabelStyle) -> some View {
        environment(\.labelStyle, style)
    }
}
