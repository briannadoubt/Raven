import Foundation
import JavaScriptKit

@MainActor
private func _ravenNextRuntimeID(prefix: String) -> String {
    #if arch(wasm32)
    let global = JSObject.global
    let next = (global.__RAVEN_RUNTIME_ID_COUNTER.number ?? 0) + 1
    global.__RAVEN_RUNTIME_ID_COUNTER = .number(next)
    return "\(prefix)-\(Int(next))"
    #else
    return "\(prefix)-\(UUID().uuidString)"
    #endif
}

// MARK: - Layout Defaults

public enum LayoutDefaults {
    public static let defaultStackSpacing: Double = 8
}

// MARK: - ProposedViewSize

public struct ProposedViewSize: Sendable, Hashable {
    public var width: Double?
    public var height: Double?

    public init(width: Double?, height: Double?) {
        self.width = width
        self.height = height
    }

    public init(_ size: CGSize) {
        self.width = size.width
        self.height = size.height
    }

    public static let unspecified = ProposedViewSize(width: nil, height: nil)
    public static let zero = ProposedViewSize(width: 0, height: 0)
    public static let infinity = ProposedViewSize(width: .infinity, height: .infinity)

    public func replacingUnspecifiedDimensions(by size: CGSize = .zero) -> CGSize {
        CGSize(width: width ?? size.width, height: height ?? size.height)
    }
}

// MARK: - Layout Value Keys

public protocol LayoutValueKey {
    associatedtype Value
    static var defaultValue: Value { get }
}

// MARK: - Layout Properties

public struct LayoutProperties: Sendable, Hashable {
    public var stackOrientation: Axis?

    public init(stackOrientation: Axis? = nil) {
        self.stackOrientation = stackOrientation
    }
}

// MARK: - View Spacing

public struct ViewSpacing: Sendable, Hashable {
    public var leading: Double
    public var trailing: Double
    public var top: Double
    public var bottom: Double

    public init(leading: Double = 0, trailing: Double = 0, top: Double = 0, bottom: Double = 0) {
        self.leading = leading
        self.trailing = trailing
        self.top = top
        self.bottom = bottom
    }

    public static let zero = ViewSpacing()

    public mutating func formUnion(_ other: ViewSpacing) {
        leading = max(leading, other.leading)
        trailing = max(trailing, other.trailing)
        top = max(top, other.top)
        bottom = max(bottom, other.bottom)
    }

    public func distance(to other: ViewSpacing, along axis: Axis) -> Double {
        switch axis {
        case .horizontal:
            return max(trailing, other.leading)
        case .vertical:
            return max(bottom, other.top)
        }
    }
}

final class _AnyLayoutValueBox: @unchecked Sendable {
    let value: Any

    init(_ value: Any) {
        self.value = value
    }
}

// MARK: - Internal Measured Subview

struct _MeasuredLayoutSubview: Sendable {
    var size: CGSize
    var priority: Double
    var isSpacer: Bool
    var spacing: ViewSpacing
    var horizontalGuides: [HorizontalAlignment: Double]
    var verticalGuides: [VerticalAlignment: Double]
    var values: [ObjectIdentifier: _AnyLayoutValueBox]

    init(
        size: CGSize,
        priority: Double = 0,
        isSpacer: Bool = false,
        spacing: ViewSpacing = .zero,
        horizontalGuides: [HorizontalAlignment: Double] = [:],
        verticalGuides: [VerticalAlignment: Double] = [:],
        values: [ObjectIdentifier: _AnyLayoutValueBox] = [:]
    ) {
        self.size = size
        self.priority = priority
        self.isSpacer = isSpacer
        self.spacing = spacing
        self.horizontalGuides = horizontalGuides
        self.verticalGuides = verticalGuides
        self.values = values
    }
}

// MARK: - Layout Subviews

final class _LayoutSubviewStorage {
    let index: Int
    var measured: _MeasuredLayoutSubview
    var frame: CGRect
    var values: [ObjectIdentifier: _AnyLayoutValueBox]

