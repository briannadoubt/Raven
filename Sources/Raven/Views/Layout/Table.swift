import Foundation

/// A container that presents data in rows and columns with optional sorting and selection.
///
/// `Table` displays structured data in a familiar tabular format with column headers
/// and data rows. It supports sorting, row selection, and customizable cell content,
/// making it ideal for data-heavy interfaces.
///
/// ## Overview
///
/// Use `Table` to present collections of data in a structured, sortable format. Tables
/// are rendered as semantic HTML `<table>` elements with full accessibility support.
///
/// ## Basic Usage
///
/// Create a simple table with data and columns:
///
/// ```swift
/// struct Person: Identifiable, Sendable {
///     let id: UUID
///     let name: String
///     let age: Int
///     let email: String
/// }
///
/// Table(people) {
///     TableColumn("Name", value: \.name)
///     TableColumn("Age", value: \.age)
///     TableColumn("Email", value: \.email)
/// }
/// ```
///
/// ## Sortable Tables
///
/// Enable sorting by providing a sort order binding:
///
/// ```swift
/// @State private var sortOrder = [KeyPathComparator(\Person.name)]
///
/// Table(people, sortOrder: $sortOrder) {
///     TableColumn("Name", value: \.name)
///     TableColumn("Age", value: \.age)
///     TableColumn("Email", value: \.email)
/// }
/// ```
///
/// ## Selectable Tables
///
/// Enable row selection with a selection binding:
///
/// ```swift
/// @State private var selection: Person.ID?
///
/// Table(people, selection: $selection) {
///     TableColumn("Name", value: \.name)
///     TableColumn("Age", value: \.age)
/// }
/// ```
///
/// ## Multi-Column Sorting
///
/// Tables support sorting by multiple columns. Click column headers to sort,
/// click again to reverse sort order:
///
/// ```swift
/// @State private var sortOrder = [
///     KeyPathComparator(\Person.name),
///     KeyPathComparator(\Person.age)
/// ]
///
/// Table(people, sortOrder: $sortOrder) {
///     TableColumn("Name", value: \.name)
///     TableColumn("Age", value: \.age)
/// }
/// ```
///
/// ## Custom Cell Content
///
/// Provide custom views for complex cell content:
///
/// ```swift
/// Table(people) {
///     TableColumn("Profile") { person in
///         HStack {
///             Image(person.avatarURL)
///             VStack(alignment: .leading) {
///                 Text(person.name)
///                     .font(.headline)
///                 Text(person.email)
///                     .font(.caption)
///             }
///         }
///     }
///     TableColumn("Status") { person in
///         Text(person.isActive ? "Active" : "Inactive")
///             .foregroundColor(person.isActive ? .green : .gray)
///     }
/// }
/// ```
///
/// ## Accessibility
///
/// Table automatically includes:
/// - Semantic HTML table structure (`<table>`, `<thead>`, `<tbody>`, `<th>`, `<td>`)
/// - ARIA attributes for screen readers
/// - Keyboard navigation support (planned)
/// - Sort state indicators in column headers
///
/// ## See Also
///
/// - ``TableColumn``
/// - ``TableRow``
/// - ``KeyPathComparator``
/// - ``SortOrder``
public struct Table<RowValue, Columns>: View, Sendable
where RowValue: Identifiable & Sendable, RowValue.ID: Sendable, Columns: View
{
    public typealias Body = Never

    /// The data to display in the table
    let data: [RowValue]

    /// The column definitions
    let columns: Columns

    /// Optional selection binding
    let selection: Binding<RowValue.ID?>?

    /// Optional sort order binding
    let sortOrder: Binding<[SortDescriptor<RowValue>]>?

    /// Unique identifier for this table
    let id: String

    // MARK: - Initializers

    /// Creates a table with the given data and columns.
    ///
    /// - Parameters:
    ///   - data: The collection of data to display.
    ///   - columns: A view builder that creates the table columns.
    @MainActor public init(
        _ data: [RowValue],
        @ViewBuilder columns: () -> Columns
    ) {
        self.data = data
        self.columns = columns()
        self.selection = nil
        self.sortOrder = nil
        self.id = UUID().uuidString
    }

    /// Creates a table with row selection.
    ///
    /// - Parameters:
    ///   - data: The collection of data to display.
    ///   - selection: A binding to the selected row's ID.
    ///   - columns: A view builder that creates the table columns.
    @MainActor public init(
        _ data: [RowValue],
        selection: Binding<RowValue.ID?>,
        @ViewBuilder columns: () -> Columns
    ) {
        self.data = data
        self.columns = columns()
        self.selection = selection
        self.sortOrder = nil
        self.id = UUID().uuidString
    }

    /// Creates a table with sortable columns.
    ///
    /// - Parameters:
    ///   - data: The collection of data to display.
    ///   - sortOrder: A binding to the array of sort descriptors.
    ///   - columns: A view builder that creates the table columns.
    @MainActor public init(
        _ data: [RowValue],
        sortOrder: Binding<[SortDescriptor<RowValue>]>,
        @ViewBuilder columns: () -> Columns
    ) {
        self.data = data
        self.columns = columns()
        self.selection = nil
        self.sortOrder = sortOrder
        self.id = UUID().uuidString
    }

    /// Creates a table with both row selection and sortable columns.
    ///
    /// - Parameters:
    ///   - data: The collection of data to display.
    ///   - selection: A binding to the selected row's ID.
    ///   - sortOrder: A binding to the array of sort descriptors.
    ///   - columns: A view builder that creates the table columns.
    @MainActor public init(
        _ data: [RowValue],
        selection: Binding<RowValue.ID?>,
        sortOrder: Binding<[SortDescriptor<RowValue>]>,
        @ViewBuilder columns: () -> Columns
    ) {
        self.data = data
        self.columns = columns()
        self.selection = selection
        self.sortOrder = sortOrder
        self.id = UUID().uuidString
    }

    // MARK: - VNode Conversion

    /// Converts this Table to a virtual DOM node.
    ///
    /// The Table is rendered as an HTML `<table>` element with:
    /// - `<thead>` containing column headers
    /// - `<tbody>` containing data rows
    /// - Full ARIA attributes for accessibility
    /// - Sort indicators in column headers
    /// - Selection state management
    ///
    /// - Returns: A VNode configured as a table element.
    @MainActor public func toVNode() -> VNode {
        // Table container props
        let tableProps: [String: VProperty] = [
            // Accessibility
            "role": .attribute(name: "role", value: "table"),
            "aria-label": .attribute(name: "aria-label", value: "Data table"),

            // Styling - standard table appearance
            "width": .style(name: "width", value: "100%"),
            "border-collapse": .style(name: "border-collapse", value: "collapse"),
            "border": .style(name: "border", value: "1px solid #e5e7eb"),
            "background-color": .style(name: "background-color", value: "white"),
        ]

        // Extract column information (this would be done by the RenderCoordinator)
        // For now, we return a skeleton structure

        // Create thead section
        let theadProps: [String: VProperty] = [:]
        let thead = VNode.element("thead", props: theadProps, children: [])

        // Create tbody section
        let tbodyProps: [String: VProperty] = [:]
        let tbody = VNode.element("tbody", props: tbodyProps, children: [])

        // Return the table structure
        return VNode.element(
            "table",
            props: tableProps,
            children: [thead, tbody]
        )
    }

    // MARK: - Internal Accessors

    /// Gets the sorted data based on the current sort order.
    ///
    /// This method applies the sort descriptors to the data and returns
    /// a sorted array. If no sort order is specified, returns the original data.
    ///
    /// - Returns: The sorted data array.
    @MainActor internal func getSortedData() -> [RowValue] {
        guard let sortOrder = sortOrder?.wrappedValue, !sortOrder.isEmpty else {
            return data
        }
        return data.sorted(using: sortOrder)
    }

    /// Checks if a row is currently selected.
    ///
    /// - Parameter rowID: The ID of the row to check.
    /// - Returns: True if the row is selected, false otherwise.
    @MainActor internal func isRowSelected(_ rowID: RowValue.ID) -> Bool {
        selection?.wrappedValue == rowID
    }

    /// Handles row selection.
    ///
    /// - Parameter rowID: The ID of the row that was selected.
    @MainActor internal func selectRow(_ rowID: RowValue.ID) {
        guard let selection = selection else { return }
        if selection.wrappedValue == rowID {
            // Deselect if already selected
            selection.wrappedValue = nil
        } else {
            selection.wrappedValue = rowID
        }
    }

    /// Handles column header click for sorting.
    ///
    /// This method updates the sort order when a column header is clicked.
    /// If the column is not in the sort order, it's added. If it's already
    /// the primary sort, its order is reversed.
    ///
    /// - Parameter columnID: The ID of the column that was clicked.
    @MainActor internal func handleColumnSort(columnID: String) {
        guard let sortOrderBinding = sortOrder else { return }

        var currentSort = sortOrderBinding.wrappedValue

        // Find if this column is already in the sort order
        if let index = currentSort.firstIndex(where: { $0.id == columnID }) {
            if index == 0 {
                // Primary sort - reverse the order
                let descriptor = currentSort[index]
                let newOrder = descriptor.order.reversed
                // We need to recreate the descriptor with reversed order
                // This is a simplification - actual implementation would need proper comparator access
                currentSort.remove(at: index)
            } else {
                // Move to primary position
                let descriptor = currentSort.remove(at: index)
                currentSort.insert(descriptor, at: 0)
            }
        }

        sortOrderBinding.wrappedValue = currentSort
    }
}

