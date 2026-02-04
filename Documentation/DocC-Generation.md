# DocC Documentation Generation

This document explains how to generate and view DocC documentation for the Raven framework.

## Overview

Raven uses Swift's DocC (Documentation Compiler) format for API documentation. All public types, methods, and properties are documented using triple-slash (`///`) comments with DocC-compatible markdown.

## DocC Syntax

Raven follows DocC best practices:

- **Triple-slash comments** (`///`) for documentation
- **Markdown formatting** for rich text
- **Symbol links** using double backticks (e.g., `` ``View`` ``, `` ``VNode`` ``)
- **Code blocks** with Swift syntax highlighting
- **Sections** using DocC keywords: `## Overview`, `## Example`, `## See Also`
- **Parameters and returns** using `- Parameter:` and `- Returns:`
- **Notes and warnings** using `- Note:` and `- Warning:`

### Example

```swift
/// A virtual DOM node representing a tree structure for efficient diffing.
///
/// VNode provides a lightweight representation of DOM elements that can be
/// efficiently compared and patched. Each node has a unique identifier,
/// type, properties, and optional children.
///
/// ## Creating VNodes
///
/// Use the convenience initializers to create different node types:
///
/// ```swift
/// let element = VNode.element("div", children: [
///     VNode.text("Hello, world!")
/// ])
/// ```
///
/// - SeeAlso: ``Differ``, ``Patch``, ``DOMBridge``
public struct VNode: Hashable, Sendable {
    // ...
}
```

## Generating Documentation

### Using Swift Package Manager

Generate DocC documentation for Raven using the Swift Package Manager:

```bash
# From the Raven repository root
swift package generate-documentation --target Raven
```

This will generate documentation for the main Raven target.

### Generate for All Targets

To generate documentation for all targets:

```bash
swift package generate-documentation
```

### Viewing Documentation

After generation, you can view the documentation in Xcode or export it to a static website.

#### In Xcode

1. Open the Raven package in Xcode:
   ```bash
   open Package.swift
   ```

2. Build the documentation:
   - Product > Build Documentation (⌃⌘D)

3. View in the Documentation Viewer:
   - Window > Developer Documentation

#### Export to Static Site

Export documentation to a standalone static website:

```bash
swift package generate-documentation \
    --target Raven \
    --output-path ./docs \
    --transform-for-static-hosting
```

This creates a static website in the `./docs` directory that can be:
- Hosted on GitHub Pages
- Deployed to any static hosting service
- Opened locally in a web browser

### Advanced Options

#### Include Symbol Graph

Generate the symbol graph for IDE integration:

```bash
swift package generate-documentation \
    --target Raven \
    --include-extended-types
```

#### Custom Hosting Base Path

When deploying to a subdirectory on a web server:

```bash
swift package generate-documentation \
    --target Raven \
    --output-path ./docs \
    --transform-for-static-hosting \
    --hosting-base-path /raven
```

## Documentation Coverage

Raven aims for comprehensive documentation coverage:

### Core Types
- ✅ `View` protocol and conformances
- ✅ `VNode` and virtual DOM types
- ✅ `Differ` and patching algorithm
- ✅ `ViewBuilder` and result builders
- ✅ `AnyView` type erasure

### State Management
- ✅ `@State` property wrapper
- ✅ `@Binding` property wrapper
- ✅ `@StateObject` and `@ObservedObject`
- ✅ `ObservableObject` protocol

### Views
- ✅ Primitive views: `Text`, `Button`, `Image`, `TextField`, `Toggle`
- ✅ Layout views: `VStack`, `HStack`, `ZStack`, `List`, `ForEach`
- ✅ Advanced layouts: `LazyVGrid`, `LazyHGrid`, `GeometryReader`
- ✅ Form components: `Form`, `Section`
- ✅ Navigation: `NavigationView`, `NavigationLink`

### Modifiers
- ✅ Basic modifiers: `padding`, `background`, `foregroundColor`
- ✅ Layout modifiers: `frame`, `offset`, `position`
- ✅ Advanced modifiers: `opacity`, `shadow`, `cornerRadius`
- ✅ Custom modifiers: `ViewModifier` protocol

### Environment
- ✅ `Environment` property wrapper
- ✅ `EnvironmentKey` protocol
- ✅ `EnvironmentValues` type
- ✅ Built-in environment values

## Documentation Standards

### All Public APIs Must Have:

1. **Summary** - One-line description
2. **Overview** - Detailed explanation with `## Overview` section
3. **Examples** - Code samples showing usage
4. **Parameters** - Documented with `- Parameter name: description`
5. **Returns** - Documented with `- Returns: description`
6. **Related Symbols** - Cross-references using `- SeeAlso:`

### Code Sample Requirements:

- All code samples must be **valid Swift code**
- Use realistic, practical examples
- Keep examples **concise and focused**
- Include comments for clarity when needed

### Writing Style:

- Use **active voice** ("Creates a button" not "A button is created")
- Be **concise** but complete
- Explain **why** not just **what**
- Include **performance considerations** when relevant
- Note **platform limitations** if applicable

## Verification

To verify documentation coverage:

1. Build documentation in Xcode (⌃⌘D)
2. Check the Documentation Viewer for warnings
3. Run the Phase 7 verification tests:
   ```bash
   swift test --filter Phase7VerificationTests
   ```

## Contributing Documentation

When adding new public APIs:

1. Add DocC-style `///` comments immediately
2. Include at least one code example
3. Link to related types using `` ``TypeName`` ``
4. Run documentation generation to verify formatting
5. Check for warnings in Xcode's documentation build

## Resources

- [Swift-DocC Documentation](https://www.swift.org/documentation/docc/)
- [DocC Tutorial](https://developer.apple.com/documentation/docc)
- [Writing Great Documentation](https://www.swift.org/documentation/docc/writing-great-documentation)

## Known Limitations

- DocC requires Xcode 13+ or Swift 5.5+ on Linux
- Some advanced DocC features (tutorials, articles) are not yet utilized
- Symbol graph generation may be slow for large projects

## Future Improvements

- Add DocC tutorials for common workflows
- Create interactive code examples
- Add architecture diagrams to documentation
- Provide downloadable documentation archives
