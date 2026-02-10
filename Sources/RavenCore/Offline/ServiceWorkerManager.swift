import Foundation
import JavaScriptKit

/// Manages Service Worker registration, lifecycle, and updates.
///
/// `ServiceWorkerManager` provides a Swift-friendly interface to the Service Worker API,
/// handling registration, activation, updates, and messaging with the service worker.
@MainActor
public final class ServiceWorkerManager: @unchecked Sendable {
    /// Singleton instance for global service worker management
    public static let shared = ServiceWorkerManager()

    // MARK: - Registration State

    /// Represents the registration state of a service worker
    public enum RegistrationState: Sendable {
        case unregistered
        case installing
        case waiting
        case active
        case redundant
    }

    /// Represents service worker update status
    public enum UpdateStatus: Sendable {
        case noUpdate
        case updateAvailable
        case updateReady
    }

    // MARK: - Properties

    /// Current service worker registration
    nonisolated(unsafe) private var registration: JSObject?

    /// Current registration state
    private(set) var state: RegistrationState = .unregistered

    /// Whether service workers are supported
    public let isSupported: Bool

    /// Callbacks for state changes
    private var stateCallbacks: [UUID: @Sendable @MainActor (RegistrationState) -> Void] = [:]

    /// Callbacks for update events
    private var updateCallbacks: [UUID: @Sendable @MainActor (UpdateStatus) -> Void] = [:]

    /// Callbacks for messages from service worker
    private var messageCallbacks: [UUID: @Sendable @MainActor (JSValue) -> Void] = [:]

    /// JavaScript closures for event handlers
    nonisolated(unsafe) private var stateChangeHandler: JSClosure?
    nonisolated(unsafe) private var updateFoundHandler: JSClosure?
    nonisolated(unsafe) private var controllerChangeHandler: JSClosure?
    nonisolated(unsafe) private var messageHandler: JSClosure?

    // MARK: - Initialization

    private init() {
        #if arch(wasm32)
        // Check if service workers are supported
        let navigator = JSObject.global.navigator
        self.isSupported = !navigator.serviceWorker.isUndefined

        if isSupported {
            setupEventListeners()
            checkExistingRegistration()
        }
        #else
        self.isSupported = false
        #endif
    }

    // MARK: - Registration

    /// Register a service worker
    /// - Parameters:
    ///   - scriptURL: URL to the service worker script
    ///   - scope: Optional scope for the service worker
    /// - Returns: True if registration was successful
    @discardableResult
    public func register(scriptURL: String, scope: String? = nil) async -> Bool {
        guard isSupported else {
            return false
        }

        do {
            let navigator = JSObject.global.navigator
            guard let serviceWorker = navigator.serviceWorker.object else {
                return false
            }

            // Build registration options
            let optionsValue: JSValue
            if let scope = scope {
                let options = JSObject.global.Object.function!.new()
                options.scope = .string(scope)
                optionsValue = .object(options)
            } else {
                optionsValue = .undefined
            }

            // Register the service worker
            guard let registerFn = serviceWorker[dynamicMember: "register"].function else {
                throw NSError(domain: "ServiceWorker", code: -1, userInfo: [NSLocalizedDescriptionKey: "Register function not available"])
            }
            let promise = registerFn(scriptURL, optionsValue)

            // Await the promise
            let result = try await JSPromise(promise.object!)!.getValue()

            if let reg = result.object {
                self.registration = reg
                updateState(from: reg)
                setupRegistrationEventListeners(reg)
                return true
            }

            return false
        } catch {
            return false
        }
    }

    /// Unregister the current service worker
    /// - Returns: True if unregistration was successful
    @discardableResult
    public func unregister() async -> Bool {
        guard let registration = registration else {
            return false
        }

        do {
            guard let unregisterFunc = registration.unregister.function else {
                return false
            }
            let promise = unregisterFunc()
            let result = try await JSPromise(promise.object!)!.getValue()

            if result.boolean == true {
                self.registration = nil
                self.state = .unregistered
                notifyStateChange(.unregistered)
                return true
            }

            return false
        } catch {
            return false
        }
    }

