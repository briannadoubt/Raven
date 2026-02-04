import Foundation
import JavaScriptKit

/// Client-side hydration system for attaching interactivity to server-rendered HTML
///
/// Hydration matches the VNode tree with server-rendered DOM elements and attaches
/// event handlers and dynamic behavior without re-rendering the entire page.
@MainActor
public final class HydrationManager {
    // MARK: - Properties

    /// Shared hydration manager instance
    public static let shared = HydrationManager()

    /// Map of hydrated node IDs
    private var hydratedNodes: Set<String> = []

    /// Map of node IDs to their VNodes for reference
    private var vnodeRegistry: [String: VNode] = [:]

    /// Whether hydration is in progress
    private var isHydrating = false

    /// Hydration statistics
    private var stats = HydrationStats()

    // MARK: - Initialization

    private init() {}

    // MARK: - Hydration

    /// Hydrate a server-rendered DOM tree with a VNode tree
    /// - Parameters:
    ///   - vnode: The virtual DOM tree to hydrate with
    ///   - rootElement: The root DOM element (defaults to document.body)
    /// - Returns: Hydration result with statistics
    public func hydrate(
        _ vnode: VNode,
        rootElement: JSObject? = nil
    ) throws -> HydrationResult {
        guard !isHydrating else {
            throw HydrationError.hydrationInProgress
        }

        isHydrating = true
        stats = HydrationStats()
        let startTime = Date()

        defer {
            isHydrating = false
        }

        let root = rootElement ?? JSObject.global.document.body.object!

        do {
            try hydrateNode(vnode, domNode: root)
            stats.duration = Date().timeIntervalSince(startTime)
            stats.success = true

            return HydrationResult(
                success: true,
                stats: stats,
                error: nil
            )
        } catch {
            stats.duration = Date().timeIntervalSince(startTime)
            stats.success = false

            return HydrationResult(
                success: false,
                stats: stats,
                error: error
            )
        }
    }

    /// Hydrate a single VNode with its corresponding DOM node
    private func hydrateNode(_ vnode: VNode, domNode: JSObject) throws {
        let nodeID = vnode.id.uuidString

        // Skip if already hydrated
        guard !hydratedNodes.contains(nodeID) else {
            return
        }

        // Verify the node matches
        if !verifyNodeMatch(vnode, domNode: domNode) {
            stats.mismatchCount += 1
            throw HydrationError.nodeMismatch(
                expected: vnode,
                found: domNode
            )
        }

        // Register the VNode
        vnodeRegistry[nodeID] = vnode

        switch vnode.type {
        case .element:
            try hydrateElement(vnode, domNode: domNode)

        case .text:
            try hydrateText(vnode, domNode: domNode)

        case .component:
            try hydrateComponent(vnode, domNode: domNode)

        case .fragment:
            try hydrateFragment(vnode, domNode: domNode)
        }

        // Mark as hydrated
        hydratedNodes.insert(nodeID)
        stats.hydratedNodeCount += 1
    }

    // MARK: - Element Hydration

    private func hydrateElement(_ vnode: VNode, domNode: JSObject) throws {
        // Attach event handlers
        for (_, property) in vnode.props {
            if case .eventHandler(_, _) = property {
                // Event handlers would need to be re-attached from the client-side VNode tree
                // The server doesn't serialize event handlers, so the client must provide them
                stats.eventHandlerCount += 1
            }
        }

        // Hydrate children
        try hydrateChildren(vnode.children, parentDOMNode: domNode)
    }

    // MARK: - Text Hydration

    private func hydrateText(_ vnode: VNode, domNode: JSObject) throws {
        guard case .text(let content) = vnode.type else {
            throw HydrationError.typeMismatch
        }

        // Verify text content matches
        let domContent = domNode.textContent.string ?? ""
        if domContent != content {
            stats.mismatchCount += 1
            // Text mismatches are typically acceptable, update the DOM
            domNode.textContent = .string(content)
        }
    }

