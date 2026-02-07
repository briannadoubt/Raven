import Testing
@testable import Raven

/// Tests for visual effect modifiers: blur, brightness, contrast, and saturation
///
/// These tests verify:
/// - Individual modifier functionality
/// - Correct CSS filter generation
/// - Modifier composition (multiple effects on same view)
/// - Edge cases and default values
/// - Type safety and Sendable conformance
@MainActor
@Suite struct VisualEffectTests {

    // MARK: - Blur Tests

    @Test func blurModifierCreation() {
        // Create a view with blur
        let view = Text("Blurred")
            .blur(radius: 10)

        // Verify the type is correct
        #expect(view is _BlurView<Text>)
    }

    @Test func blurVNodeGeneration() {
        // Create a blurred view
        let view = Text("Test")
            .blur(radius: 5)

        let vnode = view.toVNode()

        // Verify the VNode is a div element
        #expect(vnode.elementTag == "div")

        // Verify the filter property is set correctly
        if case .style(let name, let value) = vnode.props["filter"] {
            #expect(name == "filter")
            #expect(value == "blur(5.0px)")
        } else {
            Issue.record("Expected filter style property")
        }
    }

    @Test func blurWithZeroRadius() {
        // Test blur with zero radius (no effect)
        let view = Text("Test")
            .blur(radius: 0)

        let vnode = view.toVNode()

        if case .style(_, let value) = vnode.props["filter"] {
            #expect(value == "blur(0.0px)")
        } else {
            Issue.record("Expected filter style property")
        }
    }

    @Test func blurWithLargeRadius() {
        // Test blur with large radius
        let view = Text("Test")
            .blur(radius: 50)

        let vnode = view.toVNode()

        if case .style(_, let value) = vnode.props["filter"] {
            #expect(value == "blur(50.0px)")
        } else {
            Issue.record("Expected filter style property")
        }
    }

    // MARK: - Brightness Tests

    @Test func brightnessModifierCreation() {
        // Create a view with brightness adjustment
        let view = Text("Bright")
            .brightness(1.5)

        // Verify the type is correct
        #expect(view is _BrightnessView<Text>)
    }

    @Test func brightnessVNodeGeneration() {
        // Create a brightness-adjusted view
        let view = Text("Test")
            .brightness(0.8)

        let vnode = view.toVNode()

        // Verify the VNode is a div element
        #expect(vnode.elementTag == "div")

        // Verify the filter property is set correctly
        if case .style(let name, let value) = vnode.props["filter"] {
            #expect(name == "filter")
            #expect(value == "brightness(0.8)")
        } else {
            Issue.record("Expected filter style property")
        }
    }

    @Test func brightnessNormalValue() {
        // Test brightness with normal value (1.0 = no change)
        let view = Text("Test")
            .brightness(1.0)

        let vnode = view.toVNode()

        if case .style(_, let value) = vnode.props["filter"] {
            #expect(value == "brightness(1.0)")
        } else {
            Issue.record("Expected filter style property")
        }
    }

    @Test func brightnessBlack() {
        // Test brightness at 0 (completely black)
        let view = Text("Test")
            .brightness(0)

        let vnode = view.toVNode()

        if case .style(_, let value) = vnode.props["filter"] {
            #expect(value == "brightness(0.0)")
        } else {
            Issue.record("Expected filter style property")
        }
    }

    @Test func brightnessAboveNormal() {
        // Test brightness above 1.0 (brighter)
        let view = Text("Test")
            .brightness(2.0)

        let vnode = view.toVNode()

        if case .style(_, let value) = vnode.props["filter"] {
            #expect(value == "brightness(2.0)")
        } else {
            Issue.record("Expected filter style property")
        }
    }

    // MARK: - Contrast Tests

    @Test func contrastModifierCreation() {
        // Create a view with contrast adjustment
        let view = Text("High Contrast")
            .contrast(1.5)

        // Verify the type is correct
        #expect(view is _ContrastView<Text>)
    }

