import Foundation

/// A placeholder type for SwiftUI API parity.
///
/// SwiftUI defines `AdaptableTabBarPlacement` as a value type used by some
/// TabView configurations on Apple platforms. Raven's TabView currently renders
/// using a single web-first presentation, so this type is provided for source
/// compatibility only.
public struct AdaptableTabBarPlacement: Sendable, Hashable {
    @MainActor public init() {}
}

