# Phase 14: Complete Presentation System

**Status**: Complete
**Swift Version**: 6.2
**Date**: February 2026

## Overview

Phase 14 implements a complete presentation system for Raven, providing SwiftUI-compatible APIs for sheets, full-screen covers, alerts, confirmation dialogs, and popovers. The implementation includes full support for presentation modifiers, detents, and interactive dismiss control.

## Complete API Reference

### Sheet Presentations

#### Basic Sheet with Binding

```swift
.sheet(isPresented: $showSheet) {
    Text("Sheet Content")
}
```

**Parameters:**
- `isPresented`: `Binding<Bool>` - Controls sheet visibility
- `content`: `@ViewBuilder () -> Content` - The view to present

#### Sheet with onDismiss

```swift
.sheet(isPresented: $showSheet) {
    Text("Sheet Content")
} onDismiss: {
    print("Sheet dismissed")
}
```

**Parameters:**
- `isPresented`: `Binding<Bool>` - Controls sheet visibility
- `content`: `@ViewBuilder () -> Content` - The view to present
- `onDismiss`: `@MainActor @Sendable () -> Void` - Called when dismissed

#### Item-Based Sheet

```swift
struct Item: Identifiable {
    let id = UUID()
    let name: String
}

@State private var item: Item?

.sheet(item: $item) { item in
    Text(item.name)
}
```

**Parameters:**
- `item`: `Binding<Item?>` - Optional identifiable item
- `content`: `@ViewBuilder (Item) -> Content` - Builds view from item

#### Item-Based Sheet with onDismiss

```swift
.sheet(item: $item) { item in
    Text(item.name)
} onDismiss: {
    print("Dismissed")
}
```

### Full-Screen Covers

Full-screen covers use the same API patterns as sheets but present content modally over the entire screen.

```swift
.fullScreenCover(isPresented: $showCover) {
    Text("Full Screen Content")
}

.fullScreenCover(isPresented: $showCover) {
    Text("Full Screen Content")
} onDismiss: {
    print("Dismissed")
}

.fullScreenCover(item: $item) { item in
    Text(item.name)
}
```

### Alerts

#### Basic Alert

```swift
.alert("Title", isPresented: $showAlert) {
    Button("OK") {}
}
```

**Parameters:**
- `title`: `String` or `Text` - Alert title
- `isPresented`: `Binding<Bool>` - Controls alert visibility
- `actions`: `@ViewBuilder () -> Content` - Alert buttons

#### Alert with Message

```swift
.alert("Title", isPresented: $showAlert) {
    Button("OK") {}
} message: {
    Text("This is the alert message")
}
```

**Parameters:**
- `message`: `@ViewBuilder () -> Content` - Alert message content

#### Alert with Button Roles

```swift
.alert("Delete?", isPresented: $showAlert) {
    Button("Delete", role: .destructive) {
        // Delete action
    }
    Button("Cancel", role: .cancel) {}
}
```

**Button Roles:**
- `.cancel` - Cancel action (default style)
- `.destructive` - Destructive action (red/warning style)
- `nil` - Default action

#### Item-Based Alert

```swift
struct AlertError: Identifiable {
    let id = UUID()
    let message: String
}

@State private var error: AlertError?

.alert(item: $error) { error in
    Alert(
        title: Text("Error"),
        message: Text(error.message),
        buttons: [.default(Text("OK"))]
    )
}
```

### Confirmation Dialogs

Confirmation dialogs present action sheets with multiple options.

#### Basic Confirmation Dialog

```swift
.confirmationDialog("Choose", isPresented: $showDialog) {
    Button("Option 1") {}
    Button("Option 2") {}
    Button("Cancel", role: .cancel) {}
}
```

**Parameters:**
- `title`: `String` or `Text` - Dialog title
- `isPresented`: `Binding<Bool>` - Controls dialog visibility
- `actions`: `@ViewBuilder () -> Content` - Action buttons

#### Confirmation Dialog with Message

```swift
.confirmationDialog("Choose", isPresented: $showDialog) {
    Button("Option 1") {}
    Button("Option 2") {}
} message: {
    Text("Choose one of the following options")
}
```

#### Confirmation Dialog with Title Visibility

```swift
.confirmationDialog(
    "Title",
    isPresented: $showDialog,
    titleVisibility: .hidden
) {
    Button("Action") {}
}
```

**Title Visibility:**
- `.automatic` - System default
- `.visible` - Always show title
- `.hidden` - Hide title

#### Item-Based Confirmation Dialog

