import Foundation

/// The fill style for shapes.
///
/// `FillStyle` determines how a shape's interior is filled when multiple
/// overlapping subpaths exist. This is particularly important for complex
/// shapes with holes or self-intersecting paths.
///
/// ## Fill Rules
///
/// SVG and CSS support two fill rules:
///
/// - **Non-zero**: This is the default rule. A point is considered inside
///   the shape if a ray from the point to infinity crosses a non-zero number
///   of path segments (counting clockwise as +1 and counterclockwise as -1).
///
/// - **Even-odd**: A point is considered inside the shape if a ray from the
///   point to infinity crosses an odd number of path segments.
///
/// ## Usage
///
/// Fill styles are commonly used with clip shapes to control how complex
/// shapes define their interior:
///
/// ```swift
/// // Use non-zero fill rule (default)
/// Image("photo")
///     .clipShape(StarShape(), style: FillStyle(rule: .nonZero))
///
/// // Use even-odd fill rule for shapes with holes
/// Image("photo")
///     .clipShape(DonutShape(), style: FillStyle(rule: .evenOdd))
/// ```
///
/// ## Topics
///
/// ### Creating a Fill Style
/// - ``init(rule:antialiased:)``
///
/// ### Fill Rules
/// - ``FillRule``
/// - ``rule``
///
/// ### Antialiasing
/// - ``antialiased``
///
/// - Note: In Raven, fill styles are rendered using SVG fill-rule attributes,
///   which are well-supported across all modern browsers.
public struct FillStyle: Hashable, Sendable {
    /// The rule for determining the interior of a path.
    public enum FillRule: Hashable, Sendable {
        /// The non-zero winding rule.
        ///
        /// This is the default rule. Points are inside the shape if the
        /// winding number (sum of path crossings) is non-zero.
        ///
        /// This rule is useful for most shapes and handles overlapping
        /// paths intuitively.
        case nonZero

        /// The even-odd rule.
        ///
        /// Points are inside the shape if the number of path crossings
        /// is odd.
        ///
        /// This rule is useful for creating shapes with holes, like
        /// donuts or stars with cutouts.
        case evenOdd
    }

    /// The fill rule for the shape.
    public var rule: FillRule

    /// Whether the shape should be antialiased.
    ///
    /// Antialiasing smooths the edges of shapes by partially filling edge
    /// pixels. This is enabled by default and usually produces better results.
    public var antialiased: Bool

    /// Creates a fill style with the specified rule and antialiasing setting.
    ///
    /// - Parameters:
    ///   - rule: The fill rule to use. Defaults to `.nonZero`.
    ///   - antialiased: Whether to antialias the shape. Defaults to `true`.
    ///
    /// ## Example
    ///
    /// ```swift
    /// // Default fill style (non-zero, antialiased)
    /// let defaultStyle = FillStyle()
    ///
    /// // Even-odd fill rule for shapes with holes
    /// let evenOddStyle = FillStyle(rule: .evenOdd)
    ///
    /// // Non-antialiased for pixel-perfect graphics
    /// let sharpStyle = FillStyle(antialiased: false)
    /// ```
    public init(rule: FillRule = .nonZero, antialiased: Bool = true) {
        self.rule = rule
        self.antialiased = antialiased
    }

    /// The SVG fill-rule attribute value.
    ///
    /// This property converts the FillRule to the corresponding SVG attribute
    /// value for rendering.
    internal var svgFillRule: String {
        switch rule {
        case .nonZero:
            return "nonzero"
        case .evenOdd:
            return "evenodd"
        }
    }
}

// MARK: - Default Fill Style

extension FillStyle {
    /// The default fill style.
    ///
    /// This uses the non-zero fill rule with antialiasing enabled.
    public static let `default` = FillStyle(rule: .nonZero, antialiased: true)
}
