import Testing
import Raven

@Suite("FiberID Tests")
@MainActor
struct FiberIDTests {

    // MARK: - Determinism Tests

    @Test("Same path produces same rawValue")
    func determinism() {
        let id1 = FiberID(path: "root.child.grandchild")
        let id2 = FiberID(path: "root.child.grandchild")

        #expect(id1.rawValue == id2.rawValue)
        #expect(id1.path == id2.path)
    }

    @Test("Determinism across multiple identical paths")
    func determinismMultiple() {
        let paths = [
            "app",
            "root.navigation.stack",
            "view.list.item.0",
            "deeply.nested.component.tree.structure"
        ]

        for path in paths {
            let id1 = FiberID(path: path)
            let id2 = FiberID(path: path)
            let id3 = FiberID(path: path)

            #expect(id1.rawValue == id2.rawValue)
            #expect(id2.rawValue == id3.rawValue)
        }
    }

    // MARK: - Uniqueness Tests

    @Test("Different paths produce different rawValues")
    func uniqueness() {
        let id1 = FiberID(path: "root.child")
        let id2 = FiberID(path: "root.other")

        #expect(id1.rawValue != id2.rawValue)
    }

    @Test("Similar paths produce different rawValues")
    func uniquenessSimilarPaths() {
        let id1 = FiberID(path: "view")
        let id2 = FiberID(path: "view.")
        let id3 = FiberID(path: "view.child")
        let id4 = FiberID(path: "view.other")

        let rawValues = Set([id1.rawValue, id2.rawValue, id3.rawValue, id4.rawValue])
        #expect(rawValues.count == 4)
    }

    @Test("Order matters for uniqueness")
    func uniquenessOrderMatters() {
        let id1 = FiberID(path: "a.b.c")
        let id2 = FiberID(path: "c.b.a")

        #expect(id1.rawValue != id2.rawValue)
    }

    // MARK: - Child Derivation Tests

    @Test("Child appends component to path")
    func childPath() {
        let parent = FiberID(path: "root")
        let child = parent.child("child")

        #expect(child.path == "root.child")
    }

    @Test("Multiple child derivations")
    func childDerivationChain() {
        let root = FiberID(path: "root")
        let child = root.child("navigation")
        let grandchild = child.child("stack")
        let greatGrandchild = grandchild.child("item")

        #expect(child.path == "root.navigation")
        #expect(grandchild.path == "root.navigation.stack")
        #expect(greatGrandchild.path == "root.navigation.stack.item")
    }

    @Test("Child derivation produces different rawValue")
    func childDifferentRawValue() {
        let parent = FiberID(path: "root")
        let child = parent.child("child")

        #expect(parent.rawValue != child.rawValue)
    }

    @Test("Child derivation is deterministic")
    func childDeterminism() {
        let parent1 = FiberID(path: "root")
        let child1 = parent1.child("child")

        let parent2 = FiberID(path: "root")
        let child2 = parent2.child("child")

        #expect(child1.rawValue == child2.rawValue)
        #expect(child1.path == child2.path)
    }

    @Test("Child components with special names")
    func childSpecialComponents() {
        let root = FiberID(path: "root")
        let numeric = root.child("0")
        let special = root.child("@main")
        let underscore = root.child("_private")

        #expect(numeric.path == "root.0")
        #expect(special.path == "root.@main")
        #expect(underscore.path == "root._private")
    }

    // MARK: - Hashable Conformance Tests

    @Test("Can be used as dictionary keys")
    func hashableDictionary() {
        var dict: [FiberID: String] = [:]

        let id1 = FiberID(path: "root.child1")
        let id2 = FiberID(path: "root.child2")
        let id3 = FiberID(path: "root.child3")

        dict[id1] = "first"
        dict[id2] = "second"
        dict[id3] = "third"

        #expect(dict[id1] == "first")
        #expect(dict[id2] == "second")
        #expect(dict[id3] == "third")
        #expect(dict.count == 3)
    }

    @Test("Can be used in sets")
    func hashableSet() {
        let id1 = FiberID(path: "root.child1")
        let id2 = FiberID(path: "root.child2")
        let id3 = FiberID(path: "root.child1") // Duplicate

        let set: Set<FiberID> = [id1, id2, id3]

        #expect(set.count == 2)
        #expect(set.contains(id1))
        #expect(set.contains(id2))
    }

    @Test("Equality based on path and rawValue")
    func hashableEquality() {
        let id1 = FiberID(path: "test.path")
        let id2 = FiberID(path: "test.path")
        let id3 = FiberID(path: "different.path")

        #expect(id1 == id2)
        #expect(id1 != id3)
        #expect(id2 != id3)
    }

    // MARK: - Description Tests