    init(index: Int, measured: _MeasuredLayoutSubview) {
        self.index = index
        self.measured = measured
        self.frame = CGRect(origin: .zero, size: measured.size)
        self.values = measured.values
    }
}

public struct LayoutSubview {
    let storage: _LayoutSubviewStorage

    init(storage: _LayoutSubviewStorage) {
        self.storage = storage
    }

    public var priority: Double {
        storage.measured.priority
    }

    public var id: Int {
        storage.index
    }

    public var spacing: ViewSpacing {
        storage.measured.spacing
    }

    public func sizeThatFits(_ proposal: ProposedViewSize) -> CGSize {
        let measured = storage.measured.size
        let width = proposal.width ?? measured.width
        let height = proposal.height ?? measured.height
        return CGSize(width: width, height: height)
    }

    public func dimensions(in proposal: ProposedViewSize) -> ViewDimensions {
        let size = sizeThatFits(proposal)
        return ViewDimensions(
            width: size.width,
            height: size.height,
            horizontalGuides: storage.measured.horizontalGuides,
            verticalGuides: storage.measured.verticalGuides
        )
    }

    public func place(at position: CGPoint, anchor: UnitPoint = .topLeading, proposal: ProposedViewSize) {
        let size = sizeThatFits(proposal)
        let x = position.x - (size.width * anchor.x)
        let y = position.y - (size.height * anchor.y)
        storage.frame = CGRect(x: x, y: y, width: size.width, height: size.height)
    }

    public subscript<Key: LayoutValueKey>(key: Key.Type) -> Key.Value {
        get {
            if let value = storage.values[ObjectIdentifier(key)]?.value as? Key.Value {
                return value
            }
            return Key.defaultValue
        }
        nonmutating set {
            storage.values[ObjectIdentifier(key)] = _AnyLayoutValueBox(newValue)
        }
    }

    var _measuredSize: CGSize {
        storage.measured.size
    }

    var _frame: CGRect {
        storage.frame
    }
}

public struct LayoutSubviews: RandomAccessCollection {
    public typealias Element = LayoutSubview
    public typealias Index = Int

    let storages: [_LayoutSubviewStorage]

    init(storages: [_LayoutSubviewStorage]) {
        self.storages = storages
    }

    public var startIndex: Int { storages.startIndex }
    public var endIndex: Int { storages.endIndex }

    public subscript(position: Int) -> LayoutSubview {
        LayoutSubview(storage: storages[position])
    }

    static func _fromMeasured(_ measuredSubviews: [_MeasuredLayoutSubview]) -> LayoutSubviews {
        let storages = measuredSubviews.enumerated().map { index, measured in
            _LayoutSubviewStorage(index: index, measured: measured)
        }
        return LayoutSubviews(storages: storages)
    }

    func _frames() -> [CGRect] {
        storages.map(\.frame)
    }
}

// MARK: - Layout Protocol

@MainActor
public protocol Layout: Sendable {
    associatedtype Cache = Void
    typealias Subviews = LayoutSubviews

    static var layoutProperties: LayoutProperties { get }

    func makeCache(subviews: Subviews) -> Cache
    func updateCache(_ cache: inout Cache, subviews: Subviews)

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout Cache) -> CGSize
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout Cache)
    func explicitAlignment(
        of guide: HorizontalAlignment,
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout Cache
    ) -> Double?
    func explicitAlignment(
        of guide: VerticalAlignment,
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout Cache
    ) -> Double?
}

extension Layout {
    public static var layoutProperties: LayoutProperties {
        LayoutProperties()
    }

    public func makeCache(subviews: Subviews) -> Void {
        ()
    }

    public func updateCache(_ cache: inout Void, subviews: Subviews) {
    }

    public func explicitAlignment(
        of guide: HorizontalAlignment,
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout Cache
    ) -> Double? {
        nil
    }

    public func explicitAlignment(
        of guide: VerticalAlignment,
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout Cache
    ) -> Double? {
        nil
    }

