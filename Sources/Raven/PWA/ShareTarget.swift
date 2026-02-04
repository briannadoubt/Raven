import Foundation
import JavaScriptKit

/// Manages Web Share API and Share Target integration for PWAs
///
/// ShareTarget enables PWAs to share and receive content from other apps,
/// providing native-like sharing capabilities on supported platforms.
///
/// Example usage:
/// ```swift
/// let shareTarget = ShareTarget()
///
/// // Check if sharing is supported
/// if shareTarget.canShare {
///     // Share content
///     try await shareTarget.share(
///         title: "Check this out!",
///         text: "Amazing content",
///         url: "https://example.com"
///     )
/// }
///
/// // Check if file sharing is supported
/// if shareTarget.canShareFiles {
///     let files = [/* JSObject file references */]
///     try await shareTarget.shareFiles(files: files, title: "My Files")
/// }
///
/// // Handle incoming shares (as share target)
/// shareTarget.onShareReceived = { shareData in
///     print("Received share: \(shareData)")
/// }
/// ```
@MainActor
public final class ShareTarget: Sendable {

    // MARK: - Properties

    /// Whether Web Share API is supported
    public var canShare: Bool {
        !JSObject.global.navigator.share.isUndefined
    }

    /// Whether file sharing is supported
    public var canShareFiles: Bool {
        guard let navigator = JSObject.global.navigator.object else {
            return false
        }

        // Check if canShare method exists and supports files
        guard let canShareFunc = navigator.canShare.function else {
            return false
        }

        // Test with empty files array
        let testObj = JSObject.global.Object.function!.new()
        testObj.files = JSValue.object(JSObject.global.Array.function!.new())

        let result = canShareFunc(testObj)
        return result.boolean ?? false
    }

    /// Callback for received shares (when app is share target)
    public var onShareReceived: (@Sendable @MainActor (ShareData) -> Void)?

    // MARK: - Initialization

    public init() {
        setupShareTargetListener()
    }

    // MARK: - Sharing API

    /// Share content using Web Share API
    /// - Parameters:
    ///   - title: Share title
    ///   - text: Share text content
    ///   - url: Share URL
    /// - Throws: ShareError if sharing fails
    public func share(title: String? = nil, text: String? = nil, url: String? = nil) async throws {
        guard canShare else {
            throw ShareError.notSupported
        }

        let shareData = JSObject.global.Object.function!.new()

        if let title = title {
            shareData.title = .string(title)
        }
        if let text = text {
            shareData.text = .string(text)
        }
        if let url = url {
            shareData.url = .string(url)
        }

        do {
            let sharePromise = JSObject.global.navigator.share.function!(shareData)
            _ = try await JSPromise(from: sharePromise)!.getValue()
        } catch {
            // User cancelled or sharing failed
            throw ShareError.userCancelled
        }
    }

    /// Share files using Web Share API
    /// - Parameters:
    ///   - files: Array of File objects
    ///   - title: Share title
    ///   - text: Share text
    /// - Throws: ShareError if sharing fails
    public func shareFiles(files: [JSObject], title: String? = nil, text: String? = nil) async throws {
        guard canShare else {
            throw ShareError.notSupported
        }

        guard !files.isEmpty else {
            throw ShareError.noFiles
        }

        let shareData = JSObject.global.Object.function!.new()

        // Add files array
        let filesArray = JSObject.global.Array.function!.new()
        for file in files {
            _ = filesArray.push!(file)
        }
        shareData.files = JSValue.object(filesArray)

        if let title = title {
            shareData.title = .string(title)
        }
        if let text = text {
            shareData.text = .string(text)
        }

        // Check if this data can be shared
        if let canShareFunc = JSObject.global.navigator.canShare.function {
            let canShareResult = canShareFunc(shareData)
            guard canShareResult.boolean == true else {
                throw ShareError.filesNotSupported
            }
        }

        do {
            let sharePromise = JSObject.global.navigator.share.function!(shareData)
            _ = try await JSPromise(from: sharePromise)!.getValue()
        } catch {
            throw ShareError.userCancelled
        }
    }

    /// Create a shareable file from data
    /// - Parameters:
    ///   - data: File data as Data
    ///   - filename: File name
    ///   - mimeType: MIME type
    /// - Returns: JavaScript File object
    public func createFile(data: Data, filename: String, mimeType: String) -> JSObject {
        // Convert Data to Uint8Array
        let uint8Array = JSObject.global.Uint8Array.function!.new(data.count)
        for (index, byte) in data.enumerated() {
            uint8Array[index] = .number(Double(byte))
        }

        // Create blob
        let blobParts = JSObject.global.Array.function!.new()
        _ = blobParts.push!(uint8Array)

        let blobOptions = JSObject.global.Object.function!.new()
        blobOptions.type = .string(mimeType)

        let blob = JSObject.global.Blob.function!.new(blobParts, blobOptions)

        // Create File from blob
        let fileArgs = JSObject.global.Array.function!.new()
        _ = fileArgs.push!(blob)

        let fileOptions = JSObject.global.Object.function!.new()
        fileOptions.type = .string(mimeType)

        return JSObject.global.File.function!.new(fileArgs, filename, fileOptions)
    }

    // MARK: - Share Target (Receiving Shares)

    /// Set up listener for incoming shares
    private func setupShareTargetListener() {
        // Check if launched as share target
        checkLaunchQueue()

        // Listen for future share target launches
        setupLaunchQueueConsumer()
    }

