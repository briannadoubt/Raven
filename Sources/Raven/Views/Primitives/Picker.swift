import Foundation
import JavaScriptKit

/// A control that displays a selectable list of mutually exclusive options.
///
/// `Picker` is a primitive view that renders directly to an HTML `select` element.
/// It provides two-way data binding through a `Binding<Selection>` that updates when
/// the user selects an option and reflects external changes to the bound value.
///
/// ## Overview
///
/// Use `Picker` to present a list of options where the user can select one value.
/// The picker works with any `Hashable` selection type and uses the `.tag()` modifier
/// to associate values with individual options.
///
/// ## Basic Usage
///
/// Create a picker with an enumeration:
///
/// ```swift
/// enum Flavor: String, CaseIterable, Hashable {
///     case vanilla = "Vanilla"
///     case chocolate = "Chocolate"
///     case strawberry = "Strawberry"
/// }
///
/// struct FlavorPicker: View {
///     @State private var selectedFlavor = Flavor.vanilla
///
///     var body: some View {
///         Picker("Select Flavor", selection: $selectedFlavor) {
///             Text("Vanilla").tag(Flavor.vanilla)
///             Text("Chocolate").tag(Flavor.chocolate)
///             Text("Strawberry").tag(Flavor.strawberry)
///         }
///     }
/// }
/// ```
///
/// ## String Selection
///
/// Use string values for simple cases:
///
/// ```swift
/// struct ColorPicker: View {
///     @State private var selectedColor = "red"
///
///     var body: some View {
///         Picker("Color", selection: $selectedColor) {
///             Text("Red").tag("red")
///             Text("Green").tag("green")
///             Text("Blue").tag("blue")
///         }
///     }
/// }
/// ```
///
/// ## Integer Selection
///
/// Use integer values for numeric options:
///
/// ```swift
/// struct QuantityPicker: View {
///     @State private var quantity = 1
///
///     var body: some View {
///         Picker("Quantity", selection: $quantity) {
///             ForEach(1...10, id: \.self) { number in
///                 Text("\(number)").tag(number)
///             }
///         }
///     }
/// }
/// ```
///
/// ## Dynamic Options
///
/// Build picker options from arrays:
///
/// ```swift
/// struct CategoryPicker: View {
///     @State private var selectedCategory: Category?
///     let categories: [Category]
///
///     var body: some View {
///         Picker("Category", selection: $selectedCategory) {
///             Text("None").tag(nil as Category?)
///             ForEach(categories) { category in
///                 Text(category.name).tag(category as Category?)
///             }
///         }
///     }
/// }
/// ```
///
/// ## Picker Styles
///
/// Customize the picker appearance using the `.pickerStyle()` modifier:
///
/// ```swift
/// Picker("Options", selection: $selection) {
///     Text("Option 1").tag(1)
///     Text("Option 2").tag(2)
/// }
/// .pickerStyle(.menu)  // Default dropdown style
/// ```
///
/// ## Accessibility
///
/// The picker automatically includes accessibility attributes for screen readers.
/// The label parameter provides context for assistive technologies.
///
/// ## Best Practices
///
/// - Always use `.tag()` on each picker option to associate values
/// - Provide descriptive labels for accessibility
/// - Use enumerations for type-safe selection values
/// - Consider using optional selection types when "no selection" is valid
/// - Keep option lists reasonably sized for better user experience
///
/// ## See Also
///
/// - ``Text``
/// - ``Binding``
/// - ``tag(_:)``
/// - ``pickerStyle(_:)``
///
/// Because `Picker` is a primitive view with `Body == Never`, it converts directly
/// to a VNode without further composition.
public struct Picker<Selection: Hashable, Content: View>: View, PrimitiveView, Sendable where Selection: Sendable {
    public typealias Body = Never

    /// The label for the picker
    private let label: String

    /// Two-way binding to the selected value
    private let selection: Binding<Selection>

    /// The content containing tagged options
    private let content: Content

    /// The picker style from the environment
    @Environment(\.pickerStyle) private var pickerStyle

    // MARK: - Initializers

