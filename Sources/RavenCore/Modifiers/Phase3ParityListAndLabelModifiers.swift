import Foundation

/// Controls whether labels are shown for supported controls.
public enum LabelVisibility: String, Sendable, Hashable {
    case automatic
    case visible
    case hidden
}

private struct LabelVisibilityEnvironmentKey: EnvironmentKey {
    static let defaultValue: LabelVisibility = .automatic
}

extension EnvironmentValues {
    var labelVisibility: LabelVisibility {
        get { self[LabelVisibilityEnvironmentKey.self] }
        set { self[LabelVisibilityEnvironmentKey.self] = newValue }
    }
}

/// Wrapper modifier that records label visibility preference.
public struct _LabelsVisibilityView<Content: View>: View, PrimitiveView, Sendable {
    let content: Content
    let visibility: LabelVisibility

    public typealias Body = Never

    @MainActor public func toVNode() -> VNode {
        let props: [String: VProperty] = [
            "data-label-visibility": .attribute(name: "data-label-visibility", value: visibility.rawValue),
        ]
        return VNode.element("div", props: props, children: [])
    }
}

extension _LabelsVisibilityView: _ModifierRenderable {
    public var _modifiedContent: Content { content }
}

/// Wrapper modifier that applies row insets metadata for list rows.
public struct _ListRowInsetsView<Content: View>: View, PrimitiveView, Sendable {
    let content: Content
    let insets: EdgeInsets

    public typealias Body = Never

    @MainActor public func toVNode() -> VNode {
        let props: [String: VProperty] = [
            "padding-top": .style(name: "padding-top", value: "\(insets.top)px"),
            "padding-right": .style(name: "padding-right", value: "\(insets.trailing)px"),
            "padding-bottom": .style(name: "padding-bottom", value: "\(insets.bottom)px"),
            "padding-left": .style(name: "padding-left", value: "\(insets.leading)px"),
            "data-list-row-insets": .attribute(name: "data-list-row-insets", value: "custom"),
        ]
        return VNode.element("div", props: props, children: [])
    }
}

extension _ListRowInsetsView: _ModifierRenderable {
    public var _modifiedContent: Content { content }
}

extension View {
    /// Sets label visibility for views in this hierarchy.
    @MainActor public func labelsVisibility(_ visibility: LabelVisibility) -> some View {
        environment(\.labelVisibility, visibility)
    }

    /// Hides labels for supported controls.
    @MainActor public func labelsHidden() -> some View {
        labelsVisibility(.hidden)
    }

    /// Sets row insets for list row content.
    @MainActor public func listRowInsets(_ insets: EdgeInsets?) -> some View {
        if let insets {
            return AnyView(_ListRowInsetsView(content: self, insets: insets))
        }
        return AnyView(self)
    }
}
