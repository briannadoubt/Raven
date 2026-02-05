import Foundation

/// A registry for managing symbols available in the graphics context.
///
/// The symbol registry maintains a central collection of all available symbols,
/// both built-in and custom. It provides lookup by name, category filtering,
/// and SF Symbol name aliasing.
///
/// ## Overview
///
/// The registry is implemented as a singleton and is automatically populated
/// with built-in symbols when first accessed.
///
/// ## Registering Custom Symbols
///
/// ```swift
/// let customSymbol = Symbol(
///     name: "custom.logo",
///     category: "branding",
///     pathData: "M 0.5 0 L 1 1 L 0 1 Z"
/// )
///
/// SymbolRegistry.shared.register(customSymbol)
/// ```
///
/// ## Looking Up Symbols
///
/// ```swift
/// // Direct lookup
/// if let symbol = SymbolRegistry.shared.lookup(name: "heart") {
///     context.draw(symbol, at: point, size: 50)
/// }
///
/// // SF Symbol alias lookup
/// if let symbol = SymbolRegistry.shared.lookupWithAlias(name: "heart.fill") {
///     context.draw(symbol, at: point, size: 50)
/// }
/// ```
///
/// ## Category Filtering
///
/// ```swift
/// let arrowSymbols = SymbolRegistry.shared.symbols(in: "arrows")
/// ```
@MainActor
public final class SymbolRegistry: Sendable {
    /// The shared singleton instance
    public static let shared = SymbolRegistry()

    /// All registered symbols, keyed by name
    private var symbols: [String: Symbol]

    /// SF Symbol name aliases mapping to symbol names
    private var aliases: [String: String]

    /// Symbols organized by category
    private var categories: [String: Set<String>]

    // MARK: - Initialization

    private init() {
        self.symbols = [:]
        self.aliases = [:]
        self.categories = [:]

        // Register built-in symbols
        registerBuiltInSymbols()
    }

    // MARK: - Registration

    /// Registers a symbol in the registry.
    ///
    /// If a symbol with the same name already exists, it will be replaced.
    ///
    /// - Parameter symbol: The symbol to register.
    public func register(_ symbol: Symbol) {
        symbols[symbol.name] = symbol

        // Add to category index
        var categorySet = categories[symbol.category, default: Set<String>()]
        categorySet.insert(symbol.name)
        categories[symbol.category] = categorySet
    }

    /// Registers multiple symbols at once.
    ///
    /// - Parameter symbols: The symbols to register.
    public func register(_ symbols: [Symbol]) {
        for symbol in symbols {
            register(symbol)
        }
    }

    /// Unregisters a symbol by name.
    ///
    /// - Parameter name: The name of the symbol to unregister.
    /// - Returns: The unregistered symbol, or nil if not found.
    @discardableResult
    public func unregister(name: String) -> Symbol? {
        guard let symbol = symbols.removeValue(forKey: name) else {
            return nil
        }

        // Remove from category index
        if var categorySet = categories[symbol.category] {
            categorySet.remove(name)
            if categorySet.isEmpty {
                categories.removeValue(forKey: symbol.category)
            } else {
                categories[symbol.category] = categorySet
            }
        }

        return symbol
    }

    /// Registers an SF Symbol name alias.
    ///
    /// This allows SF Symbol names to be mapped to available symbols.
    ///
    /// - Parameters:
    ///   - alias: The SF Symbol name.
    ///   - target: The actual symbol name in the registry.
    public func registerAlias(_ alias: String, target: String) {
        aliases[alias] = target
    }

    /// Registers multiple aliases at once.
    ///
    /// - Parameter aliasMap: A dictionary mapping alias names to target symbol names.
    public func registerAliases(_ aliasMap: [String: String]) {
        for (alias, target) in aliasMap {
            registerAlias(alias, target: target)
        }
    }

    // MARK: - Lookup

    /// Looks up a symbol by name.
    ///
    /// - Parameter name: The symbol name.
    /// - Returns: The symbol if found, nil otherwise.
    public func lookup(name: String) -> Symbol? {
        return symbols[name]
    }

    /// Looks up a symbol by name with alias support.
    ///
    /// This first checks for a direct match, then checks aliases.
    ///
    /// - Parameter name: The symbol name or alias.
    /// - Returns: The symbol if found, nil otherwise.
    public func lookupWithAlias(name: String) -> Symbol? {
        // Try direct lookup first
        if let symbol = symbols[name] {
            return symbol
        }

        // Try alias lookup
        if let targetName = aliases[name] {
            return symbols[targetName]
        }

        return nil
    }

    /// Returns all symbols in a specific category.
    ///
    /// - Parameter category: The category name.
    /// - Returns: An array of symbols in the category.
    public func symbols(in category: String) -> [Symbol] {
        guard let symbolNames = categories[category] else {
            return []
        }

        return symbolNames.compactMap { symbols[$0] }
    }

    /// Returns all registered symbols.
    ///
    /// - Returns: An array of all symbols.
    public func allSymbols() -> [Symbol] {
        return Array(symbols.values)
    }

    /// Returns all available categories.
    ///
    /// - Returns: An array of category names.
    public func allCategories() -> [String] {
        return Array(categories.keys)
    }

    /// Returns the number of registered symbols.
    public var count: Int {
        return symbols.count
    }

    /// Returns whether the registry contains a symbol with the given name.
    ///
    /// - Parameter name: The symbol name to check.
    /// - Returns: True if the symbol exists, false otherwise.
    public func contains(name: String) -> Bool {
        return symbols[name] != nil
    }

    // MARK: - Search

    /// Searches for symbols matching a query string.
    ///
    /// This performs a case-insensitive substring search on symbol names.
    ///
    /// - Parameter query: The search query.
    /// - Returns: An array of matching symbols.
    public func search(query: String) -> [Symbol] {
        let lowercaseQuery = query.lowercased()
        return symbols.values.filter { symbol in
            symbol.name.lowercased().contains(lowercaseQuery)
        }
    }

    /// Searches for symbols with names starting with a prefix.
    ///
    /// - Parameter prefix: The name prefix to match.
    /// - Returns: An array of matching symbols.
    public func symbols(withPrefix prefix: String) -> [Symbol] {
        return symbols.values.filter { symbol in
            symbol.name.hasPrefix(prefix)
        }
    }

    // MARK: - Built-in Symbols

    private func registerBuiltInSymbols() {
        // This will be populated by BuiltInSymbols.swift
        // We register all built-in symbols here
        BuiltInSymbols.registerAll(in: self)
    }

    // MARK: - Debug

    /// Returns a debug description of the registry state.
    public var debugDescription: String {
        var lines = ["SymbolRegistry:"]
        lines.append("  Symbols: \(symbols.count)")
        lines.append("  Aliases: \(aliases.count)")
        lines.append("  Categories: \(categories.count)")

        for category in categories.keys.sorted() {
            let count = categories[category]?.count ?? 0
            lines.append("    \(category): \(count) symbols")
        }

        return lines.joined(separator: "\n")
    }
}

// MARK: - Convenience Extensions

extension Symbol {
    /// Registers this symbol in the shared registry.
    public func register() {
        SymbolRegistry.shared.register(self)
    }

    /// Unregisters this symbol from the shared registry.
    @discardableResult
    public func unregister() -> Symbol? {
        return SymbolRegistry.shared.unregister(name: name)
    }
}