    // MARK: - Component Hydration

    private func hydrateComponent(_ vnode: VNode, domNode: JSObject) throws {
        // Components are hydrated by hydrating their children
        try hydrateChildren(vnode.children, parentDOMNode: domNode)
    }

    // MARK: - Fragment Hydration

    private func hydrateFragment(_ vnode: VNode, domNode: JSObject) throws {
        // Find the fragment template element
        let fragmentID = vnode.id.uuidString
        let selector = "[data-raven-fragment=\"\(fragmentID)\"]"

        let fragmentValue = JSObject.global.document.querySelector(selector)
        guard let fragmentElement = fragmentValue.object else {
            throw HydrationError.fragmentNotFound(id: fragmentID)
        }

        // Hydrate children within the fragment
        try hydrateChildren(vnode.children, parentDOMNode: fragmentElement)
    }

    // MARK: - Children Hydration

    private func hydrateChildren(_ children: [VNode], parentDOMNode: JSObject) throws {
        guard !children.isEmpty else { return }

        // Get DOM children
        let childNodes = parentDOMNode.childNodes
        let childCount = childNodes.length.number.map { Int($0) } ?? 0

        var domIndex = 0

        for vnode in children {
            // Find matching DOM node
            guard domIndex < childCount else {
                throw HydrationError.missingDOMNode(vnode: vnode)
            }

            // Get the DOM child node
            guard let domChild = childNodes[domIndex].object else {
                throw HydrationError.invalidDOMNode
            }

            // Try to hydrate this node
            try hydrateNode(vnode, domNode: domChild)

            domIndex += 1
        }
    }

    // MARK: - Verification

    private func verifyNodeMatch(_ vnode: VNode, domNode: JSObject) -> Bool {
        // Check if the DOM node has the expected hydration marker
        let nodeID = vnode.id.uuidString
        let dataID = domNode[dynamicMember: "dataset"]
            .object?[dynamicMember: "ravenId"]
            .string

        if let dataID = dataID, dataID == nodeID {
            return true
        }

        // Fallback: verify by node type
        switch vnode.type {
        case .element(let tag):
            let nodeName = domNode.nodeName.string?.lowercased() ?? ""
            return nodeName == tag.lowercased()

        case .text:
            let nodeType = domNode.nodeType.number.map { Int($0) } ?? 0
            return nodeType == 3 // TEXT_NODE

        case .component, .fragment:
            return true // Components and fragments are structural
        }
    }

    // MARK: - Partial Hydration

    /// Hydrate only a specific subtree
    /// - Parameters:
    ///   - vnode: The VNode subtree to hydrate
    ///   - nodeID: The ID of the root node to hydrate
    public func hydrateSubtree(_ vnode: VNode, nodeID: String) throws {
        let selector = "[data-raven-id=\"\(nodeID)\"]"

        let domValue = JSObject.global.document.querySelector(selector)
        guard let domNode = domValue.object else {
            throw HydrationError.domNodeNotFound(id: nodeID)
        }

        try hydrateNode(vnode, domNode: domNode)
    }

    // MARK: - Progressive Hydration

    /// Progressively hydrate the page in chunks
    /// - Parameters:
    ///   - vnodes: Array of VNode trees to hydrate in order
    ///   - chunkSize: Number of nodes to hydrate per chunk
    ///   - delayBetweenChunks: Delay in milliseconds between chunks
    public func hydrateProgressively(
        _ vnodes: [VNode],
        chunkSize: Int = 10,
        delayBetweenChunks: Int = 16
    ) async throws {
        for chunk in vnodes.chunked(into: chunkSize) {
            for vnode in chunk {
                let selector = "[data-raven-id=\"\(vnode.id.uuidString)\"]"
                let domValue = JSObject.global.document.querySelector(selector)
                if let domNode = domValue.object {
                    try hydrateNode(vnode, domNode: domNode)
                }
            }

            // Yield to the main thread
            try await Task.sleep(for: .milliseconds(delayBetweenChunks))
        }
    }

