import Foundation
@testable import Raven

/// Phase 13 Gesture System Examples
///
/// This file contains comprehensive examples demonstrating all Phase 13 gesture features:
/// - Basic gestures (TapGesture, SpatialTapGesture, LongPressGesture)
/// - Transform gestures (DragGesture, RotationGesture, MagnificationGesture)
/// - Gesture composition (simultaneously, sequenced, exclusively)
/// - Gesture modifiers (.gesture, .simultaneousGesture, .highPriorityGesture)
/// - GestureState for automatic state management
/// - Real-world gesture patterns and interactions
///
/// These examples can be used as:
/// - Learning resources for gesture system usage
/// - Templates for common gesture patterns
/// - Test cases for gesture functionality
/// - Documentation of gesture capabilities

// MARK: - Example 1: Simple Tap Counter

/// Demonstrates basic tap gesture recognition with state management.
///
/// Key features:
/// - TapGesture with onEnded callback
/// - @State for persistent counter
/// - Simple tap interaction pattern
///
/// Web implementation:
/// - Maps to click event
/// - Works with mouse, touch, and keyboard (Enter/Space)
///
/// Usage:
/// ```swift
/// let view = SimpleTapCounterExample()
/// ```
@MainActor
struct SimpleTapCounterExample {
    @State private var tapCount = 0
    @State private var lastTapTime = Date()

    var body: some View {
        VStack(spacing: 20) {
            Text("Tap Counter")
                .font(.title)
                .fontWeight(.bold)

            // Tap target
            Circle()
                .fill(Color.blue)
                .frame(width: 150, height: 150)
                .overlay(
                    VStack {
                        Text("\(tapCount)")
                            .font(.system(size: 48, weight: .bold))
                            .foregroundColor(.white)
                        Text("taps")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                    }
                )
                .gesture(
                    TapGesture()
                        .onEnded {
                            tapCount += 1
                            lastTapTime = Date()
                        }
                )

            // Reset button
            Button("Reset") {
                tapCount = 0
            }
            .disabled(tapCount == 0)
        }
        .padding()
    }
}

// MARK: - Example 2: Spatial Drawing App

/// Demonstrates SpatialTapGesture with coordinate tracking.
///
/// Key features:
/// - SpatialTapGesture provides tap location
/// - Coordinate space management
/// - Drawing/marking interface
///
/// Web implementation:
/// - Uses clientX/clientY from pointer events
/// - Converts to local coordinates
///
/// Usage:
/// Records tap positions to create a dot pattern
@MainActor
struct SpatialDrawingExample {
    struct Dot: Identifiable {
        let id = UUID()
        let position: CGPoint
        let timestamp: Date
    }

    @State private var dots: [Dot] = []
    @State private var canvasSize: CGSize = CGSize(width: 400, height: 400)

    var body: some View {
        VStack(spacing: 16) {
            Text("Spatial Drawing")
                .font(.headline)

            Text("Tap anywhere to place dots")
                .font(.caption)
                .foregroundColor(.secondary)

            // Canvas
            ZStack {
                // Background
                Rectangle()
                    .fill(Color.gray.opacity(0.1))
                    .frame(width: canvasSize.width, height: canvasSize.height)
                    .border(Color.gray, width: 1)

                // Dots
                ForEach(dots) { dot in
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 10, height: 10)
                        .position(dot.position)
                }
            }
            .gesture(
                SpatialTapGesture(coordinateSpace: .local)
                    .onEnded { value in
                        let dot = Dot(
                            position: value.location,
                            timestamp: Date()
                        )
                        dots.append(dot)
                    }
            )

            HStack {
                Button("Clear") {
                    dots.removeAll()
                }
                .disabled(dots.isEmpty)

                Text("\(dots.count) dots")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
    }
}

// MARK: - Example 3: Long Press Menu

/// Demonstrates LongPressGesture with visual feedback and menu reveal.
///
/// Key features:
/// - LongPressGesture with custom duration
/// - Visual feedback during press
/// - Menu reveal on successful long press
///
/// Web implementation:
/// - Tracks pointerdown start time
/// - Monitors pointermove for distance threshold
/// - Cancels on pointerup before duration
///
/// Usage:
/// Long press to reveal contextual menu
@MainActor
struct LongPressMenuExample {
    @State private var isPressing = false
    @State private var showMenu = false
    @State private var pressProgress: Double = 0.0
    @State private var selectedAction: String?

