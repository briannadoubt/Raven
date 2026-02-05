# Raven + Carton Workflow Guide

The complete, modern workflow for building Raven apps using Carton.

## Why Carton?

**Carton** is the official SwiftWasm development tool that handles all the complexity:

✅ **Automatic SwiftWasm Download** - No manual toolchain installation
✅ **Development Server** - Built-in server with hot reload
✅ **Bundle Optimization** - Production builds with size optimization
✅ **Test Runner** - Run Swift tests in the browser
✅ **Zero Configuration** - Works out of the box

---

## Installation

### Install Carton (One-Time Setup)

```bash
# Using Homebrew (recommended)
brew install swiftwasm/tap/carton

# Or using Mint
mint install swiftwasm/carton

# Verify installation
carton --version
# Should show: 1.1.3 or later
```

**That's it!** Carton will automatically download SwiftWasm when you first run it.

---

## Creating a Raven App

### Method 1: From Scratch (Manual)

```bash
# Create project directory
mkdir MyRavenApp
cd MyRavenApp

# Create Package.swift
cat > Package.swift << 'EOF'
// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "MyRavenApp",
    platforms: [.macOS(.v13)],
    dependencies: [
        .package(url: "https://github.com/briannadoubt/Raven.git", from: "0.1.0")
    ],
    targets: [
        .executableTarget(
            name: "MyRavenApp",
            dependencies: ["Raven"],
            path: "Sources"
        )
    ]
)
EOF

# Create source directory
mkdir -p Sources
```

### Method 2: Using Raven CLI (Coming Soon)

```bash
raven create MyRavenApp --template carton
cd MyRavenApp
```

---

## The Development Workflow

### Step 1: Write Your App

```bash
cat > Sources/main.swift << 'EOF'
import Raven

@main
struct MyApp {
    static func main() async {
        await RavenApp {
            ContentView()
        }.run()
    }
}

struct ContentView: View {
    @State private var count = 0
    @State private var text = ""

    var body: some View {
        VStack(spacing: 24) {
            Text("🚀 Raven + Carton")
                .font(.largeTitle)
                .foregroundColor(.blue)

            // Counter
            VStack(spacing: 12) {
                Text("Count: \(count)")
                    .font(.title)

                HStack(spacing: 12) {
                    Button("−") { count -= 1 }
                        .buttonStyle(.bordered)

                    Button("Reset") { count = 0 }
                        .buttonStyle(.borderedProminent)

                    Button("+") { count += 1 }
                        .buttonStyle(.bordered)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)

            Divider()

            // Text Input
            VStack(spacing: 12) {
                TextField("Enter text...", text: $text)
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: 300)

                if !text.isEmpty {
                    Text("You typed: \(text)")
                        .font(.headline)
                        .foregroundColor(.green)
                }
            }
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
EOF
```

### Step 2: Start Development Server

```bash
# Start Carton dev server
carton dev

# Carton will:
# 1. Download SwiftWasm toolchain (first time only - 1.5GB)
# 2. Compile your app to WASM
# 3. Start development server on http://127.0.0.1:8080
# 4. Watch for file changes and rebuild automatically
# 5. Open your browser automatically
```

**Output:**
```
Compiling MyRavenApp wasm32-unknown-wasi debug
Build complete! (15.23s)
Development server started on http://127.0.0.1:8080
Watching for changes...
```

**Your browser opens automatically!** 🎉

### Step 3: Make Changes (Hot Reload)

Edit `Sources/main.swift`:

```swift
Text("Count: \(count)")
    .font(.title)
    .foregroundColor(count > 10 ? .red : .primary)  // Add color
```

**Save → Carton rebuilds → Browser refreshes automatically!** ⚡

---

## Carton Commands

### Development

```bash
# Start dev server (default: http://127.0.0.1:8080)
carton dev

# Custom host and port
carton dev --host 0.0.0.0 --port 3000

# Skip opening browser
carton dev --skip-auto-open

# Verbose output (see all build steps)
carton dev --verbose
```

### Building

```bash
# Debug build (fast compile, large binary)
carton build

# Release build (optimized, smaller binary)
carton build --release

# Release with size optimization
carton build --release -Xswiftc -Osize

# Custom output directory
carton build --output-dir ./dist
```

### Testing

```bash
# Run tests in headless browser
carton test

# Run tests in specific browser
carton test --environment chrome
carton test --environment firefox
carton test --environment safari

# Run specific test
carton test --filter MyTests.testExample
```

### Bundling for Production

