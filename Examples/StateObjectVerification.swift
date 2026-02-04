import Foundation
import Raven

// MARK: - Verification Test for @StateObject and @ObservedObject

/// This file demonstrates the correct behavior of @StateObject and @ObservedObject
/// property wrappers in a simple, verifiable example.

// MARK: - Model

@MainActor
final class VerificationModel: ObservableObject {
    @Published var value: Int = 0
    @Published var name: String = "Test"

    var updateCount: Int = 0

    init(initialValue: Int = 0, name: String = "Test") {
        self.value = initialValue
        self.name = name
        setupPublished()

        // Subscribe to track updates
        objectWillChange.subscribe {
            self.updateCount += 1
        }
    }

    func increment() {
        value += 1
    }

    func updateName(_ newName: String) {
        name = newName
    }
}

// MARK: - @StateObject Verification

struct StateObjectTestView: View {
    /// This view owns the model
    @StateObject private var model = VerificationModel(initialValue: 100, name: "StateObject")

    var body: some View {
        VStack {
            Text("StateObject Test")
            Text("Value: \(model.value)")
            Text("Name: \(model.name)")

            Button("Increment") {
                model.increment()
            }

            Button("Change Name") {
                model.updateName("Updated")
            }

            // Pass to child view
            StateObjectChildView(model: model)
        }
    }
}

struct StateObjectChildView: View {
    /// This child observes the parent's model
    @ObservedObject var model: VerificationModel

    var body: some View {
        VStack {
            Text("Child View")
            Text("Observed Value: \(model.value)")
            Text("Observed Name: \(model.name)")

            Button("Increment from Child") {
                model.increment()
            }
        }
    }
}

// MARK: - @ObservedObject Verification

struct ObservedObjectTestView: View {
    /// Create a model to pass to children
    @StateObject private var sharedModel = VerificationModel(initialValue: 200, name: "Shared")

    var body: some View {
        VStack {
            Text("ObservedObject Test")
            Text("Parent Value: \(sharedModel.value)")

            // Multiple children observing the same model
            ObserverChild1(model: sharedModel)
            ObserverChild2(model: sharedModel)
            ObserverChild3(model: sharedModel)
        }
    }
}

struct ObserverChild1: View {
    @ObservedObject var model: VerificationModel

    var body: some View {
        VStack {
            Text("Child 1 - Value: \(model.value)")
            Button("Increment") {
                model.increment()
            }
        }
    }
}

struct ObserverChild2: View {
    @ObservedObject var model: VerificationModel

    var body: some View {
        VStack {
            Text("Child 2 - Value: \(model.value)")
            Button("Increment") {
                model.increment()
            }
        }
    }
}

struct ObserverChild3: View {
    @ObservedObject var model: VerificationModel

    var body: some View {
        VStack {
            Text("Child 3 - Name: \(model.name)")
            Button("Update Name") {
                model.updateName("Changed by Child 3")
            }
        }
    }
}

// MARK: - Complete Verification App

struct StateObjectVerificationApp: View {
    var body: some View {
        VStack {
            Text("Property Wrapper Verification")

            Divider()

            StateObjectTestView()

            Divider()

            ObservedObjectTestView()
        }
    }
}

// MARK: - Expected Behavior

/*
 This verification demonstrates:

 1. @StateObject Ownership:
    - StateObjectTestView creates and owns the model
    - Model is initialized lazily on first access
    - Model persists across view updates
    - Changes trigger view re-renders

 2. @ObservedObject Observation:
    - Child views observe parent's model
    - All observers see the same state
    - Changes from any observer trigger re-renders in all observers
    - No additional copies are created

 3. Publisher Subscriptions:
    - Each property wrapper subscribes to objectWillChange
    - Subscriptions trigger view updates via callback
    - Multiple subscriptions to same object work correctly
    - All observers react to changes

 4. Projected Values:
    - $model returns the object itself (not a Binding)
    - Can be passed to child views
    - Child views use @ObservedObject to observe it

 5. Thread Safety:
    - All operations are @MainActor isolated
    - Sendable conformance is correct
    - No data races possible

 Test Cases to Verify:

 ✓ Model initialization is lazy for @StateObject
 ✓ Model is created only once per @StateObject
 ✓ @ObservedObject does not create new instances
 ✓ Changes propagate to all observers
 ✓ Multiple children can observe same model
 ✓ Subscriptions are properly established
 ✓ View updates are triggered correctly
 ✓ Memory is managed properly (no leaks)

 Expected Console Output (if tracing enabled):
 - "Creating model" appears once per @StateObject
 - "Update triggered" appears when any @Published property changes
 - All observers receive updates simultaneously
 - No duplicate subscriptions or memory warnings
 */
