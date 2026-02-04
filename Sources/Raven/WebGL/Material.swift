import Foundation
import JavaScriptKit

/// Represents a PBR (Physically Based Rendering) material for 3D meshes.
///
/// `Material` encapsulates the visual properties of a surface, including
/// albedo (base color), metallic, roughness, and various texture maps.
/// It follows the metallic-roughness workflow commonly used in modern
/// real-time rendering.
///
/// ## Example
///
/// ```swift
/// var material = Material()
/// material.albedo = [0.8, 0.2, 0.2, 1.0]
/// material.metallic = 0.0
/// material.roughness = 0.5
///
/// material.apply(to: program)
/// ```
public struct Material: Sendable {
    // MARK: - Color Properties

    /// The base color (albedo) of the material [r, g, b, a].
    public var albedo: [Float]

    /// The metallic factor (0 = dielectric, 1 = metal).
    public var metallic: Float

    /// The roughness factor (0 = smooth, 1 = rough).
    public var roughness: Float

    /// The ambient occlusion factor.
    public var ao: Float

    // MARK: - Texture Maps

    /// The albedo (base color) texture.
    public var albedoMap: Texture?

    /// The normal map for surface detail.
    public var normalMap: Texture?

    /// The metallic-roughness texture (metallic in B, roughness in G).
    public var metallicRoughnessMap: Texture?

    /// The ambient occlusion texture.
    public var aoMap: Texture?

    /// The emissive texture.
    public var emissiveMap: Texture?

    // MARK: - Additional Properties

    /// The emissive color [r, g, b].
    public var emissive: [Float]

    /// Whether the material is double-sided.
    public var doubleSided: Bool

    /// The alpha cutoff threshold for alpha testing.
    public var alphaCutoff: Float

    /// The blend mode for transparency.
    public enum BlendMode: Sendable {
        case opaque
        case blend
        case mask
    }

    /// The blend mode of the material.
    public var blendMode: BlendMode

    // MARK: - Initialization

    /// Creates a material with default properties.
    ///
    /// Default material is white, non-metallic, with medium roughness.
    public init() {
        self.albedo = [1.0, 1.0, 1.0, 1.0]
        self.metallic = 0.0
        self.roughness = 0.5
        self.ao = 1.0
        self.emissive = [0.0, 0.0, 0.0]
        self.doubleSided = false
        self.alphaCutoff = 0.5
        self.blendMode = .opaque
    }

    /// Creates a material with specified color properties.
    ///
    /// - Parameters:
    ///   - albedo: The base color [r, g, b, a].
    ///   - metallic: The metallic factor (0-1).
    ///   - roughness: The roughness factor (0-1).
    ///   - ao: The ambient occlusion factor (0-1).
    public init(albedo: [Float], metallic: Float = 0.0, roughness: Float = 0.5, ao: Float = 1.0) {
        self.albedo = albedo
        self.metallic = metallic
        self.roughness = roughness
        self.ao = ao
        self.emissive = [0.0, 0.0, 0.0]
        self.doubleSided = false
        self.alphaCutoff = 0.5
        self.blendMode = .opaque
    }

    // MARK: - Application

    /// Applies this material's properties to a shader program.
    ///
    /// This method sets all relevant uniforms on the program.
    ///
    /// - Parameter program: The shader program to apply the material to.
    @MainActor
    public func apply(to program: Program) {
        // Set color properties
        program.setUniform("uAlbedo", x: albedo[0], y: albedo[1], z: albedo[2], w: albedo[3])
        program.setUniform("uMetallic", value: metallic)
        program.setUniform("uRoughness", value: roughness)
        program.setUniform("uAO", value: ao)
        program.setUniform("uEmissive", x: emissive[0], y: emissive[1], z: emissive[2])

        // Bind textures and set texture flags
        var textureUnit = 0

        if let albedoMap = albedoMap {
            albedoMap.bind(unit: textureUnit)
            program.setUniform("uAlbedoMap", value: textureUnit)
            program.setUniform("uUseAlbedoMap", value: true)
            textureUnit += 1
        } else {
            program.setUniform("uUseAlbedoMap", value: false)
        }

        if let normalMap = normalMap {
            normalMap.bind(unit: textureUnit)
            program.setUniform("uNormalMap", value: textureUnit)
            program.setUniform("uUseNormalMap", value: true)
            textureUnit += 1
        } else {
            program.setUniform("uUseNormalMap", value: false)
        }

        if let metallicRoughnessMap = metallicRoughnessMap {
            metallicRoughnessMap.bind(unit: textureUnit)
            program.setUniform("uMetallicRoughnessMap", value: textureUnit)
            program.setUniform("uUseMetallicRoughnessMap", value: true)
            textureUnit += 1
        } else {
            program.setUniform("uUseMetallicRoughnessMap", value: false)
        }

        if let aoMap = aoMap {
            aoMap.bind(unit: textureUnit)
            program.setUniform("uAOMap", value: textureUnit)
            program.setUniform("uUseAOMap", value: true)
            textureUnit += 1
        } else {
            program.setUniform("uUseAOMap", value: false)
        }

        if let emissiveMap = emissiveMap {
            emissiveMap.bind(unit: textureUnit)
            program.setUniform("uEmissiveMap", value: textureUnit)
            program.setUniform("uUseEmissiveMap", value: true)
            textureUnit += 1
        } else {
            program.setUniform("uUseEmissiveMap", value: false)
        }
    }
}

// MARK: - Preset Materials

