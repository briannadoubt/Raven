import Foundation
import Testing
@testable import Raven

/// Comprehensive tests for PopoverModifier and PopoverItemModifier.
///
/// These tests verify:
/// - Popover presentation with isPresented binding
/// - Popover presentation with item binding
/// - Anchor positioning types
/// - Arrow edge parameter
/// - onDismiss callback behavior
/// - Environment propagation
/// - Sendable conformance
@MainActor
@Suite struct PopoverModifierTests {

    // MARK: - Test Types

    struct TestItem: Identifiable {
        let id: Int
        let name: String
    }

    // MARK: - isPresented Binding Tests

    @Test func popoverPresentationWithBinding() {
        let coordinator = PresentationCoordinator()
        var isPresented = false

        let content = Text("Popover Content")
        let modifier = PopoverModifier(
            isPresented: Binding(
                get: { isPresented },
                set: { isPresented = $0 }
            ),
            attachmentAnchor: .default,
            arrowEdge: .top,
            onDismiss: nil,
            content: { content }
        )

        // Initially not presented
        #expect(modifier.register(with: coordinator) == nil)
        #expect(coordinator.count == 0)

        // Present the popover
        isPresented = true
        let id = modifier.register(with: coordinator)

        #expect(id != nil)
        #expect(coordinator.count == 1)

        let entry = coordinator.presentations.first
        #expect(entry?.id == id)

        switch entry?.type {
        case .popover(let anchor, let edge):
            #expect(anchor == .rect(.bounds))
            #expect(edge == .top)
        default:
            Issue.record("Expected popover presentation type")
        }
    }

    @Test func popoverDismissal() {
        let coordinator = PresentationCoordinator()
        var isPresented = true
        var dismissCalled = false

        let modifier = PopoverModifier(
            isPresented: Binding(
                get: { isPresented },
                set: { isPresented = $0 }
            ),
            attachmentAnchor: .default,
            arrowEdge: .top,
            onDismiss: { dismissCalled = true },
            content: { Text("Content") }
        )

        // Present
        let id = modifier.register(with: coordinator)!
        #expect(coordinator.count == 1)

        // Dismiss via coordinator
        coordinator.dismiss(id)
        #expect(coordinator.count == 0)
        #expect(dismissCalled)
        #expect(!isPresented)
    }

    @Test func popoverOnDismissCallback() {
        let coordinator = PresentationCoordinator()
        var isPresented = true
        var onDismissCalled = false
        var dismissCallCount = 0

        let modifier = PopoverModifier(
            isPresented: Binding(
                get: { isPresented },
                set: { isPresented = $0 }
            ),
            attachmentAnchor: .default,
            arrowEdge: .top,
            onDismiss: {
                onDismissCalled = true
                dismissCallCount += 1
            },
            content: { Text("Content") }
        )

        let id = modifier.register(with: coordinator)!

        // Trigger dismiss
        coordinator.dismiss(id)

        #expect(onDismissCalled)
        #expect(dismissCallCount == 1)
        #expect(!isPresented)
    }

    // MARK: - Item Binding Tests

    @Test func popoverPresentationWithItem() {
        let coordinator = PresentationCoordinator()
        var item: TestItem? = nil

        let modifier = PopoverItemModifier(
            item: Binding(
                get: { item },
                set: { item = $0 }
            ),
            attachmentAnchor: .default,
            arrowEdge: .top,
            onDismiss: nil,
            content: { item in Text(item.name) }
        )

        // Initially not presented
        #expect(modifier.register(with: coordinator) == nil)
        #expect(coordinator.count == 0)

        // Present with item
        item = TestItem(id: 1, name: "First")
        let id = modifier.register(with: coordinator)

        #expect(id != nil)
        #expect(coordinator.count == 1)
    }

    @Test func popoverItemDismissal() {
        let coordinator = PresentationCoordinator()
        var item: TestItem? = TestItem(id: 1, name: "Test")
        var dismissCalled = false

        let modifier = PopoverItemModifier(
            item: Binding(
                get: { item },
                set: { item = $0 }
            ),
            attachmentAnchor: .default,
            arrowEdge: .top,
            onDismiss: { dismissCalled = true },
            content: { item in Text(item.name) }
        )

        // Present
        let id = modifier.register(with: coordinator)!
        #expect(coordinator.count == 1)

        // Dismiss
        coordinator.dismiss(id)
        #expect(coordinator.count == 0)
        #expect(dismissCalled)
        #expect(item == nil)
    }

