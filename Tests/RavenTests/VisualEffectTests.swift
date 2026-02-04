import XCTest
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
final class VisualEffectTests: XCTestCase {

    // MARK: - Blur Tests

    func testBlurModifierCreation() {
        // Create a view with blur
        let view = Text("Blurred")
            .blur(radius: 10)

        // Verify the type is correct
        XCTAssertTrue(view is _BlurView<Text>)
    }

    func testBlurVNodeGeneration() {
        // Create a blurred view
        let view = Text("Test")
            .blur(radius: 5)

        let vnode = view.toVNode()

        // Verify the VNode is a div element
        XCTAssertEqual(vnode.elementTag, "div")

        // Verify the filter property is set correctly
        if case .style(let name, let value) = vnode.props["filter"] {
            XCTAssertEqual(name, "filter")
            XCTAssertEqual(value, "blur(5.0px)")
        } else {
            XCTFail("Expected filter style property")
        }
    }

    func testBlurWithZeroRadius() {
        // Test blur with zero radius (no effect)
        let view = Text("Test")
            .blur(radius: 0)

        let vnode = view.toVNode()

        if case .style(_, let value) = vnode.props["filter"] {
            XCTAssertEqual(value, "blur(0.0px)")
        } else {
            XCTFail("Expected filter style property")
        }
    }

    func testBlurWithLargeRadius() {
        // Test blur with large radius
        let view = Text("Test")
            .blur(radius: 50)

        let vnode = view.toVNode()

        if case .style(_, let value) = vnode.props["filter"] {
            XCTAssertEqual(value, "blur(50.0px)")
        } else {
            XCTFail("Expected filter style property")
        }
    }

    // MARK: - Brightness Tests

    func testBrightnessModifierCreation() {
        // Create a view with brightness adjustment
        let view = Text("Bright")
            .brightness(1.5)

        // Verify the type is correct
        XCTAssertTrue(view is _BrightnessView<Text>)
    }

    func testBrightnessVNodeGeneration() {
        // Create a brightness-adjusted view
        let view = Text("Test")
            .brightness(0.8)

        let vnode = view.toVNode()

        // Verify the VNode is a div element
        XCTAssertEqual(vnode.elementTag, "div")

        // Verify the filter property is set correctly
        if case .style(let name, let value) = vnode.props["filter"] {
            XCTAssertEqual(name, "filter")
            XCTAssertEqual(value, "brightness(0.8)")
        } else {
            XCTFail("Expected filter style property")
        }
    }

    func testBrightnessNormalValue() {
        // Test brightness with normal value (1.0 = no change)
        let view = Text("Test")
            .brightness(1.0)

        let vnode = view.toVNode()

        if case .style(_, let value) = vnode.props["filter"] {
            XCTAssertEqual(value, "brightness(1.0)")
        } else {
            XCTFail("Expected filter style property")
        }
    }

    func testBrightnessBlack() {
        // Test brightness at 0 (completely black)
        let view = Text("Test")
            .brightness(0)

        let vnode = view.toVNode()

        if case .style(_, let value) = vnode.props["filter"] {
            XCTAssertEqual(value, "brightness(0.0)")
        } else {
            XCTFail("Expected filter style property")
        }
    }

    func testBrightnessAboveNormal() {
        // Test brightness above 1.0 (brighter)
        let view = Text("Test")
            .brightness(2.0)

        let vnode = view.toVNode()

        if case .style(_, let value) = vnode.props["filter"] {
            XCTAssertEqual(value, "brightness(2.0)")
        } else {
            XCTFail("Expected filter style property")
        }
    }

    // MARK: - Contrast Tests

    func testContrastModifierCreation() {
        // Create a view with contrast adjustment
        let view = Text("High Contrast")
            .contrast(1.5)

        // Verify the type is correct
        XCTAssertTrue(view is _ContrastView<Text>)
    }

    func testContrastVNodeGeneration() {
        // Create a contrast-adjusted view
        let view = Text("Test")
            .contrast(1.2)

        let vnode = view.toVNode()

        // Verify the VNode is a div element
        XCTAssertEqual(vnode.elementTag, "div")

        // Verify the filter property is set correctly
        if case .style(let name, let value) = vnode.props["filter"] {
            XCTAssertEqual(name, "filter")
            XCTAssertEqual(value, "contrast(1.2)")
        } else {
            XCTFail("Expected filter style property")
        }
    }

    func testContrastNormalValue() {
        // Test contrast with normal value (1.0 = no change)
        let view = Text("Test")
            .contrast(1.0)

        let vnode = view.toVNode()

        if case .style(_, let value) = vnode.props["filter"] {
            XCTAssertEqual(value, "contrast(1.0)")
        } else {
            XCTFail("Expected filter style property")
        }
    }

