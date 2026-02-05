/// A result builder that constructs views from multi-statement closures.
///
/// `ViewBuilder` enables the declarative syntax used throughout Raven's view system.
/// It supports conditional statements, optional values, and collections of views,
/// making it possible to build complex view hierarchies with clean, readable code.
///
/// ## Overview
///
/// The `ViewBuilder` attribute transforms closures into a series of view-building
/// operations, allowing you to write declarative UI code without explicit return
/// statements or manual view composition.
///
/// ## Basic Usage
///
/// Use `@ViewBuilder` to create multi-statement view closures:
///
/// ```swift
/// @ViewBuilder
/// var content: some View {
///     Text("Hello")
///     Text("World")
///     Divider()
/// }
/// ```
///
/// ## Conditional Content
///
/// Build views conditionally using standard Swift control flow:
///
/// ```swift
/// @ViewBuilder
/// var greeting: some View {
///     if isLoggedIn {
///         Text("Welcome back!")
///     } else {
///         Text("Please log in")
///     }
/// }
/// ```
///
/// ## Optional Content
///
/// Use optional binding to conditionally show views:
///
/// ```swift
/// @ViewBuilder
/// var userInfo: some View {
///     Text("Profile")
///     if let username = user?.name {
///         Text(username)
///     }
/// }
/// ```
///
/// ## Switch Statements
///
/// Build different views based on enum cases:
///
/// ```swift
/// @ViewBuilder
/// func stateView(for state: LoadingState) -> some View {
///     switch state {
///     case .loading:
///         Text("Loading...")
///     case .loaded(let data):
///         Text("Data: \(data)")
///     case .error(let message):
///         Text("Error: \(message)")
///     }
/// }
/// ```
///
/// ## Custom View Initializers
///
/// Use `@ViewBuilder` in custom view initializers to accept view content:
///
/// ```swift
/// struct Card<Content: View>: View {
///     let content: Content
///
///     init(@ViewBuilder content: () -> Content) {
///         self.content = content()
///     }
///
///     var body: some View {
///         VStack {
///             content
///         }
///         .padding()
///         .background(Color.white)
///     }
/// }
///
/// // Usage:
/// Card {
///     Text("Title")
///     Text("Description")
/// }
/// ```
///
/// - Note: ViewBuilder supports up to 10 view components in a single closure.
///   For more complex layouts, use nested stacks or extract subviews.
///
/// ## See Also
///
/// - ``View``
/// - ``TupleView``
/// - ``ConditionalContent``
@resultBuilder
public struct ViewBuilder: Sendable {

    // MARK: - Build Block (Multiple Components)

    /// Builds a view from zero components.
    @MainActor public static func buildBlock() -> EmptyView {
        EmptyView()
    }

    /// Builds a view from a single component.
    @MainActor public static func buildBlock<Content: View>(_ content: Content) -> Content {
        content
    }

    /// Builds a view from two components.
    @MainActor public static func buildBlock<C0: View, C1: View>(
        _ c0: C0, _ c1: C1
    ) -> TupleView<C0, C1> {
        TupleView(c0, c1)
    }

    /// Builds a view from three components.
    @MainActor public static func buildBlock<C0: View, C1: View, C2: View>(
        _ c0: C0, _ c1: C1, _ c2: C2
    ) -> TupleView<C0, C1, C2> {
        TupleView(c0, c1, c2)
    }

    /// Builds a view from four components.
    @MainActor public static func buildBlock<C0: View, C1: View, C2: View, C3: View>(
        _ c0: C0, _ c1: C1, _ c2: C2, _ c3: C3
    ) -> TupleView<C0, C1, C2, C3> {
        TupleView(c0, c1, c2, c3)
    }

    /// Builds a view from five components.
    @MainActor public static func buildBlock<C0: View, C1: View, C2: View, C3: View, C4: View>(
        _ c0: C0, _ c1: C1, _ c2: C2, _ c3: C3, _ c4: C4
    ) -> TupleView<C0, C1, C2, C3, C4> {
        TupleView(c0, c1, c2, c3, c4)
    }

    /// Builds a view from six components.
    @MainActor public static func buildBlock<C0: View, C1: View, C2: View, C3: View, C4: View, C5: View>(
        _ c0: C0, _ c1: C1, _ c2: C2, _ c3: C3, _ c4: C4, _ c5: C5
    ) -> TupleView<C0, C1, C2, C3, C4, C5> {
        TupleView(c0, c1, c2, c3, c4, c5)
    }

    /// Builds a view from seven components.
    @MainActor public static func buildBlock<C0: View, C1: View, C2: View, C3: View, C4: View, C5: View, C6: View>(
        _ c0: C0, _ c1: C1, _ c2: C2, _ c3: C3, _ c4: C4, _ c5: C5, _ c6: C6
    ) -> TupleView<C0, C1, C2, C3, C4, C5, C6> {
        TupleView(c0, c1, c2, c3, c4, c5, c6)
    }

    /// Builds a view from eight components.
    @MainActor public static func buildBlock<C0: View, C1: View, C2: View, C3: View, C4: View, C5: View, C6: View, C7: View>(
        _ c0: C0, _ c1: C1, _ c2: C2, _ c3: C3, _ c4: C4, _ c5: C5, _ c6: C6, _ c7: C7
    ) -> TupleView<C0, C1, C2, C3, C4, C5, C6, C7> {
        TupleView(c0, c1, c2, c3, c4, c5, c6, c7)
    }

