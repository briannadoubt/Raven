import Foundation
import JavaScriptKit

/// A control that presents a menu of actions when clicked.
///
/// `Menu` is a primitive view that renders as a button with a dropdown menu.
/// It displays a label that the user can click to reveal a list of menu items.
///
/// ## Overview
///
/// Use `Menu` to present a list of actions or options in a dropdown. Menus are
/// useful for providing contextual actions, settings, or navigation options
/// without cluttering your interface.
///
/// ## Basic Usage
///
/// Create a menu with a text label and menu items:
///
/// ```swift
/// Menu("Options") {
///     Button("Copy") { copy() }
///     Button("Paste") { paste() }
///     Button("Delete", role: .destructive) { delete() }
/// }
/// ```
///
/// ## Custom Labels
///
/// Use the action-label initializer for custom menu labels:
///
/// ```swift
/// Menu {
///     Button("Edit") { edit() }
///     Button("Share") { share() }
/// } label: {
///     HStack {
///         Image(systemName: "ellipsis.circle")
///         Text("Actions")
///     }
/// }
/// ```
///
/// ## Nested Menus
///
/// Create hierarchical menus by nesting Menu views:
///
/// ```swift
/// Menu("File") {
///     Button("New") { newFile() }
///     Menu("Open Recent") {
///         Button("Document 1") { openDoc1() }
///         Button("Document 2") { openDoc2() }
///     }
///     Button("Save") { save() }
/// }
/// ```
///
/// ## Menu Styles
///
/// Customize menu appearance using the `.menuStyle()` modifier:
///
/// ```swift
/// Menu("Options") {
///     Button("Action 1") { }
///     Button("Action 2") { }
/// }
/// .menuStyle(.button)
/// ```
///
/// ## Accessibility
///
/// The menu automatically includes accessibility attributes:
/// - `role="menu"` for the dropdown container
/// - `aria-haspopup="true"` on the trigger button
/// - `aria-expanded` to indicate open/closed state
///
/// ## Best Practices
///
/// - Keep menu labels concise and action-oriented
/// - Group related actions together
/// - Use destructive roles for dangerous actions
/// - Limit nesting depth (ideally max 2 levels)
/// - Provide keyboard navigation support
///
/// ## See Also
///
/// - ``Button``
/// - ``contextMenu(menuItems:)``
/// - ``MenuStyle``
///
/// Because `Menu` is a primitive view with `Body == Never`, it converts directly
/// to a VNode without further composition.
public struct Menu<Label: View, Content: View>: View, PrimitiveView, Sendable {
    public typealias Body = Never

    /// The label content to display as the menu trigger
    private let label: Label

    /// The content containing menu items
    private let content: Content

    /// The menu style from the environment
    @Environment(\.menuStyle) private var menuStyle

    // MARK: - Initializers

    /// Creates a menu with custom label and content.
    ///
    /// Use this initializer to create a menu with a custom label view.
    /// The content closure should contain Button views and/or nested Menu views.
    ///
    /// - Parameters:
    ///   - content: A view builder that creates the menu items.
    ///   - label: A view builder that creates the menu's trigger label.
    ///
    /// Example:
    /// ```swift
    /// Menu {
    ///     Button("Copy") { copy() }
    ///     Button("Paste") { paste() }
    /// } label: {
    ///     HStack {
    ///         Image(systemName: "gear")
    ///         Text("Actions")
    ///     }
    /// }
    /// ```
    @MainActor public init(
        @ViewBuilder content: () -> Content,
        @ViewBuilder label: () -> Label
    ) {
        self.content = content()
        self.label = label()
    }

    // MARK: - VNode Conversion

