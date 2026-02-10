import Foundation
import JavaScriptKit

public enum Asset {
    /// Resolves a data asset URL from the injected asset manifest.
    @MainActor
    public static func url(_ name: String) -> String? {
        AssetRegistry.resolveDataURL(name)
    }

    /// Fetches a data asset into memory.
    ///
    /// Note: this is intended for WASM builds; on non-WASM platforms, it throws.
    @MainActor
    public static func fetchData(_ name: String) async throws -> Data {
        #if arch(wasm32)
        guard let urlString = url(name) else {
            throw AssetError.notFound(name)
        }
        guard let fetchFn = JSObject.global.fetch.function else {
            throw AssetError.fetchUnavailable
        }

        let responseValue = try await JSPromise(from: fetchFn(urlString))!.getValue()
        guard let response = responseValue.object else {
            throw AssetError.fetchFailed(urlString)
        }

        guard let arrayBufferFn = response[dynamicMember: "arrayBuffer"].function else {
            throw AssetError.fetchFailed(urlString)
        }

        let arrayBufferValue = try await JSPromise(from: arrayBufferFn())!.getValue()
        guard let arrayBufferObj = arrayBufferValue.object else {
            throw AssetError.fetchFailed(urlString)
        }

        guard let uint8ArrayCtor = JSObject.global.Uint8Array.function else {
            throw AssetError.fetchFailed(urlString)
        }

        let uint8 = uint8ArrayCtor.new(arrayBufferObj)
        let length = Int(uint8.length.number ?? 0)
        var bytes: [UInt8] = []
        bytes.reserveCapacity(length)
        for i in 0..<length {
            let n = uint8[i].number ?? 0
            bytes.append(UInt8(clamping: Int(n)))
        }
        return Data(bytes)
        #else
        throw AssetError.unsupportedPlatform
        #endif
    }

    public enum AssetError: Error, LocalizedError, Sendable {
        case notFound(String)
        case fetchUnavailable
        case fetchFailed(String)
        case unsupportedPlatform

        public var errorDescription: String? {
            switch self {
            case .notFound(let name):
                return "Asset not found: \(name)"
            case .fetchUnavailable:
                return "Fetch API is not available"
            case .fetchFailed(let url):
                return "Failed to fetch asset at \(url)"
            case .unsupportedPlatform:
                return "Asset.fetchData is only supported on WASM"
            }
        }
    }
}

