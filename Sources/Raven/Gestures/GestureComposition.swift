import Foundation

// MARK: - Simultaneous Gesture

/// A gesture that recognizes two gestures simultaneously.
///
/// `SimultaneousGesture` allows two gestures to recognize at the same time, producing
/// values from both gestures. This is useful when you want to handle multiple types of
/// input concurrently, such as rotating and scaling an image simultaneously.
///
/// ## Overview
///
/// When two gestures are combined with `simultaneously(with:)`, both gestures can
/// recognize and update independently. The resulting gesture produces a tuple of
/// optional values, one from each gesture. A value is `nil` if that gesture hasn't
/// started or is currently inactive.
///
/// ## Basic Usage
///
/// Combine rotation and magnification:
///
/// ```swift
/// Image("photo")
///     .gesture(
///         RotationGesture()
///             .simultaneously(with: MagnificationGesture())
///             .onChanged { value in
///                 rotation = value.0 ?? .zero
///                 scale = value.1 ?? 1.0
///             }
///     )
/// ```
///
/// ## Value Type
///
/// The value produced is a tuple `(G1.Value?, G2.Value?)` where:
/// - The first element is the value from the first gesture (or `nil` if inactive)
/// - The second element is the value from the second gesture (or `nil` if inactive)
///
/// ## Recognition Behavior
///
/// Both gestures run concurrently:
/// - Either gesture can start first
/// - Both gestures can be active at the same time
/// - Each gesture updates independently
/// - The combined gesture ends when both gestures have ended
///
/// ## Common Use Cases
///
/// **Rotate and scale:**
/// ```swift
/// RotationGesture()
///     .simultaneously(with: MagnificationGesture())
/// ```
///
/// **Drag and long press:**
/// ```swift
/// DragGesture()
///     .simultaneously(with: LongPressGesture())
/// ```
///
/// **Multiple independent gestures:**
/// ```swift
/// TapGesture()
///     .simultaneously(with: LongPressGesture())
/// ```
///
/// ## Web Implementation
///
/// In Raven's web environment, simultaneous gestures:
/// - Share event listeners for efficiency
/// - Track state for both gestures independently
/// - Fire updates whenever either gesture changes
/// - Handle multi-touch events for touch-based gestures
///
/// ## Thread Safety
///
/// `SimultaneousGesture` is `@MainActor` isolated and `Sendable`, ensuring thread-safe
/// usage in Swift's strict concurrency model.
///
/// ## See Also
///
/// - ``SequenceGesture``
/// - ``ExclusiveGesture``
/// - ``Gesture/simultaneously(with:)``
@MainActor
public struct SimultaneousGesture<First: Gesture, Second: Gesture>: Gesture, Sendable {
    /// The type of value produced by this gesture.
    ///
    /// A tuple of optional values from both gestures. Each value is `nil` if that
    /// gesture is not currently active.
    public typealias Value = (First.Value?, Second.Value?)

    /// The body type for this gesture.
    public typealias Body = Never

    /// The first gesture in the simultaneous combination.
    public let first: First

    /// The second gesture in the simultaneous combination.
    public let second: Second

    /// Creates a gesture that recognizes two gestures simultaneously.
    ///
    /// - Parameters:
    ///   - first: The first gesture.
    ///   - second: The second gesture.
    public init(_ first: First, _ second: Second) {
        self.first = first
        self.second = second
    }
}

// MARK: - Sequence Gesture

