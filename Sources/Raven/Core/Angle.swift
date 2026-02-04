import Foundation

/// A geometric angle.
///
/// `Angle` represents an angular measurement in either degrees or radians.
/// It's commonly used with rotation effects, transformations, and other
/// geometric operations in Raven.
///
/// ## Creating Angles
///
/// You can create an angle using either degrees or radians:
///
/// ```swift
/// let degrees = Angle(degrees: 90)
/// let radians = Angle(radians: .pi / 2)
/// ```
///
/// ## Converting Between Units
///
/// Angles provide properties for converting between degrees and radians:
///
/// ```swift
/// let angle = Angle(degrees: 180)
/// print(angle.radians)  // π (approximately 3.14159)
///
/// let radAngle = Angle(radians: .pi)
/// print(radAngle.degrees)  // 180.0
/// ```
///
/// ## Common Uses
///
/// Angles are used with various visual effects and transformations:
///
/// ```swift
/// Text("Rainbow")
///     .hueRotation(Angle(degrees: 180))
///
/// Image("photo")
///     .rotationEffect(Angle(degrees: 45))
/// ```
///
/// ## Topics
///
/// ### Creating an Angle
/// - ``init(degrees:)``
/// - ``init(radians:)``
///
/// ### Getting Angle Values
/// - ``degrees``
/// - ``radians``
///
/// ### Common Angles
/// - ``zero``
///
/// - Note: Angle calculations use Double precision for accuracy.
public struct Angle: Hashable, Sendable {
    /// The angle value in degrees.
    ///
    /// A full rotation is 360 degrees.
    public var degrees: Double

    /// The angle value in radians.
    ///
    /// A full rotation is 2π radians (approximately 6.28318).
    public var radians: Double {
        get {
            degrees * .pi / 180.0
        }
        set {
            degrees = newValue * 180.0 / .pi
        }
    }

    /// Creates an angle measured in degrees.
    ///
    /// - Parameter degrees: The angle value in degrees.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let quarterTurn = Angle(degrees: 90)
    /// let halfTurn = Angle(degrees: 180)
    /// let fullTurn = Angle(degrees: 360)
    /// ```
    public init(degrees: Double) {
        self.degrees = degrees
    }

    /// Creates an angle measured in radians.
    ///
    /// - Parameter radians: The angle value in radians.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let quarterTurn = Angle(radians: .pi / 2)
    /// let halfTurn = Angle(radians: .pi)
    /// let fullTurn = Angle(radians: 2 * .pi)
    /// ```
    public init(radians: Double) {
        self.degrees = radians * 180.0 / .pi
    }

    /// An angle of zero degrees.
    ///
    /// This is a convenience property for the common case of no rotation.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let noRotation = Angle.zero
    /// // Equivalent to Angle(degrees: 0)
    /// ```
    public static let zero = Angle(degrees: 0)
}

// MARK: - Comparable

extension Angle: Comparable {
    public static func < (lhs: Angle, rhs: Angle) -> Bool {
        lhs.degrees < rhs.degrees
    }
}

// MARK: - Numeric Operations

extension Angle {
    /// Adds two angles together.
    ///
    /// - Parameters:
    ///   - lhs: The first angle.
    ///   - rhs: The second angle.
    /// - Returns: The sum of the two angles.
    public static func + (lhs: Angle, rhs: Angle) -> Angle {
        Angle(degrees: lhs.degrees + rhs.degrees)
    }

    /// Subtracts one angle from another.
    ///
    /// - Parameters:
    ///   - lhs: The angle to subtract from.
    ///   - rhs: The angle to subtract.
    /// - Returns: The difference between the two angles.
    public static func - (lhs: Angle, rhs: Angle) -> Angle {
        Angle(degrees: lhs.degrees - rhs.degrees)
    }

    /// Multiplies an angle by a scalar value.
    ///
    /// - Parameters:
    ///   - lhs: The angle to multiply.
    ///   - rhs: The scalar multiplier.
    /// - Returns: The scaled angle.
    public static func * (lhs: Angle, rhs: Double) -> Angle {
        Angle(degrees: lhs.degrees * rhs)
    }

    /// Divides an angle by a scalar value.
    ///
    /// - Parameters:
    ///   - lhs: The angle to divide.
    ///   - rhs: The scalar divisor.
    /// - Returns: The divided angle.
    public static func / (lhs: Angle, rhs: Double) -> Angle {
        Angle(degrees: lhs.degrees / rhs)
    }

    /// Negates an angle.
    ///
    /// - Parameter angle: The angle to negate.
    /// - Returns: The negated angle.
    public static prefix func - (angle: Angle) -> Angle {
        Angle(degrees: -angle.degrees)
    }
}

// MARK: - CustomStringConvertible

extension Angle: CustomStringConvertible {
    public var description: String {
        "\(degrees)°"
    }
}
