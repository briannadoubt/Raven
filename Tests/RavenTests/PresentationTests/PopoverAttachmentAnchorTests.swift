import XCTest
@testable import Raven

/// Tests for PopoverAttachmentAnchor and its nested types.
///
/// These tests verify:
/// - Anchor type creation and representation
/// - Equality and hashing behavior
/// - Sendable conformance
/// - CustomStringConvertible output
@MainActor
final class PopoverAttachmentAnchorTests: XCTestCase {

    // MARK: - Anchor Type Tests

    func testRectBoundsAnchor() {
        let anchor = PopoverAttachmentAnchor.rect(.bounds)

        switch anchor {
        case .rect(.bounds):
            XCTAssertTrue(true, "Anchor is rect with bounds")
        default:
            XCTFail("Expected rect(.bounds) anchor")
        }
    }

    func testRectCustomAnchor() {
        let rect = Raven.CGRect(x: 10, y: 20, width: 100, height: 50)
        let anchor = PopoverAttachmentAnchor.rect(.rect(rect))

        switch anchor {
        case .rect(.rect(let extractedRect)):
            XCTAssertEqual(extractedRect.origin.x, 10)
            XCTAssertEqual(extractedRect.origin.y, 20)
            XCTAssertEqual(extractedRect.size.width, 100)
            XCTAssertEqual(extractedRect.size.height, 50)
        default:
            XCTFail("Expected rect(.rect) anchor")
        }
    }

    func testPointAnchor() {
        let anchor = PopoverAttachmentAnchor.point(.center)

        switch anchor {
        case .point(let unitPoint):
            XCTAssertEqual(unitPoint.x, 0.5)
            XCTAssertEqual(unitPoint.y, 0.5)
        default:
            XCTFail("Expected point anchor")
        }
    }

    func testPointAnchorCorners() {
        let topLeading = PopoverAttachmentAnchor.point(.topLeading)
        let bottomTrailing = PopoverAttachmentAnchor.point(.bottomTrailing)

        switch topLeading {
        case .point(let point):
            XCTAssertEqual(point.x, 0)
            XCTAssertEqual(point.y, 0)
        default:
            XCTFail("Expected topLeading point")
        }

        switch bottomTrailing {
        case .point(let point):
            XCTAssertEqual(point.x, 1)
            XCTAssertEqual(point.y, 1)
        default:
            XCTFail("Expected bottomTrailing point")
        }
    }

    // MARK: - Default Value Tests

    func testDefaultAnchor() {
        let anchor = PopoverAttachmentAnchor.default

        switch anchor {
        case .rect(.bounds):
            XCTAssertTrue(true, "Default is rect(.bounds)")
        default:
            XCTFail("Expected default to be rect(.bounds)")
        }
    }

    // MARK: - Equality Tests

    func testRectBoundsEquality() {
        let anchor1 = PopoverAttachmentAnchor.rect(.bounds)
        let anchor2 = PopoverAttachmentAnchor.rect(.bounds)

        XCTAssertEqual(anchor1, anchor2)
    }

    func testRectCustomEquality() {
        let rect = Raven.CGRect(x: 10, y: 20, width: 100, height: 50)
        let anchor1 = PopoverAttachmentAnchor.rect(.rect(rect))
        let anchor2 = PopoverAttachmentAnchor.rect(.rect(rect))

        XCTAssertEqual(anchor1, anchor2)
    }

    func testRectCustomInequality() {
        let rect1 = Raven.CGRect(x: 10, y: 20, width: 100, height: 50)
        let rect2 = Raven.CGRect(x: 15, y: 25, width: 100, height: 50)
        let anchor1 = PopoverAttachmentAnchor.rect(.rect(rect1))
        let anchor2 = PopoverAttachmentAnchor.rect(.rect(rect2))

        XCTAssertNotEqual(anchor1, anchor2)
    }

    func testPointEquality() {
        let anchor1 = PopoverAttachmentAnchor.point(.center)
        let anchor2 = PopoverAttachmentAnchor.point(.center)

        XCTAssertEqual(anchor1, anchor2)
    }

    func testPointInequality() {
        let anchor1 = PopoverAttachmentAnchor.point(.center)
        let anchor2 = PopoverAttachmentAnchor.point(.topLeading)

        XCTAssertNotEqual(anchor1, anchor2)
    }

    func testDifferentTypeInequality() {
        let rectAnchor = PopoverAttachmentAnchor.rect(.bounds)
        let pointAnchor = PopoverAttachmentAnchor.point(.center)

        XCTAssertNotEqual(rectAnchor, pointAnchor)
    }

    // MARK: - Hashing Tests

    func testHashingConsistency() {
        let anchor1 = PopoverAttachmentAnchor.rect(.bounds)
        let anchor2 = PopoverAttachmentAnchor.rect(.bounds)

        XCTAssertEqual(anchor1.hashValue, anchor2.hashValue)
    }

    func testHashingDifference() {
        let rectAnchor = PopoverAttachmentAnchor.rect(.bounds)
        let pointAnchor = PopoverAttachmentAnchor.point(.center)

        // Hash values should typically be different (not guaranteed, but likely)
        // We just verify they can be hashed without issues
        let set: Set<PopoverAttachmentAnchor> = [rectAnchor, pointAnchor]
        XCTAssertEqual(set.count, 2)
    }

