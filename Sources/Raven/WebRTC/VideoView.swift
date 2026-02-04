import Foundation
import JavaScriptKit

/// SwiftUI view wrapper for HTML5 video element displaying WebRTC streams
///
/// VideoView renders a video element that can display media streams from WebRTC
/// peer connections. It supports both local and remote streams, autoplay, controls,
/// and standard SwiftUI modifiers.
///
/// ## Example Usage
///
/// ```swift
/// struct VideoCallView: View {
///     @State private var localStream: MediaStream?
///     @State private var remoteStream: MediaStream?
///
///     var body: some View {
///         VStack {
///             // Remote video (large)
///             if let stream = remoteStream {
///                 VideoView(stream: stream, autoplay: true)
///                     .frame(maxWidth: .infinity, maxHeight: .infinity)
///             }
///
///             // Local video (small overlay)
///             if let stream = localStream {
///                 VideoView(stream: stream, autoplay: true, muted: true)
///                     .frame(width: 150, height: 150)
///                     .cornerRadius(8)
///             }
///         }
///     }
/// }
/// ```
@MainActor
public struct VideoView: View {
    public typealias Body = Never

    // MARK: - Properties

    /// Media stream to display
    public let stream: MediaStream?

    /// Whether to automatically play the video
    public let autoplay: Bool

    /// Whether to show video controls
    public let showsControls: Bool

    /// Whether the video is muted
    public let muted: Bool

    /// Whether to play the video inline (iOS)
    public let playsInline: Bool

    /// Video object fit mode
    public let objectFit: ObjectFit

    /// Whether to mirror the video horizontally
    public let mirrored: Bool

    /// Unique identifier for this view
    private let id: UUID

    // MARK: - Initialization

    /// Creates a video view displaying a media stream
    ///
    /// - Parameters:
    ///   - stream: Media stream to display
    ///   - autoplay: Whether to automatically play. Defaults to true.
    ///   - showsControls: Whether to show video controls. Defaults to false.
    ///   - muted: Whether the video is muted. Defaults to false.
    ///   - playsInline: Whether to play inline on iOS. Defaults to true.
    ///   - objectFit: How video content fits in the frame. Defaults to .cover.
    ///   - mirrored: Whether to mirror the video. Defaults to false.
    public init(
        stream: MediaStream?,
        autoplay: Bool = true,
        showsControls: Bool = false,
        muted: Bool = false,
        playsInline: Bool = true,
        objectFit: ObjectFit = .cover,
        mirrored: Bool = false
    ) {
        self.stream = stream
        self.autoplay = autoplay
        self.showsControls = showsControls
        self.muted = muted
        self.playsInline = playsInline
        self.objectFit = objectFit
        self.mirrored = mirrored
        self.id = UUID()
    }

    // MARK: - Rendering

    /// Renders the video view to the DOM
    internal func render() -> VideoElement {
        VideoElement(
            stream: stream,
            autoplay: autoplay,
            showsControls: showsControls,
            muted: muted,
            playsInline: playsInline,
            objectFit: objectFit,
            mirrored: mirrored,
            id: id
        )
    }
}

// MARK: - Object Fit

extension VideoView {
    /// Defines how video content fits within its frame
    public enum ObjectFit: String, Sendable {
        /// Video maintains aspect ratio, may be letterboxed
        case contain

        /// Video fills frame, may be cropped
        case cover

        /// Video is stretched to fill frame
        case fill

        /// Video is not resized
        case none

        /// Video is scaled down to fit if too large
        case scaleDown = "scale-down"
    }
}

// MARK: - Video Element

/// Internal representation of a video DOM element
@MainActor
internal struct VideoElement: Sendable {
    let stream: MediaStream?
    let autoplay: Bool
    let showsControls: Bool
    let muted: Bool
    let playsInline: Bool
    let objectFit: VideoView.ObjectFit
    let mirrored: Bool
    let id: UUID

    func createElement() -> JSObject {
        // Create video element
        let video = JSObject.global.document.createElement("video").object!

        // Set unique ID
        video.id = JSValue.string(id.uuidString)

        // Configure attributes
        if autoplay {
            video.autoplay = JSValue.boolean(true)
        }

        if showsControls {
            video.controls = JSValue.boolean(true)
        }

        if muted {
            video.muted = JSValue.boolean(true)
        }

        if playsInline {
            _ = video.setAttribute?("playsinline", "")
            _ = video.setAttribute?("webkit-playsinline", "")
        }

        // Set stream
        if let stream = stream {
            video.srcObject = JSValue.object(stream.jsObject)
        }

        // Apply styling
        let style = video.style
        style.objectFit = JSValue.string(objectFit.rawValue)
        style.width = JSValue.string("100%")
        style.height = JSValue.string("100%")

        if mirrored {
            style.transform = JSValue.string("scaleX(-1)")
        }

        return video
    }

