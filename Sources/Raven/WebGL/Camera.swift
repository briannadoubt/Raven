import Foundation

/// A 3D camera for controlling the view and projection of rendered scenes.
///
/// `Camera` provides perspective and orthographic projection modes along with
/// view transformation capabilities. It manages camera position, orientation,
/// and projection matrices for 3D rendering.
///
/// ## Example
///
/// ```swift
/// let camera = Camera(
///     position: Vector3(x: 0, y: 5, z: 10),
///     target: Vector3.zero,
///     fieldOfView: .pi / 4,
///     aspectRatio: 16.0 / 9.0
/// )
///
/// let viewProjection = camera.viewProjectionMatrix
/// program.setUniform("uViewProjection", value: viewProjection)
/// ```
public final class Camera: Sendable {
    /// The projection mode of the camera.
    public enum ProjectionMode: Sendable {
        /// Perspective projection with field of view.
        case perspective(fov: Float, near: Float, far: Float)

        /// Orthographic projection with bounds.
        case orthographic(left: Float, right: Float, bottom: Float, top: Float, near: Float, far: Float)
    }

    // MARK: - Properties

    /// The position of the camera in world space.
    nonisolated(unsafe) public var position: Vector3 {
        didSet { updateViewMatrix() }
    }

    /// The point the camera is looking at.
    nonisolated(unsafe) public var target: Vector3 {
        didSet { updateViewMatrix() }
    }

    /// The up direction for the camera (usually Vector3.up).
    nonisolated(unsafe) public var up: Vector3 {
        didSet { updateViewMatrix() }
    }

    /// The aspect ratio (width / height) of the viewport.
    nonisolated(unsafe) public var aspectRatio: Float {
        didSet { updateProjectionMatrix() }
    }

    /// The projection mode of the camera.
    nonisolated(unsafe) public var projectionMode: ProjectionMode {
        didSet { updateProjectionMatrix() }
    }

    /// The view matrix (transforms from world space to camera space).
    nonisolated(unsafe) private(set) public var viewMatrix: Matrix4x4

    /// The projection matrix (transforms from camera space to clip space).
    nonisolated(unsafe) private(set) public var projectionMatrix: Matrix4x4

    /// The combined view-projection matrix.
    public var viewProjectionMatrix: Matrix4x4 {
        projectionMatrix * viewMatrix
    }

    /// The forward direction vector (from camera to target).
    public var forward: Vector3 {
        (target - position).normalized()
    }

    /// The right direction vector.
    public var right: Vector3 {
        Vector3.cross(forward, up).normalized()
    }

    // MARK: - Initialization

    /// Creates a camera with perspective projection.
    ///
    /// - Parameters:
    ///   - position: The camera position (default: 0, 0, 10).
    ///   - target: The point to look at (default: origin).
    ///   - up: The up direction (default: Vector3.up).
    ///   - fieldOfView: The vertical field of view in radians (default: π/4).
    ///   - aspectRatio: The viewport aspect ratio (default: 16/9).
    ///   - near: The near clipping plane (default: 0.1).
    ///   - far: The far clipping plane (default: 1000).
    public init(
        position: Vector3 = Vector3(x: 0, y: 0, z: 10),
        target: Vector3 = .zero,
        up: Vector3 = .up,
        fieldOfView: Float = .pi / 4,
        aspectRatio: Float = 16.0 / 9.0,
        near: Float = 0.1,
        far: Float = 1000.0
    ) {
        self.position = position
        self.target = target
        self.up = up
        self.aspectRatio = aspectRatio
        self.projectionMode = .perspective(fov: fieldOfView, near: near, far: far)

        // Initialize matrices
        self.viewMatrix = .identity
        self.projectionMatrix = .identity

        // Update matrices
        updateViewMatrix()
        updateProjectionMatrix()
    }

