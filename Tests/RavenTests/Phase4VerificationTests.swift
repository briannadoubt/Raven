import XCTest
@testable import Raven
import RavenRuntime

/// Comprehensive Phase 4 verification tests that validate the multi-screen app with rich UI works.
///
/// These tests verify that:
/// 1. GeometryReader provides size and coordinate space information
/// 2. Grid layouts (LazyVGrid/LazyHGrid) work with different GridItem configurations
/// 3. Navigation (NavigationView/NavigationLink) creates proper structure
/// 4. Layout helpers (Spacer/Divider) work correctly
/// 5. Form and Section create semantic HTML structures
/// 6. Advanced modifiers (font, background, overlay, shadow, transforms) work
/// 7. Color and Font enhancements (gradients, CSS variables, custom fonts) work
/// 8. Complete multi-screen app integration works end-to-end
@MainActor
final class Phase4VerificationTests: XCTestCase {

    // MARK: - Test 1: GeometryReader Tests

    func testGeometryProxySize() async throws {
        let size = Raven.CGSize(width: 320, height: 480)
        let geometry = GeometryProxy(
            size: size,
            localFrame: Raven.CGRect(x: 0, y: 0, width: 320, height: 480),
            globalFrame: Raven.CGRect(x: 10, y: 20, width: 320, height: 480)
        )

        XCTAssertEqual(geometry.size.width, 320, "GeometryProxy should provide width")
        XCTAssertEqual(geometry.size.height, 480, "GeometryProxy should provide height")
    }

    func testGeometryProxyLocalFrame() async throws {
        let geometry = GeometryProxy(
            size: Raven.CGSize(width: 100, height: 200),
            localFrame: Raven.CGRect(x: 0, y: 0, width: 100, height: 200),
            globalFrame: Raven.CGRect(x: 50, y: 75, width: 100, height: 200)
        )

        let localFrame = geometry.frame(in: .local)
        XCTAssertEqual(localFrame.minX, 0, "Local frame should start at 0,0")
        XCTAssertEqual(localFrame.minY, 0)
        XCTAssertEqual(localFrame.width, 100)
        XCTAssertEqual(localFrame.height, 200)
    }

    func testGeometryProxyGlobalFrame() async throws {
        let geometry = GeometryProxy(
            size: Raven.CGSize(width: 100, height: 200),
            localFrame: Raven.CGRect(x: 0, y: 0, width: 100, height: 200),
            globalFrame: Raven.CGRect(x: 50, y: 75, width: 100, height: 200)
        )

        let globalFrame = geometry.frame(in: .global)
        XCTAssertEqual(globalFrame.minX, 50, "Global frame should have viewport coordinates")
        XCTAssertEqual(globalFrame.minY, 75)
        XCTAssertEqual(globalFrame.width, 100)
        XCTAssertEqual(globalFrame.height, 200)
    }

    func testGeometryReaderVNodeStructure() async throws {
        let reader = GeometryReader { geometry in
            Text("Width: \(geometry.size.width)")
        }

        let body = reader.body
        XCTAssertNotNil(body, "GeometryReader should have a body")
    }

    func testGeometryReaderContainerAttributes() async throws {
        let container = _GeometryReaderContainer { geometry in
            Text("Content")
        }

        let vnode = container.toVNode()

        // Should be a div element
        XCTAssertTrue(vnode.isElement(tag: "div"), "Container should be a div")

        // Should fill available space
        XCTAssertEqual(vnode.props["display"], .style(name: "display", value: "block"))
        XCTAssertEqual(vnode.props["width"], .style(name: "width", value: "100%"))
        XCTAssertEqual(vnode.props["height"], .style(name: "height", value: "100%"))

        // Should have marker attribute
        XCTAssertEqual(
            vnode.props["data-geometry-reader"],
            .attribute(name: "data-geometry-reader", value: "true"),
            "Container should be marked for geometry measurement"
        )
    }

    // MARK: - Test 2: Grid Layout Tests

