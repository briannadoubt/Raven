import Foundation

// MARK: - List Styles

/// A type that specifies the appearance and interaction behavior of lists.
public protocol ListStyle: Sendable {}

/// The default automatic list style.
public struct AutomaticListStyle: ListStyle {
    public init() {}
}

/// The default list style.
public struct DefaultListStyle: ListStyle {
    public init() {}
}

/// A plain list style.
public struct PlainListStyle: ListStyle {
    public init() {}
}

/// A grouped list style.
public struct GroupedListStyle: ListStyle {
    public init() {}
}

/// An inset list style.
public struct InsetListStyle: ListStyle {
    public init() {}
}

/// An inset grouped list style.
public struct InsetGroupedListStyle: ListStyle {
    public init() {}
}

/// A sidebar list style.
public struct SidebarListStyle: ListStyle {
    public init() {}
}

extension ListStyle where Self == AutomaticListStyle {
    /// The automatic list style.
    public static var automatic: AutomaticListStyle { AutomaticListStyle() }
}

extension ListStyle where Self == DefaultListStyle {
    /// The default list style.
    public static var `default`: DefaultListStyle { DefaultListStyle() }
}

extension ListStyle where Self == PlainListStyle {
    /// A plain list style.
    public static var plain: PlainListStyle { PlainListStyle() }
}

extension ListStyle where Self == GroupedListStyle {
    /// A grouped list style.
    public static var grouped: GroupedListStyle { GroupedListStyle() }
}

extension ListStyle where Self == InsetListStyle {
    /// An inset list style.
    public static var inset: InsetListStyle { InsetListStyle() }
}

extension ListStyle where Self == InsetGroupedListStyle {
    /// An inset grouped list style.
    public static var insetGrouped: InsetGroupedListStyle { InsetGroupedListStyle() }
}

extension ListStyle where Self == SidebarListStyle {
    /// A sidebar list style.
    public static var sidebar: SidebarListStyle { SidebarListStyle() }
}

private struct ListStyleEnvironmentKey: EnvironmentKey {
    static let defaultValue: any ListStyle = AutomaticListStyle()
}

extension EnvironmentValues {
    var listStyle: any ListStyle {
        get { self[ListStyleEnvironmentKey.self] }
        set { self[ListStyleEnvironmentKey.self] = newValue }
    }
}

extension View {
    /// Sets the style for lists within this view hierarchy.
    @MainActor public func listStyle(_ style: some ListStyle) -> some View {
        environment(\.listStyle, style)
    }
}
