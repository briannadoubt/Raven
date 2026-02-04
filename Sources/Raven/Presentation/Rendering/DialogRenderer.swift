import Foundation

/// Renders presentation entries as HTML5 dialog VNodes.
///
/// This renderer converts `PresentationEntry` instances into VNode trees
/// using the HTML5 `<dialog>` element as the foundation. It provides:
///
/// - Dialog element creation with appropriate classes and attributes
/// - Z-index management for proper layering
/// - Event handler registration for dismiss actions
/// - Integration with animation system
/// - Backdrop click handling
///
/// ## Dialog Element Structure
///
/// The rendered dialog follows this structure:
///
/// ```html
/// <dialog class="raven-dialog raven-{type}" style="z-index: {zIndex}">
///   <!-- Presentation-specific content -->
/// </dialog>
/// ```
///
/// ## Usage
///
/// The renderer is used internally by the presentation system:
///
/// ```swift
/// let node = DialogRenderer.render(entry: presentationEntry, coordinator: coordinator)
/// ```
@MainActor
public struct DialogRenderer: Sendable {
    // MARK: - Public Methods

    /// Renders a presentation entry as a VNode.
    ///
    /// This method converts a presentation entry into a complete VNode tree
    /// with the appropriate dialog element, styling, event handlers, and content.
    ///
    /// - Parameters:
    ///   - entry: The presentation entry to render
    ///   - coordinator: The presentation coordinator for dismiss actions
    /// - Returns: A VNode representing the dialog element and its content
    public static func render(
        entry: PresentationEntry,
        coordinator: PresentationCoordinator
    ) -> VNode {
        switch entry.type {
        case .sheet:
            return SheetRenderer.render(entry: entry, coordinator: coordinator)

        case .alert:
            return AlertRenderer.render(entry: entry, coordinator: coordinator)

        case .popover(let anchor, let edge):
            return PopoverRenderer.render(
                entry: entry,
                anchor: anchor,
                edge: edge,
                coordinator: coordinator
            )

        case .fullScreenCover:
            return renderFullScreenCover(entry: entry, coordinator: coordinator)

        case .confirmationDialog:
            return renderConfirmationDialog(entry: entry, coordinator: coordinator)
        }
    }

    /// Creates the base dialog VNode with common properties.
    ///
    /// This method constructs a dialog element with:
    /// - Appropriate CSS classes
    /// - Z-index styling
    /// - Common attributes
    /// - Backdrop click handler
    ///
    /// - Parameters:
    ///   - type: The CSS class suffix for the dialog type (e.g., "sheet", "alert")
    ///   - zIndex: The z-index for layering
    ///   - dismissHandler: Optional handler for backdrop clicks
    ///   - children: Child VNodes to render inside the dialog
    ///   - additionalProps: Additional properties to merge
    /// - Returns: A dialog VNode with the specified configuration
    public static func createDialog(
        type: String,
        zIndex: Int,
        dismissHandler: (() -> Void)? = nil,
        children: [VNode],
        additionalProps: [String: VProperty] = [:]
    ) -> VNode {
        var props: [String: VProperty] = [
            "class": .attribute(name: "class", value: "raven-dialog raven-\(type)"),
            "data-raven-dialog": .attribute(name: "data-raven-dialog", value: "true")
        ]

        // Add z-index style
        props["style_z-index"] = .style(name: "z-index", value: String(zIndex))

        // Add ARIA attributes for dialog (WCAG 2.1 requirement)
        // HTML5 <dialog> element already has implicit role="dialog"
        props["role"] = .attribute(name: "role", value: "dialog")

        // Mark as modal if it blocks interaction with other content
        props["aria-modal"] = .attribute(name: "aria-modal", value: "true")

        // Dialogs should have an accessible label (can be set via aria-labelledby or aria-label)
        // This will typically be set by the specific dialog renderer

        // Add backdrop click handler if provided
        if let handler = dismissHandler {
            let handlerID = UUID()
            props["onClick"] = .eventHandler(event: "click", handlerID: handlerID)

            // Store handler for later - in a real implementation, this would be
            // registered with the DOMBridge event system
            // For now, we just create the property
        }

        // Merge additional props
        for (key, value) in additionalProps {
            props[key] = value
        }

        return VNode.element(
            "dialog",
            props: props,
            children: children,
            key: "dialog-\(type)-\(zIndex)"
        )
    }