    func testLazyVGridWithFixedColumns() async throws {
        let grid = LazyVGrid(
            columns: [
                GridItem(.fixed(100)),
                GridItem(.fixed(150)),
                GridItem(.fixed(100))
            ]
        ) {
            Text("Item 1")
            Text("Item 2")
        }

        let vnode = grid.toVNode()

        XCTAssertTrue(vnode.isElement(tag: "div"), "Grid should be a div")
        XCTAssertEqual(vnode.props["display"], .style(name: "display", value: "grid"))
        XCTAssertEqual(vnode.props["grid-auto-flow"], .style(name: "grid-auto-flow", value: "row"))

        // Verify fixed column template
        if case .style(let name, let value) = vnode.props["grid-template-columns"] {
            XCTAssertEqual(name, "grid-template-columns")
            XCTAssertEqual(value, "100.0px 150.0px 100.0px", "Fixed columns should have px values")
        } else {
            XCTFail("Should have grid-template-columns property")
        }
    }

    func testLazyVGridWithFlexibleColumns() async throws {
        let grid = LazyVGrid(
            columns: [
                GridItem(.flexible(minimum: 50, maximum: 200)),
                GridItem(.flexible())
            ],
            spacing: 16
        ) {
            Text("Item")
        }

        let vnode = grid.toVNode()

        // Verify flexible column template with minmax
        if case .style(_, let value) = vnode.props["grid-template-columns"] {
            XCTAssertTrue(value.contains("minmax"), "Flexible columns should use minmax")
            XCTAssertTrue(value.contains("1fr"), "Flexible columns should use fr units")
        } else {
            XCTFail("Should have grid-template-columns property")
        }

        // Verify spacing
        XCTAssertEqual(vnode.props["gap"], .style(name: "gap", value: "16.0px"))
    }

    func testLazyVGridWithAdaptiveColumns() async throws {
        let grid = LazyVGrid(
            columns: [
                GridItem(.adaptive(minimum: 80))
            ]
        ) {
            Text("Item")
        }

        let vnode = grid.toVNode()

        // Verify adaptive column template uses repeat(auto-fit, ...)
        if case .style(_, let value) = vnode.props["grid-template-columns"] {
            XCTAssertTrue(value.contains("repeat(auto-fit"), "Adaptive should use repeat(auto-fit)")
            XCTAssertTrue(value.contains("minmax"), "Adaptive should use minmax")
        } else {
            XCTFail("Should have grid-template-columns property")
        }
    }

    func testLazyHGridWithRows() async throws {
        let grid = LazyHGrid(
            rows: [
                GridItem(.fixed(50)),
                GridItem(.flexible())
            ],
            spacing: 12
        ) {
            Text("Item")
        }

        let vnode = grid.toVNode()

        XCTAssertTrue(vnode.isElement(tag: "div"), "Grid should be a div")
        XCTAssertEqual(vnode.props["display"], .style(name: "display", value: "grid"))
        XCTAssertEqual(vnode.props["grid-auto-flow"], .style(name: "grid-auto-flow", value: "column"))

        // Verify row template
        XCTAssertNotNil(vnode.props["grid-template-rows"], "HGrid should have grid-template-rows")

        // Verify spacing
        XCTAssertEqual(vnode.props["gap"], .style(name: "gap", value: "12.0px"))
    }

    func testGridItemSizeConversions() async throws {
        // Test fixed size
        let fixedItem = GridItem(.fixed(100))
        XCTAssertEqual(fixedItem.toCSSTemplate(), "100.0px")
        XCTAssertFalse(fixedItem.isAdaptive)

        // Test flexible size
        let flexibleItem = GridItem(.flexible(minimum: 50, maximum: 200))
        XCTAssertEqual(flexibleItem.toCSSTemplate(), "minmax(50.0px, 200.0px)")
        XCTAssertFalse(flexibleItem.isAdaptive)

        // Test flexible with infinity max
        let flexibleInfItem = GridItem(.flexible(minimum: 10))
        XCTAssertEqual(flexibleInfItem.toCSSTemplate(), "minmax(10.0px, 1fr)")

        // Test adaptive size
        let adaptiveItem = GridItem(.adaptive(minimum: 80))
        XCTAssertTrue(adaptiveItem.isAdaptive)
        XCTAssertEqual(adaptiveItem.toCSSTemplate(), "minmax(80.0px, 1fr)")
    }

