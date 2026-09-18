import AVFoundation
import Accelerate
import Foundation

struct ImportedSongAnalysis {
    let notes: [HarmonicaNoteEvent]
    let duration: TimeInterval
    let usedFallback: Bool
}

enum ImportedSongAnalyzerError: LocalizedError, Equatable {
    case unreadableAudio
    case cancelled

    var errorDescription: String? {
        switch self {
        case .unreadableAudio:
            return "The selected audio file could not be read."
        case .cancelled:
            return "Song analysis was cancelled."
        }
    }
}

/// Produces a compact, playable harmonica line from the dominant pitches in an audio file.
/// Polyphonic mixes are intentionally treated as suggestions rather than exact transcription.
struct ImportedSongAnalyzer {
    private let analysisSampleRate = 11_025.0
    private let maximumAnalysisDuration: TimeInterval = 180
    private let windowFrameCount: AVAudioFrameCount = 8_192

    func analyze(
        url: URL,
        layout: HarmonicaLayout,
        progress: ((Double) -> Void)? = nil,
        shouldCancel: () -> Bool = { false }
    ) throws -> ImportedSongAnalysis {
        let file = try AVAudioFile(forReading: url)
        let sourceRate = file.processingFormat.sampleRate
        guard sourceRate > 0, file.length > 0 else {
            throw ImportedSongAnalyzerError.unreadableAudio
        }

        let duration = min(Double(file.length) / sourceRate, maximumAnalysisDuration)
        let maximumFrames = AVAudioFramePosition(duration * sourceRate)
        var framesRead: AVAudioFramePosition = 0
        var observations: [PitchObservation] = []
        progress?(0)

        while framesRead < maximumFrames {
            guard !shouldCancel() else { throw ImportedSongAnalyzerError.cancelled }
            let remaining = maximumFrames - framesRead
            let capacity = AVAudioFrameCount(min(AVAudioFramePosition(windowFrameCount), remaining))
            guard let buffer = AVAudioPCMBuffer(
                pcmFormat: file.processingFormat,
                frameCapacity: capacity
            ) else { break }

            try file.read(into: buffer, frameCount: capacity)
            guard buffer.frameLength > 0 else { break }
            framesRead += AVAudioFramePosition(buffer.frameLength)

            let windowDuration = Double(buffer.frameLength) / sourceRate
            let frequency = try dominantFrequency(
                in: buffer,
                sourceSampleRate: sourceRate,
                shouldCancel: shouldCancel
            )
            observations.append(PitchObservation(frequency: frequency, duration: windowDuration))
            progress?(min(1, Double(framesRead) / Double(maximumFrames)))
        }

        let suggested = Self.makeSuggestedEvents(from: observations, layout: layout)
        if suggested.isEmpty {
            return ImportedSongAnalysis(
                notes: Self.fallbackPhrase(layout: layout),
                duration: duration,
                usedFallback: true
            )
        }

        return ImportedSongAnalysis(notes: suggested, duration: duration, usedFallback: false)
    }

    static func makeSuggestedEvents(
        from observations: [PitchObservation],
        layout: HarmonicaLayout,
        maximumNotes: Int = 128
    ) -> [HarmonicaNoteEvent] {
        var runs: [(note: String, duration: TimeInterval)] = []

        for observation in observations {
            guard let frequency = observation.frequency,
                  let note = layout.nearestPlayableNote(to: frequency) else { continue }

            if let last = runs.last, last.note == note {
                runs[runs.count - 1].duration += observation.duration
            } else {
                runs.append((note, observation.duration))
            }
        }

        // Very short alternating detections in a full mix are usually percussion or overtones.
        let stableRuns = runs.filter { $0.duration >= 0.12 }
        let sampledRuns: [(note: String, duration: TimeInterval)]
        if stableRuns.count <= maximumNotes {
            sampledRuns = stableRuns
        } else {
            let stride = Double(stableRuns.count) / Double(maximumNotes)
            sampledRuns = (0..<maximumNotes).map { index in
                stableRuns[min(stableRuns.count - 1, Int(Double(index) * stride))]
            }
        }

        return sampledRuns.compactMap { run in
            guard let hole = layout.hole(for: run.note) else { return nil }
            return HarmonicaNoteEvent(
                note: run.note,
                duration: min(2, max(0.25, (run.duration * 2).rounded() / 2)),
                hole: "\(hole.index)\(hole.airflow == .blow ? "B" : "D")"
            )
        }
    }

