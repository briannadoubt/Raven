import Foundation

// MARK: - GroupBox Styles

/// A type that specifies the appearance and interaction behavior of group boxes.
public protocol GroupBoxStyle: Sendable {
    associatedtype Body: View
    @MainActor func makeBody(configuration: Configuration) -> Body
    typealias Configuration = GroupBoxStyleConfiguration
}

extension GroupBoxStyle {
    @MainActor func _makeBodyAny(configuration: Configuration) -> AnyView {
        AnyView(makeBody(configuration: configuration))
    }
}

/// The properties of a group box for style configuration.
public struct GroupBoxStyleConfiguration: Sendable {
    public let label: AnyView?
    public let content: AnyView

    public init(label: AnyView?, content: AnyView) {
        self.label = label
        self.content = content
    }
}

/// A style that chooses the best group box appearance automatically.
public struct AutomaticGroupBoxStyle: GroupBoxStyle {
    public init() {}

    @MainActor public func makeBody(configuration: Configuration) -> some View {
        configuration.content
    }
}

/// The default group box style.
public struct DefaultGroupBoxStyle: GroupBoxStyle {
    public init() {}

    @MainActor public func makeBody(configuration: Configuration) -> some View {
        configuration.content
    }
}

extension GroupBoxStyle where Self == AutomaticGroupBoxStyle {
    /// The automatic group box style.
    public static var automatic: AutomaticGroupBoxStyle {
        AutomaticGroupBoxStyle()
    }
}

extension GroupBoxStyle where Self == DefaultGroupBoxStyle {
    /// The default group box style.
    public static var `default`: DefaultGroupBoxStyle {
        DefaultGroupBoxStyle()
    }
}

private struct GroupBoxStyleEnvironmentKey: EnvironmentKey {
    static let defaultValue: any GroupBoxStyle = AutomaticGroupBoxStyle()
}

extension EnvironmentValues {
    var groupBoxStyle: any GroupBoxStyle {
        get { self[GroupBoxStyleEnvironmentKey.self] }
        set { self[GroupBoxStyleEnvironmentKey.self] = newValue }
    }
}

extension View {
    /// Sets the style for group boxes within this view.
    @MainActor public func groupBoxStyle(_ style: some GroupBoxStyle) -> some View {
        environment(\.groupBoxStyle, style)
    }
}
