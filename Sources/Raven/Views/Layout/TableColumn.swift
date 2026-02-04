import Foundation

/// A column in a table that displays data from a specific property of row data.
///
/// `TableColumn` defines how a single column in a table should be rendered, including
/// its header, cell content, and optional sorting behavior. Each column is associated
/// with a property of the row data type through a key path.
///
/// ## Overview
///
/// Use `TableColumn` within a `Table` to define the structure and behavior of each
/// column. Columns can display simple values or complex custom views, and can optionally
/// support sorting.
///
/// ## Basic Usage
///
/// Define columns with value key paths:
///
/// ```swift
/// Table(people) {
///     TableColumn("Name", value: \.name)
///     TableColumn("Age", value: \.age)
///     TableColumn("Email", value: \.email)
/// }
/// ```
///
/// ## Custom Cell Content
///
/// Provide custom views for cell content:
///
/// ```swift
/// Table(people) {
///     TableColumn("Profile") { person in
///         HStack {
///             Image(person.avatarURL)
///             Text(person.name)
///         }
///     }
///     TableColumn("Status") { person in
///         Text(person.isActive ? "Active" : "Inactive")
///             .foregroundColor(person.isActive ? .green : .gray)
///     }
/// }
/// ```
///
/// ## Sortable Columns
///
/// Enable sorting by providing a comparator:
///
/// ```swift
/// @State private var sortOrder = [KeyPathComparator(\Person.name)]
///
/// Table(people, sortOrder: $sortOrder) {
///     TableColumn("Name", value: \.name, comparator: KeyPathComparator(\.name))
///     TableColumn("Age", value: \.age, comparator: KeyPathComparator(\.age))
/// }
/// ```
///
/// ## See Also
///
/// - ``Table``
/// - ``TableRow``
/// - ``KeyPathComparator``
public struct TableColumn<RowValue: Sendable, Sort, Content: View, Label: View>: Sendable {
    /// The label view for the column header
    let label: Label

    /// Closure that creates the cell content for each row
    let content: @Sendable @MainActor (RowValue) -> Content

    /// Optional comparator for sorting this column (type-erased)
    let comparatorID: String?

    /// The comparison function
    let compareFunc: (@Sendable (RowValue, RowValue) -> Bool)?

    /// Unique identifier for this column
    let id: String

    /// The title text for the column (used for accessibility)
    let title: String

    // MARK: - Initializers

    /// Creates a column with a label view and custom content.
    ///
    /// - Parameters:
    ///   - label: A view builder that creates the column header.
    ///   - content: A view builder that creates the cell content for each row.
    @MainActor public init(
        @ViewBuilder label: () -> Label,
        @ViewBuilder content: @escaping @Sendable @MainActor (RowValue) -> Content
    ) {
        self.label = label()
        self.content = content
        self.comparatorID = nil
        self.compareFunc = nil
        self.id = UUID().uuidString
        self.title = ""
    }

    /// Creates a sortable column with a label view and custom content.
    ///
    /// - Parameters:
    ///   - label: A view builder that creates the column header.
    ///   - sortUsing: The comparator to use for sorting this column.
    ///   - content: A view builder that creates the cell content for each row.
    @MainActor public init<V: Comparable & Sendable>(
        @ViewBuilder label: () -> Label,
        sortUsing comparator: KeyPathComparator<RowValue, V>,
        @ViewBuilder content: @escaping @Sendable @MainActor (RowValue) -> Content
    ) {
        self.label = label()
        self.content = content
        self.comparatorID = "\(comparator)"
        self.compareFunc = comparator.compare
        self.id = "\(comparator)"
        self.title = ""
    }
}

// MARK: - String-Based Label Initializers

extension TableColumn where Label == Text {
    /// Creates a column with a text label and custom content.
    ///
    /// - Parameters:
    ///   - title: The title for the column header.
    ///   - content: A view builder that creates the cell content for each row.
    @MainActor public init(
        _ title: String,
        @ViewBuilder content: @escaping @Sendable @MainActor (RowValue) -> Content
    ) {
        self.label = Text(title)
        self.content = content
        self.comparatorID = nil
        self.compareFunc = nil
        self.id = UUID().uuidString
        self.title = title
    }

    /// Creates a sortable column with a text label and custom content.
    ///
    /// - Parameters:
    ///   - title: The title for the column header.
    ///   - sortUsing: The comparator to use for sorting this column.
    ///   - content: A view builder that creates the cell content for each row.
    @MainActor public init<V: Comparable & Sendable>(
        _ title: String,
        sortUsing comparator: KeyPathComparator<RowValue, V>,
        @ViewBuilder content: @escaping @Sendable @MainActor (RowValue) -> Content
    ) {
        self.label = Text(title)
        self.content = content
        self.comparatorID = "\(comparator)"
        self.compareFunc = comparator.compare
        self.id = "\(comparator)"
        self.title = title
    }

