import Foundation
import JavaScriptKit

// MARK: - Keyboard Shortcut

/// Represents a keyboard shortcut with a key and optional modifiers.
///
/// Keyboard shortcuts provide a way to define and handle key combinations
/// for quick access to functionality. They can include modifier keys like
/// Command, Shift, Option, and Control.
///
/// ## Example
///
/// ```swift
/// let saveShortcut = KeyboardShortcut(.s, modifiers: .command)
/// let deleteShortcut = KeyboardShortcut(.delete)
/// let selectAllShortcut = KeyboardShortcut(.a, modifiers: [.command])
/// ```
public struct KeyboardShortcut: Hashable, Sendable {
    /// The key for this shortcut
    public let key: KeyEquivalent

    /// Modifier keys (command, shift, option, control)
    public let modifiers: KeyboardModifiers

    /// Creates a keyboard shortcut.
    ///
    /// - Parameters:
    ///   - key: The key equivalent
    ///   - modifiers: Modifier keys to combine with the key
    public init(_ key: KeyEquivalent, modifiers: KeyboardModifiers = []) {
        self.key = key
        self.modifiers = modifiers
    }
}

// MARK: - Key Equivalent

/// Represents a key on the keyboard.
///
/// Key equivalents represent physical keys and are used to define keyboard
/// shortcuts and handle key press events.
public struct KeyEquivalent: Hashable, Sendable, ExpressibleByStringLiteral {
    /// The string representation of the key
    public let character: String

    /// Creates a key equivalent from a string.
    ///
    /// - Parameter character: The character or key name
    public init(_ character: String) {
        self.character = character
    }

    /// Creates a key equivalent from a string literal.
    public init(stringLiteral value: String) {
        self.character = value
    }

    /// Check if this key equivalent matches a keyboard event.
    ///
    /// - Parameter event: The keyboard event from the DOM
    /// - Returns: True if the key matches
    internal func matches(event: JSObject) -> Bool {
        guard let eventKey = event.key.string else { return false }

        // Normalize the comparison
        let normalizedKey = character.lowercased()
        let normalizedEventKey = eventKey.lowercased()

        return normalizedKey == normalizedEventKey
    }
}

// MARK: - Common Key Equivalents

extension KeyEquivalent {
    // Letters
    public static let a = KeyEquivalent("a")
    public static let b = KeyEquivalent("b")
    public static let c = KeyEquivalent("c")
    public static let d = KeyEquivalent("d")
    public static let e = KeyEquivalent("e")
    public static let f = KeyEquivalent("f")
    public static let g = KeyEquivalent("g")
    public static let h = KeyEquivalent("h")
    public static let i = KeyEquivalent("i")
    public static let j = KeyEquivalent("j")
    public static let k = KeyEquivalent("k")
    public static let l = KeyEquivalent("l")
    public static let m = KeyEquivalent("m")
    public static let n = KeyEquivalent("n")
    public static let o = KeyEquivalent("o")
    public static let p = KeyEquivalent("p")
    public static let q = KeyEquivalent("q")
    public static let r = KeyEquivalent("r")
    public static let s = KeyEquivalent("s")
    public static let t = KeyEquivalent("t")
    public static let u = KeyEquivalent("u")
    public static let v = KeyEquivalent("v")
    public static let w = KeyEquivalent("w")
    public static let x = KeyEquivalent("x")
    public static let y = KeyEquivalent("y")
    public static let z = KeyEquivalent("z")

    // Special Keys
    public static let space = KeyEquivalent(" ")
    public static let delete = KeyEquivalent("Backspace")
    public static let deleteForward = KeyEquivalent("Delete")
    public static let escape = KeyEquivalent("Escape")
    public static let `return` = KeyEquivalent("Enter")
    public static let tab = KeyEquivalent("Tab")

    // Arrow Keys
    public static let upArrow = KeyEquivalent("ArrowUp")
    public static let downArrow = KeyEquivalent("ArrowDown")
    public static let leftArrow = KeyEquivalent("ArrowLeft")
    public static let rightArrow = KeyEquivalent("ArrowRight")

