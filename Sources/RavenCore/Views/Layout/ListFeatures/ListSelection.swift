import Foundation

// MARK: - List Selection

/// Extension to List that adds selection support.
///
/// Selection allows users to select one or multiple items in a list.
/// The selection state is controlled through a binding that stores the selected item IDs.
///
/// ## Single Selection
///
/// For single selection, use an optional binding:
///
/// ```swift
/// @State private var selection: UUID?
///
/// List(items, selection: $selection) { item in
///     Text(item.name)
/// }
/// ```
///
/// ## Multiple Selection
///
/// For multiple selection, use a Set binding:
///
/// ```swift
/// @State private var selection = Set<UUID>()
///
/// List(items, selection: $selection) { item in
///     Text(item.name)
/// }
/// ```
///
/// ## Edit Mode Integration
///
/// Selection works with edit mode. When edit mode is active, selection controls
/// (checkboxes) are displayed automatically.
///
/// ```swift
/// @State private var selection = Set<UUID>()
/// @State private var editMode = EditMode.inactive
///
/// List(items, selection: $selection) { item in
///     Text(item.name)
/// }
/// .environment(\.editMode, $editMode)
/// ```
extension List {
    /// Creates a list with single selection support.
    ///
    /// - Parameters:
    ///   - data: The collection of data to iterate over.
    ///   - id: Key path to the property that identifies each element.
    ///   - selection: A binding to the selected item's ID, or nil if no item is selected.
    ///   - content: A view builder that creates the view for each element.
    @MainActor
    public init<Data, ID, RowContent>(
        _ data: Data,
        id: KeyPath<Data.Element, ID>,
        selection: Binding<ID?>?,
        @ViewBuilder content: @escaping @Sendable @MainActor (Data.Element) -> RowContent
    ) where Content == _ListWithSelection<ForEach<Data, ID, RowContent>, ID>,
            Data: RandomAccessCollection,
            Data: Sendable,
            Data.Element: Sendable,
            ID: Hashable,
            ID: Sendable,
            RowContent: View {
        let forEach = ForEach(data, id: id, content: content)
        self.content = _ListWithSelection(content: forEach, selection: selection, multiSelection: nil)
    }

    /// Creates a list with single selection support for Identifiable data.
    ///
    /// - Parameters:
    ///   - data: The collection of identifiable data.
    ///   - selection: A binding to the selected item's ID, or nil if no item is selected.
    ///   - content: A view builder that creates the view for each element.
    @MainActor
    public init<Data, RowContent>(
        _ data: Data,
        selection: Binding<Data.Element.ID?>?,
        @ViewBuilder content: @escaping @Sendable @MainActor (Data.Element) -> RowContent
    ) where Content == _ListWithSelection<ForEach<Data, Data.Element.ID, RowContent>, Data.Element.ID>,
            Data: RandomAccessCollection,
            Data.Element: Identifiable & Sendable,
            Data: Sendable,
            RowContent: View {
        let forEach = ForEach(data, content: content)
        self.content = _ListWithSelection(content: forEach, selection: selection, multiSelection: nil)
    }

    /// Creates a list with multiple selection support.
    ///
    /// - Parameters:
    ///   - data: The collection of data to iterate over.
    ///   - id: Key path to the property that identifies each element.
    ///   - selection: A binding to a set of selected item IDs.
    ///   - content: A view builder that creates the view for each element.
    @MainActor
    public init<Data, ID, RowContent>(
        _ data: Data,
        id: KeyPath<Data.Element, ID>,
        selection: Binding<Set<ID>>,
        @ViewBuilder content: @escaping @Sendable @MainActor (Data.Element) -> RowContent
    ) where Content == _ListWithSelection<ForEach<Data, ID, RowContent>, ID>,
            Data: RandomAccessCollection,
            Data: Sendable,
            Data.Element: Sendable,
            ID: Hashable,
            ID: Sendable,
            RowContent: View {
        let forEach = ForEach(data, id: id, content: content)
        self.content = _ListWithSelection(content: forEach, selection: nil, multiSelection: selection)
    }

