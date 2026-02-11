import Foundation
import JavaScriptKit

/// Renders popover presentations as HTML5 dialog elements with positioning.
///
/// The `PopoverRenderer` creates popover-style presentations that are anchored
/// to specific UI elements. It supports:
///
/// - Dynamic positioning relative to anchor elements
/// - Arrow indicators pointing to anchor
/// - Edge preference with automatic flipping
/// - Viewport boundary detection and adjustment
/// - Backdrop clicks for dismissal
///
/// ## Popover Structure
///
/// ```html
/// <dialog class="raven-dialog raven-popover">
///   <div class="raven-popover-arrow raven-popover-arrow-{edge}"></div>
///   <div class="raven-popover-content">
///     <!-- Content -->
///   </div>
/// </dialog>
/// ```
///
/// ## Positioning Algorithm
///
/// 1. Get anchor element bounds
/// 2. Calculate ideal position based on preferred edge
/// 3. Check viewport boundaries
/// 4. Flip to opposite edge if needed
/// 5. Adjust position to fit within viewport
/// 6. Position arrow to point at anchor center
///
/// ## Edge Preferences
///
/// - `.top` - Popover appears above anchor
/// - `.bottom` - Popover appears below anchor
/// - `.leading` - Popover appears to the left (LTR) or right (RTL)
/// - `.trailing` - Popover appears to the right (LTR) or left (RTL)
@MainActor
public struct PopoverRenderer: Sendable {
    // MARK: - Constants

    /// Minimum distance from viewport edge (pixels)
    private static let viewportMargin: Double = 8

    /// Arrow size (pixels)
    private static let arrowSize: Double = 16

    /// Offset from anchor (pixels)
    private static let anchorOffset: Double = 8

    /// Default popover width (pixels)
    private static let defaultWidth: Double = 320

    private static let sourceIDMetadataKey = "ravenPopoverSourceID"
    private static let sourceIDAttribute = "data-raven-popover-source-id"
    private static let anchorKindAttribute = "data-raven-popover-anchor-kind"
    private static let anchorXAttribute = "data-raven-popover-anchor-x"
    private static let anchorYAttribute = "data-raven-popover-anchor-y"
    private static let anchorWidthAttribute = "data-raven-popover-anchor-width"
    private static let anchorHeightAttribute = "data-raven-popover-anchor-height"

    // MARK: - Public Methods

    /// Renders a popover presentation entry as a VNode.
    ///
    /// This method creates a popover dialog with positioning based on
    /// the anchor and edge preference.
    ///
    /// - Parameters:
    ///   - entry: The presentation entry to render
    ///   - anchor: The attachment anchor
    ///   - edge: The preferred arrow edge
    ///   - coordinator: The presentation coordinator
    /// - Returns: A VNode representing the popover dialog
    public static func render(
        entry: PresentationEntry,
        anchor: PopoverAttachmentAnchor,
        edge: Edge,
        coordinator: PresentationCoordinator,
        content: VNode
    ) -> VNode {
        // Create dismiss handler for backdrop clicks
        let dismissHandler = DialogRenderer.createBackdropClickHandler(
            presentationId: entry.id,
            coordinator: coordinator
        )

        // Create arrow element
        let arrow = createArrow(edge: edge)

        // Create content container
        let content = createContentContainer(content: content)

        // Build children
        let children = [arrow, content]

        // Create dialog with popover styling
        // Positioning will be done after render via JavaScript
        var props: [String: VProperty] = [
            "data-anchor": .attribute(name: "data-anchor", value: anchorIdentifier(anchor)),
            "data-edge": .attribute(name: "data-edge", value: edge.rawValue)
        ]
        props["data-raven-presentation-id"] = .attribute(
            name: "data-raven-presentation-id",
            value: entry.id.uuidString
        )
        if let sourceID = entry.metadata[sourceIDMetadataKey] as? String {
            props[sourceIDAttribute] = .attribute(name: sourceIDAttribute, value: sourceID)
        }

        // Store anchor and edge in metadata for post-render positioning
        props["data-popover-metadata"] = .attribute(
            name: "data-popover-metadata",
            value: "{\"edge\":\"\(edge.rawValue)\"}"
        )
        applyAnchorAttributes(for: anchor, to: &props)

        return DialogRenderer.createDialog(
            type: "popover",
            zIndex: entry.zIndex,
            dismissHandler: dismissHandler,
            children: children,
            additionalProps: props
        )
    }

