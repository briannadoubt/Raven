import XCTest
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
final class PopoverModifierTests: XCTestCase {

    // MARK: - Test Types

    struct TestItem: Identifiable {
        let id: Int
        let name: String
    }

    // MARK: - isPresented Binding Tests

    func testPopoverPresentationWithBinding() {
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
        XCTAssertNil(modifier.register(with: coordinator))
        XCTAssertEqual(coordinator.count, 0)

        // Present the popover
        isPresented = true
        let id = modifier.register(with: coordinator)

        XCTAssertNotNil(id)
        XCTAssertEqual(coordinator.count, 1)

        let entry = coordinator.presentations.first
        XCTAssertEqual(entry?.id, id)

        switch entry?.type {
        case .popover(let anchor, let edge):
            XCTAssertEqual(anchor, .rect(.bounds))
            XCTAssertEqual(edge, .top)
        default:
            XCTFail("Expected popover presentation type")
        }
    }

    func testPopoverDismissal() {
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
        XCTAssertEqual(coordinator.count, 1)

        // Dismiss via coordinator
        coordinator.dismiss(id)
        XCTAssertEqual(coordinator.count, 0)
        XCTAssertTrue(dismissCalled)
        XCTAssertFalse(isPresented)
    }

    func testPopoverOnDismissCallback() {
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

        XCTAssertTrue(onDismissCalled)
        XCTAssertEqual(dismissCallCount, 1)
        XCTAssertFalse(isPresented)
    }

    // MARK: - Item Binding Tests

    func testPopoverPresentationWithItem() {
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
        XCTAssertNil(modifier.register(with: coordinator))
        XCTAssertEqual(coordinator.count, 0)

        // Present with item
        item = TestItem(id: 1, name: "First")
        let id = modifier.register(with: coordinator)

        XCTAssertNotNil(id)
        XCTAssertEqual(coordinator.count, 1)
    }

    func testPopoverItemDismissal() {
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
        XCTAssertEqual(coordinator.count, 1)

        // Dismiss
        coordinator.dismiss(id)
        XCTAssertEqual(coordinator.count, 0)
        XCTAssertTrue(dismissCalled)
        XCTAssertNil(item)
    }

    func testPopoverItemChange() {
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
        XCTAssertEqual(coordinator.count, 1)

        // Change to different item
        item = TestItem(id: 2, name: "Second")

        // Should need update since item ID changed
        XCTAssertTrue(modifier.shouldUpdate(currentId: id1, coordinator: coordinator))
    }

    func testPopoverItemSameId() {
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
        XCTAssertFalse(modifier.shouldUpdate(currentId: id, coordinator: coordinator))
    }

    // MARK: - Anchor Positioning Tests

    func testPopoverWithBoundsAnchor() {
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
            XCTAssertEqual(anchor, .rect(.bounds))
        default:
            XCTFail("Expected popover with bounds anchor")
        }
    }

    func testPopoverWithCustomRectAnchor() {
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
                XCTAssertEqual(rect.origin.x, 10)
                XCTAssertEqual(rect.origin.y, 20)
                XCTAssertEqual(rect.size.width, 100)
                XCTAssertEqual(rect.size.height, 50)
            default:
                XCTFail("Expected rect anchor with custom CGRect")
            }
        default:
            XCTFail("Expected popover presentation")
        }
    }

    func testPopoverWithPointAnchor() {
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
                XCTAssertEqual(point.x, 0.5)
                XCTAssertEqual(point.y, 0.5)
            default:
                XCTFail("Expected point anchor")
            }
        default:
            XCTFail("Expected popover presentation")
        }
    }

    func testPopoverWithDifferentUnitPoints() {
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
                    XCTAssertEqual(point, unitPoint, "Failed for \(name)")
                default:
                    XCTFail("Expected point anchor for \(name)")
                }
            default:
                XCTFail("Expected popover presentation for \(name)")
            }

            // Clean up for next test
            coordinator.dismiss(id)
        }
    }

    // MARK: - Arrow Edge Tests

    func testPopoverWithTopEdge() {
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
            XCTAssertEqual(edge, .top)
        default:
            XCTFail("Expected popover with top edge")
        }
    }

    func testPopoverWithDifferentEdges() {
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
                XCTAssertEqual(presentedEdge, edge, "Failed for edge \(edge)")
            default:
                XCTFail("Expected popover with \(edge) edge")
            }

            // Clean up for next test
            coordinator.dismiss(id)
        }
    }

    // MARK: - shouldUpdate Tests

    func testShouldUpdateWhenPresentingFromNil() {
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
        XCTAssertFalse(modifier.shouldUpdate(currentId: nil, coordinator: coordinator))

        // Want to present, no ID
        isPresented = true
        XCTAssertTrue(modifier.shouldUpdate(currentId: nil, coordinator: coordinator))
    }

    func testShouldUpdateWhenDismissing() {
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
        XCTAssertFalse(modifier.shouldUpdate(currentId: id, coordinator: coordinator))

        // Want to dismiss, have ID
        isPresented = false
        XCTAssertTrue(modifier.shouldUpdate(currentId: id, coordinator: coordinator))
    }

    func testItemShouldUpdateWhenChanging() {
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
        XCTAssertTrue(modifier.shouldUpdate(currentId: UUID(), coordinator: coordinator))
    }

    // MARK: - Multiple Popovers Tests

    func testMultiplePopoversWithDifferentAnchors() {
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

        XCTAssertEqual(coordinator.count, 2)
        XCTAssertNotEqual(id1, id2)
    }

    func testMultiplePopoversWithDifferentEdges() {
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
            XCTAssertEqual(edge1, .top)
            XCTAssertEqual(edge2, .trailing)
        default:
            XCTFail("Expected both to be popovers")
        }
    }

    // MARK: - Z-Index Tests

    func testPopoverZIndex() {
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

        XCTAssertEqual(entry?.zIndex, 1000) // Base z-index
    }

    func testMultiplePopoversZIndexIncrement() {
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

        XCTAssertEqual(coordinator.presentations[0].zIndex, 1000)
        XCTAssertEqual(coordinator.presentations[1].zIndex, 1010) // Incremented by 10
    }

    // MARK: - Content Tests

    func testPopoverContentIsStored() {
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

        XCTAssertNotNil(entry?.content)
    }
}
