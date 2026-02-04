import Foundation
import JavaScriptKit

/// Represents a linked WebGL shader program.
///
/// `Program` combines vertex and fragment shaders into a complete rendering pipeline.
/// It provides methods for managing uniforms, attributes, and using the program for rendering.
///
/// ## Example
///
/// ```swift
/// let vertexShader = try Shader(context: gl, type: .vertex, source: vertexSource)
/// let fragmentShader = try Shader(context: gl, type: .fragment, source: fragmentSource)
///
/// let program = try Program(
///     context: gl,
///     vertexShader: vertexShader,
///     fragmentShader: fragmentShader
/// )
///
/// program.use()
/// program.setUniform("uColor", value: [1.0, 0.0, 0.0, 1.0])
/// ```
@MainActor
public final class Program: Sendable {
    /// The WebGL rendering context.
    nonisolated(unsafe) private let gl: JSObject

    /// The linked WebGL program object.
    nonisolated(unsafe) private let program: JSObject

    /// The vertex shader.
    public let vertexShader: Shader

    /// The fragment shader.
    public let fragmentShader: Shader

    /// Cache of uniform locations.
    private var uniformLocations: [String: JSObject?] = [:]

    /// Cache of attribute locations.
    private var attributeLocations: [String: Int] = [:]

    /// Creates and links a shader program.
    ///
    /// - Parameters:
    ///   - context: The WebGL rendering context.
    ///   - vertexShader: The compiled vertex shader.
    ///   - fragmentShader: The compiled fragment shader.
    /// - Throws: `ProgramError` if linking fails.
    public init(context: JSObject, vertexShader: Shader, fragmentShader: Shader) throws {
        self.gl = context
        self.vertexShader = vertexShader
        self.fragmentShader = fragmentShader

        // Create the program
        guard let programObj = gl.createProgram!().object else {
            throw ProgramError.creationFailed
        }
        self.program = programObj

        // Attach shaders
        _ = gl.attachShader!(program, vertexShader.getShaderObject())
        _ = gl.attachShader!(program, fragmentShader.getShaderObject())

        // Link the program
        _ = gl.linkProgram!(program)

        // Check for linking errors
        let linkStatus = gl.getProgramParameter!(program, 35714) // GL_LINK_STATUS
        if linkStatus.isNull || linkStatus.isUndefined || !linkStatus.boolean! {
            let log = gl.getProgramInfoLog!(program).string ?? "Unknown error"
            _ = gl.deleteProgram!(program)
            throw ProgramError.linkingFailed(log: log)
        }

        // Validate the program
        _ = gl.validateProgram!(program)
        let validateStatus = gl.getProgramParameter!(program, 35715) // GL_VALIDATE_STATUS
        if validateStatus.isNull || validateStatus.isUndefined || !validateStatus.boolean! {
            let log = gl.getProgramInfoLog!(program).string ?? "Unknown error"
            print("Program validation warning: \(log)")
        }
    }

    deinit {
        // Clean up the program object
        _ = gl.deleteProgram!(program)
    }

    /// Activates this program for rendering.
    public func use() {
        _ = gl.useProgram!(program)
    }

    // MARK: - Uniform Management

    /// Gets the location of a uniform variable.
    ///
    /// - Parameter name: The name of the uniform variable.
    /// - Returns: The uniform location, or nil if not found.
    private func getUniformLocation(_ name: String) -> JSObject? {
        if let cached = uniformLocations[name] {
            return cached
        }

        let location = gl.getUniformLocation!(program, name)
        let result = (location.isNull || location.isUndefined) ? nil : location.object
        uniformLocations[name] = result
        return result
    }

    /// Sets a float uniform value.
    ///
    /// - Parameters:
    ///   - name: The name of the uniform variable.
    ///   - value: The float value to set.
    public func setUniform(_ name: String, value: Float) {
        guard let location = getUniformLocation(name) else { return }
        _ = gl.uniform1f!(location, value)
    }