```bash
# Create optimized production bundle
carton bundle --release

# Output directory: .build/bundle/
# Contains:
#   - index.html
#   - main.wasm (optimized)
#   - all assets
```

---

## Project Structure

### Basic Structure

```
MyRavenApp/
├── Package.swift           # Swift package manifest
├── Sources/
│   └── main.swift          # App entry point
├── Tests/                  # Unit tests (optional)
│   └── MyAppTests.swift
├── Resources/              # Static assets (optional)
│   ├── images/
│   └── styles/
└── .build/                 # Build artifacts (ignored)
```

### With Resources

```swift
// Package.swift
let package = Package(
    name: "MyRavenApp",
    platforms: [.macOS(.v13)],
    dependencies: [
        .package(url: "https://github.com/briannadoubt/Raven.git", from: "0.1.0")
    ],
    targets: [
        .executableTarget(
            name: "MyRavenApp",
            dependencies: ["Raven"],
            path: "Sources",
            resources: [
                .copy("Resources")
            ]
        )
    ]
)
```

Access resources in code:

```swift
// Load image from Resources/images/logo.png
if let logoURL = Bundle.module.url(forResource: "logo", withExtension: "png", subdirectory: "images") {
    AsyncImage(url: logoURL)
}
```

---

## Real-World Example: Todo App

```swift
// Sources/main.swift
import Raven

@main
struct TodoApp {
    static func main() async {
        await RavenApp {
            TodoListView()
        }.run()
    }
}

// MARK: - Model

struct Todo: Identifiable, Codable {
    let id = UUID()
    var title: String
    var isCompleted = false
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
        VStack(spacing: 0) {
            // Header
            header

            // Todo List
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(filteredTodos) { todo in
                        TodoRow(
                            todo: todo,
                            onToggle: { toggleTodo(todo) },
                            onDelete: { deleteTodo(todo) }
                        )
                    }
                }
                .padding()
            }

            // Input Bar
            inputBar
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear(perform: loadTodos)
    }

    // MARK: - Subviews

    private var header: some View {
        HStack {
            Text("\(todos.filter { !$0.isCompleted }.count) tasks")
                .font(.headline)
                .foregroundColor(.secondary)

            Spacer()

            Toggle("Show Completed", isOn: $showCompleted)
                .toggleStyle(.switch)
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
                    .foregroundColor(.blue)
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
        todos.insert(Todo(title: newTodoText), at: 0)
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

    // MARK: - Persistence (localStorage)

    private func loadTodos() {
        // Load from browser localStorage
        if let data = LocalStorage.getString("todos"),
           let decoded = try? JSONDecoder().decode([Todo].self, from: Data(data.utf8)) {
            todos = decoded
        }
    }

    private func saveTodos() {
        // Save to browser localStorage
        if let encoded = try? JSONEncoder().encode(todos),
           let json = String(data: encoded, encoding: .utf8) {
            LocalStorage.setString("todos", json)
        }
    }
}

// MARK: - Todo Row

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
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(8)
    }
}

// MARK: - LocalStorage Helper

enum LocalStorage {
    static func getString(_ key: String) -> String? {
        let storage = JSObject.global.localStorage
        return storage.getItem(key).string
    }

    static func setString(_ key: String, _ value: String) {
        let storage = JSObject.global.localStorage
        _ = storage.setItem(key, value)
    }
}
```

**Run it:**
```bash
carton dev
```

**Features:**
- ✅ Add/complete/delete todos
- ✅ Filter completed items
- ✅ localStorage persistence (survives refresh!)
- ✅ Hot reload during development

---

## Production Deployment

### Step 1: Build Production Bundle

```bash
# Create optimized bundle
carton bundle --release

# Output in .build/bundle/
ls -lh .build/bundle/
# index.html
# main.wasm (400-800KB optimized)
# assets/
```

### Step 2: Deploy to Static Host

#### Netlify

```bash
# netlify.toml
[build]
  command = "carton bundle --release"
  publish = ".build/bundle"

[[headers]]
  for = "/*.wasm"
  [headers.values]
    Content-Type = "application/wasm"
```

```bash
netlify deploy --prod
```

#### Vercel

```bash
# vercel.json
{
  "buildCommand": "carton bundle --release",
  "outputDirectory": ".build/bundle"
}
```

```bash
vercel --prod
```

#### GitHub Pages

```yaml
# .github/workflows/deploy.yml
name: Deploy

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v3

      - name: Install Carton
        run: brew install swiftwasm/tap/carton

      - name: Build
        run: carton bundle --release

      - name: Deploy
        uses: peaceiris/actions-gh-pages@v3
        with:
          github_token: ${{ secrets.GITHUB_TOKEN }}
          publish_dir: ./.build/bundle
```

