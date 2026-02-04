# Changelog

All notable changes to Raven will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.6.0] - 2026-02-03 - Phase 12: Animation System

### Added

#### Core Animation Types

- **`Animation` Type** - Comprehensive animation curve support
  - `.linear` - Constant-rate animations (default 0.25s)
  - `.linear(duration:)` - Custom duration linear animations
  - `.easeIn` - Slow start, fast end (default 0.25s)
  - `.easeIn(duration:)` - Custom duration ease-in
  - `.easeOut` - Fast start, slow end (default 0.25s)
  - `.easeOut(duration:)` - Custom duration ease-out
  - `.easeInOut` - Slow start and end (default 0.25s)
  - `.easeInOut(duration:)` - Custom duration ease-in-out
  - `.default` - Standard ease curve (0.25s)
  - `.spring()` - Physics-based spring animation
  - `.spring(response:dampingFraction:)` - Custom spring parameters
  - `.spring(_:)` - Named spring configurations (.bouncy, .smooth, .snappy)
  - `.timingCurve(_:_:_:_:duration:)` - Custom cubic Bézier curves
  - Spring physics with configurable response and damping
  - CSS transition and animation generation
  - GPU-accelerated transform and opacity animations

#### Implicit Animations (.animation())

- **`.animation()` Modifier** - Value-based implicit animations
  - Automatically animates property changes when value changes
  - `Animation?` parameter for conditional animations
  - Value-based triggering to prevent unwanted animations
  - Support for animatable properties:
    - Transform properties (scale, rotation, offset)
    - Visual properties (opacity, colors)
    - Layout properties (frame, padding)
    - Shape properties (corner radius, shadow)
  - Multiple animations on same view for different properties
  - Animation inheritance control
  - CSS transition generation
  - GPU acceleration for supported properties

#### Explicit Animations (withAnimation())

- **`withAnimation()` Function** - Explicit animation blocks
  - Global function for animation contexts
  - Animates all state changes in closure
  - Optional animation parameter (defaults to `.default`)
  - Completion handler support for animation sequences
  - Nested animation support for complex choreography
  - Animation context propagation
  - Affects:
    - State changes
    - View transitions (insertion/removal)
    - Modifier changes
  - Multiple overloads:
    - `withAnimation(_:_:)` - Animation with body
    - `withAnimation(_:_:completion:)` - With completion handler
    - `withAnimation(_:)` - Animation with trailing closure
  - Async-friendly with completion callbacks

#### Transition System

- **`AnyTransition` Type** - View insertion/removal animations
  - `.identity` - No animation
  - `.opacity` - Fade in/out
  - `.scale(scale:anchor:)` - Scale from specified size and anchor
  - `.slide` - Slide from bottom edge
  - `.move(edge:)` - Slide from specified edge (.top, .bottom, .leading, .trailing)
  - `.offset(x:y:)` - Slide by specific pixel amounts
  - `.push(from:)` - Slide while staying opaque (navigation-style)
  - `.modifier(active:identity:)` - Custom transitions using ViewModifiers
  - `.combined(with:)` - Combine multiple transitions
  - `.asymmetric(insertion:removal:)` - Different insertion and removal
  - CSS @keyframes generation for each transition
  - Transform-origin support for scale transitions
  - Percentage-based offsets for responsive transitions
  - Multiple transition composition
  - Works with conditional view rendering (if statements)

- **`.transition()` Modifier** - Apply transitions to views
  - Associates transition with view
  - Used with conditional rendering
  - Inherits animation from context (withAnimation or .animation())
  - Example: `if showView { MyView().transition(.opacity) }`

#### Multi-Step Animations (keyframeAnimator())

- **`keyframeAnimator()` Modifier** - Complex, multi-step animations (iOS 17+)
  - Define custom animation value structs
  - Content closure applies values to view
  - Keyframes closure defines animation sequence
  - Multiple independent animation tracks
  - Trigger-based re-execution
  - Keyframe types:
    - `LinearKeyframe` - Constant-rate changes
    - `SpringKeyframe` - Physics-based motion with bounce
    - `CubicKeyframe` - Custom cubic Bézier timing
  - Named spring configurations:
    - `.bouncy` - High energy, playful
    - `.smooth` - Professional, no bounce
    - `.snappy` - Quick, subtle bounce
  - Support for animating:
    - Position (x, y offsets)
    - Rotation
    - Scale
    - Opacity
    - Any numeric property
  - CSS @keyframes with percentage-based timing
  - Complex choreography support
  - Perfect for loading indicators and attention-grabbing animations

