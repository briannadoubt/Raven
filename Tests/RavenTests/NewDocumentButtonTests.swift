import Foundation
import SwiftUI
import Testing

@MainActor
@Suite struct NewDocumentButtonTests {
    @Test func customLabelRendersInButton() {
        let ctx = Phase2FakeRenderContext()

        let view = NewDocumentButton(action: {}) {
            HStack {
                Text("Create")
                Text("Now")
            }
        }

        let node = ctx.render(view)

        #expect(node.isElement(tag: "button"))
        #expect(node.children.count == 1)
        #expect(node.children[0].isElement(tag: "div"))
        #expect(node.children[0].children.count == 2)
    }
}
