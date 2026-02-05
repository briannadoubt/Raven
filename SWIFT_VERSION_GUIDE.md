# Swift Version Management for Raven

Guide to using the correct Swift/SwiftWasm version with Raven.

## The Problem

Raven requires **Swift 6.2+** for full compatibility, but:
- ❌ **SwiftWasm 6.2-RELEASE** exists but only has WASM artifact bundles (no macOS toolchains)
- ✅ **SwiftWasm 6.0.2-RELEASE** has full macOS toolchains but is older
- ✅ **System Swift 6.2.3** (Apple) exists but doesn't target WASM

## Solutions

### Option 1: Use System Swift 6.2 + Manual WASM Target (Recommended for Development)

Skip SwiftWasm entirely and use your system Swift with manual WASM compilation.

**Setup:**
```bash
# Verify you have Swift 6.2+
swift --version
# Apple Swift version 6.2.3 (swiftlang-6.2.3.3.21 clang-1700.6.3.2)

# Install WASI SDK for WASM support
brew install wasi-sdk

# Set WASM sysroot
export WASM_SYSROOT=/usr/local/opt/wasi-sdk/share/wasi-sysroot
```

**Build:**
```bash
swift build \
  --triple wasm32-unknown-wasi \
  -Xcc -isysroot -Xcc $WASM_SYSROOT \
  -Xlinker --sysroot=$WASM_SYSROOT
```

**Pros:**
- ✅ Uses Swift 6.2.3 (matches Raven)
- ✅ No large SwiftWasm download
- ✅ Native macOS toolchain

**Cons:**
- ❌ Manual build commands
- ❌ No Carton dev server
- ❌ Need WASI SDK

---

### Option 2: Use SwiftWasm 6.0.2 + Carton (Easiest, but Older Swift)

Use the latest SwiftWasm with full toolchains.

**Setup:**
```bash
# Create .swift-version
echo "wasm-6.0.2-RELEASE" > .swift-version

# Carton downloads automatically
carton dev
```

**Pros:**
- ✅ Full Carton integration (dev server, hot reload)
- ✅ One command workflow
- ✅ Stable release

**Cons:**
- ❌ Swift 6.0.2 vs Raven's 6.2
- ❌ Potential API differences
- ❌ Large download (1.5GB)

---

### Option 3: Wait for SwiftWasm 6.2 Full Release (Future)

When SwiftWasm 6.2 with macOS toolchains is released:

```bash
echo "wasm-6.2-RELEASE" > .swift-version
carton dev
```

**Track progress:**
- GitHub: https://github.com/swiftwasm/swift/releases
- Look for releases with `macos_arm64.pkg` and `macos_x86_64.pkg` assets

---

### Option 4: Use Raven CLI (Coming Soon)

The Raven CLI will handle Swift version management automatically.

```bash
raven dev   # Automatically uses correct Swift version
raven build # Optimizes for production
```

---

## Current Recommendation

For **development right now**, use **Option 2** (SwiftWasm 6.0.2):

```bash
cd /tmp/RavenDemo
echo "wasm-6.0.2-RELEASE" > .swift-version
carton dev
```

This works reliably and Raven is backward compatible with Swift 6.0.2.

---

## Checking SwiftWasm Releases

```bash
# List all releases
curl -s https://api.github.com/repos/swiftwasm/swift/releases | jq -r '.[].tag_name'

# Check if a version has macOS toolchains
curl -s https://api.github.com/repos/swiftwasm/swift/releases/tags/swift-wasm-X.Y.Z-RELEASE \
  | jq -r '.assets[] | .name' | grep macos

# Example output showing it HAS toolchains:
# swift-wasm-6.0.2-RELEASE-macos_arm64.pkg
# swift-wasm-6.0.2-RELEASE-macos_x86_64.pkg
```

---

## Version Matrix

| Swift Version | SwiftWasm Available | macOS Toolchains | Raven Compatible | Carton Support |
|--------------|-------------------|------------------|------------------|----------------|
| 6.2.3 (Apple) | ❌ No | ✅ Yes | ✅ Yes | ❌ No |
| 6.2 (SwiftWasm) | ⚠️ Partial | ❌ No | ✅ Yes | ❌ No |
| 6.0.2 (SwiftWasm) | ✅ Yes | ✅ Yes | ✅ Yes | ✅ Yes |

---

## Troubleshooting

### "Invalid version wasm-6.2-RELEASE"

**Cause:** Swift 6.2-RELEASE doesn't have macOS toolchains yet.

**Solution:** Use 6.0.2 instead:
```bash
echo "wasm-6.0.2-RELEASE" > .swift-version
carton dev
```

### "No available targets compatible with wasm32-unknown-wasi"

**Cause:** Using Apple Swift without WASM support.

**Solutions:**
1. Use Carton (installs SwiftWasm automatically)
2. Install WASI SDK manually
3. Wait for SwiftWasm 6.2 with toolchains

### Mixing Swift Versions

**Problem:** Raven compiled with Swift 6.2, app compiled with Swift 6.0.

**Solution:** Usually works fine (ABI compatible), but for best results:
- Match versions exactly, OR
- Recompile Raven with same Swift version as app

---

## Future: Raven CLI Integration

The Raven CLI will eventually:
- ✅ Detect system Swift version
- ✅ Download correct SwiftWasm if needed
- ✅ Handle version mismatches automatically
- ✅ Provide unified `raven dev` / `raven build` commands

---

## Summary

**Right now (Feb 2026):**

```bash
# Best option: Use SwiftWasm 6.0.2 + Carton
echo "wasm-6.0.2-RELEASE" > .swift-version
carton dev
```

**Soon (when available):**

```bash
# Future: SwiftWasm 6.2 with toolchains
echo "wasm-6.2-RELEASE" > .swift-version
carton dev
```

**Eventually:**

```bash
# Raven CLI handles everything
raven dev
```

---

For questions or issues, check:
- SwiftWasm Releases: https://github.com/swiftwasm/swift/releases
- Carton Docs: https://github.com/swiftwasm/carton
- Raven Issues: https://github.com/briannadoubt/Raven/issues