    @Test func contrastVNodeGeneration() {
        // Create a contrast-adjusted view
        let view = Text("Test")
            .contrast(1.2)

        let vnode = view.toVNode()

        // Verify the VNode is a div element
        #expect(vnode.elementTag == "div")

        // Verify the filter property is set correctly
        if case .style(let name, let value) = vnode.props["filter"] {
            #expect(name == "filter")
            #expect(value == "contrast(1.2)")
        } else {
            Issue.record("Expected filter style property")
        }
    }

    @Test func contrastNormalValue() {
        // Test contrast with normal value (1.0 = no change)
        let view = Text("Test")
            .contrast(1.0)

        let vnode = view.toVNode()

        if case .style(_, let value) = vnode.props["filter"] {
            #expect(value == "contrast(1.0)")
        } else {
            Issue.record("Expected filter style property")
        }
    }

    @Test func contrastGray() {
        // Test contrast at 0 (completely gray)
        let view = Text("Test")
            .contrast(0)

        let vnode = view.toVNode()

        if case .style(_, let value) = vnode.props["filter"] {
            #expect(value == "contrast(0.0)")
        } else {
            Issue.record("Expected filter style property")
        }
    }

    @Test func contrastHighValue() {
        // Test high contrast
        let view = Text("Test")
            .contrast(3.0)

        let vnode = view.toVNode()

        if case .style(_, let value) = vnode.props["filter"] {
            #expect(value == "contrast(3.0)")
        } else {
            Issue.record("Expected filter style property")
        }
    }

    // MARK: - Saturation Tests

    @Test func saturationModifierCreation() {
        // Create a view with saturation adjustment
        let view = Text("Vibrant")
            .saturation(1.5)

        // Verify the type is correct
        #expect(view is _SaturationView<Text>)
    }

    @Test func saturationVNodeGeneration() {
        // Create a saturation-adjusted view
        let view = Text("Test")
            .saturation(0.5)

        let vnode = view.toVNode()

        // Verify the VNode is a div element
        #expect(vnode.elementTag == "div")

        // Verify the filter property is set correctly
        if case .style(let name, let value) = vnode.props["filter"] {
            #expect(name == "filter")
            #expect(value == "saturate(0.5)")
        } else {
            Issue.record("Expected filter style property")
        }
    }

    @Test func saturationNormalValue() {
        // Test saturation with normal value (1.0 = no change)
        let view = Text("Test")
            .saturation(1.0)

        let vnode = view.toVNode()

        if case .style(_, let value) = vnode.props["filter"] {
            #expect(value == "saturate(1.0)")
        } else {
            Issue.record("Expected filter style property")
        }
    }

    @Test func saturationGrayscale() {
        // Test saturation at 0 (grayscale)
        let view = Text("Test")
            .saturation(0)

        let vnode = view.toVNode()

        if case .style(_, let value) = vnode.props["filter"] {
            #expect(value == "saturate(0.0)")
        } else {
            Issue.record("Expected filter style property")
        }
    }

    @Test func saturationSupersaturated() {
        // Test high saturation (supersaturated colors)
        let view = Text("Test")
            .saturation(2.5)

        let vnode = view.toVNode()

        if case .style(_, let value) = vnode.props["filter"] {
            #expect(value == "saturate(2.5)")
        } else {
            Issue.record("Expected filter style property")
        }
    }

    // MARK: - Modifier Composition Tests

    @Test func blurAndBrightness() {
        // Test combining blur and brightness
        let view = Text("Combined")
            .blur(radius: 5)
            .brightness(1.2)

        // Should create nested views
        #expect(view is _BrightnessView<_BlurView<Text>>)
    }

    @Test func multipleEffects() {
        // Test combining all visual effects
        let view = Text("All Effects")
            .blur(radius: 3)
            .brightness(1.1)
            .contrast(1.2)
            .saturation(1.3)

        // Should compile and create complex nested type
        let _ = view
    }

