# Accessibility - Focus Management System

This directory contains the implementation of Raven's Focus Management System (Track E.1), providing comprehensive keyboard focus control and keyboard shortcut handling for web applications.

## Overview

The Focus Management System enables SwiftUI-style focus control in web applications by bridging Swift's `@FocusState` property wrapper with native DOM focus APIs. It provides programmatic focus control, keyboard navigation, and hierarchical focus scopes.

## Architecture

### Core Components

#### 1. FocusState.swift (~250 lines)
The `@FocusState` property wrapper for declaring focus state:

```swift
@FocusState private var focusedField: Field?
@FocusState private var isTextFieldFocused: Bool
```

**Key Features:**
- Property wrapper with boolean or optional Hashable values
- Two-way binding between Swift state and DOM focus
- Automatic view updates on focus changes
- Integration with FocusManager for coordination

**Implementation Details:**
- `FocusState<Value>`: Main property wrapper struct
- `FocusStateStorage<Value>`: Internal storage class with update callbacks
- `FocusBinding<Value>`: Specialized binding type for focus state
- Support for both `Bool` and `Optional<Hashable>` types

#### 2. FocusManager.swift (~200 lines)
Central coordinator for focus management across the application:

```swift
FocusManager.shared.setFocus(to: elementID)
FocusManager.shared.focusNext()
FocusManager.shared.focusPrevious()
```

**Key Features:**
- Singleton pattern for global focus coordination
- Registry of focusable elements with unique IDs
- Tab order management for keyboard navigation
- Bidirectional synchronization (Swift ↔ DOM)
- Event delegation for DOM focus/blur events
- Focus scope support

**Implementation Details:**
- `FocusableElement`: Struct describing a focusable element
- `registerFocusable()`: Register elements with the manager
- `setFocus()`: Programmatically set focus
- `handleDOMFocusIn()/handleDOMFocusOut()`: DOM event handlers
- Feedback loop prevention with `isUpdatingFocus` flag

#### 3. FocusScope.swift (~150 lines)
Hierarchical focus management with scope boundaries:

```swift
ModalView()
    .focusScope(trapFocus: true)
```

**Key Features:**
- Focus scope boundaries for contained UI
- Focus trapping for modals and sheets
- Hierarchical parent-child relationships
- Priority-based scope ordering
- Automatic cleanup on view disappear

**Implementation Details:**
- `FocusScope`: Struct representing a scope boundary
- `FocusScopeModifier`: ViewModifier for applying scopes
- `FocusScopeContext`: Runtime context for scope management
- Environment value for current scope ID
- Element tracking within scopes

#### 4. KeyboardShortcuts.swift (~200 lines)
Keyboard shortcut handling and key press events:

```swift
.onKeyPress(.escape) { _ in
    return .handled
}

.keyboardShortcut(.s, modifiers: .command) {
    save()
}
```

**Key Features:**
- Keyboard shortcut registration
- Key equivalents for common keys
- Event modifier support (Command, Shift, Option, Control)
- Key press result (handled/ignored) for event propagation
- Global keyboard event handling

**Implementation Details:**
- `KeyboardShortcut`: Shortcut definition with key + modifiers
- `KeyEquivalent`: Represents physical keys
- `EventModifiers`: OptionSet for modifier keys
- `KeyPress`: Event information struct
- `KeyboardShortcutManager`: Global shortcut coordinator
- DOM keydown event integration

#### 5. FocusModifiers.swift (~180 lines)
View modifiers for applying focus behavior:

```swift
TextField("Name", text: $name)
    .focused($focusedField, equals: .name)
    .focusable(true)
    .tabIndex(0)
```

**Key Features:**
- `focused(_:equals:)` - Bind focus to Hashable value
- `focused(_:)` - Bind focus to boolean
- `focusable(_:)` - Make views keyboard-accessible
- `tabIndex(_:)` - Control tab order
- Lifecycle management (onAppear/onDisappear)

**Implementation Details:**
- `FocusedModifier<Value>`: For Hashable focus values
- `FocusedBoolModifier`: For boolean focus values
- `FocusableModifier`: For making views focusable
- Automatic registration/unregistration with FocusManager
- Environment value for isFocused state

## Usage Examples

### Basic Boolean Focus

```swift
struct LoginView: View {
    @FocusState private var isPasswordFocused: Bool
    @State private var password = ""

    var body: some View {
        SecureField("Password", text: $password)
            .focused($isPasswordFocused)

        Button("Focus Password") {
            isPasswordFocused = true
        }
    }
}
```

### Multi-Field Focus with Enum