```swift
.confirmationDialog("Actions", item: $selectedItem) { item in
    Button("Edit \(item.name)") {}
    Button("Delete", role: .destructive) {}
    Button("Cancel", role: .cancel) {}
}
```

### Popovers

Popovers present content anchored to a view with an arrow.

#### Basic Popover

```swift
.popover(isPresented: $showPopover) {
    Text("Popover Content")
        .padding()
}
```

#### Popover with Attachment Anchor

```swift
.popover(
    isPresented: $showPopover,
    attachmentAnchor: .point(.topLeading)
) {
    Text("Popover")
}
```

**Attachment Anchors:**
- `.point(UnitPoint)` - Attach to a specific point
  - `.topLeading`, `.top`, `.topTrailing`
  - `.leading`, `.center`, `.trailing`
  - `.bottomLeading`, `.bottom`, `.bottomTrailing`
- `.rect(Bounds)` - Attach to a rectangular region
  - `.bounds` - The entire view bounds
  - `.rect(CGRect)` - Custom rectangle

#### Popover with Arrow Edge

```swift
.popover(
    isPresented: $showPopover,
    arrowEdge: .bottom
) {
    Text("Popover")
}
```

**Arrow Edges:**
- `.top` - Arrow points up
- `.bottom` - Arrow points down
- `.leading` - Arrow points left
- `.trailing` - Arrow points right

#### Full Popover Configuration

```swift
.popover(
    isPresented: $showPopover,
    attachmentAnchor: .point(.center),
    arrowEdge: .top,
    onDismiss: { print("Dismissed") }
) {
    Text("Popover Content")
}
```

#### Item-Based Popover

```swift
.popover(item: $selectedItem) { item in
    VStack {
        Text(item.name)
        Text(item.description)
    }
    .padding()
}
```

### Presentation Modifiers

#### Presentation Detents

Control the height of sheets with detents.

```swift
Text("Content")
    .presentationDetents([.medium, .large])
```

**Built-in Detents:**
- `.medium` - Half screen height
- `.large` - Full screen height
- `.height(CGFloat)` - Fixed height
- `.fraction(CGFloat)` - Fraction of screen (0.0 to 1.0)
- `.custom { context in ... }` - Custom calculation

**Custom Detent Example:**
```swift
.presentationDetents([
    .custom { context in
        // Return height based on context
        min(context.maxDetentValue * 0.7, 500)
    }
])
```

#### Presentation Drag Indicator

Control visibility of the drag indicator.

```swift
Text("Content")
    .presentationDragIndicator(.visible)
```

**Visibility Options:**
- `.automatic` - System default
- `.visible` - Always show
- `.hidden` - Always hide

#### Presentation Corner Radius

Customize sheet corner radius.

```swift
Text("Content")
    .presentationCornerRadius(20)
```

**Parameter:**
- `radius`: `CGFloat` - Corner radius in points

#### Interactive Dismiss Disabled

Prevent interactive dismissal (swipe down).

```swift
Text("Content")
    .interactiveDismissDisabled(hasUnsavedChanges)
```

**Parameter:**
- `isDisabled`: `Bool` - Whether to disable interactive dismiss

## Usage Patterns and Best Practices

### Pattern 1: Simple Information Display

Use a basic sheet for displaying read-only information:

```swift
@State private var showInfo = false

Button("Info") {
    showInfo = true
}
.sheet(isPresented: $showInfo) {
    VStack {
        Text("Information")
            .font(.title)
        Text("Details go here")
    }
    .padding()
    .presentationDetents([.medium])
}
```

### Pattern 2: Form Input with Validation

Use interactive dismiss control for forms:

```swift
@State private var showForm = false
@State private var text = ""

var hasChanges: Bool { !text.isEmpty }

Button("Edit") {
    showForm = true
}
.sheet(isPresented: $showForm) {
    VStack {
        TextField("Text", text: $text)
        Button("Save") {
            showForm = false
        }
    }
    .padding()
    .interactiveDismissDisabled(hasChanges)
}
```

### Pattern 3: Item-Based Details

Use item binding for displaying item details:

```swift
struct Item: Identifiable {
    let id = UUID()
    let name: String
    let details: String
}

@State private var selectedItem: Item?

List(items) { item in
    Button(item.name) {
        selectedItem = item
    }
}
.sheet(item: $selectedItem) { item in
    VStack {
        Text(item.name).font(.title)
        Text(item.details)
    }
    .padding()
}
```

### Pattern 4: Confirmation Before Action

Use alerts for destructive actions:

```swift
@State private var showDeleteAlert = false

Button("Delete") {
    showDeleteAlert = true
}
.alert("Delete Item?", isPresented: $showDeleteAlert) {
    Button("Delete", role: .destructive) {
        // Perform deletion
    }
    Button("Cancel", role: .cancel) {}
} message: {
    Text("This action cannot be undone")
}
```

### Pattern 5: Multiple Action Choices

Use confirmation dialogs for action menus:

```swift
@State private var showActions = false

Button("Actions") {
    showActions = true
}
.confirmationDialog("Choose Action", isPresented: $showActions) {
    Button("Edit") { /* edit */ }
    Button("Share") { /* share */ }
    Button("Delete", role: .destructive) { /* delete */ }
    Button("Cancel", role: .cancel) {}
}
```

### Pattern 6: Contextual Help

Use popovers for inline help:

```swift
@State private var showHelp = false

Button("?") {
    showHelp = true
}
.popover(isPresented: $showHelp, arrowEdge: .bottom) {
    Text("This is contextual help")
        .padding()
}
```

### Pattern 7: Nested Presentations

Present sheets on top of sheets:

```swift
@State private var showFirst = false
@State private var showSecond = false

Button("Open") {
    showFirst = true
}
.sheet(isPresented: $showFirst) {
    VStack {
        Text("First Sheet")
        Button("Open Second") {
            showSecond = true
        }
    }
    .sheet(isPresented: $showSecond) {
        Text("Second Sheet")
    }
}
```

### Pattern 8: Shared State Across Presentations

Use @ObservableObject for shared state:

```swift
@MainActor
class AppState: ObservableObject {
    @Published var counter = 0
}

@StateObject private var state = AppState()

VStack {
    Text("Counter: \(state.counter)")
}
.sheet(isPresented: $showSheet) {
    CounterSheet()
        .environmentObject(state)
}
```

## Migration Guide from UIKit Patterns

### UIAlertController → Alert

**UIKit:**
```swift
let alert = UIAlertController(
    title: "Title",
    message: "Message",
    preferredStyle: .alert
)
alert.addAction(UIAlertAction(title: "OK", style: .default))
present(alert, animated: true)
```

**Raven:**
```swift
.alert("Title", isPresented: $showAlert) {
    Button("OK") {}
} message: {
    Text("Message")
}
```

### UIAlertController with Actions → Confirmation Dialog

**UIKit:**
```swift
let sheet = UIAlertController(
    title: "Actions",
    message: nil,
    preferredStyle: .actionSheet
)
sheet.addAction(UIAlertAction(title: "Edit", style: .default))
sheet.addAction(UIAlertAction(title: "Delete", style: .destructive))
sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
present(sheet, animated: true)
```

**Raven:**
```swift
.confirmationDialog("Actions", isPresented: $showDialog) {
    Button("Edit") {}
    Button("Delete", role: .destructive) {}
    Button("Cancel", role: .cancel) {}
}
```

### UIPopoverPresentationController → Popover

**UIKit:**
```swift
let vc = UIViewController()
vc.modalPresentationStyle = .popover
vc.popoverPresentationController?.sourceView = button
present(vc, animated: true)
```

**Raven:**
```swift
button
    .popover(isPresented: $showPopover) {
        ContentView()
    }
```

### Modal Presentation → Sheet

**UIKit:**
```swift
let vc = UIViewController()
present(vc, animated: true)
```

**Raven:**
```swift
.sheet(isPresented: $showSheet) {
    ContentView()
}
```

## Common Use Cases

### 1. User Onboarding

```swift
.sheet(isPresented: $showOnboarding) {
    OnboardingView()
        .interactiveDismissDisabled(true)
}
```

### 2. Settings Screen

```swift
.sheet(isPresented: $showSettings) {
    SettingsView()
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
}
```

### 3. Quick Actions

```swift
.confirmationDialog("Quick Actions", isPresented: $showActions) {
    Button("New Document") {}
    Button("Open") {}
    Button("Recent") {}
}
```

### 4. Error Handling

```swift
.alert(item: $error) { error in
    Alert(
        title: Text("Error"),
        message: Text(error.localizedDescription),
        buttons: [
            .default(Text("Retry")) { retry() },
            .cancel()
        ]
    )
}
```

### 5. Contextual Information

```swift
.popover(
    isPresented: $showInfo,
    attachmentAnchor: .point(.topTrailing),
    arrowEdge: .top
) {
    InfoView().padding()
}
```

### 6. Multi-Step Workflow

