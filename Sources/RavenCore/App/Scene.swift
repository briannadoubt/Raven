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

// MARK: - Scene Modifiers

internal protocol SceneModifier: Sendable {
    func apply<S: Scene>(to scene: S)
}

internal struct ModifiedScene<Base: Scene, Modifier: SceneModifier>: Scene {
    let base: Base
    let modifier: Modifier

    init(base: Base, modifier: Modifier) {
        self.base = base
        self.modifier = modifier
    }

    @MainActor var body: Base.Body {
        base.body
    }
}

extension ModifiedScene: _SceneContentExtractable where Base: _SceneContentExtractable {
    @MainActor func _extractRootView() -> AnyView {
        base._extractRootView()
    }
}

internal struct CommandsSceneModifier<C: Commands>: SceneModifier {
    let commands: C

    func apply<S: Scene>(to scene: S) {
        // Command routing/rendering is platform-dependent and currently a no-op.
    }
}

extension Scene {
    /// Installs scene-level command declarations.
    ///
    /// This mirrors SwiftUI's `.commands { ... }` surface in `App.body`.
    @MainActor public func commands<C: Commands>(@CommandsBuilder _ content: () -> C) -> some Scene {
        ModifiedScene(base: self, modifier: CommandsSceneModifier(commands: content()))
    }
}
