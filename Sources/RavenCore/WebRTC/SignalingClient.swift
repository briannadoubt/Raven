import Foundation
import JavaScriptKit

/// WebSocket-based signaling client for WebRTC connection setup
///
/// SignalingClient manages the exchange of SDP offers/answers and ICE candidates
/// between peers using WebSocket communication. It provides a structured protocol
/// for signaling messages with automatic reconnection support.
///
/// ## Example Usage
///
/// ```swift
/// // Create signaling client
/// let signaling = SignalingClient(url: "wss://signal.example.com")
///
/// // Connect to server
/// try await signaling.connect?()
///
/// // Handle incoming messages
/// signaling.onOffer { offer in
///     // Handle offer from remote peer
/// }
///
/// signaling.onICECandidate { candidate in
///     // Handle ICE candidate from remote peer
/// }
///
/// // Send messages
/// try await signaling.sendOffer(sessionDescription)
/// try await signaling.sendICECandidate(candidate)
/// ```
@MainActor
public final class SignalingClient: Sendable {
    // MARK: - Properties

    /// WebSocket connection URL
    public let url: String

    /// Unique identifier for this peer
    public let peerId: String

    /// Target peer ID for direct messaging
    public var targetPeerId: String?

    /// Current connection state
    public var state: ConnectionState {
        if let ws = webSocket {
            let readyState = Int(ws.readyState.number ?? 3)
            switch readyState {
            case 0: return .connecting
            case 1: return .connected
            case 2: return .disconnecting
            case 3: return .disconnected
            default: return .disconnected
            }
        }
        return .disconnected
    }

    /// Whether to automatically reconnect on disconnect
    public var autoReconnect: Bool = true

    /// Reconnect delay in seconds
    public var reconnectDelay: Double = 2.0

    /// Maximum reconnect attempts (0 = unlimited)
    public var maxReconnectAttempts: Int = 0

    private var webSocket: JSObject?
    private var reconnectAttempts: Int = 0
    private var reconnectTask: Task<Void, Never>?

    // MARK: - Message Handlers

    private var offerHandlers: [UUID: @Sendable @MainActor (SessionDescription) -> Void] = [:]
    private var answerHandlers: [UUID: @Sendable @MainActor (SessionDescription) -> Void] = [:]
    private var iceCandidateHandlers: [UUID: @Sendable @MainActor (ICECandidate) -> Void] = [:]
    private var customHandlers: [UUID: @Sendable @MainActor (String, [String: Any]) -> Void] = [:]
    private var stateHandlers: [UUID: @Sendable @MainActor (ConnectionState) -> Void] = [:]
    private var errorHandlers: [UUID: @Sendable @MainActor (Error) -> Void] = [:]

    // MARK: - Event Closures

    private var openClosure: JSClosure?
    private var closeClosure: JSClosure?
    private var errorClosure: JSClosure?
    private var messageClosure: JSClosure?

    // MARK: - Initialization

    /// Creates a new signaling client
    ///
    /// - Parameters:
    ///   - url: WebSocket server URL
    ///   - peerId: Unique identifier for this peer (generated if not provided)
    public init(url: String, peerId: String = UUID().uuidString) {
        self.url = url
        self.peerId = peerId
    }

    deinit {
    }

    // MARK: - Connection Management

    /// Connect to the signaling server
    ///
    /// - Throws: SignalingError if connection fails
    public func connect() async throws {
        guard webSocket == nil else {
            throw SignalingError.alreadyConnected
        }

        return try await withCheckedThrowingContinuation { continuation in
            var resumed = false

            // Create WebSocket
            guard let ws = JSObject.global.WebSocket.call(url).object else {
                continuation.resume(throwing: SignalingError.connectionFailed)
                return
            }
            self.webSocket = ws

            setupEventHandlers(onConnect: {
                if !resumed {
                    resumed = true
                    continuation.resume()
                }
            }, onError: { error in
                if !resumed {
                    resumed = true
                    continuation.resume(throwing: error)
                }
            })

            // Timeout after 10 seconds
            Task {
                try? await Task.sleep(for: .seconds(10))
                if !resumed {
                    resumed = true
                    continuation.resume(throwing: SignalingError.connectionTimeout)
                }
            }
        }
    }

    /// Disconnect from the signaling server
    public func disconnect() {
        autoReconnect = false
        reconnectTask?.cancel()
        reconnectTask = nil

        if let ws = webSocket {
            _ = ws.close!()
            webSocket = nil
        }

        notifyStateChange(.disconnected)
    }

    // MARK: - Event Handler Setup

    private func setupEventHandlers(
        onConnect: @escaping () -> Void,
        onError: @escaping (Error) -> Void
    ) {
        guard let ws = webSocket else { return }

        // Open event
        openClosure = JSClosure { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                self.reconnectAttempts = 0
                self.notifyStateChange(.connected)
                onConnect()
            }
            return .undefined
        }
        ws.onopen = .object(openClosure!)