    func testHashingInSet() {
        let anchor1 = PopoverAttachmentAnchor.rect(.bounds)
        let anchor2 = PopoverAttachmentAnchor.rect(.bounds)
        let anchor3 = PopoverAttachmentAnchor.point(.center)

        let set: Set<PopoverAttachmentAnchor> = [anchor1, anchor2, anchor3]

        // anchor1 and anchor2 are equal, so set should contain 2 elements
        XCTAssertEqual(set.count, 2)
        XCTAssertTrue(set.contains(anchor1))
        XCTAssertTrue(set.contains(anchor3))
    }

    // MARK: - Nested Anchor Type Tests

    func testNestedAnchorBounds() {
        let anchor = PopoverAttachmentAnchor.Anchor.bounds

        switch anchor {
        case .bounds:
            XCTAssertTrue(true, "Anchor is bounds")
        case .rect:
            XCTFail("Expected bounds, got rect")
        }
    }

    func testNestedAnchorRect() {
        let rect = Raven.CGRect(x: 5, y: 10, width: 50, height: 25)
        let anchor = PopoverAttachmentAnchor.Anchor.rect(rect)

        switch anchor {
        case .bounds:
            XCTFail("Expected rect, got bounds")
        case .rect(let extractedRect):
            XCTAssertEqual(extractedRect, rect)
        }
    }

    func testNestedAnchorEquality() {
        let anchor1 = PopoverAttachmentAnchor.Anchor.bounds
        let anchor2 = PopoverAttachmentAnchor.Anchor.bounds

        XCTAssertEqual(anchor1, anchor2)
    }

    func testNestedAnchorInequality() {
        let anchor1 = PopoverAttachmentAnchor.Anchor.bounds
        let anchor2 = PopoverAttachmentAnchor.Anchor.rect(.zero)

        XCTAssertNotEqual(anchor1, anchor2)
    }

    // MARK: - CustomStringConvertible Tests

    func testRectBoundsDescription() {
        let anchor = PopoverAttachmentAnchor.rect(.bounds)
        let description = anchor.description

        XCTAssertTrue(description.contains("PopoverAttachmentAnchor.rect"))
        XCTAssertTrue(description.contains(".bounds"))
    }

    func testRectCustomDescription() {
        let rect = Raven.CGRect(x: 10, y: 20, width: 100, height: 50)
        let anchor = PopoverAttachmentAnchor.rect(.rect(rect))
        let description = anchor.description

        XCTAssertTrue(description.contains("PopoverAttachmentAnchor.rect"))
        XCTAssertTrue(description.contains(".rect"))
    }

    func testPointDescription() {
        let anchor = PopoverAttachmentAnchor.point(.center)
        let description = anchor.description

        XCTAssertTrue(description.contains("PopoverAttachmentAnchor.point"))
        XCTAssertTrue(description.contains("0.5"))
    }

    func testNestedAnchorBoundsDescription() {
        let anchor = PopoverAttachmentAnchor.Anchor.bounds
        let description = anchor.description

        XCTAssertEqual(description, ".bounds")
    }

    func testNestedAnchorRectDescription() {
        let rect = Raven.CGRect(x: 10, y: 20, width: 100, height: 50)
        let anchor = PopoverAttachmentAnchor.Anchor.rect(rect)
        let description = anchor.description

        XCTAssertTrue(description.contains(".rect"))
        XCTAssertTrue(description.contains("10"))
        XCTAssertTrue(description.contains("20"))
        XCTAssertTrue(description.contains("100"))
        XCTAssertTrue(description.contains("50"))
    }

    // MARK: - Sendable Conformance Tests

    func testSendableConformance() {
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

    func testNestedAnchorSendable() {
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

    func testCGRectZero() {
        let anchor = PopoverAttachmentAnchor.rect(.rect(.zero))

        switch anchor {
        case .rect(.rect(let rect)):
            XCTAssertEqual(rect.origin.x, 0)
            XCTAssertEqual(rect.origin.y, 0)
            XCTAssertEqual(rect.size.width, 0)
            XCTAssertEqual(rect.size.height, 0)
        default:
            XCTFail("Expected rect with CGRect.zero")
        }
    }

    func testCGRectCustomValues() {
        let customRect = Raven.CGRect(
            origin: Raven.CGPoint(x: 100, y: 200),
            size: Raven.CGSize(width: 300, height: 400)
        )
        let anchor = PopoverAttachmentAnchor.rect(.rect(customRect))

        switch anchor {
        case .rect(.rect(let rect)):
            XCTAssertEqual(rect.origin.x, 100)
            XCTAssertEqual(rect.origin.y, 200)
            XCTAssertEqual(rect.width, 300)
            XCTAssertEqual(rect.height, 400)
        default:
            XCTFail("Expected rect with custom CGRect")
        }
    }

    // MARK: - Edge Case Tests

    func testNegativeCoordinates() {
        let rect = Raven.CGRect(x: -10, y: -20, width: 50, height: 60)
        let anchor = PopoverAttachmentAnchor.rect(.rect(rect))

        switch anchor {
        case .rect(.rect(let extractedRect)):
            XCTAssertEqual(extractedRect.origin.x, -10)
            XCTAssertEqual(extractedRect.origin.y, -20)
        default:
            XCTFail("Expected rect with negative coordinates")
        }
    }

    func testUnitPointOutsideBounds() {
        // UnitPoint can have values outside 0-1 range
        let customPoint = UnitPoint(x: -0.5, y: 1.5)
        let anchor = PopoverAttachmentAnchor.point(customPoint)

        switch anchor {
        case .point(let point):
            XCTAssertEqual(point.x, -0.5)
            XCTAssertEqual(point.y, 1.5)
        default:
            XCTFail("Expected point with custom coordinates")
        }
    }
}
