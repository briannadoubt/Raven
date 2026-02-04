import Foundation
import JavaScriptKit

/// Represents a bidirectional data channel between two peers
///
/// DataChannel provides peer-to-peer communication for arbitrary application data.
/// It supports both reliable (TCP-like) and unreliable (UDP-like) delivery modes,
/// with configurable ordering and retransmission policies.
///
/// ## Example Usage
///
/// ```swift
/// // Create channel with options
/// let options = DataChannelOptions(
///     ordered: true,
///     maxRetransmits: 3
/// )
///
/// let channel = try await peerConnection.createDataChannel?(
///     label: "chat",
///     options: options
/// )
///
/// // Send data
/// try channel.send?("Hello, peer!")
/// try channel.send?(Data([0x01, 0x02, 0x03]))
///
/// // Receive messages
/// for await message in channel.messages {
///     print("Received:", message)
/// }
/// ```
@MainActor
public final class DataChannel: Sendable {
    // MARK: - Properties

    /// The underlying JavaScript RTCDataChannel object
    private let jsChannel: JSObject

    /// Label identifying this channel
    public let label: String

    /// Channel ID assigned by the browser
    public var id: Int? {
        let value = jsChannel.id
        if let num = value.number {
            return Int(num)
        }
        return nil
    }

    /// Whether the channel guarantees message ordering
    public var ordered: Bool {
        jsChannel.ordered.boolean ?? true
    }

    /// Maximum number of retransmission attempts
    public var maxRetransmits: Int? {
        let value = jsChannel.maxRetransmits
        if let num = value.number {
            return Int(num)
        }
        return nil
    }

    /// Maximum time in milliseconds for retransmissions
    public var maxPacketLifeTime: Int? {
        let value = jsChannel.maxPacketLifeTime
        if let num = value.number {
            return Int(num)
        }
        return nil
    }

    /// Protocol used by the channel
    public var `protocol`: String {
        jsChannel.protocol.string ?? ""
    }

    /// Whether negotiation was handled by application or browser
    public var negotiated: Bool {
        jsChannel.negotiated.boolean ?? false
    }

    /// Current state of the data channel
    public var readyState: ReadyState {
        if let stateString = jsChannel.readyState.string {
            return ReadyState(rawValue: stateString) ?? .closed
        }
        return .closed
    }

    /// Number of bytes currently queued to be sent
    public var bufferedAmount: Int {
        Int(jsChannel.bufferedAmount.number ?? 0)
    }

    /// Threshold for bufferedAmount at which the buffer becomes low
    public var bufferedAmountLowThreshold: Int {
        get {
            Int(jsChannel.bufferedAmountLowThreshold.number ?? 0)
        }
        set {
            jsChannel.bufferedAmountLowThreshold = .number(Double(newValue))
        }
    }

    /// Binary data type (blob or arraybuffer)
    public var binaryType: BinaryType {
        get {
            if let typeString = jsChannel.binaryType.string {
                return BinaryType(rawValue: typeString) ?? .arraybuffer
            }
            return .arraybuffer
        }
        set {
            jsChannel.binaryType = .string(newValue.rawValue)
        }
    }

    // MARK: - Event Handlers

    private var openHandlers: [UUID: @Sendable @MainActor () -> Void] = [:]
    private var closeHandlers: [UUID: @Sendable @MainActor () -> Void] = [:]
    private var errorHandlers: [UUID: @Sendable @MainActor (Error) -> Void] = [:]
    private var messageHandlers: [UUID: @Sendable @MainActor (DataChannelMessage) -> Void] = [:]
    private var bufferedAmountLowHandlers: [UUID: @Sendable @MainActor () -> Void] = [:]

    // MARK: - Event Closures

    private var openClosure: JSClosure?
    private var closeClosure: JSClosure?
    private var errorClosure: JSClosure?
    private var messageClosure: JSClosure?
    private var bufferedAmountLowClosure: JSClosure?

    // MARK: - Initialization

    /// Creates a data channel from a JavaScript RTCDataChannel object
    ///
    /// - Parameter jsChannel: The JavaScript RTCDataChannel object
    internal init(jsChannel: JSObject) {
        self.jsChannel = jsChannel
        self.label = jsChannel.label.string ?? ""
        setupEventHandlers()
    }

    deinit {
    }

    // MARK: - Event Handler Setup