    // MARK: - Private Methods

    /// Creates the arrow indicator element.
    ///
    /// - Parameter edge: The edge where the arrow should point
    /// - Returns: A VNode for the arrow
    private static func createArrow(edge: Edge) -> VNode {
        let edgeClass = "raven-popover-arrow-\(edgeClassName(edge))"

        return VNode.element(
            "div",
            props: [
                "class": .attribute(
                    name: "class",
                    value: "raven-popover-arrow \(edgeClass)"
                ),
                "aria-hidden": .attribute(name: "aria-hidden", value: "true")
            ],
            children: []
        )
    }

    /// Creates the content container element.
    ///
    /// - Parameter content: The content to display in the popover
    /// - Returns: A VNode for the content container
    private static func createContentContainer(content: VNode) -> VNode {
        return VNode.element(
            "div",
            props: [
                "class": .attribute(name: "class", value: "raven-popover-content"),
                "role": .attribute(name: "role", value: "dialog")
            ],
            children: [content]
        )
    }

    /// Converts an edge to a CSS class name.
    ///
    /// - Parameter edge: The edge
    /// - Returns: The CSS class suffix
    private static func edgeClassName(_ edge: Edge) -> String {
        switch edge {
        case .top: return "top"
        case .bottom: return "bottom"
        case .leading: return "leading"
        case .trailing: return "trailing"
        }
    }

    /// Generates an identifier for an anchor.
    ///
    /// - Parameter anchor: The popover attachment anchor
    /// - Returns: A string identifier
    private static func anchorIdentifier(_ anchor: PopoverAttachmentAnchor) -> String {
        // In a complete implementation, this would generate a unique
        // identifier based on the anchor type (rect, point, or source)
        return "anchor-\(UUID().uuidString)"
    }

    // MARK: - Positioning

    /// Calculates and applies positioning for an already-mounted popover dialog element.
    public static func positionPopoverElement(_ popoverElement: JSObject) {
        let bridge = DOMBridge.shared

        let edge = Edge(rawValue: popoverElement.getAttribute?("data-edge").string ?? "") ?? .top
        guard let anchorBounds = resolvedAnchorBounds(for: popoverElement) else {
            positionAtCenter(popoverElement)
            return
        }

        let popoverWidth = popoverElement.offsetWidth.number ?? defaultWidth
        let popoverHeight = popoverElement.offsetHeight.number ?? 200
        let viewportWidth = JSObject.global.window.innerWidth.number ?? 1024
        let viewportHeight = JSObject.global.window.innerHeight.number ?? 768

        var position = calculatePosition(
            anchorBounds: anchorBounds,
            popoverSize: (popoverWidth, popoverHeight),
            viewportSize: (viewportWidth, viewportHeight),
            edge: edge
        )

        let fitsInViewport = checkFitsInViewport(
            position: position,
            size: (popoverWidth, popoverHeight),
            viewportSize: (viewportWidth, viewportHeight)
        )

        var finalEdge = edge
        if !fitsInViewport {
            let oppositeEdge = edge.opposite
            let alternatePosition = calculatePosition(
                anchorBounds: anchorBounds,
                popoverSize: (popoverWidth, popoverHeight),
                viewportSize: (viewportWidth, viewportHeight),
                edge: oppositeEdge
            )
            let fitsOpposite = checkFitsInViewport(
                position: alternatePosition,
                size: (popoverWidth, popoverHeight),
                viewportSize: (viewportWidth, viewportHeight)
            )
            if fitsOpposite {
                position = alternatePosition
                finalEdge = oppositeEdge
            }
        }

        position = constrainToViewport(
            position: position,
            size: (popoverWidth, popoverHeight),
            viewportSize: (viewportWidth, viewportHeight)
        )

        bridge.setStyle(element: popoverElement, name: "left", value: "\(position.x)px")
        bridge.setStyle(element: popoverElement, name: "top", value: "\(position.y)px")

        if finalEdge != edge {
            updateArrowEdge(popoverElement, edge: finalEdge)
        }

        positionArrow(
            popoverElement: popoverElement,
            anchorBounds: anchorBounds,
            popoverPosition: position,
            edge: finalEdge
        )
    }