    func updateElement(_ element: JSObject) {
        // Update stream if changed
        if let stream = stream {
            element.srcObject = JSValue.object(stream.jsObject)
        } else {
            element.srcObject = JSValue.null
        }

        // Update attributes
        element.autoplay = JSValue.boolean(autoplay)
        element.controls = JSValue.boolean(showsControls)
        element.muted = JSValue.boolean(muted)

        // Update styling
        let style = element.style
        style.objectFit = JSValue.string(objectFit.rawValue)

        if mirrored {
            style.transform = JSValue.string("scaleX(-1)")
        } else {
            style.transform = JSValue.string("none")
        }
    }
}

// MARK: - Video View Modifiers

extension VideoView {
    /// Sets whether the video should show playback controls
    ///
    /// - Parameter showsControls: Whether to show controls
    /// - Returns: Modified video view
    public func showsControls(_ showsControls: Bool) -> VideoView {
        VideoView(
            stream: stream,
            autoplay: autoplay,
            showsControls: showsControls,
            muted: muted,
            playsInline: playsInline,
            objectFit: objectFit,
            mirrored: mirrored
        )
    }

    /// Sets whether the video should be muted
    ///
    /// - Parameter muted: Whether to mute audio
    /// - Returns: Modified video view
    public func muted(_ muted: Bool) -> VideoView {
        VideoView(
            stream: stream,
            autoplay: autoplay,
            showsControls: showsControls,
            muted: muted,
            playsInline: playsInline,
            objectFit: objectFit,
            mirrored: mirrored
        )
    }

    /// Sets the video object fit mode
    ///
    /// - Parameter objectFit: How content fits in the frame
    /// - Returns: Modified video view
    public func objectFit(_ objectFit: ObjectFit) -> VideoView {
        VideoView(
            stream: stream,
            autoplay: autoplay,
            showsControls: showsControls,
            muted: muted,
            playsInline: playsInline,
            objectFit: objectFit,
            mirrored: mirrored
        )
    }

    /// Sets whether the video should be mirrored
    ///
    /// - Parameter mirrored: Whether to mirror horizontally
    /// - Returns: Modified video view
    public func mirrored(_ mirrored: Bool) -> VideoView {
        VideoView(
            stream: stream,
            autoplay: autoplay,
            showsControls: showsControls,
            muted: muted,
            playsInline: playsInline,
            objectFit: objectFit,
            mirrored: mirrored
        )
    }
}

// MARK: - Video Recorder

/// Records video stream to downloadable file
@MainActor
public final class VideoRecorder: Sendable {
    // MARK: - Properties

    private let mediaRecorder: JSObject
    private var recordedChunks: [JSValue] = []

    private var dataAvailableClosure: JSClosure?
    private var stopClosure: JSClosure?

    /// Whether recording is currently active
    public var isRecording: Bool {
        if let state = mediaRecorder.state.string {
            return state == "recording"
        }
        return false
    }

    // MARK: - Initialization

    /// Creates video recorder for a stream
    ///
    /// - Parameters:
    ///   - stream: Media stream to record
    ///   - mimeType: MIME type for recording (e.g., "video/webm")
    ///   - videoBitsPerSecond: Video encoding bitrate
    /// - Throws: VideoRecorderError if MediaRecorder is not supported
    public init(
        stream: MediaStream,
        mimeType: String = "video/webm",
        videoBitsPerSecond: Int? = nil
    ) throws {
        guard let mediaRecorderConstructor = JSObject.global.MediaRecorder.function else {
            throw VideoRecorderError.notSupported
        }

        let options = JSObject.global.Object.call()
        options.mimeType = JSValue.string(mimeType)

        if let bitrate = videoBitsPerSecond {
            options.videoBitsPerSecond = JSValue.number(Double(bitrate))
        }

        guard let recorder = mediaRecorderConstructor(stream.jsObject, options).object else {
            fatalError("Failed to create MediaRecorder")
        }
        self.mediaRecorder = recorder

        setupEventHandlers()
    }

    deinit {
    }

    // MARK: - Event Handlers

    private func setupEventHandlers() {
        dataAvailableClosure = JSClosure { [weak self] args in
            Task { @MainActor [weak self] in
                guard let self = self,
                      args.count > 0,
                      let event = args[0].object else { return }

                self.recordedChunks.append(event.data)
            }
            return .undefined
        }
        mediaRecorder.ondataavailable = .object(dataAvailableClosure!)
    }

    // MARK: - Recording Control

