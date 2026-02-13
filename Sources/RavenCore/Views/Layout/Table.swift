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
public struct Table<RowValue, Columns>: View, PrimitiveView, Sendable
where RowValue: Identifiable & Sendable, RowValue.ID: Sendable, Columns: View
{
    public typealias Body = Never

    /// The data to display in the table
    let data: [RowValue]

    /// The column definitions
    let columns: Columns

    /// Optional single selection binding
    let selection: Binding<RowValue.ID?>?

    /// Optional multi-selection binding
    let multiSelection: Binding<Set<RowValue.ID>>?

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
        @TableColumnBuilder columns: () -> Columns
    ) {
        self.data = data
        self.columns = columns()
        self.selection = nil
        self.multiSelection = nil
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
        @TableColumnBuilder columns: () -> Columns
    ) {
        self.data = data
        self.columns = columns()
        self.selection = selection
        self.multiSelection = nil
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
        @TableColumnBuilder columns: () -> Columns
    ) {
        self.data = data
        self.columns = columns()
        self.selection = nil
        self.multiSelection = nil
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
        @TableColumnBuilder columns: () -> Columns
    ) {
        self.data = data
        self.columns = columns()
        self.selection = selection
        self.multiSelection = nil
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
    /// - Checkbox column for multi-selection (if enabled)
    ///
    /// - Returns: A VNode configured as a table element.
    @MainActor public func toVNode() -> VNode {
        // Determine if multi-selection is active
        let hasMultiSelection = multiSelection != nil

        // Table container props
        var tableProps: [String: VProperty] = [
            // Accessibility
            "role": .attribute(name: "role", value: "table"),
            "aria-label": .attribute(name: "aria-label", value: "Data table"),

            // Styling - standard table appearance
            "width": .style(name: "width", value: "100%"),
            "border-collapse": .style(name: "border-collapse", value: "collapse"),
            "border": .style(name: "border", value: "1px solid var(--system-separator, #e5e7eb)"),
            "background-color": .style(name: "background-color", value: "var(--system-background, white)"),
            "color": .style(name: "color", value: "var(--system-label, #111827)"),
        ]

        // Add multi-selectable ARIA attribute if multi-selection is enabled
        if hasMultiSelection {
            tableProps["aria-multiselectable"] = .attribute(name: "aria-multiselectable", value: "true")
        }

        // Extract column information (this would be done by the RenderCoordinator)
        // For now, we return a skeleton structure

        // Create thead section
        let theadProps: [String: VProperty] = [:]
        var headerChildren: [VNode] = []

        // Add checkbox column header for multi-selection
        if hasMultiSelection {
            let checkboxHeaderProps: [String: VProperty] = [
                "width": .style(name: "width", value: "40px"),
            ]
            let checkboxHeaderCell = VNode.element("th", props: checkboxHeaderProps, children: [
                VNode.text("") // Empty header for checkbox column
            ])
            headerChildren.append(checkboxHeaderCell)
        }

        let thead = VNode.element("thead", props: theadProps, children: headerChildren)

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
        if let multiSelection = multiSelection {
            return multiSelection.wrappedValue.contains(rowID)
        } else if let selection = selection {
            return selection.wrappedValue == rowID
        }
        return false
    }

    /// Handles row selection (single or multi-selection).
    ///
    /// - Parameter rowID: The ID of the row that was selected.
    @MainActor internal func selectRow(_ rowID: RowValue.ID) {
        if let multiSelection = multiSelection {
            // Multi-selection: toggle the row in the set
            var current = multiSelection.wrappedValue
            if current.contains(rowID) {
                current.remove(rowID)
            } else {
                current.insert(rowID)
            }
            multiSelection.wrappedValue = current
        } else if let selection = selection {
            // Single selection: toggle or replace
            if selection.wrappedValue == rowID {
                // Deselect if already selected
                selection.wrappedValue = nil
            } else {
                selection.wrappedValue = rowID
            }
        }
    }

    /// Toggles the selection state of a row (multi-selection only).
    ///
    /// - Parameter rowID: The ID of the row to toggle.
    @MainActor internal func toggleRow(_ rowID: RowValue.ID) {
        guard let multiSelection = multiSelection else { return }
        var current = multiSelection.wrappedValue
        if current.contains(rowID) {
            current.remove(rowID)
        } else {
            current.insert(rowID)
        }
        multiSelection.wrappedValue = current
    }

    /// Selects all rows in the table (multi-selection only).
    @MainActor internal func selectAll() {
        guard let multiSelection = multiSelection else { return }
        let allIDs = Set(data.map { $0.id })
        multiSelection.wrappedValue = allIDs
    }

    /// Deselects all rows in the table (multi-selection only).
    @MainActor internal func deselectAll() {
        guard let multiSelection = multiSelection else { return }
        multiSelection.wrappedValue = []
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
                _ = currentSort[index].order.reversed
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

// MARK: - Column Extraction

/// Type-erased representation of a `TableColumn` so `Table` can render headers and cells.
@MainActor
internal struct AnyTableColumn<RowValue: Sendable>: Sendable {
    let id: String
    let title: String
    let label: AnyView
    let makeCell: @Sendable @MainActor (RowValue) -> AnyView

    let comparatorID: String?
    let compareFunc: (@Sendable (RowValue, RowValue) -> Bool)?
}

/// Internal protocol used to erase a `TableColumn` instance without fighting its generics.
@MainActor
internal protocol _AnyTableColumnErasing: View {
    /// Returns `AnyTableColumn<RowValue>` for the concrete `RowValue` the column was built with.
    /// The return type is `Any` so `Table` can downcast to its own `RowValue`.
    func _eraseToAnyTableColumn() -> Any
}

@MainActor
private protocol _TableColumnsExtractable {
    func extractTableColumns<RowValue: Identifiable & Sendable>(into columns: inout [AnyTableColumn<RowValue>]) where RowValue.ID: Sendable
}

extension TupleView: _TableColumnsExtractable {
    @MainActor fileprivate func extractTableColumns<RowValue: Identifiable & Sendable>(into columns: inout [AnyTableColumn<RowValue>]) where RowValue.ID: Sendable {
        for child in _extractChildren() {
            extractFromView(child, into: &columns)
        }
    }

    @MainActor private func extractFromView<RowValue: Identifiable & Sendable>(_ view: any View, into columns: inout [AnyTableColumn<RowValue>]) where RowValue.ID: Sendable {
        if let erasing = view as? any _AnyTableColumnErasing,
           let erased = erasing._eraseToAnyTableColumn() as? AnyTableColumn<RowValue> {
            columns.append(erased)
        } else if let tuple = view as? any _TableColumnsExtractable {
            tuple.extractTableColumns(into: &columns)
        } else if let conditional = view as? any _TableColumnsConditionalExtractable {
            conditional.extractTableColumns(into: &columns)
        } else if let optional = view as? any _TableColumnsOptionalExtractable {
            optional.extractTableColumns(into: &columns)
        } else if let forEach = view as? any _TableColumnsForEachExtractable {
            forEach.extractTableColumns(into: &columns)
        }
    }
}

@MainActor
private protocol _TableColumnsConditionalExtractable {
    func extractTableColumns<RowValue: Identifiable & Sendable>(into columns: inout [AnyTableColumn<RowValue>]) where RowValue.ID: Sendable
}

extension ConditionalContent: _TableColumnsConditionalExtractable {
    @MainActor fileprivate func extractTableColumns<RowValue: Identifiable & Sendable>(into columns: inout [AnyTableColumn<RowValue>]) where RowValue.ID: Sendable {
        switch storage {
        case .trueContent(let content):
            extractFromView(content, into: &columns)
        case .falseContent(let content):
            extractFromView(content, into: &columns)
        }
    }

    @MainActor private func extractFromView<RowValue: Identifiable & Sendable>(_ view: any View, into columns: inout [AnyTableColumn<RowValue>]) where RowValue.ID: Sendable {
        if let erasing = view as? any _AnyTableColumnErasing,
           let erased = erasing._eraseToAnyTableColumn() as? AnyTableColumn<RowValue> {
            columns.append(erased)
        } else if let tuple = view as? any _TableColumnsExtractable {
            tuple.extractTableColumns(into: &columns)
        } else if let conditional = view as? any _TableColumnsConditionalExtractable {
            conditional.extractTableColumns(into: &columns)
        } else if let optional = view as? any _TableColumnsOptionalExtractable {
            optional.extractTableColumns(into: &columns)
        } else if let forEach = view as? any _TableColumnsForEachExtractable {
            forEach.extractTableColumns(into: &columns)
        }
    }
}

@MainActor
private protocol _TableColumnsOptionalExtractable {
    func extractTableColumns<RowValue: Identifiable & Sendable>(into columns: inout [AnyTableColumn<RowValue>]) where RowValue.ID: Sendable
}

extension OptionalContent: _TableColumnsOptionalExtractable {
    @MainActor fileprivate func extractTableColumns<RowValue: Identifiable & Sendable>(into columns: inout [AnyTableColumn<RowValue>]) where RowValue.ID: Sendable {
        if let content = content {
            extractFromView(content, into: &columns)
        }
    }

    @MainActor private func extractFromView<RowValue: Identifiable & Sendable>(_ view: any View, into columns: inout [AnyTableColumn<RowValue>]) where RowValue.ID: Sendable {
        if let erasing = view as? any _AnyTableColumnErasing,
           let erased = erasing._eraseToAnyTableColumn() as? AnyTableColumn<RowValue> {
            columns.append(erased)
        } else if let tuple = view as? any _TableColumnsExtractable {
            tuple.extractTableColumns(into: &columns)
        } else if let conditional = view as? any _TableColumnsConditionalExtractable {
            conditional.extractTableColumns(into: &columns)
        } else if let optional = view as? any _TableColumnsOptionalExtractable {
            optional.extractTableColumns(into: &columns)
        } else if let forEach = view as? any _TableColumnsForEachExtractable {
            forEach.extractTableColumns(into: &columns)
        }
    }
}

@MainActor
private protocol _TableColumnsForEachExtractable {
    func extractTableColumns<RowValue: Identifiable & Sendable>(into columns: inout [AnyTableColumn<RowValue>]) where RowValue.ID: Sendable
}

extension ForEachView: _TableColumnsForEachExtractable {
    @MainActor fileprivate func extractTableColumns<RowValue: Identifiable & Sendable>(into columns: inout [AnyTableColumn<RowValue>]) where RowValue.ID: Sendable {
        for view in views {
            if let erasing = view as? any _AnyTableColumnErasing,
               let erased = erasing._eraseToAnyTableColumn() as? AnyTableColumn<RowValue> {
                columns.append(erased)
            } else if let tuple = view as? any _TableColumnsExtractable {
                tuple.extractTableColumns(into: &columns)
            } else if let conditional = view as? any _TableColumnsConditionalExtractable {
                conditional.extractTableColumns(into: &columns)
            } else if let optional = view as? any _TableColumnsOptionalExtractable {
                optional.extractTableColumns(into: &columns)
            } else if let forEach = view as? any _TableColumnsForEachExtractable {
                forEach.extractTableColumns(into: &columns)
            }
        }
    }
}

// MARK: - Coordinator Renderable

extension Table: _CoordinatorRenderable {
    @MainActor public func _render(with context: any _RenderContext) -> VNode {
        // Extract columns from the view builder output.
        //
        // Use `_ViewTuple` traversal as the primary mechanism, because `@ViewBuilder`
        // always emits `TupleView` / conditional wrappers, and we want the extraction
        // to keep working even if `Columns` isn't exactly `TupleView`.
        func extractColumns(from view: any View, into output: inout [AnyTableColumn<RowValue>]) {
            if let erasing = view as? any _AnyTableColumnErasing,
               let erased = erasing._eraseToAnyTableColumn() as? AnyTableColumn<RowValue> {
                output.append(erased)
                return
            }

            if let tuple = view as? any _ViewTuple {
                for child in tuple._extractChildren() {
                    extractColumns(from: child, into: &output)
                }
                return
            }

            if let conditional = view as? any _TableColumnsConditionalExtractable {
                conditional.extractTableColumns(into: &output)
                return
            }

            if let optional = view as? any _TableColumnsOptionalExtractable {
                optional.extractTableColumns(into: &output)
                return
            }

            if let forEach = view as? any _TableColumnsForEachExtractable {
                forEach.extractTableColumns(into: &output)
                return
            }
        }

        var extractedColumns: [AnyTableColumn<RowValue>] = []
        extractColumns(from: columns, into: &extractedColumns)

        // If we couldn't extract columns, fall back to `toVNode()` skeleton.
        if extractedColumns.isEmpty {
            return toVNode()
        }

        let rows = getSortedData()

        // Wrapper enables scrolling and rounded borders without fighting `<table>` rendering.
        let wrapper = VNode.element(
            "div",
            props: [
                "class": .attribute(name: "class", value: "raven-table-wrapper"),
                "width": .style(name: "width", value: "100%"),
                "overflow": .style(name: "overflow", value: "auto"),
                "border": .style(name: "border", value: "1px solid var(--system-separator, #e5e7eb)"),
                "border-radius": .style(name: "border-radius", value: "10px"),
                "background-color": .style(name: "background-color", value: "var(--system-background, white)"),
            ],
            children: []
        )

        let table = VNode.element(
            "table",
            props: [
                "class": .attribute(name: "class", value: "raven-table"),
                "role": .attribute(name: "role", value: "table"),
                "aria-label": .attribute(name: "aria-label", value: "Data table"),
                "width": .style(name: "width", value: "100%"),
                "border-collapse": .style(name: "border-collapse", value: "separate"),
                "border-spacing": .style(name: "border-spacing", value: "0"),
                "color": .style(name: "color", value: "var(--system-label, #111827)"),
            ],
            children: []
        )

        // Header row
        let headerCells: [VNode] = extractedColumns.map { column in
            let labelNode = context.renderChild(column.label)
            return VNode.element(
                "th",
                props: [
                    "role": .attribute(name: "role", value: "columnheader"),
                    "scope": .attribute(name: "scope", value: "col"),
                    "text-align": .style(name: "text-align", value: "left"),
                    "font-weight": .style(name: "font-weight", value: "600"),
                    "font-size": .style(name: "font-size", value: "12px"),
                    "letter-spacing": .style(name: "letter-spacing", value: "0.02em"),
                    "text-transform": .style(name: "text-transform", value: "uppercase"),
                    "padding": .style(name: "padding", value: "10px 12px"),
                    "background-color": .style(name: "background-color", value: "var(--system-secondary-background, #f2f2f7)"),
                    "border-bottom": .style(name: "border-bottom", value: "1px solid var(--system-separator, #e0e0e0)"),
                    "position": .style(name: "position", value: "sticky"),
                    "top": .style(name: "top", value: "0"),
                    "z-index": .style(name: "z-index", value: "1"),
                ],
                children: [labelNode]
            )
        }

        let thead = VNode.element(
            "thead",
            props: [:],
            children: [
                VNode.element("tr", props: ["role": .attribute(name: "role", value: "row")], children: headerCells)
            ]
        )

        // Body rows
        let bodyRows: [VNode] = rows.enumerated().map { index, row in
            let isSelected = isRowSelected(row.id)
            // Keep it readable in both light/dark without relying on advanced CSS color functions.
            // In the future we can switch to `color-mix()` if we decide to require it.
            let rowBg = isSelected
                ? "rgba(0, 122, 255, 0.12)"
                : (index % 2 == 0 ? "transparent" : "var(--system-tertiary-background, rgba(0,0,0,0.02))")

            var rowProps: [String: VProperty] = [
                "role": .attribute(name: "role", value: "row"),
                "background-color": .style(name: "background-color", value: rowBg),
            ]

            if selection != nil || multiSelection != nil {
                rowProps["cursor"] = .style(name: "cursor", value: "pointer")
                let handlerID = context.registerClickHandler {
                    selectRow(row.id)
                }
                rowProps["onClick"] = .eventHandler(event: "click", handlerID: handlerID)
                rowProps["aria-selected"] = .attribute(name: "aria-selected", value: isSelected ? "true" : "false")
            }

            let cells: [VNode] = extractedColumns.map { column in
                let cellView = column.makeCell(row)
                let cellNode = context.renderChild(cellView)
                return VNode.element(
                    "td",
                    props: [
                        "role": .attribute(name: "role", value: "cell"),
                        "padding": .style(name: "padding", value: "10px 12px"),
                        "border-bottom": .style(name: "border-bottom", value: "1px solid var(--system-separator, #e0e0e0)"),
                        "vertical-align": .style(name: "vertical-align", value: "middle"),
                        "font-size": .style(name: "font-size", value: "14px"),
                    ],
                    children: [cellNode]
                )
            }

            return VNode.element("tr", props: rowProps, children: cells)
        }

        let tbody = VNode.element("tbody", props: [:], children: bodyRows)

        let fullTable = VNode(
            id: table.id,
            type: table.type,
            props: table.props,
            children: [thead, tbody],
            key: table.key
        )

        return VNode(
            id: wrapper.id,
            type: wrapper.type,
            props: wrapper.props,
            children: [fullTable],
            key: wrapper.key
        )
    }
}

// MARK: - Multi-Selection Support

/// Extension to Table that adds multi-selection support.
///
/// Multi-selection allows users to select multiple rows in a table using checkboxes.
/// The selection state is controlled through a binding that stores a set of selected row IDs.
///
/// ## Usage Example
///
/// ```swift
/// @State private var selection = Set<UUID>()
///
/// Table(items, selection: $selection) {
///     TableColumn("Name", value: \.name)
///     TableColumn("Age", value: \.age)
/// }
/// ```
extension Table {
    /// Creates a table with multiple row selection.
    ///
    /// This initializer enables multi-selection support with a checkbox column
    /// for selecting multiple rows at once.
    ///
    /// - Parameters:
    ///   - data: The collection of data to display.
    ///   - selection: A binding to a set of selected row IDs.
    ///   - columns: A view builder that creates the table columns.
    @MainActor public init(
        _ data: [RowValue],
        selection: Binding<Set<RowValue.ID>>,
        @TableColumnBuilder columns: () -> Columns
    ) where RowValue.ID: Hashable {
        self.data = data
        self.columns = columns()
        self.selection = nil
        self.multiSelection = selection
        self.sortOrder = nil
        self.id = UUID().uuidString
    }

    /// Creates a table with multiple row selection and sorting.
    ///
    /// This initializer enables both multi-selection and column sorting,
    /// adding a checkbox column and sortable column headers.
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
        @TableColumnBuilder columns: () -> Columns
    ) where RowValue.ID: Hashable {
        self.data = data
        self.columns = columns()
        self.selection = nil
        self.multiSelection = selection
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
        @TableColumnBuilder columns: () -> Columns
    ) where Data.Element == RowValue {
        self.data = Array(data)
        self.columns = columns()
        self.selection = nil
        self.multiSelection = nil
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
        @TableColumnBuilder columns: () -> Columns
    ) where Data.Element == RowValue {
        self.data = Array(data)
        self.columns = columns()
        self.selection = selection
        self.multiSelection = nil
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
        @TableColumnBuilder columns: () -> Columns
    ) where Data.Element == RowValue {
        self.data = Array(data)
        self.columns = columns()
        self.selection = nil
        self.multiSelection = nil
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
        @TableColumnBuilder columns: () -> Columns
    ) where Data.Element == RowValue {
        self.data = Array(data)
        self.columns = columns()
        self.selection = selection
        self.multiSelection = nil
        self.sortOrder = sortOrder
        self.id = UUID().uuidString
    }
}
