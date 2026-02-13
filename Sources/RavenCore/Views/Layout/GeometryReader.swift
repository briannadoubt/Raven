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

// MARK: - Geometry Types

/// A structure that contains a width and a height value.
public struct CGSize: Sendable, Hashable {
    /// The width value.
    public var width: Double

    /// The height value.
    public var height: Double

    /// Creates a size with zero width and height.
    public static let zero = CGSize(width: 0, height: 0)

    /// Creates a size with the specified width and height.
    ///
    /// - Parameters:
    ///   - width: The width value.
    ///   - height: The height value.
    public init(width: Double, height: Double) {
        self.width = width
        self.height = height
    }
}

/// A structure that contains a location in a two-dimensional coordinate system.
public struct CGPoint: Sendable, Hashable {
    /// The x-coordinate of the point.
    public var x: Double

    /// The y-coordinate of the point.
    public var y: Double

    /// The point at the origin (0, 0).
    public static let zero = CGPoint(x: 0, y: 0)

    /// Creates a point with the specified coordinates.
    ///
    /// - Parameters:
    ///   - x: The x-coordinate of the point.
    ///   - y: The y-coordinate of the point.
    public init(x: Double, y: Double) {
        self.x = x
        self.y = y
    }
}

/// A structure that contains the location and dimensions of a rectangle.
public struct CGRect: Sendable, Hashable {
    /// The origin of the rectangle.
    public var origin: CGPoint

    /// The size of the rectangle.
    public var size: CGSize

    /// The x-coordinate of the rectangle's origin.
    public var minX: Double { origin.x }

    /// The y-coordinate of the rectangle's origin.
    public var minY: Double { origin.y }

    /// The x-coordinate of the rectangle's maximum x value.
    public var maxX: Double { origin.x + size.width }

    /// The y-coordinate of the rectangle's maximum y value.
    public var maxY: Double { origin.y + size.height }

    /// The width of the rectangle.
    public var width: Double { size.width }

    /// The height of the rectangle.
    public var height: Double { size.height }

    /// The x-coordinate of the rectangle's center.
    public var midX: Double { origin.x + size.width / 2 }

    /// The y-coordinate of the rectangle's center.
    public var midY: Double { origin.y + size.height / 2 }

    /// The rectangle at the origin with zero width and height.
    public static let zero = CGRect(origin: .zero, size: .zero)

    /// A null rectangle.
    ///
    /// Raven uses an Infinity-origin sentinel similar to CoreGraphics' `CGRect.null`.
    /// A null rect represents "no area" and is the result of operations like
    /// intersection when two rects do not overlap.
    public static let null = CGRect(x: .infinity, y: .infinity, width: 0, height: 0)

    /// Returns true if this rect is the null sentinel.
    public var isNull: Bool {
        origin.x.isInfinite && origin.y.isInfinite
    }

    /// Returns true if this rectangle has zero or negative area.
    ///
    /// Note: This does not consider `.null` to be empty; use `isNull` to check that.
    public var isEmpty: Bool {
        width <= 0 || height <= 0
    }

    /// Creates a rectangle with the specified origin and size.
    ///
    /// - Parameters:
    ///   - origin: The origin of the rectangle.
    ///   - size: The size of the rectangle.
    public init(origin: CGPoint, size: CGSize) {
        self.origin = origin
        self.size = size
    }

    /// Creates a rectangle with the specified coordinates and dimensions.
    ///
    /// - Parameters:
    ///   - x: The x-coordinate of the rectangle's origin.
    ///   - y: The y-coordinate of the rectangle's origin.
    ///   - width: The width of the rectangle.
    ///   - height: The height of the rectangle.
    public init(x: Double, y: Double, width: Double, height: Double) {
        self.origin = CGPoint(x: x, y: y)
        self.size = CGSize(width: width, height: height)
    }

    /// Returns the intersection of this rectangle and the given rectangle.
    ///
    /// - Parameter rect: The rectangle to intersect with.
    /// - Returns: The overlapping portion of the two rectangles, or `.null` if there is no overlap.
    public func intersection(_ rect: CGRect) -> CGRect {
        if isNull || rect.isNull {
            return .null
        }

        let nx = max(minX, rect.minX)
        let ny = max(minY, rect.minY)
        let mx = min(maxX, rect.maxX)
        let my = min(maxY, rect.maxY)

        // CoreGraphics returns `.null` when there is no overlap.
        if mx <= nx || my <= ny {
            return .null
        }

        return CGRect(x: nx, y: ny, width: mx - nx, height: my - ny)
    }
}