- **`KeyframeTrack` Type** - Individual property animation tracks
  - Uses KeyPath for property targeting
  - Contains sequence of keyframes
  - Independent timing per track
  - Multiple tracks run simultaneously

#### Supporting Types

- **`TransitionModifier`** - Internal transition modifier implementation
  - Wraps view with transition
  - CSS animation generation
  - Insertion and removal handling

- **`AnimationModifier`** - Internal animation modifier implementation
  - Value-based animation triggering
  - CSS transition generation
  - Property change detection

#### Web Implementation

- **CSS Transitions** - For simple property animations
  - Generated for `.animation()` modifier
  - Property-specific transitions
  - Timing function mapping (ease, linear, cubic-bezier)
  - Multiple property transitions
  - Example: `transition: transform 0.3s ease-out, opacity 0.3s ease-out;`

- **CSS Animations** - For complex animations
  - Generated for `keyframeAnimator()` and transitions
  - @keyframes rules with percentage keyframes
  - Animation timing functions
  - Animation fill modes
  - Example:
    ```css
    @keyframes slideIn {
        from { transform: translateX(-100%); }
        to { transform: translateX(0); }
    }
    .element { animation: slideIn 0.3s ease-out; }
    ```

- **GPU Acceleration** - Hardware-accelerated animations
  - Automatic `will-change` property
  - `transform: translateZ(0)` for layer promotion
  - Optimized for:
    - `transform` (translate, scale, rotate)
    - `opacity`
  - 60fps performance target
  - Compositor thread animations

- **Transform Optimizations** - Efficient property animations
  - Prefer transform over layout properties
  - Combine transforms: `translateX() scale() rotate()`
  - `transform-origin` for scale anchoring
  - Percentage-based transforms for responsive animations

#### Testing & Quality

- **50+ Integration Tests** (Phase12VerificationTests.swift)
  - Animation curves with modifiers (5 tests)
  - .animation() with state changes (5 tests)
  - withAnimation() blocks (5 tests)
  - Transitions on conditional views (8 tests)
  - keyframeAnimator() animations (3 tests)
  - Animation interruption (2 tests)
  - Transition composition (2 tests)
  - Cross-feature integration with Phase 9-11 (5 tests)
  - Complex UI scenarios (8 tests)
  - Edge cases and error conditions (5 tests)
  - Performance scenarios (2 tests)

- **Unit Tests**
  - AnimationTests.swift - Animation types and curves
  - AnimationModifierTests.swift - .animation() modifier behavior
  - WithAnimationTests.swift - withAnimation() function
  - TransitionTests.swift - Transition system
  - KeyframeAnimatorTests.swift - Keyframe animations

- **Working Examples** (Phase12Examples.swift - 10 examples, ~1,200+ lines)
  - Animated button with spring bounce
  - List with insert/remove transitions
  - Loading spinner with keyframes
  - Animated counter/progress bar
  - Page transition demo
  - Animated shape morphing
  - Complete animated UI flow
  - Interactive card stack
  - Expandable card
  - Animated tab bar

#### Documentation

- **Comprehensive Guide** (Documentation/Phase12.md - ~1,550+ lines)
  - Animation system architecture
  - Animation types guide (linear, ease, spring, custom)
  - .animation() modifier documentation
  - withAnimation() function documentation
  - Transition system guide (all 8 types)
  - keyframeAnimator() documentation
  - Web implementation details
  - Performance considerations
  - Browser compatibility matrix
  - Common patterns and best practices
  - Troubleshooting guide
  - Migration guide from static to animated
  - 10+ complete examples
  - Future enhancements roadmap

- **API Documentation**
  - Full DocC comments for all public APIs
  - Code examples in documentation
  - Cross-references between related APIs
  - Parameter documentation with examples
  - Return value descriptions
  - Usage notes and best practices

### Changed

- **API Coverage** - Increased from ~80% to ~85%
  - Animation system aligned with SwiftUI iOS 17+
  - Modern animation APIs (keyframeAnimator)
  - Comprehensive transition support
  - Spring physics matching Apple's implementation

- **Performance** - GPU-accelerated animations
  - Transform and opacity use hardware acceleration
  - 60fps animation target
  - Efficient CSS transitions and animations
  - Minimal JavaScript overhead

