import Foundation

/// Configuration for WebRTC peer connection including STUN/TURN servers
///
/// RTCConfiguration defines the ICE servers and other settings needed to establish
/// a peer connection. STUN servers help discover the public IP address, while TURN
/// servers relay traffic when direct peer-to-peer connection fails.
///
/// ## Example Usage
///
/// ```swift
/// let config = RTCConfiguration(
///     iceServers: [
///         .stun("stun:stun.l.google.com:19302"),
///         .turn(
///             urls: ["turn:turn.example.com:3478"],
///             username: "user",
///             credential: "pass"
///         )
///     ],
///     iceTransportPolicy: .all,
///     bundlePolicy: .balanced
/// )
/// ```
@MainActor
public struct RTCConfiguration: Sendable {
    // MARK: - Properties

    /// Array of ICE servers to use for NAT traversal
    public var iceServers: [ICEServer]

    /// Policy for using ICE candidates
    public var iceTransportPolicy: ICETransportPolicy

    /// Policy for bundling media streams
    public var bundlePolicy: BundlePolicy

    /// Policy for selecting RTP/RTCP multiplexing
    public var rtcpMuxPolicy: RTCPMuxPolicy

    /// Timeout for ICE candidate gathering in milliseconds
    public var iceCandidatePoolSize: Int

    // MARK: - Initialization

    /// Creates a new RTCConfiguration with specified settings
    ///
    /// - Parameters:
    ///   - iceServers: Array of ICE servers for NAT traversal. Defaults to Google's public STUN server.
    ///   - iceTransportPolicy: Policy for ICE candidate selection. Defaults to `.all`.
    ///   - bundlePolicy: Policy for bundling media streams. Defaults to `.balanced`.
    ///   - rtcpMuxPolicy: Policy for RTP/RTCP multiplexing. Defaults to `.require`.
    ///   - iceCandidatePoolSize: Number of ICE candidates to gather. Defaults to 0.
    public init(
        iceServers: [ICEServer] = [.stun("stun:stun.l.google.com:19302")],
        iceTransportPolicy: ICETransportPolicy = .all,
        bundlePolicy: BundlePolicy = .balanced,
        rtcpMuxPolicy: RTCPMuxPolicy = .require,
        iceCandidatePoolSize: Int = 0
    ) {
        self.iceServers = iceServers
        self.iceTransportPolicy = iceTransportPolicy
        self.bundlePolicy = bundlePolicy
        self.rtcpMuxPolicy = rtcpMuxPolicy
        self.iceCandidatePoolSize = iceCandidatePoolSize
    }

    // MARK: - Conversion

    /// Convert to JavaScript object format for WebRTC API
    internal func toJSDictionary() -> [String: Any] {
        var config: [String: Any] = [:]

        // Convert ICE servers
        config["iceServers"] = iceServers.map { $0.toJSDictionary() }

        // Add policies
        config["iceTransportPolicy"] = iceTransportPolicy.rawValue
        config["bundlePolicy"] = bundlePolicy.rawValue
        config["rtcpMuxPolicy"] = rtcpMuxPolicy.rawValue

        // Add pool size if non-zero
        if iceCandidatePoolSize > 0 {
            config["iceCandidatePoolSize"] = iceCandidatePoolSize
        }

        return config
    }
}

// MARK: - ICE Server

extension RTCConfiguration {
    /// Represents an ICE server (STUN or TURN) for NAT traversal
    public struct ICEServer: Sendable {
        /// URLs for the ICE server
        public let urls: [String]

        /// Username for TURN server authentication
        public let username: String?

        /// Credential for TURN server authentication
        public let credential: String?

        /// Credential type for TURN authentication
        public let credentialType: CredentialType

        /// Creates a STUN server configuration
        ///
        /// - Parameter url: STUN server URL (e.g., "stun:stun.example.com:19302")
        /// - Returns: ICE server configured for STUN
        public static func stun(_ url: String) -> ICEServer {
            ICEServer(
                urls: [url],
                username: nil,
                credential: nil,
                credentialType: .password
            )
        }

        /// Creates a TURN server configuration
        ///
        /// - Parameters:
        ///   - urls: Array of TURN server URLs
        ///   - username: Username for authentication
        ///   - credential: Password or token for authentication
        ///   - credentialType: Type of credential (password or oauth)
        /// - Returns: ICE server configured for TURN
        public static func turn(
            urls: [String],
            username: String,
            credential: String,
            credentialType: CredentialType = .password
        ) -> ICEServer {
            ICEServer(
                urls: urls,
                username: username,
                credential: credential,
                credentialType: credentialType
            )
        }

        /// Convert to JavaScript object format
        internal func toJSDictionary() -> [String: Any] {
            var dict: [String: Any] = ["urls": urls]

            if let username = username {
                dict["username"] = username
            }

            if let credential = credential {
                dict["credential"] = credential
            }

            if username != nil || credential != nil {
                dict["credentialType"] = credentialType.rawValue
            }

            return dict
        }
    }

    /// Type of credential used for TURN server authentication
    public enum CredentialType: String, Sendable {
        /// Password-based authentication
        case password

        /// OAuth token authentication
        case oauth
    }
}

// MARK: - ICE Transport Policy

extension RTCConfiguration {
    /// Policy for selecting ICE candidates
    public enum ICETransportPolicy: String, Sendable {
        /// Use all available ICE candidates (direct, reflexive, relay)
        case all

        /// Only use relay candidates (TURN servers)
        case relay
    }
}

// MARK: - Bundle Policy

extension RTCConfiguration {
    /// Policy for bundling media streams
    public enum BundlePolicy: String, Sendable {
        /// Bundle all media streams
        case balanced = "balanced"

        /// Maximize bundling
        case maxBundle = "max-bundle"

        /// Maximize compatibility (no bundling)
        case maxCompat = "max-compat"
    }
}

// MARK: - RTCP Mux Policy

extension RTCConfiguration {
    /// Policy for RTP/RTCP multiplexing
    public enum RTCPMuxPolicy: String, Sendable {
        /// Require RTP/RTCP multiplexing
        case require

        /// Negotiate RTP/RTCP multiplexing
        case negotiate
    }
}

// MARK: - Presets

extension RTCConfiguration {
    /// Default configuration with Google's public STUN server
    public static let `default` = RTCConfiguration()

    /// Configuration for development with additional logging
    public static let development = RTCConfiguration(
        iceServers: [
            .stun("stun:stun.l.google.com:19302"),
            .stun("stun:stun1.l.google.com:19302")
        ]
    )

    /// Configuration optimized for low latency
    public static let lowLatency = RTCConfiguration(
        bundlePolicy: .maxBundle,
        iceCandidatePoolSize: 10
    )

    /// Configuration that only uses relay servers for privacy
    public static let relayOnly = RTCConfiguration(
        iceTransportPolicy: .relay
    )
}