    func testGridAlignment() async throws {
        let grid = LazyVGrid(
            columns: [GridItem(.flexible())],
            alignment: .leading
        ) {
            Text("Item")
        }

        let vnode = grid.toVNode()

        // Verify alignment is applied
        XCTAssertNotNil(vnode.props["place-items"], "Grid should have place-items for alignment")
    }

    // MARK: - Test 3: Navigation Tests

    func testNavigationViewStructure() async throws {
        let navView = NavigationView {
            Text("Home")
        }

        let body = navView.body
        XCTAssertNotNil(body, "NavigationView should have a body")
    }

    func testNavigationViewBodyStructure() async throws {
        // Test that NavigationView creates a body
        let navView = NavigationView {
            VStack {
                Text("Home")
                Text("Welcome")
            }
        }

        let body = navView.body
        XCTAssertNotNil(body, "NavigationView should have a body")

        // The body is a NavigationContainer which we can't test directly since it's private
        // But we can verify the view compiles and has a body
    }

    func testNavigationLinkStructure() async throws {
        let link = NavigationLink("Go to Detail", destination: Text("Detail View"))

        let vnode = link.toVNode()

        // Should be a button element (for Phase 4)
        XCTAssertTrue(vnode.isElement(tag: "button"), "NavigationLink should be a button")

        // Should have link role
        XCTAssertEqual(vnode.props["role"], .attribute(name: "role", value: "link"))

        // Should have click handler
        XCTAssertNotNil(vnode.props["onClick"], "NavigationLink should have click handler")

        // Should have appropriate class
        XCTAssertEqual(
            vnode.props["class"],
            .attribute(name: "class", value: "raven-navigation-link")
        )
    }

    func testNavigationLinkCustomLabel() async throws {
        let link = NavigationLink(destination: Text("Destination")) {
            HStack {
                Text("Custom")
                Text("Label")
            }
        }

        let vnode = link.toVNode()
        XCTAssertTrue(vnode.isElement(tag: "button"))
        XCTAssertEqual(vnode.props["role"], .attribute(name: "role", value: "link"))
    }

    func testNavigationModifiers() async throws {
        // Test navigationTitle modifier compiles
        let view = Text("Content")
            .navigationTitle("My Title")

        XCTAssertNotNil(view, "navigationTitle modifier should work")

        // Test navigationBarTitleDisplayMode modifier compiles
        let view2 = Text("Content")
            .navigationBarTitleDisplayMode(.inline)

        XCTAssertNotNil(view2, "navigationBarTitleDisplayMode modifier should work")

        // Test navigationBarHidden modifier compiles
        let view3 = Text("Content")
            .navigationBarHidden(true)

        XCTAssertNotNil(view3, "navigationBarHidden modifier should work")
    }

    // MARK: - Test 4: Layout Helper Tests

    func testSpacerVNode() async throws {
        let spacer = Spacer()
        let vnode = spacer.toVNode()

        XCTAssertTrue(vnode.isElement(tag: "div"), "Spacer should be a div")
        XCTAssertEqual(vnode.props["flex-grow"], .style(name: "flex-grow", value: "1"))
        XCTAssertEqual(vnode.props["flex-shrink"], .style(name: "flex-shrink", value: "1"))
        XCTAssertEqual(vnode.props["flex-basis"], .style(name: "flex-basis", value: "0"))
    }

    func testSpacerWithMinLength() async throws {
        let spacer = Spacer(minLength: 20)
        let vnode = spacer.toVNode()

        XCTAssertEqual(vnode.props["min-width"], .style(name: "min-width", value: "20.0px"))
    }

    func testDividerVNode() async throws {
        let divider = Divider()
        let vnode = divider.toVNode()

        XCTAssertTrue(vnode.isElement(tag: "div"), "Divider should be a div element")

        // Verify styling
        XCTAssertNotNil(vnode.props["border-top"], "Divider should have top border")
        XCTAssertEqual(vnode.props["height"], .style(name: "height", value: "0"))
        XCTAssertEqual(vnode.props["width"], .style(name: "width", value: "100%"))
        XCTAssertEqual(vnode.props["flex-shrink"], .style(name: "flex-shrink", value: "0"))
    }

    // MARK: - Test 5: Form/Section Tests

