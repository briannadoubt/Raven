# Presentation System DOM Rendering

This directory contains the complete DOM rendering implementation for Raven's presentation system. It converts SwiftUI-style presentations (sheets, alerts, popovers) into HTML5 `<dialog>` elements with native browser capabilities and smooth animations.

## Architecture Overview

The rendering system consists of six core components:

### 1. **PresentationAnimations.swift**
Defines all CSS animations and styles for presentation transitions.

- **CSS Keyframes**: Slide, fade, scale animations
- **Dialog Styles**: Base styling for all dialog types
- **Backdrop Effects**: Modal overlay with fade transitions
- **Dark Mode Support**: Automatic theme adaptation
- **Reduced Motion**: Accessibility support for motion-sensitive users
- **Injection API**: Runtime stylesheet injection into document head

**Key Features:**
- Hardware-accelerated transforms
- Spring-based easing for natural motion
- Configurable animation durations
- Mobile-optimized sheet animations

### 2. **DialogRenderer.swift**
Core renderer that converts `PresentationEntry` objects to VNode trees.

**Responsibilities:**
- Creates base dialog elements with proper HTML5 attributes
- Manages z-index layering for multiple presentations
- Handles backdrop click dismissal
- Routes to specialized renderers based on presentation type
- Provides common utilities for all presentation types

**Key Methods:**
- `render(entry:coordinator:)` - Main entry point
- `createDialog(...)` - Base dialog VNode factory
- `createBackdropClickHandler(...)` - Dismissal logic
- `showDialog(_:)` / `closeDialog(_:)` - HTML5 dialog API integration

### 3. **SheetRenderer.swift**
Specialized renderer for bottom sheet presentations.

**Features:**
- Slide-up animation from bottom edge
- Drag indicator for visual affordance
- Multiple detent support (height presets)
- Swipe-to-dismiss integration
- Scrollable content container
- Interactive dismiss control

**Structure:**
```html
<dialog class="raven-dialog raven-sheet">
  <div class="raven-sheet-drag-indicator"></div>
  <div class="raven-sheet-container">
    <!-- Content -->
  </div>
</dialog>
```

**Key Methods:**
- `render(entry:coordinator:)` - Creates sheet VNode
- `attachSwipeHandler(...)` - Enables gesture dismissal
- `updateDetent(...)` - Dynamic height adjustment
- `animatePresentation/Dismissal(...)` - Animation control

### 4. **AlertRenderer.swift**
iOS-style alert dialog renderer with button layout management.

**Features:**
- Centered modal appearance
- Scale and fade entrance animation
- Title and message display
- Smart button layout (horizontal for ≤2, vertical for 3+)
- Button role styling (cancel, destructive, default)
- Keyboard focus management
- ARIA attributes for accessibility

**Button Layout Logic:**
- **1 button**: Full width
- **2 buttons**: Horizontal split with separator
- **3+ buttons**: Vertical stack

**Key Methods:**
- `render(entry:coordinator:)` - Creates alert VNode
- `renderAlert(...)` - Direct alert creation with config
- `createAlertContent(...)` - Title/message layout
- `createAlertActions(...)` - Button container with smart layout

### 5. **PopoverRenderer.swift**
Context menu and popover renderer with intelligent positioning.

**Features:**
- Dynamic anchor-based positioning
- Arrow indicator pointing to source
- Edge preference with automatic flipping
- Viewport boundary detection
- Overflow prevention with position adjustment
- Mobile and desktop optimized

**Positioning Algorithm:**
1. Get anchor element bounds
2. Calculate ideal position for preferred edge
3. Check if position fits in viewport
4. Flip to opposite edge if needed
5. Constrain to viewport boundaries
6. Position arrow to point at anchor center

**Key Methods:**
- `render(entry:anchor:edge:coordinator:)` - Creates popover VNode
- `positionPopover(...)` - Post-render positioning
- `calculatePosition(...)` - Position computation
- `constrainToViewport(...)` - Boundary checks

### 6. **SwipeDismissHandler.swift**
Touch gesture handler for sheet dismissal.

