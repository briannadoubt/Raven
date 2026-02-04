import Testing
@testable import Raven

/// Quick verification tests for gesture foundation.
@Suite("Gesture Foundation Tests")
@MainActor
struct GestureFoundationTests {

    @Test("GestureMask basic operations")
    func gestureMaskOperations() {
        let mask = GestureMask.all
        #expect(mask.contains(.gesture))
        #expect(mask.contains(.subviews))

        let none = GestureMask([])
        #expect(!none.contains(.gesture))
        #expect(!none.contains(.subviews))
    }

    @Test("EventModifiers basic operations")
    func eventModifiersOperations() {
        let modifiers: EventModifiers = [.shift, .command]
        #expect(modifiers.contains(.shift))
        #expect(modifiers.contains(.command))
        #expect(!modifiers.contains(.control))
    }

    @Test("Transaction initialization")
    func transactionInit() {
        let transaction = Transaction()
        #expect(transaction.animation == nil)
        #expect(transaction.disablesAnimations == false)

        var t2 = Transaction(animation: .default)
        t2.disablesAnimations = true
        #expect(t2.animation != nil)
        #expect(t2.disablesAnimations == true)
    }

    @Test("GestureState basic functionality")
    func gestureStateBasics() {
        let state = GestureState(wrappedValue: 42)
        #expect(state.wrappedValue == 42)

        var transaction = Transaction()
        state.update(value: 100, transaction: &transaction)
        #expect(state.wrappedValue == 100)

        state.reset(transaction: &transaction)
        #expect(state.wrappedValue == 42)
    }

    @Test("GestureState with custom reset")
    func gestureStateCustomReset() {
        var resetCalled = false
        let state = GestureState(
            reset: { _, _ in
                resetCalled = true
            },
            initialValue: 0
        )

        var transaction = Transaction()
        state.update(value: 50, transaction: &transaction)
        state.reset(transaction: &transaction)

        #expect(resetCalled)
        #expect(state.wrappedValue == 0)
    }
}
