import Foundation

// MARK: - View ModifierAlignment

/// ModifierAlignment type for background and overlay modifiers.
/// This struct combines horizontal and vertical alignment for positioning layered views.
public struct ModifierAlignment: Sendable, Hashable {
    public let horizontal: HorizontalAlignment
    public let vertical: VerticalAlignment

    public init(horizontal: HorizontalAlignment, vertical: VerticalAlignment) {
        self.horizontal = horizontal
        self.vertical = vertical
    }

    internal var cssValue: String {
        "\(vertical.cssValue) \(horizontal.cssValue)"
    }

    public static let center = ModifierAlignment(horizontal: .center, vertical: .center)
    public static let top = ModifierAlignment(horizontal: .center, vertical: .top)
    public static let bottom = ModifierAlignment(horizontal: .center, vertical: .bottom)
    public static let leading = ModifierAlignment(horizontal: .leading, vertical: .center)
    public static let trailing = ModifierAlignment(horizontal: .trailing, vertical: .center)
    public static let topLeading = ModifierAlignment(horizontal: .leading, vertical: .top)
    public static let topTrailing = ModifierAlignment(horizontal: .trailing, vertical: .top)
    public static let bottomLeading = ModifierAlignment(horizontal: .leading, vertical: .bottom)
    public static let bottomTrailing = ModifierAlignment(horizontal: .trailing, vertical: .bottom)
}

// MARK: - Font Modifier

/// A view wrapper that applies a font to its content.
///
/// The font modifier sets the text font for the view and its children.
public struct _FontView<Content: View>: View, PrimitiveView, Sendable {
    let content: Content
    let font: Font

    @Environment(\.sizeCategory) private var sizeCategory

    public typealias Body = Never

    @MainActor public func toVNode() -> VNode {
        // Get the scale factor from the environment
        let scale = sizeCategory.scaleFactor

        // Convert Font to CSS properties with the scale applied
        let (family, size, weight) = font.cssProperties(scale: scale)

        let props: [String: VProperty] = [
            "font-family": .style(name: "font-family", value: family),
            "font-size": .style(name: "font-size", value: size),
            "font-weight": .style(name: "font-weight", value: weight)
        ]

        return VNode.element(
            "div",
            props: props,
            children: []
        )
    }
}

// MARK: - Background Modifier

/// A view wrapper that applies a background view to its content.
///
/// The background is positioned behind the content, aligned according to the specified alignment.
public struct _BackgroundView<Content: View, Background: View>: View, PrimitiveView, Sendable {
    let content: Content
    let background: Background
    let alignment: ModifierAlignment

    public typealias Body = Never

    @MainActor public func toVNode() -> VNode {
        // Use a grid-based approach to layer content over background
        let props: [String: VProperty] = [
            "display": .style(name: "display", value: "grid"),
            "grid-template-columns": .style(name: "grid-template-columns", value: "1fr"),
            "grid-template-rows": .style(name: "grid-template-rows", value: "1fr"),
            "place-items": .style(name: "place-items", value: alignment.cssValue)
        ]

        return VNode.element(
            "div",
            props: props,
            children: []
        )
    }
}

/// A view wrapper that applies a background color to its content.
///
/// This is a convenience variant that uses a Color as the background.
public struct _BackgroundColorView<Content: View>: View, PrimitiveView, Sendable {
    let content: Content
    let color: Color

    public typealias Body = Never

    @MainActor public func toVNode() -> VNode {
        VNode.element(
            "div",
            props: [
                "background-color": .style(name: "background-color", value: color.cssValue)
            ],
            children: []
        )
    }
}

// MARK: - Overlay Modifier

/// A view wrapper that applies an overlay view on top of its content.
///
/// The overlay is positioned on top of the content, aligned according to the specified alignment.
public struct _OverlayView<Content: View, Overlay: View>: View, PrimitiveView, Sendable {
    let content: Content
    let overlay: Overlay
    let alignment: ModifierAlignment

    public typealias Body = Never

    @MainActor public func toVNode() -> VNode {
        // Use a grid-based approach to layer overlay on content
        let props: [String: VProperty] = [
            "display": .style(name: "display", value: "grid"),
            "grid-template-columns": .style(name: "grid-template-columns", value: "1fr"),
            "grid-template-rows": .style(name: "grid-template-rows", value: "1fr"),
            "place-items": .style(name: "place-items", value: alignment.cssValue)
        ]

        return VNode.element(
            "div",
            props: props,
            children: []
        )
    }
}

// MARK: - Shadow Modifier

/// A view wrapper that applies a drop shadow to its content.
///
/// The shadow is rendered using CSS box-shadow.
public struct _ShadowView<Content: View>: View, PrimitiveView, Sendable {
    let content: Content
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat

    public typealias Body = Never

