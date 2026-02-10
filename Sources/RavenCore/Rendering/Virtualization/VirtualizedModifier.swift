import Foundation

/// Modifier that enables virtual scrolling for large lists and grids.
///
/// The `.virtualized()` modifier optimizes rendering performance for large collections
/// by only rendering visible items. It uses windowing techniques, DOM recycling,
/// and IntersectionObserver for efficient viewport management.
///
/// Example:
/// ```swift
/// List(0..<10000) { index in
///     Text("Item \(index)")
/// }
/// .virtualized()
///
/// // With custom configuration
/// List(items) { item in
///     ItemView(item: item)
/// }
/// .virtualized(
///     estimatedItemHeight: 60,
///     overscan: 5
/// )
/// ```
public struct VirtualizedModifier: ViewModifier, Sendable {
    /// Configuration for virtual scrolling
    let config: VirtualScroller.Configuration

    /// Initialize a virtualized modifier.
    ///
    /// - Parameters:
    ///   - estimatedItemHeight: Estimated height for items in pixels
    ///   - overscan: Number of items to render above/below viewport
    ///   - dynamicHeights: Whether to measure actual item heights
    public init(
        estimatedItemHeight: Double = 44.0,
        overscan: Int = 3,
        dynamicHeights: Bool = true
    ) {
        self.config = VirtualScroller.Configuration(
            overscanCount: overscan,
            overscanPixels: Int(estimatedItemHeight) * overscan,
            dynamicHeights: dynamicHeights,
            estimatedItemHeight: estimatedItemHeight
        )
    }

    /// Initialize with a full configuration.
    ///
    /// - Parameter config: Virtual scrolling configuration
    public init(config: VirtualScroller.Configuration) {
        self.config = config
    }

    @MainActor
    public func body(content: Content) -> some View {
        // Wrap the content with virtualization metadata
        VirtualizedContent(content: content, config: config)
    }
}

/// Internal view that wraps virtualized content.
///
/// This view carries the virtualization configuration through the view hierarchy
/// so that the render coordinator can detect it and apply virtual scrolling.
struct VirtualizedContent<Content: View>: View, Sendable {
    let content: Content
    let config: VirtualScroller.Configuration

    var body: some View {
        content
    }
}

// MARK: - View Extension

extension View {
    /// Apply virtual scrolling to this view.
    ///
    /// Virtual scrolling optimizes rendering of large lists by only rendering
    /// visible items. Use this modifier on List, LazyVGrid, or LazyHGrid views
    /// containing thousands of items.
    ///
    /// Example:
    /// ```swift
    /// List(0..<10000) { index in
    ///     Text("Item \(index)")
    /// }
    /// .virtualized()
    /// ```
    ///
    /// - Returns: A view with virtual scrolling enabled
    @MainActor
    public func virtualized() -> some View {
        modifier(VirtualizedModifier())
    }

    /// Apply virtual scrolling with custom configuration.
    ///
    /// Allows fine-tuning of virtual scrolling behavior for specific use cases.
    ///
    /// Example:
    /// ```swift
    /// List(products) { product in
    ///     ProductRow(product: product)
    /// }
    /// .virtualized(
    ///     estimatedItemHeight: 120,
    ///     overscan: 5,
    ///     dynamicHeights: true
    /// )
    /// ```
    ///
    /// - Parameters:
    ///   - estimatedItemHeight: Estimated height for items (pixels)
    ///   - overscan: Number of items to render off-screen
    ///   - dynamicHeights: Whether to measure actual heights
    /// - Returns: A view with virtual scrolling enabled
    @MainActor
    public func virtualized(
        estimatedItemHeight: Double = 44.0,
        overscan: Int = 3,
        dynamicHeights: Bool = true
    ) -> some View {
        modifier(VirtualizedModifier(
            estimatedItemHeight: estimatedItemHeight,
            overscan: overscan,
            dynamicHeights: dynamicHeights
        ))
    }

