# Raven Dev - Hot Reloading Development Server

A development server for Raven apps with automatic WASM rebuilding and browser hot reloading.

## Features

- 🔄 **Hot Reload**: Automatically rebuilds WASM when source files change
- 🌐 **Auto Browser Reload**: Browser automatically refreshes when new WASM is ready
- 🎨 **Colored Output**: Clear, colorful terminal output for build status
- ⚡ **Fast**: Debounced rebuilds, queued builds during active build
- 🛡️ **Safe**: Proper cache headers, CORS support, graceful shutdown
- 👀 **Watch Multiple Dirs**: Watches both app and framework sources

## Installation

Install Python dependencies:

```bash
pip3 install -r requirements.txt
```

Or install individually:

```bash
pip3 install flask flask-cors watchdog
```

## Usage

### Basic Usage

From your app directory (e.g., `Examples/TodoApp`):

```bash
python3 raven-dev.py
```

This will:
1. Perform an initial build
2. Start watching source files
3. Start Flask server on port 8000
4. Open browser to http://localhost:8000
5. Auto-reload browser when sources change

### Options

```bash
python3 raven-dev.py [OPTIONS]

Options:
  --port PORT           Port to serve on (default: 8000)
  --no-browser         Don't open browser automatically
  --no-initial-build   Skip initial build (faster startup)
```

### Examples

```bash
# Use different port
python3 raven-dev.py --port 3000

# Skip initial build (if you just built)
python3 raven-dev.py --no-initial-build

# Don't open browser
python3 raven-dev.py --no-browser
```

## How It Works

### File Watching

Watches these directories for `.swift` file changes:
- `Sources/` - Your app source code
- `../../Sources/` - Raven framework source code

When a file changes:
1. Debounces for 1 second (waits for multiple changes)
2. Triggers `swift build --swift-sdk swift-6.2.3-RELEASE_wasm`
3. Copies built WASM to `public/TodoApp-v2.wasm`
4. Updates WASM hash for browser detection

### Hot Reload

Injects a script into `index.html` that:
- Polls `/api/status` every 2 seconds
- Checks if WASM hash changed
- Reloads page when new WASM is detected

### Cache Control

Sets proper headers for WASM files:
```
Cache-Control: no-cache, no-store, must-revalidate
Pragma: no-cache
Expires: 0
```

This prevents the aggressive browser caching that causes issues during development.

## Terminal Output

Colorful, timestamped output:

```
[12:34:56] 🚀 Raven Dev Server starting on port 8000
[12:34:56] 👀 Watching: Sources
[12:34:56] 👀 Watching: ../../Sources
[12:34:56] 🔨 Building TodoApp.wasm...
[12:35:02] ✅ Build successful (6.2s, 78.1MB)
[12:35:02]    Hash: 9c41ea6d...
[12:35:10] 📝 Changed: TodoApp.swift
[12:35:10] 🔨 Building TodoApp.wasm...
[12:35:15] ✅ Build successful (5.1s, 78.1MB)
```

## Troubleshooting

### "Must run from app directory"

Make sure you're in the app directory with `Package.swift`:
```bash
cd Examples/TodoApp
python3 raven-dev.py
```

### "swift-6.2.3-RELEASE_wasm not found"

Install the WASM SDK:
```bash
swift sdk install https://download.swift.org/swift-6.2.3-release/wasm-sdk/swift-6.2.3-RELEASE/swift-6.2.3-RELEASE_wasm.artifactbundle.tar.gz --checksum 394040ecd5260e68bb02f6c20aeede733b9b90702c2204e178f3e42413edad2a
```

### Build Errors

The dev server shows the first 5 build errors. For full output:
```bash
swift build --swift-sdk swift-6.2.3-RELEASE_wasm
```

### Port Already in Use

Use a different port:
```bash
python3 raven-dev.py --port 3000
```

Or kill the process using port 8000:
```bash
lsof -ti:8000 | xargs kill -9
```

### Browser Not Auto-Reloading