    /// Calculates and applies positioning for a popover element.
    ///
    /// This method should be called after the popover is rendered to the DOM
    /// to calculate its position relative to the anchor.
    ///
    /// - Parameters:
    ///   - nodeId: The NodeID of the dialog element
    ///   - anchor: The attachment anchor
    ///   - preferredEdge: The preferred arrow edge
    public static func positionPopover(
        nodeId: NodeID,
        anchor: PopoverAttachmentAnchor,
        preferredEdge: Edge
    ) {
        let bridge = DOMBridge.shared

        guard let popoverElement = bridge.getNode(id: nodeId) else {
            return
        }
        applyAnchorAttributes(for: anchor, to: popoverElement)
        bridge.setAttribute(element: popoverElement, name: "data-edge", value: preferredEdge.rawValue)
        positionPopoverElement(popoverElement)
    }

    /// Gets the bounding rectangle for an anchor.
    ///
    /// - Parameter anchor: The attachment anchor
    /// - Returns: The bounding rectangle or nil
    private static func getAnchorBounds(
        _ anchor: PopoverAttachmentAnchor
    ) -> CGRect? {
        switch anchor {
        case .rect(.bounds):
            return nil
        case .rect(.rect(let rect)):
            return CGRect(x: rect.origin.x, y: rect.origin.y, width: rect.size.width, height: rect.size.height)
        case .point(let point):
            return CGRect(x: point.x, y: point.y, width: 0, height: 0)
        }
    }

    private static func resolvedAnchorBounds(for popoverElement: JSObject) -> CGRect? {
        guard let sourceID = popoverElement.getAttribute?(sourceIDAttribute).string,
              let document = JSObject.global.document.object,
              let sourceElement = document.querySelector?("[\(sourceIDAttribute)=\"\(sourceID)\"]").object
        else {
            return nil
        }

        var sourceRect = boundingRect(of: sourceElement)
        if sourceRect.width <= 1 || sourceRect.height <= 1 {
            if let child = sourceElement.firstElementChild.object {
                sourceRect = boundingRect(of: child)
            }
        }

        let anchorKind = popoverElement.getAttribute?(anchorKindAttribute).string ?? "rect-bounds"
        switch anchorKind {
        case "rect":
            let x = Double(popoverElement.getAttribute?(anchorXAttribute).string ?? "") ?? 0
            let y = Double(popoverElement.getAttribute?(anchorYAttribute).string ?? "") ?? 0
            let width = Double(popoverElement.getAttribute?(anchorWidthAttribute).string ?? "") ?? sourceRect.width
            let height = Double(popoverElement.getAttribute?(anchorHeightAttribute).string ?? "") ?? sourceRect.height
            return CGRect(
                x: sourceRect.minX + x,
                y: sourceRect.minY + y,
                width: width,
                height: height
            )
        case "point":
            let ux = Double(popoverElement.getAttribute?(anchorXAttribute).string ?? "") ?? 0.5
            let uy = Double(popoverElement.getAttribute?(anchorYAttribute).string ?? "") ?? 0.5
            return CGRect(
                x: sourceRect.minX + (sourceRect.width * ux),
                y: sourceRect.minY + (sourceRect.height * uy),
                width: 1,
                height: 1
            )
        default:
            return sourceRect
        }
    }

    private static func boundingRect(of element: JSObject) -> CGRect {
        guard let rectObject = element.getBoundingClientRect?().object else {
            return CGRect(x: 0, y: 0, width: 0, height: 0)
        }

        return CGRect(
            x: rectObject.left.number ?? 0,
            y: rectObject.top.number ?? 0,
            width: rectObject.width.number ?? 0,
            height: rectObject.height.number ?? 0
        )
    }

