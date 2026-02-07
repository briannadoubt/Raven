import Testing
import Foundation
@testable import Raven

/// Tests for ViewThatFits container functionality.
///
/// These tests verify that ViewThatFits correctly generates VNodes with appropriate
/// CSS container query setup for responsive view selection.
@MainActor
@Suite("ViewThatFits Tests")
struct ViewThatFitsTests {

    // MARK: - Basic Initialization Tests

    @Test("ViewThatFits initializes with default vertical axis")
    @MainActor
    func defaultAxisInitialization() {
        let view = ViewThatFits {
            Text("Option 1")
            Text("Option 2")
        }

        let vnode = view.toVNode()

        // Should create a container div
        #expect(vnode.elementTag == "div")

        // Should have container-type set to size
        let containerType = vnode.props["container-type"]
        #expect(containerType != nil)
        if case .style(_, let value) = containerType {
            #expect(value == "size")
        }

        // Should have data attribute marking it as ViewThatFits
        let dataAttr = vnode.props["data-view-that-fits"]
        #expect(dataAttr != nil)
        if case .attribute(_, let value) = dataAttr {
            #expect(value == "true")
        }
    }

    @Test("ViewThatFits with single view option")
    @MainActor
    func singleViewOption() {
        let view = ViewThatFits {
            Text("Only Option")
        }

        let vnode = view.toVNode()

        #expect(vnode.elementTag == "div")
        #expect(vnode.props["container-type"] != nil)
    }

    @Test("ViewThatFits with two view options")
    @MainActor
    func twoViewOptions() {
        let view = ViewThatFits {
            HStack {
                Text("Wide Layout")
            }
            VStack {
                Text("Narrow Layout")
            }
        }

        let vnode = view.toVNode()

        #expect(vnode.elementTag == "div")
        #expect(vnode.props["data-view-that-fits"] != nil)
    }

    @Test("ViewThatFits with multiple view options")
    @MainActor
    func multipleViewOptions() {
        let view = ViewThatFits {
            Text("Option 1")
            Text("Option 2")
            Text("Option 3")
            Text("Option 4")
        }

        let vnode = view.toVNode()

        #expect(vnode.elementTag == "div")
        #expect(vnode.props["container-type"] != nil)
    }

    // MARK: - Axis Tests

    @Test("ViewThatFits with horizontal axis")
    @MainActor
    func horizontalAxis() {
        let view = ViewThatFits(in: .horizontal) {
            Text("Option 1")
            Text("Option 2")
        }

        let vnode = view.toVNode()

        #expect(vnode.elementTag == "div")

        // Should have horizontal axis marker
        let axesAttr = vnode.props["data-fit-axes"]
        #expect(axesAttr != nil)
        if case .attribute(_, let value) = axesAttr {
            #expect(value == "horizontal")
        }

        // Should have width set to fill
        let width = vnode.props["width"]
        #expect(width != nil)
        if case .style(_, let value) = width {
            #expect(value == "100%")
        }
    }

    @Test("ViewThatFits with vertical axis")
    @MainActor
    func verticalAxis() {
        let view = ViewThatFits(in: .vertical) {
            Text("Option 1")
            Text("Option 2")
        }

        let vnode = view.toVNode()

        let axesAttr = vnode.props["data-fit-axes"]
        #expect(axesAttr != nil)
        if case .attribute(_, let value) = axesAttr {
            #expect(value == "vertical")
        }

        // Should have height set to fill
        let height = vnode.props["height"]
        #expect(height != nil)
        if case .style(_, let value) = height {
            #expect(value == "100%")
        }
    }

    @Test("ViewThatFits with both axes")
    @MainActor
    func bothAxes() {
        let view = ViewThatFits(in: [.horizontal, .vertical]) {
            Text("Option 1")
            Text("Option 2")
        }

        let vnode = view.toVNode()

        let axesAttr = vnode.props["data-fit-axes"]
        #expect(axesAttr != nil)
        if case .attribute(_, let value) = axesAttr {
            #expect(value == "both")
        }

        // Should have both width and height set to fill
        #expect(vnode.props["width"] != nil)
        #expect(vnode.props["height"] != nil)
    }

