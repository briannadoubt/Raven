import Foundation

/// Unique identifier for virtual DOM nodes
public struct NodeID: Hashable, Sendable, CustomStringConvertible {
    private let uuid: UUID

    public init() {
        self.uuid = UUID()
    }

    /// Create a stable NodeID from a path string using FNV-1a hash.
    /// The same path always produces the same NodeID, enabling the Differ
    /// to match nodes across renders.
    public init(stablePath: String) {
        var hash: UInt64 = 14695981039346656037 // FNV-1a offset basis
        for byte in stablePath.utf8 {
            hash ^= UInt64(byte)
            hash = hash &* 1099511628211 // FNV-1a prime
        }
        // Split the 64-bit hash into two 32-bit halves for UUID construction
        let highHex = String(hash >> 32, radix: 16, uppercase: false)
        let lowHex = String(hash & 0xFFFFFFFF, radix: 16, uppercase: false)
        let high = String(repeating: "0", count: max(0, 8 - highHex.count)) + highHex
        let low = String(repeating: "0", count: max(0, 12 - lowHex.count)) + lowHex
        let uuidString = "\(high)-0000-4000-8000-\(low)"
        self.uuid = UUID(uuidString: uuidString) ?? UUID()
    }

    public var description: String {
        uuid.uuidString
    }

    public var uuidString: String {
        uuid.uuidString
    }
}

/// Type of virtual node
public enum NodeType: Hashable, Sendable {
    /// Element node with HTML tag name
    case element(tag: String)
    /// Text node with content
    case text(String)
    /// Component node for custom SwiftUI components
    case component
    /// Fragment node for grouping children without a wrapper element
    case fragment
}

/// Virtual property representing attributes, styles, and event handlers
public enum VProperty: Hashable, Sendable {
    /// HTML attribute (e.g., id, class, href)
    case attribute(name: String, value: String)
    /// CSS style property
    case style(name: String, value: String)
    /// Event handler with unique identifier
    case eventHandler(event: String, handlerID: UUID)
    /// Boolean attribute (e.g., disabled, checked)
    case boolAttribute(name: String, value: Bool)
}

/// Gesture registration metadata for attaching gestures to DOM elements
public struct GestureRegistration: Hashable, Sendable {
    /// The DOM event names this gesture needs to listen to
    public let events: [String]

    /// The priority of this gesture
    public let priority: GesturePriority

    /// Unique identifier for the gesture handler
    public let handlerID: UUID

    /// Creates a gesture registration
    public init(events: [String], priority: GesturePriority, handlerID: UUID) {
        self.events = events
        self.priority = priority
        self.handlerID = handlerID
    }
}

/// Priority level for gesture recognition
public enum GesturePriority: String, Hashable, Sendable {
    /// Normal priority - competes equally with other normal-priority gestures
    case normal
    /// Simultaneous priority - recognizes alongside other gestures
    case simultaneous
    /// High priority - takes precedence over normal-priority gestures
    case high
}

/// Virtual DOM node representing a tree structure for efficient diffing
public struct VNode: Hashable, Sendable {
    /// Unique identifier for this node
    public let id: NodeID

    /// Type of this node
    public let type: NodeType

    /// Properties (attributes, styles, event handlers) for this node
    public let props: [String: VProperty]

    /// Child nodes
    public let children: [VNode]

    /// Optional key for stable identity across renders
    public let key: String?

    /// Gestures attached to this node
    public let gestures: [GestureRegistration]

    /// Initialize a virtual node
    /// - Parameters:
    ///   - id: Unique identifier (auto-generated if not provided)
    ///   - type: Type of the node
    ///   - props: Properties dictionary
    ///   - children: Child nodes
    ///   - key: Optional key for stable identity
    ///   - gestures: Gesture registrations for this node
    public init(
        id: NodeID = NodeID(),
        type: NodeType,
        props: [String: VProperty] = [:],
        children: [VNode] = [],
        key: String? = nil,
        gestures: [GestureRegistration] = []
    ) {
        self.id = id
        self.type = type
        self.props = props
        self.children = children
        self.key = key
        self.gestures = gestures
    }
}

// MARK: - Convenience Initializers

extension VNode {
    /// Create an element node
    /// - Parameters:
    ///   - tag: HTML tag name
    ///   - props: Properties dictionary
    ///   - children: Child nodes
    ///   - key: Optional key for stable identity
    ///   - gestures: Gesture registrations for this element
    /// - Returns: VNode configured as an element
    public static func element(
        _ tag: String,
        props: [String: VProperty] = [:],
        children: [VNode] = [],
        key: String? = nil,
        gestures: [GestureRegistration] = []
    ) -> VNode {
        VNode(
            type: .element(tag: tag),
            props: props,
            children: children,
            key: key,
            gestures: gestures
        )
    }

    /// Create a text node
    /// - Parameters:
    ///   - content: Text content
    ///   - key: Optional key for stable identity
    /// - Returns: VNode configured as a text node
    public static func text(
        _ content: String,
        key: String? = nil
    ) -> VNode {
        VNode(
            type: .text(content),
            props: [:],
            children: [],
            key: key
        )
    }

    /// Create a component node
    /// - Parameters:
    ///   - props: Properties dictionary
    ///   - children: Child nodes
    ///   - key: Optional key for stable identity
    /// - Returns: VNode configured as a component
    public static func component(
        props: [String: VProperty] = [:],
        children: [VNode] = [],
        key: String? = nil
    ) -> VNode {
        VNode(
            type: .component,
            props: props,
            children: children,
            key: key
        )
    }

    /// Create a fragment node
    /// - Parameters:
    ///   - children: Child nodes
    ///   - key: Optional key for stable identity
    /// - Returns: VNode configured as a fragment
    public static func fragment(
        children: [VNode] = [],
        key: String? = nil
    ) -> VNode {
        VNode(
            type: .fragment,
            props: [:],
            children: children,
            key: key
        )
    }
}

// MARK: - Helper Methods

extension VNode {
    /// Check if this node is an element with the specified tag
    /// - Parameter tag: HTML tag name to check
    /// - Returns: True if this is an element node with the specified tag
    public func isElement(tag: String) -> Bool {
        if case .element(let nodeTag) = type {
            return nodeTag == tag
        }
        return false
    }

    /// Check if this node is a text node
    public var isText: Bool {
        if case .text = type {
            return true
        }
        return false
    }

    /// Get text content if this is a text node
    public var textContent: String? {
        if case .text(let content) = type {
            return content
        }
        return nil
    }

    /// Get element tag if this is an element node
    public var elementTag: String? {
        if case .element(let tag) = type {
            return tag
        }
        return nil
    }
}
