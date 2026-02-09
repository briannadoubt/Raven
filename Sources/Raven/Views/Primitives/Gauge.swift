import Foundation

/// A view that shows a value within a range.
///
/// `Gauge` mirrors SwiftUI's gauge API and renders a simple HTML `progress` element
/// with optional labels for the current value and bounds. This provides a lightweight
/// visualization that works well in web contexts.
///
/// ## Overview
///
/// Use `Gauge` to present a bounded numeric value. The label describes the metric,
/// while the optional current/min/max labels offer additional context.
///
/// ## Basic Usage
///
/// ```swift
/// Gauge(value: 0.42, in: 0...1) {
///     Text("Completion")
/// }
/// ```
///
/// ## With Labels
///
/// ```swift
/// Gauge(value: 75, in: 0...100) {
///     Text("Upload")
/// } currentValueLabel: {
///     Text("75%")
/// } minimumValueLabel: {
///     Text("0%")
/// } maximumValueLabel: {
///     Text("100%")
/// }
/// ```
public struct Gauge<Value, Label, CurrentValueLabel, MinimumValueLabel, MaximumValueLabel>: View, PrimitiveView, Sendable
where Value: BinaryFloatingPoint & Sendable,
      Label: View,
      CurrentValueLabel: View,
      MinimumValueLabel: View,
      MaximumValueLabel: View {
    public typealias Body = Never

    private let value: Value
    private let bounds: ClosedRange<Value>
    private let label: Label
    private let currentValueLabel: CurrentValueLabel
    private let minimumValueLabel: MinimumValueLabel
    private let maximumValueLabel: MaximumValueLabel
    private let hasLabel: Bool
    private let hasCurrentValueLabel: Bool
    private let hasMinimumValueLabel: Bool
    private let hasMaximumValueLabel: Bool

    // MARK: - Initializers

    /// Creates a gauge with a value, bounds, and custom labels.
    @MainActor public init(
        value: Value,
        in bounds: ClosedRange<Value>,
        @ViewBuilder label: () -> Label,
        @ViewBuilder currentValueLabel: () -> CurrentValueLabel,
        @ViewBuilder minimumValueLabel: () -> MinimumValueLabel,
        @ViewBuilder maximumValueLabel: () -> MaximumValueLabel
    ) {
        self.value = value
        self.bounds = bounds
        self.label = label()
        self.currentValueLabel = currentValueLabel()
        self.minimumValueLabel = minimumValueLabel()
        self.maximumValueLabel = maximumValueLabel()
        self.hasLabel = Label.self != EmptyView.self
        self.hasCurrentValueLabel = CurrentValueLabel.self != EmptyView.self
        self.hasMinimumValueLabel = MinimumValueLabel.self != EmptyView.self
        self.hasMaximumValueLabel = MaximumValueLabel.self != EmptyView.self
    }

    /// Creates a gauge with a value, bounds, and label.
    @MainActor public init(
        value: Value,
        in bounds: ClosedRange<Value>,
        @ViewBuilder label: () -> Label
    ) where CurrentValueLabel == EmptyView, MinimumValueLabel == EmptyView, MaximumValueLabel == EmptyView {
        self.value = value
        self.bounds = bounds
        self.label = label()
        self.currentValueLabel = EmptyView()
        self.minimumValueLabel = EmptyView()
        self.maximumValueLabel = EmptyView()
        self.hasLabel = Label.self != EmptyView.self
        self.hasCurrentValueLabel = false
        self.hasMinimumValueLabel = false
        self.hasMaximumValueLabel = false
    }

    /// Creates a gauge with a value, bounds, label, and current value label.
    @MainActor public init(
        value: Value,
        in bounds: ClosedRange<Value>,
        @ViewBuilder label: () -> Label,
        @ViewBuilder currentValueLabel: () -> CurrentValueLabel
    ) where MinimumValueLabel == EmptyView, MaximumValueLabel == EmptyView {
        self.value = value
        self.bounds = bounds
        self.label = label()
        self.currentValueLabel = currentValueLabel()
        self.minimumValueLabel = EmptyView()
        self.maximumValueLabel = EmptyView()
        self.hasLabel = Label.self != EmptyView.self
        self.hasCurrentValueLabel = CurrentValueLabel.self != EmptyView.self
        self.hasMinimumValueLabel = false
        self.hasMaximumValueLabel = false
    }

    // MARK: - VNode Conversion

    @MainActor public func toVNode() -> VNode {
        let props: [String: VProperty] = [
            "class": .attribute(name: "class", value: "raven-gauge"),
        ]
        return VNode.element("div", props: props, children: [])
    }
}

