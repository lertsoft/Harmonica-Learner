import AVFoundation
import AudioKit
import AudioKitEX
import Combine
import SoundpipeAudioKit

enum AudioEngineServiceError: LocalizedError {
    case noInputNode
    case unableToStartFreestyleRecording
    case unableToStartSongRecording
    case freestyleAudioFileMissing
    case unableToStartFreestylePlayback

    var errorDescription: String? {
        switch self {
        case .noInputNode:
            return "No microphone input is available."
        case .unableToStartFreestyleRecording:
            return "Could not start freestyle recording."
        case .unableToStartSongRecording:
            return "Could not start recording the playing song."
        case .freestyleAudioFileMissing:
            return "Recorded audio file is missing."
        case .unableToStartFreestylePlayback:
            return "Could not play freestyle recording."
        }
    }
}

struct PitchSample: Equatable {
    let frequency: Double
    let amplitude: Double

    static let silence = PitchSample(frequency: 0, amplitude: 0)
}

@MainActor
final class AudioEngineService: NSObject, ObservableObject {
    @Published private(set) var pitchSample: PitchSample = .silence
    @Published private(set) var isRunning: Bool = false
    @Published private(set) var isRecordingFreestyle: Bool = false
    @Published private(set) var isRecordingSong: Bool = false
    @Published private(set) var isPlayingFreestyleAudio: Bool = false

    private lazy var engine = AudioEngine()
    private var tracker: PitchTap?
    private let updateInterval: TimeInterval = 0.05
    private var lastUpdateTime: TimeInterval = 0
    private var graphConfigured = false
    private var isStarting = false

    private var freestyleRecorder: AVAudioRecorder?
    private var songRecorder: AVAudioRecorder?
    private var freestylePlayer: AVAudioPlayer?

    private(set) var lastFreestyleRecordingDuration: TimeInterval = 0
    private(set) var lastSongRecordingDuration: TimeInterval = 0

    var frequency: Double { pitchSample.frequency }
    var amplitude: Double { pitchSample.amplitude }

    override init() {
        super.init()
    }