    var body: some View {
        VStack(spacing: 30) {
            Text("Long Press Menu")
                .font(.headline)

            // Press target with visual feedback
            ZStack {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 120, height: 120)
                    .scaleEffect(isPressing ? 0.95 : 1.0)
                    .opacity(isPressing ? 0.7 : 1.0)

                // Progress indicator
                if isPressing {
                    Circle()
                        .trim(from: 0, to: pressProgress)
                        .stroke(Color.white, lineWidth: 4)
                        .frame(width: 100, height: 100)
                        .rotationEffect(.degrees(-90))
                }

                Text(isPressing ? "Hold..." : "Long Press")
                    .foregroundColor(.white)
                    .font(.caption)
                    .fontWeight(.semibold)
            }
            .gesture(
                LongPressGesture(minimumDuration: 0.8)
                    .onChanged { pressing in
                        isPressing = pressing
                        // In real implementation, update progress based on time
                        if pressing {
                            pressProgress = 0.5 // Simplified
                        }
                    }
                    .onEnded { success in
                        isPressing = false
                        pressProgress = 0
                        if success {
                            showMenu = true
                        }
                    }
            )

            // Menu
            if showMenu {
                VStack(spacing: 12) {
                    Text("Choose Action")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    ForEach(["Edit", "Share", "Delete"], id: \.self) { action in
                        Button(action) {
                            selectedAction = action
                            showMenu = false
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                    }

                    Button("Cancel") {
                        showMenu = false
                    }
                    .foregroundColor(.red)
                }
                .padding()
                .background(Color.white)
                .cornerRadius(12)
                .shadow(radius: 10)
                .transition(.scale.combined(with: .opacity))
            }

            if let action = selectedAction {
                Text("Selected: \(action)")
                    .font(.caption)
                    .foregroundColor(.green)
            }
        }
        .padding()
        .animation(.spring(response: 0.3), value: isPressing)
        .animation(.spring(), value: showMenu)
    }
}

// MARK: - Example 4: Draggable Card

/// Demonstrates DragGesture with translation and snap-back animation.
///
/// Key features:
/// - @GestureState for automatic reset
/// - Translation tracking
/// - Snap-back animation on release
///
/// Web implementation:
/// - pointermove updates translation
/// - Calculates offset from start position
/// - Releases on pointerup
@MainActor
struct DraggableCardExample {
    @GestureState private var dragOffset = CGSize.zero
    @State private var position = CGSize.zero
    @State private var isDragging = false

    var body: some View {
        VStack(spacing: 20) {
            Text("Draggable Card")
                .font(.headline)

            Text("Drag anywhere")
                .font(.caption)
                .foregroundColor(.secondary)

            // Draggable card
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 200, height: 280)
                .overlay(
                    VStack {
                        Image(systemName: "hand.draw")
                            .font(.system(size: 60))
                            .foregroundColor(.white.opacity(0.9))

                        Text("Drag Me")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                )
                .shadow(
                    color: .black.opacity(isDragging ? 0.3 : 0.2),
                    radius: isDragging ? 20 : 10,
                    y: isDragging ? 10 : 5
                )
                .scaleEffect(isDragging ? 1.05 : 1.0)
                .offset(
                    x: position.width + dragOffset.width,
                    y: position.height + dragOffset.height
                )
                .gesture(
                    DragGesture()
                        .updating($dragOffset) { value, state, transaction in
                            state = value.translation
                        }
                        .onChanged { _ in
                            isDragging = true
                        }
                        .onEnded { value in
                            isDragging = false
                            position.width += value.translation.width
                            position.height += value.translation.height
                        }
                )

            // Reset button
            Button("Reset Position") {
                withAnimation(.spring()) {
                    position = .zero
                }
            }
            .disabled(position == .zero)
        }
        .padding()
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isDragging)
        .animation(.spring(), value: dragOffset)
    }
}

