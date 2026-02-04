import Foundation
import JavaScriptKit

/// Manages viewport visibility detection using the IntersectionObserver API.
///
/// `ViewportManager` provides a high-level Swift interface to the browser's
/// IntersectionObserver API, which efficiently tracks when elements enter or
/// exit the viewport. This is essential for virtual scrolling to know which
/// items should be rendered.
///
/// The manager handles:
/// - Setting up IntersectionObserver with optimal configuration
/// - Tracking which elements are currently visible
/// - Providing callbacks when visibility changes
/// - Managing observer lifecycle and cleanup
///
/// Example:
/// ```swift
/// let manager = ViewportManager(rootMargin: 200) { entries in
///     for entry in entries {
///         if entry.isIntersecting {
///             print("Item became visible")
///         }
///     }
/// }
///
/// // Observe an element
/// manager.observe(element)
///
/// // Stop observing
/// manager.unobserve(element)
/// ```
@MainActor
public final class ViewportManager: Sendable {

    // MARK: - Types

    /// Represents an intersection observer entry
    public struct IntersectionEntry {
        /// The observed element
        public let target: JSObject

        /// Whether the element is intersecting with the viewport
        public let isIntersecting: Bool

        /// The ratio of the element that is visible (0.0 to 1.0)
        public let intersectionRatio: Double

        /// Bounding rectangle of the intersection
        public let boundingClientRect: CGRect

        /// Bounding rectangle of the intersection area
        public let intersectionRect: CGRect

        /// Bounding rectangle of the root (viewport)
        public let rootBounds: CGRect

        /// Time when the intersection occurred
        public let time: Double
    }

    /// Callback type for intersection changes
    public typealias IntersectionCallback = @MainActor @Sendable ([IntersectionEntry]) -> Void

    // MARK: - Properties

    /// The IntersectionObserver instance
    private var observer: JSObject?

    /// Closure to call when intersections change
    private let callback: IntersectionCallback

    /// Root element for intersection (nil = viewport)
    private let root: JSObject?

    /// Root margin in pixels (expands/shrinks the viewport)
    private let rootMargin: Int

    /// Threshold values for triggering callbacks
    private let thresholds: [Double]

    /// Set of currently observed elements
    private var observedElements: Set<ObjectIdentifier> = []

    /// Map of element identifiers to JSObjects for cleanup
    private var elementMap: [ObjectIdentifier: JSObject] = [:]

    /// JSClosure for the observer callback (kept alive)
    private var observerClosure: JSClosure?

    // MARK: - Initialization

    /// Initialize a new ViewportManager.
    ///
    /// - Parameters:
    ///   - root: Root element for intersection (nil = viewport)
    ///   - rootMargin: Margin around root in pixels (positive = expand, negative = shrink)
    ///   - thresholds: Array of threshold values (0.0 to 1.0) for triggering callbacks
    ///   - callback: Closure called when intersections change
    public init(
        root: JSObject? = nil,
        rootMargin: Int = 0,
        thresholds: [Double] = [0.0],
        callback: @escaping IntersectionCallback
    ) {
        self.root = root
        self.rootMargin = rootMargin
        self.thresholds = thresholds
        self.callback = callback

        setupObserver()
    }

    deinit {
        // Note: Cannot call MainActor methods in deinit
        // Cleanup will happen when the observer is garbage collected
        // or when disconnect() is called explicitly before deinit
    }

    // MARK: - Setup

    /// Set up the IntersectionObserver with configuration.
    private func setupObserver() {
        // Create the callback closure
        let closure = JSClosure { [weak self] args -> JSValue in
            guard let self = self, args.count > 0 else {
                return .undefined
            }

            Task { @MainActor in
                self.handleIntersection(args[0])
            }

            return .undefined
        }

        self.observerClosure = closure

        // Build options object
        let options = JSObject.global.Object.function!.new()

        // Set root
        if let root = root {
            options.root = .object(root)
        } else {
            options.root = .null
        }

        // Set rootMargin
        options.rootMargin = .string("\(rootMargin)px")

        // Set threshold
        let thresholdArray = JSObject.global.Array.function!.new()
        for (index, threshold) in thresholds.enumerated() {
            thresholdArray[index] = .number(threshold)
        }
        options.threshold = .object(thresholdArray)

        // Create IntersectionObserver
        let observerConstructor = JSObject.global.IntersectionObserver.function!
        self.observer = observerConstructor.new(closure, options)
    }

    /// Handle intersection observer callback from JavaScript.
    ///
    /// - Parameter entriesObject: JSObject containing the intersection entries
    private func handleIntersection(_ entriesObject: JSValue) {
        guard let entriesObj = entriesObject.object else { return }

        // Convert JSObject entries to Swift array
        var entries: [IntersectionEntry] = []

        let length = entriesObj.length.number ?? 0
        for i in 0..<Int(length) {
            if let entry = parseEntry(entriesObj[i]) {
                entries.append(entry)
            }
        }

        // Call the user's callback
        callback(entries)
    }