// MARK: - Coordinate Space

/// A resolved coordinate space created by the coordinate space protocol.
public enum CoordinateSpace: Sendable, Hashable {
    /// The local coordinate space of the current view.
    case local

    /// The global coordinate space (relative to the window/document).
    case global

    /// A named coordinate space.
    case named(String)
}

// MARK: - Geometry Proxy

/// A proxy for access to the size and coordinate space of a container view.
///
/// Use `GeometryProxy` to read geometry information about a view, such as its size
/// and position in different coordinate spaces.
///
/// Example:
/// ```swift
/// GeometryReader { geometry in
///     Text("Width: \(geometry.size.width)")
/// }
/// ```
public struct GeometryProxy: Sendable {
    /// The size of the container view.
    public let size: CGSize

    /// The safe area insets of the container view.
    ///
    /// Note: For the initial implementation, this returns zero insets.
    /// Future versions will integrate with the browser's safe area.
    public var safeAreaInsets: EdgeInsets {
        EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
    }

    /// Internal storage for frame information in different coordinate spaces.
    private let localFrame: CGRect
    private let globalFrame: CGRect

    /// Creates a geometry proxy with the specified size and frames.
    ///
    /// - Parameters:
    ///   - size: The size of the container view.
    ///   - localFrame: The frame in local coordinates.
    ///   - globalFrame: The frame in global coordinates.
    internal init(size: CGSize, localFrame: CGRect, globalFrame: CGRect) {
        self.size = size
        self.localFrame = localFrame
        self.globalFrame = globalFrame
    }

    /// Returns the container view's bounds rectangle in the specified coordinate space.
    ///
    /// - Parameter coordinateSpace: The coordinate space to use for the bounds.
    /// - Returns: A rectangle representing the view's bounds.
    public func frame(in coordinateSpace: CoordinateSpace) -> CGRect {
        switch coordinateSpace {
        case .local:
            return localFrame
        case .global:
            return globalFrame
        case .named:
            // For now, treat named coordinate spaces as global
            // A full implementation would track named coordinate spaces
            return globalFrame
        }
    }
}

// MARK: - Geometry Reader

/// A container view that defines its content as a function of its own size and coordinate space.
///
/// `GeometryReader` is a layout view that provides geometry information to its content closure.
/// This allows views to adapt their appearance based on the size and position of their container.
///
/// Example:
/// ```swift
/// GeometryReader { geometry in
///     VStack {
///         Text("Width: \(geometry.size.width)")
///         Text("Height: \(geometry.size.height)")
///     }
/// }
/// ```
///
/// The GeometryReader expands to fill all available space in its parent, similar to a `Color` view.
///
/// For advanced positioning, you can query the frame in different coordinate spaces:
/// ```swift
/// GeometryReader { geometry in
///     let globalFrame = geometry.frame(in: .global)
///     Text("Global position: (\(globalFrame.minX), \(globalFrame.minY))")
/// }
/// ```
public struct GeometryReader<Content: View>: View, Sendable {
    /// The content closure that receives geometry information.
    private let content: @Sendable @MainActor (GeometryProxy) -> Content

    /// Creates a geometry reader with the specified content.
    ///
    /// - Parameter content: A view builder that creates the content based on geometry information.
    @MainActor public init(@ViewBuilder content: @escaping @Sendable @MainActor (GeometryProxy) -> Content) {
        self.content = content
    }

    /// The body of the geometry reader.
    ///
    /// GeometryReader is not a primitive view - it has a body that wraps its content
    /// in a special container that will be measured by the rendering system.
    @MainActor public var body: some View {
        _GeometryReaderContainer(content: content)
    }
}

// MARK: - Internal Container

/// Internal container view for GeometryReader that handles DOM measurement.
///
/// This is a primitive view that renders to a div element and uses JavaScriptKit
/// to measure its size and position in the DOM.
internal struct _GeometryReaderContainer<Content: View>: View, PrimitiveView, Sendable {
    typealias Body = Never

    let content: @Sendable @MainActor (GeometryProxy) -> Content

    @MainActor init(content: @escaping @Sendable @MainActor (GeometryProxy) -> Content) {
        self.content = content
    }

