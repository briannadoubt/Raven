import Foundation

// MARK: - Picker Option ID Generator

/// Counter-based unique ID generator for picker options.
/// Foundation's UUID() relies on WASI random_get which returns 0 in WASM,
/// producing identical UUIDs. This counter ensures unique option IDs.
@MainActor
private var _pickerOptionIDCounter: UInt64 = 0

@MainActor
func nextPickerOptionID() -> String {
    _pickerOptionIDCounter += 1
    return "picker-opt-\(_pickerOptionIDCounter)"
}

// MARK: - Picker Option

/// Represents a single option in a picker.
public struct PickerOption<Selection: Hashable>: Sendable where Selection: Sendable {
    /// Unique identifier for this option
    public let id: String

    /// The value associated with this option
    public let value: Selection

    /// The label to display for this option
    public let label: String

    public init(id: String, value: Selection, label: String) {
        self.id = id
        self.value = value
        self.label = label
    }
}

// MARK: - Tag Modifier

/// A view that associates a tag value for use in selection controls.
public struct TaggedView<SelectionValue: Hashable>: View, Sendable where SelectionValue: Sendable {
    public typealias Body = Never

    /// The content view being tagged
    let content: AnyView

    /// The tag value associated with this view
    let tagValue: SelectionValue

    /// The text content extracted before type erasure (for picker option labels)
    let textLabel: String

    @MainActor init<Content: View>(content: Content, tag: SelectionValue) {
        self.content = AnyView(content)
        self.tagValue = tag
        // Extract text label before type erasure loses the concrete type
        if let text = content as? Text {
            self.textLabel = text.textContent
        } else {
            self.textLabel = ""
        }
    }
}

extension View {
    /// Tags this view with a selection value for use in pickers and other selection controls.
    ///
    /// Use this modifier to associate a value with a view inside a `Picker`.
    /// The picker uses these tags to map between displayed options and selection values.
    ///
    /// Example:
    /// ```swift
    /// Picker("Size", selection: $selectedSize) {
    ///     Text("Small").tag("S")
    ///     Text("Medium").tag("M")
    ///     Text("Large").tag("L")
    /// }
    /// ```
    ///
    /// - Parameter tag: The value to associate with this view.
    /// - Returns: A tagged view that can be used in selection controls.
    @MainActor public func tag<V: Hashable>(_ tag: V) -> TaggedView<V> where V: Sendable {
        TaggedView(content: self, tag: tag)
    }
}