    /// Converts this Menu to a virtual DOM node.
    ///
    /// The Menu is rendered as:
    /// - A container div with class "raven-menu"
    /// - A trigger button with the label content
    /// - A hidden dropdown container with menu items
    /// - JavaScript handlers for show/hide functionality
    ///
    /// - Returns: A VNode configured as a menu with dropdown.
    @MainActor public func toVNode() -> VNode {
        // Generate unique IDs for this menu
        let menuID = UUID().uuidString
        let triggerID = "menu-trigger-\(menuID)"
        let dropdownID = "menu-dropdown-\(menuID)"

        // Generate a unique handler ID for the click event
        let clickHandlerID = UUID()

        // Create the trigger button
        let triggerProps: [String: VProperty] = [
            "id": .attribute(name: "id", value: triggerID),
            "class": .attribute(name: "class", value: "raven-menu-trigger"),
            "aria-haspopup": .attribute(name: "aria-haspopup", value: "true"),
            "aria-expanded": .attribute(name: "aria-expanded", value: "false"),
            "aria-controls": .attribute(name: "aria-controls", value: dropdownID),
            "onClick": .eventHandler(event: "click", handlerID: clickHandlerID),

            // Default button styles
            "cursor": .style(name: "cursor", value: "pointer"),
            "padding": .style(name: "padding", value: "8px 12px"),
            "border": .style(name: "border", value: "1px solid var(--system-control-border)"),
            "border-radius": .style(name: "border-radius", value: "4px"),
            "background-color": .style(name: "background-color", value: "var(--system-control-background)"),
            "font-size": .style(name: "font-size", value: "14px"),
            "display": .style(name: "display", value: "inline-flex"),
            "align-items": .style(name: "align-items", value: "center"),
            "gap": .style(name: "gap", value: "4px"),
        ]

        // Render the label content
        let labelNode = renderView(label)

        let triggerButton = VNode.element(
            "button",
            props: triggerProps,
            children: [labelNode]
        )

        // Create the dropdown container
        let dropdownProps: [String: VProperty] = [
            "id": .attribute(name: "id", value: dropdownID),
            "class": .attribute(name: "class", value: "raven-menu-dropdown"),
            "role": .attribute(name: "role", value: "menu"),
            "aria-labelledby": .attribute(name: "aria-labelledby", value: triggerID),

            // Dropdown styles (hidden by default)
            "display": .style(name: "display", value: "none"),
            "position": .style(name: "position", value: "absolute"),
            "top": .style(name: "top", value: "100%"),
            "left": .style(name: "left", value: "0"),
            "margin-top": .style(name: "margin-top", value: "4px"),
            "background-color": .style(name: "background-color", value: "var(--system-control-background)"),
            "border": .style(name: "border", value: "1px solid var(--system-control-border)"),
            "border-radius": .style(name: "border-radius", value: "4px"),
            "box-shadow": .style(name: "box-shadow", value: "0 2px 8px rgba(0,0,0,0.15)"),
            "min-width": .style(name: "min-width", value: "160px"),
            "z-index": .style(name: "z-index", value: "1000"),
            "padding": .style(name: "padding", value: "4px 0"),
        ]

        // Extract and render menu items
        let menuItems = extractMenuItems(from: content)

        let dropdown = VNode.element(
            "div",
            props: dropdownProps,
            children: menuItems
        )

        // Create the main menu container
        let containerProps: [String: VProperty] = [
            "class": .attribute(name: "class", value: "raven-menu"),
            "position": .style(name: "position", value: "relative"),
            "display": .style(name: "display", value: "inline-block"),
        ]

        return VNode.element(
            "div",
            props: containerProps,
            children: [triggerButton, dropdown]
        )
    }

    // MARK: - Internal Access

    /// Provides access to the click handler ID for the render coordinator.
    ///
    /// The rendering system needs this to set up the event handler that
    /// toggles the menu dropdown visibility.
    @MainActor public var content_: Content {
        content
    }

    /// Provides access to the label for the render coordinator.
    @MainActor public var label_: Label {
        label
    }

    // MARK: - Menu Item Extraction

    /// Extracts menu items from the content view hierarchy.
    ///
    /// This method traverses the view content to find Button and nested Menu views
    /// and renders them as menu items.
    ///
    /// - Parameter content: The content view to traverse.
    /// - Returns: An array of VNodes representing menu items.
    @MainActor private func extractMenuItems(from content: Content) -> [VNode] {
        // For the initial implementation, return an empty array
        // Full implementation would recursively traverse the view hierarchy
        // and extract Button views as menu items

        // This is a simplified implementation that creates placeholder menu items
        // A complete implementation would need to:
        // 1. Recursively traverse TupleView, ConditionalContent, etc.
        // 2. Extract Button views and render them as menu items
        // 3. Handle nested Menu views as submenus

        return []
    }
}

// MARK: - Convenience Initializers

extension Menu where Label == Text {
    /// Creates a menu with a text label.
    ///
    /// This is a convenience initializer for creating simple text-based menu labels.
    ///
    /// - Parameters:
    ///   - title: The string to display as the menu's label.
    ///   - content: A view builder that creates the menu items.
    ///
    /// Example:
    /// ```swift
    /// Menu("Actions") {
    ///     Button("Copy") { copy() }
    ///     Button("Paste") { paste() }
    /// }
    /// ```
    @MainActor public init(
        _ title: String,
        @ViewBuilder content: () -> Content
    ) {
        self.label = Text(title)
        self.content = content()
    }