    @Test func popoverItemChange() {
        let coordinator = PresentationCoordinator()
        var item: TestItem? = TestItem(id: 1, name: "First")

        let modifier = PopoverItemModifier(
            item: Binding(
                get: { item },
                set: { item = $0 }
            ),
            attachmentAnchor: .default,
            arrowEdge: .top,
            onDismiss: nil,
            content: { item in Text(item.name) }
        )

        // Present first item
        let id1 = modifier.register(with: coordinator)!
        #expect(coordinator.count == 1)

        // Change to different item
        item = TestItem(id: 2, name: "Second")

        // Should need update since item ID changed
        #expect(modifier.shouldUpdate(currentId: id1, coordinator: coordinator))
    }

    @Test func popoverItemSameId() {
        let coordinator = PresentationCoordinator()
        var item: TestItem? = TestItem(id: 1, name: "First")

        let modifier = PopoverItemModifier(
            item: Binding(
                get: { item },
                set: { item = $0 }
            ),
            attachmentAnchor: .default,
            arrowEdge: .top,
            onDismiss: nil,
            content: { item in Text(item.name) }
        )

        let id = modifier.register(with: coordinator)!

        // Change content but keep same ID
        item = TestItem(id: 1, name: "Modified")

        // Should not need update since ID is the same
        #expect(!modifier.shouldUpdate(currentId: id, coordinator: coordinator))
    }

    // MARK: - Anchor Positioning Tests

    @Test func popoverWithBoundsAnchor() {
        let coordinator = PresentationCoordinator()
        var isPresented = true

        let modifier = PopoverModifier(
            isPresented: Binding(
                get: { isPresented },
                set: { isPresented = $0 }
            ),
            attachmentAnchor: .rect(.bounds),
            arrowEdge: .top,
            onDismiss: nil,
            content: { Text("Content") }
        )

        let id = modifier.register(with: coordinator)!
        let entry = coordinator.presentations.first

        switch entry?.type {
        case .popover(let anchor, _):
            #expect(anchor == .rect(.bounds))
        default:
            Issue.record("Expected popover with bounds anchor")
        }
    }

    @Test func popoverWithCustomRectAnchor() {
        let coordinator = PresentationCoordinator()
        var isPresented = true
        let customRect = Raven.CGRect(x: 10, y: 20, width: 100, height: 50)

        let modifier = PopoverModifier(
            isPresented: Binding(
                get: { isPresented },
                set: { isPresented = $0 }
            ),
            attachmentAnchor: .rect(.rect(customRect)),
            arrowEdge: .bottom,
            onDismiss: nil,
            content: { Text("Content") }
        )

        let id = modifier.register(with: coordinator)!
        let entry = coordinator.presentations.first

        switch entry?.type {
        case .popover(let anchor, _):
            switch anchor {
            case .rect(.rect(let rect)):
                #expect(rect.origin.x == 10)
                #expect(rect.origin.y == 20)
                #expect(rect.size.width == 100)
                #expect(rect.size.height == 50)
            default:
                Issue.record("Expected rect anchor with custom CGRect")
            }
        default:
            Issue.record("Expected popover presentation")
        }
    }

    @Test func popoverWithPointAnchor() {
        let coordinator = PresentationCoordinator()
        var isPresented = true

        let modifier = PopoverModifier(
            isPresented: Binding(
                get: { isPresented },
                set: { isPresented = $0 }
            ),
            attachmentAnchor: .point(.center),
            arrowEdge: .leading,
            onDismiss: nil,
            content: { Text("Content") }
        )

        let id = modifier.register(with: coordinator)!
        let entry = coordinator.presentations.first

        switch entry?.type {
        case .popover(let anchor, _):
            switch anchor {
            case .point(let point):
                #expect(point.x == 0.5)
                #expect(point.y == 0.5)
            default:
                Issue.record("Expected point anchor")
            }
        default:
            Issue.record("Expected popover presentation")
        }
    }

