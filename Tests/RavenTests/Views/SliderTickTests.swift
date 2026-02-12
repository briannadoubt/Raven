import Testing
@testable import SwiftUI
@testable import RavenCore

@MainActor
@Suite("Slider Tick Tests")
struct SliderTickTests {
    @Test("SliderTick renders option with value and label")
    func sliderTickVNode() {
        let tick = SliderTick(25, label: "Quarter")
        let node = tick.toVNode()

        #expect(node.elementTag == "option")
        if case .attribute(name: "value", value: let value) = node.props["value"] {
            #expect(value == "25.0")
        } else {
            Issue.record("SliderTick should render a value attribute")
        }
        if case .attribute(name: "label", value: let label) = node.props["label"] {
            #expect(label == "Quarter")
        } else {
            Issue.record("SliderTick should render a label attribute")
        }
        #expect(node.textContent == "Quarter")
    }

    @Test("Slider with ticks renders datalist")
    func sliderWithTicksRendersDatalist() {
        var rawValue = 50.0
        let binding = Binding<Double>(
            get: { rawValue },
            set: { rawValue = $0 }
        )

        let slider = Slider(value: binding, in: 0...100, step: 5) {
            SliderTick(0, label: "Start")
            SliderTick(50, label: "Mid")
            SliderTick(100, label: "End")
        }

        let node = slider.toVNode()
        #expect(node.type == .fragment)
        #expect(node.children.count == 2)

        let inputNode = node.children[0]
        #expect(inputNode.elementTag == "input")
        #expect(inputNode.props["list"] != nil)

        let datalistNode = node.children[1]
        #expect(datalistNode.elementTag == "datalist")
        #expect(datalistNode.children.count == 3)
    }

    @Test("SliderTickBuilder supports conditional and ForEach content")
    func sliderTickBuilderConditionalAndForEach() {
        var rawValue = 10.0
        let binding = Binding<Double>(
            get: { rawValue },
            set: { rawValue = $0 }
        )
        let values = [20.0, 30.0]
        let includeEdgeTicks = true

        let slider = Slider(value: binding, in: 0...30) {
            if includeEdgeTicks {
                SliderTick(0, label: "Min")
            }
            ForEach(values, id: \.self) { value in
                SliderTick(value)
            }
        }

        let node = slider.toVNode()
        #expect(node.type == .fragment)
        let datalistNode = node.children[1]
        #expect(datalistNode.children.count == 3)
    }

    @Test("Slider without ticks still renders as input")
    func sliderWithoutTicksRendersInput() {
        var rawValue = 0.5
        let binding = Binding<Double>(
            get: { rawValue },
            set: { rawValue = $0 }
        )

        let slider = Slider(value: binding)
        let node = slider.toVNode()

        #expect(node.elementTag == "input")
        #expect(node.props["list"] == nil)
    }
}
