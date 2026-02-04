# Bundle Size Optimization Guide

This guide covers comprehensive bundle size optimization strategies for Raven applications.

## Table of Contents

1. [Overview](#overview)
2. [Optimization Targets](#optimization-targets)
3. [Compiler Optimizations](#compiler-optimizations)
4. [Build-Time Optimizations](#build-time-optimizations)
5. [Post-Processing Optimizations](#post-processing-optimizations)
6. [Runtime Optimizations](#runtime-optimizations)
7. [Measurement and Analysis](#measurement-and-analysis)
8. [CI/CD Integration](#cicd-integration)
9. [Best Practices](#best-practices)

## Overview

Raven applications are compiled to WebAssembly (WASM) for browser deployment. The bundle size directly impacts:

- **Initial load time** - Larger bundles take longer to download
- **Parse time** - More WASM code requires more time to parse and compile
- **Memory usage** - Larger binaries consume more memory
- **User experience** - Faster loads improve user satisfaction

**Current Status:**
- Baseline (unoptimized): ~2MB
- Target: <500KB uncompressed
- Expected with full optimization: 300-500KB

## Optimization Targets

| Bundle Type | Size Limit | Use Case |
|-------------|-----------|----------|
| Minimal | <200KB | Landing pages, widgets |
| Standard | <500KB | Standard applications |
| Large | <1MB | Feature-rich applications |
| Enterprise | <2MB | Complex enterprise apps |

Raven targets **<500KB** for standard applications.

## Compiler Optimizations

### 1. Size Optimization Mode (-Osize)

The Swift compiler offers three optimization levels:

```swift
// Package.swift
swiftSettings: [
    .unsafeFlags(["-Osize"], .when(configuration: .release))
]
```

**CLI Usage:**
```bash
raven build --optimize-size
```

**Impact:** 20-30% size reduction compared to -O

**Trade-offs:**
- Slightly slower execution (~5-10%)
- Longer compile time (~30-50%)

### 2. Whole Module Optimization

Enables cross-module optimization:

```swift
swiftSettings: [
    .unsafeFlags(["-whole-module-optimization"], .when(configuration: .release))
]
```

**Impact:** 10-15% size reduction

### 3. Library Evolution

Reduces binary size by enabling library evolution:

```swift
swiftSettings: [
    .unsafeFlags(["-enable-library-evolution"], .when(configuration: .release))
]
```

**Impact:** 5-10% size reduction

## Build-Time Optimizations

### 1. Link-Time Optimization (LTO)

LTO performs optimization across compilation units:

```swift
linkerSettings: [
    .unsafeFlags(["-Xlinker", "--lto-O3"], .when(configuration: .release))
]
```

**Impact:** 10-20% size reduction

**Trade-offs:**
- Significantly longer link time (+50-100%)
- Higher memory usage during linking

### 2. Dead Code Elimination

Remove unused code at link time:

```swift
linkerSettings: [
    .unsafeFlags(["-Xlinker", "--gc-sections"], .when(configuration: .release))
]
```

**Impact:** 5-15% size reduction

### 3. Debug Symbol Stripping

Remove debug information from release builds:

```swift
linkerSettings: [
    .unsafeFlags(["-Xlinker", "--strip-debug"], .when(configuration: .release))
]
```

**CLI Usage:**
```bash
raven build --strip-debug  # Enabled by default
```

**Impact:** 5-10% size reduction

## Post-Processing Optimizations

### 1. wasm-opt

Optimize WASM binary with Binaryen's wasm-opt:

```bash
# Maximum optimization (speed)
wasm-opt -O3 app.wasm -o app.optimized.wasm

# Size optimization
wasm-opt -Oz app.wasm -o app.optimized.wasm

# With additional flags
wasm-opt -Oz --strip-debug --strip-producers --strip-dwarf \
         --vacuum app.wasm -o app.optimized.wasm
```

**CLI Usage:**
```bash
raven build --optimize
```

**Impact:** 5-15% size reduction

**Flags:**
- `-Oz` - Optimize for size
- `--strip-debug` - Remove debug info
- `--strip-producers` - Remove producer section
- `--strip-dwarf` - Remove DWARF debug info
- `--vacuum` - Remove unused code

### 2. wasm-strip

Strip symbols using WABT:

```bash
wasm-strip app.wasm
```

**Impact:** 5-10% size reduction

### 3. Compression

Compress WASM for network transfer:

```bash
# Brotli (recommended)
brotli -q 11 app.wasm

# Gzip
gzip -9 app.wasm
```

**CLI Usage:**
```bash
raven build --compress
```

**Compression Ratios:**
- Brotli: 70-80% size reduction
- Gzip: 65-75% size reduction

**Server Configuration:**

**Nginx:**
```nginx
location ~* \.wasm$ {
    brotli on;
    brotli_comp_level 11;
    brotli_types application/wasm;
    gzip on;
    gzip_comp_level 9;
    gzip_types application/wasm;
}
```

**Apache:**
```apache
<IfModule mod_brotli.c>
    AddOutputFilterByType BROTLI_COMPRESS application/wasm
    BrotliCompressionQuality 11
</IfModule>
```

## Runtime Optimizations

### 1. Code Splitting

Split large applications into multiple bundles:

```swift
// Load features on demand
func loadFeature() async {
    let module = try await loadWasmModule("feature.wasm")
    // Use feature
}
```

### 2. Lazy Loading

Defer loading of non-critical code:

```swift
struct App: View {
    var body: some View {
        NavigationView {
            List {
                NavigationLink("Feature") {
                    LazyView(FeatureView())
                }
            }
        }
    }
}
```

### 3. Conditional Compilation

Exclude debug code from release builds:

```swift
#if DEBUG
    // Debug-only code
    func debugLog(_ message: String) {
        print(message)
    }
#endif
```

## Measurement and Analysis

### 1. Basic Size Check

```bash
# Get uncompressed size
ls -lh dist/app.wasm

# Get compressed size
brotli -c dist/app.wasm | wc -c
```

### 2. Detailed Analysis with twiggy

```bash
# Top space consumers
twiggy top -n 20 dist/app.wasm

# Dominators (what keeps what alive)
twiggy dominators -n 10 dist/app.wasm

# Garbage (items with no references)
twiggy garbage dist/app.wasm

# Paths between items
twiggy paths dist/app.wasm "function_name"
```

**Install twiggy:**
```bash
cargo install twiggy
```

### 3. Automated Analysis

```bash
# Run full analysis
./scripts/analyze-bundle.sh dist/app.wasm

# Compare with baseline
./scripts/analyze-bundle.sh dist/app.wasm baseline/app.wasm

# Generate JSON report
OUTPUT_JSON=1 ./scripts/analyze-bundle.sh dist/app.wasm
```

### 4. Size Tracking

```bash
# Track size over time
./scripts/track-bundle-size.sh dist/app.wasm

# View history
cat .bundle-size-history/history.csv
```

## CI/CD Integration

### GitHub Actions

See `.github/workflows/bundle-size.yml` for a complete example.

**Key Features:**
- Automatic size checking on PRs
- Historical tracking
- PR comments with size reports
- Status checks
- Artifact uploads

### Bundle Size Budgets

Fail CI if bundle size exceeds threshold:

```bash
FAIL_ON_INCREASE=1 MAX_INCREASE_PERCENT=5 \
  ./scripts/track-bundle-size.sh dist/app.wasm
```

## Best Practices

### 1. Development Workflow

```bash
# Development (fast builds)
raven build --debug

# Testing (balanced)
raven build

# Production (maximum optimization)
raven build --optimize-size --optimize --compress
```

### 2. Regular Monitoring

- Track bundle size on every commit
- Set up size budgets in CI
- Review size increases in PRs
- Analyze large contributors regularly

### 3. Dependency Management

```swift
// Prefer lightweight dependencies
dependencies: [
    .package(url: "https://github.com/swiftwasm/JavaScriptKit.git", from: "0.19.0")
]

// Avoid:
// - Large utility libraries
// - Unused framework features
// - Multiple implementations of same functionality
```

### 4. Code Organization

```swift
// Good: Modular, tree-shakeable
protocol FeatureProtocol {
    func process()
}

struct Feature: FeatureProtocol {
    func process() { /* ... */ }
}

// Avoid: Monolithic, hard to optimize
class MegaFeature {
    func feature1() { }
    func feature2() { }
    // ... 100 more methods
}
```

### 5. Asset Optimization

- Compress images before bundling
- Use modern formats (WebP, AVIF)
- Lazy-load assets
- Use CSS instead of images where possible

### 6. Regular Audits

```bash
# Weekly size audit
./scripts/analyze-bundle.sh dist/app.wasm

# Identify regressions
git log --all --format='%H' | while read commit; do
    git checkout $commit
    # build and measure
done
```

## Optimization Checklist

- [ ] Enable `-Osize` optimization
- [ ] Enable whole-module-optimization
- [ ] Enable LTO (`--lto-O3`)
- [ ] Enable dead code elimination (`--gc-sections`)
- [ ] Strip debug symbols
- [ ] Run `wasm-opt -Oz`
- [ ] Enable Brotli compression
- [ ] Review dependencies for unused code
- [ ] Implement code splitting for large features
- [ ] Set up CI bundle size checks
- [ ] Configure size budgets
- [ ] Regular size audits with twiggy

## Performance Impact Summary

| Optimization | Build Time | Size Reduction | Runtime Impact |
|--------------|-----------|----------------|----------------|
| -Osize | +30-50% | 20-30% | -5-10% speed |
| WMO | +20-30% | 10-15% | +5-10% speed |
| LTO | +50-100% | 10-20% | +5-15% speed |
| wasm-opt -Oz | +10-20% | 5-15% | -5-10% speed |
| wasm-strip | <1s | 5-10% | None |
| Brotli | <1s | 70-80%* | None |

\* For network transfer only

**Total Expected:**
- Build time: +2-3x
- Size reduction: 40-60%
- Runtime impact: Neutral to +5%

## Troubleshooting

### Bundle still too large

1. Analyze with twiggy:
   ```bash
   twiggy top -n 50 dist/app.wasm
   ```

2. Look for:
   - Large string literals
   - Unused dependencies
   - Debug/logging code
   - Duplicate implementations

3. Use conditional compilation:
   ```swift
   #if !DEBUG
   // Production-only code
   #endif
   ```

### Build fails with optimization flags

1. Check Swift version (6.2+ required)
2. Update dependencies
3. Try incremental enablement:
   - Start with `-Osize` only
   - Add `-whole-module-optimization`
   - Add LTO last

### Optimization tools not found

```bash
# macOS
brew install binaryen wabt brotli

# Linux
apt-get install binaryen wabt brotli

# Analysis tools
cargo install twiggy
```

## Resources

- [WebAssembly Binary Toolkit (WABT)](https://github.com/WebAssembly/wabt)
- [Binaryen (wasm-opt)](https://github.com/WebAssembly/binaryen)
- [Twiggy (WASM profiler)](https://github.com/rustwasm/twiggy)
- [Swift for WebAssembly](https://swiftwasm.org/)
- [MDN: WebAssembly](https://developer.mozilla.org/en-US/docs/WebAssembly)
