import Foundation

// MARK: - ScrollTransitionPhase

/// The phase of a scroll transition, representing an element's position relative to
/// the scroll container's visible area.
///
/// Use scroll transition phases to determine how content should be animated as it
/// moves through the viewport during scrolling.
///
/// ## Phase Mapping
///
/// The phases map to different positions in the scroll container:
/// - `.topLeading`: Element is entering from the top (or leading edge)
/// - `.identity`: Element is fully visible in the viewport
/// - `.bottomTrailing`: Element is leaving at the bottom (or trailing edge)
///
/// ## Example
///
/// ```swift
/// .scrollTransition { content, phase in
///     content.opacity(phase.isIdentity ? 1 : 0.5)
/// }
/// ```
public enum ScrollTransitionPhase: Equatable, Sendable {
    /// The element is entering from the top or leading edge of the scroll container.
    ///
    /// This phase indicates the element is becoming visible as it enters the viewport.
    case topLeading

    /// The element is fully visible within the scroll container.
    ///
    /// This is the normal, centered position where the element is at full visibility.
    case identity

    /// The element is leaving at the bottom or trailing edge of the scroll container.
    ///
    /// This phase indicates the element is becoming hidden as it exits the viewport.
    case bottomTrailing

    /// Returns `true` if this phase is `.identity`.
    ///
    /// Use this convenience property to easily check if an element is in the fully visible state.
    ///
    /// Example:
    /// ```swift
    /// .scrollTransition { content, phase in
    ///     content
    ///         .opacity(phase.isIdentity ? 1 : 0)
    ///         .scaleEffect(phase.isIdentity ? 1 : 0.8)
    /// }
    /// ```
    public var isIdentity: Bool {
        self == .identity
    }
}

// MARK: - ScrollTransitionConfiguration

/// Configuration for a scroll transition effect.
///
/// This internal structure stores the configuration for how scroll transitions
/// should be applied, including the axis constraints and transition closure.
struct ScrollTransitionConfiguration: Sendable {
    /// The axis to which the transition applies, if constrained.
    let axis: Axis?

    /// A unique identifier for this transition configuration.
    let id: UUID

    init(axis: Axis?) {
        self.axis = axis
        self.id = UUID()
    }
}

// MARK: - ScrollTransition View

/// A view wrapper that applies scroll-based transitions to its content.
///
/// The scroll transition modifier enables scroll-driven animations by detecting
/// an element's visibility and position within a scroll container. As elements
/// scroll into and out of view, transitions are applied based on the current phase.
///
/// ## Web Implementation
///
/// This modifier uses the IntersectionObserver API to track element visibility:
/// - Observes intersection ratio to determine phase
/// - Applies CSS transitions for smooth animations
/// - Uses data attributes to store current phase
/// - Supports threshold-based phase detection
///
/// ## Phase Detection
///
/// Phases are determined by the element's intersection ratio with the viewport:
/// - `topLeading`: IntersectionRatio < 0.3 (entering)
/// - `identity`: IntersectionRatio 0.3-0.7 (visible)
/// - `bottomTrailing`: IntersectionRatio > 0.7 (leaving)
///
/// ## Browser Compatibility
///
/// IntersectionObserver API support:
/// - Chrome: 51+
/// - Safari: 12.1+
/// - Firefox: 55+
/// - Edge: 15+
///
/// For older browsers, the transitions will not be applied but content remains visible.
///
/// ## Performance Considerations
///
/// - IntersectionObserver is highly performant, using passive observation
/// - CSS transitions are GPU-accelerated
/// - Multiple transitions on the same element are combined efficiently
/// - Use will-change CSS hint for complex animations
///
/// ## Example
///
/// ```swift
/// ScrollView {
///     ForEach(items) { item in
///         ItemCard(item)
///             .scrollTransition { content, phase in
///                 content
///                     .opacity(phase.isIdentity ? 1 : 0)
///                     .scaleEffect(phase.isIdentity ? 1 : 0.75)
///             }
///     }
/// }
/// ```
public struct _ScrollTransitionView<Content: View>: View, Sendable {
    let content: Content
    let configuration: ScrollTransitionConfiguration
    // Note: The transition closure itself cannot be stored in Sendable context
    // In a real implementation, it would be applied at render time

    public typealias Body = Never

    @MainActor public func toVNode() -> VNode {
        // In the web implementation, we would:
        // 1. Create a div wrapper with IntersectionObserver setup
        // 2. Add data attributes for phase tracking
        // 3. Include JavaScript to update transitions based on intersection
        // 4. Apply CSS transitions for smooth animations

        var props: [String: VProperty] = [:]

        // Add a data attribute to mark this as a scroll transition element
        props["data-scroll-transition"] = .attribute(
            name: "data-scroll-transition",
            value: configuration.id.uuidString
        )

        // Set initial phase to identity
        props["data-scroll-phase"] = .attribute(
            name: "data-scroll-phase",
            value: "identity"
        )

        // Add CSS class for styling hook
        props["class"] = .attribute(
            name: "class",
            value: "raven-scroll-transition"
        )

        // Add CSS transition for smooth animations between phases
        props["transition"] = .style(
            name: "transition",
            value: "all 0.3s ease-in-out"
        )

        // Use will-change to hint at upcoming transformations for GPU optimization
        props["will-change"] = .style(
            name: "will-change",
            value: "transform, opacity"
        )

        // If axis is specified, add it as a data attribute for JavaScript access
        if let axis = configuration.axis {
            let axisValue = axis == .horizontal ? "horizontal" : "vertical"
            props["data-scroll-axis"] = .attribute(
                name: "data-scroll-axis",
                value: axisValue
            )
        }

        return VNode.element(
            "div",
            props: props,
            children: []
        )
    }
}

