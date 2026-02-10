import Foundation

// MARK: - Blur Modifier

/// A view wrapper that applies a Gaussian blur effect to its content.
///
/// The blur effect is rendered using CSS `filter: blur()`, which provides
/// hardware-accelerated blurring in all modern browsers.
///
/// ## Browser Compatibility
///
/// The blur filter has excellent browser support:
/// - Chrome/Edge: 53+
/// - Safari: 9.1+
/// - Firefox: 35+
///
/// ## Performance Considerations
///
/// CSS filters are GPU-accelerated in modern browsers, making them performant
/// for most use cases. However, applying blur to large areas or many elements
/// simultaneously may impact performance on lower-end devices.
///
/// ## Example
///
/// ```swift
/// Image("background")
///     .blur(radius: 10)
///
/// // Combining with other effects
/// Text("Hello")
///     .blur(radius: 2)
///     .brightness(1.2)
/// ```
public struct _BlurView<Content: View>: View, PrimitiveView, Sendable {
    let content: Content
    let radius: CGFloat

    public typealias Body = Never

    @MainActor public func toVNode() -> VNode {
        // CSS blur expects pixel values
        let filterValue = "blur(\(radius)px)"

        return VNode.element(
            "div",
            props: [
                "filter": .style(name: "filter", value: filterValue)
            ],
            children: []
        )
    }
}

// MARK: - Brightness Modifier

/// A view wrapper that adjusts the brightness of its content.
///
/// The brightness effect is rendered using CSS `filter: brightness()`, which
/// multiplies the color channels to make the content lighter or darker.
///
/// ## Browser Compatibility
///
/// The brightness filter has excellent browser support:
/// - Chrome/Edge: 53+
/// - Safari: 9.1+
/// - Firefox: 35+
///
/// ## Value Range
///
/// - 0.0: Completely black
/// - 1.0: Normal brightness (no change)
/// - >1.0: Brighter than normal
///
/// ## Performance Considerations
///
/// Brightness adjustments are very performant as they're simple multiplicative
/// operations that are GPU-accelerated in modern browsers.
///
/// ## Example
///
/// ```swift
/// Image("photo")
///     .brightness(0.8)  // 80% brightness (darker)
///
/// Text("Highlighted")
///     .brightness(1.5)  // 150% brightness (brighter)
/// ```
public struct _BrightnessView<Content: View>: View, PrimitiveView, Sendable {
    let content: Content
    let amount: Double

    public typealias Body = Never

    @MainActor public func toVNode() -> VNode {
        // CSS brightness is a multiplier
        let filterValue = "brightness(\(amount))"

        return VNode.element(
            "div",
            props: [
                "filter": .style(name: "filter", value: filterValue)
            ],
            children: []
        )
    }
}

// MARK: - Contrast Modifier

/// A view wrapper that adjusts the contrast of its content.
///
/// The contrast effect is rendered using CSS `filter: contrast()`, which
/// adjusts the difference between light and dark areas.
///
/// ## Browser Compatibility
///
/// The contrast filter has excellent browser support:
/// - Chrome/Edge: 53+
/// - Safari: 9.1+
/// - Firefox: 35+
///
/// ## Value Range
///
/// - 0.0: Completely gray (no contrast)
/// - 1.0: Normal contrast (no change)
/// - >1.0: Higher contrast
///
/// ## Performance Considerations
///
/// Contrast adjustments are GPU-accelerated and very performant in modern browsers.
///
/// ## Example
///
/// ```swift
/// Image("photo")
///     .contrast(1.2)  // Increase contrast by 20%
///
/// Text("Low contrast")
///     .contrast(0.7)  // Decrease contrast
/// ```
public struct _ContrastView<Content: View>: View, PrimitiveView, Sendable {
    let content: Content
    let amount: Double

    public typealias Body = Never

    @MainActor public func toVNode() -> VNode {
        // CSS contrast is a multiplier
        let filterValue = "contrast(\(amount))"

        return VNode.element(
            "div",
            props: [
                "filter": .style(name: "filter", value: filterValue)
            ],
            children: []
        )
    }
}

// MARK: - Saturation Modifier

