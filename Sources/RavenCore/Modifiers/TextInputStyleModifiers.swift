import Foundation

// MARK: - TextField Styles

/// A type that specifies the appearance and interaction behavior of text fields.
public protocol TextFieldStyle: Sendable {
    associatedtype Body: View
    @MainActor func makeBody(configuration: Configuration) -> Body
    typealias Configuration = TextFieldStyleConfiguration
}

/// The properties of a text field for style configuration.
public struct TextFieldStyleConfiguration: Sendable {
    public let content: AnyView

    public init(content: AnyView) {
        self.content = content
    }
}

/// The default automatic text field style.
public struct DefaultTextFieldStyle: TextFieldStyle {
    public init() {}

    @MainActor public func makeBody(configuration: Configuration) -> some View {
        configuration.content
    }
}

/// A plain text field style.
public struct PlainTextFieldStyle: TextFieldStyle {
    public init() {}

    @MainActor public func makeBody(configuration: Configuration) -> some View {
        configuration.content
    }
}

/// A text field style that uses a rounded border.
public struct RoundedBorderTextFieldStyle: TextFieldStyle {
    public init() {}

    @MainActor public func makeBody(configuration: Configuration) -> some View {
        configuration.content
    }
}

extension TextFieldStyle where Self == DefaultTextFieldStyle {
    /// The default text field style.
    public static var `default`: DefaultTextFieldStyle {
        DefaultTextFieldStyle()
    }
}

extension TextFieldStyle where Self == PlainTextFieldStyle {
    /// A plain text field style.
    public static var plain: PlainTextFieldStyle {
        PlainTextFieldStyle()
    }
}

extension TextFieldStyle where Self == RoundedBorderTextFieldStyle {
    /// A text field style that uses a rounded border.
    public static var roundedBorder: RoundedBorderTextFieldStyle {
        RoundedBorderTextFieldStyle()
    }
}

private struct TextFieldStyleEnvironmentKey: EnvironmentKey {
    static let defaultValue: any TextFieldStyle = DefaultTextFieldStyle()
}

extension EnvironmentValues {
    var textFieldStyle: any TextFieldStyle {
        get { self[TextFieldStyleEnvironmentKey.self] }
        set { self[TextFieldStyleEnvironmentKey.self] = newValue }
    }
}

extension View {
    /// Sets the style for text fields within this view.
    @MainActor public func textFieldStyle(_ style: some TextFieldStyle) -> some View {
        environment(\.textFieldStyle, style)
    }
}

// MARK: - TextEditor Styles

/// A type that specifies the appearance and interaction behavior of text editors.
public protocol TextEditorStyle: Sendable {
    associatedtype Body: View
    @MainActor func makeBody(configuration: Configuration) -> Body
    typealias Configuration = TextEditorStyleConfiguration
}

/// The properties of a text editor for style configuration.
public struct TextEditorStyleConfiguration: Sendable {
    public let content: AnyView

    public init(content: AnyView) {
        self.content = content
    }
}

/// The default automatic text editor style.
public struct AutomaticTextEditorStyle: TextEditorStyle {
    public init() {}

    @MainActor public func makeBody(configuration: Configuration) -> some View {
        configuration.content
    }
}

/// A plain text editor style.
public struct PlainTextEditorStyle: TextEditorStyle {
    public init() {}

    @MainActor public func makeBody(configuration: Configuration) -> some View {
        configuration.content
    }
}

extension TextEditorStyle where Self == AutomaticTextEditorStyle {
    /// The default text editor style.
    public static var automatic: AutomaticTextEditorStyle {
        AutomaticTextEditorStyle()
    }
}

extension TextEditorStyle where Self == PlainTextEditorStyle {
    /// A plain text editor style.
    public static var plain: PlainTextEditorStyle {
        PlainTextEditorStyle()
    }
}

private struct TextEditorStyleEnvironmentKey: EnvironmentKey {
    static let defaultValue: any TextEditorStyle = AutomaticTextEditorStyle()
}

extension EnvironmentValues {
    var textEditorStyle: any TextEditorStyle {
        get { self[TextEditorStyleEnvironmentKey.self] }
        set { self[TextEditorStyleEnvironmentKey.self] = newValue }
    }
}

extension View {
    /// Sets the style for text editors within this view.
    @MainActor public func textEditorStyle(_ style: some TextEditorStyle) -> some View {
        environment(\.textEditorStyle, style)
    }
}
