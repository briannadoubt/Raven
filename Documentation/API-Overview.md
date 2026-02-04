# Raven API Overview

Welcome to the Raven API documentation. This guide provides a comprehensive overview of Raven's public APIs for building web applications using SwiftUI-style declarative syntax.

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

**See:** `Sources/Raven/Modifiers/` - [BasicModifiers.swift](../Sources/Raven/Modifiers/BasicModifiers.swift), [InteractionModifiers.swift](../Sources/Raven/Modifiers/InteractionModifiers.swift), [LayoutModifiers.swift](../Sources/Raven/Modifiers/LayoutModifiers.swift), [TextModifiers.swift](../Sources/Raven/Modifiers/TextModifiers.swift), [Phase 9 Documentation](Phase9.md)

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