**Features:**
- Touch and mouse event tracking
- Velocity calculation for fling gestures
- Rubber band physics for upward over-scroll
- Threshold-based commit/cancel
- Spring animation on release
- Interactive dismiss disable support

**Gesture Thresholds:**
- Distance: 30% of sheet height
- Velocity: 0.5 pixels/millisecond
- Rubber band: Exponential decay for upward drag

**Key Methods:**
- `attach()` - Add event listeners
- `detach()` - Clean up listeners
- `handleTouchStart/Move/End(...)` - Gesture tracking

## Integration with Existing System

### Modified Files

#### SheetModifier.swift
Added `toVNode()` methods to both `SheetModifier` and `ItemSheetModifier`:
```swift
@MainActor public func toVNode() -> VNode? {
    guard isPresented, let presentationId = presentationId else {
        return nil
    }

    let entry = PresentationEntry(...)
    return SheetRenderer.render(entry: entry, coordinator: coordinator)
}
```

#### AlertModifier.swift
Added `toVNode()` methods to alert presentation modifiers:
- `BasicAlertModifier.toVNode()`
- `AlertPresentationWithMessageModifier.toVNode()`
- `DataAlertPresentationModifier.toVNode()`

#### PopoverModifier.swift
Added `toVNode()` methods to both `PopoverModifier` and `PopoverItemModifier`:
```swift
@MainActor func toVNode() -> VNode? {
    guard isPresented, let presentationId = presentationId else {
        return nil
    }

    return PopoverRenderer.render(
        entry: entry,
        anchor: attachmentAnchor,
        edge: arrowEdge,
        coordinator: coordinator
    )
}
```

## Usage Examples

### Initializing the Animation System

```swift
// During app startup, inject the CSS
PresentationAnimations.injectStylesheet()
```

### Rendering a Sheet

```swift
let coordinator = PresentationCoordinator()

// Present a sheet
let id = coordinator.present(
    type: .sheet,
    content: AnyView(MySheetContent()),
    onDismiss: { print("Dismissed") }
)

// Render to VNode
if let entry = coordinator.presentations.first(where: { $0.id == id }) {
    let vnode = SheetRenderer.render(entry: entry, coordinator: coordinator)
    // Apply vnode to DOM...
}

// Attach swipe handler after DOM creation
let nodeId = NodeID() // Get from DOM
if let handler = SheetRenderer.attachSwipeHandler(
    nodeId: nodeId,
    presentationId: id,
    coordinator: coordinator
) {
    // Handler is now active
}
```

### Rendering an Alert

```swift
let alert = AlertRenderer.renderAlert(
    title: "Delete Item",
    message: "Are you sure you want to delete this item? This action cannot be undone.",
    buttons: [
        .destructive("Delete") {
            deleteItem()
        },
        .cancel()
    ],
    zIndex: 1010,
    presentationId: presentationId,
    coordinator: coordinator
)
```

### Rendering a Popover

```swift
let popover = PopoverRenderer.render(
    entry: entry,
    anchor: .source, // Anchor to source view
    edge: .top,      // Prefer appearing above
    coordinator: coordinator
)

// After DOM creation, position the popover
PopoverRenderer.positionPopover(
    nodeId: dialogNodeId,
    anchor: .source,
    preferredEdge: .top
)
```

## HTML5 Dialog API Integration

All presentations use the native `<dialog>` element:

```javascript
// Show modal dialog with backdrop
dialog.showModal()

// Close dialog
dialog.close()

// Handle backdrop clicks
dialog.addEventListener('click', (event) => {
    if (event.target === dialog) {
        // Clicked on backdrop
    }
})
```

### Benefits of `<dialog>`:
- ✅ Native focus trap
- ✅ Automatic backdrop rendering
- ✅ Keyboard accessibility (ESC to close)
- ✅ ARIA semantics built-in
- ✅ Browser-optimized rendering
- ✅ No external dependencies

## CSS Class Hierarchy

