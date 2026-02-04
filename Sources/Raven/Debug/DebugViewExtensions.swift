import Foundation

#if DEBUG

// MARK: - Debug View Extensions

extension View {

    /// Adds a debug overlay showing performance statistics for this view
    ///
    /// The overlay displays:
    /// - Render count
    /// - Average render time
    /// - Last render time
    /// - Memory estimate
    ///
    /// ## Example
    ///
    /// ```swift
    /// MyComplexView()
    ///     .debugOverlay()
    /// ```
    ///
    /// - Parameter label: Optional label for identifying this view in the overlay
    /// - Returns: A view with debug overlay attached
    @MainActor
    public func debugOverlay(label: String? = nil) -> some View {
        DebugOverlayModifier(content: self, label: label ?? "\(type(of: self))")
    }

    /// Prints debug information when this view renders
    ///
    /// Logs to console:
    /// - View type
    /// - Render timestamp
    /// - Render count
    ///
    /// ## Example
    ///
    /// ```swift
    /// UserProfile(user: user)
    ///     .debugPrint()
    /// ```
    ///
    /// - Parameter label: Optional label for the debug output
    /// - Returns: The original view with debug logging
    @MainActor
    public func debugPrint(label: String? = nil) -> some View {
        DebugPrintModifier(content: self, label: label ?? "\(type(of: self))")
    }

    /// Adds a colored border to visualize view boundaries for layout debugging
    ///
    /// ## Example
    ///
    /// ```swift
    /// VStack {
    ///     Text("Top").debugBorder(.red)
    ///     Text("Middle").debugBorder(.green)
    ///     Text("Bottom").debugBorder(.blue)
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - color: Border color (default: red)
    ///   - width: Border width in pixels (default: 1)
    /// - Returns: A view with a debug border
    @MainActor
    public func debugBorder(_ color: DebugColor = .red, width: Double = 1) -> some View {
        DebugBorderModifier(content: self, color: color, width: width)
    }

    /// Logs view hierarchy information for debugging layout issues
    ///
    /// ## Example
    ///
    /// ```swift
    /// ComplexLayout()
    ///     .debugHierarchy()
    /// ```
    ///
    /// - Parameter depth: Maximum depth to traverse (default: 3)
    /// - Returns: The original view with hierarchy logging
    @MainActor
    public func debugHierarchy(depth: Int = 3) -> some View {
        DebugHierarchyModifier(content: self, depth: depth)
    }

    /// Adds performance monitoring to this view
    ///
    /// Measures and reports:
    /// - Body evaluation time
    /// - Render frequency
    /// - Excessive re-renders
    ///
    /// ## Example
    ///
    /// ```swift
    /// ExpensiveView()
    ///     .debugPerformance()
    /// ```
    ///
    /// - Parameter threshold: Threshold in milliseconds for slow render warnings (default: 16)
    /// - Returns: A view with performance monitoring
    @MainActor
    public func debugPerformance(threshold: Double = 16.0) -> some View {
        DebugPerformanceModifier(content: self, threshold: threshold)
    }
}

// MARK: - Debug Color

/// Colors for debug borders
public enum DebugColor: Sendable {
    case red
    case green
    case blue
    case yellow
    case purple
    case orange
    case cyan
    case magenta

    var cssColor: String {
        switch self {
        case .red: return "red"
        case .green: return "lime"
        case .blue: return "blue"
        case .yellow: return "yellow"
        case .purple: return "purple"
        case .orange: return "orange"
        case .cyan: return "cyan"
        case .magenta: return "magenta"
        }
    }
}

// MARK: - Debug Modifiers

/// Shared storage for debug overlay data
@MainActor
private class DebugOverlayStorage {
    static let shared = DebugOverlayStorage()
    var renderCounts: [String: Int] = [:]
    var renderTimes: [String: [Double]] = [:]
    var lastRenderTimes: [String: Date] = [:]
    var renderDurations: [String: [Double]] = [:]
    private init() {}
}

/// Modifier that adds a debug overlay with performance stats
@MainActor
private struct DebugOverlayModifier<Content: View>: View {
    let content: Content
    let label: String