/// A gesture that recognizes two gestures in sequence.
///
/// `SequenceGesture` requires the first gesture to complete successfully before the
/// second gesture can begin. This is useful for creating multi-step interactions,
/// such as requiring a long press before allowing a drag.
///
/// ## Overview
///
/// When two gestures are combined with `sequenced(before:)`, the first gesture must
/// recognize and complete before the second gesture begins. The resulting gesture
/// produces a value that indicates which stage of the sequence is active.
///
/// ## Basic Usage
///
/// Long press then drag:
///
/// ```swift
/// Rectangle()
///     .gesture(
///         LongPressGesture()
///             .sequenced(before: DragGesture())
///             .onChanged { value in
///                 switch value {
///                 case .first:
///                     print("Waiting for long press...")
///                 case .second(true, let drag):
///                     print("Dragging: \(drag?.translation)")
///                 case .second(false, _):
///                     print("Long press not completed")
///                 }
///             }
///     )
/// ```
///
/// ## Value Type
///
/// The value is an enum with two cases:
/// - `.first(G1.Value)`: The first gesture is active and has produced a value
/// - `.second(G1.Value, G2.Value?)`: The first gesture completed, second is active
///
/// The second case includes both the final value from the first gesture and the
/// current value from the second gesture (which may be `nil` if the second gesture
/// hasn't started yet).
///
/// ## Recognition Behavior
///
/// The sequence progresses in stages:
/// 1. The first gesture begins recognizing
/// 2. The first gesture must complete successfully
/// 3. Only after first completes, the second gesture can begin
/// 4. The second gesture recognizes and produces values
/// 5. The combined gesture ends when the second gesture ends
///
/// If the first gesture fails or is cancelled, the sequence ends without attempting
/// the second gesture.
///
/// ## Common Use Cases
///
/// **Long press then drag:**
/// ```swift
/// LongPressGesture(minimumDuration: 0.5)
///     .sequenced(before: DragGesture())
/// ```
///
/// **Tap then drag:**
/// ```swift
/// TapGesture(count: 2)  // Double tap
///     .sequenced(before: DragGesture())
/// ```
///
/// **Multi-stage interaction:**
/// ```swift
/// LongPressGesture()
///     .sequenced(before: RotationGesture())
/// ```
///
/// ## Web Implementation
///
/// In Raven's web environment, sequence gestures:
/// - Track which stage of the sequence is active
/// - Only attach event listeners for the second gesture after the first completes
/// - Maintain state from the first gesture for the duration of the second
/// - Cancel the entire sequence if the first gesture fails
///
/// ## Thread Safety
///
/// `SequenceGesture` is `@MainActor` isolated and `Sendable`, ensuring thread-safe
/// usage in Swift's strict concurrency model.
///
/// ## See Also
///
/// - ``SequenceGesture/Value``
/// - ``SimultaneousGesture``
/// - ``ExclusiveGesture``
/// - ``Gesture/sequenced(before:)``
@MainActor
public struct SequenceGesture<First: Gesture, Second: Gesture>: Gesture, Sendable {
    /// The type of value produced by this gesture.
    ///
    /// An enum indicating which stage of the sequence is active and providing
    /// values from the gestures.
    public typealias Value = SequenceGestureValue<First.Value, Second.Value>

    /// The body type for this gesture.
    public typealias Body = Never

    /// The first gesture in the sequence.
    public let first: First

    /// The second gesture in the sequence.
    public let second: Second

    /// Creates a gesture that recognizes two gestures in sequence.
    ///
    /// - Parameters:
    ///   - first: The first gesture. This must complete before the second begins.
    ///   - second: The second gesture. This begins only after the first completes.
    public init(_ first: First, _ second: Second) {
        self.first = first
        self.second = second
    }
}

// MARK: - Sequence Gesture Value

/// The value produced by a sequence gesture.
///
/// This enum represents the current state of a sequence gesture, indicating which
/// gesture in the sequence is active and providing the values from the gestures.
///
/// ## Cases
///
/// - **first**: The first gesture is active. The associated value is the current
///   value from the first gesture.
///
/// - **second**: The first gesture completed and the second is active (or about to
///   start). The associated values are the final value from the first gesture and
///   the current value from the second gesture (which may be `nil` if the second
///   gesture hasn't produced a value yet).
///
/// ## Example
///
/// ```swift
/// LongPressGesture()
///     .sequenced(before: DragGesture())
///     .onChanged { value in
///         switch value {
///         case .first(let pressing):
///             print("Long press in progress: \(pressing)")
///         case .second(let longPressCompleted, let drag):
///             if longPressCompleted {
///                 if let dragValue = drag {
///                     print("Dragging: \(dragValue.translation)")
///                 } else {
///                     print("Long press completed, waiting for drag")
///                 }
///             }
///         }
///     }
/// ```
///
/// ## See Also
///
/// - ``SequenceGesture``
@frozen
public enum SequenceGestureValue<First: Sendable, Second: Sendable>: Sendable {
    /// The first gesture is currently active.
    ///
    /// - Parameter First: The current value from the first gesture.
    case first(First)

