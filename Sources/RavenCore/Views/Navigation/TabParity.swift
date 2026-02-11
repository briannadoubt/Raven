import Foundation

/// Default tab title content used by SwiftUI's tab APIs.
@MainActor
public struct DefaultTabLabel: View, Sendable {
    public init() {}

    public var body: some View {
        Text("Tab")
    }
}

/// A SwiftUI-style tab declaration for use inside `TabView`.
///
/// Raven lowers `Tab` into existing `.tabItem { ... }.tag(...)` behavior.
@MainActor
public struct Tab<SelectionValue, Content, TabLabel>: View, Sendable
where SelectionValue: Hashable & Sendable, Content: View, TabLabel: View {
    private let selectionValue: SelectionValue
    private let content: Content
    private let label: TabLabel

    public init(
        value: SelectionValue,
        @ViewBuilder content: () -> Content,
        @ViewBuilder label: () -> TabLabel
    ) {
        self.selectionValue = value
        self.content = content()
        self.label = label()
    }

    public var body: some View {
        content
            .tabItem { label }
            .tag(selectionValue)
    }
}

extension Tab: _AnyTabConfigurable {
    func _extractTabConfiguration<DesiredSelection: Hashable & Sendable>(
        as _: DesiredSelection.Type
    ) -> (tagValue: DesiredSelection?, tabItem: TabItem, badge: String?, content: AnyView) {
        let item = TabItem(id: UUID().uuidString, label: label, badge: nil)
        return (
            tagValue: selectionValue as? DesiredSelection,
            tabItem: item,
            badge: nil,
            content: AnyView(content)
        )
    }
}

extension Tab: TabConfigurable {
    @MainActor
    func extractTabConfiguration() -> (tabItem: TabItem, badge: String?, content: AnyView)? {
        let item = TabItem(id: UUID().uuidString, label: label, badge: nil)
        return (tabItem: item, badge: nil, content: AnyView(content))
    }
}

extension Tab where TabLabel == Text {
    @MainActor
    public init(
        _ title: String,
        value: SelectionValue,
        @ViewBuilder content: () -> Content
    ) {
        self.init(value: value, content: content) {
            Text(title)
        }
    }

    @MainActor
    public init(
        _ titleKey: LocalizedStringKey,
        value: SelectionValue,
        @ViewBuilder content: () -> Content
    ) {
        self.init(value: value, content: content) {
            Text(titleKey)
        }
    }
}

extension Tab where TabLabel == Label<Text, Image> {
    @MainActor
    public init(
        _ title: String,
        systemImage: String,
        value: SelectionValue,
        @ViewBuilder content: () -> Content
    ) {
        self.init(value: value, content: content) {
            Label(title, systemImage: systemImage)
        }
    }

    @MainActor
    public init(
        _ titleKey: LocalizedStringKey,
        systemImage: String,
        value: SelectionValue,
        @ViewBuilder content: () -> Content
    ) {
        self.init(value: value, content: content) {
            Label(titleKey, systemImage: systemImage)
        }
    }
}

/// Groups related tabs together in a `TabView` declaration.
///
/// Raven currently treats `TabSection` as a lightweight grouping wrapper.
@MainActor
public struct TabSection<Content: View, SectionLabel: View>: View, Sendable {
    private let content: Content
    private let label: SectionLabel

    public init(@ViewBuilder content: () -> Content, @ViewBuilder label: () -> SectionLabel) {
        self.content = content()
        self.label = label()
    }

    public var body: some View {
        content
    }
}

extension TabSection: _TabSectionContentProvider {
    func _extractSectionTabs() -> [any View] {
        if let tuple = content as? any _ViewTuple {
            return tuple._extractChildren()
        }
        return [content]
    }
}

extension TabSection where SectionLabel == Text {
    @MainActor
    public init(_ title: String, @ViewBuilder content: () -> Content) {
        self.init(content: content) {
            Text(title)
        }
    }

    @MainActor
    public init(_ titleKey: LocalizedStringKey, @ViewBuilder content: () -> Content) {
        self.init(content: content) {
            Text(titleKey)
        }
    }
}