    public func callAsFunction<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        _LayoutContainer(layout: self, content: content())
    }
}

// MARK: - Trait Extraction

private enum _LayoutGuideAttr {
    static let priority = "data-raven-layout-priority"
    static let isSpacer = "data-raven-layout-is-spacer"

    static let leading = "data-raven-layout-guide-h-leading"
    static let centerX = "data-raven-layout-guide-h-center"
    static let trailing = "data-raven-layout-guide-h-trailing"

    static let top = "data-raven-layout-guide-v-top"
    static let centerY = "data-raven-layout-guide-v-center"
    static let bottom = "data-raven-layout-guide-v-bottom"
    static let firstBaseline = "data-raven-layout-guide-v-first-baseline"
    static let lastBaseline = "data-raven-layout-guide-v-last-baseline"
    static let valueToken = "data-raven-layout-value-token"
}

private struct _LayoutChildTraits {
    var priority: Double?
    var isSpacer = false
    var horizontalGuides: [HorizontalAlignment: Double] = [:]
    var verticalGuides: [VerticalAlignment: Double] = [:]

    static func fromVNode(_ node: VNode) -> _LayoutChildTraits {
        var bestDepthForPriority: Int?
        var bestDepthForH: [HorizontalAlignment: Int] = [:]
        var bestDepthForV: [VerticalAlignment: Int] = [:]
        var result = _LayoutChildTraits()

        func visit(_ current: VNode, depth: Int) {
            if current.props["data-raven-spacer"] != nil {
                result.isSpacer = true
            }

            if let priority = current._attributeDouble(_LayoutGuideAttr.priority) {
                if bestDepthForPriority == nil || depth < bestDepthForPriority! {
                    bestDepthForPriority = depth
                    result.priority = priority
                }
            }

            func assignH(_ alignment: HorizontalAlignment, attr: String) {
                guard let value = current._attributeDouble(attr) else { return }
                if bestDepthForH[alignment] == nil || depth < bestDepthForH[alignment]! {
                    bestDepthForH[alignment] = depth
                    result.horizontalGuides[alignment] = value
                }
            }

            func assignV(_ alignment: VerticalAlignment, attr: String) {
                guard let value = current._attributeDouble(attr) else { return }
                if bestDepthForV[alignment] == nil || depth < bestDepthForV[alignment]! {
                    bestDepthForV[alignment] = depth
                    result.verticalGuides[alignment] = value
                }
            }

            assignH(.leading, attr: _LayoutGuideAttr.leading)
            assignH(.center, attr: _LayoutGuideAttr.centerX)
            assignH(.trailing, attr: _LayoutGuideAttr.trailing)

            assignV(.top, attr: _LayoutGuideAttr.top)
            assignV(.center, attr: _LayoutGuideAttr.centerY)
            assignV(.bottom, attr: _LayoutGuideAttr.bottom)
            assignV(.firstTextBaseline, attr: _LayoutGuideAttr.firstBaseline)
            assignV(.lastTextBaseline, attr: _LayoutGuideAttr.lastBaseline)

            for child in current.children {
                visit(child, depth: depth + 1)
            }
        }

        visit(node, depth: 0)
        return result
    }
}

private extension VNode {
    func _attributeDouble(_ name: String) -> Double? {
        guard let property = props[name] else { return nil }
        guard case .attribute(_, let value) = property else { return nil }
        return Double(value)
    }
}

// MARK: - Internal Measurement Runtime

@MainActor
final class _LayoutRenderController: @unchecked Sendable {
    let id: String = _ravenNextRuntimeID(prefix: "layout")

    weak var renderScheduler: (any _StateChangeReceiver)?

    private var didStart = false
    private var rafClosure: JSClosure?
    private var resizeObserver: JSObject?
    private var resizeObserverClosure: JSClosure?

    private var layoutConfigurationID: String = ""
    private var childCount = 0

    private(set) var childFrames: [CGRect] = []
    private(set) var layoutSize: CGSize = .zero
    private(set) var hasValidPlacement = false

