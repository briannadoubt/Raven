import Foundation
import JavaScriptKit
import Raven

/// Browser DOM implementation of `PlatformRenderer`.
///
/// `DOMRenderer` translates VNode trees and Patch operations into real DOM
/// mutations via `DOMBridge.shared`.  Event wiring is delegated back to the
/// coordinator through closure callbacks so that the renderer itself does not
/// need to know which handlers are click vs. input handlers, or how gestures
/// are resolved.
///
/// The coordinator sets up the following closures after construction:
/// - `eventAttacher`   — wires a DOM event listener for a handler ID
/// - `gestureAttacher` — wires gesture event listeners for a `GestureRegistration`
@MainActor
public final class DOMRenderer: PlatformRenderer, Sendable {

    // MARK: - Properties

    /// Root DOM container element (set via `setRootContainer`).
    private var rootContainer: JSObject?

    // MARK: - Coordinator Callbacks

    /// Closure provided by the coordinator for attaching a single DOM event
    /// listener to an element.  Parameters: (element, event name, handler ID).
    public var eventAttacher: (@Sendable @MainActor (JSObject, String, UUID) -> Void)?

    /// Closure provided by the coordinator for attaching gesture event
    /// listeners to an element.  Parameters: (gesture registration, element).
    public var gestureAttacher: (@Sendable @MainActor (GestureRegistration, JSObject) -> Void)?

    // MARK: - Initialization

    public init() {}

    // MARK: - PlatformRenderer Conformance

    public func setRootContainer(_ container: Any) {
        guard let jsContainer = container as? JSObject else {
            print("Warning: DOMRenderer.setRootContainer received non-JSObject")
            return
        }
        self.rootContainer = jsContainer
        AppRuntime.injectFrameworkCSSIfNeeded()
    }

    // MARK: - Tree Mounting

    public func mountTree(_ root: VNode) {
        guard let container = rootContainer else {
            print("Warning: No root container set for mounting")
            return
        }

        guard let domNode = createDOMNode(root) else {
            print("Warning: Failed to create DOM node for mount")
            return
        }

        DOMBridge.shared.appendChild(parent: container, child: domNode)
        DOMBridge.shared.registerNode(id: root.id, element: domNode)
    }

    // MARK: - DOM Node Creation

    /// Recursively create a DOM node tree from a VNode.
    private func createDOMNode(_ node: VNode) -> JSObject? {
        switch node.type {
        case .element(let tag):
            guard let element = DOMBridge.shared.createElement(tag: tag) else {
                return nil
            }

            // Apply properties (attributes, styles, event handlers)
            for (_, property) in node.props {
                applyProperty(property, to: element)
            }

            // Delegate gesture listener attachment to the coordinator
            for gestureReg in node.gestures {
                gestureAttacher?(gestureReg, element)
            }

            // Recurse into children
            for child in node.children {
                guard let childDOM = createDOMNode(child) else { continue }
                DOMBridge.shared.appendChild(parent: element, child: childDOM)
                DOMBridge.shared.registerNode(id: child.id, element: childDOM)
            }

            return element

        case .text(let content):
            return DOMBridge.shared.createTextNode(text: content)

        case .fragment:
            // Fragments use a wrapper div with `display: contents` so the
            // element is invisible to flex/grid layout.
            guard let fragment = DOMBridge.shared.createElement(tag: "div") else {
                return nil
            }
            DOMBridge.shared.setStyle(element: fragment, name: "display", value: "contents")

            for child in node.children {
                guard let childDOM = createDOMNode(child) else { continue }
                DOMBridge.shared.appendChild(parent: fragment, child: childDOM)
                DOMBridge.shared.registerNode(id: child.id, element: childDOM)
            }

            return fragment

        case .component:
            // Components are already expanded during VNode conversion;
            // create a plain wrapper div.
            return DOMBridge.shared.createElement(tag: "div")
        }
    }

    // MARK: - Patch Application

    public func applyPatches(_ patches: [Patch]) {
        for patch in patches {
            applyPatch(patch)
        }
    }

