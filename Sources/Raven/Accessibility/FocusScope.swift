import Foundation

// MARK: - Focus Scope

/// A container that defines a focus scope boundary for managing focus within a view hierarchy.
///
/// Focus scopes provide hierarchical focus management, allowing views to control focus
/// behavior within their local context without affecting the global focus state. This is
/// particularly useful for modals, sheets, popovers, and other contained UI elements.
///
/// ## Overview
///
/// A focus scope establishes a boundary where focus can be trapped, managed, or delegated
/// independently from the parent scope. When a scope is active, focus navigation (like Tab)
/// cycles only through focusable elements within that scope.
///
/// ## Key Features
///
/// - **Focus Trapping**: Keep focus within a specific view hierarchy
/// - **Hierarchical Management**: Parent scopes can delegate to child scopes
/// - **Automatic Cleanup**: Scopes automatically clean up when views disappear
/// - **Priority Ordering**: Control which scope takes precedence for focus events
///
/// ## Example Usage
///
/// ```swift
/// struct ModalView: View {
///     @FocusState private var focusedField: Field?
///
///     var body: some View {
///         VStack {
///             TextField("Username", text: $username)
///                 .focused($focusedField, equals: .username)
///
///             SecureField("Password", text: $password)
///                 .focused($focusedField, equals: .password)
///
///             Button("OK") { }
///         }
///         .focusScope()  // Creates a focus scope for the modal
///     }
/// }
/// ```
@MainActor
public struct FocusScope: Sendable {
    /// Unique identifier for this scope
    public let id: UUID

    /// Parent scope ID, if this is a child scope
    public let parentID: UUID?

    /// Whether focus should be trapped within this scope
    public let trapFocus: Bool

    /// Priority level for scope precedence (higher = more priority)
    public let priority: Int

    /// List of focusable element IDs within this scope
    private var elementIDs: Set<UUID>

    /// Child scope IDs
    private var childScopeIDs: Set<UUID>

    /// Creates a focus scope.
    ///
    /// - Parameters:
    ///   - id: Unique identifier (generated if not provided)
    ///   - parentID: Parent scope ID for hierarchical management
    ///   - trapFocus: Whether to trap focus within this scope
    ///   - priority: Priority level for scope ordering
    public init(
        id: UUID = UUID(),
        parentID: UUID? = nil,
        trapFocus: Bool = false,
        priority: Int = 0
    ) {
        self.id = id
        self.parentID = parentID
        self.trapFocus = trapFocus
        self.priority = priority
        self.elementIDs = []
        self.childScopeIDs = []
    }

    /// Add a focusable element to this scope.
    ///
    /// - Parameter elementID: The unique identifier of the element
    public mutating func addElement(_ elementID: UUID) {
        elementIDs.insert(elementID)
    }

    /// Remove a focusable element from this scope.
    ///
    /// - Parameter elementID: The unique identifier of the element
    public mutating func removeElement(_ elementID: UUID) {
        elementIDs.remove(elementID)
    }

    /// Add a child scope to this scope.
    ///
    /// - Parameter scopeID: The unique identifier of the child scope
    public mutating func addChildScope(_ scopeID: UUID) {
        childScopeIDs.insert(scopeID)
    }

    /// Remove a child scope from this scope.
    ///
    /// - Parameter scopeID: The unique identifier of the child scope
    public mutating func removeChildScope(_ scopeID: UUID) {
        childScopeIDs.remove(scopeID)
    }

    /// Get all element IDs in this scope.
    public var elements: Set<UUID> {
        elementIDs
    }

    /// Get all child scope IDs.
    public var childScopes: Set<UUID> {
        childScopeIDs
    }

    /// Check if this scope contains a specific element.
    ///
    /// - Parameter elementID: The element ID to check
    /// - Returns: True if the element is in this scope
    public func contains(element elementID: UUID) -> Bool {
        elementIDs.contains(elementID)
    }

    /// Check if this scope contains a specific child scope.
    ///
    /// - Parameter scopeID: The scope ID to check
    /// - Returns: True if the scope is a child of this scope
    public func contains(childScope scopeID: UUID) -> Bool {
        childScopeIDs.contains(scopeID)
    }
}

// MARK: - Focus Scope Modifier

/// A view modifier that creates a focus scope for its content.
public struct FocusScopeModifier: ViewModifier {
    /// The scope configuration
    private let scopeID: UUID
    private let trapFocus: Bool
    private let priority: Int

