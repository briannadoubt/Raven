import Testing
@testable import Raven

@MainActor
@Suite struct GroupAndListParityTests {

    @Test func groupBuildsWithoutWrapperLayout() async throws {
        let group = Group {
            Text("First")
            Text("Second")
        }

        let body = group.body
        #expect(String(describing: type(of: body)).contains("TupleView"))
    }

    @Test func listSupportsClosedRangeData() async throws {
        let list = List(1...3) { index in
            Text("Row \(index)")
        }

        let vnode = list.toVNode()
        #expect(vnode.isElement(tag: "div"))
    }
}
