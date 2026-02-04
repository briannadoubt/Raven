import Foundation
import JavaScriptKit

/// Manages WebRTC peer-to-peer connection
///
/// RTCPeerConnection is the main class for establishing and managing peer-to-peer
/// connections. It handles SDP negotiation, ICE candidate exchange, media tracks,
/// and data channels with full Swift 6.2 strict concurrency support.
///
/// ## Example Usage
///
/// ```swift
/// // Create peer connection
/// let config = RTCConfiguration.default
/// let peer = RTCPeerConnection(configuration: config)
///
/// // Add media tracks
/// let stream = try await MediaStream.getUserMedia?(audio: true, video: true)
/// for track in stream.tracks {
///     try peer.addTrack?(track, streamIds: [stream.id])
/// }
///
/// // Create offer
/// let offer = try await peer.createOffer?()
/// try await peer.setLocalDescription?(offer)
///
/// // Handle ICE candidates
/// peer.onICECandidate { candidate in
///     // Send to remote peer via signaling
/// }
///
/// // Set remote description from peer
/// try await peer.setRemoteDescription?(answer)
/// ```
@MainActor
public final class RTCPeerConnection: Sendable {
    // MARK: - Properties

    /// The underlying JavaScript RTCPeerConnection object
    private let jsConnection: JSObject

    /// Configuration used for this connection
    public let configuration: RTCConfiguration

    /// Current signaling state
    public var signalingState: SignalingState {
        if let stateString = jsConnection.signalingState.string {
            return SignalingState(rawValue: stateString) ?? .closed
        }
        return .closed
    }

    /// Current ICE connection state
    public var iceConnectionState: ICEConnectionState {
        if let stateString = jsConnection.iceConnectionState.string {
            return ICEConnectionState(rawValue: stateString) ?? .closed
        }
        return .closed
    }

    /// Current ICE gathering state
    public var iceGatheringState: ICEGatheringState {
        if let stateString = jsConnection.iceGatheringState.string {
            return ICEGatheringState(rawValue: stateString) ?? .new
        }
        return .new
    }

    /// Current peer connection state
    public var connectionState: PeerConnectionState {
        if let stateString = jsConnection.connectionState.string {
            return PeerConnectionState(rawValue: stateString) ?? .closed
        }
        return .closed
    }

    /// Local description (offer or answer)
    public var localDescription: SessionDescription? {
        guard let jsDesc = jsConnection.localDescription.object else {
            return nil
        }
        return SessionDescription(jsObject: jsDesc)
    }

    /// Remote description (offer or answer)
    public var remoteDescription: SessionDescription? {
        guard let jsDesc = jsConnection.remoteDescription.object else {
            return nil
        }
        return SessionDescription(jsObject: jsDesc)
    }

    // MARK: - Event Handlers

    private var iceCandidateHandlers: [UUID: @Sendable @MainActor (ICECandidate?) -> Void] = [:]
    private var iceConnectionStateHandlers: [UUID: @Sendable @MainActor (ICEConnectionState) -> Void] = [:]
    private var iceGatheringStateHandlers: [UUID: @Sendable @MainActor (ICEGatheringState) -> Void] = [:]
    private var signalingStateHandlers: [UUID: @Sendable @MainActor (SignalingState) -> Void] = [:]
    private var connectionStateHandlers: [UUID: @Sendable @MainActor (PeerConnectionState) -> Void] = [:]
    private var trackHandlers: [UUID: @Sendable @MainActor (MediaStreamTrack, [MediaStream]) -> Void] = [:]
    private var dataChannelHandlers: [UUID: @Sendable @MainActor (DataChannel) -> Void] = [:]
    private var negotiationNeededHandlers: [UUID: @Sendable @MainActor () -> Void] = [:]

    // MARK: - Event Closures

    private var iceCandidateClosure: JSClosure?
    private var iceConnectionStateChangeClosure: JSClosure?
    private var iceGatheringStateChangeClosure: JSClosure?
    private var signalingStateChangeClosure: JSClosure?
    private var connectionStateChangeClosure: JSClosure?
    private var trackClosure: JSClosure?
    private var dataChannelClosure: JSClosure?
    private var negotiationNeededClosure: JSClosure?

