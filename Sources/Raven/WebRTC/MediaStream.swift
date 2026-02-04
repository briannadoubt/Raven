import Foundation
import JavaScriptKit

/// Represents a stream of media content (audio and/or video)
///
/// MediaStream manages a collection of media tracks from sources like cameras,
/// microphones, or screen sharing. Tracks can be added, removed, and configured
/// independently.
///
/// ## Example Usage
///
/// ```swift
/// // Get user media
/// let stream = try await MediaStream.getUserMedia?(
///     audio: true,
///     video: VideoConstraints(width: 1280, height: 720)
/// )
///
/// // Access tracks
/// for track in stream.videoTracks {
///     print("Video track:", track.label)
/// }
///
/// // Stop all tracks
/// stream.stop?()
/// ```
@MainActor
public final class MediaStream: Sendable {
    // MARK: - Properties

    /// The underlying JavaScript MediaStream object
    private let jsStream: JSObject

    /// Unique identifier for this stream
    public var id: String {
        jsStream.id.string ?? ""
    }

    /// Whether this stream is active
    public var active: Bool {
        jsStream.active.boolean ?? false
    }

    /// All tracks in this stream
    public var tracks: [MediaStreamTrack] {
        guard let jsTracks = jsStream.getTracks.call().object else {
            return []
        }
        let length = Int(jsTracks.length.number ?? 0)

        var tracks: [MediaStreamTrack] = []
        for i in 0..<length {
            if let jsTrack = jsTracks[i].object {
                tracks.append(MediaStreamTrack(jsTrack: jsTrack))
            }
        }
        return tracks
    }

    /// Audio tracks in this stream
    public var audioTracks: [MediaStreamTrack] {
        guard let jsTracks = jsStream.getAudioTracks.call().object else {
            return []
        }
        let length = Int(jsTracks.length.number ?? 0)

        var tracks: [MediaStreamTrack] = []
        for i in 0..<length {
            if let jsTrack = jsTracks[i].object {
                tracks.append(MediaStreamTrack(jsTrack: jsTrack))
            }
        }
        return tracks
    }

    /// Video tracks in this stream
    public var videoTracks: [MediaStreamTrack] {
        guard let jsTracks = jsStream.getVideoTracks.call().object else {
            return []
        }
        let length = Int(jsTracks.length.number ?? 0)

        var tracks: [MediaStreamTrack] = []
        for i in 0..<length {
            if let jsTrack = jsTracks[i].object {
                tracks.append(MediaStreamTrack(jsTrack: jsTrack))
            }
        }
        return tracks
    }

    // MARK: - Event Handlers

    private var activeHandlers: [UUID: @Sendable @MainActor () -> Void] = [:]
    private var inactiveHandlers: [UUID: @Sendable @MainActor () -> Void] = [:]
    private var addTrackHandlers: [UUID: @Sendable @MainActor (MediaStreamTrack) -> Void] = [:]
    private var removeTrackHandlers: [UUID: @Sendable @MainActor (MediaStreamTrack) -> Void] = [:]

    private var activeClosure: JSClosure?
    private var inactiveClosure: JSClosure?
    private var addTrackClosure: JSClosure?
    private var removeTrackClosure: JSClosure?

    // MARK: - Initialization

    /// Creates an empty media stream
    public init() {
        guard let stream = JSObject.global.MediaStream.call().object else {
            fatalError("Failed to create MediaStream")
        }
        self.jsStream = stream
        setupEventHandlers()
    }

    /// Creates a media stream from tracks
    ///
    /// - Parameter tracks: Array of media stream tracks
    public init(tracks: [MediaStreamTrack]) {
        guard let jsTracks = JSObject.global.Array.call().object else {
            fatalError("Failed to create array")
        }
        for (index, track) in tracks.enumerated() {
            jsTracks[index] = .object(track.jsTrack)
        }
        guard let stream = JSObject.global.MediaStream.call(jsTracks).object else {
            fatalError("Failed to create MediaStream from tracks")
        }
        self.jsStream = stream
        setupEventHandlers()
    }