    func testContrastGray() {
        // Test contrast at 0 (completely gray)
        let view = Text("Test")
            .contrast(0)

        let vnode = view.toVNode()

        if case .style(_, let value) = vnode.props["filter"] {
            XCTAssertEqual(value, "contrast(0.0)")
        } else {
            XCTFail("Expected filter style property")
        }
    }

    func testContrastHighValue() {
        // Test high contrast
        let view = Text("Test")
            .contrast(3.0)

        let vnode = view.toVNode()

        if case .style(_, let value) = vnode.props["filter"] {
            XCTAssertEqual(value, "contrast(3.0)")
        } else {
            XCTFail("Expected filter style property")
        }
    }

    // MARK: - Saturation Tests

    func testSaturationModifierCreation() {
        // Create a view with saturation adjustment
        let view = Text("Vibrant")
            .saturation(1.5)

        // Verify the type is correct
        XCTAssertTrue(view is _SaturationView<Text>)
    }

    func testSaturationVNodeGeneration() {
        // Create a saturation-adjusted view
        let view = Text("Test")
            .saturation(0.5)

        let vnode = view.toVNode()

        // Verify the VNode is a div element
        XCTAssertEqual(vnode.elementTag, "div")

        // Verify the filter property is set correctly
        if case .style(let name, let value) = vnode.props["filter"] {
            XCTAssertEqual(name, "filter")
            XCTAssertEqual(value, "saturate(0.5)")
        } else {
            XCTFail("Expected filter style property")
        }
    }

    func testSaturationNormalValue() {
        // Test saturation with normal value (1.0 = no change)
        let view = Text("Test")
            .saturation(1.0)

        let vnode = view.toVNode()

        if case .style(_, let value) = vnode.props["filter"] {
            XCTAssertEqual(value, "saturate(1.0)")
        } else {
            XCTFail("Expected filter style property")
        }
    }

    func testSaturationGrayscale() {
        // Test saturation at 0 (grayscale)
        let view = Text("Test")
            .saturation(0)

        let vnode = view.toVNode()

        if case .style(_, let value) = vnode.props["filter"] {
            XCTAssertEqual(value, "saturate(0.0)")
        } else {
            XCTFail("Expected filter style property")
        }
    }

    func testSaturationSupersaturated() {
        // Test high saturation (supersaturated colors)
        let view = Text("Test")
            .saturation(2.5)

        let vnode = view.toVNode()

        if case .style(_, let value) = vnode.props["filter"] {
            XCTAssertEqual(value, "saturate(2.5)")
        } else {
            XCTFail("Expected filter style property")
        }
    }

    // MARK: - Modifier Composition Tests

    func testBlurAndBrightness() {
        // Test combining blur and brightness
        let view = Text("Combined")
            .blur(radius: 5)
            .brightness(1.2)

        // Should create nested views
        XCTAssertTrue(view is _BrightnessView<_BlurView<Text>>)
    }

    func testMultipleEffects() {
        // Test combining all visual effects
        let view = Text("All Effects")
            .blur(radius: 3)
            .brightness(1.1)
            .contrast(1.2)
            .saturation(1.3)

        // Should compile and create complex nested type
        let _ = view
    }

