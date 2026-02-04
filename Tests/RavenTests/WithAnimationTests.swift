import Testing
@testable import Raven

/// Tests for the withAnimation() function and animation context system.
@Suite("WithAnimation Tests")
@MainActor
struct WithAnimationTests {

    // MARK: - Basic Functionality Tests

    @Test("withAnimation executes body closure")
    func testWithAnimationExecutesBody() async {
        var executed = false

        withAnimation {
            executed = true
        }

        #expect(executed == true)
    }

    @Test("withAnimation returns body result")
    func testWithAnimationReturnsResult() async {
        let result = withAnimation {
            return 42
        }

        #expect(result == 42)
    }

    @Test("withAnimation sets animation context")
    func testWithAnimationSetsContext() async {
        // Initially no animation
        #expect(AnimationContext.current == nil)

        withAnimation(.default) {
            // Inside block, animation should be set
            #expect(AnimationContext.current != nil)
            #expect(AnimationContext.current == .default)
        }

        // After block, context should be cleared
        #expect(AnimationContext.current == nil)
    }

    @Test("withAnimation with nil animation")
    func testWithAnimationNil() async {
        var executed = false

        withAnimation(nil) {
            executed = true
            // Context should be explicitly nil
            #expect(AnimationContext.current == nil)
        }

        #expect(executed == true)
    }

    @Test("withAnimation with custom animation")
    func testWithAnimationCustom() async {
        let springAnim = Animation.spring(response: 0.3, dampingFraction: 0.6)

        withAnimation(springAnim) {
            #expect(AnimationContext.current == springAnim)
        }

        let linearAnim = Animation.linear.delay(0.5)

        withAnimation(linearAnim) {
            #expect(AnimationContext.current == linearAnim)
        }
    }

    // MARK: - Nested Animation Tests

    @Test("Nested withAnimation uses innermost animation")
    func testNestedWithAnimation() async {
        let outerAnim = Animation.easeIn
        let innerAnim = Animation.spring()

        withAnimation(outerAnim) {
            #expect(AnimationContext.current == outerAnim)

            withAnimation(innerAnim) {
                #expect(AnimationContext.current == innerAnim)
            }

            // Back to outer animation
            #expect(AnimationContext.current == outerAnim)
        }

        // Context fully cleared
        #expect(AnimationContext.current == nil)
    }

    @Test("Multiple levels of nesting")
    func testMultipleLevelsOfNesting() async {
        let anim1 = Animation.default
        let anim2 = Animation.easeOut
        let anim3 = Animation.spring()

        withAnimation(anim1) {
            #expect(AnimationContext.current == anim1)

            withAnimation(anim2) {
                #expect(AnimationContext.current == anim2)

                withAnimation(anim3) {
                    #expect(AnimationContext.current == anim3)
                }

                #expect(AnimationContext.current == anim2)
            }

            #expect(AnimationContext.current == anim1)
        }

        #expect(AnimationContext.current == nil)
    }

    @Test("Nested withAnimation with nil")
    func testNestedWithAnimationNil() async {
        withAnimation(.default) {
            #expect(AnimationContext.current == .default)

            withAnimation(nil) {
                #expect(AnimationContext.current == nil)
            }

            // Restored to .default
            #expect(AnimationContext.current == .default)
        }
    }

    // MARK: - Error Handling Tests

    @Test("withAnimation propagates errors")
    func testWithAnimationPropagatesErrors() async {
        enum TestError: Error {
            case testFailure
        }

        do {
            try withAnimation {
                throw TestError.testFailure
            }
            #expect(Bool(false), "Should have thrown error")
        } catch TestError.testFailure {
            // Expected
        } catch {
            #expect(Bool(false), "Wrong error type")
        }

        // Context should still be cleared after error
        #expect(AnimationContext.current == nil)
    }

    @Test("withAnimation restores context after error")
    func testWithAnimationRestoresContextAfterError() async {
        enum TestError: Error {
            case testFailure
        }

        let outerAnim = Animation.easeIn

        do {
            try withAnimation(outerAnim) {
                #expect(AnimationContext.current == outerAnim)

                try withAnimation(.spring()) {
                    #expect(AnimationContext.current == .spring())
                    throw TestError.testFailure
                }

                #expect(Bool(false), "Should not reach here")
            }
        } catch {
            // Expected error
        }

        // Context should be fully cleared
        #expect(AnimationContext.current == nil)
    }

    // MARK: - Animation Type Tests

    @Test("withAnimation with different animation types")
    func testDifferentAnimationTypes() async {
        let animations: [Animation] = [
            .default,
            .linear,
            .easeIn,
            .easeOut,
            .easeInOut,
            .spring(),
            .spring(response: 0.3, dampingFraction: 0.6),
            .timingCurve(0.4, 0.0, 0.2, 1.0)
        ]

        for animation in animations {
            withAnimation(animation) {
                #expect(AnimationContext.current == animation)
            }
        }
    }

    @Test("withAnimation with modified animations")
    func testWithModifiedAnimations() async {
        let delayedAnim = Animation.default.delay(0.5)
        withAnimation(delayedAnim) {
            #expect(AnimationContext.current == delayedAnim)
        }

        let speedAnim = Animation.easeIn.speed(2.0)
        withAnimation(speedAnim) {
            #expect(AnimationContext.current == speedAnim)
        }

        let repeatAnim = Animation.linear.repeatCount(3)
        withAnimation(repeatAnim) {
            #expect(AnimationContext.current == repeatAnim)
        }

        let complexAnim = Animation.spring().delay(0.2).speed(1.5)
        withAnimation(complexAnim) {
            #expect(AnimationContext.current == complexAnim)
        }
    }