    /// Apply virtual scrolling with full configuration.
    ///
    /// For advanced use cases requiring precise control over all
    /// virtual scrolling parameters.
    ///
    /// - Parameter config: Complete virtual scrolling configuration
    /// - Returns: A view with virtual scrolling enabled
    @MainActor
    public func virtualized(config: VirtualScroller.Configuration) -> some View {
        modifier(VirtualizedModifier(config: config))
    }
}

// MARK: - List Extensions

extension List {
    /// Create a virtualized list for optimal performance with large datasets.
    ///
    /// This convenience method combines List creation with virtualization,
    /// making it easy to handle thousands of items efficiently.
    ///
    /// Example:
    /// ```swift
    /// List.virtualized(items, estimatedHeight: 60) { item in
    ///     ItemRow(item: item)
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - data: Collection of data
    ///   - estimatedHeight: Estimated height per item
    ///   - content: View builder for each item
    /// - Returns: A virtualized list
    @MainActor
    public static func virtualized<Data, ID, RowContent>(
        _ data: Data,
        id: KeyPath<Data.Element, ID>,
        estimatedHeight: Double = 44.0,
        @ViewBuilder content: @escaping @Sendable @MainActor (Data.Element) -> RowContent
    ) -> some View where
        Content == ForEach<Data, ID, RowContent>,
        Data: RandomAccessCollection,
        Data: Sendable,
        Data.Element: Sendable,
        ID: Hashable,
        ID: Sendable,
        RowContent: View
    {
        List(data, id: id, content: content)
            .virtualized(estimatedItemHeight: estimatedHeight)
    }

    /// Create a virtualized list for Identifiable data.
    ///
    /// - Parameters:
    ///   - data: Collection of identifiable data
    ///   - estimatedHeight: Estimated height per item
    ///   - content: View builder for each item
    /// - Returns: A virtualized list
    @MainActor
    public static func virtualized<Data, RowContent>(
        _ data: Data,
        estimatedHeight: Double = 44.0,
        @ViewBuilder content: @escaping @Sendable @MainActor (Data.Element) -> RowContent
    ) -> some View where
        Content == ForEach<Data, Data.Element.ID, RowContent>,
        Data: RandomAccessCollection,
        Data.Element: Identifiable & Sendable,
        Data: Sendable,
        RowContent: View
    {
        List(data, content: content)
            .virtualized(estimatedItemHeight: estimatedHeight)
    }
}

// MARK: - LazyVGrid Extensions

extension LazyVGrid {
    /// Create a virtualized grid for optimal performance with large datasets.
    ///
    /// Virtual scrolling is especially beneficial for grids with many items,
    /// as only visible cells are rendered to the DOM.
    ///
    /// - Parameters:
    ///   - columns: Grid column configuration
    ///   - estimatedHeight: Estimated height per row
    ///   - spacing: Spacing between items
    ///   - content: View builder for content
    /// - Returns: A virtualized grid
    @MainActor
    public static func virtualized(
        columns: [GridItem],
        estimatedHeight: Double = 44.0,
        spacing: Double? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        LazyVGrid(columns: columns, spacing: spacing, content: content)
            .virtualized(estimatedItemHeight: estimatedHeight)
    }
}

// MARK: - LazyHGrid Extensions

extension LazyHGrid {
    /// Create a virtualized horizontal grid for optimal performance.
    ///
    /// - Parameters:
    ///   - rows: Grid row configuration
    ///   - estimatedWidth: Estimated width per column
    ///   - spacing: Spacing between items
    ///   - content: View builder for content
    /// - Returns: A virtualized grid
    @MainActor
    public static func virtualized(
        rows: [GridItem],
        estimatedWidth: Double = 44.0,
        spacing: Double? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        LazyHGrid(rows: rows, spacing: spacing, content: content)
            .virtualized(estimatedItemHeight: estimatedWidth)
    }
}
