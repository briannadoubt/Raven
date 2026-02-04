# Getting Started with Raven

Welcome to Raven, a powerful framework that brings SwiftUI to the web by compiling your Swift code to WebAssembly and rendering it directly in the DOM.

## Table of Contents

1. [Introduction](#introduction)
2. [Prerequisites](#prerequisites)
3. [Installation](#installation)
4. [Your First Raven App](#your-first-raven-app)
5. [Key Concepts](#key-concepts)
6. [Common Patterns](#common-patterns)
7. [Troubleshooting](#troubleshooting)
8. [Next Steps](#next-steps)

---

## Introduction

### What is Raven?

Raven is a cross-compilation framework that enables you to write SwiftUI-style user interfaces that run in web browsers. It compiles your Swift code to WebAssembly (WASM) and provides a runtime that renders your views directly to the DOM.

### Why Use Raven?

- **Type-Safe Web Development**: Write type-safe UI code with Swift's powerful type system
- **SwiftUI-Compatible API**: If you know SwiftUI, you already know most of Raven
- **Fast Performance**: WebAssembly provides near-native execution speed
- **Single Codebase**: Share UI logic across platforms (when combined with native SwiftUI)
- **Modern Developer Experience**: Hot reload, error overlays, and a great CLI

### Who Is It For?

Raven is perfect for:

- **Swift Developers** wanting to build web applications
- **iOS Developers** looking to expand to the web
- **Web Developers** interested in type-safe UI development
- **Teams** wanting to share code between native and web platforms

---

## Prerequisites

Before you begin, ensure you have the following installed:

### Required

1. **Swift 6.2 or later**
   - Verify: `swift --version`
   - Download from [swift.org](https://swift.org/download/)

2. **SwiftWasm Toolchain**
   - Required for compiling Swift to WebAssembly
   - Installation instructions below

3. **Basic SwiftUI Knowledge**
   - Familiarity with Views, State, and basic layouts
   - See [Apple's SwiftUI Tutorials](https://developer.apple.com/tutorials/swiftui) if new to SwiftUI

### Recommended

- **carton** - SwiftWasm development tool (recommended over manual toolchain setup)
- **wasm-opt** - WASM optimizer from binaryen (`brew install binaryen`)
- **A modern web browser** - Chrome, Firefox, Safari, or Edge

---

## Installation

### Step 1: Install SwiftWasm Toolchain

#### Option A: Using carton (Recommended)

Carton is the easiest way to get started with SwiftWasm:

```bash
# Install carton
brew install swiftwasm/tap/carton

# Verify installation
carton --version
```

#### Option B: Manual Toolchain Installation

If you prefer to install the toolchain manually:

1. Download the SwiftWasm toolchain from [swiftwasm.org](https://swiftwasm.org)
2. Follow the installation instructions for your platform
3. Verify with: `swift --version` (should show "SwiftWasm")

### Step 2: Clone Raven Repository

```bash
# Clone the Raven repository
git clone https://github.com/yourusername/Raven.git
cd Raven
```

### Step 3: Build Raven CLI

```bash
# Build the CLI tool
swift build -c release

# The executable will be at .build/release/raven
# Optionally, add it to your PATH or create an alias
alias raven='./build/release/raven'
```

For easier access, you can install it globally:

```bash
# Install to /usr/local/bin (requires sudo)
sudo cp .build/release/raven /usr/local/bin/

# Verify installation
raven --help
```

---

## Your First Raven App

Let's create a simple counter app to learn the basics of Raven.

### Step 1: Create a New Project

```bash
# Create a new Raven project
raven create MyFirstApp

# Navigate into the project
cd MyFirstApp
```

You should see output like:

```
✨ Successfully created Raven project: MyFirstApp

Next steps:
  1. cd MyFirstApp
  2. Add Raven dependency to Package.swift
  3. Uncomment Raven imports in source files
  4. raven dev

Happy coding! 🚀
```

### Step 2: Explore the Project Structure

Your new project has the following structure:

```
MyFirstApp/
├── Package.swift              # Swift package manifest
├── Sources/
│   └── MyFirstApp/
│       ├── App.swift          # Main application view
│       └── main.swift         # Entry point
├── Public/
│   ├── index.html             # HTML template
│   └── styles.css             # CSS styles
├── .gitignore
└── README.md
```

**Key Files:**

- **Package.swift**: Defines your project dependencies and build configuration
- **App.swift**: Contains your main application view (similar to SwiftUI's `App` protocol)
- **main.swift**: Entry point that initializes the render coordinator
- **Public/**: Static assets (HTML, CSS, images) copied to the output directory

### Step 3: Add Raven Dependency

Open `Package.swift` and uncomment the Raven dependency:

```swift
dependencies: [
    .package(url: "https://github.com/swiftwasm/JavaScriptKit.git", from: "0.19.0"),
    // Uncomment one of these:
    .package(path: "../Raven"),  // For local development
    // OR
    // .package(url: "https://github.com/yourusername/Raven.git", from: "0.1.0"),
],
```

Also uncomment the Raven imports in the target:

```swift
.executableTarget(
    name: "MyFirstApp",
    dependencies: [
        "Raven",                  // Uncomment this
        "RavenRuntime",           // Uncomment this
        .product(name: "JavaScriptKit", package: "JavaScriptKit")
    ],
    // ...
)
```

### Step 4: Update the App View

Open `Sources/MyFirstApp/App.swift` and replace the content with:

```swift
import Foundation
import Raven

/// Main application view - a simple counter example
@MainActor
struct App: View {
    @State private var count: Int = 0

    var body: some View {
        VStack(spacing: 20) {
            Text("Welcome to MyFirstApp!")
                .font(.title)

            Text("Count: \(count)")
                .font(.headline)

            HStack(spacing: 10) {
                Button("Increment") {
                    count += 1
                }

                Button("Decrement") {
                    count -= 1
                }

                Button("Reset") {
                    count = 0
                }
            }

            Text("Click the buttons to change the counter")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}
```

### Step 5: Update the Entry Point

Open `Sources/MyFirstApp/main.swift` and uncomment the Raven code:

```swift
import Foundation
import JavaScriptKit
import Raven
import RavenRuntime

@MainActor
func main() async {
    print("Starting MyFirstApp...")

    // Create the render coordinator
    let coordinator = RenderCoordinator()

    // Get root container from DOM
    guard let document = JSObject.global.document.object,
          let rootElement = document.getElementById("app").object else {
        print("Error: Could not find #app element in DOM")
        return
    }

    // Set the root container
    coordinator.setRootContainer(rootElement)

    // Render the app
    await coordinator.render(view: App())

    print("MyFirstApp is running!")
}

// Run the main function
await main()
```

### Step 6: Run the Development Server

```bash
raven dev
```

You should see:

```
Starting Raven development server...

[1/5] Performing initial build...
  ✓ Initial build complete (3.45s)
[2/5] Starting HTTP server...
  ✓ HTTP server started on http://localhost:3000
[3/5] Starting hot reload server...
  ✓ Hot reload server started on port 35729
[4/5] Starting file watcher...
  ✓ Watching for changes in /path/to/MyFirstApp/Sources
[5/5] Development server ready!

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  🚀 Raven Development Server
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Server:      http://localhost:3000
  Hot Reload:  ws://localhost:35729
  Project:     /path/to/MyFirstApp
  Output:      /path/to/MyFirstApp/dist
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Press Ctrl+C to stop the server
```

### Step 7: View Your App

Open your browser to [http://localhost:3000](http://localhost:3000)

You should see your counter app with three buttons. Click them to see the count change in real-time!

### Step 8: Make Your First Changes

With the dev server running, try making changes to `App.swift`:

1. Change the title text
2. Add another button
3. Change the spacing or colors

Save the file and watch the browser automatically reload with your changes!

### Step 9: Build for Production

When you're ready to deploy:

```bash
raven build --release
```

This creates an optimized production build in the `dist/` directory:

```
dist/
├── index.html
├── app.wasm
├── runtime.js
└── styles.css
```

Deploy these files to any static hosting service!

---

## Key Concepts

### Views and the View Protocol

In Raven, everything you see is a View. Views are structs that conform to the `View` protocol:

```swift
struct MyView: View {
    var body: some View {
        Text("Hello, Raven!")
    }
}
```

**Key Points:**
- Views are structs (value types)
- They describe what to display, not how to render
- The `body` property returns the view's content
- Views are composable - build complex UIs from simple pieces

### @State - Managing Local State

Use `@State` to create mutable state owned by a view:

```swift
struct CounterView: View {
    @State private var count = 0

    var body: some View {
        VStack {
            Text("Count: \(count)")
            Button("Tap me") {
                count += 1  // Automatically triggers UI update
            }
        }
    }
}
```

**Best Practices:**
- Always mark `@State` as `private`
- Use for simple, view-local state
- Initialize with a default value
- State changes automatically re-render the view

### @Binding - Sharing State

Use `@Binding` to create a two-way connection to state owned by a parent view:

```swift
struct ChildView: View {
    @Binding var isEnabled: Bool

    var body: some View {
        Button(isEnabled ? "Enabled" : "Disabled") {
            isEnabled.toggle()
        }
    }
}

struct ParentView: View {
    @State private var isEnabled = true

    var body: some View {
        ChildView(isEnabled: $isEnabled)  // Pass binding with $
    }
}
```

**Key Points:**
- Use `$` to create a binding from `@State`
- Child views can read and write to the parent's state
- Changes propagate automatically

### Layout Containers

#### VStack - Vertical Layout

Stacks views vertically:

```swift
VStack(spacing: 20) {
    Text("Top")
    Text("Middle")
    Text("Bottom")
}
```

#### HStack - Horizontal Layout

Stacks views horizontally:

```swift
HStack(spacing: 10) {
    Text("Left")
    Text("Center")
    Text("Right")
}
```

#### ZStack - Overlapping Layout

Layers views on top of each other:

```swift
ZStack {
    Rectangle()
        .foregroundColor(.blue)
    Text("Overlay")
        .foregroundColor(.white)
}
```

### Lists and ForEach

Display collections of data:

```swift
struct TodoList: View {
    let todos = ["Buy groceries", "Walk dog", "Write code"]

    var body: some View {
        List {
            ForEach(todos, id: \.self) { todo in
                Text(todo)
            }
        }
    }
}
```

**With Identifiable:**

```swift
struct Todo: Identifiable {
    let id = UUID()
    let title: String
}

struct TodoList: View {
    let todos: [Todo]

    var body: some View {
        List {
            ForEach(todos) { todo in  // No id: needed!
                Text(todo.title)
            }
        }
    }
}
```

### Forms and User Input

Create forms with various input controls:

```swift
struct LoginForm: View {
    @State private var username = ""
    @State private var password = ""
    @State private var rememberMe = false

    var body: some View {
        Form {
            Section {
                TextField("Username", text: $username)
                TextField("Password", text: $password)
            }

            Section {
                Toggle("Remember Me", isOn: $rememberMe)
            }

            Section {
                Button("Login") {
                    // Handle login
                }
            }
        }
    }
}
```

---

## Common Patterns

### State Management with @StateObject

For complex state or business logic, use `@StateObject` with `ObservableObject`:

```swift
class CounterViewModel: ObservableObject {
    @Published var count = 0

    func increment() {
        count += 1
    }

    func decrement() {
        count -= 1
    }

    func reset() {
        count = 0
    }
}

struct CounterView: View {
    @StateObject private var viewModel = CounterViewModel()

    var body: some View {
        VStack {
            Text("Count: \(viewModel.count)")

            HStack {
                Button("−") { viewModel.decrement() }
                Button("Reset") { viewModel.reset() }
                Button("+") { viewModel.increment() }
            }
        }
    }
}
```

### Parent-Child Communication

**Passing Data Down (Props):**

```swift
struct ParentView: View {
    let message = "Hello from parent"

    var body: some View {
        ChildView(message: message)
    }
}

struct ChildView: View {
    let message: String

    var body: some View {
        Text(message)
    }
}
```

**Sending Data Up (Bindings):**

```swift
struct ParentView: View {
    @State private var text = ""

    var body: some View {
        VStack {
            Text("You typed: \(text)")
            TextInputView(text: $text)
        }
    }
}

struct TextInputView: View {
    @Binding var text: String

    var body: some View {
        TextField("Enter text", text: $text)
    }
}
```

### Conditional Rendering

Show or hide views based on state:

```swift
struct ConditionalView: View {
    @State private var showDetails = false

    var body: some View {
        VStack {
            Button("Toggle Details") {
                showDetails.toggle()
            }

            if showDetails {
                Text("Here are the details!")
                    .font(.caption)
            }
        }
    }
}
```

### Dynamic Lists

Create lists from arrays of data:

```swift
struct ShoppingList: View {
    @State private var items = ["Apples", "Bananas", "Oranges"]
    @State private var newItem = ""

    var body: some View {
        VStack {
            HStack {
                TextField("New item", text: $newItem)
                Button("Add") {
                    if !newItem.isEmpty {
                        items.append(newItem)
                        newItem = ""
                    }
                }
            }

            List {
                ForEach(items, id: \.self) { item in
                    Text(item)
                }
            }
        }
    }
}
```

### Navigation Patterns

Navigate between views:

```swift
struct ContentView: View {
    var body: some View {
        NavigationView {
            List {
                NavigationLink("Home", destination: HomeView())
                NavigationLink("Settings", destination: SettingsView())
                NavigationLink("About", destination: AboutView())
            }
            .navigationTitle("Menu")
        }
    }
}

struct HomeView: View {
    var body: some View {
        Text("Home Screen")
            .navigationTitle("Home")
    }
}
```

---

## Troubleshooting

### Common Errors and Solutions

#### Error: "No Package.swift found"

**Problem:** Running `raven` commands in a non-Swift package directory.

**Solution:** Ensure you're in a directory with a valid `Package.swift` file.

#### Error: "Could not find #app element in DOM"

**Problem:** The JavaScript runtime can't find the mounting point.

**Solution:** Check that your `index.html` has a `<div id="app"></div>` element.

#### Error: "Module 'Raven' not found"

**Problem:** Raven dependency not properly configured.

**Solution:**
1. Verify the dependency is added to `Package.swift`
2. Ensure the path or URL is correct
3. Run `swift package update`

### SwiftWasm Compilation Issues

#### Error: "wasm32-unknown-wasi target not found"

**Problem:** SwiftWasm toolchain not installed or not in PATH.

**Solution:**
1. Install SwiftWasm toolchain from [swiftwasm.org](https://swiftwasm.org)
2. Verify with `swift --version` (should show "SwiftWasm")
3. Or use carton: `carton bundle`

#### Build is Very Slow

**Problem:** First builds can be slow due to dependency compilation.

**Solution:**
- Subsequent builds are incremental and much faster
- Use `raven dev` for development (incremental builds)
- Consider using `--release` only for production builds

### Hot Reload Not Working

#### Changes Don't Appear

**Problem:** File watcher not detecting changes or WebSocket connection lost.

**Solution:**
1. Check the console for connection errors
2. Restart the dev server: `Ctrl+C` then `raven dev`
3. Hard refresh the browser: `Cmd+Shift+R` (Mac) or `Ctrl+Shift+R` (Windows/Linux)

#### "Too Many Open Files" Error

**Problem:** File watcher limit exceeded on macOS/Linux.

**Solution:**
```bash
# macOS
sudo sysctl -w kern.maxfiles=65536
sudo sysctl -w kern.maxfilesperproc=65536

# Linux
ulimit -n 65536
```

### WASM Loading Errors

#### "Failed to compile WASM"

**Problem:** Browser doesn't support required WASM features.

**Solution:** Use a modern browser (Chrome 91+, Firefox 89+, Safari 15+, Edge 91+)

#### Large WASM File Size

**Problem:** Debug builds include symbols and are large.

**Solution:**
1. Use `raven build --release` for production
2. Enable optimization: `raven build --release --optimize`
3. Check that wasm-opt is installed: `brew install binaryen`

### Runtime Errors

#### "Type 'X' does not conform to 'View'"

**Problem:** Your view struct doesn't properly implement the View protocol.

**Solution:**
```swift
// ✅ Correct
struct MyView: View {
    var body: some View {
        Text("Hello")
    }
}

// ❌ Incorrect - missing body
struct MyView: View {
    // Missing body property
}
```

#### State Updates Don't Trigger Re-renders

**Problem:** Not using `@State` or mutating state outside of actions.

**Solution:**
```swift
// ✅ Correct
@State private var count = 0
Button("Increment") {
    count += 1  // Triggers update
}

// ❌ Incorrect - regular var
var count = 0  // Won't trigger updates
```

---

## Next Steps

Congratulations! You've created your first Raven app and learned the basics. Here's where to go next:

### Learn More

- **[API Documentation](./API.md)** - Complete API reference for all Raven views and types
- **[State Management Guide](./State.md)** - Deep dive into @State, @Binding, and @StateObject
- **[ForEach and Lists](./ForEach.md)** - Learn how to work with collections
- **[View Modifiers](./Modifiers/README.md)** - Customize view appearance and behavior

### Example Projects

Explore these example projects to see Raven in action:

- **Counter App** - Simple state management (you just built this!)
- **Todo List** - CRUD operations with dynamic lists
- **Weather App** - API integration and async data
- **Photo Gallery** - Working with images and grids
- **Form Builder** - Complex forms with validation

### Community and Support

- **GitHub Repository** - [github.com/yourusername/Raven](https://github.com/yourusername/Raven)
- **Issue Tracker** - Report bugs and request features
- **Discussions** - Ask questions and share your projects

### Advanced Topics

Once you're comfortable with the basics, explore:

- **Custom View Modifiers** - Create reusable styling components
- **Performance Optimization** - Minimize re-renders and reduce bundle size
- **Testing** - Write tests for your Raven views
- **Deployment** - Deploy to Netlify, Vercel, GitHub Pages, and more
- **Integration** - Combine Raven with JavaScript libraries

### Contributing

Raven is open source and welcomes contributions! Check out:

- **Contributing Guide** - Learn how to contribute
- **Architecture Docs** - Understand how Raven works internally
- **Good First Issues** - Start with beginner-friendly tasks

---

## Quick Reference

### Common Commands

```bash
# Create new project
raven create ProjectName

# Start development server
raven dev

# Build for production
raven build --release

# Build with optimization
raven build --release --optimize

# Custom ports
raven dev --port 8080 --hot-reload-port 35730

# Verbose output
raven build --verbose
```

### Project Structure

```
MyProject/
├── Package.swift          # Package configuration
├── Sources/
│   └── MyProject/
│       ├── App.swift      # Main app view
│       └── main.swift     # Entry point
├── Public/
│   ├── index.html         # HTML template
│   └── styles.css         # Stylesheets
├── dist/                  # Build output (generated)
└── README.md
```

### Essential Imports

```swift
import Foundation          // Swift standard library
import Raven              // Views, State, etc.
import RavenRuntime       // RenderCoordinator
import JavaScriptKit      // DOM interop
```

### View Cheat Sheet

```swift
// Primitives
Text("Hello")
Button("Tap") { }
Image("logo")
TextField("Name", text: $name)
Toggle("Enabled", isOn: $enabled)

// Layout
VStack { }           // Vertical
HStack { }           // Horizontal
ZStack { }           // Layered
List { }             // Scrollable list
Form { }             // Form container
Section { }          // Form section

// Iteration
ForEach(items) { item in
    Text(item.name)
}

// Modifiers
.font(.title)
.foregroundColor(.blue)
.padding()
.background(.gray)
```

---

**Happy coding with Raven!** 🚀

For questions or feedback, visit our [GitHub repository](https://github.com/yourusername/Raven) or join the discussion.
