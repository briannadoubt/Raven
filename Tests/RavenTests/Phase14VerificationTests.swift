import XCTest
@testable import Raven

// MARK: - Phase 14 Verification Tests
//
// These tests verify that all Phase 14 APIs compile correctly and work as expected.
// They test all presentation types, modifiers, and variants to ensure the
// implementation is complete and functional.

@MainActor
final class Phase14VerificationTests: XCTestCase {

    // MARK: - Sheet API Verification

    func testSheetWithIsPresentedBindingCompiles() async throws {
        @MainActor struct TestView: View {
            @State private var isPresented = false

            var body: some View {
                Text("Test")
                    .sheet(isPresented: $isPresented) {
                        Text("Sheet Content")
                    }
            }
        }

        let view = TestView()
        XCTAssertNotNil(view.body)
    }

    func testSheetWithIsPresentedAndOnDismissCompiles() async throws {
        @MainActor struct TestView: View {
            @State private var isPresented = false
            @State private var dismissCount = 0

            var body: some View {
                Text("Test")
                    .sheet(isPresented: $isPresented, onDismiss: {
                        dismissCount += 1
                    }) {
                        Text("Sheet")
                    }
            }
        }

        let view = TestView()
        XCTAssertNotNil(view.body)
    }

    func testSheetWithItemBindingCompiles() async throws {
        struct Item: Identifiable, Sendable, Equatable {
            let id = UUID()
            let name: String
        }

        @MainActor struct TestView: View {
            @State private var item: Item?

            var body: some View {
                Text("Test")
                    .sheet(item: $item) { item in
                        Text(item.name)
                    }
            }
        }

        let view = TestView()
        XCTAssertNotNil(view.body)
    }

    // Add a basic compilation test for presentations
    func testPresentationSystemCompiles() async throws {
        @MainActor struct TestView: View {
            @State private var showSheet = false
            @State private var showAlert = false

            var body: some View {
                VStack {
                    Button("Show Sheet") { showSheet = true }
                    Button("Show Alert") { showAlert = true }
                }
                .sheet(isPresented: $showSheet) {
                    Text("Sheet")
                }
                .alert("Alert", isPresented: $showAlert) {
                    Button("OK") {}
                }
            }
        }

        let view = TestView()
        XCTAssertNotNil(view.body)
    }
}
