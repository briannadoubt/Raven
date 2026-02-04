import Foundation
import JavaScriptKit

/// Represents a 3D mesh with vertices, normals, texture coordinates, and indices.
///
/// `Mesh` encapsulates the geometric data needed to render 3D models. It manages
/// vertex positions, normals, texture coordinates, tangents, and index data, along
/// with the WebGL buffers needed for rendering.
///
/// ## Example
///
/// ```swift
/// let mesh = Mesh.cube(context: gl, size: 2.0)
/// mesh.draw(with: program)
/// ```
@MainActor
public final class Mesh: Sendable {
    /// The vertex positions (xyz coordinates).
    public let positions: [Float]

    /// The vertex normals (xyz unit vectors).
    public let normals: [Float]

    /// The texture coordinates (uv coordinates).
    public let texCoords: [Float]

    /// The tangent vectors for normal mapping (optional).
    public let tangents: [Float]?

    /// The vertex indices.
    public let indices: [UInt16]

    /// The position buffer.
    private let positionBuffer: VertexBuffer

    /// The normal buffer.
    private let normalBuffer: VertexBuffer

    /// The texture coordinate buffer.
    private let texCoordBuffer: VertexBuffer

    /// The tangent buffer (optional).
    private let tangentBuffer: VertexBuffer?

    /// The index buffer.
    private let indexBuffer: IndexBuffer

    /// The WebGL rendering context.
    private let gl: JSObject

    /// Creates a mesh from vertex data.
    ///
    /// - Parameters:
    ///   - context: The WebGL rendering context.
    ///   - positions: Vertex positions (must be a multiple of 3).
    ///   - normals: Vertex normals (must be a multiple of 3).
    ///   - texCoords: Texture coordinates (must be a multiple of 2).
    ///   - tangents: Tangent vectors (optional, must be a multiple of 3).
    ///   - indices: Triangle indices.
    /// - Throws: `MeshError` if buffer creation fails.
    public init(
        context: JSObject,
        positions: [Float],
        normals: [Float],
        texCoords: [Float],
        tangents: [Float]? = nil,
        indices: [UInt16]
    ) throws {
        precondition(positions.count % 3 == 0, "Positions must have 3 components per vertex")
        precondition(normals.count % 3 == 0, "Normals must have 3 components per vertex")
        precondition(texCoords.count % 2 == 0, "TexCoords must have 2 components per vertex")
        precondition(positions.count / 3 == normals.count / 3, "Position and normal counts must match")
        precondition(positions.count / 3 == texCoords.count / 2, "Position and texCoord counts must match")

        if let tangents = tangents {
            precondition(tangents.count % 3 == 0, "Tangents must have 3 components per vertex")
            precondition(positions.count == tangents.count, "Position and tangent counts must match")
        }

        self.gl = context
        self.positions = positions
        self.normals = normals
        self.texCoords = texCoords
        self.tangents = tangents
        self.indices = indices

        // Create buffers
        self.positionBuffer = try VertexBuffer(
            context: context,
            data: positions,
            componentCount: 3
        )

        self.normalBuffer = try VertexBuffer(
            context: context,
            data: normals,
            componentCount: 3
        )

        self.texCoordBuffer = try VertexBuffer(
            context: context,
            data: texCoords,
            componentCount: 2
        )

        if let tangents = tangents {
            self.tangentBuffer = try VertexBuffer(
                context: context,
                data: tangents,
                componentCount: 3
            )
        } else {
            self.tangentBuffer = nil
        }

        self.indexBuffer = try IndexBuffer(context: context, data: indices)
    }

    /// The number of vertices in the mesh.
    public var vertexCount: Int {
        positions.count / 3
    }

    /// The number of triangles in the mesh.
    public var triangleCount: Int {
        indices.count / 3
    }

    // MARK: - Rendering

    /// Draws the mesh using the specified program.
    ///
    /// This method binds vertex attributes and draws the mesh geometry.
    ///
    /// - Parameters:
    ///   - program: The shader program to use for rendering.
    ///   - mode: The drawing mode (default: triangles).
    public func draw(with program: Program, mode: DrawMode = .triangles) {
        // Bind position attribute
        positionBuffer.bind()
        program.enableAttribute("aPosition")
        program.setAttributePointer(name: "aPosition", size: 3)

        // Bind normal attribute
        normalBuffer.bind()
        program.enableAttribute("aNormal")
        program.setAttributePointer(name: "aNormal", size: 3)

        // Bind texture coordinate attribute
        texCoordBuffer.bind()
        program.enableAttribute("aTexCoord")
        program.setAttributePointer(name: "aTexCoord", size: 2)

        // Bind tangent attribute if available
        if let tangentBuffer = tangentBuffer {
            tangentBuffer.bind()
            program.enableAttribute("aTangent")
            program.setAttributePointer(name: "aTangent", size: 3)
        }

        // Bind index buffer and draw
        indexBuffer.bind()
        _ = gl.drawElements!(
            mode.glConstant,
            indices.count,
            indexBuffer.indexType.glConstant,
            0
        )
    }