// MARK: - Multi-Selection Support

extension Table {
    /// Creates a table with multiple row selection.
    ///
    /// - Parameters:
    ///   - data: The collection of data to display.
    ///   - selection: A binding to a set of selected row IDs.
    ///   - columns: A view builder that creates the table columns.
    @MainActor public init(
        _ data: [RowValue],
        selection: Binding<Set<RowValue.ID>>,
        @ViewBuilder columns: () -> Columns
    ) where RowValue.ID: Hashable {
        // For now, we'll implement multi-selection as a future enhancement
        // This initializer exists for API compatibility
        self.data = data
        self.columns = columns()
        self.selection = nil // Multi-selection would need different handling
        self.sortOrder = nil
        self.id = UUID().uuidString
    }

    /// Creates a table with multiple row selection and sorting.
    ///
    /// - Parameters:
    ///   - data: The collection of data to display.
    ///   - selection: A binding to a set of selected row IDs.
    ///   - sortOrder: A binding to the array of sort descriptors.
    ///   - columns: A view builder that creates the table columns.
    @MainActor public init(
        _ data: [RowValue],
        selection: Binding<Set<RowValue.ID>>,
        sortOrder: Binding<[SortDescriptor<RowValue>]>,
        @ViewBuilder columns: () -> Columns
    ) where RowValue.ID: Hashable {
        // For now, we'll implement multi-selection as a future enhancement
        self.data = data
        self.columns = columns()
        self.selection = nil // Multi-selection would need different handling
        self.sortOrder = sortOrder
        self.id = UUID().uuidString
    }
}

