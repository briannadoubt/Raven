import Foundation
import JavaScriptKit

// MARK: - Draggable

public struct _DraggableView<Content: View>: View, PrimitiveView, _CoordinatorRenderable, Sendable {
    public typealias Body = Never

    let content: Content
    let plainTextProvider: @Sendable @MainActor () -> String

    @MainActor public func toVNode() -> VNode {
        // `toVNode()` is unused for coordinator rendering; keep a safe fallback.
        VNode.element("div", props: [:], children: [])
    }

    @MainActor public func _render(with context: any _RenderContext) -> VNode {
        let dragStartID = context.registerInputHandler { event in
            let text = plainTextProvider()
            DragDropJS.setPlainText(event, value: text)
        }

        var props: [String: VProperty] = [
            "draggable": .boolAttribute(name: "draggable", value: true),
            "onDragstart": .eventHandler(event: "dragstart", handlerID: dragStartID),
        ]

        // Make it obvious this is draggable (cursor hint).
        props["cursor"] = .style(name: "cursor", value: "grab")

        let contentNode = context.renderChild(content)
        return VNode.element("div", props: props, children: [contentNode])
    }
}

extension View {
    /// Marks this view as draggable by providing a plain-text representation.
    @MainActor public func draggable(_ plainText: String) -> _DraggableView<Self> {
        _DraggableView(content: self, plainTextProvider: { plainText })
    }

    /// Marks this view as draggable by providing a plain-text representation lazily.
    @MainActor public func draggable(_ plainText: @escaping @Sendable @MainActor () -> String) -> _DraggableView<Self> {
        _DraggableView(content: self, plainTextProvider: plainText)
    }
}

// MARK: - On Drop

public struct _OnDropView<Content: View>: View, PrimitiveView, _CoordinatorRenderable, Sendable {
    public typealias Body = Never

    let content: Content
    let allowedTypes: [UTType]
    let isTargeted: Binding<Bool>?
    let perform: @Sendable @MainActor ([DropItem]) -> Bool

    @MainActor public func toVNode() -> VNode {
        VNode.element("div", props: [:], children: [])
    }

    @MainActor public func _render(with context: any _RenderContext) -> VNode {
        // dragover must preventDefault for drop to be allowed
        let dragOverID = context.registerInputHandler { event in
            _ = allowedTypes // reserved for future type filtering
            DragDropJS.preventDefault(event)
        }

        let dragEnterID = context.registerInputHandler { event in
            _ = event
            isTargeted?.wrappedValue = true
        }

        let dragLeaveID = context.registerInputHandler { event in
            _ = event
            isTargeted?.wrappedValue = false
        }

        let dropID = context.registerInputHandler { event in
            DragDropJS.preventDefault(event)
            DragDropJS.stopPropagation(event)

            var items: [DropItem] = []

            if let text = DragDropJS.getPlainText(event), !text.isEmpty {
                items.append(.text(text))
            }

            for f in DragDropJS.files(event) {
                items.append(.file(f))
            }

            _ = perform(items)
            isTargeted?.wrappedValue = false
        }

        let props: [String: VProperty] = [
            "onDragover": .eventHandler(event: "dragover", handlerID: dragOverID),
            "onDragenter": .eventHandler(event: "dragenter", handlerID: dragEnterID),
            "onDragleave": .eventHandler(event: "dragleave", handlerID: dragLeaveID),
            "onDrop": .eventHandler(event: "drop", handlerID: dropID),
        ]

        let contentNode = context.renderChild(content)
        return VNode.element("div", props: props, children: [contentNode])
    }
}

extension View {
    /// Adds a drop handler to this view (web implementation uses HTML5 drag events).
    @MainActor public func onDrop(
        of supportedContentTypes: [UTType],
        isTargeted: Binding<Bool>? = nil,
        perform action: @escaping @Sendable @MainActor ([DropItem]) -> Bool
    ) -> _OnDropView<Self> {
        _OnDropView(
            content: self,
            allowedTypes: supportedContentTypes,
            isTargeted: isTargeted,
            perform: action
        )
    }
}

// MARK: - Drop Destination (alias)

extension View {
    /// Modern SwiftUI dropDestination-style API (Raven currently aliases to `onDrop`).
    @MainActor public func dropDestination(
        for supportedContentTypes: [UTType],
        isTargeted: Binding<Bool>? = nil,
        action: @escaping @Sendable @MainActor ([DropItem]) -> Bool
    ) -> _OnDropView<Self> {
        onDrop(of: supportedContentTypes, isTargeted: isTargeted, perform: action)
    }
}