    /// Creates a media stream from a JavaScript MediaStream object
    ///
    /// - Parameter jsStream: JavaScript MediaStream object
    internal init(jsStream: JSObject) {
        self.jsStream = jsStream
        setupEventHandlers()
    }

    deinit {
    }

    // MARK: - Event Handler Setup

    private func setupEventHandlers() {
        // Active event
        activeClosure = JSClosure { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                for handler in self.activeHandlers.values {
                    handler()
                }
            }
            return .undefined
        }
        jsStream.onactive = .object(activeClosure!)

        // Inactive event
        inactiveClosure = JSClosure { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                for handler in self.inactiveHandlers.values {
                    handler()
                }
            }
            return .undefined
        }
        jsStream.oninactive = .object(inactiveClosure!)

        // Add track event
        addTrackClosure = JSClosure { [weak self] args in
            Task { @MainActor [weak self] in
                guard let self = self,
                      args.count > 0,
                      let event = args[0].object,
                      let jsTrack = event.track.object else { return }

                let track = MediaStreamTrack(jsTrack: jsTrack)
                for handler in self.addTrackHandlers.values {
                    handler(track)
                }
            }
            return .undefined
        }
        jsStream.onaddtrack = .object(addTrackClosure!)

        // Remove track event
        removeTrackClosure = JSClosure { [weak self] args in
            Task { @MainActor [weak self] in
                guard let self = self,
                      args.count > 0,
                      let event = args[0].object,
                      let jsTrack = event.track.object else { return }

                let track = MediaStreamTrack(jsTrack: jsTrack)
                for handler in self.removeTrackHandlers.values {
                    handler(track)
                }
            }
            return .undefined
        }
        jsStream.onremovetrack = .object(removeTrackClosure!)
    }

    // MARK: - Event Handler Registration

    /// Register handler for stream becoming active
    @discardableResult
    public func onActive(_ handler: @escaping @Sendable @MainActor () -> Void) -> UUID {
        let id = UUID()
        activeHandlers[id] = handler
        return id
    }

    /// Register handler for stream becoming inactive
    @discardableResult
    public func onInactive(_ handler: @escaping @Sendable @MainActor () -> Void) -> UUID {
        let id = UUID()
        inactiveHandlers[id] = handler
        return id
    }

    /// Register handler for track being added
    @discardableResult
    public func onAddTrack(_ handler: @escaping @Sendable @MainActor (MediaStreamTrack) -> Void) -> UUID {
        let id = UUID()
        addTrackHandlers[id] = handler
        return id
    }

    /// Register handler for track being removed
    @discardableResult
    public func onRemoveTrack(_ handler: @escaping @Sendable @MainActor (MediaStreamTrack) -> Void) -> UUID {
        let id = UUID()
        removeTrackHandlers[id] = handler
        return id
    }

    /// Remove a registered event handler
    public func removeHandler(_ id: UUID) {
        activeHandlers.removeValue(forKey: id)
        inactiveHandlers.removeValue(forKey: id)
        addTrackHandlers.removeValue(forKey: id)
        removeTrackHandlers.removeValue(forKey: id)
    }

    // MARK: - Track Management

    /// Add a track to the stream
    ///
    /// - Parameter track: Track to add
    public func addTrack(_ track: MediaStreamTrack) {
        _ = jsStream.addTrack.call(track.jsTrack)
    }

    /// Remove a track from the stream
    ///
    /// - Parameter track: Track to remove
    public func removeTrack(_ track: MediaStreamTrack) {
        _ = jsStream.removeTrack.call(track.jsTrack)
    }

    /// Get a track by ID
    ///
    /// - Parameter trackId: Track identifier
    /// - Returns: Track with matching ID, or nil if not found
    public func getTrackById(_ trackId: String) -> MediaStreamTrack? {
        let jsTrack = jsStream.getTrackById.call(trackId)
        guard !jsTrack.isNull, !jsTrack.isUndefined, let track = jsTrack.object else {
            return nil
        }
        return MediaStreamTrack(jsTrack: track)
    }

    // MARK: - Stream Control

    /// Stop all tracks in the stream
    public func stop() {
        for track in tracks {
            track.stop()
        }
    }

    /// Clone this media stream
    ///
    /// - Returns: New stream with cloned tracks
    public func clone() -> MediaStream {
        guard let clonedStream = jsStream.clone.call().object else {
            fatalError("Failed to clone MediaStream")
        }
        return MediaStream(jsStream: clonedStream)
    }

    // MARK: - Internal Access

    internal var jsObject: JSObject {
        jsStream
    }

    // MARK: - Cleanup

    private func cleanup() {
        activeClosure = nil
        inactiveClosure = nil
        addTrackClosure = nil
        removeTrackClosure = nil

        activeHandlers.removeAll()
        inactiveHandlers.removeAll()
        addTrackHandlers.removeAll()
        removeTrackHandlers.removeAll()
    }
}