    /// Creates a camera with orthographic projection.
    ///
    /// - Parameters:
    ///   - position: The camera position.
    ///   - target: The point to look at.
    ///   - up: The up direction.
    ///   - left: The left clipping plane.
    ///   - right: The right clipping plane.
    ///   - bottom: The bottom clipping plane.
    ///   - top: The top clipping plane.
    ///   - near: The near clipping plane.
    ///   - far: The far clipping plane.
    public init(
        position: Vector3,
        target: Vector3,
        up: Vector3 = .up,
        left: Float,
        right: Float,
        bottom: Float,
        top: Float,
        near: Float,
        far: Float
    ) {
        self.position = position
        self.target = target
        self.up = up
        self.aspectRatio = (right - left) / (top - bottom)
        self.projectionMode = .orthographic(
            left: left,
            right: right,
            bottom: bottom,
            top: top,
            near: near,
            far: far
        )

        // Initialize matrices
        self.viewMatrix = .identity
        self.projectionMatrix = .identity

        // Update matrices
        updateViewMatrix()
        updateProjectionMatrix()
    }

    // MARK: - Matrix Updates

    private func updateViewMatrix() {
        viewMatrix = Matrix4x4.lookAt(eye: position, target: target, up: up)
    }

    private func updateProjectionMatrix() {
        switch projectionMode {
        case .perspective(let fov, let near, let far):
            projectionMatrix = Matrix4x4.perspective(
                fovy: fov,
                aspect: aspectRatio,
                near: near,
                far: far
            )

        case .orthographic(let left, let right, let bottom, let top, let near, let far):
            projectionMatrix = Matrix4x4.orthographic(
                left: left,
                right: right,
                bottom: bottom,
                top: top,
                near: near,
                far: far
            )
        }
    }

    // MARK: - Camera Movement

    /// Moves the camera forward/backward along its forward vector.
    ///
    /// - Parameter distance: The distance to move (positive = forward, negative = backward).
    public func moveForward(_ distance: Float) {
        let movement = forward * distance
        position += movement
        target += movement
    }

    /// Moves the camera right/left along its right vector.
    ///
    /// - Parameter distance: The distance to move (positive = right, negative = left).
    public func moveRight(_ distance: Float) {
        let movement = right * distance
        position += movement
        target += movement
    }

    /// Moves the camera up/down along its up vector.
    ///
    /// - Parameter distance: The distance to move (positive = up, negative = down).
    public func moveUp(_ distance: Float) {
        let movement = up * distance
        position += movement
        target += movement
    }

    /// Moves the camera to a new position while maintaining the same look direction.
    ///
    /// - Parameter newPosition: The new camera position.
    public func moveTo(_ newPosition: Vector3) {
        let offset = newPosition - position
        position = newPosition
        target += offset
    }

    /// Looks at a specific target point.
    ///
    /// - Parameter newTarget: The new target point to look at.
    public func lookAt(_ newTarget: Vector3) {
        target = newTarget
    }

    // MARK: - Camera Rotation

    /// Rotates the camera around the target (orbit).
    ///
    /// - Parameters:
    ///   - horizontal: Horizontal rotation in radians.
    ///   - vertical: Vertical rotation in radians.
    public func orbit(horizontal: Float, vertical: Float) {
        // Calculate the vector from target to camera
        let offset = position - target
        let distance = offset.length

        // Calculate current angles
        let currentPhi = atan2(offset.z, offset.x)
        let currentTheta = acos(offset.y / distance)

        // Apply rotations
        let newPhi = currentPhi + horizontal
        let newTheta = max(0.01, min(.pi - 0.01, currentTheta + vertical))

        // Calculate new position
        let x = distance * sin(newTheta) * cos(newPhi)
        let y = distance * cos(newTheta)
        let z = distance * sin(newTheta) * sin(newPhi)

        position = target + Vector3(x: x, y: y, z: z)
    }

