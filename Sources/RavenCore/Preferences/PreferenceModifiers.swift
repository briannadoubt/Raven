import Foundation

// MARK: - Preference Emission

public struct _PreferenceWritingView<Content: View, K: PreferenceKey>: View, PrimitiveView, Sendable {
    public typealias Body = Never

    let content: Content
    let value: K.Value

    @MainActor public func toVNode() -> VNode {
        // This view is rendered via _CoordinatorRenderable to ensure the emitted
        // preference is collected by the coordinator.
        VNode.element("div", props: [:], children: [])
    }
}

extension _PreferenceWritingView: _CoordinatorRenderable {
    @MainActor public func _render(with context: any _RenderContext) -> VNode {
        let node = context.renderChild(content)
        _PreferenceContext.emit(K.self, value: value)
        return node
    }
}

// MARK: - Transform Preference

public struct _TransformPreferenceView<Content: View, K: PreferenceKey>: View, PrimitiveView, Sendable {
    public typealias Body = Never

    let content: Content
    let transform: @Sendable @MainActor (inout K.Value) -> Void

    @MainActor public func toVNode() -> VNode {
        VNode.element("div", props: [:], children: [])
    }
}

extension _TransformPreferenceView: _CoordinatorRenderable {
    @MainActor public func _render(with context: any _RenderContext) -> VNode {
        let (node, prefs) = context.renderChildWithPreferences(content)
        var v = prefs[K.self]
        transform(&v)
        _PreferenceContext.override(K.self, value: v)
        return node
    }
}

// MARK: - On Preference Change

public struct _OnPreferenceChangeView<Content: View, K: PreferenceKey>: View, PrimitiveView, Sendable where K.Value: Equatable {
    public typealias Body = Never

    let content: Content
    let perform: @Sendable @MainActor (K.Value) -> Void

    @MainActor public func toVNode() -> VNode {
        VNode.element("div", props: [:], children: [])
    }
}

@MainActor
private final class _OnPreferenceChangeStorage<Value: Sendable & Equatable>: @unchecked Sendable {
    @MainActor var last: Value? = nil
    init() {}
}

extension _OnPreferenceChangeView: _CoordinatorRenderable {
    @MainActor public func _render(with context: any _RenderContext) -> VNode {
        let storage: _OnPreferenceChangeStorage<K.Value> = context.persistentState(create: { _OnPreferenceChangeStorage<K.Value>() })

        let (node, prefs) = context.renderChildWithPreferences(content)
        let current = prefs[K.self]

        let didChange: Bool
        if let last = storage.last {
            didChange = (last != current)
        } else {
            didChange = true
        }
        storage.last = current

        if didChange {
            context.enqueuePostRender {
                self.perform(current)
            }
        }

        return node
    }
}

// MARK: - Overlay/Background Preference Value

public struct _OverlayPreferenceValueView<Content: View, K: PreferenceKey, Overlay: View>: View, PrimitiveView, Sendable {
    public typealias Body = Never

    let content: Content
    let alignment: ModifierAlignment
    let transform: @Sendable @MainActor (K.Value) -> Overlay

    @MainActor public func toVNode() -> VNode {
        // Same wrapper strategy as `_OverlayView`.
        let props: [String: VProperty] = [
            "display": .style(name: "display", value: "grid"),
            "grid-template-columns": .style(name: "grid-template-columns", value: "1fr"),
            "grid-template-rows": .style(name: "grid-template-rows", value: "1fr"),
            "place-items": .style(name: "place-items", value: alignment.cssValue),
        ]
        return VNode.element("div", props: props, children: [])
    }
}

extension _OverlayPreferenceValueView: _CoordinatorRenderable {
    @MainActor public func _render(with context: any _RenderContext) -> VNode {
        let wrapperNode = toVNode()
        let (contentNode, prefs) = context.renderChildWithPreferences(content)
        let overlayView = transform(prefs[K.self])
        let overlayNode = context.renderChild(overlayView)

        guard case .element(let tag) = wrapperNode.type else { return contentNode }

        let contentWrapper = VNode.element("div", props: [
            "grid-row": .style(name: "grid-row", value: "1 / -1"),
            "grid-column": .style(name: "grid-column", value: "1 / -1"),
        ], children: [contentNode])

        let overlayWrapper = VNode.element("div", props: [
            "grid-row": .style(name: "grid-row", value: "1 / -1"),
            "grid-column": .style(name: "grid-column", value: "1 / -1"),
        ], children: [overlayNode])

        return VNode(
            id: wrapperNode.id,
            type: .element(tag: tag),
            props: wrapperNode.props,
            children: [contentWrapper, overlayWrapper],
            key: wrapperNode.key
        )
    }
}