    // MARK: - Initialization

    /// Creates a new peer connection with the specified configuration
    ///
    /// - Parameter configuration: Configuration for ICE servers and policies
    /// - Throws: RTCError if connection creation fails
    public init(configuration: RTCConfiguration = .default) throws {
        self.configuration = configuration

        // Convert configuration to JavaScript object
        let configDict = configuration.toJSDictionary()
        guard let jsConfig = JSObject.global.Object.call().object else {
            throw RTCError.configurationFailed("Failed to create config object")
        }

        for (key, value) in configDict {
            if let array = value as? [[String: Any]] {
                // Handle ICE servers array
                guard let jsArray = JSObject.global.Array.call().object else { continue }
                for (index, dict) in array.enumerated() {
                    guard let jsDict = JSObject.global.Object.call().object else { continue }
                    for (k, v) in dict {
                        jsDict[dynamicMember: k] = jsValueFromAny(v)
                    }
                    jsArray[index] = .object(jsDict)
                }
                jsConfig[dynamicMember: key] = .object(jsArray)
            } else {
                jsConfig[dynamicMember: key] = jsValueFromAny(value)
            }
        }

        // Create RTCPeerConnection
        guard let connection = JSObject.global.RTCPeerConnection.call(jsConfig).object else {
            throw RTCError.connectionCreationFailed("Failed to create RTCPeerConnection")
        }
        self.jsConnection = connection

        setupEventHandlers()
    }

    deinit {
    }

    // MARK: - Event Handler Setup

    private func setupEventHandlers() {
        // ICE candidate
        iceCandidateClosure = JSClosure { [weak self] args in
            Task { @MainActor [weak self] in
                guard let self = self,
                      args.count > 0,
                      let event = args[0].object else { return }

                let candidate: ICECandidate?
                if let jsCandidate = event.candidate.object,
                   !event.candidate.isNull {
                    candidate = try? ICECandidate(jsValue: .object(jsCandidate))
                } else {
                    candidate = nil // End of candidates
                }

                for handler in self.iceCandidateHandlers.values {
                    handler(candidate)
                }
            }
            return .undefined
        }
        jsConnection.onicecandidate = .object(iceCandidateClosure!)

        // ICE connection state change
        iceConnectionStateChangeClosure = JSClosure { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                let state = self.iceConnectionState
                for handler in self.iceConnectionStateHandlers.values {
                    handler(state)
                }
            }
            return .undefined
        }
        jsConnection.oniceconnectionstatechange = .object(iceConnectionStateChangeClosure!)

