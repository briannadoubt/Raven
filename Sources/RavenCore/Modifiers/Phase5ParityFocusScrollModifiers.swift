import Foundation

/// A type that stores focused values for a view hierarchy.
public struct FocusedValues: Sendable {
    public init() {}
}

/// A key used to read and write a value in `FocusedValues`.
public protocol FocusedValueKey {
    associatedtype Value: Sendable
}

/// A logical scroll position value used by `scrollPosition` bindings.
public struct ScrollPosition: Sendable, Hashable {
    public var id: String?

    public init(id: String? = nil) {
        self.id = id
    }
}

/// A semantic role that scopes default scroll anchors.
public struct ScrollAnchorRole: Sendable, Hashable {
    let rawValue: String

    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }

    public static let automatic = ScrollAnchorRole("automatic")
    public static let content = ScrollAnchorRole("content")
    public static let alignment = ScrollAnchorRole("alignment")
}

private struct DefaultScrollAnchorEnvironmentKey: EnvironmentKey {
    static let defaultValue: UnitPoint? = nil
}

private struct DefaultScrollAnchorByRoleEnvironmentKey: EnvironmentKey {
    static let defaultValue: [String: UnitPoint] = [:]
}

extension EnvironmentValues {
    var defaultScrollAnchor: UnitPoint? {
        get { self[DefaultScrollAnchorEnvironmentKey.self] }
        set { self[DefaultScrollAnchorEnvironmentKey.self] = newValue }
    }

    var defaultScrollAnchorByRole: [String: UnitPoint] {
        get { self[DefaultScrollAnchorByRoleEnvironmentKey.self] }
        set { self[DefaultScrollAnchorByRoleEnvironmentKey.self] = newValue }
    }
}

/// Wrapper that carries explicit scroll-position metadata.
public struct _ScrollPositionView<Content: View>: View, PrimitiveView, Sendable {
    let content: Content
    let anchor: UnitPoint?
    let idDescription: String?

    public typealias Body = Never

    @MainActor public func toVNode() -> VNode {
        var props: [String: VProperty] = [:]
        if let anchor {
            props["data-scroll-position-anchor-x"] = .attribute(name: "data-scroll-position-anchor-x", value: "\(anchor.x)")
            props["data-scroll-position-anchor-y"] = .attribute(name: "data-scroll-position-anchor-y", value: "\(anchor.y)")
        }
        if let idDescription {
            props["data-scroll-position-id"] = .attribute(name: "data-scroll-position-id", value: idDescription)
        }
        return VNode.element("div", props: props, children: [])
    }
}

extension _ScrollPositionView: _ModifierRenderable {
    public var _modifiedContent: Content { content }
}

extension View {
    /// Binds a focused value into this view hierarchy.
    @MainActor public func focusedValue<Value: Sendable>(
        _ keyPath: WritableKeyPath<FocusedValues, Value?>
    ) -> some View {
        _ = keyPath
        return self
    }

    /// Binds a concrete focused value into this view hierarchy.
    @MainActor public func focusedValue<Value: Sendable>(
        _ keyPath: WritableKeyPath<FocusedValues, Value?>,
        _ value: Value
    ) -> some View {
        _ = keyPath
        _ = value
        return self
    }

    /// Binds a scene-scoped focused value into this view hierarchy.
    @MainActor public func focusedSceneValue<Value: Sendable>(
        _ keyPath: WritableKeyPath<FocusedValues, Value?>
    ) -> some View {
        _ = keyPath
        return self
    }

    /// Binds a concrete scene-scoped focused value into this view hierarchy.
    @MainActor public func focusedSceneValue<Value: Sendable>(
        _ keyPath: WritableKeyPath<FocusedValues, Value?>,
        _ value: Value
    ) -> some View {
        _ = keyPath
        _ = value
        return self
    }

    /// Binds an observable object for focus-driven lookup.
    @MainActor public func focusedObject<ObjectType: AnyObject & Sendable>(_ object: ObjectType?) -> some View {
        _ = object
        return self
    }

    /// Binds a scene-scoped observable object for focus-driven lookup.
    @MainActor public func focusedSceneObject<ObjectType: AnyObject & Sendable>(_ object: ObjectType?) -> some View {
        _ = object
        return self
    }

    /// Binds a full scroll-position model to this view hierarchy.
    @MainActor public func scrollPosition(
        _ position: Binding<ScrollPosition>,
        anchor: UnitPoint? = nil
    ) -> _ScrollPositionView<Self> {
        _ = position
        return _ScrollPositionView(content: self, anchor: anchor, idDescription: nil)
    }

    /// Binds a scroll-position ID to this view hierarchy.
    @MainActor public func scrollPosition<ID: Hashable>(
        id: Binding<ID?>,
        anchor: UnitPoint? = nil
    ) -> _ScrollPositionView<Self> {
        let description = id.wrappedValue.map { String(describing: $0) }
        return _ScrollPositionView(content: self, anchor: anchor, idDescription: description)
    }

    /// Sets the default scroll anchor for descendant scroll views.
    @MainActor public func defaultScrollAnchor(_ anchor: UnitPoint) -> some View {
        environment(\.defaultScrollAnchor, anchor)
    }

    /// Sets the default scroll anchor for a specific semantic role.
    @MainActor public func defaultScrollAnchor(
        _ anchor: UnitPoint,
        for role: ScrollAnchorRole
    ) -> some View {
        environment(\.defaultScrollAnchorByRole, [role.rawValue: anchor])
    }
}