    /// Creates a picker with a label and selection binding.
    ///
    /// The content closure should contain views with `.tag()` modifiers
    /// to associate selection values with each option.
    ///
    /// - Parameters:
    ///   - label: The label describing the purpose of the picker.
    ///   - selection: A binding to the selected value.
    ///   - content: A view builder that creates the picker options.
    ///
    /// Example:
    /// ```swift
    /// @State private var size = "M"
    ///
    /// Picker("Size", selection: $size) {
    ///     Text("Small").tag("S")
    ///     Text("Medium").tag("M")
    ///     Text("Large").tag("L")
    /// }
    /// ```
    @MainActor public init(
        _ label: String,
        selection: Binding<Selection>,
        @ViewBuilder content: () -> Content
    ) {
        self.label = label
        self.selection = selection
        self.content = content()
    }

    /// Creates a picker with a localized label and selection binding.
    ///
    /// - Parameters:
    ///   - titleKey: The localized string key for the picker's label.
    ///   - selection: A binding to the selected value.
    ///   - content: A view builder that creates the picker options.
    @MainActor public init(
        _ titleKey: LocalizedStringKey,
        selection: Binding<Selection>,
        @ViewBuilder content: () -> Content
    ) {
        self.label = titleKey.stringValue
        self.selection = selection
        self.content = content()
    }

    // MARK: - VNode Conversion

    /// Converts this Picker to a virtual DOM node.
    ///
    /// The Picker is rendered based on the current picker style:
    /// - MenuPickerStyle: `select` element with dropdown options
    /// - InlinePickerStyle: Radio buttons with fieldset layout
    /// - SegmentedPickerStyle: Segmented control with connected buttons
    /// - WheelPickerStyle: Scrollable wheel picker with snap points
    ///
    /// - Returns: A VNode configured according to the current picker style.
    @MainActor public func toVNode() -> VNode {
        // Branch on the picker style type
        switch pickerStyle {
        case is MenuPickerStyle:
            return renderMenuPickerStyle()
        case is InlinePickerStyle:
            return renderInlinePickerStyle()
        case is SegmentedPickerStyle:
            return renderSegmentedPickerStyle()
        case is WheelPickerStyle:
            return renderWheelPickerStyle()
        default:
            // Fallback to menu style for unknown styles
            return renderMenuPickerStyle()
        }
    }

    /// Renders the picker in menu/dropdown style.
    ///
    /// The Picker is rendered as a `select` element with:
    /// - `aria-label` attribute for accessibility
    /// - `change` event handler for two-way data binding
    /// - `option` elements for each tagged item
    ///
    /// When the user selects an option, the change event triggers an update
    /// to the binding, which can cause the view to re-render.
    ///
    /// - Returns: A VNode configured as a select element with event handlers.
    @MainActor private func renderMenuPickerStyle() -> VNode {
        // Generate a unique ID for the change event handler
        let handlerID = UUID()

        // Extract options from the content
        let options = extractOptions(from: content)

        // Create option elements
        let optionNodes: [VNode] = options.map { option in
            let isSelected = option.value == selection.wrappedValue

            var optionProps: [String: VProperty] = [
                "value": .attribute(name: "value", value: option.id)
            ]

            if isSelected {
                optionProps["selected"] = .boolAttribute(name: "selected", value: true)
            }

            // Create text node for option label
            let textNode = VNode.text(option.label)

            return VNode.element(
                "option",
                props: optionProps,
                children: [textNode]
            )
        }

        // Create properties for the select element
        let props: [String: VProperty] = [
            // Accessibility label
            "aria-label": .attribute(name: "aria-label", value: label),

            // Change event handler for two-way data binding
            "onChange": .eventHandler(event: "change", handlerID: handlerID),

            // Default styling
            "padding": .style(name: "padding", value: "8px"),
            "border": .style(name: "border", value: "1px solid var(--system-control-border)"),
            "border-radius": .style(name: "border-radius", value: "4px"),
            "font-size": .style(name: "font-size", value: "14px"),
            "background-color": .style(name: "background-color", value: "var(--system-control-background)"),
            "cursor": .style(name: "cursor", value: "pointer"),
        ]

        return VNode.element(
            "select",
            props: props,
            children: optionNodes
        )
    }

