# Native Swift WASM Setup Guide

Complete guide to building Raven with **official Swift 6.2.3 + native WASM SDK** (no SwiftWasm custom toolchain needed).

## The Two Paths

### Path 1: Native Swift 6.2.3 + WASM SDK (Recommended for Production)
Use swift.org's official toolchain with native WASM support

### Path 2: Carton (Easiest for Development)
Carton handles everything automatically

---

## Path 1: Official Swift 6.2.3 + WASM SDK

### Why This Path?
- ✅ Uses official swift.org Swift 6.2.3 (matches Raven)
- ✅ Native WASM support (Swift 6.1+)
- ✅ Small SDK download (~50MB, not 1.5GB)
- ✅ Latest features and bug fixes
- ✅ Official Apple support

### Step 1: Install Swiftly (Swift Toolchain Manager)

```bash
# Install via Homebrew
brew install swiftly

# Verify installation
swiftly --version
# Output: swiftly 1.1.1 (or later)
```

### Step 2: Install Swift 6.2.3 from swift.org

```bash
# Install swift.org Swift 6.2.3
swiftly install 6.2.3

# Use it as default
swiftly use 6.2.3

# Verify (should NOT say "Apple Swift")
swift --version
# Output: Swift version 6.2.3 (swift-6.2.3-RELEASE)
```

**Important:** This installs the **swift.org toolchain**, not Apple's Xcode Swift. They're different!

### Step 3: Install Official WASM SDK

```bash
# Install the official Swift 6.2.3 WASM SDK
swift sdk install \
  https://download.swift.org/swift-6.2.3-release/wasm-sdk/swift-6.2.3-RELEASE/swift-6.2.3-RELEASE_wasm.artifactbundle.tar.gz \
  --checksum 394040ecd5260e68bb02f6c20aeede733b9b90702c2204e178f3e42413edad2a

# Verify installation
swift sdk list
# Output:
# swift-6.2.3-RELEASE_wasm
# swift-6.2.3-RELEASE_wasm-embedded
```

### Step 4: Build Your Raven App

```bash
cd /tmp/RavenDemo

# Build for WASM
swift build --swift-sdk swift-6.2.3-RELEASE_wasm

# Output in:
# .build/wasm32-unknown-wasip1/debug/RavenDemo.wasm
```

### Step 5: Serve Your App

Create `index.html`:

```html
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>My Raven App</title>
</head>
<body>
    <div id="root"></div>
    <script type="module">
        import { SwiftRuntime } from 'https://cdn.jsdelivr.net/npm/javascript-kit-swift@0.19.2/Runtime/index.js'

        const swift = await SwiftRuntime()
        const response = await fetch('./.build/wasm32-unknown-wasip1/debug/RavenDemo.wasm')
        await swift.setInstance(
            await WebAssembly.instantiateStreaming(response, swift.wasmImports)
        )
        swift.main()
    </script>
</body>
</html>
```

Serve it:

```bash
python3 -m http.server 8000
open http://localhost:8000
```

### Production Build

```bash
# Build with optimizations
swift build \
  --swift-sdk swift-6.2.3-RELEASE_wasm \
  -c release \
  -Xswiftc -Osize

# Even smaller: use embedded SDK (no stdlib)
swift build \
  --swift-sdk swift-6.2.3-RELEASE_wasm-embedded \
  -c release \
  -Xswiftc -Osize
```

---

## Path 2: Carton (Quick & Easy)

### Why This Path?
- ✅ Zero setup (downloads everything automatically)
- ✅ Built-in dev server with hot reload
- ✅ One command to run
- ✅ Handles all toolchain complexity
- ⚠️ Uses SwiftWasm 6.0.2 (slightly older)

### Setup

```bash
# Already installed via Homebrew
carton --version
# Output: 1.1.3

# Create .swift-version in your project
cd /tmp/RavenDemo
echo "wasm-6.0.2-RELEASE" > .swift-version
```

### Run

```bash
# Start dev server (downloads SwiftWasm first time)
carton dev

# Browser opens automatically to http://127.0.0.1:8080
# Hot reload enabled - edit Sources/main.swift and save!
```

### Production

```bash
# Build optimized bundle
carton bundle --release

# Output in .build/bundle/
# - index.html
# - main.wasm (optimized)
# - assets/
```

---

## Comparison: Native vs Carton

| Feature | Native Swift 6.2.3 | Carton |
|---------|-------------------|--------|
| Swift Version | 6.2.3 (latest) | 6.0.2 |
| Setup Complexity | Medium | Easy |
| Download Size | ~50MB SDK | ~1.5GB toolchain |
| Dev Server | Manual | Built-in ✅ |
| Hot Reload | Manual | Automatic ✅ |
| Build Speed | Fast | Fast |
| Production Ready | Yes ✅ | Yes ✅ |
| Official Support | Yes ✅ | Community |

