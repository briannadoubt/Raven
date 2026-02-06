import Foundation

// MARK: - Interpolatable Protocol

/// A type that can be interpolated between values.
///
/// This protocol enables smooth transitions between keyframe values in animations.
/// Types conforming to this protocol can be used with ``KeyframeTrack`` to create
/// multi-step animations.
///
/// ## Topics
/// ### Required Methods
/// - ``interpolated(to:amount:)``
public protocol Interpolatable: Sendable {
    /// Returns a value interpolated between `self` and `other` by the given amount.
    ///
    /// - Parameters:
    ///   - other: The target value to interpolate towards.
    ///   - amount: The interpolation factor, typically in the range [0, 1].
    ///     - 0.0 returns `self`
    ///     - 1.0 returns `other`
    ///     - Values between 0 and 1 blend the values proportionally
    ///
    /// - Returns: The interpolated value.
    func interpolated(to other: Self, amount: Double) -> Self
}

// MARK: - Standard Conformances

extension Double: Interpolatable {
    public func interpolated(to other: Double, amount: Double) -> Double {
        self + (other - self) * amount
    }
}

extension Float: Interpolatable {
    public func interpolated(to other: Float, amount: Double) -> Float {
        self + (other - self) * Float(amount)
    }
}

#if !(os(macOS) || os(iOS) || os(tvOS) || os(watchOS)) && !arch(wasm32)
// Only add CGFloat conformance on platforms where it's not Double
extension CGFloat: Interpolatable {
    public func interpolated(to other: CGFloat, amount: Double) -> CGFloat {
        self + (other - self) * CGFloat(amount)
    }
}
#endif

extension CGPoint: Interpolatable {
    public func interpolated(to other: CGPoint, amount: Double) -> CGPoint {
        CGPoint(
            x: x.interpolated(to: other.x, amount: amount),
            y: y.interpolated(to: other.y, amount: amount)
        )
    }
}

extension CGSize: Interpolatable {
    public func interpolated(to other: CGSize, amount: Double) -> CGSize {
        CGSize(
            width: width.interpolated(to: other.width, amount: amount),
            height: height.interpolated(to: other.height, amount: amount)
        )
    }
}

extension CGRect: Interpolatable {
    public func interpolated(to other: CGRect, amount: Double) -> CGRect {
        CGRect(
            origin: origin.interpolated(to: other.origin, amount: amount),
            size: size.interpolated(to: other.size, amount: amount)
        )
    }
}

// MARK: - Keyframe Types

/// Internal representation of a keyframe in an animation sequence.
public enum Keyframe<Value: Interpolatable>: Sendable {
    /// Linear interpolation to the target value over the specified duration.
    case linear(value: Value, duration: TimeInterval)

    /// Spring-based interpolation to the target value.
    case spring(value: Value, duration: TimeInterval, bounce: Double)

    /// Cubic bezier interpolation with smooth easing.
    case cubic(value: Value, duration: TimeInterval)

    /// Instant jump to the target value (no interpolation).
    case move(value: Value)

    /// The target value for this keyframe.
    var value: Value {
        switch self {
        case .linear(let value, _),
             .spring(let value, _, _),
             .cubic(let value, _),
             .move(let value):
            return value
        }
    }

    /// The duration of this keyframe's transition.
    var duration: TimeInterval {
        switch self {
        case .linear(_, let duration),
             .spring(_, let duration, _),
             .cubic(_, let duration):
            return duration
        case .move:
            return 0
        }
    }

    /// The timing function for this keyframe as a CSS string.
    public func cssTimingFunction() -> String {
        switch self {
        case .linear:
            return "linear"
        case .spring(_, _, let bounce):
            // Approximate spring with cubic-bezier based on bounce parameter
            // bounce = 0 -> critically damped (ease-out)
            // bounce = 1 -> maximum bounce
            if bounce <= 0 {
                return "cubic-bezier(0.25, 0.1, 0.25, 1.0)"
            } else if bounce <= 0.5 {
                // Slight bounce
                let overshoot = 1.0 + bounce * 0.3
                return "cubic-bezier(0.3, 0.0, 0.2, \(overshoot))"
            } else {
                // Strong bounce
                let overshoot = 1.0 + bounce * 0.6
                return "cubic-bezier(0.4, 0.0, 0.1, \(overshoot))"
            }
        case .cubic:
            // For now, use ease-in-out for cubic. Full velocity support would require
            // more complex bezier calculations
            return "cubic-bezier(0.42, 0.0, 0.58, 1.0)"
        case .move:
            return "step-end"
        }
    }
}

// MARK: - Spring Type

/// A spring animation configuration.
///
/// `Spring` defines the physical characteristics of a spring animation,
/// including how much it bounces and how quickly it settles.
public struct Spring: Sendable {
    /// The amount of bounce in the spring, from 0.0 (no bounce) to 1.0 (maximum bounce).
    public let bounce: Double

    /// The duration of the spring animation.
    public let duration: TimeInterval

    /// Creates a spring with the specified parameters.
    ///
    /// - Parameters:
    ///   - bounce: The amount of bounce. Default is 0.0.
    ///   - duration: The duration. Default is 0.5.
    public init(bounce: Double = 0.0, duration: TimeInterval = 0.5) {
        self.bounce = bounce
        self.duration = duration
    }

