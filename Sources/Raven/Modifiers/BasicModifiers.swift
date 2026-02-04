import Foundation

// MARK: - Padding Modifier

/// A modifier that adds padding around a view.
///
/// Padding adds space between a view's content and its edges.
/// It can be applied uniformly to all edges or to specific edges.
public struct PaddingModifier: BasicViewModifier, Sendable {
    /// The amount of padding on each edge
    let edges: EdgeInsets

    /// Creates a padding modifier with uniform padding on all edges.
    ///
    /// - Parameter value: The amount of padding in pixels.
    init(_ value: Double) {
        self.edges = EdgeInsets(top: value, leading: value, bottom: value, trailing: value)
    }

    /// Creates a padding modifier with specific edge insets.
    ///
    /// - Parameter edges: The edge insets specifying padding for each edge.
    init(_ edges: EdgeInsets) {
        self.edges = edges
    }
}

/// Internal view that applies padding by wrapping content in a div with padding styles.
public struct _PaddingView<Content: View>: View, Sendable {
    let content: Content
    let padding: EdgeInsets

    public typealias Body = Never

    @MainActor public func toVNode() -> VNode {
        var props: [String: VProperty] = [:]

        // Add padding styles
        if padding.top == padding.leading && padding.leading == padding.bottom && padding.bottom == padding.trailing {
            // Uniform padding
            props["padding"] = .style(name: "padding", value: "\(padding.top)px")
        } else {
            // Individual edge padding
            props["padding-top"] = .style(name: "padding-top", value: "\(padding.top)px")
            props["padding-right"] = .style(name: "padding-right", value: "\(padding.trailing)px")
            props["padding-bottom"] = .style(name: "padding-bottom", value: "\(padding.bottom)px")
            props["padding-left"] = .style(name: "padding-left", value: "\(padding.leading)px")
        }

        return VNode.element(
            "div",
            props: props,
            children: []
        )
    }
}

// MARK: - Frame Modifier

/// A modifier that sets the size of a view.
///
/// The frame modifier constrains a view's dimensions using CSS width and height.
public struct FrameModifier: BasicViewModifier, Sendable {
    /// The width of the frame
    let width: Double?

    /// The height of the frame
    let height: Double?

    /// Creates a frame modifier with optional width and height.
    ///
    /// - Parameters:
    ///   - width: The width in pixels. Pass `nil` to leave unconstrained.
    ///   - height: The height in pixels. Pass `nil` to leave unconstrained.
    init(width: Double? = nil, height: Double? = nil) {
        self.width = width
        self.height = height
    }
}

/// Internal view that applies frame sizing by wrapping content in a div with size styles.
public struct _FrameView<Content: View>: View, Sendable {
    let content: Content
    let width: Double?
    let height: Double?

    public typealias Body = Never

    @MainActor public func toVNode() -> VNode {
        var props: [String: VProperty] = [:]

        // Add size styles
        if let width = width {
            props["width"] = .style(name: "width", value: "\(width)px")
        }

        if let height = height {
            props["height"] = .style(name: "height", value: "\(height)px")
        }

        return VNode.element(
            "div",
            props: props,
            children: []
        )
    }
}

// MARK: - Foreground Color Modifier

/// A modifier that sets the foreground color of a view.
///
/// The foreground color affects text and other content that respects the CSS `color` property.
public struct ForegroundColorModifier: BasicViewModifier, Sendable {
    /// The color to apply
    let color: Color

    /// Creates a foreground color modifier.
    ///
    /// - Parameter color: The color to apply to the view's foreground.
    init(_ color: Color) {
        self.color = color
    }
}

/// Internal view that applies foreground color by wrapping content in a div with color style.
public struct _ForegroundColorView<Content: View>: View, Sendable {
    let content: Content
    let color: Color

    public typealias Body = Never

    @MainActor public func toVNode() -> VNode {
        VNode.element(
            "div",
            props: [
                "color": .style(name: "color", value: color.cssValue)
            ],
            children: []
        )
    }
}

// MARK: - Edge Insets

/// The inset distances for the edges of a rectangle.
///
/// Use edge insets to specify padding or margins on specific edges of a view.
public struct EdgeInsets: Sendable, Hashable {
    /// The inset from the top edge
    public let top: Double

    /// The inset from the leading edge (left in LTR, right in RTL)
    public let leading: Double

    /// The inset from the bottom edge
    public let bottom: Double

    /// The inset from the trailing edge (right in LTR, left in RTL)
    public let trailing: Double

    /// Creates edge insets with specific values for each edge.
    ///
    /// - Parameters:
    ///   - top: The inset from the top edge.
    ///   - leading: The inset from the leading edge.
    ///   - bottom: The inset from the bottom edge.
    ///   - trailing: The inset from the trailing edge.
    public init(top: Double, leading: Double, bottom: Double, trailing: Double) {
        self.top = top
        self.leading = leading
        self.bottom = bottom
        self.trailing = trailing
    }

    /// Creates edge insets with the same value for all edges.
    ///
    /// - Parameter value: The inset for all edges.
    public init(_ value: Double) {
        self.top = value
        self.leading = value
        self.bottom = value
        self.trailing = value
    }
}

// MARK: - View Extensions

extension View {
    /// Adds padding around this view.
    ///
    /// Use this method to add space between the view's content and its edges.
    ///
    /// Example:
    /// ```swift
    /// Text("Hello")
    ///     .padding()      // Adds default padding (8px)
    ///     .padding(16)    // Adds 16px padding on all sides
    /// ```
    ///
    /// - Parameter value: The amount of padding in pixels. Defaults to 8.
    /// - Returns: A view with padding applied.
    @MainActor public func padding(_ value: Double = 8) -> _PaddingView<Self> {
        _PaddingView(content: self, padding: EdgeInsets(value))
    }

    /// Adds specific padding to specified edges.
    ///
    /// Use this method to add different amounts of padding to different edges.
    ///
    /// Example:
    /// ```swift
    /// Text("Hello")
    ///     .padding(EdgeInsets(top: 10, leading: 20, bottom: 10, trailing: 20))
    /// ```
    ///
    /// - Parameter edges: The edge insets specifying padding for each edge.
    /// - Returns: A view with padding applied.
    @MainActor public func padding(_ edges: EdgeInsets) -> _PaddingView<Self> {
        _PaddingView(content: self, padding: edges)
    }

    /// Sets the size of this view.
    ///
    /// Use this method to constrain the view's width and/or height.
    ///
    /// Example:
    /// ```swift
    /// Text("Hello")
    ///     .frame(width: 100, height: 50)
    /// ```
    ///
    /// - Parameters:
    ///   - width: The width in pixels. Pass `nil` to leave unconstrained.
    ///   - height: The height in pixels. Pass `nil` to leave unconstrained.
    /// - Returns: A view with the specified frame.
    @MainActor public func frame(width: Double? = nil, height: Double? = nil) -> _FrameView<Self> {
        _FrameView(content: self, width: width, height: height)
    }

    /// Sets the foreground color of this view.
    ///
    /// The foreground color affects text and other content that respects the CSS `color` property.
    ///
    /// Example:
    /// ```swift
    /// Text("Hello")
    ///     .foregroundColor(.blue)
    /// ```
    ///
    /// - Parameter color: The color to apply to the view's foreground.
    /// - Returns: A view with the specified foreground color.
    @MainActor public func foregroundColor(_ color: Color) -> _ForegroundColorView<Self> {
        _ForegroundColorView(content: self, color: color)
    }
}