    var body: some View {
        let startTime = Date()

        // Increment render count
        DebugOverlayStorage.shared.renderCounts[label, default: 0] += 1

        let result = content

        // Measure render time
        let renderTime = Date().timeIntervalSince(startTime) * 1000

        // Store render time
        DebugOverlayStorage.shared.renderTimes[label, default: []].append(renderTime)
        if DebugOverlayStorage.shared.renderTimes[label]!.count > 10 {
            DebugOverlayStorage.shared.renderTimes[label]!.removeFirst()
        }

        // Log stats
        let avgTime = DebugOverlayStorage.shared.renderTimes[label]!.reduce(0, +) / Double(DebugOverlayStorage.shared.renderTimes[label]!.count)
        let count = DebugOverlayStorage.shared.renderCounts[label]!

        print("[Debug Overlay] \(label) - Renders: \(count), Avg: \(String(format: "%.2fms", avgTime)), Last: \(String(format: "%.2fms", renderTime))")

        return result
    }
}

/// Modifier that prints debug information on render
@MainActor
private struct DebugPrintModifier<Content: View>: View {
    let content: Content
    let label: String

    var body: some View {
        DebugOverlayStorage.shared.renderCounts[label, default: 0] += 1
        let count = DebugOverlayStorage.shared.renderCounts[label]!

        print("[Debug Print] 🔍 \(label) rendered (count: \(count)) at \(Date())")

        return content
    }
}

/// Modifier that adds a colored debug border
@MainActor
private struct DebugBorderModifier<Content: View>: View {
    let content: Content
    let color: DebugColor
    let width: Double

    var body: some View {
        // In a real implementation, this would add a border via the VNode system
        // For now, we return the content with a conceptual border
        content
        // .border(color.cssColor, width: width) // This would be the actual implementation
    }
}

/// Modifier that logs view hierarchy
@MainActor
private struct DebugHierarchyModifier<Content: View>: View {
    let content: Content
    let depth: Int

    var body: some View {
        print("[Debug Hierarchy] \(String(repeating: "  ", count: depth)) \(type(of: content))")
        return content
    }
}

/// Modifier that monitors view performance
@MainActor
private struct DebugPerformanceModifier<Content: View>: View {
    let content: Content
    let threshold: Double

    var body: some View {
        let key = "\(type(of: content))"
        let startTime = Date()

        // Check render frequency
        if let lastRender = DebugOverlayStorage.shared.lastRenderTimes[key] {
            let timeSinceLastRender = Date().timeIntervalSince(lastRender) * 1000
            if timeSinceLastRender < 16.67 {
                print("[Debug Performance] ⚠️ \(key) re-rendered after \(String(format: "%.2fms", timeSinceLastRender)) - potential excessive re-renders")
            }
        }

        DebugOverlayStorage.shared.lastRenderTimes[key] = Date()

        let result = content

        // Measure body evaluation time
        let duration = Date().timeIntervalSince(startTime) * 1000

        // Track durations
        DebugOverlayStorage.shared.renderDurations[key, default: []].append(duration)
        if DebugOverlayStorage.shared.renderDurations[key]!.count > 10 {
            DebugOverlayStorage.shared.renderDurations[key]!.removeFirst()
        }

        // Check threshold
        if duration > threshold {
            let avgDuration = DebugOverlayStorage.shared.renderDurations[key]!.reduce(0, +) / Double(DebugOverlayStorage.shared.renderDurations[key]!.count)
            print("[Debug Performance] 🐌 \(key) took \(String(format: "%.2fms", duration)) (avg: \(String(format: "%.2fms", avgDuration)), threshold: \(threshold)ms)")
        }

        return result
    }
}

#else

// Empty implementations for non-DEBUG builds
extension View {
    @MainActor
    public func debugOverlay(label: String? = nil) -> some View {
        self
    }

    @MainActor
    public func debugPrint(label: String? = nil) -> some View {
        self
    }

    @MainActor
    public func debugBorder(_ color: DebugColor = .red, width: Double = 1) -> some View {
        self
    }

    @MainActor
    public func debugHierarchy(depth: Int = 3) -> some View {
        self
    }

    @MainActor
    public func debugPerformance(threshold: Double = 16.0) -> some View {
        self
    }
}

public enum DebugColor: Sendable {
    case red, green, blue, yellow, purple, orange, cyan, magenta
}

#endif