    /// The first gesture completed and the second gesture is active or about to start.
    ///
    /// - Parameters:
    ///   - First: The final value from the first gesture.
    ///   - Second?: The current value from the second gesture, or `nil` if the
    ///     second gesture hasn't started yet.
    case second(First, Second?)
}

// MARK: - Sequence Gesture Value Equatable

extension SequenceGestureValue: Equatable where First: Equatable, Second: Equatable {
    public static func == (lhs: SequenceGestureValue<First, Second>, rhs: SequenceGestureValue<First, Second>) -> Bool {
        switch (lhs, rhs) {
        case (.first(let a), .first(let b)):
            return a == b
        case (.second(let a1, let a2), .second(let b1, let b2)):
            return a1 == b1 && a2 == b2
        default:
            return false
        }
    }
}

// MARK: - Exclusive Gesture

/// A gesture that recognizes one of two gestures, whichever recognizes first.
///
/// `ExclusiveGesture` allows only one of two gestures to recognize. The first gesture
/// to begin recognition wins, and the other gesture is prevented from recognizing.
/// This is useful when you want to handle alternative interaction methods.
///
/// ## Overview
///
/// When two gestures are combined with `exclusively(before:)`, they compete for
/// recognition. Once one gesture begins, the other is blocked. This is different
/// from simultaneous gestures (which both recognize) and sequence gestures (which
/// recognize in order).
///
/// ## Basic Usage
///
/// Tap or long press:
///
/// ```swift
/// Text("Press or tap")
///     .gesture(
///         TapGesture()
///             .exclusively(before: LongPressGesture())
///             .onEnded { value in
///                 switch value {
///                 case .first:
///                     print("Tapped!")
///                 case .second:
///                     print("Long pressed!")
///                 }
///             }
///     )
/// ```
///
/// ## Value Type
///
/// The value is an enum with two cases:
/// - `.first(G1.Value)`: The first gesture won and produced a value
/// - `.second(G2.Value)`: The second gesture won and produced a value
///
/// Only one case will ever occur per gesture recognition - whichever gesture
/// recognizes first.
///
/// ## Recognition Behavior
///
/// The gestures compete for recognition:
/// 1. Both gestures monitor for their triggering conditions
/// 2. The first gesture to begin recognition wins
/// 3. The losing gesture is cancelled and cannot recognize
/// 4. Only the winning gesture produces values
///
/// The "exclusively before" phrasing gives the first gesture priority when both
/// would recognize at the same time, but typically the first to actually begin
/// recognition wins.
///
/// ## Common Use Cases
///
/// **Tap or long press:**
/// ```swift
/// TapGesture()
///     .exclusively(before: LongPressGesture())
/// ```
///
/// **Different drag modes:**
/// ```swift
/// DragGesture(minimumDistance: 10)
///     .exclusively(before: DragGesture(minimumDistance: 50))
/// ```
///
/// **Alternative interactions:**
/// ```swift
/// TapGesture(count: 2)  // Double tap
///     .exclusively(before: TapGesture())  // Single tap
/// ```
///
/// ## Web Implementation
///
/// In Raven's web environment, exclusive gestures:
/// - Monitor events for both gestures simultaneously
/// - Cancel one gesture as soon as the other begins recognition
/// - Only fire callbacks for the winning gesture
/// - Clean up state for the losing gesture
///
/// ## Thread Safety
///
/// `ExclusiveGesture` is `@MainActor` isolated and `Sendable`, ensuring thread-safe
/// usage in Swift's strict concurrency model.
///
/// ## See Also
///
/// - ``ExclusiveGesture/Value``
/// - ``SimultaneousGesture``
/// - ``SequenceGesture``
/// - ``Gesture/exclusively(before:)``
@MainActor
public struct ExclusiveGesture<First: Gesture, Second: Gesture>: Gesture, Sendable {
    /// The type of value produced by this gesture.
    ///
    /// An enum indicating which gesture won and providing its value.
    public typealias Value = ExclusiveGestureValue<First.Value, Second.Value>

    /// The body type for this gesture.
    public typealias Body = Never

    /// The first gesture in the exclusive combination.
    public let first: First