    private static func applyAnchorAttributes(for anchor: PopoverAttachmentAnchor, to props: inout [String: VProperty]) {
        switch anchor {
        case .rect(.bounds):
            props[anchorKindAttribute] = .attribute(name: anchorKindAttribute, value: "rect-bounds")
        case .rect(.rect(let rect)):
            props[anchorKindAttribute] = .attribute(name: anchorKindAttribute, value: "rect")
            props[anchorXAttribute] = .attribute(name: anchorXAttribute, value: String(rect.origin.x))
            props[anchorYAttribute] = .attribute(name: anchorYAttribute, value: String(rect.origin.y))
            props[anchorWidthAttribute] = .attribute(name: anchorWidthAttribute, value: String(rect.size.width))
            props[anchorHeightAttribute] = .attribute(name: anchorHeightAttribute, value: String(rect.size.height))
        case .point(let point):
            props[anchorKindAttribute] = .attribute(name: anchorKindAttribute, value: "point")
            props[anchorXAttribute] = .attribute(name: anchorXAttribute, value: String(point.x))
            props[anchorYAttribute] = .attribute(name: anchorYAttribute, value: String(point.y))
        }
    }

    private static func applyAnchorAttributes(for anchor: PopoverAttachmentAnchor, to element: JSObject) {
        let bridge = DOMBridge.shared
        switch anchor {
        case .rect(.bounds):
            bridge.setAttribute(element: element, name: anchorKindAttribute, value: "rect-bounds")
        case .rect(.rect(let rect)):
            bridge.setAttribute(element: element, name: anchorKindAttribute, value: "rect")
            bridge.setAttribute(element: element, name: anchorXAttribute, value: String(rect.origin.x))
            bridge.setAttribute(element: element, name: anchorYAttribute, value: String(rect.origin.y))
            bridge.setAttribute(element: element, name: anchorWidthAttribute, value: String(rect.size.width))
            bridge.setAttribute(element: element, name: anchorHeightAttribute, value: String(rect.size.height))
        case .point(let point):
            bridge.setAttribute(element: element, name: anchorKindAttribute, value: "point")
            bridge.setAttribute(element: element, name: anchorXAttribute, value: String(point.x))
            bridge.setAttribute(element: element, name: anchorYAttribute, value: String(point.y))
        }
    }

    /// Calculates the position for a popover given an anchor and edge.
    ///
    /// - Parameters:
    ///   - anchorBounds: The anchor bounding rectangle
    ///   - popoverSize: The popover (width, height)
    ///   - viewportSize: The viewport (width, height)
    ///   - edge: The edge to position on
    /// - Returns: The calculated (x, y) position
    private static func calculatePosition(
        anchorBounds: CGRect,
        popoverSize: (Double, Double),
        viewportSize: (Double, Double),
        edge: Edge
    ) -> (x: Double, y: Double) {
        let (popoverWidth, popoverHeight) = popoverSize
        let anchorCenterX = anchorBounds.minX + anchorBounds.width / 2
        let anchorCenterY = anchorBounds.minY + anchorBounds.height / 2

        switch edge {
        case .top:
            return (
                x: anchorCenterX - popoverWidth / 2,
                y: anchorBounds.minY - popoverHeight - anchorOffset - arrowSize / 2
            )

        case .bottom:
            return (
                x: anchorCenterX - popoverWidth / 2,
                y: anchorBounds.maxY + anchorOffset + arrowSize / 2
            )

        case .leading:
            return (
                x: anchorBounds.minX - popoverWidth - anchorOffset - arrowSize / 2,
                y: anchorCenterY - popoverHeight / 2
            )

        case .trailing:
            return (
                x: anchorBounds.maxX + anchorOffset + arrowSize / 2,
                y: anchorCenterY - popoverHeight / 2
            )
        }
    }

    /// Checks if a position fits within the viewport.
    ///
    /// - Parameters:
    ///   - position: The (x, y) position
    ///   - size: The (width, height) size
    ///   - viewportSize: The viewport (width, height)
    /// - Returns: True if the element fits within the viewport
    private static func checkFitsInViewport(
        position: (x: Double, y: Double),
        size: (Double, Double),
        viewportSize: (Double, Double)
    ) -> Bool {
        let (x, y) = position
        let (width, height) = size
        let (viewportWidth, viewportHeight) = viewportSize

        return x >= viewportMargin &&
               y >= viewportMargin &&
               x + width <= viewportWidth - viewportMargin &&
               y + height <= viewportHeight - viewportMargin
    }

