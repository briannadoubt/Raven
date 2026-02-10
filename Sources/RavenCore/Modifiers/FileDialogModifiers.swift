import Foundation
import JavaScriptKit

public enum FileDialogError: Error, Sendable {
    case cancelled
    case unsupported
}

public struct ImportedFile: Sendable, Hashable {
    public let name: String
    public let size: Int
    public let type: String

    public init(name: String, size: Int, type: String) {
        self.name = name
        self.size = size
        self.type = type
    }
}

public struct _FileImporterView<Content: View>: View, PrimitiveView, _CoordinatorRenderable, Sendable {
    public typealias Body = Never

    let content: Content
    let isPresented: Binding<Bool>
    let allowedContentTypes: [UTType]
    let allowsMultipleSelection: Bool
    let onCompletion: @Sendable @MainActor (Result<[ImportedFile], Error>) -> Void

    @MainActor public func toVNode() -> VNode {
        VNode.element("div", props: [:], children: [])
    }

    @MainActor public func _render(with context: any _RenderContext) -> VNode {
        let contentNode = context.renderChild(content)

        // When not presented, just render the content normally.
        guard isPresented.wrappedValue else {
            return contentNode
        }

        // Overlay + file input. Browsers require a user gesture to open the picker,
        // so we present a lightweight UI that the user clicks.
        let cancelID = context.registerClickHandler {
            isPresented.wrappedValue = false
            onCompletion(.failure(FileDialogError.cancelled))
        }

        let inputChangeID = context.registerInputHandler { event in
            defer { isPresented.wrappedValue = false }

            guard let target = event.object?.target.object else {
                onCompletion(.failure(FileDialogError.unsupported))
                return
            }

            guard let files = target.files.object else {
                onCompletion(.failure(FileDialogError.cancelled))
                return
            }

            let length = Int(files.length.number ?? 0)
            var out: [ImportedFile] = []
            out.reserveCapacity(max(0, length))
            for i in 0..<length {
                guard let f = files[i].object else { continue }
                let name = f.name.string ?? ""
                let type = f.type.string ?? ""
                let size = Int(f.size.number ?? 0)
                out.append(ImportedFile(name: name, size: size, type: type))
            }

            onCompletion(.success(out))
        }

        let accept = allowedContentTypes.map { $0.identifier }.joined(separator: ",")

        let inputProps: [String: VProperty] = [
            "type": .attribute(name: "type", value: "file"),
            "accept": .attribute(name: "accept", value: accept),
            "multiple": .boolAttribute(name: "multiple", value: allowsMultipleSelection),
            "onChange": .eventHandler(event: "change", handlerID: inputChangeID),
        ]

        let cancelButton = VNode.element(
            "button",
            props: [
                "onClick": .eventHandler(event: "click", handlerID: cancelID),
            ],
            children: [VNode.text("Cancel")]
        )

        let overlay = VNode.element(
            "div",
            props: [
                "position": .style(name: "position", value: "fixed"),
                "left": .style(name: "left", value: "0"),
                "top": .style(name: "top", value: "0"),
                "right": .style(name: "right", value: "0"),
                "bottom": .style(name: "bottom", value: "0"),
                "background": .style(name: "background", value: "rgba(0, 0, 0, 0.35)"),
                "display": .style(name: "display", value: "flex"),
                "align-items": .style(name: "align-items", value: "center"),
                "justify-content": .style(name: "justify-content", value: "center"),
                "z-index": .style(name: "z-index", value: "9999"),
            ],
            children: [
                VNode.element(
                    "div",
                    props: [
                        "background": .style(name: "background", value: "white"),
                        "padding": .style(name: "padding", value: "16px"),
                        "border-radius": .style(name: "border-radius", value: "12px"),
                        "min-width": .style(name: "min-width", value: "280px"),
                        "box-shadow": .style(name: "box-shadow", value: "0 12px 30px rgba(0,0,0,0.25)"),
                        "display": .style(name: "display", value: "flex"),
                        "flex-direction": .style(name: "flex-direction", value: "column"),
                        "gap": .style(name: "gap", value: "12px"),
                    ],
                    children: [
                        VNode.element("div", props: [:], children: [
                            VNode.text("Choose a file to import")
                        ]),
                        VNode.element("input", props: inputProps, children: []),
                        cancelButton,
                    ]
                )
            ]
        )

        return VNode.fragment(children: [contentNode, overlay])
    }
}

extension View {
    /// Presents a file importer.
    ///
    /// Raven's WASM implementation uses an overlay with an `<input type=\"file\">`
    /// because browsers require a user gesture to open the native picker.
    @MainActor public func fileImporter(
        isPresented: Binding<Bool>,
        allowedContentTypes: [UTType],
        allowsMultipleSelection: Bool = false,
        onCompletion: @escaping @Sendable @MainActor (Result<[ImportedFile], Error>) -> Void
    ) -> _FileImporterView<Self> {
        _FileImporterView(
            content: self,
            isPresented: isPresented,
            allowedContentTypes: allowedContentTypes,
            allowsMultipleSelection: allowsMultipleSelection,
            onCompletion: onCompletion
        )
    }

    // Placeholders for other file workflows (API-surface parity first).
    @MainActor public func fileExporter(
        isPresented: Binding<Bool>,
        document _: Any,
        contentType _: UTType,
        defaultFilename _: String? = nil,
        onCompletion _: (@Sendable @MainActor (Result<Void, Error>) -> Void)? = nil
    ) -> some View {
        // TODO: Implement browser download-backed exporter.
        _ = isPresented
        return self
    }

    @MainActor public func fileMover(
        isPresented: Binding<Bool>,
        file _: Any,
        onCompletion _: (@Sendable @MainActor (Result<Void, Error>) -> Void)? = nil
    ) -> some View {
        // TODO: Implement once a Raven file storage abstraction exists.
        _ = isPresented
        return self
    }
}

