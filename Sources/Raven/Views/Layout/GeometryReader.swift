import Foundation
import JavaScriptKit

// MARK: - Geometry Types

/// A structure that contains a width and a height value.
public struct CGSize: Sendable, Hashable {
    /// The width value.
    public var width: Double

    /// The height value.
    public var height: Double

    /// Creates a size with zero width and height.
    public static let zero = CGSize(width: 0, height: 0)

    /// Creates a size with the specified width and height.
    ///
    /// - Parameters:
    ///   - width: The width value.
    ///   - height: The height value.
    public init(width: Double, height: Double) {
        self.width = width
        self.height = height
    }
}

/// A structure that contains a location in a two-dimensional coordinate system.
public struct CGPoint: Sendable, Hashable {
    /// The x-coordinate of the point.
    public var x: Double

    /// The y-coordinate of the point.
    public var y: Double

    /// The point at the origin (0, 0).
    public static let zero = CGPoint(x: 0, y: 0)

    /// Creates a point with the specified coordinates.
    ///
    /// - Parameters:
    ///   - x: The x-coordinate of the point.
    ///   - y: The y-coordinate of the point.
    public init(x: Double, y: Double) {
        self.x = x
        self.y = y
    }
}

/// A structure that contains the location and dimensions of a rectangle.
public struct CGRect: Sendable, Hashable {
    /// The origin of the rectangle.
    public var origin: CGPoint

    /// The size of the rectangle.
    public var size: CGSize

    /// The x-coordinate of the rectangle's origin.
    public var minX: Double { origin.x }

    /// The y-coordinate of the rectangle's origin.
    public var minY: Double { origin.y }

    /// The x-coordinate of the rectangle's maximum x value.
    public var maxX: Double { origin.x + size.width }

    /// The y-coordinate of the rectangle's maximum y value.
    public var maxY: Double { origin.y + size.height }

    /// The width of the rectangle.
    public var width: Double { size.width }

    /// The height of the rectangle.
    public var height: Double { size.height }

    /// The rectangle at the origin with zero width and height.
    public static let zero = CGRect(origin: .zero, size: .zero)

    /// Creates a rectangle with the specified origin and size.
    ///
    /// - Parameters:
    ///   - origin: The origin of the rectangle.
    ///   - size: The size of the rectangle.
    public init(origin: CGPoint, size: CGSize) {
        self.origin = origin
        self.size = size
    }

    /// Creates a rectangle with the specified coordinates and dimensions.
    ///
    /// - Parameters:
    ///   - x: The x-coordinate of the rectangle's origin.
    ///   - y: The y-coordinate of the rectangle's origin.
    ///   - width: The width of the rectangle.
    ///   - height: The height of the rectangle.
    public init(x: Double, y: Double, width: Double, height: Double) {
        self.origin = CGPoint(x: x, y: y)
        self.size = CGSize(width: width, height: height)
    }
}

// MARK: - Coordinate Space

/// A resolved coordinate space created by the coordinate space protocol.
public enum CoordinateSpace: Sendable, Hashable {
    /// The local coordinate space of the current view.
    case local

    /// The global coordinate space (relative to the window/document).
    case global

    /// A named coordinate space.
    case named(String)
}

// MARK: - Geometry Proxy

/// A proxy for access to the size and coordinate space of a container view.
///
/// Use `GeometryProxy` to read geometry information about a view, such as its size
/// and position in different coordinate spaces.
///
/// Example:
/// ```swift
/// GeometryReader { geometry in
///     Text("Width: \(geometry.size.width)")
/// }
/// ```
public struct GeometryProxy: Sendable {
    /// The size of the container view.
    public let size: CGSize

    /// The safe area insets of the container view.
    ///
    /// Note: For the initial implementation, this returns zero insets.
    /// Future versions will integrate with the browser's safe area.
    public var safeAreaInsets: EdgeInsets {
        EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
    }

    /// Internal storage for frame information in different coordinate spaces.
    private let localFrame: CGRect
    private let globalFrame: CGRect

    /// Creates a geometry proxy with the specified size and frames.
    ///
    /// - Parameters:
    ///   - size: The size of the container view.
    ///   - localFrame: The frame in local coordinates.
    ///   - globalFrame: The frame in global coordinates.
    internal init(size: CGSize, localFrame: CGRect, globalFrame: CGRect) {
        self.size = size
        self.localFrame = localFrame
        self.globalFrame = globalFrame
    }

    /// Returns the container view's bounds rectangle in the specified coordinate space.
    ///
    /// - Parameter coordinateSpace: The coordinate space to use for the bounds.
    /// - Returns: A rectangle representing the view's bounds.
    public func frame(in coordinateSpace: CoordinateSpace) -> CGRect {
        switch coordinateSpace {
        case .local:
            return localFrame
        case .global:
            return globalFrame
        case .named:
            // For now, treat named coordinate spaces as global
            // A full implementation would track named coordinate spaces
            return globalFrame
        }
    }
}

