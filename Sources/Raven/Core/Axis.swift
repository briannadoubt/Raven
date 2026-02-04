import Foundation

// MARK: - Axis Types

/// An enumeration that represents a coordinate axis.
///
/// Use axis values to specify which dimensions should be affected by layout modifiers
/// like `containerRelativeFrame()` and scroll behavior modifiers.
///
/// Example:
/// ```swift
/// // Apply to horizontal axis only
/// .containerRelativeFrame(.horizontal) { width, _ in width * 0.8 }
///
/// // Apply to both axes
/// .scrollBounceBehavior(.always, axes: [.horizontal, .vertical])
/// ```
public enum Axis: Sendable, Hashable, CaseIterable {
    /// The horizontal axis (width).
    case horizontal

    /// The vertical axis (height).
    case vertical

    /// A set of axes that can be used together.
    public struct Set: OptionSet, Sendable, Hashable {
        public let rawValue: Int

        public init(rawValue: Int) {
            self.rawValue = rawValue
        }

        /// The horizontal axis.
        public static let horizontal = Set(rawValue: 1 << 0)

        /// The vertical axis.
        public static let vertical = Set(rawValue: 1 << 1)

        /// Both horizontal and vertical axes.
        public static let all: Set = [.horizontal, .vertical]
    }
}
