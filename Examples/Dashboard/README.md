# Dashboard Example

A comprehensive dashboard application demonstrating advanced Raven layout capabilities, responsive design, and complex state management.

## What It Demonstrates

This example showcases advanced Raven/SwiftUI patterns:

### Complex Layouts
- **LazyVGrid**: Efficient grid layouts with flexible columns
- **GeometryReader**: Responsive layouts that adapt to container size
- **Form + Section**: Structured form layouts for settings
- **HStack/VStack/ZStack**: Flexible box model layouts
- **Spacer & Divider**: Layout helpers for spacing and separation

### Responsive Design
- Dynamic column count based on available width
- Flexible grid items that adapt to their container
- Proper use of spacing and alignment for visual hierarchy

### Navigation
- Section-based navigation without NavigationView
- State-driven content switching (tabs)
- Shared state across multiple sections

### State Management
- Single store managing multiple data types
- Immutable data updates
- Computed properties for derived state

### Component Architecture
- Small, focused, reusable components
- Clear separation of concerns
- Props down, callbacks up pattern

## Project Structure

```
Dashboard/
├── Sources/
│   └── Dashboard/
│       ├── Models.swift   # Data models (Stat, Photo, Activity, Settings)
│       ├── App.swift      # Main app, store, and all views
│       └── main.swift     # Entry point
├── Package.swift          # Swift Package Manager configuration
└── README.md             # This file
```

## Features

### Overview Section
- **Stats Grid**: 2-column grid showing key metrics with trends
- **Recent Activity**: Preview of latest activities
- Demonstrates LazyVGrid with flexible columns

### Gallery Section
- **Photo Grid**: Responsive grid that adjusts column count
- **GeometryReader**: Calculates optimal columns based on width
- Shows how to build a Pinterest-style layout

### Activity Section
- **Full Activity Feed**: Scrollable list of all activities
- **Activity Icons**: Visual indicators for activity types
- Demonstrates List usage with custom row views

### Settings Section
- **Form Layout**: Structured settings interface
- **Toggle Controls**: Boolean settings switches
- **Picker**: Dropdown-style selection for refresh interval
- Shows proper form organization with sections

## How to Run

### Build for macOS (for testing)

```bash
cd Examples/Dashboard
swift build
```

### Build for WebAssembly

```bash
# Using swift-wasm toolchain
swift build --triple wasm32-unknown-wasi
```

### Run Tests

```bash
cd ../..
swift test
```

## Key Files

### Models.swift

Data models for the dashboard:
- **Stat**: Statistics card data
- **Photo**: Gallery photo metadata
- **Activity**: Activity feed item
- **Settings**: Application settings with nested enum

### App.swift

Contains all views and logic:
1. **DashboardStore**: ObservableObject managing all state
2. **Dashboard**: Main view with section navigation
3. **DashboardHeader**: Top bar with title and refresh
4. **NavigationBar**: Section switcher
5. **OverviewSection**: Stats grid + activity preview
6. **StatCard**: Individual stat display
7. **GallerySection**: Responsive photo grid
8. **PhotoCard**: Individual photo card
9. **ActivitySection**: Full activity list
10. **ActivityRow**: Single activity item
11. **SettingsSection**: Settings form
12. **ToggleRow**: Reusable toggle component

## Key Learning Points

### LazyVGrid with Flexible Columns

```swift
LazyVGrid(
    columns: [
        GridItem(.flexible()),
        GridItem(.flexible())
    ],
    spacing: 16
) {
    ForEach(items) { item in
        ItemView(item: item)
    }
}
```

Creates a 2-column grid where each column takes equal space.

### Responsive Layout with GeometryReader

```swift
GeometryReader { geometry in
    let columnCount = max(2, Int(geometry.size.width / 200))
    let columns = Array(repeating: GridItem(.flexible()), count: columnCount)

    LazyVGrid(columns: columns, spacing: 16) {
        ForEach(photos) { photo in
            PhotoCard(photo: photo)
        }
    }
}
```

Dynamically calculates the number of columns based on available width.

### Form with Sections

```swift
Form {
    Section {
        Toggle(isOn: $notificationsEnabled) {
            Text("Notifications")
        }
    }

    Section {
        Text("Preferences")
        // More controls...
    }
}
```

Forms provide automatic layout and styling for input controls.

### Conditional View Rendering

```swift
switch selectedSection {
case .overview:
    OverviewView()
case .gallery:
    GalleryView()
case .settings:
    SettingsView()
}
```

Shows different content based on state, similar to tab navigation.

## Architecture Notes

### Single Store Pattern

All dashboard state lives in `DashboardStore`:
- Centralized state management
- Single source of truth
- Easy to test and debug

### Component Reusability

Views like `StatCard`, `PhotoCard`, `ActivityRow`, and `ToggleRow` are:
- Focused on single responsibility
- Easily reusable across sections
- Simple to test in isolation

### Immutable Updates

Settings are updated immutably:

```swift
func updateSettings(_ newSettings: Settings) {
    settings = newSettings  // Replace entire object
}

// Usage:
var updated = settings
updated.notificationsEnabled = true
onUpdate(updated)
```

This ensures predictable state changes.

### Layout Best Practices

1. **Use VStack/HStack** for simple linear layouts
2. **Use LazyVGrid** for grid layouts (more efficient than nested stacks)
3. **Use GeometryReader** sparingly, only when you need size info
4. **Use Form** for structured input areas
5. **Use Spacer** to push elements apart
6. **Use Divider** for visual separation

## Responsive Design Patterns

### Breakpoint-Based Columns

```swift
let columnCount = max(2, Int(geometry.size.width / 200))
```

Creates more columns as width increases.

### Flexible Grid Items

```swift
GridItem(.flexible())  // Takes available space equally
```

Each column shares space evenly.

### Aspect Ratios

For images/cards, you might use:

```swift
GridItem(.flexible(), spacing: 16)
```

Combined with aspect ratio modifiers to maintain proportions.

## Next Steps

To extend this example:

1. **Real Data**: Fetch stats from an API
2. **Charts**: Add data visualizations
3. **Filtering**: Filter activities by type
4. **Search**: Add search to gallery
5. **Sorting**: Sort photos by date/author
6. **Infinite Scroll**: Load more photos as user scrolls
7. **Animations**: Add transitions between sections
8. **Theming**: Implement dark mode styling
9. **Persistence**: Save settings to localStorage

## Related Examples

- **GridLayoutExample.swift**: More grid patterns
- **GeometryReaderExample.swift**: Advanced responsive techniques
- **FormSectionExample.swift**: Form layout patterns
- **TodoApp Example**: Simpler state management patterns