    private func setupEventHandlers() {
        // Open event
        openClosure = JSClosure { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                for handler in self.openHandlers.values {
                    handler()
                }
            }
            return .undefined
        }
        jsChannel.onopen = .object(openClosure!)

        // Close event
        closeClosure = JSClosure { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                for handler in self.closeHandlers.values {
                    handler()
                }
            }
            return .undefined
        }
        jsChannel.onclose = .object(closeClosure!)

        // Error event
        errorClosure = JSClosure { [weak self] args in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                let error = DataChannelError.unknown
                for handler in self.errorHandlers.values {
                    handler(error)
                }
            }
            return .undefined
        }
        jsChannel.onerror = .object(errorClosure!)

        // Message event
        messageClosure = JSClosure { [weak self] args in
            Task { @MainActor [weak self] in
                guard let self = self,
                      args.count > 0,
                      let event = args[0].object else { return }

                let message: DataChannelMessage

                // Check if data is string
                if let stringData = event.data.string {
                    message = .text(stringData)
                }
                // Check if data is ArrayBuffer
                else if let arrayBuffer = event.data.object {
                    // Convert ArrayBuffer to Data
                    let uint8Array = JSObject.global.Uint8Array.call(arrayBuffer)
                    let length = Int(uint8Array.length.number ?? 0)
                    var bytes: [UInt8] = []
                    bytes.reserveCapacity(length)

                    for i in 0..<length {
                        if let byte = uint8Array[i].number {
                            bytes.append(UInt8(byte))
                        }
                    }

                    message = .binary(Data(bytes))
                } else {
                    return
                }

                for handler in self.messageHandlers.values {
                    handler(message)
                }
            }
            return .undefined
        }
        jsChannel.onmessage = .object(messageClosure!)

        // Buffered amount low event
        bufferedAmountLowClosure = JSClosure { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                for handler in self.bufferedAmountLowHandlers.values {
                    handler()
                }
            }
            return .undefined
        }
        jsChannel.onbufferedamountlow = .object(bufferedAmountLowClosure!)
    }

    // MARK: - Event Handlers Registration

    /// Register a handler for channel open events
    ///
    /// - Parameter handler: Closure called when channel opens
    /// - Returns: Registration ID for removing the handler
    @discardableResult
    public func onOpen(_ handler: @escaping @Sendable @MainActor () -> Void) -> UUID {
        let id = UUID()
        openHandlers[id] = handler
        return id
    }

    /// Register a handler for channel close events
    ///
    /// - Parameter handler: Closure called when channel closes
    /// - Returns: Registration ID for removing the handler
    @discardableResult
    public func onClose(_ handler: @escaping @Sendable @MainActor () -> Void) -> UUID {
        let id = UUID()
        closeHandlers[id] = handler
        return id
    }

    /// Register a handler for error events
    ///
    /// - Parameter handler: Closure called when an error occurs
    /// - Returns: Registration ID for removing the handler
    @discardableResult
    public func onError(_ handler: @escaping @Sendable @MainActor (Error) -> Void) -> UUID {
        let id = UUID()
        errorHandlers[id] = handler
        return id
    }

    /// Register a handler for message events
    ///
    /// - Parameter handler: Closure called when a message is received
    /// - Returns: Registration ID for removing the handler
    @discardableResult
    public func onMessage(_ handler: @escaping @Sendable @MainActor (DataChannelMessage) -> Void) -> UUID {
        let id = UUID()
        messageHandlers[id] = handler
        return id
    }

    /// Register a handler for buffered amount low events
    ///
    /// - Parameter handler: Closure called when buffered amount drops below threshold
    /// - Returns: Registration ID for removing the handler
    @discardableResult
    public func onBufferedAmountLow(_ handler: @escaping @Sendable @MainActor () -> Void) -> UUID {
        let id = UUID()
        bufferedAmountLowHandlers[id] = handler
        return id
    }

    /// Remove a registered event handler
    ///
    /// - Parameter id: Registration ID returned when handler was added
    public func removeHandler(_ id: UUID) {
        openHandlers.removeValue(forKey: id)
        closeHandlers.removeValue(forKey: id)
        errorHandlers.removeValue(forKey: id)
        messageHandlers.removeValue(forKey: id)
        bufferedAmountLowHandlers.removeValue(forKey: id)
    }

    // MARK: - Sending Data

    /// Send a text message over the channel
    ///
    /// - Parameter text: String to send
    /// - Throws: DataChannelError if channel is not open or buffer is full
    public func send(_ text: String) throws {
        guard readyState == .open else {
            throw DataChannelError.notOpen
        }

        _ = jsChannel.send.call(text)
    }

    /// Send binary data over the channel
    ///
    /// - Parameter data: Binary data to send
    /// - Throws: DataChannelError if channel is not open or buffer is full
    public func send(_ data: Data) throws {
        guard readyState == .open else {
            throw DataChannelError.notOpen
        }

        // Convert Data to Uint8Array
        let uint8Array = JSObject.global.Uint8Array.call(data.count)
        for (index, byte) in data.enumerated() {
            uint8Array[index] = .number(Double(byte))
        }

        _ = jsChannel.send.call(uint8Array)
    }

    // MARK: - Channel Control

    /// Close the data channel
    public func close() {
        _ = jsChannel.close?()
    }

    // MARK: - Cleanup

    private func cleanup() {
        openClosure = nil
        closeClosure = nil
        errorClosure = nil
        messageClosure = nil
        bufferedAmountLowClosure = nil

        openHandlers.removeAll()
        closeHandlers.removeAll()
        errorHandlers.removeAll()
        messageHandlers.removeAll()
        bufferedAmountLowHandlers.removeAll()
    }
}

