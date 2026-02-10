import Foundation
import JavaScriptKit

// MARK: - Drag And Drop Types

/// A lightweight UTType stand-in for platforms that don't ship
/// `UniformTypeIdentifiers` (notably Swift WASM).
///
/// On Apple platforms, Raven prefers the system `UTType` when available.
#if canImport(UniformTypeIdentifiers)
import UniformTypeIdentifiers
public typealias UTType = UniformTypeIdentifiers.UTType
#else
public struct UTType: Sendable, Hashable {
    public let identifier: String

    public init(_ identifier: String) {
        self.identifier = identifier
    }

    public static let plainText = UTType("public.plain-text")
    public static let text = UTType("public.text")
    public static let data = UTType("public.data")
    public static let item = UTType("public.item")
}
#endif

/// A file dropped onto a drop target.
public struct DroppedFile: Sendable, Hashable {
    public let name: String
    public let size: Int
    public let type: String

    public init(name: String, size: Int, type: String) {
        self.name = name
        self.size = size
        self.type = type
    }
}

/// High-level drop payloads Raven can extract from the browser.
public enum DropItem: Sendable, Hashable {
    case text(String)
    case file(DroppedFile)
}

@MainActor
internal enum DragDropJS {
    static func preventDefault(_ event: JSValue) {
        _ = event.object?.preventDefault?()
    }

    static func stopPropagation(_ event: JSValue) {
        _ = event.object?.stopPropagation?()
    }

    static func dataTransfer(_ event: JSValue) -> JSObject? {
        event.object?.dataTransfer.object
    }

    static func setPlainText(_ event: JSValue, value: String) {
        guard let dt = dataTransfer(event) else { return }
        _ = dt.setData?("text/plain", value)
        // Hints (best effort; not all browsers honor these).
        _ = dt.effectAllowed = .string("copyMove")
    }

    static func getPlainText(_ event: JSValue) -> String? {
        guard let dt = dataTransfer(event) else { return nil }
        return dt.getData?("text/plain").string
    }

    static func files(_ event: JSValue) -> [DroppedFile] {
        guard let dt = dataTransfer(event) else { return [] }
        guard let files = dt.files.object else { return [] }

        let length = Int(files.length.number ?? 0)
        if length <= 0 { return [] }

        var out: [DroppedFile] = []
        out.reserveCapacity(length)
        for i in 0..<length {
            guard let f = files[i].object else { continue }
            let name = f.name.string ?? ""
            let type = f.type.string ?? ""
            let size = Int(f.size.number ?? 0)
            out.append(DroppedFile(name: name, size: size, type: type))
        }
        return out
    }
}