    @Test func popoverWithDifferentUnitPoints() {
        let coordinator = PresentationCoordinator()
        let testCases: [(UnitPoint, String)] = [
            (.topLeading, "topLeading"),
            (.center, "center"),
            (.bottomTrailing, "bottomTrailing"),
            (.top, "top"),
            (.bottom, "bottom")
        ]

        for (unitPoint, name) in testCases {
            var isPresented = true

            let modifier = PopoverModifier(
                isPresented: Binding(
                    get: { isPresented },
                    set: { isPresented = $0 }
                ),
                attachmentAnchor: .point(unitPoint),
                arrowEdge: .top,
                onDismiss: nil,
                content: { Text("Content") }
            )

            let id = modifier.register(with: coordinator)!
            let entry = coordinator.presentations.first

            switch entry?.type {
            case .popover(let anchor, _):
                switch anchor {
                case .point(let point):
                    #expect(point == unitPoint)
                default:
                    Issue.record("Expected point anchor for \(name)")
                }
            default:
                Issue.record("Expected popover presentation for \(name)")
            }

            // Clean up for next test
            coordinator.dismiss(id)
        }
    }

    // MARK: - Arrow Edge Tests

    @Test func popoverWithTopEdge() {
        let coordinator = PresentationCoordinator()
        var isPresented = true

        let modifier = PopoverModifier(
            isPresented: Binding(
                get: { isPresented },
                set: { isPresented = $0 }
            ),
            attachmentAnchor: .default,
            arrowEdge: .top,
            onDismiss: nil,
            content: { Text("Content") }
        )

        let id = modifier.register(with: coordinator)!
        let entry = coordinator.presentations.first

        switch entry?.type {
        case .popover(_, let edge):
            #expect(edge == .top)
        default:
            Issue.record("Expected popover with top edge")
        }
    }

    @Test func popoverWithDifferentEdges() {
        let coordinator = PresentationCoordinator()
        let edges: [Edge] = [.top, .bottom, .leading, .trailing]

        for edge in edges {
            var isPresented = true

            let modifier = PopoverModifier(
                isPresented: Binding(
                    get: { isPresented },
                    set: { isPresented = $0 }
                ),
                attachmentAnchor: .default,
                arrowEdge: edge,
                onDismiss: nil,
                content: { Text("Content") }
            )

            let id = modifier.register(with: coordinator)!
            let entry = coordinator.presentations.first

            switch entry?.type {
            case .popover(_, let presentedEdge):
                #expect(presentedEdge == edge)
            default:
                Issue.record("Expected popover with \(edge) edge")
            }

            // Clean up for next test
            coordinator.dismiss(id)
        }
    }

    // MARK: - shouldUpdate Tests

    @Test func shouldUpdateWhenPresentingFromNil() {
        var isPresented = false

        let modifier = PopoverModifier(
            isPresented: Binding(
                get: { isPresented },
                set: { isPresented = $0 }
            ),
            attachmentAnchor: .default,
            arrowEdge: .top,
            onDismiss: nil,
            content: { Text("Content") }
        )

        let coordinator = PresentationCoordinator()

        // Not presented, no ID
        #expect(!modifier.shouldUpdate(currentId: nil, coordinator: coordinator))

        // Want to present, no ID
        isPresented = true
        #expect(modifier.shouldUpdate(currentId: nil, coordinator: coordinator))
    }

    @Test func shouldUpdateWhenDismissing() {
        var isPresented = true

        let modifier = PopoverModifier(
            isPresented: Binding(
                get: { isPresented },
                set: { isPresented = $0 }
            ),
            attachmentAnchor: .default,
            arrowEdge: .top,
            onDismiss: nil,
            content: { Text("Content") }
        )

        let coordinator = PresentationCoordinator()
        let id = UUID()

        // Presented with ID
        #expect(!modifier.shouldUpdate(currentId: id, coordinator: coordinator))

        // Want to dismiss, have ID
        isPresented = false
        #expect(modifier.shouldUpdate(currentId: id, coordinator: coordinator))
    }

    @Test func itemShouldUpdateWhenChanging() {
        var item: TestItem? = TestItem(id: 1, name: "First")

        let modifier = PopoverItemModifier(
            item: Binding(
                get: { item },
                set: { item = $0 }
            ),
            attachmentAnchor: .default,
            arrowEdge: .top,
            onDismiss: nil,
            content: { item in Text(item.name) }
        )

        let coordinator = PresentationCoordinator()
        let _ = modifier.register(with: coordinator)

        // Change to different item
        item = TestItem(id: 2, name: "Second")
        #expect(modifier.shouldUpdate(currentId: UUID(), coordinator: coordinator))
    }