        // ICE gathering state change
        iceGatheringStateChangeClosure = JSClosure { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                let state = self.iceGatheringState
                for handler in self.iceGatheringStateHandlers.values {
                    handler(state)
                }
            }
            return .undefined
        }
        jsConnection.onicegatheringstatechange = .object(iceGatheringStateChangeClosure!)

        // Signaling state change
        signalingStateChangeClosure = JSClosure { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                let state = self.signalingState
                for handler in self.signalingStateHandlers.values {
                    handler(state)
                }
            }
            return .undefined
        }
        jsConnection.onsignalingstatechange = .object(signalingStateChangeClosure!)

        // Connection state change
        connectionStateChangeClosure = JSClosure { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                let state = self.connectionState
                for handler in self.connectionStateHandlers.values {
                    handler(state)
                }
            }
            return .undefined
        }
        jsConnection.onconnectionstatechange = .object(connectionStateChangeClosure!)

        // Track
        trackClosure = JSClosure { [weak self] args in
            Task { @MainActor [weak self] in
                guard let self = self,
                      args.count > 0,
                      let event = args[0].object,
                      let jsTrack = event.track.object else { return }

                let track = MediaStreamTrack(jsTrack: jsTrack)

                // Get associated streams
                var streams: [MediaStream] = []
                if let jsStreams = event.streams.object {
                    let length = Int(jsStreams.length.number ?? 0)
                    for i in 0..<length {
                        if let jsStream = jsStreams[i].object {
                            streams.append(MediaStream(jsStream: jsStream))
                        }
                    }
                }

                for handler in self.trackHandlers.values {
                    handler(track, streams)
                }
            }
            return .undefined
        }
        jsConnection.ontrack = .object(trackClosure!)

        // Data channel
        dataChannelClosure = JSClosure { [weak self] args in
            Task { @MainActor [weak self] in
                guard let self = self,
                      args.count > 0,
                      let event = args[0].object,
                      let jsChannel = event.channel.object else { return }

                let channel = DataChannel(jsChannel: jsChannel)

                for handler in self.dataChannelHandlers.values {
                    handler(channel)
                }
            }
            return .undefined
        }
        jsConnection.ondatachannel = .object(dataChannelClosure!)

        // Negotiation needed
        negotiationNeededClosure = JSClosure { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                for handler in self.negotiationNeededHandlers.values {
                    handler()
                }
            }
            return .undefined
        }
        jsConnection.onnegotiationneeded = .object(negotiationNeededClosure!)
    }

    // MARK: - Event Handler Registration

    /// Register handler for ICE candidates
    @discardableResult
    public func onICECandidate(_ handler: @escaping @Sendable @MainActor (ICECandidate?) -> Void) -> UUID {
        let id = UUID()
        iceCandidateHandlers[id] = handler
        return id
    }

    /// Register handler for ICE connection state changes
    @discardableResult
    public func onICEConnectionStateChange(_ handler: @escaping @Sendable @MainActor (ICEConnectionState) -> Void) -> UUID {
        let id = UUID()
        iceConnectionStateHandlers[id] = handler
        return id
    }

    /// Register handler for ICE gathering state changes
    @discardableResult
    public func onICEGatheringStateChange(_ handler: @escaping @Sendable @MainActor (ICEGatheringState) -> Void) -> UUID {
        let id = UUID()
        iceGatheringStateHandlers[id] = handler
        return id
    }

    /// Register handler for signaling state changes
    @discardableResult
    public func onSignalingStateChange(_ handler: @escaping @Sendable @MainActor (SignalingState) -> Void) -> UUID {
        let id = UUID()
        signalingStateHandlers[id] = handler
        return id
    }

    /// Register handler for connection state changes
    @discardableResult
    public func onConnectionStateChange(_ handler: @escaping @Sendable @MainActor (PeerConnectionState) -> Void) -> UUID {
        let id = UUID()
        connectionStateHandlers[id] = handler
        return id
    }

    /// Register handler for incoming tracks
    @discardableResult
    public func onTrack(_ handler: @escaping @Sendable @MainActor (MediaStreamTrack, [MediaStream]) -> Void) -> UUID {
        let id = UUID()
        trackHandlers[id] = handler
        return id
    }

    /// Register handler for incoming data channels
    @discardableResult
    public func onDataChannel(_ handler: @escaping @Sendable @MainActor (DataChannel) -> Void) -> UUID {
        let id = UUID()
        dataChannelHandlers[id] = handler
        return id
    }

    /// Register handler for negotiation needed events
    @discardableResult
    public func onNegotiationNeeded(_ handler: @escaping @Sendable @MainActor () -> Void) -> UUID {
        let id = UUID()
        negotiationNeededHandlers[id] = handler
        return id
    }

    /// Remove a registered event handler
    public func removeHandler(_ id: UUID) {
        iceCandidateHandlers.removeValue(forKey: id)
        iceConnectionStateHandlers.removeValue(forKey: id)
        iceGatheringStateHandlers.removeValue(forKey: id)
        signalingStateHandlers.removeValue(forKey: id)
        connectionStateHandlers.removeValue(forKey: id)
        trackHandlers.removeValue(forKey: id)
        dataChannelHandlers.removeValue(forKey: id)
        negotiationNeededHandlers.removeValue(forKey: id)
    }

    // MARK: - SDP Negotiation

    /// Create an SDP offer
    ///
    /// - Parameter options: Optional offer options
    /// - Returns: Session description containing the offer
    /// - Throws: RTCError if offer creation fails
    public func createOffer(options: OfferOptions? = nil) async throws -> SessionDescription {
        return try await withCheckedThrowingContinuation { continuation in
            var jsOptions: JSObject?
            if let options = options {
                jsOptions = JSObject.global.Object.call().object
                jsOptions?.offerToReceiveAudio = .boolean(options.offerToReceiveAudio)
                jsOptions?.offerToReceiveVideo = .boolean(options.offerToReceiveVideo)
                jsOptions?.iceRestart = .boolean(options.iceRestart)
            }

            let promise = jsOptions != nil
                ? jsConnection.createOffer.call(jsOptions!)
                : jsConnection.createOffer.call()

            _ = promise.then.call(JSClosure { args in
                if let jsDesc = args.first?.object {
                    continuation.resume(returning: SessionDescription(jsObject: jsDesc))
                } else {
                    continuation.resume(throwing: RTCError.offerCreationFailed)
                }
                return .undefined
            })

            _ = promise.catch.call(JSClosure { _ in
                continuation.resume(throwing: RTCError.offerCreationFailed)
                return .undefined
            })
        }
    }

    /// Create an SDP answer
    ///
    /// - Returns: Session description containing the answer
    /// - Throws: RTCError if answer creation fails
    public func createAnswer() async throws -> SessionDescription {
        return try await withCheckedThrowingContinuation { continuation in
            let promise = jsConnection.createAnswer.call()

            _ = promise.then.call(JSClosure { args in
                if let jsDesc = args.first?.object {
                    continuation.resume(returning: SessionDescription(jsObject: jsDesc))
                } else {
                    continuation.resume(throwing: RTCError.answerCreationFailed)
                }
                return .undefined
            })

            _ = promise.catch.call(JSClosure { _ in
                continuation.resume(throwing: RTCError.answerCreationFailed)
                return .undefined
            })
        }
    }

    /// Set the local description
    ///
    /// - Parameter description: Session description to set
    /// - Throws: RTCError if setting fails
    public func setLocalDescription(_ description: SessionDescription) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            do {
                let jsDesc = try description.toJSObject()
                let promise = jsConnection.setLocalDescription.call(jsDesc)

                _ = promise.then.call(JSClosure { _ in
                    continuation.resume()
                    return .undefined
                })

                _ = promise.catch.call(JSClosure { _ in
                    continuation.resume(throwing: RTCError.setLocalDescriptionFailed)
                    return .undefined
                })
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    /// Set the remote description
    ///
    /// - Parameter description: Session description to set
    /// - Throws: RTCError if setting fails
    public func setRemoteDescription(_ description: SessionDescription) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            do {
                let jsDesc = try description.toJSObject()
                let promise = jsConnection.setRemoteDescription.call(jsDesc)

                _ = promise.then.call(JSClosure { _ in
                    continuation.resume()
                    return .undefined
                })

                _ = promise.catch.call(JSClosure { _ in
                    continuation.resume(throwing: RTCError.setRemoteDescriptionFailed)
                    return .undefined
                })
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    // MARK: - ICE Candidates

    /// Add an ICE candidate
    ///
    /// - Parameter candidate: Candidate to add
    /// - Throws: RTCError if adding fails
    public func addICECandidate(_ candidate: ICECandidate) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            let jsCandidate = candidate.toJSValue()
            let promise = jsConnection.addIceCandidate.call(jsCandidate)

            _ = promise.then.call(JSClosure { _ in
                continuation.resume()
                return .undefined
            })

            _ = promise.catch.call(JSClosure { _ in
                continuation.resume(throwing: RTCError.addICECandidateFailed)
                return .undefined
            })
        }
    }

    // MARK: - Media Tracks

    /// Add a media track to the connection
    ///
    /// - Parameters:
    ///   - track: Track to add
    ///   - streamIds: Array of stream IDs to associate with the track
    /// - Throws: RTCError if adding fails
    @discardableResult
    public func addTrack(_ track: MediaStreamTrack, streamIds: [String] = []) throws -> RTCRtpSender {
        guard let streams = JSObject.global.Array.call().object else {
            throw RTCError.invalidState
        }
        for (index, streamId) in streamIds.enumerated() {
            streams[index] = .string(streamId)
        }

        guard let jsSender = jsConnection.addTrack.call(track.jsTrack, streams).object else {
            throw RTCError.invalidState
        }
        return RTCRtpSender(jsObject: jsSender)
    }

    /// Remove a sender's track from the connection
    ///
    /// - Parameter sender: Sender to remove
    public func removeTrack(_ sender: RTCRtpSender) {
        _ = jsConnection.removeTrack.call(sender.jsObject)
    }

    /// Get all RTP senders
    ///
    /// - Returns: Array of RTP senders
    public func getSenders() -> [RTCRtpSender] {
        guard let jsSenders = jsConnection.getSenders.call().object else {
            return []
        }
        let length = Int(jsSenders.length.number ?? 0)

        var senders: [RTCRtpSender] = []
        for i in 0..<length {
            if let jsSender = jsSenders[i].object {
                senders.append(RTCRtpSender(jsObject: jsSender))
            }
        }
        return senders
    }

    /// Get all RTP receivers
    ///
    /// - Returns: Array of RTP receivers
    public func getReceivers() -> [RTCRtpReceiver] {
        guard let jsReceivers = jsConnection.getReceivers.call().object else {
            return []
        }
        let length = Int(jsReceivers.length.number ?? 0)

        var receivers: [RTCRtpReceiver] = []
        for i in 0..<length {
            if let jsReceiver = jsReceivers[i].object {
                receivers.append(RTCRtpReceiver(jsObject: jsReceiver))
            }
        }
        return receivers
    }

    // MARK: - Data Channels

    /// Create a data channel
    ///
    /// - Parameters:
    ///   - label: Label for the channel
    ///   - options: Configuration options for the channel
    /// - Returns: New data channel
    /// - Throws: RTCError if creation fails
    public func createDataChannel(
        label: String,
        options: DataChannelOptions = DataChannelOptions()
    ) throws -> DataChannel {
        guard let jsOptions = JSObject.global.Object.call().object else {
            throw RTCError.dataChannelCreationFailed
        }
        let optionsDict = options.toJSDictionary()

        for (key, value) in optionsDict {
            jsOptions[dynamicMember: key] = jsValueFromAny(value)
        }

        guard let jsChannel = jsConnection.createDataChannel.call(label, jsOptions).object else {
            throw RTCError.dataChannelCreationFailed
        }
        return DataChannel(jsChannel: jsChannel)
    }

    // MARK: - Connection Control

    /// Close the peer connection
    public func close() {
        _ = jsConnection.close?()
    }

    /// Restart ICE with new credentials
    public func restartICE() {
        _ = jsConnection.restartIce?()
    }

    // MARK: - Statistics

    /// Get statistics for the connection
    ///
    /// - Returns: Statistics report
    public func getStats() async -> RTCStatsReport {
        return await withCheckedContinuation { continuation in
            let promise = jsConnection.getStats.call()

            _ = promise.then.call(JSClosure { args in
                if let jsReport = args.first?.object {
                    continuation.resume(returning: RTCStatsReport(jsObject: jsReport))
                } else if let emptyObj = JSObject.global.Object.call().object {
                    continuation.resume(returning: RTCStatsReport(jsObject: emptyObj))
                } else {
                    // Fallback to a simple empty object
                    continuation.resume(returning: RTCStatsReport(jsObject: JSObject.global))
                }
                return .undefined
            })
        }
    }

    // MARK: - Cleanup

    private func cleanup() {
        iceCandidateClosure = nil
        iceConnectionStateChangeClosure = nil
        iceGatheringStateChangeClosure = nil
        signalingStateChangeClosure = nil
        connectionStateChangeClosure = nil
        trackClosure = nil
        dataChannelClosure = nil
        negotiationNeededClosure = nil

        iceCandidateHandlers.removeAll()
        iceConnectionStateHandlers.removeAll()
        iceGatheringStateHandlers.removeAll()
        signalingStateHandlers.removeAll()
        connectionStateHandlers.removeAll()
        trackHandlers.removeAll()
        dataChannelHandlers.removeAll()
        negotiationNeededHandlers.removeAll()
    }
}

