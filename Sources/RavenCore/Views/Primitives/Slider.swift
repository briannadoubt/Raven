import Foundation
import JavaScriptKit

// Foundation UUID randomness can be unreliable in WASM, so use a counter for list IDs.
@MainActor
private var _sliderTickListIDCounter: UInt64 = 0

@MainActor
private func _nextSliderTickListID() -> String {
    _sliderTickListIDCounter += 1
    return "slider-ticks-\(_sliderTickListIDCounter)"
}

/// A slider tick definition used to render datalist tick marks.
///
/// Add `SliderTick` values inside `Slider`'s `ticks:` builder to expose
/// browser-native tick marks for range inputs.
public struct SliderTick: View, PrimitiveView, Sendable, Hashable {
    public typealias Body = Never

    /// The slider value at which this tick should appear.
    public let value: Double

    /// Optional text label for the tick.
    public let label: String?

    @MainActor public init(_ value: Double, label: String? = nil) {
        self.value = value
        self.label = label
    }

    @MainActor public func toVNode() -> VNode {
        var props: [String: VProperty] = [
            "value": .attribute(name: "value", value: String(value))
        ]
        if let label, !label.isEmpty {
            props["label"] = .attribute(name: "label", value: label)
        }
        let children = label.map { [VNode.text($0)] } ?? []
        return VNode.element("option", props: props, children: children)
    }
}

/// A result builder for declaratively defining slider tick marks.
@resultBuilder
public struct SliderTickBuilder: Sendable {
    @MainActor public static func buildBlock() -> EmptyView {
        EmptyView()
    }

    @MainActor public static func buildBlock<Content: View>(_ content: Content) -> Content {
        content
    }

    @MainActor public static func buildBlock<C0: View, C1: View>(_ c0: C0, _ c1: C1) -> TupleView<C0, C1> {
        TupleView(c0, c1)
    }

    @MainActor public static func buildBlock<C0: View, C1: View, C2: View>(_ c0: C0, _ c1: C1, _ c2: C2) -> TupleView<C0, C1, C2> {
        TupleView(c0, c1, c2)
    }

    @MainActor public static func buildBlock<C0: View, C1: View, C2: View, C3: View>(_ c0: C0, _ c1: C1, _ c2: C2, _ c3: C3) -> TupleView<C0, C1, C2, C3> {
        TupleView(c0, c1, c2, c3)
    }

    @MainActor public static func buildBlock<C0: View, C1: View, C2: View, C3: View, C4: View>(_ c0: C0, _ c1: C1, _ c2: C2, _ c3: C3, _ c4: C4) -> TupleView<C0, C1, C2, C3, C4> {
        TupleView(c0, c1, c2, c3, c4)
    }

    @MainActor public static func buildEither<TrueContent: View, FalseContent: View>(
        first component: TrueContent
    ) -> ConditionalContent<TrueContent, FalseContent> {
        ConditionalContent(trueContent: component)
    }

    @MainActor public static func buildEither<TrueContent: View, FalseContent: View>(
        second component: FalseContent
    ) -> ConditionalContent<TrueContent, FalseContent> {
        ConditionalContent(falseContent: component)
    }

    @MainActor public static func buildExpression<Content: View>(_ expression: Content) -> Content {
        expression
    }

    @MainActor public static func buildIf<Content: View>(_ content: Content?) -> OptionalContent<Content> {
        OptionalContent(content: content)
    }

    @MainActor public static func buildArray<Content: View>(_ components: [Content]) -> ForEachView<Content> {
        ForEachView(views: components)
    }

