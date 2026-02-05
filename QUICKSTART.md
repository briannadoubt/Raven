# Raven Quick Start Guide

A step-by-step walkthrough for building and running your first Raven app.

## Prerequisites

### Install SwiftWasm Toolchain

Raven compiles to WebAssembly, so you need the SwiftWasm toolchain:

```bash
# Install SwiftWasm (choose one method)

# Method 1: Using the installer script (recommended)
curl -sSf https://raw.githubusercontent.com/swiftwasm/swiftwasm/main/install-toolchain.sh | bash

# Method 2: Using Homebrew
brew install swiftwasm/tap/swiftwasm

# Method 3: Download from GitHub Releases
# Visit: https://github.com/swiftwasm/swift/releases
# Download the latest .pkg for macOS or .tar.gz for Linux
```

**Verify installation:**
```bash
swift --version
# Should show: SwiftWasm Swift version x.x.x
```

If you see "Apple Swift" instead of "SwiftWasm Swift", set the toolchain:

```bash
# Add to ~/.zshrc or ~/.bashrc
export PATH="/Library/Developer/Toolchains/swift-wasm-DEVELOPMENT-SNAPSHOT-2024-XX-XX-a.xctoolchain/usr/bin:$PATH"

# Then reload
source ~/.zshrc
```

---

## Option 1: Quick Demo (5 minutes)

### Step 1: Create a New App

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

### Step 2: Write Your App

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

    var body: some View {
        VStack(spacing: 20) {
            Text("Hello, Raven! 🚀")
                .font(.largeTitle)
                .foregroundColor(.blue)

            Text("Count: \(count)")
                .font(.title)

            HStack {
                Button("-") { count -= 1 }
                    .buttonStyle(.bordered)

                Button("Reset") { count = 0 }
                    .buttonStyle(.borderedProminent)

                Button("+") { count += 1 }
                    .buttonStyle(.bordered)
            }
        }
        .padding(40)
    }
}
EOF
```

### Step 3: Build for WASM

```bash
# Build for WebAssembly
swift build --triple wasm32-unknown-wasi -c release

# The .wasm file is at:
# .build/wasm32-unknown-wasi/release/MyRavenApp.wasm
```

**What happens during build:**
1. Swift compiler compiles your code to WASM bytecode
2. Links with Raven framework and JavaScriptKit
3. Outputs a `.wasm` binary (typically 500KB-1MB for simple apps)
4. Takes 10-30 seconds for first build, 1-5 seconds for incremental

### Step 4: Create HTML Wrapper

```bash
cat > index.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>My Raven App</title>
    <style>
        body {
            margin: 0;
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
        }
        #root {
            width: 100vw;
            height: 100vh;
        }
    </style>
</head>
<body>
    <div id="root"></div>

    <script type="module">
        // Import JavaScriptKit runtime
        import { SwiftRuntime } from 'https://cdn.jsdelivr.net/npm/javascript-kit-swift@0.19.2/Runtime/index.js'

        // Initialize Swift runtime
        const swift = await SwiftRuntime()

        // Load your WASM module
        await swift.setInstance(
            await WebAssembly.instantiateStreaming(
                fetch('./.build/wasm32-unknown-wasi/release/MyRavenApp.wasm'),
                swift.wasmImports
            )
        )

        // Start your app
        swift.main()
    </script>
</body>
</html>
EOF
```

### Step 5: Serve and View

```bash
# Start a local web server
python3 -m http.server 8000

# Open in browser
open http://localhost:8000
```

**You should see:**
- "Hello, Raven! 🚀" title in blue
- A counter showing "Count: 0"
- Three buttons: -, Reset, +
- Clicking buttons updates the counter instantly!

---

## Option 2: Using Raven CLI (Recommended)

The Raven CLI handles all the build complexity for you.

### Step 1: Build the CLI

```bash
# Clone Raven (if you haven't)
git clone https://github.com/briannadoubt/Raven.git
cd Raven

# Build the CLI tool
swift build -c release --product raven

# Install globally
sudo cp .build/release/raven /usr/local/bin/
```

### Step 2: Create a Project

```bash
# Create new project from template
raven create my-app
cd my-app
```

**Generated structure:**
```
my-app/
├── Package.swift
├── Sources/
│   └── main.swift
├── Public/
│   └── favicon.ico
└── README.md
```

### Step 3: Start Development Server

```bash
# Start dev server with hot reload
raven dev

# Server starts on http://localhost:3000
# Opens automatically in your browser
```

**Features:**
- ✅ **Auto-rebuild** - Changes to .swift files trigger rebuild
- ✅ **Hot reload** - Browser refreshes automatically
- ✅ **Build metrics** - See rebuild time in console
- ✅ **Error overlay** - Compilation errors shown in browser

### Step 4: Make Changes

Open `Sources/main.swift` and edit:

```swift
Text("Count: \(count)")
    .font(.title)
    .foregroundColor(count > 10 ? .red : .primary) // Add color
```

**Save the file → Browser updates instantly!**

### Step 5: Build for Production

```bash
# Production build with optimizations
raven build \
  --optimize-size \
  --optimize \
  --compress

# Output in dist/
```

**Result:**
```
dist/
├── index.html           # Your app page
├── app.wasm             # Optimized WASM (400-600KB)
├── app.wasm.br          # Brotli compressed (150-250KB)
├── runtime.js           # Swift/JS bridge
└── assets/              # Images, fonts, etc.
```

---

## Option 3: Try Existing Examples

The Raven repo includes several ready-to-run examples.

### HelloWorld Example

```bash
cd /path/to/Raven/Examples/HelloWorld

# Build
swift build --triple wasm32-unknown-wasi

