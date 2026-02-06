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