    @Test func effectCompositionOrder() {
        // Test that effects can be applied in any order
        let view1 = Text("Test")
            .brightness(1.2)
            .blur(radius: 5)

        let view2 = Text("Test")
            .blur(radius: 5)
            .brightness(1.2)

        // Both should compile (different types though)
        let _ = view1
        let _ = view2
    }

    // MARK: - Integration with Other Modifiers

    @Test func visualEffectsWithBasicModifiers() {
        // Test combining visual effects with basic modifiers
        let view = Text("Complex")
            .padding(10)
            .blur(radius: 2)
            .frame(width: 100, height: 50)
            .brightness(1.1)
            .foregroundColor(.blue)

        // Should compile successfully
        let _ = view
    }

    @Test func visualEffectsWithAdvancedModifiers() {
        // Test combining visual effects with advanced modifiers
        let view = Text("Advanced")
            .opacity(0.8)
            .blur(radius: 3)
            .shadow(color: .gray, radius: 5, x: 2, y: 2)
            .saturation(1.2)

        // Should compile successfully
        let _ = view
    }

    // MARK: - Sendable Conformance Tests

    @Test func blurViewIsSendable() {
        // Verify that _BlurView conforms to Sendable
        let view = Text("Test").blur(radius: 5)
        let sendableView: any View & Sendable = view
        let _ = sendableView
    }

    @Test func brightnessViewIsSendable() {
        // Verify that _BrightnessView conforms to Sendable
        let view = Text("Test").brightness(1.2)
        let sendableView: any View & Sendable = view
        let _ = sendableView
    }

    @Test func contrastViewIsSendable() {
        // Verify that _ContrastView conforms to Sendable
        let view = Text("Test").contrast(1.3)
        let sendableView: any View & Sendable = view
        let _ = sendableView
    }

    @Test func saturationViewIsSendable() {
        // Verify that _SaturationView conforms to Sendable
        let view = Text("Test").saturation(0.8)
        let sendableView: any View & Sendable = view
        let _ = sendableView
    }

    // MARK: - Edge Cases

    @Test func negativeBlurRadius() {
        // While not typical, negative values should still work
        // (CSS will treat them as 0)
        let view = Text("Test")
            .blur(radius: -5)

        let vnode = view.toVNode()

        if case .style(_, let value) = vnode.props["filter"] {
            #expect(value == "blur(-5.0px)")
        } else {
            Issue.record("Expected filter style property")
        }
    }

    @Test func negativeBrightness() {
        // Negative brightness values (CSS treats as 0)
        let view = Text("Test")
            .brightness(-0.5)

        let vnode = view.toVNode()

        if case .style(_, let value) = vnode.props["filter"] {
            #expect(value == "brightness(-0.5)")
        } else {
            Issue.record("Expected filter style property")
        }
    }

    @Test func verySmallValues() {
        // Test with very small decimal values
        let view = Text("Test")
            .brightness(0.001)
            .contrast(0.01)
            .saturation(0.1)

        // Should compile and work
        let _ = view
    }

    @Test func veryLargeValues() {
        // Test with very large values
        let view = Text("Test")
            .blur(radius: 1000)
            .brightness(100)
            .contrast(50)
            .saturation(20)

        // Should compile and work
        let _ = view
    }

    // MARK: - Grayscale Tests

    @Test func grayscaleModifierCreation() {
        // Create a view with grayscale
        let view = Text("Gray")
            .grayscale(0.8)

        // Verify the type is correct
        #expect(view is _GrayscaleView<Text>)
    }

    @Test func grayscaleVNodeGeneration() {
        // Create a grayscale view
        let view = Text("Test")
            .grayscale(0.5)

        let vnode = view.toVNode()

        // Verify the VNode is a div element
        #expect(vnode.elementTag == "div")

        // Verify the filter property is set correctly
        if case .style(let name, let value) = vnode.props["filter"] {
            #expect(name == "filter")
            #expect(value == "grayscale(0.5)")
        } else {
            Issue.record("Expected filter style property")
        }
    }