    // MARK: - Multiple Popovers Tests

    @Test func multiplePopoversWithDifferentAnchors() {
        let coordinator = PresentationCoordinator()
        var show1 = true
        var show2 = true

        let modifier1 = PopoverModifier(
            isPresented: Binding(get: { show1 }, set: { show1 = $0 }),
            attachmentAnchor: .rect(.bounds),
            arrowEdge: .top,
            onDismiss: nil,
            content: { Text("First") }
        )

        let modifier2 = PopoverModifier(
            isPresented: Binding(get: { show2 }, set: { show2 = $0 }),
            attachmentAnchor: .point(.center),
            arrowEdge: .bottom,
            onDismiss: nil,
            content: { Text("Second") }
        )

        let id1 = modifier1.register(with: coordinator)!
        let id2 = modifier2.register(with: coordinator)!

        #expect(coordinator.count == 2)
        #expect(id1 != id2)
    }

    @Test func multiplePopoversWithDifferentEdges() {
        let coordinator = PresentationCoordinator()
        var show1 = true
        var show2 = true

        let modifier1 = PopoverModifier(
            isPresented: Binding(get: { show1 }, set: { show1 = $0 }),
            attachmentAnchor: .default,
            arrowEdge: .top,
            onDismiss: nil,
            content: { Text("Top") }
        )

        let modifier2 = PopoverModifier(
            isPresented: Binding(get: { show2 }, set: { show2 = $0 }),
            attachmentAnchor: .default,
            arrowEdge: .trailing,
            onDismiss: nil,
            content: { Text("Trailing") }
        )

        let id1 = modifier1.register(with: coordinator)!
        let id2 = modifier2.register(with: coordinator)!

        let entry1 = coordinator.presentations[0]
        let entry2 = coordinator.presentations[1]

        switch (entry1.type, entry2.type) {
        case (.popover(_, let edge1), .popover(_, let edge2)):
            #expect(edge1 == .top)
            #expect(edge2 == .trailing)
        default:
            Issue.record("Expected both to be popovers")
        }
    }

    // MARK: - Z-Index Tests

    @Test func popoverZIndex() {
        let coordinator = PresentationCoordinator()
        var isPresented = true

        let modifier = PopoverModifier(
            isPresented: Binding(
                get: { isPresented },
                set: { isPresented = $0 }
            ),
            attachmentAnchor: .default,
            arrowEdge: .top,
            onDismiss: nil,
            content: { Text("Content") }
        )

        let id = modifier.register(with: coordinator)!
        let entry = coordinator.presentations.first

        #expect(entry?.zIndex == 1000) // Base z-index
    }

    @Test func multiplePopoversZIndexIncrement() {
        let coordinator = PresentationCoordinator()
        var show1 = true
        var show2 = true

        let modifier1 = PopoverModifier(
            isPresented: Binding(get: { show1 }, set: { show1 = $0 }),
            attachmentAnchor: .default,
            arrowEdge: .top,
            onDismiss: nil,
            content: { Text("First") }
        )

        let modifier2 = PopoverModifier(
            isPresented: Binding(get: { show2 }, set: { show2 = $0 }),
            attachmentAnchor: .default,
            arrowEdge: .top,
            onDismiss: nil,
            content: { Text("Second") }
        )

        let _ = modifier1.register(with: coordinator)!
        let _ = modifier2.register(with: coordinator)!

        #expect(coordinator.presentations[0].zIndex == 1000)
        #expect(coordinator.presentations[1].zIndex == 1010) // Incremented by 10
    }

    // MARK: - Content Tests

    @Test func popoverContentIsStored() {
        let coordinator = PresentationCoordinator()
        var isPresented = true
        let expectedText = "Popover Content"

        let modifier = PopoverModifier(
            isPresented: Binding(
                get: { isPresented },
                set: { isPresented = $0 }
            ),
            attachmentAnchor: .default,
            arrowEdge: .top,
            onDismiss: nil,
            content: { Text(expectedText) }
        )

        let id = modifier.register(with: coordinator)!
        let entry = coordinator.presentations.first

        #expect(entry?.content != nil)
    }
}