#### Manual Deploy (Any Host)

```bash
# Build
carton bundle --release

# Upload .build/bundle/ to:
# - AWS S3 + CloudFront
# - Azure Static Web Apps
# - Google Cloud Storage
# - Cloudflare Pages
# - Any static host!
```

---

## Performance Optimization

### Bundle Size Optimization

```bash
# Enable all optimizations
carton bundle --release \
  -Xswiftc -Osize \
  -Xswiftc -whole-module-optimization

# Typical results:
# Debug:   2-3 MB
# Release: 600-900 KB
# Osize:   400-600 KB
```

### Post-Processing

```bash
# After carton bundle, optimize further:

# 1. Strip debug symbols (if needed)
wasm-strip .build/bundle/main.wasm

# 2. Optimize with wasm-opt (requires binaryen)
wasm-opt -O3 .build/bundle/main.wasm -o optimized.wasm

# 3. Compress with Brotli
brotli -q 11 optimized.wasm
# Result: ~150-250 KB (typical)
```

### Cache Strategy

```html
<!-- In your deployed index.html -->
<script type="module">
    // Service worker for offline caching
    if ('serviceWorker' in navigator) {
        navigator.serviceWorker.register('/sw.js')
    }

    // Load WASM with caching
    const response = await fetch('/main.wasm', {
        cache: 'default'  // Browser caches automatically
    })
</script>
```

---

## Troubleshooting

### Carton Not Found

```bash
# Install Carton
brew install swiftwasm/tap/carton

# Or using Mint
mint install swiftwasm/carton

# Verify
carton --version
```

### SwiftWasm Download Fails

```bash
# Clear cache and retry
rm -rf ~/.carton
carton dev

# Or download manually from:
# https://github.com/swiftwasm/swift/releases
```

### Build Errors

```bash
# Clean build
rm -rf .build/
carton build

# Verbose output for debugging
carton build --verbose
```

### Port Already in Use

```bash
# Use different port
carton dev --port 3000

# Or kill existing process
lsof -ti:8080 | xargs kill
```

### Browser Not Opening

```bash
# Skip auto-open and open manually
carton dev --skip-auto-open

# Then open: http://127.0.0.1:8080
```

### Slow Build Times

```bash
# First build downloads toolchain (1.5GB) - takes 5-10 minutes
# Subsequent builds are fast (1-5 seconds incremental)

# To speed up:
# 1. Use debug builds during development
carton dev  # Fast incremental builds

# 2. Only use release for production
carton bundle --release  # Slower but optimized
```

---

## Advanced Configuration

### Custom Carton Configuration

Create `.carton/config.json`:

```json
{
  "defaultPort": 3000,
  "skipAutoOpen": false,
  "customIndexPage": "custom.html",
  "additionalArguments": [
    "-Xswiftc", "-warnings-as-errors"
  ]
}
```

### Custom Index Page

Create `static/index.html`:

```html
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>My Raven App</title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">

    <!-- Custom styles -->
    <style>
        body {
            margin: 0;
            font-family: system-ui;
            background: #f0f0f0;
        }
        #root {
            width: 100vw;
            height: 100vh;
        }
    </style>
</head>
<body>
    <div id="root">Loading...</div>
    <script type="module" src="/main.js"></script>
</body>
</html>
```

Tell Carton to use it:

```bash
carton dev --custom-index-page static/index.html
```

---

## Comparison: Carton vs Manual

| Feature | Carton | Manual (swift build) |
|---------|--------|---------------------|
| SwiftWasm Install | ✅ Automatic | ❌ Manual (complex) |
| Dev Server | ✅ Built-in | ❌ Separate (python/nginx) |
| Hot Reload | ✅ Yes | ❌ Manual refresh |
| Bundle Optimization | ✅ One command | ❌ Multiple tools |
| Test Runner | ✅ Built-in | ❌ Manual setup |
| Zero Config | ✅ Yes | ❌ Complex setup |

**Recommendation: Use Carton for everything!** 🚀

---

## Next Steps

1. **Build Something:** Try the Todo app example above
2. **Read Examples:** Check `Raven/Examples/` directory
3. **Learn Raven:** Read `BUILDING_AND_DEPLOYMENT.md`
4. **Deploy:** Push to Netlify/Vercel/GitHub Pages
5. **Share:** Show off your Raven app!

---

**Carton + Raven = The easiest way to build Swift web apps! 🎉**
