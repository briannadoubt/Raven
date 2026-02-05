# Raven CLI

Professional command-line tools for Raven Swift WASM development.

## Installation

### Option 1: Install Globally (Recommended)

```bash
# From Raven project root
pip3 install -e .

# Now use from anywhere
cd Examples/TodoApp
raven dev
```

### Option 2: Add to PATH

```bash
# Add to your ~/.zshrc or ~/.bashrc
export PATH="/Users/bri/dev/Raven:$PATH"

# Reload shell
source ~/.zshrc

# Now use from anywhere
raven dev
```

### Option 3: Use Directly

```bash
# Run from Raven root
./raven dev

# Or from app directory
../../raven dev
```

## Commands

### `raven dev` - Hot Reload Development

Start development server with automatic rebuilding and browser hot reload.

```bash
raven dev                    # Start dev server
raven dev --port 3000        # Use different port
raven dev --no-browser       # Don't open browser
raven dev --no-initial-build # Skip first build
```

**Features:**
- 🔄 Watches `.swift` files for changes
- ⚡ Auto-rebuilds WASM (debounced, queued)
- 🌐 Auto-reloads browser when ready
- 🎨 Colored terminal output
- 👀 Watches both app and framework sources

**Output:**
```
[12:34:56] 🚀 Raven Dev Server on http://localhost:8000
[12:34:56] 👀 Watching: Sources
[12:34:56] 👀 Watching: ../../Sources
[12:34:56] 🔨 Building TodoApp.wasm...
[12:35:02] ✅ Build successful (6.2s, 78.1MB)
[12:35:02]    Hash: 9c41ea6d...

✓ Ready!
  • Edit .swift files to trigger rebuild
  • Browser auto-reloads on changes
  • Press Ctrl+C to stop
```

### `raven build` - Build WASM

Build WASM binary without starting server.

```bash
raven build                  # Debug build
raven build --release        # Release build
raven build --optimize-size  # Optimize for size
raven build --verbose        # Show all output
```

**Examples:**
```bash
# Production build
raven build --release --optimize-size

# Quick debug build
raven build

# See all compiler output
raven build --verbose
```

### `raven serve` - Serve Without Hot Reload

Serve app without file watching or auto-rebuild.

```bash
raven serve                  # Serve on port 8000
raven serve --port 3000      # Use different port
raven serve --no-browser     # Don't open browser
```

**Use when:**
- Testing a specific build
- Don't need hot reload
- Lighter resource usage

## Configuration

### `.raven.json` (Optional)

Create in your app root to customize settings:

```json
{
  "app_name": "MyApp",
  "swift_sdk": "swift-6.2.3-RELEASE_wasm",
  "public_dir": "public",
  "source_dirs": ["Sources", "../../Sources"]
}
```

**Defaults:**
- `app_name`: Directory name
- `swift_sdk`: `swift-6.2.3-RELEASE_wasm`
- `public_dir`: `public`
- `source_dirs`: `["Sources"]` (auto-adds framework if in Examples/)

## Workflow Examples

### Standard Development

```bash
cd Examples/TodoApp

# Start dev server (builds + watches + serves)
raven dev

# Edit TodoApp.swift
# → Auto-rebuilds
# → Browser auto-reloads
# → See changes in 2-5s
```

### Production Build

```bash
# Build optimized WASM
raven build --release --optimize-size

# Test production build
raven serve
```

### Quick Test

```bash
# Build once
raven build

# Serve without watching
raven serve --no-browser
```

## Directory Structure

The CLI works from any Raven app directory:

```
Raven/
├── raven              # CLI entry point
├── cli/               # Command modules
│   ├── __init__.py
│   ├── utils.py       # Shared utilities
│   ├── raven_dev.py   # Dev command
│   ├── raven_build.py # Build command
│   └── raven_serve.py # Serve command
├── setup.py           # Installation config
├── Examples/
│   └── TodoApp/
│       ├── Package.swift
│       ├── Sources/
│       └── public/    # Created automatically
```

**Run from:**
- App directory: `cd Examples/TodoApp && raven dev`
- Anywhere (if installed): `raven dev` (finds Package.swift)
- Relative path: `cd Examples/TodoApp && ../../raven dev`

## Troubleshooting

### "Not in a Raven app directory"

Must have `Package.swift` in current or parent directory.

```bash
# ✅ Correct
cd Examples/TodoApp
raven dev

# ❌ Wrong
cd Examples
raven dev
```

### "click not installed"

Install dependencies:

```bash
pip3 install click flask flask-cors watchdog
```

Or install the CLI properly:

```bash
pip3 install -e .
```

### Port Already in Use

Use different port or kill existing process:

```bash
# Use different port
raven dev --port 3000

# Or kill existing
lsof -ti:8000 | xargs kill -9
```

### Swift SDK Not Found

Install WASM SDK:

```bash
swift sdk install https://download.swift.org/swift-6.2.3-release/wasm-sdk/swift-6.2.3-RELEASE/swift-6.2.3-RELEASE_wasm.artifactbundle.tar.gz \
  --checksum 394040ecd5260e68bb02f6c20aeede733b9b90702c2204e178f3e42413edad2a
```

### Build Errors

See full output:

```bash
raven build --verbose
```

Or build directly:

```bash
swift build --swift-sdk swift-6.2.3-RELEASE_wasm
```

## vs Carton

Similar to `carton dev`, but:

| Feature | Carton | Raven CLI |
|---------|--------|-----------|
| Swift Version | SwiftWasm 6.0.2 | Official Swift 6.2.3 |
| WASM SDK | Custom | Official swift.org |
| Framework Support | Limited | Full Raven support |
| Cache Control | Basic | Comprehensive |
| Customization | Limited | Highly customizable |
| Output | Basic | Colored, detailed |

## Integration

### VS Code

Add to `.vscode/tasks.json`:

```json
{
  "version": "2.0.0",
  "tasks": [
    {
      "label": "Raven Dev",
      "type": "shell",
      "command": "raven dev",
      "isBackground": true,
      "problemMatcher": []
    }
  ]
}
```

Run: `Cmd+Shift+P` → "Tasks: Run Task" → "Raven Dev"

### Git Hooks

Pre-commit hook:

```bash
#!/bin/sh
# .git/hooks/pre-commit

cd Examples/TodoApp
raven build || exit 1
```

## Development

### Adding New Commands

1. Create `cli/raven_newcommand.py`:

```python
import click
from .utils import Colors, log

@click.command()
def newcommand_command():
    """Description of new command"""
    log("Doing something...", 'info')
```

2. Register in `raven`:

```python
from cli.raven_newcommand import newcommand_command
cli.add_command(newcommand_command, name='newcommand')
```

3. Test:

```bash
./raven newcommand
```

### Debugging

Run with Python directly:

```bash
python3 raven dev --verbose
```

Or add debug logging in `cli/utils.py`.

## Future Commands

Planned additions:

- `raven init` - Create new Raven app
- `raven test` - Run tests in browser
- `raven bundle` - Create production bundle
- `raven deploy` - Deploy to hosting
- `raven docs` - Generate documentation

## Support

- **Documentation**: See `.claude/skills/raven-dev/`
- **Examples**: `Examples/TodoApp/`
- **Issues**: File on GitHub

---

**Built with the raven-dev workflow** 🚀