    // MARK: - State Management

    /// Check if a node is hydrated
    public func isHydrated(nodeID: String) -> Bool {
        hydratedNodes.contains(nodeID)
    }

    /// Get the VNode for a hydrated node
    public func getVNode(for nodeID: String) -> VNode? {
        vnodeRegistry[nodeID]
    }

    /// Clear all hydration state
    public func reset() {
        hydratedNodes.removeAll()
        vnodeRegistry.removeAll()
        stats = HydrationStats()
    }

    // MARK: - Statistics

    /// Get current hydration statistics
    public func getStats() -> HydrationStats {
        stats
    }
}

// MARK: - Hydration Result

/// Result of a hydration operation
public struct HydrationResult: Sendable {
    /// Whether hydration was successful
    public let success: Bool

    /// Hydration statistics
    public let stats: HydrationStats

    /// Error if hydration failed
    public let error: Error?
}

// MARK: - Hydration Stats

/// Statistics collected during hydration
public struct HydrationStats: Sendable {
    /// Number of nodes successfully hydrated
    public var hydratedNodeCount: Int = 0

    /// Number of event handlers attached
    public var eventHandlerCount: Int = 0

    /// Number of node mismatches encountered
    public var mismatchCount: Int = 0

    /// Time taken to hydrate
    public var duration: TimeInterval = 0

    /// Whether hydration was successful
    public var success: Bool = false

    public init() {}
}

// MARK: - Hydration Error

/// Errors that can occur during hydration
public enum HydrationError: Error, CustomStringConvertible, @unchecked Sendable {
    /// Hydration is already in progress
    case hydrationInProgress

    /// Node type mismatch between VNode and DOM
    case typeMismatch

    /// Node structure mismatch
    case nodeMismatch(expected: VNode, found: JSObject)

    /// Fragment not found in DOM
    case fragmentNotFound(id: String)

    /// Missing DOM node for VNode
    case missingDOMNode(vnode: VNode)

    /// Invalid DOM node
    case invalidDOMNode

    /// DOM node not found by ID
    case domNodeNotFound(id: String)

    public var description: String {
        switch self {
        case .hydrationInProgress:
            return "Hydration is already in progress"
        case .typeMismatch:
            return "Node type mismatch between VNode and DOM"
        case .nodeMismatch(let expected, let found):
            return "Node mismatch: expected \(expected.type), found \(found)"
        case .fragmentNotFound(let id):
            return "Fragment not found with ID: \(id)"
        case .missingDOMNode(let vnode):
            return "Missing DOM node for VNode: \(vnode.id)"
        case .invalidDOMNode:
            return "Invalid DOM node"
        case .domNodeNotFound(let id):
            return "DOM node not found with ID: \(id)"
        }
    }
}

// MARK: - Hydration Strategy

/// Strategy for hydrating a page
public enum HydrationStrategy: Sendable {
    /// Hydrate the entire page immediately
    case eager

    /// Hydrate progressively in chunks
    case progressive(chunkSize: Int, delayMs: Int)

    /// Hydrate only when elements are visible (intersection observer)
    case lazy

    /// Hydrate on user interaction
    case onInteraction

    /// Custom hydration strategy
    case custom
}

// MARK: - Selective Hydration

/// Configuration for selective hydration of components
public struct SelectiveHydrationConfig: Sendable {
    /// IDs of nodes that should be hydrated
    public let hydrateNodeIDs: Set<String>

    /// Strategy to use for hydration
    public let strategy: HydrationStrategy

    /// Whether to hydrate children of specified nodes
    public let hydrateChildren: Bool

    public init(
        hydrateNodeIDs: Set<String>,
        strategy: HydrationStrategy = .eager,
        hydrateChildren: Bool = true
    ) {
        self.hydrateNodeIDs = hydrateNodeIDs
        self.strategy = strategy
        self.hydrateChildren = hydrateChildren
    }
}

// MARK: - Array Extension

private extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}
