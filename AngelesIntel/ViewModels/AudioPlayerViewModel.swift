import Foundation
import AVFoundation
import Combine
import TelemetryDeck
import CoreMedia
import MediaToolbox

enum AudioStream: String, CaseIterable {
    case forestNet = "Forest Net"
    case adminNet = "Admin Net"

    var url: URL {
        switch self {
        case .forestNet: return URL(string: "https://icecast.landmark717.com/anf-forest-net")!
        case .adminNet: return URL(string: "https://icecast.landmark717.com/anf-admin-net")!
        }
    }

    var requiresAuth: Bool {
        self == .adminNet
    }
}

// MARK: - MeterBox (heap-allocated state for C callback)

final class MeterBox {
    // Written from the audio thread, read from the main thread.
    // Float reads/writes are atomic on ARM64.
    var currentLevel: Float = 0.0
}

// MARK: - StreamPlayer

class StreamPlayer {
    let stream: AudioStream
    var player: AVPlayer?
    var playerItem: AVPlayerItem?
    var statusObserver: AnyCancellable?
    var meterBox: MeterBox?

    init(stream: AudioStream) {
        self.stream = stream
    }

    func tearDown() {
        player?.pause()
        player = nil
        playerItem = nil
        statusObserver = nil
        meterBox?.currentLevel = 0.0
        meterBox = nil
    }
}

// MARK: - AudioPlayerViewModel

class AudioPlayerViewModel: ObservableObject {
    @Published var streamStates: [AudioStream: StreamState] = [
        .forestNet: .stopped,
        .adminNet: .stopped,
    ]
    // Non-published — raw levels updated 10x/sec, only threshold crossings trigger UI updates
    var levels: [AudioStream: Float] = [
        .forestNet: 0.0,
        .adminNet: 0.0,
    ]
    @Published var hotStreams: Set<AudioStream> = []
    @Published var playStartedAt: [AudioStream: Date] = [:]

    enum StreamState: Equatable {
        case stopped
        case loading
        case playing
        case buffering
        case error(String)
    }

    /// -30 dBFS threshold: 10^(-30/20) ≈ 0.03162
    static let levelThreshold: Float = 0.03162

    private var players: [AudioStream: StreamPlayer] = [:]
    private var stallObservers: [AudioStream: AnyCancellable] = [:]
    private var bufferObservers: [AudioStream: AnyCancellable] = [:]
    private var meterTimer: Timer?

    var anyPlaying: Bool {
        streamStates.values.contains(.playing)
    }

    init() {
        configureAudioSession()
    }

