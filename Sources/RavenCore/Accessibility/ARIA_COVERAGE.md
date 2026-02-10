# ARIA Attributes Coverage

This document describes the comprehensive ARIA (Accessible Rich Internet Applications) attributes implementation in Raven, ensuring WCAG 2.1 AA compliance for all UI components.

## Overview

Raven implements complete ARIA attributes coverage across all components to ensure accessibility for users of assistive technologies like screen readers. The implementation follows WCAG 2.1 Level AA guidelines and modern web accessibility best practices.

## Core Accessibility Modifiers

### AccessibilityModifiers.swift

The `AccessibilityModifiers.swift` file provides a comprehensive set of view modifiers for adding ARIA attributes to any view:

#### Label and Description

- **`.accessibilityLabel(_:)`** - Sets `aria-label` for brief descriptions
- **`.accessibilityHint(_:)`** - Sets `aria-description` for additional context
- **`.accessibilityValue(_:)`** - Sets `aria-valuenow` for current state values
- **`.accessibilityLabelledBy(_:)`** - Sets `aria-labelledby` to reference label elements
- **`.accessibilityDescribedBy(_:)`** - Sets `aria-describedby` to reference description elements

#### Roles

- **`.accessibilityRole(_:)`** - Sets the semantic `role` attribute
  - Support for 40+ ARIA roles including landmarks, widgets, and structural elements
  - Covers button, link, checkbox, textbox, list, table, navigation, main, dialog, etc.

#### States and Properties

- **`.accessibilityExpanded(_:)`** - Sets `aria-expanded` for disclosure controls
- **`.accessibilityPressed(_:)`** - Sets `aria-pressed` for toggle buttons
- **`.accessibilityHidden(_:)`** - Sets `aria-hidden` to hide decorative content
- **`.accessibilityControls(_:)`** - Sets `aria-controls` to link controls to content
- **`.accessibilityLiveRegion(_:)`** - Sets `aria-live` for dynamic content updates

#### Traits

- **`.accessibilityTraits(_:)`** - Combines multiple characteristics (button, header, selected, etc.)

## Component-Specific ARIA Implementation

### TextField & TextEditor

**Location:** `Sources/Raven/Views/Primitives/TextField.swift`

**ARIA Attributes:**
- `role="textbox"` - Identifies as text input
- `aria-label` - Uses placeholder as label
- `aria-multiline="true"` - For TextEditor
- `aria-invalid` - Can be set via modifiers for validation errors
- `aria-describedby` - Can reference help text
- `aria-required` - Can be set for required fields

**Example:**
```swift
TextField("Email", text: $email)
    .accessibilityLabel("Email address")
    .accessibilityHint("Enter your email for login")
    .accessibilityDescribedBy("email-help-text")
```

### Button

**Location:** `Sources/Raven/Views/Primitives/Button.swift`

**ARIA Attributes:**
- Native `<button>` element (implicit `role="button"`)
- `aria-pressed` - For toggle buttons (via modifier)
- `aria-expanded` - For disclosure buttons (via modifier)
- `aria-controls` - Links to controlled content (via modifier)
- `aria-label` - For buttons without visible text (via modifier)

**Example:**
```swift
Button("Menu") { isMenuOpen.toggle() }
    .accessibilityExpanded(isMenuOpen)
    .accessibilityControls("main-menu")
```

### Toggle

**Location:** `Sources/Raven/Views/Primitives/Toggle.swift`

**ARIA Attributes:**
- `role="switch"` - Identifies as toggle switch
- `aria-checked` - Indicates current state (true/false)
- Updates dynamically when state changes

**Example:**
```swift
Toggle("Dark Mode", isOn: $isDarkMode)
    .accessibilityLabel("Enable dark mode")
    .accessibilityHint("Switches the app to dark theme")
```

### List

**Location:** `Sources/Raven/Views/Layout/List.swift`

**ARIA Attributes:**
- `role="list"` - Container role
- `aria-label` - Descriptive name (via modifier)
- List items should have:
  - `role="listitem"`
  - `aria-posinset` - Position in set (1-based)
  - `aria-setsize` - Total number of items

**Example:**
```swift
List {
    ForEach(items) { item in
        ItemView(item: item)
    }
}
.accessibilityLabel("Shopping list")
.accessibilityRole(.list)
```

### NavigationView

**Location:** `Sources/Raven/Views/Navigation/NavigationView.swift`

**ARIA Attributes:**
- Outer container: `role="navigation"`, `aria-label="Main navigation"`
- Content area: `role="main"` (main landmark)
- Back button: `aria-label="Back"`

**Example:**
```swift
NavigationView {
    ContentView()
        .accessibilityRole(.main)
}
```

### TabView

**Location:** `Sources/Raven/Views/Navigation/TabView.swift`

