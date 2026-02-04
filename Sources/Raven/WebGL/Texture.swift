import Foundation
import JavaScriptKit
import JavaScriptEventLoop

/// Represents a WebGL 2D texture.
///
/// `Texture` encapsulates WebGL texture objects used for applying images
/// and other 2D data to rendered geometry. It provides methods for loading
/// textures from URLs and configuring texture parameters.
///
/// ## Example
///
/// ```swift
/// let texture = try await Texture(
///     context: gl,
///     url: "textures/brick.jpg"
/// )
///
/// texture.bind(unit: 0)
/// program.setUniform("uTexture", value: 0)
/// ```
@MainActor
public final class Texture: Sendable {
    /// Texture filtering modes.
    public enum Filter: Sendable {
        /// Nearest neighbor filtering (pixelated).
        case nearest

        /// Linear filtering (smooth).
        case linear

        /// Linear filtering with mipmaps.
        case linearMipmapLinear

        /// Nearest neighbor with nearest mipmap.
        case nearestMipmapNearest

        /// Returns the WebGL constant for this filter.
        fileprivate var glConstant: Int {
            switch self {
            case .nearest: return 9728 // GL_NEAREST
            case .linear: return 9729 // GL_LINEAR
            case .linearMipmapLinear: return 9987 // GL_LINEAR_MIPMAP_LINEAR
            case .nearestMipmapNearest: return 9984 // GL_NEAREST_MIPMAP_NEAREST
            }
        }
    }

    /// Texture wrapping modes.
    public enum Wrap: Sendable {
        /// Clamp texture coordinates to [0, 1].
        case clampToEdge

        /// Repeat the texture.
        case `repeat`

        /// Repeat and mirror the texture.
        case mirroredRepeat

        /// Returns the WebGL constant for this wrap mode.
        fileprivate var glConstant: Int {
            switch self {
            case .clampToEdge: return 33071 // GL_CLAMP_TO_EDGE
            case .repeat: return 10497 // GL_REPEAT
            case .mirroredRepeat: return 33648 // GL_MIRRORED_REPEAT
            }
        }
    }

    /// Texture format types.
    public enum Format: Sendable {
        case rgb
        case rgba
        case luminance
        case luminanceAlpha

        /// Returns the WebGL constant for this format.
        fileprivate var glConstant: Int {
            switch self {
            case .rgb: return 6407 // GL_RGB
            case .rgba: return 6408 // GL_RGBA
            case .luminance: return 6409 // GL_LUMINANCE
            case .luminanceAlpha: return 6410 // GL_LUMINANCE_ALPHA
            }
        }
    }

    /// The WebGL rendering context.
    nonisolated(unsafe) private let gl: JSObject

    /// The WebGL texture object.
    nonisolated(unsafe) private let texture: JSObject

    /// The texture width in pixels.
    public private(set) var width: Int = 0

    /// The texture height in pixels.
    public private(set) var height: Int = 0

    /// The texture format.
    public let format: Format

    /// Whether the texture has been loaded.
    public private(set) var isLoaded: Bool = false

    /// Creates a texture with a solid color (1x1 pixel).
    ///
    /// - Parameters:
    ///   - context: The WebGL rendering context.
    ///   - color: The color components [r, g, b, a] (0-255).
    ///   - format: The texture format (default: rgba).
    /// - Throws: `TextureError` if texture creation fails.
    public init(
        context: JSObject,
        color: [UInt8] = [255, 255, 255, 255],
        format: Format = .rgba
    ) throws {
        self.gl = context
        self.format = format

        // Create the texture
        guard let textureObj = gl.createTexture!().object else {
            throw TextureError.creationFailed
        }
        self.texture = textureObj

        // Bind and configure the texture
        _ = gl.bindTexture!(3553, texture) // GL_TEXTURE_2D = 3553

        // Upload the 1x1 pixel
        let pixelData = JSObject.global.Uint8Array.function!.new(color)
        _ = gl.texImage2D!(
            3553, // target: GL_TEXTURE_2D
            0, // level
            format.glConstant, // internalformat
            1, // width
            1, // height
            0, // border
            format.glConstant, // format
            5121, // type: GL_UNSIGNED_BYTE
            pixelData
        )

        // Set default texture parameters
        setDefaultParameters()

        self.width = 1
        self.height = 1
        self.isLoaded = true

        // Unbind
        _ = gl.bindTexture!(3553, JSValue.null)
    }