    static func fallbackPhrase(layout: HarmonicaLayout) -> [HarmonicaNoteEvent] {
        let preferred = ["C5", "E5", "G5", "A5", "G5", "E5", "D5", "C5"]
        return preferred.compactMap { note in
            guard let hole = layout.hole(for: note) else { return nil }
            return HarmonicaNoteEvent(
                note: note,
                duration: note == "C5" ? 1 : 0.5,
                hole: "\(hole.index)\(hole.airflow == .blow ? "B" : "D")"
            )
        }
    }

    private func dominantFrequency(
        in buffer: AVAudioPCMBuffer,
        sourceSampleRate: Double,
        shouldCancel: () -> Bool
    ) throws -> Double? {
        guard let channels = buffer.floatChannelData else { return nil }
        let channelCount = Int(buffer.format.channelCount)
        let frameCount = Int(buffer.frameLength)
        guard channelCount > 0, frameCount > 0 else { return nil }

        let downsampleStep = max(1, Int((sourceSampleRate / analysisSampleRate).rounded()))
        let effectiveRate = sourceSampleRate / Double(downsampleStep)
        var samples: [Double] = []
        samples.reserveCapacity(frameCount / downsampleStep)

        var frame = 0
        while frame < frameCount {
            var mixed: Double = 0
            for channel in 0..<channelCount {
                mixed += Double(channels[channel][frame])
            }
            samples.append(mixed / Double(channelCount))
            frame += downsampleStep
        }

        guard samples.count >= 256 else { return nil }
        let mean = samples.reduce(0, +) / Double(samples.count)
        for index in samples.indices {
            samples[index] -= mean
        }

        let rms = sqrt(samples.reduce(0) { $0 + $1 * $1 } / Double(samples.count))
        guard rms >= 0.008 else { return nil }

        var energyPrefix = [Double](repeating: 0, count: samples.count + 1)
        for index in samples.indices {
            energyPrefix[index + 1] = energyPrefix[index] + samples[index] * samples[index]
        }

        let minimumFrequency = 90.0
        let maximumFrequency = 1_200.0
        let minimumLag = max(2, Int(effectiveRate / maximumFrequency))
        let maximumLag = min(samples.count / 2, Int(effectiveRate / minimumFrequency))
        guard minimumLag < maximumLag else { return nil }

        var bestLag = 0
        var bestCorrelation = 0.0
        try samples.withUnsafeBufferPointer { sampleBuffer in
            guard let baseAddress = sampleBuffer.baseAddress else { return }
            for lag in minimumLag...maximumLag {
                if lag.isMultiple(of: 16), shouldCancel() {
                    throw ImportedSongAnalyzerError.cancelled
                }
                let comparisonCount = samples.count - lag
                var numerator = 0.0
                vDSP_dotprD(
                    baseAddress,
                    1,
                    baseAddress.advanced(by: lag),
                    1,
                    &numerator,
                    vDSP_Length(comparisonCount)
                )
                let firstEnergy = energyPrefix[comparisonCount]
                let secondEnergy = energyPrefix[samples.count] - energyPrefix[lag]
                let denominator = sqrt(firstEnergy * secondEnergy)
                let correlation = denominator > 0 ? numerator / denominator : 0
                if correlation > bestCorrelation {
                    bestCorrelation = correlation
                    bestLag = lag
                }
            }
        }

        guard bestLag > 0, bestCorrelation >= 0.35 else { return nil }
        return effectiveRate / Double(bestLag)
    }
}

struct PitchObservation {
    let frequency: Double?
    let duration: TimeInterval
}
