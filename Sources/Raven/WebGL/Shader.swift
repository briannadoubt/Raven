import Foundation
import JavaScriptKit
import JavaScriptEventLoop

/// Represents a compiled WebGL shader (vertex or fragment).
///
/// `Shader` encapsulates the compilation of GLSL shader source code into
/// a WebGL shader object. It supports both vertex and fragment shaders and
/// provides error handling for compilation failures.
///
/// ## Example
///
/// ```swift
/// let vertexSource = """
/// attribute vec3 position;
/// uniform mat4 modelViewProjection;
///
/// void main() {
///     gl_Position = modelViewProjection * vec4(position, 1.0);
/// }
/// """
///
/// let shader = try await Shader(
///     context: glContext,
///     type: .vertex,
///     source: vertexSource
/// )
/// ```
@MainActor
public final class Shader: Sendable {
    /// The type of shader.
    public enum ShaderType: Sendable {
        /// A vertex shader that processes vertex data.
        case vertex

        /// A fragment shader that processes pixel data.
        case fragment

        /// Returns the WebGL constant for this shader type.
        fileprivate var glConstant: Int {
            switch self {
            case .vertex: return 35633 // GL_VERTEX_SHADER
            case .fragment: return 35632 // GL_FRAGMENT_SHADER
            }
        }
    }

    /// The WebGL rendering context.
    nonisolated(unsafe) private let gl: JSObject

    /// The compiled WebGL shader object.
    nonisolated(unsafe) private let shader: JSObject

    /// The type of this shader.
    public let type: ShaderType

    /// The shader source code.
    public let source: String

    /// Creates and compiles a shader from GLSL source code.
    ///
    /// - Parameters:
    ///   - context: The WebGL rendering context.
    ///   - type: The type of shader (vertex or fragment).
    ///   - source: The GLSL shader source code.
    /// - Throws: `ShaderError` if compilation fails.
    public init(context: JSObject, type: ShaderType, source: String) throws {
        self.gl = context
        self.type = type
        self.source = source

        // Create the shader
        guard let shaderObj = gl.createShader!(type.glConstant).object else {
            throw ShaderError.creationFailed
        }
        self.shader = shaderObj

        // Set the shader source
        _ = gl.shaderSource!(shader, source)

        // Compile the shader
        _ = gl.compileShader!(shader)

        // Check for compilation errors
        let compileStatus = gl.getShaderParameter!(shader, 35713) // GL_COMPILE_STATUS
        if compileStatus.isNull || compileStatus.isUndefined || !(compileStatus.boolean ?? false) {
            let log = gl.getShaderInfoLog!(shader).string ?? "Unknown error"
            _ = gl.deleteShader!(shader)
            throw ShaderError.compilationFailed(log: log)
        }
    }

    deinit {
        // Clean up the shader object
        // JSObject is always valid once created, no need to check for null/undefined
        _ = gl.deleteShader!(shader)
    }

    /// Returns the underlying WebGL shader object.
    ///
    /// - Returns: The JSObject representing the compiled shader.
    public func getShaderObject() -> JSObject {
        shader
    }
}

// MARK: - Shader Error

/// Errors that can occur during shader creation and compilation.
public enum ShaderError: Error, CustomStringConvertible {
    /// Failed to create the shader object.
    case creationFailed

    /// Shader compilation failed with the given log message.
    case compilationFailed(log: String)

    public var description: String {
        switch self {
        case .creationFailed:
            return "Failed to create shader object"
        case .compilationFailed(let log):
            return "Shader compilation failed: \(log)"
        }
    }
}

// MARK: - Common Shader Sources

extension Shader {
    /// A basic vertex shader that passes through positions and texture coordinates.
    public static let defaultVertexSource = """
    attribute vec3 aPosition;
    attribute vec2 aTexCoord;
    attribute vec3 aNormal;

    uniform mat4 uModelViewProjection;
    uniform mat4 uModel;
    uniform mat4 uNormalMatrix;

    varying vec2 vTexCoord;
    varying vec3 vNormal;
    varying vec3 vWorldPosition;

    void main() {
        vTexCoord = aTexCoord;
        vNormal = mat3(uNormalMatrix) * aNormal;
        vec4 worldPos = uModel * vec4(aPosition, 1.0);
        vWorldPosition = worldPos.xyz;
        gl_Position = uModelViewProjection * vec4(aPosition, 1.0);
    }
    """

    /// A basic fragment shader with diffuse lighting.
    public static let defaultFragmentSource = """
    precision mediump float;

    varying vec2 vTexCoord;
    varying vec3 vNormal;
    varying vec3 vWorldPosition;

    uniform sampler2D uTexture;
    uniform vec3 uLightPosition;
    uniform vec3 uLightColor;
    uniform vec3 uAmbientLight;
    uniform vec4 uBaseColor;
    uniform bool uUseTexture;

    void main() {
        vec4 baseColor = uUseTexture ? texture2D(uTexture, vTexCoord) : uBaseColor;

        // Normalize the normal vector
        vec3 normal = normalize(vNormal);

        // Calculate light direction
        vec3 lightDir = normalize(uLightPosition - vWorldPosition);

        // Calculate diffuse lighting
        float diff = max(dot(normal, lightDir), 0.0);
        vec3 diffuse = diff * uLightColor;

        // Combine ambient and diffuse lighting
        vec3 lighting = uAmbientLight + diffuse;

        // Apply lighting to base color
        vec3 finalColor = baseColor.rgb * lighting;

        gl_FragColor = vec4(finalColor, baseColor.a);
    }
    """

    /// A simple unlit vertex shader.
    public static let unlitVertexSource = """
    attribute vec3 aPosition;
    attribute vec2 aTexCoord;

    uniform mat4 uModelViewProjection;

    varying vec2 vTexCoord;

    void main() {
        vTexCoord = aTexCoord;
        gl_Position = uModelViewProjection * vec4(aPosition, 1.0);
    }
    """

