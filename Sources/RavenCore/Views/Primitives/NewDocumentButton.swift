import Foundation

/// A button that triggers creation of a new document.
@MainActor
public struct NewDocumentButton<Label: View>: View, Sendable {
    private let action: @Sendable @MainActor () -> Void
    private let label: Label

    /// Creates a new document button with a custom label.
    @MainActor public init(
        action: @escaping @Sendable @MainActor () -> Void,
        @ViewBuilder label: () -> Label
    ) {
        self.action = action
        self.label = label()
    }

    @MainActor public var body: some View {
        Button(action: action) {
            label
        }
    }
}

extension NewDocumentButton where Label == Text {
    /// Creates a new document button with a default label.
    @MainActor public init(action: @escaping @Sendable @MainActor () -> Void) {
        self.init(action: action) {
            Text("New Document")
        }
    }

    /// Creates a new document button with a string title.
    @MainActor public init(_ title: String, action: @escaping @Sendable @MainActor () -> Void) {
        self.init(action: action) {
            Text(title)
        }
    }

    /// Creates a new document button with a localized title key.
    @MainActor public init(_ titleKey: LocalizedStringKey, action: @escaping @Sendable @MainActor () -> Void) {
        self.init(action: action) {
            Text(titleKey)
        }
    }
}