    /// Renders the picker in inline style with radio buttons.
    ///
    /// The Picker is rendered as a `fieldset` element with:
    /// - `legend` element for the label
    /// - Radio buttons wrapped in `label` elements for each option
    /// - `change` event handlers for two-way data binding
    ///
    /// When the user selects a radio button, the change event triggers an update
    /// to the binding, which can cause the view to re-render.
    ///
    /// - Returns: A VNode configured as a fieldset with radio inputs.
    @MainActor private func renderInlinePickerStyle() -> VNode {
        // Generate a unique name for the radio group
        let radioGroupName = "picker-\(UUID().uuidString)"

        // Extract options from the content
        let options = extractOptions(from: content)

        // Create legend element for the label
        let legendNode = VNode.element(
            "legend",
            props: [:],
            children: [VNode.text(label)]
        )

        // Create label+input pairs for each option
        let radioNodes: [VNode] = options.map { option in
            // Generate a unique handler ID for this radio button
            let handlerID = UUID()

            // Check if this option is selected
            let isSelected = option.value == selection.wrappedValue

            // Create input properties
            var inputProps: [String: VProperty] = [
                "type": .attribute(name: "type", value: "radio"),
                "name": .attribute(name: "name", value: radioGroupName),
                "value": .attribute(name: "value", value: option.id),
                "onChange": .eventHandler(event: "change", handlerID: handlerID)
            ]

            if isSelected {
                inputProps["checked"] = .boolAttribute(name: "checked", value: true)
            }

            // Create the input element
            let inputNode = VNode.element(
                "input",
                props: inputProps,
                children: []
            )

            // Create text node for the label
            let textNode = VNode.text(" \(option.label)")

            // Create label element wrapping the input and text
            return VNode.element(
                "label",
                props: [
                    "display": .style(name: "display", value: "block"),
                    "margin-bottom": .style(name: "margin-bottom", value: "8px"),
                    "cursor": .style(name: "cursor", value: "pointer")
                ],
                children: [inputNode, textNode]
            )
        }

        // Combine legend and radio buttons
        let children = [legendNode] + radioNodes

        // Create properties for the fieldset element
        let props: [String: VProperty] = [
            "class": .attribute(name: "class", value: "raven-picker-inline"),
            "border": .style(name: "border", value: "1px solid var(--system-control-border)"),
            "border-radius": .style(name: "border-radius", value: "4px"),
            "padding": .style(name: "padding", value: "12px")
        ]

        return VNode.element(
            "fieldset",
            props: props,
            children: children
        )
    }

    /// Renders the picker in segmented style with connected button group.
    ///
    /// The Picker is rendered as a `div` element with role="radiogroup" containing:
    /// - Button elements for each option with role="radio"
    /// - `aria-checked` attributes to indicate selection state
    /// - `data-value` attributes to store option IDs
    /// - `click` event handlers for two-way data binding
    ///
    /// When the user clicks a button, the click event triggers an update
    /// to the binding, which can cause the view to re-render.
    ///
    /// - Returns: A VNode configured as a segmented button group.
    @MainActor private func renderSegmentedPickerStyle() -> VNode {
        // Extract options from the content
        let options = extractOptions(from: content)

        // Create button elements for each option
        let buttonNodes: [VNode] = options.enumerated().map { index, option in
            // Generate a unique handler ID for this button
            let handlerID = UUID()

            // Check if this option is selected
            let isSelected = option.value == selection.wrappedValue

            // Determine if this is the last button
            let isLastButton = index == options.count - 1

            // Create button properties
            var buttonProps: [String: VProperty] = [
                "role": .attribute(name: "role", value: "radio"),
                "aria-checked": .attribute(name: "aria-checked", value: isSelected ? "true" : "false"),
                "data-value": .attribute(name: "data-value", value: option.id),
                "onClick": .eventHandler(event: "click", handlerID: handlerID),

                // Base button styles
                "padding": .style(name: "padding", value: "8px 16px"),
                "border": .style(name: "border", value: "1px solid var(--system-control-border)"),
                "background-color": .style(name: "background-color", value: isSelected ? "var(--system-accent)" : "var(--system-control-background)"),
                "color": .style(name: "color", value: isSelected ? "white" : "var(--system-label)"),
                "font-size": .style(name: "font-size", value: "14px"),
                "cursor": .style(name: "cursor", value: "pointer"),
                "transition": .style(name: "transition", value: "all 0.2s ease"),
                "outline": .style(name: "outline", value: "none"),
                "user-select": .style(name: "user-select", value: "none"),
                "-webkit-user-select": .style(name: "-webkit-user-select", value: "none")
            ]

            // Remove right border for all buttons except the last one
            if !isLastButton {
                buttonProps["border-right"] = .style(name: "border-right", value: "none")
            }

            // Create text node for button label
            let textNode = VNode.text(option.label)

            return VNode.element(
                "button",
                props: buttonProps,
                children: [textNode]
            )
        }

        // Create properties for the container div
        let props: [String: VProperty] = [
            "class": .attribute(name: "class", value: "raven-picker-segmented"),
            "role": .attribute(name: "role", value: "radiogroup"),
            "aria-label": .attribute(name: "aria-label", value: label),

            // Container styles
            "display": .style(name: "display", value: "inline-flex"),
            "border-radius": .style(name: "border-radius", value: "4px"),
            "overflow": .style(name: "overflow", value: "hidden")
        ]

        return VNode.element(
            "div",
            props: props,
            children: buttonNodes
        )
    }