    /// Drawing modes for meshes.
    public enum DrawMode: Sendable {
        case triangles
        case triangleStrip
        case triangleFan
        case lines
        case lineStrip
        case lineLoop
        case points

        fileprivate var glConstant: Int {
            switch self {
            case .triangles: return 4 // GL_TRIANGLES
            case .triangleStrip: return 5 // GL_TRIANGLE_STRIP
            case .triangleFan: return 6 // GL_TRIANGLE_FAN
            case .lines: return 1 // GL_LINES
            case .lineStrip: return 3 // GL_LINE_STRIP
            case .lineLoop: return 2 // GL_LINE_LOOP
            case .points: return 0 // GL_POINTS
            }
        }
    }
}

// MARK: - Mesh Error

/// Errors that can occur during mesh creation.
public enum MeshError: Error, CustomStringConvertible {
    /// Invalid mesh data provided.
    case invalidData(reason: String)

    /// Failed to create mesh buffers.
    case bufferCreationFailed

    public var description: String {
        switch self {
        case .invalidData(let reason):
            return "Invalid mesh data: \(reason)"
        case .bufferCreationFailed:
            return "Failed to create mesh buffers"
        }
    }
}

// MARK: - Primitive Meshes

extension Mesh {
    /// Creates a cube mesh.
    ///
    /// - Parameters:
    ///   - context: The WebGL rendering context.
    ///   - size: The size of the cube (default: 1.0).
    /// - Returns: A cube mesh.
    public static func cube(context: JSObject, size: Float = 1.0) throws -> Mesh {
        let s = size / 2.0

        let positions: [Float] = [
            // Front face
            -s, -s, s,  s, -s, s,  s, s, s,  -s, s, s,
            // Back face
            -s, -s, -s,  -s, s, -s,  s, s, -s,  s, -s, -s,
            // Top face
            -s, s, -s,  -s, s, s,  s, s, s,  s, s, -s,
            // Bottom face
            -s, -s, -s,  s, -s, -s,  s, -s, s,  -s, -s, s,
            // Right face
            s, -s, -s,  s, s, -s,  s, s, s,  s, -s, s,
            // Left face
            -s, -s, -s,  -s, -s, s,  -s, s, s,  -s, s, -s
        ]

        let normals: [Float] = [
            // Front
            0, 0, 1,  0, 0, 1,  0, 0, 1,  0, 0, 1,
            // Back
            0, 0, -1,  0, 0, -1,  0, 0, -1,  0, 0, -1,
            // Top
            0, 1, 0,  0, 1, 0,  0, 1, 0,  0, 1, 0,
            // Bottom
            0, -1, 0,  0, -1, 0,  0, -1, 0,  0, -1, 0,
            // Right
            1, 0, 0,  1, 0, 0,  1, 0, 0,  1, 0, 0,
            // Left
            -1, 0, 0,  -1, 0, 0,  -1, 0, 0,  -1, 0, 0
        ]

        let texCoords: [Float] = [
            // Front
            0, 0,  1, 0,  1, 1,  0, 1,
            // Back
            1, 0,  1, 1,  0, 1,  0, 0,
            // Top
            0, 1,  0, 0,  1, 0,  1, 1,
            // Bottom
            1, 1,  0, 1,  0, 0,  1, 0,
            // Right
            1, 0,  1, 1,  0, 1,  0, 0,
            // Left
            0, 0,  1, 0,  1, 1,  0, 1
        ]

        let indices: [UInt16] = [
            0, 1, 2,  0, 2, 3,    // Front
            4, 5, 6,  4, 6, 7,    // Back
            8, 9, 10,  8, 10, 11, // Top
            12, 13, 14,  12, 14, 15, // Bottom
            16, 17, 18,  16, 18, 19, // Right
            20, 21, 22,  20, 22, 23  // Left
        ]

        return try Mesh(
            context: context,
            positions: positions,
            normals: normals,
            texCoords: texCoords,
            indices: indices
        )
    }