**ARIA Attributes:**
- Tab bar: `role="tablist"`, `aria-label="Tab navigation"`
- Each tab:
  - `role="tab"`
  - `aria-selected` (true/false)
  - `aria-controls` - References tab panel
  - `tabindex` - Only selected tab in tab order
- Tab panel:
  - `role="tabpanel"`
  - `aria-labelledby` - References tab
  - `tabindex="0"` - Focusable

**Example:**
```swift
TabView {
    HomeView()
        .tabItem { Label("Home", systemImage: "house") }

    ProfileView()
        .tabItem { Label("Profile", systemImage: "person") }
}
```

### Dialog/Modal Presentations

**Location:** `Sources/Raven/Presentation/Rendering/DialogRenderer.swift`

**ARIA Attributes:**
- `role="dialog"` - Identifies as dialog
- `aria-modal="true"` - Blocks interaction with background
- `aria-labelledby` - References title element
- `aria-describedby` - References description
- Alert dialogs use `role="alertdialog"`

**Example:**
```swift
.sheet(isPresented: $showSheet) {
    VStack {
        Text("Dialog Title")
            .accessibilityIdentifier("dialog-title")
        Text("Dialog content")
    }
    .accessibilityRole(.dialog)
    .accessibilityLabelledBy("dialog-title")
}
```

## WCAG 2.1 AA Compliance

### Landmark Roles (Success Criterion 1.3.1)

Raven implements all landmark roles for proper page structure:

- **`navigation`** - Navigation sections (NavigationView)
- **`main`** - Primary content area
- **`complementary`** - Supporting content (sidebars)
- **`banner`** - Site header
- **`contentinfo`** - Site footer
- **`region`** - Generic landmark with label
- **`form`** - Form landmark
- **`search`** - Search landmark

### Live Regions (Success Criterion 4.1.3)

Dynamic content updates are announced via `aria-live`:

```swift
Text(statusMessage)
    .accessibilityLiveRegion(.polite)  // Announces when user is idle

Text(errorMessage)
    .accessibilityLiveRegion(.assertive)  // Interrupts immediately
```

### Form Controls (Success Criterion 4.1.2)

All form controls have:
- Accessible names (via `aria-label` or `aria-labelledby`)
- Roles (textbox, checkbox, radio, combobox, etc.)
- States (checked, invalid, required, readonly)
- Values (for current state)

### Interactive Elements (Success Criterion 4.1.2)

All interactive elements have:
- Proper roles (button, link, tab, menuitem, etc.)
- States (pressed, expanded, selected)
- Relationships (controls, describedby, labelledby)

## Complete ARIA Role Support

### Interactive Roles
- button
- link
- checkbox
- radio
- switch
- slider
- spinbutton
- menuitem
- menuitemcheckbox
- menuitemradio
- tab

### Input Roles
- textbox
- searchbox
- combobox

### Structural Roles
- heading
- list / listitem
- table / row / cell / columnheader / rowheader
- grid / gridcell

### Landmark Roles
- navigation
- main
- complementary
- banner
- contentinfo
- region
- form
- search

### Widget Roles
- dialog
- alertdialog
- alert
- status
- progressbar
- tablist / tab / tabpanel
- menu / menubar
- toolbar
- tooltip
- tree / treeitem

### Document Roles
- article
- document
- note
- separator
- group
- figure
- img

## Usage Guidelines

### When to Use aria-label vs aria-labelledby

**Use `aria-label`:**
- When the label text doesn't exist visually
- For icon-only buttons
- For generic containers that need names

**Use `aria-labelledby`:**
- When the label exists as a visible element
- To create compound labels from multiple elements
- For form fields with separate label elements

### When to Use aria-describedby

Use `aria-describedby` to reference:
- Help text for form fields
- Error messages
- Additional instructions
- Related content that provides context

### When to Hide with aria-hidden

Use `aria-hidden="true"` for:
- Decorative images
- Duplicate content
- Visual spacers or dividers
- Icon duplicates of text

**Never use `aria-hidden` on:**
- Interactive elements
- Focusable elements
- Content that provides information

### Live Region Priority

**Use `aria-live="off"`** (default):
- Static content
- Content that doesn't change

**Use `aria-live="polite"`** (recommended):
- Status messages
- Progress updates
- Search results
- Notification messages

**Use `aria-live="assertive"`** (sparingly):
- Critical errors
- Security alerts
- Time-sensitive warnings

## Testing Recommendations

### Automated Testing

Use automated tools to verify:
- All interactive elements have accessible names
- All form controls have labels
- Heading hierarchy is correct
- Landmarks are properly used
- ARIA attributes are valid

**Recommended Tools:**
- axe DevTools
- WAVE
- Lighthouse Accessibility Audit

### Manual Testing

