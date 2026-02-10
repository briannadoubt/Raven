/// Classification of fiber nodes in the tree.
///
/// Each fiber has a tag indicating what kind of element it represents.
/// This mirrors React's fiber tags and determines how the fiber is
/// processed during reconciliation.
public enum FiberTag: Sendable, Hashable {
    /// A host element (e.g., a real DOM element like `<div>`, `<button>`).
    case host

    /// A composite component (a SwiftUI `View` with a `.body`).
    case composite

    /// A text node (leaf content).
    case text

    /// A fragment grouping children without a wrapper element.
    case fragment

    /// The root of the fiber tree (mounted to the DOM container).
    case root
}