        // Close event
        closeClosure = JSClosure { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                self.webSocket = nil
                self.notifyStateChange(.disconnected)

                // Attempt reconnection if enabled
                if self.autoReconnect &&
                   (self.maxReconnectAttempts == 0 || self.reconnectAttempts < self.maxReconnectAttempts) {
                    self.reconnectAttempts += 1
                    self.scheduleReconnect()
                }
            }
            return .undefined
        }
        ws.onclose = .object(closeClosure!)

        // Error event
        errorClosure = JSClosure { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                let error = SignalingError.connectionFailed
                for handler in self.errorHandlers.values {
                    handler(error)
                }
                onError(error)
            }
            return .undefined
        }
        ws.onerror = .object(errorClosure!)

        // Message event
        messageClosure = JSClosure { [weak self] args in
            Task { @MainActor [weak self] in
                guard let self = self,
                      args.count > 0,
                      let event = args[0].object,
                      let data = event.data.string else { return }

                self.handleMessage(data)
            }
            return .undefined
        }
        ws.onmessage = .object(messageClosure!)
    }

    private func scheduleReconnect() {
        reconnectTask = Task {
            try? await Task.sleep(for: .seconds(reconnectDelay))

            guard !Task.isCancelled else { return }

            try? await connect()
        }
    }

    // MARK: - Message Handling

    private func handleMessage(_ data: String) {
        guard let jsonData = data.data(using: .utf8),
              let message = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
              let type = message["type"] as? String else {
            return
        }

        switch type {
        case "offer":
            if let sdp = message["sdp"] as? String {
                let offer = SessionDescription(type: .offer, sdp: sdp)
                for handler in offerHandlers.values {
                    handler(offer)
                }
            }

        case "answer":
            if let sdp = message["sdp"] as? String {
                let answer = SessionDescription(type: .answer, sdp: sdp)
                for handler in answerHandlers.values {
                    handler(answer)
                }
            }

        case "candidate":
            if let candidateString = message["candidate"] as? String,
               let sdpMLineIndex = message["sdpMLineIndex"] as? Int,
               let sdpMid = message["sdpMid"] as? String {
                let candidate = ICECandidate(
                    candidate: candidateString,
                    sdpMLineIndex: sdpMLineIndex,
                    sdpMid: sdpMid
                )
                for handler in iceCandidateHandlers.values {
                    handler(candidate)
                }
            }

        default:
            // Custom message type
            for handler in customHandlers.values {
                handler(type, message)
            }
        }
    }

    // MARK: - Sending Messages

    /// Send an SDP offer
    ///
    /// - Parameter offer: Session description to send
    /// - Throws: SignalingError if not connected
    public func sendOffer(_ offer: SessionDescription) throws {
        try send([
            "type": "offer",
            "sdp": offer.sdp,
            "from": peerId,
            "to": targetPeerId ?? ""
        ])
    }

    /// Send an SDP answer
    ///
    /// - Parameter answer: Session description to send
    /// - Throws: SignalingError if not connected
    public func sendAnswer(_ answer: SessionDescription) throws {
        try send([
            "type": "answer",
            "sdp": answer.sdp,
            "from": peerId,
            "to": targetPeerId ?? ""
        ])
    }

    /// Send an ICE candidate
    ///
    /// - Parameter candidate: ICE candidate to send
    /// - Throws: SignalingError if not connected
    public func sendICECandidate(_ candidate: ICECandidate) throws {
        try send([
            "type": "candidate",
            "candidate": candidate.candidate,
            "sdpMLineIndex": candidate.sdpMLineIndex ?? 0,
            "sdpMid": candidate.sdpMid ?? "",
            "from": peerId,
            "to": targetPeerId ?? ""
        ])
    }

    /// Send a custom message
    ///
    /// - Parameters:
    ///   - type: Message type identifier
    ///   - data: Additional message data
    /// - Throws: SignalingError if not connected
    public func sendCustom(type: String, data: [String: Any] = [:]) throws {
        var message = data
        message["type"] = type
        message["from"] = peerId
        if let to = targetPeerId {
            message["to"] = to
        }
        try send(message)
    }

    private func send(_ message: [String: Any]) throws {
        guard let ws = webSocket, state == .connected else {
            throw SignalingError.notConnected
        }

        guard let jsonData = try? JSONSerialization.data(withJSONObject: message),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            throw SignalingError.serializationFailed
        }

        _ = ws.send.call(jsonString)
    }

    // MARK: - Event Handler Registration

    /// Register handler for incoming offers
    @discardableResult
    public func onOffer(_ handler: @escaping @Sendable @MainActor (SessionDescription) -> Void) -> UUID {
        let id = UUID()
        offerHandlers[id] = handler
        return id
    }

    /// Register handler for incoming answers
    @discardableResult
    public func onAnswer(_ handler: @escaping @Sendable @MainActor (SessionDescription) -> Void) -> UUID {
        let id = UUID()
        answerHandlers[id] = handler
        return id
    }

    /// Register handler for incoming ICE candidates
    @discardableResult
    public func onICECandidate(_ handler: @escaping @Sendable @MainActor (ICECandidate) -> Void) -> UUID {
        let id = UUID()
        iceCandidateHandlers[id] = handler
        return id
    }

    /// Register handler for custom messages
    @discardableResult
    public func onCustomMessage(_ handler: @escaping @Sendable @MainActor (String, [String: Any]) -> Void) -> UUID {
        let id = UUID()
        customHandlers[id] = handler
        return id
    }

    /// Register handler for connection state changes
    @discardableResult
    public func onStateChange(_ handler: @escaping @Sendable @MainActor (ConnectionState) -> Void) -> UUID {
        let id = UUID()
        stateHandlers[id] = handler
        return id
    }

    /// Register handler for errors
    @discardableResult
    public func onError(_ handler: @escaping @Sendable @MainActor (Error) -> Void) -> UUID {
        let id = UUID()
        errorHandlers[id] = handler
        return id
    }

    /// Remove a registered event handler
    public func removeHandler(_ id: UUID) {
        offerHandlers.removeValue(forKey: id)
        answerHandlers.removeValue(forKey: id)
        iceCandidateHandlers.removeValue(forKey: id)
        customHandlers.removeValue(forKey: id)
        stateHandlers.removeValue(forKey: id)
        errorHandlers.removeValue(forKey: id)
    }

    // MARK: - State Notification

    private func notifyStateChange(_ state: ConnectionState) {
        for handler in stateHandlers.values {
            handler(state)
        }
    }

    // MARK: - Cleanup

    private func cleanup() {
        disconnect()

        openClosure = nil
        closeClosure = nil
        errorClosure = nil
        messageClosure = nil

        offerHandlers.removeAll()
        answerHandlers.removeAll()
        iceCandidateHandlers.removeAll()
        customHandlers.removeAll()
        stateHandlers.removeAll()
        errorHandlers.removeAll()
    }
}

