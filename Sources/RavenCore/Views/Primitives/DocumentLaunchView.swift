import Foundation

/// A view that presents document-launch related content.
///
/// Raven's implementation focuses on SwiftUI API compatibility while rendering a
/// clear, browser-friendly launch surface.
@MainActor
public struct DocumentLaunchView<Content: View>: View, Sendable {
    private let content: Content

    /// Creates a document launch view with custom content.
    @MainActor public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    @MainActor public var body: some View {
        VStack(spacing: 12) {
            content
        }
        .padding(16)
        .background(Color.secondarySystemBackground)
        .cornerRadius(12)
    }
}

extension DocumentLaunchView where Content == _DefaultDocumentLaunchContent {
    /// Creates a document launch view with a default title and hint.
    @MainActor public init() {
        self.content = _DefaultDocumentLaunchContent()
    }
}

@MainActor
public struct _DefaultDocumentLaunchContent: View, Sendable {
    @MainActor public init() {}

    @MainActor public var body: some View {
        VStack(spacing: 8) {
            Text("Documents")
                .font(.headline)
            Text("Create or open a document to get started.")
                .font(.caption)
                .foregroundColor(Color.secondaryLabel)
        }
    }
}