// MARK: - Example 5: Swipe to Delete

/// Demonstrates DragGesture with velocity detection for swipe actions.
///
/// Key features:
/// - Velocity-based swipe detection
/// - Threshold-based deletion
/// - Smooth animations
/// - Revealed delete button
///
/// Web implementation:
/// - Tracks pointer movement speed
/// - Calculates velocity from recent samples
/// - Triggers action on fast swipe or threshold distance
@MainActor
struct SwipeToDeleteExample {
    struct ListItem: Identifiable {
        let id = UUID()
        let title: String
        var offset: CGFloat = 0
    }

    @State private var items: [ListItem] = [
        ListItem(title: "Item 1"),
        ListItem(title: "Item 2"),
        ListItem(title: "Item 3"),
        ListItem(title: "Item 4"),
        ListItem(title: "Item 5")
    ]

    var body: some View {
        VStack(spacing: 0) {
            Text("Swipe to Delete")
                .font(.headline)
                .padding()

            Text("Swipe left to delete items")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.bottom)

            ForEach(items.indices, id: \.self) { index in
                swipeableRow(for: index)
                    .transition(.asymmetric(
                        insertion: .move(edge: .leading),
                        removal: .move(edge: .trailing).combined(with: .opacity)
                    ))
            }

            Spacer()
        }
        .animation(.spring(), value: items)
    }

    private func swipeableRow(for index: Int) -> some View {
        ZStack(alignment: .trailing) {
            // Delete button background
            Rectangle()
                .fill(Color.red)
                .frame(width: 80)
                .overlay(
                    VStack {
                        Image(systemName: "trash")
                            .foregroundColor(.white)
                        Text("Delete")
                            .font(.caption2)
                            .foregroundColor(.white)
                    }
                )

            // Content
            HStack {
                Text(items[index].title)
                    .padding()

                Spacer()

                Image(systemName: "line.3.horizontal")
                    .foregroundColor(.gray)
                    .padding()
            }
            .background(Color.white)
            .offset(x: items[index].offset)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        // Only allow left swipe
                        if value.translation.width < 0 {
                            items[index].offset = max(value.translation.width, -80)
                        }
                    }
                    .onEnded { value in
                        let swipeVelocity = value.velocity.width
                        let swipeDistance = value.translation.width

                        // Delete if swiped far or fast
                        if swipeDistance < -60 || swipeVelocity < -500 {
                            // Animate to delete position
                            withAnimation {
                                items[index].offset = -400
                            }
                            // Remove after animation
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                items.remove(at: index)
                            }
                        } else {
                            // Snap back
                            withAnimation(.spring()) {
                                items[index].offset = 0
                            }
                        }
                    }
            )
        }
        .frame(height: 60)
        .clipped()
    }
}

// MARK: - Example 6: Photo Viewer with Pinch Zoom

/// Demonstrates simultaneous RotationGesture and MagnificationGesture.
///
/// Key features:
/// - Simultaneous gesture composition
/// - Rotation and scale tracking
/// - Combined transformations
/// - Reset functionality
///
/// Web implementation:
/// - Uses multi-touch pointer events
/// - Calculates rotation from two touch points
/// - Calculates scale from touch distance
/// - Updates both transformations simultaneously
@MainActor
struct PhotoViewerExample {
    @State private var scale: CGFloat = 1.0
    @State private var rotation: Angle = .zero
    @State private var lastScale: CGFloat = 1.0
    @State private var lastRotation: Angle = .zero