    // Function Keys
    public static let f1 = KeyEquivalent("F1")
    public static let f2 = KeyEquivalent("F2")
    public static let f3 = KeyEquivalent("F3")
    public static let f4 = KeyEquivalent("F4")
    public static let f5 = KeyEquivalent("F5")
    public static let f6 = KeyEquivalent("F6")
    public static let f7 = KeyEquivalent("F7")
    public static let f8 = KeyEquivalent("F8")
    public static let f9 = KeyEquivalent("F9")
    public static let f10 = KeyEquivalent("F10")
    public static let f11 = KeyEquivalent("F11")
    public static let f12 = KeyEquivalent("F12")

    // Numbers
    public static let zero = KeyEquivalent("0")
    public static let one = KeyEquivalent("1")
    public static let two = KeyEquivalent("2")
    public static let three = KeyEquivalent("3")
    public static let four = KeyEquivalent("4")
    public static let five = KeyEquivalent("5")
    public static let six = KeyEquivalent("6")
    public static let seven = KeyEquivalent("7")
    public static let eight = KeyEquivalent("8")
    public static let nine = KeyEquivalent("9")
}

// MARK: - Event Modifiers

/// Modifier keys that can be combined with key equivalents.
///
/// Event modifiers represent the state of modifier keys (Command, Shift, Option, Control)
/// during a keyboard event.
public struct KeyboardModifiers: OptionSet, Hashable, Sendable {
    public let rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    /// The Command key (⌘) on macOS, Ctrl on other platforms
    public static let command = KeyboardModifiers(rawValue: 1 << 0)

    /// The Shift key (⇧)
    public static let shift = KeyboardModifiers(rawValue: 1 << 1)

    /// The Option key (⌥) on macOS, Alt on other platforms
    public static let option = KeyboardModifiers(rawValue: 1 << 2)

    /// The Control key (⌃)
    public static let control = KeyboardModifiers(rawValue: 1 << 3)

    /// Check if these modifiers match a keyboard event.
    ///
    /// - Parameter event: The keyboard event from the DOM
    /// - Returns: True if all modifiers match
    internal func matches(event: JSObject) -> Bool {
        let hasCommand = event.metaKey.boolean ?? false
        let hasShift = event.shiftKey.boolean ?? false
        let hasOption = event.altKey.boolean ?? false
        let hasControl = event.ctrlKey.boolean ?? false

        let wantsCommand = contains(.command)
        let wantsShift = contains(.shift)
        let wantsOption = contains(.option)
        let wantsControl = contains(.control)

        return hasCommand == wantsCommand &&
               hasShift == wantsShift &&
               hasOption == wantsOption &&
               hasControl == wantsControl
    }
}

// MARK: - Key Press Action

/// The result of handling a key press.
public enum KeyPressResult: Sendable {
    /// The key press was handled
    case handled

    /// The key press was not handled, continue propagation
    case ignored
}

// MARK: - Key Press Handler

/// A handler for key press events.
internal struct KeyPressHandler: Sendable {
    /// Unique identifier
    let id: UUID

    /// The key equivalent to match
    let key: KeyEquivalent

    /// Modifiers that must be present
    let modifiers: KeyboardModifiers

    /// The action to perform
    let action: @Sendable @MainActor (KeyPress) -> KeyPressResult

    /// Check if this handler matches a keyboard event.
    ///
    /// - Parameter event: The DOM keyboard event
    /// - Returns: True if the key and modifiers match
    func matches(event: JSObject) -> Bool {
        return key.matches(event: event) && modifiers.matches(event: event)
    }
}

// MARK: - Key Press

/// Information about a key press event.
public struct KeyPress: @unchecked Sendable {
    /// The key that was pressed
    public let key: KeyEquivalent

    /// Modifier keys that were held
    public let modifiers: KeyboardModifiers

    /// The original DOM event (for advanced use cases)
    /// Note: JSObject is not Sendable, so we use @unchecked Sendable and ensure
    /// it's only accessed on the main actor
    internal let domEvent: JSObject?

    // KeyPress is @unchecked Sendable because domEvent (JSObject) is not Sendable
    // but we ensure it's only used on the main actor through proper isolation

    /// Creates a key press from a DOM event.
    internal init(from event: JSObject) {
        self.key = KeyEquivalent(event.key.string ?? "")
        var mods = KeyboardModifiers()
        if event.metaKey.boolean == true { mods.insert(.command) }
        if event.shiftKey.boolean == true { mods.insert(.shift) }
        if event.altKey.boolean == true { mods.insert(.option) }
        if event.ctrlKey.boolean == true { mods.insert(.control) }
        self.modifiers = mods
        self.domEvent = event
    }