    /// Creates a plane mesh.
    ///
    /// - Parameters:
    ///   - context: The WebGL rendering context.
    ///   - width: The width of the plane (default: 1.0).
    ///   - height: The height of the plane (default: 1.0).
    ///   - subdivisions: The number of subdivisions (default: 1).
    /// - Returns: A plane mesh.
    public static func plane(
        context: JSObject,
        width: Float = 1.0,
        height: Float = 1.0,
        subdivisions: Int = 1
    ) throws -> Mesh {
        let w = width / 2.0
        let h = height / 2.0
        let segsW = max(1, subdivisions)
        let segsH = max(1, subdivisions)

        var positions: [Float] = []
        var normals: [Float] = []
        var texCoords: [Float] = []
        var indices: [UInt16] = []

        // Generate vertices
        for row in 0...segsH {
            let v = Float(row) / Float(segsH)
            let y = -h + v * height

            for col in 0...segsW {
                let u = Float(col) / Float(segsW)
                let x = -w + u * width

                positions.append(contentsOf: [x, y, 0])
                normals.append(contentsOf: [0, 0, 1])
                texCoords.append(contentsOf: [u, v])
            }
        }

        // Generate indices
        for row in 0..<segsH {
            for col in 0..<segsW {
                let a = UInt16(row * (segsW + 1) + col)
                let b = UInt16(a + 1)
                let c = UInt16(a + UInt16(segsW + 1))
                let d = UInt16(c + 1)

                indices.append(contentsOf: [a, b, d, a, d, c])
            }
        }

        return try Mesh(
            context: context,
            positions: positions,
            normals: normals,
            texCoords: texCoords,
            indices: indices
        )
    }

    /// Creates a sphere mesh.
    ///
    /// - Parameters:
    ///   - context: The WebGL rendering context.
    ///   - radius: The radius of the sphere (default: 1.0).
    ///   - segments: The number of segments (default: 32).
    ///   - rings: The number of rings (default: 16).
    /// - Returns: A sphere mesh.
    public static func sphere(
        context: JSObject,
        radius: Float = 1.0,
        segments: Int = 32,
        rings: Int = 16
    ) throws -> Mesh {
        var positions: [Float] = []
        var normals: [Float] = []
        var texCoords: [Float] = []
        var indices: [UInt16] = []

        // Generate vertices
        for ring in 0...rings {
            let v = Float(ring) / Float(rings)
            let phi = v * .pi

            for segment in 0...segments {
                let u = Float(segment) / Float(segments)
                let theta = u * 2.0 * .pi

                let x = -radius * sin(phi) * cos(theta)
                let y = radius * cos(phi)
                let z = radius * sin(phi) * sin(theta)

                positions.append(contentsOf: [x, y, z])

                let nx = -sin(phi) * cos(theta)
                let ny = cos(phi)
                let nz = sin(phi) * sin(theta)
                normals.append(contentsOf: [nx, ny, nz])

                texCoords.append(contentsOf: [u, v])
            }
        }

        // Generate indices
        for ring in 0..<rings {
            for segment in 0..<segments {
                let a = UInt16(ring * (segments + 1) + segment)
                let b = UInt16(a + 1)
                let c = UInt16(a + UInt16(segments + 1))
                let d = UInt16(c + 1)

                indices.append(contentsOf: [a, b, d, a, d, c])
            }
        }

        return try Mesh(
            context: context,
            positions: positions,
            normals: normals,
            texCoords: texCoords,
            indices: indices
        )
    }

    /// Creates a cylinder mesh.
    ///
    /// - Parameters:
    ///   - context: The WebGL rendering context.
    ///   - radius: The radius of the cylinder (default: 1.0).
    ///   - height: The height of the cylinder (default: 2.0).
    ///   - segments: The number of radial segments (default: 32).
    /// - Returns: A cylinder mesh.
    public static func cylinder(
        context: JSObject,
        radius: Float = 1.0,
        height: Float = 2.0,
        segments: Int = 32
    ) throws -> Mesh {
        var positions: [Float] = []
        var normals: [Float] = []
        var texCoords: [Float] = []
        var indices: [UInt16] = []

        let halfHeight = height / 2.0

        // Generate side vertices
        for ring in 0...1 {
            let y = halfHeight - Float(ring) * height

            for segment in 0...segments {
                let u = Float(segment) / Float(segments)
                let theta = u * 2.0 * .pi

                let x = radius * cos(theta)
                let z = radius * sin(theta)

                positions.append(contentsOf: [x, y, z])
                normals.append(contentsOf: [cos(theta), 0, sin(theta)])
                texCoords.append(contentsOf: [u, Float(ring)])
            }
        }

        // Generate side indices
        for segment in 0..<segments {
            let a = UInt16(segment)
            let b = UInt16(a + 1)
            let c = UInt16(a + UInt16(segments + 1))
            let d = UInt16(c + 1)

            indices.append(contentsOf: [a, b, d, a, d, c])
        }

        return try Mesh(
            context: context,
            positions: positions,
            normals: normals,
            texCoords: texCoords,
            indices: indices
        )
    }
}