    @Test func grayscaleFullColor() {
        // Test grayscale with 0 (full color)
        let view = Text("Test")
            .grayscale(0)

        let vnode = view.toVNode()

        if case .style(_, let value) = vnode.props["filter"] {
            #expect(value == "grayscale(0.0)")
        } else {
            Issue.record("Expected filter style property")
        }
    }

    @Test func grayscaleFullGrayscale() {
        // Test grayscale with 1.0 (full grayscale)
        let view = Text("Test")
            .grayscale(1.0)

        let vnode = view.toVNode()

        if case .style(_, let value) = vnode.props["filter"] {
            #expect(value == "grayscale(1.0)")
        } else {
            Issue.record("Expected filter style property")
        }
    }

    @Test func grayscalePartialValue() {
        // Test grayscale with partial value
        let view = Text("Test")
            .grayscale(0.75)

        let vnode = view.toVNode()

        if case .style(_, let value) = vnode.props["filter"] {
            #expect(value == "grayscale(0.75)")
        } else {
            Issue.record("Expected filter style property")
        }
    }

    @Test func grayscaleViewIsSendable() {
        // Verify that _GrayscaleView conforms to Sendable
        let view = Text("Test").grayscale(0.5)
        let sendableView: any View & Sendable = view
        let _ = sendableView
    }

    // MARK: - Hue Rotation Tests

    @Test func hueRotationModifierCreation() {
        // Create a view with hue rotation
        let view = Text("Rainbow")
            .hueRotation(Angle(degrees: 180))

        // Verify the type is correct
        #expect(view is _HueRotationView<Text>)
    }

    @Test func hueRotationVNodeGeneration() {
        // Create a hue-rotated view
        let view = Text("Test")
            .hueRotation(Angle(degrees: 90))

        let vnode = view.toVNode()

        // Verify the VNode is a div element
        #expect(vnode.elementTag == "div")

        // Verify the filter property is set correctly
        if case .style(let name, let value) = vnode.props["filter"] {
            #expect(name == "filter")
            #expect(value == "hue-rotate(90.0deg)")
        } else {
            Issue.record("Expected filter style property")
        }
    }

    @Test func hueRotationZeroDegrees() {
        // Test hue rotation with 0 degrees (no effect)
        let view = Text("Test")
            .hueRotation(Angle(degrees: 0))

        let vnode = view.toVNode()

        if case .style(_, let value) = vnode.props["filter"] {
            #expect(value == "hue-rotate(0.0deg)")
        } else {
            Issue.record("Expected filter style property")
        }
    }

    @Test func hueRotation180Degrees() {
        // Test hue rotation with 180 degrees (complementary colors)
        let view = Text("Test")
            .hueRotation(Angle(degrees: 180))

        let vnode = view.toVNode()

        if case .style(_, let value) = vnode.props["filter"] {
            #expect(value == "hue-rotate(180.0deg)")
        } else {
            Issue.record("Expected filter style property")
        }
    }

    @Test func hueRotation360Degrees() {
        // Test hue rotation with 360 degrees (full rotation)
        let view = Text("Test")
            .hueRotation(Angle(degrees: 360))

        let vnode = view.toVNode()

        if case .style(_, let value) = vnode.props["filter"] {
            #expect(value == "hue-rotate(360.0deg)")
        } else {
            Issue.record("Expected filter style property")
        }
    }

    @Test func hueRotationWithRadians() {
        // Test hue rotation using radians
        let view = Text("Test")
            .hueRotation(Angle(radians: .pi))

        let vnode = view.toVNode()

        if case .style(_, let value) = vnode.props["filter"] {
            // pi radians ~ 180 degrees
            #expect(value.contains("hue-rotate("))
            #expect(value.contains("deg)"))
            // Check that the value is approximately 180
            let degrees = value.replacingOccurrences(of: "hue-rotate(", with: "")
                .replacingOccurrences(of: "deg)", with: "")
            if let degreesValue = Double(degrees) {
                #expect(abs(degreesValue - 180.0) < 0.01)
            }
        } else {
            Issue.record("Expected filter style property")
        }
    }

