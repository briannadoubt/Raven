// SwiftUI Preview compatibility shims.
//
// These are intentionally no-op: we only want PreviewProvider and `#Preview` to compile
// in Raven apps (including when cross-compiling to WASM).

@MainActor
public protocol PreviewProvider {
    associatedtype Previews: View

    @ViewBuilder static var previews: Previews { get }
}

public struct PreviewDevice: Hashable, Sendable {
    public var rawValue: String

    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }
}

public enum PreviewLayout: Hashable, Sendable {
    case device
    case fixed(width: Double, height: Double)
    case sizeThatFits
}

public extension View {
    @MainActor func previewDevice(_ device: PreviewDevice?) -> some View { self }
    @MainActor func previewDisplayName(_ name: String?) -> some View { self }
    @MainActor func previewLayout(_ layout: PreviewLayout) -> some View { self }
}

// MARK: - `#Preview`

@freestanding(declaration)
public macro Preview<Content: View>(
    _ name: String? = nil,
    traits: Any = (),
    @ViewBuilder _ content: () -> Content
) = #externalMacro(module: "RavenPreviewMacros", type: "PreviewMacro")