    @Test("ViewThatFits with all axes shorthand")
    @MainActor
    func allAxesShorthand() {
        let view = ViewThatFits(in: .all) {
            Text("Option 1")
            Text("Option 2")
        }

        let vnode = view.toVNode()

        let axesAttr = vnode.props["data-fit-axes"]
        if case .attribute(_, let value) = axesAttr {
            #expect(value == "both")
        }
    }

    // MARK: - Container Query Setup Tests

    @Test("ViewThatFits sets container-type to size")
    @MainActor
    func containerTypeSize() {
        let view = ViewThatFits {
            Text("Content")
        }

        let vnode = view.toVNode()

        let containerType = vnode.props["container-type"]
        #expect(containerType != nil)
        if case .style(name: let name, value: let value) = containerType {
            #expect(name == "container-type")
            #expect(value == "size")
        }
    }

    @Test("ViewThatFits sets position to relative")
    @MainActor
    func positionRelative() {
        let view = ViewThatFits {
            Text("Content")
        }

        let vnode = view.toVNode()

        let position = vnode.props["position"]
        #expect(position != nil)
        if case .style(_, let value) = position {
            #expect(value == "relative")
        }
    }

    @Test("ViewThatFits sets display to block")
    @MainActor
    func displayBlock() {
        let view = ViewThatFits {
            Text("Content")
        }

        let vnode = view.toVNode()

        let display = vnode.props["display"]
        #expect(display != nil)
        if case .style(_, let value) = display {
            #expect(value == "block")
        }
    }

    // MARK: - Responsive Layout Tests

    @Test("ViewThatFits with responsive navigation layout")
    @MainActor
    func responsiveNavigationLayout() {
        let view = ViewThatFits(in: .horizontal) {
            HStack {
                Text("Home")
                Text("Products")
                Text("About")
                Text("Contact")
            }
            HStack {
                Text("Home")
                Text("More")
            }
        }

        let vnode = view.toVNode()

        #expect(vnode.elementTag == "div")
        #expect(vnode.props["data-fit-axes"] != nil)
    }

    @Test("ViewThatFits with form layout adaptation")
    @MainActor
    func formLayoutAdaptation() {
        let view = ViewThatFits {
            HStack {
                VStack {
                    Text("First Name")
                    Text("Email")
                }
                VStack {
                    Text("Last Name")
                    Text("Phone")
                }
            }
            VStack {
                Text("First Name")
                Text("Last Name")
                Text("Email")
                Text("Phone")
            }
        }

        let vnode = view.toVNode()

        #expect(vnode.elementTag == "div")
        #expect(vnode.props["container-type"] != nil)
    }

    @Test("ViewThatFits with header layout")
    @MainActor
    func headerLayout() {
        let view = ViewThatFits(in: .horizontal) {
            HStack {
                Text("Logo")
                Text("App Name")
                Text("Sign In")
                Text("Sign Up")
            }
            VStack {
                HStack {
                    Text("Logo")
                    Text("App")
                }
                HStack {
                    Text("Sign In")
                    Text("Sign Up")
                }
            }
        }

        let vnode = view.toVNode()

        #expect(vnode.elementTag == "div")
    }

    // MARK: - Nested Layout Tests

    @Test("ViewThatFits inside VStack")
    @MainActor
    func viewThatFitsInsideVStack() {
        let view = VStack {
            Text("Header")
            ViewThatFits {
                HStack {
                    Text("Wide")
                }
                VStack {
                    Text("Narrow")
                }
            }
            Text("Footer")
        }

        let vnode = view.toVNode()

        #expect(vnode.elementTag == "div")
    }