    /// Constrains a position to fit within the viewport.
    ///
    /// - Parameters:
    ///   - position: The (x, y) position
    ///   - size: The (width, height) size
    ///   - viewportSize: The viewport (width, height)
    /// - Returns: The constrained (x, y) position
    private static func constrainToViewport(
        position: (x: Double, y: Double),
        size: (Double, Double),
        viewportSize: (Double, Double)
    ) -> (x: Double, y: Double) {
        let (x, y) = position
        let (width, height) = size
        let (viewportWidth, viewportHeight) = viewportSize

        let constrainedX = max(
            viewportMargin,
            min(x, viewportWidth - width - viewportMargin)
        )

        let constrainedY = max(
            viewportMargin,
            min(y, viewportHeight - height - viewportMargin)
        )

        return (x: constrainedX, y: constrainedY)
    }

    /// Positions at the center of the viewport as a fallback.
    ///
    /// - Parameter element: The popover element
    private static func positionAtCenter(_ element: JSObject) {
        let bridge = DOMBridge.shared
        let viewportWidth = JSObject.global.window.innerWidth.number ?? 1024
        let viewportHeight = JSObject.global.window.innerHeight.number ?? 768
        let width = element.offsetWidth.number ?? defaultWidth
        let height = element.offsetHeight.number ?? 200

        let x = (viewportWidth - width) / 2
        let y = (viewportHeight - height) / 2

        bridge.setStyle(element: element, name: "left", value: "\(x)px")
        bridge.setStyle(element: element, name: "top", value: "\(y)px")
    }

    /// Updates the arrow element to point to a different edge.
    ///
    /// - Parameters:
    ///   - popoverElement: The popover dialog element
    ///   - edge: The new edge
    private static func updateArrowEdge(_ popoverElement: JSObject, edge: Edge) {
        // Find arrow element and update its class
        let selector = ".raven-popover-arrow"
        if JSObject.global.eval.function != nil,
           let arrow = popoverElement.querySelector?(selector).object {
            let newClass = "raven-popover-arrow raven-popover-arrow-\(edgeClassName(edge))"
            arrow.className = .string(newClass)
        }
    }

    /// Positions the arrow to point at the anchor center.
    ///
    /// - Parameters:
    ///   - popoverElement: The popover dialog element
    ///   - anchorBounds: The anchor bounding rectangle
    ///   - popoverPosition: The popover (x, y) position
    ///   - edge: The arrow edge
    private static func positionArrow(
        popoverElement: JSObject,
        anchorBounds: CGRect,
        popoverPosition: (x: Double, y: Double),
        edge: Edge
    ) {
        let bridge = DOMBridge.shared

        // Find arrow element
        let selector = ".raven-popover-arrow"
        guard let arrow = popoverElement.querySelector?(selector).object else {
            return
        }

        let anchorCenterX = anchorBounds.minX + anchorBounds.width / 2
        let anchorCenterY = anchorBounds.minY + anchorBounds.height / 2

        switch edge {
        case .top, .bottom:
            // Position arrow horizontally to point at anchor center
            let arrowX = anchorCenterX - popoverPosition.x - arrowSize / 2
            bridge.setStyle(element: arrow, name: "left", value: "\(arrowX)px")

        case .leading, .trailing:
            // Position arrow vertically to point at anchor center
            let arrowY = anchorCenterY - popoverPosition.y - arrowSize / 2
            bridge.setStyle(element: arrow, name: "top", value: "\(arrowY)px")
        }
    }

    /// Animates the popover presentation.
    ///
    /// - Parameter nodeId: The NodeID of the dialog element
    public static func animatePresentation(nodeId: NodeID) async {
        // Animation is handled by CSS
        try? await Task.sleep(for: .milliseconds(50))
    }

    /// Animates the popover dismissal.
    ///
    /// - Parameter nodeId: The NodeID of the dialog element
    public static func animateDismissal(nodeId: NodeID) async {
        await DialogRenderer.animateDismiss(
            dialogId: nodeId,
            duration: PresentationAnimations.fastDuration
        )
    }
}

// MARK: - CGRect Helper

extension PopoverRenderer {
    /// A simple rectangle structure for positioning calculations.
    private struct CGRect {
        let minX: Double
        let minY: Double
        let width: Double
        let height: Double

        var maxX: Double { minX + width }
        var maxY: Double { minY + height }

        init(x: Double, y: Double, width: Double, height: Double) {
            self.minX = x
            self.minY = y
            self.width = width
            self.height = height
        }
    }
}