    /// Sets an integer uniform value.
    ///
    /// - Parameters:
    ///   - name: The name of the uniform variable.
    ///   - value: The integer value to set.
    public func setUniform(_ name: String, value: Int) {
        guard let location = getUniformLocation(name) else { return }
        _ = gl.uniform1i!(location, value)
    }

    /// Sets a boolean uniform value.
    ///
    /// - Parameters:
    ///   - name: The name of the uniform variable.
    ///   - value: The boolean value to set.
    public func setUniform(_ name: String, value: Bool) {
        guard let location = getUniformLocation(name) else { return }
        _ = gl.uniform1i!(location, value ? 1 : 0)
    }

    /// Sets a Vector3 uniform value.
    ///
    /// - Parameters:
    ///   - name: The name of the uniform variable.
    ///   - value: The Vector3 value to set.
    public func setUniform(_ name: String, value: Vector3) {
        guard let location = getUniformLocation(name) else { return }
        _ = gl.uniform3f!(location, value.x, value.y, value.z)
    }

    /// Sets a vec2 uniform value.
    ///
    /// - Parameters:
    ///   - name: The name of the uniform variable.
    ///   - x: The x component.
    ///   - y: The y component.
    public func setUniform(_ name: String, x: Float, y: Float) {
        guard let location = getUniformLocation(name) else { return }
        _ = gl.uniform2f!(location, x, y)
    }

    /// Sets a vec3 uniform value.
    ///
    /// - Parameters:
    ///   - name: The name of the uniform variable.
    ///   - x: The x component.
    ///   - y: The y component.
    ///   - z: The z component.
    public func setUniform(_ name: String, x: Float, y: Float, z: Float) {
        guard let location = getUniformLocation(name) else { return }
        _ = gl.uniform3f!(location, x, y, z)
    }

    /// Sets a vec4 uniform value.
    ///
    /// - Parameters:
    ///   - name: The name of the uniform variable.
    ///   - x: The x component.
    ///   - y: The y component.
    ///   - z: The z component.
    ///   - w: The w component.
    public func setUniform(_ name: String, x: Float, y: Float, z: Float, w: Float) {
        guard let location = getUniformLocation(name) else { return }
        _ = gl.uniform4f!(location, x, y, z, w)
    }

    /// Sets a float array uniform value.
    ///
    /// - Parameters:
    ///   - name: The name of the uniform variable.
    ///   - value: The array of float values.
    public func setUniform(_ name: String, value: [Float]) {
        guard let location = getUniformLocation(name) else { return }

        let typedArray = JSObject.global.Float32Array.function!.new(value)

        switch value.count {
        case 1:
            _ = gl.uniform1fv!(location, typedArray)
        case 2:
            _ = gl.uniform2fv!(location, typedArray)
        case 3:
            _ = gl.uniform3fv!(location, typedArray)
        case 4:
            _ = gl.uniform4fv!(location, typedArray)
        default:
            break
        }
    }

    /// Sets a Matrix4x4 uniform value.
    ///
    /// - Parameters:
    ///   - name: The name of the uniform variable.
    ///   - value: The Matrix4x4 value to set.
    public func setUniform(_ name: String, value: Matrix4x4) {
        guard let location = getUniformLocation(name) else { return }

        let typedArray = JSObject.global.Float32Array.function!.new(value.elements)
        _ = gl.uniformMatrix4fv!(location, false, typedArray)
    }

    // MARK: - Attribute Management

    /// Gets the location of an attribute variable.
    ///
    /// - Parameter name: The name of the attribute variable.
    /// - Returns: The attribute location, or -1 if not found.
    public func getAttributeLocation(_ name: String) -> Int {
        if let cached = attributeLocations[name] {
            return cached
        }

        let location = gl.getAttribLocation!(program, name)
        let intLocation = Int(location.number ?? -1)
        attributeLocations[name] = intLocation
        return intLocation
    }

