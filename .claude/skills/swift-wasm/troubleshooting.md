# Swift WASM Troubleshooting Guide

Comprehensive troubleshooting for Swift 6.2 WebAssembly development.

## Quick Diagnosis

Run these commands to diagnose your setup:

```bash
# Check Swift version
swift --version
# Expected: Swift version 6.2.3 (swift-6.2.3-RELEASE)
# NOT: Apple Swift version...

# Check WASM SDK
swift sdk list
# Expected: swift-6.2.3-RELEASE_wasm

# Check Carton
carton --version
# Expected: 1.1.3 or later

# Check build output
ls -lh .build/wasm32-unknown-wasip1/*/YourApp.wasm
# Expected: File exists with reasonable size
```

---

## Setup Issues

### Issue: "command not found: swiftly"

**Symptoms:**
```bash
$ swiftly --version
zsh: command not found: swiftly
```

**Diagnosis:**
Swiftly is not installed.

**Solution:**
```bash
# Install via Homebrew
brew install swiftly

# Verify
swiftly --version
```

**Alternative:**
Download from [GitHub releases](https://github.com/swiftlang/swiftly/releases)

---

### Issue: "No available targets compatible with wasm32-unknown-wasip1"

**Symptoms:**
```
error: compiling for WebAssembly requires a Swift SDK
No available targets compatible with triple wasm32-unknown-wasip1
```

**Diagnosis:**
Either:
1. Using Apple's Xcode Swift instead of swift.org Swift
2. WASM SDK not installed

**Solution 1: Check Swift source**
```bash
# Check which Swift you're using
swift --version

# If it says "Apple Swift" - you need swift.org Swift
brew install swiftly
swiftly install 6.2.3
swiftly use 6.2.3

# Verify - should NOT say "Apple"
swift --version
```

**Solution 2: Install WASM SDK**
```bash
# Install the SDK
swift sdk install \
  https://download.swift.org/swift-6.2.3-release/wasm-sdk/swift-6.2.3-RELEASE/swift-6.2.3-RELEASE_wasm.artifactbundle.tar.gz \
  --checksum 394040ecd5260e68bb02f6c20aeede733b9b90702c2204e178f3e42413edad2a

# Verify
swift sdk list
# Should show: swift-6.2.3-RELEASE_wasm
```

---

### Issue: "SDK install failed: checksum mismatch"

**Symptoms:**
```
error: checksum mismatch for downloaded file
```

**Diagnosis:**
Corrupted download or incorrect checksum.

**Solution:**
```bash
# Clear any partial downloads
rm -rf ~/.swiftpm/swift-sdks/

# Try installing again with correct checksum
swift sdk install \
  https://download.swift.org/swift-6.2.3-release/wasm-sdk/swift-6.2.3-RELEASE/swift-6.2.3-RELEASE_wasm.artifactbundle.tar.gz \
  --checksum 394040ecd5260e68bb02f6c20aeede733b9b90702c2204e178f3e42413edad2a
```

If issue persists:
1. Check your internet connection
2. Try downloading the file manually and verifying checksum:
```bash
curl -O <URL>
shasum -a 256 swift-6.2.3-RELEASE_wasm.artifactbundle.tar.gz
```

---

### Issue: Carton "Invalid version wasm-6.2-RELEASE"

**Symptoms:**
```
error: toolchain 'wasm-6.2-RELEASE' is not installed
```

**Diagnosis:**
Carton doesn't have full toolchains for Swift 6.2 yet.

**Solution:**
Use Swift 6.0.2 with Carton:
```bash
# Create or update .swift-version
echo "wasm-6.0.2-RELEASE" > .swift-version

# Carton will download this version automatically
carton dev
```

**Alternative:**
Use native Swift 6.2.3 + WASM SDK instead of Carton for production builds.

---

## Build Issues

### Issue: Build is extremely slow (>5 minutes)

**Symptoms:**
```
swift build --swift-sdk swift-6.2.3-RELEASE_wasm
# ... sits for several minutes
```

**Diagnosis:**
- First build compiles all dependencies
- Release builds take longer than debug
- Large dependencies (like SwiftUI, Foundation)

**Solutions:**

**For first build:**
```bash
# First build is slow - this is normal
# Download SwiftWasm toolchain (1.5GB) if using Carton
# Wait for full dependency compilation
```

**Speed up incremental builds:**
```bash
# Use debug builds during development (10x faster)
swift build --swift-sdk swift-6.2.3-RELEASE_wasm

# Only use release for final production build
swift build --swift-sdk swift-6.2.3-RELEASE_wasm -c release
```

**Cache in CI/CD:**
```yaml
# GitHub Actions example
- uses: actions/cache@v3
  with:
    path: .build
    key: ${{ runner.os }}-spm-${{ hashFiles('Package.resolved') }}
```

---

### Issue: "Cannot find 'JavaScriptKit' in scope"

**Symptoms:**
```swift
import JavaScriptKit  // error: cannot find 'JavaScriptKit' in scope
```

**Diagnosis:**
Missing dependency in Package.swift

**Solution:**
```swift
// Package.swift
let package = Package(
    name: "MyApp",
    dependencies: [
        .package(
            url: "https://github.com/swiftwasm/JavaScriptKit.git",
            exact: "0.19.2"
        )
    ],
    targets: [
        .executableTarget(
            name: "MyApp",
            dependencies: [
                .product(name: "JavaScriptKit", package: "JavaScriptKit")
            ]
        )
    ]
)
```

Then resolve:
```bash
swift package resolve
swift build --swift-sdk swift-6.2.3-RELEASE_wasm
```

---

### Issue: WASM file is 10MB+ (too large)

**Symptoms:**
```bash
$ ls -lh .build/wasm32-unknown-wasip1/debug/MyApp.wasm
-rw-r--r--  1 user  staff    12M  ...  MyApp.wasm
```

**Diagnosis:**
Debug build includes debug symbols and is not optimized.

**Solution:**

**Step 1: Use release build**
```bash
swift build --swift-sdk swift-6.2.3-RELEASE_wasm -c release
# Typical result: 800KB - 1.5MB
```

**Step 2: Enable size optimization**
```bash
swift build \
  --swift-sdk swift-6.2.3-RELEASE_wasm \
  -c release \
  -Xswiftc -Osize
# Typical result: 400-600KB
```

**Step 3: Enable all optimizations (Package.swift)**
```swift
.executableTarget(
    name: "MyApp",
    dependencies: ["Raven"],
    swiftSettings: [
        .unsafeFlags(["-Osize"], .when(configuration: .release)),
        .unsafeFlags(["-whole-module-optimization"], .when(configuration: .release)),
    ],
    linkerSettings: [
        .unsafeFlags(["--lto-O3"], .when(configuration: .release)),
        .unsafeFlags(["--gc-sections"], .when(configuration: .release)),
        .unsafeFlags(["--strip-debug"], .when(configuration: .release)),
    ]
)
```

**Step 4: Post-process optimization**
```bash
# Install tools
brew install binaryen  # provides wasm-opt
brew install brotli    # compression

# Optimize
wasm-opt -Oz .build/wasm32-unknown-wasip1/release/MyApp.wasm -o optimized.wasm

# Compress
brotli -q 11 optimized.wasm
# Result: ~150-250KB
```

---

### Issue: Compilation errors with Swift 6 strict concurrency

**Symptoms:**
```
error: sending 'self' risks causing data races
```

**Diagnosis:**
Swift 6 strict concurrency checking enabled.

**Solutions:**

**Option 1: Fix the code (recommended)**
```swift
// Mark types as Sendable
struct MyData: Sendable {
    let value: String
}

// Use MainActor for UI code
@MainActor
class ViewModel: ObservableObject {
    @Published var state: String = ""
}
```

**Option 2: Disable strict checking (temporary)**
```swift
// Package.swift
swiftSettings: [
    .enableUpcomingFeature("StrictConcurrency", .when(configuration: .debug))
]
```

---

## Runtime Issues

### Issue: Browser shows "Loading..." forever

**Symptoms:**
- Page loads but shows loading spinner indefinitely
- App never appears

**Diagnosis:**
WASM failed to load or initialize.

**Debug steps:**

**Step 1: Open browser console**
```
Chrome: Cmd+Option+I (Mac) / Ctrl+Shift+I (Windows)
Safari: Develop > Show JavaScript Console
Firefox: Cmd+Option+K (Mac) / Ctrl+Shift+K (Windows)
```

**Step 2: Check for errors**

**Error: "Failed to fetch WASM"**
```
Solution: Verify file path in HTML
<script>
    // Check this path is correct
    const response = await fetch('./app.wasm')
</script>

# Verify file exists
ls -lh .build/wasm32-unknown-wasip1/release/*.wasm
```

**Error: "MIME type mismatch"**
```
Solution: Configure server to serve .wasm files correctly

# Python server (works by default)
python3 -m http.server 8000

# nginx
http {
    types {
        application/wasm wasm;
    }
}

# Apache
AddType application/wasm .wasm
```

**Error: "WebAssembly instantiation failed"**
```
Solution: WASM file corrupted or incompatible

# Rebuild
rm -rf .build
swift build --swift-sdk swift-6.2.3-RELEASE_wasm

# Verify file is valid
file .build/wasm32-unknown-wasip1/release/MyApp.wasm
# Should output: WebAssembly (wasm) binary module
```

---

### Issue: JavaScript errors in console

**Symptoms:**
```
TypeError: Cannot read property 'function' of undefined
ReferenceError: Module is not defined
```

**Diagnosis:**
Swift/JavaScript bridging issue.

**Solutions:**

**Check JavaScriptKit import:**
```swift
import JavaScriptKit  // Must be present

let console = JSObject.global.console  // Correct
```

**Verify runtime version:**
```html
<!-- Make sure version matches Package.swift -->
<script type="module">
    import { SwiftRuntime } from 'https://cdn.jsdelivr.net/npm/javascript-kit-swift@0.19.2/Runtime/index.js'
</script>
```

**Check for async/await issues:**
```javascript
// BAD - missing await
const swift = SwiftRuntime()

// GOOD - properly awaited
const swift = await SwiftRuntime()
```

---

### Issue: "ReferenceError: JSObject is not defined"

**Symptoms:**
```swift
let console = JSObject.global.console
// Runtime error in browser
```

**Diagnosis:**
Missing JavaScriptKit import.

**Solution:**
```swift
// Add at top of file
import JavaScriptKit

// Now JSObject is available
let console = JSObject.global.console
```

---

### Issue: Memory errors or crashes

**Symptoms:**
- Browser tab crashes
- "Out of memory" errors
- Unresponsive page

**Diagnosis:**
Memory leak or excessive allocation.

**Debug:**

**Check memory usage:**
```swift
import JavaScriptKit

let memory = JSObject.global.performance.memory
console.log("Used:", memory.usedJSHeapSize)
console.log("Limit:", memory.jsHeapSizeLimit)
```

**Common causes:**
1. **Retaining closures**: Clean up JSClosure objects
```swift
// BAD - leaks memory
let closure = JSClosure { _ in
    // Never released
    return .undefined
}

// GOOD - release when done
var closure: JSClosure? = JSClosure { _ in
    return .undefined
}
defer { closure = nil }
```

2. **Large arrays**: Process in chunks
```swift
// BAD - loads everything
let allData = loadLargeDataset()

// GOOD - stream or paginate
func loadPage(_ page: Int) -> [Item] { ... }
```

3. **Image references**: Release unused images
```swift
// Clear image when done
imageView.image = nil
```

---

## Carton-Specific Issues

### Issue: Carton dev server won't start

**Symptoms:**
```
$ carton dev
error: failed to start development server
```

**Diagnosis:**
Port conflict or missing files.

**Solutions:**

**Check port availability:**
```bash
# Check if port 8080 is in use
lsof -i :8080

# Kill process if needed
lsof -ti:8080 | xargs kill

# Or use different port
carton dev --port 3000
```

**Verify Package.swift exists:**
```bash
# Carton needs valid Package.swift
ls -la Package.swift

# If missing, create one
cat > Package.swift << 'EOF'
// swift-tools-version: 6.0
import PackageDescription
let package = Package(
    name: "MyApp",
    dependencies: [
        .package(url: "https://github.com/briannadoubt/Raven.git", from: "0.1.0")
    ],
    targets: [
        .executableTarget(name: "MyApp", dependencies: ["Raven"])
    ]
)
EOF
```

---

### Issue: Hot reload not working

**Symptoms:**
- Edit Sources/*.swift
- Save file
- Browser doesn't refresh

**Diagnosis:**
WebSocket connection issue or file watcher not running.

**Solutions:**

**Check console for WebSocket errors:**
```
Look for: "WebSocket connection failed"
```

**Restart dev server:**
```bash
# Stop Carton (Ctrl+C)
# Clear cache
rm -rf .build/
# Restart
carton dev
```

**Check firewall:**
```bash
# Allow port 35729 (LiveReload)
# System Preferences > Security & Privacy > Firewall > Options
```

---

### Issue: Carton SwiftWasm download fails

**Symptoms:**
```
Downloading SwiftWasm toolchain...
error: failed to download toolchain
```

**Diagnosis:**
Network issue or server unavailable.

**Solutions:**

**Clear cache and retry:**
```bash
rm -rf ~/.carton
carton dev
```

**Check internet connection:**
```bash
curl -I https://github.com/swiftwasm/swift/releases
```

**Manual download:**
1. Visit https://github.com/swiftwasm/swift/releases
2. Download wasm-6.0.2 toolchain
3. Extract to ~/.carton/toolchains/

---

## Performance Issues

### Issue: Slow page load

**Symptoms:**
- Takes 5+ seconds to load WASM
- "Loading..." screen visible too long

**Diagnosis:**
Large WASM file or slow network.

**Solutions:**

**Optimize bundle size:**
See "WASM file is 10MB+" above.

**Enable compression:**
```bash
# Build
swift build --swift-sdk swift-6.2.3-RELEASE_wasm -c release -Xswiftc -Osize

# Compress
brotli -q 11 .build/wasm32-unknown-wasip1/release/MyApp.wasm

# Configure server to serve .br files
# nginx:
http {
    gzip on;
    gzip_types application/wasm;
}
```

**Use preloading:**
```html
<link rel="preload" href="/app.wasm" as="fetch" crossorigin>
```

**Use CDN:**
Deploy to CDN for faster global delivery (Cloudflare, Fastly, etc.)

---

### Issue: Slow runtime performance

**Symptoms:**
- UI feels sluggish
- Animations stutter
- Delayed interactions

**Diagnosis:**
Inefficient code or excessive Swift/JS bridging.

**Solutions:**

**Profile with Chrome DevTools:**
1. Open DevTools
2. Performance tab
3. Record while interacting
4. Analyze flame graph

**Reduce JS bridging:**
```swift
// BAD - calls JS on every frame
func render() {
    document.getElementById("box").style.left = "\(x)px"  // Slow
}

// GOOD - batch updates
func render() {
    // Update Swift state
    positions.append((x, y))
    // Flush to DOM once
    updateDOM(positions)
}
```

**Use async for heavy work:**
```swift
// BAD - blocks UI
let result = heavyComputation()

// GOOD - non-blocking
Task {
    let result = await heavyComputation()
    await updateUI(result)
}
```

---

## Deployment Issues

### Issue: 404 when loading on deployment

**Symptoms:**
- Works locally with `python3 -m http.server`
- Fails on Netlify/Vercel with 404 for .wasm

**Diagnosis:**
WASM file not included in deployment or wrong path.

**Solutions:**

**Verify build output:**
```bash
# Check dist/ or public/ has .wasm file
ls -lh dist/*.wasm
```

**Check deployment config:**

**Netlify:**
```toml
# netlify.toml
[build]
  command = "swift build --swift-sdk swift-6.2.3-RELEASE_wasm -c release && cp .build/wasm32-unknown-wasip1/release/*.wasm public/"
  publish = "public"
```

**Vercel:**
```json
{
  "buildCommand": "swift build --swift-sdk swift-6.2.3-RELEASE_wasm -c release && cp .build/wasm32-unknown-wasip1/release/*.wasm public/",
  "outputDirectory": "public"
}
```

---

### Issue: CORS errors on deployment

**Symptoms:**
```
Access to fetch at 'https://example.com/app.wasm' has been blocked by CORS policy
```

**Diagnosis:**
CORS headers not configured.

**Solution:**

**Netlify (_headers file):**
```
/*.wasm
  Access-Control-Allow-Origin: *
  Content-Type: application/wasm
```

**Vercel (vercel.json):**
```json
{
  "headers": [
    {
      "source": "/(.*).wasm",
      "headers": [
        { "key": "Access-Control-Allow-Origin", "value": "*" },
        { "key": "Content-Type", "value": "application/wasm" }
      ]
    }
  ]
}
```

---

## Advanced Debugging

### Enable verbose logging

```bash
# Carton verbose output
carton dev --verbose

# Swift build verbose
swift build --swift-sdk swift-6.2.3-RELEASE_wasm -v
```

### Inspect WASM module

```bash
# Install wabt tools
brew install wabt

# Convert WASM to WAT (text format)
wasm2wat app.wasm -o app.wat

# Validate WASM
wasm-validate app.wasm

# Print imports/exports
wasm-objdump -x app.wasm
```

### Profile build time

```bash
# Time each build
time swift build --swift-sdk swift-6.2.3-RELEASE_wasm

# Detailed timing
swift build --swift-sdk swift-6.2.3-RELEASE_wasm -Xswiftc -driver-time-compilation
```

---

## Getting Help

If issues persist:

1. **Check project documentation:**
   - NATIVE_WASM_SETUP.md
   - CARTON_WORKFLOW.md
   - QUICKSTART.md

2. **Search GitHub issues:**
   - [SwiftWasm Issues](https://github.com/swiftwasm/swift/issues)
   - [Carton Issues](https://github.com/swiftwasm/carton/issues)
   - [JavaScriptKit Issues](https://github.com/swiftwasm/JavaScriptKit/issues)

3. **Ask in forums:**
   - [Swift Forums - WebAssembly](https://forums.swift.org/c/related-projects/webassembly/)
   - SwiftWasm Discord
   - Raven GitHub Discussions

4. **Provide diagnostic info:**
   ```bash
   # Include this in bug reports
   swift --version
   swift sdk list
   carton --version  # if using Carton
   uname -a  # system info
   ```

---

**Remember:** Most issues are setup-related. Double-check you're using swift.org Swift (not Apple Swift) and the WASM SDK is installed correctly.