    /// Creates a focus scope modifier.
    ///
    /// - Parameters:
    ///   - scopeID: Unique identifier for the scope
    ///   - trapFocus: Whether to trap focus within this scope
    ///   - priority: Priority level for scope ordering
    public init(scopeID: UUID = UUID(), trapFocus: Bool = false, priority: Int = 0) {
        self.scopeID = scopeID
        self.trapFocus = trapFocus
        self.priority = priority
    }

    public func body(content: Content) -> some View {
        content
            .onAppear {
                let scope = FocusScope(
                    id: scopeID,
                    trapFocus: trapFocus,
                    priority: priority
                )
                FocusManager.shared.registerScope(scopeID, scope: scope)
            }
            .onDisappear {
                FocusManager.shared.unregisterScope(scopeID)
            }
    }
}

// MARK: - View Extension

extension View {
    /// Creates a focus scope around this view.
    ///
    /// A focus scope provides hierarchical focus management, allowing focus to be
    /// controlled within a specific view hierarchy. This is useful for modals,
    /// sheets, and other contained UI elements.
    ///
    /// Example:
    /// ```swift
    /// Sheet {
    ///     FormView()
    ///         .focusScope(trapFocus: true)  // Keep focus within the sheet
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - trapFocus: Whether to trap focus within this scope. When true, Tab
    ///                navigation cycles only through elements in this scope.
    ///   - priority: Priority level for scope ordering. Higher priority scopes
    ///              take precedence for focus events.
    /// - Returns: A view with a focus scope applied.
    @MainActor
    public func focusScope(trapFocus: Bool = false, priority: Int = 0) -> some View {
        self.modifier(FocusScopeModifier(trapFocus: trapFocus, priority: priority))
    }
}

// MARK: - Focus Scope Environment

/// Environment key for the current focus scope ID.
private struct FocusScopeIDKey: EnvironmentKey {
    static let defaultValue: UUID? = nil
}

extension EnvironmentValues {
    /// The current focus scope ID.
    public var focusScopeID: UUID? {
        get { self[FocusScopeIDKey.self] }
        set { self[FocusScopeIDKey.self] = newValue }
    }
}

// MARK: - Focus Scope Context

/// Context information for managing focus within a scope.
@MainActor
public final class FocusScopeContext {
    /// The scope this context belongs to
    public let scopeID: UUID

    /// Elements within this scope
    private var elements: [UUID] = []

    /// The currently focused element within this scope
    private var focusedElement: UUID?

    /// Creates a focus scope context.
    ///
    /// - Parameter scopeID: The scope identifier
    public init(scopeID: UUID) {
        self.scopeID = scopeID
    }

    /// Add an element to this scope context.
    ///
    /// - Parameter elementID: The element identifier
    public func addElement(_ elementID: UUID) {
        if !elements.contains(elementID) {
            elements.append(elementID)
        }
    }

    /// Remove an element from this scope context.
    ///
    /// - Parameter elementID: The element identifier
    public func removeElement(_ elementID: UUID) {
        elements.removeAll { $0 == elementID }
        if focusedElement == elementID {
            focusedElement = nil
        }
    }

    /// Set the focused element within this scope.
    ///
    /// - Parameter elementID: The element identifier, or nil to clear focus
    public func setFocusedElement(_ elementID: UUID?) {
        focusedElement = elementID
    }

    /// Get the currently focused element in this scope.
    public var currentlyFocusedElement: UUID? {
        focusedElement
    }

    /// Get all elements in this scope.
    public var allElements: [UUID] {
        elements
    }

    /// Focus the next element in this scope.
    ///
    /// - Returns: The ID of the newly focused element, or nil if at the end
    public func focusNext() -> UUID? {
        guard !elements.isEmpty else { return nil }

        if let current = focusedElement,
           let currentIndex = elements.firstIndex(of: current) {
            let nextIndex = currentIndex + 1
            if nextIndex < elements.count {
                let next = elements[nextIndex]
                focusedElement = next
                return next
            }
        } else {
            // No current focus, focus the first element
            let first = elements[0]
            focusedElement = first
            return first
        }

        return nil
    }

    /// Focus the previous element in this scope.
    ///
    /// - Returns: The ID of the newly focused element, or nil if at the beginning
    public func focusPrevious() -> UUID? {
        guard !elements.isEmpty else { return nil }

        if let current = focusedElement,
           let currentIndex = elements.firstIndex(of: current) {
            if currentIndex > 0 {
                let previous = elements[currentIndex - 1]
                focusedElement = previous
                return previous
            }
        } else {
            // No current focus, focus the last element
            let last = elements[elements.count - 1]
            focusedElement = last
            return last
        }

        return nil
    }
}