    private var renderAnimationContext: Animation?
    private(set) var layoutDeltaAnimation: Animation?

    var erasedLayout: AnyLayout = AnyLayout(HStackLayout())
    var erasedCache = AnyLayoutCache()

    func configure(layout: AnyLayout, layoutConfigurationID: String, childCount: Int) {
        if self.layoutConfigurationID != layoutConfigurationID {
            self.layoutConfigurationID = layoutConfigurationID
            erasedCache = AnyLayoutCache()
            hasValidPlacement = false
            layoutDeltaAnimation = nil
        }
        if self.childCount != childCount {
            self.childCount = childCount
            hasValidPlacement = false
        }
        erasedLayout = layout
    }

    func captureAnimationContext(_ animation: Animation?) {
        renderAnimationContext = animation
    }

    func startIfNeeded() {
        guard !didStart else { return }
        didStart = true
        scheduleMeasure(force: true)
    }

    func scheduleMeasure(force: Bool = false) {
        if !force, hasValidPlacement { return }
        guard rafClosure == nil else { return }

        let closure = JSClosure { [weak self] _ -> JSValue in
            guard let self else { return .undefined }
            self.rafClosure = nil
            self.measureAndPlaceIfPossible()
            return .undefined
        }
        rafClosure = closure

        if let raf = JSObject.global.requestAnimationFrame.function {
            _ = raf(closure)
        } else if let setTimeout = JSObject.global.setTimeout.function {
            _ = setTimeout(closure, 0)
        }
    }

    private func measureAndPlaceIfPossible() {
        guard let document = JSObject.global.document.object else { return }

        let selector = "[data-raven-layout-id=\"\(id)\"]"
        guard let querySelectorFn = document.querySelector.function else { return }
        let containerResult = querySelectorFn(this: document, selector)
        guard !containerResult.isNull, let container = containerResult.object else { return }

        attachResizeObserverIfAvailable(to: container)

        let childElements = directLayoutChildren(in: container)
        let count = childElements.count
        guard count > 0 else { return }

        var measured: [_MeasuredLayoutSubview] = []
        measured.reserveCapacity(count)
        for element in childElements {
            measured.append(measureSubview(element: element))
        }

        let containerWidth = container.clientWidth.number ?? DOMBridge.shared.measureGeometry(element: container).size.width
        let containerHeight = container.clientHeight.number ?? DOMBridge.shared.measureGeometry(element: container).size.height

        let proposal = ProposedViewSize(
            width: containerWidth > 0 ? containerWidth : nil,
            height: containerHeight > 0 ? containerHeight : nil
        )

        var cache = erasedCache
        let result = erasedLayout._computeLayout(
            proposal: proposal,
            measuredSubviews: measured,
            cache: &cache
        )
        erasedCache = cache

        let changed = result.frames != childFrames || result.size != layoutSize
        childFrames = result.frames
        layoutSize = result.size
        hasValidPlacement = !result.frames.isEmpty
        layoutDeltaAnimation = changed ? renderAnimationContext : nil

        if changed {
            renderScheduler?.scheduleRender()
        }
    }

    private func directLayoutChildren(in container: JSObject) -> [JSObject] {
        guard let htmlCollection = container.children.object else { return [] }
        let count = Int(htmlCollection.length.number ?? 0)
        guard count > 0 else { return [] }

        var children: [JSObject] = []
        children.reserveCapacity(count)
        for index in 0..<count {
            guard let element = htmlCollection[index].object else { continue }
            guard element.getAttribute?("data-raven-layout-child").string != nil else { continue }
            children.append(element)
        }
        return children
    }

