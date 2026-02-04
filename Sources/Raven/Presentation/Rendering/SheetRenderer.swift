import Foundation

/// Renders sheet presentations as HTML5 dialog elements.
///
/// The `SheetRenderer` creates sheet-style presentations that slide up from
/// the bottom of the screen. It supports:
///
/// - Drag indicator for visual feedback
/// - Swipe-to-dismiss gestures
/// - Multiple presentation detents (heights)
/// - Interactive dismiss control
/// - Smooth slide-up/down animations
///
/// ## Sheet Structure
///
/// ```html
/// <dialog class="raven-dialog raven-sheet">
///   <div class="raven-sheet-drag-indicator"></div>
///   <div class="raven-sheet-container">
///     <!-- Content -->
///   </div>
/// </dialog>
/// ```
///
/// ## Detent Support
///
/// Sheets can be sized using presentation detents:
/// - `.large` - Full height (default)
/// - `.medium` - Half height
/// - `.height(n)` - Fixed pixel height
/// - `.fraction(n)` - Percentage of available height
///
/// ## Interactive Dismissal
///
/// Sheets can be dismissed by:
/// - Swiping down (if not disabled)
/// - Tapping backdrop (if not disabled)
/// - Programmatic dismiss
@MainActor
public struct SheetRenderer: Sendable {
    // MARK: - Constants

    /// Default maximum height as percentage of viewport
    private static let defaultMaxHeight: Double = 0.9

    /// Minimum sheet height in pixels
    private static let minSheetHeight: Double = 200

    // MARK: - Public Methods

    /// Renders a sheet presentation entry as a VNode.
    ///
    /// This method creates a complete sheet dialog with drag indicator,
    /// content container, and appropriate styling.
    ///
    /// - Parameters:
    ///   - entry: The presentation entry to render
    ///   - coordinator: The presentation coordinator
    /// - Returns: A VNode representing the sheet dialog
    public static func render(
        entry: PresentationEntry,
        coordinator: PresentationCoordinator
    ) -> VNode {
        // Check if interactive dismiss is disabled from environment
        let dismissDisabled = false // TODO: Read from entry metadata

        // Create dismiss handler
        let dismissHandler = dismissDisabled ? nil : DialogRenderer.createBackdropClickHandler(
            presentationId: entry.id,
            coordinator: coordinator
        )

        // Build child elements
        var children: [VNode] = []

        // Add drag indicator
        children.append(createDragIndicator())

        // Add content container
        children.append(createContentContainer(content: entry.content))

        // Create dialog with sheet styling
        var props: [String: VProperty] = [:]

        // Add detent styling if specified
        // TODO: Extract detents from entry metadata
        let detent: PresentationDetent = .large
        let maxHeight = calculateMaxHeight(for: detent)
        props["style_max-height"] = .style(name: "max-height", value: "\(Int(maxHeight * 100))vh")

        return DialogRenderer.createDialog(
            type: "sheet",
            zIndex: entry.zIndex,
            dismissHandler: dismissHandler,
            children: children,
            additionalProps: props
        )
    }

    // MARK: - Private Methods

    /// Creates the drag indicator element.
    ///
    /// The drag indicator is a small horizontal bar at the top of the sheet
    /// that provides visual affordance for the swipe gesture.
    ///
    /// - Returns: A VNode for the drag indicator
    private static func createDragIndicator() -> VNode {
        return VNode.element(
            "div",
            props: [
                "class": .attribute(name: "class", value: "raven-sheet-drag-indicator"),
                "aria-hidden": .attribute(name: "aria-hidden", value: "true")
            ],
            children: []
        )
    }

