# Changelog

All notable changes to Raven will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.4.0] - 2026-02-03 - Phase 10: Shapes & Visual Effects

### Added

#### Shape System

- **Shape Protocol** - Foundation for all 2D shapes in Raven
  - `path(in:)` method for defining shape outlines
  - Automatic View conformance for seamless integration
  - SVG-based rendering for resolution-independent graphics
  - Composable with standard view modifiers

- **5 Built-in Shapes**
  - `Circle` - Perfect circular shape using SVG `<circle>` element
  - `Rectangle` - Rectangular shape with sharp corners
  - `RoundedRectangle(cornerRadius:)` - Rectangle with rounded corners
  - `Capsule` - Rounded rectangle with fully circular ends
  - `Ellipse` - Elliptical shape with separate horizontal/vertical radii

- **Path Type** - Comprehensive custom drawing API
  - Drawing commands: `move(to:)`, `addLine(to:)`, `closeSubpath()`
  - Curves: `addQuadCurve(to:control:)`, `addCurve(to:control1:control2:)`
  - Arcs: `addArc(center:radius:startAngle:endAngle:clockwise:)`
  - Shape primitives: `addRect()`, `addRoundedRect()`, `addEllipse()`
  - Convenience initializers for common shapes
  - Path transformations with `CGAffineTransform`
  - Path combination with `addPath()`
  - SVG path data generation

#### Shape Modifiers

- **`.fill(_:)` Modifier** - Fill shapes with styles
  - Support for solid colors (`Color`)
  - Linear gradient support with SVG definitions
  - Radial gradient support
  - Any `ShapeStyle` conforming type
  - Hardware-accelerated rendering

- **`.stroke(_:lineWidth:)` Modifier** - Stroke shape outlines
  - Basic stroke with color and line width
  - Advanced stroke with `StrokeStyle`
  - Support for gradients in strokes
  - SVG stroke attributes

- **`.trim(from:to:)` Modifier** - Partial shape rendering
  - Trim shapes from start to end position (0.0 to 1.0)
  - Perfect for progress indicators
  - Circular progress bars
  - Animated path drawing effects
  - SVG stroke-dasharray implementation

- **StrokeStyle** - Advanced stroke configuration
  - `lineWidth` - Stroke thickness
  - `lineCap` - Line ending style (.butt, .round, .square)
  - `lineJoin` - Corner style (.miter, .round, .bevel)
  - `miterLimit` - Miter join limit
  - `dash` - Dash pattern array
  - `dashPhase` - Dash pattern offset

#### Visual Effect Modifiers (7 new modifiers)

- **`.blur(radius:)`** - Gaussian blur effect
  - CSS `filter: blur()` implementation
  - GPU-accelerated rendering
  - Radius in pixels for blur strength
  - Perfect for background blur and depth effects

- **`.brightness(_:)`** - Brightness adjustment
  - CSS `filter: brightness()` implementation
  - Multiplier-based (0.0 = black, 1.0 = normal, >1.0 = brighter)
  - GPU-accelerated
  - Ideal for hover effects and dimming

- **`.contrast(_:)`** - Contrast adjustment
  - CSS `filter: contrast()` implementation
  - Multiplier-based (0.0 = gray, 1.0 = normal, >1.0 = higher contrast)
  - GPU-accelerated
  - Great for making images pop

- **`.saturation(_:)`** - Color saturation adjustment
  - CSS `filter: saturate()` implementation
  - Multiplier-based (0.0 = grayscale, 1.0 = normal, >1.0 = vibrant)
  - GPU-accelerated
  - Perfect for color intensity control

- **`.grayscale(_:)`** - Grayscale conversion
  - CSS `filter: grayscale()` implementation
  - Range from 0.0 (full color) to 1.0 (full grayscale)
  - GPU-accelerated
  - Ideal for vintage effects and disabled states

- **`.hueRotation(_:)`** - Hue rotation effect
  - CSS `filter: hue-rotate()` implementation
  - Angle-based rotation around color wheel
  - GPU-accelerated
  - Great for color theming and artistic effects
  - Requires `Angle` type (degrees or radians)

- **`.shadow(color:radius:x:y:)`** - Drop shadow effect
  - CSS `filter: drop-shadow()` implementation
  - Configurable color, blur radius, and offset
  - GPU-accelerated
  - Perfect for depth and elevation

