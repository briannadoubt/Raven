import Testing
@testable import SwiftUI
@testable import RavenCore

@MainActor
@Suite struct HoverAndDropParityTests {
    @Test func onHoverModifierCompiles() {
        let view = Text("Hover me").onHover { _ in }
        #expect(view != nil)
    }

    @Test func onContinuousHoverModifierCompiles() {
        let view = Text("Hover me").onContinuousHover { _ in }
        #expect(view != nil)
    }

    @Test func dropOperationAndProposalCompile() {
        let proposal = DropProposal(operation: .copy)
        #expect(proposal.operation == .copy)
        #expect(proposal.operationOutsideApplication == .copy)
        #expect(!proposal.debugDescription.isEmpty)
    }

    @Test func dropInfoConformanceCheck() {
        let info = DropInfo(location: .zero, items: [.text("hello")])
        #expect(info.hasItemsConforming(to: [.plainText]))
        #expect(info.location == .zero)
        #expect(info.itemProviders(for: [.plainText]).count == 1)
    }

    @Test func onDropWithDelegateCompiles() {
        struct DemoDropDelegate: DropDelegate {
            @MainActor func validateDrop(info: DropInfo) -> Bool {
                info.hasItemsConforming(to: [.plainText])
            }

            @MainActor func dropUpdated(info: DropInfo) -> DropProposal? {
                _ = info
                return DropProposal(operation: .copy)
            }

            @MainActor func dropEntered(info: DropInfo) {
                _ = info
            }

            @MainActor func dropExited(info: DropInfo) {
                _ = info
            }

            @MainActor func performDrop(info: DropInfo) -> Bool {
                _ = info
                return true
            }
        }

        let view = Text("Drop here").onDrop(of: [.plainText], delegate: DemoDropDelegate())
        #expect(view != nil)
    }
}
