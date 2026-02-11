import Foundation
import JavaScriptKit

@MainActor
private func _ravenNextRuntimeID(prefix: String) -> String {
    #if arch(wasm32)
    let global = JSObject.global
    let next = (global.__RAVEN_RUNTIME_ID_COUNTER.number ?? 0) + 1
    global.__RAVEN_RUNTIME_ID_COUNTER = .number(next)
    return "\(prefix)-\(Int(next))"
    #else
    return "\(prefix)-\(UUID().uuidString)"
    #endif
}

/// An opaque reference to the geometry of a view.
///
/// Raven models `Anchor` similarly to SwiftUI's anchor preferences: an `Anchor`
/// captures geometry from a target view, and a `GeometryProxy` can resolve it
/// to concrete values.
///
/// In Raven's DOM-backed renderer, anchors are identified by a stable DOM
/// attribute (`data-raven-anchor-id` / `data-raven-anchor-group`) so they can be
/// resolved without depending on internal VNode IDs.
public struct Anchor<Value: Sendable>: Sendable, Hashable {
    package enum _Locator: Sendable, Hashable {
        case single(String) // selector: data-raven-anchor-id
        case group(String)  // selector: data-raven-anchor-group (union)
    }

    package let locator: _Locator

    package init(locator: _Locator) {
        self.locator = locator
    }
}

extension Anchor where Value == CGRect {
    /// The source of a bounds anchor.
    public enum Source: Sendable, Hashable {
        case bounds
    }
}

// MARK: - Anchor Preference

public struct _AnchorPreferenceView<Content: View, K: PreferenceKey, A: Sendable>: View, PrimitiveView, Sendable {
    public typealias Body = Never

    let content: Content
    let source: Anchor<CGRect>.Source
    let transform: @Sendable @MainActor (Anchor<CGRect>) -> K.Value

    @MainActor public func toVNode() -> VNode {
        VNode.element("div", props: [:], children: [])
    }
}

@MainActor
private final class _AnchorPreferenceID: @unchecked Sendable {
    let id: String = _ravenNextRuntimeID(prefix: "anchor")
    init() {}
}

extension _AnchorPreferenceView: _CoordinatorRenderable where A == CGRect {
    @MainActor public func _render(with context: any _RenderContext) -> VNode {
        // Create a stable anchor id for this view instance.
        let anchorID = context.persistentState(create: { _AnchorPreferenceID() }).id

        // Render content first.
        let node = context.renderChild(content)

        func tagAnchorGroupInFragmentTree(_ node: VNode) -> VNode {
            // Only recurse through fragments. We intentionally do not recurse into
            // element children because we want the "top-level element(s)" of the
            // view output, even if the view output contains nested DOM structure.
            switch node.type {
            case .element:
                var props = node.props
                props["data-raven-anchor-group"] = .attribute(name: "data-raven-anchor-group", value: anchorID)
                return VNode(
                    id: node.id,
                    type: node.type,
                    props: props,
                    children: node.children,
                    key: node.key,
                    gestures: node.gestures
                )
            case .fragment:
                let children = node.children.map(tagAnchorGroupInFragmentTree(_:))
                return VNode(
                    id: node.id,
                    type: node.type,
                    props: node.props,
                    children: children,
                    key: node.key,
                    gestures: node.gestures
                )
            default:
                return node
            }
        }

        // Attach an identifier to the rendered node without changing layout.
        // - element: add data-raven-anchor-id
        // - fragment: tag each top-level element with data-raven-anchor-group
        let anchoredNode: VNode
        let anchor: Anchor<CGRect>

        switch node.type {
        case .element:
            var props = node.props
            props["data-raven-anchor-id"] = .attribute(name: "data-raven-anchor-id", value: anchorID)
            anchoredNode = VNode(
                id: node.id,
                type: node.type,
                props: props,
                children: node.children,
                key: node.key,
                gestures: node.gestures
            )
            anchor = Anchor(locator: .single(anchorID))

        case .fragment:
            anchoredNode = tagAnchorGroupInFragmentTree(node)
            anchor = Anchor(locator: .group(anchorID))

        default:
            anchoredNode = node
            anchor = Anchor(locator: .single(anchorID))
        }

        // Emit the preference.
        _PreferenceContext.emit(K.self, value: transform(anchor))

        return anchoredNode
    }
}

