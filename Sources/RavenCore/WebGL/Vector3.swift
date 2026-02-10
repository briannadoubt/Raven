import Foundation

/// A three-dimensional vector for 3D graphics operations.
///
/// `Vector3` represents a point or direction in 3D space with x, y, and z components.
/// It provides common vector operations like addition, subtraction, scaling, and
/// normalization for use in 3D transformations, lighting calculations, and more.
///
/// ## Example
///
/// ```swift
/// let position = Vector3(x: 1.0, y: 2.0, z: 3.0)
/// let direction = Vector3(x: 0.0, y: 1.0, z: 0.0)
/// let scaled = position * 2.0
/// let normalized = direction.normalized()
/// ```
public struct Vector3: Sendable, Equatable, Hashable {
    /// The x-coordinate component.
    public var x: Float

    /// The y-coordinate component.
    public var y: Float

    /// The z-coordinate component.
    public var z: Float

    /// Creates a vector with the specified components.
    ///
    /// - Parameters:
    ///   - x: The x-coordinate component.
    ///   - y: The y-coordinate component.
    ///   - z: The z-coordinate component.
    public init(x: Float, y: Float, z: Float) {
        self.x = x
        self.y = y
        self.z = z
    }

    // MARK: - Common Vectors

    /// A vector with all components set to zero.
    public static let zero = Vector3(x: 0, y: 0, z: 0)

    /// A vector pointing in the positive x-direction (1, 0, 0).
    public static let right = Vector3(x: 1, y: 0, z: 0)

    /// A vector pointing in the negative x-direction (-1, 0, 0).
    public static let left = Vector3(x: -1, y: 0, z: 0)

    /// A vector pointing in the positive y-direction (0, 1, 0).
    public static let up = Vector3(x: 0, y: 1, z: 0)

    /// A vector pointing in the negative y-direction (0, -1, 0).
    public static let down = Vector3(x: 0, y: -1, z: 0)

    /// A vector pointing in the positive z-direction (0, 0, 1).
    public static let forward = Vector3(x: 0, y: 0, z: 1)

    /// A vector pointing in the negative z-direction (0, 0, -1).
    public static let back = Vector3(x: 0, y: 0, z: -1)

    /// A vector with all components set to one (1, 1, 1).
    public static let one = Vector3(x: 1, y: 1, z: 1)

    // MARK: - Properties

    /// The squared length (magnitude) of the vector.
    ///
    /// Use this instead of `length` when you only need to compare distances,
    /// as it avoids the expensive square root operation.
    public var lengthSquared: Float {
        x * x + y * y + z * z
    }

    /// The length (magnitude) of the vector.
    public var length: Float {
        sqrt(lengthSquared)
    }

    /// Returns a normalized (unit length) version of this vector.
    ///
    /// A normalized vector has the same direction but a length of 1.
    /// If the vector has zero length, returns the zero vector.
    ///
    /// - Returns: The normalized vector.
    public func normalized() -> Vector3 {
        let len = length
        guard len > 0 else { return .zero }
        return self / len
    }

    /// Normalizes this vector in place.
    ///
    /// After calling this method, the vector will have the same direction
    /// but a length of 1. If the vector has zero length, it remains unchanged.
    public mutating func normalize() {
        self = normalized()
    }

    // MARK: - Operations

    /// Computes the dot product of two vectors.
    ///
    /// The dot product measures how parallel two vectors are.
    /// - For parallel vectors: returns 1
    /// - For perpendicular vectors: returns 0
    /// - For opposite vectors: returns -1
    ///
    /// - Parameters:
    ///   - lhs: The first vector.
    ///   - rhs: The second vector.
    /// - Returns: The dot product.
    public static func dot(_ lhs: Vector3, _ rhs: Vector3) -> Float {
        lhs.x * rhs.x + lhs.y * rhs.y + lhs.z * rhs.z
    }