#### Clipping

- **`.clipShape(_:style:)`** - Clip content to shape bounds
  - Works with any `Shape` conforming type
  - SVG `<clipPath>` implementation
  - `FillStyle` support (.nonZero, .evenOdd)
  - Efficient reusable clip definitions
  - Perfect for circular profile pictures and custom masks

#### Supporting Types

- **Angle** - Representation for angles in degrees or radians
  - `Angle(degrees:)` initializer
  - `Angle(radians:)` initializer
  - Conversion between degrees and radians
  - Used by hue rotation and arc drawing

- **FillStyle** - Fill rule enumeration
  - `.nonZero` - Standard fill rule (default)
  - `.evenOdd` - Alternate fill rule for complex paths

- **InsettableShape Protocol** - For shapes with inset support
  - Foundation for advanced shape manipulation
  - Used by stroke modifier implementation

- **ShapeStyle Protocol** - Base protocol for fill/stroke styles
  - SVG gradient definition generation
  - Fill and stroke value generation
  - Extensible for custom styles

#### Testing & Quality

- 162+ comprehensive tests covering all Phase 10 features
  - Shape protocol and built-in shapes (40+ tests)
  - Path drawing and SVG generation (35+ tests)
  - Shape modifiers (fill, stroke, trim) (30+ tests)
  - Visual effect modifiers (22+ tests)
  - ClipShape and FillStyle (15+ tests)
  - Integration tests for real-world scenarios

- Working examples demonstrating usage
  - Custom shape creation examples
  - Progress indicator with trim
  - Visual effect combinations
  - Clipped images and content

### Changed

- **API Coverage** - Increased from ~60% to ~70%
  - Now includes comprehensive shape and drawing APIs
  - Full visual effects support
  - Better alignment with SwiftUI's graphics capabilities

- **Rendering System** - Enhanced SVG capabilities
  - Optimized SVG generation for shapes
  - Gradient definition caching
  - ClipPath reuse and optimization

### Statistics

- **Files Added:** 13 new files
  - 5 built-in shape implementations
  - Path type with comprehensive drawing API
  - Shape modifiers file
  - Visual effect modifiers file
  - ClipShape modifier
  - Supporting types (Angle, FillStyle, ShapeStyle, InsettableShape)

- **Lines of Code:** ~2,941 lines of production code
- **Test Coverage:** 162+ tests across 5 test files
- **Test Code:** ~2,167 lines of test code
- **Test/Code Ratio:** 0.74 (excellent coverage)

### Documentation

- Added [Documentation/Phase10.md](Documentation/Phase10.md) - Comprehensive Phase 10 guide
  - Complete shape system overview
  - All 5 built-in shapes with examples
  - Path API guide with drawing commands
  - Custom shape creation examples (star, heart, triangle)
  - Shape modifier documentation
  - Visual effects guide with all 7 modifiers
  - ClipShape usage and implementation
  - Web implementation details (SVG, CSS filters)
  - Browser compatibility matrix
  - Performance benchmarks and optimization tips
  - Future enhancement roadmap

- Updated [README.md](README.md)
  - "What's New in v0.4.0" section
  - Enhanced feature list with shapes and effects
  - Updated development phases table
  - API coverage updated to ~70%

- Updated [Documentation/API-Overview.md](Documentation/API-Overview.md)
  - Added Shape section with all built-in shapes
  - Added Path section with drawing API
  - Added visual effect modifiers section
  - Cross-references to Phase10.md

- Enhanced inline documentation
  - Full DocC comments for all new APIs
  - Comprehensive code examples in documentation
  - SVG implementation notes
  - Browser compatibility information
  - Performance considerations

### Browser Compatibility

All Phase 10 features support modern browsers:

- **SVG Shapes:** All browsers with SVG support
- **CSS Filters:** Chrome 53+, Firefox 35+, Safari 9.1+, Edge 79+
- **SVG ClipPath:** All browsers with SVG support
- **Linear Gradients:** All browsers with SVG support

### Performance Notes