/// A view wrapper that adjusts the color saturation of its content.
///
/// The saturation effect is rendered using CSS `filter: saturate()`, which
/// adjusts the intensity of colors.
///
/// ## Browser Compatibility
///
/// The saturate filter has excellent browser support:
/// - Chrome/Edge: 53+
/// - Safari: 9.1+
/// - Firefox: 35+
///
/// ## Value Range
///
/// - 0.0: Completely grayscale (no color)
/// - 1.0: Normal saturation (no change)
/// - >1.0: Supersaturated colors
///
/// ## Performance Considerations
///
/// Saturation adjustments are GPU-accelerated and very performant in modern browsers.
///
/// ## Example
///
/// ```swift
/// Image("photo")
///     .saturation(0)  // Grayscale
///
/// Image("photo")
///     .saturation(1.5)  // Vibrant colors
/// ```
public struct _SaturationView<Content: View>: View, PrimitiveView, Sendable {
    let content: Content
    let amount: Double

    public typealias Body = Never

    @MainActor public func toVNode() -> VNode {
        // CSS saturate is a multiplier
        let filterValue = "saturate(\(amount))"

        return VNode.element(
            "div",
            props: [
                "filter": .style(name: "filter", value: filterValue)
            ],
            children: []
        )
    }
}

// MARK: - Grayscale Modifier

/// A view wrapper that converts its content to grayscale.
///
/// The grayscale effect is rendered using CSS `filter: grayscale()`, which
/// removes color from the content, converting it to shades of gray.
///
/// ## Browser Compatibility
///
/// The grayscale filter has excellent browser support:
/// - Chrome/Edge: 53+
/// - Safari: 9.1+
/// - Firefox: 35+
///
/// ## Value Range
///
/// - 0.0: Full color (no grayscale effect)
/// - 1.0: Full grayscale (completely desaturated)
/// - Values between 0 and 1: Partial grayscale effect
///
/// ## Performance Considerations
///
/// Grayscale adjustments are GPU-accelerated and very performant in modern browsers.
///
/// ## Example
///
/// ```swift
/// Image("photo")
///     .grayscale(0.8)  // Mostly grayscale with slight color
///
/// Image("old-photo")
///     .grayscale(1.0)  // Full black and white
///
/// // Combine with other effects
/// Image("vintage")
///     .grayscale(0.6)
///     .brightness(1.1)
///     .contrast(1.2)
/// ```
public struct _GrayscaleView<Content: View>: View, PrimitiveView, Sendable {
    let content: Content
    let amount: Double

    public typealias Body = Never

    @MainActor public func toVNode() -> VNode {
        // CSS grayscale expects a value between 0 and 1
        let filterValue = "grayscale(\(amount))"

        return VNode.element(
            "div",
            props: [
                "filter": .style(name: "filter", value: filterValue)
            ],
            children: []
        )
    }
}

// MARK: - Hue Rotation Modifier

/// A view wrapper that rotates the hues of its content.
///
/// The hue rotation effect is rendered using CSS `filter: hue-rotate()`, which
/// rotates the color wheel by the specified angle. This shifts all colors by
/// the same amount, creating color transformations.
///
/// ## Browser Compatibility
///
/// The hue-rotate filter has excellent browser support:
/// - Chrome/Edge: 53+
/// - Safari: 9.1+
/// - Firefox: 35+
///
/// ## How It Works
///
/// Hue rotation works on the HSL color wheel. An angle of:
/// - 0°: No change
/// - 120°: Red becomes green, green becomes blue, blue becomes red
/// - 180°: Colors shift to their complementary colors
/// - 360°: Full rotation back to original (same as 0°)
///
/// ## Performance Considerations
///
/// Hue rotation is GPU-accelerated and performs well in modern browsers.
///
/// ## Example
///
/// ```swift
/// Image("photo")
///     .hueRotation(Angle(degrees: 180))  // Shift to complementary colors
///
/// Text("Rainbow")
///     .hueRotation(Angle(radians: .pi / 2))  // 90° rotation
///
/// // Create color shifting animation effect
/// Circle()
///     .fill(Color.red)
///     .hueRotation(Angle(degrees: 45))
/// ```
public struct _HueRotationView<Content: View>: View, PrimitiveView, Sendable {
    let content: Content
    let angle: Angle

    public typealias Body = Never

