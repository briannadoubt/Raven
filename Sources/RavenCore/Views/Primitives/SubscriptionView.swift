import Foundation

/// A view that presents subscription-related content.
///
/// This compatibility implementation preserves SwiftUI-style API usage and renders
/// a lightweight card in the browser.
@MainActor
public struct SubscriptionView<Content: View>: View, Sendable {
    private let content: Content

    /// Creates a subscription view with custom content.
    @MainActor public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    @MainActor public var body: some View {
        VStack(spacing: 12) {
            content
        }
        .padding(16)
        .background(Color.secondarySystemBackground)
        .cornerRadius(12)
    }
}

extension SubscriptionView where Content == _DefaultSubscriptionContent {
    /// Creates a subscription view with default marketing copy.
    @MainActor public init() {
        self.content = _DefaultSubscriptionContent()
    }
}

@MainActor
public struct _DefaultSubscriptionContent: View, Sendable {
    @MainActor public init() {}

    @MainActor public var body: some View {
        VStack(spacing: 8) {
            Text("Subscription")
                .font(.headline)
            Text("Unlock additional features with a premium plan.")
                .font(.caption)
                .foregroundColor(Color.secondaryLabel)
        }
    }
}