// MARK: - Connection State

extension SignalingClient {
    public enum ConnectionState: Sendable {
        case disconnected
        case connecting
        case connected
        case disconnecting
    }
}

// MARK: - Errors

public enum SignalingError: Error, Sendable {
    case alreadyConnected
    case notConnected
    case connectionFailed
    case connectionTimeout
    case serializationFailed
    case invalidMessage
}

// MARK: - Signaling Protocol

/// Protocol for custom signaling implementations
@MainActor
public protocol SignalingProtocol: Sendable {
    /// Send an offer to a peer
    func sendOffer(_ offer: SessionDescription, to peerId: String) async throws

    /// Send an answer to a peer
    func sendAnswer(_ answer: SessionDescription, to peerId: String) async throws

    /// Send an ICE candidate to a peer
    func sendICECandidate(_ candidate: ICECandidate, to peerId: String) async throws

    /// Register handler for incoming offers
    func onOffer(_ handler: @escaping @Sendable @MainActor (SessionDescription, String) -> Void)

    /// Register handler for incoming answers
    func onAnswer(_ handler: @escaping @Sendable @MainActor (SessionDescription, String) -> Void)

    /// Register handler for incoming ICE candidates
    func onICECandidate(_ handler: @escaping @Sendable @MainActor (ICECandidate, String) -> Void)
}

// MARK: - Simple Signaling Channel

/// Simplified signaling helper that coordinates peer connection setup
@MainActor
public final class SignalingChannel: Sendable {
    private let client: SignalingClient
    private let peerConnection: RTCPeerConnection

    public init(client: SignalingClient, peerConnection: RTCPeerConnection) {
        self.client = client
        self.peerConnection = peerConnection
        setupHandlers()
    }

    private func setupHandlers() {
        // Forward offers
        client.onOffer { [weak self] offer in
            guard let self = self else { return }
            Task {
                try? await self.peerConnection.setRemoteDescription(offer)
                let answer = try? await self.peerConnection.createAnswer()
                if let answer = answer {
                    try? await self.peerConnection.setLocalDescription(answer)
                    try? self.client.sendAnswer(answer)
                }
            }
        }

        // Forward answers
        client.onAnswer { [weak self] answer in
            guard let self = self else { return }
            Task {
                try? await self.peerConnection.setRemoteDescription(answer)
            }
        }

        // Forward ICE candidates
        client.onICECandidate { [weak self] candidate in
            guard let self = self else { return }
            Task {
                try? await self.peerConnection.addICECandidate(candidate)
            }
        }

        // Send local ICE candidates
        peerConnection.onICECandidate { [weak self] candidate in
            guard let self = self, let candidate = candidate else { return }
            try? self.client.sendICECandidate(candidate)
        }
    }

    /// Create and send an offer
    public func createOffer() async throws {
        let offer = try await peerConnection.createOffer()
        try await peerConnection.setLocalDescription(offer)
        try client.sendOffer(offer)
    }
}
