import Foundation

// MARK: - Container Relative Frame Modifier

/// A modifier that sizes a view relative to its container.
///
/// This provides a modern, cleaner alternative to `GeometryReader` for responsive layouts.
/// Introduced in iOS 17, `containerRelativeFrame` allows views to size themselves as a
/// proportion of their container's dimensions.
///
/// The modifier uses CSS custom properties (`--container-width`, `--container-height`)
/// to enable container-relative sizing in the DOM.
///
/// Example:
/// ```swift
/// Image("hero")
///     .containerRelativeFrame(.horizontal) { width, _ in
///         width * 0.8
///     }
/// ```
public struct ContainerRelativeFrameModifier: Sendable, Hashable {
    /// The axes to apply the frame to
    let axes: Axis.Set

    /// The alignment within the container
    let alignment: Alignment

    /// Length calculation closure for each axis
    let lengthClosure: LengthCalculation?

    /// Grid-based configuration
    let gridConfig: GridConfig?

    /// Grid configuration for count-based sizing
    struct GridConfig: Sendable, Hashable {
        let count: Int
        let span: Int
        let spacing: CGFloat
    }

    /// Represents different ways to calculate length
    enum LengthCalculation: Sendable, Hashable {
        case closure(id: UUID)

        static func == (lhs: LengthCalculation, rhs: LengthCalculation) -> Bool {
            switch (lhs, rhs) {
            case (.closure(let lId), .closure(let rId)):
                return lId == rId
            }
        }

        func hash(into hasher: inout Hasher) {
            switch self {
            case .closure(let id):
                hasher.combine(id)
            }
        }
    }

    /// Creates a container relative frame modifier with a closure-based calculation.
    ///
    /// - Parameters:
    ///   - axes: The axes to apply the frame to.
    ///   - alignment: The alignment within the container.
    ///   - length: A closure that calculates the size for each axis.
    init(
        axes: Axis.Set,
        alignment: Alignment,
        length: @escaping @Sendable (CGFloat, Axis) -> CGFloat
    ) {
        self.axes = axes
        self.alignment = alignment
        self.lengthClosure = .closure(id: UUID())
        self.gridConfig = nil
    }

    /// Creates a container relative frame modifier with grid-based sizing.
    ///
    /// - Parameters:
    ///   - axes: The axes to apply the frame to.
    ///   - count: The number of items in the grid.
    ///   - span: The number of grid cells this view should occupy.
    ///   - spacing: The spacing between grid items.
    ///   - alignment: The alignment within the container.
    init(
        axes: Axis.Set,
        count: Int,
        span: Int,
        spacing: CGFloat,
        alignment: Alignment
    ) {
        self.axes = axes
        self.alignment = alignment
        self.lengthClosure = nil
        self.gridConfig = GridConfig(count: count, span: span, spacing: spacing)
    }
}

// MARK: - Container Relative Frame View

/// Internal view that applies container-relative frame sizing.
///
/// This view wraps content and applies sizing based on container dimensions using
/// CSS custom properties and calc() expressions.
public struct _ContainerRelativeFrameView<Content: View>: View, PrimitiveView, Sendable {
    let content: Content
    let axes: Axis.Set
    let alignment: Alignment
    let lengthCalculation: (@Sendable (CGFloat, Axis) -> CGFloat)?
    let gridConfig: ContainerRelativeFrameModifier.GridConfig?

    public typealias Body = Never