    func testEffectCompositionOrder() {
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

    func testVisualEffectsWithBasicModifiers() {
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

    func testVisualEffectsWithAdvancedModifiers() {
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

    func testBlurViewIsSendable() {
        // Verify that _BlurView conforms to Sendable
        let view = Text("Test").blur(radius: 5)
        let sendableView: any View & Sendable = view
        let _ = sendableView
    }

    func testBrightnessViewIsSendable() {
        // Verify that _BrightnessView conforms to Sendable
        let view = Text("Test").brightness(1.2)
        let sendableView: any View & Sendable = view
        let _ = sendableView
    }

    func testContrastViewIsSendable() {
        // Verify that _ContrastView conforms to Sendable
        let view = Text("Test").contrast(1.3)
        let sendableView: any View & Sendable = view
        let _ = sendableView
    }

    func testSaturationViewIsSendable() {
        // Verify that _SaturationView conforms to Sendable
        let view = Text("Test").saturation(0.8)
        let sendableView: any View & Sendable = view
        let _ = sendableView
    }

    // MARK: - Edge Cases

    func testNegativeBlurRadius() {
        // While not typical, negative values should still work
        // (CSS will treat them as 0)
        let view = Text("Test")
            .blur(radius: -5)

        let vnode = view.toVNode()

        if case .style(_, let value) = vnode.props["filter"] {
            XCTAssertEqual(value, "blur(-5.0px)")
        } else {
            XCTFail("Expected filter style property")
        }
    }

    func testNegativeBrightness() {
        // Negative brightness values (CSS treats as 0)
        let view = Text("Test")
            .brightness(-0.5)

        let vnode = view.toVNode()

        if case .style(_, let value) = vnode.props["filter"] {
            XCTAssertEqual(value, "brightness(-0.5)")
        } else {
            XCTFail("Expected filter style property")
        }
    }

    func testVerySmallValues() {
        // Test with very small decimal values
        let view = Text("Test")
            .brightness(0.001)
            .contrast(0.01)
            .saturation(0.1)

        // Should compile and work
        let _ = view
    }

    func testVeryLargeValues() {
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

    func testGrayscaleModifierCreation() {
        // Create a view with grayscale
        let view = Text("Gray")
            .grayscale(0.8)

        // Verify the type is correct
        XCTAssertTrue(view is _GrayscaleView<Text>)
    }

    func testGrayscaleVNodeGeneration() {
        // Create a grayscale view
        let view = Text("Test")
            .grayscale(0.5)

        let vnode = view.toVNode()

        // Verify the VNode is a div element
        XCTAssertEqual(vnode.elementTag, "div")

        // Verify the filter property is set correctly
        if case .style(let name, let value) = vnode.props["filter"] {
            XCTAssertEqual(name, "filter")
            XCTAssertEqual(value, "grayscale(0.5)")
        } else {
            XCTFail("Expected filter style property")
        }
    }

    func testGrayscaleFullColor() {
        // Test grayscale with 0 (full color)
        let view = Text("Test")
            .grayscale(0)

        let vnode = view.toVNode()

        if case .style(_, let value) = vnode.props["filter"] {
            XCTAssertEqual(value, "grayscale(0.0)")
        } else {
            XCTFail("Expected filter style property")
        }
    }

    func testGrayscaleFullGrayscale() {
        // Test grayscale with 1.0 (full grayscale)
        let view = Text("Test")
            .grayscale(1.0)

        let vnode = view.toVNode()

        if case .style(_, let value) = vnode.props["filter"] {
            XCTAssertEqual(value, "grayscale(1.0)")
        } else {
            XCTFail("Expected filter style property")
        }
    }

    func testGrayscalePartialValue() {
        // Test grayscale with partial value
        let view = Text("Test")
            .grayscale(0.75)

        let vnode = view.toVNode()

        if case .style(_, let value) = vnode.props["filter"] {
            XCTAssertEqual(value, "grayscale(0.75)")
        } else {
            XCTFail("Expected filter style property")
        }
    }

    func testGrayscaleViewIsSendable() {
        // Verify that _GrayscaleView conforms to Sendable
        let view = Text("Test").grayscale(0.5)
        let sendableView: any View & Sendable = view
        let _ = sendableView
    }

    // MARK: - Hue Rotation Tests

    func testHueRotationModifierCreation() {
        // Create a view with hue rotation
        let view = Text("Rainbow")
            .hueRotation(Angle(degrees: 180))

        // Verify the type is correct
        XCTAssertTrue(view is _HueRotationView<Text>)
    }

    func testHueRotationVNodeGeneration() {
        // Create a hue-rotated view
        let view = Text("Test")
            .hueRotation(Angle(degrees: 90))

        let vnode = view.toVNode()

        // Verify the VNode is a div element
        XCTAssertEqual(vnode.elementTag, "div")

        // Verify the filter property is set correctly
        if case .style(let name, let value) = vnode.props["filter"] {
            XCTAssertEqual(name, "filter")
            XCTAssertEqual(value, "hue-rotate(90.0deg)")
        } else {
            XCTFail("Expected filter style property")
        }
    }

    func testHueRotationZeroDegrees() {
        // Test hue rotation with 0 degrees (no effect)
        let view = Text("Test")
            .hueRotation(Angle(degrees: 0))

        let vnode = view.toVNode()

        if case .style(_, let value) = vnode.props["filter"] {
            XCTAssertEqual(value, "hue-rotate(0.0deg)")
        } else {
            XCTFail("Expected filter style property")
        }
    }

    func testHueRotation180Degrees() {
        // Test hue rotation with 180 degrees (complementary colors)
        let view = Text("Test")
            .hueRotation(Angle(degrees: 180))

        let vnode = view.toVNode()

        if case .style(_, let value) = vnode.props["filter"] {
            XCTAssertEqual(value, "hue-rotate(180.0deg)")
        } else {
            XCTFail("Expected filter style property")
        }
    }

    func testHueRotation360Degrees() {
        // Test hue rotation with 360 degrees (full rotation)
        let view = Text("Test")
            .hueRotation(Angle(degrees: 360))

        let vnode = view.toVNode()

        if case .style(_, let value) = vnode.props["filter"] {
            XCTAssertEqual(value, "hue-rotate(360.0deg)")
        } else {
            XCTFail("Expected filter style property")
        }
    }

    func testHueRotationWithRadians() {
        // Test hue rotation using radians
        let view = Text("Test")
            .hueRotation(Angle(radians: .pi))

        let vnode = view.toVNode()

        if case .style(_, let value) = vnode.props["filter"] {
            // π radians ≈ 180 degrees
            XCTAssertTrue(value.contains("hue-rotate("))
            XCTAssertTrue(value.contains("deg)"))
            // Check that the value is approximately 180
            let degrees = value.replacingOccurrences(of: "hue-rotate(", with: "")
                .replacingOccurrences(of: "deg)", with: "")
            if let degreesValue = Double(degrees) {
                XCTAssertEqual(degreesValue, 180.0, accuracy: 0.01)
            }
        } else {
            XCTFail("Expected filter style property")
        }
    }

    func testHueRotationNegativeDegrees() {
        // Test hue rotation with negative degrees
        let view = Text("Test")
            .hueRotation(Angle(degrees: -45))

        let vnode = view.toVNode()

        if case .style(_, let value) = vnode.props["filter"] {
            XCTAssertEqual(value, "hue-rotate(-45.0deg)")
        } else {
            XCTFail("Expected filter style property")
        }
    }

    func testHueRotationViewIsSendable() {
        // Verify that _HueRotationView conforms to Sendable
        let view = Text("Test").hueRotation(Angle(degrees: 45))
        let sendableView: any View & Sendable = view
        let _ = sendableView
    }

    // MARK: - Clip Shape Tests

    func testClipShapeModifierCreation() {
        // Create a view with clip shape
        let view = Text("Clipped")
            .clipShape(Circle())

        // Verify the type is correct
        XCTAssertTrue(view is _ClipShapeView<Text, Circle>)
    }

    func testClipShapeWithCircle() {
        // Create a clipped view with circle
        let view = Text("Test")
            .clipShape(Circle())

        // Should compile and create the correct type
        let _ = view
    }

    func testClipShapeWithRectangle() {
        // Create a clipped view with rectangle
        let view = Text("Test")
            .clipShape(Rectangle())

        // Should compile and create the correct type
        let _ = view
    }

    func testClipShapeWithRoundedRectangle() {
        // Create a clipped view with rounded rectangle
        let view = Text("Test")
            .clipShape(RoundedRectangle(cornerRadius: 10))

        // Should compile and create the correct type
        let _ = view
    }

    func testClipShapeWithFillStyle() {
        // Create a clipped view with specific fill style
        let view = Text("Test")
            .clipShape(Circle(), style: FillStyle(rule: .evenOdd))

        // Should compile and create the correct type
        let _ = view
    }

    func testClipShapeDefaultFillStyle() {
        // Create a clipped view with default fill style
        let view = Text("Test")
            .clipShape(Circle())

        // Should compile successfully
        let _ = view
    }

    func testClipShapeViewIsSendable() {
        // Verify that _ClipShapeView conforms to Sendable
        let view = Text("Test").clipShape(Circle())
        let sendableView: any View & Sendable = view
        let _ = sendableView
    }

    // MARK: - Combined Effects Tests

    func testGrayscaleWithOtherEffects() {
        // Test combining grayscale with other effects
        let view = Text("Combined")
            .grayscale(0.8)
            .brightness(1.1)
            .contrast(1.2)

        // Should compile successfully
        let _ = view
    }

    func testHueRotationWithSaturation() {
        // Test combining hue rotation with saturation
        let view = Text("Vibrant")
            .hueRotation(Angle(degrees: 45))
            .saturation(1.5)

        // Should compile successfully
        let _ = view
    }

    func testClipShapeWithVisualEffects() {
        // Test combining clip shape with visual effects
        let view = Text("Complex")
            .clipShape(Circle())
            .blur(radius: 2)
            .brightness(1.1)

        // Should compile successfully
        let _ = view
    }

    func testAllNewEffectsTogether() {
        // Test all new effects combined
        let view = Text("Everything")
            .grayscale(0.5)
            .hueRotation(Angle(degrees: 90))
            .clipShape(RoundedRectangle(cornerRadius: 8))

        // Should compile successfully
        let _ = view
    }

    func testNewEffectsCompositionOrder() {
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
