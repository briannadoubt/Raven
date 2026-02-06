import Foundation

// MARK: - Text Alignment

/// Horizontal text alignment for multiline text.
///
/// Used by text modifiers to control how lines of text are aligned horizontally
/// within their container.
public enum TextAlignment: Sendable, Hashable {
    /// Align text to the leading edge (left in LTR, right in RTL).
    case leading

    /// Center-align text.
    case center

    /// Align text to the trailing edge (right in LTR, left in RTL).
    case trailing

    /// Convert to CSS text-align value.
    internal var cssValue: String {
        switch self {
        case .leading:
            return "left"
        case .center:
            return "center"
        case .trailing:
            return "right"
        }
    }
}

// MARK: - Truncation Mode

/// The truncation mode for text that doesn't fit in the available space.
///
/// Used by text modifiers to control where ellipsis appears when text is truncated.
public enum TruncationMode: Sendable, Hashable {
    /// Truncate at the head (beginning) of the text.
    case head

    /// Truncate at the tail (end) of the text.
    case tail

    /// Truncate in the middle of the text.
    case middle
}

// MARK: - Line Limit Modifier

/// A view wrapper that limits the number of lines for text.
///
/// The line limit is rendered using CSS -webkit-line-clamp with display: -webkit-box.
public struct _LineLimitView<Content: View>: View, PrimitiveView, Sendable {
    let content: Content
    let lineLimit: Int?

    public typealias Body = Never

    @MainActor public func toVNode() -> VNode {
        var props: [String: VProperty] = [:]

        if let limit = lineLimit {
            // Use -webkit-line-clamp for limiting lines
            props["display"] = .style(name: "display", value: "-webkit-box")
            props["-webkit-line-clamp"] = .style(name: "-webkit-line-clamp", value: "\(limit)")
            props["-webkit-box-orient"] = .style(name: "-webkit-box-orient", value: "vertical")
            props["overflow"] = .style(name: "overflow", value: "hidden")
        }

        return VNode.element(
            "div",
            props: props,
            children: []
        )
    }
}

// MARK: - Multiline Text Alignment Modifier

/// A view wrapper that sets text alignment for multiline text.
///
/// The text alignment is rendered using CSS text-align property.
public struct _MultilineTextAlignmentView<Content: View>: View, PrimitiveView, Sendable {
    let content: Content
    let alignment: TextAlignment

    public typealias Body = Never

    @MainActor public func toVNode() -> VNode {
        VNode.element(
            "div",
            props: [
                "text-align": .style(name: "text-align", value: alignment.cssValue)
            ],
            children: []
        )
    }
}

// MARK: - Truncation Mode Modifier

/// A view wrapper that sets the truncation mode for text.
///
/// The truncation mode is rendered using CSS text-overflow, overflow, and direction properties.
public struct _TruncationModeView<Content: View>: View, PrimitiveView, Sendable {
    let content: Content
    let mode: TruncationMode

    public typealias Body = Never

    @MainActor public func toVNode() -> VNode {
        var props: [String: VProperty] = [
            "overflow": .style(name: "overflow", value: "hidden"),
            "white-space": .style(name: "white-space", value: "nowrap"),
            "text-overflow": .style(name: "text-overflow", value: "ellipsis")
        ]

        // For head truncation, we need to reverse the text direction
        switch mode {
        case .head:
            props["direction"] = .style(name: "direction", value: "rtl")
            props["text-align"] = .style(name: "text-align", value: "right")
        case .tail:
            // Default behavior with text-overflow: ellipsis
            break
        case .middle:
            // Middle truncation requires a more complex approach
            // We'll use a data attribute to mark this for JS enhancement
            props["data-truncation"] = .attribute(name: "data-truncation", value: "middle")
            // For now, fall back to tail truncation in pure CSS
            break
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
    /// Sets the maximum number of lines that text can occupy.
    ///
    /// Use this modifier to limit text to a specific number of lines. Text that exceeds
    /// the line limit will be truncated.
    ///
    /// Example:
    /// ```swift
    /// Text("This is a very long text that might need to wrap across multiple lines")
    ///     .lineLimit(2)
    /// ```
    ///
    /// - Parameter number: The maximum number of lines. Pass `nil` to remove any line limit.
    /// - Returns: A view with the specified line limit.
    @MainActor public func lineLimit(_ number: Int?) -> _LineLimitView<Self> {
        _LineLimitView(content: self, lineLimit: number)
    }

    /// Sets the horizontal alignment of multiline text.
    ///
    /// Use this modifier to control how lines of text are aligned within their container.
    ///
    /// Example:
    /// ```swift
    /// Text("Multiple\nLines\nOf Text")
    ///     .multilineTextAlignment(.center)
    /// ```
    ///
    /// - Parameter alignment: The text alignment to apply.
    /// - Returns: A view with the specified text alignment.
    @MainActor public func multilineTextAlignment(_ alignment: TextAlignment) -> _MultilineTextAlignmentView<Self> {
        _MultilineTextAlignmentView(content: self, alignment: alignment)
    }

    /// Sets the truncation mode for text that doesn't fit in the available space.
    ///
    /// Use this modifier to control where the ellipsis appears when text is truncated.
    ///
    /// Example:
    /// ```swift
    /// Text("This is very long text that will be truncated")
    ///     .lineLimit(1)
    ///     .truncationMode(.tail)
    /// ```
    ///
    /// - Parameter mode: The truncation mode to apply.
    /// - Returns: A view with the specified truncation mode.
    @MainActor public func truncationMode(_ mode: TruncationMode) -> _TruncationModeView<Self> {
        _TruncationModeView(content: self, mode: mode)
    }
}

// MARK: - Modifier Renderable Conformances

extension _LineLimitView: _ModifierRenderable {
    public var _modifiedContent: Content { content }
}

extension _MultilineTextAlignmentView: _ModifierRenderable {
    public var _modifiedContent: Content { content }
}

extension _TruncationModeView: _ModifierRenderable {
    public var _modifiedContent: Content { content }
}
