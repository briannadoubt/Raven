# Raven API Overview

Welcome to the Raven API documentation. This guide provides a comprehensive overview of Raven's public APIs for building web applications using SwiftUI-style declarative syntax.

## What's New in v0.6.0 (Phase 12)

Phase 12 introduces a comprehensive animation system with full SwiftUI compatibility:

- **Animation System** - Complete animation curve support (linear, ease, spring, custom timing)
- **.animation() Modifier** - Implicit, value-based animations for smooth property changes
- **withAnimation()** - Explicit animation blocks with completion handlers
- **Transition System** - 8 transition types (opacity, scale, slide, move, push, offset, custom, asymmetric)
- **keyframeAnimator()** - Multi-step animations with precise timing control (iOS 17+)
- **50+ Tests** - Comprehensive integration and unit test coverage
- **GPU Acceleration** - CSS-based animations with hardware acceleration for 60fps
- **API Coverage** - Increased from ~80% to ~85%

See [Phase 12 Documentation](Phase12.md) for detailed information.

## What's New in v0.5.0 (Phase 11)

Phase 11 introduces modern layout APIs, enhanced scroll features, and search functionality:

- **Modern Layout APIs** - containerRelativeFrame() and ViewThatFits for responsive, adaptive layouts
- **Scroll Enhancements** - .scrollBounceBehavior(), .scrollClipDisabled(), .scrollTransition() for advanced scroll control
- **Search** - .searchable() modifier with suggestions, filtering, and placement options
- **102+ Tests** - Comprehensive test coverage
- **Web Platform** - CSS container queries, IntersectionObserver, native HTML search
- **API Coverage** - Increased from ~70% to ~80%

See [Phase 11 Documentation](Phase11.md) for detailed information.

## What's New in v0.4.0 (Phase 10)

Phase 10 introduces a comprehensive shape system and visual effects:

- **Shape System** - Shape protocol, 5 built-in shapes (Circle, Rectangle, RoundedRectangle, Capsule, Ellipse)
- **Path API** - Custom drawing with lines, curves, arcs, and transformations
- **Shape Modifiers** - .fill(), .stroke(), .trim() with full styling support
- **7 Visual Effects** - .blur(), .brightness(), .contrast(), .saturation(), .grayscale(), .hueRotation(), .shadow()
- **Clipping** - .clipShape() for masking content with shapes
- **162+ Tests** - Comprehensive test coverage
- **SVG Rendering** - Resolution-independent vector graphics
- **API Coverage** - Increased from ~60% to ~70%

See [Phase 10 Documentation](Phase10.md) for detailed information.

## What's New in v0.3.0 (Phase 9)

Phase 9 brings modern state management and enhanced UI capabilities:

- **@Observable & @Bindable** - Modern state management (iOS 17+ API)
- **ContentUnavailableView** - Polished empty state UI
- **10 New Modifiers** - Interaction, layout, and text modifiers
- **159+ Tests** - Comprehensive test coverage
- **Full Documentation** - Complete DocC comments and examples

See [Phase 9 Documentation](Phase9.md) for detailed information.

---

## Table of Contents