    /// Renders the picker in wheel style with a scrollable container.
    ///
    /// The Picker is rendered as a scrollable wheel with:
    /// - A container div with class "raven-picker-wheel"
    /// - A scroller div with class "raven-picker-wheel-scroller"
    /// - Option divs for each item with class "raven-picker-wheel-option"
    /// - Selected option marked with "raven-picker-wheel-option-selected"
    /// - Data attributes storing tag values for event handling
    /// - Scroll event handler for detecting selection changes
    ///
    /// The wheel uses CSS scroll-snap to provide a native wheel-picker feel.
    /// When the user scrolls, the scroll event handler updates the selection
    /// based on which option is centered in the viewport.
    ///
    /// - Returns: A VNode configured as a wheel picker with scroll handling.
    @MainActor private func renderWheelPickerStyle() -> VNode {
        // Generate a unique ID for the scroll event handler
        let handlerID = UUID()

        // Extract options from the content
        let options = extractOptions(from: content)

        // Create option divs for each picker option
        let optionNodes: [VNode] = options.map { option in
            let isSelected = option.value == selection.wrappedValue

            // Build classes for the option div
            var classes = "raven-picker-wheel-option"
            if isSelected {
                classes += " raven-picker-wheel-option-selected"
            }

            // Create properties for the option div
            let optionProps: [String: VProperty] = [
                "class": .attribute(name: "class", value: classes),
                // Store the option ID as a data attribute for event handling
                "data-option-id": .attribute(name: "data-option-id", value: option.id),
                // Styling for option
                "padding": .style(name: "padding", value: "12px 16px"),
                "text-align": .style(name: "text-align", value: "center"),
                "font-size": .style(name: "font-size", value: "16px"),
                "cursor": .style(name: "cursor", value: "pointer"),
                "user-select": .style(name: "user-select", value: "none"),
                "scroll-snap-align": .style(name: "scroll-snap-align", value: "center")
            ]

            // Create text node for option label
            let textNode = VNode.text(option.label)

            return VNode.element(
                "div",
                props: optionProps,
                children: [textNode]
            )
        }

        // Create the scroller container
        let scrollerProps: [String: VProperty] = [
            "class": .attribute(name: "class", value: "raven-picker-wheel-scroller"),
            // Scroll event handler for detecting selection changes
            "onScroll": .eventHandler(event: "scroll", handlerID: handlerID),
            // Styling for scroller
            "overflow-y": .style(name: "overflow-y", value: "auto"),
            "scroll-snap-type": .style(name: "scroll-snap-type", value: "y mandatory"),
            "height": .style(name: "height", value: "150px"),
            "-webkit-overflow-scrolling": .style(name: "-webkit-overflow-scrolling", value: "touch")
        ]

        let scrollerNode = VNode.element(
            "div",
            props: scrollerProps,
            children: optionNodes
        )

        // Create properties for the wheel container
        let containerProps: [String: VProperty] = [
            "class": .attribute(name: "class", value: "raven-picker-wheel"),
            "aria-label": .attribute(name: "aria-label", value: label),
            "role": .attribute(name: "role", value: "listbox"),
            // Styling for container
            "border": .style(name: "border", value: "1px solid var(--system-control-border)"),
            "border-radius": .style(name: "border-radius", value: "8px"),
            "background-color": .style(name: "background-color", value: "var(--system-control-background)"),
            "position": .style(name: "position", value: "relative"),
            "overflow": .style(name: "overflow", value: "hidden")
        ]

        return VNode.element(
            "div",
            props: containerProps,
            children: [scrollerNode]
        )
    }

    // MARK: - Internal Access

    /// Provides access to the selection binding for the render coordinator.
    ///
    /// The rendering system needs access to the binding to properly set up
    /// the event handler that updates the bound value when the user selects an option.
    @MainActor public var selectionBinding: Binding<Selection> {
        selection
    }

