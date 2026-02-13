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

/// A container view that selects the first child view that fits within the available space.
///
/// `ViewThatFits` enables responsive design by automatically choosing between multiple
/// view layouts based on available space. It measures each child view option and displays
/// the first one that fits, making it ideal for adapting between desktop and mobile layouts
/// without explicit breakpoints.
///
/// ## Overview
///
/// Use `ViewThatFits` when you want to provide multiple layout options and let the system
/// choose the most appropriate one based on available space. This is particularly useful
/// for responsive designs where you want different layouts for different screen sizes.
///
/// ## Basic Usage
///
/// Provide multiple view options, ordered from most preferred to least preferred:
///
/// ```swift
/// ViewThatFits {
///     // Desktop layout - will be used if it fits
///     HStack {
///         Image("logo")
///         Text("My App Name")
///         Spacer()
///         Button("Sign In") { }
///         Button("Sign Up") { }
///     }
///
///     // Mobile layout - fallback if desktop layout doesn't fit
///     VStack {
///         HStack {
///             Image("logo")
///             Text("My App")
///         }
///         HStack {
///             Button("Sign In") { }
///             Button("Sign Up") { }
///         }
///     }
/// }
/// ```
///
/// ## Axis Control
///
/// By default, `ViewThatFits` measures views on the vertical axis. You can control
/// which axes are considered for fitting:
///
/// ```swift
/// // Check horizontal space only
/// ViewThatFits(in: .horizontal) {
///     HStack {
///         Text("Option 1")
///         Text("Option 2")
///         Text("Option 3")
///     }
///     VStack {
///         Text("Option 1")
///         Text("Option 2")
///     }
/// }
///
/// // Check both axes
/// ViewThatFits(in: [.horizontal, .vertical]) {
///     LargeLayout()
///     MediumLayout()
///     CompactLayout()
/// }
/// ```
///
/// ## Responsive Navigation
///
/// Create navigation that adapts to available space:
///
/// ```swift
/// ViewThatFits(in: .horizontal) {
///     // Wide layout with all items
///     HStack {
///         ForEach(items) { item in
///             NavigationLink(item.title) {
///                 item.destination
///             }
///         }
///     }
///
///     // Medium layout with some items
///     HStack {
///         ForEach(items.prefix(3)) { item in
///             NavigationLink(item.title) {
///                 item.destination
///             }
///         }
///         Menu("More") {
///             ForEach(items.dropFirst(3)) { item in
///                 Button(item.title) {
///                     navigate(to: item)
///                 }
///             }
///         }
///     }
///
///     // Compact layout with menu only
///     Menu("Menu") {
///         ForEach(items) { item in
///             Button(item.title) {
///                 navigate(to: item)
///             }
///         }
///     }
/// }
/// ```
///
/// ## Form Layouts
///
/// Adapt form layouts based on available space:
///
/// ```swift
/// ViewThatFits {
///     // Two-column form for wide screens
///     HStack(alignment: .top, spacing: 20) {
///         VStack(alignment: .leading) {
///             TextField("First Name", text: $firstName)
///             TextField("Email", text: $email)
///         }
///         VStack(alignment: .leading) {
///             TextField("Last Name", text: $lastName)
///             TextField("Phone", text: $phone)
///         }
///     }
///
///     // Single-column form for narrow screens
///     VStack(alignment: .leading) {
///         TextField("First Name", text: $firstName)
///         TextField("Last Name", text: $lastName)
///         TextField("Email", text: $email)
///         TextField("Phone", text: $phone)
///     }
/// }
/// ```
///
/// ## Web Implementation
///
/// On the web, `ViewThatFits` uses CSS container queries to efficiently determine which
/// view fits. Each view option is wrapped in a container with visibility rules based on
/// the container size. The browser natively handles the selection, making it highly
/// performant.
///
/// ## Best Practices
///
/// - Order views from most preferred to least preferred
/// - Always provide a fallback option that will fit in minimal space
/// - Use for layout adaptation, not for feature detection
/// - Consider using with `.containerRelativeFrame()` for more control
/// - Test with various container sizes to ensure all options work
///
/// ## Browser Compatibility
///
/// `ViewThatFits` uses CSS Container Queries, which are supported in:
/// - Chrome/Edge 105+
/// - Safari 16+
/// - Firefox 110+
///
/// For older browsers, the last (most compact) option will be displayed as a fallback.
///
/// ## See Also
///
/// - ``containerRelativeFrame(_:alignment:_:)``
/// - ``GeometryReader``
/// - ``Axis``
///
/// - Parameters:
///   - axes: The axes to consider when determining if a view fits. Defaults to `.vertical`.
///   - content: A view builder that provides the view options to choose from.
public struct ViewThatFits<Content: View>: View, PrimitiveView, Sendable {
    public typealias Body = Never

    /// The axes to measure for fitting
    let axes: Axis.Set

    /// The view options to choose from
    let content: Content

    // MARK: - Initializers

