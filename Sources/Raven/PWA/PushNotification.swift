import Foundation
import JavaScriptKit

/// Manages push notification subscriptions and handling for PWA
///
/// PushNotification provides a comprehensive API for managing push notifications,
/// including permission requests, subscription management, and notification display.
///
/// Example usage:
/// ```swift
/// let pushNotification = PushNotification()
///
/// // Request permission
/// do {
///     let granted = try await pushNotification.requestPermission()
///     if granted {
///         // Subscribe to push notifications
///         let subscription = try await pushNotification.subscribe(
///             vapidPublicKey: "YOUR_VAPID_PUBLIC_KEY"
///         )
///         print("Subscribed: \(subscription.endpoint)")
///     }
/// } catch {
///     print("Failed to subscribe: \(error)")
/// }
///
/// // Display a notification
/// try await pushNotification.showNotification(
///     title: "New Message",
///     options: NotificationOptions(
///         body: "You have a new message",
///         icon: "/icon.png",
///         badge: "/badge.png"
///     )
/// )
/// ```
@MainActor
public final class PushNotification: Sendable {

    // MARK: - Properties

    /// Service worker registration
    private var registration: JSObject?

    /// Current push subscription
    private var currentSubscription: PushSubscription?

    /// Callback for notification clicks
    public var onNotificationClick: (@Sendable @MainActor (String) -> Void)?

    /// Callback for notification close
    public var onNotificationClose: (@Sendable @MainActor (String) -> Void)?

    // MARK: - Initialization

    public init() {
        Task {
            await initializeServiceWorker()
            await loadCurrentSubscription()
        }
    }

    // MARK: - Permission Management

    /// Request notification permission from the user
    /// - Returns: True if permission was granted
    /// - Throws: NotificationError if request fails
    public func requestPermission() async throws -> Bool {
        let notification = JSObject.global.Notification

        guard !notification.isUndefined else {
            throw NotificationError.notSupported
        }

        // Check current permission state
        let currentPermission = notification.permission.string ?? "default"

        if currentPermission == "granted" {
            return true
        } else if currentPermission == "denied" {
            throw NotificationError.permissionDenied
        }

        // Request permission
        guard let requestPermission = notification.requestPermission.function else {
            throw NotificationError.notSupported
        }

        let promise = requestPermission()
        let result = try await JSPromise(from: promise)!.getValue()

        let permission = result.string ?? "denied"
        return permission == "granted"
    }

    /// Get current notification permission state
    /// - Returns: Current permission state
    public func getPermissionState() -> PermissionState {
        let notification = JSObject.global.Notification

        guard !notification.isUndefined else {
            return .unsupported
        }

        switch notification.permission.string {
        case "granted":
            return .granted
        case "denied":
            return .denied
        default:
            return .prompt
        }
    }

    // MARK: - Subscription Management

    /// Subscribe to push notifications
    /// - Parameter vapidPublicKey: VAPID public key for push service
    /// - Returns: Push subscription information
    /// - Throws: NotificationError if subscription fails
    public func subscribe(vapidPublicKey: String) async throws -> PushSubscription {
        guard let registration = registration else {
            throw NotificationError.serviceWorkerNotAvailable
        }

        guard getPermissionState() == .granted else {
            throw NotificationError.permissionDenied
        }

        // Convert VAPID key to Uint8Array
        let applicationServerKey = urlBase64ToUint8Array(vapidPublicKey)

        // Subscribe options
        let options = JSObject.global.Object.function!.new()
        options.userVisibleOnly = .boolean(true)
        options.applicationServerKey = applicationServerKey

        // Subscribe
        let pushManager = registration.pushManager.object!
        let subscribePromise = pushManager.subscribe.function!(options)
        let subscription = try await JSPromise(from: subscribePromise)!.getValue()

        // Parse subscription
        let pushSubscription = try parsePushSubscription(subscription.object!)
        currentSubscription = pushSubscription

        return pushSubscription
    }

