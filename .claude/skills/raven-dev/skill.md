# Raven Development Skill

Expert workflow for developing and debugging Raven Swift WASM applications with browser automation.

## When to Use This Skill

Invoke this skill when:
- Building and testing Raven WASM apps
- Debugging rendering issues in Raven
- Fixing DOMBridge or event handling problems
- Testing changes to the Raven framework
- Setting up development environment for Raven examples

## Core Workflow

### 1. Build Phase

**Always build from the app directory (not root):**
```bash
cd Examples/TodoApp  # or other example app
swift build --swift-sdk swift-6.2.3-RELEASE_wasm
```

**Why app directory?**
- Avoids building RavenCLI which has WASM-incompatible code (Process, DispatchSource)
- Faster builds focusing only on the app
- Cleaner error output

**Copy WASM to public directory:**
```bash
cp .build/wasm32-unknown-wasip1/debug/TodoApp.wasm public/TodoApp-v2.wasm
md5 public/TodoApp-v2.wasm  # Track changes
```

### 2. Serve Phase

**Flask server (NOT Python SimpleHTTPServer):**
- Located at: `Examples/TodoApp/serve.py`
- Provides proper cache-control headers for WASM
- Serves with correct MIME types
- Port: 8000

**Start server:**
```bash
cd Examples/TodoApp
python3 serve.py
```

**Server structure:**
```python
from flask import Flask, send_from_directory

app = Flask(__name__)

@app.after_request
def add_header(response):
    if response.mimetype == 'application/wasm':
        response.headers['Cache-Control'] = 'no-cache, no-store, must-revalidate'
        response.headers['Pragma'] = 'no-cache'
        response.headers['Expires'] = '0'
    return response

@app.route('/')
def index():
    return send_from_directory('.', 'public/index.html')

@app.route('/<path:path>')
def serve_file(path):
    return send_from_directory('.', path)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8000)
```

### 3. Test Phase (Browser Automation)

**Get tab context first:**
```javascript
mcp__claude-in-chrome__tabs_context_mcp()
```

**Navigate or create tab:**
```javascript
// If tab exists, navigate
mcp__claude-in-chrome__navigate(tabId, "http://localhost:8000/")

// If no tab, create one
mcp__claude-in-chrome__tabs_create_mcp()
```

**Check console for errors:**
```javascript
mcp__claude-in-chrome__read_console_messages({
  tabId: tabId,
  pattern: "error|Error|unreachable|fatal|Fatal|success|Success",
  limit: 50
})
```

**Take screenshot to verify render:**
```javascript
mcp__claude-in-chrome__computer({
  tabId: tabId,
  action: "screenshot"
})
```

### 4. Debug Phase

**Common issues and solutions:**

#### Browser Cache (Most Common!)
**Problem:** Browser loads old WASM even after rebuild
**Detection:**
- Check WASM hash in console (e.g., `TodoApp.wasm-13869b0e`)
- Compare with actual file: `md5 public/TodoApp-v2.wasm`
- Hashes don't match = cache issue

**Solutions (in order of preference):**
1. Use versioned filename: `TodoApp-v2.wasm?t=${Date.now()}`
2. Clear cache via JavaScript:
```javascript
caches.keys().then(names => {
    names.forEach(name => caches.delete(name));
});
window.location.reload(true);
```
3. Hard refresh: Cmd+Shift+R (may not work for WASM)
4. Open in incognito/private window
5. Last resort: Restart browser

**Why so aggressive?**
- WASM files are ~78MB
- Browsers use heuristic caching for large files
- No explicit Cache-Control = days/weeks of caching
- Even with headers, compilation cache persists

#### addEventListener Crashes

**Error signature:**
```
JavaScriptKit/JSValue.swift:107: Fatal error: Unexpectedly found nil while unwrapping an Optional value
at TodoApp.wasm.$s13JavaScriptKit7JSValueO13dynamicMemberAcA013ConvertibleToD0_pd_tcSS_tcig
at TodoApp.wasm.$s5Raven9DOMBridgeC16addEventListener...
```

