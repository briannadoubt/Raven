import Foundation

/// Internal wrapper to make KeyPath Sendable-compatible
/// KeyPaths are immutable and thread-safe, so this is safe
private struct UnsafeSendableKeyPath<Root, Value>: @unchecked Sendable {
    let keyPath: KeyPath<Root, Value>

    init(_ keyPath: KeyPath<Root, Value>) {
        self.keyPath = keyPath
    }
}

/// A structure that computes views on demand from an underlying collection of identified data.
///
/// `ForEach` is a view that iterates over a collection and generates child views for each element.
/// It supports both Identifiable collections and custom ID key paths for stable identity,
/// enabling efficient diffing and DOM updates.
///
/// Examples:
/// ```swift
/// // With Identifiable items
/// struct Item: Identifiable {
///     let id: UUID
///     let name: String
/// }
/// ForEach(items) { item in
///     Text(item.name)
/// }
///
/// // With custom ID key path
/// ForEach(items, id: \.name) { item in
///     Text(item.name)
/// }
///
/// // With range
/// ForEach(0..<10) { index in
///     Text("Item \(index)")
/// }
/// ```
public struct ForEach<Data, ID, Content>: View, Sendable
where Data: RandomAccessCollection, ID: Hashable, Content: View, Data: Sendable, ID: Sendable
{
    /// The collection of data to iterate over
    let data: Data

    /// Closure to extract the ID from each element (replaces KeyPath for Sendable compliance)
    let idExtractor: (@Sendable (Data.Element) -> ID)?

    /// Closure that creates a view for each element
    let content: @Sendable @MainActor (Data.Element) -> Content

    // MARK: - Initializers

    /// Creates an instance that identifies views by ID key path.
    ///
    /// - Parameters:
    ///   - data: The collection of data to iterate over.
    ///   - id: Key path to the property that identifies each element.
    ///   - content: A view builder that creates the view for each element.
    @MainActor public init(
        _ data: Data,
        id: KeyPath<Data.Element, ID>,
        @ViewBuilder content: @escaping @Sendable @MainActor (Data.Element) -> Content
    ) where Data.Element: Sendable {
        self.data = data
        // Convert KeyPath to a closure for Sendable compliance
        // KeyPath is not Sendable but is safe to capture as it's immutable
        let sendableKeyPath = UnsafeSendableKeyPath(id)
        self.idExtractor = { element in
            element[keyPath: sendableKeyPath.keyPath]
        }
        self.content = content
    }

    // MARK: - Body

    /// The content and behavior of this view.
    ///
    /// ForEach generates its body by applying the content closure to each element
    /// in the data collection. The resulting views are wrapped in a ForEachView
    /// which is a ViewBuilder construct that the RenderCoordinator knows how to handle.
    @ViewBuilder @MainActor public var body: some View {
        // Convert the collection into an array of views
        // The ViewBuilder.buildArray will wrap these in a ForEachView
        let views = data.map { element in
            content(element)
        }
        // Use buildArray to create a ForEachView
        ForEachView(views: Array(views))
    }
}

// MARK: - Identifiable Extension

extension ForEach where ID == Data.Element.ID, Data.Element: Identifiable & Sendable {
    /// Creates an instance that uniquely identifies views across updates based on the identity
    /// of the underlying data element.
    ///
    /// Use this initializer when your data elements conform to `Identifiable`.
    /// The ForEach will use the element's `id` property for stable identity.
    ///
    /// - Parameters:
    ///   - data: The collection of identifiable data.
    ///   - content: A view builder that creates the view for each element.
    @MainActor public init(
        _ data: Data,
        @ViewBuilder content: @escaping @Sendable @MainActor (Data.Element) -> Content
    ) {
        self.data = data
        // Convert KeyPath to a closure for Sendable compliance
        self.idExtractor = { element in
            element.id
        }
        self.content = content
    }
}

// MARK: - Range Extension

extension ForEach where Data == Range<Int>, ID == Int, Data.Element == Int {
    /// Creates an instance that computes views for a range of integers.
    ///
    /// Use this initializer to create a fixed number of views based on an integer range.
    /// This is useful for creating grids, lists, or repeated patterns.
    ///
    /// Example:
    /// ```swift
    /// ForEach(0..<10) { index in
    ///     Text("Row \(index)")
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - data: A range of integers.
    ///   - content: A view builder that creates the view for each integer.
    @MainActor public init(
        _ data: Range<Int>,
        @ViewBuilder content: @escaping @Sendable @MainActor (Int) -> Content
    ) {
        self.data = data
        // For Range<Int>, the ID is the element itself
        self.idExtractor = { element in
            element
        }
        self.content = content
    }
}

extension ForEach where Data == ClosedRange<Int>, ID == Int, Data.Element == Int {
    /// Creates an instance that computes views for a closed range of integers.
    ///
    /// Use this initializer for inclusive integer ranges (for example `1...5`),
    /// matching SwiftUI's API surface for `ForEach`.
    ///
    /// - Parameters:
    ///   - data: A closed range of integers.
    ///   - content: A view builder that creates the view for each integer.
    @MainActor public init(
        _ data: ClosedRange<Int>,
        @ViewBuilder content: @escaping @Sendable @MainActor (Int) -> Content
    ) {
        self.data = data
        self.idExtractor = { element in
            element
        }
        self.content = content
    }
}