    @MainActor public func toVNode() -> VNode {
        // CSS hue-rotate expects degrees
        let filterValue = "hue-rotate(\(angle.degrees)deg)"

        return VNode.element(
            "div",
            props: [
                "filter": .style(name: "filter", value: filterValue)
            ],
            children: []
        )
    }
}

// MARK: - View Extensions

extension View {
    /// Applies a Gaussian blur to this view.
    ///
    /// Use this modifier to create depth effects, focus attention, or create
    /// background blur effects commonly seen in modern UIs.
    ///
    /// The blur effect uses CSS filters and is GPU-accelerated in modern browsers.
    ///
    /// ## Example
    ///
    /// ```swift
    /// // Background blur effect
    /// ZStack {
    ///     Image("background")
    ///         .blur(radius: 20)
    ///
    ///     VStack {
    ///         Text("Clear Content")
    ///         Text("On blurred background")
    ///     }
    /// }
    ///
    /// // Subtle blur for depth
    /// Image("photo")
    ///     .blur(radius: 2)
    /// ```
    ///
    /// - Parameter radius: The blur radius in pixels. Larger values create stronger blur.
    /// - Returns: A view with the blur effect applied.
    ///
    /// - Note: Multiple blur modifiers can be combined, and they will stack additively.
    @MainActor public func blur(radius: CGFloat) -> _BlurView<Self> {
        _BlurView(content: self, radius: radius)
    }

    /// Adjusts the brightness of this view.
    ///
    /// Use this modifier to make views lighter or darker. This is commonly used
    /// for hover effects, dimming backgrounds, or creating visual emphasis.
    ///
    /// The brightness effect uses CSS filters and is GPU-accelerated in modern browsers.
    ///
    /// ## Example
    ///
    /// ```swift
    /// // Darken an image
    /// Image("photo")
    ///     .brightness(0.7)
    ///
    /// // Brighten text for emphasis
    /// Text("Important")
    ///     .brightness(1.3)
    ///
    /// // Dim a background
    /// Rectangle()
    ///     .fill(.black)
    ///     .brightness(0.5)
    /// ```
    ///
    /// - Parameter amount: The brightness multiplier (0.0 = black, 1.0 = normal, >1.0 = brighter).
    /// - Returns: A view with the brightness adjustment applied.
    ///
    /// - Note: Values less than 0 are treated as 0, and the effect is GPU-accelerated.
    @MainActor public func brightness(_ amount: Double) -> _BrightnessView<Self> {
        _BrightnessView(content: self, amount: amount)
    }

    /// Adjusts the contrast of this view.
    ///
    /// Use this modifier to increase or decrease the difference between light and
    /// dark areas. Higher contrast makes images pop, while lower contrast creates
    /// a softer, more subtle appearance.
    ///
    /// The contrast effect uses CSS filters and is GPU-accelerated in modern browsers.
    ///
    /// ## Example
    ///
    /// ```swift
    /// // Increase contrast for emphasis
    /// Image("photo")
    ///     .contrast(1.5)
    ///
    /// // Decrease contrast for subtle effect
    /// Image("background")
    ///     .contrast(0.8)
    ///
    /// // Remove all contrast (gray)
    /// Image("photo")
    ///     .contrast(0)
    /// ```
    ///
    /// - Parameter amount: The contrast multiplier (0.0 = gray, 1.0 = normal, >1.0 = more contrast).
    /// - Returns: A view with the contrast adjustment applied.
    ///
    /// - Note: Values less than 0 are treated as 0, and the effect is GPU-accelerated.
    @MainActor public func contrast(_ amount: Double) -> _ContrastView<Self> {
        _ContrastView(content: self, amount: amount)
    }