    /// The second gesture in the exclusive combination.
    public let second: Second

    /// Creates a gesture that recognizes one of two gestures exclusively.
    ///
    /// - Parameters:
    ///   - first: The first gesture. This has priority if both recognize simultaneously.
    ///   - second: The second gesture.
    public init(_ first: First, _ second: Second) {
        self.first = first
        self.second = second
    }
}

// MARK: - Exclusive Gesture Value

/// The value produced by an exclusive gesture.
///
/// This enum represents which gesture in an exclusive combination won recognition
/// and provides that gesture's value.
///
/// ## Cases
///
/// - **first**: The first gesture won. The associated value is the value from the
///   first gesture.
///
/// - **second**: The second gesture won. The associated value is the value from the
///   second gesture.
///
/// ## Example
///
/// ```swift
/// TapGesture()
///     .exclusively(before: LongPressGesture())
///     .onEnded { value in
///         switch value {
///         case .first:
///             print("Quick tap detected")
///         case .second:
///             print("Long press detected")
///         }
///     }
/// ```
///
/// ## See Also
///
/// - ``ExclusiveGesture``
@frozen
public enum ExclusiveGestureValue<First: Sendable, Second: Sendable>: Sendable {
    /// The first gesture was recognized.
    ///
    /// - Parameter First: The value from the first gesture.
    case first(First)

    /// The second gesture was recognized.
    ///
    /// - Parameter Second: The value from the second gesture.
    case second(Second)
}

// MARK: - Exclusive Gesture Value Equatable

extension ExclusiveGestureValue: Equatable where First: Equatable, Second: Equatable {
    public static func == (lhs: ExclusiveGestureValue<First, Second>, rhs: ExclusiveGestureValue<First, Second>) -> Bool {
        switch (lhs, rhs) {
        case (.first(let a), .first(let b)):
            return a == b
        case (.second(let a), .second(let b)):
            return a == b
        default:
            return false
        }
    }
}

// MARK: - Gesture Extensions

extension Gesture {
    /// Combines this gesture with another gesture to create a gesture that recognizes
    /// both gestures simultaneously.
    ///
    /// Use this method when you want two gestures to work together at the same time.
    /// Both gestures can recognize and update independently, and the combined gesture
    /// produces a tuple of optional values from both gestures.
    ///
    /// ## Example
    ///
    /// Rotate and zoom an image simultaneously:
    ///
    /// ```swift
    /// @State private var rotation: Angle = .zero
    /// @State private var scale: Double = 1.0
    ///
    /// Image("photo")
    ///     .rotationEffect(rotation)
    ///     .scaleEffect(scale)
    ///     .gesture(
    ///         RotationGesture()
    ///             .simultaneously(with: MagnificationGesture())
    ///             .onChanged { value in
    ///                 rotation = value.0 ?? .zero
    ///                 scale = value.1 ?? 1.0
    ///             }
    ///     )
    /// ```
    ///
    /// ## Value Type
    ///
    /// The combined gesture produces `(Self.Value?, Other.Value?)`:
    /// - First element: Value from this gesture (or `nil` if inactive)
    /// - Second element: Value from the other gesture (or `nil` if inactive)
    ///
    /// - Parameter other: The gesture to combine with this gesture.
    /// - Returns: A gesture that recognizes both gestures simultaneously.
    ///
    /// ## See Also
    ///
    /// - ``SimultaneousGesture``
    /// - ``sequenced(before:)``
    /// - ``exclusively(before:)``
    @MainActor
    public func simultaneously<Other: Gesture>(
        with other: Other
    ) -> SimultaneousGesture<Self, Other> {
        SimultaneousGesture(self, other)
    }

