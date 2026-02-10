import Foundation

/// A 4x4 matrix for 3D transformations.
///
/// `Matrix4x4` represents transformation matrices used in 3D graphics for
/// translations, rotations, scaling, and projections. The matrix is stored
/// in column-major order to match WebGL's expectations.
///
/// ## Example
///
/// ```swift
/// let translation = Matrix4x4.translation(x: 1.0, y: 2.0, z: 3.0)
/// let rotation = Matrix4x4.rotationY(radians: .pi / 4)
/// let combined = translation * rotation
/// ```
public struct Matrix4x4: Sendable, Equatable {
    /// The matrix elements stored in column-major order.
    ///
    /// Elements are arranged as:
    /// ```
    /// [m11, m21, m31, m41,  // column 0
    ///  m12, m22, m32, m42,  // column 1
    ///  m13, m23, m33, m43,  // column 2
    ///  m14, m24, m34, m44]  // column 3
    /// ```
    public var elements: [Float]

    /// Creates a matrix with the specified elements in column-major order.
    ///
    /// - Parameter elements: An array of 16 Float values in column-major order.
    public init(elements: [Float]) {
        precondition(elements.count == 16, "Matrix4x4 requires exactly 16 elements")
        self.elements = elements
    }

    /// Creates a matrix with individual element values.
    ///
    /// - Parameters: Individual matrix elements (m11 through m44).
    public init(
        m11: Float, m12: Float, m13: Float, m14: Float,
        m21: Float, m22: Float, m23: Float, m24: Float,
        m31: Float, m32: Float, m33: Float, m34: Float,
        m41: Float, m42: Float, m43: Float, m44: Float
    ) {
        self.elements = [
            m11, m21, m31, m41,
            m12, m22, m32, m42,
            m13, m23, m33, m43,
            m14, m24, m34, m44
        ]
    }

    // MARK: - Common Matrices

    /// The identity matrix.
    ///
    /// Multiplying any matrix by the identity matrix returns the original matrix.
    public static let identity = Matrix4x4(
        m11: 1, m12: 0, m13: 0, m14: 0,
        m21: 0, m22: 1, m23: 0, m24: 0,
        m31: 0, m32: 0, m33: 1, m34: 0,
        m41: 0, m42: 0, m43: 0, m44: 1
    )

    // MARK: - Transformations

    /// Creates a translation matrix.
    ///
    /// - Parameters:
    ///   - x: Translation along the x-axis.
    ///   - y: Translation along the y-axis.
    ///   - z: Translation along the z-axis.
    /// - Returns: A translation matrix.
    public static func translation(x: Float, y: Float, z: Float) -> Matrix4x4 {
        Matrix4x4(
            m11: 1, m12: 0, m13: 0, m14: x,
            m21: 0, m22: 1, m23: 0, m24: y,
            m31: 0, m32: 0, m33: 1, m34: z,
            m41: 0, m42: 0, m43: 0, m44: 1
        )
    }

    /// Creates a translation matrix from a vector.
    ///
    /// - Parameter vector: The translation vector.
    /// - Returns: A translation matrix.
    public static func translation(_ vector: Vector3) -> Matrix4x4 {
        translation(x: vector.x, y: vector.y, z: vector.z)
    }

    /// Creates a uniform scale matrix.
    ///
    /// - Parameter scale: The scale factor applied to all axes.
    /// - Returns: A scale matrix.
    public static func scale(_ scale: Float) -> Matrix4x4 {
        Matrix4x4(
            m11: scale, m12: 0, m13: 0, m14: 0,
            m21: 0, m22: scale, m23: 0, m24: 0,
            m31: 0, m32: 0, m33: scale, m34: 0,
            m41: 0, m42: 0, m43: 0, m44: 1
        )
    }

    /// Creates a non-uniform scale matrix.
    ///
    /// - Parameters:
    ///   - x: Scale factor along the x-axis.
    ///   - y: Scale factor along the y-axis.
    ///   - z: Scale factor along the z-axis.
    /// - Returns: A scale matrix.
    public static func scale(x: Float, y: Float, z: Float) -> Matrix4x4 {
        Matrix4x4(
            m11: x, m12: 0, m13: 0, m14: 0,
            m21: 0, m22: y, m23: 0, m24: 0,
            m31: 0, m32: 0, m33: z, m34: 0,
            m41: 0, m42: 0, m43: 0, m44: 1
        )
    }

