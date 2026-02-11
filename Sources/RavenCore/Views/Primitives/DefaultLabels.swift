import Foundation

/// Default button title content used by SwiftUI button style APIs.
@MainActor
public struct DefaultButtonLabel: View, Sendable {
    public init() {}

    public var body: some View {
        Text("Button")
    }
}

/// Default date-related progress label used by SwiftUI progress APIs.
@MainActor
public struct DefaultDateProgressLabel: View, Sendable {
    public init() {}

    public var body: some View {
        Text("Progress")
    }
}

/// Default share link label used by SwiftUI's `ShareLink`.
@MainActor
public struct DefaultShareLinkLabel: View, Sendable {
    public init() {}

    public var body: some View {
        Label("Share", systemImage: "square.and.arrow.up")
    }
}
