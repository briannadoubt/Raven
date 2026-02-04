import Foundation

/// A scrollable view that allows content larger than its container to be viewed.
///
/// `ScrollView` is a container view that provides scrolling functionality for content
/// that exceeds the available display area. It supports both horizontal and vertical
/// scrolling, individually or simultaneously.
///
/// ## Overview
///
/// Use `ScrollView` when you need to display content that might not fit within the
/// available screen space. Unlike `List`, which is optimized for vertical lists of
/// data, `ScrollView` is a general-purpose scrolling container suitable for any
/// content layout.
///
/// ## Basic Usage
///
/// Create a simple vertical scroll view:
///
/// ```swift
/// ScrollView {
///     VStack(spacing: 20) {
///         ForEach(0..<100) { index in
///             Text("Item \(index)")
///         }
///     }
/// }
/// ```
///
/// ## Scrolling Directions
///
/// Control which axes allow scrolling:
///
/// ```swift
/// // Vertical scrolling (default)
/// ScrollView(.vertical) {
///     VStack {
///         // Tall content
///     }
/// }
///
/// // Horizontal scrolling
/// ScrollView(.horizontal) {
///     HStack {
///         // Wide content
///     }
/// }
///
/// // Both directions
/// ScrollView([.horizontal, .vertical]) {
///     // Content that scrolls both ways
/// }
/// ```
///
/// ## Scroll Indicators
///
/// Show or hide scroll indicators:
///
/// ```swift
/// // With indicators (default)
/// ScrollView {
///     content
/// }
///
/// // Without indicators
/// ScrollView(showsIndicators: false) {
///     content
/// }
/// ```
///
/// ## Common Patterns
///
/// **Long-form content:**
/// ```swift
/// ScrollView {
///     VStack(alignment: .leading, spacing: 16) {
///         Text("Article Title")
///             .font(.title)
///         Text("Long article content...")
///             .font(.body)
///         Image("hero")
///         Text("More content...")
///     }
///     .padding()
/// }
/// ```
///
/// **Horizontal gallery:**
/// ```swift
/// ScrollView(.horizontal, showsIndicators: false) {
///     HStack(spacing: 12) {
///         ForEach(images) { image in
///             Image(image.name)
///                 .frame(width: 200, height: 150)
///         }
///     }
///     .padding()
/// }
/// ```
///
/// **Grid of content:**
/// ```swift
/// ScrollView {
///     LazyVGrid(columns: [
///         GridItem(.adaptive(minimum: 150))
///     ]) {
///         ForEach(items) { item in
///             ItemCard(item: item)
///         }
///     }
///     .padding()
/// }
/// ```
///
/// ## Performance Considerations
///
/// For large lists of similar items, consider using `List` instead of `ScrollView`
/// with a `VStack`, as `List` provides better performance optimizations. For grids
/// of data, use `LazyVGrid` or `LazyHGrid` inside a `ScrollView` for lazy loading.
///
/// ## Accessibility
///
/// ScrollView automatically provides appropriate ARIA attributes for accessibility.
/// The scrollable region is properly marked for screen readers and keyboard navigation.
///
/// ## See Also
///
/// - ``List``
/// - ``LazyVStack``
/// - ``LazyHStack``
/// - ``LazyVGrid``
/// - ``LazyHGrid``
///
/// - Parameters:
///   - axes: The scrollable axes of the scroll view. Defaults to `.vertical`.
///   - showsIndicators: Whether to show scroll indicators. Defaults to `true`.
///   - content: A view builder that creates the scrollable content.
public struct ScrollView<Content: View>: View, PrimitiveView, Sendable {
    public typealias Body = Never

    /// The scrollable axes
    let axes: Axis.Set

    /// Whether to show scroll indicators
    let showsIndicators: Bool

    /// The scrollable content
    let content: Content

    // MARK: - Initializers

    /// Creates a scroll view with configurable axes and indicator visibility.
    ///
    /// - Parameters:
    ///   - axes: The scrollable axes of the scroll view. Defaults to `.vertical`.
    ///   - showsIndicators: Whether to show scroll indicators. Defaults to `true`.
    ///   - content: A view builder that creates the scrollable content.
    ///
    /// Example:
    /// ```swift
    /// ScrollView(.vertical, showsIndicators: true) {
    ///     VStack {
    ///         ForEach(items) { item in
    ///             ItemView(item: item)
    ///         }
    ///     }
    /// }
    /// ```
    @MainActor public init(
        _ axes: Axis.Set = .vertical,
        showsIndicators: Bool = true,
        @ViewBuilder content: () -> Content
    ) {
        self.axes = axes
        self.showsIndicators = showsIndicators
        self.content = content()
    }

    // MARK: - VNode Conversion

    /// Converts this ScrollView to a virtual DOM node.
    ///
    /// The ScrollView is rendered as a `div` element with:
    /// - `display: block` for proper layout
    /// - `overflow-y: auto` for vertical scrolling (when enabled)
    /// - `overflow-x: auto` for horizontal scrolling (when enabled)
    /// - `scrollbar-width: none` to hide scrollbars (when showsIndicators is false)
    /// - WebKit-specific styles for hiding scrollbars in Safari/Chrome
    /// - `role="region"` for accessibility
    /// - `class="raven-scroll-view"` for styling
    ///
    /// The overflow behavior is set based on the axes parameter:
    /// - If an axis is included in `axes`, its overflow is set to `auto`
    /// - Otherwise, it's set to `visible` to allow natural layout
    ///
    /// Note: The children are not converted here. The RenderCoordinator
    /// will handle rendering the content by accessing the `content` property.
    ///
    /// - Returns: A VNode configured as a scrollable container with ARIA attributes.
    @MainActor public func toVNode() -> VNode {
        var props: [String: VProperty] = [
            // ARIA role for accessibility
            "role": .attribute(name: "role", value: "region"),

            // CSS class for custom styling
            "class": .attribute(name: "class", value: "raven-scroll-view"),

            // Layout styles
            "display": .style(name: "display", value: "block"),

            // Overflow behavior based on axes
            "overflow-y": .style(
                name: "overflow-y",
                value: axes.contains(.vertical) ? "auto" : "visible"
            ),
            "overflow-x": .style(
                name: "overflow-x",
                value: axes.contains(.horizontal) ? "auto" : "visible"
            ),

            // Default sizing
            "width": .style(name: "width", value: "100%"),
            "height": .style(name: "height", value: "100%"),
        ]

        // Hide scroll indicators if requested
        if !showsIndicators {
            // Standard property for Firefox
            props["scrollbar-width"] = .style(name: "scrollbar-width", value: "none")

            // For WebKit browsers (Safari, Chrome), we need to use a pseudo-element
            // This is handled via CSS class styling rather than inline styles
            // The CSS would look like:
            // .raven-scroll-view.hide-scrollbars::-webkit-scrollbar { display: none; }
            if let existingClass = props["class"] {
                if case .attribute(let name, let value) = existingClass {
                    props["class"] = .attribute(name: name, value: "\(value) hide-scrollbars")
                }
            }

            // Also set -ms-overflow-style for IE/Edge
            props["-ms-overflow-style"] = .style(name: "-ms-overflow-style", value: "none")
        }

        // Return element with empty children - the RenderCoordinator will populate them
        return VNode.element(
            "div",
            props: props,
            children: []
        )
    }
}
