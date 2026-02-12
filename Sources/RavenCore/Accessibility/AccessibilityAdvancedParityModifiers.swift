import Foundation

public enum AccessibilityAdjustmentDirection: String, Sendable, Hashable {
    case increment
    case decrement
}

public struct AccessibilityActionCategory: Sendable, Hashable {
    let rawValue: String

    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }

    public static let `default` = AccessibilityActionCategory("default")
}

public struct AccessibilityChildBehavior: Sendable, Hashable {
    let rawValue: String

    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }

    public static let ignore = AccessibilityChildBehavior("ignore")
    public static let combine = AccessibilityChildBehavior("combine")
    public static let contain = AccessibilityChildBehavior("contain")
}

public struct AccessibilityDirectTouchOptions: OptionSet, Sendable {
    public let rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    public static let silentOnTouch = AccessibilityDirectTouchOptions(rawValue: 1 << 0)
}

public enum AccessibilityCustomContentImportance: String, Sendable, Hashable {
    case `default`
    case high
}

public struct AccessibilityTextContentType: Sendable, Hashable {
    let rawValue: String

    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }

    public static let sourceCode = AccessibilityTextContentType("sourceCode")
    public static let narrative = AccessibilityTextContentType("narrative")
}

public struct AccessibilityLabeledPairRole: Sendable, Hashable {
    let rawValue: String

    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }

    public static let content = AccessibilityLabeledPairRole("content")
    public static let label = AccessibilityLabeledPairRole("label")
}

extension View {
    @MainActor public func accessibilityActions(
        _ actions: @escaping @Sendable @MainActor () -> Void
    ) -> some View {
        _ = actions
        return _AccessibilityMetadataView(
            content: self,
            properties: ["data-accessibility-actions": "true"]
        )
    }

    @MainActor public func accessibilityActions(
        category: AccessibilityActionCategory,
        _ actions: @escaping @Sendable @MainActor () -> Void
    ) -> some View {
        _ = actions
        return _AccessibilityMetadataView(
            content: self,
            properties: ["data-accessibility-action-category": category.rawValue]
        )
    }

    @MainActor public func accessibilityActivationPoint(_ point: UnitPoint) -> some View {
        accessibility(activationPoint: point)
    }

    @MainActor public func accessibilityActivationPoint(
        _ point: UnitPoint,
        isEnabled: Bool
    ) -> some View {
        guard isEnabled else { return AnyView(self) }
        return AnyView(accessibilityActivationPoint(point))
    }

    @MainActor public func accessibilityAddTraits(_ traits: AccessibilityTraits) -> some View {
        accessibility(addTraits: traits)
    }

    @MainActor public func accessibilityAdjustableAction(
        _ action: @escaping @Sendable @MainActor (AccessibilityAdjustmentDirection) -> Void
    ) -> some View {
        _ = action
        return _AccessibilityMetadataView(
            content: self,
            properties: ["data-accessibility-adjustable-action": "true"]
        )
    }

    @MainActor public func accessibilityChartDescriptor(
        _ descriptor: @escaping @MainActor () -> Any?
    ) -> some View {
        _ = descriptor
        return _AccessibilityMetadataView(
            content: self,
            properties: ["data-accessibility-chart-descriptor": "true"]
        )
    }

    @MainActor public func accessibilityChildren(
        children behavior: AccessibilityChildBehavior
    ) -> some View {
        _AccessibilityMetadataView(
            content: self,
            properties: ["data-accessibility-children": behavior.rawValue]
        )
    }

    @MainActor public func accessibilityCustomContent(
        _ label: Text,
        _ value: Text,
        importance: AccessibilityCustomContentImportance = .default
    ) -> some View {
        _AccessibilityMetadataView(
            content: self,
            properties: [
                "data-accessibility-custom-content-label": label.textContent,
                "data-accessibility-custom-content-value": value.textContent,
                "data-accessibility-custom-content-importance": importance.rawValue,
            ]
        )
    }

    @MainActor public func accessibilityDefaultFocus(
        _ isFocused: Bool,
        _ namespace: AnyHashable?
    ) -> some View {
        _ = namespace
        return _AccessibilityMetadataView(
            content: self,
            properties: ["data-accessibility-default-focus": isFocused ? "true" : "false"]
        )
    }

    @MainActor public func accessibilityDirectTouch(
        _ isEnabled: Bool,
        options: AccessibilityDirectTouchOptions = []
    ) -> some View {
        _AccessibilityMetadataView(
            content: self,
            properties: [
                "data-accessibility-direct-touch": isEnabled ? "true" : "false",
                "data-accessibility-direct-touch-options": "\(options.rawValue)",
            ]
        )
    }

    @MainActor public func accessibilityElement(
        children behavior: AccessibilityChildBehavior
    ) -> some View {
        accessibilityChildren(children: behavior)
    }

    @MainActor public func accessibilityFocused(_ isFocused: Binding<Bool>) -> some View {
        _ = isFocused
        return _AccessibilityMetadataView(
            content: self,
            properties: ["data-accessibility-focused": "binding"]
        )
    }

    @MainActor public func accessibilityFocused<Value: Hashable & Sendable>(
        _ focusedValue: Binding<Value?>,
        equals value: Value
    ) -> some View {
        _ = focusedValue
        return _AccessibilityMetadataView(
            content: self,
            properties: ["data-accessibility-focused-equals": String(describing: value)]
        )
    }

    @MainActor public func accessibilityIgnoresInvertColors(_ ignores: Bool = true) -> some View {
        _AccessibilityMetadataView(
            content: self,
            properties: ["data-accessibility-ignores-invert-colors": ignores ? "true" : "false"]
        )
    }