    /// Check for service worker updates
    public func checkForUpdate() async {
        guard let registration = registration else {
            return
        }

        do {
            guard let updateFn = registration[dynamicMember: "update"].function else { return }
            let promise = updateFn()
            _ = try await JSPromise(promise.object!)!.getValue()
        } catch {
            // Update check failed, continue silently
        }
    }

    // MARK: - Communication

    /// Send a message to the active service worker
    /// - Parameter message: Message to send (must be JSON-serializable)
    public func postMessage(_ message: [String: Any]) {
        guard let registration = registration,
              let active = registration.active.object else {
            return
        }

        // Convert Swift dictionary to JSObject
        let jsMessage = convertToJSValue(message)
        _ = active.postMessage?(jsMessage)
    }

    /// Send a message and wait for a response
    /// - Parameter message: Message to send
    /// - Returns: Response from the service worker
    public func sendMessage(_ message: [String: Any]) async -> JSValue? {
        guard let registration = registration,
              let active = registration.active.object else {
            return nil
        }

        return await withCheckedContinuation { continuation in
            let messageChannel = JSObject.global.MessageChannel.function!.new()
            let port1 = messageChannel.port1
            let port2 = messageChannel.port2

            // Set up one-time response handler
            let responseHandler = JSClosure { args in
                if let event = args.first?.object,
                   let data = event.data.object {
                    continuation.resume(returning: .object(data))
                } else {
                    continuation.resume(returning: nil)
                }
                return .undefined
            }

            _ = port1.addEventListener("message", responseHandler)

            // Send message with port
            let jsMessage = convertToJSValue(message)
            guard let postMessageFunc = active.postMessage.function else { return }
            _ = postMessageFunc(jsMessage, [port2])
        }
    }

    // MARK: - Event Callbacks

    /// Register callback for state changes
    /// - Parameter callback: Closure called with new state
    /// - Returns: Token for unregistering the callback
    public func onStateChange(
        _ callback: @escaping @Sendable @MainActor (RegistrationState) -> Void
    ) -> UUID {
        let id = UUID()
        stateCallbacks[id] = callback
        return id
    }

    /// Register callback for update events
    /// - Parameter callback: Closure called with update status
    /// - Returns: Token for unregistering the callback
    public func onUpdate(
        _ callback: @escaping @Sendable @MainActor (UpdateStatus) -> Void
    ) -> UUID {
        let id = UUID()
        updateCallbacks[id] = callback
        return id
    }

    /// Register callback for messages from service worker
    /// - Parameter callback: Closure called with message data
    /// - Returns: Token for unregistering the callback
    public func onMessage(
        _ callback: @escaping @Sendable @MainActor (JSValue) -> Void
    ) -> UUID {
        let id = UUID()
        messageCallbacks[id] = callback
        return id
    }

    /// Unregister a callback
    /// - Parameter token: Token returned from registration
    public func removeCallback(_ token: UUID) {
        stateCallbacks.removeValue(forKey: token)
        updateCallbacks.removeValue(forKey: token)
        messageCallbacks.removeValue(forKey: token)
    }

    // MARK: - Private Methods

    private func checkExistingRegistration() {
        Task {
            guard isSupported else { return }

            let navigator = JSObject.global.navigator
            guard let serviceWorker = navigator.serviceWorker.object else { return }

            do {
                let promise = serviceWorker.ready
                let reg = try await JSPromise(promise.object!)!.getValue()

                if let regObject = reg.object {
                    self.registration = regObject
                    updateState(from: regObject)
                    setupRegistrationEventListeners(regObject)
                }
            } catch {
                // No existing registration
            }
        }
    }

