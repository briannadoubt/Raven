import Foundation

// MARK: - Form Styles

/// A type that specifies the appearance and interaction behavior of forms.
public protocol FormStyle: Sendable {
    associatedtype Body: View
    @MainActor func makeBody(configuration: Configuration) -> Body
    typealias Configuration = FormStyleConfiguration
}

/// The properties of a form for style configuration.
public struct FormStyleConfiguration: Sendable {
    public let content: AnyView

    public init(content: AnyView) {
        self.content = content
    }
}

/// The default automatic form style.
public struct AutomaticFormStyle: FormStyle {
    public init() {}

    @MainActor public func makeBody(configuration: Configuration) -> some View {
        configuration.content
    }
}

/// A grouped form style.
public struct GroupedFormStyle: FormStyle {
    public init() {}

    @MainActor public func makeBody(configuration: Configuration) -> some View {
        configuration.content
    }
}

/// A column-based form style.
public struct ColumnsFormStyle: FormStyle {
    public init() {}

    @MainActor public func makeBody(configuration: Configuration) -> some View {
        configuration.content
    }
}

extension FormStyle where Self == AutomaticFormStyle {
    /// The automatic form style.
    public static var automatic: AutomaticFormStyle {
        AutomaticFormStyle()
    }
}

extension FormStyle where Self == GroupedFormStyle {
    /// A grouped form style.
    public static var grouped: GroupedFormStyle {
        GroupedFormStyle()
    }
}

extension FormStyle where Self == ColumnsFormStyle {
    /// A column-based form style.
    public static var columns: ColumnsFormStyle {
        ColumnsFormStyle()
    }
}

private struct FormStyleEnvironmentKey: EnvironmentKey {
    static let defaultValue: any FormStyle = AutomaticFormStyle()
}

extension EnvironmentValues {
    var formStyle: any FormStyle {
        get { self[FormStyleEnvironmentKey.self] }
        set { self[FormStyleEnvironmentKey.self] = newValue }
    }
}

extension View {
    /// Sets the style for forms within this view.
    @MainActor public func formStyle(_ style: some FormStyle) -> some View {
        environment(\.formStyle, style)
    }
}

// MARK: - Disclosure Group Styles

/// A type that specifies the appearance and interaction behavior of disclosure groups.
public protocol DisclosureGroupStyle: Sendable {
    associatedtype Body: View
    @MainActor func makeBody(configuration: Configuration) -> Body
    typealias Configuration = DisclosureGroupStyleConfiguration
}

/// The properties of a disclosure group for style configuration.
public struct DisclosureGroupStyleConfiguration: Sendable {
    public let label: AnyView
    public let content: AnyView
    public let isExpanded: Bool

    public init(label: AnyView, content: AnyView, isExpanded: Bool) {
        self.label = label
        self.content = content
        self.isExpanded = isExpanded
    }
}

/// The default automatic disclosure group style.
public struct AutomaticDisclosureGroupStyle: DisclosureGroupStyle {
    public init() {}

    @MainActor public func makeBody(configuration: Configuration) -> some View {
        configuration.content
    }
}

extension DisclosureGroupStyle where Self == AutomaticDisclosureGroupStyle {
    /// The automatic disclosure group style.
    public static var automatic: AutomaticDisclosureGroupStyle {
        AutomaticDisclosureGroupStyle()
    }
}

private struct DisclosureGroupStyleEnvironmentKey: EnvironmentKey {
    static let defaultValue: any DisclosureGroupStyle = AutomaticDisclosureGroupStyle()
}

extension EnvironmentValues {
    var disclosureGroupStyle: any DisclosureGroupStyle {
        get { self[DisclosureGroupStyleEnvironmentKey.self] }
        set { self[DisclosureGroupStyleEnvironmentKey.self] = newValue }
    }
}

extension View {
    /// Sets the style for disclosure groups within this view.
    @MainActor public func disclosureGroupStyle(_ style: some DisclosureGroupStyle) -> some View {
        environment(\.disclosureGroupStyle, style)
    }
}

// MARK: - Labeled Content Styles

/// A type that specifies the appearance and interaction behavior of labeled content.
public protocol LabeledContentStyle: Sendable {
    associatedtype Body: View
    @MainActor func makeBody(configuration: Configuration) -> Body
    typealias Configuration = LabeledContentStyleConfiguration
}

/// The properties of labeled content for style configuration.
public struct LabeledContentStyleConfiguration: Sendable {
    public let label: AnyView
    public let content: AnyView

    public init(label: AnyView, content: AnyView) {
        self.label = label
        self.content = content
    }
}

/// The default automatic labeled content style.
public struct AutomaticLabeledContentStyle: LabeledContentStyle {
    public init() {}

    @MainActor public func makeBody(configuration: Configuration) -> some View {
        configuration.content
    }
}

extension LabeledContentStyle where Self == AutomaticLabeledContentStyle {
    /// The automatic labeled content style.
    public static var automatic: AutomaticLabeledContentStyle {
        AutomaticLabeledContentStyle()
    }
}

private struct LabeledContentStyleEnvironmentKey: EnvironmentKey {
    static let defaultValue: any LabeledContentStyle = AutomaticLabeledContentStyle()
}

extension EnvironmentValues {
    var labeledContentStyle: any LabeledContentStyle {
        get { self[LabeledContentStyleEnvironmentKey.self] }
        set { self[LabeledContentStyleEnvironmentKey.self] = newValue }
    }
}

extension View {
    /// Sets the style for labeled content views within this view.
    @MainActor public func labeledContentStyle(_ style: some LabeledContentStyle) -> some View {
        environment(\.labeledContentStyle, style)
    }
}

// MARK: - Table Styles

/// A type that specifies the appearance and interaction behavior of tables.
public protocol TableStyle: Sendable {
    associatedtype Body: View
    @MainActor func makeBody(configuration: Configuration) -> Body
    typealias Configuration = TableStyleConfiguration
}

/// The properties of a table for style configuration.
public struct TableStyleConfiguration: Sendable {
    public let content: AnyView

    public init(content: AnyView) {
        self.content = content
    }
}

/// The default automatic table style.
public struct AutomaticTableStyle: TableStyle {
    public init() {}

    @MainActor public func makeBody(configuration: Configuration) -> some View {
        configuration.content
    }
}

/// An inset table style.
public struct InsetTableStyle: TableStyle {
    public init() {}

    @MainActor public func makeBody(configuration: Configuration) -> some View {
        configuration.content
    }
}

extension TableStyle where Self == AutomaticTableStyle {
    /// The automatic table style.
    public static var automatic: AutomaticTableStyle {
        AutomaticTableStyle()
    }
}

extension TableStyle where Self == InsetTableStyle {
    /// An inset table style.
    public static var inset: InsetTableStyle {
        InsetTableStyle()
    }
}

private struct TableStyleEnvironmentKey: EnvironmentKey {
    static let defaultValue: any TableStyle = AutomaticTableStyle()
}

extension EnvironmentValues {
    var tableStyle: any TableStyle {
        get { self[TableStyleEnvironmentKey.self] }
        set { self[TableStyleEnvironmentKey.self] = newValue }
    }
}

extension View {
    /// Sets the style for tables within this view.
    @MainActor public func tableStyle(_ style: some TableStyle) -> some View {
        environment(\.tableStyle, style)
    }
}