// MARK: - Data Channel Message

/// Represents a message received on a data channel
public enum DataChannelMessage: Sendable {
    /// Text message
    case text(String)

    /// Binary message
    case binary(Data)
}

// MARK: - Ready State

extension DataChannel {
    /// Connection state of the data channel
    public enum ReadyState: String, Sendable {
        /// Channel is connecting
        case connecting

        /// Channel is open and ready to transmit data
        case open

        /// Channel is closing
        case closing

        /// Channel is closed
        case closed
    }
}

// MARK: - Binary Type

extension DataChannel {
    /// Format for binary data
    public enum BinaryType: String, Sendable {
        /// Blob format
        case blob

        /// ArrayBuffer format (recommended)
        case arraybuffer
    }
}

// MARK: - Data Channel Options

/// Configuration options for creating a data channel
@MainActor
public struct DataChannelOptions: Sendable {
    /// Whether messages are guaranteed to arrive in order
    public var ordered: Bool

    /// Maximum number of retransmission attempts (conflicts with maxPacketLifeTime)
    public var maxRetransmits: Int?

    /// Maximum time in milliseconds for retransmissions (conflicts with maxRetransmits)
    public var maxPacketLifeTime: Int?

    /// Sub-protocol name
    public var `protocol`: String

    /// Whether the channel was negotiated by the application
    public var negotiated: Bool

    /// Channel ID for negotiated channels
    public var id: Int?

    /// Creates data channel options
    ///
    /// - Parameters:
    ///   - ordered: Whether to guarantee message ordering. Defaults to true.
    ///   - maxRetransmits: Maximum retransmission attempts for unordered channels
    ///   - maxPacketLifeTime: Maximum time for retransmissions in milliseconds
    ///   - protocol: Sub-protocol name
    ///   - negotiated: Whether negotiation is handled by application
    ///   - id: Channel ID for negotiated channels
    public init(
        ordered: Bool = true,
        maxRetransmits: Int? = nil,
        maxPacketLifeTime: Int? = nil,
        protocol: String = "",
        negotiated: Bool = false,
        id: Int? = nil
    ) {
        self.ordered = ordered
        self.maxRetransmits = maxRetransmits
        self.maxPacketLifeTime = maxPacketLifeTime
        self.protocol = `protocol`
        self.negotiated = negotiated
        self.id = id
    }

    /// Convert to JavaScript object format
    internal func toJSDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "ordered": ordered,
            "protocol": `protocol`,
            "negotiated": negotiated
        ]

        if let maxRetransmits = maxRetransmits {
            dict["maxRetransmits"] = maxRetransmits
        }

        if let maxPacketLifeTime = maxPacketLifeTime {
            dict["maxPacketLifeTime"] = maxPacketLifeTime
        }

        if let id = id {
            dict["id"] = id
        }

        return dict
    }
}

// MARK: - Errors

/// Errors that can occur with data channels
public enum DataChannelError: Error, Sendable {
    /// Channel is not in open state
    case notOpen

    /// Send buffer is full
    case bufferFull

    /// Invalid data format
    case invalidData

    /// Unknown error occurred
    case unknown
}
