import Foundation
import JavaScriptKit

/// Represents the current network connection state and capabilities.
///
/// `NetworkState` monitors the browser's network connectivity using the Network Information API
/// and provides real-time updates about connection status, type, and quality.
@MainActor
public final class NetworkState: @unchecked Sendable {
    /// Singleton instance for global network state access
    public static let shared = NetworkState()

    // MARK: - Connection Types

    /// Represents the type of network connection
    public enum ConnectionType: String, Sendable {
        case bluetooth
        case cellular
        case ethernet
        case none
        case wifi
        case wimax
        case other
        case unknown
    }

    /// Represents the effective connection type based on observed round-trip time and downlink
    public enum EffectiveType: String, Sendable {
        case slow2g = "slow-2g"
        case twoG = "2g"
        case threeG = "3g"
        case fourG = "4g"
        case unknown
    }

    // MARK: - Properties

    /// Current online/offline status
    private(set) var isOnline: Bool

    /// Current connection type
    private(set) var connectionType: ConnectionType

    /// Effective connection type
    private(set) var effectiveType: EffectiveType

    /// Downlink speed estimate in Mbps
    private(set) var downlink: Double?

    /// Round-trip time estimate in milliseconds
    private(set) var rtt: Double?

    /// Whether the user has enabled data saver mode
    private(set) var saveData: Bool

    /// Callbacks for online status changes
    nonisolated(unsafe) private var onlineCallbacks: [UUID: @Sendable @MainActor (Bool) -> Void] = [:]

    /// Callbacks for connection changes
    nonisolated(unsafe) private var connectionCallbacks: [UUID: @Sendable @MainActor (ConnectionInfo) -> Void] = [:]

    /// JavaScript closures for event handlers
    nonisolated(unsafe) private var onlineHandler: JSClosure?
    nonisolated(unsafe) private var offlineHandler: JSClosure?
    nonisolated(unsafe) private var connectionChangeHandler: JSClosure?

    // MARK: - Connection Info

    /// Aggregate connection information
    public struct ConnectionInfo: Sendable {
        public let isOnline: Bool
        public let type: ConnectionType
        public let effectiveType: EffectiveType
        public let downlink: Double?
        public let rtt: Double?
        public let saveData: Bool

        public init(
            isOnline: Bool,
            type: ConnectionType,
            effectiveType: EffectiveType,
            downlink: Double?,
            rtt: Double?,
            saveData: Bool
        ) {
            self.isOnline = isOnline
            self.type = type
            self.effectiveType = effectiveType
            self.downlink = downlink
            self.rtt = rtt
            self.saveData = saveData
        }
    }

    // MARK: - Initialization

    private init() {
        #if arch(wasm32)
        // Initialize with current navigator.onLine status
        self.isOnline = JSObject.global.navigator.onLine.boolean ?? true
        #else
        self.isOnline = true
        #endif
        self.connectionType = .unknown
        self.effectiveType = .unknown
        self.saveData = false

        #if arch(wasm32)
        // Update connection info from Network Information API
        updateConnectionInfo()

        // Set up event listeners
        setupEventListeners()
        #endif
    }

    // MARK: - Public API

    /// Get current connection information
    public var currentInfo: ConnectionInfo {
        ConnectionInfo(
            isOnline: isOnline,
            type: connectionType,
            effectiveType: effectiveType,
            downlink: downlink,
            rtt: rtt,
            saveData: saveData
        )
    }

    /// Register callback for online status changes
    /// - Parameter callback: Closure called with new online status
    /// - Returns: Token for unregistering the callback
    public func onOnlineStatusChange(
        _ callback: @escaping @Sendable @MainActor (Bool) -> Void
    ) -> UUID {
        let id = UUID()
        onlineCallbacks[id] = callback
        return id
    }

    /// Register callback for connection changes
    /// - Parameter callback: Closure called with new connection info
    /// - Returns: Token for unregistering the callback
    public func onConnectionChange(
        _ callback: @escaping @Sendable @MainActor (ConnectionInfo) -> Void
    ) -> UUID {
        let id = UUID()
        connectionCallbacks[id] = callback
        return id
    }