    @MainActor public func accessibilityInputLabels(_ labels: [Text]) -> some View {
        accessibility(inputLabels: labels)
    }

    @MainActor public func accessibilityInputLabels(
        _ labels: [Text],
        isEnabled: Bool
    ) -> some View {
        guard isEnabled else { return AnyView(self) }
        return AnyView(accessibilityInputLabels(labels))
    }

    @MainActor public func accessibilityLabeledPair(
        role: AccessibilityLabeledPairRole,
        id: AnyHashable,
        in namespace: AnyHashable
    ) -> some View {
        _ = namespace
        return _AccessibilityMetadataView(
            content: self,
            properties: [
                "data-accessibility-labeled-pair-role": role.rawValue,
                "data-accessibility-labeled-pair-id": String(describing: id),
            ]
        )
    }

    @MainActor public func accessibilityLinkedGroup(
        id: AnyHashable,
        in namespace: AnyHashable
    ) -> some View {
        _ = namespace
        return _AccessibilityMetadataView(
            content: self,
            properties: ["data-accessibility-linked-group-id": String(describing: id)]
        )
    }

    @MainActor public func accessibilityRemoveTraits(_ traits: AccessibilityTraits) -> some View {
        accessibility(removeTraits: traits)
    }

    @MainActor public func accessibilityRepresentation<Representation: View>(
        @ViewBuilder representation: () -> Representation
    ) -> some View {
        _ = representation()
        return _AccessibilityMetadataView(
            content: self,
            properties: ["data-accessibility-representation": "true"]
        )
    }

    @MainActor public func accessibilityRespondsToUserInteraction(_ responds: Bool) -> some View {
        _AccessibilityMetadataView(
            content: self,
            properties: ["data-accessibility-responds-to-user-interaction": responds ? "true" : "false"]
        )
    }

    @MainActor public func accessibilityRespondsToUserInteraction(
        _ responds: Bool,
        isEnabled: Bool
    ) -> some View {
        guard isEnabled else { return AnyView(self) }
        return AnyView(accessibilityRespondsToUserInteraction(responds))
    }

    @MainActor public func accessibilityRotor<Entry: Sendable>(
        _ title: Text,
        entries: [Entry]
    ) -> some View {
        _AccessibilityMetadataView(
            content: self,
            properties: [
                "data-accessibility-rotor-title": title.textContent,
                "data-accessibility-rotor-entry-count": "\(entries.count)",
            ]
        )
    }

    @MainActor public func accessibilityRotor<Entry: Sendable, EntryID: Hashable>(
        _ title: Text,
        entries: [Entry],
        entryID: KeyPath<Entry, EntryID>,
        entryLabel: KeyPath<Entry, Text>
    ) -> some View {
        _ = entryID
        _ = entryLabel
        return accessibilityRotor(title, entries: entries)
    }

    @MainActor public func accessibilityRotor<Entry: Sendable>(
        _ title: Text,
        entries: [Entry],
        entryLabel: KeyPath<Entry, Text>
    ) -> some View {
        _ = entryLabel
        return accessibilityRotor(title, entries: entries)
    }

    @MainActor public func accessibilityRotor(
        _ title: Text,
        textRanges: [Range<String.Index>]
    ) -> some View {
        _AccessibilityMetadataView(
            content: self,
            properties: [
                "data-accessibility-rotor-title": title.textContent,
                "data-accessibility-rotor-text-range-count": "\(textRanges.count)",
            ]
        )
    }

    @MainActor public func accessibilityRotorEntry(
        id: AnyHashable,
        in namespace: AnyHashable
    ) -> some View {
        _ = namespace
        return _AccessibilityMetadataView(
            content: self,
            properties: ["data-accessibility-rotor-entry-id": String(describing: id)]
        )
    }

    @MainActor public func accessibilityScrollAction(
        _ action: @escaping @Sendable @MainActor (AccessibilityAdjustmentDirection) -> Void
    ) -> some View {
        _ = action
        return _AccessibilityMetadataView(
            content: self,
            properties: ["data-accessibility-scroll-action": "true"]
        )
    }

    @MainActor public func accessibilityScrollStatus(
        _ status: Text,
        isEnabled: Bool
    ) -> some View {
        guard isEnabled else { return AnyView(self) }
        return AnyView(
            _AccessibilityMetadataView(
                content: self,
                properties: ["data-accessibility-scroll-status": status.textContent]
            )
        )
    }

    @MainActor public func accessibilityShowsLargeContentViewer() -> some View {
        accessibilityShowsLargeContentViewer(true)
    }

    @MainActor public func accessibilityShowsLargeContentViewer(_ shows: Bool) -> some View {
        _AccessibilityMetadataView(
            content: self,
            properties: ["data-accessibility-large-content-viewer": shows ? "true" : "false"]
        )
    }

    @MainActor public func accessibilitySortPriority(_ priority: Double) -> some View {
        accessibility(sortPriority: priority)
    }

    @MainActor public func accessibilityTextContentType(
        _ contentType: AccessibilityTextContentType
    ) -> some View {
        _AccessibilityMetadataView(
            content: self,
            properties: ["data-accessibility-text-content-type": contentType.rawValue]
        )
    }

    @MainActor public func accessibilityZoomAction(
        _ action: @escaping @Sendable @MainActor (AccessibilityAdjustmentDirection) -> Void
    ) -> some View {
        _ = action
        return _AccessibilityMetadataView(
            content: self,
            properties: ["data-accessibility-zoom-action": "true"]
        )
    }
}
