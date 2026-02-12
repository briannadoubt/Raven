import Foundation

/// A hover effect style applied to interactive views.
public struct HoverEffect: Sendable, Hashable {
    let rawValue: String

    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }

    public static let automatic = HoverEffect("automatic")
    public static let highlight = HoverEffect("highlight")
    public static let lift = HoverEffect("lift")
}

/// Controls visual prominence for badges in supporting contexts.
public struct BadgeProminence: Sendable, Hashable {
    let rawValue: String

    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }

    public static let standard = BadgeProminence("standard")
    public static let increased = BadgeProminence("increased")
}

/// Controls whether a button should repeat while pressed.
public struct ButtonRepeatBehavior: Sendable, Hashable {
    let rawValue: String

    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }

    public static let automatic = ButtonRepeatBehavior("automatic")
    public static let enabled = ButtonRepeatBehavior("enabled")
    public static let disabled = ButtonRepeatBehavior("disabled")
}

private struct DefaultHoverEffectEnvironmentKey: EnvironmentKey {
    static let defaultValue: HoverEffect? = nil
}

private struct HoverEffectDisabledEnvironmentKey: EnvironmentKey {
    static let defaultValue = false
}

private struct BadgeProminenceEnvironmentKey: EnvironmentKey {
    static let defaultValue: BadgeProminence? = nil
}

private struct ButtonRepeatBehaviorEnvironmentKey: EnvironmentKey {
    static let defaultValue: ButtonRepeatBehavior? = nil
}

extension EnvironmentValues {
    var defaultHoverEffect: HoverEffect? {
        get { self[DefaultHoverEffectEnvironmentKey.self] }
        set { self[DefaultHoverEffectEnvironmentKey.self] = newValue }
    }

    var hoverEffectDisabled: Bool {
        get { self[HoverEffectDisabledEnvironmentKey.self] }
        set { self[HoverEffectDisabledEnvironmentKey.self] = newValue }
    }

    var badgeProminence: BadgeProminence? {
        get { self[BadgeProminenceEnvironmentKey.self] }
        set { self[BadgeProminenceEnvironmentKey.self] = newValue }
    }

    var buttonRepeatBehavior: ButtonRepeatBehavior? {
        get { self[ButtonRepeatBehaviorEnvironmentKey.self] }
        set { self[ButtonRepeatBehaviorEnvironmentKey.self] = newValue }
    }
}

/// Wrapper modifier that attaches hover-effect metadata.
public struct _HoverEffectView<Content: View>: View, PrimitiveView, Sendable {
    let content: Content
    let effect: HoverEffect
    let isEnabled: Bool

    @Environment(\.defaultHoverEffect) private var defaultHoverEffect
    @Environment(\.hoverEffectDisabled) private var hoverEffectDisabled

    public typealias Body = Never

    @MainActor public func toVNode() -> VNode {
        let resolvedEffect = defaultHoverEffect ?? effect
        let enabled = isEnabled && !hoverEffectDisabled
        var props: [String: VProperty] = [:]
        if enabled {
            props["data-hover-effect"] = .attribute(name: "data-hover-effect", value: resolvedEffect.rawValue)
            props["transition"] = .style(name: "transition", value: "transform 0.15s ease, filter 0.15s ease")
        }
        return VNode.element("div", props: props, children: [])
    }
}

extension _HoverEffectView: _ModifierRenderable {
    public var _modifiedContent: Content { content }
}

/// Wrapper modifier that attaches tooltip/help metadata.
public struct _HelpView<Content: View>: View, PrimitiveView, Sendable {
    let content: Content
    let helpText: String

    public typealias Body = Never

    @MainActor public func toVNode() -> VNode {
        let props: [String: VProperty] = [
            "title": .attribute(name: "title", value: helpText),
            "aria-description": .attribute(name: "aria-description", value: helpText),
        ]
        return VNode.element("div", props: props, children: [])
    }
}

extension _HelpView: _ModifierRenderable {
    public var _modifiedContent: Content { content }
}

extension View {
    /// Adds descriptive help text shown by assistive technologies and browser tooltips.
    @MainActor public func help(_ text: String) -> _HelpView<Self> {
        _HelpView(content: self, helpText: text)
    }

    /// Adds descriptive help text from a `Text` value.
    @MainActor public func help(_ text: Text) -> _HelpView<Self> {
        _HelpView(content: self, helpText: text.textContent)
    }

    /// Applies a hover effect style.
    @MainActor public func hoverEffect(_ effect: HoverEffect = .automatic) -> _HoverEffectView<Self> {
        _HoverEffectView(content: self, effect: effect, isEnabled: true)
    }

    /// Applies a hover effect style with explicit enablement.
    @MainActor public func hoverEffect(
        _ effect: HoverEffect = .automatic,
        isEnabled: Bool
    ) -> _HoverEffectView<Self> {
        _HoverEffectView(content: self, effect: effect, isEnabled: isEnabled)
    }

    /// Sets the default hover effect for descendant views.
    @MainActor public func defaultHoverEffect(_ effect: HoverEffect?) -> some View {
        environment(\.defaultHoverEffect, effect)
    }

    /// Disables hover effects for descendant views.
    @MainActor public func hoverEffectDisabled(_ disabled: Bool = true) -> some View {
        environment(\.hoverEffectDisabled, disabled)
    }

    /// Sets badge prominence for supported controls.
    @MainActor public func badgeProminence(_ prominence: BadgeProminence) -> some View {
        environment(\.badgeProminence, prominence)
    }

    /// Controls repeat behavior for supported buttons.
    @MainActor public func buttonRepeatBehavior(_ behavior: ButtonRepeatBehavior) -> some View {
        environment(\.buttonRepeatBehavior, behavior)
    }
}
