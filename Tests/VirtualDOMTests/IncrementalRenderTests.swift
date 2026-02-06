import Foundation
import Testing
@testable import Raven

// MARK: - Stable NodeID Tests

@Suite("Stable NodeID")
struct StableNodeIDTests {

    @Test func samePathProducesSameID() {
        let id1 = NodeID(stablePath: "root.0.Button")
        let id2 = NodeID(stablePath: "root.0.Button")
        #expect(id1 == id2)
    }

    @Test func differentPathsProduceDifferentIDs() {
        let id1 = NodeID(stablePath: "root.0.Button")
        let id2 = NodeID(stablePath: "root.1.Button")
        #expect(id1 != id2)
    }

    @Test func stableIDIsDeterministic() {
        // Call multiple times with the same path — always identical
        var ids: [NodeID] = []
        for _ in 0..<100 {
            ids.append(NodeID(stablePath: "root.VStack.0.HStack.1.Button"))
        }
        let first = ids[0]
        for id in ids {
            #expect(id == first)
        }
    }

    @Test func emptyPathProducesValidID() {
        let id = NodeID(stablePath: "")
        #expect(id.uuidString.count > 0)
    }

    @Test func longPathProducesValidID() {
        let longPath = (0..<200).map { "node\($0)" }.joined(separator: ".")
        let id = NodeID(stablePath: longPath)
        #expect(id.uuidString.count > 0)
    }
}

// MARK: - Differ Integration Tests

@Suite("Differ")
@MainActor
struct DifferIntegrationTests {

    let differ = Differ()

    // MARK: - Basics

    @Test func identicalTreesProduceNoPatches() {
        let tree = VNode.element("div", props: [
            "class": .attribute(name: "class", value: "root")
        ], children: [
            VNode.text("hello")
        ])
        // Give both trees the same stable IDs
        let old = withStableIDs(tree, path: "root")
        let new = withStableIDs(tree, path: "root")
        let patches = differ.diff(old: old, new: new)
        #expect(patches.isEmpty)
    }

    @Test func textChangeProducesReplacePatch() {
        let old = withStableIDs(
            VNode.element("div", children: [VNode.text("hello")]),
            path: "root"
        )
        let new = withStableIDs(
            VNode.element("div", children: [VNode.text("world")]),
            path: "root"
        )
        let patches = differ.diff(old: old, new: new)
        // Text node type changed from .text("hello") to .text("world") — replace
        #expect(!patches.isEmpty)
    }

    @Test func propChangeProducesUpdatePatch() {
        let old = withStableIDs(
            VNode.element("div", props: [
                "color": .style(name: "color", value: "red")
            ]),
            path: "root"
        )
        let new = withStableIDs(
            VNode.element("div", props: [
                "color": .style(name: "color", value: "blue")
            ]),
            path: "root"
        )
        let patches = differ.diff(old: old, new: new)
        #expect(patches.count == 1)
        if case .updateProps(_, let propPatches) = patches.first {
            #expect(propPatches.count == 1)
        } else {
            Issue.record("Expected updateProps patch")
        }
    }

    @Test func addedChildProducesInsertPatch() {
        let old = withStableIDs(
            VNode.element("div", children: [
                VNode.text("a")
            ]),
            path: "root"
        )
        let new = withStableIDs(
            VNode.element("div", children: [
                VNode.text("a"),
                VNode.text("b")
            ]),
            path: "root"
        )
        let patches = differ.diff(old: old, new: new)
        let inserts = patches.filter {
            if case .insert = $0 { return true }
            return false
        }
        #expect(inserts.count == 1)
    }

    @Test func removedChildProducesRemovePatch() {
        let old = withStableIDs(
            VNode.element("div", children: [
                VNode.text("a"),
                VNode.text("b")
            ]),
            path: "root"
        )
        let new = withStableIDs(
            VNode.element("div", children: [
                VNode.text("a")
            ]),
            path: "root"
        )
        let patches = differ.diff(old: old, new: new)
        let removes = patches.filter {
            if case .remove = $0 { return true }
            return false
        }
        #expect(removes.count == 1)
    }

    @Test func tagChangeProducesReplacePatch() {
        let old = withStableIDs(VNode.element("div"), path: "root")
        let new = withStableIDs(VNode.element("span"), path: "root")
        let patches = differ.diff(old: old, new: new)
        let replaces = patches.filter {
            if case .replace = $0 { return true }
            return false
        }
        #expect(replaces.count == 1)
    }

    // MARK: - Keyed Diffing

    @Test func keyedChildrenDiffCorrectly() {
        let old = withStableIDs(
            VNode.element("ul", children: [
                VNode.element("li", key: "a"),
                VNode.element("li", key: "b"),
                VNode.element("li", key: "c"),
            ]),
            path: "root"
        )
        let new = withStableIDs(
            VNode.element("ul", children: [
                VNode.element("li", key: "c"),
                VNode.element("li", key: "a"),
                VNode.element("li", key: "b"),
            ]),
            path: "root"
        )
        let patches = differ.diff(old: old, new: new)
        // Should produce reorder and/or move patches, NOT full replacements
        let replaces = patches.filter {
            if case .replace = $0 { return true }
            return false
        }
        #expect(replaces.isEmpty, "Keyed children should reorder, not replace")
    }

    @Test func eventHandlerWithSameIDProducesNoPatch() {
        let handlerID = UUID()
        let old = withStableIDs(
            VNode.element("button", props: [
                "onClick": .eventHandler(event: "click", handlerID: handlerID)
            ]),
            path: "root"
        )
        let new = withStableIDs(
            VNode.element("button", props: [
                "onClick": .eventHandler(event: "click", handlerID: handlerID)
            ]),
            path: "root"
        )
        let patches = differ.diff(old: old, new: new)
        #expect(patches.isEmpty, "Same handler ID should produce no patch")
    }

    // MARK: - Helpers

    /// Assign stable IDs to a VNode tree based on structural position.
    private func withStableIDs(_ node: VNode, path: String) -> VNode {
        let stableID = NodeID(stablePath: path)
        let children = node.children.enumerated().map { (i, child) in
            let childKey = child.key ?? String(i)
            return withStableIDs(child, path: "\(path).\(childKey)")
        }
        return VNode(
            id: stableID,
            type: node.type,
            props: node.props,
            children: children,
            key: node.key,
            gestures: node.gestures
        )
    }
}