// MARK: - Geometry Reader

/// A container view that defines its content as a function of its own size and coordinate space.
///
/// `GeometryReader` is a layout view that provides geometry information to its content closure.
/// This allows views to adapt their appearance based on the size and position of their container.
///
/// Example:
/// ```swift
/// GeometryReader { geometry in
///     VStack {
///         Text("Width: \(geometry.size.width)")
///         Text("Height: \(geometry.size.height)")
///     }
/// }
/// ```
///
/// The GeometryReader expands to fill all available space in its parent, similar to a `Color` view.
///
/// For advanced positioning, you can query the frame in different coordinate spaces:
/// ```swift
/// GeometryReader { geometry in
///     let globalFrame = geometry.frame(in: .global)
///     Text("Global position: (\(globalFrame.minX), \(globalFrame.minY))")
/// }
/// ```
public struct GeometryReader<Content: View>: View, Sendable {
    /// The content closure that receives geometry information.
    private let content: @Sendable @MainActor (GeometryProxy) -> Content

    /// Creates a geometry reader with the specified content.
    ///
    /// - Parameter content: A view builder that creates the content based on geometry information.
    @MainActor public init(@ViewBuilder content: @escaping @Sendable @MainActor (GeometryProxy) -> Content) {
        self.content = content
    }

    /// The body of the geometry reader.
    ///
    /// GeometryReader is not a primitive view - it has a body that wraps its content
    /// in a special container that will be measured by the rendering system.
    @MainActor public var body: some View {
        _GeometryReaderContainer(content: content)
    }
}

// MARK: - Internal Container

/// Internal container view for GeometryReader that handles DOM measurement.
///
/// This is a primitive view that renders to a div element and uses JavaScriptKit
/// to measure its size and position in the DOM.
internal struct _GeometryReaderContainer<Content: View>: View, Sendable {
    typealias Body = Never

    let content: @Sendable @MainActor (GeometryProxy) -> Content

    @MainActor init(content: @escaping @Sendable @MainActor (GeometryProxy) -> Content) {
        self.content = content
    }

    /// Converts this container to a virtual DOM node.
    ///
    /// The container is rendered as a div with specific styling to fill available space
    /// and enable geometry measurement. The actual measurement and content rendering
    /// will be handled by the RenderCoordinator.
    ///
    /// - Returns: A VNode configured as a geometry container.
    @MainActor public func toVNode() -> VNode {
        // Create a container div that fills available space
        let props: [String: VProperty] = [
            "display": .style(name: "display", value: "block"),
            "position": .style(name: "position", value: "relative"),
            "width": .style(name: "width", value: "100%"),
            "height": .style(name: "height", value: "100%"),
            // Mark this as a geometry reader container for the render coordinator
            "data-geometry-reader": .attribute(name: "data-geometry-reader", value: "true")
        ]

        return VNode.element(
            "div",
            props: props,
            children: []
        )
    }
}

// MARK: - DOM Bridge Extensions

extension DOMBridge {
    /// Measures the geometry of a DOM element.
    ///
    /// Uses getBoundingClientRect() to measure the element's size and position
    /// in both local and global coordinate spaces.
    ///
    /// - Parameter element: The DOM element to measure.
    /// - Returns: A GeometryProxy with the measured geometry information.
    @MainActor public func measureGeometry(element: JSObject) -> GeometryProxy {
        // Get the bounding client rect
        let rect = element.getBoundingClientRect!()

        // Extract dimensions
        let width = rect.width.number ?? 0
        let height = rect.height.number ?? 0
        let x = rect.x.number ?? 0
        let y = rect.y.number ?? 0

        // Create size
        let size = CGSize(width: width, height: height)

        // Local frame is relative to the element itself
        let localFrame = CGRect(x: 0, y: 0, width: width, height: height)

        // Global frame is relative to the viewport
        let globalFrame = CGRect(x: x, y: y, width: width, height: height)

        return GeometryProxy(size: size, localFrame: localFrame, globalFrame: globalFrame)
    }

    /// Creates a default geometry proxy with placeholder values.
    ///
    /// This is used when DOM measurement is not yet available, such as during
    /// initial rendering before the element is mounted to the DOM.
    ///
    /// - Returns: A GeometryProxy with zero size and frames.
    @MainActor public func createDefaultGeometry() -> GeometryProxy {
        GeometryProxy(
            size: .zero,
            localFrame: .zero,
            globalFrame: .zero
        )
    }
}
