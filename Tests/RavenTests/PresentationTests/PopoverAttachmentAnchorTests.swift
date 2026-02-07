import Testing
@testable import Raven

/// Tests for PopoverAttachmentAnchor and its nested types.
///
/// These tests verify:
/// - Anchor type creation and representation
/// - Equality and hashing behavior
/// - Sendable conformance
/// - CustomStringConvertible output
@MainActor
@Suite struct PopoverAttachmentAnchorTests {

    // MARK: - Anchor Type Tests

    @Test func rectBoundsAnchor() {
        let anchor = PopoverAttachmentAnchor.rect(.bounds)

        switch anchor {
        case .rect(.bounds):
            #expect(true)
        default:
            Issue.record("Expected rect(.bounds) anchor")
        }
    }

    @Test func rectCustomAnchor() {
        let rect = Raven.CGRect(x: 10, y: 20, width: 100, height: 50)
        let anchor = PopoverAttachmentAnchor.rect(.rect(rect))

        switch anchor {
        case .rect(.rect(let extractedRect)):
            #expect(extractedRect.origin.x == 10)
            #expect(extractedRect.origin.y == 20)
            #expect(extractedRect.size.width == 100)
            #expect(extractedRect.size.height == 50)
        default:
            Issue.record("Expected rect(.rect) anchor")
        }
    }

    @Test func pointAnchor() {
        let anchor = PopoverAttachmentAnchor.point(.center)

        switch anchor {
        case .point(let unitPoint):
            #expect(unitPoint.x == 0.5)
            #expect(unitPoint.y == 0.5)
        default:
            Issue.record("Expected point anchor")
        }
    }

    @Test func pointAnchorCorners() {
        let topLeading = PopoverAttachmentAnchor.point(.topLeading)
        let bottomTrailing = PopoverAttachmentAnchor.point(.bottomTrailing)

        switch topLeading {
        case .point(let point):
            #expect(point.x == 0)
            #expect(point.y == 0)
        default:
            Issue.record("Expected topLeading point")
        }

        switch bottomTrailing {
        case .point(let point):
            #expect(point.x == 1)
            #expect(point.y == 1)
        default:
            Issue.record("Expected bottomTrailing point")
        }
    }

    // MARK: - Default Value Tests

    @Test func defaultAnchor() {
        let anchor = PopoverAttachmentAnchor.default

        switch anchor {
        case .rect(.bounds):
            #expect(true)
        default:
            Issue.record("Expected default to be rect(.bounds)")
        }
    }

    // MARK: - Equality Tests

    @Test func rectBoundsEquality() {
        let anchor1 = PopoverAttachmentAnchor.rect(.bounds)
        let anchor2 = PopoverAttachmentAnchor.rect(.bounds)

        #expect(anchor1 == anchor2)
    }

    @Test func rectCustomEquality() {
        let rect = Raven.CGRect(x: 10, y: 20, width: 100, height: 50)
        let anchor1 = PopoverAttachmentAnchor.rect(.rect(rect))
        let anchor2 = PopoverAttachmentAnchor.rect(.rect(rect))

        #expect(anchor1 == anchor2)
    }

    @Test func rectCustomInequality() {
        let rect1 = Raven.CGRect(x: 10, y: 20, width: 100, height: 50)
        let rect2 = Raven.CGRect(x: 15, y: 25, width: 100, height: 50)
        let anchor1 = PopoverAttachmentAnchor.rect(.rect(rect1))
        let anchor2 = PopoverAttachmentAnchor.rect(.rect(rect2))

        #expect(anchor1 != anchor2)
    }

    @Test func pointEquality() {
        let anchor1 = PopoverAttachmentAnchor.point(.center)
        let anchor2 = PopoverAttachmentAnchor.point(.center)

        #expect(anchor1 == anchor2)
    }

    @Test func pointInequality() {
        let anchor1 = PopoverAttachmentAnchor.point(.center)
        let anchor2 = PopoverAttachmentAnchor.point(.topLeading)

        #expect(anchor1 != anchor2)
    }

    @Test func differentTypeInequality() {
        let rectAnchor = PopoverAttachmentAnchor.rect(.bounds)
        let pointAnchor = PopoverAttachmentAnchor.point(.center)

        #expect(rectAnchor != pointAnchor)
    }

    // MARK: - Hashing Tests

    @Test func hashingConsistency() {
        let anchor1 = PopoverAttachmentAnchor.rect(.bounds)
        let anchor2 = PopoverAttachmentAnchor.rect(.bounds)

        #expect(anchor1.hashValue == anchor2.hashValue)
    }

    @Test func hashingDifference() {
        let rectAnchor = PopoverAttachmentAnchor.rect(.bounds)
        let pointAnchor = PopoverAttachmentAnchor.point(.center)

        // Hash values should typically be different (not guaranteed, but likely)
        // We just verify they can be hashed without issues
        let set: Set<PopoverAttachmentAnchor> = [rectAnchor, pointAnchor]
        #expect(set.count == 2)
    }

    @Test func hashingInSet() {
        let anchor1 = PopoverAttachmentAnchor.rect(.bounds)
        let anchor2 = PopoverAttachmentAnchor.rect(.bounds)
        let anchor3 = PopoverAttachmentAnchor.point(.center)

        let set: Set<PopoverAttachmentAnchor> = [anchor1, anchor2, anchor3]

        // anchor1 and anchor2 are equal, so set should contain 2 elements
        #expect(set.count == 2)
        #expect(set.contains(anchor1))
        #expect(set.contains(anchor3))
    }

    // MARK: - Nested Anchor Type Tests

