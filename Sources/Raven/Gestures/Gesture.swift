import Foundation

// MARK: - Gesture Protocol

/// A type that represents a gesture recognizer in Raven.
///
/// The `Gesture` protocol is the foundation of gesture recognition in Raven. It defines
/// a gesture as something that can track user interaction and produce a value over time.
/// Concrete gesture types like `TapGesture`, `DragGesture`, and `LongPressGesture` conform
/// to this protocol.
///
/// ## Overview
///
/// Gestures are composable and can be combined using modifiers like `simultaneously(with:)`,
/// `sequenced(before:)`, and `exclusively(before:)`. Each gesture has an associated `Value`
/// type that represents the data produced during gesture recognition.
///
/// ## Creating Custom Gestures
///
/// To create a custom gesture, conform to the `Gesture` protocol:
///
/// ```swift
/// struct MyGesture: Gesture {
///     typealias Value = CGPoint
///
///     var body: Never {
///         fatalError("This gesture has no body")
///     }
/// }
/// ```
///
/// Most gestures are "primitive" gestures (like the example above) that have `Never` as their
/// body type. These gestures do their work directly rather than composing other gestures.
///
/// ## Gesture Composition
///
/// Combine gestures to create complex interactions:
///
/// ```swift
/// struct ContentView: View {
///     var body: some View {
///         Rectangle()
///             .gesture(
///                 DragGesture()
///                     .simultaneously(with: MagnificationGesture())
///             )
///     }
/// }
/// ```
///
/// ## Gesture Values
///
/// Each gesture produces a value during recognition. For example:
/// - `TapGesture` produces `Void` (the tap happened)
/// - `DragGesture` produces `DragGesture.Value` (location, translation, etc.)
/// - `MagnificationGesture` produces `Double` (the scale factor)
///
/// ## Web Implementation
///
/// In Raven's web environment, gestures map to JavaScript events:
/// - Mouse events (mousedown, mousemove, mouseup)
/// - Touch events (touchstart, touchmove, touchend)
/// - Pointer events (pointerdown, pointermove, pointerup)
///
/// The gesture system automatically handles event registration, tracking, and cleanup.
///
/// ## Thread Safety
///
/// All gestures and their values must be `Sendable` to ensure thread safety in Swift's
/// strict concurrency model. Gesture recognition occurs on the main actor.
///
/// ## See Also
///
/// - ``TapGesture``
/// - ``DragGesture``
/// - ``LongPressGesture``
/// - ``MagnificationGesture``
/// - ``RotationGesture``
/// - ``GestureState``
@MainActor
public protocol Gesture: Sendable {
    /// The type representing the gesture's value.
    ///
    /// This associated type defines what data the gesture produces during recognition.
    /// For example, a drag gesture produces location and translation information,
    /// while a tap gesture produces no value (Void).
    associatedtype Value: Sendable

    /// The type of gesture representing the body of this gesture.
    ///
    /// For primitive gestures (gestures that do their work directly), this is `Never`.
    /// For composite gestures (gestures built from other gestures), this is the type
    /// of the composed gesture.
    associatedtype Body: Gesture

    /// The content and behavior of the gesture.
    ///
    /// For primitive gestures, this property should never be accessed and can be
    /// implemented to trigger a fatal error. For composite gestures, this returns
    /// the composed gesture.
    @MainActor
    var body: Body { get }
}

// MARK: - Never Gesture Conformance

extension Never: Gesture {
    /// The value type for Never gestures.
    public typealias Value = Never
}

// MARK: - Default Implementation

extension Gesture where Body == Never {
    /// Default implementation for primitive gestures.
    ///
    /// Primitive gestures have `Never` as their body type and should never have their
    /// body accessed. This provides a default implementation that makes it clear if
    /// this happens by accident.
    @MainActor
    public var body: Never {
        fatalError("\(type(of: self)).body should never be called for primitive gestures")
    }
}

// MARK: - GestureMask