    @Test func hueRotationNegativeDegrees() {
        // Test hue rotation with negative degrees
        let view = Text("Test")
            .hueRotation(Angle(degrees: -45))

        let vnode = view.toVNode()

        if case .style(_, let value) = vnode.props["filter"] {
            #expect(value == "hue-rotate(-45.0deg)")
        } else {
            Issue.record("Expected filter style property")
        }
    }

    @Test func hueRotationViewIsSendable() {
        // Verify that _HueRotationView conforms to Sendable
        let view = Text("Test").hueRotation(Angle(degrees: 45))
        let sendableView: any View & Sendable = view
        let _ = sendableView
    }

    // MARK: - Clip Shape Tests

    @Test func clipShapeModifierCreation() {
        // Create a view with clip shape
        let view = Text("Clipped")
            .clipShape(Circle())

        // Verify the type is correct
        #expect(view is _ClipShapeView<Text, Circle>)
    }

    @Test func clipShapeWithCircle() {
        // Create a clipped view with circle
        let view = Text("Test")
            .clipShape(Circle())

        // Should compile and create the correct type
        let _ = view
    }

    @Test func clipShapeWithRectangle() {
        // Create a clipped view with rectangle
        let view = Text("Test")
            .clipShape(Rectangle())

        // Should compile and create the correct type
        let _ = view
    }

    @Test func clipShapeWithRoundedRectangle() {
        // Create a clipped view with rounded rectangle
        let view = Text("Test")
            .clipShape(RoundedRectangle(cornerRadius: 10))

        // Should compile and create the correct type
        let _ = view
    }

    @Test func clipShapeWithFillStyle() {
        // Create a clipped view with specific fill style
        let view = Text("Test")
            .clipShape(Circle(), style: FillStyle(rule: .evenOdd))

        // Should compile and create the correct type
        let _ = view
    }

    @Test func clipShapeDefaultFillStyle() {
        // Create a clipped view with default fill style
        let view = Text("Test")
            .clipShape(Circle())

        // Should compile successfully
        let _ = view
    }

    @Test func clipShapeViewIsSendable() {
        // Verify that _ClipShapeView conforms to Sendable
        let view = Text("Test").clipShape(Circle())
        let sendableView: any View & Sendable = view
        let _ = sendableView
    }

    // MARK: - Combined Effects Tests

    @Test func grayscaleWithOtherEffects() {
        // Test combining grayscale with other effects
        let view = Text("Combined")
            .grayscale(0.8)
            .brightness(1.1)
            .contrast(1.2)

        // Should compile successfully
        let _ = view
    }

    @Test func hueRotationWithSaturation() {
        // Test combining hue rotation with saturation
        let view = Text("Vibrant")
            .hueRotation(Angle(degrees: 45))
            .saturation(1.5)

        // Should compile successfully
        let _ = view
    }

    @Test func clipShapeWithVisualEffects() {
        // Test combining clip shape with visual effects
        let view = Text("Complex")
            .clipShape(Circle())
            .blur(radius: 2)
            .brightness(1.1)

        // Should compile successfully
        let _ = view
    }

    @Test func allNewEffectsTogether() {
        // Test all new effects combined
        let view = Text("Everything")
            .grayscale(0.5)
            .hueRotation(Angle(degrees: 90))
            .clipShape(RoundedRectangle(cornerRadius: 8))

        // Should compile successfully
        let _ = view
    }

    @Test func newEffectsCompositionOrder() {
        // Test that new effects can be applied in any order
        let view1 = Text("Test")
            .grayscale(0.5)
            .hueRotation(Angle(degrees: 45))

        let view2 = Text("Test")
            .hueRotation(Angle(degrees: 45))
            .grayscale(0.5)

        // Both should compile (different types though)
        let _ = view1
        let _ = view2
    }
}
