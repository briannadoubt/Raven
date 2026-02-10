# ARIA Quick Reference Guide

A quick reference for adding accessibility to your Raven views.

## Common Patterns

### Text Input

```swift
TextField("Email", text: $email)
    .accessibilityLabel("Email address")
    .accessibilityHint("We'll use this to send notifications")
```

### Required Field

```swift
TextField("Name", text: $name)
    .accessibilityRequired()
    .accessibilityLabel("Full name (required)")
```

### Invalid Field

```swift
TextField("Email", text: $email)
    .accessibilityInvalid(isInvalid: !emailValid, describedBy: "email-error")

if !emailValid {
    Text("Please enter a valid email")
        .accessibilityIdentifier("email-error")
        .accessibilityRole(.alert)
}
```

### Button with Action Description

```swift
Button("Delete") { deleteItem() }
    .accessibilityLabel("Delete item")
    .accessibilityHint("Permanently removes the item")
```

### Toggle Button

```swift
Button("Bold") { isBold.toggle() }
    .accessibilityToggleButton(isPressed: isBold)
```

### Expandable Section

```swift
Button(isExpanded ? "Hide" : "Show") { isExpanded.toggle() }
    .accessibilityDisclosureButton(
        isExpanded: isExpanded,
        controls: "details"
    )

if isExpanded {
    VStack {
        // Details
    }
    .accessibilityIdentifier("details")
}
```

### Headings

```swift
Text("Page Title")
    .accessibilityHeading(level: 1)

Text("Section Title")
    .accessibilityHeading(level: 2)
```

### Lists

```swift
List {
    ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
        ItemView(item)
            .accessibilityListItem(
                position: index + 1,
                total: items.count
            )
    }
}
.accessibilityLabel("Shopping list")
```

### Landmarks

```swift
// Main content
VStack {
    // Primary content
}
.accessibilityLandmark(.main, label: "Product catalog")

// Navigation
VStack {
    // Nav links
}
.accessibilityLandmark(.navigation, label: "Main menu")

// Sidebar
VStack {
    // Filters
}
.accessibilityLandmark(.complementary, label: "Filters")
```

### Status Messages

```swift
// Loading indicator
Text("Loading...")
    .accessibilityStatus()

// Success message
Text("Saved successfully")
    .accessibilityStatus()
```

### Error Alerts

```swift
if let error = errorMessage {
    Text(error)
        .accessibilityAlert()
}
```

### Progress Indicator

```swift
ProgressView(value: progress, total: 100)
    .accessibilityProgress(
        value: Int(progress),
        total: 100,
        label: "Upload progress"
    )
```

### Complete Form Field

```swift
TextField("", text: $email)
    .accessibilityFormField(
        label: "Email address",
        hint: "We'll never share your email",
        helpTextId: "email-help",
        required: true,
        invalid: !emailValid,
        errorId: emailValid ? nil : "email-error"
    )

Text("We'll never share your email")
    .accessibilityIdentifier("email-help")

if !emailValid {
    Text("Invalid email format")
        .accessibilityIdentifier("email-error")
}
```

### Hide Decorative Elements

```swift
Image("decorative-pattern")
    .accessibilityHidden(true)
```

### Image with Description

```swift
Image("product-photo")
    .accessibilityLabel("Blue running shoes")
    .accessibilityRole(.image)
```

### Selected Items

```swift
ItemView(item)
    .accessibilitySelected(selectedItems.contains(item.id))
```

## Landmark Roles

| Role | Purpose | Usage |
|------|---------|-------|
| `.main` | Primary content | Main content area (one per page) |
| `.navigation` | Navigation | Nav bars, menus |
| `.complementary` | Supporting content | Sidebars, related content |
| `.search` | Search | Search functionality |
| `.banner` | Site header | Page header |
| `.contentInfo` | Site footer | Page footer |
| `.form` | Form | Form container |
| `.region` | Generic section | Named sections |

## Live Region Priority

| Priority | When to Use | Example |
|----------|-------------|---------|
| `.off` | Static content | Default, no announcements |
| `.polite` | Non-urgent updates | Status messages, search results |
| `.assertive` | Urgent alerts | Errors, critical warnings |

## Form Field States

```swift
// Required
.accessibilityRequired()

// Invalid
.accessibilityInvalid(isInvalid: true)

// Read-only
.accessibilityReadonly()

// Disabled (built-in)
.disabled(true)
```

## Interactive States

```swift
// Expanded/collapsed
.accessibilityExpanded(isExpanded)

// Pressed/unpressed
.accessibilityPressed(isPressed)

// Selected
.accessibilitySelected(isSelected)

// Checked (for custom controls)
.accessibilityRole(.checkbox)
// Toggle handles aria-checked automatically
```

## Testing Checklist

### Keyboard Navigation
- [ ] Tab through all controls
- [ ] All interactive elements reachable
- [ ] Focus indicators visible
- [ ] Tab order logical

### Screen Reader
- [ ] All elements have names
- [ ] States announced (checked, expanded, etc.)
- [ ] Landmarks navigable
- [ ] Live regions announce updates
- [ ] Form errors announced

### Validation
- [ ] Run axe DevTools
- [ ] Check Lighthouse accessibility score
- [ ] No ARIA violations
- [ ] All images have alt text
- [ ] Form labels present

## Common Mistakes to Avoid

### ❌ Don't
```swift
// Missing label
TextField("", text: $email)

// Hiding interactive elements
Button("Click me") { }
    .accessibilityHidden(true)

// Generic labels
Button("Click here") { }
    .accessibilityLabel("Click here")

// Decorative images without hiding
Image("border-pattern")
```

### ✅ Do
```swift
// Provide clear label
TextField("", text: $email)
    .accessibilityLabel("Email address")

// Only hide decorative elements
Image("border-pattern")
    .accessibilityHidden(true)

// Descriptive labels
Button("Save") { }
    .accessibilityLabel("Save document")
    .accessibilityHint("Saves your changes")

// Image descriptions
Image("product")
    .accessibilityLabel("Blue running shoes")
```

## Resources

- [WCAG 2.1 Quick Reference](https://www.w3.org/WAI/WCAG21/quickref/)
- [ARIA Authoring Practices](https://www.w3.org/WAI/ARIA/apg/)
- [WebAIM ARIA Techniques](https://webaim.org/techniques/aria/)

## Getting Help

For detailed documentation, see:
- `ARIA_COVERAGE.md` - Complete ARIA reference
- `README.md` - Focus management system
- `AccessibilityModifiers.swift` - API documentation
- `AccessibilityHelpers.swift` - Helper method docs
