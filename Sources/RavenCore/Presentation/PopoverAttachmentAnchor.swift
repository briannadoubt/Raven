import Foundation

/// Defines how a popover attaches to its source view.
///
/// The `PopoverAttachmentAnchor` determines the point or region on the source view
/// where the popover will be anchored. This affects both the positioning and the
/// visual connection between the popover and its source.
///
/// ## Anchor Types
///
/// There are two main ways to specify an anchor:
///
/// - **Rect anchor**: Attaches to a rectangular region of the source view
/// - **Point anchor**: Attaches to a specific point in the source view's coordinate space
///
/// ## Usage
///
/// ### Attaching to the entire view bounds (default)
///
/// ```swift
/// .popover(isPresented: $showPopover, attachmentAnchor: .rect(.bounds)) {
///     Text("Popover content")
/// }
/// ```
///
/// ### Attaching to a specific rectangle
///
/// ```swift
/// let customRect = CGRect(x: 10, y: 10, width: 50, height: 50)
/// .popover(isPresented: $showPopover, attachmentAnchor: .rect(.rect(customRect))) {
///     Text("Anchored to custom rect")
/// }
/// ```
///
/// ### Attaching to a point
///
/// ```swift
/// .popover(isPresented: $showPopover, attachmentAnchor: .point(.topLeading)) {
///     Text("Anchored to top-leading corner")
/// }
/// ```
///
/// ## Topics
///
/// ### Anchor Cases
/// - ``rect(_:)``
/// - ``point(_:)``
///
/// ### Rect Anchor Types
/// - ``Anchor``
///
/// - Note: When using `.rect(.bounds)`, the popover will be positioned relative to
///   the entire bounds of the source view. When using a specific rect or point,
///   positioning is calculated relative to that anchor.
public enum PopoverAttachmentAnchor: Sendable, Hashable {
    /// Attaches the popover to a rectangular region of the source view.
    ///
    /// Use this anchor type when you want the popover to be positioned relative
    /// to a specific rectangular region, such as the entire view bounds or a
    /// custom rect within the view.
    ///
    /// ## Example
    ///
    /// ```swift
    /// // Attach to the entire view
    /// .popover(isPresented: $show, attachmentAnchor: .rect(.bounds)) {
    ///     PopoverContent()
    /// }
    ///
    /// // Attach to a specific region
    /// let region = CGRect(x: 0, y: 0, width: 100, height: 50)
    /// .popover(isPresented: $show, attachmentAnchor: .rect(.rect(region))) {
    ///     PopoverContent()
    /// }
    /// ```
    case rect(Anchor)

    /// Attaches the popover to a specific point in the source view's coordinate space.
    ///
    /// Use this anchor type when you want the popover to be positioned relative
    /// to a specific point, such as a corner or the center of the view.
    ///
    /// ## Example
    ///
    /// ```swift
    /// // Attach to the top-leading corner
    /// .popover(isPresented: $show, attachmentAnchor: .point(.topLeading)) {
    ///     PopoverContent()
    /// }
    ///
    /// // Attach to the center
    /// .popover(isPresented: $show, attachmentAnchor: .point(.center)) {
    ///     PopoverContent()
    /// }
    /// ```
    case point(UnitPoint)

    // MARK: - Nested Anchor Type

    /// Specifies a rectangular anchor region within a view.
    ///
    /// The `Anchor` type defines different ways to specify a rectangular region
    /// that the popover will attach to. This can be the entire bounds of the
    /// source view or a specific rectangle within it.
    ///
    /// ## Usage
    ///
    /// ### Using the entire view bounds
    ///
    /// ```swift
    /// .popover(isPresented: $show, attachmentAnchor: .rect(.bounds)) {
    ///     Text("Attached to bounds")
    /// }
    /// ```
    ///
    /// ### Using a specific rectangle
    ///
    /// ```swift
    /// let rect = CGRect(x: 20, y: 20, width: 100, height: 50)
    /// .popover(isPresented: $show, attachmentAnchor: .rect(.rect(rect))) {
    ///     Text("Attached to custom rect")
    /// }
    /// ```
    ///
    /// ## Topics
    ///
    /// ### Anchor Cases
    /// - ``bounds``
    /// - ``rect(_:)``
    public enum Anchor: Sendable, Hashable {
        /// The entire bounds of the source view.
        ///
        /// When using this anchor, the popover will be positioned relative to
        /// the full rectangular bounds of the source view. This is the most
        /// common anchor type and provides a natural attachment point for
        /// most popovers.
        ///
        /// ## Example
        ///
        /// ```swift
        /// Button("Show Info") {
        ///     showPopover = true
        /// }
        /// .popover(isPresented: $showPopover, attachmentAnchor: .rect(.bounds)) {
        ///     Text("Information about this button")
        /// }
        /// ```
        case bounds

        /// A specific rectangular region within the source view.
        ///
        /// Use this anchor when you want the popover to attach to a specific
        /// region within the view, rather than the entire view bounds. The
        /// rectangle is specified in the view's local coordinate space.
        ///
        /// ## Example
        ///
        /// ```swift
        /// // Attach to the right half of a view
        /// GeometryReader { geometry in
        ///     let rightHalf = CGRect(
        ///         x: geometry.size.width / 2,
        ///         y: 0,
        ///         width: geometry.size.width / 2,
        ///         height: geometry.size.height
        ///     )
        ///
        ///     MyView()
        ///         .popover(isPresented: $show, attachmentAnchor: .rect(.rect(rightHalf))) {
        ///             Text("Attached to right half")
        ///         }
        /// }
        /// ```
        ///
        /// - Parameter rect: The rectangular region in the source view's
        ///   coordinate space to attach to.
        case rect(CGRect)
    }
}

// MARK: - Default Values

extension PopoverAttachmentAnchor {
    /// The default attachment anchor for popovers.
    ///
    /// The default anchor is `.rect(.bounds)`, which attaches the popover to
    /// the entire bounds of the source view. This provides the most natural
    /// and expected behavior for most popovers.
    ///
    /// ## Usage
    ///
    /// You typically don't need to use this property directly, as it's applied
    /// automatically when no anchor is specified:
    ///
    /// ```swift
    /// // These are equivalent:
    /// .popover(isPresented: $show) { /* content */ }
    /// .popover(isPresented: $show, attachmentAnchor: .default) { /* content */ }
    /// ```
    public static let `default`: PopoverAttachmentAnchor = .rect(.bounds)
}

// MARK: - CustomStringConvertible

extension PopoverAttachmentAnchor: CustomStringConvertible {
    public var description: String {
        switch self {
        case .rect(let anchor):
            return "PopoverAttachmentAnchor.rect(\(anchor))"
        case .point(let unitPoint):
            return "PopoverAttachmentAnchor.point(\(unitPoint))"
        }
    }
}

extension PopoverAttachmentAnchor.Anchor: CustomStringConvertible {
    public var description: String {
        switch self {
        case .bounds:
            return ".bounds"
        case .rect(let rect):
            return ".rect(origin: (\(rect.origin.x), \(rect.origin.y)), size: (\(rect.size.width), \(rect.size.height)))"
        }
    }
}