- **GPU Acceleration:** All visual effects are GPU-accelerated via CSS filters
- **SVG Rendering:** Hardware-composited for smooth animations
- **Efficient Updates:** Only changed shape properties trigger re-renders
- **Gradient Caching:** Gradient definitions are reused across instances
- **ClipPath Reuse:** ClipPath definitions shared efficiently

## [0.3.0] - 2026-02-03 - Phase 9: Modern State & UI

### Added

#### Modern State Management

- **@Observable Macro** - Modern alternative to ObservableObject (iOS 17+ API)
  - Automatic property observation without `@Published` wrappers
  - `ObservationRegistrar` for tracking property changes
  - `@ObservationIgnored` for excluding properties from observation
  - Manual implementation pattern for SwiftWasm compatibility
  - Full Swift 6.2 concurrency support with `@MainActor` isolation

- **@Bindable Property Wrapper** - Create bindings to Observable objects
  - Works seamlessly with `@Observable` classes
  - Dynamic member lookup for creating property bindings
  - Cleaner syntax than `@ObservedObject`
  - Type-safe binding creation with full compiler support

#### Empty State UI

- **ContentUnavailableView** - Standardized empty state interface
  - Centered layout with icon, title, description, and actions
  - Built-in `.search` variant for empty search results
  - Multiple initializer variants for flexibility
  - Comprehensive DocC documentation with usage examples
  - Web rendering with semantic HTML and CSS

#### Interaction Modifiers (5 new modifiers)

- **`.disabled(_:)`** - Disable user interaction with views
  - CSS-based implementation with visual feedback
  - Reduces opacity and changes cursor style
  - Works with all interactive controls

- **`.onTapGesture(count:perform:)`** - Handle tap/click events
  - Support for single and double taps
  - Custom action closures
  - Web implementation using click and dblclick events

- **`.onAppear(perform:)`** - Run actions when view appears
  - Lifecycle hook for setup and initialization
  - IntersectionObserver-based detection
  - Common pattern for data loading

- **`.onDisappear(perform:)`** - Run actions when view disappears
  - Lifecycle hook for cleanup and teardown
  - Resource management support
  - Pairs with onAppear for complete lifecycle

- **`.onChange(of:perform:)`** - React to value changes
  - Automatic change detection
  - Receives new value as parameter
  - Useful for search, validation, and side effects

#### Layout Modifiers (3 new modifiers)

- **`.clipped()`** - Clip content to bounding frame
  - CSS `overflow: hidden` implementation
  - Prevents content from drawing outside bounds
  - Essential for controlled layouts

- **`.aspectRatio(_:contentMode:)`** - Maintain aspect ratios
  - Modern CSS `aspect-ratio` property
  - `.fit` and `.fill` content modes
  - Responsive image and video layouts

- **`.fixedSize(horizontal:vertical:)`** - Fix view to ideal size
  - Prevents compression or expansion
  - CSS `fit-content` and `max-content`
  - Control over horizontal and vertical independently

#### Text Modifiers (3 new modifiers)

- **`.lineLimit(_:)`** - Limit text to specific number of lines
  - CSS `-webkit-line-clamp` implementation
  - Works with multiline text
  - Automatic ellipsis for overflow

- **`.multilineTextAlignment(_:)`** - Align multiline text
  - `.leading`, `.center`, `.trailing` options
  - CSS `text-align` implementation
  - Works with all text views

- **`.truncationMode(_:)`** - Control text truncation
  - `.head`, `.tail`, `.middle` modes
  - CSS `text-overflow: ellipsis`
  - Directional control for truncation

#### Testing & Quality

- 159+ comprehensive tests covering all Phase 9 features
  - @Observable and @Bindable state management tests
  - ContentUnavailableView rendering tests
  - All 10 new modifiers thoroughly tested
  - Integration tests for real-world scenarios

- Working examples demonstrating usage
  - Modern state management patterns
  - Empty state UI best practices
  - Modifier composition examples

### Changed

- **State Management** - Enhanced API coverage from ~50% to ~60%
  - Now includes both legacy (`ObservableObject`) and modern (`@Observable`) approaches
  - Better alignment with SwiftUI's evolution
  - Migration path clearly documented

- **View Modifiers** - Significantly expanded modifier library
  - Organized into interaction, layout, and text categories
  - Consistent API design patterns
  - Comprehensive documentation for all modifiers

### Migration Guide