    /// Creates a non-uniform scale matrix from a vector.
    ///
    /// - Parameter vector: The scale factors for each axis.
    /// - Returns: A scale matrix.
    public static func scale(_ vector: Vector3) -> Matrix4x4 {
        scale(x: vector.x, y: vector.y, z: vector.z)
    }

    /// Creates a rotation matrix around the x-axis.
    ///
    /// - Parameter radians: The rotation angle in radians.
    /// - Returns: A rotation matrix.
    public static func rotationX(radians: Float) -> Matrix4x4 {
        let c = cos(radians)
        let s = sin(radians)
        return Matrix4x4(
            m11: 1, m12: 0, m13: 0, m14: 0,
            m21: 0, m22: c, m23: -s, m24: 0,
            m31: 0, m32: s, m33: c, m34: 0,
            m41: 0, m42: 0, m43: 0, m44: 1
        )
    }

    /// Creates a rotation matrix around the y-axis.
    ///
    /// - Parameter radians: The rotation angle in radians.
    /// - Returns: A rotation matrix.
    public static func rotationY(radians: Float) -> Matrix4x4 {
        let c = cos(radians)
        let s = sin(radians)
        return Matrix4x4(
            m11: c, m12: 0, m13: s, m14: 0,
            m21: 0, m22: 1, m23: 0, m24: 0,
            m31: -s, m32: 0, m33: c, m34: 0,
            m41: 0, m42: 0, m43: 0, m44: 1
        )
    }

    /// Creates a rotation matrix around the z-axis.
    ///
    /// - Parameter radians: The rotation angle in radians.
    /// - Returns: A rotation matrix.
    public static func rotationZ(radians: Float) -> Matrix4x4 {
        let c = cos(radians)
        let s = sin(radians)
        return Matrix4x4(
            m11: c, m12: -s, m13: 0, m14: 0,
            m21: s, m22: c, m23: 0, m24: 0,
            m31: 0, m32: 0, m33: 1, m34: 0,
            m41: 0, m42: 0, m43: 0, m44: 1
        )
    }

    /// Creates a rotation matrix around an arbitrary axis.
    ///
    /// - Parameters:
    ///   - axis: The rotation axis (should be normalized).
    ///   - radians: The rotation angle in radians.
    /// - Returns: A rotation matrix.
    public static func rotation(axis: Vector3, radians: Float) -> Matrix4x4 {
        let c = cos(radians)
        let s = sin(radians)
        let t = 1 - c

        let normalized = axis.normalized()
        let x = normalized.x
        let y = normalized.y
        let z = normalized.z

        return Matrix4x4(
            m11: t * x * x + c, m12: t * x * y - s * z, m13: t * x * z + s * y, m14: 0,
            m21: t * x * y + s * z, m22: t * y * y + c, m23: t * y * z - s * x, m24: 0,
            m31: t * x * z - s * y, m32: t * y * z + s * x, m33: t * z * z + c, m34: 0,
            m41: 0, m42: 0, m43: 0, m44: 1
        )
    }

    // MARK: - Projections

    /// Creates a perspective projection matrix.
    ///
    /// - Parameters:
    ///   - fovy: The vertical field of view in radians.
    ///   - aspect: The aspect ratio (width / height).
    ///   - near: The near clipping plane distance.
    ///   - far: The far clipping plane distance.
    /// - Returns: A perspective projection matrix.
    public static func perspective(fovy: Float, aspect: Float, near: Float, far: Float) -> Matrix4x4 {
        let f = 1.0 / tan(fovy / 2.0)
        let rangeInv = 1.0 / (near - far)

        return Matrix4x4(
            m11: f / aspect, m12: 0, m13: 0, m14: 0,
            m21: 0, m22: f, m23: 0, m24: 0,
            m31: 0, m32: 0, m33: (near + far) * rangeInv, m34: 2 * far * near * rangeInv,
            m41: 0, m42: 0, m43: -1, m44: 0
        )
    }

