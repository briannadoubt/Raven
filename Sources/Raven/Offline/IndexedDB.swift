import Foundation
import JavaScriptKit

/// Swift wrapper for the IndexedDB API providing structured data storage.
///
/// `IndexedDB` provides a type-safe interface to browser IndexedDB for storing
/// structured data locally. It supports transactions, indexes, and complex queries.
@MainActor
public final class IndexedDB: @unchecked Sendable {
    // MARK: - Types

    /// Transaction mode for database operations
    public enum TransactionMode: String, Sendable {
        case readonly
        case readwrite
    }

    /// Index configuration for object stores
    public struct IndexConfig: Sendable {
        public let name: String
        public let keyPath: String
        public let unique: Bool

        public init(name: String, keyPath: String, unique: Bool = false) {
            self.name = name
            self.keyPath = keyPath
            self.unique = unique
        }
    }

    /// Object store configuration
    public struct StoreConfig: Sendable {
        public let name: String
        public let keyPath: String?
        public let autoIncrement: Bool
        public let indexes: [IndexConfig]

        public init(
            name: String,
            keyPath: String? = nil,
            autoIncrement: Bool = false,
            indexes: [IndexConfig] = []
        ) {
            self.name = name
            self.keyPath = keyPath
            self.autoIncrement = autoIncrement
            self.indexes = indexes
        }
    }

    // MARK: - Properties

    /// Database name
    public let name: String

    /// Database version
    public let version: Int

    /// Object store configurations
    private let stores: [StoreConfig]

    /// Open database instance
    nonisolated(unsafe) private var database: JSObject?

    /// Whether the database is currently open
    nonisolated(unsafe) private(set) var isOpen: Bool = false

    // MARK: - Initialization

    public init(name: String, version: Int, stores: [StoreConfig]) {
        self.name = name
        self.version = version
        self.stores = stores
    }

    // MARK: - Database Operations

    /// Open the database connection
    public func open() async throws {
        guard !isOpen else { return }

        let indexedDB = JSObject.global.indexedDB

        return try await withCheckedThrowingContinuation { continuation in
            let request = indexedDB.open(name, version)

            // Success handler
            let successHandler = JSClosure { [weak self] args -> JSValue in
                guard let self = self,
                      let event = args.first?.object,
                      let db = event.target.result.object else {
                    continuation.resume(throwing: IndexedDBError.openFailed)
                    return .undefined
                }

                self.database = db
                self.isOpen = true
                continuation.resume()
                return .undefined
            }

            // Error handler
            let errorHandler = JSClosure { _ in
                continuation.resume(throwing: IndexedDBError.openFailed)
                return .undefined
            }

            // Upgrade handler
            let upgradeHandler = JSClosure { [weak self] args in
                guard let self = self,
                      let event = args.first?.object,
                      let db = event.target.result.object else {
                    return .undefined
                }

                // Create object stores during upgrade
                self.createObjectStores(db: db)
                return .undefined
            }

            if let addEventListenerFunc = request.addEventListener.function {
                _ = addEventListenerFunc("success", successHandler)
                _ = addEventListenerFunc("error", errorHandler)
            }
            _ = request.addEventListener("upgradeneeded", upgradeHandler)
        }
    }

    /// Close the database connection
    nonisolated public func close() {
        _ = database?.close?()
        database = nil
        isOpen = false
    }

    /// Delete the database
    public static func deleteDatabase(name: String) async throws {
        let indexedDB = JSObject.global.indexedDB

        return try await withCheckedThrowingContinuation { continuation in
            let request = indexedDB.deleteDatabase(name)

            let successHandler = JSClosure { _ in
                continuation.resume()
                return .undefined
            }

            let errorHandler = JSClosure { _ in
                continuation.resume(throwing: IndexedDBError.deleteFailed)
                return .undefined
            }

            if let addEventListenerFunc = request.addEventListener.function {
                _ = addEventListenerFunc("success", successHandler)
                _ = addEventListenerFunc("error", errorHandler)
            }
        }
    }

    // MARK: - CRUD Operations