#### From ObservableObject to @Observable

The new `@Observable` macro provides a cleaner, more modern approach to state management:

**Before (ObservableObject):**
```swift
@MainActor
class UserSettings: ObservableObject {
    @Published var username: String = ""
    @Published var isDarkMode: Bool = false

    init() {
        setupPublished()
    }
}

struct SettingsView: View {
    @ObservedObject var settings: UserSettings

    var body: some View {
        TextField("Username", text: $settings.username)
    }
}
```

**After (@Observable):**
```swift
@Observable
@MainActor
class UserSettings {
    var username: String = ""
    var isDarkMode: Bool = false
}

struct SettingsView: View {
    @Bindable var settings: UserSettings

    var body: some View {
        TextField("Username", text: $settings.username)
    }
}
```

**Key Changes:**
1. Replace `ObservableObject` conformance with `@Observable` macro
2. Remove `@Published` from properties (all properties are automatically observable)
3. Remove `setupPublished()` call from init
4. Replace `@ObservedObject` with `@Bindable` in views that need bindings
5. Keep using `@StateObject` for view-owned objects (works with both approaches)

**When to Migrate:**
- `@Observable` is recommended for new code
- `ObservableObject` remains fully supported for existing code
- Both approaches can coexist in the same application
- Migrate incrementally at your own pace

### Documentation

- Added [Documentation/Phase9.md](Documentation/Phase9.md) - Comprehensive Phase 9 guide
  - Overview of all Phase 9 features
  - Usage examples and best practices
  - Web implementation details
  - Performance considerations
  - Future enhancement roadmap

- Updated [README.md](README.md)
  - "What's New in v0.3.0" section
  - Enhanced feature list
  - Updated development phases table
  - API coverage metrics

- Enhanced inline documentation
  - Full DocC comments for all new APIs
  - Code examples in documentation
  - Cross-references between related APIs
  - Migration guides and best practices

## [0.2.0] - Earlier Phases

### Phase 5: Build Pipeline
- CLI tooling for creating and building projects
- WASM compilation support
- Asset bundling and optimization
- Development server with hot reload

### Phase 4: Advanced UI
- Navigation with NavigationView and NavigationLink
- Grid layouts (LazyVGrid, LazyHGrid)
- GeometryReader for dynamic layouts
- Form and Section components
- Font modifiers and text styling

### Phase 3: Rich UI & State
- @StateObject for view-owned objects
- @ObservedObject for shared objects
- TextField and SecureField input controls
- Toggle, Slider, Stepper controls
- List and ForEach for collections
- Image with multiple source types

### Phase 2: Interactive Apps
- @State for local view state
- @Binding for two-way data flow
- Button with action handling
- Event system and render loop
- Interactive state management

### Phase 1: Core Infrastructure
- View protocol and ViewBuilder
- Virtual DOM (VNode) system
- Efficient diffing algorithm
- DOMBridge for web rendering
- Basic layout containers (VStack, HStack, ZStack)
- Text rendering

---

## Version History

- **0.4.0** (2026-02-03) - Phase 10: Shapes & Visual Effects
- **0.3.0** (2026-02-03) - Phase 9: Modern State & UI
- **0.2.0** (Earlier) - Phases 1-5: Foundation through Build Pipeline
- **0.1.0** (Initial) - Proof of concept

---

## Roadmap

### Phase 6 (In Progress) - Developer Experience
- [ ] Hot reload development server
- [ ] Live preview in browser
- [ ] Enhanced debugging tools
- [ ] Comprehensive documentation
- [ ] Tutorial series

### Phase 7 (Planned) - Production Ready
- [ ] Performance benchmarks and optimization
- [ ] Accessibility features (ARIA support)
- [ ] Comprehensive example applications
- [ ] Production deployment guides
- [ ] v1.0 release

### Phase 8 (Planned) - Advanced Components
- [ ] Animation system
- [ ] Advanced gesture recognition
- [ ] Sheet and popover presentations
- [ ] Custom layout containers
- [ ] Advanced navigation patterns

### Future Considerations
- Server-side rendering (SSR)
- Progressive Web App (PWA) support
- Component library ecosystem
- Visual design tools
- Browser extension APIs

---

For more information, see the [README](README.md) and [Documentation](Documentation/) folder.
