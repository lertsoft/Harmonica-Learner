import XCTest
import AVFoundation
@testable import Harmonica

final class ImportedSongAnalyzerTests: XCTestCase {
    func testSuggestedEventsCollapseRepeatedPitchAndMapToHarmonicaHole() {
        let observations = [
            PitchObservation(frequency: 523.251, duration: 0.1),
            PitchObservation(frequency: 523.251, duration: 0.1),
            PitchObservation(frequency: 587.330, duration: 0.2)
        ]

        let events = ImportedSongAnalyzer.makeSuggestedEvents(
            from: observations,
            layout: .diatonicC
        )

        XCTAssertEqual(events.map(\.note), ["C5", "D5"])
        XCTAssertEqual(events.map(\.hole), ["4B", "4D"])
        XCTAssertEqual(events.map(\.duration), [0.25, 0.25])
    }

    func testSuggestedEventsIgnoreSilenceAndUnstableBlips() {
        let observations = [
            PitchObservation(frequency: nil, duration: 0.2),
            PitchObservation(frequency: 523.251, duration: 0.05),
            PitchObservation(frequency: nil, duration: 0.2)
        ]

        let events = ImportedSongAnalyzer.makeSuggestedEvents(
            from: observations,
            layout: .diatonicC
        )

        XCTAssertTrue(events.isEmpty)
    }

    func testFallbackPhraseIsPlayableOnSelectedLayout() {
        let events = ImportedSongAnalyzer.fallbackPhrase(layout: .diatonicC)

        XCTAssertFalse(events.isEmpty)
        XCTAssertTrue(events.allSatisfy { HarmonicaHole.fromCode($0.hole) != nil })
        XCTAssertTrue(events.allSatisfy { HarmonicaLayout.diatonicC.hole(for: $0.note) != nil })
    }

    func testAnalyzeReadsAudioFileAndFindsPlayablePitch() throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("harmonica-analyzer-\(UUID().uuidString).caf")
        defer { try? FileManager.default.removeItem(at: url) }

        let sampleRate = 44_100.0
        let duration = 0.75
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        let format = try XCTUnwrap(
            AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)
        )
        let buffer = try XCTUnwrap(AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount))
        let samples = try XCTUnwrap(buffer.floatChannelData?[0])
        buffer.frameLength = frameCount

        for frame in 0..<Int(frameCount) {
            let time = Double(frame) / sampleRate
            samples[frame] = Float(sin(2 * .pi * 523.251 * time) * 0.4)
        }

        let file = try AVAudioFile(forWriting: url, settings: format.settings)
        try file.write(from: buffer)

        let analysis = try ImportedSongAnalyzer().analyze(url: url, layout: .diatonicC)

        XCTAssertFalse(analysis.usedFallback)
        XCTAssertFalse(analysis.notes.isEmpty)
        XCTAssertTrue(analysis.notes.allSatisfy { $0.note == "C5" })
        XCTAssertEqual(analysis.duration, duration, accuracy: 0.02)
    }
}