    /// Converts this container to a virtual DOM node.
    ///
    /// The container is rendered as a div with specific styling to fill available space
    /// and enable geometry measurement. The actual measurement and content rendering
    /// will be handled by the RenderCoordinator.
    ///
    /// - Returns: A VNode configured as a geometry container.
    @MainActor public func toVNode() -> VNode {
        // Create a container div that fills available space
        let props: [String: VProperty] = [
            "display": .style(name: "display", value: "block"),
            "position": .style(name: "position", value: "relative"),
            "width": .style(name: "width", value: "100%"),
            "height": .style(name: "height", value: "100%"),
            // Mark this as a geometry reader container for the render coordinator
            "data-geometry-reader": .attribute(name: "data-geometry-reader", value: "true")
        ]

        return VNode.element(
            "div",
            props: props,
            children: []
        )
    }
}

// MARK: - Geometry Reader Controller

/// Persistent controller that measures the mounted DOM node for a GeometryReader.
///
/// Raven doesn't currently have a first-class view lifecycle callback (onMount / afterRender).
/// To bridge that gap, this controller:
/// 1. Tags the container node with a stable `data-raven-geometry-id`
/// 2. Schedules a `requestAnimationFrame` to find + measure the element after DOM updates
/// 3. Attaches a ResizeObserver (when available) to keep measurements current
@MainActor
internal final class GeometryReaderController: @unchecked Sendable {
    let id: String = _ravenNextRuntimeID(prefix: "geometry")

    private(set) var proxy: GeometryProxy = GeometryProxy(size: .zero, localFrame: .zero, globalFrame: .zero)

    weak var renderScheduler: (any _StateChangeReceiver)?

    private var didStart = false
    private var rafClosure: JSClosure?
    private var resizeObserver: JSObject?
    private var resizeObserverClosure: JSClosure?
    private var observedElement: JSObject?
    private var lastRenderScheduleTimeMS: Double = 0

    func startIfNeeded() {
        guard !didStart else { return }
        didStart = true
        scheduleMeasure()
    }

    func scheduleMeasure() {
        #if arch(wasm32)
        // If we're already observing the element for size changes, don't keep scheduling
        // RAF measurements on every render pass.
        if observedElement != nil, resizeObserver != nil {
            return
        }

        // Avoid stacking RAF calls on every render pass.
        guard rafClosure == nil else { return }

        let closure = JSClosure { [weak self] _ -> JSValue in
            guard let self else { return .undefined }
            self.rafClosure = nil
            self.measureAndObserveIfNeeded()
            return .undefined
        }
        rafClosure = closure

        // requestAnimationFrame is preferable to setTimeout(0) for layout measurement.
        if let raf = JSObject.global.requestAnimationFrame.function {
            _ = raf(closure)
        } else if let setTimeout = JSObject.global.setTimeout.function {
            _ = setTimeout(closure, 0)
        }
        #endif
    }

    private func measureAndObserveIfNeeded() {
        guard let document = JSObject.global.document.object else { return }

        // Find the element created for this GeometryReader instance.
        //
        // Important: DOM methods like `document.querySelector` require a proper `this`
        // binding. Calling an unbound function in JS (or via JavaScriptKit) triggers
        // "Illegal invocation".
        let selector = "[data-raven-geometry-id=\"\(id)\"]"
        guard let querySelectorFn = document.querySelector.function else { return }
        let result = querySelectorFn(this: document, selector)
        guard !result.isNull, let element = result.object else { return }

        // Cache the element and attach ResizeObserver once.
        if observedElement == nil {
            observedElement = element
            attachResizeObserverIfAvailable(to: element)
        }

        let newProxy = DOMBridge.shared.measureGeometry(element: element)
        let oldSize = proxy.size
        let newSize = newProxy.size

        func nearlyEqual(_ a: Double, _ b: Double, epsilon: Double = 1.5) -> Bool {
            abs(a - b) < epsilon
        }

        // Only re-render when geometry materially changes; otherwise we'd RAF-loop forever.
        if !nearlyEqual(oldSize.width, newSize.width) || !nearlyEqual(oldSize.height, newSize.height) {
            let widthDelta = abs(oldSize.width - newSize.width)
            let heightDelta = abs(oldSize.height - newSize.height)
            let nowMS = Date().timeIntervalSince1970 * 1000
            let recentlyScheduled = (nowMS - lastRenderScheduleTimeMS) < 120
            // Self-referential layout loops often drift in small steps (e.g. +32px/frame).
            // Treat those as oscillation and suppress extra re-renders.
            let likelyOscillation = widthDelta < 64 && heightDelta < 64

            if recentlyScheduled && likelyOscillation {
                proxy = newProxy
                return
            }

            lastRenderScheduleTimeMS = nowMS
            proxy = newProxy
            renderScheduler?.scheduleRender()
        } else {
            // Still update frames even if size is unchanged, but don't force a render.
            proxy = newProxy
        }
    }

