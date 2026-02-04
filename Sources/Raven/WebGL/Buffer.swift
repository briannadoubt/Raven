import Foundation
import JavaScriptKit

/// Represents a WebGL buffer for vertex or index data.
///
/// `Buffer` encapsulates WebGL buffer objects used to store vertex attributes,
/// index data, and other array data on the GPU. It provides a type-safe interface
/// for creating and managing buffer data.
///
/// ## Example
///
/// ```swift
/// let vertices: [Float] = [
///     -0.5, -0.5, 0.0,
///      0.5, -0.5, 0.0,
///      0.0,  0.5, 0.0
/// ]
///
/// let buffer = try Buffer(
///     context: gl,
///     target: .arrayBuffer,
///     data: vertices,
///     usage: .staticDraw
/// )
///
/// buffer.bind()
/// ```
@MainActor
public final class Buffer: Sendable {
    /// The buffer target type.
    public enum Target: Sendable {
        /// Buffer for vertex attribute data.
        case arrayBuffer

        /// Buffer for element (index) data.
        case elementArrayBuffer

        /// Returns the WebGL constant for this target.
        fileprivate var glConstant: Int {
            switch self {
            case .arrayBuffer: return 34962 // GL_ARRAY_BUFFER
            case .elementArrayBuffer: return 34963 // GL_ELEMENT_ARRAY_BUFFER
            }
        }
    }

    /// The buffer usage hint.
    public enum Usage: Sendable {
        /// Data is set once and used many times.
        case staticDraw

        /// Data is modified repeatedly and used many times.
        case dynamicDraw

        /// Data is modified once and used a few times.
        case streamDraw

        /// Returns the WebGL constant for this usage.
        fileprivate var glConstant: Int {
            switch self {
            case .staticDraw: return 35044 // GL_STATIC_DRAW
            case .dynamicDraw: return 35048 // GL_DYNAMIC_DRAW
            case .streamDraw: return 35040 // GL_STREAM_DRAW
            }
        }
    }

    /// The WebGL rendering context.
    nonisolated(unsafe) private let gl: JSObject

    /// The WebGL buffer object.
    nonisolated(unsafe) private let buffer: JSObject

    /// The buffer target.
    public let target: Target

    /// The buffer usage hint.
    public let usage: Usage

    /// The size of the buffer in bytes.
    public private(set) var byteLength: Int

    /// Creates a buffer with float data.
    ///
    /// - Parameters:
    ///   - context: The WebGL rendering context.
    ///   - target: The buffer target (arrayBuffer or elementArrayBuffer).
    ///   - data: The float data to store in the buffer.
    ///   - usage: The usage hint (default: staticDraw).
    /// - Throws: `BufferError` if buffer creation fails.
    public init(
        context: JSObject,
        target: Target,
        data: [Float],
        usage: Usage = .staticDraw
    ) throws {
        self.gl = context
        self.target = target
        self.usage = usage
        self.byteLength = data.count * MemoryLayout<Float>.stride

        // Create the buffer
        guard let bufferObj = gl.createBuffer!().object else {
            throw BufferError.creationFailed
        }
        self.buffer = bufferObj

        // Bind and fill the buffer
        _ = gl.bindBuffer!(target.glConstant, buffer)

        let typedArray = JSObject.global.Float32Array.function!.new(data)
        _ = gl.bufferData!(target.glConstant, typedArray, usage.glConstant)

        // Unbind
        _ = gl.bindBuffer!(target.glConstant, JSValue.null)
    }

    /// Creates a buffer with unsigned 16-bit integer data (for indices).
    ///
    /// - Parameters:
    ///   - context: The WebGL rendering context.
    ///   - target: The buffer target (typically elementArrayBuffer for indices).
    ///   - data: The uint16 data to store in the buffer.
    ///   - usage: The usage hint (default: staticDraw).
    /// - Throws: `BufferError` if buffer creation fails.
    public init(
        context: JSObject,
        target: Target,
        data: [UInt16],
        usage: Usage = .staticDraw
    ) throws {
        self.gl = context
        self.target = target
        self.usage = usage
        self.byteLength = data.count * MemoryLayout<UInt16>.stride

        // Create the buffer
        guard let bufferObj = gl.createBuffer!().object else {
            throw BufferError.creationFailed
        }
        self.buffer = bufferObj

        // Bind and fill the buffer
        _ = gl.bindBuffer!(target.glConstant, buffer)

        let typedArray = JSObject.global.Uint16Array.function!.new(data)
        _ = gl.bufferData!(target.glConstant, typedArray, usage.glConstant)

        // Unbind
        _ = gl.bindBuffer!(target.glConstant, JSValue.null)
    }