    /// Builds a view from nine components.
    @MainActor public static func buildBlock<C0: View, C1: View, C2: View, C3: View, C4: View, C5: View, C6: View, C7: View, C8: View>(
        _ c0: C0, _ c1: C1, _ c2: C2, _ c3: C3, _ c4: C4, _ c5: C5, _ c6: C6, _ c7: C7, _ c8: C8
    ) -> TupleView<C0, C1, C2, C3, C4, C5, C6, C7, C8> {
        TupleView(c0, c1, c2, c3, c4, c5, c6, c7, c8)
    }

    /// Builds a view from ten components.
    @MainActor public static func buildBlock<C0: View, C1: View, C2: View, C3: View, C4: View, C5: View, C6: View, C7: View, C8: View, C9: View>(
        _ c0: C0, _ c1: C1, _ c2: C2, _ c3: C3, _ c4: C4, _ c5: C5, _ c6: C6, _ c7: C7, _ c8: C8, _ c9: C9
    ) -> TupleView<C0, C1, C2, C3, C4, C5, C6, C7, C8, C9> {
        TupleView(c0, c1, c2, c3, c4, c5, c6, c7, c8, c9)
    }

    // MARK: - Conditional Content

    /// Builds a view for the first branch of an if-else statement.
    @MainActor public static func buildEither<TrueContent: View, FalseContent: View>(
        first component: TrueContent
    ) -> ConditionalContent<TrueContent, FalseContent> {
        ConditionalContent(trueContent: component)
    }

    /// Builds a view for the second branch of an if-else statement.
    @MainActor public static func buildEither<TrueContent: View, FalseContent: View>(
        second component: FalseContent
    ) -> ConditionalContent<TrueContent, FalseContent> {
        ConditionalContent(falseContent: component)
    }

    // MARK: - Optional Content

    /// Builds a view from an optional component.
    @MainActor public static func buildOptional<Content: View>(
        _ component: Content?
    ) -> OptionalContent<Content> {
        OptionalContent(content: component)
    }

    // MARK: - Array Content

    /// Builds a view from an array of components.
    @MainActor public static func buildArray<Content: View>(
        _ components: [Content]
    ) -> ForEachView<Content> {
        ForEachView(views: components)
    }

    // MARK: - Availability

    /// Provides support for limited availability checking.
    @MainActor public static func buildLimitedAvailability<Content: View>(
        _ component: Content
    ) -> Content {
        component
    }
}

// MARK: - Supporting View Types

/// A view that represents an empty, invisible view.
///
/// Use `EmptyView` when you need to provide a view but don't want to render
/// any content. This is useful in conditional logic or as a placeholder.
///
/// ## Example
///
/// ```swift
/// @ViewBuilder
/// var content: some View {
///     if showContent {
///         Text("Content")
///     } else {
///         EmptyView()
///     }
/// }
/// ```
///
/// - Note: `EmptyView` renders nothing to the DOM and takes up no space.
public struct EmptyView: View, Sendable {
    public typealias Body = Never

    @MainActor public init() {}
}

/// A view that contains a tuple of views.
///
/// `TupleView` is created automatically by `@ViewBuilder` when you provide
/// multiple views in a closure. You typically don't create `TupleView` instances
/// directly.
///
/// ## Example
///
/// ```swift
/// // ViewBuilder creates a TupleView internally:
/// @ViewBuilder
/// var content: some View {
///     Text("First")
///     Text("Second")
///     // This becomes TupleView<(Text, Text)>
/// }
/// ```
///
/// - Note: `TupleView` supports up to 10 child views. For more complex layouts,
///   use nested container views like `VStack` or `HStack`.

/// Protocol for views that contain tuple children
/// Allows runtime dispatch to parameter pack implementations
@MainActor
public protocol _ViewTuple: View {
    func _extractChildren() -> [any View]
}

/// A view that contains multiple child views in a tuple structure.
/// Uses parameter packs to support any number of child views
public struct TupleView<each Element: View>: View, Sendable, _ViewTuple {
    public typealias Body = Never

    public let content: (repeat each Element)

    @MainActor public init(_ content: repeat each Element) {
        self.content = (repeat each content)
    }

    /// Extract children using parameter pack iteration
    @MainActor
    public func _extractChildren() -> [any View] {
        var children: [any View] = []
        repeat (children.append(each content))
        return children
    }
}

/// A view that represents conditional content from if-else statements.
///
/// `ConditionalContent` is created automatically by `@ViewBuilder` when you use
/// if-else statements. It holds either the true branch or false branch view.
///
/// ## Example
///
/// ```swift
/// // ViewBuilder creates ConditionalContent internally:
/// @ViewBuilder
/// var greeting: some View {
///     if isLoggedIn {
///         Text("Welcome back!")
///     } else {
///         Text("Please log in")
///     }
///     // This becomes ConditionalContent<Text, Text>
/// }
/// ```
///
/// - Note: You typically don't create `ConditionalContent` instances directly.
///   Use if-else statements in `@ViewBuilder` closures instead.
public struct ConditionalContent<TrueContent: View, FalseContent: View>: View, Sendable {
    public typealias Body = Never

    enum Storage: Sendable {
        case trueContent(TrueContent)
        case falseContent(FalseContent)
    }

    let storage: Storage

    @MainActor init(trueContent: TrueContent) {
        self.storage = .trueContent(trueContent)
    }

    @MainActor init(falseContent: FalseContent) {
        self.storage = .falseContent(falseContent)
    }
}

/// A view that represents optional content.
public struct OptionalContent<Content: View>: View, Sendable {
    public typealias Body = Never

    let content: Content?

    @MainActor init(content: Content?) {
        self.content = content
    }
}

/// A view that represents an array of views.
public struct ForEachView<Content: View>: View, Sendable {
    public typealias Body = Never

    let views: [Content]

    @MainActor init(views: [Content]) {
        self.views = views
    }
}