    /// Rotates the camera's view direction (first-person rotation).
    ///
    /// - Parameters:
    ///   - yaw: Horizontal rotation in radians.
    ///   - pitch: Vertical rotation in radians.
    public func rotate(yaw: Float, pitch: Float) {
        // Calculate current direction
        let direction = forward
        let distance = (target - position).length

        // Calculate current angles
        let currentYaw = atan2(direction.z, direction.x)
        let currentPitch = asin(direction.y)

        // Apply rotations
        let newYaw = currentYaw + yaw
        let newPitch = max(-.pi / 2 + 0.01, min(.pi / 2 - 0.01, currentPitch + pitch))

        // Calculate new direction
        let x = cos(newPitch) * cos(newYaw)
        let y = sin(newPitch)
        let z = cos(newPitch) * sin(newYaw)

        let newDirection = Vector3(x: x, y: y, z: z).normalized()
        target = position + newDirection * distance
    }

    // MARK: - Projection Control

    /// Sets the field of view for perspective projection.
    ///
    /// - Parameter fov: The new field of view in radians.
    public func setFieldOfView(_ fov: Float) {
        if case .perspective(_, let near, let far) = projectionMode {
            projectionMode = .perspective(fov: fov, near: near, far: far)
        }
    }

    /// Sets the near and far clipping planes.
    ///
    /// - Parameters:
    ///   - near: The near clipping plane distance.
    ///   - far: The far clipping plane distance.
    public func setClippingPlanes(near: Float, far: Float) {
        switch projectionMode {
        case .perspective(let fov, _, _):
            projectionMode = .perspective(fov: fov, near: near, far: far)

        case .orthographic(let left, let right, let bottom, let top, _, _):
            projectionMode = .orthographic(
                left: left,
                right: right,
                bottom: bottom,
                top: top,
                near: near,
                far: far
            )
        }
    }

    /// Zooms the camera by adjusting the field of view or moving closer.
    ///
    /// - Parameter amount: The zoom amount (positive = zoom in, negative = zoom out).
    public func zoom(_ amount: Float) {
        switch projectionMode {
        case .perspective(let fov, let near, let far):
            let newFov = max(0.1, min(.pi - 0.1, fov - amount))
            projectionMode = .perspective(fov: newFov, near: near, far: far)

        case .orthographic:
            // For orthographic, move the camera closer/farther
            moveForward(amount * 10)
        }
    }
}

// MARK: - Preset Cameras

extension Camera {
    /// Creates a camera for viewing a 2D scene.
    ///
    /// - Parameters:
    ///   - width: The viewport width.
    ///   - height: The viewport height.
    /// - Returns: An orthographic camera for 2D rendering.
    public static func orthographic2D(width: Float, height: Float) -> Camera {
        Camera(
            position: Vector3(x: width / 2, y: height / 2, z: 10),
            target: Vector3(x: width / 2, y: height / 2, z: 0),
            up: .up,
            left: 0,
            right: width,
            bottom: 0,
            top: height,
            near: 0.1,
            far: 100
        )
    }

    /// Creates a default perspective camera.
    ///
    /// - Parameter aspectRatio: The viewport aspect ratio.
    /// - Returns: A perspective camera with standard settings.
    public static func defaultPerspective(aspectRatio: Float) -> Camera {
        Camera(
            position: Vector3(x: 0, y: 5, z: 10),
            target: .zero,
            up: .up,
            fieldOfView: .pi / 4,
            aspectRatio: aspectRatio,
            near: 0.1,
            far: 1000
        )
    }

    /// Creates a top-down orthographic camera.
    ///
    /// - Parameters:
    ///   - width: The view width.
    ///   - height: The view height.
    ///   - distance: The distance from the target.
    /// - Returns: A top-down orthographic camera.
    public static func topDown(width: Float, height: Float, distance: Float = 10) -> Camera {
        Camera(
            position: Vector3(x: 0, y: distance, z: 0),
            target: .zero,
            up: .forward,
            left: -width / 2,
            right: width / 2,
            bottom: -height / 2,
            top: height / 2,
            near: 0.1,
            far: distance * 2
        )
    }
}