    /// Creates a view that fits with the specified axes and content options.
    ///
    /// - Parameters:
    ///   - axes: The axes to consider when determining if a view fits. Defaults to `.vertical`.
    ///   - content: A view builder that provides the view options to choose from, ordered from most preferred to least preferred.
    @MainActor public init(
        in axes: Axis.Set = .vertical,
        @ViewBuilder content: () -> Content
    ) {
        self.axes = axes
        self.content = content()
    }

    // MARK: - VNode Conversion

    /// Converts this ViewThatFits to a virtual DOM node.
    ///
    /// The ViewThatFits is rendered using CSS container queries to efficiently select
    /// the first view that fits. The implementation creates:
    /// - An outer container with `container-type: size` to enable container queries
    /// - Inner wrappers for each view option with visibility controlled by `@container` rules
    /// - Fallback behavior that shows the last option for browsers without container query support
    ///
    /// The children are not converted here. The RenderCoordinator will handle rendering
    /// the content by accessing the `content` property and extracting individual view options.
    ///
    /// - Returns: A VNode configured as a container query-based selector.
    @MainActor public func toVNode() -> VNode {
        // Create an outer container with container query support
        var props: [String: VProperty] = [
            "display": .style(name: "display", value: "block"),
            "container-type": .style(name: "container-type", value: "size"),
            "position": .style(name: "position", value: "relative"),
            // Mark this as a ViewThatFits container for the render coordinator
            "data-view-that-fits": .attribute(name: "data-view-that-fits", value: "true"),
            "data-fit-axes": .attribute(name: "data-fit-axes", value: axesString)
        ]

        // Add width/height fill based on axes
        if axes.contains(.horizontal) {
            props["width"] = .style(name: "width", value: "100%")
        }
        if axes.contains(.vertical) {
            props["height"] = .style(name: "height", value: "100%")
        }

        return VNode.element(
            "div",
            props: props,
            children: []
        )
    }

    /// String representation of the axes for DOM attributes
    private var axesString: String {
        if axes == .all {
            return "both"
        } else if axes.contains(.horizontal) {
            return "horizontal"
        } else if axes.contains(.vertical) {
            return "vertical"
        } else {
            return "vertical" // default
        }
    }
}

// MARK: - Coordinator Rendering (WASM)

@MainActor
internal final class ViewThatFitsController: @unchecked Sendable {
    let id: String = _ravenNextRuntimeID(prefix: "vtf")

    private(set) var selectedIndex: Int = 0

    weak var renderScheduler: (any _StateChangeReceiver)?

    private var didStart = false
    private var rafClosure: JSClosure?
    private var resizeObserver: JSObject?
    private var resizeObserverClosure: JSClosure?
    private var observedContainer: JSObject?

    private var lastAxes: Axis.Set = .vertical
    private var lastOptionCount: Int = 0

    func startIfNeeded() {
        guard !didStart else { return }
        didStart = true
        scheduleMeasure(force: true)
    }

    func updateConfig(axes: Axis.Set, optionCount: Int) {
        let configChanged = axes != lastAxes || optionCount != lastOptionCount
        lastAxes = axes
        lastOptionCount = optionCount

        if configChanged {
            scheduleMeasure(force: true)
        }
    }

    func scheduleMeasure(force: Bool) {
        #if arch(wasm32)
        // If we're already observing and this isn't a forced re-measure, do nothing.
        if !force, observedContainer != nil, resizeObserver != nil { return }

        // Avoid stacking RAF calls.
        guard rafClosure == nil else { return }

        let closure = JSClosure { [weak self] _ -> JSValue in
            guard let self else { return .undefined }
            self.rafClosure = nil
            self.measureAndObserveIfNeeded()
            return .undefined
        }
        rafClosure = closure

        if let raf = JSObject.global.requestAnimationFrame.function {
            _ = raf(closure)
        } else if let setTimeout = JSObject.global.setTimeout.function {
            _ = setTimeout(closure, 0)
        }
        #else
        _ = force
        #endif
    }