    @Test func nestedAnchorBounds() {
        let anchor = PopoverAttachmentAnchor.Anchor.bounds

        switch anchor {
        case .bounds:
            #expect(true)
        case .rect:
            Issue.record("Expected bounds, got rect")
        }
    }

    @Test func nestedAnchorRect() {
        let rect = Raven.CGRect(x: 5, y: 10, width: 50, height: 25)
        let anchor = PopoverAttachmentAnchor.Anchor.rect(rect)

        switch anchor {
        case .bounds:
            Issue.record("Expected rect, got bounds")
        case .rect(let extractedRect):
            #expect(extractedRect == rect)
        }
    }

    @Test func nestedAnchorEquality() {
        let anchor1 = PopoverAttachmentAnchor.Anchor.bounds
        let anchor2 = PopoverAttachmentAnchor.Anchor.bounds

        #expect(anchor1 == anchor2)
    }

    @Test func nestedAnchorInequality() {
        let anchor1 = PopoverAttachmentAnchor.Anchor.bounds
        let anchor2 = PopoverAttachmentAnchor.Anchor.rect(.zero)

        #expect(anchor1 != anchor2)
    }

    // MARK: - CustomStringConvertible Tests

    @Test func rectBoundsDescription() {
        let anchor = PopoverAttachmentAnchor.rect(.bounds)
        let description = anchor.description

        #expect(description.contains("PopoverAttachmentAnchor.rect"))
        #expect(description.contains(".bounds"))
    }

    @Test func rectCustomDescription() {
        let rect = Raven.CGRect(x: 10, y: 20, width: 100, height: 50)
        let anchor = PopoverAttachmentAnchor.rect(.rect(rect))
        let description = anchor.description

        #expect(description.contains("PopoverAttachmentAnchor.rect"))
        #expect(description.contains(".rect"))
    }

    @Test func pointDescription() {
        let anchor = PopoverAttachmentAnchor.point(.center)
        let description = anchor.description

        #expect(description.contains("PopoverAttachmentAnchor.point"))
        #expect(description.contains("0.5"))
    }

    @Test func nestedAnchorBoundsDescription() {
        let anchor = PopoverAttachmentAnchor.Anchor.bounds
        let description = anchor.description

        #expect(description == ".bounds")
    }

    @Test func nestedAnchorRectDescription() {
        let rect = Raven.CGRect(x: 10, y: 20, width: 100, height: 50)
        let anchor = PopoverAttachmentAnchor.Anchor.rect(rect)
        let description = anchor.description

        #expect(description.contains(".rect"))
        #expect(description.contains("10"))
        #expect(description.contains("20"))
        #expect(description.contains("100"))
        #expect(description.contains("50"))
    }

    // MARK: - Sendable Conformance Tests

    @Test func sendableConformance() {
        // This test verifies that PopoverAttachmentAnchor can be used in concurrent contexts
        // If it compiles, the Sendable conformance is working correctly

        Task {
            let anchor = PopoverAttachmentAnchor.rect(.bounds)
            await sendAnchor(anchor)
        }

        Task {
            let anchor = PopoverAttachmentAnchor.point(.center)
            await sendAnchor(anchor)
        }
    }

    private func sendAnchor(_ anchor: PopoverAttachmentAnchor) async {
        // Just using the anchor in an async context
        _ = anchor
    }

    @Test func nestedAnchorSendable() {
        // Verify nested Anchor type is also Sendable
        Task {
            let anchor = PopoverAttachmentAnchor.Anchor.bounds
            await sendNestedAnchor(anchor)
        }
    }

    private func sendNestedAnchor(_ anchor: PopoverAttachmentAnchor.Anchor) async {
        _ = anchor
    }

    // MARK: - CGRect Integration Tests

    @Test func cgRectZero() {
        let anchor = PopoverAttachmentAnchor.rect(.rect(.zero))

        switch anchor {
        case .rect(.rect(let rect)):
            #expect(rect.origin.x == 0)
            #expect(rect.origin.y == 0)
            #expect(rect.size.width == 0)
            #expect(rect.size.height == 0)
        default:
            Issue.record("Expected rect with CGRect.zero")
        }
    }

    @Test func cgRectCustomValues() {
        let customRect = Raven.CGRect(
            origin: Raven.CGPoint(x: 100, y: 200),
            size: Raven.CGSize(width: 300, height: 400)
        )
        let anchor = PopoverAttachmentAnchor.rect(.rect(customRect))

        switch anchor {
        case .rect(.rect(let rect)):
            #expect(rect.origin.x == 100)
            #expect(rect.origin.y == 200)
            #expect(rect.width == 300)
            #expect(rect.height == 400)
        default:
            Issue.record("Expected rect with custom CGRect")
        }
    }

    // MARK: - Edge Case Tests

    @Test func negativeCoordinates() {
        let rect = Raven.CGRect(x: -10, y: -20, width: 50, height: 60)
        let anchor = PopoverAttachmentAnchor.rect(.rect(rect))

        switch anchor {
        case .rect(.rect(let extractedRect)):
            #expect(extractedRect.origin.x == -10)
            #expect(extractedRect.origin.y == -20)
        default:
            Issue.record("Expected rect with negative coordinates")
        }
    }

    @Test func unitPointOutsideBounds() {
        // UnitPoint can have values outside 0-1 range
        let customPoint = UnitPoint(x: -0.5, y: 1.5)
        let anchor = PopoverAttachmentAnchor.point(customPoint)

        switch anchor {
        case .point(let point):
            #expect(point.x == -0.5)
            #expect(point.y == 1.5)
        default:
            Issue.record("Expected point with custom coordinates")
        }
    }
}