    /// Add a value to an object store
    /// - Parameters:
    ///   - storeName: Name of the object store
    ///   - value: Value to add (must be JSON-serializable)
    ///   - key: Optional explicit key
    public func add(to storeName: String, value: [String: Any], key: String? = nil) async throws {
        guard let db = database else {
            throw IndexedDBError.notOpen
        }

        return try await withCheckedThrowingContinuation { continuation in
            let transaction = db.transaction!([storeName], "readwrite")
            let store = transaction.objectStore(storeName)

            let jsValue = convertToJSValue(value)
            let request: JSValue
            if let key = key {
                guard let addFn = store[dynamicMember: "add"].function else {
                    continuation.resume(throwing: IndexedDBError.operationFailed)
                    return
                }
                request = addFn(jsValue, key)
            } else {
                guard let addFn = store[dynamicMember: "add"].function else {
                    continuation.resume(throwing: IndexedDBError.operationFailed)
                    return
                }
                request = addFn(jsValue)
            }

            let successHandler = JSClosure { _ in
                continuation.resume()
                return .undefined
            }

            let errorHandler = JSClosure { _ in
                continuation.resume(throwing: IndexedDBError.operationFailed)
                return .undefined
            }

            if let addEventListenerFunc = request.addEventListener.function {
                _ = addEventListenerFunc("success", successHandler)
                _ = addEventListenerFunc("error", errorHandler)
            }
        }
    }

    /// Put (add or update) a value in an object store
    /// - Parameters:
    ///   - storeName: Name of the object store
    ///   - value: Value to put
    ///   - key: Optional explicit key
    public func put(to storeName: String, value: [String: Any], key: String? = nil) async throws {
        guard let db = database else {
            throw IndexedDBError.notOpen
        }

        return try await withCheckedThrowingContinuation { continuation in
            let transaction = db.transaction!([storeName], "readwrite")
            let store = transaction.objectStore(storeName)

            let jsValue = convertToJSValue(value)
            let request: JSValue
            if let key = key {
                guard let putFn = store[dynamicMember: "put"].function else {
                    continuation.resume(throwing: IndexedDBError.operationFailed)
                    return
                }
                request = putFn(jsValue, key)
            } else {
                guard let putFn = store[dynamicMember: "put"].function else {
                    continuation.resume(throwing: IndexedDBError.operationFailed)
                    return
                }
                request = putFn(jsValue)
            }

            let successHandler = JSClosure { _ in
                continuation.resume()
                return .undefined
            }

            let errorHandler = JSClosure { _ in
                continuation.resume(throwing: IndexedDBError.operationFailed)
                return .undefined
            }

            if let addEventListenerFunc = request.addEventListener.function {
                _ = addEventListenerFunc("success", successHandler)
                _ = addEventListenerFunc("error", errorHandler)
            }
        }
    }

    /// Get a value from an object store by key
    /// - Parameters:
    ///   - storeName: Name of the object store
    ///   - key: Key to retrieve
    /// - Returns: The stored value or empty dictionary if not found
    public func get(from storeName: String, key: String) async throws -> [String: Any] {
        guard let db = database else {
            throw IndexedDBError.notOpen
        }

        return try await withCheckedThrowingContinuation { continuation in
            let transaction = db.transaction!([storeName], "readonly")
            let store = transaction.objectStore(storeName)
            guard let getFn = store[dynamicMember: "get"].function else {
                continuation.resume(throwing: IndexedDBError.operationFailed)
                return
            }
            let request = getFn(key)

            // Use closure function to avoid ExpressibleByDictionaryLiteral ambiguity
            let successClosure: (sending [JSValue]) -> JSValue = { args in
                guard let event = args.first else{
                    continuation.resume(returning: [:])
                    return .undefined
                }

                let target: JSValue = event[dynamicMember: "target"]
                let result: JSValue = target[dynamicMember: "result"]

                if result.isUndefined || result.isNull {
                    continuation.resume(returning: [:])
                } else {
                    continuation.resume(returning: [:])
                }

                return .undefined
            }
            let successHandler = JSClosure(successClosure)

            let errorClosure: (sending [JSValue]) -> JSValue = { _ in
                continuation.resume(throwing: IndexedDBError.operationFailed)
                return .undefined
            }
            let errorHandler = JSClosure(errorClosure)

            if let addEventListenerFunc = request.addEventListener.function {
                _ = addEventListenerFunc("success", successHandler)
                _ = addEventListenerFunc("error", errorHandler)
            }
        }
    }

