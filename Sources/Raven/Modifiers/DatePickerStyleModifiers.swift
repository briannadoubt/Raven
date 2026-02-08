import Foundation

// MARK: - Date Picker Styles

/// A type that specifies the appearance and interaction behavior of date pickers.
public protocol DatePickerStyle: Sendable {
    associatedtype Body: View

    /// Creates a view that represents the styled date picker.
    @MainActor func makeBody(configuration: Configuration) -> Body

    /// The properties of a date picker style.
    typealias Configuration = DatePickerStyleConfiguration
}

/// The properties of a date picker for style configuration.
public struct DatePickerStyleConfiguration: Sendable {
    /// The date picker label.
    public let label: String

    /// The date picker content.
    public let content: AnyView

    /// Creates a date picker style configuration.
    public init(label: String, content: AnyView) {
        self.label = label
        self.content = content
    }
}

/// The default automatic date picker style.
public struct AutomaticDatePickerStyle: DatePickerStyle {
    public init() {}

    @MainActor public func makeBody(configuration: Configuration) -> some View {
        configuration.content
    }
}

/// A compact date picker style.
public struct CompactDatePickerStyle: DatePickerStyle {
    public init() {}

    @MainActor public func makeBody(configuration: Configuration) -> some View {
        configuration.content
    }
}

extension DatePickerStyle where Self == AutomaticDatePickerStyle {
    /// The automatic date picker style.
    public static var automatic: AutomaticDatePickerStyle {
        AutomaticDatePickerStyle()
    }
}

extension DatePickerStyle where Self == CompactDatePickerStyle {
    /// The compact date picker style.
    public static var compact: CompactDatePickerStyle {
        CompactDatePickerStyle()
    }
}

private struct DatePickerStyleEnvironmentKey: EnvironmentKey {
    static let defaultValue: any DatePickerStyle = AutomaticDatePickerStyle()
}

extension EnvironmentValues {
    var datePickerStyle: any DatePickerStyle {
        get { self[DatePickerStyleEnvironmentKey.self] }
        set { self[DatePickerStyleEnvironmentKey.self] = newValue }
    }
}

extension View {
    /// Sets the style for date pickers within this view.
    ///
    /// - Parameter style: The date picker style to apply.
    /// - Returns: A view with the specified date picker style.
    @MainActor public func datePickerStyle(_ style: some DatePickerStyle) -> some View {
        environment(\.datePickerStyle, style)
    }
}
