import Foundation

// MARK: - GestureState Property Wrapper

/// A property wrapper that manages gesture-driven state with automatic reset.
///
/// Use `@GestureState` to track temporary state during a gesture. Unlike `@State`, a
/// gesture state property automatically resets to its initial value when the gesture
/// ends. This makes it perfect for tracking gesture progress without manual cleanup.
///
/// ## Overview
///
/// `@GestureState` is designed specifically for gesture recognition. It maintains a
/// value while a gesture is active and automatically resets when the gesture completes,
/// is cancelled, or fails. This pattern eliminates the need for manual state management
/// in gesture handlers.
///
/// ## Basic Usage
///
/// Track drag offset during a gesture:
///
/// ```swift
/// struct DraggableView: View {
///     @GestureState private var dragOffset = CGSize.zero
///
///     var body: some View {
///         Circle()
///             .offset(dragOffset)
///             .gesture(
///                 DragGesture()
///                     .updating($dragOffset) { value, state, transaction in
///                         state = value.translation
///                     }
///             )
///     }
/// }
/// ```
///
/// When the drag ends, `dragOffset` automatically resets to `.zero`.
///
/// ## Custom Reset Behavior
///
/// Provide a custom reset function to perform cleanup when the gesture ends:
///
/// ```swift
/// @GestureState(
///     reset: { value, transaction in
///         print("Gesture ended with value: \(value)")
///         // Optionally modify the transaction
///         transaction.animation = .spring()
///     },
///     initialValue: CGSize.zero
/// ) private var dragOffset
/// ```
///
/// ## How It Works
///
/// 1. **Initialization**: The property starts at its initial value
/// 2. **Updating**: Use `.updating(_:body:)` on a gesture to update the state
/// 3. **Reset**: When the gesture ends, the value resets to the initial value
///
/// The reset happens automatically - you never set `@GestureState` directly.
///
/// ## Updating Pattern
///
/// Always use the `.updating(_:body:)` modifier to update gesture state:
///
/// ```swift
/// DragGesture()
///     .updating($dragOffset) { currentValue, state, transaction in
///         // currentValue: The current gesture value
///         // state: An inout parameter to update the gesture state
///         // transaction: The current transaction (can be modified)
///         state = currentValue.translation
///     }
/// ```
///
/// ## Multiple Gesture States
///
/// Combine multiple gesture states to track different aspects of a gesture:
///
/// ```swift
/// struct ContentView: View {
///     @GestureState private var dragOffset = CGSize.zero
///     @GestureState private var isDragging = false
///
///     var body: some View {
///         Rectangle()
///             .offset(dragOffset)
///             .opacity(isDragging ? 0.5 : 1.0)
///             .gesture(
///                 DragGesture()
///                     .updating($dragOffset) { value, state, _ in
///                         state = value.translation
///                     }
///                     .updating($isDragging) { _, state, _ in
///                         state = true
///                     }
///             )
///     }
/// }
/// ```
///
/// ## Animations
///
/// Modify the transaction in the update closure to animate state changes:
///
/// ```swift
/// @GestureState private var scale: CGFloat = 1.0
///
/// MagnificationGesture()
///     .updating($scale) { value, state, transaction in
///         transaction.animation = .spring()
///         state = value
///     }
/// ```
///
/// ## Persistent State
///
/// For state that should persist after a gesture ends, use `@State` instead:
///
/// ```swift
/// @State private var totalOffset = CGSize.zero  // Persists
/// @GestureState private var dragOffset = CGSize.zero  // Resets
///
/// var body: some View {
///     Rectangle()
///         .offset(x: totalOffset.width + dragOffset.width,
///                y: totalOffset.height + dragOffset.height)
///         .gesture(
///             DragGesture()
///                 .updating($dragOffset) { value, state, _ in
///                     state = value.translation
///                 }
///                 .onEnded { value in
///                     totalOffset.width += value.translation.width
///                     totalOffset.height += value.translation.height
///                 }
///         )
/// }
/// ```
///
/// ## Thread Safety
///
/// `@GestureState` is `@MainActor` isolated and thread-safe. All gesture state updates
/// occur on the main thread, ensuring safe access to UI state.
///
/// ## Web Implementation
///
/// In Raven's web environment, gesture state is managed through JavaScript event handlers.
/// When a gesture ends (mouseup, touchend, pointerup), the gesture state automatically
/// resets to its initial value.
///
/// ## See Also
///
/// - ``Gesture/updating(_:body:)``
/// - ``State``
/// - ``Transaction``
@MainActor
@propertyWrapper
public struct GestureState<Value: Sendable>: DynamicProperty {
    /// The underlying storage for the gesture state value.
    private let storage: GestureStateStorage<Value>

    /// The current value of the gesture state.
    ///
    /// Reading this property returns the current gesture state value. You should never
    /// set this property directly - instead, use the `.updating(_:body:)` gesture modifier.
    ///
    /// When a gesture is not active, this returns the initial value. During a gesture,
    /// it returns the value set by the `.updating(_:body:)` closure.
    public var wrappedValue: Value {
        get { storage.currentValue }
        nonmutating set {
            // This setter exists to satisfy the property wrapper protocol,
            // but should not be used directly. The gesture system uses internal
            // methods to update the value.
            storage.setValue(newValue)
        }
    }