    @MainActor public func toVNode() -> VNode {
        // CSS box-shadow: offset-x offset-y blur-radius color
        let shadowValue = "\(x)px \(y)px \(radius)px \(color.cssValue)"

        return VNode.element(
            "div",
            props: [
                "box-shadow": .style(name: "box-shadow", value: shadowValue)
            ],
            children: []
        )
    }
}

// MARK: - Corner Radius Modifier

/// A view wrapper that applies rounded corners to its content.
///
/// The corner radius is rendered using CSS border-radius.
public struct _CornerRadiusView<Content: View>: View, PrimitiveView, Sendable {
    let content: Content
    let radius: CGFloat

    public typealias Body = Never

    @MainActor public func toVNode() -> VNode {
        return VNode.element(
            "div",
            props: [
                "border-radius": .style(name: "border-radius", value: "\(radius)px"),
                "overflow": .style(name: "overflow", value: "hidden")
            ],
            children: []
        )
    }
}

// MARK: - Opacity Modifier

/// A view wrapper that applies opacity to its content.
///
/// The opacity is rendered using CSS opacity property.
public struct _OpacityView<Content: View>: View, PrimitiveView, Sendable {
    let content: Content
    let opacity: Double

    public typealias Body = Never

    @MainActor public func toVNode() -> VNode {
        // Clamp opacity to 0-1 range
        let clampedOpacity = min(max(opacity, 0.0), 1.0)

        return VNode.element(
            "div",
            props: [
                "opacity": .style(name: "opacity", value: "\(clampedOpacity)")
            ],
            children: []
        )
    }
}

// MARK: - Offset Modifier

/// A view wrapper that applies a position offset to its content.
///
/// The offset is rendered using CSS transform translateX/translateY.
public struct _OffsetView<Content: View>: View, PrimitiveView, Sendable {
    let content: Content
    let x: CGFloat
    let y: CGFloat

    public typealias Body = Never

    @MainActor public func toVNode() -> VNode {
        let transformValue = "translate(\(x)px, \(y)px)"

        return VNode.element(
            "div",
            props: [
                "transform": .style(name: "transform", value: transformValue)
            ],
            children: []
        )
    }
}

// MARK: - Rotation Modifier

/// A view wrapper that applies a rotation transform to its content.
///
/// The rotation is rendered using CSS transform rotate.
public struct _RotationEffectView<Content: View>: View, PrimitiveView, Sendable {
    let content: Content
    let angle: Angle

    public typealias Body = Never

    @MainActor public func toVNode() -> VNode {
        let transformValue = "rotate(\(angle.degrees)deg)"

        return VNode.element(
            "div",
            props: [
                "transform": .style(name: "transform", value: transformValue)
            ],
            children: []
        )
    }
}

// MARK: - Scale Modifier

/// A view wrapper that applies a scale transform to its content.
///
/// The scale is rendered using CSS transform scale.
public struct _ScaleEffectView<Content: View>: View, PrimitiveView, Sendable {
    let content: Content
    let scale: CGFloat

    public typealias Body = Never

    @MainActor public func toVNode() -> VNode {
        let transformValue = "scale(\(scale))"

        return VNode.element(
            "div",
            props: [
                "transform": .style(name: "transform", value: transformValue)
            ],
            children: []
        )
    }
}

// MARK: - View Extensions

extension View {
    /// Sets the font for text in this view.
    ///
    /// Use this modifier to apply a specific font to text within the view hierarchy.
    ///
    /// Example:
    /// ```swift
    /// Text("Hello")
    ///     .font(.title)
    ///     .font(.system(size: 20, weight: .bold))
    /// ```
    ///
    /// - Parameter font: The font to apply.
    /// - Returns: A view with the specified font.
    @MainActor public func font(_ font: Font) -> _FontView<Self> {
        _FontView(content: self, font: font)
    }

    /// Layers a view behind this view.
    ///
    /// Use this modifier to place a background view behind the content.
    ///
    /// Example:
    /// ```swift
    /// Text("Hello")
    ///     .background(
    ///         Rectangle()
    ///             .fill(.blue)
    ///     )
    /// ```
    ///
    /// - Parameters:
    ///   - view: The view to layer behind this view.
    ///   - alignment: The alignment of the background view. Defaults to `.center`.
    /// - Returns: A view with the specified background.
    @MainActor public func background<V: View>(
        _ view: V,
        alignment: ModifierAlignment = .center
    ) -> _BackgroundView<Self, V> {
        _BackgroundView(content: self, background: view, alignment: alignment)
    }

    /// Sets the background color of this view.
    ///
    /// This is a convenience method for setting a solid color background.
    ///
    /// Example:
    /// ```swift
    /// Text("Hello")
    ///     .background(.blue)
    /// ```
    ///
    /// - Parameter color: The background color.
    /// - Returns: A view with the specified background color.
    @MainActor public func background(_ color: Color) -> _BackgroundColorView<Self> {
        _BackgroundColorView(content: self, color: color)
    }

