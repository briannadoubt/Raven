import Foundation

// MARK: - Gesture Modifiers

extension DragGesture {
    /// Adds an action to perform when the drag gesture changes.
    ///
    /// The action is called continuously as the user drags, providing updated values
    /// with current position, velocity, and prediction information.
    ///
    /// Example:
    /// ```swift
    /// DragGesture()
    ///     .onChanged { value in
    ///         print("Dragging: \(value.translation)")
    ///     }
    /// ```
    ///
    /// - Parameter action: The action to perform with each drag update.
    /// - Returns: A gesture with the action attached.
    public func onChanged(
        _ action: @escaping @MainActor @Sendable (Value) -> Void
    ) -> _ModifiedGesture<DragGesture, _ChangedGestureModifier<Value>> {
        _ModifiedGesture(
            gesture: self,
            modifier: _ChangedGestureModifier(action: action)
        )
    }

    /// Adds an action to perform when the drag gesture ends.
    ///
    /// The action is called once when the user releases the drag, providing final
    /// values including velocity and predicted end position.
    ///
    /// Example:
    /// ```swift
    /// DragGesture()
    ///     .onEnded { value in
    ///         print("Drag ended: \(value.translation)")
    ///         print("Final velocity: \(value.velocity)")
    ///     }
    /// ```
    ///
    /// - Parameter action: The action to perform when the gesture ends.
    /// - Returns: A gesture with the action attached.
    public func onEnded(
        _ action: @escaping @MainActor @Sendable (Value) -> Void
    ) -> _ModifiedGesture<DragGesture, _EndedGestureModifier<Value>> {
        _ModifiedGesture(
            gesture: self,
            modifier: _EndedGestureModifier(action: action)
        )
    }

    /// Updates gesture state values as the gesture changes.
    ///
    /// Use this modifier with `@GestureState` to track the gesture's progress.
    /// The gesture state automatically resets when the gesture ends or cancels.
    ///
    /// Example:
    /// ```swift
    /// @GestureState private var dragOffset = CGSize.zero
    ///
    /// DragGesture()
    ///     .updating($dragOffset) { value, state, transaction in
    ///         state = value.translation
    ///     }
    /// ```
    ///
    /// - Parameters:
    ///   - state: A binding to gesture state that will be updated.
    ///   - body: A closure that updates the gesture state. It receives the current
    ///     gesture value, an inout parameter for the gesture state, and a transaction.
    /// - Returns: A gesture that updates the provided state.
    public func updating<State>(
        _ state: GestureState<State>,
        body: @escaping @MainActor @Sendable (Value, inout State, inout Transaction) -> Void
    ) -> _ModifiedGesture<DragGesture, _UpdatingGestureModifier<State, Value>> {
        _ModifiedGesture(
            gesture: self,
            modifier: _UpdatingGestureModifier(state: state, body: body)
        )
    }
}

// MARK: - Documentation Examples

/*
 Example: Draggable card

 ```swift
 struct DraggableCard: View {
     @State private var offset = CGSize.zero

     var body: some View {
         RoundedRectangle(cornerRadius: 20)
             .fill(.blue)
             .frame(width: 300, height: 400)
             .offset(offset)
             .gesture(
                 DragGesture()
                     .onChanged { value in
                         offset = value.translation
                     }
                     .onEnded { value in
                         // Snap back or dismiss based on velocity
                         if abs(value.velocity.width) > 500 {
                             // Dismiss card
                             offset = CGSize(
                                 width: value.velocity.width > 0 ? 1000 : -1000,
                                 height: 0
                             )
                         } else {
                             // Snap back
                             withAnimation(.spring()) {
                                 offset = .zero
                             }
                         }
                     }
             )
     }
 }
 ```

 Example: Custom slider

 ```swift
 struct CustomSlider: View {
     @State private var value: Double = 0.5
     let width: Double = 300

     var body: some View {
         GeometryReader { geometry in
             ZStack(alignment: .leading) {
                 // Track
                 Rectangle()
                     .fill(.gray.opacity(0.3))
                     .frame(height: 4)

                 // Thumb
                 Circle()
                     .fill(.blue)
                     .frame(width: 30, height: 30)
                     .offset(x: value * (width - 30))
                     .gesture(
                         DragGesture(coordinateSpace: .local)
                             .onChanged { gesture in
                                 let newValue = gesture.location.x / (width - 30)
                                 value = min(max(newValue, 0), 1)
                             }
                     )
             }
         }
         .frame(width: width, height: 30)
     }
 }
 ```

 Example: Swipe to delete

 ```swift
 struct SwipeToDelete: View {
     @State private var offset: CGFloat = 0
     @State private var isDeleted = false

     var body: some View {
         if !isDeleted {
             HStack {
                 Text("Swipe to delete")
                     .padding()
                     .background(.white)
                     .offset(x: offset)
                     .gesture(
                         DragGesture()
                             .onChanged { value in
                                 // Only allow swiping left
                                 if value.translation.width < 0 {
                                     offset = value.translation.width
                                 }
                             }
                             .onEnded { value in
                                 if offset < -100 {
                                     // Delete threshold reached
                                     withAnimation {
                                         isDeleted = true
                                     }
                                 } else {
                                     // Snap back
                                     withAnimation(.spring()) {
                                         offset = 0
                                     }
                                 }
                             }
                     )

                 Spacer()

                 // Delete button revealed by swipe
                 Button(action: {
                     withAnimation {
                         isDeleted = true
                     }
                 }) {
                     Image(systemName: "trash")
                         .foregroundColor(.white)
                 }
                 .padding()
                 .background(.red)
             }
         }
     }
 }
 ```
 */
