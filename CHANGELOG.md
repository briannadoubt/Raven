# Changelog

All notable changes to Raven will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