    @Test("Description includes path")
    func descriptionIncludesPath() {
        let id = FiberID(path: "root.navigation.stack")
        let description = id.description

        #expect(description.contains("root.navigation.stack"))
    }

    @Test("Description for simple path")
    func descriptionSimple() {
        let id = FiberID(path: "root")
        let description = id.description

        #expect(description.contains("root"))
    }

    @Test("Description for complex path")
    func descriptionComplex() {
        let id = FiberID(path: "app.window.scene.navigation.stack.list.item.42")
        let description = id.description

        #expect(description.contains("app.window.scene.navigation.stack.list.item.42"))
    }

    // MARK: - Edge Cases Tests

    @Test("Empty path")
    func emptyPath() {
        let id = FiberID(path: "")

        #expect(id.path == "")
        #expect(id.rawValue != 0) // Should still produce a hash
    }

    @Test("Empty path determinism")
    func emptyPathDeterminism() {
        let id1 = FiberID(path: "")
        let id2 = FiberID(path: "")

        #expect(id1.rawValue == id2.rawValue)
    }

    @Test("Very long path")
    func veryLongPath() {
        let components = (0..<100).map { "component\($0)" }
        let longPath = components.joined(separator: ".")

        let id = FiberID(path: longPath)

        #expect(id.path == longPath)
        #expect(id.path.count > 1000)
    }

    @Test("Very long path determinism")
    func veryLongPathDeterminism() {
        let components = (0..<100).map { "node\($0)" }
        let longPath = components.joined(separator: ".")

        let id1 = FiberID(path: longPath)
        let id2 = FiberID(path: longPath)

        #expect(id1.rawValue == id2.rawValue)
    }

    @Test("Special characters in path")
    func specialCharacters() {
        let specialPaths = [
            "root.child-with-dash",
            "root.child_with_underscore",
            "root.child@special",
            "root.child#hash",
            "root.child$dollar",
            "root.child!exclaim",
            "root.child(parens)",
            "root.child[brackets]",
            "root.child{braces}",
            "unicode.🎨.path"
        ]

        for path in specialPaths {
            let id = FiberID(path: path)
            #expect(id.path == path)
        }
    }

    @Test("Special characters produce unique hashes")
    func specialCharactersUnique() {
        let id1 = FiberID(path: "root-child")
        let id2 = FiberID(path: "root_child")
        let id3 = FiberID(path: "root.child")

        let rawValues = Set([id1.rawValue, id2.rawValue, id3.rawValue])
        #expect(rawValues.count == 3)
    }

    @Test("Unicode paths")
    func unicodePaths() {
        let id1 = FiberID(path: "你好.世界")
        let id2 = FiberID(path: "hello.world")
        let id3 = FiberID(path: "🎨.🎭.🎪")

        #expect(id1.path == "你好.世界")
        #expect(id2.path == "hello.world")
        #expect(id3.path == "🎨.🎭.🎪")

        // All should produce different hashes
        let rawValues = Set([id1.rawValue, id2.rawValue, id3.rawValue])
        #expect(rawValues.count == 3)
    }

    @Test("Path with consecutive dots")
    func consecutiveDots() {
        let id1 = FiberID(path: "root..child")
        let id2 = FiberID(path: "root.child")

        #expect(id1.path == "root..child")
        #expect(id2.path == "root.child")
        #expect(id1.rawValue != id2.rawValue)
    }

    @Test("Child with empty component")
    func childEmptyComponent() {
        let parent = FiberID(path: "root")
        let child = parent.child("")

        #expect(child.path == "root.")
    }

    @Test("Whitespace in paths")
    func whitespacePaths() {
        let id1 = FiberID(path: "root.child with spaces")
        let id2 = FiberID(path: "root.child")

        #expect(id1.path == "root.child with spaces")
        #expect(id1.rawValue != id2.rawValue)
    }

    // MARK: - Hash Collision Resistance Tests

    @Test("No collisions in common patterns")
    func noCollisionsCommonPatterns() {
        var seen: Set<UInt64> = []
        let patterns = [
            "root",
            "app",
            "view",
            "list",
            "item",
            "navigation",
            "stack",
            "screen",
            "button",
            "text"
        ]

        for pattern in patterns {
            let id = FiberID(path: pattern)
            #expect(!seen.contains(id.rawValue))
            seen.insert(id.rawValue)
        }

        #expect(seen.count == patterns.count)
    }

    @Test("No collisions in indexed paths")
    func noCollisionsIndexed() {
        var seen: Set<UInt64> = []

        for i in 0..<100 {
            let id = FiberID(path: "root.item.\(i)")
            #expect(!seen.contains(id.rawValue))
            seen.insert(id.rawValue)
        }

        #expect(seen.count == 100)
    }
}
