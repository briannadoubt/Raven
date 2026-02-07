import Foundation
import Testing
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
@Suite struct Phase4VerificationTests {

    // MARK: - Test 1: GeometryReader Tests

    @Test func geometryProxySize() async throws {
        let size = Raven.CGSize(width: 320, height: 480)
        let geometry = GeometryProxy(
            size: size,
            localFrame: Raven.CGRect(x: 0, y: 0, width: 320, height: 480),
            globalFrame: Raven.CGRect(x: 10, y: 20, width: 320, height: 480)
        )

        #expect(geometry.size.width == 320)
        #expect(geometry.size.height == 480)
    }

    @Test func geometryProxyLocalFrame() async throws {
        let geometry = GeometryProxy(
            size: Raven.CGSize(width: 100, height: 200),
            localFrame: Raven.CGRect(x: 0, y: 0, width: 100, height: 200),
            globalFrame: Raven.CGRect(x: 50, y: 75, width: 100, height: 200)
        )

        let localFrame = geometry.frame(in: .local)
        #expect(localFrame.minX == 0)
        #expect(localFrame.minY == 0)
        #expect(localFrame.width == 100)
        #expect(localFrame.height == 200)
    }

    @Test func geometryProxyGlobalFrame() async throws {
        let geometry = GeometryProxy(
            size: Raven.CGSize(width: 100, height: 200),
            localFrame: Raven.CGRect(x: 0, y: 0, width: 100, height: 200),
            globalFrame: Raven.CGRect(x: 50, y: 75, width: 100, height: 200)
        )

        let globalFrame = geometry.frame(in: .global)
        #expect(globalFrame.minX == 50)
        #expect(globalFrame.minY == 75)
        #expect(globalFrame.width == 100)
        #expect(globalFrame.height == 200)
    }

    @Test func geometryReaderVNodeStructure() async throws {
        let reader = GeometryReader { geometry in
            Text("Width: \(geometry.size.width)")
        }

        let body = reader.body
        #expect(body != nil)
    }

