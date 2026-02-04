# Raven Examples

A collection of example applications demonstrating Raven framework capabilities.

## Getting Started

Each example is a complete, runnable application. To try an example:

```bash
# Navigate to the example directory
cd Examples/HelloWorld

# Build for WASM
swift build --triple wasm32-unknown-wasi

# The built .wasm file will be in .build/wasm32-unknown-wasi/debug/
```

## Example Applications

### 1. **Hello World** 👋
**Difficulty**: Beginner
**Concepts**: Basic app structure, state, buttons, layout

The simplest possible Raven app. Perfect for getting started.

**Key Features**:
- Counter with button
- Basic styling
- State management

[View Code](./HelloWorld/) | [Guide](./HelloWorld/README.md)

---

### 2. **Todo List** ✅
**Difficulty**: Intermediate
**Concepts**: Forms, lists, CRUD operations, filtering

A complete todo list app with add, toggle, delete, and filtering.

**Key Features**:
- Dynamic list rendering
- Form input handling
- Computed properties
- Component composition

[View Code](./TodoList/) | [Guide](./TodoList/README.md)

---

### 3. **Animation Gallery** ✨
**Difficulty**: Intermediate
**Concepts**: Animations, spring physics, transforms

Interactive demos of Raven's animation system.

**Key Features**:
- Multiple animation types
- Spring physics
- Combined animations
- Rotation and scaling

[View Code](./Animation/) | [Guide](./Animation/README.md)

---

## Coming Soon

More examples will be added covering:

- **Navigation App**: Multi-screen navigation with routing
- **Form Validation**: Complex forms with validation
- **Data Visualization**: Charts and graphs
- **Real-time Chat**: WebRTC and WebSocket integration
- **3D Graphics**: WebGL shader effects
- **PWA Features**: Offline support and installation
- **Canvas Drawing**: 2D graphics and interactive drawing

## Building for Production

All examples can be built for production with optimization:

```bash
swift build --triple wasm32-unknown-wasi -c release -Xswiftc -Osize
```

This enables:
- Size optimization (`-Osize`)
- Link-time optimization (LTO)
- Dead code elimination
- Result: Typically <500KB WASM bundles

## Learning Path

**Recommended Order**:

1. Start with **Hello World** to understand basics
2. Try **Todo List** for state management and lists
3. Explore **Animation** for interactive effects
4. Build your own app!

## Resources

- [API Documentation](../Docs/)
- [Getting Started Guide](../README.md)
- [Best Practices](../Docs/best-practices.md)
- [Performance Tips](../Docs/performance.md)

## Contributing Examples

Have a great example to share? We'd love to include it!

1. Create your example in `Examples/YourExampleName/`
2. Include a `README.md` with:
   - What the example demonstrates
   - Key concepts covered
   - Step-by-step explanation
3. Keep it focused on teaching specific concepts
4. Submit a PR!

---

**Happy coding with Raven! 🚀**