**Root cause:** Dynamic member access on JSObject fails when property doesn't exist

**Solution:** Use JSClosure directly, avoid dynamic member access
```swift
// ❌ WRONG - Dynamic member access can fail
let handler = element.__ravenHandlers.object
element.__ravenHandlers[dynamicMember: id] = value

// ✅ CORRECT - Use JSClosure directly
let jsClosure = JSClosure { _ in
    Task { @MainActor in
        handler()
    }
    return .undefined
}
eventClosures[handlerID] = jsClosure  // Store in Swift dict
_ = element.addEventListener!(event, jsClosure)
```

**Key rules for DOMBridge:**
1. NEVER access custom properties on DOM elements (like `__ravenHandlers`)
2. Store handler references in Swift dictionaries, not on DOM
3. Use JSClosure for all event handlers
4. Call DOM methods directly with `!` to preserve `this` binding
5. Avoid `.function`, `.object` access chains on JSValues

#### Parameter Packs Not Rendering

**Expected console output:**
```
[Swift Render] VNode children count: 5
```

**If missing:** Parameter packs aren't being recognized
**Check:** Swift version, ViewBuilder implementation

#### RenderLoop Errors

**Common errors:**
- `createElement` returns nil → DOM not ready
- `appendChild` fails → element or child is invalid
- Optional unwrapping → Always use guards, never force unwrap

## Critical Code Patterns

### DOMBridge Event Handling (SAFE)

```swift
/// Registry of JSClosures for event handlers
private var eventClosures: [UUID: JSClosure] = [:]

public func addEventListener(
    element: JSObject,
    event: String,
    handlerID: UUID,
    handler: @escaping @Sendable @MainActor () -> Void
) {
    // Create JSClosure (safe - no dynamic member access)
    let jsClosure = JSClosure { _ in
        Task { @MainActor in
            handler()
        }
        return .undefined
    }

    // Store in Swift dictionary (safe)
    eventClosures[handlerID] = jsClosure

    // Add listener (safe - direct DOM method call)
    _ = element.addEventListener!(event, jsClosure)
}

public func removeEventListener(
    element: JSObject,
    event: String,
    handlerID: UUID
) {
    // Remove from registries
    eventHandlers.removeValue(forKey: handlerID)

    // Get closure and remove listener
    guard let jsClosure = eventClosures.removeValue(forKey: handlerID) else {
        return
    }

    _ = element.removeEventListener!(event, jsClosure)
}
```

### DOM Method Calls (SAFE)

```swift
// ✅ Direct method calls preserve 'this' binding
_ = element.appendChild!(child)
_ = element.removeChild!(child)
_ = element.setAttribute!(name, value)
let result = document.createElement!(tag)

// ❌ Avoid extracting to variables (loses 'this')
let appendFn = element.appendChild.function  // BAD
appendFn!(child)  // Will fail - 'this' is lost
```

### Optional Handling (SAFE)

```swift
// ✅ Always check for nil when creating elements
public func createElement(tag: String) -> JSObject? {
    let result = document.createElement!(tag)
    return result.isNull || result.isUndefined ? nil : result.object
}

// ✅ Use guards at call sites
guard let element = DOMBridge.shared.createElement(tag) else {
    print("Failed to create element: \(tag)")
    return
}
```

## File Locations Reference

### Framework Core
- **DOMBridge:** `/Users/bri/dev/Raven/Sources/Raven/Rendering/DOMBridge.swift`
- **RenderLoop:** `/Users/bri/dev/Raven/Sources/RavenRuntime/RenderLoop.swift`
- **ViewBuilder:** `/Users/bri/dev/Raven/Sources/Raven/Core/ViewBuilder.swift`
- **AppRuntime:** `/Users/bri/dev/Raven/Sources/RavenRuntime/AppRuntime.swift`