    /// Enables a vertex attribute array.
    ///
    /// - Parameter name: The name of the attribute variable.
    public func enableAttribute(_ name: String) {
        let location = getAttributeLocation(name)
        if location >= 0 {
            _ = gl.enableVertexAttribArray!(location)
        }
    }

    /// Disables a vertex attribute array.
    ///
    /// - Parameter name: The name of the attribute variable.
    public func disableAttribute(_ name: String) {
        let location = getAttributeLocation(name)
        if location >= 0 {
            _ = gl.disableVertexAttribArray!(location)
        }
    }

    /// Specifies the layout of vertex attribute data.
    ///
    /// - Parameters:
    ///   - name: The name of the attribute variable.
    ///   - size: The number of components per vertex (1-4).
    ///   - type: The data type (default: GL_FLOAT = 5126).
    ///   - normalized: Whether to normalize the data (default: false).
    ///   - stride: The byte offset between consecutive vertices (default: 0).
    ///   - offset: The byte offset of the first component (default: 0).
    public func setAttributePointer(
        name: String,
        size: Int,
        type: Int = 5126, // GL_FLOAT
        normalized: Bool = false,
        stride: Int = 0,
        offset: Int = 0
    ) {
        let location = getAttributeLocation(name)
        if location >= 0 {
            _ = gl.vertexAttribPointer!(location, size, type, normalized, stride, offset)
        }
    }

    /// Returns the underlying WebGL program object.
    ///
    /// - Returns: The JSObject representing the linked program.
    public func getProgramObject() -> JSObject {
        program
    }
}

// MARK: - Program Error

/// Errors that can occur during program creation and linking.
public enum ProgramError: Error, CustomStringConvertible {
    /// Failed to create the program object.
    case creationFailed

    /// Program linking failed with the given log message.
    case linkingFailed(log: String)

    public var description: String {
        switch self {
        case .creationFailed:
            return "Failed to create program object"
        case .linkingFailed(let log):
            return "Program linking failed: \(log)"
        }
    }
}

// MARK: - Convenience Initializers

extension Program {
    /// Creates a program from GLSL source code strings.
    ///
    /// - Parameters:
    ///   - context: The WebGL rendering context.
    ///   - vertexSource: The vertex shader source code.
    ///   - fragmentSource: The fragment shader source code.
    /// - Throws: `ShaderError` or `ProgramError` if compilation or linking fails.
    public convenience init(
        context: JSObject,
        vertexSource: String,
        fragmentSource: String
    ) throws {
        let vertexShader = try Shader(context: context, type: .vertex, source: vertexSource)
        let fragmentShader = try Shader(context: context, type: .fragment, source: fragmentSource)
        try self.init(context: context, vertexShader: vertexShader, fragmentShader: fragmentShader)
    }

    /// Creates a program using default shaders.
    ///
    /// - Parameter context: The WebGL rendering context.
    /// - Throws: `ShaderError` or `ProgramError` if compilation or linking fails.
    public static func defaultProgram(context: JSObject) throws -> Program {
        try Program(
            context: context,
            vertexSource: Shader.defaultVertexSource,
            fragmentSource: Shader.defaultFragmentSource
        )
    }

    /// Creates a program using unlit shaders.
    ///
    /// - Parameter context: The WebGL rendering context.
    /// - Throws: `ShaderError` or `ProgramError` if compilation or linking fails.
    public static func unlitProgram(context: JSObject) throws -> Program {
        try Program(
            context: context,
            vertexSource: Shader.unlitVertexSource,
            fragmentSource: Shader.unlitFragmentSource
        )
    }

    /// Creates a program using PBR shaders.
    ///
    /// - Parameter context: The WebGL rendering context.
    /// - Throws: `ShaderError` or `ProgramError` if compilation or linking fails.
    public static func pbrProgram(context: JSObject) throws -> Program {
        try Program(
            context: context,
            vertexSource: Shader.pbrVertexSource,
            fragmentSource: Shader.pbrFragmentSource
        )
    }
}