    /// Handles backdrop clicks for modal dismissal.
    ///
    /// This creates a backdrop click handler that checks if the click
    /// occurred on the dialog backdrop (not on content within the dialog).
    ///
    /// - Parameters:
    ///   - presentationId: The ID of the presentation to dismiss
    ///   - coordinator: The presentation coordinator
    /// - Returns: A closure that handles backdrop clicks
    public static func createBackdropClickHandler(
        presentationId: UUID,
        coordinator: PresentationCoordinator
    ) -> @Sendable @MainActor () -> Void {
        return { @MainActor in
            // In the actual implementation, we'd check if the click
            // was on the dialog element itself (not a child)
            // For now, this is a placeholder
            coordinator.dismiss(presentationId)
        }
    }

    // MARK: - Full Screen Cover Rendering

    /// Renders a full screen cover presentation.
    ///
    /// Full screen covers take up the entire viewport and typically
    /// don't have dismissal via backdrop clicks.
    ///
    /// - Parameters:
    ///   - entry: The presentation entry
    ///   - coordinator: The presentation coordinator
    /// - Returns: A VNode for the full screen cover
    private static func renderFullScreenCover(
        entry: PresentationEntry,
        coordinator: PresentationCoordinator
    ) -> VNode {
        // Create content wrapper
        let contentWrapper = VNode.element(
            "div",
            props: [
                "class": .attribute(name: "class", value: "raven-fullscreen-content")
            ],
            children: [renderContent(entry.content)]
        )

        // Create dialog without backdrop click handler
        return createDialog(
            type: "fullscreen",
            zIndex: entry.zIndex,
            dismissHandler: nil,
            children: [contentWrapper]
        )
    }

    // MARK: - Confirmation Dialog Rendering

    /// Renders a confirmation dialog presentation.
    ///
    /// Confirmation dialogs slide up from the bottom (on mobile) or
    /// appear centered (on desktop) with action buttons.
    ///
    /// - Parameters:
    ///   - entry: The presentation entry
    ///   - coordinator: The presentation coordinator
    /// - Returns: A VNode for the confirmation dialog
    private static func renderConfirmationDialog(
        entry: PresentationEntry,
        coordinator: PresentationCoordinator
    ) -> VNode {
        let dismissHandler = createBackdropClickHandler(
            presentationId: entry.id,
            coordinator: coordinator
        )

        // Create content wrapper
        let contentWrapper = VNode.element(
            "div",
            props: [
                "class": .attribute(name: "class", value: "raven-confirmation-content")
            ],
            children: [renderContent(entry.content)]
        )

        return createDialog(
            type: "confirmation",
            zIndex: entry.zIndex,
            dismissHandler: dismissHandler,
            children: [contentWrapper]
        )
    }

    // MARK: - Content Rendering

    /// Renders the content view into a VNode.
    ///
    /// This method converts the AnyView content into a VNode tree.
    /// For now, it creates a placeholder element that will be filled
    /// by the render system.
    ///
    /// - Parameter content: The AnyView content to render
    /// - Returns: A VNode representing the content
    private static func renderContent(_ content: AnyView) -> VNode {
        // In a complete implementation, this would traverse the view
        // hierarchy and convert it to VNodes. For now, we create a
        // placeholder that the render coordinator will populate.
        return VNode.element(
            "div",
            props: [
                "class": .attribute(name: "class", value: "raven-presentation-content"),
                "data-content-placeholder": .attribute(name: "data-content-placeholder", value: "true")
            ],
            children: []
        )
    }

