import Foundation
import JavaScriptKit

/// Manages Progressive Web App installation prompts and install state
///
/// InstallPrompt provides control over the app installation experience,
/// allowing developers to customize when and how users are prompted to
/// install the PWA to their device.
///
/// Example usage:
/// ```swift
/// let installPrompt = InstallPrompt()
///
/// // Check if app can be installed
/// if installPrompt.canInstall {
///     // Show custom install button
///     Button("Install App") {
///         Task {
///             do {
///                 let installed = try await installPrompt.promptInstall()
///                 if installed {
///                     print("App installed successfully!")
///                 }
///             } catch {
///                 print("Installation failed: \(error)")
///             }
///         }
///     }
/// }
///
/// // Listen for install state changes
/// installPrompt.onInstallStateChanged = { state in
///     print("Install state changed: \(state)")
/// }
/// ```
@MainActor
public final class InstallPrompt: Sendable {

    // MARK: - Properties

    /// Cached reference to the beforeinstallprompt event
    private var deferredPrompt: JSObject?

    /// Current installation state
    private var installState: InstallState = .unknown

    /// Callback for install state changes
    public var onInstallStateChanged: (@Sendable @MainActor (InstallState) -> Void)?

    /// Whether the app can be installed
    public var canInstall: Bool {
        deferredPrompt != nil && installState == .installable
    }

    /// Whether the app is already installed
    public var isInstalled: Bool {
        installState == .installed
    }

    // MARK: - Initialization

    public init() {
        setupEventListeners()
        checkInstallState()
    }

    // MARK: - Public API

    /// Prompt the user to install the PWA
    /// - Returns: True if the user accepted the install prompt
    /// - Throws: InstallError if prompting fails
    public func promptInstall() async throws -> Bool {
        guard let prompt = deferredPrompt else {
            throw InstallError.notAvailable
        }

        guard installState == .installable else {
            throw InstallError.notInstallable
        }

        do {
            // Show the install prompt
            _ = prompt.prompt.function!()

            // Wait for user response
            let userChoice = prompt.userChoice
            let outcome = try await JSPromise(from: userChoice)!.getValue()

            let accepted = outcome.outcome.string == "accepted"

            if accepted {
                updateInstallState(.installing)
            } else {
                updateInstallState(.dismissed)
            }

            // Clear the deferred prompt as it can only be used once
            deferredPrompt = nil

            return accepted
        } catch {
            throw InstallError.promptFailed(error.localizedDescription)
        }
    }

    /// Cancel the install prompt and prevent future prompts
    public func cancelPrompt() {
        deferredPrompt = nil
        updateInstallState(.dismissed)
    }

    /// Check if the app is running in standalone mode (installed)
    /// - Returns: True if app is running as installed PWA
    public func isRunningStandalone() -> Bool {
        let navigator = JSObject.global.navigator

        // Check display mode
        if let matchMedia = JSObject.global.matchMedia.function {
            let standalone = matchMedia("(display-mode: standalone)")
            if let matches = standalone.object?.matches.boolean {
                return matches
            }
        }

        // Fallback: check navigator.standalone (iOS Safari)
        if let standalone = navigator.standalone.boolean {
            return standalone
        }

        return false
    }

    /// Get installation-related metrics
    /// - Returns: Installation metrics
    public func getMetrics() -> InstallMetrics {
        InstallMetrics(
            state: installState,
            canInstall: canInstall,
            isStandalone: isRunningStandalone(),
            hasPromptAvailable: deferredPrompt != nil
        )
    }

    // MARK: - Private Methods

    /// Set up event listeners for install-related events
    private func setupEventListeners() {
        let window = JSObject.global

        // Listen for beforeinstallprompt event
        let beforeInstallClosure = JSClosure { [weak self] args -> JSValue in
            guard let self = self, args.count > 0 else {
                return .undefined
            }

            let event = args[0]

            // Prevent automatic prompt
            _ = event.preventDefault.function?()

            Task { @MainActor in
                // Store the event for later use
                self.deferredPrompt = event.object
                self.updateInstallState(.installable)
            }

            return .undefined
        }

        _ = window.addEventListener.function!("beforeinstallprompt", beforeInstallClosure)

        // Listen for appinstalled event
        let appInstalledClosure = JSClosure { [weak self] _ -> JSValue in
            Task { @MainActor in
                self?.updateInstallState(.installed)
                self?.deferredPrompt = nil
            }
            return .undefined
        }

        _ = window.addEventListener.function!("appinstalled", appInstalledClosure)

        // Store closures to prevent deallocation
        window.__ravenInstallClosures = JSValue.object(JSObject.global.Array.function!.new())
        _ = window.__ravenInstallClosures.push.function!(beforeInstallClosure, appInstalledClosure)
    }

    /// Check current installation state
    private func checkInstallState() {
        if isRunningStandalone() {
            updateInstallState(.installed)
        } else {
            updateInstallState(.unknown)
        }
    }

    /// Update installation state and notify listeners
    private func updateInstallState(_ newState: InstallState) {
        guard installState != newState else { return }

        installState = newState
        onInstallStateChanged?(newState)
    }
}

// MARK: - Supporting Types

/// Installation state of the PWA
public enum InstallState: String, Sendable {
    /// Installation state is unknown
    case unknown
    /// App can be installed
    case installable
    /// User is being prompted to install
    case installing
    /// App is installed
    case installed
    /// User dismissed the install prompt
    case dismissed
}

/// Installation metrics
public struct InstallMetrics: Sendable {
    /// Current installation state
    public let state: InstallState

    /// Whether app can be installed
    public let canInstall: Bool

    /// Whether app is running in standalone mode
    public let isStandalone: Bool

    /// Whether install prompt is available
    public let hasPromptAvailable: Bool
}

/// Errors that can occur during installation
public enum InstallError: Error, Sendable {
    /// Install prompt is not available
    case notAvailable
    /// App is not in an installable state
    case notInstallable
    /// Prompting failed with error message
    case promptFailed(String)
}