/// A set of options for controlling how gestures are recognized in a view hierarchy.
///
/// Use `GestureMask` to control which parts of a view hierarchy can recognize gestures.
/// This is useful when you want to prevent gesture conflicts or enable gestures only
/// on specific parts of your UI.
///
/// ## Overview
///
/// When you add a gesture to a view using the `.gesture(_:including:)` modifier, you can
/// specify a mask that controls where the gesture should be recognized:
///
/// ```swift
/// Rectangle()
///     .gesture(
///         TapGesture(),
///         including: .gesture  // Only this view, not subviews
///     )
/// ```
///
/// ## Common Patterns
///
/// **Enable gestures only on the view itself:**
/// ```swift
/// .gesture(drag, including: .gesture)
/// ```
///
/// **Enable gestures only on subviews:**
/// ```swift
/// .gesture(drag, including: .subviews)
/// ```
///
/// **Enable gestures on both view and subviews (default):**
/// ```swift
/// .gesture(drag, including: .all)
/// ```
///
/// **Disable gestures entirely:**
/// ```swift
/// .gesture(drag, including: .none)
/// ```
///
/// ## Web Implementation
///
/// In Raven's web environment, gesture masks control event listener attachment:
/// - `.gesture`: Listeners on the element itself only
/// - `.subviews`: Listeners on child elements only (via event delegation)
/// - `.all`: Listeners on both the element and children
/// - `.none`: No listeners attached
///
/// ## See Also
///
/// - ``View/gesture(_:including:)``
/// - ``View/simultaneousGesture(_:including:)``
/// - ``View/highPriorityGesture(_:including:)``
public struct GestureMask: OptionSet, Sendable {
    public let rawValue: Int

    /// Creates a gesture mask with the specified raw value.
    ///
    /// - Parameter rawValue: The raw integer value for the mask.
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    /// No gestures are recognized.
    ///
    /// Use this to completely disable gesture recognition for a view and its subviews.
    public static let none = GestureMask([])

    /// Gestures are recognized on the view itself.
    ///
    /// With this option, only the view that has the gesture modifier applied will
    /// recognize the gesture. Subviews will not trigger gesture recognition.
    public static let gesture = GestureMask(rawValue: 1 << 0)

    /// Gestures are recognized on subviews of the view.
    ///
    /// With this option, only subviews of the view with the gesture modifier will
    /// recognize the gesture. The view itself will not trigger gesture recognition.
    public static let subviews = GestureMask(rawValue: 1 << 1)

    /// Gestures are recognized on both the view and its subviews.
    ///
    /// This is the default behavior. Gestures will be recognized whether the interaction
    /// happens on the view itself or any of its subviews.
    public static let all: GestureMask = [.gesture, .subviews]
}

// MARK: - EventModifiers

/// A set of modifier keys that can be pressed during a gesture.
///
/// Use `EventModifiers` to detect which keyboard modifier keys (like Shift, Control, or Command)
/// are pressed during a gesture. This allows you to create different behaviors based on modifier
/// key combinations.
///
/// ## Overview
///
/// Event modifiers are commonly used to add variations to gesture behaviors:
///
/// ```swift
/// DragGesture()
///     .onChanged { value in
///         if value.modifiers.contains(.shift) {
///             // Constrain drag to horizontal or vertical
///         } else {
///             // Free drag
///         }
///     }
/// ```
///
/// ## Available Modifiers
///
/// - **capsLock**: The Caps Lock key is engaged
/// - **shift**: The Shift key is pressed
/// - **control**: The Control key is pressed
/// - **option**: The Option/Alt key is pressed
/// - **command**: The Command/Meta key is pressed
/// - **numericPad**: The key is from the numeric keypad
/// - **function**: A function key is pressed
///
/// ## Platform Differences
///
/// Different platforms have different modifier keys:
/// - **macOS**: Command (⌘), Option (⌥), Control (⌃), Shift (⇧)
/// - **Windows**: Control, Alt, Shift, Windows key
/// - **Linux**: Control, Alt, Shift, Super/Meta
///
/// In Raven's web environment, the standard JavaScript keyboard event modifiers are used,
/// and the appropriate keys are mapped based on the user's platform.
///
/// ## Web Implementation
///
/// Event modifiers map to JavaScript KeyboardEvent and MouseEvent properties:
/// - `shift` → `event.shiftKey`
/// - `control` → `event.ctrlKey`
/// - `option` → `event.altKey`
/// - `command` → `event.metaKey`
///
/// ## Example
///
/// Create different drag behaviors based on modifiers:
///
/// ```swift
/// struct DragView: View {
///     @GestureState private var dragOffset = CGSize.zero
///
///     var body: some View {
///         Rectangle()
///             .offset(dragOffset)
///             .gesture(
///                 DragGesture()
///                     .updating($dragOffset) { value, state, _ in
///                         if value.modifiers.contains(.shift) {
///                             // Constrain to one axis
///                             let dx = abs(value.translation.width)
///                             let dy = abs(value.translation.height)
///                             state = dx > dy
///                                 ? CGSize(width: value.translation.width, height: 0)
///                                 : CGSize(width: 0, height: value.translation.height)
///                         } else {
///                             state = value.translation
///                         }
///                     }
///             )
///     }
/// }
/// ```
///
/// ## See Also
///
/// - ``DragGesture/Value``
/// - ``Gesture``
public struct EventModifiers: OptionSet, Sendable {
    public let rawValue: Int