    private func measureSubview(element: JSObject) -> _MeasuredLayoutSubview {
        let width = element.scrollWidth.number ?? DOMBridge.shared.measureGeometry(element: element).size.width
        let height = element.scrollHeight.number ?? DOMBridge.shared.measureGeometry(element: element).size.height
        let size = CGSize(width: width, height: height)

        let priority = element.getAttribute?(_LayoutGuideAttr.priority).string.flatMap(Double.init) ?? 0
        let isSpacer = (element.getAttribute?(_LayoutGuideAttr.isSpacer).string ?? "") == "true"

        var horizontalGuides: [HorizontalAlignment: Double] = [:]
        var verticalGuides: [VerticalAlignment: Double] = [:]
        var values: [ObjectIdentifier: _AnyLayoutValueBox] = [:]

        if let value = element.getAttribute?(_LayoutGuideAttr.leading).string.flatMap(Double.init) {
            horizontalGuides[.leading] = value
        }
        if let value = element.getAttribute?(_LayoutGuideAttr.centerX).string.flatMap(Double.init) {
            horizontalGuides[.center] = value
        }
        if let value = element.getAttribute?(_LayoutGuideAttr.trailing).string.flatMap(Double.init) {
            horizontalGuides[.trailing] = value
        }

        if let value = element.getAttribute?(_LayoutGuideAttr.top).string.flatMap(Double.init) {
            verticalGuides[.top] = value
        }
        if let value = element.getAttribute?(_LayoutGuideAttr.centerY).string.flatMap(Double.init) {
            verticalGuides[.center] = value
        }
        if let value = element.getAttribute?(_LayoutGuideAttr.bottom).string.flatMap(Double.init) {
            verticalGuides[.bottom] = value
        }

        let computedBaselines = inferTextBaselines(for: element, size: size)
        verticalGuides[.firstTextBaseline] = element.getAttribute?(_LayoutGuideAttr.firstBaseline).string.flatMap(Double.init) ?? computedBaselines.first
        verticalGuides[.lastTextBaseline] = element.getAttribute?(_LayoutGuideAttr.lastBaseline).string.flatMap(Double.init) ?? computedBaselines.last

        mergeRegisteredGuides(on: element, size: size, intoH: &horizontalGuides, intoV: &verticalGuides)
        mergeRegisteredLayoutValues(on: element, into: &values)

        return _MeasuredLayoutSubview(
            size: size,
            priority: priority,
            isSpacer: isSpacer,
            spacing: .zero,
            horizontalGuides: horizontalGuides,
            verticalGuides: verticalGuides,
            values: values
        )
    }