    func testFormBasicStructure() async throws {
        let form = Form {
            Text("Form content")
        }

        let vnode = form.toVNode()

        // Should be a form element
        XCTAssertTrue(vnode.isElement(tag: "form"), "Should be a form element")

        // Should have role attribute
        XCTAssertEqual(vnode.props["role"], .attribute(name: "role", value: "form"))

        // Should have submit event handler
        XCTAssertNotNil(vnode.props["onSubmit"], "Form should have submit handler")
    }

    func testFormStyling() async throws {
        let form = Form {
            Text("Content")
        }

        let vnode = form.toVNode()

        // Verify flexbox layout
        XCTAssertEqual(vnode.props["display"], .style(name: "display", value: "flex"))
        XCTAssertEqual(vnode.props["flex-direction"], .style(name: "flex-direction", value: "column"))
        XCTAssertEqual(vnode.props["gap"], .style(name: "gap", value: "16px"))
        XCTAssertEqual(vnode.props["width"], .style(name: "width", value: "100%"))
    }

    func testSectionBasicStructure() async throws {
        let section = Section {
            Text("Section content")
        }

        let vnode = section.toVNode()

        // Should be a fieldset element
        XCTAssertTrue(vnode.isElement(tag: "fieldset"), "Should be a fieldset element")
    }

    func testSectionWithHeader() async throws {
        let section = Section(header: "Settings") {
            Text("Content")
        }

        let vnode = section.toVNode()
        XCTAssertTrue(vnode.isElement(tag: "fieldset"))
        XCTAssertNotNil(section.header, "Section should have a header")
    }

    func testSectionWithCustomHeader() async throws {
        let section = Section(header: { Text("Custom Header") }) {
            Text("Content")
        }

        let vnode = section.toVNode()
        XCTAssertTrue(vnode.isElement(tag: "fieldset"))
        XCTAssertNotNil(section.header, "Section should have custom header")
    }

    func testSectionWithFooter() async throws {
        let section = Section(
            header: "Header",
            footer: { Text("Footer") }
        ) {
            Text("Content")
        }

        let vnode = section.toVNode()
        XCTAssertTrue(vnode.isElement(tag: "fieldset"))
        XCTAssertNotNil(section.header)
        XCTAssertNotNil(section.footer)
    }

    func testSectionStyling() async throws {
        let section = Section {
            Text("Content")
        }

        let vnode = section.toVNode()

        // Verify styling
        XCTAssertEqual(vnode.props["display"], .style(name: "display", value: "flex"))
        XCTAssertEqual(vnode.props["flex-direction"], .style(name: "flex-direction", value: "column"))
        XCTAssertEqual(vnode.props["gap"], .style(name: "gap", value: "12px"))
        XCTAssertNotNil(vnode.props["border"], "Section should have border")
        XCTAssertNotNil(vnode.props["border-radius"], "Section should have border-radius")
    }

    // MARK: - Test 6: Advanced Modifier Tests

    func testFontModifier() async throws {
        let view = _FontView(content: Text("Hello"), font: .headline)
        let vnode = view.toVNode()

        XCTAssertTrue(vnode.isElement(tag: "div"))
        XCTAssertNotNil(vnode.props["font-family"], "Should have font-family")
        XCTAssertNotNil(vnode.props["font-size"], "Should have font-size")
        XCTAssertNotNil(vnode.props["font-weight"], "Should have font-weight")
    }

    func testBackgroundModifier() async throws {
        let view = _BackgroundView(
            content: Text("Content"),
            background: Color.blue,
            alignment: .center
        )
        let vnode = view.toVNode()

        XCTAssertTrue(vnode.isElement(tag: "div"))
        XCTAssertEqual(vnode.props["display"], .style(name: "display", value: "grid"))
        XCTAssertNotNil(vnode.props["place-items"], "Should have place-items for alignment")
    }

    func testBackgroundColorModifier() async throws {
        let view = _BackgroundColorView(content: Text("Content"), color: .red)
        let vnode = view.toVNode()

        XCTAssertTrue(vnode.isElement(tag: "div"))
        XCTAssertNotNil(vnode.props["background-color"], "Should have background-color")
    }

