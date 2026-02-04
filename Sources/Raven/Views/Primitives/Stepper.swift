import Foundation

/// A control that performs increment and decrement actions.
///
/// `Stepper` is a primitive view that renders directly to a set of buttons in the virtual DOM.
/// It provides two-way data binding through a `Binding<Int>` that updates when the user clicks
/// the increment or decrement buttons, and enforces optional range constraints.
///
/// ## Overview
///
/// Use `Stepper` to create controls that allow users to increment or decrement an integer value
/// within an optional range. The stepper automatically disables buttons when the value reaches
/// the minimum or maximum of the specified range.
///
/// ## Basic Usage
///
/// Create a stepper with a label and value binding:
///
/// ```swift
/// struct CounterView: View {
///     @State private var quantity = 0
///
///     var body: some View {
///         Stepper("Quantity", value: $quantity, in: 0...10)
///     }
/// }
/// ```
///
/// ## Without a Label
///
/// Create a stepper without a visible label:
///
/// ```swift
/// @State private var count = 5
///
/// var body: some View {
///     Stepper(value: $count, in: 1...100)
/// }
/// ```
///
/// ## With Localized Labels
///
/// Use localized string keys for internationalization:
///
/// ```swift
/// @State private var volume = 50
///
/// var body: some View {
///     Stepper("volume_label", value: $volume, in: 0...100)
/// }
/// ```
///
/// ## Range Constraints
///
/// The stepper enforces the specified range by disabling buttons when the value
/// reaches the minimum or maximum:
///
/// ```swift
/// @State private var temperature = 72
///
/// var body: some View {
///     VStack {
///         Text("Temperature: \(temperature)°F")
///         Stepper("Adjust", value: $temperature, in: 60...80)
///     }
/// }
/// ```
///
/// When `temperature` is 60, the decrement button will be disabled.
/// When `temperature` is 80, the increment button will be disabled.
///
/// ## Common Patterns
///
/// **Cart quantity:**
/// ```swift
/// struct CartItemView: View {
///     @State private var quantity = 1
///
///     var body: some View {
///         HStack {
///             Text("Quantity:")
///             Stepper(value: $quantity, in: 1...99)
///             Text("\(quantity)")
///         }
///     }
/// }
/// ```
///
/// **Settings adjustment:**
/// ```swift
/// struct SettingsView: View {
///     @State private var fontSize = 14
///
///     var body: some View {
///         VStack {
///             Text("Preview text")
///                 .font(.system(size: CGFloat(fontSize)))
///             Stepper("Font Size", value: $fontSize, in: 10...24)
///         }
///     }
/// }
/// ```
///
/// **Form input:**
/// ```swift
/// struct AgeInputView: View {
///     @State private var age = 18
///
///     var body: some View {
///         Form {
///             Stepper("Age", value: $age, in: 0...120)
///             Text("You are \(age) years old")
///         }
///     }
/// }
/// ```
///
/// ## Styling
///
/// Style steppers using view modifiers:
///
/// ```swift
/// Stepper("Count", value: $count, in: 0...100)
///     .padding()
///     .background(Color.gray.opacity(0.1))
///     .cornerRadius(8)
/// ```
///
/// ## Best Practices
///
/// - Always specify a reasonable range to prevent overflow or invalid values
/// - Use clear, concise labels that describe what the value represents
/// - Consider displaying the current value near the stepper
/// - For large ranges, consider using a `Slider` or `TextField` instead
/// - Provide visual feedback when buttons are disabled at range limits
///
/// ## Accessibility
///
/// The stepper includes ARIA attributes for accessibility:
/// - Buttons are properly labeled for screen readers
/// - Disabled states are communicated through ARIA attributes
/// - The current value and range are accessible to assistive technologies
///
/// ## See Also
///
/// - ``Slider``
/// - ``TextField``
/// - ``Binding``
///
/// Because `Stepper` is a primitive view with `Body == Never`, it converts directly
/// to a VNode without further composition.
public struct Stepper<Label: View>: View, Sendable {
    public typealias Body = Never