    /// Parse a single IntersectionObserverEntry from JavaScript.
    ///
    /// - Parameter entryValue: JSValue containing the entry
    /// - Returns: Parsed IntersectionEntry, or nil if parsing failed
    private func parseEntry(_ entryValue: JSValue) -> IntersectionEntry? {
        guard let entry = entryValue.object else { return nil }

        let target = entry.target.object!
        let isIntersecting = entry.isIntersecting.boolean ?? false
        let intersectionRatio = entry.intersectionRatio.number ?? 0.0
        let time = entry.time.number ?? 0.0

        // Parse bounding client rect
        let boundingClientRect = parseRect(entry.boundingClientRect)

        // Parse intersection rect
        let intersectionRect = parseRect(entry.intersectionRect)

        // Parse root bounds
        let rootBounds = parseRect(entry.rootBounds)

        return IntersectionEntry(
            target: target,
            isIntersecting: isIntersecting,
            intersectionRatio: intersectionRatio,
            boundingClientRect: boundingClientRect,
            intersectionRect: intersectionRect,
            rootBounds: rootBounds,
            time: time
        )
    }

    /// Parse a DOMRect from JavaScript.
    ///
    /// - Parameter rectValue: JSValue containing the DOMRect
    /// - Returns: CGRect representation
    private func parseRect(_ rectValue: JSValue) -> CGRect {
        guard let rect = rectValue.object else {
            return .zero
        }

        let x = rect.x.number ?? 0.0
        let y = rect.y.number ?? 0.0
        let width = rect.width.number ?? 0.0
        let height = rect.height.number ?? 0.0

        return CGRect(x: x, y: y, width: width, height: height)
    }

    // MARK: - Observation

    /// Start observing an element.
    ///
    /// The element will be tracked for intersection with the viewport.
    /// When it enters or exits, the callback will be triggered.
    ///
    /// - Parameter element: DOM element to observe
    public func observe(_ element: JSObject) {
        guard let observer = observer else { return }

        let id = ObjectIdentifier(element as AnyObject)
        observedElements.insert(id)
        elementMap[id] = element

        _ = observer.observe!(element)
    }

    /// Stop observing an element.
    ///
    /// - Parameter element: DOM element to stop observing
    public func unobserve(_ element: JSObject) {
        guard let observer = observer else { return }

        let id = ObjectIdentifier(element as AnyObject)
        observedElements.remove(id)
        elementMap.removeValue(forKey: id)

        _ = observer.unobserve!(element)
    }

    /// Stop observing all elements.
    public func unobserveAll() {
        guard let observer = observer else { return }

        for element in elementMap.values {
            _ = observer.unobserve!(element)
        }

        observedElements.removeAll()
        elementMap.removeAll()
    }

    /// Disconnect the observer completely.
    ///
    /// Stops observing all elements and cleans up resources.
    public func disconnect() {
        guard let observer = observer else { return }

        _ = observer.disconnect!()

        observedElements.removeAll()
        elementMap.removeAll()
        self.observer = nil
        self.observerClosure = nil
    }

    /// Reconnect the observer if it was disconnected.
    public func reconnect() {
        if observer == nil {
            setupObserver()
        }
    }

    // MARK: - Queries

    /// Check if an element is currently being observed.
    ///
    /// - Parameter element: DOM element to check
    /// - Returns: True if the element is being observed
    public func isObserving(_ element: JSObject) -> Bool {
        let id = ObjectIdentifier(element as AnyObject)
        return observedElements.contains(id)
    }

    /// Get the number of currently observed elements.
    public var observedCount: Int {
        observedElements.count
    }

    /// Get all observed elements.
    public var observedElementList: [JSObject] {
        Array(elementMap.values)
    }
}

// MARK: - Factory Methods

extension ViewportManager {
    /// Create a ViewportManager optimized for virtual scrolling.
    ///
    /// Uses a large root margin to trigger loading before items are visible,
    /// providing smooth scrolling without loading delays.
    ///
    /// - Parameters:
    ///   - overscan: Number of pixels to overscan above/below viewport
    ///   - callback: Intersection callback
    /// - Returns: Configured ViewportManager
    public static func forVirtualScrolling(
        overscan: Int = 300,
        callback: @escaping IntersectionCallback
    ) -> ViewportManager {
        ViewportManager(
            root: nil,
            rootMargin: overscan,
            thresholds: [0.0, 0.5, 1.0],
            callback: callback
        )
    }

    /// Create a ViewportManager for lazy loading images.
    ///
    /// Uses a moderate root margin to load images shortly before they're visible.
    ///
    /// - Parameters:
    ///   - preloadDistance: Distance in pixels to start loading before visible
    ///   - callback: Intersection callback
    /// - Returns: Configured ViewportManager
    public static func forLazyLoading(
        preloadDistance: Int = 100,
        callback: @escaping IntersectionCallback
    ) -> ViewportManager {
        ViewportManager(
            root: nil,
            rootMargin: preloadDistance,
            thresholds: [0.0],
            callback: callback
        )
    }

    /// Create a ViewportManager for detecting when elements are fully visible.
    ///
    /// Only triggers when elements are completely within the viewport.
    ///
    /// - Parameter callback: Intersection callback
    /// - Returns: Configured ViewportManager
    public static func forFullyVisible(
        callback: @escaping IntersectionCallback
    ) -> ViewportManager {
        ViewportManager(
            root: nil,
            rootMargin: 0,
            thresholds: [1.0],
            callback: callback
        )
    }
}

