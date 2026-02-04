import Foundation

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
