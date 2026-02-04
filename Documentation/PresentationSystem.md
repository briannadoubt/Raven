# Raven Presentation System Architecture

**Version**: 1.0
**Swift Version**: 6.2
**Last Updated**: February 2026

## Overview

The Raven Presentation System is a comprehensive framework for managing modal presentations in web-based SwiftUI applications. It provides a SwiftUI-compatible API while handling the unique challenges of DOM-based rendering.

## Architecture Overview

### Component Hierarchy

```
┌─────────────────────────────────────┐
│         View Hierarchy              │
│  (User's SwiftUI Views)            │
└──────────────┬──────────────────────┘
               │
               │ Presentation Modifiers
               ▼
┌─────────────────────────────────────┐
│    Presentation Modifiers           │
│  - SheetModifier                    │
│  - AlertModifier                    │
│  - PopoverModifier                  │
│  - ConfirmationDialogModifier       │
└──────────────┬──────────────────────┘
               │
               │ Present/Dismiss
               ▼
┌─────────────────────────────────────┐
│    PresentationCoordinator          │
│  - Manages presentation stack       │
│  - Assigns z-indices                │
│  - Coordinates lifecycle            │
└──────────────┬──────────────────────┘
               │
               │ Environment
               ▼
┌─────────────────────────────────────┐
│      PresentationContext            │
│  - Environment integration          │
│  - Coordinator access               │
└─────────────────────────────────────┘
```

### Data Flow

```
User Action → State Change → Binding Update → Modifier Triggers
     ↓
PresentationCoordinator.present()
     ↓
Create PresentationEntry
     ↓
Assign z-index
     ↓
Add to stack
     ↓
Render in DOM with overlay
     ↓
User dismisses → Binding Update → Coordinator.dismiss()
     ↓
Remove from stack
     ↓
Call onDismiss callback
     ↓
Update complete
```

## Core Components

### 1. PresentationCoordinator

The central authority for managing presentations.

#### Responsibilities

- **Stack Management**: Maintains ordered list of active presentations
- **Z-Index Assignment**: Automatically calculates CSS z-index values
- **Lifecycle Management**: Handles present and dismiss operations
- **Callback Execution**: Invokes onDismiss callbacks

#### Implementation Details

```swift
@MainActor
public final class PresentationCoordinator: ObservableObject, Sendable {
    @Published public private(set) var presentations: [PresentationEntry] = []

    private let baseZIndex: Int = 1000
    private let zIndexIncrement: Int = 10

    public func present(
        type: PresentationType,
        content: AnyView,
        onDismiss: (@MainActor @Sendable () -> Void)? = nil
    ) -> UUID

    public func dismiss(_ id: UUID) -> Bool
    public func dismissAll()
}
```

#### Z-Index Strategy

- **Base Z-Index**: 1000 (above typical page content)
- **Increment**: 10 (allows manual tweaking if needed)
- **Calculation**: `baseZIndex + (presentationCount * zIndexIncrement)`
- **Result**: First presentation at 1000, second at 1010, third at 1020, etc.

This ensures:
- Presentations always layer correctly
- Adequate space between layers for debugging
- Predictable stacking behavior

### 2. PresentationType

Enum defining available presentation styles.

```swift
public enum PresentationType: Sendable, Equatable {
    case sheet
    case fullScreenCover
    case alert
    case confirmationDialog
    case popover(anchor: PopoverAttachmentAnchor, edge: Edge)
}
```

#### Design Rationale

- **Type Safety**: Each presentation type is explicitly represented
- **Associated Values**: Popover includes anchor and edge information
- **Equatable**: Enables comparison and testing
- **Sendable**: Safe for concurrent access

### 3. PresentationEntry

Represents a single presentation in the stack.

```swift
public struct PresentationEntry: Sendable, Identifiable {
    public let id: UUID
    public let type: PresentationType
    public let content: AnyView
    public let zIndex: Int
    public let onDismiss: (@MainActor @Sendable () -> Void)?
}
```

#### Properties

- **id**: Unique identifier for this presentation
- **type**: The presentation style
- **content**: Type-erased view content
- **zIndex**: CSS z-index for layering
- **onDismiss**: Optional callback on dismissal

### 4. Presentation Modifiers

View modifiers that connect SwiftUI views to the coordinator.

#### Common Pattern