    private func measureAndObserveIfNeeded() {
        guard let document = JSObject.global.document.object else { return }

        // Find the container for this instance.
        //
        // Important: DOM methods like `document.querySelector` require a proper `this`
        // binding. Calling an unbound function triggers "Illegal invocation".
        let selector = "[data-raven-vtf-id=\"\(id)\"]"
        guard let querySelectorFn = document.querySelector.function else { return }
        let containerResult = querySelectorFn(this: document, selector)
        guard !containerResult.isNull, let container = containerResult.object else { return }

        if observedContainer == nil {
            observedContainer = container
            attachResizeObserverIfAvailable(to: container)
        }

        // Grab all option wrappers.
        let optionSelector = "\(selector) [data-raven-vtf-option]"
        guard let querySelectorAllFn = document.querySelectorAll.function else { return }
        let nodeListResult = querySelectorAllFn(this: document, optionSelector)
        let length = nodeListResult.length.number ?? 0
        var options: [JSObject] = []
        options.reserveCapacity(Int(length))
        for i in 0..<Int(length) {
            if let element = nodeListResult[i].object {
                options.append(element)
            }
        }
        guard !options.isEmpty else { return }

        // Prefer clientWidth/clientHeight because bounding rect width can be influenced
        // by layout, while scrollWidth/scrollHeight captures overflow content.
        let containerWidth = container.clientWidth.number ?? DOMBridge.shared.measureGeometry(element: container).size.width
        let containerHeight = container.clientHeight.number ?? DOMBridge.shared.measureGeometry(element: container).size.height

        // Pick the first option that fits; if none do, fall back to the last.
        var bestIndex = max(0, options.count - 1)

        for (idx, option) in options.enumerated() {
            // Use scroll size to detect overflow (e.g. wide HStack that doesn't wrap).
            let optionWidth = option.scrollWidth.number ?? DOMBridge.shared.measureGeometry(element: option).size.width
            let optionHeight = option.scrollHeight.number ?? DOMBridge.shared.measureGeometry(element: option).size.height

            let fitsHorizontally: Bool =
                !lastAxes.contains(.horizontal) || optionWidth <= containerWidth + 0.5
            let fitsVertically: Bool =
                !lastAxes.contains(.vertical) || optionHeight <= containerHeight + 0.5

            if fitsHorizontally && fitsVertically {
                bestIndex = idx
                break
            }
        }

        if bestIndex != selectedIndex {
            selectedIndex = bestIndex
            renderScheduler?.scheduleRender()
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

extension ViewThatFits: _CoordinatorRenderable {
    @MainActor public func _render(with context: any _RenderContext) -> VNode {
        let controller = context.persistentState(create: { ViewThatFitsController() })
        controller.renderScheduler = _RenderScheduler.current
        controller.startIfNeeded()

        let contentNode = context.renderChild(content)
        let options: [VNode]
        if case .fragment = contentNode.type {
            options = contentNode.children
        } else {
            options = [contentNode]
        }

        controller.updateConfig(axes: axes, optionCount: options.count)

        let selected = min(max(controller.selectedIndex, 0), max(0, options.count - 1))

        var props: [String: VProperty] = [
            "display": .style(name: "display", value: "block"),
            "position": .style(name: "position", value: "relative"),
            "min-width": .style(name: "min-width", value: "0"),
            "data-raven-vtf-id": .attribute(name: "data-raven-vtf-id", value: controller.id),
        ]

        // Make sure the container actually has a horizontal proposal when asked.
        if axes.contains(.horizontal) {
            props["width"] = .style(name: "width", value: "100%")
        }
        if axes.contains(.vertical) {
            props["height"] = .style(name: "height", value: "100%")
        }

        // Render each option exactly once.
        //
        // We keep non-selected options in the DOM (visibility:hidden) so we can measure
        // their scroll sizes, but we take them out of flow (position:absolute) so they
        // don't affect layout. This avoids duplicate VNode IDs (which can cause blank
        // output) while still allowing measurement.
        let children = options.enumerated().map { (idx, option) in
            let isSelected = idx == selected
            var optionProps: [String: VProperty] = [
                "display": .style(name: "display", value: "block"),
                "data-raven-vtf-option": .attribute(name: "data-raven-vtf-option", value: "\(idx)"),
                "pointer-events": .style(name: "pointer-events", value: isSelected ? "auto" : "none"),
                "visibility": .style(name: "visibility", value: isSelected ? "visible" : "hidden"),
            ]

            if isSelected {
                optionProps["position"] = .style(name: "position", value: "relative")
            } else {
                optionProps["position"] = .style(name: "position", value: "absolute")
                optionProps["top"] = .style(name: "top", value: "0")
                optionProps["left"] = .style(name: "left", value: "0")
            }

            return VNode.element("div", props: optionProps, children: [option])
        }

        return VNode.element("div", props: props, children: children)
    }
}

// MARK: - Helper Extensions

extension ViewThatFits {
    /// Helper to extract view options from TupleView content.
    ///
    /// This is used internally by the RenderCoordinator to get individual view options
    /// from the ViewBuilder result. The implementation needs to handle different tuple sizes.
    ///
    /// Note: This is a marker for the render system. Actual tuple extraction happens
    /// in the RenderCoordinator using reflection or type-specific handling.
    @MainActor internal func extractViewOptions() -> [Any] {
        // This will be implemented by the render coordinator
        // For now, return the content wrapped
        return [content]
    }
}

// MARK: - Supporting Types

/// Internal wrapper for ViewThatFits option handling.
///
/// This type is used by the RenderCoordinator to wrap each view option with
/// appropriate container query styling.
internal struct _ViewThatFitsOption<Content: View>: View, Sendable {
    typealias Body = Never

    let index: Int
    let isLast: Bool
    let content: Content

    @MainActor init(index: Int, isLast: Bool, content: Content) {
        self.index = index
        self.isLast = isLast
        self.content = content
    }

    @MainActor func toVNode() -> VNode {
        // Each option is wrapped in a container with specific visibility rules
        // The actual container query logic will be handled via CSS classes
        let props: [String: VProperty] = [
            "display": .style(name: "display", value: "block"),
            "data-fit-option": .attribute(name: "data-fit-option", value: "\(index)"),
            "data-fit-last": .attribute(name: "data-fit-last", value: isLast ? "true" : "false")
        ]

        return VNode.element(
            "div",
            props: props,
            children: []
        )
    }
}