    /// Creates a buffer with unsigned 32-bit integer data (for indices).
    ///
    /// - Parameters:
    ///   - context: The WebGL rendering context.
    ///   - target: The buffer target (typically elementArrayBuffer for indices).
    ///   - data: The uint32 data to store in the buffer.
    ///   - usage: The usage hint (default: staticDraw).
    /// - Throws: `BufferError` if buffer creation fails.
    public init(
        context: JSObject,
        target: Target,
        data: [UInt32],
        usage: Usage = .staticDraw
    ) throws {
        self.gl = context
        self.target = target
        self.usage = usage
        self.byteLength = data.count * MemoryLayout<UInt32>.stride

        // Create the buffer
        guard let bufferObj = gl.createBuffer!().object else {
            throw BufferError.creationFailed
        }
        self.buffer = bufferObj

        // Bind and fill the buffer
        _ = gl.bindBuffer!(target.glConstant, buffer)

        let typedArray = JSObject.global.Uint32Array.function!.new(data)
        _ = gl.bufferData!(target.glConstant, typedArray, usage.glConstant)

        // Unbind
        _ = gl.bindBuffer!(target.glConstant, JSValue.null)
    }

    /// Creates an empty buffer with the specified size.
    ///
    /// - Parameters:
    ///   - context: The WebGL rendering context.
    ///   - target: The buffer target.
    ///   - byteLength: The size of the buffer in bytes.
    ///   - usage: The usage hint (default: dynamicDraw).
    /// - Throws: `BufferError` if buffer creation fails.
    public init(
        context: JSObject,
        target: Target,
        byteLength: Int,
        usage: Usage = .dynamicDraw
    ) throws {
        self.gl = context
        self.target = target
        self.usage = usage
        self.byteLength = byteLength

        // Create the buffer
        guard let bufferObj = gl.createBuffer!().object else {
            throw BufferError.creationFailed
        }
        self.buffer = bufferObj

        // Bind and allocate the buffer
        _ = gl.bindBuffer!(target.glConstant, buffer)
        _ = gl.bufferData!(target.glConstant, byteLength, usage.glConstant)

        // Unbind
        _ = gl.bindBuffer!(target.glConstant, JSValue.null)
    }

    deinit {
        // Clean up the buffer object
        // JSObject is always valid once created, no need to check for null/undefined
        _ = gl.deleteBuffer!(buffer)
    }

    // MARK: - Buffer Operations

    /// Binds this buffer to its target.
    public func bind() {
        _ = gl.bindBuffer!(target.glConstant, buffer)
    }

    /// Unbinds any buffer from this buffer's target.
    public func unbind() {
        _ = gl.bindBuffer!(target.glConstant, JSValue.null)
    }

    /// Updates the buffer with new float data.
    ///
    /// - Parameters:
    ///   - data: The new float data.
    ///   - offset: The byte offset at which to start writing (default: 0).
    public func updateData(_ data: [Float], offset: Int = 0) {
        bind()
        let typedArray = JSObject.global.Float32Array.function!.new(data)
        _ = gl.bufferSubData!(target.glConstant, offset, typedArray)
    }

    /// Updates the buffer with new uint16 data.
    ///
    /// - Parameters:
    ///   - data: The new uint16 data.
    ///   - offset: The byte offset at which to start writing (default: 0).
    public func updateData(_ data: [UInt16], offset: Int = 0) {
        bind()
        let typedArray = JSObject.global.Uint16Array.function!.new(data)
        _ = gl.bufferSubData!(target.glConstant, offset, typedArray)
    }

    /// Updates the buffer with new uint32 data.
    ///
    /// - Parameters:
    ///   - data: The new uint32 data.
    ///   - offset: The byte offset at which to start writing (default: 0).
    public func updateData(_ data: [UInt32], offset: Int = 0) {
        bind()
        let typedArray = JSObject.global.Uint32Array.function!.new(data)
        _ = gl.bufferSubData!(target.glConstant, offset, typedArray)
    }

