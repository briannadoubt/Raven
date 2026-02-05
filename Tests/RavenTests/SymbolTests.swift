import XCTest
@testable import Raven

/// Tests for the Canvas Symbol system
@MainActor
final class SymbolTests: XCTestCase {

    override func setUp() async throws {
        // Registry is a singleton and auto-initializes with built-in symbols
    }

    // MARK: - Symbol Creation Tests

    func testSymbolCreation() {
        let symbol = Symbol(
            name: "test.icon",
            category: "test",
            pathData: "M 0 0 L 1 1"
        )

        XCTAssertEqual(symbol.name, "test.icon")
        XCTAssertEqual(symbol.category, "test")
        XCTAssertEqual(symbol.pathData, "M 0 0 L 1 1")
        XCTAssertNil(symbol.foregroundColor)
        XCTAssertNil(symbol.weight)
        XCTAssertEqual(symbol.renderingMode, .monochrome)
    }

    func testSymbolCreationFromPath() {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: 1, y: 1))

        let symbol = Symbol(
            name: "test.path",
            category: "test",
            path: path
        )

        XCTAssertEqual(symbol.name, "test.path")
        XCTAssertFalse(symbol.pathData.isEmpty)
    }

    func testSymbolWithCustomViewBox() {
        let symbol = Symbol(
            name: "test.custom",
            category: "test",
            pathData: "M 0 0 L 100 100",
            viewBox: CGRect(x: 0, y: 0, width: 100, height: 100)
        )

        XCTAssertEqual(symbol.viewBox.width, 100)
        XCTAssertEqual(symbol.viewBox.height, 100)
    }

    // MARK: - Symbol Modifier Tests

    func testSymbolForegroundColor() {
        let symbol = Symbol(name: "test", category: "test", pathData: "M 0 0")
        let colored = symbol.foregroundColor(.red)

        XCTAssertNotNil(colored.foregroundColor)
        XCTAssertEqual(symbol.name, colored.name) // Name should be preserved
    }

    func testSymbolWeight() {
        let symbol = Symbol(name: "test", category: "test", pathData: "M 0 0")
        let weighted = symbol.weight(.bold)

        XCTAssertEqual(weighted.weight, .bold)
        XCTAssertEqual(weighted.weight?.strokeWidthMultiplier, 1.5)
    }

    func testSymbolRenderingMode() {
        let symbol = Symbol(name: "test", category: "test", pathData: "M 0 0")
        let hierarchical = symbol.symbolRenderingMode(.hierarchical)

        XCTAssertEqual(hierarchical.renderingMode, .hierarchical)
    }

    func testSymbolAccessibilityLabel() {
        let symbol = Symbol(name: "test", category: "test", pathData: "M 0 0")
        let labeled = symbol.accessibilityLabel("Test Icon")

        XCTAssertEqual(labeled.accessibilityLabel, "Test Icon")
    }

    func testSymbolWeightValues() {
        let weights: [Symbol.Weight] = [
            .ultraLight, .thin, .light, .regular,
            .medium, .semibold, .bold, .heavy, .black
        ]

        let expectedMultipliers: [Double] = [
            0.5, 0.7, 0.85, 1.0, 1.15, 1.3, 1.5, 1.7, 2.0
        ]

        for (weight, expected) in zip(weights, expectedMultipliers) {
            XCTAssertEqual(weight.strokeWidthMultiplier, expected,
                          "Weight \(weight) should have multiplier \(expected)")
        }
    }

    // MARK: - Registry Tests

    func testRegistryContainsBuiltInSymbols() {
        let registry = SymbolRegistry.shared

        // Test that registry has symbols
        XCTAssertGreaterThan(registry.count, 0, "Registry should contain built-in symbols")

        // Test specific symbols exist
        XCTAssertNotNil(registry.lookup(name: "circle"))
        XCTAssertNotNil(registry.lookup(name: "heart"))
        XCTAssertNotNil(registry.lookup(name: "star"))
    }

    func testRegistryLookup() {
        let registry = SymbolRegistry.shared

        // Test direct lookup
        let circle = registry.lookup(name: "circle")
        XCTAssertNotNil(circle)
        XCTAssertEqual(circle?.name, "circle")

        // Test missing symbol
        let missing = registry.lookup(name: "nonexistent.symbol")
        XCTAssertNil(missing)
    }

    func testRegistryAliasLookup() {
        let registry = SymbolRegistry.shared

        // Test SF Symbol alias
        let heart = registry.lookupWithAlias(name: "heart.fill")
        XCTAssertNotNil(heart)

        // Test that direct name also works
        let circle = registry.lookupWithAlias(name: "circle")
        XCTAssertNotNil(circle)
    }

    func testCustomSymbolRegistration() {
        let registry = SymbolRegistry.shared

        let customSymbol = Symbol(
            name: "custom.test.symbol",
            category: "test",
            pathData: "M 0.5 0.5 L 1 1"
        )

        registry.register(customSymbol)

        let retrieved = registry.lookup(name: "custom.test.symbol")
        XCTAssertNotNil(retrieved)
        XCTAssertEqual(retrieved?.name, "custom.test.symbol")

        // Clean up
        registry.unregister(name: "custom.test.symbol")
    }

    func testSymbolUnregistration() {
        let registry = SymbolRegistry.shared

        let symbol = Symbol(name: "temp.symbol", category: "test", pathData: "M 0 0")
        registry.register(symbol)

        XCTAssertTrue(registry.contains(name: "temp.symbol"))

        let unregistered = registry.unregister(name: "temp.symbol")
        XCTAssertNotNil(unregistered)
        XCTAssertFalse(registry.contains(name: "temp.symbol"))
    }

    func testRegistryCategoryFiltering() {
        let registry = SymbolRegistry.shared

        let shapesSymbols = registry.symbols(in: Symbol.Category.shapes)
        XCTAssertGreaterThan(shapesSymbols.count, 0, "Should have shape symbols")

        let arrowsSymbols = registry.symbols(in: Symbol.Category.arrows)
        XCTAssertGreaterThan(arrowsSymbols.count, 0, "Should have arrow symbols")
    }

    func testRegistryAllCategories() {
        let registry = SymbolRegistry.shared
        let categories = registry.allCategories()

        XCTAssertTrue(categories.contains(Symbol.Category.shapes))
        XCTAssertTrue(categories.contains(Symbol.Category.arrows))
        XCTAssertTrue(categories.contains(Symbol.Category.communication))
    }

    func testRegistrySearch() {
        let registry = SymbolRegistry.shared

        let circleResults = registry.search(query: "circle")
        XCTAssertGreaterThan(circleResults.count, 0, "Should find symbols with 'circle'")

        let allResults = circleResults.filter { $0.name.contains("circle") }
        XCTAssertEqual(circleResults.count, allResults.count, "All results should contain 'circle'")
    }

    func testRegistryPrefixSearch() {
        let registry = SymbolRegistry.shared

        let arrowSymbols = registry.symbols(withPrefix: "arrow.")
        XCTAssertGreaterThan(arrowSymbols.count, 0, "Should find arrow symbols")

        for symbol in arrowSymbols {
            XCTAssertTrue(symbol.name.hasPrefix("arrow."), "Symbol should start with 'arrow.'")
        }
    }

    func testRegistryBatchRegistration() {
        let registry = SymbolRegistry.shared

        let symbols = [
            Symbol(name: "batch.1", category: "test", pathData: "M 0 0"),
            Symbol(name: "batch.2", category: "test", pathData: "M 0 0"),
            Symbol(name: "batch.3", category: "test", pathData: "M 0 0")
        ]

        registry.register(symbols)

        XCTAssertTrue(registry.contains(name: "batch.1"))
        XCTAssertTrue(registry.contains(name: "batch.2"))
        XCTAssertTrue(registry.contains(name: "batch.3"))

        // Clean up
        registry.unregister(name: "batch.1")
        registry.unregister(name: "batch.2")
        registry.unregister(name: "batch.3")
    }

    func testRegistryAliasRegistration() {
        let registry = SymbolRegistry.shared

        let symbol = Symbol(name: "test.original", category: "test", pathData: "M 0 0")
        registry.register(symbol)
        registry.registerAlias("test.alias", target: "test.original")

        let viaAlias = registry.lookupWithAlias(name: "test.alias")
        XCTAssertNotNil(viaAlias)
        XCTAssertEqual(viaAlias?.name, "test.original")

        // Clean up
        registry.unregister(name: "test.original")
    }

    // MARK: - Built-in Symbol Tests

    func testBuiltInShapeSymbols() {
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
            XCTAssertNotNil(symbol, "Symbol '\(name)' should exist")
            XCTAssertEqual(symbol?.category, Symbol.Category.shapes)
        }
    }

    func testBuiltInArrowSymbols() {
        let registry = SymbolRegistry.shared

        let arrowNames = [
            "arrow.up", "arrow.down", "arrow.left", "arrow.right",
            "arrow.clockwise", "arrow.counterclockwise",
            "chevron.up", "chevron.down", "chevron.left", "chevron.right"
        ]

        for name in arrowNames {
            let symbol = registry.lookup(name: name)
            XCTAssertNotNil(symbol, "Symbol '\(name)' should exist")
            XCTAssertEqual(symbol?.category, Symbol.Category.arrows)
        }
    }

    func testBuiltInCommunicationSymbols() {
        let registry = SymbolRegistry.shared

        let commNames = [
            "envelope", "envelope.fill",
            "phone", "phone.fill",
            "message", "message.fill",
            "bell", "bell.fill"
        ]

        for name in commNames {
            let symbol = registry.lookup(name: name)
            XCTAssertNotNil(symbol, "Symbol '\(name)' should exist")
            XCTAssertEqual(symbol?.category, Symbol.Category.communication)
        }
    }

    func testBuiltInMediaSymbols() {
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
            XCTAssertNotNil(symbol, "Symbol '\(name)' should exist")
            XCTAssertEqual(symbol?.category, Symbol.Category.media)
        }
    }

    func testBuiltInActionSymbols() {
        let registry = SymbolRegistry.shared

        let actionNames = [
            "plus", "minus", "xmark", "checkmark",
            "plus.circle", "minus.circle", "xmark.circle", "checkmark.circle",
            "trash", "trash.fill", "gear"
        ]

        for name in actionNames {
            let symbol = registry.lookup(name: name)
            XCTAssertNotNil(symbol, "Symbol '\(name)' should exist")
            XCTAssertEqual(symbol?.category, Symbol.Category.actions)
        }
    }

    func testBuiltInStatusSymbols() {
        let registry = SymbolRegistry.shared

        let statusNames = [
            "info.circle", "info.circle.fill",
            "exclamationmark.triangle", "exclamationmark.triangle.fill",
            "exclamationmark.circle", "exclamationmark.circle.fill",
            "questionmark.circle", "questionmark.circle.fill"
        ]

        for name in statusNames {
            let symbol = registry.lookup(name: name)
            XCTAssertNotNil(symbol, "Symbol '\(name)' should exist")
            XCTAssertEqual(symbol?.category, Symbol.Category.status)
        }
    }

    func testBuiltInNavigationSymbols() {
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
            XCTAssertNotNil(symbol, "Symbol '\(name)' should exist")
            XCTAssertEqual(symbol?.category, Symbol.Category.navigation)
        }
    }

    // MARK: - SF Symbol Compatibility Tests

    func testSFSymbolCompatibility() {
        let registry = SymbolRegistry.shared

        // Test that common SF Symbol names are aliased
        let sfSymbolNames = [
            "circle.fill", "heart", "star.fill",
            "arrow.up", "envelope", "play.fill",
            "plus.circle", "checkmark", "house"
        ]

        for name in sfSymbolNames {
            let symbol = Symbol.systemName(name)
            XCTAssertNotNil(symbol, "SF Symbol '\(name)' should be available")
        }
    }

    func testStaticBuiltInLookup() {
        let circle = Symbol.builtIn("circle")
        XCTAssertNotNil(circle)
        XCTAssertEqual(circle?.name, "circle")

        let missing = Symbol.builtIn("nonexistent")
        XCTAssertNil(missing)
    }

    func testStaticSystemNameLookup() {
        let heart = Symbol.systemName("heart.fill")
        XCTAssertNotNil(heart)

        let arrow = Symbol.systemName("arrow.right")
        XCTAssertNotNil(arrow)
    }

    // MARK: - Symbol Count Tests

    func testMinimumSymbolCount() {
        let registry = SymbolRegistry.shared

        // Should have at least 50 built-in symbols as per requirements
        XCTAssertGreaterThanOrEqual(registry.count, 50,
                                   "Registry should contain at least 50 built-in symbols")
    }

    func testCategoryDistribution() {
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
            XCTAssertGreaterThan(count, 0, "Category '\(category)' should have symbols")
        }
    }

    // MARK: - Symbol Identifiable Tests

    func testSymbolIdentifiable() {
        let symbol = Symbol(name: "test.id", category: "test", pathData: "M 0 0")
        XCTAssertEqual(symbol.id, symbol.name)
    }

    // MARK: - Symbol Hashable Tests

    func testSymbolHashable() {
        let symbol1 = Symbol(name: "test", category: "test", pathData: "M 0 0")
        let symbol2 = Symbol(name: "test", category: "test", pathData: "M 0 0")
        let symbol3 = Symbol(name: "other", category: "test", pathData: "M 0 0")

        XCTAssertEqual(symbol1, symbol2)
        XCTAssertNotEqual(symbol1, symbol3)
    }

    // MARK: - Convenience Extension Tests

    func testSymbolRegisterExtension() {
        let symbol = Symbol(name: "extension.test", category: "test", pathData: "M 0 0")
        symbol.register()

        let retrieved = SymbolRegistry.shared.lookup(name: "extension.test")
        XCTAssertNotNil(retrieved)

        // Clean up
        symbol.unregister()
    }
}