```swift
struct FormView: View {
    enum Field: Hashable {
        case firstName, lastName, email
    }

    @FocusState private var focusedField: Field?
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var email = ""

    var body: some View {
        VStack {
            TextField("First Name", text: $firstName)
                .focused($focusedField, equals: .firstName)

            TextField("Last Name", text: $lastName)
                .focused($focusedField, equals: .lastName)

            TextField("Email", text: $email)
                .focused($focusedField, equals: .email)

            Button("Next Field") {
                switch focusedField {
                case .firstName: focusedField = .lastName
                case .lastName: focusedField = .email
                case .email: focusedField = nil
                case nil: focusedField = .firstName
                }
            }
        }
    }
}
```

### Focus Scopes for Modals

```swift
struct ModalView: View {
    @FocusState private var focusedField: Field?

    var body: some View {
        VStack {
            TextField("Username", text: $username)
                .focused($focusedField, equals: .username)

            SecureField("Password", text: $password)
                .focused($focusedField, equals: .password)

            Button("Login") { }
        }
        .focusScope(trapFocus: true)  // Keep focus within modal
        .onAppear {
            focusedField = .username  // Auto-focus first field
        }
    }
}
```

### Keyboard Shortcuts

```swift
struct EditorView: View {
    @State private var content = ""

    var body: some View {
        TextEditor(text: $content)
            .keyboardShortcut(.s, modifiers: .command) {
                save()
            }
            .onKeyPress(.escape) { _ in
                clearSelection()
                return .handled
            }
    }

    func save() {
        // Save logic
    }

    func clearSelection() {
        // Clear selection logic
    }
}
```

## Integration with Raven

### JavaScript Bridge

The Focus Management System uses JavaScriptKit to interact with DOM focus APIs:

- `element.focus()` - Set DOM focus
- `element.blur()` - Remove DOM focus
- `document.activeElement` - Get currently focused element
- `focusin`/`focusout` events - Track focus changes

### Virtual DOM Integration

Focus state is tracked using:
- Node IDs from VNode system
- DOMBridge for element registration
- Event handler registration for focus events

### Rendering Pipeline

1. Views with `focused()` modifier register with FocusManager
2. FocusManager tracks element IDs and their DOM nodes
3. Focus changes update both DOM and Swift state
4. View re-renders triggered by state changes

## Thread Safety

All focus operations are `@MainActor` isolated:
- FocusManager is MainActor-bound
- All callbacks are `@Sendable @MainActor`
- JavaScriptKit operations run on main thread
- Storage classes use `@unchecked Sendable` with MainActor protection

## Accessibility Considerations

The Focus Management System enhances accessibility by:

1. **Keyboard Navigation**: Full Tab/Shift-Tab support
2. **Programmatic Focus**: Screen reader announcements
3. **Focus Trapping**: Keeps users in modal contexts
4. **Custom Tab Order**: Logical navigation flow
5. **Focus Indicators**: Visual feedback for keyboard users

## Testing Strategy

Recommended testing approaches:

1. **Unit Tests**: Test focus state changes
2. **Integration Tests**: Test focus manager coordination
3. **E2E Tests**: Test keyboard navigation flows
4. **Accessibility Tests**: Verify screen reader behavior

## Performance

The system is optimized for performance:

- O(1) element lookups using UUID-based registries
- Efficient tab order rebuild on changes
- Event delegation for minimal DOM listeners
- Feedback loop prevention for state sync

## Future Enhancements

Potential improvements for future releases:

1. **Focus Groups**: Logical grouping of related elements
2. **Arrow Navigation**: Up/down/left/right focus movement
3. **Focus History**: Navigate back to previous focus
4. **Focus Animations**: Smooth focus transitions
5. **Custom Focus Indicators**: Themeable focus styles

## API Reference

### Property Wrappers

- `@FocusState<Value>` - Declare focus state in views

### Modifiers

- `.focused(_:equals:)` - Bind focus with value
- `.focused(_:)` - Bind focus with boolean
- `.focusable(_:)` - Make view focusable
- `.tabIndex(_:)` - Set tab order
- `.focusScope(trapFocus:priority:)` - Create focus scope
- `.onKeyPress(_:action:)` - Handle key presses
- `.keyboardShortcut(_:modifiers:action:)` - Add shortcuts

### Types

- `FocusBinding<Value>` - Binding for focus state
- `KeyboardShortcut` - Keyboard shortcut definition
- `KeyEquivalent` - Physical key representation
- `EventModifiers` - Modifier keys (Command, Shift, etc.)
- `KeyPress` - Key press event information
- `KeyPressResult` - Handler result (handled/ignored)

## Related Documentation

- Environment system for focus scope propagation
- State management for @FocusState storage
- View modifiers for applying focus behavior
- DOMBridge for JavaScript interop

## Implementation Status

✅ **Complete** - All core functionality implemented:
- @FocusState property wrapper with Boolean and Hashable support
- FocusManager with full DOM synchronization
- FocusScope with hierarchical management
- KeyboardShortcut system with modifiers
- View modifiers for focus control
- Tab order management
- Focus trapping in scopes

Ready for integration testing and user feedback.
