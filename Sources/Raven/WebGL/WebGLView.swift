import Foundation
import JavaScriptKit

/// A view that renders 3D graphics using WebGL.
///
/// `WebGLView` integrates WebGL rendering into Raven's SwiftUI-like view system.
/// It provides a canvas for 3D graphics with full control over the WebGL context
/// and rendering pipeline.
///
/// ## Example
///
/// ```swift
/// struct Scene3D: View {
///     var body: some View {
///         WebGLView { context in
///             // Setup and render 3D scene
///             let program = try Program.defaultProgram(context: context)
///             let mesh = try Mesh.cube(context: context)
///             let camera = Camera.defaultPerspective(aspectRatio: 16.0 / 9.0)
///
///             return WebGLRenderer(
///                 context: context,
///                 program: program,
///                 camera: camera,
///                 meshes: [mesh]
///             )
///         }
///     }
/// }
/// ```
public struct WebGLView: View {
    public typealias Body = Never

    /// The rendering callback that sets up and performs WebGL rendering.
    private let render: @Sendable @MainActor (JSObject, CGSize) -> Void

    /// The clear color for the WebGL viewport [r, g, b, a].
    private let clearColor: [Float]

    /// Whether to enable depth testing.
    private let depthTest: Bool

    /// Whether to enable backface culling.
    private let cullFace: Bool

    /// Whether to enable alpha blending.
    private let blend: Bool

    /// Creates a WebGL view with a rendering callback.
    ///
    /// - Parameters:
    ///   - clearColor: The clear color [r, g, b, a] (default: black).
    ///   - depthTest: Whether to enable depth testing (default: true).
    ///   - cullFace: Whether to enable backface culling (default: true).
    ///   - blend: Whether to enable alpha blending (default: false).
    ///   - render: The rendering callback that receives the WebGL context and size.
    @MainActor
    public init(
        clearColor: [Float] = [0.0, 0.0, 0.0, 1.0],
        depthTest: Bool = true,
        cullFace: Bool = true,
        blend: Bool = false,
        render: @escaping @Sendable @MainActor (JSObject, CGSize) -> Void
    ) {
        self.clearColor = clearColor
        self.depthTest = depthTest
        self.cullFace = cullFace
        self.blend = blend
        self.render = render
    }
}

// MARK: - WebGL Renderer

/// A renderer that manages WebGL state and drawing.
///
/// `WebGLRenderer` encapsulates common rendering operations and provides
/// a convenient interface for drawing meshes with materials and cameras.
@MainActor
public final class WebGLRenderer: Sendable {
    /// The WebGL rendering context.
    private let gl: JSObject

    /// The shader program.
    private let program: Program

    /// The camera for view and projection.
    public var camera: Camera

    /// The light position in world space.
    public var lightPosition: Vector3

    /// The light color.
    public var lightColor: Vector3

    /// The ambient light color.
    public var ambientLight: Vector3

    /// Creates a WebGL renderer.
    ///
    /// - Parameters:
    ///   - context: The WebGL rendering context.
    ///   - program: The shader program to use.
    ///   - camera: The camera for rendering.
    ///   - lightPosition: The light position (default: above and to the right).
    ///   - lightColor: The light color (default: white).
    ///   - ambientLight: The ambient light color (default: dim white).
    public init(
        context: JSObject,
        program: Program,
        camera: Camera,
        lightPosition: Vector3 = Vector3(x: 10, y: 10, z: 10),
        lightColor: Vector3 = Vector3(x: 1, y: 1, z: 1),
        ambientLight: Vector3 = Vector3(x: 0.3, y: 0.3, z: 0.3)
    ) {
        self.gl = context
        self.program = program
        self.camera = camera
        self.lightPosition = lightPosition
        self.lightColor = lightColor
        self.ambientLight = ambientLight
    }

    /// Clears the viewport.
    ///
    /// - Parameter color: The clear color [r, g, b, a] (default: black).
    public func clear(color: [Float] = [0, 0, 0, 1]) {
        _ = gl.clearColor!(color[0], color[1], color[2], color[3])
        _ = gl.clear!(16640) // GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT (16384 | 256)
    }

    /// Draws a mesh with the specified material and transform.
    ///
    /// - Parameters:
    ///   - mesh: The mesh to draw.
    ///   - material: The material to apply (default: white).
    ///   - transform: The model transformation matrix (default: identity).
    public func draw(mesh: Mesh, material: Material = .white, transform: Matrix4x4 = .identity) {
        // Use the program
        program.use()

        // Set transformation matrices
        let viewProjection = camera.viewProjectionMatrix
        let modelViewProjection = viewProjection * transform

        program.setUniform("uModelViewProjection", value: modelViewProjection)
        program.setUniform("uModel", value: transform)

        // Calculate normal matrix (inverse transpose of upper-left 3x3 of model matrix)
        let normalMatrix = transform
        program.setUniform("uNormalMatrix", value: normalMatrix)

        // Set camera position
        program.setUniform("uCameraPosition", value: camera.position)

        // Set lighting uniforms
        program.setUniform("uLightPosition", value: lightPosition)
        program.setUniform("uLightColor", value: lightColor)
        program.setUniform("uAmbientLight", value: ambientLight)

        // Apply material
        material.apply(to: program)

        // Draw the mesh
        mesh.draw(with: program)
    }
}