- **Features List** - Updated README.md
  - Added animation system to feature highlights
  - Updated API coverage percentage
  - Added Phase 12 to development phases table
  - New "What's New in v0.6.0" section

### Fixed

- N/A - Initial animation implementation

### Migration Guide

#### Adding Animations to Existing Views

**Before (No Animation):**
```swift
@State private var isExpanded = false

var body: some View {
    Circle()
        .scaleEffect(isExpanded ? 1.5 : 1.0)
        .onTapGesture {
            isExpanded.toggle()
        }
}
```

**After (With Animation):**
```swift
@State private var isExpanded = false

var body: some View {
    Circle()
        .scaleEffect(isExpanded ? 1.5 : 1.0)
        .animation(.spring(), value: isExpanded)  // Add this
        .onTapGesture {
            isExpanded.toggle()
        }
}
```

#### View Transitions

**Before:**
```swift
if showDetails {
    DetailView()
}
```

**After:**
```swift
VStack {
    if showDetails {
        DetailView()
            .transition(.opacity.combined(with: .scale))
    }
}
.animation(.spring(), value: showDetails)
```

#### Using withAnimation

```swift
Button("Toggle") {
    withAnimation(.spring()) {
        showDetails.toggle()
    }
}
```

### Browser Compatibility

All animation features work in modern browsers:

- **Chrome 90+** ✅ Full support
- **Firefox 90+** ✅ Full support
- **Safari 14+** ✅ Full support
- **Edge 90+** ✅ Full support

Features used:
- CSS Transitions ✅
- CSS Animations ✅
- CSS Transforms (2D/3D) ✅
- `will-change` property ✅
- GPU acceleration ✅

### Performance Notes

- Animations use GPU acceleration for `transform` and `opacity`
- Target 60fps on modern hardware
- Automatic `will-change` hints for browsers
- Efficient CSS transitions minimize JavaScript overhead
- Spring animations approximated with cubic-bezier curves
- Layout-affecting properties (width, height) not recommended for animation

### Statistics

- **Files Added**: 7 new files
  - Animation.swift (567 lines)
  - AnimationModifier.swift (289 lines)
  - WithAnimation.swift (356 lines)
  - AnyTransition.swift (720 lines)
  - TransitionModifier.swift (245 lines)
  - KeyframeAnimator.swift (487 lines)
  - Phase12VerificationTests.swift (938 lines)
- **Production Code**: ~2,664 lines
- **Test Coverage**: 50+ integration tests + unit tests
- **Test Code**: ~938 lines (verification) + existing unit tests
- **Examples**: 10 complete examples (~1,200+ lines)
- **Documentation**: ~1,550+ lines
- **API Coverage**: Increased from ~80% to ~85%

---

## [0.5.0] - 2026-02-03 - Phase 11: Modern Layout & Search

### Added

#### Modern Layout APIs

- **`containerRelativeFrame()` Modifier** - Responsive sizing relative to containers
  - Modern alternative to `GeometryReader` with cleaner syntax
  - CSS container queries for efficient responsive design
  - Closure-based API: `.containerRelativeFrame(.horizontal) { width, _ in width * 0.8 }`
  - Grid-based API: `.containerRelativeFrame(.horizontal, count: 3, span: 1, spacing: 16)`
  - Support for horizontal, vertical, and both axes
  - Alignment options for positioning within container
  - CSS custom properties (`--container-width`, `--container-height`) for sizing
  - `calc()` expressions for precise calculations
  - Works with all view types

- **`ViewThatFits` Container** - Adaptive layouts based on available space
  - Automatically selects first child view that fits
  - Axis control: check horizontal, vertical, or both axes
  - Ideal for responsive navigation and adaptive UIs
  - No explicit breakpoints needed
  - CSS-based measurement using `max-content` and container queries
  - Graceful fallback to last option if none fit
  - Perfect for desktop/mobile layout variations
  - Multiple layout options with ordered preference

#### Scroll Enhancement Modifiers

- **`.scrollBounceBehavior()` Modifier** - Control scroll bounce/overscroll behavior
  - `.automatic` - System default behavior
  - `.always` - Always allow bounce
  - `.basedOnSize` - Bounce only when content exceeds container
  - `.never` - Disable bounce entirely
  - Per-axis control (horizontal, vertical, or both)
  - CSS `overscroll-behavior` implementation
  - Prevents unwanted scroll chaining
  - Ideal for nested scrollable areas