    private func configureAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: .mixWithOthers)
            try session.setActive(true)
        } catch {
            // Best-effort
        }
    }

    private func startMeterTimerIfNeeded() {
        guard meterTimer == nil, anyPlaying else { return }
        meterTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self else { return }
            DispatchQueue.main.async {
                var newHot = Set<AudioStream>()
                for stream in AudioStream.allCases {
                    self.levels[stream] = self.players[stream]?.meterBox?.currentLevel ?? 0.0
                    if (self.levels[stream] ?? 0) > Self.levelThreshold {
                        newHot.insert(stream)
                    }
                }
                if newHot != self.hotStreams {
                    self.hotStreams = newHot
                }
            }
        }
    }

    private func stopMeterTimerIfIdle() {
        guard !anyPlaying else { return }
        meterTimer?.invalidate()
        meterTimer = nil
    }

    func isPlaying(_ stream: AudioStream) -> Bool {
        streamStates[stream] == .playing
    }

    func isLoading(_ stream: AudioStream) -> Bool {
        streamStates[stream] == .loading
    }

    func errorMessage(for stream: AudioStream) -> String? {
        if case .error(let msg) = streamStates[stream] { return msg }
        return nil
    }

    func isAboveThreshold(_ stream: AudioStream) -> Bool {
        hotStreams.contains(stream)
    }

    func play(_ stream: AudioStream) {
        guard streamStates[stream] != .playing, streamStates[stream] != .loading else { return }

        streamStates[stream] = .loading

        let sp = StreamPlayer(stream: stream)
        sp.playerItem = AVPlayerItem(url: stream.url)
        sp.meterBox = Self.installMeterTap(on: sp.playerItem!)
        sp.player = AVPlayer(playerItem: sp.playerItem)

        sp.statusObserver = sp.playerItem?.publisher(for: \.status)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                guard let self else { return }
                switch status {
                case .readyToPlay:
                    sp.player?.play()
                    self.streamStates[stream] = .playing
                    self.playStartedAt[stream] = Date()
                    self.retryCount[stream] = nil
                    self.startMeterTimerIfNeeded()
                    TelemetryDeck.signal("Audio.streamStarted", parameters: ["stream": stream.rawValue])
                case .failed:
                    self.retryStream(stream)
                default:
                    break
                }
            }

        // Observe playback stalls
        stallObservers[stream] = NotificationCenter.default.publisher(for: .AVPlayerItemPlaybackStalled, object: sp.playerItem)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self else { return }
                self.streamStates[stream] = .buffering
                self.retryStream(stream)
            }

        // Observe buffer empty → buffering, buffer ready → resume
        bufferObservers[stream] = sp.playerItem?.publisher(for: \.isPlaybackLikelyToKeepUp)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] likelyToKeepUp in
                guard let self else { return }
                if likelyToKeepUp, self.streamStates[stream] == .buffering {
                    sp.player?.play()
                    self.streamStates[stream] = .playing
                }
            }

        players[stream] = sp
    }

    func stop(_ stream: AudioStream) {
        stallObservers[stream] = nil
        bufferObservers[stream] = nil
        players[stream]?.tearDown()
        players[stream] = nil
        retryCount[stream] = nil
        streamStates[stream] = .stopped
        playStartedAt[stream] = nil
        levels[stream] = 0.0
        hotStreams.remove(stream)
        stopMeterTimerIfIdle()
    }

    func toggle(_ stream: AudioStream) {
        if isPlaying(stream) || isLoading(stream) {
            stop(stream)
        } else {
            play(stream)
        }
    }

    private var retryCount: [AudioStream: Int] = [:]

    private func retryStream(_ stream: AudioStream) {
        guard streamStates[stream] != .stopped else {
            retryCount[stream] = nil
            return
        }
        streamStates[stream] = .buffering
        stallObservers[stream] = nil
        bufferObservers[stream] = nil
        players[stream]?.tearDown()
        players[stream] = nil

        let attempt = (retryCount[stream] ?? 0) + 1
        retryCount[stream] = attempt
        let delay = min(Double(attempt) * 3, 30)

        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            guard let self, self.streamStates[stream] == .buffering else { return }
            self.streamStates[stream] = .stopped
            self.play(stream)
        }
    }

    func stopAll() {
        for stream in AudioStream.allCases {
            stop(stream)
        }
    }

    // MARK: - MTAudioProcessingTap

    private static func installMeterTap(on item: AVPlayerItem) -> MeterBox {
        let box = MeterBox()
        let boxPtr = Unmanaged.passRetained(box)

        var callbacks = MTAudioProcessingTapCallbacks(
            version: kMTAudioProcessingTapCallbacksVersion_0,
            clientInfo: boxPtr.toOpaque(),
            init: { _, clientInfo, tapStorageOut in
                tapStorageOut.pointee = clientInfo
            },
            finalize: { tap in
                let ptr = MTAudioProcessingTapGetStorage(tap)
                Unmanaged<MeterBox>.fromOpaque(ptr).release()
            },
            prepare: nil,
            unprepare: nil,
            process: { tap, numberFrames, flags, bufferListInOut, numberFramesOut, flagsOut in
                MTAudioProcessingTapGetSourceAudio(tap, numberFrames, bufferListInOut, flagsOut, nil, numberFramesOut)

                let ptr = MTAudioProcessingTapGetStorage(tap)
                let box = Unmanaged<MeterBox>.fromOpaque(ptr).takeUnretainedValue()

                var sumOfSquares: Float = 0.0
                var sampleCount: Int = 0
                let bufCount = Int(bufferListInOut.pointee.mNumberBuffers)
                for bufIdx in 0..<bufCount {
                    withUnsafeMutablePointer(to: &bufferListInOut.pointee.mBuffers) { base in
                        let buf = (base + bufIdx).pointee
                        guard let data = buf.mData else { return }
                        let frames = Int(buf.mDataByteSize) / MemoryLayout<Float>.size
                        let samples = data.bindMemory(to: Float.self, capacity: frames)
                        if buf.mNumberChannels == 2 || bufIdx == 0 {
                            for i in 0..<frames { sumOfSquares += samples[i] * samples[i] }
                            sampleCount += frames
                        }
                    }
                }
                box.currentLevel = sampleCount > 0 ? sqrtf(sumOfSquares / Float(sampleCount)) : 0.0
            }
        )

        var tapOut: MTAudioProcessingTap? = nil
        let status = MTAudioProcessingTapCreate(kCFAllocatorDefault, &callbacks, kMTAudioProcessingTapCreationFlag_PreEffects, &tapOut)
        guard status == noErr, let tap = tapOut else {
            boxPtr.release()
            return box
        }

        let params = AVMutableAudioMixInputParameters()
        params.audioTapProcessor = tap
        params.trackID = CMPersistentTrackID(kCMPersistentTrackID_Invalid)

        let mix = AVMutableAudioMix()
        mix.inputParameters = [params]
        item.audioMix = mix

        return box
    }
}
