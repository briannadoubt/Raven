import Foundation

/// Advanced easing curves and custom timing functions for animations.
///
/// `AnimationCurve` provides a comprehensive set of easing functions beyond the basic
/// cubic bezier curves. These curves can be evaluated at any time point to get the
/// interpolated value, making them ideal for custom animation loops using
/// requestAnimationFrame.
///
/// ## Overview
///
/// Easing curves control the rate of change during an animation, creating different
/// feels from linear motion to complex anticipation and overshoot effects.
///
/// ## Usage
///
/// ```swift
/// let curve = AnimationCurve.easeInOutBack
/// let progress = curve.value(at: 0.5) // Get value at 50% progress
/// let interpolated = curve.interpolate(from: 0, to: 100, at: 0.5)
/// ```
///
/// ## Curve Categories
///
/// - **Quadratic**: Gentle acceleration/deceleration
/// - **Cubic**: More pronounced curves
/// - **Quartic/Quintic**: Strong acceleration
/// - **Sinusoidal**: Smooth, wave-like motion
/// - **Exponential**: Sharp acceleration
/// - **Circular**: Quarter-circle curves
/// - **Back**: Anticipation (pull back) and overshoot
/// - **Elastic**: Elastic/spring effects
/// - **Bounce**: Bouncing ball effect
///
/// ## Performance
///
/// All curve calculations are optimized for 60fps updates. The implementation uses
/// direct mathematical functions rather than lookup tables for precision and
/// minimal memory usage.
public enum AnimationCurve: Sendable, Hashable, Equatable {
    // MARK: - Quadratic
    case easeInQuad
    case easeOutQuad
    case easeInOutQuad

    // MARK: - Cubic
    case easeInCubic
    case easeOutCubic
    case easeInOutCubic

    // MARK: - Quartic
    case easeInQuart
    case easeOutQuart
    case easeInOutQuart

    // MARK: - Quintic
    case easeInQuint
    case easeOutQuint
    case easeInOutQuint

    // MARK: - Sinusoidal
    case easeInSine
    case easeOutSine
    case easeInOutSine

    // MARK: - Exponential
    case easeInExpo
    case easeOutExpo
    case easeInOutExpo

    // MARK: - Circular
    case easeInCirc
    case easeOutCirc
    case easeInOutCirc

    // MARK: - Back
    case easeInBack
    case easeOutBack
    case easeInOutBack

    // MARK: - Elastic
    case easeInElastic
    case easeOutElastic
    case easeInOutElastic

    // MARK: - Bounce
    case easeInBounce
    case easeOutBounce
    case easeInOutBounce

    // MARK: - Custom Bezier
    case bezier(p1: CGPoint, p2: CGPoint)

    // MARK: - Linear
    case linear

    // MARK: - Convenience Aliases

    /// Alias for easeInQuad
    public static var easeIn: AnimationCurve { .easeInQuad }

    /// Alias for easeOutQuad
    public static var easeOut: AnimationCurve { .easeOutQuad }

    /// Alias for easeInOutQuad
    public static var easeInOut: AnimationCurve { .easeInOutQuad }

    // MARK: - Evaluation