Test with:
- Screen readers (NVDA, JAWS, VoiceOver)
- Keyboard-only navigation
- Browser accessibility inspector

**Key Tests:**
- Tab through all interactive elements
- Use screen reader to navigate landmarks
- Verify announcements for dynamic content
- Test form validation messages
- Verify dialog focus trapping

### Screen Reader Testing

Test with major screen readers:
- **VoiceOver** (macOS/iOS) - Safari
- **NVDA** (Windows) - Firefox
- **JAWS** (Windows) - Chrome/Edge

**Verify:**
- All elements have meaningful names
- States are announced (checked, expanded, etc.)
- Live regions announce updates
- Landmarks are navigable
- Tab order is logical

## Examples

### Accessible Form

```swift
Form {
    TextField("Name", text: $name)
        .accessibilityLabel("Full name")
        .accessibilityHint("Enter your first and last name")

    TextField("Email", text: $email)
        .accessibilityLabel("Email address")
        .accessibilityDescribedBy("email-help")
        .accessibilityValue(emailValid ? "Valid" : "Invalid")

    Text("We'll use this to contact you")
        .accessibilityIdentifier("email-help")
        .accessibilityHidden(false)

    Button("Submit") { submit() }
        .accessibilityHint("Submits the form")
}
.accessibilityRole(.form)
.accessibilityLabel("Contact form")
```

### Accessible Navigation

```swift
NavigationView {
    List {
        NavigationLink("Home", destination: HomeView())
            .accessibilityLabel("Go to home page")

        NavigationLink("Settings", destination: SettingsView())
            .accessibilityLabel("Go to settings")
    }
    .accessibilityRole(.list)
    .accessibilityLabel("Main menu")
}
```

### Accessible Modal Dialog

```swift
.sheet(isPresented: $showDialog) {
    VStack {
        Text("Confirm Action")
            .accessibilityRole(.heading)
            .accessibilityIdentifier("dialog-title")

        Text("Are you sure you want to delete this item?")
            .accessibilityIdentifier("dialog-description")

        HStack {
            Button("Cancel") { showDialog = false }
                .accessibilityHint("Closes the dialog without deleting")

            Button("Delete", role: .destructive) {
                deleteItem()
                showDialog = false
            }
            .accessibilityHint("Permanently deletes the item")
        }
    }
    .accessibilityRole(.alertDialog)
    .accessibilityLabelledBy("dialog-title")
    .accessibilityDescribedBy("dialog-description")
}
```

### Accessible Dynamic Content

```swift
VStack {
    Button("Load Data") { loadData() }

    if isLoading {
        Text("Loading...")
            .accessibilityLiveRegion(.polite)
    }

    if let error = errorMessage {
        Text(error)
            .accessibilityRole(.alert)
            .accessibilityLiveRegion(.assertive)
    }

    if let data = data {
        Text("Loaded \(data.count) items")
            .accessibilityLiveRegion(.polite)
    }
}
```

## Future Enhancements

Potential improvements for future releases:

1. **Automatic Label Generation** - Infer labels from context
2. **Accessibility Hints Library** - Predefined hints for common actions
3. **Accessibility Testing Tools** - Built-in validation
4. **Screen Reader Simulator** - Development tool
5. **ARIA Documentation Generator** - Auto-generate accessibility docs
6. **Accessibility Linter** - Compile-time warnings for missing attributes
7. **Keyboard Shortcut Discovery** - Announce available shortcuts
8. **High Contrast Mode** - Automatic style adjustments
9. **Reduced Motion Support** - Respect prefers-reduced-motion
10. **Focus Visible Indicators** - Enhanced keyboard focus styles

## Resources

### Specifications
- [ARIA 1.2 Specification](https://www.w3.org/TR/wai-aria-1.2/)
- [WCAG 2.1 Guidelines](https://www.w3.org/WAI/WCAG21/quickref/)
- [ARIA Authoring Practices Guide (APG)](https://www.w3.org/WAI/ARIA/apg/)

### Testing Tools
- [axe DevTools](https://www.deque.com/axe/devtools/)
- [WAVE](https://wave.webaim.org/)
- [Lighthouse](https://developers.google.com/web/tools/lighthouse)

### Screen Readers
- [NVDA](https://www.nvaccess.org/)
- [JAWS](https://www.freedomscientific.com/products/software/jaws/)
- [VoiceOver](https://www.apple.com/accessibility/voiceover/)

## Implementation Status

✅ **Complete** - All core functionality implemented:
- Comprehensive ARIA role support (40+ roles)
- All ARIA state and property attributes
- Component-specific ARIA attributes
- Landmark roles for page structure
- Live region support
- Form accessibility
- Dialog/modal accessibility
- Tab navigation accessibility
- View modifiers for all ARIA attributes
- WCAG 2.1 AA compliance

Ready for integration testing and accessibility audits.