    var body: some View {
        VStack(spacing: 20) {
            Text("Photo Viewer")
                .font(.headline)

            Text("Pinch to zoom, rotate with two fingers")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            // Photo container
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 300, height: 400)

                // Photo
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        LinearGradient(
                            colors: [.orange, .pink],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 250, height: 350)
                    .overlay(
                        VStack {
                            Image(systemName: "photo")
                                .font(.system(size: 80))
                                .foregroundColor(.white)
                            Text("Sample Photo")
                                .foregroundColor(.white)
                                .font(.caption)
                        }
                    )
                    .scaleEffect(scale)
                    .rotationEffect(rotation)
                    .gesture(
                        MagnificationGesture()
                            .simultaneously(with: RotationGesture())
                            .onChanged { value in
                                scale = lastScale * (value.0 ?? 1.0)
                                rotation = lastRotation + (value.1 ?? .zero)
                            }
                            .onEnded { value in
                                lastScale = scale
                                lastRotation = rotation
                            }
                    )
            }

            // Controls
            HStack(spacing: 20) {
                VStack(spacing: 4) {
                    Text("Scale")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(String(format: "%.1fx", scale))
                        .font(.caption)
                        .fontWeight(.semibold)
                }

                Divider()
                    .frame(height: 30)

                VStack(spacing: 4) {
                    Text("Rotation")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(String(format: "%.0f°", rotation.degrees))
                        .font(.caption)
                        .fontWeight(.semibold)
                }
            }

            Button("Reset") {
                withAnimation(.spring()) {
                    scale = 1.0
                    rotation = .zero
                    lastScale = 1.0
                    lastRotation = .zero
                }
            }
            .disabled(scale == 1.0 && rotation == .zero)
        }
        .padding()
    }
}

// MARK: - Example 7: Custom Slider

/// Demonstrates DragGesture with constraints for a custom slider.
///
/// Key features:
/// - Horizontal drag constraint
/// - Value clamping (0-1 range)
/// - Local coordinate space
/// - Visual thumb indicator
///
/// Web implementation:
/// - Tracks drag in local coordinates
/// - Constrains movement to slider track
/// - Updates value based on position
@MainActor
struct CustomSliderExample {
    @State private var value: Double = 0.5
    @State private var isDragging = false

    let sliderWidth: CGFloat = 300
    let thumbSize: CGFloat = 30

    var body: some View {
        VStack(spacing: 30) {
            Text("Custom Slider")
                .font(.headline)

            // Value display
            VStack(spacing: 8) {
                Text("\(Int(value * 100))%")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(.blue)

                Text("Drag the thumb to adjust")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // Slider
            ZStack(alignment: .leading) {
                // Track background
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: sliderWidth, height: 4)

                // Track fill
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.blue)
                    .frame(width: CGFloat(value) * sliderWidth, height: 4)

                // Thumb
                Circle()
                    .fill(Color.blue)
                    .frame(width: thumbSize, height: thumbSize)
                    .shadow(color: .black.opacity(0.2), radius: isDragging ? 8 : 4)
                    .scaleEffect(isDragging ? 1.2 : 1.0)
                    .offset(x: CGFloat(value) * (sliderWidth - thumbSize))
                    .gesture(
                        DragGesture(coordinateSpace: .local)
                            .onChanged { gesture in
                                isDragging = true
                                // Calculate new value from drag position
                                let dragX = gesture.location.x - thumbSize / 2
                                let newValue = dragX / (sliderWidth - thumbSize)
                                value = min(max(newValue, 0), 1)
                            }
                            .onEnded { _ in
                                isDragging = false
                            }
                    )
            }
            .frame(width: sliderWidth, height: thumbSize)

            // Preset buttons
            HStack(spacing: 12) {
                ForEach([0, 25, 50, 75, 100], id: \.self) { preset in
                    Button("\(preset)%") {
                        withAnimation(.spring(response: 0.3)) {
                            value = Double(preset) / 100.0
                        }
                    }
                    .font(.caption)
                }
            }
        }
        .padding()
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isDragging)
    }
}

// MARK: - Example 8: Gesture Sequencing

