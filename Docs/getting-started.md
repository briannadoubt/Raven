# Getting Started with Raven

Welcome to Raven! This guide will help you build your first SwiftUI app for the web.

## Prerequisites

- **Swift 6.2+** installed
- **WebAssembly toolchain** for Swift
- Basic familiarity with SwiftUI concepts

### Installing Swift for WebAssembly

```bash
# Download from Swift.org
https://www.swift.org/download/

# Verify installation
swift --version
```

## Creating Your First App

### 1. Create a new Swift package

```bash
mkdir MyRavenApp
cd MyRavenApp
swift package init --type executable
```

### 2. Add Raven as a dependency

Edit `Package.swift`:

```swift
// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "MyRavenApp",
    platforms: [.macOS(.v13)],
    dependencies: [
        .package(url: "https://github.com/YourOrg/Raven.git", from: "1.0.0")
    ],
    targets: [
        .executableTarget(
            name: "MyRavenApp",
            dependencies: ["Raven"]
        )
    ]
)
```

### 3. Write your app

Create `Sources/MyRavenApp/main.swift`:

```swift
import Raven

@main
struct MyApp {
    static func main() async {
        await RavenApp(rootView: ContentView()).run()
    }
}

struct ContentView: View {
    @State private var count = 0

    var body: some View {
        VStack(spacing: 20) {
            Text("Welcome to Raven!")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("You've clicked \(count) times")
                .font(.title2)

            Button("Click Me!") {
                count += 1
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(40)
    }
}
```

### 4. Build for WebAssembly

```bash
swift build --triple wasm32-unknown-wasi
```

The compiled `.wasm` file will be in `.build/wasm32-unknown-wasi/debug/`.

### 5. Create an HTML page

Create `index.html`:

```html
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>My Raven App</title>
    <style>
        body {
            margin: 0;
            font-family: -apple-system, system-ui, sans-serif;
        }
        #app {
            width: 100vw;
            height: 100vh;
        }
    </style>
</head>
<body>
    <div id="app"></div>

    <script type="module">
        import { WASMInstantiator } from './JavaScriptKit_JavaScriptKit.resources/Runtime/index.mjs';

        const instantiator = new WASMInstantiator();
        const { instance } = await instantiator.instantiate(
            new URL('./MyRavenApp.wasm', import.meta.url)
        );
    </script>
</body>
</html>
```

### 6. Serve and view

```bash
python3 -m http.server 8000
# Open http://localhost:8000 in your browser
```

## Understanding the Basics

### The View Protocol

All UI components conform to the `View` protocol:

```swift
protocol View {
    associatedtype Body: View
    var body: Self.Body { get }
}
```

Your view's `body` describes what the UI should look like.

### State Management

Use `@State` for local view state:

```swift
struct Counter: View {
    @State private var count = 0  // ← State

    var body: some View {
        Button("Count: \(count)") {
            count += 1  // ← Modifying state updates UI
        }
    }
}
```

### Layout

Stack views vertically or horizontally:

```swift
VStack {  // Vertical stack
    Text("Top")
    Text("Bottom")
}

HStack {  // Horizontal stack
    Text("Left")
    Text("Right")
}
```

### Modifiers

Chain modifiers to style and configure views:

```swift
Text("Hello")
    .font(.title)
    .foregroundColor(.blue)
    .padding()
    .background(Color.gray.opacity(0.2))
    .cornerRadius(8)
```

## Next Steps

### Learn Core Concepts

- **[State Management](./concepts/state-management.md)** - @State, @Binding, @ObservedObject
- **[Layout](./concepts/layout.md)** - Stacks, grids, alignment
- **[Navigation](./concepts/navigation.md)** - Multi-screen apps
- **[Animation](./concepts/animation.md)** - Smooth transitions

### Explore Examples

- [Hello World](../Examples/HelloWorld/) - Basic app structure
- [Todo List](../Examples/TodoList/) - Forms and lists
- [Animation Gallery](../Examples/Animation/) - Interactive animations

### API Reference

- [Views API](./API/Views.md) - All built-in views
- [Modifiers API](./API/Modifiers.md) - Styling and layout
- [State API](./API/State.md) - State management
- [Advanced Features](./API/Overview.md) - Canvas, WebGL, WebRTC

## Common Patterns

### Form with Validation

```swift
struct LoginForm: View {
    @State private var email = ""
    @State private var password = ""

    var body: some View {
        VStack(spacing: 16) {
            TextField("Email", text: $email)
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)

            SecureField("Password", text: $password)

            Button("Log In") {
                login()
            }
            .disabled(email.isEmpty || password.isEmpty)
        }
        .padding()
    }

    func login() {
        // Handle login
    }
}
```

### List with Navigation

```swift
struct ItemList: View {
    let items = ["Apple", "Banana", "Cherry"]

    var body: some View {
        NavigationView {
            List(items, id: \.self) { item in
                NavigationLink(destination: DetailView(item: item)) {
                    Text(item)
                }
            }
            .navigationTitle("Fruits")
        }
    }
}
```

### Animated Transitions

```swift
struct AnimatedView: View {
    @State private var isExpanded = false

    var body: some View {
        VStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.blue)
                .frame(height: isExpanded ? 200 : 100)
                .animation(.spring(), value: isExpanded)

            Button("Toggle") {
                isExpanded.toggle()
            }
        }
    }
}
```

## Troubleshooting

### Build Issues

**Problem**: Build fails with "No such module 'Raven'"

**Solution**: Ensure Raven is listed in dependencies in Package.swift

**Problem**: WASM file is too large

**Solution**: Build in release mode:
```bash
swift build -c release --triple wasm32-unknown-wasi -Xswiftc -Osize
```

### Runtime Issues

**Problem**: App doesn't load in browser

**Solution**: Check browser console for errors. Ensure you're serving from a web server (not file://).

**Problem**: State changes don't update UI

**Solution**: Ensure you're using `@State` and modifying it correctly:
```swift
// ✅ Correct
@State private var count = 0
count += 1

// ❌ Wrong
var count = 0  // Not @State
count += 1
```

## Getting Help

- **Documentation**: [API Reference](./API/Overview.md)
- **Examples**: [Example Apps](../Examples/)
- **Community**: [GitHub Discussions](https://github.com/YourOrg/Raven/discussions)
- **Issues**: [Report a bug](https://github.com/YourOrg/Raven/issues)

---

**Ready to build something amazing? Let's go! 🚀**