    /// Evaluates the curve at a given time point.
    ///
    /// - Parameter t: The time progress from 0.0 to 1.0.
    /// - Returns: The interpolated value, typically in [0, 1] but may exceed for overshoot curves.
    public func value(at t: Double) -> Double {
        // Clamp input to [0, 1]
        let t = max(0, min(1, t))

        switch self {
        // Quadratic
        case .easeInQuad:
            return t * t
        case .easeOutQuad:
            return t * (2 - t)
        case .easeInOutQuad:
            return t < 0.5 ? 2 * t * t : -1 + (4 - 2 * t) * t

        // Cubic
        case .easeInCubic:
            return t * t * t
        case .easeOutCubic:
            let t1 = t - 1
            return t1 * t1 * t1 + 1
        case .easeInOutCubic:
            return t < 0.5 ? 4 * t * t * t : (t - 1) * (2 * t - 2) * (2 * t - 2) + 1

        // Quartic
        case .easeInQuart:
            return t * t * t * t
        case .easeOutQuart:
            let t1 = t - 1
            return 1 - t1 * t1 * t1 * t1
        case .easeInOutQuart:
            return t < 0.5 ? 8 * t * t * t * t : 1 - 8 * (t - 1) * (t - 1) * (t - 1) * (t - 1)

        // Quintic
        case .easeInQuint:
            return t * t * t * t * t
        case .easeOutQuint:
            let t1 = t - 1
            return 1 + t1 * t1 * t1 * t1 * t1
        case .easeInOutQuint:
            return t < 0.5 ? 16 * t * t * t * t * t : 1 + 16 * (t - 1) * (t - 1) * (t - 1) * (t - 1) * (t - 1)

        // Sinusoidal
        case .easeInSine:
            return 1 - cos(t * .pi / 2)
        case .easeOutSine:
            return sin(t * .pi / 2)
        case .easeInOutSine:
            return -(cos(.pi * t) - 1) / 2

        // Exponential
        case .easeInExpo:
            return t == 0 ? 0 : pow(2, 10 * (t - 1))
        case .easeOutExpo:
            return t == 1 ? 1 : 1 - pow(2, -10 * t)
        case .easeInOutExpo:
            if t == 0 { return 0 }
            if t == 1 { return 1 }
            return t < 0.5 ? pow(2, 20 * t - 10) / 2 : (2 - pow(2, -20 * t + 10)) / 2

        // Circular
        case .easeInCirc:
            return 1 - sqrt(1 - t * t)
        case .easeOutCirc:
            let t1 = t - 1
            return sqrt(1 - t1 * t1)
        case .easeInOutCirc:
            return t < 0.5
                ? (1 - sqrt(1 - 4 * t * t)) / 2
                : (sqrt(1 - pow(-2 * t + 2, 2)) + 1) / 2

        // Back (overshoot)
        case .easeInBack:
            let c1 = 1.70158
            let c3 = c1 + 1
            return c3 * t * t * t - c1 * t * t
        case .easeOutBack:
            let c1 = 1.70158
            let c3 = c1 + 1
            return 1 + c3 * pow(t - 1, 3) + c1 * pow(t - 1, 2)
        case .easeInOutBack:
            let c1 = 1.70158
            let c2 = c1 * 1.525
            return t < 0.5
                ? (pow(2 * t, 2) * ((c2 + 1) * 2 * t - c2)) / 2
                : (pow(2 * t - 2, 2) * ((c2 + 1) * (t * 2 - 2) + c2) + 2) / 2

        // Elastic
        case .easeInElastic:
            if t == 0 { return 0 }
            if t == 1 { return 1 }
            let c4 = (2 * Double.pi) / 3
            return -pow(2, 10 * t - 10) * sin((t * 10 - 10.75) * c4)
        case .easeOutElastic:
            if t == 0 { return 0 }
            if t == 1 { return 1 }
            let c4 = (2 * Double.pi) / 3
            return pow(2, -10 * t) * sin((t * 10 - 0.75) * c4) + 1
        case .easeInOutElastic:
            if t == 0 { return 0 }
            if t == 1 { return 1 }
            let c5 = (2 * Double.pi) / 4.5
            return t < 0.5
                ? -(pow(2, 20 * t - 10) * sin((20 * t - 11.125) * c5)) / 2
                : (pow(2, -20 * t + 10) * sin((20 * t - 11.125) * c5)) / 2 + 1

        // Bounce
        case .easeInBounce:
            return 1 - bounceOut(1 - t)
        case .easeOutBounce:
            return bounceOut(t)
        case .easeInOutBounce:
            return t < 0.5
                ? (1 - bounceOut(1 - 2 * t)) / 2
                : (1 + bounceOut(2 * t - 1)) / 2

        // Bezier
        case .bezier(let p1, let p2):
            return solveBezier(p1: p1, p2: p2, t: t)

        // Linear
        case .linear:
            return t
        }
    }

    /// Interpolates between two values using this curve.
    ///
    /// - Parameters:
    ///   - from: The starting value.
    ///   - to: The ending value.
    ///   - t: The time progress from 0.0 to 1.0.
    /// - Returns: The interpolated value.
    public func interpolate(from: Double, to: Double, at t: Double) -> Double {
        let curveValue = value(at: t)
        return from + (to - from) * curveValue
    }

    /// Interpolates between two CGPoints using this curve.
    public func interpolate(from: CGPoint, to: CGPoint, at t: Double) -> CGPoint {
        let curveValue = value(at: t)
        return CGPoint(
            x: from.x + (to.x - from.x) * curveValue,
            y: from.y + (to.y - from.y) * curveValue
        )
    }

    /// Interpolates between two CGSizes using this curve.
    public func interpolate(from: CGSize, to: CGSize, at t: Double) -> CGSize {
        let curveValue = value(at: t)
        return CGSize(
            width: from.width + (to.width - from.width) * curveValue,
            height: from.height + (to.height - from.height) * curveValue
        )
    }

    // MARK: - Helper Functions

    /// Helper function for bounce easing (out).
    private func bounceOut(_ t: Double) -> Double {
        let n1 = 7.5625
        let d1 = 2.75

        if t < 1 / d1 {
            return n1 * t * t
        } else if t < 2 / d1 {
            let t2 = t - 1.5 / d1
            return n1 * t2 * t2 + 0.75
        } else if t < 2.5 / d1 {
            let t2 = t - 2.25 / d1
            return n1 * t2 * t2 + 0.9375
        } else {
            let t2 = t - 2.625 / d1
            return n1 * t2 * t2 + 0.984375
        }
    }