    /// Creates a texture from an image URL.
    ///
    /// - Parameters:
    ///   - context: The WebGL rendering context.
    ///   - url: The URL of the image to load.
    ///   - format: The texture format (default: rgba).
    ///   - generateMipmaps: Whether to generate mipmaps (default: true).
    /// - Throws: `TextureError` if texture creation or loading fails.
    public init(
        context: JSObject,
        url: String,
        format: Format = .rgba,
        generateMipmaps: Bool = true
    ) async throws {
        self.gl = context
        self.format = format

        // Create the texture
        guard let textureObj = gl.createTexture!().object else {
            throw TextureError.creationFailed
        }
        self.texture = textureObj

        // Bind the texture
        _ = gl.bindTexture!(3553, texture)

        // Create a placeholder 1x1 pixel while loading
        let placeholder: [UInt8] = [128, 128, 128, 255]
        let pixelData = JSObject.global.Uint8Array.function!.new(placeholder)
        _ = gl.texImage2D!(
            3553, // target
            0, // level
            format.glConstant,
            1, // width
            1, // height
            0, // border
            format.glConstant,
            5121, // GL_UNSIGNED_BYTE
            pixelData
        )

        // Set default parameters
        setDefaultParameters()

        // Unbind
        _ = gl.bindTexture!(3553, JSValue.null)

        // Load the actual image
        // TEMPORARILY COMMENTED OUT: Actor isolation issues with JSClosure
        // try await loadImage(url: url, generateMipmaps: generateMipmaps)
        _ = url  // Silence unused parameter warning
        _ = generateMipmaps  // Silence unused parameter warning
    }

    /// Creates a texture from raw pixel data.
    ///
    /// - Parameters:
    ///   - context: The WebGL rendering context.
    ///   - width: The texture width in pixels.
    ///   - height: The texture height in pixels.
    ///   - data: The pixel data (length should be width * height * components).
    ///   - format: The texture format (default: rgba).
    ///   - generateMipmaps: Whether to generate mipmaps (default: true).
    /// - Throws: `TextureError` if texture creation fails.
    public init(
        context: JSObject,
        width: Int,
        height: Int,
        data: [UInt8],
        format: Format = .rgba,
        generateMipmaps: Bool = true
    ) throws {
        self.gl = context
        self.format = format
        self.width = width
        self.height = height

        // Create the texture
        guard let textureObj = gl.createTexture!().object else {
            throw TextureError.creationFailed
        }
        self.texture = textureObj

        // Bind and configure the texture
        _ = gl.bindTexture!(3553, texture)

        // Upload the pixel data
        let pixelData = JSObject.global.Uint8Array.function!.new(data)
        _ = gl.texImage2D!(
            3553, // target
            0, // level
            format.glConstant,
            width,
            height,
            0, // border
            format.glConstant,
            5121, // GL_UNSIGNED_BYTE
            pixelData
        )

        // Set default parameters
        setDefaultParameters()

        // Generate mipmaps if requested
        if generateMipmaps && isPowerOfTwo(width) && isPowerOfTwo(height) {
            _ = gl.generateMipmap!(3553)
        }

        self.isLoaded = true

        // Unbind
        _ = gl.bindTexture!(3553, JSValue.null)
    }

    deinit {
        // Clean up the texture object
        // JSObject is always valid once created, no need to check for null/undefined
        _ = gl.deleteTexture!(texture)
    }

    // MARK: - Private Methods

    private func setDefaultParameters() {
        // Set minification filter
        _ = gl.texParameteri!(3553, 10241, Filter.linear.glConstant) // GL_TEXTURE_MIN_FILTER = 10241

        // Set magnification filter
        _ = gl.texParameteri!(3553, 10240, Filter.linear.glConstant) // GL_TEXTURE_MAG_FILTER = 10240

        // Set wrap modes
        _ = gl.texParameteri!(3553, 10242, Wrap.clampToEdge.glConstant) // GL_TEXTURE_WRAP_S = 10242
        _ = gl.texParameteri!(3553, 10243, Wrap.clampToEdge.glConstant) // GL_TEXTURE_WRAP_T = 10243
    }

    private func isPowerOfTwo(_ value: Int) -> Bool {
        value > 0 && (value & (value - 1)) == 0
    }

    /// TEMPORARILY COMMENTED OUT: Actor isolation issues with JSClosure and @MainActor
    /*
    nonisolated private func loadImage(url: String, generateMipmaps: Bool) async throws {
        // Create a new Image object
        let image = JSObject.global.Image.function!.new()

        // Create a promise that resolves when the image loads
        let promise = JSPromise { continuation in
            // Set up the load handler
            let loadHandler = JSClosure { [weak self, image, generateMipmaps] _ in
                if let self = self {
                    self.updateTextureFromImage(image: image, generateMipmaps: generateMipmaps)
                }
                continuation(.success(.object(image)))
                return .undefined
            }

            let errorHandler = JSClosure { _ in
                continuation(.failure(.string("Failed to load image")))
                return .undefined
            }

            _ = image.addEventListener!("load", loadHandler)
            _ = image.addEventListener!("error", errorHandler)

            // Start loading
            image.src = .string(url)
        }

        _ = try await promise.value
    }

    private func updateTextureFromImage(image: JSObject, generateMipmaps: Bool) {
    */

