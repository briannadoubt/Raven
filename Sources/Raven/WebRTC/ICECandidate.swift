import Foundation
import JavaScriptKit

/// Represents an ICE (Interactive Connectivity Establishment) candidate
///
/// An ICE candidate describes a method for connecting to a peer, including
/// the IP address, port, protocol, and priority. During WebRTC connection
/// establishment, peers exchange ICE candidates to find the best connection path.
///
/// ## Example Usage
///
/// ```swift
/// // From JavaScript candidate
/// let candidate = try ICECandidate(jsValue: jsCandidateObject)
///
/// // Create manually
/// let candidate = ICECandidate(
///     candidate: "candidate:1 1 UDP 2130706431 192.168.1.100 54321 typ host",
///     sdpMLineIndex: 0,
///     sdpMid: "0"
/// )
/// ```
public struct ICECandidate: Sendable {
    // MARK: - Properties

    /// The candidate string in SDP format
    public let candidate: String

    /// The index of the media description in the SDP
    public let sdpMLineIndex: Int?

    /// The media stream identification tag
    public let sdpMid: String?

    /// The username fragment for this candidate
    public let usernameFragment: String?

    // MARK: - Computed Properties

    /// The foundation identifier for this candidate
    public var foundation: String? {
        parseField(at: 0)
    }

    /// The component ID (1=RTP, 2=RTCP)
    public var component: Int? {
        if let value = parseField(at: 1) {
            return Int(value)
        }
        return nil
    }

    /// The protocol used (UDP, TCP)
    public var `protocol`: String? {
        parseField(at: 2)
    }

    /// The priority of this candidate
    public var priority: Int? {
        if let value = parseField(at: 3) {
            return Int(value)
        }
        return nil
    }

    /// The IP address
    public var address: String? {
        parseField(at: 4)
    }

    /// The port number
    public var port: Int? {
        if let value = parseField(at: 5) {
            return Int(value)
        }
        return nil
    }

    /// The candidate type (host, srflx, prflx, relay)
    public var type: CandidateType? {
        if let typString = parseAttribute("typ") {
            return CandidateType(rawValue: typString)
        }
        return nil
    }

    /// Related address for reflexive and relay candidates
    public var relatedAddress: String? {
        parseAttribute("raddr")
    }

    /// Related port for reflexive and relay candidates
    public var relatedPort: Int? {
        if let value = parseAttribute("rport") {
            return Int(value)
        }
        return nil
    }

    // MARK: - Initialization

    /// Creates an ICE candidate with explicit parameters
    ///
    /// - Parameters:
    ///   - candidate: The candidate string in SDP format
    ///   - sdpMLineIndex: Index of the media description in SDP
    ///   - sdpMid: Media stream identification tag
    ///   - usernameFragment: Username fragment for the candidate
    public init(
        candidate: String,
        sdpMLineIndex: Int? = nil,
        sdpMid: String? = nil,
        usernameFragment: String? = nil
    ) {
        self.candidate = candidate
        self.sdpMLineIndex = sdpMLineIndex
        self.sdpMid = sdpMid
        self.usernameFragment = usernameFragment
    }

    /// Creates an ICE candidate from a JavaScript RTCIceCandidate object
    ///
    /// - Parameter jsValue: JavaScript RTCIceCandidate object
    /// - Throws: ICECandidateError if the JavaScript object is invalid
    public init(jsValue: JSValue) throws {
        guard let jsObject = jsValue.object else {
            throw ICECandidateError.invalidJSObject
        }

        guard let candidateString = jsObject.candidate.string, !candidateString.isEmpty else {
            throw ICECandidateError.missingCandidate
        }

        self.candidate = candidateString

        // Extract optional fields
        let sdpMLineIndexValue: JSValue = jsObject.sdpMLineIndex
        if let numberValue = sdpMLineIndexValue.number {
            self.sdpMLineIndex = Int(numberValue)
        } else {
            self.sdpMLineIndex = nil
        }

        self.sdpMid = jsObject.sdpMid.string

        self.usernameFragment = jsObject.usernameFragment.string
    }

    // MARK: - Conversion

