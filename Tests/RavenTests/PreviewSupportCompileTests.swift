import XCTest
import RavenCore

@MainActor
private struct _PreviewTestView: View {
    var body: some View {
        Text("Preview")
    }
}

private struct _PreviewProviderTest: PreviewProvider {
    static var previews: some View {
        _PreviewTestView()
            .previewDisplayName("Test")
            .previewLayout(.sizeThatFits)
            .previewDevice(PreviewDevice("Raven"))
    }
}

#Preview {
    _PreviewTestView()
}

final class PreviewSupportCompileTests: XCTestCase {
    func testPreviewSupportCompiles() {
        XCTAssertTrue(true)
    }
}

