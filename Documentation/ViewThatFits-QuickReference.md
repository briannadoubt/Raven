# ViewThatFits Quick Reference

## Basic Syntax

```swift
ViewThatFits(in: axes) {
    FirstOption()
    SecondOption()
    FallbackOption()
}
```

## Axis Options

| Axis | Description | Use Case |
|------|-------------|----------|
| `.vertical` | Measures height (default) | Content that varies in vertical space |
| `.horizontal` | Measures width | Navigation, toolbars, horizontal layouts |
| `.all` or `[.horizontal, .vertical]` | Measures both | Complex responsive layouts |

## Common Patterns

### Responsive Navigation

```swift
ViewThatFits(in: .horizontal) {
    // Desktop: Full navigation
    HStack {
        ForEach(items) { item in
            NavigationLink(item.title, destination: item.view)
        }
    }

    // Tablet: Limited + menu
    HStack {
        ForEach(items.prefix(3)) { item in
            NavigationLink(item.title, destination: item.view)
        }
        Menu("More") { /* remaining items */ }
    }

    // Mobile: Menu only
    Menu("Menu") { /* all items */ }
}
```

### Adaptive Forms

```swift
ViewThatFits {
    // Wide: Multi-column
    HStack(alignment: .top) {
        VStack { /* column 1 */ }
        VStack { /* column 2 */ }
    }

    // Narrow: Single column
    VStack { /* all fields */ }
}
```

### Header Layouts

```swift
ViewThatFits(in: .horizontal) {
    // Desktop: Logo + Title + Actions
    HStack {
        Image("logo")
        Text("App Name")
        Spacer()
        Button("Sign In") { }
        Button("Sign Up") { }
    }

    // Mobile: Compact
    HStack {
        Image("logo")
        Text("App")
        Spacer()
        Button("Menu") { }
    }
}
```

## Key Principles

1. **Order Matters**: First fitting option is shown
2. **Always Provide Fallback**: Last option should fit in minimal space
3. **Test All Sizes**: Verify each option displays correctly
4. **Use Appropriate Axis**: Choose axis based on your layout variation

## Browser Support

- ✅ Chrome/Edge 105+
- ✅ Safari 16+
- ✅ Firefox 110+
- ⚠️ Older browsers: Shows last option as fallback

## Performance

- **Native CSS**: Uses container queries (no JavaScript)
- **Efficient**: Browser handles selection
- **Fast**: No resize listeners or measurements

## Combines Well With

- `.containerRelativeFrame()` - For precise sizing within containers
- `.padding()` - For consistent spacing
- `.frame()` - For explicit size constraints
- `GeometryReader` - For advanced size-aware layouts

## Anti-Patterns

❌ **Don't use for simple hide/show logic**
```swift
// Bad: Use conditional rendering instead
ViewThatFits {
    if condition { SomeView() }
    EmptyView()
}

// Good: Use conditional directly
if condition { SomeView() }
```

❌ **Don't provide too many similar options**
```swift
// Bad: Too many similar options
ViewThatFits {
    Layout1()  // 1200px wide
    Layout2()  // 1150px wide
    Layout3()  // 1100px wide
    Layout4()  // 1050px wide
}

// Good: Distinct breakpoints
ViewThatFits {
    DesktopLayout()   // > 1024px
    TabletLayout()    // > 768px
    MobileLayout()    // fallback
}
```

❌ **Don't use when size is controlled by parent**
```swift
// Bad: Parent controls size explicitly
VStack {
    Text("Header")
        .frame(width: 200)
    ViewThatFits {
        WideLayout()
        NarrowLayout()
    }
    .frame(width: 200)  // Fixed width makes ViewThatFits pointless
}

// Good: Let ViewThatFits have available space
VStack {
    Text("Header")
    ViewThatFits {
        WideLayout()
        NarrowLayout()
    }
    // No fixed width - can adapt naturally
}
```

## Debug Tips

1. **Test at different sizes**: Use browser dev tools to resize container
2. **Check all options**: Verify each layout option renders correctly
3. **Verify axis choice**: Ensure you're measuring the right dimension
4. **Check browser support**: Test in target browsers

## Code Examples Location

- **Simple Examples**: `/Examples/ViewThatFitsExample.swift`
- **Advanced Patterns**: Same file, `AdvancedViewThatFitsExample`
- **Full Documentation**: `Sources/Raven/Views/Layout/ViewThatFits.swift`

## Implementation Details

- **File**: `Sources/Raven/Views/Layout/ViewThatFits.swift`
- **Tests**: `Tests/RavenTests/ViewThatFitsTests.swift` (22 tests)
- **Technology**: CSS Container Queries
- **Type**: Primitive View (Body = Never)