    @Test("ViewThatFits inside HStack")
    @MainActor
    func viewThatFitsInsideHStack() {
        let view = HStack {
            Text("Left")
            ViewThatFits {
                Text("Option 1")
                Text("Option 2")
            }
            Text("Right")
        }

        let vnode = view.toVNode()

        #expect(vnode.elementTag == "div")
    }

    @Test("Nested ViewThatFits containers")
    @MainActor
    func nestedViewThatFits() {
        let view = ViewThatFits {
            HStack {
                ViewThatFits(in: .vertical) {
                    Text("Inner Wide")
                    Text("Inner Narrow")
                }
            }
            VStack {
                Text("Outer Narrow")
            }
        }

        let vnode = view.toVNode()

        #expect(vnode.elementTag == "div")
        #expect(vnode.props["container-type"] != nil)
    }

    // MARK: - Complex Content Tests

    @Test("ViewThatFits with complex view hierarchies")
    @MainActor
    func complexViewHierarchies() {
        let view = ViewThatFits {
            VStack {
                HStack {
                    Text("A")
                    Text("B")
                }
                HStack {
                    Text("C")
                    Text("D")
                }
            }
            Text("Simple Fallback")
        }

        let vnode = view.toVNode()

        #expect(vnode.elementTag == "div")
        #expect(vnode.props["data-view-that-fits"] != nil)
    }

    // MARK: - Edge Cases

    @Test("ViewThatFits with empty content builds successfully")
    @MainActor
    func emptyContentBuilds() {
        // This should compile and create a container even with no content
        let view = ViewThatFits {
            EmptyView()
        }

        let vnode = view.toVNode()

        #expect(vnode.elementTag == "div")
    }

    // MARK: - Internal Option Wrapper Tests

    @Test("ViewThatFits option wrapper creates correct structure")
    @MainActor
    func optionWrapperStructure() {
        let option = _ViewThatFitsOption(index: 0, isLast: false, content: Text("Test"))

        let vnode = option.toVNode()

        #expect(vnode.elementTag == "div")

        // Should have option index
        let indexAttr = vnode.props["data-fit-option"]
        #expect(indexAttr != nil)
        if case .attribute(_, let value) = indexAttr {
            #expect(value == "0")
        }

        // Should have is-last marker
        let lastAttr = vnode.props["data-fit-last"]
        #expect(lastAttr != nil)
        if case .attribute(_, let value) = lastAttr {
            #expect(value == "false")
        }
    }

    @Test("ViewThatFits option wrapper marks last option")
    @MainActor
    func optionWrapperLastMarker() {
        let option = _ViewThatFitsOption(index: 2, isLast: true, content: Text("Last"))

        let vnode = option.toVNode()

        let lastAttr = vnode.props["data-fit-last"]
        if case .attribute(_, let value) = lastAttr {
            #expect(value == "true")
        }
    }

    @Test("ViewThatFits option wrapper with different indices")
    @MainActor
    func optionWrapperIndices() {
        let option1 = _ViewThatFitsOption(index: 0, isLast: false, content: Text("First"))
        let option2 = _ViewThatFitsOption(index: 1, isLast: false, content: Text("Second"))
        let option3 = _ViewThatFitsOption(index: 2, isLast: true, content: Text("Third"))

        let vnode1 = option1.toVNode()
        let vnode2 = option2.toVNode()
        let vnode3 = option3.toVNode()

        // Check first option
        if case .attribute(_, let value) = vnode1.props["data-fit-option"] {
            #expect(value == "0")
        }

        // Check second option
        if case .attribute(_, let value) = vnode2.props["data-fit-option"] {
            #expect(value == "1")
        }

        // Check third option
        if case .attribute(_, let value) = vnode3.props["data-fit-option"] {
            #expect(value == "2")
        }

        // Only last should be marked as last
        if case .attribute(_, let value) = vnode3.props["data-fit-last"] {
            #expect(value == "true")
        }
    }
}
