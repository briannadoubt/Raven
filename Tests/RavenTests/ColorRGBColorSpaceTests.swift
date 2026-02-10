import Testing
@testable import RavenCore

@MainActor
struct ColorRGBColorSpaceTests {
    @Test("Color(.sRGB, red:green:blue:opacity:) matches default RGB initializer")
    func sRGBInitializerMatchesDefault() {
        let a = Color(.sRGB, red: 1.0, green: 0.5, blue: 0.0, opacity: 1.0)
        let b = Color(red: 1.0, green: 0.5, blue: 0.0, opacity: 1.0)
        #expect(a.cssValue == b.cssValue)
        #expect(a.cssValue == "rgb(255, 127, 0)")
    }

    @Test("Color(.displayP3, ...) uses CSS Color 4 syntax")
    func displayP3UsesColorFunction() {
        let c = Color(.displayP3, red: 0.1, green: 0.2, blue: 0.3, opacity: 0.4)
        #expect(c.cssValue.contains("color(display-p3"))
        #expect(c.cssValue.contains("/"))
        #expect(c.cssValue.hasSuffix(")"))
    }
}

