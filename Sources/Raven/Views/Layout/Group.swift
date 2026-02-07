import Foundation

/// A container for grouping view content without affecting layout.
///
/// `Group` mirrors SwiftUI's `Group`: it is purely structural and does not
/// introduce an extra DOM node or visual styling. This is useful for applying
/// conditional logic and sharing modifiers over multiple sibling views.
public struct Group<Content: View>: View, Sendable {
    let content: Content

    /// Creates a group that contains the specified child content.
    ///
    /// - Parameter content: A view builder that creates the group's child views.
    @MainActor public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    /// The grouped child content.
    @MainActor public var body: some View {
        content
    }
}
