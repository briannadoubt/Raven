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
        if let alertData = extractAlertData(from: entry.content) {
            // Use extracted data to render the alert
            return renderAlert(
                title: alertData.title,
                message: alertData.message,
                buttons: alertData.buttons,
                zIndex: entry.zIndex,
                presentationId: entry.id,
                coordinator: coordinator
            )
        } else {
            // Fallback: create a basic alert if extraction fails
            return renderAlert(
                title: "Alert",
                message: nil,
                buttons: [],
                zIndex: entry.zIndex,
                presentationId: entry.id,
                coordinator: coordinator
            )
        }
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
    /// The expected structure is:
    /// - VStack containing:
    ///   - Text (title - first text node)
    ///   - Text or other views (message - optional subsequent text)
    ///   - Button elements (actions)
    ///
    /// - Parameter content: The AnyView to extract from
    /// - Returns: An optional tuple of (title, message, buttons)
    public static func extractAlertData(
        from content: AnyView
    ) -> (title: String, message: String?, buttons: [ButtonConfiguration])? {
        // Render the AnyView to a VNode to examine its structure
        let vnode = content.render()

        // Extract components from the VNode tree
        if let components = extractComponentsFromVNode(vnode) {
            return (
                title: components.title,
                message: components.message,
                buttons: components.buttons
            )
        }

        // Fallback for coordinator-renderable containers (e.g. VStack) when AnyView
        // is rendered outside RenderLoop and children are not materialized.
        if let mirrored = extractComponentsFromView(content.wrappedView) {
            return (
                title: mirrored.title,
                message: mirrored.message,
                buttons: mirrored.buttons
            )
        }

        return nil
    }

    /// Internal structure for extracted alert components
    private struct AlertComponents {
        let title: String
        let message: String?
        let buttons: [ButtonConfiguration]
    }

    /// Extracts alert components from a VNode tree.
    ///
    /// This method parses the VNode structure to extract:
    /// - First text content as title
    /// - Subsequent text content as message (optional)
    /// - Button elements as actions
    ///
    /// - Parameter vnode: The VNode to parse
    /// - Returns: Optional AlertComponents if extraction succeeds
    private static func extractComponentsFromVNode(_ vnode: VNode) -> AlertComponents? {
        var textNodes: [String] = []
        var buttons: [ButtonConfiguration] = []

        // Recursively collect text and buttons from the VNode tree
        collectNodes(from: vnode, texts: &textNodes, buttons: &buttons)

        // We need at least a title
        guard !textNodes.isEmpty else {
            return nil
        }

        // First text is the title
        let title = textNodes[0]

        // Second text (if present) is the message
        let message = textNodes.count > 1 ? textNodes[1] : nil

        return AlertComponents(
            title: title,
            message: message,
            buttons: buttons
        )
    }

    /// Recursively collects text and button nodes from a VNode tree.
    ///
    /// - Parameters:
    ///   - vnode: The VNode to traverse
    ///   - texts: Array to accumulate text content
    ///   - buttons: Array to accumulate button configurations
    private static func collectNodes(
        from vnode: VNode,
        texts: inout [String],
        buttons: inout [ButtonConfiguration]
    ) {
        // Check the node type
        switch vnode.type {
        case .text(let content):
            // Collect text content
            if !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                texts.append(content)
            }

        case .element(let tag):
            // Check if this is a button element
            if tag == "button" {
                // Extract button label from children
                let label = extractButtonLabel(from: vnode.children)

                // Try to determine button role from props
                let role = extractButtonRole(from: vnode.props)

                // Note: We cannot extract the action closure from the VNode,
                // so buttons will have nil actions. The coordinator will need
                // to handle button dismissal separately.
                buttons.append(ButtonConfiguration(
                    label: label,
                    role: role,
                    action: nil
                ))
            } else {
                // Recursively process children
                for child in vnode.children {
                    collectNodes(from: child, texts: &texts, buttons: &buttons)
                }
            }

        case .fragment:
            // Process fragment children
            for child in vnode.children {
                collectNodes(from: child, texts: &texts, buttons: &buttons)
            }

        case .component:
            // Process component children
            for child in vnode.children {
                collectNodes(from: child, texts: &texts, buttons: &buttons)
            }
        }
    }

    /// Extracts button label text from child VNodes.
    ///
    /// - Parameter children: The button's child VNodes
    /// - Returns: The extracted label text or "Button" as fallback
    private static func extractButtonLabel(from children: [VNode]) -> String {
        for child in children {
            // Check if this is a text node
            if let content = child.textContent {
                return content
            }
            // Recursively check nested children
            if case .element = child.type {
                let nestedLabel = extractButtonLabel(from: child.children)
                if !nestedLabel.isEmpty && nestedLabel != "Button" {
                    return nestedLabel
                }
            }
        }
        return "Button"
    }

    /// Attempts to extract button role from VNode properties.
    ///
    /// This checks for CSS classes or other markers that indicate button role.
    ///
    /// - Parameter props: The button's VNode properties
    /// - Returns: Optional ButtonRole if detected
    private static func extractButtonRole(from props: [String: VProperty]) -> ButtonRole? {
        // Check for class attributes that might indicate role
        if let classProperty = props["class"],
           case .attribute(_, let value) = classProperty {
            if value.contains("destructive") {
                return .destructive
            }
            if value.contains("cancel") {
                return .cancel
            }
        }

        // No role detected
        return nil
    }

    /// Fallback extraction path that walks the wrapped view structure with Mirror.
    ///
    /// This supports headless/unit-test contexts where container primitives can render
    /// without children unless a full coordinator render pass is available.
    private static func extractComponentsFromView(_ view: any View) -> AlertComponents? {
        var textNodes: [String] = []
        var buttons: [ButtonConfiguration] = []
        collectComponentsFromValue(view, texts: &textNodes, buttons: &buttons)

        guard !textNodes.isEmpty else { return nil }
        return AlertComponents(
            title: textNodes[0],
            message: textNodes.count > 1 ? textNodes[1] : nil,
            buttons: buttons
        )
    }

    private static func collectComponentsFromValue(
        _ value: Any,
        texts: inout [String],
        buttons: inout [ButtonConfiguration]
    ) {
        if let text = value as? Text {
            let content = text.textContent.trimmingCharacters(in: .whitespacesAndNewlines)
            if !content.isEmpty {
                texts.append(content)
            }
            return
        }

        // Treat any Button<...> as an action source and avoid traversing its label
        // as plain text content to prevent title/message contamination.
        let typeName = String(describing: type(of: value))
        if typeName.hasPrefix("Button<") {
            if let label = extractButtonLabelFromValue(value) {
                buttons.append(ButtonConfiguration(label: label, role: nil, action: nil))
            }
            return
        }

        let mirror = Mirror(reflecting: value)
        for child in mirror.children {
            collectComponentsFromValue(child.value, texts: &texts, buttons: &buttons)
        }
    }

    private static func extractButtonLabelFromValue(_ value: Any) -> String? {
        let mirror = Mirror(reflecting: value)
        for child in mirror.children where child.label == "label" {
            return extractFirstText(from: child.value)
        }

        // Fallback: search all descendants in case field labels differ.
        for child in mirror.children {
            if let found = extractFirstText(from: child.value) {
                return found
            }
        }
        return nil
    }

    private static func extractFirstText(from value: Any) -> String? {
        if let text = value as? Text {
            let content = text.textContent.trimmingCharacters(in: .whitespacesAndNewlines)
            return content.isEmpty ? nil : content
        }

        let mirror = Mirror(reflecting: value)
        for child in mirror.children {
            if let found = extractFirstText(from: child.value) {
                return found
            }
        }
        return nil
    }
}