```swift
struct SheetModifier<Item: Identifiable, SheetContent: View>: ViewModifier {
    @Binding var item: Item?
    @ViewBuilder let sheetContent: (Item) -> SheetContent
    let onDismiss: (@MainActor @Sendable () -> Void)?

    @Environment(\.presentationCoordinator) private var coordinator

    func body(content: Content) -> some View {
        content
            .onChange(of: item) { oldValue, newValue in
                if let item = newValue {
                    // Present sheet
                } else if oldValue != nil {
                    // Dismiss sheet
                }
            }
    }
}
```

#### Modifier Responsibilities

1. **Watch Binding**: Monitor state changes
2. **Present on Change**: Call coordinator when binding becomes non-nil/true
3. **Dismiss on Change**: Call coordinator when binding becomes nil/false
4. **Store ID**: Track presentation ID for later dismissal
5. **Execute Callback**: Call onDismiss when appropriate

### 5. PresentationContext

Environment integration for coordinator access.

```swift
public struct PresentationCoordinatorKey: EnvironmentKey {
    public static let defaultValue = PresentationCoordinator()
}

extension EnvironmentValues {
    public var presentationCoordinator: PresentationCoordinator {
        get { self[PresentationCoordinatorKey.self] }
        set { self[PresentationCoordinatorKey.self] = newValue }
    }
}
```

#### Usage

```swift
struct MyView: View {
    @Environment(\.presentationCoordinator) var coordinator

    var body: some View {
        Button("Present") {
            coordinator.present(
                type: .sheet,
                content: AnyView(Text("Content"))
            )
        }
    }
}
```

## Presentation Types in Detail

### Sheet

Slides up from bottom, can be resized with detents.

**Key Features**:
- Presentation detents (medium, large, custom)
- Drag indicator
- Corner radius customization
- Interactive dismiss control

**DOM Representation**:
```html
<div class="sheet-overlay" style="z-index: 1000">
  <div class="sheet-container">
    <div class="sheet-content">
      <!-- User's view content -->
    </div>
  </div>
</div>
```

### Full-Screen Cover

Takes over the entire screen.

**Key Features**:
- No detents (always full screen)
- No drag indicator
- Must be dismissed programmatically or with explicit UI

**DOM Representation**:
```html
<div class="fullscreen-overlay" style="z-index: 1000">
  <div class="fullscreen-container">
    <!-- User's view content -->
  </div>
</div>
```

### Alert

Modal dialog with title, message, and buttons.

**Key Features**:
- Title and optional message
- Multiple buttons with roles
- Center-screen positioning
- Blur/dim background

**DOM Representation**:
```html
<div class="alert-overlay" style="z-index: 1000">
  <div class="alert-container">
    <div class="alert-title">Title</div>
    <div class="alert-message">Message</div>
    <div class="alert-buttons">
      <!-- Button elements -->
    </div>
  </div>
</div>
```

### Confirmation Dialog

Action sheet style with multiple options.

**Key Features**:
- Title and optional message
- Multiple action buttons
- Typically slides from bottom
- Optional title visibility control

**DOM Representation**:
```html
<div class="dialog-overlay" style="z-index: 1000">
  <div class="dialog-container">
    <div class="dialog-title">Title</div>
    <div class="dialog-actions">
      <!-- Action buttons -->
    </div>
  </div>
</div>
```

### Popover

Content anchored to a view with arrow.

**Key Features**:
- Attachment anchor (point or rect)
- Arrow edge specification
- Automatic positioning
- Lightweight presentation

**DOM Representation**:
```html
<div class="popover-overlay" style="z-index: 1000">
  <div class="popover-container" style="position: absolute; top: ...; left: ...">
    <div class="popover-arrow"></div>
    <div class="popover-content">
      <!-- User's view content -->
    </div>
  </div>
</div>
```

## Presentation Modifiers

### PresentationDetent

Controls sheet height.

```swift
public enum PresentationDetent: Sendable {
    case medium
    case large
    case height(CGFloat)
    case fraction(CGFloat)
    case custom((PresentationDetentContext) -> CGFloat?)
}
```

**Implementation**:
- Modifier stores detent preferences
- Rendering system applies as CSS height/max-height
- Multiple detents allow user resizing

### InteractiveDismissDisabled

Prevents swipe-to-dismiss.

```swift
.interactiveDismissDisabled(hasUnsavedChanges)
```

**Implementation**:
- Stores boolean in modifier
- Rendering system adds/removes swipe handlers
- Useful for forms with unsaved changes

### PresentationDragIndicator

Controls drag handle visibility.

```swift
public enum Visibility: Sendable {
    case automatic
    case visible
    case hidden
}

.presentationDragIndicator(.visible)
```

