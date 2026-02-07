# Raven

<div align="center">

<img width="384" height="384" alt="Raven@0 5" src="https://github.com/user-attachments/assets/8d0656c7-de7a-4ff8-8953-67affd5427fa" />

**SwiftUI for the Web**

Cross-compile SwiftUI applications to WebAssembly and run them natively in modern browsers.

[![Swift](https://img.shields.io/badge/Swift-6.2-orange.svg)](https://swift.org)
[![Platform](https://img.shields.io/badge/Platform-macOS%20%7C%20Linux%20%7C%20WASM-blue.svg)](https://swift.org)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Swift Package Manager](https://img.shields.io/badge/SPM-compatible-brightgreen.svg)](Package.swift)

</div>

---

## Overview

Raven is a Swift framework that brings the power and elegance of SwiftUI to the web. Write your UI once in Swift using familiar SwiftUI APIs, and Raven compiles it to WebAssembly for native browser execution. With a virtual DOM architecture, efficient diffing algorithms, and full Swift 6.2 strict concurrency support, Raven delivers both developer productivity and runtime performance.

Whether you're building interactive web applications, creating cross-platform tools, or bringing existing SwiftUI expertise to the browser, Raven provides a type-safe, modern approach to web development without requiring JavaScript knowledge.

## Features

- **Full SwiftUI API Compatibility** - Use familiar SwiftUI views, modifiers, and patterns
- **Virtual DOM with Efficient Diffing** - Minimal DOM updates for optimal performance
- **Swift 6.2 Strict Concurrency** - Type-safe, data-race-free code with `@MainActor` isolation
- **WebAssembly Runtime** - Native browser execution without JavaScript dependencies
- **Modern State Management** - `@Observable`, `@Bindable`, `@State`, `@Binding`, `@StateObject`, and `@ObservedObject` support
- **Hot Reload Development** - Fast iteration with live code updates (Phase 6)
- **Complete Build Tooling** - CLI tools for creating, building, and serving applications
- **No Combine Dependency** - Linux and WASM compatible with custom publisher implementation
- **Rich UI Components** - Text, Button, Image, TextField, Toggle, List, ContentUnavailableView, and more
- **Shape System** - Shape protocol, 5 built-in shapes, Path for custom drawing, SVG rendering
- **Modern Layout APIs** - containerRelativeFrame(), ViewThatFits for responsive, adaptive layouts
- **Layout System** - VStack, HStack, ZStack, LazyVGrid, LazyHGrid, GeometryReader with advanced modifiers
- **Navigation** - NavigationLink and navigation state management
- **Scroll Features** - Advanced scroll behavior and scroll-based animations
- **Search** - Built-in searchable modifier with suggestions and filtering
- **Gesture System** - Complete gesture recognition with 6 gesture types, @GestureState, composition, and web event integration
- **Animation System** - Complete animation support with curves, transitions, keyframes, and GPU acceleration
- **Visual Effects** - 7 GPU-accelerated effects (blur, brightness, contrast, saturation, grayscale, hue rotation, shadow)
- **Comprehensive View Modifiers** - Layout, interaction, text styling, shape styling, animations, gestures, and visual effects
- **Environment Values** - Propagate configuration through the view hierarchy

## Quick Start

### Prerequisites

- Swift 6.2 or later
- SwiftWasm toolchain (for WASM builds)
- Modern web browser (Chrome, Firefox, Safari, Edge)

### Installation

Clone the Raven repository:

```bash
git clone https://github.com/yourusername/Raven.git
cd Raven
swift build -c release
```

### Create Your First App

Use the Raven CLI to scaffold a new project:

```bash
# Create a new project
./raven create MyApp
cd MyApp

# Start the development server
../raven dev

# Open http://localhost:8080 in your browser
```

### Build for Production

```bash
# Build optimized WASM bundle
./raven build --release

# Output will be in dist/
```

## AI Agent Support

This repository supports both Claude and Codex workflows.

- Claude config and skills: `/Users/bri/dev/Raven/.claude/`
- Codex config and skills: `/Users/bri/dev/Raven/.codex/`
- Codex repo instructions: `/Users/bri/dev/Raven/AGENTS.md`

Codex local skills included:

- `raven-dev`: `/Users/bri/dev/Raven/.codex/skills/raven-dev/SKILL.md`
- `swift-wasm`: `/Users/bri/dev/Raven/.codex/skills/swift-wasm/SKILL.md`

## What's New in v0.7.0 (Phase 13)

Raven v0.7.0 introduces a comprehensive gesture recognition system with full SwiftUI compatibility:

**Gesture System**
- Complete `Gesture` protocol foundation with composability support
- 6 built-in gesture types: `TapGesture`, `SpatialTapGesture`, `LongPressGesture`, `DragGesture`, `RotationGesture`, `MagnificationGesture`
- `@GestureState` property wrapper for automatic state management with reset
- Gesture modifiers: `.onChanged()`, `.onEnded()`, `.updating()` for lifecycle handling
- Three view integration methods: `.gesture()`, `.simultaneousGesture()`, `.highPriorityGesture()` with priority control
- Gesture composition operators: `.simultaneously(with:)`, `.sequenced(before:)`, `.exclusively(before:)`
- `GestureMask` options for controlling gesture recognition scope
- `EventModifiers` support for detecting keyboard modifiers during gestures
- `Transaction` support for animation integration

**Web Platform Integration**
- Pointer Events API for unified mouse/touch handling
- Touch Events for multi-touch gestures (rotation, magnification)
- Coordinate space transformations (local, global, named)
- Velocity calculation for drag gestures
- Event throttling for performance (60fps)
- Automatic event listener cleanup

**Testing & Quality**
- 194+ comprehensive tests across all gesture features
- Plus existing unit tests for each gesture component
- ~5,224 lines of production code, ~3,782 lines of test code
- Full DocC documentation for all APIs
- API coverage increased from ~85% to ~90%

See [CHANGELOG.md](CHANGELOG.md) and [Phase 13 Documentation](Documentation/Phase13.md) for complete details.

## What's New in v0.6.0 (Phase 12)

Raven v0.6.0 introduces a comprehensive animation system with full SwiftUI compatibility:

**Animation System**
- Complete animation curve support (linear, ease, spring, custom timing)
- `.animation()` modifier for implicit, value-based animations
- `withAnimation()` for explicit animation blocks with completion handlers
- Full transition system (8 transition types: opacity, scale, slide, move, push, offset, custom, asymmetric)
- `keyframeAnimator()` for multi-step animations with precise timing (iOS 17+)
- CSS-based implementation with GPU acceleration for 60fps performance

**Animation Types & Curves**
- Linear animations for constant-rate changes
- Ease animations (easeIn, easeOut, easeInOut, default)
- Spring animations with physics-based motion and customizable damping
- Custom cubic Bézier timing curves
- Named spring configurations (.bouncy, .smooth, .snappy)

**Advanced Features**
- Combined transitions for complex effects
- Asymmetric transitions (different insertion/removal)
- Animation interruption and cancellation
- Multiple animation tracks in keyframes
- Trigger-based animation re-execution
- Cross-feature integration with Phases 9-11

**Testing & Quality**
- 50+ integration tests across all animation features
- Plus existing unit tests for each animation component
- ~2,664 lines of production code, ~938 lines of verification tests
- 10 complete working examples (~1,200+ lines)
- Full DocC documentation for all APIs
- API coverage increased from ~80% to ~85%

See [CHANGELOG.md](CHANGELOG.md) and [Phase 12 Documentation](Documentation/Phase12.md) for complete details.

## What's New in v0.5.0 (Phase 11)

Raven v0.5.0 introduces modern layout APIs, enhanced scroll features, and search functionality:

**Modern Layout APIs**
- `containerRelativeFrame()` for responsive sizing relative to containers
- `ViewThatFits` for adaptive layouts that adjust to available space
- Modern alternative to GeometryReader with cleaner syntax
- CSS container queries for efficient responsive design

**Scroll Enhancements (3 modifiers)**
- `.scrollBounceBehavior()` - Control bounce/overscroll behavior
- `.scrollClipDisabled()` - Allow content to overflow (shadows, glows)
- `.scrollTransition()` - Animate content based on scroll position
- IntersectionObserver-based scroll animations

**Search Functionality**
- `.searchable()` modifier with suggestions and filtering
- Real-time search with two-way binding
- Search field placement options (navigation, sidebar, toolbar)
- Native HTML search input with keyboard shortcuts

**Testing & Quality**
- 102+ comprehensive tests across all Phase 11 features
- Plus integration tests for real-world scenarios
- ~1,796 lines of production code, ~2,172 lines of test code
- Full DocC documentation for all new APIs
- API coverage increased from ~70% to ~80%

See [CHANGELOG.md](CHANGELOG.md) and [Phase 11 Documentation](Documentation/Phase11.md) for complete details.

## Example Code

Here's a simple counter app demonstrating Raven's reactive state management:

```swift
import Raven

@MainActor
struct CounterApp: View {
    @State private var count = 0
    @State private var stepSize = 1

    var body: some View {
        VStack(spacing: 20) {
            Text("Counter")
                .font(.largeTitle)
                .foregroundColor(.blue)

            Text("Count: \(count)")
                .font(.title)

            HStack(spacing: 10) {
                Button("−") {
                    count -= stepSize
                }
                .padding()
                .background(Color.red)
                .foregroundColor(.white)

                Button("+") {
                    count += stepSize
                }
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
            }

            HStack {
                Text("Step size:")
                TextField("Step", value: $stepSize)
                    .frame(width: 60)
            }

            Button("Reset") {
                count = 0
                stepSize = 1
            }
            .padding()
            .background(Color.gray)
        }
        .padding(40)
    }
}
```

## Documentation

- **[Getting Started Guide](Documentation/GettingStarted.md)** - Build your first Raven application
- **[API Documentation](Documentation/)** - Complete API reference and examples
- **[Architecture Overview](Docs/)** - Learn how Raven works under the hood
- **[Examples](Examples/)** - Sample applications demonstrating key features

## Development Phases

Raven is being developed in phases, each delivering complete, tested functionality:

| Phase | Focus | Status | Key Deliverables |
|-------|-------|--------|------------------|
| **Phase 1** | Core Infrastructure | ✅ Complete | Virtual DOM, View protocol, ViewBuilder, diffing algorithm, DOMBridge |
| **Phase 2** | Interactive Apps | ✅ Complete | @State, @Binding, Button, event handling, render loop |
| **Phase 3** | Rich UI & State | ✅ Complete | @StateObject, @ObservedObject, TextField, Toggle, List, ForEach, Image |
| **Phase 4** | Advanced UI | ✅ Complete | Navigation, Grid layouts, GeometryReader, Form, Section, Font modifiers |
| **Phase 5** | Build Pipeline | ✅ Complete | CLI tooling, WASM compilation, asset bundling, optimization |
| **Phase 6** | Developer Experience | 🔄 In Progress | Hot reload, live preview, debugging tools, documentation |
| **Phase 7** | Production Ready | ⏳ Planned | Performance optimization, accessibility, comprehensive examples |
| **Phase 8** | Advanced Components | ⏳ Planned | Advanced gestures, navigation improvements, custom layouts |
| **Phase 9** | Modern State & UI | ✅ Complete | @Observable, @Bindable, ContentUnavailableView, 10 new modifiers |
| **Phase 10** | Shapes & Visual Effects | ✅ Complete | Shape system, Path, visual effects, clipping, 162+ tests |
| **Phase 11** | Modern Layout & Search | ✅ Complete | containerRelativeFrame, ViewThatFits, scroll features, searchable, 102+ tests |
| **Phase 12** | Animation System | ✅ Complete | Animation curves, transitions, keyframeAnimator, GPU acceleration, 50+ tests |
| **Phase 13** | Gesture System | ✅ Complete | 6 gesture types, @GestureState, composition, web events, 194+ tests |

## Architecture

Raven uses a three-layer architecture to bridge SwiftUI and the browser DOM:

```
┌─────────────────────────────────────┐
│      SwiftUI-like View Layer        │
│  (Text, VStack, Button, @State...)  │
└──────────────┬──────────────────────┘
               │ toVNode()
               ▼
┌─────────────────────────────────────┐
│         Virtual DOM Layer           │
│     (VNode tree, Differ, Patch)     │
└──────────────┬──────────────────────┘
               │ applyPatch()
               ▼
┌─────────────────────────────────────┐
│          DOM Bridge Layer           │
│    (JavaScriptKit, DOM updates)     │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│          Browser DOM                │
└─────────────────────────────────────┘
```

### How It Works

1. **View Layer**: Write your UI using SwiftUI-compatible views and modifiers
2. **Virtual DOM**: Views are converted to lightweight `VNode` trees
3. **Diffing**: When state changes, Raven computes minimal differences between old and new trees
4. **Patching**: Only the changed DOM nodes are updated via the DOMBridge
5. **Rendering**: Browser displays the updated UI

This architecture ensures efficient updates and maintains SwiftUI's declarative programming model while targeting web browsers.

## Requirements

### Development Environment

- **Swift**: 6.2 or later
- **OS**: macOS 13+, Linux (Ubuntu 20.04+, Amazon Linux 2023+)
- **SwiftWasm**: Latest SwiftWasm toolchain or `carton` for WASM builds

### Runtime

- **Browser**: Modern browser with WebAssembly support
  - Chrome 87+
  - Firefox 89+
  - Safari 15+
  - Edge 88+

### Dependencies

Raven uses minimal external dependencies:

- **JavaScriptKit** - Swift/JavaScript interop for WASM
- **swift-argument-parser** - CLI argument handling

## Project Structure

```
Raven/
├── Sources/
│   ├── Raven/              # Main SwiftUI-like framework
│   │   ├── Core/          # View protocol, ViewBuilder, AnyView
│   │   ├── Views/         # UI components (Text, Button, etc.)
│   │   ├── State/         # @State, @Binding, ObservableObject
│   │   ├── VirtualDOM/    # VNode, Differ, VTree
│   │   ├── Rendering/     # DOMBridge, render loop
│   │   ├── Modifiers/     # View modifiers
│   │   └── Environment/   # Environment values
│   ├── RavenRuntime/      # Runtime support and utilities
│   └── RavenCLI/          # Command-line tools
├── Tests/                 # Comprehensive test suite
├── Examples/              # Sample applications
└── Documentation/         # API docs and guides
```

## Contributing

We welcome contributions to Raven! Here's how you can help:

### Getting Started

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes following Swift 6.2 strict concurrency guidelines
4. Write tests for your changes
5. Ensure all tests pass (`swift test`)
6. Submit a pull request

### Guidelines

- Follow the existing code style and architecture
- Use `@MainActor` isolation for UI-related code
- Ensure all types are `Sendable` where appropriate
- Add tests for new features
- Update documentation for API changes
- Write clear commit messages

### Code of Conduct

Please be respectful and constructive in all interactions. We're building an inclusive community focused on advancing Swift on the web.

### Reporting Issues

Found a bug or have a feature request? Please open an issue on GitHub with:

- A clear description of the problem or suggestion
- Steps to reproduce (for bugs)
- Expected vs. actual behavior
- Swift version, OS, and browser information

## Testing

Run the test suite:

```bash
# Run all tests
swift test

# Run specific test suite
swift test --filter RavenTests
swift test --filter VirtualDOMTests

# Run with coverage
swift test --enable-code-coverage
```

## Performance

Raven is designed for production use with:

- **Efficient Virtual DOM** - Only changed nodes are updated
- **Batched Updates** - Multiple state changes coalesced into single render
- **Minimal Allocations** - Value types and copy-on-write semantics
- **WASM Optimization** - Small bundle sizes with release builds

Benchmark results and performance guidelines coming in Phase 7.

## License

Raven is released under the MIT License. See [LICENSE](LICENSE) for details.

```
MIT License

Copyright (c) 2026 Raven Contributors

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

## Acknowledgments

Raven stands on the shoulders of giants:

- **SwiftUI** - Apple's revolutionary declarative UI framework that inspired Raven's API design
- **SwiftWasm** - The amazing work by the SwiftWasm team enabling Swift in browsers
- **React** - Virtual DOM concepts and reconciliation algorithms
- **Swift Community** - For building an incredible language and ecosystem

Special thanks to all contributors who have helped shape Raven into a powerful tool for web development.

## Roadmap

### Phase 6 (In Progress)

- [ ] Hot reload development server
- [ ] Live preview in browser
- [ ] Enhanced debugging tools
- [ ] Comprehensive documentation
- [ ] Tutorial series

### Phase 7 (Planned)

- [ ] Performance benchmarks and optimization
- [ ] Accessibility features (ARIA support)
- [ ] Comprehensive example applications
- [ ] Production deployment guides
- [ ] v1.0 release

### Future Considerations

- Server-side rendering (SSR)
- Progressive Web App (PWA) support
- Component library ecosystem
- Visual design tools
- Browser extension APIs

---

<div align="center">

**Built with ❤️ using Swift**

[Documentation](Documentation/) • [Examples](Examples/) • [Contributing](#contributing) • [License](LICENSE)

</div>