    // MARK: - Completion Callback Tests

    @Test("withAnimation with completion callback")
    func testWithAnimationCompletion() async {
        var bodyExecuted = false
        var completionExecuted = false

        withAnimation(.default, {
            bodyExecuted = true
        }, completion: {
            completionExecuted = true
        })

        #expect(bodyExecuted == true)
        // Note: Completion is stored but not immediately executed
        // It will be called by the rendering system when CSS transitions complete
    }

    @Test("withAnimation stores completion callback")
    func testWithAnimationStoresCompletion() async {
        var callbackInvoked = false

        withAnimation(.default, {
            // Body
        }, completion: {
            callbackInvoked = true
        })

        // Completion should be stored
        let storedCallback = AnimationContext.takeCompletionCallback()
        #expect(storedCallback != nil)

        // Invoke it manually to test
        if let callback = storedCallback {
            callback()
            #expect(callbackInvoked == true)
        }
    }

    @Test("withAnimation completion is cleared after take")
    func testCompletionClearedAfterTake() async {
        withAnimation(.default, {
            // Body
        }, completion: {
            // Callback
        })

        // First take should return callback
        let first = AnimationContext.takeCompletionCallback()
        #expect(first != nil)

        // Second take should return nil
        let second = AnimationContext.takeCompletionCallback()
        #expect(second == nil)
    }

    @Test("Nested animations with completion callbacks")
    func testNestedAnimationsWithCompletion() async {
        var outerCompleted = false
        var innerCompleted = false

        withAnimation(.default, {
            withAnimation(.spring(), {
                // Inner body
            }, completion: {
                innerCompleted = true
            })

            // Inner completion should be set
            let innerCallback = AnimationContext.takeCompletionCallback()
            #expect(innerCallback != nil)
            innerCallback?()
        }, completion: {
            outerCompleted = true
        })

        // Outer completion should be set
        let outerCallback = AnimationContext.takeCompletionCallback()
        #expect(outerCallback != nil)
        outerCallback?()

        #expect(innerCompleted == true)
        #expect(outerCompleted == true)
    }

    // MARK: - Context Management Tests

    @Test("getCurrentAnimation returns current animation")
    func testGetCurrentAnimation() async {
        #expect(AnimationContext.getCurrentAnimation() == nil)

        let animation = Animation.spring()
        withAnimation(animation) {
            #expect(AnimationContext.getCurrentAnimation() == animation)
        }

        #expect(AnimationContext.getCurrentAnimation() == nil)
    }

    @Test("Animation context is thread-local-like")
    func testAnimationContextIsolation() async {
        // Set animation in one context
        withAnimation(.easeIn) {
            #expect(AnimationContext.current == .easeIn)

            // Nested context should be independent
            withAnimation(.easeOut) {
                #expect(AnimationContext.current == .easeOut)
            }

            // Original context restored
            #expect(AnimationContext.current == .easeIn)
        }

        // All cleared
        #expect(AnimationContext.current == nil)
    }

    // MARK: - Integration Tests

    @Test("Multiple sequential withAnimation calls")
    func testSequentialAnimations() async {
        withAnimation(.default) {
            #expect(AnimationContext.current == .default)
        }

        #expect(AnimationContext.current == nil)

        withAnimation(.spring()) {
            #expect(AnimationContext.current == .spring())
        }

        #expect(AnimationContext.current == nil)

        withAnimation(nil) {
            #expect(AnimationContext.current == nil)
        }

        #expect(AnimationContext.current == nil)
    }

    @Test("withAnimation does not interfere with return values")
    func testWithAnimationReturnValues() async {
        let stringResult = withAnimation(.default) {
            return "test"
        }
        #expect(stringResult == "test")

        let intResult = withAnimation(.spring()) {
            return 123
        }
        #expect(intResult == 123)

        let tupleResult = withAnimation(.easeIn) {
            return (1, "two", 3.0)
        }
        #expect(tupleResult.0 == 1)
        #expect(tupleResult.1 == "two")
        #expect(tupleResult.2 == 3.0)
    }

    @Test("withAnimation with complex control flow")
    func testWithAnimationComplexControlFlow() async {
        var result = 0

        withAnimation(.default) {
            for i in 1...5 {
                result += i
                #expect(AnimationContext.current == .default)
            }

            if result > 10 {
                result *= 2
            }

            #expect(AnimationContext.current == .default)
        }

        #expect(result == 30) // (1+2+3+4+5) * 2 = 30
        #expect(AnimationContext.current == nil)
    }

    // MARK: - Edge Cases

    @Test("withAnimation with empty body")
    func testWithAnimationEmptyBody() async {
        withAnimation {
            // Empty body
        }

        #expect(AnimationContext.current == nil)
    }

    @Test("withAnimation with void return")
    func testWithAnimationVoidReturn() async {
        func voidFunction() {}

        withAnimation {
            voidFunction()
        }

        #expect(AnimationContext.current == nil)
    }

    @Test("Animation equality in context")
    func testAnimationEqualityInContext() async {
        let anim1 = Animation.easeIn.delay(0.5)
        let anim2 = Animation.easeIn.delay(0.5)

        withAnimation(anim1) {
            #expect(AnimationContext.current == anim1)
            #expect(AnimationContext.current == anim2) // Should be equal
        }
    }
}