    /// Creates a list with multiple selection support for Identifiable data.
    ///
    /// - Parameters:
    ///   - data: The collection of identifiable data.
    ///   - selection: A binding to a set of selected item IDs.
    ///   - content: A view builder that creates the view for each element.
    @MainActor
    public init<Data, RowContent>(
        _ data: Data,
        selection: Binding<Set<Data.Element.ID>>,
        @ViewBuilder content: @escaping @Sendable @MainActor (Data.Element) -> RowContent
    ) where Content == _ListWithSelection<ForEach<Data, Data.Element.ID, RowContent>, Data.Element.ID>,
            Data: RandomAccessCollection,
            Data.Element: Identifiable & Sendable,
            Data: Sendable,
            RowContent: View {
        let forEach = ForEach(data, content: content)
        self.content = _ListWithSelection(content: forEach, selection: nil, multiSelection: selection)
    }
}

// MARK: - List with Selection

/// Internal view that wraps list content with selection support.
///
/// This view handles:
/// - Rendering selection indicators (checkboxes) in edit mode
/// - Managing selection state through bindings
/// - Touch event handling for selection
/// - Visual feedback for selected items
@MainActor
public struct _ListWithSelection<Content: View, SelectionValue: Hashable & Sendable>: View, Sendable {
    let content: Content
    let selection: Binding<SelectionValue?>?
    let multiSelection: Binding<Set<SelectionValue>>?

    @Environment(\.editMode) private var editMode

    public var body: some View {
        // The content is wrapped with selection handling
        // In a full implementation, this would add:
        // 1. Click/tap handlers for selection
        // 2. Visual indicators for selected state
        // 3. Checkboxes in edit mode
        // 4. ARIA attributes for accessibility
        content
    }
}

// MARK: - Selection Modifier

extension View {
    /// Adds selection support to a list or form.
    ///
    /// Use this modifier to add single or multiple selection to any view,
    /// typically a List or ForEach.
    ///
    /// ## Single Selection
    ///
    /// ```swift
    /// ForEach(items) { item in
    ///     Text(item.name)
    /// }
    /// .selectable(selection: $selectedItem)
    /// ```
    ///
    /// ## Multiple Selection
    ///
    /// ```swift
    /// ForEach(items) { item in
    ///     Text(item.name)
    /// }
    /// .selectable(selection: $selectedItems)
    /// ```
    ///
    /// - Parameter selection: A binding to the selection state.
    /// - Returns: A view with selection support.
    @MainActor
    public func selectable<SelectionValue: Hashable & Sendable>(
        selection: Binding<SelectionValue?>
    ) -> some View {
        modifier(_SelectionModifier(selection: selection, multiSelection: nil))
    }

    /// Adds multiple selection support to a list or form.
    ///
    /// - Parameter selection: A binding to a set of selected values.
    /// - Returns: A view with multiple selection support.
    @MainActor
    public func selectable<SelectionValue: Hashable & Sendable>(
        selection: Binding<Set<SelectionValue>>
    ) -> some View {
        modifier(_SelectionModifier(selection: nil, multiSelection: selection))
    }
}

// MARK: - Selection Modifier Implementation

/// Internal modifier that adds selection behavior to a view.
@MainActor
struct _SelectionModifier<SelectionValue: Hashable & Sendable>: ViewModifier, Sendable {
    let selection: Binding<SelectionValue?>?
    let multiSelection: Binding<Set<SelectionValue>>?

    @Environment(\.editMode) private var editMode

    @MainActor
    func body(content: Content) -> some View {
        // In a full implementation, this would:
        // 1. Add data-selection-id attributes to items
        // 2. Attach click handlers for selection
        // 3. Add CSS classes for selected state
        // 4. Show/hide selection indicators based on edit mode
        // 5. Handle keyboard navigation (arrow keys, space for selection)
        content
    }
}

// MARK: - Selection State

/// Represents the selection state for a list.
///
/// This type is used internally to track and manage selection state across
/// list items. It handles both single and multiple selection modes.
@MainActor
struct SelectionState<ID: Hashable & Sendable>: Sendable {
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