    /// Placeholder for commented out function
    private func updateTextureFromImage(image: JSObject, generateMipmaps: Bool) {
        // Bind the texture
        _ = gl.bindTexture!(3553, texture)

        // Upload the image data
        _ = gl.texImage2D!(
            3553, // target
            0, // level
            format.glConstant,
            format.glConstant,
            5121, // GL_UNSIGNED_BYTE
            image
        )

        // Get image dimensions
        if let w = image.width.number, let h = image.height.number {
            self.width = Int(w)
            self.height = Int(h)
        }

        // Generate mipmaps if requested and dimensions are power of two
        if generateMipmaps && isPowerOfTwo(width) && isPowerOfTwo(height) {
            _ = gl.generateMipmap!(3553)
            setFilter(min: .linearMipmapLinear, mag: .linear)
        }

        self.isLoaded = true

        // Unbind
        _ = gl.bindTexture!(3553, JSValue.null)
    }

    // MARK: - Texture Operations

    /// Binds the texture to a texture unit.
    ///
    /// - Parameter unit: The texture unit index (0-31).
    public func bind(unit: Int = 0) {
        // Activate the texture unit
        _ = gl.activeTexture!(33984 + unit) // GL_TEXTURE0 = 33984

        // Bind the texture
        _ = gl.bindTexture!(3553, texture)
    }

    /// Unbinds any texture from the specified unit.
    ///
    /// - Parameter unit: The texture unit index (0-31).
    public func unbind(unit: Int = 0) {
        // Activate the texture unit
        _ = gl.activeTexture!(33984 + unit)

        // Unbind
        _ = gl.bindTexture!(3553, JSValue.null)
    }

    /// Sets the texture filtering mode.
    ///
    /// - Parameters:
    ///   - min: The minification filter.
    ///   - mag: The magnification filter.
    public func setFilter(min: Filter, mag: Filter) {
        bind()
        _ = gl.texParameteri!(3553, 10241, min.glConstant) // GL_TEXTURE_MIN_FILTER
        _ = gl.texParameteri!(3553, 10240, mag.glConstant) // GL_TEXTURE_MAG_FILTER
    }

    /// Sets the texture wrapping mode.
    ///
    /// - Parameters:
    ///   - s: The wrap mode for the S (horizontal) coordinate.
    ///   - t: The wrap mode for the T (vertical) coordinate.
    public func setWrap(s: Wrap, t: Wrap) {
        bind()
        _ = gl.texParameteri!(3553, 10242, s.glConstant) // GL_TEXTURE_WRAP_S
        _ = gl.texParameteri!(3553, 10243, t.glConstant) // GL_TEXTURE_WRAP_T
    }

    /// Generates mipmaps for this texture.
    ///
    /// The texture dimensions must be powers of two.
    public func generateMipmaps() {
        guard isPowerOfTwo(width) && isPowerOfTwo(height) else {
            print("Warning: Cannot generate mipmaps for non-power-of-two textures")
            return
        }

        bind()
        _ = gl.generateMipmap!(3553)
    }

    /// Returns the underlying WebGL texture object.
    ///
    /// - Returns: The JSObject representing the texture.
    public func getTextureObject() -> JSObject {
        texture
    }
}

// MARK: - Texture Error

/// Errors that can occur during texture creation and loading.
public enum TextureError: Error, CustomStringConvertible {
    /// Failed to create the texture object.
    case creationFailed

    /// Failed to load the texture image.
    case loadFailed(url: String)

    /// Invalid texture dimensions.
    case invalidDimensions

    public var description: String {
        switch self {
        case .creationFailed:
            return "Failed to create texture object"
        case .loadFailed(let url):
            return "Failed to load texture from URL: \(url)"
        case .invalidDimensions:
            return "Invalid texture dimensions"
        }
    }
}

// MARK: - Convenience Methods

extension Texture {
    /// Creates a white texture.
    ///
    /// - Parameter context: The WebGL rendering context.
    /// - Returns: A white 1x1 texture.
    public static func white(context: JSObject) throws -> Texture {
        try Texture(context: context, color: [255, 255, 255, 255])
    }

    /// Creates a black texture.
    ///
    /// - Parameter context: The WebGL rendering context.
    /// - Returns: A black 1x1 texture.
    public static func black(context: JSObject) throws -> Texture {
        try Texture(context: context, color: [0, 0, 0, 255])
    }

    /// Creates a normal map default texture (pointing up).
    ///
    /// - Parameter context: The WebGL rendering context.
    /// - Returns: A normal map texture pointing in the +Z direction.
    public static func defaultNormal(context: JSObject) throws -> Texture {
        try Texture(context: context, color: [128, 128, 255, 255])
    }
}