    /// Unsubscribe from push notifications
    /// - Throws: NotificationError if unsubscribe fails
    public func unsubscribe() async throws {
        guard let registration = registration else {
            throw NotificationError.serviceWorkerNotAvailable
        }

        let pushManager = registration.pushManager.object!
        let getSubscriptionPromise = pushManager.getSubscription.function!()
        let subscription = try await JSPromise(from: getSubscriptionPromise)!.getValue()

        if let sub = subscription.object {
            let unsubscribePromise = sub.unsubscribe.function!()
            _ = try await JSPromise(from: unsubscribePromise)!.getValue()
        }

        currentSubscription = nil
    }

    /// Get current push subscription
    /// - Returns: Current subscription or nil if not subscribed
    public func getSubscription() -> PushSubscription? {
        currentSubscription
    }

    // MARK: - Notification Display

    /// Show a notification
    /// - Parameters:
    ///   - title: Notification title
    ///   - options: Notification options
    /// - Throws: NotificationError if showing notification fails
    public func showNotification(title: String, options: NotificationOptions = NotificationOptions()) async throws {
        guard getPermissionState() == .granted else {
            throw NotificationError.permissionDenied
        }

        guard let registration = registration else {
            // Fallback to Web Notification API
            try showWebNotification(title: title, options: options)
            return
        }

        // Use service worker notification
        let optionsObj = options.toJSObject()
        _ = registration.showNotification.function!(title, optionsObj)
    }

    /// Show a notification using Web Notification API (fallback)
    private func showWebNotification(title: String, options: NotificationOptions) throws {
        let notification = JSObject.global.Notification

        guard !notification.isUndefined else {
            throw NotificationError.notSupported
        }

        let optionsObj = options.toJSObject()
        _ = notification.function!.new(title, optionsObj)
    }

    // MARK: - Private Methods

    /// Initialize service worker
    private func initializeServiceWorker() async {
        let navigator = JSObject.global.navigator

        guard let serviceWorker = navigator.serviceWorker.object else {
            print("⚠️ PushNotification: Service Worker not supported")
            return
        }

        do {
            // Get ready service worker registration
            let readyPromise = serviceWorker.ready
            let reg = try await JSPromise(from: readyPromise)!.getValue()
            registration = reg.object
        } catch {
            print("⚠️ PushNotification: Failed to get service worker registration")
        }
    }

    /// Load current subscription
    private func loadCurrentSubscription() async {
        guard let registration = registration else { return }

        do {
            let pushManager = registration.pushManager.object!
            let getSubscriptionPromise = pushManager.getSubscription.function!()
            let subscription = try await JSPromise(from: getSubscriptionPromise)!.getValue()

            if let sub = subscription.object {
                currentSubscription = try parsePushSubscription(sub)
            }
        } catch {
            print("⚠️ PushNotification: Failed to load current subscription")
        }
    }

    /// Parse push subscription from JSObject
    private func parsePushSubscription(_ jsSubscription: JSObject) throws -> PushSubscription {
        let endpoint = jsSubscription.endpoint.string ?? ""

        // Get keys
        let getKeyFunc = jsSubscription.getKey.function!
        let p256dhKey = getKeyFunc("p256dh")
        let authKey = getKeyFunc("auth")

        // Convert to base64
        let p256dh = arrayBufferToBase64(p256dhKey.object!)
        let auth = arrayBufferToBase64(authKey.object!)

        return PushSubscription(
            endpoint: endpoint,
            keys: SubscriptionKeys(
                p256dh: p256dh,
                auth: auth
            )
        )
    }

    /// Convert URL-safe base64 to Uint8Array
    private func urlBase64ToUint8Array(_ base64String: String) -> JSValue {
        // Add padding
        var base64 = base64String
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")

        let padding = base64.count % 4
        if padding > 0 {
            base64 += String(repeating: "=", count: 4 - padding)
        }

        // Decode
        let rawData = JSObject.global.atob.function!(base64).string ?? ""
        let outputArray = JSObject.global.Uint8Array.function!.new(rawData.count)

        for (index, char) in rawData.enumerated() {
            outputArray[index] = .number(Double(char.asciiValue ?? 0))
        }

        return .object(outputArray)
    }

