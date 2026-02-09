import AVFoundation
import AudioKit
import AudioKitEX
import Combine
import SoundpipeAudioKit

enum AudioEngineServiceError: LocalizedError {
    case noInputNode
    case unableToStartFreestyleRecording
    case freestyleAudioFileMissing
    case unableToStartFreestylePlayback

    var errorDescription: String? {
        switch self {
        case .noInputNode:
            return "No microphone input is available."
        case .unableToStartFreestyleRecording:
            return "Could not start freestyle recording."
        case .freestyleAudioFileMissing:
            return "Recorded audio file is missing."
        case .unableToStartFreestylePlayback:
            return "Could not play freestyle recording."
        }
    }
}

final class AudioEngineService: NSObject, ObservableObject {
    @Published private(set) var frequency: Double = 0
    @Published private(set) var amplitude: Double = 0
    @Published private(set) var isRunning: Bool = false
    @Published private(set) var isRecordingFreestyle: Bool = false
    @Published private(set) var isPlayingFreestyleAudio: Bool = false

    private lazy var engine = AudioEngine()
    private var tracker: PitchTap?
    private let updateInterval: TimeInterval = 0.05
    private var lastUpdateTime: TimeInterval = 0
    private var sessionConfigured = false
    private var graphConfigured = false

    private var freestyleRecorder: AVAudioRecorder?
    private var freestylePlayer: AVAudioPlayer?

    private(set) var lastFreestyleRecordingDuration: TimeInterval = 0

    override init() {
        super.init()
    }

    func requestPermission(completion: @escaping (Bool) -> Void) {
        let handlePermission: (Bool) -> Void = { granted in
            DispatchQueue.main.async {
                completion(granted)
            }
        }

        if #available(iOS 17.0, *) {
            AVAudioApplication.requestRecordPermission(completionHandler: handlePermission)
        } else {
            AVAudioSession.sharedInstance().requestRecordPermission(handlePermission)
        }
    }

    func start() throws {
        guard !isRunning else { return }
        try configureAudioSession()
        if !graphConfigured {
            let outputFormat = engine.avEngine.outputNode.inputFormat(forBus: 0)
            Settings.audioFormat = outputFormat
            engine.outputAudioFormat = outputFormat

            guard let input = engine.input else {
                throw AudioEngineServiceError.noInputNode
            }
            let mixer = Mixer(input)
            mixer.outputFormat = outputFormat
            engine.output = mixer

            tracker = PitchTap(input) { [weak self] pitches, amplitudes in
                guard let self else { return }
                let now = Date().timeIntervalSinceReferenceDate
                guard now - self.lastUpdateTime >= self.updateInterval else { return }
                self.lastUpdateTime = now

                let frequency = Double(pitches.first ?? 0)
                let amplitude = Double(amplitudes.first ?? 0)
                DispatchQueue.main.async {
                    self.frequency = frequency
                    self.amplitude = amplitude
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

    func startFreestyleRecording(to url: URL) throws {
        try configureAudioSession()
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
        recorder.stop()
        lastFreestyleRecordingDuration = recorder.currentTime
        freestyleRecorder = nil
        isRecordingFreestyle = false
    }

    func playFreestyleAudio(from url: URL) throws {
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw AudioEngineServiceError.freestyleAudioFileMissing
        }

        stopFreestyleAudio()

        let player = try AVAudioPlayer(contentsOf: url)
        player.delegate = self

        guard player.play() else {
            throw AudioEngineServiceError.unableToStartFreestylePlayback
        }

        freestylePlayer = player
        isPlayingFreestyleAudio = true
    }

    func stopFreestyleAudio() {
        freestylePlayer?.stop()
        freestylePlayer = nil
        isPlayingFreestyleAudio = false
    }

    private func configureAudioSession() throws {
        let session = AVAudioSession.sharedInstance()
        if !sessionConfigured {
            try session.setCategory(.playAndRecord, mode: .measurement, options: [.defaultToSpeaker])
            _ = try? session.setPreferredInputNumberOfChannels(1)
            _ = try? session.setPreferredOutputNumberOfChannels(2)
            _ = try? session.setPreferredSampleRate(48_000)
            _ = try? session.setPreferredIOBufferDuration(0.01)
            sessionConfigured = true
        }
        try session.setActive(true)
    }

    private func logAudioFormats(input: Node) {
        let session = AVAudioSession.sharedInstance()
        let inputFormat = input.avAudioNode.inputFormat(forBus: 0)
        let outputFormat = engine.output?.avAudioNode.outputFormat(forBus: 0)
        let outputNodeInput = engine.avEngine.outputNode.inputFormat(forBus: 0)
        let outputNodeOutput = engine.avEngine.outputNode.outputFormat(forBus: 0)
        print("AudioSession sampleRate=\(session.sampleRate) inputChannels=\(inputFormat.channelCount) inputInterleaved=\(inputFormat.isInterleaved) outputChannels=\(outputFormat?.channelCount ?? 0) outputInterleaved=\(outputFormat?.isInterleaved ?? false)")
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