    /// Solves a cubic bezier curve for a given t value.
    ///
    /// Uses Newton-Raphson method to find the x value that corresponds to the
    /// given t, then evaluates the y value at that x.
    private func solveBezier(p1: CGPoint, p2: CGPoint, t: Double) -> Double {
        // For bezier curves, we need to find x such that bezierX(x) = t
        // Then return bezierY(x)

        // Use Newton-Raphson to solve for x
        var x = t // Initial guess
        let epsilon = 0.0001
        let maxIterations = 10

        for _ in 0..<maxIterations {
            let bx = bezierX(p1: p1, p2: p2, t: x)
            let diff = bx - t

            if abs(diff) < epsilon {
                break
            }

            // Derivative of bezierX
            let derivative = bezierXDerivative(p1: p1, p2: p2, t: x)
            if abs(derivative) < epsilon {
                break
            }

            x -= diff / derivative
        }

        // Clamp x to [0, 1]
        x = max(0, min(1, x))

        // Return the y value at this x
        return bezierY(p1: p1, p2: p2, t: x)
    }

    /// Evaluates the X component of a cubic bezier curve.
    private func bezierX(p1: CGPoint, p2: CGPoint, t: Double) -> Double {
        // Cubic bezier: B(t) = (1-t)³P0 + 3(1-t)²tP1 + 3(1-t)t²P2 + t³P3
        // Where P0 = (0,0) and P3 = (1,1)
        let t2 = t * t
        let t3 = t2 * t
        let mt = 1 - t
        let mt2 = mt * mt

        return 3 * mt2 * t * p1.x + 3 * mt * t2 * p2.x + t3
    }

    /// Evaluates the Y component of a cubic bezier curve.
    private func bezierY(p1: CGPoint, p2: CGPoint, t: Double) -> Double {
        let t2 = t * t
        let t3 = t2 * t
        let mt = 1 - t
        let mt2 = mt * mt

        return 3 * mt2 * t * p1.y + 3 * mt * t2 * p2.y + t3
    }

    /// Calculates the derivative of the X component (for Newton-Raphson).
    private func bezierXDerivative(p1: CGPoint, p2: CGPoint, t: Double) -> Double {
        let mt = 1 - t
        let mt2 = mt * mt
        let t2 = t * t

        return 3 * mt2 * p1.x + 6 * mt * t * (p2.x - p1.x) + 3 * t2 * (1 - p2.x)
    }

    // MARK: - CSS Generation

    /// Generates a CSS timing function string for this curve.
    ///
    /// For standard curves, this uses CSS keywords. For custom bezier curves,
    /// it generates cubic-bezier() notation. For complex curves (elastic, bounce),
    /// it returns a linear approximation.
    ///
    /// - Returns: A CSS timing function string.
    public func cssTimingFunction() -> String {
        switch self {
        case .linear:
            return "linear"
        case .easeInQuad, .easeInCubic:
            return "ease-in"
        case .easeOutQuad, .easeOutCubic:
            return "ease-out"
        case .easeInOutQuad, .easeInOutCubic:
            return "ease-in-out"
        case .bezier(let p1, let p2):
            return "cubic-bezier(\(p1.x), \(p1.y), \(p2.x), \(p2.y))"
        default:
            // For complex curves, approximate with cubic bezier
            return approximateCubicBezier()
        }
    }

    /// Approximates complex curves with a cubic bezier.
    private func approximateCubicBezier() -> String {
        // Sample the curve at key points and fit a cubic bezier
        // This is a simplified approximation
        let y1 = value(at: 0.25)
        let y2 = value(at: 0.75)

        // Approximate control points
        let p1 = CGPoint(x: 0.25, y: y1)
        let p2 = CGPoint(x: 0.75, y: y2)

        return "cubic-bezier(\(p1.x), \(p1.y), \(p2.x), \(p2.y))"
    }
}

// MARK: - Curve Presets

extension AnimationCurve {
    /// Material Design standard curve.
    public static var materialStandard: AnimationCurve {
        .bezier(p1: CGPoint(x: 0.4, y: 0.0), p2: CGPoint(x: 0.2, y: 1.0))
    }

    /// Material Design accelerate curve (exiting).
    public static var materialAccelerate: AnimationCurve {
        .bezier(p1: CGPoint(x: 0.4, y: 0.0), p2: CGPoint(x: 1.0, y: 1.0))
    }

    /// Material Design decelerate curve (entering).
    public static var materialDecelerate: AnimationCurve {
        .bezier(p1: CGPoint(x: 0.0, y: 0.0), p2: CGPoint(x: 0.2, y: 1.0))
    }

    /// iOS standard curve.
    public static var iosStandard: AnimationCurve {
        .bezier(p1: CGPoint(x: 0.25, y: 0.1), p2: CGPoint(x: 0.25, y: 1.0))
    }

    /// Swift anticipation curve (pulls back before moving forward).
    public static var anticipate: AnimationCurve {
        .easeInBack
    }

    /// Overshoot curve (goes past target then returns).
    public static var overshoot: AnimationCurve {
        .easeOutBack
    }
}