    /// Convert ArrayBuffer to base64
    private func arrayBufferToBase64(_ buffer: JSObject) -> String {
        let array = JSObject.global.Uint8Array.function!.new(buffer)
        let length = array.length.number ?? 0

        var binary = ""
        for i in 0..<Int(length) {
            if let byte = array[i].number {
                binary += String(UnicodeScalar(UInt8(byte)))
            }
        }

        return JSObject.global.btoa.function!(binary).string ?? ""
    }
}

// MARK: - Supporting Types

/// Permission state for notifications
public enum PermissionState: String, Sendable {
    case granted
    case denied
    case prompt
    case unsupported
}

/// Push subscription information
public struct PushSubscription: Sendable {
    /// Push endpoint URL
    public let endpoint: String

    /// Subscription keys
    public let keys: SubscriptionKeys
}

/// Subscription encryption keys
public struct SubscriptionKeys: Sendable {
    /// P256DH public key (base64 encoded)
    public let p256dh: String

    /// Authentication secret (base64 encoded)
    public let auth: String
}

/// Notification options
public struct NotificationOptions: Sendable {
    /// Notification body text
    public let body: String?

    /// Icon URL
    public let icon: String?

    /// Badge URL (small icon for notification bar)
    public let badge: String?

    /// Notification tag (for grouping)
    public let tag: String?

    /// Whether notification should be silent
    public let silent: Bool

    /// Whether notification requires interaction
    public let requireInteraction: Bool

    /// Action buttons
    public let actions: [NotificationAction]

    /// Custom data
    public let data: [String: String]

    public init(
        body: String? = nil,
        icon: String? = nil,
        badge: String? = nil,
        tag: String? = nil,
        silent: Bool = false,
        requireInteraction: Bool = false,
        actions: [NotificationAction] = [],
        data: [String: String] = [:]
    ) {
        self.body = body
        self.icon = icon
        self.badge = badge
        self.tag = tag
        self.silent = silent
        self.requireInteraction = requireInteraction
        self.actions = actions
        self.data = data
    }

    /// Convert to JavaScript object
    func toJSObject() -> JSObject {
        let obj = JSObject.global.Object.function!.new()

        if let body = body {
            obj.body = .string(body)
        }
        if let icon = icon {
            obj.icon = .string(icon)
        }
        if let badge = badge {
            obj.badge = .string(badge)
        }
        if let tag = tag {
            obj.tag = .string(tag)
        }

        obj.silent = .boolean(silent)
        obj.requireInteraction = .boolean(requireInteraction)

        if !actions.isEmpty {
            let actionsArray = JSObject.global.Array.function!.new()
            for action in actions {
                _ = actionsArray.push.function!(action.toJSObject())
            }
            obj.actions = JSValue.object(actionsArray)
        }

        if !data.isEmpty {
            let dataObj = JSObject.global.Object.function!.new()
            for (key, value) in data {
                dataObj[dynamicMember: key] = .string(value)
            }
            obj.data = JSValue.object(dataObj)
        }

        return obj
    }
}

/// Notification action button
public struct NotificationAction: Sendable {
    /// Action identifier
    public let action: String

    /// Button title
    public let title: String

    /// Icon URL
    public let icon: String?

    public init(action: String, title: String, icon: String? = nil) {
        self.action = action
        self.title = title
        self.icon = icon
    }

    /// Convert to JavaScript object
    func toJSObject() -> JSObject {
        let obj = JSObject.global.Object.function!.new()
        obj.action = .string(action)
        obj.title = .string(title)
        if let icon = icon {
            obj.icon = .string(icon)
        }
        return obj
    }
}

/// Notification errors
public enum NotificationError: Error, Sendable {
    case notSupported
    case permissionDenied
    case serviceWorkerNotAvailable
    case subscriptionFailed(String)
}