    /// Creates an event modifiers set with the specified raw value.
    ///
    /// - Parameter rawValue: The raw integer value for the modifiers.
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    /// The Caps Lock key is engaged.
    ///
    /// Note: This is detected based on whether Caps Lock affects the current key press,
    /// not by tracking the Caps Lock state directly (which is not available in web browsers
    /// for privacy reasons).
    public static let capsLock = EventModifiers(rawValue: 1 << 0)

    /// The Shift key is pressed.
    ///
    /// On all platforms, this corresponds to the Shift modifier key.
    public static let shift = EventModifiers(rawValue: 1 << 1)

    /// The Control key is pressed.
    ///
    /// On all platforms, this corresponds to the Control modifier key.
    /// Note that on macOS, the Command key is typically used for keyboard shortcuts,
    /// not Control.
    public static let control = EventModifiers(rawValue: 1 << 2)

    /// The Option key is pressed (macOS) or Alt key (Windows/Linux).
    ///
    /// This corresponds to:
    /// - Option (⌥) on macOS
    /// - Alt on Windows and Linux
    public static let option = EventModifiers(rawValue: 1 << 3)

    /// The Command key is pressed (macOS) or Windows/Meta key (Windows/Linux).
    ///
    /// This corresponds to:
    /// - Command (⌘) on macOS
    /// - Windows key on Windows
    /// - Super/Meta key on Linux
    public static let command = EventModifiers(rawValue: 1 << 4)

    /// The key is from the numeric keypad.
    ///
    /// This modifier indicates that the key press originated from the numeric keypad
    /// rather than the main keyboard area.
    public static let numericPad = EventModifiers(rawValue: 1 << 5)

    /// A function key is pressed.
    ///
    /// This indicates that one of the function keys (F1-F12 or higher) is involved
    /// in the event.
    public static let function = EventModifiers(rawValue: 1 << 6)

    /// All modifier keys.
    ///
    /// Use this to check if any modifier keys are pressed.
    public static let all: EventModifiers = [
        .capsLock,
        .shift,
        .control,
        .option,
        .command,
        .numericPad,
        .function
    ]
}

// MARK: - Transaction

/// A context for state changes and animations.
///
/// A transaction represents a context in which state changes occur. Transactions can carry
/// animation information, allowing views to animate in response to state changes.
///
/// ## Overview
///
/// Transactions are created automatically when state changes occur, but you can also
/// create and modify transactions explicitly to control animation behavior.
///
/// ## Using Transactions
///
/// Most of the time, you won't work with transactions directly. Instead, you use
/// `withAnimation` which creates a transaction for you:
///
/// ```swift
/// withAnimation(.spring()) {
///     isExpanded.toggle()
/// }
/// ```
///
/// ## Transaction Properties
///
/// Transactions carry information about how state changes should be handled:
/// - **animation**: The animation to apply to state changes
/// - **disablesAnimations**: Whether animations should be disabled
///
/// ## Gesture Integration
///
/// Gestures use transactions to communicate animation intent to `@GestureState`:
///
/// ```swift
/// @GestureState private var dragOffset = CGSize.zero
///
/// DragGesture()
///     .updating($dragOffset) { value, state, transaction in
///         // The transaction can modify how the state updates
///         transaction.animation = .spring()
///         state = value.translation
///     }
/// ```
///
/// ## See Also
///
/// - ``withAnimation(_:_:)``
/// - ``GestureState``
/// - ``Animation``
@MainActor
public struct Transaction: Sendable {
    /// The animation associated with this transaction, if any.
    ///
    /// When set, this animation will be applied to any state changes that occur
    /// within the transaction context.
    public var animation: Animation?

    /// A Boolean value that indicates whether animations are disabled.
    ///
    /// When `true`, state changes will occur immediately without animation,
    /// even if an animation is set.
    public var disablesAnimations: Bool

    /// Creates a new transaction.
    ///
    /// - Parameters:
    ///   - animation: The animation to apply to state changes. Default is `nil`.
    ///   - disablesAnimations: Whether to disable animations. Default is `false`.
    public init(animation: Animation? = nil, disablesAnimations: Bool = false) {
        self.animation = animation
        self.disablesAnimations = disablesAnimations
    }
}

// MARK: - Gesture Modifier Types

/// A modifier that adds an onChanged action to a gesture.
///
/// This modifier is used internally by gesture types to provide the `onChanged` modifier.
@MainActor
public struct _ChangedGestureModifier<Value: Sendable>: Sendable {
    public let action: @MainActor @Sendable (Value) -> Void

    public init(action: @escaping @MainActor @Sendable (Value) -> Void) {
        self.action = action
    }
}