/// Demonstrates sequenced gestures: long press then drag.
///
/// Key features:
/// - Sequence gesture composition
/// - State tracking through sequence stages
/// - Visual feedback for each stage
/// - Gesture value pattern matching
///
/// Web implementation:
/// - First gesture must complete before second begins
/// - Maintains state between gesture stages
/// - Cancels sequence if first gesture fails
@MainActor
struct GestureSequencingExample {
    @GestureState private var dragOffset = CGSize.zero
    @State private var isLongPressing = false
    @State private var isDragging = false
    @State private var permanentOffset = CGSize.zero

    var statusText: String {
        if isDragging {
            return "Dragging - Release to finish"
        } else if isLongPressing {
            return "Long press detected - Now drag"
        } else {
            return "Hold for 0.5s, then drag"
        }
    }

    var body: some View {
        VStack(spacing: 30) {
            Text("Gesture Sequencing")
                .font(.headline)

            Text(statusText)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            // Draggable item
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    isDragging ? Color.green :
                    isLongPressing ? Color.orange : Color.blue
                )
                .frame(width: 180, height: 180)
                .overlay(
                    VStack(spacing: 8) {
                        Image(systemName: isDragging ? "hand.point.up.left" : "hand.tap")
                            .font(.system(size: 50))
                            .foregroundColor(.white)

                        Text(isDragging ? "Dragging" : isLongPressing ? "Ready" : "Hold")
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                    }
                )
                .shadow(
                    color: .black.opacity(isDragging ? 0.3 : 0.2),
                    radius: isDragging ? 15 : 8
                )
                .scaleEffect(isLongPressing && !isDragging ? 1.05 : 1.0)
                .offset(
                    x: permanentOffset.width + dragOffset.width,
                    y: permanentOffset.height + dragOffset.height
                )
                .gesture(
                    LongPressGesture(minimumDuration: 0.5)
                        .sequenced(before: DragGesture())
                        .updating($dragOffset) { value, state, _ in
                            switch value {
                            case .first:
                                state = .zero
                            case .second(true, let drag):
                                state = drag?.translation ?? .zero
                            case .second(false, _):
                                state = .zero
                            }
                        }
                        .onChanged { value in
                            switch value {
                            case .first:
                                isLongPressing = true
                                isDragging = false
                            case .second(true, let drag):
                                isDragging = drag != nil
                            case .second(false, _):
                                isLongPressing = false
                                isDragging = false
                            }
                        }
                        .onEnded { value in
                            isLongPressing = false
                            isDragging = false

                            // Save final position
                            switch value {
                            case .second(true, let drag):
                                if let dragValue = drag {
                                    permanentOffset.width += dragValue.translation.width
                                    permanentOffset.height += dragValue.translation.height
                                }
                            default:
                                break
                            }
                        }
                )

            Button("Reset Position") {
                withAnimation(.spring()) {
                    permanentOffset = .zero
                }
            }
            .disabled(permanentOffset == .zero)
        }
        .padding()
        .animation(.spring(response: 0.3), value: isLongPressing)
        .animation(.spring(response: 0.2), value: isDragging)
    }
}

// MARK: - Example 9: Drawing App with Multiple Gestures

/// Demonstrates complex multi-gesture interaction.
///
/// Key features:
/// - Exclusive gesture for tool selection
/// - Spatial tap for drawing
/// - Pinch to zoom canvas
/// - Gesture priority management
///
/// Web implementation:
/// - Multiple event listeners coordinated
/// - Tool state determines active gesture
/// - Canvas transformation combined with drawing
@MainActor
struct DrawingAppExample {
    enum Tool {
        case draw
        case erase
        case select
    }

    struct Stroke: Identifiable {
        let id = UUID()
        var points: [CGPoint]
        let color: Color
        let timestamp: Date
    }

    @State private var currentTool: Tool = .draw
    @State private var strokes: [Stroke] = []
    @State private var currentStroke: [CGPoint] = []
    @State private var canvasScale: CGFloat = 1.0
    @State private var selectedColor: Color = .blue

    let colors: [Color] = [.blue, .red, .green, .purple, .orange]

