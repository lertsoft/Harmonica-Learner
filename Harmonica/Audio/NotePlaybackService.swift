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

@MainActor
final class NotePlaybackService: ObservableObject {
    @Published private(set) var isPlaying = false
    @Published private(set) var isPlayingSequence = false

    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private let sampleRate = 44_100.0
    private var playbackID = UUID()
    private var sequenceTones: [(frequency: Double, duration: TimeInterval)] = []
    private var sequenceToneIndex = 0
    private var sequenceFrameOffset = 0
    private var sequenceBuffersInFlight = 0

    init() {
        engine.attach(player)
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)
        engine.connect(player, to: engine.mainMixerNode, format: format)
    }

    @MainActor
    func play(noteName: String, duration: TimeInterval = 0.8) async throws {
        guard let frequency = NoteMapper.frequency(for: noteName) else {
            throw NotePlaybackServiceError.invalidNote
        }

        stop()
        guard let buffer = makeBuffer(for: [(frequency, duration)]) else {
            throw NotePlaybackServiceError.unableToCreateBuffer
        }

        try await startPlayback(buffer: buffer, sequence: false)
    }

    /// Plays only newly synthesized tones. The imported source recording is not mixed into this cover.
    @MainActor
    func play(events: [HarmonicaNoteEvent]) async throws {
        let tones = Self.coverTones(for: events)
        guard !tones.isEmpty else { throw NotePlaybackServiceError.noPlayableNotes }
        stop()
        let currentPlaybackID = UUID()
        playbackID = currentPlaybackID
        try await AppAudioSession.activate()
        guard playbackID == currentPlaybackID else { return }
        sequenceTones = tones
        sequenceToneIndex = 0
        sequenceFrameOffset = 0
        sequenceBuffersInFlight = 0
        // Bound memory to three half-second buffers, including for long imported songs.
        for _ in 0..<3 { scheduleNextSequenceBuffer(playbackID: currentPlaybackID) }
        guard sequenceBuffersInFlight > 0 else { throw NotePlaybackServiceError.unableToCreateBuffer }
        engine.prepare()
        do {
            if !engine.isRunning { try engine.start() }
        } catch {
            stop()
            throw error
        }
        isPlaying = true
        isPlayingSequence = true
        player.play()
        guard player.isPlaying else {
            stop()
            throw NotePlaybackServiceError.unableToStartPlayback
        }
    }

    /// A zero-frequency segment is a rest. Source timestamps retain gaps; very fast
    /// arpeggios expand the playable timeline rather than dropping their chord tones.
    nonisolated static func coverTones(for events: [HarmonicaNoteEvent]) -> [(frequency: Double, duration: TimeInterval)] {
        var tones: [(frequency: Double, duration: TimeInterval)] = []
        var sourceCursor = 0.0
        for event in events {
            guard event.duration.isFinite, event.duration > 0,
                  let frequency = NoteMapper.frequency(for: event.note) else { continue }
            if let start = event.startTime, start.isFinite, start > sourceCursor {
                tones.append((0, start - sourceCursor))
            }
            tones.append((frequency, event.duration))
            let sourceDuration = event.sourceDuration.flatMap { $0.isFinite && $0 > 0 ? $0 : nil } ?? event.duration
            sourceCursor = max(sourceCursor, event.startTime ?? sourceCursor) + sourceDuration
        }
        return tones
    }

    @MainActor
    private func scheduleNextSequenceBuffer(playbackID currentPlaybackID: UUID) {
        guard playbackID == currentPlaybackID, sequenceToneIndex < sequenceTones.count,
              let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1),
              let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(sampleRate / 2)),
              let samples = buffer.floatChannelData?[0] else { return }
        var written = 0
        let capacity = Int(buffer.frameCapacity)
        while written < capacity, sequenceToneIndex < sequenceTones.count {
            let tone = sequenceTones[sequenceToneIndex]
            let toneFrames = max(1, Int(min(tone.duration, Double(Int.max / 2) / sampleRate) * sampleRate))
            let count = min(capacity - written, toneFrames - sequenceFrameOffset)
            for frame in 0..<count {
                let offset = sequenceFrameOffset + frame
                let time = Double(offset) / sampleRate
                let attack = min(1, time / 0.008)
                let release = min(1, Double(toneFrames - offset - 1) / sampleRate / 0.015)
                samples[written + frame] = tone.frequency == 0 ? 0 : Float(
                    (sin(2 * .pi * tone.frequency * time)
                     + 0.24 * sin(2 * .pi * tone.frequency * 2 * time + 0.08)
                     + 0.09 * sin(2 * .pi * tone.frequency * 3 * time + 0.17))
                    * attack * release * (0.96 + 0.04 * sin(2 * .pi * 5.2 * time)) * 0.19
                )
            }
            written += count
            sequenceFrameOffset += count
            if sequenceFrameOffset >= toneFrames {
                sequenceToneIndex += 1
                sequenceFrameOffset = 0
            }
        }
        buffer.frameLength = AVAudioFrameCount(written)
        sequenceBuffersInFlight += 1
        player.scheduleBuffer(buffer, completionCallbackType: .dataPlayedBack) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self, self.playbackID == currentPlaybackID else { return }
                self.sequenceBuffersInFlight -= 1
                self.scheduleNextSequenceBuffer(playbackID: currentPlaybackID)
                if self.sequenceBuffersInFlight == 0 {
                    self.isPlaying = false
                    self.isPlayingSequence = false
                    self.sequenceTones = []
                }
            }
        }
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

    @MainActor
    private func startPlayback(buffer: AVAudioPCMBuffer, sequence: Bool) async throws {
        let currentPlaybackID = UUID()
        playbackID = currentPlaybackID
        try await AppAudioSession.activate()
        guard playbackID == currentPlaybackID else { return }

        schedule(buffer, playbackID: currentPlaybackID)

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

    private func schedule(_ buffer: AVAudioPCMBuffer, playbackID currentPlaybackID: UUID) {
        player.scheduleBuffer(buffer, at: nil, options: .interrupts) { [weak self] in
            Task { @MainActor [weak self] in
                guard self?.playbackID == currentPlaybackID else { return }
                self?.isPlaying = false
                self?.isPlayingSequence = false
            }
        }
    }

    func stop() {
        playbackID = UUID()
        player.stop()
        sequenceTones = []
        sequenceBuffersInFlight = 0
        isPlaying = false
        isPlayingSequence = false
    }
}