# The example includes its own index.html
python3 -m http.server 8000
open http://localhost:8000
```

### TodoList Example

```bash
cd /path/to/Raven/Examples/TodoList

# Build
swift build --triple wasm32-unknown-wasi

# Serve
python3 -m http.server 8000
open http://localhost:8000
```

**Features:**
- Add/complete/delete todos
- Filter completed items
- localStorage persistence (todos survive refresh!)

### Animation Example

```bash
cd /path/to/Raven/Examples/Animation

# Build
swift build --triple wasm32-unknown-wasi

# Serve
python3 -m http.server 8000
open http://localhost:8000
```

**Features:**
- Spring animations
- Rotation and scaling
- Color transitions
- Interactive sliders

---

## Troubleshooting

### "No available targets compatible with wasm32-unknown-wasi"

**Problem:** Standard Swift toolchain doesn't support WASM.

**Solution:** Install SwiftWasm (see Prerequisites above).

```bash
# Verify you have SwiftWasm
swift --version | grep -i wasm

# Should output: SwiftWasm Swift version...
```

### Build is Very Slow

**First build takes 20-60 seconds** - Swift needs to compile all dependencies.

**Speed it up:**
```bash
# Use debug build (faster compile, larger binary)
swift build --triple wasm32-unknown-wasi

# Use release build only for production
swift build --triple wasm32-unknown-wasi -c release -Xswiftc -Osize
```

### WASM File is Too Large

**Typical sizes:**
- Debug: 3-5 MB
- Release: 800KB - 1.5 MB
- Release + Osize: 400-600 KB
- Compressed (Brotli): 150-250 KB

**Optimize:**
```bash
# Enable all optimizations
swift build \
  --triple wasm32-unknown-wasi \
  -c release \
  -Xswiftc -Osize \
  -Xswiftc -whole-module-optimization

# Then strip debug symbols
wasm-strip .build/wasm32-unknown-wasi/release/MyApp.wasm

# Optional: wasm-opt (requires binaryen)
wasm-opt -O3 input.wasm -o output.wasm
```

### "Cannot find 'RavenApp' in scope"

**Problem:** Missing import or wrong dependency.

**Solution:**
```swift
import Raven  // Must be first line

@main
struct MyApp {
    static func main() async {
        await RavenApp { /* ... */ }.run()
    }
}
```

### Page Shows "Loading..." Forever

**Problem:** WASM failed to load or initialize.

**Solution:** Open browser console (Cmd+Option+I on Mac) and check for:
- 404 errors (WASM file not found)
- MIME type errors (server not serving .wasm correctly)
- JavaScript errors (runtime issue)

**Fix MIME types:**
```bash
# Python server handles .wasm correctly by default

# If using custom server, ensure:
# Content-Type: application/wasm
```

### Hot Reload Not Working

**Problem:** WebSocket connection failed.

**Solution:**
```bash
# Check if dev server is running
curl http://localhost:35729

# Restart with verbose logging
raven dev --verbose

# Use different port if 35729 is taken
raven dev --hot-reload-port 35730
```

---

## Next Steps

### Learn by Example

```bash
cd Raven/Examples
ls -la

# Try these in order:
# 1. HelloWorld - Basic counter
# 2. TodoList - Forms and lists
# 3. Animation - Animations and effects
```

### Read the Docs

- **API Reference:** `Raven/Docs/API.md`
- **Build & Deploy:** `Raven/BUILDING_AND_DEPLOYMENT.md`
- **Best Practices:** `Raven/Docs/best-practices.md`

### Build Something!

**Ideas for first projects:**
- **Calculator** - Buttons, state, math operations
- **Quiz App** - Multiple choice, score tracking
- **Habit Tracker** - Daily checkboxes, localStorage
- **Color Picker** - Sliders, real-time preview
- **Markdown Previewer** - Text input, live rendering
- **Weather Dashboard** - Fetch API, async data

### Join the Community

- **GitHub:** https://github.com/briannadoubt/Raven
- **Issues:** Report bugs or request features
- **Discussions:** Ask questions, share projects
- **Contributing:** Help build the future of Raven!

---

## Common Workflows

### Development Loop

```bash
# Terminal 1: Watch mode (future feature)
raven dev --watch

# Terminal 2: Your editor
code Sources/main.swift

# Make changes → Save → Browser refreshes automatically
```

### Production Deployment

```bash
# 1. Build optimized bundle
raven build --optimize-size --compress

# 2. Deploy to host
netlify deploy --dir=dist --prod

# Or upload dist/ to:
# - Vercel
# - GitHub Pages
# - Cloudflare Pages
# - AWS S3 + CloudFront
# - Any static host!
```

### Testing Changes

```bash
# Quick test
swift build --triple wasm32-unknown-wasi && python3 -m http.server 8000

# Full test with optimizations
raven build && cd dist && python3 -m http.server 8000
```

---

## Performance Tips

### Fast Iteration

```bash
# Use debug builds during development
swift build --triple wasm32-unknown-wasi

# Saves 10-20 seconds per build
```

### Smaller Bundles

```swift
// Avoid heavy dependencies
// ❌ Bad
import HugeLibrary  // Adds 500KB

// ✅ Good
// Implement simple features yourself
func simpleHash(_ string: String) -> Int {
    // Custom implementation
}
```

### Faster Load Times

```html
<!-- Preload WASM for instant startup -->
<link rel="preload" href="/app.wasm" as="fetch" crossorigin>

<!-- Use Brotli compression -->
<script>
    const wasmURL = '/app.wasm.br'  // 3x smaller than .wasm
    // Browser automatically decompresses
</script>
```

---

**Ready to build amazing web apps with Swift? Let's go! 🚀**