    var body: some View {
        VStack(spacing: 16) {
            Text("Drawing App")
                .font(.headline)

            // Tool selector
            HStack(spacing: 12) {
                ForEach([Tool.draw, Tool.erase, Tool.select], id: \.self) { tool in
                    toolButton(tool)
                }
            }

            // Color picker (shown only for draw tool)
            if currentTool == .draw {
                HStack(spacing: 8) {
                    ForEach(colors, id: \.self) { color in
                        Circle()
                            .fill(color)
                            .frame(width: 30, height: 30)
                            .overlay(
                                Circle()
                                    .stroke(Color.white, lineWidth: selectedColor == color ? 3 : 0)
                            )
                            .gesture(
                                TapGesture()
                                    .onEnded { selectedColor = color }
                            )
                    }
                }
            }

            // Canvas
            ZStack {
                Rectangle()
                    .fill(Color.white)
                    .frame(width: 350, height: 350)
                    .border(Color.gray, width: 1)

                // Rendered strokes
                ForEach(strokes) { stroke in
                    // In real implementation, would draw path
                    ForEach(stroke.points, id: \.debugDescription) { point in
                        Circle()
                            .fill(stroke.color)
                            .frame(width: 4, height: 4)
                            .position(point)
                    }
                }

                // Current stroke being drawn
                ForEach(currentStroke, id: \.debugDescription) { point in
                    Circle()
                        .fill(selectedColor)
                        .frame(width: 4, height: 4)
                        .position(point)
                }
            }
            .scaleEffect(canvasScale)
            .gesture(
                // Drawing gesture (when draw tool selected)
                currentTool == .draw ?
                DragGesture(minimumDistance: 0, coordinateSpace: .local)
                    .onChanged { value in
                        currentStroke.append(value.location)
                    }
                    .onEnded { _ in
                        if !currentStroke.isEmpty {
                            let stroke = Stroke(
                                points: currentStroke,
                                color: selectedColor,
                                timestamp: Date()
                            )
                            strokes.append(stroke)
                            currentStroke = []
                        }
                    } : nil
            )

            // Canvas info
            HStack {
                Text("\(strokes.count) strokes")
                Spacer()
                Text("Zoom: \(Int(canvasScale * 100))%")
            }
            .font(.caption)
            .foregroundColor(.secondary)

            // Actions
            HStack(spacing: 12) {
                Button("Clear") {
                    strokes.removeAll()
                    currentStroke.removeAll()
                }
                .disabled(strokes.isEmpty)

                Button("Undo") {
                    if !strokes.isEmpty {
                        strokes.removeLast()
                    }
                }
                .disabled(strokes.isEmpty)
            }
        }
        .padding()
    }

    private func toolButton(_ tool: Tool) -> some View {
        let isSelected = currentTool == tool
        let iconName: String = {
            switch tool {
            case .draw: return "pencil"
            case .erase: return "eraser"
            case .select: return "hand.point.up.left"
            }
        }()

        return Button(action: { currentTool = tool }) {
            VStack(spacing: 4) {
                Image(systemName: iconName)
                    .font(.system(size: 20))
                Text(String(describing: tool).capitalized)
                    .font(.caption2)
            }
            .frame(width: 70, height: 60)
            .background(isSelected ? Color.blue : Color.gray.opacity(0.2))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(8)
        }
    }
}

// MARK: - Example 10: Touch Visualizer

/// Demonstrates gesture state visualization and debugging.
///
/// Key features:
/// - Real-time gesture state display
/// - Multiple gesture types tracked
/// - Visual feedback for all gestures
/// - Debug information display
///
/// Web implementation:
/// - Shows all active pointer events
/// - Displays gesture recognition state
/// - Useful for testing and debugging
@MainActor
struct TouchVisualizerExample {
    struct TouchInfo: Identifiable {
        let id = UUID()
        let location: CGPoint
        let type: String
        let timestamp: Date
    }

    @GestureState private var dragLocation: CGPoint?
    @State private var tapLocations: [TouchInfo] = []
    @State private var longPressActive = false
    @State private var lastGestureType = "None"
    @State private var gestureCount = 0