```swift
.sheet(isPresented: $showStep1) {
    Step1View(onComplete: {
        showStep1 = false
        showStep2 = true
    })
}
.sheet(isPresented: $showStep2) {
    Step2View()
}
```

### 7. Confirmation with Input

```swift
@State private var showConfirm = false
@State private var inputText = ""

.alert("Enter Name", isPresented: $showConfirm) {
    TextField("Name", text: $inputText)
    Button("OK") { saveWithName(inputText) }
    Button("Cancel", role: .cancel) {}
}
```

### 8. Dynamic Sheet Sizing

```swift
.sheet(isPresented: $showSheet) {
    ContentView()
        .presentationDetents([
            .height(200),
            .medium,
            .large
        ])
}
```

## Performance Considerations

### 1. Avoid Heavy Views in Sheets

Create sheets lazily when needed:

```swift
// Good
.sheet(isPresented: $showSheet) {
    HeavyView() // Created only when needed
}

// Avoid
let heavyView = HeavyView() // Created immediately
.sheet(isPresented: $showSheet) {
    heavyView
}
```

### 2. Clean Up on Dismiss

Use onDismiss to clean up resources:

```swift
.sheet(isPresented: $showSheet) {
    CameraView()
} onDismiss: {
    // Release camera resources
    camera.stop()
}
```

### 3. Limit Nesting Depth

Avoid deeply nested presentations (3+ levels) for better UX and performance.

### 4. Use Item Binding for Dynamic Content

Item binding is more efficient than conditional logic:

```swift
// Good
.sheet(item: $selectedItem) { item in
    DetailView(item: item)
}

// Less efficient
.sheet(isPresented: $showSheet) {
    if let item = selectedItem {
        DetailView(item: item)
    }
}
```

## Troubleshooting

### Issue: Sheet Not Appearing

**Cause**: Binding not properly connected
**Solution**: Ensure state variable is in view hierarchy

```swift
// Wrong - state in wrong scope
struct MyView: View {
    var body: some View {
        @State var show = false // ❌
        Button("Open") { show = true }
    }
}

// Correct
struct MyView: View {
    @State private var show = false // ✅
    var body: some View {
        Button("Open") { show = true }
    }
}
```

### Issue: Alert Not Dismissing

**Cause**: Binding not set to false
**Solution**: Ensure binding is reset

```swift
.alert("Title", isPresented: $showAlert) {
    Button("OK") {
        showAlert = false // Important!
    }
}
```

### Issue: Multiple Presentations Conflict

**Cause**: Multiple presentation modifiers triggered simultaneously
**Solution**: Use a single item binding with enum

```swift
enum PresentationType: Identifiable {
    case settings, help, about
    var id: Self { self }
}

@State private var activePresentation: PresentationType?

.sheet(item: $activePresentation) { type in
    switch type {
    case .settings: SettingsView()
    case .help: HelpView()
    case .about: AboutView()
    }
}
```

### Issue: Popover Not Positioned Correctly

**Cause**: Incorrect attachment anchor
**Solution**: Use appropriate anchor for desired position

```swift
// Attach to specific corner
.popover(
    isPresented: $show,
    attachmentAnchor: .point(.bottomTrailing),
    arrowEdge: .bottom
) { /* ... */ }
```

## Testing Presentations

### Unit Testing

```swift
@Test("Sheet presentation")
func testSheetPresentation() async throws {
    let coordinator = PresentationCoordinator()

    let id = coordinator.present(
        type: .sheet,
        content: AnyView(Text("Test"))
    )

    #expect(coordinator.count == 1)
    #expect(coordinator.topPresentation()?.id == id)

    coordinator.dismiss(id)
    #expect(coordinator.count == 0)
}
```

### Integration Testing

```swift
@Test("Nested presentations")
func testNestedPresentations() async throws {
    let coordinator = PresentationCoordinator()

    let first = coordinator.present(type: .sheet, content: AnyView(Text("1")))
    let second = coordinator.present(type: .sheet, content: AnyView(Text("2")))

    #expect(coordinator.presentations[0].zIndex < coordinator.presentations[1].zIndex)
}
```

## Summary

Phase 14 delivers a complete, production-ready presentation system that:

- ✅ Matches SwiftUI's presentation APIs
- ✅ Supports all major presentation types
- ✅ Includes comprehensive modifiers
- ✅ Handles nested presentations
- ✅ Provides proper state management
- ✅ Follows Swift 6.2 concurrency best practices
- ✅ Includes extensive examples and documentation

The system is ready for use in production Raven applications.