Check:
1. Hot reload script injected in `index.html` (look for `raven-hot-reload`)
2. Browser console for errors
3. `/api/status` endpoint returns JSON

Manually check status:
```bash
curl http://localhost:8000/api/status
```

### Slow Builds

First build is always slow (compiles all dependencies). Subsequent builds are incremental and much faster.

Tips:
- Use debug builds during development
- Only build release for production
- Keep changes small and focused

## Comparison with Carton

Similar to `carton dev`, but:
- ✅ Uses official Swift 6.2.3 + WASM SDK
- ✅ Works with Raven framework structure
- ✅ Proper cache control for WASM
- ✅ Colored terminal output
- ✅ Watches framework sources too
- ✅ Customizable (Python, easy to modify)

## API Endpoints

### GET /api/status

Returns build status and WASM hash:

```json
{
  "building": false,
  "wasm_hash": "9c41ea6dad787ffbf93dad1d3d8aa655",
  "timestamp": "2026-02-05T01:23:45.678901"
}
```

Used by hot reload script to detect changes.

## Configuration

Edit `raven-dev.py` to customize:

```python
# Lines 16-21
SWIFT_SDK = "swift-6.2.3-RELEASE_wasm"
WASM_TARGET = "wasm32-unknown-wasip1/debug"
APP_NAME = "TodoApp"
SOURCE_DIRS = ["Sources", "../../Sources"]
PUBLIC_DIR = "public"
BUILD_DIR = ".build"
```

## Integration with IDEs

### VS Code

Add to `tasks.json`:
```json
{
  "label": "Raven Dev Server",
  "type": "shell",
  "command": "python3 raven-dev.py",
  "isBackground": true,
  "problemMatcher": []
}
```

Run with: `Cmd+Shift+P` → "Tasks: Run Task" → "Raven Dev Server"

### Xcode

Not recommended (Xcode doesn't support WASM targets well). Use VS Code or terminal.

## Advanced Usage

### Watch Additional Directories

Edit `SOURCE_DIRS` to add more directories:

```python
SOURCE_DIRS = [
    "Sources",
    "../../Sources",
    "../Shared",  # Add shared code
]
```

### Custom Build Command

Modify `build_wasm()` method to add build flags:

```python
result = subprocess.run(
    [
        'swift', 'build',
        '--swift-sdk', SWIFT_SDK,
        '-c', 'release',  # Release build
        '-Xswiftc', '-Osize',  # Size optimization
    ],
    capture_output=True,
    text=True,
    timeout=120
)
```

### Post-Build Hooks

Add custom actions after successful build:

```python
# In build_wasm() after successful build
if result.returncode == 0:
    # Custom post-build actions
    self.log("Running tests...", 'info')
    subprocess.run(['swift', 'test'])
```

## Tips & Best Practices

1. **Keep dev server running** - Rebuilds are much faster with warm cache
2. **Save frequently** - Builds trigger on save, faster iteration
3. **Use debug builds** - Release builds are slower, only use for production
4. **Check console** - Browser console shows WASM loading and hot reload status
5. **Clear browser cache** - If hot reload seems stuck, hard refresh (Cmd+Shift+R)

## Known Limitations

- Only watches `.swift` files (not Package.swift, assets, etc.)
- Debounce means very rapid saves might miss a rebuild (rare)
- First build is slow (10-30s), subsequent builds are fast (2-5s)
- Browser cache can still interfere (use hard refresh if needed)

## Future Enhancements

Potential improvements:
- [ ] WebSocket-based hot reload (instead of polling)
- [ ] Incremental compilation hints
- [ ] Build notifications (desktop/sound)
- [ ] Integration with Swift-DocC for live documentation
- [ ] Support for multiple apps simultaneously
- [ ] Build metrics and performance tracking

## Related

- **serve.py** - Simple Flask server without hot reload
- **docker-compose.yml** - Docker-based development setup
- **raven-dev skill** - Claude skill for Raven development workflow

---

**Built with the raven-dev workflow** 🚀