    /// Unregister a callback
    /// - Parameter token: Token returned from registration
    nonisolated public func removeCallback(_ token: UUID) {
        onlineCallbacks.removeValue(forKey: token)
        connectionCallbacks.removeValue(forKey: token)
    }

    /// Check if connection is fast enough for heavy operations
    /// - Returns: True if connection is 3G or better
    public func isFastConnection() -> Bool {
        switch effectiveType {
        case .fourG, .threeG:
            return true
        case .twoG, .slow2g, .unknown:
            return false
        }
    }

    /// Check if connection should use reduced data
    /// - Returns: True if data saver is enabled or connection is slow
    public func shouldReduceData() -> Bool {
        saveData || effectiveType == .slow2g || effectiveType == .twoG
    }

    // MARK: - Private Methods

    private func updateConnectionInfo() {
        let navigator = JSObject.global.navigator

        // Check if Network Information API is available
        guard let connection = navigator.connection.object ?? navigator.mozConnection.object ?? navigator.webkitConnection.object else {
            return
        }

        // Update connection type
        if let typeString = connection.type.string {
            connectionType = ConnectionType(rawValue: typeString) ?? .unknown
        } else if connection.effectiveType.string != nil {
            // Fallback to effective type
            connectionType = .unknown
        }

        // Update effective type
        if let effectiveTypeString = connection.effectiveType.string {
            effectiveType = EffectiveType(rawValue: effectiveTypeString) ?? .unknown
        }

        // Update downlink (in Mbps)
        if let downlinkValue = connection.downlink.number {
            downlink = downlinkValue
        }

        // Update RTT (in milliseconds)
        if let rttValue = connection.rtt.number {
            rtt = rttValue
        }

        // Update save data preference
        saveData = connection.saveData.boolean ?? false
    }

    private func setupEventListeners() {
        let window = JSObject.global

        // Online event
        let onlineHandler = JSClosure { [weak self] _ in
            Task { @MainActor in
                self?.handleOnlineChange(true)
            }
            return .undefined
        }
        self.onlineHandler = onlineHandler
        _ = window.addEventListener?("online", onlineHandler)

        // Offline event
        let offlineHandler = JSClosure { [weak self] _ in
            Task { @MainActor in
                self?.handleOnlineChange(false)
            }
            return .undefined
        }
        self.offlineHandler = offlineHandler
        _ = window.addEventListener?("offline", offlineHandler)

        // Connection change event
        let navigator = window.navigator
        if let connection = navigator.connection.object ?? navigator.mozConnection.object ?? navigator.webkitConnection.object {
            let changeHandler = JSClosure { [weak self] _ in
                Task { @MainActor in
                    self?.handleConnectionChange()
                }
                return .undefined
            }
            self.connectionChangeHandler = changeHandler
            _ = connection.addEventListener?("change", changeHandler)
        }
    }

    private func handleOnlineChange(_ online: Bool) {
        let wasOnline = isOnline
        isOnline = online

        // Notify online status callbacks
        if wasOnline != online {
            for callback in onlineCallbacks.values {
                callback(online)
            }

            // Also notify connection callbacks with full info
            let info = currentInfo
            for callback in connectionCallbacks.values {
                callback(info)
            }
        }
    }

    private func handleConnectionChange() {
        updateConnectionInfo()

        // Notify connection callbacks
        let info = currentInfo
        for callback in connectionCallbacks.values {
            callback(info)
        }
    }

    // MARK: - Cleanup

    deinit {
        let window = JSObject.global

        if let handler = onlineHandler {
            _ = window.removeEventListener?("online", handler)
        }

        if let handler = offlineHandler {
            _ = window.removeEventListener?("offline", handler)
        }

        if let handler = connectionChangeHandler {
            let navigator = window.navigator
            if let connection = navigator.connection.object ?? navigator.mozConnection.object ?? navigator.webkitConnection.object {
                _ = connection.removeEventListener?("change", handler)
            }
        }
    }
}
