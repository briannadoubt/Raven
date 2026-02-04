import Foundation

/// 2D transformation utilities for canvas drawing.
///
/// Transformations allow you to modify the coordinate system used for drawing,
/// enabling rotation, scaling, translation, and other geometric operations.
///
/// ## Overview
///
/// Canvas transformations modify the coordinate system, affecting all subsequent
/// drawing operations. Transformations are cumulative and can be saved and restored
/// using the graphics state stack.
///
/// ## Common Transformations
///
/// ```swift
/// Canvas { context, size in
///     context.saveState()
///
///     // Translate to center
///     context.translateBy(x: size.width / 2, y: size.height / 2)
///
///     // Rotate 45 degrees
///     context.rotate(by: .degrees(45))
///
///     // Scale 2x
///     context.scaleBy(x: 2, y: 2)
///
///     // Draw in transformed space
///     context.fill(
///         Path(CGRect(x: -25, y: -25, width: 50, height: 50)),
///         with: .color(.red)
///     )
///
///     context.restoreState()
/// }
/// ```
///
/// ## Transform Matrices
///
/// For complex transformations, use affine transform matrices:
///
/// ```swift
/// Canvas { context, size in
///     // Create a custom transformation
///     var transform = CGAffineTransform.identity
///     transform = transform.translatedBy(x: 100, y: 100)
///     transform = transform.rotated(by: .pi / 4)
///     transform = transform.scaledBy(x: 1.5, y: 1.5)
///
///     context.concatenate(transform)
/// }
/// ```

// MARK: - CGAffineTransform Extensions

extension CGAffineTransform {
    /// Returns a transform created by translating an existing transform.
    ///
    /// - Parameters:
    ///   - x: The horizontal translation.
    ///   - y: The vertical translation.
    /// - Returns: A translated transform.
    public func translatedBy(x: Double, y: Double) -> CGAffineTransform {
        var result = self
        result.tx += a * x + c * y
        result.ty += b * x + d * y
        return result
    }

    /// Returns a transform created by rotating an existing transform.
    ///
    /// - Parameter angle: The rotation angle in radians.
    /// - Returns: A rotated transform.
    public func rotated(by angle: Double) -> CGAffineTransform {
        let cos = Foundation.cos(angle)
        let sin = Foundation.sin(angle)

        return CGAffineTransform(
            a: a * cos + c * sin,
            b: b * cos + d * sin,
            c: a * -sin + c * cos,
            d: b * -sin + d * cos,
            tx: tx,
            ty: ty
        )
    }

    /// Returns a transform created by scaling an existing transform.
    ///
    /// - Parameters:
    ///   - x: The horizontal scale factor.
    ///   - y: The vertical scale factor.
    /// - Returns: A scaled transform.
    public func scaledBy(x: Double, y: Double) -> CGAffineTransform {
        CGAffineTransform(
            a: a * x,
            b: b * x,
            c: c * y,
            d: d * y,
            tx: tx,
            ty: ty
        )
    }

    /// Returns the inverse of the transform.
    ///
    /// - Returns: The inverted transform, or identity if the transform is not invertible.
    public func inverted() -> CGAffineTransform {
        let determinant = a * d - b * c

        guard abs(determinant) > 1e-10 else {
            return .identity
        }

        return CGAffineTransform(
            a: d / determinant,
            b: -b / determinant,
            c: -c / determinant,
            d: a / determinant,
            tx: (c * ty - d * tx) / determinant,
            ty: (b * tx - a * ty) / determinant
        )
    }

    /// Concatenates two transforms.
    ///
    /// - Parameter other: The transform to concatenate.
    /// - Returns: The concatenated transform.
    public func concatenating(_ other: CGAffineTransform) -> CGAffineTransform {
        CGAffineTransform(
            a: a * other.a + b * other.c,
            b: a * other.b + b * other.d,
            c: c * other.a + d * other.c,
            d: c * other.b + d * other.d,
            tx: tx * other.a + ty * other.c + other.tx,
            ty: tx * other.b + ty * other.d + other.ty
        )
    }

    /// Checks if the transform is the identity transform.
    public var isIdentity: Bool {
        self == .identity
    }
}

// MARK: - Transform Utilities

extension GraphicsContext {
    /// Applies multiple transformations in sequence.
    ///
    /// This is a convenience method for applying several transformations at once.
    ///
    /// - Parameter transforms: The transformations to apply in order.
    public func apply(transforms: CGAffineTransform...) {
        for transform in transforms {
            concatenate(transform)
        }
    }

    /// Executes a closure with temporary transformations.
    ///
    /// The graphics state is saved before applying transformations and restored
    /// after the closure executes.
    ///
    /// - Parameters:
    ///   - transform: The transformation to apply.
    ///   - drawing: A closure that performs drawing operations.
    public func withTransform(
        _ transform: CGAffineTransform,
        drawing: () -> Void
    ) {
        saveState()
        concatenate(transform)
        drawing()
        restoreState()
    }

