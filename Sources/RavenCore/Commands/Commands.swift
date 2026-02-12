import Foundation

/// A resolved keyboard shortcut/action pair extracted from `.commands { ... }`.
@MainActor
public struct CommandShortcutBinding: Sendable {
    public let key: KeyEquivalent
    public let modifiers: KeyboardModifiers
    public let action: @Sendable @MainActor () -> Void

    public init(
        key: KeyEquivalent,
        modifiers: KeyboardModifiers,
        action: @escaping @Sendable @MainActor () -> Void
    ) {
        self.key = key
        self.modifiers = modifiers
        self.action = action
    }
}

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

public struct CommandMenu<Content: Commands>: Commands {
    private let title: Text
    private let content: Content

    @MainActor public init(
        _ title: LocalizedStringResource,
        @CommandsBuilder content: @MainActor () -> Content
    ) {
        self.title = Text(title.stringValue)
        self.content = content()
    }

    @MainActor public init(
        _ titleKey: LocalizedStringKey,
        @CommandsBuilder content: @MainActor () -> Content
    ) {
        self.title = Text(titleKey)
        self.content = content()
    }

    @MainActor public init(
        _ title: Text,
        @CommandsBuilder content: @MainActor () -> Content
    ) {
        self.title = title
        self.content = content()
    }

    @MainActor public init<S: StringProtocol>(
        _ title: S,
        @CommandsBuilder content: @MainActor () -> Content
    ) {
        self.title = Text(String(title))
        self.content = content()
    }
}

// MARK: - CommandGroup

public struct CommandGroup<Content: Commands>: Commands {
    private let placement: CommandGroupPlacement
    private let operation: CommandGroupOperation
    private let content: Content

    private enum CommandGroupOperation: Sendable {
        case before
        case after
        case replacing
    }

    @MainActor public init(
        after placement: CommandGroupPlacement,
        @CommandsBuilder addition: @MainActor () -> Content
    ) {
        self.placement = placement
        self.operation = .after
        self.content = addition()
    }

    @MainActor public init(
        before placement: CommandGroupPlacement,
        @CommandsBuilder addition: @MainActor () -> Content
    ) {
        self.placement = placement
        self.operation = .before
        self.content = addition()
    }

    @MainActor public init(
        replacing placement: CommandGroupPlacement,
        @CommandsBuilder addition: @MainActor () -> Content
    ) {
        self.placement = placement
        self.operation = .replacing
        self.content = addition()
    }
}

// MARK: - Command-Compatible Primitives

extension Button: Commands {}

// MARK: - Command Keyboard Shortcut Extraction

@MainActor
public protocol _CommandShortcutExtractable {
    func _extractCommandShortcuts() -> [CommandShortcutBinding]
}

/// A command wrapper that annotates a command button with a keyboard shortcut.
public struct _CommandShortcutButton<Label: View>: Commands, _CommandShortcutExtractable {
    let button: Button<Label>
    let shortcut: KeyboardShortcut

    @MainActor
    init(button: Button<Label>, shortcut: KeyboardShortcut) {
        self.button = button
        self.shortcut = shortcut
    }

    @MainActor
    public func _extractCommandShortcuts() -> [CommandShortcutBinding] {
        [
            CommandShortcutBinding(
                key: shortcut.key,
                modifiers: shortcut.modifiers,
                action: button.actionClosure
            ),
        ]
    }
}

extension Button {
    /// Assigns a keyboard shortcut to a command button.
    ///
    /// This mirrors SwiftUI command usage where `Button` entries inside
    /// `.commands { ... }` can declare key equivalents.
    @MainActor
    public func keyboardShortcut(
        _ key: KeyEquivalent,
        modifiers: KeyboardModifiers = [.command]
    ) -> some Commands {
        _CommandShortcutButton(button: self, shortcut: KeyboardShortcut(key, modifiers: modifiers))
    }
}

extension CommandMenu: _CommandShortcutExtractable where Content: Commands {
    @MainActor public func _extractCommandShortcuts() -> [CommandShortcutBinding] {
        _resolveCommandShortcuts(from: content)
    }
}

extension CommandGroup: _CommandShortcutExtractable where Content: Commands {
    @MainActor public func _extractCommandShortcuts() -> [CommandShortcutBinding] {
        _resolveCommandShortcuts(from: content)
    }
}

extension OptionalCommands: _CommandShortcutExtractable where Content: Commands {
    @MainActor public func _extractCommandShortcuts() -> [CommandShortcutBinding] {
        guard let content else { return [] }
        return _resolveCommandShortcuts(from: content)
    }
}

extension ConditionalCommands: _CommandShortcutExtractable where TrueContent: Commands, FalseContent: Commands {
    @MainActor public func _extractCommandShortcuts() -> [CommandShortcutBinding] {
        if condition, let trueContent {
            return _resolveCommandShortcuts(from: trueContent)
        }
        if let falseContent {
            return _resolveCommandShortcuts(from: falseContent)
        }
        return []
    }
}

extension TupleCommands: _CommandShortcutExtractable {
    @MainActor public func _extractCommandShortcuts() -> [CommandShortcutBinding] {
        var bindings: [CommandShortcutBinding] = []
        let mirror = Mirror(reflecting: content)
        for child in mirror.children {
            guard let command = child.value as? any Commands else { continue }
            bindings.append(contentsOf: _resolveCommandShortcuts(from: command))
        }
        return bindings
    }
}

@MainActor
public func _resolveCommandShortcuts(from commands: any Commands) -> [CommandShortcutBinding] {
    if let extractable = commands as? any _CommandShortcutExtractable {
        return extractable._extractCommandShortcuts()
    }
    return []
}
