# Building and Deploying Raven Apps

A complete guide to building UX with Raven and deploying to production.

## Table of Contents

1. [Quick Start](#quick-start)
2. [Creating a New App](#creating-a-new-app)
3. [Building Your UX](#building-your-ux)
4. [Development Workflow](#development-workflow)
5. [Production Build](#production-build)
6. [Deployment Options](#deployment-options)
7. [Performance Optimization](#performance-optimization)

---

## Quick Start

### Prerequisites

```bash
# Install Swift with WASM support
# macOS: Install Xcode or Swift from swift.org
# Linux: Install Swift 6.0+

# Install WASM toolchain
curl -sSf https://raw.githubusercontent.com/swiftwasm/swiftwasm/main/install-toolchain.sh | bash

# Install the Raven CLI (optional, but recommended)
swift build -c release --product raven
cp .build/release/raven /usr/local/bin/
```

### 30-Second Demo

```bash
# 1. Create a new app
raven create my-app
cd my-app

# 2. Start development server with hot reload
raven dev

# 3. Open http://localhost:3000 in your browser
# Changes to .swift files automatically reload! 🔥
```

---

## Creating a New App

### Option 1: Using Raven CLI (Recommended)

```bash
# Create from default template
raven create my-awesome-app

# Available templates:
raven create my-app --template default        # Basic app
raven create my-app --template dashboard      # Dashboard with charts
raven create my-app --template form-app       # Form-heavy app
```

This creates:
```
my-app/
├── Package.swift           # Swift package manifest
├── Sources/
│   └── App/
│       └── main.swift      # App entry point
├── Public/                 # Static assets (images, fonts, etc.)
│   └── favicon.ico
└── README.md
```

### Option 2: Manual Setup

Create a `Package.swift`:

```swift
// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "MyApp",
    platforms: [.macOS(.v13)],
    dependencies: [
        .package(url: "https://github.com/briannadoubt/Raven.git", from: "0.1.0")
    ],
    targets: [
        .executableTarget(
            name: "App",
            dependencies: ["Raven"]
        )
    ]
)
```

Create `Sources/App/main.swift`:

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
            Text("Hello, Raven!")
                .font(.largeTitle)

            Text("Count: \(count)")

            Button("Increment") {
                count += 1
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}
```

---

## Building Your UX

### App Structure

Every Raven app has:

1. **Entry Point** - `@main` struct with `RavenApp`
2. **Root View** - Your main UI component
3. **State Management** - `@State`, `@Binding`, `@ObservableObject`
4. **Navigation** - NavigationStack, sheets, alerts
5. **Assets** - Public/ directory for images, fonts, etc.

### Example: Complete Todo App

```swift
import Raven

@main
struct TodoApp {
    static func main() async {
        await RavenApp(rootView: TodoListView()).run()
    }
}

// MARK: - Models

struct Todo: Identifiable, Codable {
    let id = UUID()
    var title: String
    var isCompleted = false
    var createdAt = Date()
}

// MARK: - Main View

struct TodoListView: View {
    @State private var todos: [Todo] = []
    @State private var newTodoText = ""
    @State private var showCompleted = true

    var filteredTodos: [Todo] {
        showCompleted ? todos : todos.filter { !$0.isCompleted }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header with stats
                headerView

                // Todo list
                List {
                    ForEach(filteredTodos) { todo in
                        TodoRow(
                            todo: todo,
                            onToggle: { toggleTodo(todo) },
                            onDelete: { deleteTodo(todo) }
                        )
                    }
                }

                // Input bar
                inputBar
            }
            .navigationTitle("My Tasks")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Toggle("Show Completed", isOn: $showCompleted)
                        .toggleStyle(.switch)
                }
            }
        }
        .onAppear(perform: loadTodos)
    }

    // MARK: - Subviews

    private var headerView: some View {
        HStack {
            Text("\(todos.filter { !$0.isCompleted }.count) remaining")
                .font(.headline)
                .foregroundColor(.secondary)

            Spacer()

            if !todos.isEmpty {
                Button("Clear Completed", role: .destructive) {
                    clearCompleted()
                }
                .font(.caption)
            }
        }
        .padding()
        .background(Color(.systemGroupedBackground))
    }

    private var inputBar: some View {
        HStack(spacing: 12) {
            TextField("New todo", text: $newTodoText)
                .textFieldStyle(.roundedBorder)
                .onSubmit(addTodo)

            Button(action: addTodo) {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
            }
            .disabled(newTodoText.isEmpty)
        }
        .padding()
        .background(Color(.systemBackground))
        .shadow(radius: 2)
    }

    // MARK: - Actions

    private func addTodo() {
        guard !newTodoText.isEmpty else { return }

        let todo = Todo(title: newTodoText)
        todos.insert(todo, at: 0)
        newTodoText = ""
        saveTodos()
    }

    private func toggleTodo(_ todo: Todo) {
        if let index = todos.firstIndex(where: { $0.id == todo.id }) {
            todos[index].isCompleted.toggle()
            saveTodos()
        }
    }

    private func deleteTodo(_ todo: Todo) {
        todos.removeAll { $0.id == todo.id }
        saveTodos()
    }

    private func clearCompleted() {
        todos.removeAll { $0.isCompleted }
        saveTodos()
    }

    // MARK: - Persistence (localStorage in browser)

    private func loadTodos() {
        // Use browser's localStorage API via JavaScriptKit
        if let data = LocalStorage.getItem("todos"),
           let decoded = try? JSONDecoder().decode([Todo].self, from: Data(data.utf8)) {
            todos = decoded
        }
    }

    private func saveTodos() {
        if let encoded = try? JSONEncoder().encode(todos),
           let json = String(data: encoded, encoding: .utf8) {
            LocalStorage.setItem("todos", json)
        }
    }
}

// MARK: - Todo Row Component

struct TodoRow: View {
    let todo: Todo
    let onToggle: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onToggle) {
                Image(systemName: todo.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundColor(todo.isCompleted ? .green : .gray)
            }

            Text(todo.title)
                .strikethrough(todo.isCompleted)
                .foregroundColor(todo.isCompleted ? .secondary : .primary)

            Spacer()

            Button(action: onDelete) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - LocalStorage Helper

enum LocalStorage {
    static func getItem(_ key: String) -> String? {
        // Use JavaScriptKit to access browser localStorage
        let storage = JSObject.global.localStorage
        return storage.getItem(key).string
    }

    static func setItem(_ key: String, _ value: String) {
        let storage = JSObject.global.localStorage
        _ = storage.setItem(key, value)
    }
}
```

### Key Concepts

**1. State Management**
```swift
@State private var count = 0              // Local state
@Binding var isPresented: Bool            // Two-way binding
@ObservableObject var viewModel: VM       // Observable object
@Environment(\.colorScheme) var scheme    // Environment value
```

**2. Layout**
```swift
VStack { /* vertical */ }
HStack { /* horizontal */ }
ZStack { /* layered */ }
Grid { /* 2D grid */ }
ScrollView { /* scrollable */ }
```

**3. Navigation**
```swift
NavigationStack {
    List {
        NavigationLink("Detail", value: item)
    }
    .navigationDestination(for: Item.self) { item in
        DetailView(item: item)
    }
}
```

**4. Modals**
```swift
.sheet(isPresented: $showSheet) { SheetView() }
.alert("Title", isPresented: $showAlert) { Button("OK") { } }
.popover(isPresented: $showPopover) { PopoverView() }
```

---

## Development Workflow

### Start Dev Server

```bash
# Default (localhost:3000)
raven dev

# Custom port and host
raven dev --port 8080 --host 0.0.0.0

# Enable verbose logging
raven dev --verbose

# Custom hot reload port
raven dev --hot-reload-port 35730
```

The dev server provides:
- ✅ **Hot Module Reload** - Changes update instantly without full refresh
- ✅ **Source Watching** - Automatically rebuilds on .swift file changes
- ✅ **Build Metrics** - Shows rebuild time in console
- ✅ **Error Overlay** - Compilation errors displayed in browser
- ✅ **HTTP Server** - Serves your app on localhost

### Manual Build (without CLI)

```bash
# Build for WASM
swift build --triple wasm32-unknown-wasi

# The WASM binary is at:
# .build/wasm32-unknown-wasi/debug/App.wasm

# Serve with any HTTP server
python3 -m http.server 8000
# OR
npx serve .
# OR
php -S localhost:8000
```

Create a minimal `index.html`:

```html
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>My Raven App</title>
</head>
<body>
    <div id="root"></div>
    <script type="module">
        import { SwiftRuntime } from './runtime.js'

        const swift = await SwiftRuntime()
        await swift.loadWASM('./App.wasm')
        swift.run()
    </script>
</body>
</html>
```

---

## Production Build

### Build with Raven CLI

```bash
# Production build with all optimizations
raven build

# Options:
raven build \
  --input ./MyApp \
  --output ./dist \
  --optimize-size \      # -Osize optimization
  --optimize \           # wasm-opt (requires binaryen)
  --strip-debug \        # Remove debug symbols (default: true)
  --compress \           # Generate .br Brotli bundle
  --report-size          # Show bundle size report (default: true)
```

**Build Output (`dist/`):**
```
dist/
├── index.html          # Generated HTML with runtime
├── app.wasm            # Optimized WASM binary
├── app.wasm.br         # Brotli compressed (if --compress)
├── runtime.js          # Swift/JS bridge
└── assets/             # Static assets from Public/
```

### Manual Production Build

```bash
# Compile with size optimization
swift build \
  --triple wasm32-unknown-wasi \
  -c release \
  -Xswiftc -Osize \
  -Xswiftc -whole-module-optimization

# Optional: Optimize with wasm-opt (install binaryen first)
wasm-opt .build/release/App.wasm -O3 -o dist/app.wasm

# Optional: Strip debug symbols (install wabt first)
wasm-strip dist/app.wasm

# Optional: Compress with Brotli
brotli -q 11 dist/app.wasm  # Creates app.wasm.br
```

### Optimization Results

Typical bundle sizes:
- **Debug**: 3-5 MB (with debug symbols)
- **Release**: 800KB - 1.5 MB (basic optimization)
- **Release + -Osize**: 500KB - 800KB (size optimization)
- **Release + wasm-opt**: 400KB - 600KB (advanced optimization)
- **Brotli compressed**: 150KB - 250KB (gzip: 200KB - 350KB)

**Example from BundleSizeAnalyzer:**
```
Bundle Size Report
==================================================

Uncompressed: 523 KB
Brotli:       187 KB (35.8%)
Gzip:         234 KB (44.7%)

✓ Target met! Under by 23 KB
```

---

## Deployment Options

### 1. Static Hosting (Easiest)

Deploy the `dist/` folder to any static host:

#### Netlify

```bash
# netlify.toml
[build]
  command = "raven build"
  publish = "dist"

[[headers]]
  for = "/*.wasm"
  [headers.values]
    Content-Type = "application/wasm"

[[headers]]
  for = "/*.br"
  [headers.values]
    Content-Encoding = "br"
```

```bash
# Deploy
netlify deploy --prod
```

#### Vercel

```bash
# vercel.json
{
  "buildCommand": "raven build",
  "outputDirectory": "dist",
  "headers": [
    {
      "source": "/(.*).wasm",
      "headers": [
        { "key": "Content-Type", "value": "application/wasm" }
      ]
    }
  ]
}
```

```bash
vercel --prod
```

#### GitHub Pages

```yaml
# .github/workflows/deploy.yml
name: Deploy to GitHub Pages

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v3

      - name: Install SwiftWasm
        run: curl -sSf https://raw.githubusercontent.com/swiftwasm/swiftwasm/main/install-toolchain.sh | bash

      - name: Build
        run: raven build --output dist

      - name: Deploy to GitHub Pages
        uses: peaceiris/actions-gh-pages@v3
        with:
          github_token: ${{ secrets.GITHUB_TOKEN }}
          publish_dir: ./dist
```

#### Cloudflare Pages

```bash
# Build command: raven build
# Output directory: dist

# Automatic deployment on git push
```

### 2. CDN Deployment

Upload to S3/CloudFront, Azure Blob, GCS, etc.:

```bash
# AWS S3 + CloudFront
raven build
aws s3 sync dist/ s3://my-bucket/ --delete
aws cloudfront create-invalidation --distribution-id XXX --paths "/*"
```

### 3. Docker Container

```dockerfile
# Dockerfile
FROM swift:6.0 AS builder
RUN curl -sSf https://raw.githubusercontent.com/swiftwasm/swiftwasm/main/install-toolchain.sh | bash
WORKDIR /app
COPY . .
RUN raven build --output /app/dist

FROM nginx:alpine
COPY --from=builder /app/dist /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
```

```nginx
# nginx.conf
server {
    listen 80;
    root /usr/share/nginx/html;

    location / {
        try_files $uri $uri/ /index.html;
    }

    location ~* \.wasm$ {
        types { application/wasm wasm; }
        add_header Cache-Control "public, max-age=31536000, immutable";
    }
}
```

### 4. Serverless Functions (Advanced)

For apps needing backend APIs, combine with serverless functions:

**Vercel:**
```
project/
├── api/                # Serverless functions (Node.js, Python, Go)
│   └── todos.ts       # API endpoint
├── dist/              # Raven app
└── vercel.json
```

**Netlify:**
```
project/
├── functions/         # Netlify Functions
│   └── api.js
└── dist/             # Raven app
```

---

## Performance Optimization

### 1. Bundle Size

```bash
# Enable all size optimizations
raven build \
  --optimize-size \
  --optimize \
  --strip-debug \
  --compress
```

**Code-level optimizations:**
```swift
// ❌ Avoid expensive types in hot paths
struct HeavyView: View {
    var body: some View {
        // Triggers full re-render on every change
        expensiveComputation()
    }
}

// ✅ Cache computed values
struct OptimizedView: View {
    @State private var cachedValue: String = ""

    var body: some View {
        Text(cachedValue)
            .onAppear {
                cachedValue = expensiveComputation()
            }
    }
}
```

### 2. Lazy Loading

```swift
// Load heavy views on demand
LazyVStack {
    ForEach(items) { item in
        ItemRow(item: item)  // Only rendered when scrolled into view
    }
}

// Lazy load images
AsyncImage(url: imageURL) { image in
    image.resizable().aspectRatio(contentMode: .fit)
} placeholder: {
    ProgressView()
}
```

### 3. Asset Optimization

```bash
# Optimize images before adding to Public/
# PNG
pngquant --quality 65-80 image.png
optipng -o7 image.png

# JPEG
jpegoptim --max=85 image.jpg

# Use WebP for modern browsers
cwebp -q 80 image.jpg -o image.webp
```

### 4. Caching Strategy

```html
<!-- index.html with aggressive caching -->
<script type="module">
    import { SwiftRuntime } from './runtime.js'

    // Enable service worker for offline support
    if ('serviceWorker' in navigator) {
        navigator.serviceWorker.register('/sw.js')
    }

    const swift = await SwiftRuntime()
    await swift.loadWASM('./app.wasm')
    swift.run()
</script>
```

```javascript
// sw.js - Service Worker for caching
const CACHE_NAME = 'raven-app-v1'
const ASSETS = [
    '/',
    '/index.html',
    '/app.wasm',
    '/runtime.js'
]

self.addEventListener('install', e => {
    e.waitUntil(
        caches.open(CACHE_NAME).then(cache => cache.addAll(ASSETS))
    )
})

self.addEventListener('fetch', e => {
    e.respondWith(
        caches.match(e.request).then(response => response || fetch(e.request))
    )
})
```

### 5. Performance Monitoring

```swift
// Add performance tracking
struct ContentView: View {
    var body: some View {
        VStack {
            content
        }
        .onAppear {
            Performance.mark("view-appeared")
        }
    }
}

enum Performance {
    static func mark(_ name: String) {
        let perf = JSObject.global.performance
        _ = perf.mark(name)
    }

    static func measure(_ name: String, start: String, end: String) {
        let perf = JSObject.global.performance
        _ = perf.measure(name, start, end)
    }
}
```

---

## Best Practices

### 1. Project Structure

```
MyApp/
├── Package.swift
├── Sources/
│   └── App/
│       ├── main.swift           # Entry point
│       ├── Models/              # Data models
│       │   └── Todo.swift
│       ├── Views/               # UI components
│       │   ├── TodoListView.swift
│       │   └── TodoRow.swift
│       ├── ViewModels/          # Business logic
│       │   └── TodoViewModel.swift
│       └── Utilities/           # Helpers
│           └── LocalStorage.swift
├── Public/                      # Static assets
│   ├── images/
│   ├── fonts/
│   └── favicon.ico
└── Tests/                       # Unit tests
```

### 2. State Management Patterns

```swift
// ✅ Use @Observable for complex state (Swift 6)
@Observable
class TodoViewModel {
    var todos: [Todo] = []
    var filter: Filter = .all

    func addTodo(_ title: String) {
        todos.append(Todo(title: title))
    }
}

struct ContentView: View {
    @State private var viewModel = TodoViewModel()

    var body: some View {
        List(viewModel.todos) { todo in
            TodoRow(todo: todo)
        }
    }
}
```

### 3. Component Composition

```swift
// Break down complex views into reusable components
struct DashboardView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                HeaderCard()
                StatsGrid()
                RecentActivityList()
                ChartSection()
            }
        }
    }
}
```

### 4. Accessibility

```swift
// Always include accessibility labels
Button(action: delete) {
    Image(systemName: "trash")
}
.accessibilityLabel("Delete item")

// Support Dynamic Type
Text("Title")
    .font(.headline)  // Scales with user preferences
```

---

## Troubleshooting

### Common Issues

**1. WASM binary too large**
```bash
# Solution: Enable size optimization
raven build --optimize-size --optimize --strip-debug
```

**2. Hot reload not working**
```bash
# Solution: Check WebSocket connection
raven dev --verbose  # Shows WebSocket status
```

**3. Assets not loading**
```bash
# Solution: Verify Public/ directory structure
# Assets must be in Public/ to be bundled
```

**4. State not updating**
```swift
// ❌ Problem: Mutating struct without @State
struct ContentView: View {
    var count = 0  // Won't trigger re-render
}

// ✅ Solution: Use @State
struct ContentView: View {
    @State private var count = 0  // Reactive
}
```

### Build Errors

```bash
# Clean build artifacts
rm -rf .build/
swift package clean

# Rebuild
raven build
```

---

## Next Steps

- **Examples**: Check the [Examples](./Examples/) directory for complete apps
- **API Docs**: Browse the [API Documentation](./Docs/)
- **Community**: Join discussions on GitHub
- **Contributing**: Read [CONTRIBUTING.md](./CONTRIBUTING.md)

---

**Built something awesome with Raven? Share it!** 🚀