    func testOverlayModifier() async throws {
        let view = _OverlayView(
            content: Text("Content"),
            overlay: Text("Overlay"),
            alignment: .topTrailing
        )
        let vnode = view.toVNode()

        XCTAssertTrue(vnode.isElement(tag: "div"))
        XCTAssertEqual(vnode.props["display"], .style(name: "display", value: "grid"))
    }

    func testShadowModifier() async throws {
        let view = _ShadowView(
            content: Text("Content"),
            color: .gray,
            radius: 5,
            x: 2,
            y: 2
        )
        let vnode = view.toVNode()

        XCTAssertTrue(vnode.isElement(tag: "div"))

        if case .style(let name, let value) = vnode.props["box-shadow"] {
            XCTAssertEqual(name, "box-shadow")
            XCTAssertTrue(value.contains("2.0px"), "Shadow should contain x offset")
            XCTAssertTrue(value.contains("5.0px"), "Shadow should contain blur radius")
        } else {
            XCTFail("Should have box-shadow property")
        }
    }

    func testCornerRadiusModifier() async throws {
        let view = _CornerRadiusView(content: Text("Content"), radius: 10)
        let vnode = view.toVNode()

        XCTAssertTrue(vnode.isElement(tag: "div"))
        XCTAssertEqual(vnode.props["border-radius"], .style(name: "border-radius", value: "10.0px"))
        XCTAssertEqual(vnode.props["overflow"], .style(name: "overflow", value: "hidden"))
    }

    func testOpacityModifier() async throws {
        let view = _OpacityView(content: Text("Content"), opacity: 0.5)
        let vnode = view.toVNode()

        XCTAssertTrue(vnode.isElement(tag: "div"))
        XCTAssertEqual(vnode.props["opacity"], .style(name: "opacity", value: "0.5"))
    }

    func testOffsetModifier() async throws {
        let view = _OffsetView(content: Text("Content"), x: 10, y: 20)
        let vnode = view.toVNode()

        XCTAssertTrue(vnode.isElement(tag: "div"))

        if case .style(let name, let value) = vnode.props["transform"] {
            XCTAssertEqual(name, "transform")
            XCTAssertEqual(value, "translate(10.0px, 20.0px)")
        } else {
            XCTFail("Should have transform property")
        }
    }

    func testRotationEffectModifier() async throws {
        let view = _RotationEffectView(content: Text("Content"), angle: .degrees(45))
        let vnode = view.toVNode()

        XCTAssertTrue(vnode.isElement(tag: "div"))

        if case .style(let name, let value) = vnode.props["transform"] {
            XCTAssertEqual(name, "transform")
            XCTAssertEqual(value, "rotate(45.0deg)")
        } else {
            XCTFail("Should have transform property")
        }
    }

    func testScaleEffectModifier() async throws {
        let view = _ScaleEffectView(content: Text("Content"), scale: 1.5)
        let vnode = view.toVNode()

        XCTAssertTrue(vnode.isElement(tag: "div"))

        if case .style(let name, let value) = vnode.props["transform"] {
            XCTAssertEqual(name, "transform")
            XCTAssertEqual(value, "scale(1.5)")
        } else {
            XCTFail("Should have transform property")
        }
    }

    // MARK: - Test 7: Color/Font Enhancement Tests

    func testLinearGradient() async throws {
        let gradient = LinearGradient(
            colors: [.red, .blue],
            angle: .degrees(90)
        )

        let cssValue = gradient.cssValue
        XCTAssertTrue(cssValue.contains("linear-gradient"), "Should generate linear-gradient")
        XCTAssertTrue(cssValue.contains("90.0deg"), "Should include angle")
    }

    func testRadialGradient() async throws {
        let gradient = RadialGradient(colors: [.white, .blue])

        let cssValue = gradient.cssValue
        XCTAssertTrue(cssValue.contains("radial-gradient"), "Should generate radial-gradient")
        XCTAssertTrue(cssValue.contains("circle"), "Should specify circle shape")
    }

    func testColorCustomCSSVariable() async throws {
        let color = Color.custom("theme-primary")

        // Custom colors should reference CSS variables
        let cssValue = color.cssValue
        XCTAssertTrue(cssValue.contains("var(--theme-primary)"), "Should generate CSS variable reference")
    }

