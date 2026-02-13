import Foundation

public struct SensoryFeedback: Sendable, Hashable {
    let rawValue: String

    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }

    public static let success = SensoryFeedback("success")
    public static let warning = SensoryFeedback("warning")
    public static let error = SensoryFeedback("error")
    public static let selection = SensoryFeedback("selection")
    public static let impact = SensoryFeedback("impact")
}

public struct PresentationAdaptation: Sendable, Hashable {
    let rawValue: String

    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }

    public static let automatic = PresentationAdaptation("automatic")
    public static let none = PresentationAdaptation("none")
    public static let popover = PresentationAdaptation("popover")
    public static let sheet = PresentationAdaptation("sheet")
    public static let fullScreenCover = PresentationAdaptation("fullScreenCover")
}

public struct SymbolEffect: Sendable, Hashable {
    let rawValue: String

    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }

    public static let appear = SymbolEffect("appear")
    public static let disappear = SymbolEffect("disappear")
    public static let bounce = SymbolEffect("bounce")
    public static let pulse = SymbolEffect("pulse")
}

public struct SymbolEffectOptions: OptionSet, Sendable {
    public let rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    public static let repeating = SymbolEffectOptions(rawValue: 1 << 0)
    public static let nonRepeating = SymbolEffectOptions(rawValue: 1 << 1)
}

public struct _ModifierMetadataView<Content: View>: View, PrimitiveView, Sendable {
    let content: Content
    let properties: [String: String]

    public typealias Body = Never

    @MainActor public func toVNode() -> VNode {
        let props = properties.reduce(into: [String: VProperty]()) { acc, entry in
            acc[entry.key] = .attribute(name: entry.key, value: entry.value)
        }
        return VNode.element("div", props: props, children: [])
    }
}

extension _ModifierMetadataView: _ModifierRenderable {
    public var _modifiedContent: Content { content }
}

extension View {
    @MainActor public func sensoryFeedback<Trigger: Equatable & Sendable>(
        _ feedback: SensoryFeedback,
        trigger: Trigger
    ) -> some View {
        _ = trigger
        return _ModifierMetadataView(content: self, properties: ["data-sensory-feedback": feedback.rawValue])
    }

    @MainActor public func sensoryFeedback<Trigger: Equatable & Sendable>(
        _ feedback: SensoryFeedback,
        trigger: Trigger,
        condition: @escaping @Sendable (Trigger, Trigger) -> Bool
    ) -> some View {
        _ = condition
        return sensoryFeedback(feedback, trigger: trigger)
    }

    @MainActor public func sensoryFeedback<Trigger: Equatable & Sendable>(
        trigger: Trigger,
        _ feedback: @escaping @Sendable (Trigger, Trigger) -> SensoryFeedback?
    ) -> some View {
        _ = feedback
        return _ModifierMetadataView(content: self, properties: ["data-sensory-feedback-dynamic": "true"])
    }

    @MainActor public func coordinateSpace(_ space: CoordinateSpace) -> some View {
        switch space {
        case .local:
            return AnyView(_ModifierMetadataView(content: self, properties: ["data-coordinate-space": "local"]))
        case .global:
            return AnyView(_ModifierMetadataView(content: self, properties: ["data-coordinate-space": "global"]))
        case let .named(name):
            return AnyView(_ModifierMetadataView(content: self, properties: ["data-coordinate-space": "named:\(name)"]))
        }
    }

    @MainActor public func coordinateSpace(name: String) -> some View {
        coordinateSpace(.named(name))
    }

    @MainActor public func inspectorColumnWidth(_ width: Double) -> some View {
        _ModifierMetadataView(content: self, properties: ["data-inspector-column-width": "\(width)"])
    }

    @MainActor public func inspectorColumnWidth(
        min: Double,
        ideal: Double,
        max: Double
    ) -> some View {
        _ModifierMetadataView(
            content: self,
            properties: [
                "data-inspector-column-width-min": "\(min)",
                "data-inspector-column-width-ideal": "\(ideal)",
                "data-inspector-column-width-max": "\(max)",
            ]
        )
    }

    @MainActor public func matchedTransitionSource<ID: Hashable>(
        id: ID,
        in namespace: AnyHashable
    ) -> some View {
        _ModifierMetadataView(
            content: self,
            properties: [
                "data-matched-transition-id": String(describing: id),
                "data-matched-transition-namespace": String(describing: namespace),
            ]
        )
    }

    @MainActor public func matchedTransitionSource<ID: Hashable, Configuration>(
        id: ID,
        in namespace: AnyHashable,
        configuration: Configuration
    ) -> some View {
        _ = configuration
        return matchedTransitionSource(id: id, in: namespace)
    }

    @MainActor public func onDrag(
        _ data: @escaping @Sendable @MainActor () -> Any?
    ) -> some View {
        _ = data
        return _ModifierMetadataView(content: self, properties: ["data-on-drag": "true"])
    }