    /// Get all values from an object store
    /// - Parameter storeName: Name of the object store
    /// - Returns: Array of all stored values
    public func getAll(from storeName: String) async throws -> [[String: Any]] {
        guard let db = database else {
            throw IndexedDBError.notOpen
        }

        return try await withCheckedThrowingContinuation { continuation in
            let transaction = db.transaction!([storeName], "readonly")
            let store = transaction.objectStore(storeName)
            guard let getAllFn = store[dynamicMember: "getAll"].function else {
                continuation.resume(throwing: IndexedDBError.operationFailed)
                return
            }
            let request = getAllFn()

            let successHandler = JSClosure { [weak self] args -> JSValue in
                guard let self = self,
                      let event = args.first?.object else {
                    continuation.resume(returning: []);
                    return .undefined
                }

                let resultValue: JSValue = event.target.result

                if let array = resultValue.object {
                    let length = array.length.number ?? 0
                    nonisolated(unsafe) var values: [[String: Any]] = []

                    for i in 0..<Int(length) {
                        if let obj = array[i].object {
                            values.append(self.convertFromJSValue(obj))
                        }
                    }

                    continuation.resume(returning: values)
                } else {
                    continuation.resume(returning: [])
                }

                return .undefined
            }

            let errorHandler = JSClosure { _ in
                continuation.resume(throwing: IndexedDBError.operationFailed)
                return .undefined
            }

            if let addEventListenerFunc = request.addEventListener.function {
                _ = addEventListenerFunc("success", successHandler)
                _ = addEventListenerFunc("error", errorHandler)
            }
        }
    }

    /// Delete a value from an object store
    /// - Parameters:
    ///   - storeName: Name of the object store
    ///   - key: Key to delete
    public func delete(from storeName: String, key: String) async throws {
        guard let db = database else {
            throw IndexedDBError.notOpen
        }

        return try await withCheckedThrowingContinuation { continuation in
            let transaction = db.transaction!([storeName], "readwrite")
            let store = transaction.objectStore(storeName)
            guard let deleteFn = store[dynamicMember: "delete"].function else {
                continuation.resume(throwing: IndexedDBError.operationFailed)
                return
            }
            let request = deleteFn(key)

            let successHandler = JSClosure { _ in
                continuation.resume()
                return .undefined
            }

            let errorHandler = JSClosure { _ in
                continuation.resume(throwing: IndexedDBError.operationFailed)
                return .undefined
            }

            if let addEventListenerFunc = request.addEventListener.function {
                _ = addEventListenerFunc("success", successHandler)
                _ = addEventListenerFunc("error", errorHandler)
            }
        }
    }

    /// Clear all values from an object store
    /// - Parameter storeName: Name of the object store
    public func clear(storeName: String) async throws {
        guard let db = database else {
            throw IndexedDBError.notOpen
        }

        return try await withCheckedThrowingContinuation { continuation in
            let transaction = db.transaction!([storeName], "readwrite")
            let store = transaction.objectStore(storeName)
            guard let clearFn = store[dynamicMember: "clear"].function else {
                continuation.resume(throwing: IndexedDBError.operationFailed)
                return
            }
            let request = clearFn()

            let successHandler = JSClosure { _ in
                continuation.resume()
                return .undefined
            }

            let errorHandler = JSClosure { _ in
                continuation.resume(throwing: IndexedDBError.operationFailed)
                return .undefined
            }

            if let addEventListenerFunc = request.addEventListener.function {
                _ = addEventListenerFunc("success", successHandler)
                _ = addEventListenerFunc("error", errorHandler)
            }
        }
    }

    /// Count values in an object store
    /// - Parameter storeName: Name of the object store
    /// - Returns: Number of items in the store
    public func count(in storeName: String) async throws -> Int {
        guard let db = database else {
            throw IndexedDBError.notOpen
        }

        return try await withCheckedThrowingContinuation { continuation in
            let transaction = db.transaction!([storeName], "readonly")
            let store = transaction.objectStore(storeName)
            guard let countFn = store[dynamicMember: "count"].function else {
                continuation.resume(throwing: IndexedDBError.operationFailed)
                return
            }
            let request = countFn()

            let successHandler = JSClosure { args in
                guard let event = args.first?.object,
                      let count = event.target.result.number else {
                    continuation.resume(returning: 0)
                    return .undefined
                }

                continuation.resume(returning: Int(count))
                return .undefined
            }

            let errorHandler = JSClosure { _ in
                continuation.resume(throwing: IndexedDBError.operationFailed)
                return .undefined
            }

            if let addEventListenerFunc = request.addEventListener.function {
                _ = addEventListenerFunc("success", successHandler)
                _ = addEventListenerFunc("error", errorHandler)
            }
        }
    }

    // MARK: - Index Operations