    /// Computes the cross product of two vectors.
    ///
    /// The cross product produces a vector perpendicular to both input vectors.
    /// The magnitude of the result equals the area of the parallelogram formed
    /// by the two vectors.
    ///
    /// - Parameters:
    ///   - lhs: The first vector.
    ///   - rhs: The second vector.
    /// - Returns: A vector perpendicular to both inputs.
    public static func cross(_ lhs: Vector3, _ rhs: Vector3) -> Vector3 {
        Vector3(
            x: lhs.y * rhs.z - lhs.z * rhs.y,
            y: lhs.z * rhs.x - lhs.x * rhs.z,
            z: lhs.x * rhs.y - lhs.y * rhs.x
        )
    }

    /// Computes the distance between two vectors.
    ///
    /// - Parameters:
    ///   - lhs: The first vector.
    ///   - rhs: The second vector.
    /// - Returns: The distance between the vectors.
    public static func distance(_ lhs: Vector3, _ rhs: Vector3) -> Float {
        (rhs - lhs).length
    }

    /// Computes the squared distance between two vectors.
    ///
    /// Use this instead of `distance` when you only need to compare distances,
    /// as it avoids the expensive square root operation.
    ///
    /// - Parameters:
    ///   - lhs: The first vector.
    ///   - rhs: The second vector.
    /// - Returns: The squared distance between the vectors.
    public static func distanceSquared(_ lhs: Vector3, _ rhs: Vector3) -> Float {
        (rhs - lhs).lengthSquared
    }

    /// Linearly interpolates between two vectors.
    ///
    /// - Parameters:
    ///   - start: The starting vector.
    ///   - end: The ending vector.
    ///   - t: The interpolation factor (0 = start, 1 = end).
    /// - Returns: The interpolated vector.
    public static func lerp(_ start: Vector3, _ end: Vector3, t: Float) -> Vector3 {
        start + (end - start) * t
    }

    /// Reflects a vector off a surface with the given normal.
    ///
    /// - Parameters:
    ///   - vector: The incident vector.
    ///   - normal: The surface normal (should be normalized).
    /// - Returns: The reflected vector.
    public static func reflect(_ vector: Vector3, normal: Vector3) -> Vector3 {
        vector - normal * (2 * dot(vector, normal))
    }
}

// MARK: - Operators

extension Vector3 {
    /// Adds two vectors component-wise.
    public static func + (lhs: Vector3, rhs: Vector3) -> Vector3 {
        Vector3(x: lhs.x + rhs.x, y: lhs.y + rhs.y, z: lhs.z + rhs.z)
    }

    /// Subtracts two vectors component-wise.
    public static func - (lhs: Vector3, rhs: Vector3) -> Vector3 {
        Vector3(x: lhs.x - rhs.x, y: lhs.y - rhs.y, z: lhs.z - rhs.z)
    }

    /// Multiplies a vector by a scalar.
    public static func * (lhs: Vector3, rhs: Float) -> Vector3 {
        Vector3(x: lhs.x * rhs, y: lhs.y * rhs, z: lhs.z * rhs)
    }

    /// Multiplies a scalar by a vector.
    public static func * (lhs: Float, rhs: Vector3) -> Vector3 {
        rhs * lhs
    }

    /// Divides a vector by a scalar.
    public static func / (lhs: Vector3, rhs: Float) -> Vector3 {
        Vector3(x: lhs.x / rhs, y: lhs.y / rhs, z: lhs.z / rhs)
    }

    /// Negates all components of a vector.
    public static prefix func - (vector: Vector3) -> Vector3 {
        Vector3(x: -vector.x, y: -vector.y, z: -vector.z)
    }

    /// Adds another vector to this vector in place.
    public static func += (lhs: inout Vector3, rhs: Vector3) {
        lhs = lhs + rhs
    }

    /// Subtracts another vector from this vector in place.
    public static func -= (lhs: inout Vector3, rhs: Vector3) {
        lhs = lhs - rhs
    }

    /// Multiplies this vector by a scalar in place.
    public static func *= (lhs: inout Vector3, rhs: Float) {
        lhs = lhs * rhs
    }

    /// Divides this vector by a scalar in place.
    public static func /= (lhs: inout Vector3, rhs: Float) {
        lhs = lhs / rhs
    }
}

// MARK: - CustomStringConvertible

extension Vector3: CustomStringConvertible {
    public var description: String {
        "Vector3(x: \(x), y: \(y), z: \(z))"
    }
}
