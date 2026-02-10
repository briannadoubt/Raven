import Foundation

/// An indication of a scene's operational state.
///
/// The system moves scenes through different phases based on user interactions and system events.
/// In a web context, these phases are derived from the Page Visibility API and focus/blur events.
///
/// Use the `@Environment(\.scenePhase)` property to read the current phase:
///
/// ```swift
/// struct MyView: View {
///     @Environment(\.scenePhase) var scenePhase
///
///     var body: some View {
///         Text("App is \(scenePhase == .active ? "active" : "inactive")")
///             .onChange(of: scenePhase) { newPhase in
///                 if newPhase == .background {
///                     // Save state
///                 }
///             }
///     }
/// }
/// ```
public enum ScenePhase: Sendable, Equatable {
    /// The scene is in the foreground and interactive.
    ///
    /// In a web context, this means the page is visible and has focus.
    case active

    /// The scene is visible but not interactive.
    ///
    /// In a web context, this means the window has lost focus but the page is still visible.
    case inactive

    /// The scene is not visible.
    ///
    /// In a web context, this means the page is hidden (user switched to another tab).
    /// This is a good time to reduce resource usage and save state.
    case background
}

// MARK: - Environment Key

/// Environment key for the scene phase.
private struct ScenePhaseKey: EnvironmentKey {
    static let defaultValue: ScenePhase = .active
}

extension EnvironmentValues {
    /// The current operational state of the scene.
    ///
    /// Read this value to adapt your UI or trigger actions based on scene lifecycle:
    ///
    /// ```swift
    /// @Environment(\.scenePhase) var scenePhase
    ///
    /// var body: some View {
    ///     Text("Hello")
    ///         .onChange(of: scenePhase) { newPhase in
    ///             switch newPhase {
    ///             case .active:
    ///                 // Resume active work
    ///             case .inactive:
    ///                 // Pause animations
    ///             case .background:
    ///                 // Save state, reduce resource usage
    ///             }
    ///         }
    /// }
    /// ```
    public var scenePhase: ScenePhase {
        get { self[ScenePhaseKey.self] }
        set { self[ScenePhaseKey.self] = newValue }
    }
}
