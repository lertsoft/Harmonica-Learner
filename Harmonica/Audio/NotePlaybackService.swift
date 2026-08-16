import AVFoundation
import Combine
import Foundation

enum NotePlaybackServiceError: LocalizedError {
    case invalidNote
    case unableToCreateBuffer

    var errorDescription: String? {
        switch self {
        case .invalidNote:
            return "This note cannot be previewed."
        case .unableToCreateBuffer:
            return "A reference tone could not be created."
        }
    }
}

final class NotePlaybackService: ObservableObject {
    @Published private(set) var isPlaying = false

    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private let sampleRate = 44_100.0

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
        let safeDuration = min(2, max(0.25, duration))
        let frameCount = AVAudioFrameCount(sampleRate * safeDuration)
        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1),
              let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount),
              let samples = buffer.floatChannelData?[0] else {
            throw NotePlaybackServiceError.unableToCreateBuffer
        }

        buffer.frameLength = frameCount
        for frame in 0..<Int(frameCount) {
            let time = Double(frame) / sampleRate
            let progress = Double(frame) / Double(max(1, Int(frameCount) - 1))
            let envelope = min(1, progress / 0.04) * min(1, (1 - progress) / 0.12)
            let fundamental = sin(2 * .pi * frequency * time)
            let secondHarmonic = 0.18 * sin(2 * .pi * frequency * 2 * time)
            samples[frame] = Float((fundamental + secondHarmonic) * envelope * 0.22)
        }

        if !engine.isRunning {
            try engine.start()
        }

        isPlaying = true
        player.scheduleBuffer(buffer, at: nil, options: .interrupts) { [weak self] in
            DispatchQueue.main.async {
                self?.isPlaying = false
            }
        }
        player.play()
    }

    func stop() {
        player.stop()
        isPlaying = false
    }
}