extension View {
    /// Creates and emits an anchor preference for this view.
    ///
    /// Raven currently supports `.bounds` anchors and resolving them within a
    /// `GeometryReader`.
    @MainActor
    public func anchorPreference<K: PreferenceKey>(
        key: K.Type,
        value source: Anchor<CGRect>.Source,
        transform: @escaping @Sendable @MainActor (Anchor<CGRect>) -> K.Value
    ) -> some View {
        _AnchorPreferenceView<AnyView, K, CGRect>(
            content: AnyView(self),
            source: source,
            transform: transform
        )
    }
}

// MARK: - GeometryProxy Anchor Resolution

extension GeometryProxy {
    /// Resolve a bounds anchor into the geometry reader's local coordinate space.
    @MainActor
    public subscript(_ anchor: Anchor<CGRect>) -> CGRect {
        #if arch(wasm32)
        @MainActor
        func nearlyEqual(_ a: Double, _ b: Double, epsilon: Double = 0.5) -> Bool {
            abs(a - b) < epsilon
        }

        @MainActor
        func nearlyEqualRect(_ a: CGRect, _ b: CGRect, epsilon: Double = 0.5) -> Bool {
            nearlyEqual(a.minX, b.minX, epsilon: epsilon) &&
            nearlyEqual(a.minY, b.minY, epsilon: epsilon) &&
            nearlyEqual(a.width, b.width, epsilon: epsilon) &&
            nearlyEqual(a.height, b.height, epsilon: epsilon)
        }

        @MainActor
        func maybeScheduleAnchorRefresh(locator: Anchor<CGRect>._Locator, rect: CGRect) {
            // Anchor geometry is resolved against the *committed* DOM. During a
            // render pass, VNodes are computed before `fiberRender` applies DOM
            // mutations, so querying now can return the previous frame's
            // coordinates. To converge, schedule a follow-up render when the
            // resolved anchor rect changes.
            if let last = _AnchorResolutionCache.lastRectByLocator[locator] {
                if nearlyEqualRect(last, rect) {
                    return
                }
            }
            _AnchorResolutionCache.lastRectByLocator[locator] = rect

            // Avoid self-sustaining render loops from live anchor reads.
            // We only request convergence when the anchor has no meaningful size yet.
            // Once a non-zero rect is available, consumers can read it directly
            // without forcing another full render cycle.
            if rect.width <= 0.5 || rect.height <= 0.5 {
                _RenderScheduler.current?.scheduleRender()
            }
        }

        guard let document = JSObject.global.document.object else { return .zero }
        guard let querySelectorFn = document.querySelector.function else { return .zero }

        func rect(for element: JSObject) -> CGRect {
            DOMBridge.shared.measureGeometry(element: element).frame(in: .global)
        }

        let globalSelf = frame(in: .global)

        switch anchor.locator {
        case .single(let id):
            let selector = "[data-raven-anchor-id=\"\(id)\"]"
            let result = querySelectorFn(this: document, selector)
            guard !result.isNull, let element = result.object else { return .zero }
            let g = rect(for: element)
            let local = CGRect(
                x: g.minX - globalSelf.minX,
                y: g.minY - globalSelf.minY,
                width: g.width,
                height: g.height
            )
            maybeScheduleAnchorRefresh(locator: anchor.locator, rect: local)
            return local

        case .group(let id):
            let selector = "[data-raven-anchor-group=\"\(id)\"]"
            guard let qsa = document.querySelectorAll.function else { return .zero }
            let listValue = qsa(this: document, selector)
            guard !listValue.isNull, let list = listValue.object else { return .zero }
            let length = Int(list.length.number ?? 0)
            guard length > 0 else { return .zero }

            var union: CGRect? = nil
            for i in 0..<length {
                guard let element = list[i].object else { continue }
                let g = rect(for: element)
                if let u = union {
                    let minX = min(u.minX, g.minX)
                    let minY = min(u.minY, g.minY)
                    let maxX = max(u.maxX, g.maxX)
                    let maxY = max(u.maxY, g.maxY)
                    union = CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
                } else {
                    union = g
                }
            }

            guard let g = union else { return .zero }
            let local = CGRect(
                x: g.minX - globalSelf.minX,
                y: g.minY - globalSelf.minY,
                width: g.width,
                height: g.height
            )
            maybeScheduleAnchorRefresh(locator: anchor.locator, rect: local)
            return local
        }
        #else
        return .zero
        #endif
    }
}

@MainActor
private enum _AnchorResolutionCache {
    static var lastRectByLocator: [Anchor<CGRect>._Locator: CGRect] = [:]
}