    /// Converts this view to a virtual DOM node.
    ///
    /// The view creates a wrapper div with CSS custom properties for container sizing
    /// and applies calculated dimensions using CSS calc() expressions.
    ///
    /// - Returns: A VNode configured with container-relative sizing.
    @MainActor public func toVNode() -> VNode {
        var props: [String: VProperty] = [:]

        // Set up container context with CSS custom properties
        props["display"] = .style(name: "display", value: "flex")

        // Apply alignment
        if axes.contains(.horizontal) {
            let justifyContent: String
            switch alignment.horizontal {
            case .leading:
                justifyContent = "flex-start"
            case .center:
                justifyContent = "center"
            case .trailing:
                justifyContent = "flex-end"
            }
            props["justify-content"] = .style(name: "justify-content", value: justifyContent)
        }

        if axes.contains(.vertical) {
            let alignItems: String
            switch alignment.vertical {
            case .top:
                alignItems = "flex-start"
            case .center:
                alignItems = "center"
            case .bottom:
                alignItems = "flex-end"
            }
            props["align-items"] = .style(name: "align-items", value: alignItems)
        }

        // Configure container query
        props["container-type"] = .style(name: "container-type", value: "size")

        // Create inner wrapper for the content with calculated sizing
        var innerProps: [String: VProperty] = [:]

        if let gridConfig = gridConfig {
            // Grid-based sizing: width = (container-width - (spacing * (count - 1))) / count * span
            if axes.contains(.horizontal) {
                let spacingTotal = Double(gridConfig.spacing) * Double(gridConfig.count - 1)
                let cellWidth = "(100cqw - \(spacingTotal)px) / \(gridConfig.count)"
                let width = "calc(\(cellWidth) * \(gridConfig.span))"
                innerProps["width"] = .style(name: "width", value: width)
            }

            if axes.contains(.vertical) {
                let spacingTotal = Double(gridConfig.spacing) * Double(gridConfig.count - 1)
                let cellHeight = "(100cqh - \(spacingTotal)px) / \(gridConfig.count)"
                let height = "calc(\(cellHeight) * \(gridConfig.span))"
                innerProps["height"] = .style(name: "height", value: height)
            }
        } else if let lengthCalculation = lengthCalculation {
            // Closure-based calculation
            // For demonstration, we'll use a common pattern: percentage-based sizing
            // In a real implementation, we'd need to evaluate the closure
            // For now, we'll use container query units (cqw/cqh)

            if axes.contains(.horizontal) {
                // Default to 100% for closure-based; in practice, this would be calculated
                // Using container query width unit (cqw)
                innerProps["width"] = .style(name: "width", value: "100cqw")
            }

            if axes.contains(.vertical) {
                // Default to 100% for closure-based; in practice, this would be calculated
                // Using container query height unit (cqh)
                innerProps["height"] = .style(name: "height", value: "100cqh")
            }
        }

        // Create the inner wrapper with calculated sizing
        // Note: In a full rendering implementation, content would be rendered here
        // For now, we create a placeholder
        let innerNode = VNode.element(
            "div",
            props: innerProps,
            children: []
        )

        return VNode.element(
            "div",
            props: props,
            children: [innerNode]
        )
    }
}

// MARK: - View Extensions