    private func attachResizeObserverIfAvailable(to element: JSObject) {
        guard resizeObserver == nil else { return }
        guard let resizeObserverCtor = JSObject.global.ResizeObserver.function else { return }

        let closure = JSClosure { [weak self] _ -> JSValue in
            guard let self else { return .undefined }
            self.measureAndObserveIfNeeded()
            return .undefined
        }
        resizeObserverClosure = closure
        let observer = resizeObserverCtor.new(closure)
        resizeObserver = observer
        _ = observer.observe!(element)
    }
}

// MARK: - DOM Bridge Extensions

extension DOMBridge {
    /// Measures the geometry of a DOM element.
    ///
    /// Uses getBoundingClientRect() to measure the element's size and position
    /// in both local and global coordinate spaces.
    ///
    /// - Parameter element: The DOM element to measure.
    /// - Returns: A GeometryProxy with the measured geometry information.
    @MainActor public func measureGeometry(element: JSObject) -> GeometryProxy {
        // Get the bounding client rect
        let rect = element.getBoundingClientRect!()

        // Extract dimensions
        let width = rect.width.number ?? 0
        let height = rect.height.number ?? 0
        let x = rect.x.number ?? 0
        let y = rect.y.number ?? 0

        // Create size
        let size = CGSize(width: width, height: height)

        // Local frame is relative to the element itself
        let localFrame = CGRect(x: 0, y: 0, width: width, height: height)

        // Global frame is relative to the viewport
        let globalFrame = CGRect(x: x, y: y, width: width, height: height)

        return GeometryProxy(size: size, localFrame: localFrame, globalFrame: globalFrame)
    }

    /// Creates a default geometry proxy with placeholder values.
    ///
    /// This is used when DOM measurement is not yet available, such as during
    /// initial rendering before the element is mounted to the DOM.
    ///
    /// - Returns: A GeometryProxy with zero size and frames.
    @MainActor public func createDefaultGeometry() -> GeometryProxy {
        GeometryProxy(
            size: .zero,
            localFrame: .zero,
            globalFrame: .zero
        )
    }
}

// MARK: - Coordinator Renderable

extension _GeometryReaderContainer: _CoordinatorRenderable {
    @MainActor public func _render(with context: any _RenderContext) -> VNode {
        let controller = context.persistentState(create: { GeometryReaderController() })
        controller.renderScheduler = _RenderScheduler.current
        controller.startIfNeeded()

        let props: [String: VProperty] = [
            "display": .style(name: "display", value: "block"),
            "position": .style(name: "position", value: "relative"),
            "width": .style(name: "width", value: "100%"),
            "height": .style(name: "height", value: "100%"),
            "data-geometry-reader": .attribute(name: "data-geometry-reader", value: "true")
        ]

        var mergedProps = props
        mergedProps["data-raven-geometry-id"] = .attribute(name: "data-raven-geometry-id", value: controller.id)

        let childView = content(controller.proxy)
        let contentNode = context.renderChild(childView)
        let contentChildren: [VNode]
        if case .fragment = contentNode.type {
            contentChildren = contentNode.children
        } else {
            contentChildren = [contentNode]
        }

        // GeometryReader content should not determine the GeometryReader's own size.
        // It is laid out inside the measured container's bounds.
        let contentWrapper = VNode.element(
            "div",
            props: [
                "position": .style(name: "position", value: "absolute"),
                "top": .style(name: "top", value: "0"),
                "right": .style(name: "right", value: "0"),
                "bottom": .style(name: "bottom", value: "0"),
                "left": .style(name: "left", value: "0"),
            ],
            children: contentChildren
        )

        return VNode.element("div", props: mergedProps, children: [contentWrapper])
    }
}