// MARK: - Session Description

/// Represents an SDP offer or answer
@MainActor
public struct SessionDescription: Sendable {
    public enum SDPType: String, Sendable {
        case offer
        case answer
        case pranswer
        case rollback
    }

    public let type: SDPType
    public let sdp: String

    public init(type: SDPType, sdp: String) {
        self.type = type
        self.sdp = sdp
    }

    internal init(jsObject: JSObject) {
        self.type = SDPType(rawValue: jsObject.type.string ?? "offer") ?? .offer
        self.sdp = jsObject.sdp.string ?? ""
    }

    internal func toJSObject() throws -> JSObject {
        guard let obj = JSObject.global.Object.call().object else {
            throw RTCError.sessionDescriptionCreationFailed("Failed to create JavaScript object for SessionDescription")
        }
        obj.type = .string(type.rawValue)
        obj.sdp = .string(sdp)
        return obj
    }
}

// MARK: - Offer Options

@MainActor
public struct OfferOptions: Sendable {
    public var offerToReceiveAudio: Bool
    public var offerToReceiveVideo: Bool
    public var iceRestart: Bool

    public init(
        offerToReceiveAudio: Bool = true,
        offerToReceiveVideo: Bool = true,
        iceRestart: Bool = false
    ) {
        self.offerToReceiveAudio = offerToReceiveAudio
        self.offerToReceiveVideo = offerToReceiveVideo
        self.iceRestart = iceRestart
    }
}