---

## Current Status (Your Machine)

### ✅ What's Working

1. **Swift 6.2.3 WASM SDK Installed**
   ```bash
   swift sdk list
   # swift-6.2.3-RELEASE_wasm ✅
   # swift-6.2.3-RELEASE_wasm-embedded ✅
   ```

2. **Carton Installed and Working**
   ```bash
   carton --version
   # 1.1.3 ✅
   ```

### ⚠️ What's Not Working Yet

**Native WASM builds fail** because we're using **Apple's Xcode Swift**, not swift.org's Swift:

```bash
$ which swift
/usr/bin/swift  # ❌ This is Apple's Xcode Swift

$ swift --version
Apple Swift version 6.2.3  # ❌ Note "Apple"
```

**The Swift SDK requires swift.org's toolchain:**

```bash
# After installing swiftly + swift.org Swift 6.2.3:
$ which swift
/Users/YOU/.local/share/swiftly/toolchains/6.2.3/usr/bin/swift  # ✅

$ swift --version
Swift version 6.2.3 (swift-6.2.3-RELEASE)  # ✅ No "Apple"
```

---

## Recommended Next Steps

### For Development (Now)

**Use Carton** - it works out of the box:

```bash
cd /tmp/RavenDemo
carton dev
# ✅ Works immediately
```

### For Production (When Ready)

**Install swiftly + swift.org toolchain:**

```bash
# 1. Install swiftly
brew install swiftly

# 2. Install swift.org Swift 6.2.3
swiftly install 6.2.3
swiftly use 6.2.3

# 3. Build with native WASM SDK (already installed!)
cd /tmp/RavenDemo
swift build --swift-sdk swift-6.2.3-RELEASE_wasm -c release

# ✅ Native WASM builds work
```

---

## Troubleshooting

### "No available targets compatible with triple wasm32-unknown-wasip1"

**Cause:** Using Apple's Xcode Swift instead of swift.org Swift.

**Solution:**
```bash
brew install swiftly
swiftly install 6.2.3
swiftly use 6.2.3
swift --version  # Should NOT say "Apple"
```

### "Invalid version wasm-6.2-RELEASE" (Carton)

**Cause:** Trying to use Swift 6.2 with Carton, but full toolchains aren't available yet.

**Solution:** Use Swift 6.0.2:
```bash
echo "wasm-6.0.2-RELEASE" > .swift-version
carton dev
```

### SDK Install Requires Checksum

**Cause:** Swift requires checksum verification for remote SDK installs.

**Solution:** Use the exact command from this guide with `--checksum` parameter.

### Mixing Swift Versions

**Problem:** Raven compiled with 6.2, app compiled with 6.0.

**Impact:** Usually fine (ABI compatible), but for best results match versions.

---

## Technical Details

### WASM Target Triple

The official target is **`wasm32-unknown-wasip1`** (not the older `wasm32-unknown-wasi`).

When you build:
```bash
swift build --swift-sdk swift-6.2.3-RELEASE_wasm
```

Output goes to:
```
.build/wasm32-unknown-wasip1/debug/YourApp.wasm
```

### Two SDK Flavors

1. **`swift-6.2.3-RELEASE_wasm`** - Full Swift stdlib (~400-600KB)
2. **`swift-6.2.3-RELEASE_wasm-embedded`** - Embedded (tiny, <100KB)

Use embedded for size-critical applications.

### Carton vs Native

**Carton uses SwiftWasm:**
- Separate fork of Swift optimized for WASM
- Swift 6.0.2 (older but stable)
- 1.5GB download (full toolchain)
- All-in-one solution

**Native uses swift.org:**
- Official Swift with WASM SDK (Swift 6.1+)
- Latest Swift 6.2.3
- ~50MB download (just SDK)
- Modular approach

---

## References

- [Swift.org WASM Getting Started](https://swift.org/documentation/articles/wasm-getting-started.html)
- [Swift Forums: WASM SDK 6.2](https://forums.swift.org/t/swift-sdks-for-webassembly-now-available-on-swift-org/80405)
- [Swiftly Toolchain Manager](https://github.com/swiftlang/swiftly)
- [Carton](https://github.com/swiftwasm/carton)

---

## Summary

**Right now (Development):**
```bash
cd /tmp/RavenDemo
carton dev  # ✅ Works immediately
```

**Future (Production with native WASM):**
```bash
brew install swiftly
swiftly install 6.2.3
swiftly use 6.2.3
swift build --swift-sdk swift-6.2.3-RELEASE_wasm -c release
```

**The WASM SDK is already installed** - you just need swift.org's toolchain to use it! 🚀