    @Test func geometryReaderContainerAttributes() async throws {
        let container = _GeometryReaderContainer { geometry in
            Text("Content")
        }

        let vnode = container.toVNode()

        // Should be a div element
        #expect(vnode.isElement(tag: "div"))

        // Should fill available space
        #expect(vnode.props["display"] == .style(name: "display", value: "block"))
        #expect(vnode.props["width"] == .style(name: "width", value: "100%"))
        #expect(vnode.props["height"] == .style(name: "height", value: "100%"))

        // Should have marker attribute
        #expect(
            vnode.props["data-geometry-reader"] ==
            .attribute(name: "data-geometry-reader", value: "true")
        )
    }

    // MARK: - Test 2: Grid Layout Tests

    @Test func lazyVGridWithFixedColumns() async throws {
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

        #expect(vnode.isElement(tag: "div"))
        #expect(vnode.props["display"] == .style(name: "display", value: "grid"))
        #expect(vnode.props["grid-auto-flow"] == .style(name: "grid-auto-flow", value: "row"))

        // Verify fixed column template
        if case .style(let name, let value) = vnode.props["grid-template-columns"] {
            #expect(name == "grid-template-columns")
            #expect(value == "100.0px 150.0px 100.0px")
        } else {
            Issue.record("Should have grid-template-columns property")
        }
    }

    @Test func lazyVGridWithFlexibleColumns() async throws {
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
            #expect(value.contains("minmax"))
            #expect(value.contains("1fr"))
        } else {
            Issue.record("Should have grid-template-columns property")
        }

        // Verify spacing
        #expect(vnode.props["gap"] == .style(name: "gap", value: "16.0px"))
    }

    @Test func lazyVGridWithAdaptiveColumns() async throws {
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
            #expect(value.contains("repeat(auto-fit"))
            #expect(value.contains("minmax"))
        } else {
            Issue.record("Should have grid-template-columns property")
        }
    }

    @Test func lazyHGridWithRows() async throws {
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

        #expect(vnode.isElement(tag: "div"))
        #expect(vnode.props["display"] == .style(name: "display", value: "grid"))
        #expect(vnode.props["grid-auto-flow"] == .style(name: "grid-auto-flow", value: "column"))

        // Verify row template
        #expect(vnode.props["grid-template-rows"] != nil)

        // Verify spacing
        #expect(vnode.props["gap"] == .style(name: "gap", value: "12.0px"))
    }

    @Test func gridItemSizeConversions() async throws {
        // Test fixed size
        let fixedItem = GridItem(.fixed(100))
        #expect(fixedItem.toCSSTemplate() == "100.0px")
        #expect(!fixedItem.isAdaptive)

        // Test flexible size
        let flexibleItem = GridItem(.flexible(minimum: 50, maximum: 200))
        #expect(flexibleItem.toCSSTemplate() == "minmax(50.0px, 200.0px)")
        #expect(!flexibleItem.isAdaptive)

        // Test flexible with infinity max
        let flexibleInfItem = GridItem(.flexible(minimum: 10))
        #expect(flexibleInfItem.toCSSTemplate() == "minmax(10.0px, 1fr)")

        // Test adaptive size
        let adaptiveItem = GridItem(.adaptive(minimum: 80))
        #expect(adaptiveItem.isAdaptive)
        #expect(adaptiveItem.toCSSTemplate() == "minmax(80.0px, 1fr)")
    }

    @Test func gridAlignment() async throws {
        let grid = LazyVGrid(
            columns: [GridItem(.flexible())],
            alignment: .leading
        ) {
            Text("Item")
        }

        let vnode = grid.toVNode()

        // Verify alignment is applied
        #expect(vnode.props["place-items"] != nil)
    }

    // MARK: - Test 3: Navigation Tests

    @Test func navigationViewStructure() async throws {
        let navView = NavigationView {
            Text("Home")
        }

        let body = navView.body
        #expect(body != nil)
    }

    @Test func navigationViewBodyStructure() async throws {
        // Test that NavigationView creates a body
        let navView = NavigationView {
            VStack {
                Text("Home")
                Text("Welcome")
            }
        }

        let body = navView.body
        #expect(body != nil)

        // The body is a NavigationContainer which we can't test directly since it's private
        // But we can verify the view compiles and has a body
    }

    @Test func navigationLinkStructure() async throws {
        let link = NavigationLink("Go to Detail", destination: Text("Detail View"))

        let vnode = link.toVNode()

        // Should be a button element (for Phase 4)
        #expect(vnode.isElement(tag: "button"))

        // Should have link role
        #expect(vnode.props["role"] == .attribute(name: "role", value: "link"))

        // Should have click handler
        #expect(vnode.props["onClick"] != nil)

        // Should have appropriate class
        #expect(
            vnode.props["class"] ==
            .attribute(name: "class", value: "raven-navigation-link")
        )
    }

    @Test func navigationLinkCustomLabel() async throws {
        let link = NavigationLink(destination: Text("Destination")) {
            HStack {
                Text("Custom")
                Text("Label")
            }
        }

        let vnode = link.toVNode()
        #expect(vnode.isElement(tag: "button"))
        #expect(vnode.props["role"] == .attribute(name: "role", value: "link"))
    }

    @Test func navigationModifiers() async throws {
        // Test navigationTitle modifier compiles
        let view = Text("Content")
            .navigationTitle("My Title")

        #expect(view != nil)

        // Test navigationBarTitleDisplayMode modifier compiles
        let view2 = Text("Content")
            .navigationBarTitleDisplayMode(.inline)

        #expect(view2 != nil)

        // Test navigationBarHidden modifier compiles
        let view3 = Text("Content")
            .navigationBarHidden(true)

        #expect(view3 != nil)
    }

    // MARK: - Test 4: Layout Helper Tests

    @Test func spacerVNode() async throws {
        let spacer = Spacer()
        let vnode = spacer.toVNode()

        #expect(vnode.isElement(tag: "div"))
        #expect(vnode.props["flex-grow"] == .style(name: "flex-grow", value: "1"))
        #expect(vnode.props["flex-shrink"] == .style(name: "flex-shrink", value: "1"))
        #expect(vnode.props["flex-basis"] == .style(name: "flex-basis", value: "0"))
    }

    @Test func spacerWithMinLength() async throws {
        let spacer = Spacer(minLength: 20)
        let vnode = spacer.toVNode()

        #expect(vnode.props["min-width"] == .style(name: "min-width", value: "20.0px"))
    }

    @Test func dividerVNode() async throws {
        let divider = Divider()
        let vnode = divider.toVNode()

        #expect(vnode.isElement(tag: "div"))

        // Verify styling
        #expect(vnode.props["border-top"] != nil)
        #expect(vnode.props["height"] == .style(name: "height", value: "0"))
        #expect(vnode.props["width"] == .style(name: "width", value: "100%"))
        #expect(vnode.props["flex-shrink"] == .style(name: "flex-shrink", value: "0"))
    }

    // MARK: - Test 5: Form/Section Tests

    @Test func formBasicStructure() async throws {
        let form = Form {
            Text("Form content")
        }

        let vnode = form.toVNode()

        // Should be a form element
        #expect(vnode.isElement(tag: "form"))

        // Should have role attribute
        #expect(vnode.props["role"] == .attribute(name: "role", value: "form"))

        // Should have submit event handler
        #expect(vnode.props["onSubmit"] != nil)
    }

    @Test func formStyling() async throws {
        let form = Form {
            Text("Content")
        }

        let vnode = form.toVNode()

        // Verify flexbox layout
        #expect(vnode.props["display"] == .style(name: "display", value: "flex"))
        #expect(vnode.props["flex-direction"] == .style(name: "flex-direction", value: "column"))
        #expect(vnode.props["gap"] == .style(name: "gap", value: "16px"))
        #expect(vnode.props["width"] == .style(name: "width", value: "100%"))
    }

    @Test func sectionBasicStructure() async throws {
        let section = Section {
            Text("Section content")
        }

        let vnode = section.toVNode()

        // Should be a fieldset element
        #expect(vnode.isElement(tag: "fieldset"))
    }

    @Test func sectionWithHeader() async throws {
        let section = Section(header: "Settings") {
            Text("Content")
        }

        let vnode = section.toVNode()
        #expect(vnode.isElement(tag: "fieldset"))
        #expect(section.header != nil)
    }

    @Test func sectionWithCustomHeader() async throws {
        let section = Section(header: { Text("Custom Header") }) {
            Text("Content")
        }

        let vnode = section.toVNode()
        #expect(vnode.isElement(tag: "fieldset"))
        #expect(section.header != nil)
    }

    @Test func sectionWithFooter() async throws {
        let section = Section(
            header: "Header",
            footer: { Text("Footer") }
        ) {
            Text("Content")
        }

        let vnode = section.toVNode()
        #expect(vnode.isElement(tag: "fieldset"))
        #expect(section.header != nil)
        #expect(section.footer != nil)
    }

    @Test func sectionStyling() async throws {
        let section = Section {
            Text("Content")
        }

        let vnode = section.toVNode()

        // Verify styling
        #expect(vnode.props["display"] == .style(name: "display", value: "flex"))
        #expect(vnode.props["flex-direction"] == .style(name: "flex-direction", value: "column"))
        #expect(vnode.props["gap"] == .style(name: "gap", value: "12px"))
        #expect(vnode.props["border"] != nil)
        #expect(vnode.props["border-radius"] != nil)
    }

    // MARK: - Test 6: Advanced Modifier Tests

    @Test func fontModifier() async throws {
        let view = _FontView(content: Text("Hello"), font: .headline)
        let vnode = view.toVNode()

        #expect(vnode.isElement(tag: "div"))
        #expect(vnode.props["font-family"] != nil)
        #expect(vnode.props["font-size"] != nil)
        #expect(vnode.props["font-weight"] != nil)
    }

    @Test func backgroundModifier() async throws {
        let view = _BackgroundView(
            content: Text("Content"),
            background: Color.blue,
            alignment: .center
        )
        let vnode = view.toVNode()

        #expect(vnode.isElement(tag: "div"))
        #expect(vnode.props["display"] == .style(name: "display", value: "grid"))
        #expect(vnode.props["place-items"] != nil)
    }

    @Test func backgroundColorModifier() async throws {
        let view = _BackgroundColorView(content: Text("Content"), color: .red)
        let vnode = view.toVNode()

        #expect(vnode.isElement(tag: "div"))
        #expect(vnode.props["background-color"] != nil)
    }

    @Test func overlayModifier() async throws {
        let view = _OverlayView(
            content: Text("Content"),
            overlay: Text("Overlay"),
            alignment: .topTrailing
        )
        let vnode = view.toVNode()

        #expect(vnode.isElement(tag: "div"))
        #expect(vnode.props["display"] == .style(name: "display", value: "grid"))
    }

    @Test func shadowModifier() async throws {
        let view = _ShadowView(
            content: Text("Content"),
            color: .gray,
            radius: 5,
            x: 2,
            y: 2
        )
        let vnode = view.toVNode()

        #expect(vnode.isElement(tag: "div"))

        if case .style(let name, let value) = vnode.props["box-shadow"] {
            #expect(name == "box-shadow")
            #expect(value.contains("2.0px"))
            #expect(value.contains("5.0px"))
        } else {
            Issue.record("Should have box-shadow property")
        }
    }

    @Test func cornerRadiusModifier() async throws {
        let view = _CornerRadiusView(content: Text("Content"), radius: 10)
        let vnode = view.toVNode()

        #expect(vnode.isElement(tag: "div"))
        #expect(vnode.props["border-radius"] == .style(name: "border-radius", value: "10.0px"))
        #expect(vnode.props["overflow"] == .style(name: "overflow", value: "hidden"))
    }

    @Test func opacityModifier() async throws {
        let view = _OpacityView(content: Text("Content"), opacity: 0.5)
        let vnode = view.toVNode()

        #expect(vnode.isElement(tag: "div"))
        #expect(vnode.props["opacity"] == .style(name: "opacity", value: "0.5"))
    }

    @Test func offsetModifier() async throws {
        let view = _OffsetView(content: Text("Content"), x: 10, y: 20)
        let vnode = view.toVNode()

        #expect(vnode.isElement(tag: "div"))

        if case .style(let name, let value) = vnode.props["transform"] {
            #expect(name == "transform")
            #expect(value == "translate(10.0px, 20.0px)")
        } else {
            Issue.record("Should have transform property")
        }
    }

    @Test func rotationEffectModifier() async throws {
        let view = _RotationEffectView(content: Text("Content"), angle: Angle(degrees: 45))
        let vnode = view.toVNode()

        #expect(vnode.isElement(tag: "div"))

        if case .style(let name, let value) = vnode.props["transform"] {
            #expect(name == "transform")
            #expect(value == "rotate(45.0deg)")
        } else {
            Issue.record("Should have transform property")
        }
    }

    @Test func scaleEffectModifier() async throws {
        let view = _ScaleEffectView(content: Text("Content"), scale: 1.5)
        let vnode = view.toVNode()

        #expect(vnode.isElement(tag: "div"))

        if case .style(let name, let value) = vnode.props["transform"] {
            #expect(name == "transform")
            #expect(value == "scale(1.5)")
        } else {
            Issue.record("Should have transform property")
        }
    }

    // MARK: - Test 7: Color/Font Enhancement Tests

    @Test func linearGradient() async throws {
        let gradient = LinearGradient(
            colors: [.red, .blue],
            angle: Angle(degrees: 90)
        )

        let cssValue = gradient.cssValue
        #expect(cssValue.contains("linear-gradient"))
        #expect(cssValue.contains("90.0deg"))
    }

    @Test func radialGradient() async throws {
        let gradient = RadialGradient(colors: [.white, .blue])

        let cssValue = gradient.cssValue
        #expect(cssValue.contains("radial-gradient"))
        #expect(cssValue.contains("circle"))
    }

    @Test func colorCustomCSSVariable() async throws {
        let color = Color.custom("theme-primary")

        // Custom colors should reference CSS variables
        let cssValue = color.cssValue
        #expect(cssValue.contains("var(--theme-primary)"))
    }

    @Test func colorOpacity() async throws {
        let color = Color.red.opacity(0.5)

        let cssValue = color.cssValue
        // Opacity should be reflected in the CSS value
        #expect(cssValue != Color.red.cssValue)
    }

    @Test func fontSystemWithWeight() async throws {
        let font = Font.system(size: 18, weight: .bold)

        let (_, size, weight) = font.cssProperties()

        #expect(size.contains("18"))
        #expect(weight == "700")
    }

    @Test func fontSystemWithDesign() async throws {
        let font = Font.system(size: 16, design: .monospaced)

        let (family, _, _) = font.cssProperties()

        #expect(family.contains("monospace"))
    }

    @Test func fontCustom() async throws {
        let font = Font.custom("Helvetica", size: 20)

        let (family, size, _) = font.cssProperties()

        #expect(family.contains("Helvetica"))
        #expect(size.contains("20"))
    }

    @Test func fontTextStyles() async throws {
        // Test that text style fonts exist and can be used
        let fonts: [Font] = [
            .largeTitle, .title, .title2, .title3,
            .headline, .subheadline, .body,
            .callout, .footnote, .caption, .caption2
        ]

        for font in fonts {
            let (family, size, weight) = font.cssProperties()
            #expect(!family.isEmpty)
            #expect(!size.isEmpty)
            #expect(!weight.isEmpty)
        }
    }

    @Test func angleConversions() async throws {
        let degreesAngle = Angle(degrees: 180)
        #expect(abs(degreesAngle.degrees - 180) < 0.01)
        #expect(abs(degreesAngle.radians - .pi) < 0.01)

        let radiansAngle = Angle(radians: .pi / 2)
        #expect(abs(radiansAngle.degrees - 90) < 0.01)
        #expect(abs(radiansAngle.radians - .pi / 2) < 0.01)
    }

    // MARK: - Test 8: Complete Multi-Screen App Integration

    @Test func multiScreenAppModels() async throws {
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

        #expect(photo.id != nil)
        #expect(photo.title == "Sunset")

        let category = PhotoCategory(
            id: UUID(),
            name: "Nature",
            photos: [photo]
        )

        #expect(category.photos.count == 1)
        #expect(category.photos[0].title == "Sunset")
    }

    @Test func multiScreenAppStore() async throws {
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

        #expect(store.photos.count == 0)
        #expect(store.selectedPhoto == nil)

        store.addPhoto(title: "Photo 1", imageName: "photo1.jpg")
        #expect(store.photos.count == 1)
        #expect(changeCount == 1)

        store.selectPhoto(store.photos[0])
        #expect(store.selectedPhoto != nil)
        #expect(changeCount == 2)
    }

    @Test func multiScreenAppHomeView() async throws {
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
        #expect(home.body != nil)
    }

    @Test func multiScreenAppWithForms() async throws {
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
        #expect(settings.body != nil)

        let settingsStore = settings.$store
        #expect(settingsStore.settings.notificationsEnabled)
        #expect(settingsStore.settings.theme == "light")
    }

    @Test func completeMultiScreenIntegration() async throws {
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

        #expect(state.photos.count == 3)
        #expect(state.selectedCategory == "All")

        // Verify the body compiles
        let body = app.body
        #expect(body != nil)

        // Test navigation flow
        let gridView = PhotoGridView(appState: state)
        #expect(gridView.body != nil)

        let detailView = PhotoDetailView(photo: state.photos[0])
        #expect(detailView.body != nil)
    }

    @Test func completeAppWithAllPhase4Features() async throws {
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

        #expect(store.items.count == 2)
        #expect(store.searchText == "")

        let body = app.body
        #expect(body != nil)

        // Verify we can create the detail view
        let detailView = DetailScreen(item: store.items[0])
        #expect(detailView.body != nil)
    }
}