    /// Creates the content container element.
    ///
    /// The content container wraps the sheet content and provides
    /// scrolling behavior if content exceeds the sheet height.
    ///
    /// - Parameter content: The content to display in the sheet
    /// - Returns: A VNode for the content container
    private static func createContentContainer(content: AnyView) -> VNode {
        return VNode.element(
            "div",
            props: [
                "class": .attribute(name: "class", value: "raven-sheet-container"),
                "role": .attribute(name: "role", value: "document")
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
        // In a complete implementation, this would convert the view to VNodes
        return VNode.element(
            "div",
            props: [
                "class": .attribute(name: "class", value: "raven-presentation-content")
            ],
            children: []
        )
    }

    /// Calculates the maximum height for a detent.
    ///
    /// This method converts a presentation detent into a fractional
    /// height value (0.0 to 1.0) for CSS styling.
    ///
    /// - Parameter detent: The presentation detent
    /// - Returns: A fractional height value
    private static func calculateMaxHeight(for detent: PresentationDetent) -> Double {
        // Create a context with viewport height
        // In a real implementation, we'd get this from the window
        let context = PresentationDetent.Context(maxDetentValue: 1000)

        let resolvedHeight = detent.resolvedHeight(in: context)
        let fraction = resolvedHeight / context.maxDetentValue

        return min(fraction, defaultMaxHeight)
    }

    /// Attaches swipe gesture handlers to a sheet element.
    ///
    /// This method should be called after the sheet is rendered to the DOM
    /// to enable swipe-to-dismiss functionality.
    ///
    /// - Parameters:
    ///   - nodeId: The NodeID of the dialog element
    ///   - presentationId: The ID of the presentation
    ///   - coordinator: The presentation coordinator
    ///   - dismissDisabled: Whether dismiss is disabled
    /// - Returns: A SwipeDismissHandler instance
    public static func attachSwipeHandler(
        nodeId: NodeID,
        presentationId: UUID,
        coordinator: PresentationCoordinator,
        dismissDisabled: Bool = false
    ) -> SwipeDismissHandler? {
        let bridge = DOMBridge.shared

        guard let dialogElement = bridge.getNode(id: nodeId) else {
            return nil
        }

        let handler = SwipeDismissHandler(
            dialogElement: dialogElement,
            dismissDisabled: dismissDisabled,
            onDismiss: { @MainActor in
                coordinator.dismiss(presentationId)
            }
        )

        handler.attach()
        return handler
    }

    /// Updates the detent for an active sheet.
    ///
    /// This method allows dynamically changing the sheet height by
    /// updating the detent value. The change is animated smoothly.
    ///
    /// - Parameters:
    ///   - nodeId: The NodeID of the dialog element
    ///   - detent: The new presentation detent
    public static func updateDetent(nodeId: NodeID, detent: PresentationDetent) {
        let bridge = DOMBridge.shared

        guard let dialogElement = bridge.getNode(id: nodeId) else {
            return
        }

        let maxHeight = calculateMaxHeight(for: detent)
        bridge.setStyle(
            element: dialogElement,
            name: "max-height",
            value: "\(Int(maxHeight * 100))vh"
        )
    }

    /// Animates the sheet presentation.
    ///
    /// This method should be called after showing the dialog to trigger
    /// the slide-up animation.
    ///
    /// - Parameter nodeId: The NodeID of the dialog element
    public static func animatePresentation(nodeId: NodeID) async {
        // Animation is handled by CSS
        // This is a placeholder for any additional setup
        try? await Task.sleep(for: .milliseconds(50))
    }

    /// Animates the sheet dismissal.
    ///
    /// This method triggers the slide-down animation and waits for it
    /// to complete before removing the dialog.
    ///
    /// - Parameter nodeId: The NodeID of the dialog element
    public static func animateDismissal(nodeId: NodeID) async {
        await DialogRenderer.animateDismiss(
            dialogId: nodeId,
            duration: PresentationAnimations.fastDuration
        )
    }
}

// MARK: - Sheet Configuration

extension SheetRenderer {
    /// Configuration options for sheet presentations.
    ///
    /// These options can be stored in the presentation entry metadata
    /// to customize sheet behavior.
    public struct Configuration: Sendable, Codable {
        /// Available detents for the sheet
        public var detents: [String]

        /// The selected detent identifier
        public var selectedDetent: String?

        /// Whether interactive dismiss is disabled
        public var interactiveDismissDisabled: Bool

        /// Whether drag indicator should be shown
        public var showDragIndicator: Bool

        /// Creates a default configuration
        public init(
            detents: [String] = ["large"],
            selectedDetent: String? = nil,
            interactiveDismissDisabled: Bool = false,
            showDragIndicator: Bool = true
        ) {
            self.detents = detents
            self.selectedDetent = selectedDetent
            self.interactiveDismissDisabled = interactiveDismissDisabled
            self.showDragIndicator = showDragIndicator
        }

        /// Default configuration with large detent
        public static let `default` = Configuration()
    }
}