    func testColorOpacity() async throws {
        let color = Color.red.opacity(0.5)

        let cssValue = color.cssValue
        // Opacity should be reflected in the CSS value
        XCTAssertNotEqual(cssValue, Color.red.cssValue, "Opacity should modify CSS value")
    }

    func testFontSystemWithWeight() async throws {
        let font = Font.system(size: 18, weight: .bold)

        let (_, size, weight) = font.cssProperties()

        XCTAssertTrue(size.contains("18"), "Should include size")
        XCTAssertEqual(weight, "700", "Bold should be weight 700")
    }

    func testFontSystemWithDesign() async throws {
        let font = Font.system(size: 16, design: .monospaced)

        let (family, _, _) = font.cssProperties()

        XCTAssertTrue(family.contains("monospace"), "Monospaced design should use monospace fonts")
    }

    func testFontCustom() async throws {
        let font = Font.custom("Helvetica", size: 20)

        let (family, size, _) = font.cssProperties()

        XCTAssertTrue(family.contains("Helvetica"), "Should use custom font family")
        XCTAssertTrue(size.contains("20"), "Should include size")
    }

    func testFontTextStyles() async throws {
        // Test that text style fonts exist and can be used
        let fonts: [Font] = [
            .largeTitle, .title, .title2, .title3,
            .headline, .subheadline, .body,
            .callout, .footnote, .caption, .caption2
        ]

        for font in fonts {
            let (family, size, weight) = font.cssProperties()
            XCTAssertFalse(family.isEmpty, "Font should have family")
            XCTAssertFalse(size.isEmpty, "Font should have size")
            XCTAssertFalse(weight.isEmpty, "Font should have weight")
        }
    }

    func testAngleConversions() async throws {
        let degreesAngle = Angle.degrees(180)
        XCTAssertEqual(degreesAngle.degrees, 180, accuracy: 0.01)
        XCTAssertEqual(degreesAngle.radians, .pi, accuracy: 0.01)

        let radiansAngle = Angle.radians(.pi / 2)
        XCTAssertEqual(radiansAngle.degrees, 90, accuracy: 0.01)
        XCTAssertEqual(radiansAngle.radians, .pi / 2, accuracy: 0.01)
    }

    // MARK: - Test 8: Complete Multi-Screen App Integration

    func testMultiScreenAppModels() async throws {
        // Define models for a multi-screen photo gallery app
        struct Photo: Identifiable, Sendable {
            let id: UUID
            let title: String
            let description: String
            let imageName: String
        }

        struct PhotoCategory: Identifiable, Sendable {
            let id: UUID
            let name: String
            let photos: [Photo]
        }

        let photo = Photo(
            id: UUID(),
            title: "Sunset",
            description: "Beautiful sunset over the ocean",
            imageName: "sunset.jpg"
        )

        XCTAssertNotNil(photo.id)
        XCTAssertEqual(photo.title, "Sunset")

        let category = PhotoCategory(
            id: UUID(),
            name: "Nature",
            photos: [photo]
        )

        XCTAssertEqual(category.photos.count, 1)
        XCTAssertEqual(category.photos[0].title, "Sunset")
    }

    func testMultiScreenAppStore() async throws {
        struct Photo: Identifiable, Sendable {
            let id: UUID
            let title: String
            let imageName: String
        }

        class PhotoGalleryStore: Raven.ObservableObject {
            @Raven.Published var photos: [Photo] = []
            @Raven.Published var selectedPhoto: Photo?

            init() {
                setupPublished()
            }

            func addPhoto(title: String, imageName: String) {
                let photo = Photo(id: UUID(), title: title, imageName: imageName)
                photos.append(photo)
            }

            func selectPhoto(_ photo: Photo) {
                selectedPhoto = photo
            }
        }

        let store = PhotoGalleryStore()
        var changeCount = 0

        store.objectWillChange.subscribe {
            changeCount += 1
        }

        XCTAssertEqual(store.photos.count, 0)
        XCTAssertNil(store.selectedPhoto)

        store.addPhoto(title: "Photo 1", imageName: "photo1.jpg")
        XCTAssertEqual(store.photos.count, 1)
        XCTAssertEqual(changeCount, 1, "Adding photo should trigger change")

        store.selectPhoto(store.photos[0])
        XCTAssertNotNil(store.selectedPhoto)
        XCTAssertEqual(changeCount, 2, "Selecting photo should trigger change")
    }

