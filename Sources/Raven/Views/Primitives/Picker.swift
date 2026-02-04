import Foundation

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
public struct Picker<Selection: Hashable, Content: View>: View, Sendable where Selection: Sendable {
    public typealias Body = Never

    /// The label for the picker
    private let label: String

    /// Two-way binding to the selected value
    private let selection: Binding<Selection>

    /// The content containing tagged options
    private let content: Content

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
    /// The Picker is rendered as a `select` element with:
    /// - `aria-label` attribute for accessibility
    /// - `change` event handler for two-way data binding
    /// - `option` elements for each tagged item
    ///
    /// When the user selects an option, the change event triggers an update
    /// to the binding, which can cause the view to re-render.
    ///
    /// - Returns: A VNode configured as a select element with event handlers.
    @MainActor public func toVNode() -> VNode {
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

            // Change event handler for two-way binding
            "onChange": .eventHandler(event: "change", handlerID: handlerID),

            // Default styling
            "padding": .style(name: "padding", value: "8px"),
            "border": .style(name: "border", value: "1px solid #ccc"),
            "border-radius": .style(name: "border-radius", value: "4px"),
            "font-size": .style(name: "font-size", value: "14px"),
            "background-color": .style(name: "background-color", value: "white"),
            "cursor": .style(name: "cursor", value: "pointer"),
        ]

