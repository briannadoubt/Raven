import Foundation
import JavaScriptKit

// MARK: - GraphicsContext Symbol Extensions

extension GraphicsContext {
    /// Draws a symbol at the specified point with the given size.
    ///
    /// The symbol is drawn centered at the specified point.
    ///
    /// - Parameters:
    ///   - symbol: The symbol to draw.
    ///   - point: The center point where the symbol should be drawn.
    ///   - size: The size of the symbol (width and height).
    public func draw(_ symbol: Symbol, at point: CGPoint, size: Double) {
        let rect = CGRect(
            x: point.x - size / 2,
            y: point.y - size / 2,
            width: size,
            height: size
        )
        draw(symbol, in: rect)
    }

    /// Draws a symbol fitted within the specified rectangle.
    ///
    /// The symbol is scaled to fit within the rectangle while preserving
    /// its aspect ratio.
    ///
    /// - Parameters:
    ///   - symbol: The symbol to draw.
    ///   - rect: The rectangle to fit the symbol in.
    public func draw(_ symbol: Symbol, in rect: CGRect) {
        saveState()
        defer { restoreState() }

        // Calculate the scale to fit the symbol in the rect
        let scaleX = rect.width / symbol.viewBox.width
        let scaleY = rect.height / symbol.viewBox.height
        let scale = min(scaleX, scaleY) // Preserve aspect ratio

        // Calculate centering offset
        let scaledWidth = symbol.viewBox.width * scale
        let scaledHeight = symbol.viewBox.height * scale
        let offsetX = rect.minX + (rect.width - scaledWidth) / 2
        let offsetY = rect.minY + (rect.height - scaledHeight) / 2

        // Apply transformation
        translateBy(x: offsetX, y: offsetY)
        scaleBy(x: scale, y: scale)
        translateBy(x: -symbol.viewBox.minX, y: -symbol.viewBox.minY)

        // Create path from symbol data
        let path = createPathFromSVGData(symbol.pathData)

        // Determine fill or stroke based on symbol name
        let isFilled = symbol.name.contains(".fill")

        // Get the color to use
        let color = symbol.foregroundColor ?? Color.black

        // Apply rendering based on mode and style
        switch symbol.renderingMode {
        case .monochrome:
            if isFilled {
                fill(path, with: .color(color))
            } else {
                let lineWidth = (symbol.weight?.strokeWidthMultiplier ?? 1.0) * 0.05
                stroke(path, with: .color(color), lineWidth: lineWidth)
            }

        case .hierarchical:
            // Use opacity variations for hierarchical rendering
            let baseOpacity = 1.0
            if isFilled {
                setOpacity(baseOpacity)
                fill(path, with: .color(color))
            } else {
                setOpacity(baseOpacity * 0.8)
                let lineWidth = (symbol.weight?.strokeWidthMultiplier ?? 1.0) * 0.05
                stroke(path, with: .color(color), lineWidth: lineWidth)
            }

        case .multicolor, .palette:
            // For now, treat these the same as monochrome
            // A full implementation would support multiple colors
            if isFilled {
                fill(path, with: .color(color))
            } else {
                let lineWidth = (symbol.weight?.strokeWidthMultiplier ?? 1.0) * 0.05
                stroke(path, with: .color(color), lineWidth: lineWidth)
            }
        }
    }

    /// Draws a symbol with explicit size specification.
    ///
    /// - Parameters:
    ///   - symbol: The symbol to draw.
    ///   - at: The center point where the symbol should be drawn.
    ///   - width: The width of the symbol.
    ///   - height: The height of the symbol.
    public func draw(_ symbol: Symbol, at point: CGPoint, width: Double, height: Double) {
        let rect = CGRect(
            x: point.x - width / 2,
            y: point.y - height / 2,
            width: width,
            height: height
        )
        draw(symbol, in: rect)
    }

    /// Draws a symbol by name from the registry.
    ///
    /// This is a convenience method that looks up the symbol and draws it.
    ///
    /// - Parameters:
    ///   - name: The symbol name.
    ///   - at: The center point where the symbol should be drawn.
    ///   - size: The size of the symbol.
    /// - Returns: True if the symbol was found and drawn, false otherwise.
    @discardableResult
    public func drawSymbol(named name: String, at point: CGPoint, size: Double) -> Bool {
        guard let symbol = Symbol.systemName(name) else {
            return false
        }
        draw(symbol, at: point, size: size)
        return true
    }