    func requestPermission(completion: @escaping @MainActor @Sendable (Bool) -> Void) {
        let handlePermission: @Sendable (Bool) -> Void = { granted in
            Task { @MainActor in
                completion(granted)
            }
        }

        if #available(iOS 17.0, *) {
            AVAudioApplication.requestRecordPermission(completionHandler: handlePermission)
        } else {
            AVAudioSession.sharedInstance().requestRecordPermission(handlePermission)
        }
    }

    @MainActor
    func start() async throws {
        guard !isRunning, !isStarting else { return }
        isStarting = true
        defer { isStarting = false }

        try await configureAudioSession()
        guard !isRunning else { return }
        if !graphConfigured {
            let outputFormat = engine.avEngine.outputNode.inputFormat(forBus: 0)
            engine.outputAudioFormat = outputFormat

            guard let input = engine.input else {
                throw AudioEngineServiceError.noInputNode
            }
            // PitchTap derives its sample rate from AudioKit's default settings.
            // Retain the input mixer's default format so its resampling agrees
            // with the tracker, including iOS 17's 44.1 kHz default.
            let mixer = Mixer(input)
            mixer.outputFormat = outputFormat
            engine.output = mixer

            tracker = PitchTap(input) { [weak self] pitches, amplitudes in
                let now = Date().timeIntervalSinceReferenceDate
                let frequency = Double(pitches.first ?? 0)
                let amplitude = Double(amplitudes.first ?? 0)
                Task { @MainActor [weak self] in
                    guard let self, self.isRunning,
                          now - self.lastUpdateTime >= self.updateInterval else { return }
                    self.lastUpdateTime = now
                    self.pitchSample = PitchSample(frequency: frequency, amplitude: amplitude)
                }
            }

            logAudioFormats(input: input)
            graphConfigured = true
        }

        if !engine.avEngine.isRunning {
            try engine.start()
        }
        tracker?.start()
        isRunning = true
    }

    func stop() {
        guard isRunning else { return }
        tracker?.stop()
        isRunning = false
    }

    @MainActor
    func startFreestyleRecording(to url: URL) async throws {
        guard !isRecordingFreestyle else { return }
        try await configureAudioSession()
        guard !isRecordingFreestyle else { return }
        stopFreestyleAudio()

        let directory = url.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        if FileManager.default.fileExists(atPath: url.path) {
            try? FileManager.default.removeItem(at: url)
        }

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44_100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        let recorder = try AVAudioRecorder(url: url, settings: settings)
        recorder.prepareToRecord()

        guard recorder.record() else {
            throw AudioEngineServiceError.unableToStartFreestyleRecording
        }

        freestyleRecorder = recorder
        isRecordingFreestyle = true
        lastFreestyleRecordingDuration = 0
    }

    func stopFreestyleRecording() throws {
        guard let recorder = freestyleRecorder else { return }
        lastFreestyleRecordingDuration = recorder.currentTime
        recorder.stop()
        freestyleRecorder = nil
        isRecordingFreestyle = false
    }

    @MainActor
    func startSongRecording(to url: URL) async throws {
        guard !isRecordingSong else { return }
        // Release the live input graph so it cannot monitor microphone audio
        // through the speaker while the song recorder is capturing it.
        stop()
        engine.stop()
        try await configureAudioSession()
        try Task.checkCancellation()
        guard !isRecordingSong else { return }
        stopFreestyleAudio()

        let directory = url.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        if FileManager.default.fileExists(atPath: url.path) {
            try FileManager.default.removeItem(at: url)
        }

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44_100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        let recorder = try AVAudioRecorder(url: url, settings: settings)
        recorder.prepareToRecord()
        guard recorder.record() else {
            throw AudioEngineServiceError.unableToStartSongRecording
        }
        songRecorder = recorder
        lastSongRecordingDuration = 0
        isRecordingSong = true
    }

    func stopSongRecording() {
        guard let recorder = songRecorder else { return }
        lastSongRecordingDuration = recorder.currentTime
        recorder.stop()
        songRecorder = nil
        isRecordingSong = false
    }

    @MainActor
    func playFreestyleAudio(from url: URL) async throws {
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw AudioEngineServiceError.freestyleAudioFileMissing
        }

        stopFreestyleAudio()
        try await AppAudioSession.activate()

        let player = try AVAudioPlayer(contentsOf: url)
        player.delegate = self
        guard player.prepareToPlay() else {
            throw AudioEngineServiceError.unableToStartFreestylePlayback
        }

        // Retain the player before starting it so its audio queue cannot be released
        // during the transition out of a system importer or media picker.
        freestylePlayer = player

        guard player.play() else {
            freestylePlayer = nil
            throw AudioEngineServiceError.unableToStartFreestylePlayback
        }

        isPlayingFreestyleAudio = true
    }

    func stopFreestyleAudio() {
        freestylePlayer?.stop()
        freestylePlayer = nil
        isPlayingFreestyleAudio = false
    }

    private func configureAudioSession() async throws {
        try await AppAudioSession.activate(configureInput: true)
    }

    private func logAudioFormats(input: Node) {
        let session = AVAudioSession.sharedInstance()
        let inputFormat = input.avAudioNode.inputFormat(forBus: 0)
        let outputFormat = engine.output?.avAudioNode.outputFormat(forBus: 0)
        let outputNodeInput = engine.avEngine.outputNode.inputFormat(forBus: 0)
        let outputNodeOutput = engine.avEngine.outputNode.outputFormat(forBus: 0)
        print("AudioSession sampleRate=\(session.sampleRate) trackerSampleRate=\(input.avAudioNode.outputFormat(forBus: 0).sampleRate) inputChannels=\(inputFormat.channelCount) inputInterleaved=\(inputFormat.isInterleaved) outputChannels=\(outputFormat?.channelCount ?? 0) outputInterleaved=\(outputFormat?.isInterleaved ?? false)")
        print("OutputNode inputChannels=\(outputNodeInput.channelCount) inputInterleaved=\(outputNodeInput.isInterleaved) outputChannels=\(outputNodeOutput.channelCount) outputInterleaved=\(outputNodeOutput.isInterleaved)")
    }
}

extension AudioEngineService: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.freestylePlayer = nil
            self.isPlayingFreestyleAudio = false
        }
    }
}