    /// Combines this gesture with another gesture to create a gesture that recognizes
    /// the gestures in sequence.
    ///
    /// Use this method when you want to require one gesture to complete before another
    /// can begin. This is useful for creating multi-step interactions.
    ///
    /// ## Example
    ///
    /// Require a long press before allowing drag:
    ///
    /// ```swift
    /// @State private var isDragging = false
    /// @State private var offset = CGSize.zero
    ///
    /// Rectangle()
    ///     .offset(offset)
    ///     .gesture(
    ///         LongPressGesture(minimumDuration: 0.5)
    ///             .sequenced(before: DragGesture())
    ///             .onChanged { value in
    ///                 switch value {
    ///                 case .first:
    ///                     isDragging = false
    ///                 case .second(true, let drag):
    ///                     isDragging = true
    ///                     offset = drag?.translation ?? .zero
    ///                 case .second(false, _):
    ///                     isDragging = false
    ///                 }
    ///             }
    ///     )
    /// ```
    ///
    /// ## Value Type
    ///
    /// The combined gesture produces `SequenceGestureValue<Self.Value, Other.Value>`:
    /// - `.first(Self.Value)`: First gesture is active
    /// - `.second(Self.Value, Other.Value?)`: First completed, second is active
    ///
    /// - Parameter other: The gesture that follows this gesture.
    /// - Returns: A gesture that recognizes the gestures in sequence.
    ///
    /// ## See Also
    ///
    /// - ``SequenceGesture``
    /// - ``SequenceGestureValue``
    /// - ``simultaneously(with:)``
    /// - ``exclusively(before:)``
    @MainActor
    public func sequenced<Other: Gesture>(
        before other: Other
    ) -> SequenceGesture<Self, Other> {
        SequenceGesture(self, other)
    }

    /// Combines this gesture with another gesture to create a gesture that recognizes
    /// only one of the two gestures.
    ///
    /// Use this method when you want to handle alternative interaction methods. The
    /// first gesture to recognize wins, and the other is cancelled.
    ///
    /// ## Example
    ///
    /// Handle either tap or long press:
    ///
    /// ```swift
    /// @State private var message = ""
    ///
    /// Text(message)
    ///     .gesture(
    ///         TapGesture()
    ///             .exclusively(before: LongPressGesture())
    ///             .onEnded { value in
    ///                 switch value {
    ///                 case .first:
    ///                     message = "Tapped!"
    ///                 case .second:
    ///                     message = "Long pressed!"
    ///                 }
    ///             }
    ///     )
    /// ```
    ///
    /// ## Value Type
    ///
    /// The combined gesture produces `ExclusiveGestureValue<Self.Value, Other.Value>`:
    /// - `.first(Self.Value)`: This gesture won
    /// - `.second(Other.Value)`: The other gesture won
    ///
    /// - Parameter other: The alternative gesture.
    /// - Returns: A gesture that recognizes one of the two gestures exclusively.
    ///
    /// ## See Also
    ///
    /// - ``ExclusiveGesture``
    /// - ``ExclusiveGestureValue``
    /// - ``simultaneously(with:)``
    /// - ``sequenced(before:)``
    @MainActor
    public func exclusively<Other: Gesture>(
        before other: Other
    ) -> ExclusiveGesture<Self, Other> {
        ExclusiveGesture(self, other)
    }
}

// MARK: - Gesture Modifiers for Composed Gestures

extension SimultaneousGesture {
    /// Adds an action to perform when the simultaneous gesture changes.
    ///
    /// - Parameter action: The action to perform with each update.
    /// - Returns: A gesture with the action attached.
    @MainActor
    public func onChanged(
        _ action: @escaping @MainActor @Sendable (Value) -> Void
    ) -> _ModifiedGesture<SimultaneousGesture<First, Second>, _ChangedGestureModifier<Value>> {
        _ModifiedGesture(
            gesture: self,
            modifier: _ChangedGestureModifier(action: action)
        )
    }

    /// Adds an action to perform when the simultaneous gesture ends.
    ///
    /// - Parameter action: The action to perform when the gesture ends.
    /// - Returns: A gesture with the action attached.
    @MainActor
    public func onEnded(
        _ action: @escaping @MainActor @Sendable (Value) -> Void
    ) -> _ModifiedGesture<SimultaneousGesture<First, Second>, _EndedGestureModifier<Value>> {
        _ModifiedGesture(
            gesture: self,
            modifier: _EndedGestureModifier(action: action)
        )
    }
}

extension SequenceGesture {
    /// Adds an action to perform when the sequence gesture changes.
    ///
    /// - Parameter action: The action to perform with each update.
    /// - Returns: A gesture with the action attached.
    @MainActor
    public func onChanged(
        _ action: @escaping @MainActor @Sendable (Value) -> Void
    ) -> _ModifiedGesture<SequenceGesture<First, Second>, _ChangedGestureModifier<Value>> {
        _ModifiedGesture(
            gesture: self,
            modifier: _ChangedGestureModifier(action: action)
        )
    }

