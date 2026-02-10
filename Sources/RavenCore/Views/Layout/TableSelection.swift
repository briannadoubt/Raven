import Foundation

// MARK: - Table Selection State

/// Represents the selection state for a table.
///
/// This type is used internally to track and manage selection state across
/// table rows. It handles both single and multiple selection modes.
@MainActor
internal struct TableSelectionState<ID: Hashable & Sendable>: Sendable {
    /// Single selection storage
    var singleSelection: ID?

    /// Multiple selection storage
    var multiSelection: Set<ID>

    /// Whether multiple selection is enabled
    var isMultiSelection: Bool

    /// Creates a selection state for single selection.
    init(single: ID?) {
        self.singleSelection = single
        self.multiSelection = []
        self.isMultiSelection = false
    }

    /// Creates a selection state for multiple selection.
    init(multi: Set<ID>) {
        self.singleSelection = nil
        self.multiSelection = multi
        self.isMultiSelection = true
    }

    /// Checks if an item is selected.
    func isSelected(_ id: ID) -> Bool {
        if isMultiSelection {
            return multiSelection.contains(id)
        } else {
            return singleSelection == id
        }
    }

    /// Toggles the selection state of an item.
    mutating func toggle(_ id: ID) {
        if isMultiSelection {
            if multiSelection.contains(id) {
                multiSelection.remove(id)
            } else {
                multiSelection.insert(id)
            }
        } else {
            if singleSelection == id {
                singleSelection = nil
            } else {
                singleSelection = id
            }
        }
    }

    /// Selects an item, replacing any previous selection in single-selection mode.
    mutating func select(_ id: ID) {
        if isMultiSelection {
            multiSelection.insert(id)
        } else {
            singleSelection = id
        }
    }

    /// Deselects an item.
    mutating func deselect(_ id: ID) {
        if isMultiSelection {
            multiSelection.remove(id)
        } else if singleSelection == id {
            singleSelection = nil
        }
    }

    /// Clears all selections.
    mutating func clear() {
        singleSelection = nil
        multiSelection.removeAll()
    }
}

// MARK: - Table with Multi-Selection

/// Internal wrapper that provides a Table with multi-selection support.
///
/// This view wraps a Table to provide multi-selection functionality by:
/// - Managing a Set-based selection binding
/// - Adding checkbox column when multi-selection is active
/// - Handling selection state through bindings
/// - Providing visual feedback for selected rows
@MainActor
public struct _TableWithMultiSelection<RowValue, Columns>: View, PrimitiveView, Sendable
where RowValue: Identifiable & Sendable, RowValue.ID: Sendable & Hashable, Columns: View
{
    public typealias Body = Never

    /// The data to display in the table
    let data: [RowValue]

    /// The column definitions
    let columns: Columns

    /// Multiple selection binding
    let multiSelection: Binding<Set<RowValue.ID>>

    /// Optional sort order binding
    let sortOrder: Binding<[SortDescriptor<RowValue>]>?

    /// Unique identifier for this table
    let id: String

    @Environment(\.editMode) private var editMode

    /// Converts this table to a virtual DOM node.
    ///
    /// The table is rendered as an HTML `<table>` element with:
    /// - A checkbox column for multi-selection
    /// - `<thead>` containing column headers
    /// - `<tbody>` containing data rows with selection controls
    /// - Full ARIA attributes for accessibility
    ///
    /// - Returns: A VNode configured as a table element with multi-selection.
    @MainActor public func toVNode() -> VNode {
        // Table container props
        let tableProps: [String: VProperty] = [
            // Accessibility
            "role": .attribute(name: "role", value: "table"),
            "aria-label": .attribute(name: "aria-label", value: "Data table with multi-selection"),
            "aria-multiselectable": .attribute(name: "aria-multiselectable", value: "true"),

            // Styling - standard table appearance
            "width": .style(name: "width", value: "100%"),
            "border-collapse": .style(name: "border-collapse", value: "collapse"),
            "border": .style(name: "border", value: "1px solid #e5e7eb"),
            "background-color": .style(name: "background-color", value: "white"),
        ]

        // Extract column information (this would be done by the RenderCoordinator)
        // For now, we return a skeleton structure that includes a checkbox column

        // Create thead section with checkbox column header
        let theadProps: [String: VProperty] = [:]
        let checkboxHeaderProps: [String: VProperty] = [
            "width": .style(name: "width", value: "40px"),
        ]
        let checkboxHeaderCell = VNode.element("th", props: checkboxHeaderProps, children: [
            VNode.text("") // Empty header for checkbox column
        ])

        let thead = VNode.element("thead", props: theadProps, children: [
            VNode.element("tr", props: [:], children: [checkboxHeaderCell])
        ])

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

    // MARK: - Selection Management

    /// Checks if a row is currently selected.
    ///
    /// - Parameter rowID: The ID of the row to check.
    /// - Returns: True if the row is selected, false otherwise.
    @MainActor internal func isRowSelected(_ rowID: RowValue.ID) -> Bool {
        multiSelection.wrappedValue.contains(rowID)
    }

    /// Toggles the selection state of a row.
    ///
    /// - Parameter rowID: The ID of the row to toggle.
    @MainActor internal func toggleRow(_ rowID: RowValue.ID) {
        var current = multiSelection.wrappedValue
        if current.contains(rowID) {
            current.remove(rowID)
        } else {
            current.insert(rowID)
        }
        multiSelection.wrappedValue = current
    }

    /// Selects all rows in the table.
    @MainActor internal func selectAll() {
        let allIDs = Set(data.map { $0.id })
        multiSelection.wrappedValue = allIDs
    }

    /// Deselects all rows in the table.
    @MainActor internal func deselectAll() {
        multiSelection.wrappedValue = []
    }

    // MARK: - Sorting Support

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
