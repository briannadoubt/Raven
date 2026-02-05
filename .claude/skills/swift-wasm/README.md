# Swift WASM Skill

A comprehensive skill for Swift 6.2 WebAssembly development with official toolchains, Carton, and modern WASM APIs.

## Quick Start

### Using the Skill

The skill can be invoked in several ways:

**With arguments (recommended):**
```
/swift-wasm setup      # Set up Swift 6.2.3 + WASM SDK
/swift-wasm build      # Build current project for WASM
/swift-wasm dev        # Start development server
/swift-wasm optimize   # Build optimized production bundle
/swift-wasm debug      # Debug WASM build issues
/swift-wasm test       # Run tests in browser
```

**Without arguments:**
```
/swift-wasm
# Claude will analyze your needs and provide guidance
```

**Natural language:**
Just ask questions about Swift WASM:
- "How do I set up Swift WASM?"
- "Build my app for WebAssembly"
- "Why is my WASM file so large?"
- "Deploy to production"

## What This Skill Does

### Automatic Detection
- Detects your Swift version (Apple vs swift.org)
- Checks for WASM SDK installation
- Identifies Carton availability
- Analyzes your project configuration

### Smart Actions
- **Setup**: Guides through Swift 6.2.3 + WASM SDK installation
- **Build**: Chooses optimal build method (Carton vs native SDK)
- **Development**: Starts appropriate dev server with hot reload
- **Optimization**: Applies production-grade size optimizations
- **Debugging**: Diagnoses and fixes common issues
- **Testing**: Runs browser-based tests

### Knowledge Base
- Latest Swift 6.2 WASM APIs and features
- Carton vs native SDK trade-offs
- JavaScriptKit integration patterns
- Performance optimization techniques
- Deployment platform configurations

## Files in This Skill

### SKILL.md (Main)
The main skill definition with:
- Quick action handlers
- Common commands reference
- Workflow patterns
- Troubleshooting guide
- Performance best practices

### examples.md
Practical code examples including:
- Setup scripts
- Build configurations
- JavaScript interop patterns
- HTML wrappers
- CI/CD configurations
- Optimization recipes

### troubleshooting.md
Comprehensive problem-solving guide:
- Setup issues
- Build errors
- Runtime problems
- Deployment challenges
- Performance optimization

### README.md (This File)
Overview and usage instructions.

## Example Workflows

### First-Time Setup
```
You: /swift-wasm setup
Claude: [Checks your system, installs swiftly, Swift 6.2.3, and WASM SDK]
```

### Daily Development
```
You: /swift-wasm dev
Claude: [Starts Carton dev server with hot reload]
```

### Production Build
```
You: /swift-wasm optimize
Claude: [Builds with all optimizations, shows before/after sizes]
```

### Troubleshooting
```
You: My WASM file is 5MB, how do I make it smaller?
Claude: [Analyzes build, suggests optimizations, rebuilds optimized]
```

## Integration with Raven

This skill is designed specifically for the Raven project and integrates with:
- **NATIVE_WASM_SETUP.md** - Official Swift + WASM SDK guide
- **CARTON_WORKFLOW.md** - Carton development workflow
- **QUICKSTART.md** - Getting started guide

The skill always references and respects your project's existing documentation.

## What Makes This Skill Special

### 2026 Best Practices
- Uses latest Swift 6.2.3 with official WASM support
- Covers both Carton (dev) and native SDK (production)
- Includes modern optimization techniques
- References current deployment platforms

### Research-Backed
Built from extensive 2026 research including:
- Official Swift.org documentation
- SwiftWasm project updates
- JavaScriptKit latest releases
- Real-world deployment patterns

### Comprehensive Coverage
- Setup and installation
- Development workflows
- Production optimization
- Debugging techniques
- Deployment strategies
- Common pitfalls and solutions

## Allowed Tools

This skill can use:
- **Bash** - Run Swift commands, build scripts
- **Read** - Read project files and configurations
- **Grep** - Search for code patterns
- **Glob** - Find relevant files
- **WebFetch** - Fetch latest documentation
- **WebSearch** - Search for solutions

## When This Skill Activates

The skill automatically activates when you:
- Mention "Swift WASM" or "WebAssembly"
- Ask about building for the web
- Request WASM toolchain setup
- Need to optimize bundle size
- Want to deploy WASM apps
- Use the `/swift-wasm` command

## Current Project Status

Your Raven project uses:
- **Swift Version:** 6.2.3
- **JavaScriptKit:** 0.19.2 (pinned for compatibility)
- **Platforms:** macOS 13+, iOS 16+
- **Optimizations:** Already configured in Package.swift

## Tips for Best Results

1. **Be specific about your goal**
   - "Set up for production" vs "Quick development setup"
   - "Optimize for size" vs "Fast build times"

2. **Mention your context**
   - "First time using Swift WASM"
   - "Already have Carton installed"
   - "Need to deploy to Netlify"

3. **Share error messages**
   - Copy full error output
   - Include relevant file contents
   - Mention what you've already tried

4. **Ask follow-up questions**
   - "Why did you choose Carton over native SDK?"
   - "Can I make it even smaller?"
   - "What's the trade-off here?"

## Limitations

This skill:
- Cannot install software that requires admin/sudo
- Cannot modify system-wide configurations
- Works best with macOS (Linux support varies)
- Assumes you have basic command-line knowledge

For issues outside the skill's scope, it will direct you to:
- Project documentation
- Swift forums
- GitHub issues
- Community resources

## Updates and Maintenance

This skill is based on:
- **Swift 6.2.3** (September 2025 release)
- **Research date:** February 2026
- **Tooling versions:** Carton 1.1.3, JavaScriptKit 0.33.0

As the Swift WASM ecosystem evolves, some commands or URLs may need updates. Check official documentation for the latest information.

## Contributing

Found an issue or have a suggestion? This skill is part of the Raven project. You can:
1. Report issues in Raven's GitHub
2. Suggest improvements to skill behavior
3. Share new optimization techniques
4. Add more examples and recipes

## License

This skill is part of the Raven project and follows the same license.

---

**Ready to build amazing web apps with Swift? Try `/swift-wasm setup` to get started!**