    private func setupEventListeners() {
        let navigator = JSObject.global.navigator
        guard let serviceWorker = navigator.serviceWorker.object else { return }

        // Controller change (new service worker takes control)
        let controllerHandler = JSClosure { [weak self] _ in
            Task { @MainActor in
                self?.handleControllerChange()
            }
            return .undefined
        }
        self.controllerChangeHandler = controllerHandler
        _ = serviceWorker.addEventListener?("controllerchange", controllerHandler)

        // Messages from service worker
        let messageHandler = JSClosure { [weak self] args in
            Task { @MainActor in
                if let event = args.first?.object,
                   let data = event.data.object {
                    self?.handleMessage(.object(data))
                }
            }
            return .undefined
        }
        self.messageHandler = messageHandler
        _ = serviceWorker.addEventListener?("message", messageHandler)
    }

    private func setupRegistrationEventListeners(_ registration: JSObject) {
        // Update found event
        let updateHandler = JSClosure { [weak self] _ in
            Task { @MainActor in
                self?.handleUpdateFound()
            }
            return .undefined
        }
        self.updateFoundHandler = updateHandler
        _ = registration.addEventListener?("updatefound", updateHandler)

        // Monitor installing worker state changes
        if let installing = registration.installing.object {
            monitorWorkerState(installing)
        }

        // Monitor waiting worker state changes
        if let waiting = registration.waiting.object {
            monitorWorkerState(waiting)
        }

        // Monitor active worker state changes
        if let active = registration.active.object {
            monitorWorkerState(active)
        }
    }

    private func monitorWorkerState(_ worker: JSObject) {
        let stateHandler = JSClosure { [weak self] _ in
            Task { @MainActor in
                self?.handleWorkerStateChange()
            }
            return .undefined
        }
        _ = worker.addEventListener?("statechange", stateHandler)
    }

    private func updateState(from registration: JSObject) {
        if !registration.active.isNull && !registration.active.isUndefined {
            state = .active
        } else if !registration.waiting.isNull && !registration.waiting.isUndefined {
            state = .waiting
        } else if !registration.installing.isNull && !registration.installing.isUndefined {
            state = .installing
        } else {
            state = .unregistered
        }

        notifyStateChange(state)
    }

    private func handleUpdateFound() {
        notifyUpdate(.updateAvailable)

        guard let registration = registration else { return }

        // Monitor the installing worker
        if let installing = registration.installing.object {
            monitorWorkerState(installing)
        }
    }

    private func handleControllerChange() {
        notifyUpdate(.updateReady)

        if let registration = registration {
            updateState(from: registration)
        }
    }

    private func handleWorkerStateChange() {
        if let registration = registration {
            updateState(from: registration)
        }
    }

    private func handleMessage(_ data: JSValue) {
        for callback in messageCallbacks.values {
            callback(data)
        }
    }

    private func notifyStateChange(_ newState: RegistrationState) {
        for callback in stateCallbacks.values {
            callback(newState)
        }
    }

    private func notifyUpdate(_ status: UpdateStatus) {
        for callback in updateCallbacks.values {
            callback(status)
        }
    }

    private func convertToJSValue(_ value: Any) -> JSValue {
        if let dict = value as? [String: Any] {
            let jsObj = JSObject.global.Object.function!.new()
            for (key, val) in dict {
                jsObj[dynamicMember: key] = convertToJSValue(val)
            }
            return .object(jsObj)
        } else if let array = value as? [Any] {
            let jsArray = JSObject.global.Array.function!.new()
            for (index, item) in array.enumerated() {
                jsArray[index] = convertToJSValue(item)
            }
            return .object(jsArray)
        } else if let string = value as? String {
            return .string(string)
        } else if let number = value as? Double {
            return .number(number)
        } else if let number = value as? Int {
            return .number(Double(number))
        } else if let bool = value as? Bool {
            return .boolean(bool)
        } else {
            return .null
        }
    }

    // MARK: - Cleanup

    deinit {
        if let handler = controllerChangeHandler {
            let navigator = JSObject.global.navigator
            _ = navigator.serviceWorker.removeEventListener("controllerchange", handler)
        }

        if let handler = messageHandler {
            let navigator = JSObject.global.navigator
            _ = navigator.serviceWorker.removeEventListener("message", handler)
        }

        if let registration = registration, let handler = updateFoundHandler {
            guard let removeFunc = registration.removeEventListener.function else { return }
            _ = removeFunc("updatefound", handler)
        }
    }
}