// MARK: - Convenience Initializers

extension Gauge where Label == Text, CurrentValueLabel == EmptyView, MinimumValueLabel == EmptyView, MaximumValueLabel == EmptyView {
    /// Creates a gauge with a string label.
    @MainActor public init(
        _ title: String,
        value: Value,
        in bounds: ClosedRange<Value>
    ) {
        self.init(value: value, in: bounds) {
            Text(title)
        }
    }

    /// Creates a gauge with a localized string label.
    @MainActor public init(
        _ titleKey: LocalizedStringKey,
        value: Value,
        in bounds: ClosedRange<Value>
    ) {
        self.init(value: value, in: bounds) {
            Text(titleKey)
        }
    }
}

// MARK: - Coordinator Renderable

extension Gauge: _CoordinatorRenderable {
    @MainActor public func _render(with context: any _RenderContext) -> VNode {
        func renderChildren<V: View>(_ view: V) -> [VNode] {
            let node = context.renderChild(view)
            if case .fragment = node.type {
                return node.children
            }
            return [node]
        }

        let lowerBound = Double(bounds.lowerBound)
        let upperBound = Double(bounds.upperBound)
        let range = max(upperBound - lowerBound, 0.000_000_1)
        let clampedValue = min(max(Double(value), lowerBound), upperBound)
        let progressValue = clampedValue - lowerBound

        var children: [VNode] = []

        if hasLabel || hasCurrentValueLabel {
            var labelRowChildren: [VNode] = []
            if hasLabel {
                labelRowChildren.append(contentsOf: renderChildren(label))
            }
            if hasCurrentValueLabel {
                let currentNode = VNode.element(
                    "span",
                    props: [
                        "class": .attribute(name: "class", value: "raven-gauge-current"),
                        "margin-left": .style(name: "margin-left", value: "auto"),
                        "font-size": .style(name: "font-size", value: "0.85rem"),
                        "color": .style(name: "color", value: "var(--system-secondary-label)"),
                    ],
                    children: renderChildren(currentValueLabel)
                )
                labelRowChildren.append(currentNode)
            }

            let labelRow = VNode.element(
                "div",
                props: [
                    "class": .attribute(name: "class", value: "raven-gauge-labels"),
                    "display": .style(name: "display", value: "flex"),
                    "align-items": .style(name: "align-items", value: "center"),
                    "gap": .style(name: "gap", value: "8px"),
                ],
                children: labelRowChildren
            )
            children.append(labelRow)
        }

        let progressNode = VNode.element(
            "progress",
            props: [
                "class": .attribute(name: "class", value: "raven-gauge-progress"),
                "value": .attribute(name: "value", value: String(progressValue)),
                "max": .attribute(name: "max", value: String(range)),
                "width": .style(name: "width", value: "100%"),
                "height": .style(name: "height", value: "10px"),
                "appearance": .style(name: "appearance", value: "none"),
            ],
            children: []
        )
        children.append(progressNode)

        if hasMinimumValueLabel || hasMaximumValueLabel {
            var minMaxChildren: [VNode] = []
            if hasMinimumValueLabel {
                minMaxChildren.append(contentsOf: renderChildren(minimumValueLabel))
            }
            if hasMaximumValueLabel {
                let maxNode = VNode.element(
                    "span",
                    props: [
                        "margin-left": .style(name: "margin-left", value: "auto"),
                        "font-size": .style(name: "font-size", value: "0.75rem"),
                        "color": .style(name: "color", value: "var(--system-secondary-label)"),
                    ],
                    children: renderChildren(maximumValueLabel)
                )
                minMaxChildren.append(maxNode)
            }

            let minMaxRow = VNode.element(
                "div",
                props: [
                    "class": .attribute(name: "class", value: "raven-gauge-bounds"),
                    "display": .style(name: "display", value: "flex"),
                    "align-items": .style(name: "align-items", value: "center"),
                    "gap": .style(name: "gap", value: "8px"),
                    "font-size": .style(name: "font-size", value: "0.75rem"),
                    "color": .style(name: "color", value: "var(--system-secondary-label)"),
                ],
                children: minMaxChildren
            )
            children.append(minMaxRow)
        }

        let containerProps: [String: VProperty] = [
            "class": .attribute(name: "class", value: "raven-gauge"),
            "display": .style(name: "display", value: "flex"),
            "flex-direction": .style(name: "flex-direction", value: "column"),
            "gap": .style(name: "gap", value: "6px"),
        ]

        return VNode.element("div", props: containerProps, children: children)
    }
}