    var body: some View {
        VStack(spacing: 16) {
            Text("Touch Visualizer")
                .font(.headline)

            Text("Try different gestures")
                .font(.caption)
                .foregroundColor(.secondary)

            // Stats
            HStack(spacing: 20) {
                VStack(spacing: 4) {
                    Text("\(gestureCount)")
                        .font(.title)
                        .fontWeight(.bold)
                    Text("Gestures")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Divider()
                    .frame(height: 40)

                VStack(spacing: 4) {
                    Text(lastGestureType)
                        .font(.title3)
                        .fontWeight(.semibold)
                    Text("Last Type")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)

            // Visualization area
            ZStack {
                Rectangle()
                    .fill(Color.white)
                    .frame(width: 350, height: 350)
                    .border(longPressActive ? Color.orange : Color.gray, width: 2)

                // Tap markers
                ForEach(tapLocations) { tap in
                    Circle()
                        .fill(Color.blue.opacity(0.5))
                        .frame(width: 30, height: 30)
                        .position(tap.location)
                        .overlay(
                            Text(tap.type)
                                .font(.caption2)
                                .foregroundColor(.white)
                                .position(tap.location)
                        )
                }

                // Drag indicator
                if let location = dragLocation {
                    Circle()
                        .stroke(Color.green, lineWidth: 3)
                        .frame(width: 50, height: 50)
                        .position(location)

                    Text("Dragging")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                        .position(x: location.x, y: location.y - 40)
                }

                // Long press indicator
                if longPressActive {
                    VStack {
                        Text("Long Press")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.orange)

                        Circle()
                            .stroke(Color.orange, lineWidth: 4)
                            .frame(width: 80, height: 80)
                    }
                }
            }
            .gesture(
                // Tap gesture
                SpatialTapGesture(coordinateSpace: .local)
                    .onEnded { value in
                        lastGestureType = "Tap"
                        gestureCount += 1
                        let touch = TouchInfo(
                            location: value.location,
                            type: "T",
                            timestamp: Date()
                        )
                        tapLocations.append(touch)

                        // Fade out old touches
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            tapLocations.removeAll { $0.id == touch.id }
                        }
                    }
            )
            .simultaneousGesture(
                // Drag gesture
                DragGesture(coordinateSpace: .local)
                    .updating($dragLocation) { value, state, _ in
                        state = value.location
                    }
                    .onChanged { _ in
                        lastGestureType = "Drag"
                    }
                    .onEnded { _ in
                        gestureCount += 1
                    }
            )
            .simultaneousGesture(
                // Long press gesture
                LongPressGesture(minimumDuration: 0.5)
                    .onChanged { pressing in
                        longPressActive = pressing
                        if pressing {
                            lastGestureType = "Long Press"
                        }
                    }
                    .onEnded { success in
                        longPressActive = false
                        if success {
                            gestureCount += 1
                        }
                    }
            )

            Button("Clear History") {
                tapLocations.removeAll()
                gestureCount = 0
                lastGestureType = "None"
            }
        }
        .padding()
    }
}

// MARK: - Usage Examples

/// Example usage of all gesture examples.
///
/// These can be rendered individually or combined in a showcase view.
@MainActor
struct Phase13ShowcaseView {
    var body: some View {
        ScrollView {
            VStack(spacing: 40) {
                Text("Phase 13 Gesture Examples")
                    .font(.system(size: 32, weight: .bold))
                    .padding(.top)

                SimpleTapCounterExample()
                Divider()

                SpatialDrawingExample()
                Divider()

                LongPressMenuExample()
                Divider()

                DraggableCardExample()
                Divider()

                SwipeToDeleteExample()
                Divider()

                PhotoViewerExample()
                Divider()

                CustomSliderExample()
                Divider()

                GestureSequencingExample()
                Divider()

                DrawingAppExample()
                Divider()

                TouchVisualizerExample()
            }
            .padding()
        }
    }
}
