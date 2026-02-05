# Swift WASM Examples and Recipes

Practical code examples and recipes for Swift 6.2 WebAssembly development.

## Table of Contents

- [Setup Examples](#setup-examples)
- [Build Configurations](#build-configurations)
- [JavaScript Interop](#javascript-interop)
- [HTML Wrappers](#html-wrappers)
- [CI/CD Configurations](#cicd-configurations)
- [Optimization Recipes](#optimization-recipes)
- [Debugging Snippets](#debugging-snippets)

---

## Setup Examples

### Complete Swift 6.2.3 + WASM SDK Setup

```bash
#!/bin/bash
# setup-swift-wasm.sh - Complete setup script

set -e

echo "🔧 Installing Swiftly..."
if ! command -v swiftly &> /dev/null; then
    brew install swiftly
else
    echo "✅ Swiftly already installed"
fi

echo "📦 Installing Swift 6.2.3..."
swiftly install 6.2.3
swiftly use 6.2.3

echo "🌐 Installing WASM SDK..."
swift sdk install \
  https://download.swift.org/swift-6.2.3-release/wasm-sdk/swift-6.2.3-RELEASE/swift-6.2.3-RELEASE_wasm.artifactbundle.tar.gz \
  --checksum 394040ecd5260e68bb02f6c20aeede733b9b90702c2204e178f3e42413edad2a

echo "✅ Verifying installation..."
swift --version
swift sdk list

echo "🚀 Setup complete! You can now build for WASM:"
echo "   swift build --swift-sdk swift-6.2.3-RELEASE_wasm"
```

### Carton Quick Setup

```bash
#!/bin/bash
# setup-carton.sh - Quick Carton setup

set -e

echo "🔧 Installing Carton..."
brew install swiftwasm/tap/carton

echo "📝 Creating .swift-version..."
echo "wasm-6.0.2-RELEASE" > .swift-version

echo "✅ Setup complete! Start dev server with:"
echo "   carton dev"
```

---

## Build Configurations

### Package.swift for WASM Projects

```swift
// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "MyWasmApp",
    platforms: [
        .macOS(.v13),
        .iOS(.v16)
    ],
    dependencies: [
        .package(
            url: "https://github.com/swiftwasm/JavaScriptKit.git",
            exact: "0.19.2"  // Pinned for Swift 6.0 compatibility
        ),
        .package(
            url: "https://github.com/briannadoubt/Raven.git",
            from: "0.1.0"
        )
    ],
    targets: [
        .executableTarget(
            name: "MyWasmApp",
            dependencies: [
                "Raven",
                .product(name: "JavaScriptKit", package: "JavaScriptKit")
            ],
            swiftSettings: [
                // Size optimization
                .unsafeFlags(["-Osize"], .when(configuration: .release)),
                // Whole module optimization
                .unsafeFlags(["-whole-module-optimization"], .when(configuration: .release)),
            ],
            linkerSettings: [
                // Link-time optimization
                .unsafeFlags(["--lto-O3"], .when(configuration: .release)),
                // Dead code elimination
                .unsafeFlags(["--gc-sections"], .when(configuration: .release)),
                // Strip debug symbols
                .unsafeFlags(["--strip-debug"], .when(configuration: .release)),
            ]
        ),
        .testTarget(
            name: "MyWasmAppTests",
            dependencies: ["MyWasmApp"]
        )
    ]
)
```

### Build Scripts

**Debug build (fast iteration):**
```bash
#!/bin/bash
# build-debug.sh

swift build --swift-sdk swift-6.2.3-RELEASE_wasm
echo "✅ Debug build complete: $(ls -lh .build/wasm32-unknown-wasip1/debug/*.wasm)"
```

**Production build (optimized):**
```bash
#!/bin/bash
# build-release.sh

swift build \
  --swift-sdk swift-6.2.3-RELEASE_wasm \
  -c release \
  -Xswiftc -Osize \
  -Xswiftc -whole-module-optimization

WASM_FILE=".build/wasm32-unknown-wasip1/release/*.wasm"
echo "📦 Release build complete:"
ls -lh $WASM_FILE

# Optional: Post-process optimization
if command -v wasm-opt &> /dev/null; then
    echo "🔧 Running wasm-opt..."
    wasm-opt -O3 $WASM_FILE -o optimized.wasm
    echo "✅ Optimized: $(ls -lh optimized.wasm)"
fi

# Optional: Compress with Brotli
if command -v brotli &> /dev/null; then
    echo "🗜️  Compressing with Brotli..."
    brotli -q 11 optimized.wasm -o optimized.wasm.br
    echo "✅ Compressed: $(ls -lh optimized.wasm.br)"
fi
```

---

## JavaScript Interop

### Calling JavaScript from Swift

```swift
import JavaScriptKit

// Access global objects
let document = JSObject.global.document
let window = JSObject.global.window
let console = JSObject.global.console

// Call JavaScript functions
console.log("Hello from Swift!")

// Create and manipulate DOM elements
let div = document.createElement("div")
div.textContent = "Created from Swift"
div.style.color = "blue"
document.body.appendChild(div)

// Set timeouts
let setTimeout = JSObject.global.setTimeout
_ = setTimeout.function!(JSClosure { _ in
    console.log("Timeout executed!")
    return .undefined
}, 1000)

// Fetch API
let fetch = JSObject.global.fetch
Task {
    let response = await fetch("https://api.example.com/data").object!
    let json = await response.json().object!
    console.log("Fetched:", json)
}
```

### Calling Swift from JavaScript

```swift
import JavaScriptKit

// Export a Swift function to JavaScript
@_expose(wasm, "greet")
public func greet(name: String) -> String {
    return "Hello, \(name) from Swift!"
}

@_expose(wasm, "calculate")
public func calculate(a: Int, b: Int) -> Int {
    return a + b
}

// Export a Swift class
@_expose(wasm, "Counter")
public class Counter {
    private var count = 0

    public init() {}

    @_expose(wasm)
    public func increment() -> Int {
        count += 1
        return count
    }

    @_expose(wasm)
    public func getValue() -> Int {
        return count
    }
}
```

Then use in JavaScript:
```javascript
// Call Swift functions
const greeting = Module.greet("World")
console.log(greeting)  // "Hello, World from Swift!"

const result = Module.calculate(5, 3)
console.log(result)  // 8

// Use Swift classes
const counter = new Module.Counter()
counter.increment()  // 1
counter.increment()  // 2
console.log(counter.getValue())  // 2
```

### LocalStorage Integration

```swift
import JavaScriptKit

struct LocalStorage {
    private static let storage = JSObject.global.localStorage

    static func set<T: Codable>(_ key: String, value: T) throws {
        let encoder = JSONEncoder()
        let data = try encoder.encode(value)
        let json = String(data: data, encoding: .utf8)!
        _ = storage.setItem(key, json)
    }

    static func get<T: Codable>(_ key: String, as type: T.Type) throws -> T? {
        guard let json = storage.getItem(key).string else {
            return nil
        }
        let decoder = JSONDecoder()
        let data = Data(json.utf8)
        return try decoder.decode(type, from: data)
    }

    static func remove(_ key: String) {
        _ = storage.removeItem(key)
    }

    static func clear() {
        _ = storage.clear()
    }
}

// Usage
struct UserSettings: Codable {
    var theme: String
    var fontSize: Int
}

// Save
try? LocalStorage.set("settings", value: UserSettings(theme: "dark", fontSize: 14))

// Load
if let settings = try? LocalStorage.get("settings", as: UserSettings.self) {
    print("Theme: \(settings.theme)")
}

// Remove
LocalStorage.remove("settings")
```

---

## HTML Wrappers

### Minimal HTML Wrapper

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Swift WASM App</title>
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
        import { SwiftRuntime } from 'https://cdn.jsdelivr.net/npm/javascript-kit-swift@0.19.2/Runtime/index.js'

        const swift = await SwiftRuntime()
        const response = await fetch('./app.wasm')
        await swift.setInstance(
            await WebAssembly.instantiateStreaming(response, swift.wasmImports)
        )
        swift.main()
    </script>
</body>
</html>
```

### Production HTML with Loading State

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Swift WASM App</title>
    <link rel="preload" href="/app.wasm" as="fetch" crossorigin>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }

        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
            background: #f5f5f5;
        }

        #root {
            width: 100vw;
            height: 100vh;
        }

        #loading {
            display: flex;
            align-items: center;
            justify-content: center;
            flex-direction: column;
            height: 100vh;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
        }

        .spinner {
            width: 50px;
            height: 50px;
            border: 4px solid rgba(255, 255, 255, 0.3);
            border-top-color: white;
            border-radius: 50%;
            animation: spin 1s linear infinite;
        }

        @keyframes spin {
            to { transform: rotate(360deg); }
        }

        .loading-text {
            margin-top: 20px;
            font-size: 18px;
        }

        #error {
            display: none;
            padding: 20px;
            background: #ff4444;
            color: white;
            text-align: center;
        }
    </style>
</head>
<body>
    <div id="error"></div>
    <div id="loading">
        <div class="spinner"></div>
        <div class="loading-text">Loading Swift WASM...</div>
    </div>
    <div id="root"></div>

    <script type="module">
        try {
            // Show loading state
            const loading = document.getElementById('loading')
            const root = document.getElementById('root')

            // Import Swift runtime
            const { SwiftRuntime } = await import(
                'https://cdn.jsdelivr.net/npm/javascript-kit-swift@0.19.2/Runtime/index.js'
            )

            // Initialize Swift
            const swift = await SwiftRuntime()

            // Load WASM module
            const response = await fetch('./app.wasm')
            if (!response.ok) {
                throw new Error(`Failed to load WASM: ${response.statusText}`)
            }

            // Instantiate WASM
            await swift.setInstance(
                await WebAssembly.instantiateStreaming(response, swift.wasmImports)
            )

            // Hide loading, show app
            loading.style.display = 'none'
            root.style.display = 'block'

            // Start Swift app
            swift.main()

        } catch (error) {
            console.error('Failed to load Swift WASM:', error)
            document.getElementById('error').textContent =
                `Error loading app: ${error.message}`
            document.getElementById('error').style.display = 'block'
            document.getElementById('loading').style.display = 'none'
        }
    </script>
</body>
</html>
```

---

## CI/CD Configurations

### GitHub Actions

```yaml
# .github/workflows/build-wasm.yml
name: Build WASM

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  build:
    runs-on: macos-latest

    steps:
      - uses: actions/checkout@v4

      - name: Install Swiftly
        run: brew install swiftly

      - name: Install Swift 6.2.3
        run: |
          swiftly install 6.2.3
          swiftly use 6.2.3

      - name: Install WASM SDK
        run: |
          swift sdk install \
            https://download.swift.org/swift-6.2.3-release/wasm-sdk/swift-6.2.3-RELEASE/swift-6.2.3-RELEASE_wasm.artifactbundle.tar.gz \
            --checksum 394040ecd5260e68bb02f6c20aeede733b9b90702c2204e178f3e42413edad2a

      - name: Build WASM
        run: |
          swift build --swift-sdk swift-6.2.3-RELEASE_wasm -c release -Xswiftc -Osize

      - name: Upload artifacts
        uses: actions/upload-artifact@v4
        with:
          name: wasm-build
          path: .build/wasm32-unknown-wasip1/release/*.wasm

      - name: Deploy to GitHub Pages
        if: github.ref == 'refs/heads/main'
        uses: peaceiris/actions-gh-pages@v3
        with:
          github_token: ${{ secrets.GITHUB_TOKEN }}
          publish_dir: ./public
```

### Netlify Configuration

```toml
# netlify.toml
[build]
  command = "carton bundle --release"
  publish = ".build/bundle"

[[headers]]
  for = "/*.wasm"
  [headers.values]
    Content-Type = "application/wasm"
    Cache-Control = "public, max-age=31536000, immutable"

[[headers]]
  for = "/*.wasm.br"
  [headers.values]
    Content-Type = "application/wasm"
    Content-Encoding = "br"
    Cache-Control = "public, max-age=31536000, immutable"
```

### Vercel Configuration

```json
{
  "buildCommand": "swift build --swift-sdk swift-6.2.3-RELEASE_wasm -c release && cp .build/wasm32-unknown-wasip1/release/*.wasm public/",
  "outputDirectory": "public",
  "headers": [
    {
      "source": "/(.*).wasm",
      "headers": [
        {
          "key": "Content-Type",
          "value": "application/wasm"
        },
        {
          "key": "Cache-Control",
          "value": "public, max-age=31536000, immutable"
        }
      ]
    }
  ]
}
```

---

## Optimization Recipes

### Maximum Size Optimization

```bash
#!/bin/bash
# optimize-max.sh - Maximum size optimization

set -e

APP_NAME="MyApp"
WASM_PATH=".build/wasm32-unknown-wasip1/release/${APP_NAME}.wasm"

echo "🔨 Building with maximum optimizations..."
swift build \
  --swift-sdk swift-6.2.3-RELEASE_wasm \
  -c release \
  -Xswiftc -Osize \
  -Xswiftc -whole-module-optimization \
  -Xlinker --lto-O3 \
  -Xlinker --gc-sections \
  -Xlinker --strip-debug

echo "📊 Original size:"
ls -lh $WASM_PATH

if command -v wasm-opt &> /dev/null; then
    echo "🔧 Running wasm-opt..."
    wasm-opt -Oz --enable-bulk-memory $WASM_PATH -o "${APP_NAME}_opt.wasm"
    echo "📊 After wasm-opt:"
    ls -lh "${APP_NAME}_opt.wasm"
    WASM_PATH="${APP_NAME}_opt.wasm"
fi

if command -v wasm-strip &> /dev/null; then
    echo "✂️  Stripping symbols..."
    wasm-strip $WASM_PATH
    echo "📊 After stripping:"
    ls -lh $WASM_PATH
fi

if command -v brotli &> /dev/null; then
    echo "🗜️  Compressing with Brotli..."
    brotli -q 11 $WASM_PATH
    echo "📊 Compressed size:"
    ls -lh "${WASM_PATH}.br"
fi

echo "✅ Optimization complete!"
```

### Build Size Comparison Script

```bash
#!/bin/bash
# compare-builds.sh - Compare build sizes

APP_NAME="MyApp"

echo "📊 Building and comparing all configurations..."

# Debug build
swift build --swift-sdk swift-6.2.3-RELEASE_wasm
DEBUG_SIZE=$(stat -f%z ".build/wasm32-unknown-wasip1/debug/${APP_NAME}.wasm")

# Release build
swift build --swift-sdk swift-6.2.3-RELEASE_wasm -c release
RELEASE_SIZE=$(stat -f%z ".build/wasm32-unknown-wasip1/release/${APP_NAME}.wasm")

# Release + Osize
swift build --swift-sdk swift-6.2.3-RELEASE_wasm -c release -Xswiftc -Osize
OSIZE_SIZE=$(stat -f%z ".build/wasm32-unknown-wasip1/release/${APP_NAME}.wasm")

# Format sizes
format_size() {
    numfmt --to=iec-i --suffix=B $1
}

echo ""
echo "Build Size Comparison:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
printf "Debug:          %10s\n" "$(format_size $DEBUG_SIZE)"
printf "Release:        %10s (%.1f%% of debug)\n" "$(format_size $RELEASE_SIZE)" "$(echo "scale=1; $RELEASE_SIZE * 100 / $DEBUG_SIZE" | bc)"
printf "Release+Osize:  %10s (%.1f%% of debug)\n" "$(format_size $OSIZE_SIZE)" "$(echo "scale=1; $OSIZE_SIZE * 100 / $DEBUG_SIZE" | bc)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
```

---

## Debugging Snippets

### Console Logging Wrapper

```swift
import JavaScriptKit

enum Log {
    private static let console = JSObject.global.console

    static func debug(_ items: Any...) {
        console.log("[DEBUG]", items.map { "\($0)" }.joined(separator: " "))
    }

    static func info(_ items: Any...) {
        console.info("[INFO]", items.map { "\($0)" }.joined(separator: " "))
    }

    static func warn(_ items: Any...) {
        console.warn("[WARN]", items.map { "\($0)" }.joined(separator: " "))
    }

    static func error(_ items: Any...) {
        console.error("[ERROR]", items.map { "\($0)" }.joined(separator: " "))
    }

    static func trace() {
        console.trace()
    }
}

// Usage
Log.debug("Starting app")
Log.info("User logged in:", username)
Log.warn("Low memory:", availableMemory)
Log.error("Failed to fetch:", errorMessage)
Log.trace()  // Print stack trace
```

### Performance Measurement

```swift
import JavaScriptKit

struct Performance {
    private static let performance = JSObject.global.performance

    static func now() -> Double {
        return performance.now().number ?? 0
    }

    static func measure<T>(_ name: String, block: () throws -> T) rethrows -> T {
        let start = now()
        defer {
            let duration = now() - start
            Log.info("\(name) took \(String(format: "%.2f", duration))ms")
        }
        return try block()
    }

    static func measureAsync<T>(_ name: String, block: () async throws -> T) async rethrows -> T {
        let start = now()
        defer {
            let duration = now() - start
            Log.info("\(name) took \(String(format: "%.2f", duration))ms")
        }
        return try await block()
    }
}

// Usage
let result = Performance.measure("heavy computation") {
    // ... expensive operation
    return computeValue()
}

let data = await Performance.measureAsync("API fetch") {
    try await fetchData()
}
```

### Memory Debugging

```swift
import JavaScriptKit

struct MemoryDebug {
    static func logMemoryUsage() {
        if let memory = JSObject.global.performance.memory.object {
            let used = memory.usedJSHeapSize.number ?? 0
            let total = memory.totalJSHeapSize.number ?? 0
            let limit = memory.jsHeapSizeLimit.number ?? 0

            let usedMB = used / 1_000_000
            let totalMB = total / 1_000_000
            let limitMB = limit / 1_000_000

            Log.info("""
                Memory Usage:
                  Used:  \(String(format: "%.2f", usedMB)) MB
                  Total: \(String(format: "%.2f", totalMB)) MB
                  Limit: \(String(format: "%.2f", limitMB)) MB
                """)
        }
    }
}

// Usage
MemoryDebug.logMemoryUsage()
```

---

## Advanced Patterns

### Service Worker for Offline Support

```javascript
// sw.js - Service Worker for offline caching
const CACHE_NAME = 'swift-wasm-v1'
const urlsToCache = [
  '/',
  '/index.html',
  '/app.wasm',
  '/runtime.js'
]

self.addEventListener('install', event => {
  event.waitUntil(
    caches.open(CACHE_NAME)
      .then(cache => cache.addAll(urlsToCache))
  )
})

self.addEventListener('fetch', event => {
  event.respondWith(
    caches.match(event.request)
      .then(response => response || fetch(event.request))
  )
})
```

Register in HTML:
```html
<script>
if ('serviceWorker' in navigator) {
    navigator.serviceWorker.register('/sw.js')
        .then(reg => console.log('Service Worker registered'))
        .catch(err => console.error('Service Worker registration failed', err))
}
</script>
```

### WASM Streaming with Progress

```javascript
async function loadWasmWithProgress(url, onProgress) {
    const response = await fetch(url)
    const reader = response.body.getReader()
    const contentLength = +response.headers.get('Content-Length')

    let receivedLength = 0
    let chunks = []

    while (true) {
        const { done, value } = await reader.read()

        if (done) break

        chunks.push(value)
        receivedLength += value.length

        if (onProgress) {
            onProgress(receivedLength, contentLength)
        }
    }

    const blob = new Blob(chunks)
    const arrayBuffer = await blob.arrayBuffer()
    return arrayBuffer
}

// Usage
const wasmBytes = await loadWasmWithProgress('./app.wasm', (loaded, total) => {
    const percent = (loaded / total * 100).toFixed(0)
    console.log(`Loading: ${percent}%`)
    document.getElementById('progress').textContent = `${percent}%`
})
```

---

These examples cover common use cases and can be adapted for specific needs. Refer to project documentation for Raven-specific patterns.