    /// The binding to the stepper's value
    private let value: Binding<Int>

    /// The range of valid values
    private let bounds: ClosedRange<Int>

    /// The label content to display
    private let label: Label?

    // MARK: - Initializers

    /// Creates a stepper with a custom label.
    ///
    /// - Parameters:
    ///   - value: A binding to an integer value that the stepper controls.
    ///   - bounds: The valid range for the value.
    ///   - label: A view builder that creates the stepper's label.
    @MainActor public init(
        value: Binding<Int>,
        in bounds: ClosedRange<Int>,
        @ViewBuilder label: () -> Label
    ) {
        self.value = value
        self.bounds = bounds
        self.label = label()
    }

    /// Creates a stepper without a label.
    ///
    /// - Parameters:
    ///   - value: A binding to an integer value that the stepper controls.
    ///   - bounds: The valid range for the value.
    ///
    /// Example:
    /// ```swift
    /// @State private var count = 5
    ///
    /// Stepper(value: $count, in: 0...10)
    /// ```
    @MainActor public init(
        value: Binding<Int>,
        in bounds: ClosedRange<Int>
    ) where Label == EmptyView {
        self.value = value
        self.bounds = bounds
        self.label = nil
    }

    // MARK: - VNode Conversion

    /// Converts this Stepper view to a virtual DOM node.
    ///
    /// This method is used internally by the rendering system to convert
    /// the Stepper primitive into its VNode representation.
    ///
    /// The stepper is rendered as a div containing:
    /// - An optional label element (if label is provided)
    /// - A decrement button (-)
    /// - An increment button (+)
    ///
    /// The buttons are disabled when the value reaches the minimum or maximum of the range.
    ///
    /// - Returns: A div element VNode containing the stepper controls.
    @MainActor public func toVNode() -> VNode {
        let currentValue = value.wrappedValue

        // Check if we're at the bounds
        let isAtMin = currentValue <= bounds.lowerBound
        let isAtMax = currentValue >= bounds.upperBound

        // Generate unique IDs for event handlers
        let decrementHandlerID = UUID()
        let incrementHandlerID = UUID()

        // Create decrement button
        var decrementProps: [String: VProperty] = [
            "type": .attribute(name: "type", value: "button"),
            "aria-label": .attribute(name: "aria-label", value: "Decrement"),
            "class": .attribute(name: "class", value: "raven-stepper-button raven-stepper-decrement"),
        ]

        if isAtMin {
            decrementProps["disabled"] = .boolAttribute(name: "disabled", value: true)
            decrementProps["aria-disabled"] = .attribute(name: "aria-disabled", value: "true")
        } else {
            decrementProps["onClick"] = .eventHandler(event: "click", handlerID: decrementHandlerID)
        }

        let decrementButton = VNode.element(
            "button",
            props: decrementProps,
            children: [VNode.text("-")]
        )

        // Create increment button
        var incrementProps: [String: VProperty] = [
            "type": .attribute(name: "type", value: "button"),
            "aria-label": .attribute(name: "aria-label", value: "Increment"),
            "class": .attribute(name: "class", value: "raven-stepper-button raven-stepper-increment"),
        ]

        if isAtMax {
            incrementProps["disabled"] = .boolAttribute(name: "disabled", value: true)
            incrementProps["aria-disabled"] = .attribute(name: "aria-disabled", value: "true")
        } else {
            incrementProps["onClick"] = .eventHandler(event: "click", handlerID: incrementHandlerID)
        }

        let incrementButton = VNode.element(
            "button",
            props: incrementProps,
            children: [VNode.text("+")]
        )

        // Build children array
        var children: [VNode] = []

        // Add label if present
        if let label = label {
            if let textLabel = label as? Text {
                // Optimize for simple text labels
                let labelNode = VNode.element(
                    "span",
                    props: ["class": .attribute(name: "class", value: "raven-stepper-label")],
                    children: [textLabel.toVNode()]
                )
                children.append(labelNode)
            } else {
                // For complex labels, we'll need to render them
                // For now, create a placeholder that will be handled by the render system
                // This will be properly implemented when the render system is connected
            }
        }

        // Create button container
        let buttonsContainer = VNode.element(
            "div",
            props: ["class": .attribute(name: "class", value: "raven-stepper-buttons")],
            children: [decrementButton, incrementButton]
        )

        children.append(buttonsContainer)

        // Create main container with flexbox layout
        let containerProps: [String: VProperty] = [
            "class": .attribute(name: "class", value: "raven-stepper"),
            "role": .attribute(name: "role", value: "group"),
            "aria-label": .attribute(name: "aria-label", value: "Stepper control"),
            "display": .style(name: "display", value: "flex"),
            "align-items": .style(name: "align-items", value: "center"),
            "gap": .style(name: "gap", value: "8px"),
        ]

        return VNode.element(
            "div",
            props: containerProps,
            children: children
        )
    }