    /// Draws content centered at a point with optional rotation and scale.
    ///
    /// - Parameters:
    ///   - center: The center point.
    ///   - rotation: The rotation angle.
    ///   - scale: The scale factor.
    ///   - drawing: A closure that performs drawing operations.
    public func drawCentered(
        at center: CGPoint,
        rotation: Angle = .zero,
        scale: CGSize = CGSize(width: 1, height: 1),
        drawing: () -> Void
    ) {
        saveState()

        translateBy(x: center.x, y: center.y)

        if rotation != .zero {
            rotate(by: rotation)
        }

        if scale.width != 1 || scale.height != 1 {
            scaleBy(x: scale.width, y: scale.height)
        }

        drawing()

        restoreState()
    }
}

// MARK: - Projection Utilities

extension GraphicsContext {
    /// Creates an isometric projection transformation.
    ///
    /// Useful for drawing pseudo-3D isometric graphics.
    ///
    /// - Parameter angle: The isometric angle (typically 30 degrees).
    /// - Returns: An isometric projection transform.
    public static func isometricProjection(angle: Angle = Angle(degrees: 30)) -> CGAffineTransform {
        let rad = angle.radians
        let cos = Foundation.cos(rad)
        let sin = Foundation.sin(rad)

        return CGAffineTransform(
            a: cos,
            b: -sin,
            c: cos,
            d: sin,
            tx: 0,
            ty: 0
        )
    }

    /// Creates a perspective-like transformation.
    ///
    /// Note: This is a simplified perspective effect. True 3D perspective
    /// requires WebGL or CSS 3D transforms.
    ///
    /// - Parameter depth: The perspective depth (higher values = more perspective).
    /// - Returns: A transform with perspective-like scaling.
    public static func perspectiveTransform(depth: Double) -> CGAffineTransform {
        // This creates a simple scaling effect that approximates perspective
        let scale = 1.0 / (1.0 + depth)
        return CGAffineTransform(scaleX: scale, y: scale)
    }

    /// Creates a skew transformation.
    ///
    /// - Parameters:
    ///   - x: The horizontal skew angle.
    ///   - y: The vertical skew angle.
    /// - Returns: A skew transform.
    public static func skew(x: Angle = .zero, y: Angle = .zero) -> CGAffineTransform {
        CGAffineTransform(
            a: 1,
            b: tan(y.radians),
            c: tan(x.radians),
            d: 1,
            tx: 0,
            ty: 0
        )
    }

    /// Creates a flip transformation.
    ///
    /// - Parameters:
    ///   - horizontal: Whether to flip horizontally.
    ///   - vertical: Whether to flip vertically.
    /// - Returns: A flip transform.
    public static func flip(horizontal: Bool = false, vertical: Bool = false) -> CGAffineTransform {
        CGAffineTransform(
            scaleX: horizontal ? -1 : 1,
            y: vertical ? -1 : 1
        )
    }
}

// MARK: - Animation Helpers

extension GraphicsContext {
    /// Interpolates between two transforms.
    ///
    /// - Parameters:
    ///   - from: The starting transform.
    ///   - to: The ending transform.
    ///   - progress: The interpolation progress (0.0 to 1.0).
    /// - Returns: The interpolated transform.
    public static func interpolate(
        from: CGAffineTransform,
        to: CGAffineTransform,
        progress: Double
    ) -> CGAffineTransform {
        let p = max(0, min(1, progress))

        return CGAffineTransform(
            a: from.a + (to.a - from.a) * p,
            b: from.b + (to.b - from.b) * p,
            c: from.c + (to.c - from.c) * p,
            d: from.d + (to.d - from.d) * p,
            tx: from.tx + (to.tx - from.tx) * p,
            ty: from.ty + (to.ty - from.ty) * p
        )
    }

    /// Creates a bouncing scale animation transform.
    ///
    /// - Parameters:
    ///   - progress: The animation progress (0.0 to 1.0).
    ///   - amplitude: The bounce amplitude.
    /// - Returns: A bouncing scale transform.
    public static func bounceScale(progress: Double, amplitude: Double = 0.2) -> CGAffineTransform {
        let p = max(0, min(1, progress))
        let bounce = sin(p * .pi * 2) * amplitude * (1 - p)
        let scale = 1 + bounce

        return CGAffineTransform(scaleX: scale, y: scale)
    }

    /// Creates a spring animation transform.
    ///
    /// - Parameters:
    ///   - progress: The animation progress (0.0 to 1.0).
    ///   - stiffness: The spring stiffness.
    ///   - damping: The spring damping.
    /// - Returns: A spring animation transform.
    public static func springScale(
        progress: Double,
        stiffness: Double = 5,
        damping: Double = 0.5
    ) -> CGAffineTransform {
        let p = max(0, min(1, progress))
        let decay = exp(-damping * stiffness * p)
        let oscillation = cos(stiffness * p * .pi * 2)
        let spring = 1 + decay * oscillation * 0.2

        return CGAffineTransform(scaleX: spring, y: spring)
    }
}