    /// Returns the underlying WebGL buffer object.
    ///
    /// - Returns: The JSObject representing the buffer.
    public func getBufferObject() -> JSObject {
        buffer
    }
}

// MARK: - Buffer Error

/// Errors that can occur during buffer creation and manipulation.
public enum BufferError: Error, CustomStringConvertible {
    /// Failed to create the buffer object.
    case creationFailed

    /// Invalid buffer target or usage.
    case invalidParameter

    public var description: String {
        switch self {
        case .creationFailed:
            return "Failed to create buffer object"
        case .invalidParameter:
            return "Invalid buffer parameter"
        }
    }
}

// MARK: - Vertex Buffer Object

/// A convenience wrapper for vertex buffer objects.
@MainActor
public final class VertexBuffer: Sendable {
    /// The underlying buffer.
    private let buffer: Buffer

    /// The number of components per vertex.
    public let componentCount: Int

    /// The number of vertices.
    public let vertexCount: Int

    /// Creates a vertex buffer from float data.
    ///
    /// - Parameters:
    ///   - context: The WebGL rendering context.
    ///   - data: The vertex data.
    ///   - componentCount: The number of components per vertex (e.g., 3 for xyz).
    ///   - usage: The usage hint (default: staticDraw).
    /// - Throws: `BufferError` if buffer creation fails.
    public init(
        context: JSObject,
        data: [Float],
        componentCount: Int,
        usage: Buffer.Usage = .staticDraw
    ) throws {
        self.buffer = try Buffer(context: context, target: .arrayBuffer, data: data, usage: usage)
        self.componentCount = componentCount
        self.vertexCount = data.count / componentCount
    }

    /// Binds the vertex buffer.
    public func bind() {
        buffer.bind()
    }

    /// Unbinds the vertex buffer.
    public func unbind() {
        buffer.unbind()
    }

    /// Updates the vertex buffer with new data.
    ///
    /// - Parameters:
    ///   - data: The new vertex data.
    ///   - offset: The byte offset at which to start writing (default: 0).
    public func updateData(_ data: [Float], offset: Int = 0) {
        buffer.updateData(data, offset: offset)
    }

    /// Returns the underlying buffer.
    public func getBuffer() -> Buffer {
        buffer
    }
}

// MARK: - Index Buffer Object

/// A convenience wrapper for index buffer objects.
@MainActor
public final class IndexBuffer: Sendable {
    /// The underlying buffer.
    private let buffer: Buffer

    /// The number of indices.
    public let indexCount: Int

    /// The index data type.
    public enum IndexType: Sendable {
        case uint16
        case uint32

        /// Returns the WebGL constant for this index type.
        public var glConstant: Int {
            switch self {
            case .uint16: return 5123 // GL_UNSIGNED_SHORT
            case .uint32: return 5125 // GL_UNSIGNED_INT
            }
        }
    }

    /// The type of indices stored in this buffer.
    public let indexType: IndexType

    /// Creates an index buffer from uint16 data.
    ///
    /// - Parameters:
    ///   - context: The WebGL rendering context.
    ///   - data: The index data.
    ///   - usage: The usage hint (default: staticDraw).
    /// - Throws: `BufferError` if buffer creation fails.
    public init(
        context: JSObject,
        data: [UInt16],
        usage: Buffer.Usage = .staticDraw
    ) throws {
        self.buffer = try Buffer(
            context: context,
            target: .elementArrayBuffer,
            data: data,
            usage: usage
        )
        self.indexCount = data.count
        self.indexType = .uint16
    }

    /// Creates an index buffer from uint32 data.
    ///
    /// - Parameters:
    ///   - context: The WebGL rendering context.
    ///   - data: The index data.
    ///   - usage: The usage hint (default: staticDraw).
    /// - Throws: `BufferError` if buffer creation fails.
    public init(
        context: JSObject,
        data: [UInt32],
        usage: Buffer.Usage = .staticDraw
    ) throws {
        self.buffer = try Buffer(
            context: context,
            target: .elementArrayBuffer,
            data: data,
            usage: usage
        )
        self.indexCount = data.count
        self.indexType = .uint32
    }

    /// Binds the index buffer.
    public func bind() {
        buffer.bind()
    }

    /// Unbinds the index buffer.
    public func unbind() {
        buffer.unbind()
    }

    /// Returns the underlying buffer.
    public func getBuffer() -> Buffer {
        buffer
    }
}
