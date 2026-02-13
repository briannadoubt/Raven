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

/// Default current-value label used by SwiftUI gauge/progress style APIs.
@MainActor
public struct CurrentValueLabel: View, Sendable {
    public init() {}

    public var body: some View {
        Text("Current")
    }
}

/// Default minimum-value label used by SwiftUI gauge/progress style APIs.
@MainActor
public struct MinimumValueLabel: View, Sendable {
    public init() {}

    public var body: some View {
        Text("Min")
    }
}

/// Default maximum-value label used by SwiftUI gauge/progress style APIs.
@MainActor
public struct MaximumValueLabel: View, Sendable {
    public init() {}

    public var body: some View {
        Text("Max")
    }
}

/// Default marked-value label used by SwiftUI slider/gauge style APIs.
@MainActor
public struct MarkedValueLabel: View, Sendable {
    public init() {}

    public var body: some View {
        Text("Marked")
    }
}