extension Material {
    /// A white matte material (non-metallic, medium roughness).
    public static var white: Material {
        Material(albedo: [1.0, 1.0, 1.0, 1.0], metallic: 0.0, roughness: 0.5)
    }

    /// A black matte material.
    public static var black: Material {
        Material(albedo: [0.0, 0.0, 0.0, 1.0], metallic: 0.0, roughness: 0.5)
    }

    /// A red matte material.
    public static var red: Material {
        Material(albedo: [1.0, 0.0, 0.0, 1.0], metallic: 0.0, roughness: 0.5)
    }

    /// A green matte material.
    public static var green: Material {
        Material(albedo: [0.0, 1.0, 0.0, 1.0], metallic: 0.0, roughness: 0.5)
    }

    /// A blue matte material.
    public static var blue: Material {
        Material(albedo: [0.0, 0.0, 1.0, 1.0], metallic: 0.0, roughness: 0.5)
    }

    /// A gold metal material.
    public static var gold: Material {
        Material(albedo: [1.0, 0.765, 0.336, 1.0], metallic: 1.0, roughness: 0.2)
    }

    /// A silver metal material.
    public static var silver: Material {
        Material(albedo: [0.972, 0.960, 0.915, 1.0], metallic: 1.0, roughness: 0.2)
    }

    /// A copper metal material.
    public static var copper: Material {
        Material(albedo: [0.955, 0.637, 0.538, 1.0], metallic: 1.0, roughness: 0.3)
    }

    /// An iron metal material.
    public static var iron: Material {
        Material(albedo: [0.560, 0.570, 0.580, 1.0], metallic: 1.0, roughness: 0.4)
    }

    /// A chrome metal material (very reflective).
    public static var chrome: Material {
        Material(albedo: [0.549, 0.556, 0.554, 1.0], metallic: 1.0, roughness: 0.05)
    }

    /// A plastic material.
    public static var plastic: Material {
        Material(albedo: [0.5, 0.5, 0.5, 1.0], metallic: 0.0, roughness: 0.3)
    }

    /// A rubber material.
    public static var rubber: Material {
        Material(albedo: [0.2, 0.2, 0.2, 1.0], metallic: 0.0, roughness: 0.8)
    }

    /// A glass material (transparent).
    public static var glass: Material {
        var material = Material(albedo: [0.95, 0.95, 0.95, 0.3], metallic: 0.0, roughness: 0.0)
        material.blendMode = .blend
        return material
    }

    /// A wood material.
    public static var wood: Material {
        Material(albedo: [0.545, 0.353, 0.169, 1.0], metallic: 0.0, roughness: 0.7)
    }

    /// A stone material.
    public static var stone: Material {
        Material(albedo: [0.5, 0.5, 0.5, 1.0], metallic: 0.0, roughness: 0.9)
    }
}

// MARK: - Material Builder

extension Material {
    /// Sets the albedo color.
    ///
    /// - Parameter color: The albedo color [r, g, b, a].
    /// - Returns: The material with updated albedo.
    public func withAlbedo(_ color: [Float]) -> Material {
        var material = self
        material.albedo = color
        return material
    }

    /// Sets the metallic factor.
    ///
    /// - Parameter metallic: The metallic factor (0-1).
    /// - Returns: The material with updated metallic value.
    public func withMetallic(_ metallic: Float) -> Material {
        var material = self
        material.metallic = metallic
        return material
    }

    /// Sets the roughness factor.
    ///
    /// - Parameter roughness: The roughness factor (0-1).
    /// - Returns: The material with updated roughness value.
    public func withRoughness(_ roughness: Float) -> Material {
        var material = self
        material.roughness = roughness
        return material
    }

    /// Sets the albedo texture map.
    ///
    /// - Parameter texture: The albedo texture.
    /// - Returns: The material with updated albedo map.
    public func withAlbedoMap(_ texture: Texture?) -> Material {
        var material = self
        material.albedoMap = texture
        return material
    }

    /// Sets the normal map.
    ///
    /// - Parameter texture: The normal map texture.
    /// - Returns: The material with updated normal map.
    public func withNormalMap(_ texture: Texture?) -> Material {
        var material = self
        material.normalMap = texture
        return material
    }

    /// Sets the metallic-roughness map.
    ///
    /// - Parameter texture: The metallic-roughness texture.
    /// - Returns: The material with updated metallic-roughness map.
    public func withMetallicRoughnessMap(_ texture: Texture?) -> Material {
        var material = self
        material.metallicRoughnessMap = texture
        return material
    }

    /// Sets the ambient occlusion map.
    ///
    /// - Parameter texture: The AO texture.
    /// - Returns: The material with updated AO map.
    public func withAOMap(_ texture: Texture?) -> Material {
        var material = self
        material.aoMap = texture
        return material
    }

    /// Sets the emissive color.
    ///
    /// - Parameter color: The emissive color [r, g, b].
    /// - Returns: The material with updated emissive color.
    public func withEmissive(_ color: [Float]) -> Material {
        var material = self
        material.emissive = color
        return material
    }

    /// Sets whether the material is double-sided.
    ///
    /// - Parameter doubleSided: Whether the material is double-sided.
    /// - Returns: The material with updated double-sided flag.
    public func withDoubleSided(_ doubleSided: Bool) -> Material {
        var material = self
        material.doubleSided = doubleSided
        return material
    }

    /// Sets the blend mode.
    ///
    /// - Parameter blendMode: The blend mode.
    /// - Returns: The material with updated blend mode.
    public func withBlendMode(_ blendMode: BlendMode) -> Material {
        var material = self
        material.blendMode = blendMode
        return material
    }
}