    /// Creates a key press programmatically.
    public init(key: KeyEquivalent, modifiers: KeyboardModifiers = []) {
        self.key = key
        self.modifiers = modifiers
        self.domEvent = nil
    }
}

// MARK: - On Key Press Modifier

/// A view modifier that handles key press events.
internal struct OnKeyPressModifier: ViewModifier {
    /// The key to handle
    let key: KeyEquivalent

    /// Required modifiers
    let modifiers: KeyboardModifiers

    /// The action to perform
    let action: @Sendable @MainActor (KeyPress) -> KeyPressResult

    func body(content: Content) -> some View {
        content
            .onAppear {
                // Register the key press handler
                let handler = KeyPressHandler(
                    id: UUID(),
                    key: key,
                    modifiers: modifiers,
                    action: action
                )
                KeyboardShortcutManager.shared.registerHandler(handler)
            }
    }
}

// MARK: - View Extensions

extension View {
    /// Adds a key press handler to this view.
    ///
    /// The handler is called when the specified key is pressed while this view
    /// (or a descendant) has focus.
    ///
    /// Example:
    /// ```swift
    /// TextField("Search", text: $query)
    ///     .onKeyPress(.escape) { _ in
    ///         query = ""
    ///         return .handled
    ///     }
    /// ```
    ///
    /// - Parameters:
    ///   - key: The key to handle
    ///   - action: The action to perform when the key is pressed
    /// - Returns: A view that handles the key press
    @MainActor
    public func onKeyPress(
        _ key: KeyEquivalent,
        action: @escaping @Sendable @MainActor (KeyPress) -> KeyPressResult
    ) -> some View {
        self.modifier(OnKeyPressModifier(key: key, modifiers: [], action: action))
    }

    /// Adds a keyboard shortcut handler to this view.
    ///
    /// The handler is called when the specified key combination is pressed.
    ///
    /// Example:
    /// ```swift
    /// Button("Save") { save() }
    ///     .keyboardShortcut(.s, modifiers: .command)
    /// ```
    ///
    /// - Parameters:
    ///   - key: The key equivalent
    ///   - modifiers: The modifier keys
    ///   - action: The action to perform
    /// - Returns: A view that handles the keyboard shortcut
    @MainActor
    public func keyboardShortcut(
        _ key: KeyEquivalent,
        modifiers: KeyboardModifiers = [],
        action: @escaping @Sendable @MainActor () -> Void
    ) -> some View {
        self.modifier(OnKeyPressModifier(
            key: key,
            modifiers: modifiers,
            action: { _ in
                action()
                return .handled
            }
        ))
    }
}

// MARK: - Keyboard Shortcut Manager

/// Global manager for keyboard shortcuts and key press handlers.
@MainActor
internal final class KeyboardShortcutManager {
    /// Shared singleton instance
    static let shared = KeyboardShortcutManager()

    /// Registered key press handlers
    private var handlers: [UUID: KeyPressHandler] = [:]

    /// JavaScript closure for handling keydown events
    private var keydownClosure: JSClosure?

    private init() {
        setupGlobalKeyHandler()
    }

    /// Register a key press handler.
    func registerHandler(_ handler: KeyPressHandler) {
        handlers[handler.id] = handler
    }

    /// Unregister a key press handler.
    func unregisterHandler(_ id: UUID) {
        handlers.removeValue(forKey: id)
    }

    /// Setup global keyboard event handler.
    private func setupGlobalKeyHandler() {
        let closure = JSClosure { [weak self] args -> JSValue in
            guard let self = self,
                  args.count > 0,
                  let event = args[0].object else {
                return .undefined
            }

            Task { @MainActor in
                self.handleKeyEvent(event)
            }

            return .undefined
        }

        self.keydownClosure = closure

        // Register global keydown listener
        _ = JSObject.global.document.addEventListener("keydown", closure)
    }

    /// Handle a keyboard event.
    private func handleKeyEvent(_ event: JSObject) {
        let keyPress = KeyPress(from: event)

        // Find matching handlers
        for handler in handlers.values {
            if handler.matches(event: event) {
                let result = handler.action(keyPress)

                if result == .handled {
                    // Prevent default browser behavior
                    _ = event.preventDefault!()
                    _ = event.stopPropagation!()
                    break
                }
            }
        }
    }
}
