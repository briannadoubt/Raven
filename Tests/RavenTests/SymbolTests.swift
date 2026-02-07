import Testing
@testable import Raven

/// Tests for the Canvas Symbol system
@MainActor
@Suite struct SymbolTests {

    // MARK: - Symbol Creation Tests

    @Test func symbolCreation() {
        let symbol = Symbol(
            name: "test.icon",
            category: "test",
            pathData: "M 0 0 L 1 1"
        )

        #expect(symbol.name == "test.icon")
        #expect(symbol.category == "test")
        #expect(symbol.pathData == "M 0 0 L 1 1")
        #expect(symbol.foregroundColor == nil)
        #expect(symbol.weight == nil)
        #expect(symbol.renderingMode == .monochrome)
    }

    @Test func symbolCreationFromPath() {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: 1, y: 1))

        let symbol = Symbol(
            name: "test.path",
            category: "test",
            path: path
        )

        #expect(symbol.name == "test.path")
        #expect(!symbol.pathData.isEmpty)
    }

    @Test func symbolWithCustomViewBox() {
        let symbol = Symbol(
            name: "test.custom",
            category: "test",
            pathData: "M 0 0 L 100 100",
            viewBox: CGRect(x: 0, y: 0, width: 100, height: 100)
        )

        #expect(symbol.viewBox.width == 100)
        #expect(symbol.viewBox.height == 100)
    }

    // MARK: - Symbol Modifier Tests

    @Test func symbolForegroundColor() {
        let symbol = Symbol(name: "test", category: "test", pathData: "M 0 0")
        let colored = symbol.foregroundColor(.red)

        #expect(colored.foregroundColor != nil)
        #expect(symbol.name == colored.name) // Name should be preserved
    }

    @Test func symbolWeight() {
        let symbol = Symbol(name: "test", category: "test", pathData: "M 0 0")
        let weighted = symbol.weight(.bold)

        #expect(weighted.weight == .bold)
        #expect(weighted.weight?.strokeWidthMultiplier == 1.5)
    }

    @Test func symbolRenderingMode() {
        let symbol = Symbol(name: "test", category: "test", pathData: "M 0 0")
        let hierarchical = symbol.symbolRenderingMode(.hierarchical)

        #expect(hierarchical.renderingMode == .hierarchical)
    }

    @Test func symbolAccessibilityLabel() {
        let symbol = Symbol(name: "test", category: "test", pathData: "M 0 0")
        let labeled = symbol.accessibilityLabel("Test Icon")

        #expect(labeled.accessibilityLabel == "Test Icon")
    }

    @Test func symbolWeightValues() {
        let weights: [Symbol.Weight] = [
            .ultraLight, .thin, .light, .regular,
            .medium, .semibold, .bold, .heavy, .black
        ]

        let expectedMultipliers: [Double] = [
            0.5, 0.7, 0.85, 1.0, 1.15, 1.3, 1.5, 1.7, 2.0
        ]

        for (weight, expected) in zip(weights, expectedMultipliers) {
            #expect(weight.strokeWidthMultiplier == expected)
        }
    }

    // MARK: - Registry Tests

    @Test func registryContainsBuiltInSymbols() {
        let registry = SymbolRegistry.shared

        // Test that registry has symbols
        #expect(registry.count > 0)

        // Test specific symbols exist
        #expect(registry.lookup(name: "circle") != nil)
        #expect(registry.lookup(name: "heart") != nil)
        #expect(registry.lookup(name: "star") != nil)
    }

    @Test func registryLookup() {
        let registry = SymbolRegistry.shared

        // Test direct lookup
        let circle = registry.lookup(name: "circle")
        #expect(circle != nil)
        #expect(circle?.name == "circle")

        // Test missing symbol
        let missing = registry.lookup(name: "nonexistent.symbol")
        #expect(missing == nil)
    }

    @Test func registryAliasLookup() {
        let registry = SymbolRegistry.shared

        // Test SF Symbol alias
        let heart = registry.lookupWithAlias(name: "heart.fill")
        #expect(heart != nil)

        // Test that direct name also works
        let circle = registry.lookupWithAlias(name: "circle")
        #expect(circle != nil)
    }

    @Test func customSymbolRegistration() {
        let registry = SymbolRegistry.shared

        let customSymbol = Symbol(
            name: "custom.test.symbol",
            category: "test",
            pathData: "M 0.5 0.5 L 1 1"
        )

        registry.register(customSymbol)

        let retrieved = registry.lookup(name: "custom.test.symbol")
        #expect(retrieved != nil)
        #expect(retrieved?.name == "custom.test.symbol")

        // Clean up
        registry.unregister(name: "custom.test.symbol")
    }

    @Test func symbolUnregistration() {
        let registry = SymbolRegistry.shared

        let symbol = Symbol(name: "temp.symbol", category: "test", pathData: "M 0 0")
        registry.register(symbol)

        #expect(registry.contains(name: "temp.symbol"))

        let unregistered = registry.unregister(name: "temp.symbol")
        #expect(unregistered != nil)
        #expect(!registry.contains(name: "temp.symbol"))
    }

    @Test func registryCategoryFiltering() {
        let registry = SymbolRegistry.shared

        let shapesSymbols = registry.symbols(in: Symbol.Category.shapes)
        #expect(shapesSymbols.count > 0)

        let arrowsSymbols = registry.symbols(in: Symbol.Category.arrows)
        #expect(arrowsSymbols.count > 0)
    }

    @Test func registryAllCategories() {
        let registry = SymbolRegistry.shared
        let categories = registry.allCategories()

        #expect(categories.contains(Symbol.Category.shapes))
        #expect(categories.contains(Symbol.Category.arrows))
        #expect(categories.contains(Symbol.Category.communication))
    }

    @Test func registrySearch() {
        let registry = SymbolRegistry.shared

        let circleResults = registry.search(query: "circle")
        #expect(circleResults.count > 0)

        let allResults = circleResults.filter { $0.name.contains("circle") }
        #expect(circleResults.count == allResults.count)
    }

    @Test func registryPrefixSearch() {
        let registry = SymbolRegistry.shared

        let arrowSymbols = registry.symbols(withPrefix: "arrow.")
        #expect(arrowSymbols.count > 0)

        for symbol in arrowSymbols {
            #expect(symbol.name.hasPrefix("arrow."))
        }
    }

    @Test func registryBatchRegistration() {
        let registry = SymbolRegistry.shared

        let symbols = [
            Symbol(name: "batch.1", category: "test", pathData: "M 0 0"),
            Symbol(name: "batch.2", category: "test", pathData: "M 0 0"),
            Symbol(name: "batch.3", category: "test", pathData: "M 0 0")
        ]

        registry.register(symbols)

        #expect(registry.contains(name: "batch.1"))
        #expect(registry.contains(name: "batch.2"))
        #expect(registry.contains(name: "batch.3"))

        // Clean up
        registry.unregister(name: "batch.1")
        registry.unregister(name: "batch.2")
        registry.unregister(name: "batch.3")
    }

    @Test func registryAliasRegistration() {
        let registry = SymbolRegistry.shared

        let symbol = Symbol(name: "test.original", category: "test", pathData: "M 0 0")
        registry.register(symbol)
        registry.registerAlias("test.alias", target: "test.original")

        let viaAlias = registry.lookupWithAlias(name: "test.alias")
        #expect(viaAlias != nil)
        #expect(viaAlias?.name == "test.original")

        // Clean up
        registry.unregister(name: "test.original")
    }

    // MARK: - Built-in Symbol Tests

    @Test func builtInShapeSymbols() {
        let registry = SymbolRegistry.shared

        let shapeNames = [
            "circle", "circle.fill",
            "square", "square.fill",
            "triangle", "triangle.fill",
            "star", "star.fill",
            "heart", "heart.fill",
            "diamond", "diamond.fill"
        ]

        for name in shapeNames {
            let symbol = registry.lookup(name: name)
            #expect(symbol != nil)
            #expect(symbol?.category == Symbol.Category.shapes)
        }
    }

    @Test func builtInArrowSymbols() {
        let registry = SymbolRegistry.shared

        let arrowNames = [
            "arrow.up", "arrow.down", "arrow.left", "arrow.right",
            "arrow.clockwise", "arrow.counterclockwise",
            "chevron.up", "chevron.down", "chevron.left", "chevron.right"
        ]

        for name in arrowNames {
            let symbol = registry.lookup(name: name)
            #expect(symbol != nil)
            #expect(symbol?.category == Symbol.Category.arrows)
        }
    }

    @Test func builtInCommunicationSymbols() {
        let registry = SymbolRegistry.shared

        let commNames = [
            "envelope", "envelope.fill",
            "phone", "phone.fill",
            "message", "message.fill",
            "bell", "bell.fill"
        ]

        for name in commNames {
            let symbol = registry.lookup(name: name)
            #expect(symbol != nil)
            #expect(symbol?.category == Symbol.Category.communication)
        }
    }

    @Test func builtInMediaSymbols() {
        let registry = SymbolRegistry.shared

        let mediaNames = [
            "play", "play.fill",
            "pause", "pause.fill",
            "stop", "stop.fill",
            "forward", "forward.fill",
            "backward", "backward.fill",
            "speaker", "speaker.fill"
        ]

        for name in mediaNames {
            let symbol = registry.lookup(name: name)
            #expect(symbol != nil)
            #expect(symbol?.category == Symbol.Category.media)
        }
    }

    @Test func builtInActionSymbols() {
        let registry = SymbolRegistry.shared

        let actionNames = [
            "plus", "minus", "xmark", "checkmark",
            "plus.circle", "minus.circle", "xmark.circle", "checkmark.circle",
            "trash", "trash.fill", "gear"
        ]

        for name in actionNames {
            let symbol = registry.lookup(name: name)
            #expect(symbol != nil)
            #expect(symbol?.category == Symbol.Category.actions)
        }
    }

    @Test func builtInStatusSymbols() {
        let registry = SymbolRegistry.shared

        let statusNames = [
            "info.circle", "info.circle.fill",
            "exclamationmark.triangle", "exclamationmark.triangle.fill",
            "exclamationmark.circle", "exclamationmark.circle.fill",
            "questionmark.circle", "questionmark.circle.fill"
        ]

        for name in statusNames {
            let symbol = registry.lookup(name: name)
            #expect(symbol != nil)
            #expect(symbol?.category == Symbol.Category.status)
        }
    }

    @Test func builtInNavigationSymbols() {
        let registry = SymbolRegistry.shared

        let navNames = [
            "house", "house.fill",
            "magnifyingglass",
            "person", "person.fill",
            "folder", "folder.fill",
            "doc", "doc.fill",
            "calendar"
        ]

        for name in navNames {
            let symbol = registry.lookup(name: name)
            #expect(symbol != nil)
            #expect(symbol?.category == Symbol.Category.navigation)
        }
    }

    // MARK: - SF Symbol Compatibility Tests

    @Test func sfSymbolCompatibility() {
        let registry = SymbolRegistry.shared

        // Test that common SF Symbol names are aliased
        let sfSymbolNames = [
            "circle.fill", "heart", "star.fill",
            "arrow.up", "envelope", "play.fill",
            "plus.circle", "checkmark", "house"
        ]

        for name in sfSymbolNames {
            let symbol = Symbol.systemName(name)
            #expect(symbol != nil)
        }
    }

    @Test func staticBuiltInLookup() {
        let circle = Symbol.builtIn("circle")
        #expect(circle != nil)
        #expect(circle?.name == "circle")

        let missing = Symbol.builtIn("nonexistent")
        #expect(missing == nil)
    }

    @Test func staticSystemNameLookup() {
        let heart = Symbol.systemName("heart.fill")
        #expect(heart != nil)

        let arrow = Symbol.systemName("arrow.right")
        #expect(arrow != nil)
    }

    // MARK: - Symbol Count Tests

    @Test func minimumSymbolCount() {
        let registry = SymbolRegistry.shared

        // Should have at least 50 built-in symbols as per requirements
        #expect(registry.count >= 50)
    }

    @Test func categoryDistribution() {
        let registry = SymbolRegistry.shared

        // Each major category should have multiple symbols
        let categories = [
            Symbol.Category.shapes,
            Symbol.Category.arrows,
            Symbol.Category.communication,
            Symbol.Category.media,
            Symbol.Category.actions,
            Symbol.Category.status
        ]

        for category in categories {
            let count = registry.symbols(in: category).count
            #expect(count > 0)
        }
    }

    // MARK: - Symbol Identifiable Tests

    @Test func symbolIdentifiable() {
        let symbol = Symbol(name: "test.id", category: "test", pathData: "M 0 0")
        #expect(symbol.id == symbol.name)
    }

    // MARK: - Symbol Hashable Tests

    @Test func symbolHashable() {
        let symbol1 = Symbol(name: "test", category: "test", pathData: "M 0 0")
        let symbol2 = Symbol(name: "test", category: "test", pathData: "M 0 0")
        let symbol3 = Symbol(name: "other", category: "test", pathData: "M 0 0")

        #expect(symbol1 == symbol2)
        #expect(symbol1 != symbol3)
    }

    // MARK: - Convenience Extension Tests

    @Test func symbolRegisterExtension() {
        let symbol = Symbol(name: "extension.test", category: "test", pathData: "M 0 0")
        symbol.register()

        let retrieved = SymbolRegistry.shared.lookup(name: "extension.test")
        #expect(retrieved != nil)

        // Clean up
        symbol.unregister()
    }
}