    /// Gets the options from the content for event handling.
    ///
    /// This is used by the render coordinator to map selected option IDs
    /// back to their associated values when handling change events.
    @MainActor public var options: [PickerOption<Selection>] {
        extractOptions(from: content)
    }

    // MARK: - Option Extraction

    /// Extracts picker options from the content view hierarchy.
    ///
    /// This method traverses the view content to find all views with `.tag()` modifiers
    /// and builds a list of options with their associated values and labels.
    ///
    /// - Parameter content: The content view to traverse.
    /// - Returns: An array of picker options.
    @MainActor private func extractOptions(from content: Content) -> [PickerOption<Selection>] {
        var options: [PickerOption<Selection>] = []
        extractOptionsRecursive(from: content, into: &options)
        return options
    }

    /// Recursively extracts options from a view hierarchy.
    @MainActor private func extractOptionsRecursive(from view: some View, into options: inout [PickerOption<Selection>]) {
        // Check if this view is a tagged view
        if let taggedView = view as? TaggedView<Selection> {
            let option = PickerOption(
                id: nextPickerOptionID(),
                value: taggedView.tagValue,
                label: taggedView.textLabel
            )
            options.append(option)
            return
        }

        // Handle tuple views
        if let tupleView = view as? any TupleViewProtocol {
            tupleView.extractPickerOptions(into: &options)
            return
        }

        // Handle conditional content
        if let conditionalView = view as? any ConditionalContentProtocol {
            conditionalView.extractPickerOptions(into: &options)
            return
        }

        // Handle optional content
        if let optionalView = view as? any OptionalContentProtocol {
            optionalView.extractPickerOptions(into: &options)
            return
        }

        // Handle ForEach views
        if let forEachView = view as? any ForEachViewProtocol {
            forEachView.extractPickerOptions(into: &options)
            return
        }
    }

    /// Extracts a label string from a view.
    @MainActor private func extractLabel(from view: some View) -> String {
        if let text = view as? Text {
            return text.textContent
        }
        // Default to empty string for non-text views
        return ""
    }
}

// MARK: - Coordinator Renderable

extension Picker: _CoordinatorRenderable {
    @MainActor public func _render(with context: any _RenderContext) -> VNode {
        let opts = self.options

        // Register input handler for selection changes
        let handlerID = context.registerInputHandler { event in
            // Get the selected value from the event target
            if let selectedValue = event.target.value.string {
                // Find the option with matching ID and update selection
                if let option = opts.first(where: { $0.id == selectedValue }) {
                    self.selection.wrappedValue = option.value
                }
            }
        }

        // Build option elements
        let optionNodes: [VNode] = opts.map { option in
            let isSelected = option.value == selection.wrappedValue
            var optionProps: [String: VProperty] = [
                "value": .attribute(name: "value", value: option.id),
            ]
            if isSelected {
                optionProps["selected"] = .boolAttribute(name: "selected", value: true)
            }
            return VNode.element("option", props: optionProps, children: [VNode.text(option.label)])
        }

        // Create select element
        let selectProps: [String: VProperty] = [
            "aria-label": .attribute(name: "aria-label", value: label),
            "onChange": .eventHandler(event: "change", handlerID: handlerID),
            "padding": .style(name: "padding", value: "8px"),
            "border": .style(name: "border", value: "1px solid var(--system-control-border)"),
            "border-radius": .style(name: "border-radius", value: "4px"),
            "font-size": .style(name: "font-size", value: "14px"),
            "background-color": .style(name: "background-color", value: "var(--system-control-background)"),
            "cursor": .style(name: "cursor", value: "pointer"),
        ]
        let selectNode = VNode.element("select", props: selectProps, children: optionNodes)

        // Create label + select wrapper
        let labelNode = VNode.element("span", props: [
            "font-size": .style(name: "font-size", value: "14px"),
            "margin-right": .style(name: "margin-right", value: "8px"),
        ], children: [VNode.text(label)])

        let containerProps: [String: VProperty] = [
            "class": .attribute(name: "class", value: "raven-picker"),
            "display": .style(name: "display", value: "flex"),
            "align-items": .style(name: "align-items", value: "center"),
            "gap": .style(name: "gap", value: "8px"),
        ]

        return VNode.element("div", props: containerProps, children: [labelNode, selectNode])
    }
}
