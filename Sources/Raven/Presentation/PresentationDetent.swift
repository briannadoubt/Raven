import Foundation

// MARK: - PresentationDetent

/// A type that represents the height of a presentation.
///
/// Use `PresentationDetent` to control the height of sheet presentations.
/// The system supports several built-in detents and allows custom heights.
///
/// ## Built-in Detents
///
/// The most common detents are:
/// - `.large`: The presentation fills the available height
/// - `.medium`: The presentation takes up approximately half the screen
///
/// ## Custom Heights
///
/// Create custom detents with specific heights or fractions:
///
/// ```swift
/// .presentationDetents([
///     .height(300),           // Fixed height of 300 points
///     .fraction(0.75),        // 75% of available height
///     .large
/// ])
/// ```
///
/// ## Custom Detents with Context
///
/// For dynamic heights based on available space:
///
/// ```swift
/// .presentationDetents([
///     .custom { context in
///         context.maxDetentValue * 0.6
///     }
/// ])
/// ```
///
/// - Note: Multiple detents allow users to resize sheets by dragging.
///   The first detent in the array is the initial size.
public struct PresentationDetent: Sendable, Hashable {
    // MARK: - Internal Storage

    /// The type of detent
    internal enum DetentType: Sendable, Hashable {
        case large
        case medium
        case height(Double)
        case fraction(Double)
        case custom(String) // Store identifier for custom detents
    }

    /// The detent type
    internal let type: DetentType

    /// Custom resolver function (not included in Hashable/Equatable)
    internal let resolver: (@Sendable (Context) -> Double)?

    // MARK: - Initialization

    /// Internal initializer
    private init(type: DetentType, resolver: (@Sendable (Context) -> Double)? = nil) {
        self.type = type
        self.resolver = resolver
    }

    // MARK: - Built-in Detents

    /// A detent that sizes the presentation to fill the available height.
    ///
    /// Use this detent when you want the sheet to take up the maximum
    /// available vertical space. This is typically the full screen height
    /// minus safe area insets.
    ///
    /// Example:
    /// ```swift
    /// .sheet(isPresented: $showSheet) {
    ///     SheetContent()
    /// }
    /// .presentationDetents([.large])
    /// ```
    public static let large = PresentationDetent(type: .large)

    /// A detent that sizes the presentation to approximately half the available height.
    ///
    /// The medium detent provides a comfortable size for many sheet presentations,
    /// allowing content above the sheet to remain partially visible.
    ///
    /// Example:
    /// ```swift
    /// .sheet(isPresented: $showSheet) {
    ///     SheetContent()
    /// }
    /// .presentationDetents([.medium, .large])
    /// ```
    public static let medium = PresentationDetent(type: .medium)

    // MARK: - Custom Detents

    /// Creates a detent with a fixed height.
    ///
    /// Use this method to specify an exact height for your sheet presentation.
    /// The height is specified in points.
    ///
    /// Example:
    /// ```swift
    /// .presentationDetents([
    ///     .height(250),  // 250 points tall
    ///     .large
    /// ])
    /// ```
    ///
    /// - Parameter height: The fixed height in points.
    /// - Returns: A detent with the specified height.
    ///
    /// - Note: If the specified height exceeds the available space,
    ///   the sheet will be sized to the maximum available height.
    public static func height(_ height: Double) -> PresentationDetent {
        PresentationDetent(type: .height(height))
    }

    /// Creates a detent as a fraction of the available height.
    ///
    /// Use this method to size your sheet relative to the available space.
    /// The fraction should be between 0.0 and 1.0, where 1.0 represents
    /// the full available height.
    ///
    /// Example:
    /// ```swift
    /// .presentationDetents([
    ///     .fraction(0.25),  // 25% of available height
    ///     .fraction(0.75),  // 75% of available height
    ///     .large            // 100% of available height
    /// ])
    /// ```
    ///
    /// - Parameter fraction: The fraction of available height (0.0 to 1.0).
    /// - Returns: A detent with the specified fractional height.
    ///
    /// - Note: Fractions less than 0.0 are treated as 0.0, and fractions
    ///   greater than 1.0 are treated as 1.0.
    public static func fraction(_ fraction: Double) -> PresentationDetent {
        PresentationDetent(type: .fraction(fraction))
    }

