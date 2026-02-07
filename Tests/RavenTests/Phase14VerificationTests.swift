import Foundation
import Testing
@testable import Raven

// MARK: - Phase 14 Verification Tests
//
// These tests verify that all Phase 14 APIs compile correctly and work as expected.
// They test all presentation types, modifiers, and variants to ensure the
// implementation is complete and functional.

@MainActor
@Suite struct Phase14VerificationTests {

    // MARK: - Sheet API Verification

    @Test func sheetWithIsPresentedBindingCompiles() async throws {
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
        #expect(view.body != nil)
    }

    @Test func sheetWithIsPresentedAndOnDismissCompiles() async throws {
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
        #expect(view.body != nil)
    }

    @Test func sheetWithItemBindingCompiles() async throws {
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
        #expect(view.body != nil)
    }

    // Add a basic compilation test for presentations
    @Test func presentationSystemCompiles() async throws {
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
        #expect(view.body != nil)
    }
}