- **`.scrollClipDisabled()` Modifier** - Allow scroll content to overflow
  - Disables clipping of scroll content
  - Perfect for shadows, glows, and overlapping effects
  - Boolean parameter to enable/disable
  - CSS `overflow: visible` implementation
  - Works with all scrollable containers
  - Maintains scroll functionality while showing overflow

- **`.scrollTransition()` Modifier** - Animate content based on scroll position
  - IntersectionObserver-based implementation
  - Smooth animations as content enters/leaves viewport
  - Configuration options:
    - `topLeading` - Trigger at top/leading edge
    - `center` - Trigger when centered in viewport
    - `bottomTrailing` - Trigger at bottom/trailing edge
  - Phase-based transitions:
    - `.identity` - Fully visible (0% out of view)
    - `.topLeading`, `.bottomTrailing` - Entering/exiting states
  - Transform effects (scale, rotation, translation)
  - Opacity animations
  - Smooth CSS transitions
  - Configurable threshold for trigger points
  - Ideal for scroll-based reveals and parallax effects

#### Search Functionality

- **`.searchable()` Modifier** - Add search functionality to views
  - Two-way binding with `Binding<String>`
  - Customizable placeholder text
  - Search suggestions support with ViewBuilder
  - Multiple placement options:
    - `.automatic` - Default top placement
    - `.navigationBarDrawer` - Navigation-integrated
    - `.sidebar` - Sidebar-optimized
    - `.toolbar` - Inline toolbar placement
  - HTML `<input type="search">` implementation
  - Native browser features:
    - Built-in clear button (x)
    - Search icon indicator
    - Autocomplete support
  - Keyboard shortcuts (Cmd+F to focus)
  - ARIA attributes for accessibility:
    - `role="search"` container
    - `aria-label` for screen readers
    - Proper label association
  - Real-time filtering and updates
  - Suggestions dropdown with custom content
  - Styled for web with responsive design

#### Supporting Types

- **`Axis.Set`** - Used by containerRelativeFrame and ViewThatFits
  - `.horizontal`, `.vertical`, or both
  - Bitmask-based set operations

- **`ScrollBounceBehavior`** - Scroll bounce configuration
  - `.automatic`, `.always`, `.basedOnSize`, `.never`
  - Per-axis application

- **`ScrollTransitionConfiguration`** - Scroll animation config
  - `topLeading`, `center`, `bottomTrailing`
  - Threshold customization

- **`ScrollTransitionPhase`** - Scroll position state
  - `.identity`, `.topLeading`, `.bottomTrailing`
  - Used by transition effects

- **`SearchFieldPlacement`** - Search field positioning
  - `.automatic`, `.navigationBarDrawer`, `.sidebar`, `.toolbar`

#### Testing & Quality

- 102+ comprehensive tests covering all Phase 11 features
  - containerRelativeFrame tests (20+ tests)
  - ViewThatFits tests (25+ tests)
  - Scroll behavior tests (18+ tests)
  - Scroll transition tests (20+ tests)
  - Searchable tests (28+ tests)
  - Integration tests for real-world scenarios

- Working examples demonstrating usage
  - Responsive dashboard layouts
  - Adaptive navigation patterns
  - Scroll-based animations
  - Search with filtering and suggestions

### Changed

- **API Coverage** - Increased from ~70% to ~80%
  - Modern layout APIs aligned with SwiftUI iOS 17+
  - Enhanced scroll capabilities
  - Search functionality matching native patterns
  - Better responsive design support

- **Layout System** - Enhanced responsive capabilities
  - Easier responsive layouts without GeometryReader
  - More declarative approach to adaptive UIs
  - Better container-relative sizing patterns

### Migration Guide

#### From GeometryReader to containerRelativeFrame

The new `containerRelativeFrame()` modifier provides a cleaner alternative to `GeometryReader` for responsive sizing:

**Before (GeometryReader):**
```swift
GeometryReader { geometry in
    Image("hero")
        .frame(width: geometry.size.width * 0.8)
}
```

**After (containerRelativeFrame):**
```swift
Image("hero")
    .containerRelativeFrame(.horizontal) { width, _ in
        width * 0.8
    }
```

**Benefits:**
- No wrapper container needed
- Cleaner, more readable syntax
- Better performance with CSS container queries
- Alignment support built-in
- Works with grid-based layouts