    /// Start recording
    ///
    /// - Parameter timeslice: Optional time slice in milliseconds for data events
    public func start(timeslice: Int? = nil) {
        recordedChunks.removeAll()

        if let timeslice = timeslice {
            _ = mediaRecorder.start.call(timeslice)
        } else {
            _ = mediaRecorder.start.call()
        }
    }

    /// Stop recording and get the recorded data
    ///
    /// - Returns: Recorded video data as Data
    public func stop() async -> Data? {
        return await withCheckedContinuation { continuation in
            stopClosure = JSClosure { [weak self] _ in
                Task { @MainActor [weak self] in
                    guard let self = self else {
                        continuation.resume(returning: nil)
                        return
                    }

                    // Create blob from chunks
                    let chunksArray = JSObject.global.Array.call()
                    for (index, chunk) in self.recordedChunks.enumerated() {
                        chunksArray[index] = chunk
                    }

                    let blob = JSObject.global.Blob.call(chunksArray)

                    // Convert blob to array buffer
                    let promise = blob.arrayBuffer.call()
                    _ = promise.then.call(JSClosure { args in
                        if let arrayBuffer = args.first?.object {
                            let uint8Array = JSObject.global.Uint8Array.call(arrayBuffer)
                            let length = Int(uint8Array.length.number ?? 0)

                            var bytes: [UInt8] = []
                            bytes.reserveCapacity(length)

                            for i in 0..<length {
                                if let byte = uint8Array[i].number {
                                    bytes.append(UInt8(byte))
                                }
                            }

                            continuation.resume(returning: Data(bytes))
                        } else {
                            continuation.resume(returning: nil)
                        }
                        return .undefined
                    })
                }
                return .undefined
            }
            mediaRecorder.onstop = .object(stopClosure!)

            _ = mediaRecorder.stop.call()
        }
    }

    /// Pause recording
    public func pause() {
        _ = mediaRecorder.pause.call()
    }

    /// Resume recording
    public func resume() {
        _ = mediaRecorder.resume.call()
    }

    /// Request data event
    public func requestData() {
        _ = mediaRecorder.requestData.call()
    }

    // MARK: - Cleanup

    private func cleanup() {
        dataAvailableClosure = nil
        stopClosure = nil
        recordedChunks.removeAll()
    }
}

// MARK: - Errors

public enum VideoRecorderError: Error, Sendable {
    case notSupported
    case recordingFailed
}

// MARK: - Video Snapshot

extension VideoView {
    /// Capture a snapshot from the video
    ///
    /// - Returns: Captured image data as Data (PNG format)
    public static func captureSnapshot(from stream: MediaStream) async -> Data? {
        return await withCheckedContinuation { continuation in
            // Create temporary video element
            let video = JSObject.global.document.createElement("video").object!
            video.srcObject = JSValue.object(stream.jsObject)
            video.autoplay = JSValue.boolean(true)
            video.muted = JSValue.boolean(true)

            // Wait for video to have dimensions
            let loadedMetadataClosure = JSClosure { _ in
                Task { @MainActor in
                    // Create canvas
                    let canvas = JSObject.global.document.createElement.call("canvas").object!
                    let width = video.videoWidth.number ?? 640
                    let height = video.videoHeight.number ?? 480

                    canvas.width = JSValue.number(width)
                    canvas.height = JSValue.number(height)

                    // Draw video frame to canvas
                    if let ctx = canvas.getContext.call("2d").object {
                        _ = ctx.drawImage.call(video, 0, 0, width, height)

                        // Convert canvas to blob
                        let blobCallback = JSClosure { args in
                            Task { @MainActor in
                                if let blob = args.first?.object {
                                    // Convert blob to array buffer
                                    let promise = blob.arrayBuffer.call()
                                    _ = promise.then.call(JSClosure { args in
                                        if let arrayBuffer = args.first?.object {
                                            let uint8Array = JSObject.global.Uint8Array.call(arrayBuffer)
                                            let length = Int(uint8Array.length.number ?? 0)

                                            var bytes: [UInt8] = []
                                            bytes.reserveCapacity(length)

                                            for i in 0..<length {
                                                if let byte = uint8Array[i].number {
                                                    bytes.append(UInt8(byte))
                                                }
                                            }

                                            continuation.resume(returning: Data(bytes))
                                        } else {
                                            continuation.resume(returning: nil)
                                        }
                                        return .undefined
                                    })
                                } else {
                                    continuation.resume(returning: nil)
                                }
                            }
                            return .undefined
                        }

                        _ = canvas.toBlob.call(blobCallback)
                    } else {
                        continuation.resume(returning: nil)
                    }
                }
                return .undefined
            }

            video.onloadedmetadata = .object(loadedMetadataClosure)
        }
    }
}