    /// Extracts text content from a Text view if possible.
    ///
    /// Helper method to extract string content from Text views
    /// for rendering in alerts and buttons.
    ///
    /// - Parameter view: The view to extract text from
    /// - Returns: The text content if available
    internal static func extractTextContent(_ view: Any) -> String? {
        // Use reflection to extract text from Text views
        let mirror = Mirror(reflecting: view)

        // Look for a "content" property (Text views store their string here)
        for child in mirror.children {
            if child.label == "content", let content = child.value as? String {
                return content
            }
        }

        return nil
    }

    /// Creates a button element VNode.
    ///
    /// Helper method to create button elements with consistent styling
    /// and event handling.
    ///
    /// - Parameters:
    ///   - label: The button label text
    ///   - role: The button role (cancel, destructive, or nil)
    ///   - action: The action to perform when clicked
    /// - Returns: A button VNode
    internal static func createButton(
        label: String,
        role: ButtonRole?,
        action: @escaping @Sendable @MainActor () -> Void
    ) -> VNode {
        let handlerID = UUID()

        var buttonClasses = ["raven-alert-button"]
        if let role = role {
            switch role {
            case .cancel:
                buttonClasses.append("raven-alert-button-cancel")
            case .destructive:
                buttonClasses.append("raven-alert-button-destructive")
            }
        }

        let props: [String: VProperty] = [
            "class": .attribute(name: "class", value: buttonClasses.joined(separator: " ")),
            "onClick": .eventHandler(event: "click", handlerID: handlerID)
        ]

        return VNode.element(
            "button",
            props: props,
            children: [VNode.text(label)]
        )
    }

    /// Renders a close button for dismissible presentations.
    ///
    /// Creates a standard close button (×) that can be positioned
    /// in the top-right corner of presentations.
    ///
    /// - Parameters:
    ///   - presentationId: The ID of the presentation to dismiss
    ///   - coordinator: The presentation coordinator
    /// - Returns: A VNode for the close button
    internal static func renderCloseButton(
        presentationId: UUID,
        coordinator: PresentationCoordinator
    ) -> VNode {
        let handlerID = UUID()

        let props: [String: VProperty] = [
            "class": .attribute(name: "class", value: "raven-close-button"),
            "aria-label": .attribute(name: "aria-label", value: "Close"),
            "onClick": .eventHandler(event: "click", handlerID: handlerID)
        ]

        return VNode.element(
            "button",
            props: props,
            children: [VNode.text("×")]
        )
    }

    /// Applies dismiss animation to a dialog element.
    ///
    /// This method triggers the dismiss animation by setting the
    /// appropriate data attribute and waiting for the animation to complete.
    ///
    /// - Parameters:
    ///   - dialogId: The NodeID of the dialog element
    ///   - duration: The animation duration in milliseconds
    /// - Returns: An async task that completes after the animation
    public static func animateDismiss(
        dialogId: NodeID,
        duration: Int = PresentationAnimations.fastDuration
    ) async {
        let bridge = DOMBridge.shared

        guard let element = bridge.getNode(id: dialogId) else {
            return
        }

        // Set dismissing attribute
        bridge.setAttribute(element: element, name: "data-dismissing", value: "true")

        // Wait for animation to complete
        try? await Task.sleep(for: .milliseconds(duration))

        // Close the dialog
        if let eval = JSObject.global.eval.function {
            _ = eval("arguments[0].close()")
        }
    }
}

// MARK: - JavaScript Helpers

import JavaScriptKit

extension DialogRenderer {
    /// Shows a dialog element using the HTML5 dialog API.
    ///
    /// - Parameter dialogElement: The dialog JSObject to show
    public static func showDialog(_ dialogElement: JSObject) {
        // Use showModal() to show with backdrop
        _ = dialogElement.showModal!()
    }

    /// Closes a dialog element using the HTML5 dialog API.
    ///
    /// - Parameter dialogElement: The dialog JSObject to close
    public static func closeDialog(_ dialogElement: JSObject) {
        _ = dialogElement.close!()
    }
}
