import Foundation

/// Internal wrapper for accessibility metadata that doesn't map directly to a
/// standard ARIA attribute in Raven yet.
public struct _AccessibilityMetadataView<Content: View>: View, PrimitiveView, Sendable {
    let content: Content
    let properties: [String: String]

    public typealias Body = Never

    @MainActor public func toVNode() -> VNode {
        let props = properties.reduce(into: [String: VProperty]()) { acc, entry in
            let (name, value) = entry
            acc[name] = .attribute(name: name, value: value)
        }
        return VNode.element("div", props: props, children: [])
    }
}

extension _AccessibilityMetadataView: _ModifierRenderable {
    public var _modifiedContent: Content { content }
}

extension View {
    /// Sets an accessibility activation point.
    @MainActor public func accessibility(activationPoint point: UnitPoint) -> some View {
        _AccessibilityMetadataView(
            content: self,
            properties: [
                "data-accessibility-activation-point-x": "\(point.x)",
                "data-accessibility-activation-point-y": "\(point.y)",
            ]
        )
    }

    /// Adds accessibility traits to this view.
    @MainActor public func accessibility(addTraits traits: AccessibilityTraits) -> some View {
        accessibilityTraits(traits)
    }

    /// Sets whether this view is hidden from accessibility.
    @MainActor public func accessibility(hidden isHidden: Bool) -> some View {
        accessibilityHidden(isHidden)
    }

    /// Sets an accessibility hint for this view.
    @MainActor public func accessibility(hint: Text) -> some View {
        accessibilityHint(hint.textContent)
    }

    /// Sets an accessibility identifier for this view.
    @MainActor public func accessibility(identifier: String) -> some View {
        accessibilityIdentifier(identifier)
    }

    /// Sets accessibility input labels for this view.
    @MainActor public func accessibility(inputLabels labels: [Text]) -> some View {
        _AccessibilityMetadataView(
            content: self,
            properties: [
                "data-accessibility-input-labels": labels.map(\.textContent).joined(separator: "|"),
            ]
        )
    }

    /// Sets an accessibility label for this view.
    @MainActor public func accessibility(label: Text) -> some View {
        accessibilityLabel(label.textContent)
    }

    /// Removes accessibility traits from this view.
    @MainActor public func accessibility(removeTraits traits: AccessibilityTraits) -> some View {
        _AccessibilityMetadataView(
            content: self,
            properties: [
                "data-accessibility-remove-traits": "\(traits.rawValue)",
            ]
        )
    }

    /// Sets a stable selection identifier for accessibility.
    @MainActor public func accessibility(selectionIdentifier: AnyHashable) -> some View {
        _AccessibilityMetadataView(
            content: self,
            properties: [
                "data-accessibility-selection-identifier": String(describing: selectionIdentifier),
            ]
        )
    }

    /// Sets accessibility sort priority for sibling navigation order.
    @MainActor public func accessibility(sortPriority priority: Double) -> some View {
        _AccessibilityMetadataView(
            content: self,
            properties: [
                "data-accessibility-sort-priority": "\(priority)",
            ]
        )
    }

    /// Sets an accessibility value for this view.
    @MainActor public func accessibility(value: Text) -> some View {
        accessibilityValue(value.textContent)
    }
}
