import Foundation

// MARK: - Commands Builder

/// A result builder that creates command groups from multi-statement closures.
@resultBuilder
public struct CommandsBuilder: Sendable {
    @MainActor public static func buildBlock<Content: Commands>(_ content: Content) -> Content {
        content
    }

    @MainActor public static func buildBlock<C0: Commands, C1: Commands>(_ c0: C0, _ c1: C1) -> some Commands {
        TupleCommands((c0, c1))
    }

    @MainActor public static func buildBlock<C0: Commands, C1: Commands, C2: Commands>(_ c0: C0, _ c1: C1, _ c2: C2) -> some Commands {
        TupleCommands((c0, c1, c2))
    }

    @MainActor public static func buildBlock<C0: Commands, C1: Commands, C2: Commands, C3: Commands>(_ c0: C0, _ c1: C1, _ c2: C2, _ c3: C3) -> some Commands {
        TupleCommands((c0, c1, c2, c3))
    }

    @MainActor public static func buildBlock<C0: Commands, C1: Commands, C2: Commands, C3: Commands, C4: Commands>(_ c0: C0, _ c1: C1, _ c2: C2, _ c3: C3, _ c4: C4) -> some Commands {
        TupleCommands((c0, c1, c2, c3, c4))
    }

    @MainActor public static func buildOptional<Content: Commands>(_ content: Content?) -> some Commands {
        OptionalCommands(content)
    }

    @MainActor public static func buildEither<TrueContent: Commands, FalseContent: Commands>(first: TrueContent) -> ConditionalCommands<TrueContent, FalseContent> {
        ConditionalCommands(trueContent: first, condition: true)
    }

    @MainActor public static func buildEither<TrueContent: Commands, FalseContent: Commands>(second: FalseContent) -> ConditionalCommands<TrueContent, FalseContent> {
        ConditionalCommands(falseContent: second, condition: false)
    }
}

// MARK: - Commands Protocol

/// A marker protocol for command groups used by ``CommandsBuilder``.
@MainActor public protocol Commands: Sendable {}

// MARK: - Empty Commands

public struct EmptyCommands: Commands, Sendable {
    @MainActor public init() {}
}

public struct _EmptyCommands: Commands, Sendable {
    @MainActor public init() {}
}

// MARK: - Tuple/Optional/Conditional

public struct TupleCommands<Content: Sendable>: Commands {
    let content: Content

    init(_ content: Content) {
        self.content = content
    }
}

public struct OptionalCommands<Content: Commands>: Commands {
    let content: Content?

    init(_ content: Content?) {
        self.content = content
    }
}

public struct ConditionalCommands<TrueContent: Commands, FalseContent: Commands>: Commands {
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

// MARK: - Command Group Placement

public enum CommandGroupPlacement: Sendable, Hashable {
    case appInfo
    case appSettings
    case appTermination
    case appVisibility
    case help
    case importExport
    case newItem
    case pasteboard
    case printItem
    case saveItem
    case sidebar
    case systemServices
    case textEditing
    case textFormatting
    case toolbar
    case undoRedo
    case windowArrangement
    case windowSize

    public var displayName: String {
        switch self {
        case .appInfo: return "App Info"
        case .appSettings: return "App Settings"
        case .appTermination: return "App Termination"
        case .appVisibility: return "App Visibility"
        case .help: return "Help"
        case .importExport: return "Import/Export"
        case .newItem: return "New Item"
        case .pasteboard: return "Pasteboard"
        case .printItem: return "Print"
        case .saveItem: return "Save"
        case .sidebar: return "Sidebar"
        case .systemServices: return "System Services"
        case .textEditing: return "Text Editing"
        case .textFormatting: return "Text Formatting"
        case .toolbar: return "Toolbar"
        case .undoRedo: return "Undo/Redo"
        case .windowArrangement: return "Window Arrangement"
        case .windowSize: return "Window Size"
        }
    }

}

// MARK: - CommandMenu

public struct CommandMenu<Content: View>: View, Commands, Sendable {

    private let label: Text
    private let content: Content

    @MainActor public init(
        _ title: LocalizedStringResource,
        @ViewBuilder content: () -> Content
    ) {
        self.label = Text(title.stringValue)
        self.content = content()
    }

    @MainActor public init(
        _ titleKey: LocalizedStringKey,
        @ViewBuilder content: () -> Content
    ) {
        self.label = Text(titleKey)
        self.content = content()
    }

    @MainActor public init(
        _ title: Text,
        @ViewBuilder content: () -> Content
    ) {
        self.label = title
        self.content = content()
    }

    @MainActor public init<S: StringProtocol>(
        _ title: S,
        @ViewBuilder content: () -> Content
    ) {
        self.label = Text(String(title))
        self.content = content()
    }

    @MainActor public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            label
                .font(.headline)
                .foregroundColor(Color.label)

            content
        }
        .padding(10)
        .background(Color.systemBackground)
        .cornerRadius(10)
    }
}

// MARK: - CommandGroup

public struct CommandGroup<Content: View>: View, Commands, Sendable {

    private enum Operation: String, Sendable {
        case before = "Before"
        case after = "After"
        case replacing = "Replacing"
    }

    private let placement: CommandGroupPlacement
    private let operation: Operation
    private let content: Content

    @MainActor public init(
        after placement: CommandGroupPlacement,
        @ViewBuilder addition: () -> Content
    ) {
        self.placement = placement
        self.operation = .after
        self.content = addition()
    }

    @MainActor public init(
        before placement: CommandGroupPlacement,
        @ViewBuilder addition: () -> Content
    ) {
        self.placement = placement
        self.operation = .before
        self.content = addition()
    }

    @MainActor public init(
        replacing placement: CommandGroupPlacement,
        @ViewBuilder addition: () -> Content
    ) {
        self.placement = placement
        self.operation = .replacing
        self.content = addition()
    }

    @MainActor public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("\(operation.rawValue) \(placement.displayName)")
                .font(.caption)
                .foregroundColor(Color.secondaryLabel)

            content
        }
        .padding(8)
        .background(Color.secondarySystemBackground)
        .cornerRadius(8)
    }
}