public struct _BackgroundPreferenceValueView<Content: View, K: PreferenceKey, Background: View>: View, PrimitiveView, Sendable {
    public typealias Body = Never

    let content: Content
    let alignment: ModifierAlignment
    let transform: @Sendable @MainActor (K.Value) -> Background

    @MainActor public func toVNode() -> VNode {
        // Same wrapper strategy as `_BackgroundView`.
        let props: [String: VProperty] = [
            "display": .style(name: "display", value: "grid"),
            "grid-template-columns": .style(name: "grid-template-columns", value: "1fr"),
            "grid-template-rows": .style(name: "grid-template-rows", value: "1fr"),
            "place-items": .style(name: "place-items", value: alignment.cssValue),
        ]
        return VNode.element("div", props: props, children: [])
    }
}

extension _BackgroundPreferenceValueView: _CoordinatorRenderable {
    @MainActor public func _render(with context: any _RenderContext) -> VNode {
        let wrapperNode = toVNode()
        let (contentNode, prefs) = context.renderChildWithPreferences(content)
        let backgroundView = transform(prefs[K.self])
        let backgroundNode = context.renderChild(backgroundView)

        guard case .element(let tag) = wrapperNode.type else { return contentNode }

        let bgWrapper = VNode.element("div", props: [
            "grid-row": .style(name: "grid-row", value: "1 / -1"),
            "grid-column": .style(name: "grid-column", value: "1 / -1"),
        ], children: [backgroundNode])

        let contentWrapper = VNode.element("div", props: [
            "grid-row": .style(name: "grid-row", value: "1 / -1"),
            "grid-column": .style(name: "grid-column", value: "1 / -1"),
        ], children: [contentNode])

        return VNode(
            id: wrapperNode.id,
            type: .element(tag: tag),
            props: wrapperNode.props,
            children: [bgWrapper, contentWrapper],
            key: wrapperNode.key
        )
    }
}

// MARK: - View API Surface

extension View {
    /// Emit a preference value for a key.
    @MainActor
    public func preference<K: PreferenceKey>(key: K.Type = K.self, value: K.Value) -> some View {
        _PreferenceWritingView<AnyView, K>(content: AnyView(self), value: value)
    }

    /// Transform a reduced preference value before it propagates to ancestors.
    @MainActor
    public func transformPreference<K: PreferenceKey>(
        _ key: K.Type,
        _ transform: @escaping @Sendable @MainActor (inout K.Value) -> Void
    ) -> some View {
        _TransformPreferenceView<AnyView, K>(content: AnyView(self), transform: transform)
    }

    /// Perform an action when a preference value changes.
    @MainActor
    public func onPreferenceChange<K: PreferenceKey>(
        _ key: K.Type,
        perform action: @escaping @Sendable @MainActor (K.Value) -> Void
    ) -> some View where K.Value: Equatable {
        _OnPreferenceChangeView<AnyView, K>(content: AnyView(self), perform: action)
    }

    /// Overlay a view computed from a preference value.
    @MainActor
    public func overlayPreferenceValue<K: PreferenceKey, Overlay: View>(
        _ key: K.Type,
        alignment: ModifierAlignment = .center,
        @ViewBuilder _ transform: @escaping @Sendable @MainActor (K.Value) -> Overlay
    ) -> some View {
        _OverlayPreferenceValueView<AnyView, K, Overlay>(
            content: AnyView(self),
            alignment: alignment,
            transform: transform
        )
    }

    /// Add a background view computed from a preference value.
    @MainActor
    public func backgroundPreferenceValue<K: PreferenceKey, Background: View>(
        _ key: K.Type,
        alignment: ModifierAlignment = .center,
        @ViewBuilder _ transform: @escaping @Sendable @MainActor (K.Value) -> Background
    ) -> some View {
        _BackgroundPreferenceValueView<AnyView, K, Background>(
            content: AnyView(self),
            alignment: alignment,
            transform: transform
        )
    }
}
