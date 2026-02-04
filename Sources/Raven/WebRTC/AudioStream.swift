import Foundation
import JavaScriptKit

/// Provides controls for audio stream capture and playback
///
/// AudioStream simplifies working with audio tracks, providing volume control,
/// muting, and audio context integration for advanced processing.
///
/// ## Example Usage
///
/// ```swift
/// // Create audio stream from microphone
/// let audioStream = try await AudioStream.fromMicrophone()
///
/// // Control volume
/// audioStream.volume = 0.5
///
/// // Mute/unmute
/// audioStream.isMuted = true
///
/// // Stop when done
/// audioStream.stop?()
/// ```
@MainActor
public final class AudioStream: Sendable {
    // MARK: - Properties

    /// The underlying media stream containing audio tracks
    public let mediaStream: MediaStream

    /// Current volume level (0.0 to 1.0)
    public var volume: Double {
        get { _volume }
        set {
            _volume = max(0.0, min(1.0, newValue))
            updateGainNode()
        }
    }

    /// Whether the audio is muted
    public var isMuted: Bool {
        didSet {
            for track in mediaStream.audioTracks {
                track.enabled = !isMuted
            }
        }
    }

    /// Audio context for processing
    private var audioContext: JSObject?

    /// Gain node for volume control
    private var gainNode: JSObject?

    /// Source node connected to stream
    private var sourceNode: JSObject?

    /// Current volume value
    private var _volume: Double = 1.0

    // MARK: - Initialization

    /// Creates an audio stream from a media stream
    ///
    /// - Parameter mediaStream: Media stream containing audio tracks
    public init(mediaStream: MediaStream) {
        self.mediaStream = mediaStream
        self.isMuted = false
        setupAudioProcessing()
    }

    /// Creates an audio stream from audio tracks
    ///
    /// - Parameter tracks: Array of audio tracks
    /// - Throws: MediaStreamError if stream creation fails
    public init(tracks: [MediaStreamTrack]) throws {
        self.mediaStream = try MediaStream(tracks: tracks)
        self.isMuted = false
        setupAudioProcessing()
    }

    deinit {
    }

    // MARK: - Audio Processing Setup

    private func setupAudioProcessing() {
        // Create audio context if available
        guard let audioContextConstructor = JSObject.global.AudioContext.function
            ?? JSObject.global.webkitAudioContext.function else {
            return
        }

        audioContext = audioContextConstructor().object

        guard let context = audioContext else { return }

        // Create gain node for volume control
        gainNode = context.createGain?().object

        // Create media stream source
        sourceNode = context.createMediaStreamSource.call(mediaStream.jsObject).object

        // Connect nodes: source -> gain -> destination
        if let source = sourceNode, let gain = gainNode {
            _ = source.connect.call(gain)
            _ = gain.connect.call(context.destination)
        }

        updateGainNode()
    }

    private func updateGainNode() {
        guard let gain = gainNode else { return }
        gain.gain.value = .number(_volume)
    }

    // MARK: - Factory Methods

    /// Create audio stream from microphone
    ///
    /// - Parameter constraints: Optional audio constraints
    /// - Returns: Audio stream from microphone
    /// - Throws: MediaStreamError if microphone access fails
    public static func fromMicrophone() async throws -> AudioStream {
        let stream = try await MediaStream.getUserMedia(audio: true, video: nil)
        return AudioStream(mediaStream: stream)
    }

    /// Create audio stream from audio element
    ///
    /// - Parameter element: HTML audio element
    /// - Returns: Audio stream from the element
    public static func fromElement(_ element: JSObject) -> AudioStream? {
        // Check if AudioContext is available
        guard let audioContextConstructor = JSObject.global.AudioContext.function
            ?? JSObject.global.webkitAudioContext.function else {
            return nil
        }

        guard let context = audioContextConstructor().object else {
            return nil
        }

        // Create media element source
        guard let source = context.createMediaElementSource.call(element).object,
              let _ = context.destination.object else {
            return nil
        }

        // Create a media stream from destination
        guard let streamDestination = context.createMediaStreamDestination.call().object,
              let stream = streamDestination.stream.object else {
            return nil
        }

        // Connect source to stream destination
        _ = source.connect.call(streamDestination)

        return AudioStream(mediaStream: MediaStream(jsStream: stream))
    }

    // MARK: - Audio Control

    /// Stop all audio tracks
    public func stop() {
        mediaStream.stop()
        cleanup()
    }

    /// Pause audio playback
    public func pause() {
        isMuted = true
    }