    @MainActor public func onDrag<Preview: View>(
        _ data: @escaping @Sendable @MainActor () -> Any?,
        preview: @escaping @Sendable @MainActor () -> Preview
    ) -> some View {
        _ = data
        _ = preview
        return _ModifierMetadataView(content: self, properties: ["data-on-drag-preview": "true"])
    }

    @MainActor public func onLongPressGesture(
        minimumDuration: Double,
        maximumDistance: Double,
        perform action: @escaping @Sendable @MainActor () -> Void,
        onPressingChanged: @escaping @Sendable @MainActor (Bool) -> Void
    ) -> some View {
        _ = minimumDuration
        _ = maximumDistance
        _ = action
        _ = onPressingChanged
        return _ModifierMetadataView(content: self, properties: ["data-on-long-press": "true"])
    }

    @MainActor public func onLongPressGesture(
        minimumDuration: Double,
        maximumDistance: Double,
        pressing: @escaping @Sendable @MainActor (Bool) -> Void,
        perform action: @escaping @Sendable @MainActor () -> Void
    ) -> some View {
        onLongPressGesture(
            minimumDuration: minimumDuration,
            maximumDistance: maximumDistance,
            perform: action,
            onPressingChanged: pressing
        )
    }

    @MainActor public func presentationCompactAdaptation(
        _ adaptation: PresentationAdaptation
    ) -> some View {
        _ModifierMetadataView(content: self, properties: ["data-presentation-compact-adaptation": adaptation.rawValue])
    }

    @MainActor public func presentationCompactAdaptation(
        horizontal: PresentationAdaptation,
        vertical: PresentationAdaptation
    ) -> some View {
        _ModifierMetadataView(
            content: self,
            properties: [
                "data-presentation-compact-adaptation-horizontal": horizontal.rawValue,
                "data-presentation-compact-adaptation-vertical": vertical.rawValue,
            ]
        )
    }

    @MainActor public func scenePadding(_ length: Double) -> some View {
        padding(length)
    }

    @MainActor public func scenePadding(
        _ length: Double,
        edges: Edge.Set
    ) -> some View {
        let insets = EdgeInsets(
            top: edges.contains(.top) ? length : 0,
            leading: edges.contains(.leading) ? length : 0,
            bottom: edges.contains(.bottom) ? length : 0,
            trailing: edges.contains(.trailing) ? length : 0
        )
        return padding(insets)
    }

    @MainActor public func scrollIndicatorsFlash(onAppear: Bool) -> some View {
        _ModifierMetadataView(content: self, properties: ["data-scroll-indicators-flash-on-appear": onAppear ? "true" : "false"])
    }

    @MainActor public func scrollIndicatorsFlash<Trigger: Equatable & Sendable>(
        trigger: Trigger
    ) -> some View {
        _ModifierMetadataView(content: self, properties: ["data-scroll-indicators-flash-trigger": String(describing: trigger)])
    }

    @MainActor public func symbolEffect(
        _ effect: SymbolEffect,
        options: SymbolEffectOptions = [],
        isActive: Bool
    ) -> some View {
        _ModifierMetadataView(
            content: self,
            properties: [
                "data-symbol-effect": effect.rawValue,
                "data-symbol-effect-options": "\(options.rawValue)",
                "data-symbol-effect-active": isActive ? "true" : "false",
            ]
        )
    }

    @MainActor public func symbolEffect<Value: Equatable & Sendable>(
        _ effect: SymbolEffect,
        options: SymbolEffectOptions = [],
        value: Value
    ) -> some View {
        _ModifierMetadataView(
            content: self,
            properties: [
                "data-symbol-effect": effect.rawValue,
                "data-symbol-effect-options": "\(options.rawValue)",
                "data-symbol-effect-value": String(describing: value),
            ]
        )
    }

    @MainActor public func tabViewBottomAccessory<Content: View>(
        @ViewBuilder content: () -> Content
    ) -> some View {
        _ = content()
        return _ModifierMetadataView(content: self, properties: ["data-tabview-bottom-accessory": "true"])
    }

    @MainActor public func tabViewBottomAccessory<Content: View>(
        isEnabled: Bool,
        @ViewBuilder content: () -> Content
    ) -> some View {
        _ = content()
        return _ModifierMetadataView(content: self, properties: ["data-tabview-bottom-accessory-enabled": isEnabled ? "true" : "false"])
    }

    @MainActor public func userActivity<Element: Sendable>(
        _ activityType: String,
        element: Element,
        _ update: @escaping @Sendable @MainActor (inout Element) -> Void
    ) -> some View {
        _ = update
        return _ModifierMetadataView(
            content: self,
            properties: [
                "data-user-activity-type": activityType,
                "data-user-activity-element": String(describing: element),
            ]
        )
    }

    @MainActor public func userActivity(
        _ activityType: String,
        isActive: Bool,
        _ update: @escaping @Sendable @MainActor () -> Void
    ) -> some View {
        _ = update
        return _ModifierMetadataView(
            content: self,
            properties: [
                "data-user-activity-type": activityType,
                "data-user-activity-active": isActive ? "true" : "false",
            ]
        )
    }
}