    private func inferTextBaselines(for element: JSObject, size: CGSize) -> (first: Double, last: Double) {
        guard let getComputedStyle = JSObject.global.getComputedStyle.function else {
            return (size.height, size.height)
        }

        let style = getComputedStyle(element).object
        let fontSizePx = style?.fontSize.string.flatMap { $0.replacingOccurrences(of: "px", with: "") }.flatMap(Double.init) ?? 16
        let rawLineHeight = style?.lineHeight.string ?? ""
        let lineHeightPx: Double
        if rawLineHeight == "normal" || rawLineHeight.isEmpty {
            lineHeightPx = fontSizePx * 1.2
        } else {
            lineHeightPx = rawLineHeight.replacingOccurrences(of: "px", with: "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                ? fontSizePx * 1.2
                : (Double(rawLineHeight.replacingOccurrences(of: "px", with: "").trimmingCharacters(in: .whitespacesAndNewlines)) ?? (fontSizePx * 1.2))
        }

        let ascent = fontSizePx * 0.8
        let first = min(size.height, max(0, ascent))
        let lines = max(1, Int(round(size.height / max(1, lineHeightPx))))
        let last = min(size.height, first + (Double(lines - 1) * lineHeightPx))
        return (first, last)
    }

    private func mergeRegisteredGuides(
        on element: JSObject,
        size: CGSize,
        intoH horizontalGuides: inout [HorizontalAlignment: Double],
        intoV verticalGuides: inout [VerticalAlignment: Double]
    ) {
        guard let tokenNodes = element.querySelectorAll?("[data-raven-layout-guide-token]") else { return }
        let length = Int(tokenNodes.length.number ?? 0)
        guard length > 0 else { return }

        for index in 0..<length {
            guard let node = tokenNodes[index].object else { continue }
            guard let tokenString = node.getAttribute?("data-raven-layout-guide-token").string else { continue }
            guard let token = UUID(uuidString: tokenString) else { continue }
            guard let registered = _LayoutTraitRegistry.alignmentGuides[token] else { continue }

            let dimensions = ViewDimensions(
                width: size.width,
                height: size.height,
                horizontalGuides: horizontalGuides,
                verticalGuides: verticalGuides
            )

            switch registered {
            case .horizontal(let alignment, let resolver):
                horizontalGuides[alignment] = resolver(dimensions)
            case .vertical(let alignment, let resolver):
                verticalGuides[alignment] = resolver(dimensions)
            }
        }
    }

    private func mergeRegisteredLayoutValues(
        on element: JSObject,
        into values: inout [ObjectIdentifier: _AnyLayoutValueBox]
    ) {
        guard let tokenNodes = element.querySelectorAll?("[\(_LayoutGuideAttr.valueToken)]") else { return }
        let length = Int(tokenNodes.length.number ?? 0)
        guard length > 0 else { return }

        for index in 0..<length {
            guard let node = tokenNodes[index].object else { continue }
            guard let tokenString = node.getAttribute?(_LayoutGuideAttr.valueToken).string else { continue }
            guard let token = UUID(uuidString: tokenString) else { continue }
            guard let registered = _LayoutTraitRegistry.layoutValues[token] else { continue }
            values[registered.keyID] = _AnyLayoutValueBox(registered.value)
        }
    }

    private func attachResizeObserverIfAvailable(to element: JSObject) {
        guard resizeObserver == nil else { return }
        guard let resizeObserverCtor = JSObject.global.ResizeObserver.function else { return }

        let closure = JSClosure { [weak self] _ -> JSValue in
            self?.hasValidPlacement = false
            self?.scheduleMeasure(force: true)
            return .undefined
        }
        resizeObserverClosure = closure
        let observer = resizeObserverCtor.new(closure)
        resizeObserver = observer
        _ = observer.observe!(element)
    }
}

// MARK: - Layout Container

@MainActor
public struct _LayoutContainer<L: Layout, Content: View>: View, PrimitiveView, Sendable {
    public typealias Body = Never

    let layout: L
    let content: Content

    init(layout: L, content: Content) {
        self.layout = layout
        self.content = content
    }