// MARK: - WebGL Context Setup

extension WebGLView {
    /// Internal method to create a WebGL context from a canvas element.
    ///
    /// - Parameter canvas: The canvas DOM element.
    /// - Returns: The WebGL rendering context, or nil if creation failed.
    @MainActor
    internal static func createContext(canvas: JSObject) -> JSObject? {
        // Try to get a WebGL2 context first
        if let context = canvas.getContext!("webgl2").object {
            return context
        }

        // Fall back to WebGL1
        if let context = canvas.getContext!("webgl").object {
            return context
        }

        return nil
    }

    /// Configures the WebGL context with the specified settings.
    ///
    /// - Parameters:
    ///   - gl: The WebGL rendering context.
    ///   - depthTest: Whether to enable depth testing.
    ///   - cullFace: Whether to enable backface culling.
    ///   - blend: Whether to enable alpha blending.
    @MainActor
    internal static func configureContext(
        gl: JSObject,
        depthTest: Bool,
        cullFace: Bool,
        blend: Bool
    ) {
        // Enable/disable depth testing
        if depthTest {
            _ = gl.enable!(2929) // GL_DEPTH_TEST
            _ = gl.depthFunc!(515) // GL_LEQUAL
        } else {
            _ = gl.disable!(2929) // GL_DEPTH_TEST
        }

        // Enable/disable backface culling
        if cullFace {
            _ = gl.enable!(2884) // GL_CULL_FACE
            _ = gl.cullFace!(1029) // GL_BACK
        } else {
            _ = gl.disable!(2884) // GL_CULL_FACE
        }

        // Enable/disable blending
        if blend {
            _ = gl.enable!(3042) // GL_BLEND
            _ = gl.blendFunc!(770, 771) // GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA
        } else {
            _ = gl.disable!(3042) // GL_BLEND
        }
    }
}

// MARK: - WebGL Constants

/// Common WebGL constants for convenience.
public enum WebGLConstant {
    // Clear flags
    public static let colorBufferBit: Int = 16384
    public static let depthBufferBit: Int = 256
    public static let stencilBufferBit: Int = 1024

    // Enable/disable capabilities
    public static let blend: Int = 3042
    public static let cullFace: Int = 2884
    public static let depthTest: Int = 2929
    public static let dither: Int = 3024
    public static let polygonOffsetFill: Int = 32823
    public static let sampleAlphaToCoverage: Int = 32926
    public static let sampleCoverage: Int = 32928
    public static let scissorTest: Int = 3089
    public static let stencilTest: Int = 2960

    // Blend functions
    public static let zero: Int = 0
    public static let one: Int = 1
    public static let srcColor: Int = 768
    public static let oneMinusSrcColor: Int = 769
    public static let dstColor: Int = 774
    public static let oneMinusDstColor: Int = 775
    public static let srcAlpha: Int = 770
    public static let oneMinusSrcAlpha: Int = 771
    public static let dstAlpha: Int = 772
    public static let oneMinusDstAlpha: Int = 773

    // Depth functions
    public static let never: Int = 512
    public static let less: Int = 513
    public static let equal: Int = 514
    public static let lequal: Int = 515
    public static let greater: Int = 516
    public static let notequal: Int = 517
    public static let gequal: Int = 518
    public static let always: Int = 519
}

// MARK: - Convenience Initializers

extension WebGLView {
    /// Creates a WebGL view with a scene renderer.
    ///
    /// This convenience initializer sets up a complete rendering pipeline
    /// with a camera, program, and meshes.
    ///
    /// - Parameters:
    ///   - clearColor: The clear color (default: black).
    ///   - setup: A callback that creates and returns a renderer.
    @MainActor
    public init(
        clearColor: [Float] = [0.0, 0.0, 0.0, 1.0],
        setup: @escaping @Sendable @MainActor (JSObject, CGSize) throws -> WebGLRenderer
    ) {
        self.clearColor = clearColor
        self.depthTest = true
        self.cullFace = true
        self.blend = false

        self.render = { context, size in
            do {
                let renderer = try setup(context, size)
                renderer.clear(color: clearColor)

                // Rendering is handled by calling draw methods on the renderer
            } catch {
                print("WebGL setup error: \(error)")
            }
        }
    }
}
