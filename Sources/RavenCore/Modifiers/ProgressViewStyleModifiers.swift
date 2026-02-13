import Foundation

// MARK: - Progress View Styles

/// A type that specifies the appearance and interaction behavior of progress views.
public protocol ProgressViewStyle: Sendable {
    associatedtype Body: View
    @MainActor func makeBody(configuration: Configuration) -> Body
    typealias Configuration = ProgressViewStyleConfiguration
}

/// The properties of a progress view for style configuration.
public struct ProgressViewStyleConfiguration: Sendable {
    public let label: AnyView?
    public let value: Double?
    public let total: Double

    public init(label: AnyView?, value: Double?, total: Double) {
        self.label = label
        self.value = value
        self.total = total
    }
}

/// A style that chooses the best progress view appearance automatically.
public struct AutomaticProgressViewStyle: ProgressViewStyle {
    public init() {}

    @MainActor public func makeBody(configuration: Configuration) -> some View {
        ProgressView(
            value: configuration.value ?? 0,
            total: configuration.total
        )
    }
}

/// The default progress view style.
public struct DefaultProgressViewStyle: ProgressViewStyle {
    public init() {}

    @MainActor public func makeBody(configuration: Configuration) -> some View {
        ProgressView(
            value: configuration.value ?? 0,
            total: configuration.total
        )
    }
}

/// A circular progress view style.
public struct CircularProgressViewStyle: ProgressViewStyle {
    public init() {}

    @MainActor public func makeBody(configuration: Configuration) -> some View {
        ProgressView()
    }
}

/// A linear progress view style.
public struct LinearProgressViewStyle: ProgressViewStyle {
    public init() {}

    @MainActor public func makeBody(configuration: Configuration) -> some View {
        ProgressView(
            value: configuration.value ?? 0,
            total: configuration.total
        )
    }
}

extension ProgressViewStyle where Self == AutomaticProgressViewStyle {
    /// The automatic progress view style.
    public static var automatic: AutomaticProgressViewStyle {
        AutomaticProgressViewStyle()
    }
}

extension ProgressViewStyle where Self == DefaultProgressViewStyle {
    /// The default progress view style.
    public static var `default`: DefaultProgressViewStyle {
        DefaultProgressViewStyle()
    }
}

extension ProgressViewStyle where Self == CircularProgressViewStyle {
    /// A circular progress view style.
    public static var circular: CircularProgressViewStyle {
        CircularProgressViewStyle()
    }
}

extension ProgressViewStyle where Self == LinearProgressViewStyle {
    /// A linear progress view style.
    public static var linear: LinearProgressViewStyle {
        LinearProgressViewStyle()
    }
}

private struct ProgressViewStyleEnvironmentKey: EnvironmentKey {
    static let defaultValue: any ProgressViewStyle = AutomaticProgressViewStyle()
}

extension EnvironmentValues {
    var progressViewStyle: any ProgressViewStyle {
        get { self[ProgressViewStyleEnvironmentKey.self] }
        set { self[ProgressViewStyleEnvironmentKey.self] = newValue }
    }
}

extension View {
    /// Sets the style for progress views within this view.
    @MainActor public func progressViewStyle(_ style: some ProgressViewStyle) -> some View {
        environment(\.progressViewStyle, style)
    }
}
