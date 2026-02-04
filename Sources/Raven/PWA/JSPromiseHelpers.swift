import Foundation
import JavaScriptKit

/// Helper extension for JSPromise to provide async/await support without JavaScriptEventLoop dependency
extension JSPromise {
    /// Wait for the promise to complete and return its value
    /// - Returns: The resolved JSValue
    /// - Throws: Error if the promise rejects
    @MainActor
    func getValue() async throws -> JSValue {
        try await withCheckedThrowingContinuation { continuation in
            _ = self.then(
                success: { value in
                    continuation.resume(returning: value)
                    return .undefined
                },
                failure: { error in
                    continuation.resume(throwing: JSPromiseError.rejected(error))
                    return .undefined
                }
            )
        }
    }
}

/// Errors that can occur when working with JS Promises
enum JSPromiseError: Error, @unchecked Sendable {
    case rejected(JSValue)
    case conversionFailed
}