### PresentationCornerRadius

Customizes sheet corner radius.

```swift
.presentationCornerRadius(20)
```

**Implementation**:
- Applied as CSS border-radius
- Only affects sheet presentations
- Default varies by platform conventions

## Environment Integration

### Propagation

Environment values propagate through presentations:

```swift
struct MyView: View {
    @State private var showSheet = false

    var body: some View {
        Text("Root")
            .environment(\.colorScheme, .dark)
            .sheet(isPresented: $showSheet) {
                // This sheet inherits .dark color scheme
                Text("Sheet")
            }
    }
}
```

### Custom Environment Values

Custom environment values work seamlessly:

```swift
struct ThemeKey: EnvironmentKey {
    static let defaultValue = Theme.light
}

extension EnvironmentValues {
    var theme: Theme {
        get { self[ThemeKey.self] }
        set { self[ThemeKey.self] = newValue }
    }
}

// Usage
rootView
    .environment(\.theme, .dark)
    .sheet(isPresented: $show) {
        // Inherits theme
        ThemedView()
    }
```

## State Management

### Local State

State within presentations is isolated:

```swift
.sheet(isPresented: $showSheet) {
    VStack {
        @State var counter = 0 // Isolated to sheet
        Text("Count: \(counter)")
        Button("Increment") { counter += 1 }
    }
}
```

### Shared State

Use @ObservableObject or @EnvironmentObject for shared state:

```swift
@MainActor
class AppState: ObservableObject {
    @Published var data: [String] = []
}

@StateObject private var state = AppState()

.sheet(isPresented: $show) {
    EditorView()
        .environmentObject(state) // Shared state
}
```

### Binding Across Boundaries

Bindings work across presentation boundaries:

```swift
@State private var text = ""

.sheet(isPresented: $show) {
    TextField("Text", text: $text) // Binds to parent's state
}
```

## Memory Management

### Presentation Cleanup

Presentations are automatically cleaned up on dismiss:

```swift
coordinator.dismiss(id)
// Removes from stack
// Releases content view
// Calls onDismiss callback
```

### View Lifecycle

```
Present → Create View → Render → User Interacts → Dismiss → Destroy View
```

Views are created lazily when presented and destroyed when dismissed.

### Avoiding Leaks

**Do:**
- Use weak references in closures if needed
- Clean up resources in onDismiss
- Use @MainActor for observable objects

**Don't:**
- Store strong references to views
- Create retain cycles in callbacks
- Hold onto dismissed presentation references

## Extension Points

### Custom Presentation Types

To add a new presentation type:

1. **Add to PresentationType enum**:
```swift
public enum PresentationType: Sendable, Equatable {
    // Existing cases...
    case myCustomPresentation(config: CustomConfig)
}
```

2. **Create modifier**:
```swift
struct CustomPresentationModifier<Content: View>: ViewModifier {
    @Binding var isPresented: Bool
    let content: Content

    @Environment(\.presentationCoordinator) var coordinator

    func body(content: Content) -> some View {
        content.onChange(of: isPresented) { _, newValue in
            if newValue {
                coordinator.present(
                    type: .myCustomPresentation(config: ...),
                    content: AnyView(self.content)
                )
            }
        }
    }
}
```

3. **Add View extension**:
```swift
extension View {
    func customPresentation(
        isPresented: Binding<Bool>,
        @ViewBuilder content: () -> Content
    ) -> some View {
        modifier(CustomPresentationModifier(
            isPresented: isPresented,
            content: content()
        ))
    }
}
```

### Custom Detents

Create reusable custom detents:

```swift
extension PresentationDetent {
    static let compact = custom { context in
        min(context.maxDetentValue * 0.3, 300)
    }

    static let extraLarge = custom { context in
        context.maxDetentValue * 0.95
    }
}

// Usage
.presentationDetents([.compact, .medium, .extraLarge])
```

### Custom Transitions

Implement custom presentation transitions:

```swift
// Define transition style
enum PresentationTransition {
    case slide
    case fade
    case scale
}

// Add to modifier
struct SheetModifier {
    let transition: PresentationTransition

    // Apply transition classes/animations
}
```

## Best Practices

### 1. Use Appropriate Presentation Type

- **Sheet**: Editing, forms, multi-step flows
- **Full-Screen Cover**: Immersive experiences, onboarding
- **Alert**: Simple confirmations, errors, warnings
- **Confirmation Dialog**: Multiple action choices
- **Popover**: Contextual info, lightweight options

### 2. Limit Nesting Depth