    public func toVNode() -> VNode {
        VNode.element("div", props: [
            "position": .style(name: "position", value: "relative"),
            "display": .style(name: "display", value: "block"),
            "data-raven-layout": .attribute(name: "data-raven-layout", value: "true"),
        ])
    }
}

extension _LayoutContainer: _CoordinatorRenderable {
    public func _render(with context: any _RenderContext) -> VNode {
        let contentNode = context.renderChild(content)
        let children: [VNode]
        if case .fragment = contentNode.type {
            children = contentNode.children
        } else {
            children = [contentNode]
        }

        let traits = children.map { _LayoutChildTraits.fromVNode($0) }

        let controller = context.persistentState(create: { _LayoutRenderController() })
        controller.renderScheduler = _RenderScheduler.current
        controller.captureAnimationContext(AnimationContext.current)

        let erased = AnyLayout(layout)
        let layoutConfigurationID = "\(String(describing: L.self))|\(String(reflecting: layout))"
        controller.configure(layout: erased, layoutConfigurationID: layoutConfigurationID, childCount: children.count)
        controller.startIfNeeded()

        if controller.hasValidPlacement, controller.childFrames.count == children.count {
            var props: [String: VProperty] = [
                "position": .style(name: "position", value: "relative"),
                "display": .style(name: "display", value: "block"),
                "data-raven-layout-id": .attribute(name: "data-raven-layout-id", value: controller.id),
            ]
            if controller.layoutSize.height > 0 {
                props["height"] = .style(name: "height", value: "\(controller.layoutSize.height)px")
            }

            let placedChildren = zip(zip(children, controller.childFrames), traits).enumerated().map { index, entry in
                let ((child, frame), trait) = entry
                var childProps: [String: VProperty] = [
                    "position": .style(name: "position", value: "absolute"),
                    "left": .style(name: "left", value: "\(frame.origin.x)px"),
                    "top": .style(name: "top", value: "\(frame.origin.y)px"),
                    "width": .style(name: "width", value: "\(frame.size.width)px"),
                    "height": .style(name: "height", value: "\(frame.size.height)px"),
                    "min-width": .style(name: "min-width", value: "0"),
                    "min-height": .style(name: "min-height", value: "0"),
                    "data-raven-layout-placed": .attribute(name: "data-raven-layout-placed", value: "\(index)"),
                    "data-raven-layout-child": .attribute(name: "data-raven-layout-child", value: "\(index)"),
                ]

                if let animation = controller.layoutDeltaAnimation {
                    childProps["transition"] = .style(
                        name: "transition",
                        value: animation.cssTransition(property: "left, top, width, height")
                    )
                    childProps["will-change"] = .style(name: "will-change", value: "left, top, width, height")
                }

                applyTraits(trait, to: &childProps)

                return VNode.element("div", props: childProps, children: [child])
            }

            return VNode.element("div", props: props, children: placedChildren)
        }

        controller.scheduleMeasure(force: true)

        let measureChildren = zip(children, traits).enumerated().map { index, entry in
            let (child, trait) = entry
            var childProps: [String: VProperty] = [
                "visibility": .style(name: "visibility", value: "hidden"),
                "pointer-events": .style(name: "pointer-events", value: "none"),
                "data-raven-layout-child": .attribute(name: "data-raven-layout-child", value: "\(index)"),
            ]
            applyTraits(trait, to: &childProps)
            return VNode.element("div", props: childProps, children: [child])
        }

        return VNode.element("div", props: [
            "position": .style(name: "position", value: "relative"),
            "display": .style(name: "display", value: "block"),
            "data-raven-layout-id": .attribute(name: "data-raven-layout-id", value: controller.id),
        ], children: measureChildren)
    }

    private func applyTraits(_ trait: _LayoutChildTraits, to props: inout [String: VProperty]) {
        if let priority = trait.priority {
            props[_LayoutGuideAttr.priority] = .attribute(name: _LayoutGuideAttr.priority, value: "\(priority)")
        }
        if trait.isSpacer {
            props[_LayoutGuideAttr.isSpacer] = .attribute(name: _LayoutGuideAttr.isSpacer, value: "true")
        }

        if let value = trait.horizontalGuides[.leading] {
            props[_LayoutGuideAttr.leading] = .attribute(name: _LayoutGuideAttr.leading, value: "\(value)")
        }
        if let value = trait.horizontalGuides[.center] {
            props[_LayoutGuideAttr.centerX] = .attribute(name: _LayoutGuideAttr.centerX, value: "\(value)")
        }
        if let value = trait.horizontalGuides[.trailing] {
            props[_LayoutGuideAttr.trailing] = .attribute(name: _LayoutGuideAttr.trailing, value: "\(value)")
        }

        if let value = trait.verticalGuides[.top] {
            props[_LayoutGuideAttr.top] = .attribute(name: _LayoutGuideAttr.top, value: "\(value)")
        }
        if let value = trait.verticalGuides[.center] {
            props[_LayoutGuideAttr.centerY] = .attribute(name: _LayoutGuideAttr.centerY, value: "\(value)")
        }
        if let value = trait.verticalGuides[.bottom] {
            props[_LayoutGuideAttr.bottom] = .attribute(name: _LayoutGuideAttr.bottom, value: "\(value)")
        }
        if let value = trait.verticalGuides[.firstTextBaseline] {
            props[_LayoutGuideAttr.firstBaseline] = .attribute(name: _LayoutGuideAttr.firstBaseline, value: "\(value)")
        }
        if let value = trait.verticalGuides[.lastTextBaseline] {
            props[_LayoutGuideAttr.lastBaseline] = .attribute(name: _LayoutGuideAttr.lastBaseline, value: "\(value)")
        }
    }
}
