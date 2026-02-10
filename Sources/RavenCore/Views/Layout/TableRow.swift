import Foundation

/// A wrapper view that represents a single row in a table.
///
/// `TableRow` is used internally by `Table` to wrap row content and provide
/// consistent row styling and selection behavior. Each row corresponds to a
/// single element from the table's data collection.
///
/// ## Overview
///
/// You typically don't create `TableRow` instances directly. The `Table` view
/// automatically creates rows as it iterates over its data. However, understanding
/// `TableRow` is useful when working with table customization and selection.
///
/// ## Row Selection
///
/// When a table has a selection binding, rows become interactive and can be
/// selected by clicking. Selected rows are visually distinguished with a
/// background color.
///
/// ## Accessibility
///
/// Each row includes appropriate ARIA attributes to ensure proper accessibility
/// for screen readers and assistive technologies. Rows are marked with `role="row"`
/// and include selection state information when applicable.
public struct TableRow<RowValue: Sendable, Content: View>: View, PrimitiveView, Sendable {
    public typealias Body = Never

    /// The row data
    let rowValue: RowValue

    /// The cell content for this row
    let content: Content

    /// Whether this row is selected
    let isSelected: Bool

    /// Callback invoked when the row is clicked
    let onSelect: (@Sendable @MainActor () -> Void)?

    /// Unique identifier for this row
    let id: String

    // MARK: - Initializers

    /// Creates a table row.
    ///
    /// - Parameters:
    ///   - rowValue: The data for this row.
    ///   - id: A unique identifier for this row.
    ///   - isSelected: Whether this row is currently selected.
    ///   - onSelect: Callback invoked when the row is clicked.
    ///   - content: The cell content for this row.
    @MainActor public init(
        rowValue: RowValue,
        id: String,
        isSelected: Bool,
        onSelect: (@Sendable @MainActor () -> Void)?,
        content: Content
    ) {
        self.rowValue = rowValue
        self.content = content
        self.isSelected = isSelected
        self.onSelect = onSelect
        self.id = id
    }

    // MARK: - VNode Conversion

    /// Converts this TableRow to a virtual DOM node.
    ///
    /// The TableRow is rendered as a `<tr>` element with:
    /// - `role="row"` for accessibility
    /// - Background color styling for selected state
    /// - Hover effects when selectable
    /// - Click handler when selection is enabled
    ///
    /// - Returns: A VNode configured as a table row element.
    @MainActor public func toVNode() -> VNode {
        var props: [String: VProperty] = [
            // Accessibility
            "role": .attribute(name: "role", value: "row"),
        ]

        // Selection styling
        if isSelected {
            props["background-color"] = .style(name: "background-color", value: "#dbeafe")
            props["aria-selected"] = .attribute(name: "aria-selected", value: "true")
        } else if onSelect != nil {
            // Hoverable when selectable
            props["background-color"] = .style(name: "background-color", value: "transparent")
        }

        // Add click handler if selectable
        if onSelect != nil {
            props["cursor"] = .style(name: "cursor", value: "pointer")
            let handlerID = UUID()
            props["onClick"] = .eventHandler(event: "click", handlerID: handlerID)

            // Add hover effect via CSS class
            props["class"] = .attribute(name: "class", value: "table-row-selectable")
        }

        // The children (table cells) will be populated by the RenderCoordinator
        return VNode.element(
            "tr",
            props: props,
            children: []
        )
    }
}

// MARK: - CSS Helper

/// Global CSS for table row hover effects.
///
/// This CSS should be injected into the document head when a table with
/// selection is rendered. It provides smooth hover transitions for selectable rows.
internal let tableRowCSS = """
<style>
.table-row-selectable:hover {
    background-color: #f3f4f6 !important;
    transition: background-color 0.15s ease-in-out;
}
</style>
"""
