import Foundation

/// Renders alert presentations as HTML5 dialog elements.
///
/// The `AlertRenderer` creates iOS-style alert dialogs that appear centered
/// on screen with a modal backdrop. It supports:
///
/// - Title and message display
/// - Multiple buttons with roles (default, cancel, destructive)
/// - Horizontal or vertical button layout
/// - Keyboard accessibility with focus management
/// - Scale and fade animations
///
/// ## Alert Structure
///
/// ```html
/// <dialog class="raven-dialog raven-alert">
///   <div class="raven-alert-content">
///     <div class="raven-alert-title">Title</div>
///     <div class="raven-alert-message">Message</div>
///   </div>
///   <div class="raven-alert-actions">
///     <button class="raven-alert-button">Action</button>
///   </div>
/// </dialog>
/// ```
///
/// ## Button Layout
///
/// - **Two buttons**: Horizontal layout with separator
/// - **One button**: Full width
/// - **Three+ buttons**: Vertical stack
///
/// ## Button Roles
///
/// - `.cancel` - Bold font weight, left position in two-button layout
/// - `.destructive` - Red color for dangerous actions
/// - Default - Standard blue accent color
@MainActor
public struct AlertRenderer: Sendable {
    // MARK: - Constants

    /// Maximum number of buttons for horizontal layout
    private static let horizontalLayoutThreshold = 2

    /// Default button label if none provided
    private static let defaultButtonLabel = "OK"

    // MARK: - Public Methods

    /// Renders an alert presentation entry as a VNode.
    ///
    /// This method creates a complete alert dialog with title, message,
    /// and action buttons.
    ///
    /// - Parameters:
    ///   - entry: The presentation entry to render
    ///   - coordinator: The presentation coordinator
    /// - Returns: A VNode representing the alert dialog
    public static func render(
        entry: PresentationEntry,
        coordinator: PresentationCoordinator
    ) -> VNode {
        // Extract alert data from content
        // In a real implementation, we'd parse the AnyView to extract alert details
        // For now, we create a basic structure

        // Create alert content
        let content = createAlertContent(title: "Alert", message: nil)

        // Create alert actions
        let actions = createAlertActions(
            buttons: [],
            presentationId: entry.id,
            coordinator: coordinator
        )

        // Build children
        let children = [content, actions]

        // Create dialog
        return DialogRenderer.createDialog(
            type: "alert",
            zIndex: entry.zIndex,
            dismissHandler: nil, // Alerts should only dismiss via button actions
            children: children,
            additionalProps: [
                "role": .attribute(name: "role", value: "alertdialog"),
                "aria-modal": .attribute(name: "aria-modal", value: "true")
            ]
        )
    }

    /// Renders an alert with explicit configuration.
    ///
    /// This variant allows direct specification of alert properties
    /// without needing to extract them from a view hierarchy.
    ///
    /// - Parameters:
    ///   - title: The alert title
    ///   - message: Optional message text
    ///   - buttons: Array of button configurations
    ///   - zIndex: The z-index for layering
    ///   - presentationId: The presentation ID for dismiss handling
    ///   - coordinator: The presentation coordinator
    /// - Returns: A VNode representing the alert dialog
    public static func renderAlert(
        title: String,
        message: String?,
        buttons: [ButtonConfiguration],
        zIndex: Int,
        presentationId: UUID,
        coordinator: PresentationCoordinator
    ) -> VNode {
        // Create alert content
        let content = createAlertContent(title: title, message: message)

        // Create alert actions
        let actions = createAlertActions(
            buttons: buttons,
            presentationId: presentationId,
            coordinator: coordinator
        )

        // Build children
        let children = [content, actions]

        // Create dialog
        return DialogRenderer.createDialog(
            type: "alert",
            zIndex: zIndex,
            dismissHandler: nil,
            children: children,
            additionalProps: [
                "role": .attribute(name: "role", value: "alertdialog"),
                "aria-modal": .attribute(name: "aria-modal", value: "true"),
                "aria-labelledby": .attribute(name: "aria-labelledby", value: "alert-title")
            ]
        )
    }

    // MARK: - Private Methods

    /// Creates the alert content section with title and message.
    ///
    /// - Parameters:
    ///   - title: The alert title
    ///   - message: Optional message text
    /// - Returns: A VNode for the alert content
    private static func createAlertContent(
        title: String,
        message: String?
    ) -> VNode {
        var children: [VNode] = []

        // Add title
        children.append(VNode.element(
            "div",
            props: [
                "class": .attribute(name: "class", value: "raven-alert-title"),
                "id": .attribute(name: "id", value: "alert-title")
            ],
            children: [VNode.text(title)]
        ))

        // Add message if provided
        if let message = message {
            children.append(VNode.element(
                "div",
                props: [
                    "class": .attribute(name: "class", value: "raven-alert-message"),
                    "id": .attribute(name: "id", value: "alert-message")
                ],
                children: [VNode.text(message)]
            ))
        }

        return VNode.element(
            "div",
            props: [
                "class": .attribute(name: "class", value: "raven-alert-content")
            ],
            children: children
        )
    }