```
.raven-dialog                    # Base class for all dialogs
├── .raven-sheet                 # Bottom sheet
├── .raven-alert                 # Alert dialog
│   ├── .raven-alert-content
│   ├── .raven-alert-title
│   ├── .raven-alert-message
│   └── .raven-alert-actions
│       └── .raven-alert-button
│           ├── .raven-alert-button-cancel
│           └── .raven-alert-button-destructive
├── .raven-popover               # Popover/context menu
│   ├── .raven-popover-arrow
│   └── .raven-popover-content
├── .raven-fullscreen            # Full screen cover
└── .raven-confirmation          # Confirmation dialog
```

## Animation Specifications

### Sheet Animations
- **Entry**: Slide up from bottom, 300ms, spring easing
- **Exit**: Slide down, 200ms, ease-out
- **Backdrop**: Fade in/out, 250ms, smooth easing

### Alert Animations
- **Entry**: Scale from 0.9 to 1.0 + fade, 300ms
- **Exit**: Scale to 0.95 + fade, 200ms

### Popover Animations
- **Entry**: Scale from 0.95 + fade, 200ms
- **Exit**: Scale to 0.95 + fade, 200ms

### Full Screen Cover
- **Entry/Exit**: Simple fade, 300ms/200ms

## Accessibility Features

### ARIA Attributes
- `role="alertdialog"` for alerts
- `role="dialog"` for other presentations
- `aria-modal="true"` for modal dialogs
- `aria-labelledby` linking to title elements
- `aria-hidden="true"` for decorative elements

### Keyboard Navigation
- Focus trap within dialog
- ESC key dismissal (via native dialog)
- Tab order managed automatically
- Focus returns to trigger element on close

### Screen Reader Support
- Proper semantic structure
- Hidden decorative elements
- Announced role and state
- Content hierarchy preservation

## Performance Optimizations

### Hardware Acceleration
All animations use transform and opacity properties:
```css
transform: translateY(100%);  /* GPU-accelerated */
opacity: 0;                   /* Composited */
```

### Will-Change Hints
Dialog elements use `will-change` for better composition:
```css
will-change: transform, opacity;
```

### Event Delegation
- Single global event handler for all presentations
- Efficient event routing via handler IDs
- Minimal memory overhead

### CSS Containment
```css
dialog {
    contain: layout style paint;
}
```

## Browser Compatibility

### Modern Browser Support
- Chrome 37+
- Safari 15.4+
- Firefox 98+
- Edge 79+

### Polyfill Strategy
For older browsers, a dialog polyfill can be used:
```javascript
if (!window.HTMLDialogElement) {
    // Load dialog-polyfill
}
```

## Future Enhancements

### Planned Features
1. **Custom Transitions**: User-defined animation curves
2. **Gesture Customization**: Configurable swipe thresholds
3. **Multiple Detents**: Interactive height adjustment for sheets
4. **Smart Positioning**: Machine learning for optimal popover placement
5. **Blur Effects**: Native backdrop filters (iOS-style)
6. **Spring Physics**: Advanced spring animations
7. **Haptic Feedback**: WebVibration API integration

### API Extensions
- `PresentationLink` for declarative navigation
- `presentationBackground()` modifier
- `presentationCornerRadius()` modifier
- `presentationDragIndicator()` customization

## Testing Considerations

### Unit Tests
- VNode structure validation
- Animation class application
- Event handler registration
- Position calculation accuracy

### Integration Tests
- Coordinator integration
- Dismiss callback execution
- Focus management
- Z-index layering

### Visual Regression Tests
- Animation smoothness
- Cross-browser rendering
- Dark mode appearance
- Mobile responsiveness

## Dependencies

### Internal
- `VNode` - Virtual DOM representation
- `DOMBridge` - JavaScript interop
- `PresentationCoordinator` - State management
- `PresentationEntry` - Data model

### External
- `JavaScriptKit` - Swift/JS bridging
- Native `<dialog>` element
- CSS animations

## Conclusion

This implementation provides a complete, production-ready presentation system that:
- ✅ Uses modern web standards (HTML5 dialog)
- ✅ Provides smooth, performant animations
- ✅ Supports all major presentation types
- ✅ Includes full accessibility support
- ✅ Integrates seamlessly with SwiftUI-style API
- ✅ Requires no external JavaScript dependencies
- ✅ Follows Swift 6.2 strict concurrency

The system is ready for integration with the Raven rendering pipeline and can be extended with additional presentation types as needed.