    /// Creates an orthographic projection matrix.
    ///
    /// - Parameters:
    ///   - left: The left clipping plane coordinate.
    ///   - right: The right clipping plane coordinate.
    ///   - bottom: The bottom clipping plane coordinate.
    ///   - top: The top clipping plane coordinate.
    ///   - near: The near clipping plane distance.
    ///   - far: The far clipping plane distance.
    /// - Returns: An orthographic projection matrix.
    public static func orthographic(
        left: Float,
        right: Float,
        bottom: Float,
        top: Float,
        near: Float,
        far: Float
    ) -> Matrix4x4 {
        let width = right - left
        let height = top - bottom
        let depth = far - near

        return Matrix4x4(
            m11: 2 / width, m12: 0, m13: 0, m14: -(right + left) / width,
            m21: 0, m22: 2 / height, m23: 0, m24: -(top + bottom) / height,
            m31: 0, m32: 0, m33: -2 / depth, m34: -(far + near) / depth,
            m41: 0, m42: 0, m43: 0, m44: 1
        )
    }

    /// Creates a look-at view matrix.
    ///
    /// - Parameters:
    ///   - eye: The camera position.
    ///   - target: The point the camera is looking at.
    ///   - up: The up direction (usually Vector3.up).
    /// - Returns: A view matrix.
    public static func lookAt(eye: Vector3, target: Vector3, up: Vector3) -> Matrix4x4 {
        let z = (eye - target).normalized()
        let x = Vector3.cross(up, z).normalized()
        let y = Vector3.cross(z, x)

        return Matrix4x4(
            m11: x.x, m12: x.y, m13: x.z, m14: -Vector3.dot(x, eye),
            m21: y.x, m22: y.y, m23: y.z, m24: -Vector3.dot(y, eye),
            m31: z.x, m32: z.y, m33: z.z, m34: -Vector3.dot(z, eye),
            m41: 0, m42: 0, m43: 0, m44: 1
        )
    }

    // MARK: - Operations

    /// Computes the transpose of this matrix.
    ///
    /// The transpose swaps rows and columns.
    ///
    /// - Returns: The transposed matrix.
    public func transposed() -> Matrix4x4 {
        let e = elements
        return Matrix4x4(elements: [
            e[0], e[4], e[8], e[12],
            e[1], e[5], e[9], e[13],
            e[2], e[6], e[10], e[14],
            e[3], e[7], e[11], e[15]
        ])
    }

    /// Transforms a vector by this matrix.
    ///
    /// - Parameter vector: The vector to transform.
    /// - Returns: The transformed vector.
    public func transform(_ vector: Vector3) -> Vector3 {
        let e = elements
        let x = e[0] * vector.x + e[4] * vector.y + e[8] * vector.z + e[12]
        let y = e[1] * vector.x + e[5] * vector.y + e[9] * vector.z + e[13]
        let z = e[2] * vector.x + e[6] * vector.y + e[10] * vector.z + e[14]
        let w = e[3] * vector.x + e[7] * vector.y + e[11] * vector.z + e[15]

        if abs(w - 1.0) < 0.00001 {
            return Vector3(x: x, y: y, z: z)
        } else {
            return Vector3(x: x / w, y: y / w, z: z / w)
        }
    }
}

// MARK: - Operators

extension Matrix4x4 {
    /// Multiplies two matrices.
    ///
    /// Matrix multiplication is not commutative: A * B != B * A.
    ///
    /// - Parameters:
    ///   - lhs: The left-hand matrix.
    ///   - rhs: The right-hand matrix.
    /// - Returns: The product matrix.
    public static func * (lhs: Matrix4x4, rhs: Matrix4x4) -> Matrix4x4 {
        let a = lhs.elements
        let b = rhs.elements
        var result = [Float](repeating: 0, count: 16)

        for i in 0..<4 {
            for j in 0..<4 {
                var sum: Float = 0
                for k in 0..<4 {
                    sum += a[i + k * 4] * b[k + j * 4]
                }
                result[i + j * 4] = sum
            }
        }

        return Matrix4x4(elements: result)
    }

    /// Multiplies this matrix by another in place.
    public static func *= (lhs: inout Matrix4x4, rhs: Matrix4x4) {
        lhs = lhs * rhs
    }
}

// MARK: - CustomStringConvertible

extension Matrix4x4: CustomStringConvertible {
    public var description: String {
        let e = elements
        return """
        Matrix4x4(
          [\(e[0]), \(e[4]), \(e[8]), \(e[12])]
          [\(e[1]), \(e[5]), \(e[9]), \(e[13])]
          [\(e[2]), \(e[6]), \(e[10]), \(e[14])]
          [\(e[3]), \(e[7]), \(e[11]), \(e[15])]
        )
        """
    }
}