    func testMultiScreenAppHomeView() async throws {
        struct Photo: Identifiable, Sendable {
            let id: UUID
            let title: String
        }

        class PhotoStore: Raven.ObservableObject {
            @Raven.Published var photos: [Photo] = []

            init() {
                setupPublished()
            }
        }

        struct HomeView: View {
            @Raven.StateObject var store = PhotoStore()

            var body: some View {
                NavigationView {
                    VStack {
                        Text("Photo Gallery")
                            .font(.largeTitle)

                        LazyVGrid(columns: [
                            GridItem(.adaptive(minimum: 150))
                        ], spacing: 16) {
                            ForEach(store.photos) { photo in
                                NavigationLink(photo.title, destination: Text("Detail"))
                            }
                        }
                    }
                    .navigationTitle("Home")
                }
            }

            @MainActor init() {}
        }

        let home = HomeView()
        XCTAssertNotNil(home.body, "Home view should have a body")
    }

    func testMultiScreenAppWithForms() async throws {
        struct Settings: Sendable {
            var notificationsEnabled: Bool
            var theme: String
            var fontSize: Double
        }

        class SettingsStore: Raven.ObservableObject {
            @Raven.Published var settings = Settings(
                notificationsEnabled: true,
                theme: "light",
                fontSize: 16
            )

            init() {
                setupPublished()
            }
        }

        struct SettingsView: View {
            @Raven.StateObject var store = SettingsStore()

            var body: some View {
                NavigationView {
                    Form {
                        Section(header: "Notifications") {
                            Toggle("Enable Notifications", isOn: .constant(store.settings.notificationsEnabled))
                        }

                        Section(header: "Appearance") {
                            Text("Theme: \(store.settings.theme)")
                            Text("Font Size: \(store.settings.fontSize)")
                        }
                    }
                    .navigationTitle("Settings")
                }
            }

            @MainActor init() {}
        }

        let settings = SettingsView()
        XCTAssertNotNil(settings.body, "Settings view should have a body")

        let settingsStore = settings.$store
        XCTAssertTrue(settingsStore.settings.notificationsEnabled)
        XCTAssertEqual(settingsStore.settings.theme, "light")
    }

