import Foundation

// MARK: - ContentMode

/// Defines how content should be resized to fit within a container.
///
/// Use content modes with modifiers like `.aspectRatio(_:contentMode:)` to control
/// how content is sized and positioned within its available space.
public enum ContentMode: Sendable, Hashable {
    /// Scale the content to fit the available space while maintaining aspect ratio.
    ///
    /// This mode ensures the entire content is visible, potentially leaving empty space.
    case fit

    /// Scale the content to fill the available space while maintaining aspect ratio.
    ///
    /// This mode may crop parts of the content to fill the entire space.
    case fill
}

// MARK: - Clipped Modifier

/// A view wrapper that clips its content to its bounding rectangle.
///
/// Use the clipped modifier to prevent content from drawing outside its frame.
/// This is rendered using CSS `overflow: hidden`.
public struct _ClippedView<Content: View>: View, PrimitiveView, Sendable {
    let content: Content

    public typealias Body = Never

    @MainActor public func toVNode() -> VNode {
        VNode.element(
            "div",
            props: [
                "overflow": .style(name: "overflow", value: "hidden")
            ],
            children: []
        )
    }
}

// MARK: - AspectRatio Modifier

/// A view wrapper that constrains the aspect ratio of its content.
///
/// The aspect ratio modifier ensures the view maintains a specific width-to-height ratio.
/// It uses modern CSS `aspect-ratio` property with a fallback for older browsers.
public struct _AspectRatioView<Content: View>: View, PrimitiveView, Sendable {
    let content: Content
    let aspectRatio: CGFloat?
    let contentMode: ContentMode

    public typealias Body = Never

    @MainActor public func toVNode() -> VNode {
        var props: [String: VProperty] = [:]

        if let ratio = aspectRatio {
            // Modern approach: use CSS aspect-ratio property
            props["aspect-ratio"] = .style(name: "aspect-ratio", value: "\(ratio)")

            // Set object-fit based on content mode
            switch contentMode {
            case .fit:
                props["object-fit"] = .style(name: "object-fit", value: "contain")
                props["width"] = .style(name: "width", value: "100%")
                props["height"] = .style(name: "height", value: "100%")
            case .fill:
                props["object-fit"] = .style(name: "object-fit", value: "cover")
                props["width"] = .style(name: "width", value: "100%")
                props["height"] = .style(name: "height", value: "100%")
            }
        }

        return VNode.element(
            "div",
            props: props,
            children: []
        )
    }
}

// MARK: - FixedSize Modifier

/// A view wrapper that fixes the size of its content to its ideal size.
///
/// The fixed size modifier prevents the view from being resized along specified axes.
/// It uses CSS `width: fit-content` and `height: fit-content` to achieve this.
public struct _FixedSizeView<Content: View>: View, PrimitiveView, Sendable {
    let content: Content
    let horizontal: Bool
    let vertical: Bool

    public typealias Body = Never

    @MainActor public func toVNode() -> VNode {
        var props: [String: VProperty] = [:]

        // Apply fit-content for specified axes
        if horizontal {
            props["width"] = .style(name: "width", value: "fit-content")
            props["max-width"] = .style(name: "max-width", value: "max-content")
        }

        if vertical {
            props["height"] = .style(name: "height", value: "fit-content")
            props["max-height"] = .style(name: "max-height", value: "max-content")
        }

        // Ensure the container doesn't force sizing on its children
        if horizontal || vertical {
            props["flex-shrink"] = .style(name: "flex-shrink", value: "0")
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
    /// Clips this view to its bounding rectangular frame.
    ///
    /// Use this modifier to prevent the view's content from drawing outside
    /// its frame. This is particularly useful when you have content that might
    /// overflow, such as long text or images.
    ///
    /// Example:
    /// ```swift
    /// Image("wide-image")
    ///     .frame(width: 100, height: 100)
    ///     .clipped()  // Prevents image from drawing outside the 100x100 frame
    /// ```
    ///
    /// - Returns: A view that clips to its bounding frame.
    @MainActor public func clipped() -> _ClippedView<Self> {
        _ClippedView(content: self)
    }

    /// Constrains this view's dimensions to the aspect ratio of the specified size.
    ///
    /// Use this modifier to maintain a specific width-to-height ratio for the view.
    /// The content mode determines how the content is sized within the constrained dimensions.
    ///
    /// Example:
    /// ```swift
    /// // Maintain a 16:9 aspect ratio, fitting content within bounds
    /// Rectangle()
    ///     .fill(.blue)
    ///     .aspectRatio(16/9, contentMode: .fit)
    ///
    /// // Maintain a square aspect ratio, filling the available space
    /// Image("photo")
    ///     .aspectRatio(1, contentMode: .fill)
    ///
    /// // Let the content determine its own aspect ratio
    /// Image("photo")
    ///     .aspectRatio(contentMode: .fit)
    /// ```
    ///
    /// - Parameters:
    ///   - aspectRatio: The ratio of width to height. Pass `nil` to use the content's
    ///     intrinsic aspect ratio.
    ///   - contentMode: How the content should be resized. Defaults to `.fit`.
    /// - Returns: A view with constrained dimensions.
    @MainActor public func aspectRatio(
        _ aspectRatio: CGFloat? = nil,
        contentMode: ContentMode
    ) -> _AspectRatioView<Self> {
        _AspectRatioView(content: self, aspectRatio: aspectRatio, contentMode: contentMode)
    }

    /// Fixes this view at its ideal size.
    ///
    /// Use this modifier to prevent the view from being compressed or expanded
    /// beyond its natural size along the specified axes. This is useful when you
    /// want a view to maintain its intrinsic size regardless of available space.
    ///
    /// Example:
    /// ```swift
    /// // Fix both dimensions
    /// Text("Fixed")
    ///     .fixedSize()
    ///
    /// // Fix only horizontal dimension (allow vertical growth)
    /// Text("Long text that can wrap to multiple lines")
    ///     .fixedSize(horizontal: false, vertical: true)
    ///
    /// // Fix only vertical dimension (allow horizontal growth)
    /// Text("Wide")
    ///     .fixedSize(horizontal: true, vertical: false)
    /// ```
    ///
    /// - Parameters:
    ///   - horizontal: Whether to fix the width. Defaults to `true`.
    ///   - vertical: Whether to fix the height. Defaults to `true`.
    /// - Returns: A view with fixed dimensions.
    @MainActor public func fixedSize(
        horizontal: Bool = true,
        vertical: Bool = true
    ) -> _FixedSizeView<Self> {
        _FixedSizeView(content: self, horizontal: horizontal, vertical: vertical)
    }
}