    /// Creates a menu with a localized text label.
    ///
    /// - Parameters:
    ///   - titleKey: The localized string key for the menu's label.
    ///   - content: A view builder that creates the menu items.
    @MainActor public init(
        _ titleKey: LocalizedStringKey,
        @ViewBuilder content: () -> Content
    ) {
        self.label = Text(titleKey)
        self.content = content()
    }
}

// Note: Menu item extraction uses the existing protocols defined in Picker.swift
// for TupleViewProtocol, ConditionalContentProtocol, OptionalContentProtocol, and ForEachViewProtocol

// MARK: - Coordinator Renderable

extension Menu: _CoordinatorRenderable {
    @MainActor public func _render(with context: any _RenderContext) -> VNode {
        let menuID = UUID().uuidString
        let dropdownID = "menu-dropdown-\(menuID)"

        // Register click handler that toggles dropdown via JS attribute
        let clickHandlerID = context.registerClickHandler {
            // Toggle dropdown display using JavaScript
            let document = JSObject.global.document
            if let dropdown = document.getElementById(dropdownID).object {
                let currentDisplay = dropdown.style.display.string ?? "none"
                if currentDisplay == "none" {
                    _ = dropdown.style.setProperty("display", "block")
                } else {
                    _ = dropdown.style.setProperty("display", "none")
                }
            }
        }

        // Render label
        let labelNode = context.renderChild(label)

        // Trigger button
        let triggerProps: [String: VProperty] = [
            "class": .attribute(name: "class", value: "raven-menu-trigger"),
            "aria-haspopup": .attribute(name: "aria-haspopup", value: "true"),
            "aria-expanded": .attribute(name: "aria-expanded", value: "false"),
            "aria-controls": .attribute(name: "aria-controls", value: dropdownID),
            "onClick": .eventHandler(event: "click", handlerID: clickHandlerID),
            "cursor": .style(name: "cursor", value: "pointer"),
            "padding": .style(name: "padding", value: "8px 12px"),
            "border": .style(name: "border", value: "1px solid var(--system-control-border)"),
            "border-radius": .style(name: "border-radius", value: "4px"),
            "background-color": .style(name: "background-color", value: "var(--system-control-background)"),
            "font-size": .style(name: "font-size", value: "14px"),
            "display": .style(name: "display", value: "inline-flex"),
            "align-items": .style(name: "align-items", value: "center"),
            "gap": .style(name: "gap", value: "4px"),
        ]

        // Add dropdown arrow
        let arrowNode = VNode.text(" \u{25BC}")
        let triggerButton = VNode.element("button", props: triggerProps, children: [labelNode, arrowNode])

        // Render dropdown content
        let contentNode = context.renderChild(content)
        var dropdownChildren: [VNode] = []
        if case .fragment = contentNode.type {
            dropdownChildren = contentNode.children
        } else {
            dropdownChildren = [contentNode]
        }

        let dropdownProps: [String: VProperty] = [
            "id": .attribute(name: "id", value: dropdownID),
            "class": .attribute(name: "class", value: "raven-menu-dropdown"),
            "role": .attribute(name: "role", value: "menu"),
            "display": .style(name: "display", value: "none"),
            "position": .style(name: "position", value: "absolute"),
            "top": .style(name: "top", value: "100%"),
            "left": .style(name: "left", value: "0"),
            "margin-top": .style(name: "margin-top", value: "4px"),
            "background-color": .style(name: "background-color", value: "var(--system-control-background)"),
            "border": .style(name: "border", value: "1px solid var(--system-control-border)"),
            "border-radius": .style(name: "border-radius", value: "4px"),
            "box-shadow": .style(name: "box-shadow", value: "0 2px 8px rgba(0,0,0,0.15)"),
            "min-width": .style(name: "min-width", value: "160px"),
            "z-index": .style(name: "z-index", value: "1000"),
            "padding": .style(name: "padding", value: "4px 0"),
        ]
        let dropdown = VNode.element("div", props: dropdownProps, children: dropdownChildren)

        // Container
        let containerProps: [String: VProperty] = [
            "class": .attribute(name: "class", value: "raven-menu"),
            "position": .style(name: "position", value: "relative"),
            "display": .style(name: "display", value: "inline-block"),
        ]

        return VNode.element("div", props: containerProps, children: [triggerButton, dropdown])
    }
}