    /// A simple unlit fragment shader.
    public static let unlitFragmentSource = """
    precision mediump float;

    varying vec2 vTexCoord;

    uniform sampler2D uTexture;
    uniform vec4 uBaseColor;
    uniform bool uUseTexture;

    void main() {
        vec4 color = uUseTexture ? texture2D(uTexture, vTexCoord) : uBaseColor;
        gl_FragColor = color;
    }
    """

    /// A PBR (Physically Based Rendering) vertex shader.
    public static let pbrVertexSource = """
    attribute vec3 aPosition;
    attribute vec2 aTexCoord;
    attribute vec3 aNormal;
    attribute vec3 aTangent;

    uniform mat4 uModelViewProjection;
    uniform mat4 uModel;
    uniform mat4 uNormalMatrix;

    varying vec2 vTexCoord;
    varying vec3 vNormal;
    varying vec3 vWorldPosition;
    varying mat3 vTBN;

    void main() {
        vTexCoord = aTexCoord;

        vec3 T = normalize(mat3(uNormalMatrix) * aTangent);
        vec3 N = normalize(mat3(uNormalMatrix) * aNormal);
        vec3 B = cross(N, T);
        vTBN = mat3(T, B, N);

        vNormal = N;
        vec4 worldPos = uModel * vec4(aPosition, 1.0);
        vWorldPosition = worldPos.xyz;
        gl_Position = uModelViewProjection * vec4(aPosition, 1.0);
    }
    """

    /// A PBR (Physically Based Rendering) fragment shader.
    public static let pbrFragmentSource = """
    precision mediump float;

    varying vec2 vTexCoord;
    varying vec3 vNormal;
    varying vec3 vWorldPosition;
    varying mat3 vTBN;

    uniform sampler2D uAlbedoMap;
    uniform sampler2D uNormalMap;
    uniform sampler2D uMetallicRoughnessMap;
    uniform sampler2D uAOMap;

    uniform vec3 uCameraPosition;
    uniform vec3 uLightPosition;
    uniform vec3 uLightColor;

    uniform vec4 uAlbedo;
    uniform float uMetallic;
    uniform float uRoughness;
    uniform float uAO;

    uniform bool uUseAlbedoMap;
    uniform bool uUseNormalMap;
    uniform bool uUseMetallicRoughnessMap;
    uniform bool uUseAOMap;

    const float PI = 3.14159265359;

    vec3 fresnelSchlick(float cosTheta, vec3 F0) {
        return F0 + (1.0 - F0) * pow(1.0 - cosTheta, 5.0);
    }

    float distributionGGX(vec3 N, vec3 H, float roughness) {
        float a = roughness * roughness;
        float a2 = a * a;
        float NdotH = max(dot(N, H), 0.0);
        float NdotH2 = NdotH * NdotH;

        float num = a2;
        float denom = (NdotH2 * (a2 - 1.0) + 1.0);
        denom = PI * denom * denom;

        return num / denom;
    }

    float geometrySchlickGGX(float NdotV, float roughness) {
        float r = (roughness + 1.0);
        float k = (r * r) / 8.0;

        float num = NdotV;
        float denom = NdotV * (1.0 - k) + k;

        return num / denom;
    }

    float geometrySmith(vec3 N, vec3 V, vec3 L, float roughness) {
        float NdotV = max(dot(N, V), 0.0);
        float NdotL = max(dot(N, L), 0.0);
        float ggx2 = geometrySchlickGGX(NdotV, roughness);
        float ggx1 = geometrySchlickGGX(NdotL, roughness);

        return ggx1 * ggx2;
    }

    void main() {
        vec3 albedo = uUseAlbedoMap ? texture2D(uAlbedoMap, vTexCoord).rgb : uAlbedo.rgb;
        float metallic = uUseMetallicRoughnessMap ? texture2D(uMetallicRoughnessMap, vTexCoord).b : uMetallic;
        float roughness = uUseMetallicRoughnessMap ? texture2D(uMetallicRoughnessMap, vTexCoord).g : uRoughness;
        float ao = uUseAOMap ? texture2D(uAOMap, vTexCoord).r : uAO;

        vec3 N = vNormal;
        if (uUseNormalMap) {
            N = texture2D(uNormalMap, vTexCoord).rgb;
            N = N * 2.0 - 1.0;
            N = normalize(vTBN * N);
        }

        vec3 V = normalize(uCameraPosition - vWorldPosition);
        vec3 L = normalize(uLightPosition - vWorldPosition);
        vec3 H = normalize(V + L);

        vec3 F0 = vec3(0.04);
        F0 = mix(F0, albedo, metallic);

        vec3 F = fresnelSchlick(max(dot(H, V), 0.0), F0);
        float NDF = distributionGGX(N, H, roughness);
        float G = geometrySmith(N, V, L, roughness);

        vec3 numerator = NDF * G * F;
        float denominator = 4.0 * max(dot(N, V), 0.0) * max(dot(N, L), 0.0) + 0.001;
        vec3 specular = numerator / denominator;

        vec3 kS = F;
        vec3 kD = vec3(1.0) - kS;
        kD *= 1.0 - metallic;

        float NdotL = max(dot(N, L), 0.0);
        vec3 Lo = (kD * albedo / PI + specular) * uLightColor * NdotL;

        vec3 ambient = vec3(0.03) * albedo * ao;
        vec3 color = ambient + Lo;

        color = color / (color + vec3(1.0));
        color = pow(color, vec3(1.0/2.2));

        gl_FragColor = vec4(color, uAlbedo.a);
    }
    """
}
