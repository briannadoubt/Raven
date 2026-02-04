# Bundle Size Optimization - Quick Start

## TL;DR

```bash
# Maximum optimization (recommended for production)
raven build --optimize-size --optimize --compress

# Analyze bundle
./scripts/analyze-bundle.sh dist/app.wasm

# Track size over time
./scripts/track-bundle-size.sh dist/app.wasm
```

## Build Modes

### Development (Fast, Large)
```bash
raven build --debug
```
- Build time: ~30s
- Bundle size: ~2MB
- Use for: Development, debugging

### Release (Balanced)
```bash
raven build
```
- Build time: ~45s
- Bundle size: ~1MB
- Use for: Testing, staging

### Production (Slow, Small)
```bash
raven build --optimize-size --optimize --compress
```
- Build time: ~90-120s
- Bundle size: <500KB
- Use for: Production deployments

## CLI Flags Quick Reference

| Flag | What It Does | Impact |
|------|--------------|--------|
| `--optimize-size` | Use -Osize compiler flag | 20-30% smaller |
| `--optimize` | Run wasm-opt | 5-15% smaller |
| `--strip-debug` | Remove debug symbols | 5-10% smaller |
| `--compress` | Generate .br file | 70-80% network size |
| `--report-size` | Show size analysis | No impact |
| `--verbose` | Detailed output | No impact |

## Scripts Quick Reference

### Build Optimized
```bash
./scripts/build-optimized.sh
```
Does everything: compile, optimize, strip, compress, report.

### Analyze Bundle
```bash
./scripts/analyze-bundle.sh dist/app.wasm
```
Shows: sizes, compression ratios, top contributors, suggestions.

### Track Size
```bash
./scripts/track-bundle-size.sh dist/app.wasm
```
Records: size history, trends, comparisons.

## Target Sizes

| Type | Target | Use Case |
|------|--------|----------|
| Minimal | <200KB | Widgets, landing pages |
| **Standard** | **<500KB** | **Standard apps (Raven target)** |
| Large | <1MB | Feature-rich apps |
| Enterprise | <2MB | Complex enterprise apps |

## Compression Ratios

| Format | Typical Ratio | Network Size (from 500KB) |
|--------|---------------|---------------------------|
| Uncompressed | 100% | 500KB |
| Gzip | 25-35% | 125-175KB |
| **Brotli** | **20-30%** | **100-150KB** |

## Common Commands

### Check Current Size
```bash
ls -lh dist/app.wasm
```

### Compare with Baseline
```bash
./scripts/analyze-bundle.sh dist/app.wasm baseline/app.wasm
```

### Build and Analyze
```bash
raven build --optimize-size --optimize && \
./scripts/analyze-bundle.sh dist/app.wasm
```

### Install Tools
```bash
# macOS
brew install binaryen wabt brotli
cargo install twiggy

# Linux
apt-get install binaryen wabt brotli
cargo install twiggy
```

## Troubleshooting

### "Bundle too large"
```bash
# Try maximum optimization
raven build --optimize-size --optimize

# Analyze what's taking space
twiggy top -n 20 dist/app.wasm

# Check for debug code
strings dist/app.wasm | grep -i debug
```

### "Build too slow"
```bash
# Use release mode for development
raven build

# Reserve --optimize-size for production
raven build --optimize-size  # only when needed
```

### "Tools not found"
```bash
# macOS
brew install binaryen wabt brotli

# Verify
which wasm-opt wasm-strip brotli
```

## CI/CD Setup

1. Add workflow:
   ```bash
   cp .github/workflows/bundle-size.yml .github/workflows/
   ```

2. Commit and push:
   ```bash
   git add .github/workflows/bundle-size.yml
   git commit -m "Add bundle size tracking"
   git push
   ```

3. Check PR comments for size reports

## Best Practices

✅ **Do:**
- Use `--optimize-size` for production
- Track size on every commit
- Set size budgets in CI
- Analyze large increases
- Enable Brotli on server

❌ **Don't:**
- Use debug builds in production
- Ignore size increases
- Skip optimization steps
- Bundle debug code
- Forget to compress

## Size Budget

Set in CI with:
```bash
FAIL_ON_INCREASE=1 MAX_INCREASE_PERCENT=5 \
./scripts/track-bundle-size.sh dist/app.wasm
```

## Emergency Size Fix

If bundle suddenly gets large:

1. **Check git log:**
   ```bash
   git log --oneline -10
   ```

2. **Build previous commit:**
   ```bash
   git checkout HEAD~1
   raven build --optimize-size
   ls -lh dist/app.wasm
   ```

3. **Compare:**
   ```bash
   ./scripts/analyze-bundle.sh dist/app.wasm baseline/app.wasm
   ```

4. **Analyze top contributors:**
   ```bash
   twiggy top -n 50 dist/app.wasm
   ```

## More Info

- Full guide: `docs/bundle-size-optimization.md`
- Script docs: `scripts/README.md`
- Implementation: `docs/bundle-size-implementation.md`

## Quick Health Check

```bash
# Run this to check everything works
raven build --optimize-size --optimize && \
./scripts/analyze-bundle.sh dist/app.wasm && \
./scripts/track-bundle-size.sh dist/app.wasm
```

Expected output:
- ✅ Build complete
- ✅ Bundle <500KB
- ✅ Size tracked
- ✅ Target met

## Get Help

If bundle size is problematic:

1. Check `twiggy top` for largest items
2. Review recent commits
3. Look for unused dependencies
4. Check for debug code
5. Verify all optimization flags enabled

```bash
# Full diagnostic
raven build --optimize-size --optimize --verbose
./scripts/analyze-bundle.sh dist/app.wasm
twiggy top -n 50 dist/app.wasm
```