// MARK: - Media Stream Track

/// Represents a single media track (audio or video)
@MainActor
public final class MediaStreamTrack: Sendable {
    // MARK: - Properties

    internal let jsTrack: JSObject

    /// Unique identifier for this track
    public var id: String {
        jsTrack.id.string ?? ""
    }

    /// Label describing the track source
    public var label: String {
        jsTrack.label.string ?? ""
    }

    /// Kind of track (audio or video)
    public var kind: TrackKind {
        if let kindString = jsTrack.kind.string {
            return TrackKind(rawValue: kindString) ?? .video
        }
        return .video
    }

    /// Whether the track is enabled
    public var enabled: Bool {
        get { jsTrack.enabled.boolean ?? false }
        set { jsTrack.enabled = .boolean(newValue) }
    }

    /// Whether the track is muted
    public var muted: Bool {
        jsTrack.muted.boolean ?? false
    }

    /// Current state of the track
    public var readyState: TrackState {
        if let stateString = jsTrack.readyState.string {
            return TrackState(rawValue: stateString) ?? .ended
        }
        return .ended
    }

    // MARK: - Initialization

    internal init(jsTrack: JSObject) {
        self.jsTrack = jsTrack
    }

    // MARK: - Control

    /// Stop the track
    public func stop() {
        _ = jsTrack.stop.call()
    }

    /// Clone the track
    ///
    /// - Returns: New track with same source
    public func clone() -> MediaStreamTrack {
        guard let cloned = jsTrack.clone.call().object else {
            fatalError("Failed to clone MediaStreamTrack")
        }
        return MediaStreamTrack(jsTrack: cloned)
    }

    /// Get track capabilities
    ///
    /// - Returns: Dictionary of supported capabilities
    public func getCapabilities() -> [String: Any] {
        guard let capabilities = jsTrack.getCapabilities.call().object else {
            return [:]
        }
        return jsObjectToDictionary(capabilities)
    }

    /// Get current track settings
    ///
    /// - Returns: Dictionary of current settings
    public func getSettings() -> [String: Any] {
        guard let settings = jsTrack.getSettings.call().object else {
            return [:]
        }
        return jsObjectToDictionary(settings)
    }

    // MARK: - Helpers

    private func jsObjectToDictionary(_ obj: JSObject) -> [String: Any] {
        var dict: [String: Any] = [:]
        let keys = JSObject.global.Object.keys(obj)
        let length = Int(keys.length.number ?? 0)

        for i in 0..<length {
            if let key = keys[i].string {
                let value = obj[dynamicMember: key]
                if let string = value.string {
                    dict[key] = string
                } else if let number = value.number {
                    dict[key] = number
                } else if let bool = value.boolean {
                    dict[key] = bool
                }
            }
        }

        return dict
    }
}

// MARK: - Track Kind

extension MediaStreamTrack {
    public enum TrackKind: String, Sendable {
        case audio
        case video
    }

    public enum TrackState: String, Sendable {
        case live
        case ended
    }
}

// MARK: - User Media

