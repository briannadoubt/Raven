import Foundation
import JavaScriptKit

/// A button that reads text content from the clipboard.
///
/// Raven's web implementation supports plain-text clipboard pasting. The
/// `payloadAction` receives pasted strings when browser clipboard APIs are available.
public struct PasteButton<Label: View>: View, Sendable {
    private let supportedContentTypes: [UTType]
    private let payloadAction: @Sendable @MainActor ([String]) -> Void
    private let label: Label

    @MainActor public init(
        supportedContentTypes: [UTType],
        payloadAction: @escaping @Sendable @MainActor ([String]) -> Void,
        @ViewBuilder label: () -> Label
    ) {
        self.supportedContentTypes = supportedContentTypes
        self.payloadAction = payloadAction
        self.label = label()
    }

    @MainActor public var body: some View {
        Button(action: readClipboard) {
            label
        }
    }

    @MainActor
    private func readClipboard() {
        guard supportsPlainText else { return }
        guard let eval = JSObject.global.eval.function else {
            payloadAction([])
            return
        }
        guard let promise = JSPromise(from: eval("navigator.clipboard.readText()")) else {
            payloadAction([])
            return
        }

        _ = promise.then(
            success: { value in
                let text = value.string ?? ""
                self.payloadAction(text.isEmpty ? [] : [text])
                return JSValue.undefined
            },
            failure: { _ in
                self.payloadAction([])
                return JSValue.undefined
            }
        )
    }

    private var supportsPlainText: Bool {
        if supportedContentTypes.isEmpty {
            return true
        }
        return supportedContentTypes.contains { type in
            let identifier = typeIdentifier(type)
            return identifier == "public.plain-text"
                || identifier == "public.text"
                || identifier == "text/plain"
        }
    }

    private func typeIdentifier(_ type: UTType) -> String {
        #if canImport(UniformTypeIdentifiers)
        return type.identifier
        #else
        return type.identifier
        #endif
    }
}

extension PasteButton where Label == Text {
    @MainActor public init(
        supportedContentTypes: [UTType],
        payloadAction: @escaping @Sendable @MainActor ([String]) -> Void
    ) {
        self.init(supportedContentTypes: supportedContentTypes, payloadAction: payloadAction) {
            Text("Paste")
        }
    }

    @MainActor public init(
        payloadType: String.Type = String.self,
        onPaste: @escaping @Sendable @MainActor ([String]) -> Void
    ) {
        _ = payloadType
        self.init(supportedContentTypes: [.plainText], payloadAction: onPaste) {
            Text("Paste")
        }
    }
}

extension PasteButton {
    @MainActor public init(
        payloadType: String.Type = String.self,
        onPaste: @escaping @Sendable @MainActor ([String]) -> Void,
        @ViewBuilder label: () -> Label
    ) {
        _ = payloadType
        self.init(supportedContentTypes: [.plainText], payloadAction: onPaste, label: label)
    }
}