    /// Creates a column with a localized string key label and custom content.
    ///
    /// - Parameters:
    ///   - titleKey: The localized string key for the column header.
    ///   - content: A view builder that creates the cell content for each row.
    @MainActor public init(
        _ titleKey: LocalizedStringKey,
        @ViewBuilder content: @escaping @Sendable @MainActor (RowValue) -> Content
    ) {
        let title = titleKey.stringValue
        self.label = Text(title)
        self.content = content
        self.comparatorID = nil
        self.compareFunc = nil
        self.id = UUID().uuidString
        self.title = title
    }
}

// MARK: - Value-Based Initializers

extension TableColumn where Label == Text, Content == Text {
    /// Creates a column that displays a text representation of a value.
    ///
    /// This initializer is used for columns that display simple values that can be
    /// converted to strings. The value is extracted using the provided key path.
    ///
    /// - Parameters:
    ///   - title: The title for the column header.
    ///   - value: A key path to the property to display.
    @MainActor public init<V: CustomStringConvertible & Sendable>(
        _ title: String,
        value: KeyPath<RowValue, V>
    ) {
        self.label = Text(title)
        self.content = { (row: RowValue) in
            Text(String(describing: row[keyPath: value]))
        }
        self.comparatorID = nil
        self.compareFunc = nil
        self.id = UUID().uuidString
        self.title = title
    }

    /// Creates a sortable column that displays a text representation of a comparable value.
    ///
    /// - Parameters:
    ///   - title: The title for the column header.
    ///   - value: A key path to the property to display.
    ///   - comparator: The comparator to use for sorting this column.
    @MainActor public init<V: Comparable & CustomStringConvertible & Sendable>(
        _ title: String,
        value: KeyPath<RowValue, V>,
        comparator: KeyPathComparator<RowValue, V>
    ) {
        self.label = Text(title)
        self.content = { (row: RowValue) in
            Text(String(describing: row[keyPath: value]))
        }
        self.comparatorID = "\(comparator)"
        self.compareFunc = comparator.compare
        self.id = "\(comparator)"
        self.title = title
    }

    /// Creates a sortable column that displays a text representation of a comparable value.
    ///
    /// This convenience initializer automatically creates a comparator from the value key path.
    ///
    /// - Parameters:
    ///   - title: The title for the column header.
    ///   - value: A key path to the comparable property to display and sort by.
    @MainActor public init<V: Comparable & CustomStringConvertible & Sendable>(
        _ title: String,
        value: KeyPath<RowValue, V>
    ) {
        let comparator = KeyPathComparator(value)
        self.label = Text(title)
        self.content = { (row: RowValue) in
            Text(String(describing: row[keyPath: value]))
        }
        self.comparatorID = "\(comparator)"
        self.compareFunc = comparator.compare
        self.id = "\(comparator)"
        self.title = title
    }
}

// MARK: - Internal Helpers

extension TableColumn {
    /// Creates a header cell VNode for this column.
    ///
    /// - Parameters:
    ///   - isSorted: Whether this column is currently sorted.
    ///   - sortOrder: The current sort order if sorted.
    ///   - onSort: Callback invoked when the column header is clicked for sorting.
    /// - Returns: A VNode configured as a table header cell.
    @MainActor internal func createHeaderNode(
        isSorted: Bool,
        sortOrder: SortOrder?,
        onSort: (() -> Void)?
    ) -> VNode {
        var props: [String: VProperty] = [
            // Semantic HTML
            "scope": .attribute(name: "scope", value: "col"),

            // Styling
            "padding": .style(name: "padding", value: "12px 16px"),
            "text-align": .style(name: "text-align", value: "left"),
            "font-weight": .style(name: "font-weight", value: "600"),
            "border-bottom": .style(name: "border-bottom", value: "2px solid #e5e7eb"),
            "background-color": .style(name: "background-color", value: "#f9fafb"),
            "user-select": .style(name: "user-select", value: "none"),
        ]

        // Add click handler and styling if sortable
        if comparatorID != nil {
            props["cursor"] = .style(name: "cursor", value: "pointer")

            if let onSort = onSort {
                let handlerID = UUID()
                props["onClick"] = .eventHandler(event: "click", handlerID: handlerID)
            }
        }

        // Determine sort indicator
        let sortIndicator: String
        if isSorted, let order = sortOrder {
            sortIndicator = order == .forward ? " ▲" : " ▼"
        } else {
            sortIndicator = ""
        }

        // Create text content with title and sort indicator
        let titleText = title.isEmpty ? "" : title
        let textNode = VNode.text(titleText + sortIndicator)

        return VNode.element(
            "th",
            props: props,
            children: [textNode]
        )
    }

    /// Creates a data cell VNode for this column and row value.
    ///
    /// - Parameter rowValue: The row data to display in this cell.
    /// - Returns: A VNode configured as a table data cell.
    @MainActor internal func createCellNode(for rowValue: RowValue) -> VNode {
        let props: [String: VProperty] = [
            "padding": .style(name: "padding", value: "12px 16px"),
            "border-bottom": .style(name: "border-bottom", value: "1px solid #e5e7eb"),
        ]

        // For now, we'll create a placeholder text node
        // The actual rendering will be handled by the RenderCoordinator
        return VNode.element(
            "td",
            props: props,
            children: []
        )
    }
}