    /// Convert to JavaScript RTCIceCandidate format
    internal func toJSValue() -> JSValue {
        var dict: [String: Any] = ["candidate": candidate]

        if let sdpMLineIndex = sdpMLineIndex {
            dict["sdpMLineIndex"] = sdpMLineIndex
        }

        if let sdpMid = sdpMid {
            dict["sdpMid"] = sdpMid
        }

        if let usernameFragment = usernameFragment {
            dict["usernameFragment"] = usernameFragment
        }

        // Create JavaScript object
        guard let jsObject = JSObject.global.Object.call().object else {
            return .undefined
        }
        for (key, value) in dict {
            jsObject[dynamicMember: key] = JSValue(value)
        }

        return .object(jsObject)
    }

    /// Convert to dictionary for signaling
    public func toDictionary() -> [String: Any] {
        var dict: [String: Any] = ["candidate": candidate]

        if let sdpMLineIndex = sdpMLineIndex {
            dict["sdpMLineIndex"] = sdpMLineIndex
        }

        if let sdpMid = sdpMid {
            dict["sdpMid"] = sdpMid
        }

        if let usernameFragment = usernameFragment {
            dict["usernameFragment"] = usernameFragment
        }

        return dict
    }

    // MARK: - Parsing Helpers

    /// Parse a field from the candidate string by index
    private func parseField(at index: Int) -> String? {
        let components = candidate.split(separator: " ")
        guard components.count > index else { return nil }
        let field = String(components[index])
        return field.isEmpty ? nil : field
    }

    /// Parse an attribute from the candidate string
    private func parseAttribute(_ name: String) -> String? {
        let pattern = "\(name)\\s+(\\S+)"
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(
                in: candidate,
                range: NSRange(candidate.startIndex..., in: candidate)
              ),
              match.numberOfRanges > 1,
              let range = Range(match.range(at: 1), in: candidate) else {
            return nil
        }
        return String(candidate[range])
    }
}

// MARK: - Candidate Type

extension ICECandidate {
    /// Type of ICE candidate
    public enum CandidateType: String, Sendable {
        /// Host candidate (local interface)
        case host

        /// Server reflexive candidate (from STUN server)
        case srflx

        /// Peer reflexive candidate (discovered during connectivity checks)
        case prflx

        /// Relay candidate (from TURN server)
        case relay
    }
}

// MARK: - Errors

/// Errors that can occur when working with ICE candidates
public enum ICECandidateError: Error, Sendable {
    /// The JavaScript object is not a valid RTCIceCandidate
    case invalidJSObject

    /// The candidate string is missing or empty
    case missingCandidate

    /// The candidate string format is invalid
    case invalidFormat

    /// Failed to parse a required field
    case parsingFailed(String)
}

// MARK: - Equatable

extension ICECandidate: Equatable {
    public static func == (lhs: ICECandidate, rhs: ICECandidate) -> Bool {
        lhs.candidate == rhs.candidate &&
        lhs.sdpMLineIndex == rhs.sdpMLineIndex &&
        lhs.sdpMid == rhs.sdpMid
    }
}

// MARK: - Hashable

extension ICECandidate: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(candidate)
        hasher.combine(sdpMLineIndex)
        hasher.combine(sdpMid)
    }
}

// MARK: - CustomStringConvertible

extension ICECandidate: CustomStringConvertible {
    public var description: String {
        var parts = ["ICECandidate("]

        if let type = type {
            parts.append("type: \(type.rawValue)")
        }

        if let address = address, let port = port {
            parts.append(", address: \(address):\(port)")
        }

        if let priority = priority {
            parts.append(", priority: \(priority)")
        }

        parts.append(")")

        return parts.joined()
    }
}

// MARK: - JSValue Extension

private extension JSValue {
    init(_ value: Any) {
        if let string = value as? String {
            self = .string(string)
        } else if let number = value as? Int {
            self = .number(Double(number))
        } else if let number = value as? Double {
            self = .number(number)
        } else if let bool = value as? Bool {
            self = .boolean(bool)
        } else {
            self = .undefined
        }
    }
}