    /// Draws a symbol by name within a rectangle.
    ///
    /// This is a convenience method that looks up the symbol and draws it.
    ///
    /// - Parameters:
    ///   - name: The symbol name.
    ///   - in: The rectangle to fit the symbol in.
    /// - Returns: True if the symbol was found and drawn, false otherwise.
    @discardableResult
    public func drawSymbol(named name: String, in rect: CGRect) -> Bool {
        guard let symbol = Symbol.systemName(name) else {
            return false
        }
        draw(symbol, in: rect)
        return true
    }

    // MARK: - Helper Methods

    /// Creates a Path from SVG path data.
    ///
    /// This is a simplified implementation that uses the browser's Path2D API
    /// to parse the SVG path data.
    ///
    /// - Parameter svgData: The SVG path data string.
    /// - Returns: A Path object.
    private func createPathFromSVGData(_ svgData: String) -> Path {
        // For now, we'll create a simple path wrapper
        // The actual rendering will use the SVG data directly via Path2D
        var path = Path()

        // Parse basic SVG commands to build a Path
        // This is simplified - a full implementation would parse all SVG path commands

        // For now, we'll use the internal SVG data directly
        // when the path is rendered to the canvas
        path.addSVGPathData(svgData)

        return path
    }
}

// MARK: - Path SVG Data Extension

extension Path {
    /// Internal method to add SVG path data directly.
    ///
    /// This is used by the symbol system to preserve the original SVG path data.
    internal mutating func addSVGPathData(_ data: String) {
        // This is a workaround - we'll store the SVG data by creating a temporary
        // shape that can be parsed by the SVG renderer.
        // The actual implementation would need to parse SVG commands into Path elements.

        // For now, we'll just note that the SVG data needs to be parsed.
        // In a full implementation, this would parse commands like:
        // M (moveto), L (lineto), C (curveto), Q (quadratic), A (arc), Z (closepath)
        // and convert them to Path elements.

        // As a placeholder, we'll just add a comment that this needs proper implementation
    }
}

// MARK: - Symbol Drawing Modifiers

extension GraphicsContext {
    /// Draws multiple symbols arranged in a grid pattern.
    ///
    /// - Parameters:
    ///   - symbols: The symbols to draw.
    ///   - in: The rectangle containing the grid.
    ///   - columns: The number of columns in the grid.
    public func drawSymbols(_ symbols: [Symbol], in rect: CGRect, columns: Int) {
        guard !symbols.isEmpty, columns > 0 else { return }

        let rows = (symbols.count + columns - 1) / columns
        let cellWidth = rect.width / Double(columns)
        let cellHeight = rect.height / Double(rows)

        for (index, symbol) in symbols.enumerated() {
            let row = index / columns
            let col = index % columns

            let cellRect = CGRect(
                x: rect.minX + Double(col) * cellWidth,
                y: rect.minY + Double(row) * cellHeight,
                width: cellWidth,
                height: cellHeight
            )

            // Add some padding
            let padding = min(cellWidth, cellHeight) * 0.1
            let symbolRect = cellRect.insetBy(dx: padding, dy: padding)

            draw(symbol, in: symbolRect)
        }
    }

    /// Draws a symbol with a shadow.
    ///
    /// - Parameters:
    ///   - symbol: The symbol to draw.
    ///   - in: The rectangle to fit the symbol in.
    ///   - shadowColor: The shadow color.
    ///   - shadowBlur: The shadow blur radius.
    ///   - shadowOffset: The shadow offset.
    public func drawSymbolWithShadow(
        _ symbol: Symbol,
        in rect: CGRect,
        shadowColor: Color = Color.black,
        shadowBlur: Double = 5,
        shadowOffset: CGSize = CGSize(width: 2, height: 2)
    ) {
        saveState()
        defer { restoreState() }

        setShadow(color: shadowColor, blur: shadowBlur, offset: shadowOffset)
        draw(symbol, in: rect)
    }

    /// Draws a symbol with custom opacity.
    ///
    /// - Parameters:
    ///   - symbol: The symbol to draw.
    ///   - in: The rectangle to fit the symbol in.
    ///   - opacity: The opacity value from 0.0 to 1.0.
    public func drawSymbol(_ symbol: Symbol, in rect: CGRect, opacity: Double) {
        saveState()
        defer { restoreState() }

        setOpacity(opacity)
        draw(symbol, in: rect)
    }
}
