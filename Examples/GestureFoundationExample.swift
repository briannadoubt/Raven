import Raven

/// Example demonstrating the Gesture foundation types.
///
/// This example shows how to use:
/// - GestureMask for controlling gesture recognition
/// - EventModifiers for detecting modifier keys
/// - Transaction for animation context
/// - @GestureState for temporary gesture state
///
/// Run this example to verify the gesture foundation is working correctly.
@MainActor
struct GestureFoundationExample {

    static func demonstrateGestureMask() {
        // Create different gesture masks
        let all = GestureMask.all
        let gestureOnly = GestureMask.gesture
        let subviewsOnly = GestureMask.subviews
        let none = GestureMask([])

        print("GestureMask.all contains gesture: \(all.contains(.gesture))")
        print("GestureMask.all contains subviews: \(all.contains(.subviews))")
        print("GestureMask.gesture contains gesture: \(gestureOnly.contains(.gesture))")
        print("GestureMask.gesture contains subviews: \(gestureOnly.contains(.subviews))")
    }

    static func demonstrateEventModifiers() {
        // Create modifier combinations
        let shiftCommand: EventModifiers = [.shift, .command]
        let controlOption: EventModifiers = [.control, .option]

        print("\nEventModifiers [shift, command] contains shift: \(shiftCommand.contains(.shift))")
        print("EventModifiers [shift, command] contains command: \(shiftCommand.contains(.command))")
        print("EventModifiers [shift, command] contains control: \(shiftCommand.contains(.control))")
    }

    static func demonstrateTransaction() {
        // Create transactions
        var transaction = Transaction()
        print("\nDefault transaction has animation: \(transaction.animation != nil)")
        print("Default transaction disables animations: \(transaction.disablesAnimations)")

        // Modify transaction
        transaction.animation = .spring()
        transaction.disablesAnimations = true
        print("Modified transaction has animation: \(transaction.animation != nil)")
        print("Modified transaction disables animations: \(transaction.disablesAnimations)")
    }

    static func demonstrateGestureState() {
        // Create gesture state
        let offset = GestureState(wrappedValue: Raven.CGSize(width: 0, height: 0))
        print("\nGestureState initial value: (\(offset.wrappedValue.width), \(offset.wrappedValue.height))")

        var transaction = Transaction()

        // Update gesture state
        offset.update(value: Raven.CGSize(width: 100, height: 50), transaction: &transaction)
        print("GestureState after update: (\(offset.wrappedValue.width), \(offset.wrappedValue.height))")

        // Reset gesture state
        offset.reset(transaction: &transaction)
        print("GestureState after reset: (\(offset.wrappedValue.width), \(offset.wrappedValue.height))")
    }

    static func demonstrateCustomReset() {
        // Create gesture state with custom reset
        var resetWasCalled = false
        let state = GestureState(
            reset: { value, transaction in
                print("\nCustom reset called with value: \(value)")
                resetWasCalled = true
                transaction.animation = .spring()
            },
            initialValue: 0.0
        )

        var transaction = Transaction()
        state.update(value: 1.5, transaction: &transaction)
        print("Value before reset: \(state.wrappedValue)")

        state.reset(transaction: &transaction)
        print("Value after reset: \(state.wrappedValue)")
        print("Reset was called: \(resetWasCalled)")
        print("Transaction has animation: \(transaction.animation != nil)")
    }

    static func run() {
        print("=== Gesture Foundation Example ===\n")
        demonstrateGestureMask()
        demonstrateEventModifiers()
        demonstrateTransaction()
        demonstrateGestureState()
        demonstrateCustomReset()
        print("\n=== Example Complete ===")
    }
}

// To run this example, uncomment the following line:
// GestureFoundationExample.run()
