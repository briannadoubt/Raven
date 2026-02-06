import Foundation
import JavaScriptKit

/// A control for selecting a value from a bounded linear range.
///
/// `Slider` is a primitive view that renders directly to an HTML `input` element
/// with `type="range"`. It provides two-way data binding through a `Binding<Double>`,
/// allowing users to adjust numeric values by dragging a slider handle.
///
/// ## Overview
///
/// Use `Slider` to present a continuous range of values and let users select
/// a specific value by moving the slider thumb. The slider automatically updates
/// the binding when the user interacts with it, enabling reactive UI updates.
///
/// ## Basic Usage
///
/// Create a slider with default bounds (0...1):
///
/// ```swift
/// struct VolumeControl: View {
///     @State private var volume = 0.5
///
///     var body: some View {
///         VStack {
///             Text("Volume: \(Int(volume * 100))%")
///             Slider(value: $volume)
///         }
///     }
/// }
/// ```
///
/// ## Custom Range
///
/// Specify custom minimum and maximum values:
///
/// ```swift
/// @State private var temperature = 20.0
///
/// var body: some View {
///     VStack {
///         Text("Temperature: \(Int(temperature))°C")
///         Slider(value: $temperature, in: 0...100)
///     }
/// }
/// ```
///
/// ## Step Increments
///
/// Use the `step` parameter to constrain the slider to specific increments:
///
/// ```swift
/// @State private var rating = 3.0
///
/// var body: some View {
///     VStack {
///         Text("Rating: \(Int(rating)) stars")
///         Slider(value: $rating, in: 1...5, step: 1)
///     }
/// }
/// ```
///
/// ## Common Patterns
///
/// **Volume control:**
/// ```swift
/// @State private var volume = 0.7
///
/// Slider(value: $volume, in: 0...1, step: 0.01)
///     .onChange(of: volume) { newValue in
///         audioPlayer.setVolume(newValue)
///     }
/// ```
///
/// **Age selector:**
/// ```swift
/// @State private var age = 25.0
///
/// VStack {
///     Text("Age: \(Int(age))")
///     Slider(value: $age, in: 0...120, step: 1)
/// }
/// ```
///
/// **Percentage selector:**
/// ```swift
/// @State private var percentage = 50.0
///
/// VStack {
///     Text("\(Int(percentage))%")
///     Slider(value: $percentage, in: 0...100, step: 5)
/// }
/// ```
///
/// ## Best Practices
///
/// - Use appropriate ranges that match the domain of your data
/// - Provide visual feedback showing the current value
/// - Use step increments when discrete values are needed
/// - Consider accessibility by ensuring adequate contrast and size
/// - Combine with labels or text to display the current value
///
/// ## See Also
///
/// - ``Stepper``
/// - ``TextField``
///
/// Because `Slider` is a primitive view with `Body == Never`, it converts directly
/// to a VNode without further composition.
public struct Slider: View, PrimitiveView, Sendable {
    public typealias Body = Never

    /// The binding to the slider's current value
    private let value: Binding<Double>

    /// The range of valid values for the slider
    private let bounds: ClosedRange<Double>

    /// Optional step increment for discrete values
    private let step: Double?

    // MARK: - Initializers

    /// Creates a slider with a value binding and optional bounds and step.
    ///
    /// - Parameters:
    ///   - value: A binding to the slider's current value.
    ///   - bounds: The range of valid values. Defaults to 0...1.
    ///   - step: The increment for discrete values. If `nil`, the slider is continuous.
    ///
    /// Example:
    /// ```swift
    /// @State private var volume = 0.5
    ///
    /// Slider(value: $volume, in: 0...1, step: 0.1)
    /// ```
    @MainActor public init(
        value: Binding<Double>,
        in bounds: ClosedRange<Double> = 0...1,
        step: Double? = nil
    ) {
        self.value = value
        self.bounds = bounds
        self.step = step
    }

    // MARK: - VNode Conversion

    /// Converts this Slider to a virtual DOM node.
    ///
    /// The Slider is rendered as an `input` element with:
    /// - `type="range"` attribute
    /// - `min` attribute for the lower bound
    /// - `max` attribute for the upper bound
    /// - `step` attribute if specified (for discrete increments)
    /// - `value` attribute bound to the current slider value
    /// - `input` event handler for two-way data binding
    ///
    /// When the user moves the slider, the input event triggers an update to the
    /// binding, which causes the view to re-render and reflect the new value.
    ///
    /// - Returns: A VNode configured as a range input element with event handlers.
    @MainActor public func toVNode() -> VNode {
        // Generate a unique ID for the input event handler
        let handlerID = UUID()

        // Create properties for the input element
        var props: [String: VProperty] = [
            // Input type
            "type": .attribute(name: "type", value: "range"),

            // Minimum value
            "min": .attribute(name: "min", value: String(bounds.lowerBound)),

            // Maximum value
            "max": .attribute(name: "max", value: String(bounds.upperBound)),

            // Current value (reflects the binding)
            "value": .attribute(name: "value", value: String(value.wrappedValue)),

            // Input event handler for two-way binding
            "onInput": .eventHandler(event: "input", handlerID: handlerID),

            // Default styling for better appearance
            "width": .style(name: "width", value: "100%"),
        ]

        // Add step attribute if specified
        if let step = step {
            props["step"] = .attribute(name: "step", value: String(step))
        }

        return VNode.element(
            "input",
            props: props,
            children: []
        )
    }

    // MARK: - Internal Access

    /// Provides access to the value binding for the render coordinator.
    ///
    /// The rendering system needs access to the binding to properly set up
    /// the event handler that updates the bound value when the user moves
    /// the slider. The event handler will parse the string value from the
    /// input element and convert it to a Double.
    @MainActor public var valueBinding: Binding<Double> {
        value
    }
}

// MARK: - Coordinator Renderable

extension Slider: _CoordinatorRenderable {
    @MainActor public func _render(with context: any _RenderContext) -> VNode {
        let binding = value
        let handlerID = context.registerInputHandler { event in
            if let str = event.target.value.string, let val = Double(str) {
                binding.wrappedValue = val
            }
        }

        var props: [String: VProperty] = [
            "type": .attribute(name: "type", value: "range"),
            "min": .attribute(name: "min", value: String(bounds.lowerBound)),
            "max": .attribute(name: "max", value: String(bounds.upperBound)),
            "value": .attribute(name: "value", value: String(binding.wrappedValue)),
            "onInput": .eventHandler(event: "input", handlerID: handlerID),
            "width": .style(name: "width", value: "100%"),
        ]
        if let step = step {
            props["step"] = .attribute(name: "step", value: String(step))
        }
        return VNode.element("input", props: props, children: [])
    }
}