    /// Resume audio playback
    public func resume() {
        isMuted = false
    }

    /// Get audio level (volume) from the stream
    ///
    /// - Returns: Current audio level (0.0 to 1.0)
    public func getAudioLevel() -> Double {
        guard let context = audioContext,
              let source = sourceNode else {
            return 0.0
        }

        // Create analyser node if needed
        let analyser = context.createAnalyser.call().object!
        _ = source.connect.call(analyser)

        analyser.fftSize = .number(256)
        let bufferLength = Int(analyser.frequencyBinCount.number ?? 0)

        let dataArray = JSObject.global.Uint8Array.call(bufferLength)
        _ = analyser.getByteFrequencyData.call(dataArray)

        // Calculate average volume
        var sum: Double = 0
        for i in 0..<bufferLength {
            sum += dataArray[i].number ?? 0
        }

        let average = sum / Double(bufferLength)
        return average / 255.0
    }

    // MARK: - Advanced Processing

    /// Apply audio filter
    ///
    /// - Parameter filterType: Type of filter to apply
    /// - Parameter frequency: Filter frequency in Hz
    public func applyFilter(type filterType: FilterType, frequency: Double) {
        guard let context = audioContext,
              let source = sourceNode,
              let destination = gainNode else {
            return
        }

        // Create biquad filter
        let filter = context.createBiquadFilter.call().object!
        filter.type = .string(filterType.rawValue)
        filter.frequency.value = .number(frequency)

        // Reconnect: source -> filter -> gain
        _ = source.disconnect.call()
        _ = source.connect.call(filter)
        _ = filter.connect.call(destination)
    }

    /// Remove all audio filters
    public func removeFilters() {
        guard let source = sourceNode, let destination = gainNode else {
            return
        }

        // Reconnect directly: source -> gain
        _ = source.disconnect.call()
        _ = source.connect.call(destination)
    }

    // MARK: - Audio Tracks

    /// All audio tracks in the stream
    public var tracks: [MediaStreamTrack] {
        mediaStream.audioTracks
    }

    /// Add an audio track
    ///
    /// - Parameter track: Track to add
    public func addTrack(_ track: MediaStreamTrack) {
        guard track.kind == .audio else { return }
        mediaStream.addTrack(track)
    }

    /// Remove an audio track
    ///
    /// - Parameter track: Track to remove
    public func removeTrack(_ track: MediaStreamTrack) {
        mediaStream.removeTrack(track)
    }

    // MARK: - Cleanup

    private func cleanup() {
        if let context = audioContext {
            _ = context.close?()
        }

        audioContext = nil
        gainNode = nil
        sourceNode = nil
    }
}

// MARK: - Filter Type

extension AudioStream {
    /// Audio filter types
    public enum FilterType: String, Sendable {
        /// Low-pass filter
        case lowpass

        /// High-pass filter
        case highpass

        /// Band-pass filter
        case bandpass

        /// Low-shelf filter
        case lowshelf

        /// High-shelf filter
        case highshelf

        /// Peaking filter
        case peaking

        /// Notch filter
        case notch

        /// All-pass filter
        case allpass
    }
}

// MARK: - Audio Recorder

/// Records audio stream to downloadable file
@MainActor
public final class AudioRecorder: Sendable {
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

    /// Creates audio recorder for a stream
    ///
    /// - Parameters:
    ///   - stream: Audio stream to record
    ///   - mimeType: MIME type for recording (e.g., "audio/webm")
    /// - Throws: AudioRecorderError if MediaRecorder is not supported
    public init(stream: AudioStream, mimeType: String = "audio/webm") throws {
        guard let mediaRecorderConstructor = JSObject.global.MediaRecorder.function else {
            throw AudioRecorderError.notSupported
        }

        guard let options = JSObject.global.Object.call().object else {
            throw AudioRecorderError.notSupported
        }
        options.mimeType = JSValue.string(mimeType)

        guard let recorder = mediaRecorderConstructor(stream.mediaStream.jsObject, options).object else {
            throw AudioRecorderError.notSupported
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
    public func start() {
        recordedChunks.removeAll()
        _ = mediaRecorder.start.call()
    }

    /// Stop recording and get the recorded data
    ///
    /// - Returns: Recorded audio data as Data
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

    // MARK: - Cleanup

    private func cleanup() {
        dataAvailableClosure = nil
        stopClosure = nil
        recordedChunks.removeAll()
    }
}

// MARK: - Errors

public enum AudioRecorderError: Error, Sendable {
    case notSupported
    case recordingFailed
}
