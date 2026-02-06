import Foundation

/// A part of an app's user interface with a lifecycle managed by the system.
///
/// You create an `App` by combining one or more instances that conform to the `Scene` protocol
/// in the app's body. You can use the built-in scenes that Raven provides, like `WindowGroup`,
/// or you can compose custom scenes that conform to the `Scene` protocol.
///
/// Example:
/// ```swift
/// struct MyApp: App {
///     var body: some Scene {
///         WindowGroup {
///             ContentView()
///         }
///     }
/// }
/// ```
@MainActor public protocol Scene: Sendable {
    /// The type of scene representing the body of this scene.
    associatedtype Body: Scene

    /// The content and behavior of this scene.
    @SceneBuilder @MainActor var body: Self.Body { get }
}

// MARK: - EmptyScene Type

/// Empty scene marker type used for primitive scenes.
public struct _EmptyScene: Scene, Sendable {
    public typealias Body = _EmptyScene

    @MainActor public var body: _EmptyScene { self }

    public init() {}
}

// MARK: - Default Implementations

extension Scene where Body == _EmptyScene {
    /// Default implementation for primitive scenes.
    @MainActor public var body: _EmptyScene {
        _EmptyScene()
    }
}
