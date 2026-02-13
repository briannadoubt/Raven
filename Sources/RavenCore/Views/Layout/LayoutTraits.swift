import Foundation

// MARK: - ViewDimensions

public struct ViewDimensions: Sendable, Hashable {
    public let width: Double
    public let height: Double

    private let horizontalGuides: [HorizontalAlignment: Double]
    private let verticalGuides: [VerticalAlignment: Double]

    public init(
        width: Double,
        height: Double,
        horizontalGuides: [HorizontalAlignment: Double] = [:],
        verticalGuides: [VerticalAlignment: Double] = [:]
    ) {
        self.width = width
        self.height = height
        self.horizontalGuides = horizontalGuides
        self.verticalGuides = verticalGuides
    }

    public subscript(_ alignment: HorizontalAlignment) -> Double {
        if let override = horizontalGuides[alignment] {
            return override
        }
        switch alignment {
        case .leading:
            return 0
        case .center:
            return width / 2
        case .trailing:
            return width
        }
    }

    public subscript(_ alignment: VerticalAlignment) -> Double {
        if let override = verticalGuides[alignment] {
            return override
        }
        switch alignment {
        case .top:
            return 0
        case .center:
            return height / 2
        case .bottom:
            return height
        case .firstTextBaseline:
            return height
        case .lastTextBaseline:
            return height
        }
    }
}

// MARK: - Trait Registries

typealias _LayoutGuideResolver = @Sendable (ViewDimensions) -> Double

enum _RegisteredAlignmentGuide: Sendable {
    case horizontal(HorizontalAlignment, _LayoutGuideResolver)
    case vertical(VerticalAlignment, _LayoutGuideResolver)
}

struct _RegisteredLayoutValue: @unchecked Sendable {
    let keyID: ObjectIdentifier
    let value: Any
}

@MainActor
enum _LayoutTraitRegistry {
    static var alignmentGuides: [UUID: _RegisteredAlignmentGuide] = [:]
    static var layoutValues: [UUID: _RegisteredLayoutValue] = [:]

    static func registerAlignment(_ id: UUID, guide: _RegisteredAlignmentGuide) {
        alignmentGuides[id] = guide
    }

    static func registerLayoutValue(_ id: UUID, keyID: ObjectIdentifier, value: Any) {
        layoutValues[id] = _RegisteredLayoutValue(keyID: keyID, value: value)
    }
}

@MainActor
private final class _LayoutTraitTokenBox {
    let id = UUID()
}

// MARK: - layoutPriority

public struct _LayoutPriorityView<Content: View>: View, PrimitiveView, Sendable {
    let content: Content
    let priority: Double

    public typealias Body = Never

    @MainActor public func toVNode() -> VNode {
        VNode.element("div", props: [
            "data-raven-layout-priority": .attribute(
                name: "data-raven-layout-priority",
                value: "\(priority)"
            ),
        ])
    }
}

extension _LayoutPriorityView: _ModifierRenderable {
    public var _modifiedContent: Content { content }
}

// MARK: - alignmentGuide

public struct _HorizontalAlignmentGuideView<Content: View>: View, PrimitiveView, Sendable {
    let content: Content
    let alignment: HorizontalAlignment
    let computeValue: _LayoutGuideResolver

    public typealias Body = Never

    @MainActor public func toVNode() -> VNode {
        VNode.element("div")
    }
}

extension _HorizontalAlignmentGuideView: _CoordinatorRenderable {
    @MainActor public func _render(with context: any _RenderContext) -> VNode {
        let token = context.persistentState(create: { _LayoutTraitTokenBox() }).id
        _LayoutTraitRegistry.registerAlignment(token, guide: .horizontal(alignment, computeValue))
        let child = context.renderChild(content)
        return VNode.element("div", props: [
            "data-raven-layout-guide-token": .attribute(
                name: "data-raven-layout-guide-token",
                value: token.uuidString
            ),
        ], children: [child])
    }
}

public struct _VerticalAlignmentGuideView<Content: View>: View, PrimitiveView, Sendable {
    let content: Content
    let alignment: VerticalAlignment
    let computeValue: _LayoutGuideResolver

    public typealias Body = Never

    @MainActor public func toVNode() -> VNode {
        VNode.element("div")
    }
}

extension _VerticalAlignmentGuideView: _CoordinatorRenderable {
    @MainActor public func _render(with context: any _RenderContext) -> VNode {
        let token = context.persistentState(create: { _LayoutTraitTokenBox() }).id
        _LayoutTraitRegistry.registerAlignment(token, guide: .vertical(alignment, computeValue))
        let child = context.renderChild(content)
        return VNode.element("div", props: [
            "data-raven-layout-guide-token": .attribute(
                name: "data-raven-layout-guide-token",
                value: token.uuidString
            ),
        ], children: [child])
    }
}

// MARK: - layoutValue

public struct _LayoutValueView<Content: View>: View, PrimitiveView, Sendable {
    let content: Content
    let keyID: ObjectIdentifier
    let value: Any

    public typealias Body = Never

    @MainActor public func toVNode() -> VNode {
        VNode.element("div")
    }
}

extension _LayoutValueView: _CoordinatorRenderable {
    @MainActor public func _render(with context: any _RenderContext) -> VNode {
        let token = context.persistentState(create: { _LayoutTraitTokenBox() }).id
        _LayoutTraitRegistry.registerLayoutValue(token, keyID: keyID, value: value)
        let child = context.renderChild(content)
        return VNode.element("div", props: [
            "data-raven-layout-value-token": .attribute(
                name: "data-raven-layout-value-token",
                value: token.uuidString
            ),
        ], children: [child])
    }
}

// MARK: - View API

extension View {
    @MainActor public func layoutPriority(_ value: Double) -> _LayoutPriorityView<Self> {
        _LayoutPriorityView(content: self, priority: value)
    }

    @MainActor public func alignmentGuide(
        _ alignment: HorizontalAlignment,
        computeValue: @escaping @Sendable (ViewDimensions) -> Double
    ) -> _HorizontalAlignmentGuideView<Self> {
        _HorizontalAlignmentGuideView(content: self, alignment: alignment, computeValue: computeValue)
    }

    @MainActor public func alignmentGuide(
        _ alignment: VerticalAlignment,
        computeValue: @escaping @Sendable (ViewDimensions) -> Double
    ) -> _VerticalAlignmentGuideView<Self> {
        _VerticalAlignmentGuideView(content: self, alignment: alignment, computeValue: computeValue)
    }

    @MainActor public func layoutValue<Key: LayoutValueKey>(key: Key.Type, value: Key.Value) -> _LayoutValueView<Self> {
        _LayoutValueView(content: self, keyID: ObjectIdentifier(Key.self), value: value)
    }
}