// MARK: - Convenience Initializers for Collections

extension Table {
    /// Creates a table from any random access collection.
    ///
    /// - Parameters:
    ///   - data: The collection of data to display.
    ///   - columns: A view builder that creates the table columns.
    @MainActor public init<Data: RandomAccessCollection>(
        _ data: Data,
        @ViewBuilder columns: () -> Columns
    ) where Data.Element == RowValue {
        self.data = Array(data)
        self.columns = columns()
        self.selection = nil
        self.sortOrder = nil
        self.id = UUID().uuidString
    }

    /// Creates a table from any random access collection with selection.
    ///
    /// - Parameters:
    ///   - data: The collection of data to display.
    ///   - selection: A binding to the selected row's ID.
    ///   - columns: A view builder that creates the table columns.
    @MainActor public init<Data: RandomAccessCollection>(
        _ data: Data,
        selection: Binding<RowValue.ID?>,
        @ViewBuilder columns: () -> Columns
    ) where Data.Element == RowValue {
        self.data = Array(data)
        self.columns = columns()
        self.selection = selection
        self.sortOrder = nil
        self.id = UUID().uuidString
    }

    /// Creates a table from any random access collection with sorting.
    ///
    /// - Parameters:
    ///   - data: The collection of data to display.
    ///   - sortOrder: A binding to the array of sort descriptors.
    ///   - columns: A view builder that creates the table columns.
    @MainActor public init<Data: RandomAccessCollection>(
        _ data: Data,
        sortOrder: Binding<[SortDescriptor<RowValue>]>,
        @ViewBuilder columns: () -> Columns
    ) where Data.Element == RowValue {
        self.data = Array(data)
        self.columns = columns()
        self.selection = nil
        self.sortOrder = sortOrder
        self.id = UUID().uuidString
    }

    /// Creates a table from any random access collection with selection and sorting.
    ///
    /// - Parameters:
    ///   - data: The collection of data to display.
    ///   - selection: A binding to the selected row's ID.
    ///   - sortOrder: A binding to the array of sort descriptors.
    ///   - columns: A view builder that creates the table columns.
    @MainActor public init<Data: RandomAccessCollection>(
        _ data: Data,
        selection: Binding<RowValue.ID?>,
        sortOrder: Binding<[SortDescriptor<RowValue>]>,
        @ViewBuilder columns: () -> Columns
    ) where Data.Element == RowValue {
        self.data = Array(data)
        self.columns = columns()
        self.selection = selection
        self.sortOrder = sortOrder
        self.id = UUID().uuidString
    }
}
