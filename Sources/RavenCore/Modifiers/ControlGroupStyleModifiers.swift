import Foundation

// MARK: - Control Group Styles

/// A type that specifies the appearance and interaction behavior of control groups.
public protocol ControlGroupStyle: Sendable {
    associatedtype Body: View

    /// Creates a view that represents the styled control group.
    @MainActor func makeBody(configuration: Configuration) -> Body

    /// The properties of a control group style.
    typealias Configuration = ControlGroupStyleConfiguration
}

/// The properties of a control group for style configuration.
public struct ControlGroupStyleConfiguration: Sendable {
    /// The control group content.
    public let content: AnyView

    /// Creates a control group style configuration.
    public init(content: AnyView) {
        self.content = content
    }
}

/// The default automatic control group style.
public struct AutomaticControlGroupStyle: ControlGroupStyle {
    public init() {}

    @MainActor public func makeBody(configuration: Configuration) -> some View {
        configuration.content
    }
}

/// A compact menu control group style.
public struct CompactMenuControlGroupStyle: ControlGroupStyle {
    public init() {}

    @MainActor public func makeBody(configuration: Configuration) -> some View {
        configuration.content
    }
}

extension ControlGroupStyle where Self == AutomaticControlGroupStyle {
    /// The automatic control group style.
    public static var automatic: AutomaticControlGroupStyle {
        AutomaticControlGroupStyle()
    }
}

extension ControlGroupStyle where Self == CompactMenuControlGroupStyle {
    /// A compact menu control group style.
    public static var compactMenu: CompactMenuControlGroupStyle {
        CompactMenuControlGroupStyle()
    }
}

private struct ControlGroupStyleEnvironmentKey: EnvironmentKey {
    static let defaultValue: any ControlGroupStyle = AutomaticControlGroupStyle()
}

extension EnvironmentValues {
    var controlGroupStyle: any ControlGroupStyle {
        get { self[ControlGroupStyleEnvironmentKey.self] }
        set { self[ControlGroupStyleEnvironmentKey.self] = newValue }
    }
}

extension View {
    /// Sets the style for control groups within this view.
    ///
    /// - Parameter style: The control group style to apply.
    /// - Returns: A view with the specified control group style.
    @MainActor public func controlGroupStyle(_ style: some ControlGroupStyle) -> some View {
        environment(\.controlGroupStyle, style)
    }
}
