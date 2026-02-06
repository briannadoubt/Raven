import Foundation

/// A result builder that creates scenes from multi-statement closures.
///
/// Use `@SceneBuilder` to enable declarative scene composition in your app's body:
///
/// ```swift
/// struct MyApp: App {
///     var body: some Scene {
///         WindowGroup {
///             ContentView()
///         }
///
///         Settings {
///             SettingsView()
///         }
///     }
/// }
/// ```
@resultBuilder
public struct SceneBuilder: Sendable {
    /// Builds a scene from a single scene component.
    @MainActor public static func buildBlock<Content: Scene>(_ content: Content) -> Content {
        content
    }

    /// Builds a scene from two scene components.
    @MainActor public static func buildBlock<C0: Scene, C1: Scene>(_ c0: C0, _ c1: C1) -> some Scene {
        TupleScene((c0, c1))
    }

    /// Builds a scene from three scene components.
    @MainActor public static func buildBlock<C0: Scene, C1: Scene, C2: Scene>(_ c0: C0, _ c1: C1, _ c2: C2) -> some Scene {
        TupleScene((c0, c1, c2))
    }

    /// Builds a scene from four scene components.
    @MainActor public static func buildBlock<C0: Scene, C1: Scene, C2: Scene, C3: Scene>(_ c0: C0, _ c1: C1, _ c2: C2, _ c3: C3) -> some Scene {
        TupleScene((c0, c1, c2, c3))
    }

    /// Builds a scene from five scene components.
    @MainActor public static func buildBlock<C0: Scene, C1: Scene, C2: Scene, C3: Scene, C4: Scene>(_ c0: C0, _ c1: C1, _ c2: C2, _ c3: C3, _ c4: C4) -> some Scene {
        TupleScene((c0, c1, c2, c3, c4))
    }

    /// Provides support for optional scenes.
    @MainActor public static func buildOptional<Content: Scene>(_ content: Content?) -> some Scene {
        OptionalScene(content)
    }

    /// Provides support for if-else branches.
    @MainActor public static func buildEither<TrueContent: Scene, FalseContent: Scene>(first: TrueContent) -> ConditionalScene<TrueContent, FalseContent> {
        ConditionalScene(trueContent: first, condition: true)
    }

    /// Provides support for if-else branches.
    @MainActor public static func buildEither<TrueContent: Scene, FalseContent: Scene>(second: FalseContent) -> ConditionalScene<TrueContent, FalseContent> {
        ConditionalScene(falseContent: second, condition: false)
    }
}

// MARK: - TupleScene

/// A scene that contains multiple scenes.
public struct TupleScene<Content: Sendable>: Scene {
    public typealias Body = _EmptyScene

    let content: Content

    init(_ content: Content) {
        self.content = content
    }
}

// MARK: - OptionalScene

/// A scene that may or may not be present.
public struct OptionalScene<Content: Scene>: Scene {
    public typealias Body = _EmptyScene

    let content: Content?

    init(_ content: Content?) {
        self.content = content
    }
}

// MARK: - ConditionalScene

/// A scene that represents a conditional branch.
public struct ConditionalScene<TrueContent: Scene, FalseContent: Scene>: Scene {
    public typealias Body = _EmptyScene

    let trueContent: TrueContent?
    let falseContent: FalseContent?
    let condition: Bool

    init(trueContent: TrueContent, condition: Bool) {
        self.trueContent = trueContent
        self.falseContent = nil
        self.condition = condition
    }

    init(falseContent: FalseContent, condition: Bool) {
        self.trueContent = nil
        self.falseContent = falseContent
        self.condition = condition
    }
}
