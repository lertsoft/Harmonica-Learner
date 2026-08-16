import AVFoundation
import Combine
import Foundation

enum NotePlaybackServiceError: LocalizedError {
    case invalidNote
    case noPlayableNotes
    case unableToCreateBuffer
    case unableToStartPlayback

    var errorDescription: String? {
        switch self {
        case .invalidNote:
            return "This note cannot be previewed."
        case .noPlayableNotes:
            return "This song does not contain any playable notes."
        case .unableToCreateBuffer:
            return "A reference tone could not be created."
        case .unableToStartPlayback:
            return "Audio output could not be started."
        }
    }
}

final class NotePlaybackService: ObservableObject {
    @Published private(set) var isPlaying = false
    @Published private(set) var isPlayingSequence = false

    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private let sampleRate = 44_100.0
    private var playbackID = UUID()

    init() {
        engine.attach(player)
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)
        engine.connect(player, to: engine.mainMixerNode, format: format)
    }

    func play(noteName: String, duration: TimeInterval = 0.8) throws {
        guard let frequency = NoteMapper.frequency(for: noteName) else {
            throw NotePlaybackServiceError.invalidNote
        }

        stop()
        guard let buffer = makeBuffer(for: [(frequency, duration)]) else {
            throw NotePlaybackServiceError.unableToCreateBuffer
        }

        try startPlayback(buffer: buffer, sequence: false)
    }

    /// Plays only newly synthesized tones. The imported source recording is not mixed into this cover.
    func play(events: [HarmonicaNoteEvent]) throws {
        let tones = events.compactMap { event -> (Double, TimeInterval)? in
            guard let frequency = NoteMapper.frequency(for: event.note) else { return nil }
            return (frequency, event.duration)
        }
        guard !tones.isEmpty else { throw NotePlaybackServiceError.noPlayableNotes }

        stop()
        guard let buffer = makeBuffer(for: tones) else {
            throw NotePlaybackServiceError.unableToCreateBuffer
        }

        try startPlayback(buffer: buffer, sequence: true)
    }

    private func makeBuffer(for tones: [(frequency: Double, duration: TimeInterval)]) -> AVAudioPCMBuffer? {
        let durations = tones.map { min(2, max(0.25, $0.duration)) }
        let totalFrames = durations.reduce(0) { $0 + Int(sampleRate * $1) }
        guard totalFrames > 0,
              totalFrames <= Int(sampleRate * 240),
              let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1),
              let buffer = AVAudioPCMBuffer(
                pcmFormat: format,
                frameCapacity: AVAudioFrameCount(totalFrames)
              ),
              let samples = buffer.floatChannelData?[0] else { return nil }

        buffer.frameLength = AVAudioFrameCount(totalFrames)
        var writeIndex = 0
        for (toneIndex, tone) in tones.enumerated() {
            let frameCount = Int(sampleRate * durations[toneIndex])
            for frame in 0..<frameCount {
                let time = Double(frame) / sampleRate
                let progress = Double(frame) / Double(max(1, frameCount - 1))
                let attack = min(1, progress / 0.035)
                let release = min(1, (1 - progress) / 0.09)
                let breathPulse = 0.96 + 0.04 * sin(2 * .pi * 5.2 * time)
                let fundamental = sin(2 * .pi * tone.frequency * time)
                let secondHarmonic = 0.24 * sin(2 * .pi * tone.frequency * 2 * time + 0.08)
                let thirdHarmonic = 0.09 * sin(2 * .pi * tone.frequency * 3 * time + 0.17)
                samples[writeIndex + frame] = Float(
                    (fundamental + secondHarmonic + thirdHarmonic) * attack * release * breathPulse * 0.19
                )
            }
            writeIndex += frameCount
        }

        return buffer
    }

    private func startPlayback(buffer: AVAudioPCMBuffer, sequence: Bool) throws {
        try AppAudioSession.activate()

        let currentPlaybackID = UUID()
        playbackID = currentPlaybackID
        player.scheduleBuffer(buffer, at: nil, options: .interrupts) { [weak self] in
            DispatchQueue.main.async {
                guard self?.playbackID == currentPlaybackID else { return }
                self?.isPlaying = false
                self?.isPlayingSequence = false
            }
        }

        engine.prepare()
        if !engine.isRunning {
            do {
                try engine.start()
            } catch {
                player.stop()
                playbackID = UUID()
                throw error
            }
        }

        isPlaying = true
        isPlayingSequence = sequence
        player.play()
        guard player.isPlaying else {
            stop()
            throw NotePlaybackServiceError.unableToStartPlayback
        }
    }

    func stop() {
        playbackID = UUID()
        player.stop()
        isPlaying = false
        isPlayingSequence = false
    }
}