    /// Adds an action to perform when the sequence gesture ends.
    ///
    /// - Parameter action: The action to perform when the gesture ends.
    /// - Returns: A gesture with the action attached.
    @MainActor
    public func onEnded(
        _ action: @escaping @MainActor @Sendable (Value) -> Void
    ) -> _ModifiedGesture<SequenceGesture<First, Second>, _EndedGestureModifier<Value>> {
        _ModifiedGesture(
            gesture: self,
            modifier: _EndedGestureModifier(action: action)
        )
    }
}

extension ExclusiveGesture {
    /// Adds an action to perform when the exclusive gesture changes.
    ///
    /// - Parameter action: The action to perform with each update.
    /// - Returns: A gesture with the action attached.
    @MainActor
    public func onChanged(
        _ action: @escaping @MainActor @Sendable (Value) -> Void
    ) -> _ModifiedGesture<ExclusiveGesture<First, Second>, _ChangedGestureModifier<Value>> {
        _ModifiedGesture(
            gesture: self,
            modifier: _ChangedGestureModifier(action: action)
        )
    }

    /// Adds an action to perform when the exclusive gesture ends.
    ///
    /// - Parameter action: The action to perform when the gesture ends.
    /// - Returns: A gesture with the action attached.
    @MainActor
    public func onEnded(
        _ action: @escaping @MainActor @Sendable (Value) -> Void
    ) -> _ModifiedGesture<ExclusiveGesture<First, Second>, _EndedGestureModifier<Value>> {
        _ModifiedGesture(
            gesture: self,
            modifier: _EndedGestureModifier(action: action)
        )
    }
}

// MARK: - Documentation Examples

/*
 Example: Simultaneous rotation and magnification

 ```swift
 struct PhotoView: View {
     @State private var rotation: Angle = .zero
     @State private var scale: Double = 1.0

     var body: some View {
         Image("photo")
             .rotationEffect(rotation)
             .scaleEffect(scale)
             .gesture(
                 RotationGesture()
                     .simultaneously(with: MagnificationGesture())
                     .onChanged { value in
                         rotation = value.0 ?? .zero
                         scale = value.1 ?? 1.0
                     }
             )
     }
 }
 ```

 Example: Long press then drag sequence

 ```swift
 struct DraggableCard: View {
     @State private var offset = CGSize.zero
     @State private var isLongPressing = false

     var body: some View {
         RoundedRectangle(cornerRadius: 20)
             .fill(isLongPressing ? .blue : .gray)
             .frame(width: 200, height: 300)
             .offset(offset)
             .gesture(
                 LongPressGesture(minimumDuration: 0.5)
                     .sequenced(before: DragGesture())
                     .onChanged { value in
                         switch value {
                         case .first:
                             isLongPressing = true
                         case .second(true, let drag):
                             offset = drag?.translation ?? .zero
                         case .second(false, _):
                             isLongPressing = false
                         }
                     }
                     .onEnded { _ in
                         isLongPressing = false
                         withAnimation(.spring()) {
                             offset = .zero
                         }
                     }
             )
     }
 }
 ```

 Example: Exclusive tap or long press

 ```swift
 struct InteractiveButton: View {
     @State private var action = ""

     var body: some View {
         Text(action.isEmpty ? "Tap or press" : action)
             .padding()
             .background(.blue)
             .foregroundColor(.white)
             .gesture(
                 TapGesture()
                     .exclusively(before: LongPressGesture())
                     .onEnded { value in
                         switch value {
                         case .first:
                             action = "Tapped!"
                         case .second:
                             action = "Long pressed!"
                         }
                     }
             )
     }
 }
 ```

 Example: Nested compositions

 ```swift
 struct ComplexGestureView: View {
     var body: some View {
         Rectangle()
             .gesture(
                 TapGesture()
                     .simultaneously(with:
                         RotationGesture()
                             .simultaneously(with: MagnificationGesture())
                     )
             )
     }
 }
 ```
 */
