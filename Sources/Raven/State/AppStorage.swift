import Foundation
#if arch(wasm32)
import JavaScriptKit
#endif

// MARK: - AppStorage

/// A property wrapper that reads and writes values from a persistent key-value store.
///
/// On Apple platforms, this uses `UserDefaults`.
/// On WASM, this uses `window.localStorage`.
///
/// Raven's implementation is intentionally small: it persists `Codable` values
/// using JSON, and marks all views that read the key as dirty when the value
/// changes so a re-render updates dependents.
@MainActor
@propertyWrapper
public struct AppStorage<Value: Codable & Sendable>: DynamicProperty, Sendable {
    private let key: String
    private let defaultValue: Value
    private let store: UserDefaults?

    public init(wrappedValue: Value, _ key: String, store: UserDefaults? = nil) {
        self.key = key
        self.defaultValue = wrappedValue
        self.store = store
    }

    public var wrappedValue: Value {
        get {
            AppStorageRegistry.shared.box(for: key, defaultValue: defaultValue, store: store).currentValue
        }
        nonmutating set {
            AppStorageRegistry.shared.box(for: key, defaultValue: defaultValue, store: store).setValue(newValue)
        }
    }

    public var projectedValue: Binding<Value> {
        Binding(
            get: { self.wrappedValue },
            set: { self.wrappedValue = $0 }
        )
    }
}

// MARK: - Registry

@MainActor
final class AppStorageRegistry: @unchecked Sendable {
    static let shared = AppStorageRegistry()

    private var boxes: [String: any _AnyAppStorageBox] = [:]

    private init() {}

    func box<Value: Codable & Sendable>(
        for key: String,
        defaultValue: Value,
        store: UserDefaults?
    ) -> AppStorageBox<Value> {
        let storageKey: String
        #if arch(wasm32)
        storageKey = "localStorage|\(key)"
        #else
        let defaults = store ?? .standard
        storageKey = "\(ObjectIdentifier(defaults).hashValue)|\(key)"
        #endif

        if let existing = boxes[storageKey] as? AppStorageBox<Value> {
            return existing
        }
        let created = AppStorageBox<Value>(key: key, defaultValue: defaultValue, store: store)
        boxes[storageKey] = created
        return created
    }
}

@MainActor
protocol _AnyAppStorageBox: AnyObject {}

@MainActor
final class AppStorageBox<Value: Codable & Sendable>: _AnyAppStorageBox, @unchecked Sendable {
    private let key: String
    private let store: UserDefaults?

    private var value: Value
    private var readerComponentPaths: Set<String> = []

    init(key: String, defaultValue: Value, store: UserDefaults?) {
        self.key = key
        self.store = store
        self.value = Self.loadValue(key: key, store: store) ?? defaultValue
    }

    var currentValue: Value {
        if let path = _RenderScheduler.currentComponentPath {
            readerComponentPaths.insert(path)
        }
        return value
    }

    func setValue(_ newValue: Value) {
        value = newValue
        Self.saveValue(newValue, key: key, store: store)

        // Mark all readers dirty; they can be in different subtrees.
        if readerComponentPaths.isEmpty {
            _RenderScheduler.current?.scheduleRender()
            return
        }
        for path in readerComponentPaths {
            _RenderScheduler.current?.markDirty(path: path)
        }
    }

    private static func loadValue(key: String, store: UserDefaults?) -> Value? {
        #if arch(wasm32)
        guard let storage = JSObject.global.window.object?.localStorage.object else { return nil }
        guard let raw = storage.getItem?(key).string, !raw.isEmpty else { return nil }
        guard let data = raw.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(Value.self, from: data)
        #else
        let defaults = store ?? .standard
        if let data = defaults.data(forKey: key) {
            return try? JSONDecoder().decode(Value.self, from: data)
        }
        if let raw = defaults.string(forKey: key), let data = raw.data(using: .utf8) {
            return try? JSONDecoder().decode(Value.self, from: data)
        }
        return nil
        #endif
    }

    private static func saveValue(_ value: Value, key: String, store: UserDefaults?) {
        let encoded: Data?
        do {
            encoded = try JSONEncoder().encode(value)
        } catch {
            return
        }

        #if arch(wasm32)
        guard let storage = JSObject.global.window.object?.localStorage.object else { return }
        let raw = String(data: encoded ?? Data(), encoding: .utf8) ?? ""
        _ = storage.setItem?(key, raw)
        #else
        let defaults = store ?? .standard
        if let encoded {
            defaults.set(encoded, forKey: key)
        }
        #endif
    }
}
