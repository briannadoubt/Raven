import Testing
import RavenAssetSupport

@Suite("AssetID Tests")
struct AssetIDTests {
    @Test("Slugify produces stable ASCII")
    func slugifyBasic() {
        #expect(AssetID.slugify("Brand Primary") == "brand-primary")
        #expect(AssetID.slugify("  Hello__World  ") == "hello-world")
        #expect(AssetID.slugify("Symbols!@#$") == "symbols")
    }

    @Test("fromName includes hash suffix")
    func fromNameIncludesHash() {
        let id = AssetID.fromName("Logo")
        #expect(id.hasPrefix("logo-"))
        #expect(id.count >= "logo-".count + 16)
    }
}

