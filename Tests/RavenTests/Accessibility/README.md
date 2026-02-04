# Accessibility Tests

Comprehensive test suite for Track E: Accessibility features in Raven.

## Quick Start

Run all accessibility tests:
```bash
swift test --filter AccessibilityTests
```

## Test Structure

```
Tests/RavenTests/Accessibility/
├── AccessibilityTests.swift    # Main test suite (72 tests)
├── TEST_SUMMARY.md            # Detailed coverage report
└── README.md                  # This file
```

## Test Categories

1. **FocusState Boolean Binding** (5 tests)
2. **FocusState Hashable/Enum** (5 tests)
3. **Programmatic Focus** (3 tests)
4. **Tab Order Management** (4 tests)
5. **Focus Scopes** (6 tests)
6. **ARIA Roles** (5 tests)
7. **ARIA Attributes** (9 tests)
8. **Live Regions** (3 tests)
9. **Accessibility Helpers** (13 tests)
10. **Accessibility Traits** (2 tests)
11. **WCAG 2.1 Compliance** (5 tests)
12. **Complex Integration** (3 tests)
13. **Edge Cases** (9 tests)

## Features Tested

### FocusState
- Boolean bindings for single field focus
- Hashable/Enum bindings for multi-field focus
- Programmatic focus changes
- Focus state callbacks
- Projected value access

### Focus Management
- Tab order customization
- Focus scopes and boundaries
- Focus trapping in modals
- Hierarchical scope management
- Focus callbacks

### ARIA
- 17+ semantic roles
- Landmark roles (navigation, main, complementary, etc.)
- State attributes (expanded, pressed, checked, selected)
- Relationship attributes (labelledby, describedby, controls)
- Live regions (polite, assertive)
- Form attributes (required, invalid, readonly)

### WCAG 2.1
- Info and Relationships (1.3.1)
- Bypass Blocks (2.4.1)
- Headings and Labels (2.4.6)
- Error Identification (3.3.1)
- Labels or Instructions (3.3.2)
- Status Messages (4.1.3)

## Example Usage

### Basic FocusState Test
```swift
func testFocusStateWithEnum() {
    enum Field: Hashable {
        case username, password
    }
    
    var focusState = FocusState<Field?>()
    focusState.wrappedValue = .username
    XCTAssertEqual(focusState.wrappedValue, .username)
}
```

### ARIA Role Test
```swift
func testAccessibilityRoleButton() {
    struct TestView: View {
        var body: some View {
            Text("Click me")
                .accessibilityRole(.button)
        }
    }
    
    let view = TestView()
    XCTAssertNotNil(view.body)
}
```

### WCAG Compliance Test
```swift
func testWCAGFormLabels() {
    struct TestView: View {
        @State private var name = ""
        
        var body: some View {
            TextField("Name", text: $name)
                .accessibilityLabel("Full name")
                .accessibilityRequired(true)
        }
    }
    
    let view = TestView()
    XCTAssertNotNil(view.body)
}
```

## Running Specific Tests

Run FocusState tests only:
```bash
swift test --filter AccessibilityTests.testFocusState
```

Run ARIA tests only:
```bash
swift test --filter AccessibilityTests.testAccessibility
```

Run WCAG compliance tests only:
```bash
swift test --filter AccessibilityTests.testWCAG
```

## Test Philosophy

- **Comprehensive**: Cover all accessibility APIs
- **Realistic**: Test real-world usage patterns
- **Isolated**: Each test is independent
- **Clear**: Test names clearly indicate what is being tested
- **Maintainable**: Well-organized with clear categories

## Coverage Goals

✅ **FocusState**: Boolean and Hashable bindings
✅ **Focus Management**: Tab order, scopes, trapping
✅ **ARIA Roles**: All semantic roles
✅ **ARIA Attributes**: Labels, states, relationships
✅ **Live Regions**: Polite and assertive announcements
✅ **WCAG 2.1**: Key success criteria tested
✅ **Edge Cases**: Nil values, empty strings, conditional content
✅ **Integration**: Complex multi-feature scenarios

## Related Documentation

- Source: `Sources/Raven/Accessibility/`
- ARIA Coverage: `Sources/Raven/Accessibility/ARIA_COVERAGE.md`
- Quick Reference: `Sources/Raven/Accessibility/QUICK_REFERENCE.md`
- Main README: `Sources/Raven/Accessibility/README.md`