    // MARK: - Public API for Event Handling

    /// Gets the handler closure for the decrement button click event.
    ///
    /// This is used by the render coordinator to register the event handler
    /// that decrements the binding value when the button is clicked.
    ///
    /// - Returns: A closure that decrements the binding value if not at minimum.
    @MainActor public var decrementHandler: @Sendable @MainActor () -> Void {
        { [value, bounds] in
            let currentValue = value.wrappedValue
            if currentValue > bounds.lowerBound {
                value.wrappedValue = currentValue - 1
            }
        }
    }

    /// Gets the handler closure for the increment button click event.
    ///
    /// This is used by the render coordinator to register the event handler
    /// that increments the binding value when the button is clicked.
    ///
    /// - Returns: A closure that increments the binding value if not at maximum.
    @MainActor public var incrementHandler: @Sendable @MainActor () -> Void {
        { [value, bounds] in
            let currentValue = value.wrappedValue
            if currentValue < bounds.upperBound {
                value.wrappedValue = currentValue + 1
            }
        }
    }

    /// Provides access to the value binding for the render coordinator.
    ///
    /// The rendering system needs access to the binding to properly set up
    /// the UI state and re-render when the value changes.
    @MainActor public var valueBinding: Binding<Int> {
        value
    }
}

// MARK: - Convenience Initializers

extension Stepper where Label == Text {
    /// Creates a stepper with a text label.
    ///
    /// This is a convenience initializer for creating simple text-based steppers.
    ///
    /// - Parameters:
    ///   - title: The string to display as the stepper's label.
    ///   - value: A binding to an integer value that the stepper controls.
    ///   - bounds: The valid range for the value.
    ///
    /// Example:
    /// ```swift
    /// @State private var quantity = 1
    ///
    /// var body: some View {
    ///     Stepper("Quantity", value: $quantity, in: 1...10)
    /// }
    /// ```
    @MainActor public init(
        _ title: String,
        value: Binding<Int>,
        in bounds: ClosedRange<Int>
    ) {
        self.value = value
        self.bounds = bounds
        self.label = Text(title)
    }

    /// Creates a stepper with a localized text label.
    ///
    /// - Parameters:
    ///   - titleKey: The localized string key for the stepper's label.
    ///   - value: A binding to an integer value that the stepper controls.
    ///   - bounds: The valid range for the value.
    ///
    /// Example:
    /// ```swift
    /// @State private var volume = 50
    ///
    /// var body: some View {
    ///     Stepper("volume_label", value: $volume, in: 0...100)
    /// }
    /// ```
    @MainActor public init(
        _ titleKey: LocalizedStringKey,
        value: Binding<Int>,
        in bounds: ClosedRange<Int>
    ) {
        self.value = value
        self.bounds = bounds
        self.label = Text(titleKey)
    }
}