        return VNode.element(
            "select",
            props: props,
            children: optionNodes
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
            let label = extractLabel(from: taggedView.content)
            let option = PickerOption(
                id: UUID().uuidString,
                value: taggedView.tagValue,
                label: label
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

/// Represents a single option in a picker.
public struct PickerOption<Selection: Hashable>: Sendable where Selection: Sendable {
    /// Unique identifier for this option
    public let id: String

    /// The value associated with this option
    public let value: Selection

    /// The label to display for this option
    public let label: String

    public init(id: String, value: Selection, label: String) {
        self.id = id
        self.value = value
        self.label = label
    }
}

// MARK: - Tag Modifier

/// A view that associates a tag value for use in selection controls.
public struct TaggedView<SelectionValue: Hashable>: View, Sendable where SelectionValue: Sendable {
    public typealias Body = Never

    /// The content view being tagged
    let content: AnyView

    /// The tag value associated with this view
    let tagValue: SelectionValue

    @MainActor init<Content: View>(content: Content, tag: SelectionValue) {
        self.content = AnyView(content)
        self.tagValue = tag
    }
}

extension View {
    /// Tags this view with a selection value for use in pickers and other selection controls.
    ///
    /// Use this modifier to associate a value with a view inside a `Picker`.
    /// The picker uses these tags to map between displayed options and selection values.
    ///
    /// Example:
    /// ```swift
    /// Picker("Size", selection: $selectedSize) {
    ///     Text("Small").tag("S")
    ///     Text("Medium").tag("M")
    ///     Text("Large").tag("L")
    /// }
    /// ```
    ///
    /// - Parameter tag: The value to associate with this view.
    /// - Returns: A tagged view that can be used in selection controls.
    @MainActor public func tag<V: Hashable>(_ tag: V) -> TaggedView<V> where V: Sendable {
        TaggedView(content: self, tag: tag)
    }
}

// MARK: - Helper Protocols for Option Extraction

/// Protocol for traversing tuple views during option extraction.
@MainActor
protocol TupleViewProtocol {
    func extractPickerOptions<Selection: Hashable>(into options: inout [PickerOption<Selection>]) where Selection: Sendable
}

/// Protocol for traversing conditional content during option extraction.
@MainActor
protocol ConditionalContentProtocol {
    func extractPickerOptions<Selection: Hashable>(into options: inout [PickerOption<Selection>]) where Selection: Sendable
}

/// Protocol for traversing optional content during option extraction.
@MainActor
protocol OptionalContentProtocol {
    func extractPickerOptions<Selection: Hashable>(into options: inout [PickerOption<Selection>]) where Selection: Sendable
}

/// Protocol for traversing ForEach views during option extraction.
@MainActor
protocol ForEachViewProtocol {
    func extractPickerOptions<Selection: Hashable>(into options: inout [PickerOption<Selection>]) where Selection: Sendable
}

// MARK: - TupleView Conformance

extension TupleView: TupleViewProtocol {
    @MainActor func extractPickerOptions<Selection: Hashable>(into options: inout [PickerOption<Selection>]) where Selection: Sendable {
        // Use Mirror to traverse tuple elements
        let mirror = Mirror(reflecting: content)
        for child in mirror.children {
            if let view = child.value as? any View {
                extractFromView(view, into: &options)
            }
        }
    }

    @MainActor private func extractFromView<Selection: Hashable>(_ view: any View, into options: inout [PickerOption<Selection>]) where Selection: Sendable {
        if let taggedView = view as? TaggedView<Selection> {
            let label = extractLabel(from: taggedView.content)
            let option = PickerOption(
                id: UUID().uuidString,
                value: taggedView.tagValue,
                label: label
            )
            options.append(option)
        } else if let tupleView = view as? any TupleViewProtocol {
            tupleView.extractPickerOptions(into: &options)
        } else if let conditionalView = view as? any ConditionalContentProtocol {
            conditionalView.extractPickerOptions(into: &options)
        } else if let optionalView = view as? any OptionalContentProtocol {
            optionalView.extractPickerOptions(into: &options)
        } else if let forEachView = view as? any ForEachViewProtocol {
            forEachView.extractPickerOptions(into: &options)
        }
    }

    @MainActor private func extractLabel(from view: any View) -> String {
        if let text = view as? Text {
            return text.textContent
        }
        return ""
    }
}

// MARK: - ConditionalContent Conformance

extension ConditionalContent: ConditionalContentProtocol {
    @MainActor func extractPickerOptions<Selection: Hashable>(into options: inout [PickerOption<Selection>]) where Selection: Sendable {
        switch storage {
        case .trueContent(let content):
            extractFromView(content, into: &options)
        case .falseContent(let content):
            extractFromView(content, into: &options)
        }
    }

    @MainActor private func extractFromView<Selection: Hashable>(_ view: any View, into options: inout [PickerOption<Selection>]) where Selection: Sendable {
        if let taggedView = view as? TaggedView<Selection> {
            let label = extractLabel(from: taggedView.content)
            let option = PickerOption(
                id: UUID().uuidString,
                value: taggedView.tagValue,
                label: label
            )
            options.append(option)
        } else if let tupleView = view as? any TupleViewProtocol {
            tupleView.extractPickerOptions(into: &options)
        } else if let conditionalView = view as? any ConditionalContentProtocol {
            conditionalView.extractPickerOptions(into: &options)
        } else if let optionalView = view as? any OptionalContentProtocol {
            optionalView.extractPickerOptions(into: &options)
        } else if let forEachView = view as? any ForEachViewProtocol {
            forEachView.extractPickerOptions(into: &options)
        }
    }

    @MainActor private func extractLabel(from view: any View) -> String {
        if let text = view as? Text {
            return text.textContent
        }
        return ""
    }
}

// MARK: - OptionalContent Conformance

extension OptionalContent: OptionalContentProtocol {
    @MainActor func extractPickerOptions<Selection: Hashable>(into options: inout [PickerOption<Selection>]) where Selection: Sendable {
        if let content = content {
            extractFromView(content, into: &options)
        }
    }

    @MainActor private func extractFromView<Selection: Hashable>(_ view: any View, into options: inout [PickerOption<Selection>]) where Selection: Sendable {
        if let taggedView = view as? TaggedView<Selection> {
            let label = extractLabel(from: taggedView.content)
            let option = PickerOption(
                id: UUID().uuidString,
                value: taggedView.tagValue,
                label: label
            )
            options.append(option)
        } else if let tupleView = view as? any TupleViewProtocol {
            tupleView.extractPickerOptions(into: &options)
        } else if let conditionalView = view as? any ConditionalContentProtocol {
            conditionalView.extractPickerOptions(into: &options)
        } else if let optionalView = view as? any OptionalContentProtocol {
            optionalView.extractPickerOptions(into: &options)
        } else if let forEachView = view as? any ForEachViewProtocol {
            forEachView.extractPickerOptions(into: &options)
        }
    }

    @MainActor private func extractLabel(from view: any View) -> String {
        if let text = view as? Text {
            return text.textContent
        }
        return ""
    }
}

// MARK: - ForEachView Conformance

extension ForEachView: ForEachViewProtocol {
    @MainActor func extractPickerOptions<Selection: Hashable>(into options: inout [PickerOption<Selection>]) where Selection: Sendable {
        for view in views {
            extractFromView(view, into: &options)
        }
    }

    @MainActor private func extractFromView<Selection: Hashable>(_ view: any View, into options: inout [PickerOption<Selection>]) where Selection: Sendable {
        if let taggedView = view as? TaggedView<Selection> {
            let label = extractLabel(from: taggedView.content)
            let option = PickerOption(
                id: UUID().uuidString,
                value: taggedView.tagValue,
                label: label
            )
            options.append(option)
        } else if let tupleView = view as? any TupleViewProtocol {
            tupleView.extractPickerOptions(into: &options)
        } else if let conditionalView = view as? any ConditionalContentProtocol {
            conditionalView.extractPickerOptions(into: &options)
        } else if let optionalView = view as? any OptionalContentProtocol {
            optionalView.extractPickerOptions(into: &options)
        } else if let forEachView = view as? any ForEachViewProtocol {
            forEachView.extractPickerOptions(into: &options)
        }
    }

    @MainActor private func extractLabel(from view: any View) -> String {
        if let text = view as? Text {
            return text.textContent
        }
        return ""
    }
}
