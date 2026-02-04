import Foundation

/// Extensions to support Canvas API functionality.
///
/// These extensions provide convenience methods and computed properties
/// for working with canvas drawing.

// MARK: - Color Extensions

extension Color {
    /// Creates a grayscale color.
    ///
    /// - Parameters:
    ///   - white: The grayscale value from 0.0 (black) to 1.0 (white).
    ///   - opacity: The opacity from 0.0 (transparent) to 1.0 (opaque).
    /// - Returns: A grayscale color.
    public init(white: Double, opacity: Double = 1.0) {
        self.init(red: white, green: white, blue: white, opacity: opacity)
    }
}

// MARK: - FillStyle Extensions

extension FillStyle {
    /// Whether this fill style uses the even-odd fill rule.
    internal var isEOFilled: Bool {
        rule == .evenOdd
    }
}

// MARK: - CGSize Extensions

extension CGSize {
    /// Creates a size with equal width and height.
    ///
    /// - Parameter value: The value to use for both width and height.
    public init(square value: Double) {
        self.init(width: value, height: value)
    }

    /// Returns a scaled version of this size.
    ///
    /// - Parameter factor: The scale factor.
    /// - Returns: A scaled size.
    public func scaled(by factor: Double) -> CGSize {
        CGSize(width: width * factor, height: height * factor)
    }

    /// Returns the aspect ratio (width / height).
    ///
    /// - Returns: The aspect ratio, or 0 if height is 0.
    public var aspectRatio: Double {
        height > 0 ? width / height : 0
    }
}

// MARK: - CGPoint Extensions

extension CGPoint {
    /// Returns the distance between two points.
    ///
    /// - Parameter other: The other point.
    /// - Returns: The distance.
    public func distance(to other: CGPoint) -> Double {
        let dx = other.x - x
        let dy = other.y - y
        return sqrt(dx * dx + dy * dy)
    }

    /// Returns a point offset by the specified amounts.
    ///
    /// - Parameters:
    ///   - dx: The horizontal offset.
    ///   - dy: The vertical offset.
    /// - Returns: The offset point.
    public func offset(by dx: Double, _ dy: Double) -> CGPoint {
        CGPoint(x: x + dx, y: y + dy)
    }

    /// Returns the midpoint between two points.
    ///
    /// - Parameter other: The other point.
    /// - Returns: The midpoint.
    public func midpoint(to other: CGPoint) -> CGPoint {
        CGPoint(x: (x + other.x) / 2, y: (y + other.y) / 2)
    }
}

// MARK: - CGRect Extensions

extension CGRect {
    /// The center point of the rectangle.
    public var center: CGPoint {
        CGPoint(x: midX, y: midY)
    }

    /// Creates a rectangle centered at a point with the specified size.
    ///
    /// - Parameters:
    ///   - center: The center point.
    ///   - size: The size of the rectangle.
    public init(center: CGPoint, size: CGSize) {
        self.init(
            x: center.x - size.width / 2,
            y: center.y - size.height / 2,
            width: size.width,
            height: size.height
        )
    }


    /// Returns whether this rectangle contains a point.
    ///
    /// - Parameter point: The point to test.
    /// - Returns: True if the point is inside the rectangle.
    public func contains(_ point: CGPoint) -> Bool {
        point.x >= minX && point.x <= maxX && point.y >= minY && point.y <= maxY
    }

    /// Returns whether this rectangle intersects another rectangle.
    ///
    /// - Parameter other: The other rectangle.
    /// - Returns: True if the rectangles intersect.
    public func intersects(_ other: CGRect) -> Bool {
        !(maxX < other.minX || minX > other.maxX || maxY < other.minY || minY > other.maxY)
    }
}
