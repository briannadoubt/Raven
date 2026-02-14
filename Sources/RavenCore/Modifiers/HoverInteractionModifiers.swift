import Foundation
import JavaScriptKit

/// The phase of a hover interaction.
public enum HoverPhase: Sendable, Hashable {
    case active(CGPoint)
    case ended
}

public struct _OnHoverView<Content: View>: View, PrimitiveView, _CoordinatorRenderable, Sendable {
    public typealias Body = Never

    let content: Content
    let perform: @Sendable @MainActor (Bool) -> Void

    @MainActor public func toVNode() -> VNode {
        VNode.element("div", props: [:], children: [])
    }

    @MainActor public func _render(with context: any _RenderContext) -> VNode {
        let enterID = context.registerInputHandler { _ in
            perform(true)
        }
        let leaveID = context.registerInputHandler { _ in
            perform(false)
        }

        let props: [String: VProperty] = [
            "onMouseEnter": .eventHandler(event: "mouseenter", handlerID: enterID),
            "onMouseLeave": .eventHandler(event: "mouseleave", handlerID: leaveID),
        ]

        return VNode.element("div", props: props, children: [context.renderChild(content)])
    }
}

public struct _OnContinuousHoverView<Content: View>: View, PrimitiveView, _CoordinatorRenderable, Sendable {
    public typealias Body = Never

    let content: Content
    let perform: @Sendable @MainActor (HoverPhase) -> Void

    @MainActor public func toVNode() -> VNode {
        VNode.element("div", props: [:], children: [])
    }

    @MainActor public func _render(with context: any _RenderContext) -> VNode {
        func point(from event: JSValue) -> CGPoint {
            DragDropJS.location(event)
        }

        let moveID = context.registerInputHandler { event in
            perform(.active(point(from: event)))
        }

        let leaveID = context.registerInputHandler { _ in
            perform(.ended)
        }

        let props: [String: VProperty] = [
            "onMouseMove": .eventHandler(event: "mousemove", handlerID: moveID),
            "onMouseLeave": .eventHandler(event: "mouseleave", handlerID: leaveID),
        ]

        return VNode.element("div", props: props, children: [context.renderChild(content)])
    }
}

extension View {
    /// Adds an action to perform when this view is hovered.
    @MainActor public func onHover(
        perform action: @escaping @Sendable @MainActor (Bool) -> Void
    ) -> _OnHoverView<Self> {
        _OnHoverView(content: self, perform: action)
    }

    /// Adds an action that receives continuous hover updates.
    @MainActor public func onContinuousHover(
        coordinateSpace: CoordinateSpace = .local,
        perform action: @escaping @Sendable @MainActor (HoverPhase) -> Void
    ) -> _OnContinuousHoverView<Self> {
        _ = coordinateSpace
        return _OnContinuousHoverView(content: self, perform: action)
    }
}