    private func applyPatch(_ patch: Patch) {
        switch patch {
        case .insert(let parentID, let node, let index):
            guard let parentElement = DOMBridge.shared.getNode(id: parentID) else {
                print("Warning: Parent node not found for insert: \(parentID)")
                return
            }

            guard let newElement = createDOMNode(node) else {
                print("Warning: Failed to create DOM node for insert")
                return
            }

            // Insert before the child at `index`, or append if index is past the end.
            if index < Int(parentElement.childNodes.length.number ?? 0) {
                let referenceChild = parentElement.childNodes[index].object
                DOMBridge.shared.insertBefore(
                    parent: parentElement,
                    new: newElement,
                    reference: referenceChild
                )
            } else {
                DOMBridge.shared.appendChild(parent: parentElement, child: newElement)
            }

            DOMBridge.shared.registerNode(id: node.id, element: newElement)

        case .remove(let nodeID):
            guard let element = DOMBridge.shared.getNode(id: nodeID) else {
                print("Warning: Node not found for removal: \(nodeID)")
                return
            }

            if let parent = element.parentNode.object {
                DOMBridge.shared.removeChild(parent: parent, child: element)
            }
            DOMBridge.shared.unregisterNode(id: nodeID)

        case .replace(let oldID, let newNode):
            guard let oldElement = DOMBridge.shared.getNode(id: oldID),
                  let parent = oldElement.parentNode.object else {
                print("Warning: Old node not found for replacement: \(oldID)")
                return
            }

            guard let newElement = createDOMNode(newNode) else {
                print("Warning: Failed to create DOM node for replace")
                return
            }

            DOMBridge.shared.replaceChild(parent: parent, old: oldElement, new: newElement)
            DOMBridge.shared.unregisterNode(id: oldID)
            DOMBridge.shared.registerNode(id: newNode.id, element: newElement)

        case .updateProps(let nodeID, let propPatches):
            guard let element = DOMBridge.shared.getNode(id: nodeID) else {
                print("Warning: Node not found for property update: \(nodeID)")
                return
            }

            for propPatch in propPatches {
                applyPropPatch(propPatch, to: element)
            }

        case .reorder(let parentID, let moves):
            guard let parentElement = DOMBridge.shared.getNode(id: parentID) else {
                return
            }

            // Snapshot current child elements in order
            let childCount = Int(parentElement.childNodes.length.number ?? 0)
            var childElements: [JSObject] = []
            for i in 0..<childCount {
                if let child = parentElement.childNodes[i].object {
                    childElements.append(child)
                }
            }

            // Re-insert each moved element at its target position
            for move in moves {
                guard move.from < childElements.count else { continue }
                let element = childElements[move.from]
                if move.to < childCount {
                    if let reference = parentElement.childNodes[move.to].object {
                        DOMBridge.shared.insertBefore(
                            parent: parentElement,
                            new: element,
                            reference: reference
                        )
                    }
                } else {
                    DOMBridge.shared.appendChild(parent: parentElement, child: element)
                }
            }
        }
    }

    // MARK: - Property Application

    /// Apply a single VProperty to a DOM element.
    private func applyProperty(_ property: VProperty, to element: JSObject) {
        switch property {
        case .attribute(let name, let value):
            DOMBridge.shared.setAttribute(element: element, name: name, value: value)

        case .style(let name, let value):
            DOMBridge.shared.setStyle(element: element, name: name, value: value)

        case .boolAttribute(let name, let value):
            if value {
                DOMBridge.shared.setAttribute(element: element, name: name, value: name)
            } else {
                DOMBridge.shared.removeAttribute(element: element, name: name)
            }

        case .eventHandler(let event, let handlerID):
            // Delegate event handler wiring to the coordinator callback.
            // The coordinator knows whether this is an input handler or a
            // click handler and can call the appropriate DOMBridge method.
            eventAttacher?(element, event, handlerID)
        }
    }

    /// Apply a PropPatch (add / update / remove) to a DOM element.
    private func applyPropPatch(_ patch: PropPatch, to element: JSObject) {
        switch patch {
        case .add(_, let value), .update(_, let value):
            applyProperty(value, to: element)

        case .remove(let key):
            DOMBridge.shared.removeAttribute(element: element, name: key)
        }
    }

    // MARK: - Node Registry Delegation

    public func registerNode(id: NodeID, element: Any) {
        guard let jsElement = element as? JSObject else { return }
        DOMBridge.shared.registerNode(id: id, element: jsElement)
    }

    public func unregisterNode(id: NodeID) {
        DOMBridge.shared.unregisterNode(id: id)
    }

    public func getNode(id: NodeID) -> Any? {
        DOMBridge.shared.getNode(id: id)
    }

    // MARK: - Event Handler Delegation

    public func attachEventHandler(nodeID: NodeID, event: String, handlerID: UUID) {
        guard let element = DOMBridge.shared.getNode(id: nodeID) else { return }
        eventAttacher?(element, event, handlerID)
    }

    public func updateEventHandler(id: UUID, handler: @escaping @Sendable @MainActor () -> Void) {
        DOMBridge.shared.updateEventHandler(id: id, handler: handler)
    }

    public func updateInputEventHandler(id: UUID, handler: @escaping @Sendable @MainActor (Any) -> Void) {
        // DOMBridge expects (JSValue) -> Void; bridge via a cast.
        let jsHandler: @Sendable @MainActor (JSValue) -> Void = { value in
            handler(value)
        }
        DOMBridge.shared.updateInputEventHandler(id: id, handler: jsHandler)
    }

    public func cleanupHandler(id: UUID) {
        DOMBridge.shared.cleanupStaleHandler(id: id)
    }
}