Maximum recommended: 3 levels deep
- Better UX (easier to understand context)
- Better performance (fewer DOM layers)
- Easier to manage state

### 3. Clean Up Resources

Always use onDismiss for cleanup:

```swift
.sheet(isPresented: $show) {
    CameraView()
} onDismiss: {
    camera.stop()
    releaseResources()
}
```

### 4. Handle State Consistently

Choose the right state management:
- **@State**: View-local state
- **@Binding**: Parent-child communication
- **@ObservableObject**: Shared mutable state
- **@EnvironmentObject**: App-wide state

### 5. Test Presentations

Write tests for:
- Present/dismiss cycles
- Nested presentations
- State updates
- Memory cleanup

```swift
@Test("Sheet lifecycle")
func testSheetLifecycle() {
    let coordinator = PresentationCoordinator()
    let id = coordinator.present(type: .sheet, content: AnyView(Text("Test")))
    #expect(coordinator.count == 1)
    coordinator.dismiss(id)
    #expect(coordinator.count == 0)
}
```

### 6. Document Complex Flows

For multi-step presentations, document the flow:

```swift
/// Multi-step checkout flow:
/// 1. Cart Review (sheet)
/// 2. Shipping Info (sheet)
/// 3. Payment (sheet)
/// 4. Confirmation (alert)
```

## Performance Optimization

### 1. Lazy View Creation

Views are created only when presented:

```swift
.sheet(isPresented: $show) {
    ExpensiveView() // Created only when show = true
}
```

### 2. Minimize Re-renders

Use @Binding instead of @ObservedObject when possible:

```swift
// Less efficient
struct SheetView: View {
    @ObservedObject var model: Model
}

// More efficient
struct SheetView: View {
    @Binding var value: String
}
```

### 3. Batch Dismissals

Use dismissAll() for multiple presentations:

```swift
coordinator.dismissAll() // More efficient than multiple dismiss() calls
```

### 4. Avoid Heavy Views in Presentations

Keep presentation content lightweight:

```swift
// Good
.sheet(isPresented: $show) {
    SimpleFormView()
}

// Avoid
.sheet(isPresented: $show) {
    HeavyListView(items: thousandsOfItems)
}
```

## Debugging

### Log Presentation Events

```swift
coordinator.present(type: .sheet, content: content)
print("Presented sheet, stack depth: \(coordinator.count)")

coordinator.dismiss(id)
print("Dismissed, remaining: \(coordinator.count)")
```

### Inspect Presentation Stack

```swift
for (index, presentation) in coordinator.presentations.enumerated() {
    print("[\(index)] Type: \(presentation.type), Z-Index: \(presentation.zIndex)")
}
```

### Verify Z-Indices

```swift
let zIndices = coordinator.presentations.map { $0.zIndex }
print("Z-indices: \(zIndices)")
// Should be monotonically increasing
```

### Test Cleanup

```swift
// Present many
for _ in 0..<10 {
    coordinator.present(type: .sheet, content: AnyView(Text("Test")))
}

// Dismiss all
coordinator.dismissAll()

// Verify cleanup
#expect(coordinator.presentations.isEmpty)
```

## Thread Safety

All coordinator operations must be on the main actor:

```swift
@MainActor
func presentSheet() {
    coordinator.present(/* ... */)
}
```

The `@MainActor` annotation ensures:
- UI updates are on main thread
- State changes are serialized
- No race conditions

## Future Enhancements

Potential additions to the presentation system:

1. **Custom Transitions**: Define custom animation styles
2. **Presentation Context Menu**: Right-click presentations
3. **Drawer**: Side-sliding panels
4. **Toast/Notification**: Non-modal notifications
5. **Bottom Sheet Gestures**: Velocity-based dismiss
6. **Accessibility**: Enhanced VoiceOver support
7. **Analytics**: Built-in presentation tracking
8. **Persistence**: Save/restore presentation state

## Summary

The Raven Presentation System provides:

- ✅ **Complete API Coverage**: All SwiftUI presentation types
- ✅ **Proper Layering**: Automatic z-index management
- ✅ **State Management**: Full binding support
- ✅ **Environment Integration**: Seamless value propagation
- ✅ **Memory Safety**: Automatic cleanup
- ✅ **Concurrency Safe**: Swift 6.2 strict isolation
- ✅ **Extensible**: Easy to add custom types
- ✅ **Well-Tested**: Comprehensive test coverage

The architecture is production-ready and provides a solid foundation for modal presentations in Raven applications.
