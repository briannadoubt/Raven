import Foundation

// Note: ViewModifier, View, State, FocusBinding, NodeID, FocusableElement, and FocusManager
// are all defined in the Raven module and don't need explicit imports since this file
// is part of the Raven module.

// MARK: - Focused Modifier

/// A view modifier that binds focus state to a view.
///
/// This modifier connects a @FocusState property to a specific view, allowing
/// programmatic control of focus and responding to focus changes.
internal struct FocusedModifier<Value: Sendable & Hashable>: ViewModifier {
    /// The focus binding
    let binding: FocusBinding<Value?>

    /// The value that indicates this view is focused
    let value: Value

    /// Unique identifier for this focused element
    let elementID: UUID = UUID()

    /// The node ID in the virtual DOM
    @State private var nodeID: NodeID?

    /// Explicit initializer to avoid actor isolation issues
    @MainActor
    init(binding: FocusBinding<Value?>, value: Value) {
        self.binding = binding
        self.value = value
    }

    func body(content: Content) -> some View {
        content
            .onAppear {
                registerFocusableElement()
            }
            .onDisappear {
                unregisterFocusableElement()
            }
    }

    /// Register this element with the focus manager
    @MainActor
    private func registerFocusableElement() {
        let element = FocusableElement(
            id: elementID,
            nodeID: nodeID,
            isFocusable: true,
            tabIndex: 0,
            onFocusChange: { hasFocus in
                if hasFocus {
                    binding.wrappedValue = value
                } else if binding.wrappedValue == value {
                    binding.wrappedValue = nil
                }
            },
            focusStateMatcher: { state in
                if let stateValue = state as? Value {
                    return stateValue == value
                }
                return false
            }
        )

        FocusManager.shared.registerFocusable(elementID, element: element)

        // Check if we should be focused initially
        if binding.wrappedValue == value {
            FocusManager.shared.setFocus(to: elementID)
        }
    }

    /// Unregister this element from the focus manager
    @MainActor
    private func unregisterFocusableElement() {
        FocusManager.shared.unregisterFocusable(elementID)
    }
}

/// A view modifier that binds boolean focus state to a view.
internal struct FocusedBoolModifier: ViewModifier {
    /// The focus binding
    let binding: FocusBinding<Bool>

    /// Unique identifier for this focused element
    let elementID: UUID = UUID()

    /// The node ID in the virtual DOM
    @State private var nodeID: NodeID?

    /// Explicit initializer to avoid actor isolation issues
    @MainActor
    init(binding: FocusBinding<Bool>) {
        self.binding = binding
    }

    func body(content: Content) -> some View {
        content
            .onAppear {
                registerFocusableElement()
            }
            .onDisappear {
                unregisterFocusableElement()
            }
    }

    /// Register this element with the focus manager
    @MainActor
    private func registerFocusableElement() {
        let element = FocusableElement(
            id: elementID,
            nodeID: nodeID,
            isFocusable: true,
            tabIndex: 0,
            onFocusChange: { hasFocus in
                binding.wrappedValue = hasFocus
            },
            focusStateMatcher: { state in
                if let boolValue = state as? Bool {
                    return boolValue == true
                }
                return false
            }
        )

        FocusManager.shared.registerFocusable(elementID, element: element)

        // Check if we should be focused initially
        if binding.wrappedValue {
            FocusManager.shared.setFocus(to: elementID)
        }
    }

    /// Unregister this element from the focus manager
    @MainActor
    private func unregisterFocusableElement() {
        FocusManager.shared.unregisterFocusable(elementID)
    }
}

// MARK: - Focusable Modifier

/// A view modifier that makes a view focusable.
///
/// This modifier adds focus capability to a view without binding to @FocusState.
/// It's useful for making custom views keyboard-accessible.
internal struct FocusableModifier: ViewModifier {
    /// Whether this view can receive focus
    let isFocusable: Bool

    /// Tab order index
    let tabIndex: Int

    /// Unique identifier for this focused element
    let elementID: UUID = UUID()

    /// The node ID in the virtual DOM
    @State private var nodeID: NodeID?

    /// Callback when focus changes
    let onFocusChange: (@Sendable @MainActor (Bool) -> Void)?

    /// Explicit initializer to avoid actor isolation issues
    @MainActor
    init(isFocusable: Bool = true, tabIndex: Int = 0, onFocusChange: (@Sendable @MainActor (Bool) -> Void)? = nil) {
        self.isFocusable = isFocusable
        self.tabIndex = tabIndex
        self.onFocusChange = onFocusChange
    }