    /// Query values using an index
    /// - Parameters:
    ///   - storeName: Name of the object store
    ///   - indexName: Name of the index
    ///   - value: Value to query for
    /// - Returns: Array of matching values
    public func queryIndex(storeName: String, indexName: String, value: String) async throws -> [[String: Any]] {
        guard let db = database else {
            throw IndexedDBError.notOpen
        }

        return try await withCheckedThrowingContinuation { continuation in
            let transaction = db.transaction!([storeName], "readonly")
            let store = transaction.objectStore(storeName)
            guard let indexFn = store[dynamicMember: "index"].function else {
                continuation.resume(throwing: IndexedDBError.operationFailed)
                return
            }
            let index = indexFn(indexName)
            guard let indexObj = index.object else {
                continuation.resume(throwing: IndexedDBError.operationFailed)
                return
            }
            guard let getAllFn = indexObj[dynamicMember: "getAll"].function else {
                continuation.resume(throwing: IndexedDBError.operationFailed)
                return
            }
            let request = getAllFn(value)

            let successHandler = JSClosure { [weak self] args -> JSValue in
                guard let self = self,
                      let event = args.first?.object else {
                    continuation.resume(returning: []);
                    return .undefined
                }

                let resultValue: JSValue = event.target.result

                if let array = resultValue.object {
                    let length = array.length.number ?? 0
                    nonisolated(unsafe) var values: [[String: Any]] = []

                    for i in 0..<Int(length) {
                        if let obj = array[i].object {
                            values.append(self.convertFromJSValue(obj))
                        }
                    }

                    continuation.resume(returning: values)
                } else {
                    continuation.resume(returning: [])
                }

                return .undefined
            }

            let errorHandler = JSClosure { _ in
                continuation.resume(throwing: IndexedDBError.operationFailed)
                return .undefined
            }

            if let addEventListenerFunc = request.addEventListener.function {
                _ = addEventListenerFunc("success", successHandler)
                _ = addEventListenerFunc("error", errorHandler)
            }
        }
    }

    // MARK: - Private Helpers

    private func createObjectStores(db: JSObject) {
        for store in stores {
            // Check if store already exists
            guard let containsFn = db.objectStoreNames[dynamicMember: "contains"].function else { continue }
            if containsFn(store.name).boolean == true {
                continue
            }

            // Create store options
            guard let options = JSObject.global.Object.function?.new() else { continue }
            if let keyPath = store.keyPath {
                options.keyPath = .string(keyPath)
            }
            options.autoIncrement = .boolean(store.autoIncrement)

            // Create object store
            guard let createStoreFn = db[dynamicMember: "createObjectStore"].function else { continue }
            guard let objectStore = createStoreFn(store.name, options).object else { continue }

            // Create indexes
            for index in store.indexes {
                guard let indexOptions = JSObject.global.Object.function?.new() else { continue }
                indexOptions.unique = .boolean(index.unique)
                guard let createIndexFn = objectStore[dynamicMember: "createIndex"].function else { continue }
                _ = createIndexFn(index.name, index.keyPath, indexOptions)
            }
        }
    }

    private func convertToJSValue(_ value: Any) -> JSValue {
        if let dict = value as? [String: Any] {
            let jsObj = JSObject.global.Object.function!.new()
            for (key, val) in dict {
                jsObj[dynamicMember: key] = convertToJSValue(val)
            }
            return .object(jsObj)
        } else if let array = value as? [Any] {
            let jsArray = JSObject.global.Array.function!.new()
            for (index, item) in array.enumerated() {
                jsArray[index] = convertToJSValue(item)
            }
            return .object(jsArray)
        } else if let string = value as? String {
            return .string(string)
        } else if let number = value as? Double {
            return .number(number)
        } else if let number = value as? Int {
            return .number(Double(number))
        } else if let bool = value as? Bool {
            return .boolean(bool)
        } else {
            return .null
        }
    }

    private func convertFromJSValue(_ jsObject: JSObject) -> [String: Any] {
        var result: [String: Any] = [:]

        let keys = JSObject.global.Object.keys(jsObject)
        let length = keys.length.number ?? 0

        for i in 0..<Int(length) {
            guard let key = keys[i].string else { continue }
            let value = jsObject[dynamicMember: key]

            if let string = value.string {
                result[key] = string
            } else if let number = value.number {
                result[key] = number
            } else if let bool = value.boolean {
                result[key] = bool
            } else if let obj = value.object {
                result[key] = convertFromJSValue(obj)
            }
        }

        return result
    }
}

// MARK: - Errors

/// Errors that can occur during IndexedDB operations
public enum IndexedDBError: Error, Sendable {
    case notOpen
    case openFailed
    case deleteFailed
    case operationFailed
    case transactionFailed
    case notSupported
}