// MARK: - RTP Sender/Receiver

@MainActor
public struct RTCRtpSender: Sendable {
    internal let jsObject: JSObject

    public var track: MediaStreamTrack? {
        guard let jsTrack = jsObject.track.object else { return nil }
        return MediaStreamTrack(jsTrack: jsTrack)
    }
}

@MainActor
public struct RTCRtpReceiver: Sendable {
    internal let jsObject: JSObject

    public var track: MediaStreamTrack? {
        guard let jsTrack = jsObject.track.object else { return nil }
        return MediaStreamTrack(jsTrack: jsTrack)
    }
}

// MARK: - Statistics

@MainActor
public struct RTCStatsReport: Sendable {
    internal let jsObject: JSObject

    public init(jsObject: JSObject) {
        self.jsObject = jsObject
    }
}

// MARK: - Connection States

extension RTCPeerConnection {
    public enum SignalingState: String, Sendable {
        case stable
        case haveLocalOffer = "have-local-offer"
        case haveRemoteOffer = "have-remote-offer"
        case haveLocalPranswer = "have-local-pranswer"
        case haveRemotePranswer = "have-remote-pranswer"
        case closed
    }

    public enum ICEConnectionState: String, Sendable {
        case new
        case checking
        case connected
        case completed
        case failed
        case disconnected
        case closed
    }

    public enum ICEGatheringState: String, Sendable {
        case new
        case gathering
        case complete
    }

    public enum PeerConnectionState: String, Sendable {
        case new
        case connecting
        case connected
        case disconnected
        case failed
        case closed
    }
}

// MARK: - Errors

public enum RTCError: Error, Sendable {
    case offerCreationFailed
    case answerCreationFailed
    case setLocalDescriptionFailed
    case setRemoteDescriptionFailed
    case addICECandidateFailed
    case dataChannelCreationFailed
    case invalidState
    case configurationFailed(String)
    case connectionCreationFailed(String)
    case sessionDescriptionCreationFailed(String)
}

// MARK: - Helper Functions

private func jsValueFromAny(_ value: Any) -> JSValue {
    if let string = value as? String {
        return .string(string)
    } else if let number = value as? Int {
        return .number(Double(number))
    } else if let number = value as? Double {
        return .number(number)
    } else if let bool = value as? Bool {
        return .boolean(bool)
    } else if let array = value as? [String] {
        guard let jsArray = JSObject.global.Array.call().object else {
            return .undefined
        }
        for (index, item) in array.enumerated() {
            jsArray[index] = .string(item)
        }
        return .object(jsArray)
    } else {
        return .undefined
    }
}