    @MainActor public static func buildLimitedAvailability<Content: View>(_ component: Content) -> Content {
        component
    }
}

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

    /// Optional browser-native tick marks for the slider.
    private let ticks: [SliderTick]

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
        self.ticks = []
    }

    /// Creates a slider with custom tick marks.
    ///
    /// - Parameters:
    ///   - value: A binding to the slider's current value.
    ///   - bounds: The range of valid values. Defaults to 0...1.
    ///   - step: The increment for discrete values. If `nil`, the slider is continuous.
    ///   - ticks: A `SliderTickBuilder` closure that defines visual tick marks.
    @MainActor public init<Ticks: View>(
        value: Binding<Double>,
        in bounds: ClosedRange<Double> = 0...1,
        step: Double? = nil,
        @SliderTickBuilder ticks: () -> Ticks
    ) {
        self.value = value
        self.bounds = bounds
        self.step = step
        self.ticks = _collectSliderTicks(from: ticks())
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
        let datalistID = ticks.isEmpty ? nil : _nextSliderTickListID()

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
            // Leave room for the thumb so adjacent labels don't visually overlap.
            "margin-bottom": .style(name: "margin-bottom", value: "8px"),
        ]

        if let datalistID {
            props["list"] = .attribute(name: "list", value: datalistID)
        }

        // Add step attribute if specified
        if let step = step {
            props["step"] = .attribute(name: "step", value: String(step))
        }

        let inputNode = VNode.element(
            "input",
            props: props,
            children: []
        )

        guard let datalistID else { return inputNode }

        let datalistNode = VNode.element(
            "datalist",
            props: ["id": .attribute(name: "id", value: datalistID)],
            children: ticks.map { $0.toVNode() }
        )
        return VNode.fragment(children: [inputNode, datalistNode])
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
        let datalistID = ticks.isEmpty ? nil : _nextSliderTickListID()

        var props: [String: VProperty] = [
            "type": .attribute(name: "type", value: "range"),
            "min": .attribute(name: "min", value: String(bounds.lowerBound)),
            "max": .attribute(name: "max", value: String(bounds.upperBound)),
            "value": .attribute(name: "value", value: String(binding.wrappedValue)),
            "aria-label": .attribute(name: "aria-label", value: "Slider"),
            // Use "change" instead of "input" so the binding only updates on mouseup.
            // "input" fires on every drag tick, causing a full DOM rebuild that kills
            // the browser's native drag tracking on the range input.
            "onChange": .eventHandler(event: "change", handlerID: handlerID),
            "width": .style(name: "width", value: "100%"),
            "margin-bottom": .style(name: "margin-bottom", value: "8px"),
        ]
        if let datalistID {
            props["list"] = .attribute(name: "list", value: datalistID)
        }
        if let step = step {
            props["step"] = .attribute(name: "step", value: String(step))
        }
        let inputNode = VNode.element("input", props: props, children: [])
        guard let datalistID else { return inputNode }

        let datalistNode = VNode.element(
            "datalist",
            props: ["id": .attribute(name: "id", value: datalistID)],
            children: ticks.map { $0.toVNode() }
        )
        return VNode.fragment(children: [inputNode, datalistNode])
    }
}

@MainActor
private protocol _SliderTickConditionalContentProtocol {
    func _extractSliderTicks(into ticks: inout [SliderTick])
}

@MainActor
private protocol _SliderTickOptionalContentProtocol {
    func _extractSliderTicks(into ticks: inout [SliderTick])
}

@MainActor
private protocol _SliderTickForEachContentProtocol {
    func _extractSliderTicks(into ticks: inout [SliderTick])
}

extension ConditionalContent: _SliderTickConditionalContentProtocol {
    @MainActor fileprivate func _extractSliderTicks(into ticks: inout [SliderTick]) {
        switch storage {
        case .trueContent(let content):
            _collectSliderTicks(from: content, into: &ticks)
        case .falseContent(let content):
            _collectSliderTicks(from: content, into: &ticks)
        }
    }
}

extension OptionalContent: _SliderTickOptionalContentProtocol {
    @MainActor fileprivate func _extractSliderTicks(into ticks: inout [SliderTick]) {
        if let content {
            _collectSliderTicks(from: content, into: &ticks)
        }
    }
}

extension ForEachView: _SliderTickForEachContentProtocol {
    @MainActor fileprivate func _extractSliderTicks(into ticks: inout [SliderTick]) {
        for view in views {
            _collectSliderTicks(from: view, into: &ticks)
        }
    }
}

extension ForEach: _SliderTickForEachContentProtocol {
    @MainActor fileprivate func _extractSliderTicks(into ticks: inout [SliderTick]) {
        for element in data {
            _collectSliderTicks(from: content(element), into: &ticks)
        }
    }
}

@MainActor
private func _collectSliderTicks(from view: any View) -> [SliderTick] {
    var ticks: [SliderTick] = []
    _collectSliderTicks(from: view, into: &ticks)
    return ticks
}

@MainActor
private func _collectSliderTicks(from view: any View, into ticks: inout [SliderTick]) {
    if let tick = view as? SliderTick {
        ticks.append(tick)
        return
    }
    if let tuple = view as? any _ViewTuple {
        for child in tuple._extractChildren() {
            _collectSliderTicks(from: child, into: &ticks)
        }
        return
    }
    if let conditional = view as? any _SliderTickConditionalContentProtocol {
        conditional._extractSliderTicks(into: &ticks)
        return
    }
    if let optional = view as? any _SliderTickOptionalContentProtocol {
        optional._extractSliderTicks(into: &ticks)
        return
    }
    if let forEachView = view as? any _SliderTickForEachContentProtocol {
        forEachView._extractSliderTicks(into: &ticks)
    }
}
