import Foundation

/// A view that presents system sharing for a URL.
///
/// `ShareLink` uses the Web Share API when available, falling back to rendering
/// a normal link when sharing isn't supported.
public struct ShareLink<Label: View>: View, Sendable {
    private let item: URL
    private let subject: String?
    private let message: String?
    private let label: Label
    private let shareTarget: ShareTarget

    // MARK: - Initializers

    /// Creates a share link for a URL with a custom label.
    @MainActor public init(
        item: URL,
        subject: String? = nil,
        message: String? = nil,
        @ViewBuilder label: () -> Label
    ) {
        self.item = item
        self.subject = subject
        self.message = message
        self.label = label()
        self.shareTarget = ShareTarget()
    }

    // MARK: - Body

    public var body: some View {
        Group {
            if shareTarget.canShare {
                Button(action: share) {
                    label
                }
            } else {
                Link(destination: item) {
                    label
                }
            }
        }
    }

    @MainActor private func share() {
        let subject = subject
        let message = message
        let urlString = item.absoluteString

        Task { @MainActor in
            guard shareTarget.canShare else { return }
            _ = try? await shareTarget.share(title: subject, text: message, url: urlString)
        }
    }
}

// MARK: - Convenience Initializers

extension ShareLink where Label == Text {
    /// Creates a share link with a string label.
    @MainActor public init(
        _ title: String,
        item: URL,
        subject: String? = nil,
        message: String? = nil
    ) {
        self.init(item: item, subject: subject, message: message) {
            Text(title)
        }
    }

    /// Creates a share link with a localized string label.
    @MainActor public init(
        _ titleKey: LocalizedStringKey,
        item: URL,
        subject: String? = nil,
        message: String? = nil
    ) {
        self.init(item: item, subject: subject, message: message) {
            Text(titleKey)
        }
    }
}