    /// A binding-like wrapper that provides access to the gesture state.
    ///
    /// Use the projected value (accessed with `$`) to connect a gesture state to a
    /// gesture's `.updating(_:body:)` modifier:
    ///
    /// ```swift
    /// @GestureState private var offset = CGSize.zero
    ///
    /// var body: some View {
    ///     DragGesture()
    ///         .updating($offset) { value, state, transaction in
    ///             state = value.translation
    ///         }
    /// }
    /// ```
    public var projectedValue: GestureState<Value> {
        self
    }

    /// Creates a gesture state with an initial value.
    ///
    /// The gesture state will reset to this initial value whenever the gesture ends,
    /// is cancelled, or fails.
    ///
    /// Example:
    /// ```swift
    /// @GestureState private var dragOffset = CGSize.zero
    /// ```
    ///
    /// - Parameter wrappedValue: The initial value of the gesture state.
    public init(wrappedValue: Value) {
        self.storage = GestureStateStorage(
            initialValue: wrappedValue,
            reset: nil
        )
    }

    /// Creates a gesture state with an initial value.
    ///
    /// This initializer is equivalent to `init(wrappedValue:)` but uses a different
    /// parameter name for clarity in some contexts.
    ///
    /// - Parameter initialValue: The initial value of the gesture state.
    public init(initialValue: Value) {
        self.storage = GestureStateStorage(
            initialValue: initialValue,
            reset: nil
        )
    }

    /// Creates a gesture state with a custom reset function.
    ///
    /// The reset function is called when the gesture ends, allowing you to perform
    /// cleanup or logging. You can also modify the transaction to control how the
    /// reset is animated.
    ///
    /// Example:
    /// ```swift
    /// @GestureState(
    ///     reset: { value, transaction in
    ///         print("Gesture ended, final value: \(value)")
    ///         transaction.animation = .spring()
    ///     },
    ///     initialValue: 0.0
    /// ) private var scale
    /// ```
    ///
    /// - Parameters:
    ///   - reset: A closure called when the gesture ends. Receives the current value
    ///     and a mutable transaction that can be modified.
    ///   - initialValue: The initial value to reset to when the gesture ends.
    public init(
        reset: @escaping @Sendable @MainActor (Value, inout Transaction) -> Void,
        initialValue: Value
    ) {
        self.storage = GestureStateStorage(
            initialValue: initialValue,
            reset: reset
        )
    }

    /// Internal method to update the gesture state value.
    ///
    /// This is called by the gesture system when the gesture updates. It should not
    /// be called directly by user code.
    ///
    /// - Parameters:
    ///   - newValue: The new value for the gesture state.
    ///   - transaction: The transaction context for the update.
    internal func update(value newValue: Value, transaction: inout Transaction) {
        storage.setValue(newValue)
    }

    /// Internal method to reset the gesture state.
    ///
    /// This is called by the gesture system when the gesture ends. It resets the
    /// value to the initial value and calls the custom reset function if provided.
    ///
    /// - Parameter transaction: The transaction context for the reset.
    internal func reset(transaction: inout Transaction) {
        storage.reset(transaction: &transaction)
    }
}

// MARK: - Internal Storage

/// Internal storage for @GestureState property wrapper values.
///
/// This class holds the current value, the initial value, and an optional reset function.
/// It provides thread-safe access through `@MainActor` isolation.
@MainActor
private final class GestureStateStorage<Value: Sendable>: @unchecked Sendable {
    /// The current value of the gesture state.
    private var value: Value

    /// The initial value to reset to when the gesture ends.
    private let initialValue: Value

    /// Optional closure called when the gesture ends.
    private let resetFunction: (@Sendable @MainActor (Value, inout Transaction) -> Void)?

    /// Initialize with an initial value and optional reset function.
    ///
    /// - Parameters:
    ///   - initialValue: The initial value to use and reset to.
    ///   - reset: Optional closure to call when resetting.
    init(
        initialValue: Value,
        reset: (@Sendable @MainActor (Value, inout Transaction) -> Void)?
    ) {
        self.value = initialValue
        self.initialValue = initialValue
        self.resetFunction = reset
    }

    /// Get the current value.
    var currentValue: Value {
        value
    }

    /// Set a new value.
    ///
    /// This is used during gesture updates to change the current value.
    ///
    /// - Parameter newValue: The new value to store.
    func setValue(_ newValue: Value) {
        value = newValue
    }

    /// Reset to the initial value.
    ///
    /// This is called when the gesture ends. It resets the value to the initial
    /// value and invokes the custom reset function if one was provided.
    ///
    /// - Parameter transaction: The transaction context, which can be modified
    ///   by the reset function.
    func reset(transaction: inout Transaction) {
        // Call the custom reset function if provided
        if let resetFunction = resetFunction {
            resetFunction(value, &transaction)
        }

        // Reset to initial value
        value = initialValue
    }
}

// MARK: - Sendable Conformance

// GestureState is @unchecked Sendable because GestureStateStorage is marked as such.
// The MainActor isolation ensures thread safety.
extension GestureState: @unchecked Sendable {}