- [What's New](#whats-new-in-v030-phase-9)
- [Getting Started](#getting-started)
- [Core Concepts](#core-concepts)
- [API Reference](#api-reference)
  - [Core Types](#core-types)
  - [State Management](#state-management)
  - [Shapes](#shapes)
  - [Path](#path)
  - [Primitive Views](#primitive-views)
  - [Layout Views](#layout-views)
  - [Navigation](#navigation)
  - [View Modifiers](#view-modifiers)
- [CLI Commands](#cli-commands)
- [Common Patterns](#common-patterns)
- [Quick Reference](#quick-reference)

---

## Getting Started

Raven enables you to build web applications using Swift and SwiftUI-style declarative syntax. Views are compiled to WebAssembly and rendered in the browser.

### Basic Example

```swift
import Raven

struct HelloWorld: View {
    var body: some View {
        Text("Hello, World!")
            .font(.title)
            .foregroundColor(.blue)
    }
}
```

### With State

```swift
struct Counter: View {
    @State private var count = 0

    var body: some View {
        VStack(spacing: 16) {
            Text("Count: \(count)")
                .font(.title)

            Button("Increment") {
                count += 1
            }
        }
        .padding()
    }
}
```

---

## Core Concepts

### View Protocol

All UI components in Raven conform to the `View` protocol. Views define their content using the `body` property.

### Declarative Syntax

Raven uses SwiftUI's declarative syntax, enabled by `@ViewBuilder`. This allows you to compose views naturally using Swift control flow.

### State Management

Raven provides property wrappers for managing state:
- `@State` - Local state owned by a view
- `@Binding` - Two-way connection to a value
- `@StateObject` - Creates and owns an observable object
- `@ObservedObject` - Observes an object owned elsewhere
- `@Published` - Publishes changes from observable objects

---

## API Reference

### Core Types

#### View

The fundamental protocol for all views in Raven.

```swift
public protocol View: Sendable {
    associatedtype Body: View
    @ViewBuilder @MainActor var body: Body { get }
}
```

**Key Methods:**
- `eraseToAnyView()` - Wraps the view in a type-erased container

**See:** `Sources/Raven/Core/View.swift`

---

#### ViewBuilder

A result builder that constructs views from multi-statement closures.

```swift
@ViewBuilder
var content: some View {
    Text("Line 1")
    Text("Line 2")
    if condition {
        Text("Conditional")
    }
}
```

**Features:**
- Supports up to 10 view components
- Handles if-else statements
- Supports optional content
- Works with switch statements

**See:** `Sources/Raven/Core/ViewBuilder.swift`

---

#### AnyView

A type-erased view for returning different view types from a single code path.

```swift
func makeView(condition: Bool) -> AnyView {
    if condition {
        return Text("True").eraseToAnyView()
    } else {
        return Image("icon").eraseToAnyView()
    }
}
```

**Note:** Prefer `@ViewBuilder` when possible for better performance.

**See:** `Sources/Raven/Core/AnyView.swift`

---

### State Management

#### @Observable (New in v0.3.0)

Modern macro for observable classes (iOS 17+ API).

```swift
@Observable
@MainActor
class UserSettings {
    var username: String = ""
    var isDarkMode: Bool = false
    var fontSize: Double = 14.0
}
```

**Benefits:**
- No need for `@Published` wrappers
- Automatic property observation
- Fine-grained updates
- Cleaner syntax

**See:** `Sources/Raven/State/Observable.swift`, [Phase 9 Documentation](Phase9.md)

---

#### @Bindable (New in v0.3.0)

Creates bindings to properties of `@Observable` objects.

```swift
struct SettingsView: View {
    @Bindable var settings: UserSettings

    var body: some View {
        VStack {
            TextField("Username", text: $settings.username)
            Toggle("Dark Mode", isOn: $settings.isDarkMode)
        }
    }
}
```

**Features:**
- Dynamic member lookup for bindings
- Type-safe binding creation
- Works with `@Observable` classes

**See:** `Sources/Raven/State/Bindable.swift`, [Phase 9 Documentation](Phase9.md)

---

#### @State

Manages mutable state local to a view.

```swift
struct Example: View {
    @State private var isOn = false

    var body: some View {
        Toggle("Switch", isOn: $isOn)
    }
}
```

**Best Practices:**
- Always declare as `private`
- Use for simple value types
- Keep state focused and specific

**See:** `Sources/Raven/State/State.swift`

---

#### @Binding

Creates a two-way connection to a value owned elsewhere.

```swift
struct ChildView: View {
    @Binding var text: String

    var body: some View {
        TextField("Enter text", text: $text)
    }
}

struct ParentView: View {
    @State private var text = ""

    var body: some View {
        ChildView(text: $text)
    }
}
```

**Features:**
- Dynamic member lookup for nested properties
- Custom bindings with get/set closures
- Constant bindings for static values

**See:** `Sources/Raven/State/State.swift`

---

#### @StateObject

Creates and owns an observable object.

```swift
@MainActor
class ViewModel: ObservableObject {
    @Published var count = 0

    init() {
        setupPublished()
    }
}

struct ContentView: View {
    @StateObject private var viewModel = ViewModel()

    var body: some View {
        Text("Count: \(viewModel.count)")
    }
}
```

**When to Use:**
- View creates and owns the object
- Object persists across view updates
- Object lifetime tied to view lifetime

**See:** `Sources/Raven/State/StateObject.swift`

---

#### @ObservedObject

Observes an object owned by a parent view.

```swift
struct ChildView: View {
    @ObservedObject var viewModel: ViewModel

    var body: some View {
        Text("Count: \(viewModel.count)")
    }
}
```

**When to Use:**
- Object created by parent view
- Object passed as parameter
- Multiple views observe same object

**See:** `Sources/Raven/State/ObservedObject.swift`

---

#### ObservableObject

Protocol for reference types with observable properties.

```swift
@MainActor
class AppState: ObservableObject {
    @Published var isLoggedIn = false
    @Published var username = ""

    init() {
        setupPublished()
    }

    func login(username: String) {
        self.username = username
        isLoggedIn = true
    }
}
```

**Important:** Always call `setupPublished()` in your initializer.

**See:** `Sources/Raven/State/ObservableObject.swift`

---

### Shapes

#### Shape Protocol (New in v0.4.0)

The foundation for all 2D shapes in Raven.

```swift
public protocol Shape: View {
    @MainActor func path(in rect: CGRect) -> Path
}
```

**Key Features:**
- Resolution-independent vector graphics
- SVG-based rendering
- Automatic View conformance
- Composable with view modifiers

**See:** `Sources/Raven/Drawing/Shape.swift`, [Phase 10 Documentation](Phase10.md)

---

#### Circle (New in v0.4.0)

A perfect circular shape.

```swift
Circle()
    .fill(Color.blue)
    .frame(width: 100, height: 100)

Circle()
    .stroke(Color.red, lineWidth: 3)
```

**See:** `Sources/Raven/Drawing/Shapes/Circle.swift`

---

#### Rectangle (New in v0.4.0)

A rectangular shape with sharp corners.

```swift
Rectangle()
    .fill(Color.gray)
    .frame(width: 200, height: 100)
```

**See:** `Sources/Raven/Drawing/Shapes/Rectangle.swift`

---

#### RoundedRectangle (New in v0.4.0)

A rectangle with rounded corners.

```swift
RoundedRectangle(cornerRadius: 10)
    .fill(Color.blue)
    .frame(width: 200, height: 100)
```

**See:** `Sources/Raven/Drawing/Shapes/RoundedRectangle.swift`

---

#### Capsule (New in v0.4.0)

A rounded rectangle with fully circular ends.

```swift
Capsule()
    .fill(Color.green)
    .frame(width: 200, height: 50)
```

**See:** `Sources/Raven/Drawing/Shapes/Capsule.swift`

---

#### Ellipse (New in v0.4.0)

An elliptical shape.

```swift
Ellipse()
    .fill(Color.purple)
    .frame(width: 150, height: 100)
```

**See:** `Sources/Raven/Drawing/Shapes/Ellipse.swift`

---

### Path

#### Path Type (New in v0.4.0)

A flexible API for creating custom shapes.

```swift
var path = Path()
path.move(to: CGPoint(x: 50, y: 0))
path.addLine(to: CGPoint(x: 100, y: 100))
path.addLine(to: CGPoint(x: 0, y: 100))
path.closeSubpath()
```

**Drawing Commands:**
- `move(to:)` - Move without drawing
- `addLine(to:)` - Draw straight line
- `addRect(_:)` - Add rectangle
- `addRoundedRect(in:cornerRadius:)` - Add rounded rectangle
- `addEllipse(in:)` - Add ellipse
- `addQuadCurve(to:control:)` - Add quadratic curve
- `addCurve(to:control1:control2:)` - Add cubic curve
- `addArc(center:radius:startAngle:endAngle:clockwise:)` - Add arc
- `closeSubpath()` - Close current path

**Convenience Initializers:**
```swift
Path(CGRect(...))
Path(roundedRect:cornerRadius:)
Path(ellipseIn:)
```

**Transformations:**
```swift
path.offsetBy(x:y:)
path.applying(CGAffineTransform)
```

**See:** `Sources/Raven/Drawing/Path.swift`, [Phase 10 Documentation](Phase10.md)

---

### Primitive Views

#### Text

Displays read-only text.

```swift
Text("Hello, World!")
Text("Count: \(count)")
Text("localized_key")
```

**Common Modifiers:**
- `.font(_:)` - Set text font
- `.foregroundColor(_:)` - Set text color
- `.bold()` - Make text bold

**See:** `Sources/Raven/Views/Primitives/Text.swift`

---

#### Button

Interactive button that triggers an action.

```swift
// Simple text button
Button("Click Me") {
    print("Clicked!")
}

// Custom label
Button(action: handleTap) {
    HStack {
        Image(systemName: "star")
        Text("Favorite")
    }
}
```

**See:** `Sources/Raven/Views/Primitives/Button.swift`

---

#### Image

Displays an image.

```swift
Image("photo")
Image(systemName: "star.fill")
Image("photo", alt: "Description")
Image.url("https://example.com/image.png")
```

**Features:**
- Named resources
- System icons
- URL loading
- Accessibility support

**See:** `Sources/Raven/Views/Primitives/Image.swift`

---

#### TextField

Editable single-line text input.

```swift
@State private var username = ""

TextField("Enter username", text: $username)
```

**See:** `Sources/Raven/Views/Primitives/TextField.swift`

---

#### Toggle

Boolean on/off control.

```swift
@State private var isEnabled = false

Toggle("Enable Feature", isOn: $isEnabled)
```

**See:** `Sources/Raven/Views/Primitives/Toggle.swift`

---

#### ContentUnavailableView (New in v0.3.0)

Standardized empty state interface.

```swift
// Basic usage
ContentUnavailableView(
    "No Messages",
    systemImage: "envelope.open",
    description: Text("You don't have any messages yet.")
)

// With actions
ContentUnavailableView(
    "No Items",
    systemImage: "tray",
    description: Text("Add your first item to get started.")
) {
    Button("Add Item") {
        addNewItem()
    }
}

// Search variant
ContentUnavailableView.search
```

**Features:**
- Centered layout with icon, title, description, and actions
- Built-in search variant
- Multiple initializer options
- Web-optimized rendering

**See:** `Sources/Raven/Views/Primitives/ContentUnavailableView.swift`, [Phase 9 Documentation](Phase9.md)

---

### Layout Views

#### VStack

Vertical stack layout.

```swift
VStack(alignment: .leading, spacing: 16) {
    Text("Title")
    Text("Subtitle")
    Text("Description")
}
```

**Parameters:**
- `alignment` - Horizontal alignment (.leading, .center, .trailing)
- `spacing` - Vertical spacing in pixels

**See:** `Sources/Raven/Views/Layout/VStack.swift`

---

#### HStack

Horizontal stack layout.

```swift
HStack(alignment: .center, spacing: 12) {
    Image("icon")
    Text("Label")
    Spacer()
    Text("Value")
}
```

**Parameters:**
- `alignment` - Vertical alignment (.top, .center, .bottom)
- `spacing` - Horizontal spacing in pixels

**See:** `Sources/Raven/Views/Layout/HStack.swift`

---

#### ZStack

Layered stack (overlay).

```swift
ZStack(alignment: .topLeading) {
    Image("background")
    Text("Overlay")
        .foregroundColor(.white)
}
```

**Parameters:**
- `alignment` - Alignment for child views

**See:** `Sources/Raven/Views/Layout/ZStack.swift`

---

#### ViewThatFits (New in v0.5.0)

Adaptive container that selects the first child view that fits in available space.

```swift
ViewThatFits {
    // Desktop layout
    HStack {
        Image("logo")
        Text("My Application")
        Spacer()
        Button("Sign In") { }
        Button("Sign Up") { }
    }

    // Mobile layout - fallback
    VStack {
        HStack {
            Image("logo")
            Text("My App")
        }
        HStack {
            Button("Sign In") { }
            Button("Sign Up") { }
        }
    }
}

// Control which axes to check
ViewThatFits(in: .horizontal) {
    WideLayout()
    NarrowLayout()
}

ViewThatFits(in: [.horizontal, .vertical]) {
    LargeLayout()
    CompactLayout()
}
```

**Features:**
- Automatic layout selection based on available space
- Axis control (horizontal, vertical, or both)
- Perfect for responsive navigation and adaptive UIs
- No explicit breakpoints needed
- CSS container query implementation

**Common Uses:**
- Responsive navigation (full menu vs. hamburger)
- Adaptive dashboards (multi-column vs. single column)
- Form layouts (horizontal vs. vertical)
- Content cards (expanded vs. compact)

**See:** `Sources/Raven/Views/Layout/ViewThatFits.swift`, [Phase 11 Documentation](Phase11.md)

---

#### List

Scrollable list of content.

```swift
// Static content
List {
    Text("Item 1")
    Text("Item 2")
    Text("Item 3")
}

// Dynamic content
List(items, id: \.id) { item in
    Text(item.name)
}
```

**See:** `Sources/Raven/Views/Layout/List.swift`

---

#### ForEach

Iterates over collections to create views.

```swift
ForEach(items) { item in
    Text(item.name)
}

ForEach(0..<10) { index in
    Text("Row \(index)")
}
```

**See:** `Sources/Raven/Views/Layout/ForEach.swift`

---

#### Form

Semantic container for form controls.

```swift
Form {
    Section(header: "Personal Info") {
        TextField("Name", text: $name)
        TextField("Email", text: $email)
    }

    Section(header: "Preferences") {
        Toggle("Notifications", isOn: $notifications)
    }
}
```

**See:** `Sources/Raven/Views/Layout/Form.swift`

---

#### Section

Groups related content, typically in forms.

```swift
Section(header: "Account") {
    TextField("Username", text: $username)
    TextField("Password", text: $password)
}

Section {
    Text("Content without header")
}
```

**See:** `Sources/Raven/Views/Layout/Section.swift`

---

### Navigation

#### NavigationView

Container for navigable content.

```swift
NavigationView {
    List {
        NavigationLink("Detail", destination: DetailView())
        NavigationLink("Settings", destination: SettingsView())
    }
    .navigationTitle("Home")
}
```

**See:** `Sources/Raven/Views/Navigation/NavigationView.swift`

---

#### NavigationLink

Interactive link that navigates to a destination.

```swift
// Text label
NavigationLink("Show Details", destination: DetailView())

// Custom label
NavigationLink(destination: SettingsView()) {
    HStack {
        Image(systemName: "gear")
        Text("Settings")
    }
}

// Programmatic navigation
NavigationLink(
    "Details",
    destination: DetailView(),
    isActive: $showDetails
)
```

**See:** `Sources/Raven/Views/Navigation/NavigationLink.swift`

---

### View Modifiers

View modifiers customize the appearance and behavior of views.

#### Common Modifiers

**Layout:**
- `.padding(_:)` - Add padding
- `.frame(width:height:)` - Set fixed size
- `.background(_:)` - Set background
- `.clipped()` - Clip content to bounds (New in v0.3.0)
- `.aspectRatio(_:contentMode:)` - Maintain aspect ratio (New in v0.3.0)
- `.fixedSize(horizontal:vertical:)` - Fix to ideal size (New in v0.3.0)
- `.containerRelativeFrame(_:alignment:length:)` - Size relative to container (New in v0.5.0)

**Styling:**
- `.foregroundColor(_:)` - Set text/icon color
- `.font(_:)` - Set font style
- `.bold()` - Make text bold
- `.cornerRadius(_:)` - Round corners

**Text:**
- `.lineLimit(_:)` - Limit number of lines (New in v0.3.0)
- `.multilineTextAlignment(_:)` - Align multiline text (New in v0.3.0)
- `.truncationMode(_:)` - Control truncation (New in v0.3.0)

**Interaction:**
- `.disabled(_:)` - Disable interactions (New in v0.3.0)
- `.onTapGesture(count:perform:)` - Handle tap events (New in v0.3.0)

**Lifecycle:**
- `.onAppear(perform:)` - Run action when view appears (New in v0.3.0)
- `.onDisappear(perform:)` - Run action when view disappears (New in v0.3.0)
- `.onChange(of:perform:)` - React to value changes (New in v0.3.0)

**Shape Modifiers (New in v0.4.0):**
- `.fill(_:)` - Fill shape with color or gradient
- `.stroke(_:lineWidth:)` - Stroke shape outline
- `.stroke(_:style:)` - Stroke with advanced StrokeStyle
- `.trim(from:to:)` - Trim shape path (progress indicators)

**Visual Effects (New in v0.4.0):**
- `.blur(radius:)` - Apply Gaussian blur
- `.brightness(_:)` - Adjust brightness (0.0-∞)
- `.contrast(_:)` - Adjust contrast (0.0-∞)
- `.saturation(_:)` - Adjust color saturation (0.0-∞)
- `.grayscale(_:)` - Convert to grayscale (0.0-1.0)
- `.hueRotation(_:)` - Rotate hues (Angle)
- `.shadow(color:radius:x:y:)` - Apply drop shadow

**Clipping (New in v0.4.0):**
- `.clipShape(_:style:)` - Clip content to shape bounds

**Scroll Modifiers (New in v0.5.0):**
- `.scrollBounceBehavior(_:axes:)` - Control scroll bounce/overscroll behavior
- `.scrollClipDisabled(_:)` - Allow scroll content to overflow
- `.scrollTransition(_:transition:)` - Animate content based on scroll position

**Search (New in v0.5.0):**
- `.searchable(text:placement:prompt:)` - Add search functionality with suggestions

**Animation (New in v0.6.0):**
- `.animation(_:value:)` - Implicit animations triggered by value changes
- `.transition(_:)` - View insertion/removal animations
- `.keyframeAnimator(initialValue:trigger:content:keyframes:)` - Multi-step keyframe animations

**See:** `Sources/Raven/Modifiers/` - [BasicModifiers.swift](../Sources/Raven/Modifiers/BasicModifiers.swift), [InteractionModifiers.swift](../Sources/Raven/Modifiers/InteractionModifiers.swift), [LayoutModifiers.swift](../Sources/Raven/Modifiers/LayoutModifiers.swift), [TextModifiers.swift](../Sources/Raven/Modifiers/TextModifiers.swift), [ShapeModifiers.swift](../Sources/Raven/Modifiers/ShapeModifiers.swift), [VisualEffectModifiers.swift](../Sources/Raven/Modifiers/VisualEffectModifiers.swift), [ClipShapeModifier.swift](../Sources/Raven/Modifiers/ClipShapeModifier.swift), [ContainerRelativeFrameModifier.swift](../Sources/Raven/Modifiers/ContainerRelativeFrameModifier.swift), [ScrollBehaviorModifiers.swift](../Sources/Raven/Modifiers/ScrollBehaviorModifiers.swift), [ScrollTransitionModifier.swift](../Sources/Raven/Modifiers/ScrollTransitionModifier.swift), [SearchableModifier.swift](../Sources/Raven/Modifiers/SearchableModifier.swift), [AnimationModifier.swift](../Sources/Raven/Animation/AnimationModifier.swift), [TransitionModifier.swift](../Sources/Raven/Animation/TransitionModifier.swift), [Phase 9 Documentation](Phase9.md), [Phase 10 Documentation](Phase10.md), [Phase 11 Documentation](Phase11.md), [Phase 12 Documentation](Phase12.md)

---

### Modern Layout Modifiers (New in v0.5.0)

#### containerRelativeFrame()

Size views relative to their container using CSS container queries.

```swift
// Closure-based sizing
Image("hero")
    .containerRelativeFrame(.horizontal) { width, _ in
        width * 0.8
    }

// Grid-based sizing
ItemCard()
    .containerRelativeFrame(.horizontal, count: 3, span: 1, spacing: 16)

// Both axes with alignment
Rectangle()
    .containerRelativeFrame(
        [.horizontal, .vertical],
        alignment: .center
    ) { length, axis in
        switch axis {
        case .horizontal: return length * 0.8
        case .vertical: return length * 0.5
        }
    }
```

**Parameters:**
- `axes` - Axes to apply frame to (.horizontal, .vertical, or both)
- `alignment` - Alignment within container
- `length` - Closure that calculates size for each axis
- `count` - (Grid mode) Total number of grid columns/rows
- `span` - (Grid mode) Number of cells to span
- `spacing` - (Grid mode) Gap between items

**Benefits:**
- Modern alternative to GeometryReader
- Cleaner syntax
- CSS container query implementation
- No wrapper views needed

**See:** `Sources/Raven/Modifiers/ContainerRelativeFrameModifier.swift`, [Phase 11 Documentation](Phase11.md#containerrelativeframe)

---

### Scroll Modifiers (New in v0.5.0)

#### scrollBounceBehavior()

Control scroll bounce/overscroll behavior.

```swift
ScrollView {
    Content()
}
.scrollBounceBehavior(.never)  // Disable bounce

ScrollView(.horizontal) {
    Content()
}
.scrollBounceBehavior(.basedOnSize, axes: .horizontal)
```

**Behaviors:**
- `.automatic` - System default
- `.always` - Always allow bounce
- `.basedOnSize` - Bounce only if content exceeds container
- `.never` - Disable bounce

**See:** `Sources/Raven/Modifiers/ScrollBehaviorModifiers.swift`, [Phase 11 Documentation](Phase11.md#scrollbouncebehavior)

---

#### scrollClipDisabled()

Allow scroll content to overflow (for shadows, glows).

```swift
ScrollView {
    ForEach(items) { item in
        ItemCard(item: item)
            .shadow(radius: 8)  // Shadow won't be clipped
    }
}
.scrollClipDisabled(true)
```

**See:** `Sources/Raven/Modifiers/ScrollBehaviorModifiers.swift`, [Phase 11 Documentation](Phase11.md#scrollclipdisabled)

---

#### scrollTransition()

Animate content based on scroll position.

```swift
ScrollView {
    ForEach(items) { item in
        ItemRow(item: item)
            .scrollTransition { content, phase in
                content
                    .opacity(phase.isIdentity ? 1 : 0.5)
                    .scaleEffect(phase.isIdentity ? 1 : 0.95)
            }
    }
}

// With configuration
.scrollTransition(.topLeading) { content, phase in
    content
        .offset(y: phase.isIdentity ? 0 : 50)
        .opacity(phase.isIdentity ? 1 : 0)
}
```

**Configurations:**
- `.topLeading` - Trigger at top/leading edge
- `.center` - Trigger when centered (default)
- `.bottomTrailing` - Trigger at bottom/trailing edge

**Phases:**
- `.identity` - Fully visible
- `.topLeading` - Entering from top/leading
- `.bottomTrailing` - Exiting to bottom/trailing

**See:** `Sources/Raven/Modifiers/ScrollTransitionModifier.swift`, [Phase 11 Documentation](Phase11.md#scrolltransition)

---

### Search Modifier (New in v0.5.0)

#### searchable()

Add search functionality to views.

```swift
struct ItemList: View {
    @State private var searchText = ""

    var filteredItems: [Item] {
        if searchText.isEmpty { return items }
        return items.filter { $0.name.contains(searchText) }
    }

    var body: some View {
        List(filteredItems) { item in
            ItemRow(item: item)
        }
        .searchable(text: $searchText, prompt: "Search items")
    }
}

// With suggestions
.searchable(text: $searchText, prompt: "Search") {
    ForEach(suggestions) { suggestion in
        Text(suggestion.name)
            .searchCompletion(suggestion.name)
    }
}

// With placement
.searchable(
    text: $searchText,
    placement: .navigationBarDrawer,
    prompt: "Search"
)
```

**Placement Options:**
- `.automatic` - Default top placement
- `.navigationBarDrawer` - Navigation-integrated
- `.sidebar` - Sidebar-optimized
- `.toolbar` - Inline toolbar

**Features:**
- Two-way binding with `Binding<String>`
- Search suggestions with ViewBuilder
- Native HTML search input
- Keyboard shortcuts (Cmd+F)
- ARIA accessibility

**See:** `Sources/Raven/Modifiers/SearchableModifier.swift`, [Phase 11 Documentation](Phase11.md#search-functionality)

---

## Animation System (New in v0.6.0)

Phase 12 introduces a comprehensive animation system with full SwiftUI compatibility, including animation curves, transitions, and multi-step keyframe animations.

### Animation Types

Raven provides multiple animation curves for different motion characteristics:

```swift
// Linear - Constant rate
.animation(.linear, value: state)
.animation(.linear(duration: 0.5), value: state)

// Ease - Acceleration/deceleration
.animation(.easeIn, value: state)       // Slow start
.animation(.easeOut, value: state)      // Slow end
.animation(.easeInOut, value: state)    // Slow start and end
.animation(.default, value: state)      // Standard ease

// Spring - Physics-based motion
.animation(.spring(), value: state)     // Default spring
.animation(.spring(response: 0.5, dampingFraction: 0.7), value: state)
.animation(.spring(.bouncy), value: state)   // Bouncy
.animation(.spring(.smooth), value: state)   // Smooth
.animation(.spring(.snappy), value: state)   // Snappy

// Custom - Cubic Bézier curves
.animation(.timingCurve(0.17, 0.67, 0.83, 0.67, duration: 0.5), value: state)
```

**Parameters:**
- `duration` - Animation duration in seconds
- `response` - Spring response time
- `dampingFraction` - Spring damping (0.0 = bouncy, 1.0 = no bounce)

**See:** `Sources/Raven/Animation/Animation.swift`, [Phase 12 Documentation](Phase12.md#animation-types--curves)

---

### .animation() Modifier

Apply implicit animations that trigger when a value changes:

```swift
@State private var isExpanded = false

Circle()
    .scaleEffect(isExpanded ? 1.5 : 1.0)
    .animation(.spring(), value: isExpanded)
    .onTapGesture {
        isExpanded.toggle()
    }
```

**Multiple animations:**
```swift
Rectangle()
    .scaleEffect(scale)
    .animation(.spring(), value: scale)
    .opacity(opacity)
    .animation(.easeOut, value: opacity)
```

**Conditional animation:**
```swift
Circle()
    .offset(x: position)
    .animation(animated ? .spring() : nil, value: position)
```

**Animatable properties:**
- Transform (scale, rotation, offset)
- Opacity
- Colors (foreground, background)
- Frame (width, height)
- Corner radius
- Shadow

**See:** `Sources/Raven/Animation/AnimationModifier.swift`, [Phase 12 Documentation](Phase12.md#implicit-animations-animation)

---

### withAnimation()

Create explicit animation blocks for coordinated state changes:

```swift
@State private var isVisible = false

Button("Toggle") {
    withAnimation(.spring()) {
        isVisible.toggle()
    }
}

if isVisible {
    DetailView()
        .transition(.opacity)
}
```

**With completion:**
```swift
withAnimation(.easeOut(duration: 0.3), {
    isLoading = true
}, completion: {
    // Called when animation completes
    fetchData()
})
```

**Nested animations:**
```swift
withAnimation(.easeOut) {
    step = 1
} completion: {
    withAnimation(.spring()) {
        step = 2
    }
}
```

**See:** `Sources/Raven/Animation/WithAnimation.swift`, [Phase 12 Documentation](Phase12.md#explicit-animations-withanimation)

---

### Transitions

Define how views animate when inserted or removed:

```swift
// Basic transitions
if showView {
    MyView()
        .transition(.opacity)          // Fade
        .transition(.scale)            // Scale from 0
        .transition(.slide)            // Slide from bottom
        .transition(.move(edge: .leading))  // Slide from edge
        .transition(.offset(x: 20, y: 0))   // Slide by pixels
}

// Combined transitions
if showDialog {
    DialogView()
        .transition(.opacity.combined(with: .scale))
}

// Asymmetric transitions
if showNotification {
    NotificationView()
        .transition(.asymmetric(
            insertion: .move(edge: .trailing),
            removal: .opacity
        ))
}

// Advanced transitions
if showPanel {
    PanelView()
        .transition(.push(from: .trailing))  // Push while opaque
}
```

**Available transitions:**
- `.identity` - No animation
- `.opacity` - Fade in/out
- `.scale(scale:anchor:)` - Scale from specified size
- `.slide` - Slide from bottom
- `.move(edge:)` - Slide from edge (.top, .bottom, .leading, .trailing)
- `.offset(x:y:)` - Slide by pixels
- `.push(from:)` - Slide while staying opaque
- `.modifier(active:identity:)` - Custom ViewModifier-based transition
- `.combined(with:)` - Combine multiple transitions
- `.asymmetric(insertion:removal:)` - Different insertion/removal

**Trigger with animation:**
```swift
VStack {
    if showView {
        MyView().transition(.scale)
    }
}
.animation(.spring(), value: showView)

// Or with withAnimation
Button("Toggle") {
    withAnimation {
        showView.toggle()
    }
}
```

**See:** `Sources/Raven/Animation/AnyTransition.swift`, `Sources/Raven/Animation/TransitionModifier.swift`, [Phase 12 Documentation](Phase12.md#transition-system)

---

### keyframeAnimator()

Create multi-step animations with precise timing control:

```swift
struct AnimationValues {
    var scale = 1.0
    var opacity = 1.0
}

Circle()
    .keyframeAnimator(initialValue: AnimationValues()) { content, value in
        content
            .scaleEffect(value.scale)
            .opacity(value.opacity)
    } keyframes: { _ in
        KeyframeTrack(\.scale) {
            LinearKeyframe(1.5, duration: 0.3)
            SpringKeyframe(1.0, duration: 0.5)
        }
        KeyframeTrack(\.opacity) {
            LinearKeyframe(0.5, duration: 0.4)
            LinearKeyframe(1.0, duration: 0.4)
        }
    }
```

**Keyframe types:**
- `LinearKeyframe` - Constant rate
- `SpringKeyframe` - Physics-based motion
- `CubicKeyframe` - Custom cubic Bézier

**Multiple tracks:**
```swift
struct ComplexValues {
    var x = 0.0
    var y = 0.0
    var rotation = 0.0
}

Rectangle()
    .keyframeAnimator(initialValue: ComplexValues()) { content, value in
        content
            .offset(x: value.x, y: value.y)
            .rotationEffect(.degrees(value.rotation))
    } keyframes: { _ in
        KeyframeTrack(\.x) {
            LinearKeyframe(100, duration: 0.5)
            SpringKeyframe(0, duration: 0.5)
        }
        KeyframeTrack(\.y) {
            LinearKeyframe(50, duration: 0.5)
            SpringKeyframe(0, duration: 0.5)
        }
        KeyframeTrack(\.rotation) {
            LinearKeyframe(180, duration: 0.5)
            CubicKeyframe(360, duration: 0.5)
        }
    }
```

**With trigger:**
```swift
@State private var trigger = 0

Circle()
    .keyframeAnimator(
        initialValue: AnimationValues(),
        trigger: trigger  // Re-run when this changes
    ) { content, value in
        content.scaleEffect(value.scale)
    } keyframes: { _ in
        KeyframeTrack(\.scale) {
            SpringKeyframe(1.2, duration: 0.3)
            SpringKeyframe(1.0, duration: 0.3)
        }
    }

Button("Animate") {
    trigger += 1
}
```

**See:** `Sources/Raven/Animation/KeyframeAnimator.swift`, [Phase 12 Documentation](Phase12.md#multi-step-animations-keyframeanimator)

---

### Common Animation Patterns

**Button press feedback:**
```swift
@State private var isPressed = false

Button("Press Me") { }
    .scaleEffect(isPressed ? 0.95 : 1.0)
    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
```

**Modal presentation:**
```swift
if showModal {
    Color.black.opacity(0.4)
        .ignoresSafeArea()
        .transition(.opacity)

    ModalContent()
        .transition(.scale.combined(with: .opacity))
}
```

**List animations:**
```swift
ForEach(items, id: \.id) { item in
    ItemView(item: item)
        .transition(.asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        ))
}
.animation(.spring(), value: items)
```

**Loading spinner:**
```swift
struct SpinnerValues {
    var rotation = 0.0
}

Circle()
    .trim(from: 0, to: 0.7)
    .stroke(Color.blue, lineWidth: 4)
    .keyframeAnimator(initialValue: SpinnerValues()) { content, value in
        content.rotationEffect(.degrees(value.rotation))
    } keyframes: { _ in
        KeyframeTrack(\.rotation) {
            LinearKeyframe(360, duration: 1.0)
        }
    }
```

**See:** `Examples/Phase12Examples.swift`, [Phase 12 Documentation](Phase12.md#common-patterns)

---

### Performance

Raven's animation system is optimized for smooth 60fps performance:

- **GPU Acceleration** - Transform and opacity animations use hardware acceleration
- **CSS-Based** - Efficient CSS transitions and animations
- **Compositor Thread** - Animations run on browser compositor thread
- **Optimized Properties** - Prefer transform over layout properties

**Best practices:**
- Use `transform` (scale, rotate, translate) instead of `width`/`height`/`top`/`left`
- Animate `opacity` instead of adding/removing elements when possible
- Keep animation durations between 0.2-0.5s for best feel
- Use spring animations for interactive elements
- Limit simultaneous animations to avoid performance issues

**See:** [Phase 12 Documentation](Phase12.md#performance-considerations)

---

## CLI Commands

### create

Create a new Raven project.

```bash
raven create MyApp
cd MyApp
```

**See:** `Sources/RavenCLI/Commands/CreateCommand.swift`

---

### build

Build the project for production.

```bash
raven build
```

**Options:**
- `--release` - Build in release mode with optimizations
- `--output <path>` - Specify output directory

**See:** `Sources/RavenCLI/Commands/BuildCommand.swift`

---

### dev

Start development server with hot reload.

```bash
raven dev
```

**Options:**
- `--port <number>` - Specify server port (default: 8080)
- `--host <address>` - Specify host address

**Features:**
- File watching
- Automatic rebuild
- Live reload
- WebSocket connection

**See:** `Sources/RavenCLI/Commands/DevCommand.swift`

---

## Common Patterns

### Simple Counter

```swift
struct Counter: View {
    @State private var count = 0

    var body: some View {
        VStack(spacing: 16) {
            Text("Count: \(count)")

            HStack(spacing: 12) {
                Button("Decrement") { count -= 1 }
                Button("Reset") { count = 0 }
                Button("Increment") { count += 1 }
            }
        }
        .padding()
    }
}
```

---

### Form with Validation

```swift
struct LoginForm: View {
    @State private var username = ""
    @State private var password = ""

    var isValid: Bool {
        !username.isEmpty && password.count >= 8
    }

    var body: some View {
        Form {
            Section(header: "Credentials") {
                TextField("Username", text: $username)
                SecureField("Password", text: $password)
            }

            Section {
                Button("Log In") {
                    login()
                }
                .disabled(!isValid)
            }
        }
    }

    func login() {
        // Handle login
    }
}
```

---

### Master-Detail Navigation

```swift
struct ContentView: View {
    let items = ["Item 1", "Item 2", "Item 3"]

    var body: some View {
        NavigationView {
            List(items, id: \.self) { item in
                NavigationLink(item, destination: DetailView(item: item))
            }
            .navigationTitle("Items")
        }
    }
}

struct DetailView: View {
    let item: String

    var body: some View {
        Text("Details for \(item)")
            .navigationTitle(item)
    }
}
```

---

### Observable Object Pattern

```swift
@MainActor
class AppState: ObservableObject {
    @Published var isLoading = false
    @Published var items: [Item] = []
    @Published var errorMessage: String?

    init() {
        setupPublished()
    }

    func fetchItems() async {
        isLoading = true
        defer { isLoading = false }

        do {
            items = try await API.fetchItems()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

struct ContentView: View {
    @StateObject private var state = AppState()

    var body: some View {
        VStack {
            if state.isLoading {
                ProgressView()
            } else {
                List(state.items) { item in
                    Text(item.name)
                }
            }
        }
        .task {
            await state.fetchItems()
        }
    }
}
```

---

## Quick Reference

### State Management Decision Tree

**Simple values (Bool, Int, String, etc.):**
- Owned by view → `@State`
- Passed from parent → `@Binding`

**Complex objects (classes with multiple properties):**
- View creates object → `@StateObject`
- Object from parent → `@ObservedObject`

### Layout Containers

| Container | Use Case |
|-----------|----------|
| `VStack` | Vertical arrangement |
| `HStack` | Horizontal arrangement |
| `ZStack` | Layered/overlapping |
| `List` | Scrollable list |
| `Form` | Form inputs |
| `NavigationView` | Navigation stack |

### Common View Modifiers

```swift
Text("Hello")
    .font(.title)              // Font style
    .foregroundColor(.blue)    // Text color
    .padding()                 // Add padding
    .background(Color.gray)    // Background color
    .cornerRadius(8)           // Rounded corners
    .frame(width: 200)         // Fixed width
```

---

## Additional Resources

- **Getting Started Guide:** `Documentation/getting-started.md`
- **Source Code:** `Sources/Raven/`
- **Examples:** `Examples/`
- **API Documentation:** In-code Swift DocC comments

---

## API Stability

This API documentation covers Raven's public APIs. While Raven is under active development, we strive to maintain backward compatibility for documented public APIs. Breaking changes will be noted in release notes.

For the most up-to-date information, refer to the Swift DocC comments in the source code.