    /// Layers a view in front of this view.
    ///
    /// Use this modifier to place an overlay view on top of the content.
    ///
    /// Example:
    /// ```swift
    /// Image("photo")
    ///     .overlay(
    ///         Text("Caption")
    ///             .foregroundColor(.white),
    ///         alignment: .bottom
    ///     )
    /// ```
    ///
    /// - Parameters:
    ///   - view: The view to layer in front of this view.
    ///   - alignment: The alignment of the overlay view. Defaults to `.center`.
    /// - Returns: A view with the specified overlay.
    @MainActor public func overlay<V: View>(
        _ view: V,
        alignment: ModifierAlignment = .center
    ) -> _OverlayView<Self, V> {
        _OverlayView(content: self, overlay: view, alignment: alignment)
    }

    /// Adds a drop shadow to this view.
    ///
    /// Use this modifier to create depth by adding a shadow behind the view.
    ///
    /// Example:
    /// ```swift
    /// Text("Hello")
    ///     .shadow(color: .gray, radius: 5, x: 2, y: 2)
    /// ```
    ///
    /// - Parameters:
    ///   - color: The shadow color. Defaults to `.black`.
    ///   - radius: The blur radius of the shadow.
    ///   - x: The horizontal offset of the shadow. Defaults to `0`.
    ///   - y: The vertical offset of the shadow. Defaults to `0`.
    /// - Returns: A view with the specified shadow.
    @MainActor public func shadow(
        color: Color = .black,
        radius: CGFloat,
        x: CGFloat = 0,
        y: CGFloat = 0
    ) -> _ShadowView<Self> {
        _ShadowView(content: self, color: color, radius: radius, x: x, y: y)
    }

    /// Clips this view to its bounding frame with the specified corner radius.
    ///
    /// Use this modifier to round the corners of the view.
    ///
    /// Example:
    /// ```swift
    /// Rectangle()
    ///     .fill(.blue)
    ///     .frame(width: 100, height: 100)
    ///     .cornerRadius(10)
    /// ```
    ///
    /// - Parameter radius: The corner radius in pixels.
    /// - Returns: A view with rounded corners.
    @MainActor public func cornerRadius(_ radius: CGFloat) -> _CornerRadiusView<Self> {
        _CornerRadiusView(content: self, radius: radius)
    }

    /// Sets the transparency of this view.
    ///
    /// Use this modifier to make the view partially or fully transparent.
    ///
    /// Example:
    /// ```swift
    /// Text("Hello")
    ///     .opacity(0.5)  // 50% transparent
    /// ```
    ///
    /// - Parameter value: The opacity value (0.0 to 1.0).
    /// - Returns: A view with the specified opacity.
    @MainActor public func opacity(_ value: Double) -> _OpacityView<Self> {
        _OpacityView(content: self, opacity: value)
    }

    /// Offset this view by the specified amount.
    ///
    /// Use this modifier to shift the view's position without affecting its layout.
    ///
    /// Example:
    /// ```swift
    /// Text("Hello")
    ///     .offset(x: 10, y: 20)
    /// ```
    ///
    /// - Parameters:
    ///   - x: The horizontal offset. Defaults to `0`.
    ///   - y: The vertical offset. Defaults to `0`.
    /// - Returns: A view with the specified offset.
    @MainActor public func offset(x: CGFloat = 0, y: CGFloat = 0) -> _OffsetView<Self> {
        _OffsetView(content: self, x: x, y: y)
    }

    /// Rotates this view by the specified angle.
    ///
    /// Use this modifier to rotate the view around its center point.
    ///
    /// Example:
    /// ```swift
    /// Text("Hello")
    ///     .rotationEffect(.degrees(45))
    /// ```
    ///
    /// - Parameter angle: The angle to rotate the view.
    /// - Returns: A view with the specified rotation.
    @MainActor public func rotationEffect(_ angle: Angle) -> _RotationEffectView<Self> {
        _RotationEffectView(content: self, angle: angle)
    }

    /// Scales this view by the specified amount.
    ///
    /// Use this modifier to make the view larger or smaller.
    ///
    /// Example:
    /// ```swift
    /// Text("Hello")
    ///     .scaleEffect(1.5)  // 150% size
    /// ```
    ///
    /// - Parameter scale: The scale factor (1.0 is normal size).
    /// - Returns: A view with the specified scale.
    @MainActor public func scaleEffect(_ scale: CGFloat) -> _ScaleEffectView<Self> {
        _ScaleEffectView(content: self, scale: scale)
    }
}

// MARK: - CGFloat Typealias

/// A type alias for Double to match SwiftUI's CGFloat usage.
///
/// In Swift on WebAssembly, CGFloat is not available, so we use Double as a replacement.
public typealias CGFloat = Double