    func testCompleteMultiScreenIntegration() async throws {
        // Complete multi-screen app with navigation, grids, forms, and advanced styling
        struct Photo: Identifiable, Sendable {
            let id: UUID
            let title: String
            let description: String
        }

        class AppState: Raven.ObservableObject {
            @Raven.Published var photos: [Photo] = []
            @Raven.Published var selectedCategory: String = "All"

            init() {
                setupPublished()
                // Initialize with sample data
                photos = [
                    Photo(id: UUID(), title: "Mountain", description: "A tall mountain"),
                    Photo(id: UUID(), title: "Ocean", description: "Blue ocean waves"),
                    Photo(id: UUID(), title: "Forest", description: "Green forest path")
                ]
            }
        }

        struct PhotoDetailView: View {
            let photo: Photo

            var body: some View {
                VStack(spacing: 20) {
                    Text(photo.title)
                        .font(.title)
                        .foregroundColor(.primary)

                    GeometryReader { geometry in
                        VStack {
                            Text("Width: \(geometry.size.width)")
                            Text("Height: \(geometry.size.height)")
                        }
                    }

                    Text(photo.description)
                        .font(.body)
                        .padding()
                        .background(.gray.opacity(0.1))
                        .cornerRadius(8)

                    Spacer()
                }
                .padding()
                .navigationTitle(photo.title)
            }
        }

        @MainActor
        struct PhotoGridView: View {
            @Raven.ObservedObject var appState: AppState

            var body: some View {
                LazyVGrid(
                    columns: [
                        GridItem(.adaptive(minimum: 150)),
                    ],
                    spacing: 16
                ) {
                    ForEach(appState.photos) { photo in
                        NavigationLink(destination: PhotoDetailView(photo: photo)) {
                            VStack {
                                Text(photo.title)
                                    .font(.headline)
                                Text(photo.description)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(.white)
                            .shadow(color: .gray, radius: 4, x: 0, y: 2)
                            .cornerRadius(12)
                        }
                    }
                }
                .padding()
            }
        }

        struct MainApp: View {
            @Raven.StateObject var appState = AppState()

            var body: some View {
                NavigationView {
                    VStack {
                        Text("Photo Gallery")
                            .font(.largeTitle)
                            .padding()

                        Form {
                            Section(header: "Category") {
                                Text("Selected: \(appState.selectedCategory)")
                            }
                        }

                        PhotoGridView(appState: appState)

                        Spacer()

                        Divider()

                        HStack {
                            Text("Total: \(appState.photos.count)")
                                .font(.caption)
                            Spacer()
                        }
                        .padding()
                    }
                    .navigationTitle("Gallery")
                }
            }

            @MainActor init() {}
        }

        // Create and test the complete app
        let app = MainApp()
        let state = app.$appState

        XCTAssertEqual(state.photos.count, 3, "App should have 3 photos")
        XCTAssertEqual(state.selectedCategory, "All")

        // Verify the body compiles
        let body = app.body
        XCTAssertNotNil(body, "Complete app should have a body")

        // Test navigation flow
        let gridView = PhotoGridView(appState: state)
        XCTAssertNotNil(gridView.body, "Grid view should render")

        let detailView = PhotoDetailView(photo: state.photos[0])
        XCTAssertNotNil(detailView.body, "Detail view should render")
    }

    func testCompleteAppWithAllPhase4Features() async throws {
        // Ultimate integration test using ALL Phase 4 features
        struct Item: Identifiable, Sendable {
            let id: UUID
            let name: String
            var isActive: Bool
        }

        class CompleteStore: Raven.ObservableObject {
            @Raven.Published var items: [Item] = []
            @Raven.Published var searchText: String = ""

            init() {
                setupPublished()
                items = [
                    Item(id: UUID(), name: "Item 1", isActive: true),
                    Item(id: UUID(), name: "Item 2", isActive: false)
                ]
            }
        }

        struct DetailScreen: View {
            let item: Item

            var body: some View {
                GeometryReader { geometry in
                    VStack(spacing: 16) {
                        Text("Detail: \(item.name)")
                            .font(.title)
                            .foregroundColor(.primary)

                        Text("Screen width: \(geometry.size.width)")
                            .font(.caption)

                        Form {
                            Section(header: "Status") {
                                HStack {
                                    Text("Active:")
                                    Spacer()
                                    Text(item.isActive ? "Yes" : "No")
                                        .foregroundColor(item.isActive ? .green : .gray)
                                }
                            }
                        }

                        Spacer()
                    }
                    .padding()
                }
                .navigationTitle(item.name)
                .background(Color.custom("background-primary"))
            }
        }

        struct CompleteApp: View {
            @Raven.StateObject var store = CompleteStore()

            var body: some View {
                NavigationView {
                    VStack {
                        Text("Complete Phase 4 App")
                            .font(.largeTitle)
                            .shadow(color: .gray, radius: 2, x: 1, y: 1)

                        Divider()

                        LazyVGrid(
                            columns: [
                                GridItem(.flexible(minimum: 100)),
                                GridItem(.flexible(minimum: 100))
                            ],
                            spacing: 12
                        ) {
                            ForEach(store.items) { item in
                                NavigationLink(destination: DetailScreen(item: item)) {
                                    VStack {
                                        Text(item.name)
                                            .font(.headline)
                                        Text(item.isActive ? "Active" : "Inactive")
                                            .font(.caption)
                                    }
                                    .padding()
                                    .background(.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                                    .opacity(item.isActive ? 1.0 : 0.5)
                                    .scaleEffect(item.isActive ? 1.0 : 0.95)
                                }
                            }
                        }
                        .padding()

                        Spacer()
                    }
                    .navigationTitle("Home")
                }
            }

            @MainActor init() {}
        }

        // Test the complete app
        let app = CompleteApp()
        let store = app.$store

        XCTAssertEqual(store.items.count, 2)
        XCTAssertEqual(store.searchText, "")

        let body = app.body
        XCTAssertNotNil(body, "Complete app with all features should compile and render")

        // Verify we can create the detail view
        let detailView = DetailScreen(item: store.items[0])
        XCTAssertNotNil(detailView.body, "Detail view should render")
    }
}