    /// Adjusts the color saturation of this view.
    ///
    /// Use this modifier to control color intensity. Reducing saturation creates
    /// a more muted, grayscale appearance, while increasing it makes colors more vivid.
    ///
    /// The saturation effect uses CSS filters and is GPU-accelerated in modern browsers.
    ///
    /// ## Example
    ///
    /// ```swift
    /// // Grayscale effect
    /// Image("photo")
    ///     .saturation(0)
    ///
    /// // Subtle desaturation
    /// Image("background")
    ///     .saturation(0.6)
    ///
    /// // Vibrant, saturated colors
    /// Image("photo")
    ///     .saturation(1.5)
    ///
    /// // Combine with other effects
    /// Image("photo")
    ///     .saturation(1.2)
    ///     .brightness(1.1)
    /// ```
    ///
    /// - Parameter amount: The saturation multiplier (0.0 = grayscale, 1.0 = normal, >1.0 = supersaturated).
    /// - Returns: A view with the saturation adjustment applied.
    ///
    /// - Note: Values less than 0 are treated as 0, and the effect is GPU-accelerated.
    @MainActor public func saturation(_ amount: Double) -> _SaturationView<Self> {
        _SaturationView(content: self, amount: amount)
    }

    /// Applies a grayscale effect to this view.
    ///
    /// Use this modifier to convert colors to grayscale. This is commonly used
    /// for vintage effects, disabled states, or focus/attention control.
    ///
    /// The grayscale effect uses CSS filters and is GPU-accelerated in modern browsers.
    ///
    /// ## Example
    ///
    /// ```swift
    /// // Full grayscale (black and white)
    /// Image("photo")
    ///     .grayscale(1.0)
    ///
    /// // Partial grayscale
    /// Image("background")
    ///     .grayscale(0.5)
    ///
    /// // Disabled button state
    /// Button("Action") { }
    ///     .grayscale(isDisabled ? 1.0 : 0.0)
    ///     .brightness(isDisabled ? 0.7 : 1.0)
    ///
    /// // Combine with other effects
    /// Image("vintage")
    ///     .grayscale(0.8)
    ///     .contrast(1.1)
    ///     .brightness(0.9)
    /// ```
    ///
    /// - Parameter amount: The grayscale amount (0.0 = full color, 1.0 = full grayscale).
    /// - Returns: A view with the grayscale effect applied.
    ///
    /// - Note: Values outside 0.0-1.0 are clamped by the browser, and the effect is GPU-accelerated.
    @MainActor public func grayscale(_ amount: Double) -> _GrayscaleView<Self> {
        _GrayscaleView(content: self, amount: amount)
    }

    /// Applies a hue rotation effect to this view.
    ///
    /// Use this modifier to shift colors around the color wheel. This creates
    /// interesting color transformations and can be used for artistic effects,
    /// theming, or creating color variations.
    ///
    /// The hue rotation effect uses CSS filters and is GPU-accelerated in modern browsers.
    ///
    /// ## Example
    ///
    /// ```swift
    /// // Shift to complementary colors
    /// Image("photo")
    ///     .hueRotation(Angle(degrees: 180))
    ///
    /// // Create color variants
    /// Circle()
    ///     .fill(Color.red)
    ///     .hueRotation(Angle(degrees: 120))  // Red becomes blue
    ///
    /// // Subtle color shift
    /// Text("Tinted")
    ///     .hueRotation(Angle(degrees: 15))
    ///
    /// // Using radians
    /// Image("sunset")
    ///     .hueRotation(Angle(radians: .pi))
    ///
    /// // Combine with saturation for vibrant effects
    /// Image("photo")
    ///     .hueRotation(Angle(degrees: 45))
    ///     .saturation(1.3)
    /// ```
    ///
    /// - Parameter angle: The angle to rotate hues by (full rotation is 360 degrees).
    /// - Returns: A view with the hue rotation effect applied.
    ///
    /// - Note: The hue rotation works on the HSL color space and is GPU-accelerated.
    @MainActor public func hueRotation(_ angle: Angle) -> _HueRotationView<Self> {
        _HueRotationView(content: self, angle: angle)
    }
}

// MARK: - Modifier Renderable Conformances

extension _BlurView: _ModifierRenderable {
    public var _modifiedContent: Content { content }
}

extension _BrightnessView: _ModifierRenderable {
    public var _modifiedContent: Content { content }
}

extension _ContrastView: _ModifierRenderable {
    public var _modifiedContent: Content { content }
}

extension _SaturationView: _ModifierRenderable {
    public var _modifiedContent: Content { content }
}

extension _GrayscaleView: _ModifierRenderable {
    public var _modifiedContent: Content { content }
}

extension _HueRotationView: _ModifierRenderable {
    public var _modifiedContent: Content { content }
}
