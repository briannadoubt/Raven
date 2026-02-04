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
        coordinator: PresentationCoordinator
    ) -> VNode {
        // Create dismiss handler for backdrop clicks
        let dismissHandler = DialogRenderer.createBackdropClickHandler(
            presentationId: entry.id,
            coordinator: coordinator
        )

        // Create arrow element
        let arrow = createArrow(edge: edge)

        // Create content container
        let content = createContentContainer(content: entry.content)

        // Build children
        let children = [arrow, content]

        // Create dialog with popover styling
        // Positioning will be done after render via JavaScript
        var props: [String: VProperty] = [
            "data-anchor": .attribute(name: "data-anchor", value: anchorIdentifier(anchor)),
            "data-edge": .attribute(name: "data-edge", value: edge.rawValue)
        ]

        // Store anchor and edge in metadata for post-render positioning
        props["data-popover-metadata"] = .attribute(
            name: "data-popover-metadata",
            value: "{\"edge\":\"\(edge.rawValue)\"}"
        )

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
    private static func createContentContainer(content: AnyView) -> VNode {
        return VNode.element(
            "div",
            props: [
                "class": .attribute(name: "class", value: "raven-popover-content"),
                "role": .attribute(name: "role", value: "dialog")
            ],
            children: [renderContent(content)]
        )
    }

    /// Renders the content view into a VNode.
    ///
    /// - Parameter content: The AnyView content to render
    /// - Returns: A VNode representing the content
    private static func renderContent(_ content: AnyView) -> VNode {
        // Placeholder for content rendering
        return VNode.element(
            "div",
            props: [
                "class": .attribute(name: "class", value: "raven-presentation-content")
            ],
            children: []
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

        // Get anchor bounds
        guard let anchorBounds = getAnchorBounds(anchor) else {
            // Fallback to center of viewport
            positionAtCenter(popoverElement)
            return
        }

        // Get popover dimensions
        let popoverWidth = popoverElement.offsetWidth.number ?? defaultWidth
        let popoverHeight = popoverElement.offsetHeight.number ?? 200

        // Get viewport dimensions
        let viewportWidth = JSObject.global.window.innerWidth.number ?? 1024
        let viewportHeight = JSObject.global.window.innerHeight.number ?? 768

        // Calculate position for preferred edge
        var position = calculatePosition(
            anchorBounds: anchorBounds,
            popoverSize: (popoverWidth, popoverHeight),
            viewportSize: (viewportWidth, viewportHeight),
            edge: preferredEdge
        )

        // Check if we need to flip to fit in viewport
        let fitsInViewport = checkFitsInViewport(
            position: position,
            size: (popoverWidth, popoverHeight),
            viewportSize: (viewportWidth, viewportHeight)
        )

        var finalEdge = preferredEdge

        if !fitsInViewport {
            // Try opposite edge
            let oppositeEdge = preferredEdge.opposite
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

        // Constrain position to viewport
        position = constrainToViewport(
            position: position,
            size: (popoverWidth, popoverHeight),
            viewportSize: (viewportWidth, viewportHeight)
        )

        // Apply position
        bridge.setStyle(element: popoverElement, name: "left", value: "\(position.x)px")
        bridge.setStyle(element: popoverElement, name: "top", value: "\(position.y)px")

        // Update arrow if edge changed
        if finalEdge != preferredEdge {
            updateArrowEdge(popoverElement, edge: finalEdge)
        }

        // Position arrow to point at anchor center
        positionArrow(
            popoverElement: popoverElement,
            anchorBounds: anchorBounds,
            popoverPosition: position,
            edge: finalEdge
        )
    }

    /// Gets the bounding rectangle for an anchor.
    ///
    /// - Parameter anchor: The attachment anchor
    /// - Returns: The bounding rectangle or nil
    private static func getAnchorBounds(
        _ anchor: PopoverAttachmentAnchor
    ) -> CGRect? {
        // In a complete implementation, this would:
        // 1. For .source - get bounds of the source view element
        // 2. For .rect - use the provided rect
        // 3. For .point - create a small rect at the point

        // Placeholder: return center of viewport
        let viewportWidth = JSObject.global.window.innerWidth.number ?? 1024
        let viewportHeight = JSObject.global.window.innerHeight.number ?? 768

        return CGRect(
            x: viewportWidth / 2,
            y: viewportHeight / 2,
            width: 1,
            height: 1
        )
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
        if let eval = JSObject.global.eval.function,
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
