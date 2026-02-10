import Foundation

/// A three-column navigation container that adapts to available space.
///
/// `NavigationSplitView` mirrors SwiftUI's split view API by hosting sidebar,
/// content, and optional detail columns. Raven renders the split layout using
/// flexbox, with column visibility driven by the supplied binding.
public struct NavigationSplitView<Sidebar: View, Content: View, Detail: View>: View, Sendable {
    @Environment(\.navigationSplitViewStyle) private var style

    private let columnVisibility: Binding<NavigationSplitViewVisibility>
    private let sidebar: Sidebar
    private let content: Content
    private let detail: Detail
    private let hasDetail: Bool

    /// Creates a split view with sidebar, content, and detail columns.
    @MainActor
    public init(
        columnVisibility: Binding<NavigationSplitViewVisibility> = .constant(.automatic),
        @ViewBuilder sidebar: () -> Sidebar,
        @ViewBuilder content: () -> Content,
        @ViewBuilder detail: () -> Detail
    ) {
        self.columnVisibility = columnVisibility
        self.sidebar = sidebar()
        self.content = content()
        self.detail = detail()
        self.hasDetail = Detail.self != EmptyView.self
    }

    /// Creates a split view with sidebar and content columns only.
    @MainActor
    public init(
        columnVisibility: Binding<NavigationSplitViewVisibility> = .constant(.automatic),
        @ViewBuilder sidebar: () -> Sidebar,
        @ViewBuilder content: () -> Content
    ) where Detail == EmptyView {
        self.columnVisibility = columnVisibility
        self.sidebar = sidebar()
        self.content = content()
        self.detail = EmptyView()
        self.hasDetail = false
    }

    @MainActor public var body: some View {
        NavigationSplitViewContainer(
            sidebar: AnyView(sidebar),
            content: AnyView(content),
            detail: hasDetail ? AnyView(detail) : nil,
            columnVisibility: columnVisibility,
            layout: style.layout
        )
    }
}

/// Controls which columns are visible in a navigation split view.
public enum NavigationSplitViewVisibility: String, CaseIterable, Hashable, Sendable {
    case automatic
    case all
    case doubleColumn
    case detailOnly
}

/// Identifies columns in a navigation split view.
public enum NavigationSplitViewColumn: Hashable, Sendable {
    case sidebar
    case content
    case detail
}

// MARK: - Internal Layout

public struct NavigationSplitViewLayout: Sendable {
    public let sidebarFlex: Double
    public let contentFlex: Double
    public let detailFlex: Double
    public let sidebarMinWidth: Double
    public let contentMinWidth: Double
    public let detailMinWidth: Double
    public let columnGap: Double

    public static let automatic = NavigationSplitViewLayout(
        sidebarFlex: 1.0,
        contentFlex: 1.6,
        detailFlex: 1.6,
        sidebarMinWidth: 180,
        contentMinWidth: 240,
        detailMinWidth: 260,
        columnGap: 16
    )

    public static let balanced = NavigationSplitViewLayout(
        sidebarFlex: 1.0,
        contentFlex: 1.0,
        detailFlex: 1.0,
        sidebarMinWidth: 180,
        contentMinWidth: 220,
        detailMinWidth: 220,
        columnGap: 16
    )

    public static let prominentDetail = NavigationSplitViewLayout(
        sidebarFlex: 0.9,
        contentFlex: 1.1,
        detailFlex: 2.0,
        sidebarMinWidth: 180,
        contentMinWidth: 220,
        detailMinWidth: 300,
        columnGap: 16
    )
}

@MainActor
struct NavigationSplitViewContainer: View, PrimitiveView, Sendable {
    typealias Body = Never

    let sidebar: AnyView
    let content: AnyView
    let detail: AnyView?
    let columnVisibility: Binding<NavigationSplitViewVisibility>
    let layout: NavigationSplitViewLayout

    @MainActor public func toVNode() -> VNode {
        let props: [String: VProperty] = [
            "class": .attribute(name: "class", value: "raven-navigation-split-view"),
            "display": .style(name: "display", value: "flex"),
            "gap": .style(name: "gap", value: "\(layout.columnGap)px"),
            "align-items": .style(name: "align-items", value: "stretch")
        ]
        return VNode.element("div", props: props, children: [])
    }

    private func makeColumnProps(
        className: String,
        flex: Double,
        minWidth: Double
    ) -> [String: VProperty] {
        [
            "class": .attribute(name: "class", value: className),
            "flex": .style(name: "flex", value: "\(flex) 1 0%"),
            "min-width": .style(name: "min-width", value: "\(minWidth)px"),
            "padding": .style(name: "padding", value: "12px"),
            "border": .style(name: "border", value: "1px solid rgba(0, 0, 0, 0.08)"),
            "border-radius": .style(name: "border-radius", value: "8px"),
            "background": .style(name: "background", value: "rgba(255, 255, 255, 0.6)"),
            "overflow": .style(name: "overflow", value: "auto")
        ]
    }

    private func wrapChildren(_ node: VNode) -> [VNode] {
        if case .fragment = node.type {
            return node.children
        }
        return [node]
    }

    @MainActor private func renderColumn(
        _ view: AnyView,
        className: String,
        flex: Double,
        minWidth: Double,
        context: any _RenderContext
    ) -> VNode {
        let node = context.renderChild(view)
        return VNode.element(
            "div",
            props: makeColumnProps(className: className, flex: flex, minWidth: minWidth),
            children: wrapChildren(node)
        )
    }
}

extension NavigationSplitViewContainer: _CoordinatorRenderable {
    @MainActor public func _render(with context: any _RenderContext) -> VNode {
        let visibility = columnVisibility.wrappedValue
        var showSidebar = true
        var showContent = true
        var showDetail = detail != nil

        switch visibility {
        case .automatic, .all:
            break
        case .doubleColumn:
            showDetail = false
        case .detailOnly:
            showSidebar = false
            showContent = false
        }

        var children: [VNode] = []

        if showSidebar {
            children.append(
                renderColumn(
                    sidebar,
                    className: "raven-navigation-split-sidebar",
                    flex: layout.sidebarFlex,
                    minWidth: layout.sidebarMinWidth,
                    context: context
                )
            )
        }

        if showContent {
            children.append(
                renderColumn(
                    content,
                    className: "raven-navigation-split-content",
                    flex: layout.contentFlex,
                    minWidth: layout.contentMinWidth,
                    context: context
                )
            )
        }

        if showDetail, let detail {
            children.append(
                renderColumn(
                    detail,
                    className: "raven-navigation-split-detail",
                    flex: layout.detailFlex,
                    minWidth: layout.detailMinWidth,
                    context: context
                )
            )
        }

        let props: [String: VProperty] = [
            "class": .attribute(name: "class", value: "raven-navigation-split-view"),
            "display": .style(name: "display", value: "flex"),
            "gap": .style(name: "gap", value: "\(layout.columnGap)px"),
            "align-items": .style(name: "align-items", value: "stretch")
        ]

        return VNode.element("div", props: props, children: children)
    }
}