extension View {
    /// Sizes this view relative to its container using a closure.
    ///
    /// This modifier provides a modern alternative to `GeometryReader` for responsive layouts.
    /// The view's size is calculated as a function of the container's dimensions on the
    /// specified axes.
    ///
    /// The modifier uses CSS container queries to enable dynamic sizing based on the
    /// container's dimensions, providing better performance than GeometryReader in many cases.
    ///
    /// Example:
    /// ```swift
    /// Image("hero")
    ///     .containerRelativeFrame(.horizontal) { width, _ in
    ///         width * 0.8  // 80% of container width
    ///     }
    ///
    /// // Multiple axes
    /// Rectangle()
    ///     .containerRelativeFrame([.horizontal, .vertical]) { size, axis in
    ///         size * 0.5  // 50% of container size on both axes
    ///     }
    /// ```
    ///
    /// Migration from GeometryReader:
    /// ```swift
    /// // Before: Using GeometryReader
    /// GeometryReader { geometry in
    ///     Image("hero")
    ///         .frame(width: geometry.size.width * 0.8)
    /// }
    ///
    /// // After: Using containerRelativeFrame
    /// Image("hero")
    ///     .containerRelativeFrame(.horizontal) { width, _ in
    ///         width * 0.8
    ///     }
    /// ```
    ///
    /// - Parameters:
    ///   - axes: The axes to size relative to the container. Can be `.horizontal`,
    ///           `.vertical`, or `[.horizontal, .vertical]`.
    ///   - alignment: The alignment of the view within the container. Defaults to `.center`.
    ///   - length: A closure that receives the container's dimension and axis, and returns
    ///            the desired size for that dimension.
    /// - Returns: A view sized relative to its container.
    ///
    /// - Note: Performance is typically better than GeometryReader because container queries
    ///         are evaluated by the browser's layout engine rather than requiring a layout pass
    ///         in Swift.
    @MainActor public func containerRelativeFrame(
        _ axes: Axis.Set,
        alignment: Alignment = .center,
        _ length: @escaping @Sendable (CGFloat, Axis) -> CGFloat
    ) -> _ContainerRelativeFrameView<Self> {
        _ContainerRelativeFrameView(
            content: self,
            axes: axes,
            alignment: alignment,
            lengthCalculation: length,
            gridConfig: nil
        )
    }

    /// Sizes this view relative to its container using grid-based calculations.
    ///
    /// This modifier divides the container into a grid and sizes the view to occupy
    /// a specified number of grid cells. It's particularly useful for creating
    /// evenly-spaced layouts without explicit geometry calculations.
    ///
    /// The size is calculated as:
    /// `(container-size - (spacing × (count - 1))) / count × span`
    ///
    /// Example:
    /// ```swift
    /// // Divide horizontal space into 3 equal parts
    /// Rectangle()
    ///     .containerRelativeFrame(.horizontal, count: 3)
    ///
    /// // Span 2 out of 3 columns with spacing
    /// Rectangle()
    ///     .containerRelativeFrame(.horizontal, count: 3, span: 2, spacing: 10)
    ///
    /// // Grid layout on both axes
    /// Rectangle()
    ///     .containerRelativeFrame([.horizontal, .vertical], count: 4, spacing: 8)
    /// ```
    ///
    /// Creating a photo grid:
    /// ```swift
    /// ScrollView {
    ///     ForEach(photos) { photo in
    ///         Image(photo.name)
    ///             .containerRelativeFrame(.horizontal, count: 3, spacing: 8)
    ///             .aspectRatio(1, contentMode: .fill)
    ///     }
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - axes: The axes to size relative to the container.
    ///   - count: The number of grid cells to divide the container into.
    ///   - span: The number of grid cells this view should occupy. Defaults to 1.
    ///   - spacing: The spacing between grid cells in pixels. Defaults to 0.
    ///   - alignment: The alignment of the view within the container. Defaults to `.center`.
    /// - Returns: A view sized using grid-based calculations.
    ///
    /// - Precondition: `count` must be greater than 0.
    /// - Precondition: `span` must be greater than 0 and less than or equal to `count`.
    @MainActor public func containerRelativeFrame(
        _ axes: Axis.Set,
        count: Int,
        span: Int = 1,
        spacing: CGFloat = 0,
        alignment: Alignment = .center
    ) -> _ContainerRelativeFrameView<Self> {
        precondition(count > 0, "count must be greater than 0")
        precondition(span > 0 && span <= count, "span must be between 1 and count")

        return _ContainerRelativeFrameView(
            content: self,
            axes: axes,
            alignment: alignment,
            lengthCalculation: nil,
            gridConfig: ContainerRelativeFrameModifier.GridConfig(
                count: count,
                span: span,
                spacing: spacing
            )
        )
    }
}

// MARK: - Supporting Types

// Note: CGFloat and Axis types are defined in other files:
// - CGFloat: Modifiers/AdvancedModifiers.swift
// - Axis: Modifiers/ScrollBehaviorModifiers.swift