    /// Creates the alert actions section with buttons.
    ///
    /// - Parameters:
    ///   - buttons: Array of button configurations
    ///   - presentationId: The presentation ID
    ///   - coordinator: The presentation coordinator
    /// - Returns: A VNode for the alert actions
    private static func createAlertActions(
        buttons: [ButtonConfiguration],
        presentationId: UUID,
        coordinator: PresentationCoordinator
    ) -> VNode {
        // Use default OK button if no buttons provided
        let buttonConfigs = buttons.isEmpty
            ? [ButtonConfiguration(label: defaultButtonLabel, role: nil, action: nil)]
            : buttons

        // Determine layout based on button count
        let isHorizontal = buttonConfigs.count <= horizontalLayoutThreshold

        // Create button nodes
        let buttonNodes = buttonConfigs.map { config in
            createAlertButton(
                config: config,
                presentationId: presentationId,
                coordinator: coordinator
            )
        }

        // Apply appropriate class for layout
        let containerClass = isHorizontal
            ? "raven-alert-actions raven-alert-actions-horizontal"
            : "raven-alert-actions raven-alert-actions-vertical"

        return VNode.element(
            "div",
            props: [
                "class": .attribute(name: "class", value: containerClass)
            ],
            children: buttonNodes
        )
    }

    /// Creates a single alert button.
    ///
    /// - Parameters:
    ///   - config: The button configuration
    ///   - presentationId: The presentation ID
    ///   - coordinator: The presentation coordinator
    /// - Returns: A VNode for the button
    private static func createAlertButton(
        config: ButtonConfiguration,
        presentationId: UUID,
        coordinator: PresentationCoordinator
    ) -> VNode {
        let handlerID = UUID()

        // Build button classes
        var buttonClasses = ["raven-alert-button"]

        if let role = config.role {
            switch role {
            case .cancel:
                buttonClasses.append("raven-alert-button-cancel")
            case .destructive:
                buttonClasses.append("raven-alert-button-destructive")
            }
        }

        // Create button action that dismisses and executes custom action
        // Note: In the actual implementation, we'd register this with DOMBridge
        let composedAction: @Sendable @MainActor () -> Void = { @MainActor in
            // Execute custom action first
            config.action?()

            // Then dismiss the alert
            coordinator.dismiss(presentationId)
        }

        let props: [String: VProperty] = [
            "class": .attribute(name: "class", value: buttonClasses.joined(separator: " ")),
            "type": .attribute(name: "type", value: "button"),
            "onClick": .eventHandler(event: "click", handlerID: handlerID)
        ]

        return VNode.element(
            "button",
            props: props,
            children: [VNode.text(config.label)],
            key: "alert-button-\(config.label)"
        )
    }

    /// Shows an alert dialog with animation.
    ///
    /// - Parameter nodeId: The NodeID of the dialog element
    public static func animatePresentation(nodeId: NodeID) async {
        // Animation is handled by CSS
        // Wait briefly for the dialog to be shown
        try? await Task.sleep(for: .milliseconds(50))

        let bridge = DOMBridge.shared
        guard let element = bridge.getNode(id: nodeId) else { return }

        // Focus the first button for keyboard navigation
        if let eval = JSObject.global.eval.function,
           let firstButton = eval("document.querySelector('.raven-alert-button')").object {
            _ = firstButton.focus?()
        }
    }

    /// Animates the alert dismissal.
    ///
    /// - Parameter nodeId: The NodeID of the dialog element
    public static func animateDismissal(nodeId: NodeID) async {
        await DialogRenderer.animateDismiss(
            dialogId: nodeId,
            duration: PresentationAnimations.fastDuration
        )
    }
}

// MARK: - Button Configuration

extension AlertRenderer {
    /// Configuration for an alert button.
    ///
    /// This struct encapsulates all properties needed to render an alert button.
    public struct ButtonConfiguration: Sendable {
        /// The button label text
        public let label: String

        /// The button role (affects styling and position)
        public let role: ButtonRole?

        /// The action to perform when the button is tapped
        public let action: (@Sendable @MainActor () -> Void)?

        /// Creates a button configuration.
        ///
        /// - Parameters:
        ///   - label: The button label text
        ///   - role: The button role (optional)
        ///   - action: The action to perform when tapped (optional)
        public init(
            label: String,
            role: ButtonRole? = nil,
            action: (@Sendable @MainActor () -> Void)? = nil
        ) {
            self.label = label
            self.role = role
            self.action = action
        }

        /// Creates a default button (no role).
        public static func `default`(
            _ label: String,
            action: (@Sendable @MainActor () -> Void)? = nil
        ) -> ButtonConfiguration {
            ButtonConfiguration(label: label, role: nil, action: action)
        }

        /// Creates a cancel button.
        public static func cancel(
            _ label: String = "Cancel",
            action: (@Sendable @MainActor () -> Void)? = nil
        ) -> ButtonConfiguration {
            ButtonConfiguration(label: label, role: .cancel, action: action)
        }

        /// Creates a destructive button.
        public static func destructive(
            _ label: String,
            action: (@Sendable @MainActor () -> Void)? = nil
        ) -> ButtonConfiguration {
            ButtonConfiguration(label: label, role: .destructive, action: action)
        }
    }
}

// MARK: - JavaScript Integration

import JavaScriptKit

extension AlertRenderer {
    /// Extracts alert configuration from a View hierarchy.
    ///
    /// This method attempts to extract alert details (title, message, buttons)
    /// from an AnyView that contains alert content.
    ///
    /// - Parameter content: The AnyView to extract from
    /// - Returns: An optional tuple of (title, message, buttons)
    public static func extractAlertData(
        from content: AnyView
    ) -> (title: String, message: String?, buttons: [ButtonConfiguration])? {
        // In a complete implementation, this would use reflection or
        // a visitor pattern to extract data from the view hierarchy.
        // For now, return nil to indicate extraction is not implemented.
        return nil
    }
}
