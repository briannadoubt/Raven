import Foundation

// MARK: - PresentationCoordinatorKey

/// Environment key for accessing the presentation coordinator.
///
/// This key provides access to the `PresentationCoordinator` through the environment,
/// allowing views to present sheets, alerts, and other modal content.
///
/// ## Usage
///
/// Access the coordinator through the environment:
///
/// ```swift
/// struct MyView: View {
///     @Environment(\.presentationCoordinator) var coordinator
///
///     var body: some View {
///         Button("Present Sheet") {
///             coordinator.present(type: .sheet, content: AnyView(SheetContent()))
///         }
///     }
/// }
/// ```
///
/// The default value is a shared instance of `PresentationCoordinator`, ensuring
/// that all views have access to presentation capabilities even if not explicitly
/// set in the environment.
public struct PresentationCoordinatorKey: EnvironmentKey {
    /// The default value for the presentation coordinator environment key.
    ///
    /// This is implemented using `MainActor.assumeIsolated` to safely bridge from
    /// the nonisolated EnvironmentKey requirement to the MainActor-isolated coordinator.
    /// This is safe because the environment system only accesses these values from
    /// view contexts, which are always on the main thread.
    public static var defaultValue: PresentationCoordinator {
        MainActor.assumeIsolated {
            _shared
        }
    }

    /// The shared coordinator instance, isolated to the main actor.
    @MainActor private static let _shared = PresentationCoordinator()
}

// MARK: - EnvironmentValues Extension

extension EnvironmentValues {
    /// The presentation coordinator for managing modal presentations.
    ///
    /// Use this environment value to access the presentation coordinator and
    /// present sheets, alerts, popovers, and other modal content.
    ///
    /// ## Setting a Custom Coordinator
    ///
    /// Inject a custom coordinator at the root of your view hierarchy:
    ///
    /// ```swift
    /// @main
    /// struct MyApp: App {
    ///     @StateObject private var coordinator = PresentationCoordinator()
    ///
    ///     var body: some Scene {
    ///         WindowGroup {
    ///             ContentView()
    ///                 .environment(\.presentationCoordinator, coordinator)
    ///         }
    ///     }
    /// }
    /// ```
    ///
    /// ## Accessing the Coordinator
    ///
    /// Access the coordinator from any view:
    ///
    /// ```swift
    /// struct ContentView: View {
    ///     @Environment(\.presentationCoordinator) var coordinator
    ///
    ///     var body: some View {
    ///         Button("Show Alert") {
    ///             coordinator.present(
    ///                 type: .alert,
    ///                 content: AnyView(AlertView())
    ///             )
    ///         }
    ///     }
    /// }
    /// ```
    ///
    /// - Note: The coordinator is MainActor-bound, ensuring all presentation
    ///   operations occur on the main thread.
    public var presentationCoordinator: PresentationCoordinator {
        get { self[PresentationCoordinatorKey.self] }
        set { self[PresentationCoordinatorKey.self] = newValue }
    }
}