    /// Check launch queue for share target data
    private func checkLaunchQueue() {
        guard let launchQueue = JSObject.global.launchQueue.object else {
            return
        }

        // Set up consumer for launch queue
        let consumer = JSClosure { [weak self] args -> JSValue in
            guard let self = self, args.count > 0 else {
                return .undefined
            }

            let launchParams = args[0]

            Task { @MainActor in
                self.handleLaunchParams(launchParams.object!)
            }

            return .undefined
        }

        _ = launchQueue.setConsumer!(consumer)

        // Store closure to prevent deallocation
        JSObject.global.__ravenShareConsumer = JSValue.object(consumer)
    }

    /// Set up consumer for launch queue
    private func setupLaunchQueueConsumer() {
        // This is called when app receives a share
        // Launch queue consumer is already set up in checkLaunchQueue
    }

    /// Handle launch parameters from share target
    private func handleLaunchParams(_ launchParams: JSObject) {
        guard let files = launchParams.files.object else {
            return
        }

        let shareData = parseShareData(launchParams)
        onShareReceived?(shareData)
    }

    /// Parse share data from launch params
    private func parseShareData(_ launchParams: JSObject) -> ShareData {
        var title: String?
        var text: String?
        var url: String?
        var files: [ShareFile] = []

        // Extract title, text, url from query parameters
        if let targetURL = launchParams.targetURL.string {
            if let urlComponents = parseURL(targetURL) {
                title = urlComponents["title"]
                text = urlComponents["text"]
                url = urlComponents["url"]
            }
        }

        // Extract files
        if let filesArray = launchParams.files.object {
            let length = filesArray.length.number ?? 0
            for i in 0..<Int(length) {
                if let file = filesArray[i].object {
                    let shareFile = parseFile(file)
                    files.append(shareFile)
                }
            }
        }

        return ShareData(
            title: title,
            text: text,
            url: url,
            files: files
        )
    }

    /// Parse URL query parameters
    private func parseURL(_ urlString: String) -> [String: String]? {
        guard let url = URL(string: urlString),
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return nil
        }

        var params: [String: String] = [:]
        for item in components.queryItems ?? [] {
            if let value = item.value {
                params[item.name] = value
            }
        }

        return params
    }

    /// Parse JavaScript File object
    private func parseFile(_ jsFile: JSObject) -> ShareFile {
        let name = jsFile.name.string ?? "unknown"
        let type = jsFile.type.string ?? "application/octet-stream"
        let size = Int(jsFile.size.number ?? 0)

        return ShareFile(
            name: name,
            type: type,
            size: size,
            jsObject: jsFile
        )
    }

    // MARK: - File Reading

    /// Read file as text
    /// - Parameter shareFile: Share file to read
    /// - Returns: File content as string
    /// - Throws: ShareError if reading fails
    public func readFileAsText(_ shareFile: ShareFile) async throws -> String {
        let file = shareFile.jsObject

        do {
            let textPromise = file.text.function!()
            let result = try await JSPromise(from: textPromise)!.getValue()
            return result.string ?? ""
        } catch {
            throw ShareError.fileReadFailed
        }
    }

    /// Read file as data
    /// - Parameter shareFile: Share file to read
    /// - Returns: File content as Data
    /// - Throws: ShareError if reading fails
    public func readFileAsData(_ shareFile: ShareFile) async throws -> Data {
        let file = shareFile.jsObject

        do {
            let arrayBufferPromise = file.arrayBuffer.function!()
            let result = try await JSPromise(from: arrayBufferPromise)!.getValue()

            // Convert ArrayBuffer to Data
            let arrayBuffer = result.object!
            let uint8Array = JSObject.global.Uint8Array.function!.new(arrayBuffer)
            let length = Int(uint8Array.length.number ?? 0)

            var data = Data()
            for i in 0..<length {
                if let byte = uint8Array[i].number {
                    data.append(UInt8(byte))
                }
            }

            return data
        } catch {
            throw ShareError.fileReadFailed
        }
    }

    /// Read file as data URL (base64)
    /// - Parameter shareFile: Share file to read
    /// - Returns: Data URL string
    /// - Throws: ShareError if reading fails
    public func readFileAsDataURL(_ shareFile: ShareFile) async throws -> String {
        let file = shareFile.jsObject

        return try await withCheckedThrowingContinuation { continuation in
            let reader = JSObject.global.FileReader.function!.new()

            // Set up load handler
            let onLoad = JSClosure { [reader] args -> JSValue in
                if let result = reader.result.string {
                    continuation.resume(returning: result)
                } else {
                    continuation.resume(throwing: ShareError.fileReadFailed)
                }
                return .undefined
            }

            let onError = JSClosure { _ -> JSValue in
                continuation.resume(throwing: ShareError.fileReadFailed)
                return .undefined
            }

            _ = reader.addEventListener.function!("load", onLoad)
            _ = reader.addEventListener.function!("error", onError)

            // Read file
            _ = reader.readAsDataURL.function!(file)

            // Store closures
            reader.__ravenReadClosures = JSValue.object(JSObject.global.Array.function!.new())
            _ = reader.__ravenReadClosures.push.function!(onLoad, onError)
        }
    }
}

// MARK: - Supporting Types

/// Share data received by share target
public struct ShareData: Sendable {
    public let title: String?
    public let text: String?
    public let url: String?
    public let files: [ShareFile]

    public init(title: String?, text: String?, url: String?, files: [ShareFile]) {
        self.title = title
        self.text = text
        self.url = url
        self.files = files
    }
}

/// Shared file information
public struct ShareFile: Sendable {
    public let name: String
    public let type: String
    public let size: Int
    nonisolated(unsafe) public let jsObject: JSObject

    public init(name: String, type: String, size: Int, jsObject: JSObject) {
        self.name = name
        self.type = type
        self.size = size
        self.jsObject = jsObject
    }
}

/// Share errors
public enum ShareError: Error, Sendable {
    case notSupported
    case userCancelled
    case noFiles
    case filesNotSupported
    case fileReadFailed
}