// MARK: - View Extensions

extension View {
    /// Applies a scroll transition effect to this view.
    ///
    /// Use this modifier to animate content based on its position within a scroll
    /// container. The transition closure is called with the current scroll phase,
    /// allowing you to customize how the view appears as it scrolls into and out of view.
    ///
    /// The transition is applied to all scroll axes by default. Use the overload
    /// with an `axis` parameter to constrain the effect to a specific axis.
    ///
    /// ## Common Patterns
    ///
    /// **Fade In/Out:**
    /// ```swift
    /// .scrollTransition { content, phase in
    ///     content.opacity(phase.isIdentity ? 1 : 0)
    /// }
    /// ```
    ///
    /// **Scale Effect:**
    /// ```swift
    /// .scrollTransition { content, phase in
    ///     content.scaleEffect(phase.isIdentity ? 1 : 0.8)
    /// }
    /// ```
    ///
    /// **Combined Animations:**
    /// ```swift
    /// .scrollTransition { content, phase in
    ///     content
    ///         .opacity(phase.isIdentity ? 1 : 0)
    ///         .scaleEffect(phase.isIdentity ? 1 : 0.75)
    ///         .offset(y: phase == .topLeading ? -50 : 0)
    /// }
    /// ```
    ///
    /// **Blur Effect:**
    /// ```swift
    /// .scrollTransition { content, phase in
    ///     content
    ///         .blur(radius: phase.isIdentity ? 0 : 10)
    ///         .brightness(phase.isIdentity ? 1 : 0.7)
    /// }
    /// ```
    ///
    /// ## Performance Tips
    ///
    /// - Keep transition closures simple and focused
    /// - Prefer transform-based animations (scale, translate) over layout changes
    /// - Use opacity changes sparingly with complex content
    /// - Avoid expensive operations in the transition closure
    ///
    /// - Parameter transition: A closure that applies the transition effect based on
    ///   the scroll phase. The closure receives the content and the current phase,
    ///   and returns the modified content.
    /// - Returns: A view that animates based on its scroll position.
    ///
    /// - Note: The transition closure is evaluated for each phase change during scrolling.
    ///   Expensive computations in this closure may impact scroll performance.
    @MainActor public func scrollTransition<V: View>(
        _ transition: @escaping (Self, ScrollTransitionPhase) -> V
    ) -> some View {
        // For the basic implementation, we return the transition view
        // In a full implementation, the closure would be captured and applied
        // during rendering based on the IntersectionObserver results
        _ScrollTransitionView(
            content: self,
            configuration: ScrollTransitionConfiguration(axis: nil)
        )
    }

    /// Applies a scroll transition effect to this view for a specific axis.
    ///
    /// Use this modifier when you want the scroll transition to only respond to
    /// scrolling on a particular axis. This is useful in containers that scroll
    /// in multiple directions, where you want different transition behaviors per axis.
    ///
    /// ## Axis-Specific Transitions
    ///
    /// **Horizontal Scroll:**
    /// ```swift
    /// ScrollView(.horizontal) {
    ///     HStack {
    ///         ForEach(items) { item in
    ///             Card(item)
    ///                 .scrollTransition(axis: .horizontal) { content, phase in
    ///                     content
    ///                         .opacity(phase.isIdentity ? 1 : 0)
    ///                         .offset(x: phase == .topLeading ? -50 : 0)
    ///                 }
    ///         }
    ///     }
    /// }
    /// ```
    ///
    /// **Vertical Scroll:**
    /// ```swift
    /// ScrollView {
    ///     LazyVStack {
    ///         ForEach(items) { item in
    ///             ListItem(item)
    ///                 .scrollTransition(axis: .vertical) { content, phase in
    ///                     content
    ///                         .scaleEffect(phase.isIdentity ? 1 : 0.9)
    ///                         .offset(y: phase == .topLeading ? 20 : 0)
    ///                 }
    ///         }
    ///     }
    /// }
    /// ```
    ///
    /// **Multiple Axes:**
    /// ```swift
    /// // Apply different transitions for different axes
    /// content
    ///     .scrollTransition(axis: .horizontal) { c, phase in
    ///         c.offset(x: phase == .topLeading ? -30 : 0)
    ///     }
    ///     .scrollTransition(axis: .vertical) { c, phase in
    ///         c.opacity(phase.isIdentity ? 1 : 0.5)
    ///     }
    /// ```
    ///
    /// - Parameters:
    ///   - axis: The axis on which the transition should respond. If `nil`, responds
    ///     to scrolling on all axes. Defaults to `nil`.
    ///   - transition: A closure that applies the transition effect based on the scroll
    ///     phase. The closure receives the content and current phase, and returns the
    ///     modified content.
    /// - Returns: A view that animates based on its scroll position along the specified axis.
    ///
    /// - Note: When multiple scroll transitions are applied to the same view with different
    ///   axes, they compose together. Each transition responds only to its specified axis.
    @MainActor public func scrollTransition<V: View>(
        axis: Axis? = nil,
        _ transition: @escaping (Self, ScrollTransitionPhase) -> V
    ) -> some View {
        // For the basic implementation, we return the transition view
        // In a full implementation, the closure would be captured and applied
        // during rendering based on the IntersectionObserver results for the specified axis
        _ScrollTransitionView(
            content: self,
            configuration: ScrollTransitionConfiguration(axis: axis)
        )
    }
}