    /// Creates a custom detent with a resolver function.
    ///
    /// Use this method to create detents with dynamic heights that depend
    /// on the presentation context. The resolver receives a `Context` object
    /// with information about the available space.
    ///
    /// Example:
    /// ```swift
    /// .presentationDetents([
    ///     .custom { context in
    ///         // Size to 60% of maximum height
    ///         context.maxDetentValue * 0.6
    ///     },
    ///     .large
    /// ])
    /// ```
    ///
    /// - Parameters:
    ///   - identifier: A unique identifier for this custom detent.
    ///   - resolver: A closure that computes the detent height from the context.
    /// - Returns: A custom detent.
    ///
    /// - Note: The identifier is used for hashing and equality comparisons.
    ///   Detents with the same identifier are considered equal.
    public static func custom<ID: Hashable>(
        _ identifier: ID,
        resolver: @escaping @Sendable (Context) -> Double
    ) -> PresentationDetent {
        let idString = String(describing: identifier)
        return PresentationDetent(
            type: .custom(idString),
            resolver: resolver
        )
    }

    /// Creates a custom detent with an anonymous identifier.
    ///
    /// This is a convenience overload for custom detents when you don't need
    /// to specify an explicit identifier.
    ///
    /// Example:
    /// ```swift
    /// .presentationDetents([
    ///     .custom { context in
    ///         min(context.maxDetentValue * 0.6, 400)
    ///     }
    /// ])
    /// ```
    ///
    /// - Parameter resolver: A closure that computes the detent height from the context.
    /// - Returns: A custom detent.
    ///
    /// - Note: Anonymous custom detents use a UUID for their identifier,
    ///   so each call creates a unique detent instance.
    public static func custom(
        resolver: @escaping @Sendable (Context) -> Double
    ) -> PresentationDetent {
        custom(UUID(), resolver: resolver)
    }

    // MARK: - Hashable

    public func hash(into hasher: inout Hasher) {
        hasher.combine(type)
    }

    public static func == (lhs: PresentationDetent, rhs: PresentationDetent) -> Bool {
        lhs.type == rhs.type
    }
}

// MARK: - PresentationDetent.Context

extension PresentationDetent {
    /// Context information for custom detent resolvers.
    ///
    /// The context provides information about the available space for
    /// presentations, allowing custom detents to compute appropriate heights.
    ///
    /// ## Available Properties
    ///
    /// - `maxDetentValue`: The maximum available height for presentations
    ///
    /// Example:
    /// ```swift
    /// .custom { context in
    ///     // Use 80% of available space, but cap at 500 points
    ///     min(context.maxDetentValue * 0.8, 500)
    /// }
    /// ```
    public struct Context: Sendable {
        /// The maximum height available for presentations.
        ///
        /// This value represents the full available vertical space for the
        /// presentation, typically the screen height minus safe area insets.
        ///
        /// Use this value to compute relative heights:
        /// ```swift
        /// .custom { context in
        ///     context.maxDetentValue * 0.6 // 60% of available space
        /// }
        /// ```
        public let maxDetentValue: Double

        /// Creates a new context with the specified maximum detent value.
        ///
        /// - Parameter maxDetentValue: The maximum available height.
        public init(maxDetentValue: Double) {
            self.maxDetentValue = maxDetentValue
        }
    }
}

// MARK: - Resolved Height Calculation

extension PresentationDetent {
    /// Resolves this detent to a concrete height value.
    ///
    /// This internal method converts the detent specification into an actual
    /// height in points, given the available space.
    ///
    /// - Parameter context: The context providing maximum available height.
    /// - Returns: The resolved height in points.
    internal func resolvedHeight(in context: Context) -> Double {
        switch type {
        case .large:
            return context.maxDetentValue
        case .medium:
            return context.maxDetentValue * 0.5
        case .height(let h):
            return min(h, context.maxDetentValue)
        case .fraction(let f):
            let clampedFraction = max(0.0, min(1.0, f))
            return context.maxDetentValue * clampedFraction
        case .custom:
            if let resolver = resolver {
                return resolver(context)
            }
            return context.maxDetentValue
        }
    }
}