    func body(content: Content) -> some View {
        content
            .onAppear {
                registerFocusableElement()
            }
            .onDisappear {
                unregisterFocusableElement()
            }
    }

    /// Register this element with the focus manager
    @MainActor
    private func registerFocusableElement() {
        let element = FocusableElement(
            id: elementID,
            nodeID: nodeID,
            isFocusable: isFocusable,
            tabIndex: tabIndex,
            onFocusChange: { hasFocus in
                onFocusChange?(hasFocus)
            }
        )

        FocusManager.shared.registerFocusable(elementID, element: element)
    }

    /// Unregister this element from the focus manager
    @MainActor
    private func unregisterFocusableElement() {
        FocusManager.shared.unregisterFocusable(elementID)
    }
}

// MARK: - View Extensions

extension View {
    /// Binds focus state to this view with a specific value.
    ///
    /// Use this modifier to create a two-way binding between focus state and a view.
    /// When the view receives focus, the binding is set to the specified value.
    /// When the binding is set to the value, the view receives focus.
    ///
    /// Example:
    /// ```swift
    /// enum Field: Hashable {
    ///     case username, password
    /// }
    ///
    /// @FocusState private var focusedField: Field?
    ///
    /// TextField("Username", text: $username)
    ///     .focused($focusedField, equals: .username)
    ///
    /// SecureField("Password", text: $password)
    ///     .focused($focusedField, equals: .password)
    /// ```
    ///
    /// - Parameters:
    ///   - binding: The focus state binding
    ///   - value: The value indicating this view is focused
    /// - Returns: A view with focus binding
    @MainActor
    public func focused<Value: Sendable & Hashable>(
        _ binding: FocusBinding<Value?>,
        equals value: Value
    ) -> some View {
        self.modifier(FocusedModifier(binding: binding, value: value))
    }

    /// Binds boolean focus state to this view.
    ///
    /// Use this modifier for simple focus tracking with a boolean value.
    /// When the view receives focus, the binding is set to true.
    /// When the binding is set to true, the view receives focus.
    ///
    /// Example:
    /// ```swift
    /// @FocusState private var isTextFieldFocused: Bool
    ///
    /// TextField("Name", text: $name)
    ///     .focused($isTextFieldFocused)
    ///     .onAppear {
    ///         isTextFieldFocused = true  // Focus the field on appear
    ///     }
    /// ```
    ///
    /// - Parameter binding: The focus state binding
    /// - Returns: A view with focus binding
    @MainActor
    public func focused(_ binding: FocusBinding<Bool>) -> some View {
        self.modifier(FocusedBoolModifier(binding: binding))
    }

    /// Makes this view focusable and able to receive keyboard input.
    ///
    /// Use this modifier to make custom views keyboard-accessible. The view will
    /// be included in the tab order and can receive focus via keyboard navigation.
    ///
    /// Example:
    /// ```swift
    /// CustomControl()
    ///     .focusable(true) { hasFocus in
    ///         if hasFocus {
    ///             // Handle focus gained
    ///         }
    ///     }
    /// ```
    ///
    /// - Parameters:
    ///   - isFocusable: Whether this view can receive focus
    ///   - onFocusChange: Optional callback when focus changes
    /// - Returns: A focusable view
    @MainActor
    public func focusable(
        _ isFocusable: Bool = true,
        onFocusChange: (@Sendable @MainActor (Bool) -> Void)? = nil
    ) -> some View {
        self.modifier(FocusableModifier(
            isFocusable: isFocusable,
            tabIndex: 0,
            onFocusChange: onFocusChange
        ))
    }

    /// Sets the tab order index for this view.
    ///
    /// Views with lower tab indices are focused before views with higher indices
    /// when navigating with the Tab key.
    ///
    /// Example:
    /// ```swift
    /// TextField("First", text: $first)
    ///     .tabIndex(0)
    ///
    /// TextField("Second", text: $second)
    ///     .tabIndex(1)
    /// ```
    ///
    /// - Parameter index: The tab order index (default is 0)
    /// - Returns: A view with the specified tab index
    @MainActor
    public func tabIndex(_ index: Int) -> some View {
        self.modifier(FocusableModifier(
            isFocusable: true,
            tabIndex: index,
            onFocusChange: nil
        ))
    }
}

// MARK: - Focus Environment

/// Environment key for tracking focus within a view hierarchy
private struct IsFocusedKey: EnvironmentKey {
    static let defaultValue: Bool = false
}

extension EnvironmentValues {
    /// Whether the current view has focus
    public var isFocused: Bool {
        get { self[IsFocusedKey.self] }
        set { self[IsFocusedKey.self] = newValue }
    }
}
