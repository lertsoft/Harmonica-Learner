import AVFoundation
import Accelerate
import Foundation

nonisolated struct ImportedSongAnalysis {
    let notes: [HarmonicaNoteEvent]
    let duration: TimeInterval
    let arrangement: HarmonicaArrangementSummary
}

nonisolated enum ImportedSongAnalyzerError: LocalizedError, Equatable {
    case unreadableAudio
    case cancelled

    var errorDescription: String? {
        switch self {
        case .unreadableAudio: return "The selected audio file could not be read."
        case .cancelled: return "Song analysis was cancelled."
        }
    }
}

/// Best-effort multipitch estimation, followed by a playable single-hole arrangement.
/// Spectral evidence is approximate in mixed recordings; no generic melody is substituted.
nonisolated struct ImportedSongAnalyzer {
    func analyze(
        url: URL,
        layout: HarmonicaLayout,
        progress: ((Double) -> Void)? = nil,
        shouldCancel: () -> Bool = { false }
    ) throws -> ImportedSongAnalysis {
        let file = try AVAudioFile(forReading: url)
        let sampleRate = file.processingFormat.sampleRate
        guard sampleRate.isFinite, sampleRate > 0, file.length > 0 else {
            throw ImportedSongAnalyzerError.unreadableAudio
        }
        let duration = Double(file.length) / sampleRate
        // ~186 ms overlapping windows at every supported file sample rate. No time cap.
        let log2Size = vDSP_Length(max(9, min(16, Int(ceil(log2(sampleRate * 0.15))))))
        let size = 1 << Int(log2Size)
        let hop = size / 4
        guard let fft = vDSP_create_fftsetup(log2Size, FFTRadix(kFFTRadix2)) else {
            throw ImportedSongAnalyzerError.unreadableAudio
        }
        defer { vDSP_destroy_fftsetup(fft) }
        let channelCount = Int(file.processingFormat.channelCount)
        var channelSamples = [[Float]](repeating: [], count: channelCount)
        var window = [Float](repeating: 0, count: size)
        vDSP_hann_window(&window, vDSP_Length(size), Int32(vDSP_HANN_NORM))
        var observations: [PitchObservation] = []
        var position: AVAudioFramePosition = 0
        var previousHopRMS = 0.0
        progress?(0)
        while position < file.length {
            guard !shouldCancel() else { throw ImportedSongAnalyzerError.cancelled }
            let needed = size - (channelSamples.first?.count ?? 0)
            if needed > 0, file.framePosition < file.length {
                guard let buffer = AVAudioPCMBuffer(pcmFormat: file.processingFormat, frameCapacity: AVAudioFrameCount(needed)) else {
                    throw ImportedSongAnalyzerError.unreadableAudio
                }
                try file.read(into: buffer, frameCount: AVAudioFrameCount(needed))
                guard let channels = buffer.floatChannelData, buffer.frameLength > 0 else {
                    throw ImportedSongAnalyzerError.unreadableAudio
                }
                for channel in 0..<channelCount {
                    channelSamples[channel].append(contentsOf: UnsafeBufferPointer(start: channels[channel], count: Int(buffer.frameLength)))
                }
            }
            let frequencies = try pitches(
                channels: channelSamples, sampleRate: sampleRate, size: size,
                window: window, fft: fft, log2Size: log2Size, shouldCancel: shouldCancel
            )
            let consumed = min(hop, Int(file.length - position))
            let hopRMS = channelSamples.map { samples in
                let chunk = samples.prefix(consumed)
                return sqrt(chunk.reduce(0.0) { $0 + Double($1 * $1) } / Double(max(1, chunk.count)))
            }.max() ?? 0
            let newAttack = previousHopRMS > 0.003 && hopRMS > previousHopRMS * 1.8
            observations.append(PitchObservation(
                frequencies: frequencies, duration: Double(consumed) / sampleRate, startsNewNote: newAttack
            ))
            previousHopRMS = hopRMS
            position += AVAudioFramePosition(consumed)
            for channel in 0..<channelCount {
                channelSamples[channel].removeFirst(min(consumed, channelSamples[channel].count))
            }
            progress?(min(1, Double(position) / Double(file.length)))
        }
        guard !shouldCancel() else { throw ImportedSongAnalyzerError.cancelled }
        let arrangement = HarmonicaArrangement.make(from: observations, layout: layout)
        return ImportedSongAnalysis(notes: arrangement.notes, duration: duration, arrangement: arrangement.summary)
    }

    static func makeSuggestedEvents(from observations: [PitchObservation], layout: HarmonicaLayout) -> [HarmonicaNoteEvent] {
        HarmonicaArrangement.make(from: observations, layout: layout).notes
    }

    private func pitches(
        channels: [[Float]], sampleRate: Double, size: Int, window: [Float],
        fft: FFTSetup, log2Size: vDSP_Length, shouldCancel: () -> Bool
    ) throws -> [Double] {
        var power = [Float](repeating: 0, count: size / 2)
        var rms: Double = 0
        // Add channel energies rather than samples: stereo phase cancellation cannot erase a note.
        for channel in channels {
            guard !shouldCancel() else { throw ImportedSongAnalyzerError.cancelled }
            guard !channel.isEmpty else { continue }
            let mean = channel.reduce(0, +) / Float(channel.count)
            var samples = [Float](repeating: 0, count: size)
            var energy = 0.0
            for index in channel.indices {
                let value = channel[index] - mean
                energy += Double(value * value)
                samples[index] = value * window[index]
            }
            rms = max(rms, sqrt(energy / Double(channel.count)))
            var real = [Float](repeating: 0, count: size / 2)
            var imaginary = real
            real.withUnsafeMutableBufferPointer { re in
                imaginary.withUnsafeMutableBufferPointer { im in
                    var split = DSPSplitComplex(realp: re.baseAddress!, imagp: im.baseAddress!)
                    samples.withUnsafeBufferPointer { input in
                        input.baseAddress!.withMemoryRebound(to: DSPComplex.self, capacity: size / 2) {
                            vDSP_ctoz($0, 2, &split, 1, vDSP_Length(size / 2))
                        }
                    }
                    vDSP_fft_zrip(fft, &split, 1, log2Size, FFTDirection(FFT_FORWARD))
                    // DC and Nyquist are packed together; neither is a note candidate.
                    for index in 1..<size / 2 {
                        power[index] += re[index] * re[index] + im[index] * im[index]
                    }
                }
            }
        }
        guard rms >= 0.003 else { return [] }
        let magnitudes = power.map { sqrt(Double($0)) }
        let lower = max(2, Int(80 * Double(size) / sampleRate))
        let upper = min(size / 2 - 2, Int(2_200 * Double(size) / sampleRate))
        guard lower < upper else { return [] }
        let noise = magnitudes[lower...upper].sorted()[((upper - lower) / 2)]
        let strongest = magnitudes[lower...upper].max() ?? 0
        guard strongest > max(0.01, noise * 12) else { return [] }
        struct Peak {
            let frequency: Double
            let amplitude: Double
        }
        var peaks: [Peak] = []
        for bin in lower...upper {
            let amplitude = magnitudes[bin]
            guard amplitude > max(noise * 10, strongest * 0.16),
                  amplitude > magnitudes[bin - 1], amplitude >= magnitudes[bin + 1] else { continue }
            // Parabolic interpolation avoids quantizing a pitch to the nearest FFT bin.
            let left = log(max(1e-12, magnitudes[bin - 1]))
            let middle = log(max(1e-12, amplitude))
            let right = log(max(1e-12, magnitudes[bin + 1]))
            let denominator = left - 2 * middle + right
            let delta = abs(denominator) > 1e-12 ? 0.5 * (left - right) / denominator : 0
            let frequency = (Double(bin) + max(-0.5, min(0.5, delta))) * sampleRate / Double(size)
            guard let pitch = NoteMapper.pitch(for: frequency), abs(pitch.centsOffset) < 40 else { continue }
            peaks.append(Peak(frequency: frequency, amplitude: amplitude))
        }
        func isHarmonic(_ higher: Double, of lower: Double) -> Bool {
            let multiple = (higher / lower).rounded()
            return multiple >= 2 && multiple <= 8 && abs(1200 * log2(higher / (lower * multiple))) < 45
        }
        var detected: [Double] = []
        while !peaks.isEmpty, detected.count < 4 {
            guard !shouldCancel() else { throw ImportedSongAnalyzerError.cancelled }
            let best = peaks.max { left, right in
                func score(_ peak: Peak) -> Double {
                    peak.amplitude + peaks.reduce(0) { score, other in
                        score + (isHarmonic(other.frequency, of: peak.frequency) ? other.amplitude * 0.7 : 0)
                    }
                }
                return score(left) < score(right)
            }!
            detected.append(best.frequency)
            peaks.removeAll { abs(1200 * log2($0.frequency / best.frequency)) < 50 || isHarmonic($0.frequency, of: best.frequency) }
        }
        return detected.sorted()
    }
}

nonisolated struct PitchObservation {
    let frequencies: [Double]
    let duration: TimeInterval

    let startsNewNote: Bool

    init(frequencies: [Double], duration: TimeInterval, startsNewNote: Bool = false) {
        self.frequencies = frequencies
        self.duration = duration
        self.startsNewNote = startsNewNote
    }

    init(frequency: Double?, duration: TimeInterval) {
        self.init(frequencies: frequency.map { [$0] } ?? [], duration: duration)
    }
}
