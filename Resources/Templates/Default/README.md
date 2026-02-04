# {{ProjectName}}

A Raven application - SwiftUI compiled to WebAssembly and rendered in the DOM.

## About This Project

This project was created with the Raven CLI using the default template. Raven enables you to write SwiftUI-style code that compiles to WebAssembly and runs in the browser.

## Getting Started

### Prerequisites

- Swift 6.2 or later
- SwiftWasm toolchain ([installation guide](https://swiftwasm.org))
- Raven CLI

### Setup

1. **Add Raven Dependency**

   Edit `Package.swift` and uncomment the Raven dependency:

   ```swift
   dependencies: [
       .package(path: "../Raven"),  // For local development
       // OR
       .package(url: "https://github.com/yourusername/Raven.git", from: "0.1.0"),
   ],
   ```

   Also uncomment the Raven imports in your source files:
   - `Sources/{{ProjectName}}/App.swift`
   - `Sources/{{ProjectName}}/main.swift`

2. **Build the Project**

   ```bash
   raven build
   ```

   This compiles your Swift code to WebAssembly and generates output in the `dist/` directory.

3. **Run Development Server**

   ```bash
   raven dev
   ```

   This starts a local development server with hot reload.

## Project Structure

```
{{ProjectName}}/
├── Package.swift              # Swift package manifest
├── Sources/
│   └── {{ProjectName}}/
│       ├── App.swift          # Main application view
│       └── main.swift         # Entry point
├── Public/
│   ├── index.html             # HTML template
│   └── styles.css             # CSS styles
├── .gitignore
└── README.md
```

## Development

### Writing Views

Raven uses SwiftUI-style syntax. Here's the default counter example:

```swift
@MainActor
struct App: View {
    @State private var count: Int = 0

    var body: some View {
        VStack(spacing: 20) {
            Text("Count: \(count)")

            HStack {
                Button("Increment") {
                    count += 1
                }

                Button("Decrement") {
                    count -= 1
                }
            }
        }
    }
}
```

### Available Components

Raven supports many SwiftUI components:

- **Layout**: `VStack`, `HStack`, `ZStack`, `List`, `Form`, `Section`
- **Controls**: `Button`, `Text`, `TextField`, `Toggle`, `Image`
- **State**: `@State`, `@Binding`, `@ObservedObject`, `@StateObject`
- **Modifiers**: `.font()`, `.foregroundColor()`, `.padding()`, etc.

### Building for Production

```bash
raven build --release
```

This creates an optimized production build in `dist/`.

## Deployment

The `dist/` directory contains everything needed to deploy your app:

- `index.html` - Entry HTML file
- `{{ProjectName}}.wasm` - Compiled WebAssembly module
- `runtime.js` - JavaScript runtime
- `styles.css` - CSS styles

You can deploy this to any static hosting service:
- GitHub Pages
- Netlify
- Vercel
- AWS S3
- And more!

## Learn More

- [Raven Documentation](https://github.com/yourusername/Raven)
- [SwiftWasm](https://swiftwasm.org)
- [SwiftUI Tutorials](https://developer.apple.com/tutorials/swiftui)
- [WebAssembly](https://webassembly.org)

## License

This project template is provided as-is for use with Raven.

---

Built with [Raven](https://github.com/yourusername/Raven) - SwiftUI for the Web
