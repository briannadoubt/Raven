import Foundation
import JavaScriptKit
import Raven
import Testing

@MainActor
final class Phase2FakeRenderContext: _RenderContext {
    private var counter: UInt64 = 0

    var registeredClickHandlers: [UUID] = []
    var registeredInputHandlers: [UUID] = []

    func renderChild(_ view: any View) -> VNode {
        // Minimal coordinator-like rendering that is sufficient for modifier tests.
        if let renderable = view as? any _CoordinatorRenderable {
            return renderable._render(with: self)
        }
        if let primitive = view as? any PrimitiveView {
            return primitive.toVNode()
        }
        return VNode.element("div", props: [:], children: [])
    }

    func registerClickHandler(_ action: @escaping @Sendable @MainActor () -> Void) -> UUID {
        _ = action
        counter += 1
        let id = UUID(uuidString: String(format: "00000000-0000-4000-8000-%012llx", counter)) ?? UUID()
        registeredClickHandlers.append(id)
        return id
    }

    func registerInputHandler(_ handler: @escaping @Sendable @MainActor (JSValue) -> Void) -> UUID {
        _ = handler
        counter += 1
        let id = UUID(uuidString: String(format: "00000000-0000-4000-8000-%012llx", counter)) ?? UUID()
        registeredInputHandlers.append(id)
        return id
    }

    func persistentState<T: AnyObject>(create: () -> T) -> T {
        create()
    }

    // Generic helper to render composite views in tests.
    func render<V: View>(_ view: V) -> VNode {
        if V.Body.self == Never.self {
            return renderChild(view)
        }
        return render(view.body)
    }
}

@MainActor
@Suite("Phase 2: Drag/Drop + File Dialogs")
struct Phase2DragDropAndFileDialogTests {
    @Test func draggableRendersDragStartHandlerAndDraggableAttribute() {
        let ctx = Phase2FakeRenderContext()
        let view = Text("Drag Me").draggable("hello")
        let node = ctx.render(view)

        #expect(node.type == .element(tag: "div"))
        #expect(node.props["draggable"] != nil)
        #expect(node.props["onDragstart"] != nil)
        #expect(ctx.registeredInputHandlers.count == 1)
    }

    @Test func onDropRendersExpectedHandlers() {
        let ctx = Phase2FakeRenderContext()
        var targeted = false
        let binding = Binding<Bool>(get: { targeted }, set: { targeted = $0 })

        let view = Text("Drop Here").onDrop(of: [.plainText], isTargeted: binding) { _ in true }
        let node = ctx.render(view)

        #expect(node.props["onDragover"] != nil)
        #expect(node.props["onDragenter"] != nil)
        #expect(node.props["onDragleave"] != nil)
        #expect(node.props["onDrop"] != nil)
        #expect(ctx.registeredInputHandlers.count == 4)
    }

    @Test func fileImporterNotPresentedIsTransparent() {
        let ctx = Phase2FakeRenderContext()
        var presented = false
        let binding = Binding<Bool>(get: { presented }, set: { presented = $0 })

        let view = Text("Hello").fileImporter(isPresented: binding, allowedContentTypes: [.plainText]) { _ in }
        let node = ctx.render(view)

        // Should just return the content node (Text) when not presented.
        #expect(node.type != .fragment)
    }

    @Test func fileImporterPresentedRendersOverlayFragment() {
        let ctx = Phase2FakeRenderContext()
        var presented = true
        let binding = Binding<Bool>(get: { presented }, set: { presented = $0 })

        let view = Text("Hello").fileImporter(isPresented: binding, allowedContentTypes: [.plainText]) { _ in }
        let node = ctx.render(view)

        if case .fragment = node.type {
            #expect(true)
        } else {
            #expect(Bool(false))
        }
    }

    @Test func environmentModifierScopesEnvironmentValues() {
        let ctx = Phase2FakeRenderContext()
        let node = ctx.render(
            Button("Primary") {}
                .buttonStyle(.borderedProminent)
        )

        // Button runtime should see the environment-provided primitive style.
        #expect(node.props["background"] == .style(name: "background", value: "var(--system-accent)"))
    }
}