    /// A spring with no bounce, settling quickly.
    public static var `default`: Spring {
        Spring(bounce: 0.0, duration: 0.5)
    }

    /// A smooth spring with no bounce.
    public static var smooth: Spring {
        Spring(bounce: 0.0, duration: 0.5)
    }

    /// A snappy, responsive spring.
    public static var snappy: Spring {
        Spring(bounce: 0.15, duration: 0.35)
    }

    /// A playful, bouncy spring.
    public static var bouncy: Spring {
        Spring(bounce: 0.4, duration: 0.6)
    }
}

// MARK: - Convenience Keyframe Types

/// A protocol for keyframe content used in result builders.
public protocol KeyframeTrackContent: Sendable {}

/// A linear keyframe that interpolates to a target value at constant speed.
public struct LinearKeyframe<Value: Interpolatable>: KeyframeTrackContent {
    public let value: Value
    public let duration: TimeInterval

    public init(_ value: Value, duration: TimeInterval) {
        self.value = value
        self.duration = duration
    }
}

/// A spring keyframe that uses spring physics to reach a target value.
public struct SpringKeyframe<Value: Interpolatable>: KeyframeTrackContent {
    public let value: Value
    public let duration: TimeInterval
    public let spring: Spring

    public init(_ value: Value, duration: TimeInterval, spring: Spring = .default) {
        self.value = value
        self.duration = duration
        self.spring = spring
    }

    public init(_ value: Value, duration: TimeInterval, bounce: Double) {
        self.value = value
        self.duration = duration
        self.spring = Spring(bounce: bounce)
    }
}

/// A cubic keyframe that uses cubic bezier interpolation.
public struct CubicKeyframe<Value: Interpolatable>: KeyframeTrackContent {
    public let value: Value
    public let duration: TimeInterval

    public init(_ value: Value, duration: TimeInterval) {
        self.value = value
        self.duration = duration
    }
}

// MARK: - Keyframe Track Content Builder

/// A result builder for constructing keyframe track content.
@resultBuilder
public struct KeyframeTrackContentBuilder {
    public static func buildBlock(_ components: any KeyframeTrackContent...) -> [any KeyframeTrackContent] {
        Array(components)
    }
}

// MARK: - KeyframeTrack KeyPath Initializer

extension KeyframeTrack {
    /// Creates a keyframe track targeting a specific property via key path.
    ///
    /// - Parameters:
    ///   - keyPath: The key path to the property to animate.
    ///   - content: A builder that produces the keyframe content.
    public init<Root>(
        _ keyPath: WritableKeyPath<Root, Value>,
        @KeyframeTrackContentBuilder content: () -> [any KeyframeTrackContent]
    ) {
        self.init()
        let items = content()
        for item in items {
            if let linear = item as? LinearKeyframe<Value> {
                self.linear(linear.value, duration: linear.duration)
            } else if let spring = item as? SpringKeyframe<Value> {
                self.spring(spring.value, duration: spring.duration, bounce: spring.spring.bounce)
            } else if let cubic = item as? CubicKeyframe<Value> {
                self.cubic(cubic.value, duration: cubic.duration)
            }
        }
    }
}

// MARK: - KeyframeSequence

/// Internal structure that collects and manages keyframes in a sequence.
public struct KeyframeSequence<Value: Interpolatable>: Sendable {
    /// The ordered list of keyframes.
    public var keyframes: [Keyframe<Value>] = []

    /// The total duration of all keyframes combined.
    public var totalDuration: TimeInterval {
        keyframes.reduce(0) { $0 + $1.duration }
    }

    public init() {}

    /// Adds a keyframe to the sequence.
    public mutating func add(_ keyframe: Keyframe<Value>) {
        keyframes.append(keyframe)
    }

    /// Generates CSS keyframe stops as percentages with properties.
    ///
    /// - Parameter propertyGenerator: A closure that generates CSS property strings
    ///   for a given value.
    /// - Returns: An array of keyframe stop strings in CSS format.
    public func generateCSSKeyframeStops(
        propertyGenerator: @escaping (Value) -> [String: String]
    ) -> [(percentage: Double, properties: [String: String], timing: String)] {
        guard !keyframes.isEmpty else { return [] }

        let total = totalDuration
        guard total > 0 else { return [] }

        var stops: [(percentage: Double, properties: [String: String], timing: String)] = []
        var currentTime: TimeInterval = 0

        // Add starting stop at 0%
        if let first = keyframes.first {
            stops.append((
                percentage: 0,
                properties: propertyGenerator(first.value),
                timing: first.cssTimingFunction()
            ))
        }

        // Add intermediate and final stops
        for (index, keyframe) in keyframes.enumerated() {
            currentTime += keyframe.duration
            let percentage = (currentTime / total) * 100

            // Skip the first keyframe since we already added it at 0%
            if index > 0 || keyframe.duration == 0 {
                stops.append((
                    percentage: percentage,
                    properties: propertyGenerator(keyframe.value),
                    timing: keyframe.cssTimingFunction()
                ))
            }
        }

        return stops
    }
}