### TodoApp Example
- **Main:** `/Users/bri/dev/Raven/Examples/TodoApp/Sources/TodoApp/TodoAppMain.swift`
- **Package:** `/Users/bri/dev/Raven/Examples/TodoApp/Package.swift`
- **Flask Server:** `/Users/bri/dev/Raven/Examples/TodoApp/serve.py`
- **HTML:** `/Users/bri/dev/Raven/Examples/TodoApp/public/index.html`
- **Runtime JS:** `/Users/bri/dev/Raven/Examples/TodoApp/public/runtime.js`

### Memory
- **Memory Dir:** `/Users/bri/.claude/projects/-Users-bri-dev-Raven/memory/`
- **Main Memory:** `/Users/bri/.claude/projects/-Users-bri-dev-Raven/memory/MEMORY.md`

## Build Troubleshooting

### RavenCLI Errors (Expected)
```
error: cannot find 'Process' in scope
error: cannot find 'DispatchSource' in scope
```
**Why:** RavenCLI has native-only dependencies
**Solution:** Build from Examples/TodoApp, not root
**Impact:** None - doesn't affect TodoApp or framework

### Swift SDK Not Found
```
error: no available targets compatible with wasm32-unknown-wasip1
```
**Why:** Using Apple Swift instead of swift.org Swift
**Solution:**
```bash
brew install swiftly
swiftly install 6.2.3
swiftly use 6.2.3
swift sdk list  # Should show swift-6.2.3-RELEASE_wasm
```

### WASM Too Large
**Normal sizes:**
- Debug: 78MB (uncompressed)
- Release: 20-30MB
- Release + Osize: 10-15MB

**If larger:** Check for accidental includes

## Testing Checklist

Before marking work complete:

- [ ] Build succeeds from Examples/TodoApp directory
- [ ] WASM file created (check size ~78MB for debug)
- [ ] WASM copied to public/ directory
- [ ] Flask server running on port 8000
- [ ] Browser loads page (check with tabs_context_mcp)
- [ ] Console shows no errors (especially addEventListener)
- [ ] Console shows "Render complete!"
- [ ] Screenshot shows UI elements rendering
- [ ] Event handlers work (if applicable)
- [ ] No "unreachable" errors in console

## Development Tips

1. **Always check WASM hash** when debugging - cache issues are extremely common
2. **Read console messages** before taking screenshots - errors happen before render
3. **Use Flask, never SimpleHTTPServer** - cache headers matter
4. **Build from app directory** - avoids RavenCLI issues
5. **Store closures in Swift** - never on DOM elements
6. **Test in browser immediately** - catch runtime issues early
7. **Take screenshots** - verify visual output
8. **Check memory docs** - we've documented patterns

## Quick Commands

```bash
# Build
cd Examples/TodoApp
swift build --swift-sdk swift-6.2.3-RELEASE_wasm

# Copy + verify
cp .build/wasm32-unknown-wasip1/debug/TodoApp.wasm public/TodoApp-v2.wasm
md5 public/TodoApp-v2.wasm

# Serve (if not running)
python3 serve.py

# Check if server running
lsof -ti:8000
```

## Success Criteria

A successful Raven development session should result in:

1. ✅ Clean build (only warnings, no errors)
2. ✅ WASM file deployed to public/
3. ✅ Flask server serving with cache headers
4. ✅ Browser loads and instantiates WASM
5. ✅ Console shows "Render complete!"
6. ✅ No addEventListener crashes
7. ✅ UI renders (even if not fully styled)
8. ✅ No "unreachable" errors

## Related Skills

- **swift-wasm:** For general Swift WASM toolchain setup
- **keybindings-help:** For customizing development shortcuts

## Notes

This skill encodes lessons learned from fixing the addEventListener crash bug in DOMBridge, which was caused by JavaScriptKit's dynamic member access failing on non-existent properties. The solution was to eliminate all dynamic property access on DOM elements and use JSClosure-based handlers stored in Swift dictionaries.

The aggressive browser caching of WASM files remains a challenge and requires explicit cache-busting strategies.