**When to Use Each:**
- Use `containerRelativeFrame()` for simple proportional sizing
- Use `GeometryReader` when you need full geometry information or complex calculations
- Both can coexist in the same application

### Statistics

- **Files Added:** 5 new files
  - ContainerRelativeFrameModifier.swift (349 lines)
  - ViewThatFits.swift (304 lines)
  - ScrollBehaviorModifiers.swift (262 lines)
  - ScrollTransitionModifier.swift (342 lines)
  - SearchableModifier.swift (539 lines)

- **Lines of Code:** ~1,796 lines of production code
- **Test Coverage:** 102+ tests across 5 test files
- **Test Code:** ~2,172 lines of test code
- **Test/Code Ratio:** 1.21 (excellent coverage)

### Documentation

- Added [Documentation/Phase11.md](Documentation/Phase11.md) - Comprehensive Phase 11 guide
  - Modern layout APIs overview and usage
  - Migration guide from GeometryReader
  - ViewThatFits patterns and examples
  - Scroll enhancement documentation
  - Search functionality guide
  - Web implementation details
  - Browser compatibility matrix
  - Performance optimization tips
  - Complete real-world examples

- Updated [README.md](README.md)
  - "What's New in v0.5.0" section
  - Enhanced feature list with modern layout and search
  - Updated development phases table
  - API coverage updated to ~80%

- Updated [Documentation/API-Overview.md](Documentation/API-Overview.md)
  - Added containerRelativeFrame to modifiers section
  - Added ViewThatFits to layout containers
  - Added scroll modifiers section
  - Added searchable modifier documentation
  - Cross-references to Phase11.md

- Enhanced inline documentation
  - Full DocC comments for all new APIs
  - Comprehensive code examples in documentation
  - Web implementation notes
  - Browser compatibility information
  - Performance considerations

### Browser Compatibility

All Phase 11 features support modern browsers:

- **CSS Container Queries:** Chrome 105+, Firefox 110+, Safari 16+, Edge 105+
- **IntersectionObserver:** Chrome 51+, Firefox 55+, Safari 12.1+, Edge 15+
- **CSS overscroll-behavior:** Chrome 63+, Firefox 59+, Safari 16+, Edge 79+
- **HTML Search Input:** All modern browsers
- **CSS calc():** All modern browsers
- **CSS Custom Properties:** All modern browsers

**Fallbacks:**
- Container queries gracefully degrade to percentage-based sizing
- IntersectionObserver has polyfill support for older browsers
- Search inputs fall back to standard text inputs in older browsers

### Performance Notes

- **Container Queries:** Efficiently handled by browser layout engine
- **IntersectionObserver:** Passive observation with minimal performance impact
- **Scroll Animations:** CSS transitions for GPU acceleration
- **Search Filtering:** Debounced for optimal performance with large lists
- **ViewThatFits:** Measurement cached to avoid redundant calculations

### Real-World Use Cases

**Responsive Dashboard:**
```swift
VStack {
    ViewThatFits {
        // Wide layout - 3 columns
        HStack {
            DashboardCard("Sales")
            DashboardCard("Users")
            DashboardCard("Revenue")
        }

        // Medium layout - 2 columns
        VStack {
            HStack {
                DashboardCard("Sales")
                DashboardCard("Users")
            }
            DashboardCard("Revenue")
        }

        // Narrow layout - 1 column
        VStack {
            DashboardCard("Sales")
            DashboardCard("Users")
            DashboardCard("Revenue")
        }
    }
}
```

**Search with Filtering:**
```swift
struct ItemList: View {
    @State private var searchText = ""

    var filteredItems: [Item] {
        if searchText.isEmpty { return items }
        return items.filter { $0.name.contains(searchText) }
    }

    var body: some View {
        List(filteredItems) { item in
            ItemRow(item: item)
                .scrollTransition { content, phase in
                    content
                        .opacity(phase.isIdentity ? 1 : 0.5)
                        .scaleEffect(phase.isIdentity ? 1 : 0.95)
                }
        }
        .searchable(text: $searchText, prompt: "Search items") {
            ForEach(suggestions) { suggestion in
                Text(suggestion.name)
                    .searchCompletion(suggestion.name)
            }
        }
    }
}
```

**Responsive Grid:**
```swift
LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))]) {
    ForEach(items) { item in
        ItemCard(item: item)
            .containerRelativeFrame(.horizontal, count: 3, span: 1, spacing: 16)
    }
}
```

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