extension MediaStream {
    /// Request access to user's camera and/or microphone
    ///
    /// - Parameters:
    ///   - audio: Audio constraints or true to use defaults
    ///   - video: Video constraints or true to use defaults
    /// - Returns: Media stream with requested tracks
    /// - Throws: MediaStreamError if access is denied or not available
    public static func getUserMedia(
        audio: Bool = false,
        video: VideoConstraints? = nil
    ) async throws -> MediaStream {
        guard let constraints = JSObject.global.Object.call().object else {
            throw MediaStreamError.notSupported
        }

        if audio {
            constraints.audio = .boolean(true)
        }

        if let video = video {
            guard let videoConstraints = JSObject.global.Object.call().object else {
                throw MediaStreamError.notSupported
            }

            if let width = video.width {
                videoConstraints.width = .number(Double(width))
            }
            if let height = video.height {
                videoConstraints.height = .number(Double(height))
            }
            if let frameRate = video.frameRate {
                videoConstraints.frameRate = .number(Double(frameRate))
            }
            if let facingMode = video.facingMode {
                videoConstraints.facingMode = .string(facingMode.rawValue)
            }

            constraints.video = .object(videoConstraints)
        } else if video == nil && !audio {
            constraints.video = .boolean(true)
        }

        return try await withCheckedThrowingContinuation { continuation in
            let promise = JSObject.global.navigator.mediaDevices.getUserMedia.call(constraints)

            _ = promise.then.call(JSClosure { args in
                if let stream = args.first?.object {
                    continuation.resume(returning: MediaStream(jsStream: stream))
                } else {
                    continuation.resume(throwing: MediaStreamError.accessDenied)
                }
                return .undefined
            })

            _ = promise.catch.call(JSClosure { args in
                continuation.resume(throwing: MediaStreamError.accessDenied)
                return .undefined
            })
        }
    }

    /// Request access to display media (screen sharing)
    ///
    /// - Parameter video: Video constraints for screen capture
    /// - Returns: Media stream with display media
    /// - Throws: MediaStreamError if access is denied
    public static func getDisplayMedia(
        video: VideoConstraints? = nil
    ) async throws -> MediaStream {
        guard let constraints = JSObject.global.Object.call().object else {
            throw MediaStreamError.notSupported
        }

        if let video = video {
            guard let videoConstraints = JSObject.global.Object.call().object else {
                throw MediaStreamError.notSupported
            }

            if let width = video.width {
                videoConstraints.width = .number(Double(width))
            }
            if let height = video.height {
                videoConstraints.height = .number(Double(height))
            }
            if let frameRate = video.frameRate {
                videoConstraints.frameRate = .number(Double(frameRate))
            }

            constraints.video = .object(videoConstraints)
        } else {
            constraints.video = .boolean(true)
        }

        return try await withCheckedThrowingContinuation { continuation in
            let promise = JSObject.global.navigator.mediaDevices.getDisplayMedia.call(constraints)

            _ = promise.then.call(JSClosure { args in
                if let stream = args.first?.object {
                    continuation.resume(returning: MediaStream(jsStream: stream))
                } else {
                    continuation.resume(throwing: MediaStreamError.accessDenied)
                }
                return .undefined
            })

            _ = promise.catch.call(JSClosure { args in
                continuation.resume(throwing: MediaStreamError.accessDenied)
                return .undefined
            })
        }
    }
}

// MARK: - Video Constraints

/// Constraints for video capture
@MainActor
public struct VideoConstraints: Sendable {
    public var width: Int?
    public var height: Int?
    public var frameRate: Int?
    public var facingMode: FacingMode?

    public init(
        width: Int? = nil,
        height: Int? = nil,
        frameRate: Int? = nil,
        facingMode: FacingMode? = nil
    ) {
        self.width = width
        self.height = height
        self.frameRate = frameRate
        self.facingMode = facingMode
    }

    public enum FacingMode: String, Sendable {
        case user
        case environment
        case left
        case right
    }
}

// MARK: - Errors

public enum MediaStreamError: Error, Sendable {
    case accessDenied
    case notSupported
    case notFound
    case unknown
}
