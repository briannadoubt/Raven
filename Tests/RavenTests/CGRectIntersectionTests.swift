import Testing
@testable import RavenCore

@MainActor
struct CGRectIntersectionTests {
    @Test("CGRect.intersection returns expected overlap")
    func intersectionOverlaps() {
        let a = CGRect(x: 0, y: 0, width: 10, height: 10)
        let b = CGRect(x: 5, y: 6, width: 10, height: 10)
        let i = a.intersection(b)
        #expect(i.isNull == false)
        #expect(i == CGRect(x: 5, y: 6, width: 5, height: 4))
    }

    @Test("CGRect.intersection returns null when disjoint")
    func intersectionDisjointIsNull() {
        let a = CGRect(x: 0, y: 0, width: 10, height: 10)
        let b = CGRect(x: 11, y: 0, width: 1, height: 1)
        let i = a.intersection(b)
        #expect(i.isNull == true)
    }
}

